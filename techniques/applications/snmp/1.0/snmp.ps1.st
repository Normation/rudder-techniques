# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: 2021 Normation SAS

function snmp {
  [CmdletBinding()]
  param (
    [parameter(Mandatory = $true)]
    [String]$reportId,

    [parameter(Mandatory = $true)]
    [String]$techniqueName,

    [parameter(Mandatory = $true)]
    [Rudder.PolicyMode]$policyMode
  )

  $force = $false
  function Translate-AclToDword {
    param(
      [String] $acl
    )
    switch ($acl) {
      rocommunity { 4 }
      rwcommunity { 8 }
      default { throw "Unexpected acl type '${acl}'" }
    }
  }

  function Get-SnmpCommunities {
    $registry = "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\SNMP\Parameters\ValidCommunities"
    $indices = (Get-Item -Path $registry).Property
    $hash = @{}
    $raw = Get-ItemProperty -Path $registry
    $null = $indices | Foreach-Object {
      $hash.Add($_, ($raw | Select-Object -ExpandProperty $_))
    }
    $hash
  }

  function Force-SnmpCommunities {
    param(
      [Hashtable] $communities
    )
    $registry = "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\SNMP\Parameters\ValidCommunities"
    (Get-Item -Path $registry).Property | Foreach-Object {
      [Rudder.Logger]::Log.Debug("Removing entry '${_}'")
      Remove-ItemProperty -Path $registry -Name $_
    }
    $communities.Keys | Foreach-Object {
      [Rudder.Logger]::Log.Debug("Adding entry '${_}' = '$($communities[$_])'")
      New-ItemProperty -Path $registry -Name $_ -Value $communities[$_] -PropertyType String | Out-Null
    }
  }

  # If $force is set to $true, flush all the sources that are not explicitly
  # listed in the $expected input.
  function Check-SnmpCommunities {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'result')]
    param(
      [Parameter(Mandatory = $true)]
      [Hashtable] $expected,

      [Parameter(Mandatory = $true)]
      [Switch] $force
    )
    $result = $true
    $currentCommu = Get-SnmpCommunities
    try {
      # test that all entries in the expected records are defined
      $expected.Keys | Foreach-Object {
        if ($currentCommu[$_] -ne $expected[$_]) {
          $result = $false
        }
      }
      if ($force) {
        $result = $expected.Length -eq $currentCommu.Length
      }
      return $result
    } catch {
      return $false
    } finally {
      [Rudder.Logger]::Log.Debug("Comparing expected and found communities.`nFOUND:")
      $currentCommu.Keys | Foreach-Object {
        [Rudder.Logger]::Log.Debug( "'${_}' = '$($currentCommu[$_])'")
      }
      [Rudder.Logger]::Log.Debug("EXPECTED:")
      $expected.Keys | Foreach-Object {
        [Rudder.Logger]::Log.Debug("'${_}' = '$($expected[$_])'")
      }
      [Rudder.Logger]::Log.Debug("--> returning ${result}")
    }
  }

  function Build-Expected-SnmpCommunities {
    param(
      [String[]] $names,
      [String[]] $acls,
      [Switch] $force
    )
    $hash = @{}
    for ($i=0; $i -lt $names.Length; $i++) {
      $hash.Add($names[$i], (Translate-AclToDword -Acl $acls[$i]))
    }
    if ($force) {
      $current = Get-SnmpCommunities
      $current.Keys | Foreach-Object {
        if ($_ -notin $hash.Keys) {
          $hash.Add($_, $current[$_])
        }
      }
    }
    return $hash
  }

  #### MAIN STUFF

  function Manage-Communities {
    param(
      [String[]] $names,
      [String[]] $acls,
      [Switch] $force,
      [Rudder.PolicyMode] $policyMode
    )

    function CheckApply {
      [OutputType("Rudder.ApplyResult")]
      param(
        [String[]] $names,
        [String[]] $acls,
        [Switch] $force,
        [Rudder.PolicyMode] $policyMode
      )
      $localErrors = [System.Collections.Generic.List[Rudder.InfoLog]]::new()
      try {
        $expected = Build-Expected-SnmpCommunities -Names $names -Acls $acls -Force:$force
        if (Check-SnmpCommunities -Expected $expected -Force:$force) {
          return [Rudder.ApplyResult]::Success("SNMP Communities are already configured.")
        }

        if ($policyMode -eq ([Rudder.PolicyMode]::Audit)) {
          return [Rudder.ApplyResult]::Error("SNMP Communities do not match the expected configuration.")
        }

        # Try to repair
        Force-SnmpCommunities -Communities $expected
        if (Check-SnmpCommunities -Expected $expected -Force:$force) {
          return [Rudder.ApplyResult]::Repaired("SNMP Communities were reconfigured to match the expected configuration.")
        } else {
          $message = "Could not repair the SNMP communities to match the expected configuration. Current state:`n"
          $current = Get-SnmpCommunities
          $current.Key | Foreach-Object {
            $message += "'${_}' = '$($current[$_])'`n"
          }
          return [Rudder.ApplyResult]::Repaired($message)
        }
      } catch {
        $localErrors.Add([Rudder.InfoLog]::Error((Format-Exception $_)))
        return [Rudder.ApplyResult]::Error(
          "An unknown error occurred while checking SNMP communities.",
          $localErrors
        )
      }
    }

    $localResult = CheckApply -Names $names -Acls $acls -Force:$force -PolicyMode $policyMode
    return [Rudder.MethodResult]::new(
      $localResult.Status,
      $localResult.Message,
      (Get-FunctionName),
      $localResult.InfoLogs
    )
  }

  function Get-SnmpAuthSources {
    $registry = "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\SNMP\Parameters\PermittedManagers"
    $indices = (Get-Item -Path $registry).Property
    $raw = Get-ItemProperty -Path $registry
    $indices | Foreach-Object {
      $raw | Select-Object -ExpandProperty $_
    }
  }

  function Force-SnmpAuthSources {
    param(
      [String[]] $sources
    )
    function Flush-SnmpAuthSources {
      $registry = "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\SNMP\Parameters\PermittedManagers"
      $indices = (Get-Item -Path $registry).Property
      $indices | Foreach-Object {
        Remove-ItemProperty -Path $registry -Name $_
      }
    }
    $indice = 1
    $registry = "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\SNMP\Parameters\PermittedManagers"
    Flush-SnmpAuthSources
    $sources | Foreach-Object {
      New-ItemProperty -Path $registry -Name $indice -Value $_ | Out-Null
      $indice++
    }
  }

  # If $force is set to $true, flush all the sources that are not explicitly
  # listed in the $expected input.
  function Check-SnmpAuthSources {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'result')]
    param(
      [String[]] $expected,
      [Switch] $force
    )
    $currentSources = Get-SnmpAuthSources
    [Rudder.Logger]::Log.Debug("Found configured SNMP sources:")
    $currentSources | Foreach-Object { [Rudder.Logger]::Log.Debug($_) }

    if (Compare-Object ($currentSources | Sort-Object -Unique) $currentSources) {
      return $false
    }

    if ($force) {
      return (Compare-Object $expected $currentSources)
    }

    $result = $true
    $null = $expected | Foreach-Object {
      if ($currentSources -notcontains $_) {
        [Rudder.Logger]::Log.Debug("Missing " + $_)
        $result = $false
      }
    }
    return $result
  }

  function Build-Expected-SnmpAuthSources {
    param(
      [String[]] $expected,
      [Switch] $force
    )
    if ($force) {
      return (((Get-SnmpAuthSources) + $expected) | Sort-Object -Unique)
    }
    return $expected
  }

  function Manage-SnmpSources {
    param(
      [String[]] $sources,
      [Switch] $force,
      [Rudder.PolicyMode] $policyMode,
      $acls
    )
    function CheckApply {
      [OutputType("Rudder.ApplyResult")]
      param(
        [String[]] $sources,
        [Switch] $force
      )
      $localErrors = [System.Collections.Generic.List[Rudder.InfoLog]]::new()
      try {
        $expected = Build-Expected-SnmpAuthSources -Expected $sources -Force:$force
        [Rudder.Logger]::Log.Debug("Expecting SNMP sources:")
        $expected | Foreach-Object { [Rudder.Logger]::Log.Debug($_) }

        if (Check-SnmpAuthSources -Expected $expected -Force:$force) {
          return [Rudder.ApplyResult]::Success("SNMP authorized sources are already configured.")
        }

        if ($policyMode -eq ([Rudder.PolicyMode]::Audit)) {
          return [Rudder.ApplyResult]::Error("SNMP authorized sources configuration did not match the expected one.")
        }

        # Try to repair
        Force-SnmpAuthSources -Sources $expected
        if (Check-SnmpAuthSources -Expected $expected -Force:$force) {
          return [Rudder.ApplyResult]::Repaired("SNMP authorized sources were reconfigured to match the expected configuration")
        } else {
          $message = "Could not repair the SNMP authorized sources to match the expected configuration. Current state:`n"
          Get-SnmpAuthSources | Foreach-Object {
            $message += $_ + "`n"
          }
          return [Rudder.ApplyResult]::Repaired($message)
        }
      } catch {
        $localErrors.Add([Rudder.InfoLog]::Error((Format-Exception $_)))
        return [Rudder.ApplyResult]::Error(
          "An unknown error occurred while checking SNMP authorized sources.",
          $localErrors
        )
      }
    }

    $localResult = CheckApply -Sources $sources -Acls $acls -Force:$force -PolicyMode $policyMode
    return [Rudder.MethodResult]::new(
      $localResult.Status,
      $localResult.Message,
      (Get-FunctionName),
      $localResult.InfoLogs
    )
  }

  $sources = ("&SNMP_AUTHORIZED_SOURCES&").Split(",") | Foreach-Object { $_.Trim() } | Select-Object -Unique

  $acls = @(
  &SNMP_COMMUNITY_ACL:{acl |
  "&acl&" };separator=","&  )

  $names = @(
  &SNMP_COMMUNITY_NAME:{name |
  "&name&" };separator=","&  )

  $commonParams = @{
    TechniqueName = $techniqueName
    ReportID = $reportID
    ClassPrefix = "rudder_snmp"
    PolicyMode = $policyMode
  }
  ################################
  # SNMP installation
  ################################

  $installParams = $commonParams + @{
    ComponentName = "SNMP installation"
    ComponentKey = "None"
  }
  $installCall = Windows-Component-Present -Component "SNMP-service" -PolicyMode $policyMode
  # Check service configuration (ie check all checkboxes in Services->SNMP->Properties->Agent->Service)
  $regCall = Registry-Entry-Present -Key "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\SNMP\Parameters\RFC1156Agent" -Entry "sysServices" -Value 79 -RegistryType "DWord" -PolicyMode $policyMode
  $worstStatus = (@($installCall.MethodStatus, $regCall.MethodStatus) | Measure-Object -Maximum).Maximum
  $installMessage = switch ($worstStatus) {
    ([Rudder.MethodStatus]::Error) { "An unexpected error occurred while installing the SNMP components" }
    ([Rudder.MethodStatus]::Repaired) { "SNMP components were correctly installed" }
    ([Rudder.MethodStatus]::Success) { "SNMP components are already installed" }
    default { throw "Unexpected method status '${worstStatus}'" }
  }
  $installResult = [Rudder.MethodResult]::new(
    $worstStatus,
    $installMessage,
    (Get-FunctionName),
    ($installCall.InfoLogs + $regCall.InfoLogs)
  )
  $null = Compute-Method-Call -MethodCall $installResult @installParams

  ################################
  # Check the Communities
  ################################
  $communitiesParams = $commonParams + @{
    ComponentName = "Communities configuration"
    ComponentKey = "None"
  }
  $communitiesCall = Manage-Communities -Names $names -Acls $acls -Force:$force -PolicyMode $policyMode
  $null = Compute-Method-Call -MethodCall $communitiesCall @communitiesParams

  ################################
  # Check the permitted sources
  ################################
  $sourcesParams = $commonParams + @{
    ComponentName = "Authorized Servers"
    ComponentKey = "None"
  }
  $authorizedSourcesCall = Manage-SnmpSources -Sources $sources -Force:$force -PolicyMode $policyMode -Acls $acls
  $null = Compute-Method-Call -MethodCall $authorizedSourcesCall @sourcesParams

  ################################
  # Check the service status
  ################################
  $serviceParams = $commonParams + @{
    ComponentName = "Communities configuration"
    ComponentKey = "None"
    # Disable the reporting as it was previously merged with the communities reporting
    # this is bad, but good enough
    DisableReporting = $true
  }
  $serviceCall = Service-started -Name "snmp" -PolicyMode $policyMode
  $null = Compute-Method-Call -MethodCall $serviceCall @serviceParams
}
