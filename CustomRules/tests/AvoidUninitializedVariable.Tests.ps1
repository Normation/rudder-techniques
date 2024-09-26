# This does not work correctly atm, due to the invoke-customscriptAnalyzeRule
# which is used with the scriptblock type instead of file type.
Describe AvoidUninitializedVariable {
    BeforeAll {
        $settings = Join-Path -Path $PSScriptRoot -ChildPath "../PSScriptAnalyzerSettings.psd1"
    }

    It 'Triggers when some variables are undefined: <name>' -TestCases @(
        @{ Script = 'return $b'; Name = "Undefined"}
        @{ Script = '$b = 0; foreach ($a in @("1", "2", "3")) { $b += $i }'; Name = "Undefined in foreach" }
    ) {
        Invoke-ScriptAnalyzer -ScriptDefinition $script -Settings $settings | Should -Not -BeNullOrEmpty
    }

    It 'Does not trigger when every variables are defined prior to their usage: <name>' -TestCases @(
        @{
          Name = "trivial case 1"
          Script = '$a = "ping"; $b = $a + "pong"'
        }
        @{
          Name = "Foreach"
          Script = '$b = 0; foreach ($a in @("1", "2", "3")) { $b += $a}'
        }
        @{
          Name = "Function parameters"
          Script = 'function f { param($a, $b) return $a + $b }'
        }
        @{
          Name = "Nested scriptblock"
          Script = '$tmpKey = Get-Item -Path .; $tmpValue = @{ Name = "Value"; Expression = { $tmpKey.GetValue($_) } }'
        }
        @{
          Name = "Real life block"
          Script = @'
            $tempProperties = @{}
            $currentFile = $_.FullName
            $content = ConvertPSObjectToHashtable -InputObject $(ConvertFrom-Json "$(Get-Content $_.FullName)")

            foreach ($key in $content.keys) {
              $tempProperties[$key] = $content[$key]
            }
'@
          }
        @{
          Name = "Scoped variable"
          Script = '$private:a = "ping"; $b = $a + "pong"'
        }
    ) {
        $a = Invoke-ScriptAnalyzer -ScriptDefinition $script -Settings $settings 
        if ($null -ne $a) {
          Write-Host $a.message
        }
        $a | Should -BeNullOrEmpty
    }
}
