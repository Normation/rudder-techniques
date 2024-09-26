# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: 2021 Normation SAS

function fileTemplate_&RudderUniqueID& {
  [CmdletBinding()]
  param (
    [parameter(Mandatory = $true)]
    [string]$reportId,

    [parameter(Mandatory = $true)]
    [string]$techniqueName,

    [Rudder.PolicyMode]$policyMode
  )

  $trackingkeys = @(
  &TRACKINGKEY:{directiveId |
  "&directiveId&" };separator=","&  )

  $sources = @(
  &FILE_TEMPLATE_TEMPLATE:{source |
  "&source&" };separator=","&  )

  $isRaws = @(
  &FILE_TEMPLATE_RAW_OR_NOT:{isRaw |
  "&isRaw&" };separator=","&  )

  $rawSources = @(
&FILE_TEMPLATE_RAW_TEMPLATE:{rawSource |
"&rawSource&" };separator=","&  )

  $destinations = @(
  &FILE_TEMPLATE_AGENT_DESTINATION_PATH:{destination |
  "&destination&" };separator=","&  )

  $posthooks = @(
  &FILE_TEMPLATE_TEMPLATE_POST_HOOK_COMMAND:{destination |
  "&destination&" };separator=","&  )

  for ($i=0; $i -lt $trackingkeys.length; $i++) {
    $commonParams = @{
      TechniqueName = $techniqueName
      PolicyMode = $policyMode
      ClassPrefix = "fileTemplate_&RudderUniqueID&"
      ReportID = $reportId
      ComponentKey = $destinations[$i]
    }
    $templateFolder = Join-Path -Path ([Rudder.Datastate]::Get()['vars']['rudderBase']) -ChildPath "tmp/templates"
    $templateDestinations = Join-Path -Path $templateFolder -ChildPath ([Rudder.Condition]::canonify($destinations[$i]))

    #Check for template folder
    $templateFolderCall = Directory-Create -Path $templateFolder -PolicyMode $policyMode
    $null = Compute-Method-Call @commonParams -MethodCall $templateFolderCall -ComponentName "Templates location"

    # Prepare the template source
    #No need to check for permissions, they are well defined by the inheritance of Rudder folder
    $templateSrcCall = if ($isRaws[$i] -eq "Raw") {
      File-Enforce-Content -Path $templateDestinations -Lines $rawSources[$i] -Enforce:$true -PolicyMode $policyMode
    } else {
      File-From-Shared-Folder -Source $sources[$i] -Path $templateDestinations -HashType "sha256" -PolicyMode $policyMode
    }
    $null = Compute-Method-Call @commonParams -MethodCall $templateSrcCall -ComponentName "Load Template from a file or text input"


    #Expand the template
    $expandParams = $commonParams + @{
      ComponentName = "Expand template"
    }
    $expandCall = File-From-Template-Mustache -SourceTemplate $templateDestinations -Path $destinations[$i] -PolicyMode $policyMode
    $null = Compute-Method-Call -MethodCall $expandCall @expandParams


    #Posthook execution
    if ([String]::IsNullOrEmpty($posthooks[$i])) {
      Rudder-Report-NA @commonParams -Message "No posthook defined" -ComponentName "Posthook"
    } elseif ($expandCall.MethodStatus -eq ([Rudder.MethodStatus]::Repaired)) {
      $posthookCall = Command-Execution -Command $posthooks[$i] -PolicyMode $policyMode
      $null = Compute-Method-Call -MethodCall $posthookCall @commonParams -ComponentName "Posthook"
    } else {
      Rudder-Report-NA @commonParams -Message "No posthook execution needed." -ComponentName "Posthook"
    }

    #Non applicable sections
    Rudder-Report-NA @commonParams -ComponentName "Put permissions"
    Rudder-Report-NA @commonParams -ComponentName "Templates directory permissions"
  }
}
