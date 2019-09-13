function rudderMotd {
  [CmdletBinding()]
  param (
      [parameter(Mandatory=$true)]  [string]$reportId,
      [parameter(Mandatory=$true)]  [string]$techniqueName,
      [switch]$auditOnly
  )
    
    $trackingKey = "&TRACKINGKEY&"

    $motdContent = "&MOTD&"

    $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"

    $local_classes = New-ClassContext

    # Ensure that the caption is there (mandatory to have the message)
    $local_classes = Registry-Entry-Present -Key $registryPath -Entry "legalnoticecaption" -Value "Notice" -RegistryType "String" -ReportId $trackingKey -TechniqueName $techniqueName -auditOnly:$auditOnly -Report:$false

    # Ensure that the content is valid
    $local_classes = Merge-ClassContext $local_classes $(Registry-Entry-Present -Key $registryPath -Entry "legalnoticetext" -Value $motdContent -RegistryType "String"  -ReportId $trackingKey -TechniqueName $techniqueName -auditOnly:$auditOnly  -componentName "MOTD Configuration" -Report:$false  )

    $msg = defineReportMessageMotd -status $local_classes["status"]
    $classes = _rudder_common_report -TechniqueName $techniqueName -Status $local_classes["status"] -ReportId $reportId -ComponentName "MOTD Configuration" -ComponentKey "None" -Message $msg -report:$true

}

function defineReportMessageMotd {
  [CmdletBinding()]
  param (
      [parameter(Mandatory=$true)]  [string]$status
  )


    switch ($status)
    {
        "result_success" { "The welcome message is correct" }
        "result_repaired" { "The welcome message was repaired" }
        "result_error" { "The welcome message is incorrect and could not be corrected" }
        "result_na" { "The welcome message was not set to be changed" }
        "audit_compliant" { "The welcome message is correct" }
        "audit_noncompliant" { "The welcome message is not compliant" }
        "audit_error" { "Error: the welcome message is not compliant" }
        "audit_na" { "The welcome message was not set to be changed" }
        default { "Unknwon status for welcome message" }
    }
}
