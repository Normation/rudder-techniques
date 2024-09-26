# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: 2021 Normation SAS

function rudderMotd {
  [CmdletBinding()]
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'reportId', Justification = 'Very old technique')]
  param (
    [parameter(Mandatory = $true)]
    [string]$reportId,

    [parameter(Mandatory = $true)]
    [string]$techniqueName,

    [Rudder.PolicyMode]$policyMode
  )
  $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"

  $commonParams = @{
    TechniqueName = $techniqueName
    PolicyMode = $policyMode
    ClassPrefix = "rudderMotd"
    ReportID = "&TRACKINGKEY&"
    ComponentKey = "None"
    ComponentName = "MOTD Configuration"
  }

  # Ensure that the caption is there (mandatory to have the message)
  $regCall = Registry-Entry-Present -Key $registryPath -Entry "legalnoticecaption" -Value "Notice" -RegistryType "String" -PolicyMode $policyMode
  $null = Compute-Method-Call @commonParams -MethodCall $regCall -DisableReporting:$true

  # Ensure that the content is valid
  $contentCall = Registry-Entry-Present -Key $registryPath -Entry "legalnoticetext" -Value "&MOTD&" -RegistryType "String" -PolicyMode $policyMode
  $null = Compute-Method-Call @commonParams -MethodCall $contentCall
}
