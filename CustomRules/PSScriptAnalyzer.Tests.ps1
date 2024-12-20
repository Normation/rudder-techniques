﻿<#
  Taken from https://github.com/indented-automation/Indented.ScriptAnalyzerRules
  Import the settings and custom rules from PSScriptAnalyzer in the repo to make
  them usable by the Invoke-CustomScriptAnalyzerRule cmdlet.
#>
Describe PSScriptAnalyzer {
    BeforeDiscovery {
        $moduleRoot = $PSScriptRoot.Substring(0, $PSScriptRoot.IndexOf('\tests'))
        $projectRoot = $moduleRoot | Split-Path -Parent
        $settings = Join-Path $projectRoot -ChildPath 'PSScriptAnalyzerSettings.psd1'

        $rules = Get-ChildItem -Path $moduleRoot -File -Recurse -Include *.ps1 -Exclude *.tests.ps1 |
            ForEach-Object {
                Invoke-ScriptAnalyzer -Path $_.FullName -Settings $settings
            } |
            Where-Object RuleName -NE 'TypeNotFound' |
            ForEach-Object {
                @{
                    Rule = [PSCustomObject]@{
                        RuleName   = $_.RuleName
                        Message    = $_.Message -replace '(.{50,90}) ', "`n        `$1" -replace '^\n        '
                        ScriptName = $_.ScriptName
                        Line       = $_.Line
                        ScriptPath = $_.ScriptPath
                    }
                }
            }
    }

    It (
        @(
            '<rule.RuleName>'
            '        <rule.Message>'
            '    in <rule.ScriptName> line <rule.Line>'
        ) | Out-String
    ) -TestCases $rules {
        $rule.ScriptPath | Should -BeNullOrEmpty
    }
}
