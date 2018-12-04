#####################################################################################
# Copyright 2018 Normation SAS
#####################################################################################
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, Version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#####################################################################################

function snmp {
  [CmdletBinding()]
  param (
      [parameter(Mandatory=$true)]  [string]$reportId,
      [parameter(Mandatory=$true)]  [string]$techniqueName,
      [switch]$auditOnly
  )
    $sources = ("&SNMP_AUTHORIZED_SOURCES&" -Split ",").Trim() | Select-Object -Unique
    $flush = "&SNMP_FLUSH&"
  
    $acls = @(
    &SNMP_COMMUNITY_ACL:{acl |
    "&acl&" };separator=","& )
  
    $names = @(
    &SNMP_COMMUNITY_NAME:{name |
    "&name&" };separator=","& )


    $local_classes = New-ClassContext
    $snmpComponent = "SNMP-service"
    $snmpRegistry = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\SNMP\Parameters"
    $snmpService = "SNMP"

    ## Check the installation of the SNMP feature
    $componentKeyInstallation = "None"
    $componentNameInstallation = "SNMP installation"

    $local_classes = Merge-ClassContext $local_classes $(Windows-Component-Present -Component $snmpComponent -ReportId $reportId -TechniqueName $techniqueName -auditOnly:$auditOnly -componentKey $componentKeyInstallation -componentName $componentNameInstallation )


    # Check service configuration (ie check all checkboxes in Services->SNMP->Properties->Agent->Service)
    $snmpConfigKey = "${snmpRegistry}\RFC1156Agent"
    $serviceConfigurationContext = Registry-Entry-Present -Key "$snmpConfigKey" -Entry "sysServices" -Value 79 -RegistryType "DWord" -techniqueName $techniqueName -ReportId $reportId -Report:$false -auditOnly:$auditOnly

    ## Check the Communities
    # Flush if needed
    if ($flush -eq $true) {
      $flushCommunitiesContext = sanitize-communities -communities $names -auditOnly:$auditOnly
    }
    $snmpCommunitiesKey = "${snmpRegistry}\ValidCommunities"
    for ($i=0; $i -lt $names.length; $i++) {
      switch ($acls[$i]) {
        rocommunity { $WindowsAcls = 4 }
        rwcommunity { $WindowsAcls = 8 }
      }
      $name = $names[$i]
      if (-not [string]::IsNullOrEmpty($name)) {
        $localCommunitiesContext = Registry-Entry-Present -Key "$snmpCommunitiesKey" -Entry "$name" -Value $WindowsAcls -RegistryType "DWord" -techniqueName $techniqueName -ReportId $reportId -Report:$false -auditOnly:$auditOnly
        $communitiesContext = ncf_classes_local_combine_N -auditOnly:$auditOnly -destinationPrefix "SNMP_Communities_Context" -contexts @($communitiesContext, $localCommunitiesContext)
      }
    }

    ## Check the permitted sources
    # Flush if needed
    if ("any" -eq $sources) {
      $flush = $true
      $sources = @()
    }
    if ($flush -eq $true) {
      $flushSourcesContext = sanitize-authorized-sources -Sources $sources -auditOnly:$auditOnly
    }
    # Add the missing ones
    $snmpPermittedServerKey = "${snmpRegistry}\PermittedManagers"
    $entries = Get-ItemProperty -Path "registry::${snmpPermittedServerKey}"

    # Next indice of permitted source
    $indices = (Get-Item -Path "Registry::${snmpPermittedServerKey}").property
    $nextIndice = ($indices | Measure-Object -Maximum).maximum + 1

    foreach ($iSource in $sources.GetEnumerator()) {
      $permitted = 0
      foreach ($iIndice in $indices.GetEnumerator()) {
        if (($entries).($iIndice) -eq $iSource) {
          $permitted = 1;
          break
        }
      }
      if ($permitted -eq 0 -and -not [string]::IsNullOrEmpty($iSource)) {
        $authorizedSourcesContext = Merge-ClassContext $local_classes $(Registry-Entry-Present -Key "$snmpPermittedServerKey" -Entry $nextindice -Value $iSource -RegistryType "String" -techniqueName $techniqueName -ReportId $reportId -Report:$false -auditOnly:$auditOnly)
        $nextIndice = $nextIndice + 1
      }
    }

    # Re index if needed
    $indexContext = index-authorized-sources -auditOnly:$auditOnly

    # Check the service status
    $serviceContext = Service-started -ServiceName $snmpService -ReportId $reportId -TechniqueName $techniqueName -auditOnly:$auditOnly -report:$False

    ## Communities Reporting
    $componentKeyCommunities = "None"
    $componentNameCommunities = "Communities configuration"
    $CommunitiesResult = ncf_classes_local_combine_N -auditOnly:$auditOnly -destinationPrefix "SNMP_Communities" -contexts @($serviceConfigurationContext, $communitiesContext, $serviceContext, $flushCommunitiesContext)

    $classes = _rudder_common_report -TechniqueName $techniqueName -Status $CommunitiesResult["status"] -ReportId $reportId -ComponentName $componentNameCommunities -ComponentKey $componentKeyCommunities -Message "Communities configuration" -report:$true

    ## Authorized Sources Reporting
    $componentKeyAuthorizedServers = "None"
    $componentNameAuthorizedServers = "Authorized Servers"
    $AuthorizedServersResult = ncf_classes_local_combine_N -auditOnly:$auditOnly -destinationPrefix "SNMP_AuthorizedServers" -contexts @($serviceConfigurationContext, $authorizedSourcesContext, $ServiceContext, $flushSourcesContext, $indexContext, $flushSourcesContext)

    $classes = _rudder_common_report -TechniqueName $techniqueName -Status $AuthorizedServersResult["status"] -ReportId $reportId -ComponentName $componentNameAuthorizedServers -ComponentKey $componentKeyAuthorizedServers -Message "Authorized SNMP sources" -report:$true

}


