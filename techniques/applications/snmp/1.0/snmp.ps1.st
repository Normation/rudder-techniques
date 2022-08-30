# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: 2021 Normation SAS

function snmp {
  [CmdletBinding()]
  param (
      [parameter(Mandatory = $true)]
      [String]$reportId,

      [parameter(Mandatory = $true)]
      [String]$techniqueName,

      [Rudder.PolicyMode]$policyMode
  )

  . $PSScriptRoot/snmp_communities.ps1
  . $PSScriptRoot/snmp_sources.ps1

  $sources = ("&SNMP_AUTHORIZED_SOURCES&").Split(",") | foreach { $_.Trim() } | Select-Object -Unique
  $flush = "&SNMP_FLUSH&"

  $acls = @(
  &SNMP_COMMUNITY_ACL:{acl |
  "&acl&" };separator=","& )

  $names = @(
  &SNMP_COMMUNITY_NAME:{name |
  "&name&" };separator=","& )

  $commonParams = @{
    TechniqueName = $techniqueName
    ReportID = $reportID
    ClassPrefix = "rudder_snmp"
    PolicyMode = $policyMode
  }
  ################################
  # SNMP installation
  ################################

  $installParams = @commonParams + @{
    ComponentName = "SNMP installation"
    ComponentKey = "None"
  }
  $installCall = Windows-Component-Present -Component $snmpComponent -PolicyMode $policyMode
  # Check service configuration (ie check all checkboxes in Services->SNMP->Properties->Agent->Service)
  $regCall = Registry-Entry-Present -Key "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\SNMP\Parameters\RFC1156Agent" -Entry "sysServices" -Value 79 -RegistryType "DWord" -PolicyMode $policyMode

  $worstStatus = (@($installCall.MethodStatus, $regCall.MethodStatus) | Measure -Maximum).Maximum
  $installMessage = switch($worstStatus) {
    ([Rudder.MethodStatus]::Error) { "An unexpected error occured while installing the SNMP components" }
    ([Rudder.MethodStatus]::Repaired) { "SNMP components were correctly installed" }
    ([Rudder.MethodStatus]::Success) { "SNMP components are already installed" }
    default { throw "Unexpected method status '${worstStatus}'" }
  }
  $installResult = [Rudder.MethodResult]::new(
    $worstStatus,
    $installMessage,
    (Get-FunctionName),
    ($installCall.InfoLogs + $regCallL.InfoLogs)
  )
  $null = Compute-Method-Call -MethodCall $installResult @installParams

  ################################
  # Check the Communities
  ################################
  $communitiesParams = @commonParams + @{
    ComponentName = "Communities configuration"
    ComponentKey = "None"
  }
  $communitiesCall = Manage-Communities -Names $names -Acls $acls -Force:$force -PolicyMode $policyMode
  $null = Compute-Method-Call -MethodCall $communitiesCall @communitiesParams

  ################################
  # Check the permitted sources
  ################################
  $sourcesParams = @commonParams + @{
    ComponentName = "Authorized Servers"
    ComponentKey = "None"
  }
  $authorizedSourcesCall = Manage-SnmpSources -Sources $sources -Force:$force -PolicyMode $policyMode
  $null = Compute-Method-Call -MethodCall $authorizedSourcesCall @sourcesParams

  ################################
  # Check the service status
  ################################
  $serviceParams = @commonParams + @{
    ComponentName = "Communities configuration"
    ComponentKey = "None"
    # Disable the reporting as it was previously merged with the communities reporting
    # this is bad, but good enough
    DisableReporting = $true
  }
  $serviceCall = Service-started -Name "snmp" -PolicyMode $policyMode
  $null = Compute-Method-Call -MethodCall $serviceCall @serviceParams
}
