<#
.SYNOPSIS
  Avoid using undefined variables.
.DESCRIPTION
  Avoid using undefined variables.
.EXAMPLE
  Test-VariablbeAssignment -ScriptBlockAst $ScriptBlockAst
.INPUTS
  [System.Management.Automation.Language.ScriptBlockAst]
.OUTPUTS
  [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
#>
. $psScriptroot/../rulesLib.ps1

function AvoidUninitializedVariableInModule {
  [CmdletBinding()]
  [OutputType([PSCustomObject[]])]
  Param (
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [System.Management.Automation.Language.ScriptBlockAst]$ast
  )

  process {
    try {
      # Since we are doing a recursive lookup to pass variable context to
      # children, we need to only trigger the rule on the root block
      if ($null -eq $ast.parent) {
        $context = New-Object System.Collections.ArrayList
        return FindUninitializedVariables -ScriptBlockAst $ast -Context $context -Target Module
      }
    } catch {
      $psCmdlet.ThrowTerminatingError( $_ )
    }
  }
}