# Since the authorized sources entries are an index, which should all be consecutives
# whenever we delete some entries, we must reindex the indices.
function index-authorized-sources {
  param (
      [switch]$auditOnly
  )
  $reIndexContext = New-ClassContext
  $snmpPermittedRegistry = "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\SNMP\Parameters\PermittedManagers"
  $mustReIndex = $false
  $sources = @()
  $expectedIndice = 1
  $indice = 1

  # Check if we need to reindex
  $entryLIst = (Get-Item -Path "${snmpPermittedRegistry}").property | sort-Object
  $reIndexContext["status"] = 
    try {
      if (Test-Path "${snmpPermittedRegistry}") {
        foreach ($iIndice in $entryList) {
          $currentSource = (Get-ItemProperty -Path "${snmpPermittedRegistry}").($iIndice)
          $sources += $currentSource
          if ($iIndice -ne $expectedIndice) {
            $mustReIndex = $true
          }
          $expectedIndice++
        }
      }

      if (($mustReIndex -eq $true) -and ($auditOnly -eq $false)) {
        foreach ($iOldIndice in $entryList) {
          Remove-ItemProperty -Path "${snmpPermittedRegistry}" -Name $iOldIndice
        }
        # At this point the authorized servers are empty
        foreach ($iNewSource in $Sources) {
          New-ItemProperty -Path "${snmpPermittedRegistry}" -Name $indice -Value $iNewSource | Out-Null
          $indice++
        }
        [ComplianceStatus]::result_repaired
      } elseif ($auditOnly -eq $true) {
        if ($mustReIndex -eq $true) {
          [ComplianceStatus]::audit_noncompliant
        } else {
          [ComplianceStatus]::audit_compliant
        }
      } else {
          [ComplianceStatus]::result_success
      }
    } catch {
      if ($auditOnly -eq $true) {
        [ComplianceStatus]::audit_error
      } else {
        [ComplianceStatus]::result_error
      }
    }
    return $reIndexContext
}

# If flush is active, all entries non defined by rudder should be removed
function sanitize-authorized-sources {
  param (
      [string[]]$sources,
      [switch]$auditOnly
  )
  $mustFlush = $false
  $alreadySeen = @()
  $snmpPermittedRegistry = "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\SNMP\Parameters\PermittedManagers"
  $flushSourcesContext = New-ClassContext
  $flushSourcesContext["status"] =
  try {
    # Get entry list in the registry key
    $entryLIst = (Get-Item -Path "${snmppermittedRegistry}").property | sort-Object
    foreach ($iIndice in $entryList) {
      $currentSource = (Get-ItemProperty -Path "${snmppermittedRegistry}").($iIndice)
      if ((-not ($sources -contains $currentSource)) -or ($alreadySeen -contains $currentSource)) {
        $mustFlush = $true
        if ($auditOnly -eq $false) {
          Remove-ItemProperty -Path "${snmpPermittedRegistry}" -Name $iIndice
        }
      }
      $alreadySeen += $currentSource
    }
    if (($auditOnly -eq $true) -and ($mustFlush -eq $true)) {
      [ComplianceStatus]::audit_noncompliant
    } elseif (($auditOnly -eq $false) -and ($mustFlush -eq $true)) {
      [ComplianceStatus]::result_repaired
    } elseif (($auditOnly -eq $true) -and ($mustFlush -eq $false)) {
      [ComplianceStatus]::audit_compliant
    } elseif (($auditOnly -eq $false) -and ($mustFlush -eq $false)) {
      [ComplianceStatus]::result_success
    }
  } catch {
    if ($auditOnly -eq $true) {
      [ComplianceStatus]::audit_error
    } else {
      [ComplianceStatus]::result_error
    }
  }
  return $flushSourcesContext
}

# If flush is active, all communities non defined by rudder should be removed
function sanitize-communities {
  param (
      [string[]]$communities,
      [switch]$auditOnly
  )
  $mustFlush = $false
  $snmpCommunitiesRegistry = "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\SNMP\Parameters\ValidCommunities"
  $flushCommunitiesContext = New-ClassContext
  $flushCommunitiesContext["status"] =
  try {
    # Get entry list in the registry key
    $entryLIst = (Get-Item -Path "${snmpCommunitiesRegistry}").property
    foreach ($iCommunity in $entryList) {
      if (-not ($communities -contains $iCommunity)) {
        $mustFlush = $true
        if ($auditOnly -eq $false) {
          Remove-ItemProperty -Path "${snmpCommunitiesRegistry}" -Name $iCommunity
        }
      }
    }
    if (($auditOnly -eq $true) -and ($mustFlush -eq $true)) {
      [ComplianceStatus]::audit_noncompliant
    } elseif (($auditOnly -eq $false) -and ($mustFlush -eq $true)) {
      [ComplianceStatus]::result_repaired
    } elseif (($auditOnly -eq $true) -and ($mustFlush -eq $false)) {
      [ComplianceStatus]::audit_compliant
    } elseif (($auditOnly -eq $false) -and ($mustFlush -eq $false)) {
      [ComplianceStatus]::result_success
    }
  } catch {
    if ($auditOnly -eq $true) {
      [ComplianceStatus]::audit_error
    } else {
      [ComplianceStatus]::result_error
    }
  }
  return $flushCommunitiesContext
}
