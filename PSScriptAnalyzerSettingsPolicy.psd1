@{
  IncludeDefaultRules = $True
  CustomRulePath      = @(
      './CustomRules/CustomRules.psm1'
  )
  Rules = @{
    PSPlaceOpenBrace = @{
      Enable             = $true
      OnSameLine         = $true
      NewLineAfter       = $true
      IgnoreOneLineBlock = $true
    }

    PSPlaceCloseBrace = @{
      Enable             = $true
      NoEmptyLineBefore  = $true
      IgnoreOneLineBlock = $true
      NewLineAfter       = $false
    }

    PSUseConsistentIndentation = @{
      Enable              = $true
      IndentationSize     = 2
      PipelineIndentation = "IncreaseIndentationForFirstPipeline"
      Kind                = "space"
    }

    PSUseConsistentWhitespace = @{
      Enable                                  = $true
      CheckInnerBrace                         = $true
      CheckOpenBrace                          = $true
      CheckOpenParen                          = $true
      CheckOperator                           = $false
      CheckPipe                               = $true
      CheckPipeForRedundantWhitespace         = $false
      CheckSeparator                          = $true
      CheckParameter                          = $false
      IgnoreAssignmentOperatorInsideHashTable = $false
    }
  }

  ExcludeRules = @(
    "PSAvoidTrailingWhitespace",
    "AvoidUninitializedVariableInModule",
    "PSAvoidUsingWriteHost",
    "PSUseApprovedVerbs",
    "PSAvoidDefaultValueSwitchParameter",
    "PSUseOutputTypeCorrectly",
    "PSUseShouldProcessForStateChangingFunctions",
    "PSAvoidUsingInvokeExpression",
    "PSAvoidUsingPlainTextForPassword",
    "PSAvoidUsingConvertToSecureStringWithPlainText",
    "PSUseSingularNouns",
    "PSUseToExportFieldsInManifest"
  )
}
