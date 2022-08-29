# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: 2021 Normation SAS

function copyFileFromSharedFolder_&RudderUniqueID& {
  [CmdletBinding()]
  param (
      [parameter(Mandatory=$true)]
      [string]$reportId,

      [parameter(Mandatory=$true)]
      [string]$techniqueName,

      [Rudder.PolicyMode]$policyMode
  )

    $trackingkey = @(
    &TRACKINGKEY:{directiveId |
    "&directiveId&" };separator=","& )

    $names = @(
    &COPYFILE_NAME:{name |
    "&name&" };separator=","& )

    $destinations = @(
    &COPYFILE_DESTINATION:{destination |
    "&destination&" };separator=","& )

    $posthooks = @(
    &COPYFILE_POST_HOOK_COMMAND:{posthook |
    "&posthook&" };separator=","& )

    for ($i=0; $i -lt $trackingkey.length; $i++) {
      $commonParams = @{
        TechniqueName = $techniqueName
        PolicyMode = $policyMode
        ClassPrefix = "copyGitFile_&RUDDERUniqueID&"
        ReportID = $trackingkey[$i]
      }
      $downloadCall = File-From-Shared-Folder -Source $names[$i] -Path $destinations[$i] -HashType "sha256" -PolicyMode $policyMode
      $downloadParams = $commonParams + @{
        ComponentName = "Copy file"
        ComponentKey = $destinations[$i]
      }
      $null = Compute-Method-Call -MethodCall $downloadCall @downloadParams

      #Posthook execution
      $posthookParams = $commonParams + @{
        ComponentName = "Post-modification hook"
        ComponentKey = $destinations[$i]
      }
      if ((-not([String]::IsNullOrEmpty($posthooks[$i]))) -And ($downloadCall.MethodStatus -eq ([Rudder.MethodStatus]::Repaired))) {
        $posthookCall = Command-Execution -Command $posthooks[$i] -PolicyMode $policyMode
        $null = Compute-Method-Call -MethodCall $posthookCall @posthookParams
      } else {
        $message = if ([String]::IsNullOrEmpty($posthooks[$i])) {
          "No posthook defined"
        } else {
          "No posthook execution needed"
        }
        $null = Rudder-Report-NA @postHookParams -Message $message
      }
    }
}

