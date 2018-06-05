function check_usergroup_user_parameters {
  [CmdletBinding()]
  param (
      [parameter(Mandatory=$true)]  [string]$reportId,
      [parameter(Mandatory=$true)]  [string]$techniqueName,
      [switch]$auditOnly
  )
    
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
    

    $local_classes = New-ClassContext

    for ($i=0; $i -lt $trackingkey.length; $i++) {

      if ($policies[$i] -eq $present) {
        $local_classes = Merge-ClassContext $local_classes $(User-Present -login $logins[$i] -ReportId $trackingkey[$i] -TechniqueName $techniqueName -componentName $componentName -auditOnly:$auditOnly)
        if ($Passwords[$i]) {
          #Password defined
          if ($password_policies[$i] -eq "everytime") {
            #Checking password everytime
            $local_classes = Merge-ClassContext $local_classes $(User-Password-Clear -login $logins[$i] -password $passwords[$i] -ReportId $trackingkey[$i] -componentName $passwdSection -TechniqueName $techniqueName -auditOnly:$auditOnly)
          } elseif ($password_policies[$i] -eq "oneshot") {
            #Checking password at creation only
            $login_name = $logins[$i]
            $class_name = "users_${login_name}_repaired"
            if ($local_classes["classes"].contains($class_name)) {
              #User absent => setting password
              $local_classes = Merge-ClassContext $local_classes $(User-Password-Clear -login $logins[$i] -password $passwords[$i] -ReportId $trackingkey[$i] -componentName $passwdSection -TechniqueName $techniqueName -auditOnly:$auditOnly)
            } else {
              if ($auditOnly) {
                $state = [ComplianceStatus]::audit_na
              } else { 
                $state = [ComplianceStatus]::result_na
              }
              $classes = _rudder_common_report -TechniqueName $techniqueName -Status $state -ReportId $reportId -ComponentName $passwdSection -ComponentKey $logins[$i] -Message $resultNAString -report:$true
            }
          }
        } else {
          $state = [ComplianceStatus]::result_na
          $passwordAbsent = "$resultNAString, no password defined"
          $classes = _rudder_common_report -TechniqueName $techniqueName -Status $state -ReportId $reportId -ComponentName $passwdSection -ComponentKey $logins[$i] -Message $passwordAbsent -report:$true
        }

      } elseif ($policies[$i] -eq $absent) {
        $local_classes = Merge-ClassContext $local_classes $(User-Absent -login $logins[$i] -reportId $trackingkey[$i] -TechniqueName $techniqueName -componentName $componentName -auditOnly:$auditOnly)

#To REMOVE in the future
      } elseif ($policies[$i] -eq $check_present) {
        $reportString = "User ${logins[$i]} check_present"
        $command = Invoke-Expression "NET USER $logins[$i] 2>\&1"
        $TestResult = $LastExitCode -eq 0
        if ($TestResult) {
          #User exists
          if ($auditOnly) { 
            $state = [ComplianceStatus]::audit_compliant
          } else { 
            $state = [ComplianceStatus]::result_success
          }
          $classes = _rudder_common_report -TechniqueName $techniqueName -Status $state -ReportId $reportId -ComponentName $componentName -ComponentKey $logins[$i] -Message $reportString -report:$true
        } else {
          #User does not exists
          if ($auditOnly) { 
            $state = [ComplianceStatus]::audit_noncompliant
          } else { 
            $state = [ComplianceStatus]::result_error
          }
          $classes = _rudder_common_report -TechniqueName $techniqueName -Status $state -ReportId $reportId -ComponentName $componentName -ComponentKey $logins[$i] -Message $reportString -report:$true
        }

      } elseif ($policies[$i] -eq $check_absent) {
        $reportString = "User ${logins[$i]} check_absent"
        $command = Invoke-Expression "NET USER $logins[$i] 2>\&1"
        $TestResult = $LastExitCode -eq 0
        if ($TestResult) {
          #User exists
          if ($auditOnly) { 
            $state = [ComplianceStatus]::audit_noncompliant
          } else { 
            $state = [ComplianceStatus]::result_error
          }
          $classes = _rudder_common_report -TechniqueName $techniqueName -Status $state -ReportId $reportId -ComponentName $componentName -ComponentKey $logins[$i] -Message $reportString -report:$true
        } else {
          #User does not exists
          if ($auditOnly) { 
            $state = [ComplianceStatus]::audit_compliant
          } else { 
            $state = [ComplianceStatus]::result_success
          }
          $classes = _rudder_common_report -TechniqueName $techniqueName -Status $state -ReportId $reportId -ComponentName $componentName -ComponentKey $logins[$i] -Message $reportString -report:$true
        }
#END
      }

      #Unix section reporting
      if ($auditOnly) { 
        $state = [ComplianceStatus]::audit_na
      } else { 
        $state = [ComplianceStatus]::result_na
      }
      $classes = _rudder_common_report -TechniqueName $techniqueName -Status $state -ReportId $reportId -ComponentName $homeSection -ComponentKey $logins[$i] -Message $resultNAString -report:$true
    }
}

