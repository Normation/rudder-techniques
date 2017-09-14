function user_host_management {
  [CmdletBinding()]
  param (
      [parameter(Mandatory=$true)]
      [string]$reportId,
      [parameter(Mandatory=$true)]
      [string]$techniqueName,
      [switch]$auditOnly
  )
    
    $trackingkey = @(
    &TRACKINGKEY:{directiveId |
    "&directiveId&" };separator=","& )

    $logins = @(
    &USER_NODE_MANAGEMENT_LOGIN:{login |
    "&login&" };separator=","& )

    $policies = @(
    &USER_NODE_MANAGEMENT_POLICY:{policy |
    "&policy&" };separator=","& )

    $passwords = @(
    &USER_NODE_MANAGEMENT_PASSWORD:{password |
    "&password&" };separator=","& )


    $aix_passwords = @(
    &USER_NODE_MANAGEMENT_AIX:{aix_password |
    "&aix_password&" };separator=","& )

    $present = "present"
    $absent = "absent"
    $componentName = "User Present"


    $local_classes = New-ClassContext

    for ($i=0; $i -lt $trackingkey.length; $i++) {
        if ($policies[$i] -eq $present) {
          if (!$Password) {
            $local_classes = Merge-ClassContext $local_classes $(User-Present -login $logins[$i] -ReportId $trackingkey[$i] -TechniqueName $techniqueName -auditOnly:$auditOnly)
          } else {
            $local_classes = Merge-ClassContext $local_classes $(User-Present -login $logins[$i] -password $passwords[$i] -ReportId $trackingkey[$i] -TechniqueName $techniqueName -auditOnly:$auditOnly)
          }
        } elseif ($policies[$i] -eq $absent) {
          $local_classes = Merge-ClassContext $local_classes $(User-Absent -login $logins[$i] -reportId $trackingkey[$i] -TechniqueName $techniqueName -auditOnly:$auditOnly)
        }
    }
}

