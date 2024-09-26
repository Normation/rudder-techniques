Function Is-Variable-Assignment {
  Param (
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [System.Management.Automation.Language.Ast]$ast
  )
  return $ast -is [System.Management.Automation.Language.AssignmentStatementAst]
}

Function Get-Variable-Name {
  Param (
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [System.Management.Automation.Language.AssignmentStatementAst]$ast
  )
  $subAsts = $ast.Left.FindAll(
               { param($a)
                 $a -is [System.Management.Automation.Language.VariableExpressionAst]
               }, $true
             )

  if ($subAsts.Count -eq 0) {
    $rawName = $ast.Left.VariablePath.UserPath
    if ($rawName.contains(':')) {
      return $rawName.split(':')[1]
    }
    return $rawName
  } else {
    [System.Management.Automation.Language.VariableExpressionAst]$a = $subAsts[0]
    return $a.VariablePath.UserPath
  }
}

<#
  Return an ArrayList containing each variables defined in the current
  scriptblock, under the format: @{ Name=""; Line=x }

  To find each variable definition in the current scope we need to find:
    - All the parameters if any of the scriptblock
    - All the iterators used in loops
    - All the explicit variable assignments, which can have many forms:
       - $a = ""
       - [randomType]$a = ""
       - ($a, $b) = ("", "")
       - $b = { ... }
       - ...
#>
function Get-AllDefinedVariables {
  Param (
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [System.Management.Automation.Language.ScriptBlockAst]$ScriptBlockAst
  )
  begin {
    Write-Verbose "Enter $($MyInvocation.InvocationName)"
  }
  process {
    $context = New-Object System.Collections.ArrayList
    # Get all parameters
    $parametersAst  = $ScriptBlockAst.FindAll({
                                                param($a)
                                                $a -is [System.Management.Automation.Language.ParameterAst]
                                               }, $false)
    foreach ($p in $parametersAst) {
      $name = $p.Name.ToString().Trim('$')
      $line = $p.Extent.StartLineNumber
      Write-Verbose "  Found parameters: $name l:$line"
      $context.Add(@{ Name = $name; Line = $line }) | Out-null
    }

    # Get all variable assignments
    $variablesAst   = $ScriptBlockAst.FindAll({
                                                param($a)
                                                $a -is [System.Management.Automation.Language.AssignmentStatementAst]
                                              }, $false)
    foreach ($v in $variablesAst) {
      $targets = $v.GetAssignmentTargets()
      $line = $v.Extent.StartLineNumber
      $names = @()

      # The logic behind is broken, but seems sufficient for most cases
      foreach ($t in $targets) {
        # $hash[$property.Name][..] ...
        if ($t.PSObject.Properties.Name -contains "Target") {
          $i = $t.Target
          while ($i.PSObject.Properties.Name -contains "Target") {
            $i = $i.Target
          }
          $names += $i.VariablePath.UserPath.ToString().Trim("$")
        # ($a, $b) = ... case
        } elseif ($t.PSObject.Properties.Name -contains "Pipeline") {
          $varAssignments = $t.FindAll({
                                         param($c)
                                         $c -is [System.Management.Automation.Language.VariableExpressionAst]
                                       }, $false)
          foreach ($i in $varAssignments) {
            $names += $i.VariablePath.UserPath
          }
        # $output.$key = ...
        } elseif ($t.PSObject.Properties.Name -contains "Expression") {
          $names += $t.Expression.VariablePath.UserPath.ToString().Trim("$")
        #  Simple typed assignment
        } elseif ($t.PSObject.Properties.Name -contains "Child") {
          $names += $t.Child.VariablePath.UserPath.ToString().Trim("$")
        # Classic assignment
        } else {
          $names += $t.VariablePath.UserPath.ToString().Trim("$")
        }
        foreach ($name in $names) {
          Write-Verbose "  Found variable assignment: $name l:$line"
          # Remove scope tag if present: '$private:myPrivateVar' -> '$myPrivateVar'
          if ($name.contains(':')) {
            $name = ($name.Split(':'))[1]
            Write-Verbose "  Removing scope name: $name l:$line"
          }
          $context.Add(@{ Name = $name; Line = $line }) | Out-Null
        }
      }
    }

    # List all pseudo variables defined in loops
    $expressionsAst = $ScriptBlockAst.FindAll({
                                                param($a)
                                                $a -is [System.Management.Automation.Language.VariableExpressionAst]
                                              }, $false)

    foreach ($f in $expressionsAst) {
      if ($f.parent -is [System.Management.Automation.Language.ForEachStatementAst]) {
        $name = $f.parent.Variable.ToString().Trim("$")
        $line = $f.parent.Extent.StartLineNumber
        Write-Verbose "  Found foreach iterator: $name l:$line"
        $context.Add(@{ Name = $name; Line = $line }) | Out-Null
      }
    }
    write-verbose "END of loop search"
    return $context
  }
  end {
    Write-Verbose "END $($MyInvocation.InvocationName)"
  }
}

<#
  Given a scriptblock, look for all undefined/uninitialized variables in it,
  it returns an ArrayList of DiagnosticRecord, one per variable identified.

  It works recursively, each sub-scriptblock found under the current one will be check
  and inherit variables context from its parent.

  Each variable expression is compared with the variable context defined in the lines "above" it.
