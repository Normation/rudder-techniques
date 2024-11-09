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
    $updateIfExists = "updateonly"

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
      $passwordParams = $commonParams + @{
          ComponentName = "Password"
          ComponentKey = $logins[$i]
      }
      # check if user exists
      $global:lastExitCode = $null
      # Test if user already exists
      $login = $logins[$i]
      Invoke-Expression "NET USER ${login} 2>&1" | Out-Null
      $userExists = $LastExitCode -eq 0

        
      if ( ($policies[$i] -eq $present) -or ($userExists -and ($policies[$i] -eq $updateIfExists) ) ) {
        $methodCallPresent = User-Present -login $logins[$i] -PolicyMode $policyMode
        $null = Compute-Method-Call -MethodCall $methodCallPresent @userParams

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

      } elseif ( (-not $userExists) -and ($policies[$i] -eq $updateIfExists) ) {
        $null = Rudder-Report-NA  @userParams -message "User does not exists"
        $null = Rudder-Report-NA  @passwordParams -message "User does not exists"
      }

      #Unix section reporting
      $primaryGroup = $commonParams + @{
          ComponentName = "User primary group"
          ComponentKey = $logins[$i]
      }
      $null = Rudder-Report-NA  @primaryGroup -message "Not applicable on Windows"

      $userFullName = $commonParams + @{
          ComponentName = "User full name"
          ComponentKey = $logins[$i]
      }
      $null = Rudder-Report-NA  @userFullName -message "Not applicable on Windows"

      $userDefaultShell = $commonParams + @{
          ComponentName = "User default shell"
          ComponentKey = $logins[$i]
      }
      $null = Rudder-Report-NA  @userDefaultShell -message "Not applicable on Windows"

      $homeDirectory = $commonParams + @{
          ComponentName = "Home Directory"
          ComponentKey = $logins[$i]
      }
      $null = Rudder-Report-NA  @homeDirectory -message "Not applicable on Windows"

      $secondaryParams = $commonParams + @{
          ComponentName = "User secondary groups"
          ComponentKey = $logins[$i]
      }
      $null = Rudder-Report-NA  @secondaryParams -message "Not applicable on Windows"
    }
}

