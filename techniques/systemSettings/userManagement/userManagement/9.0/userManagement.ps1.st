# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: 2021 Normation SAS

function check_usergroup_user_parameters_&RudderUniqueID& {
  [CmdletBinding()]
  param (
      [parameter(Mandatory=$true)]   [string]$reportId,
      [parameter(Mandatory=$true)]   [string]$techniqueName,
      [Parameter(Mandatory = $true)] [Rudder.PolicyMode]$policyMode
  )


    $localContext = [Rudder.Context]::new($techniqueName)
    $localContext.merge($system_classes)
    $trackingkey = @(
    &TRACKINGKEY:{directiveId |
    "&directiveId&" };separator=","& )

    $logins = @(
    &USERGROUP_USER_LOGIN:{login |
    "&login&" };separator=","& )

    $policies = @(
    &USERGROUP_USER_ACTION:{policy |
    "&policy&" };separator=","& )

    $passwords = @(
    &USERGROUP_USER_PASSWORD:{password |
    "&password&" };separator=","& )

    $password_policies = @(
    &USERGROUP_USER_PASSWORD_POLICY:{password_policy |
    "&password_policy&" };separator=","& )

    $present        = "add"
    $absent         = "remove"
#To REMOVE in the future
    $check_present  = "checkhere"
    $check_absent   = "checknothere"
#END
    $componentName  = "Users"
    $homeSection    = "Home directory"
    $passwdSection  = "Password"
    $resultNAString = "Not applicable"

    $commonParams = @{
      TechniqueName = $techniqueName
      ReportId      = $reportId
      PolicyMode    = $policyMode
      ClassPrefix   = "user_management_&RudderUniqueID&"
    }

    for ($i=0; $i -lt $trackingkey.length; $i++) {
      $userParams = $commonParams + @{
          ComponentName = "Users"
          ComponentKey = $logins[$i]
      }
        
      if ($policies[$i] -eq $present) {
        $methodCallPresent = User-Present -login $logins[$i] -PolicyMode $policyMode
        $null = Compute-Method-Call -MethodCall $methodCallPresent @userParams

        $passwordParams = $commonParams + @{
          ComponentName = "Password"
          ComponentKey = $logins[$i]
        }
        if ($Passwords[$i]) {
          #Password defined
          if ($password_policies[$i] -eq "everytime") {
            #Checking password everytime
            $methodCallPassword = User-Password-Clear -login $logins[$i] -password $passwords[$i] -PolicyMode $policyMode
            $null = Compute-Method-Call -MethodCall $methodCallPassword @passwordParams
            
          } elseif ($password_policies[$i] -eq "oneshot") {
            #Checking password at creation only

            if ($methodCallPresent.MethodStatus -eq [Rudder.MethodStatus]::Repaired) {
              #User absent => setting password
              $methodCallPassword = User-Password-Clear -login $logins[$i] -password $passwords[$i] -PolicyMode $policyMode
              
              $null = Compute-Method-Call -MethodCall $methodCallPassword @passwordParams
            } else {
              $null = Rudder-Report-NA  @passwordParams -message "Password is not requested to be checked"
            }
          }
        } else {
          $null = Rudder-Report-NA  @passwordParams -message "Not applicable, no password defined"
        }

      } elseif ($policies[$i] -eq $absent) {
        $methodCallPresent = User-Absent -login $logins[$i] -PolicyMode $policyMode
        $null = Compute-Method-Call -MethodCall $methodCallPresent @userParams

#To REMOVE in the future
      } elseif ($policies[$i] -eq $check_present) {
        $methodCallPresent = User-Present -login $logins[$i] -PolicyMode ([Rudder.PolicyMode]::Audit)
        $null = Compute-Method-Call -MethodCall $methodCallPresent @userParams
      } elseif ($policies[$i] -eq $check_absent) {
        $methodCallPresent = User-Absent -login $logins[$i] -PolicyMode ([Rudder.PolicyMode]::Audit)
        $null = Compute-Method-Call -MethodCall $methodCallPresent @userParams
      }

      #Unix section reporting
      $unixParams = $commonParams + @{
          ComponentName = "Home directory"
          ComponentKey = $logins[$i]
      }
      $null = Rudder-Report-NA  @unixParams -message "Not applicable on Windows"
    }
}