#>
function FindUninitializedVariables {
  Param (
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [System.Management.Automation.Language.ScriptBlockAst]$ScriptBlockAst,

    [Parameter(Mandatory=$false)]
    [AllowEmptyCollection()]
    [System.Collections.ArrayList]$Context,

    [Parameter(Mandatory)]
    [ValidateSet('Policy', 'Module')]
    [String] $target
  )
  begin {
    Write-Verbose "------------------------------"
    Write-Verbose "Enter $($MyInvocation.InvocationName)"
    Write-Verbose "  ScriptBlockAst = $ScriptBlockAst"
    Write-Verbose "  Inherited Context ="
    foreach ($a in $context) {
      Write-verbose "    | $($a.Name), l:$($a.Line)"
    }
  }
  process {
    $results = New-Object System.Collections.ArrayList

    $assigned = Get-AllDefinedVariables -ScriptBlockAst $ScriptBlockAst
    foreach ($v in $assigned) {
      $context.Add(@{ Name = $v.Name; Line = $v.Line }) | Out-Null
    }

    foreach ($a in $context) {
      Write-verbose "    | $($a.Name), l:$($a.Line)"
    }

    $expressionsAst = $ScriptBlockAst.FindAll({
                                                param($a)
                                                $a -is [System.Management.Automation.Language.VariableExpressionAst]
                                              }, $false)
    foreach ($expression in $expressionsAst) {
      if (-not (Is-Initialized -Ast $expression -AssignedVariables $context -Target $target)) {
        $ruleName = "AvoidUninitializedVariableIn{0}" -f $target
        $resultArgs = @{
          TypeName = "Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord"
          ArgumentList = "$($expression.ToString()) is used before assignment", $expression.Extent, "AvoidUninitializedVariable", "Warning", $null
        }
        $results.Add((New-Object @resultArgs)) | Out-Null
      }
    }

    # Do the same for each sub scriptblock
    $childrenBlock = $ScriptBlockAst.FindAll({
                                                param($a)
                                                (($a -is [System.Management.Automation.Language.ScriptBlockAst]) -and ($a -ne $ScriptBlockAst))
                                              }, $true)
    foreach ($block in $childrenBlock) {
      Write-Verbose "Testing subscriptblock..."
      [System.Management.Automation.Language.ScriptBlockAst]$blockAst = $block
      $results += FindUninitializedVariables -ScriptBlockAst $block -Context $context -Target $target
    }
    return $results
  }
  end {
    Write-Verbose "END $($MyInvocation.InvocationName)"
  }
}

<#
  Verify that a given variable used in a [VariableExpressionAst] is properly
  defined in the current scope.
  All variables matching a Powershell system variable or a Rudder global
  variable will be skipped.
#>
function Is-Initialized {
  Param (
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [System.Management.Automation.Language.VariableExpressionAst] $ast,

    [Parameter(Mandatory)]
    [AllowEmptyCollection()]
    [System.Collections.ArrayList] $assignedVariables,

    [Parameter(Mandatory)]
    [ValidateSet('Policy', 'Module')]
    [String] $target
  )
  $automaticVariables = @(
                           '$','?','^','_','ARGS',
                           'CONSOLEFILENAME',
                           'ERROR',
                           'ENV:CURL_SSL_BACKEND',
                           'ENV:PATH',
                           'ENV:PROGRAMFILES',
                           'ENV:PROGRAMFILES(X86)',
                           'ENV:PSMODULEPATH',
                           'EVENT',
                           'EVENTARGS',
                           'EVENTSUBSCRIBER',
                           'EXECUTIONCONTEXT',
                           'FALSE',
                           'FOREACH',
                           'HOME',
                           'HOST',
                           'INPUT',
                           'ISLINUX',
                           'LASTEXITCODE',
                           'MATCHES',
                           'MYINVOCATION',
                           'NESTEDPROMPTLEVEL',
                           'NULL',
                           'OFS',
                           'PID',
                           'PROFILE',
                           'PSBOUNDPARAMETERS',
                           'PSCMDLET',
                           'PSCOMMANDPATH',
                           'PSCULTURE',
                           'PSDEBUGCONTEXT',
                           'PSHOME',
                           'PSITEM',
                           'PSSCRIPTROOT',
                           'PSSENDERINFO',
                           'PSUICULTURE',
                           'PSVERSIONTABLE',
                           'PWD',
                           'REPORTERRORSHOWEXCEPTIONCLASS',
                           'REPORTERRORSHOWINNEREXCEPTION',
                           'REPORTERRORSHOWSOURCE',
                           'REPORTERRORSHOWSTACKTRACE',
                           'SENDER',
                           'SHELLID',
                           'STACKTRACE',
                           'THIS',
                           'TRUE',
                           'VERBOSEPREFERENCE'
                         )
  # STARTDATE should not be global, still, we let it be in the whitelist for now
  $whiteList = if ($target -ne 'Policy') {
    $automaticVariables + (Get-RudderModuleVariables)
  } else {
    $automaticVariables + (Get-PolicyVariables)
  }
  $result = $false
  $rawVarName = $ast.VariablePath.UserPath.ToString().Trim('$')
  $varName = if ($rawVarName.contains(':')) {
    $split = $rawVarName.Split(':')
    if ($split[0] -in @('env', 'local', 'global', 'private', 'script')) {
      $split[1]
    } else {
      $rawVarName
    }
  } else { $rawVarName }
  $varLine = $ast.Extent.StartLineNumber
  $assignedBefore = $assignedVariables | Where-Object { $_.Line -le $varLine }

  if (($varName -in $assignedBefore.Name) -or ($varName -in $whiteList)) {
    $result = $true
  } else {
    Write-Verbose "  Expression '$varName' on line '$varLine'"
    Write-Verbose "    ... contains uninitialized elements."
  }
  return $result
}

function Get-RudderModuleVariables {
  return (Import-PowershellDataFile -Path (Join-Path -Path $psScriptRoot -ChildPath '../rudderVariables.psd1'))['Internal']
}

function Get-PolicyVariables {
  return (Import-PowershellDataFile -Path (Join-Path -Path $psScriptRoot -ChildPath '../rudderVariables.psd1'))['policy']
}
