<#
.SYNOPSIS
  The variables names should be in camelCase.
.DESCRIPTION
  Variable names should use camelCase style
  The rule verify that each variable assignment use camelCase. It does not
  currently check each variable expressions, only assignments.
.EXAMPLE
  UseCamelCase -ScriptBlockAst $ScriptBlockAst
.INPUTS
  [System.Management.Automation.Language.ScriptBlockAst]
.OUTPUTS
  [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
.NOTES
  https://msdn.microsoft.com/en-us/library/dd878270(v=vs.85).aspx
  https://msdn.microsoft.com/en-us/library/ms229043(v=vs.110).aspx
#>
Function UseCamelCase {
  [CmdletBinding()]
  [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
  Param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [System.Management.Automation.Language.ScriptBlockAst]
    $ScriptBlockAst
  )

  Process {
    $results = @()
    try {
      [ScriptBlock]$predicate = {
        Param ([System.Management.Automation.Language.Ast]$Ast)
        [bool]$returnValue = $false

        # Look for an AssignmentStatementAst, and inside it, for VariableExpressionAst in its left part
        if (Is-variable-Assignment $ast) {
          [System.Management.Automation.Language.AssignmentStatementAst]$assignmentAst = $Ast
          $variableName = Get-Variable-Name $assignmentAst
          $returnValue = $variableName -cnotmatch '^(env:.*)|((global:|private:|local:)?[a-z]+([A-Z0-9]{1,3}|([A-Z][a-z0-9]+)*))$'
        }
        return $returnValue
      }

      [System.Management.Automation.Language.Ast[]]$violations = $ScriptBlockAst.FindAll($predicate, $True)
      If ($violations.Count -ne 0) {
        Foreach ($violation in $violations) {
          [System.Management.Automation.Language.AssignmentStatementAst]$violationAst = $violation
          $resultArgs = @{
            TypeName = "Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord"
            ArgumentList = "$((Get-Help $MyInvocation.MyCommand.Name).Description.Text): $($violationAst.Left)", $violationAst.Extent, $PSCmdlet.MyInvocation.InvocationName, "Information", $null
          }
          $result = New-Object @resultArgs
          $results += $result
        }
      }
      return $results
    } catch {
      Write-Host $_
      $PSCmdlet.ThrowTerminatingError($_)
    }
  }
}
