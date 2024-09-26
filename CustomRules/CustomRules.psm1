# Module defining the Rudder custom PSSA rules. It exposes the rules and
# some helper cmdlet such as Invoke-CustomScriptAnalyzer used to debug, dev
# and test the custom rules.
$public = Get-ChildItem $psScriptRoot\public -Filter *.ps1 -Recurse
foreach ($item in $public) {
    . $item.FullName
}
Export-ModuleMember -Function AvoidUninitializedVariableInPolicy, AvoidUninitializedVariableInModule, UseCamelCase, Invoke-CustomScriptAnalyzerRule
