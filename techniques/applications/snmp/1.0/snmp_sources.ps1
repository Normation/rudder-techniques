function Get-SnmpAuthSources {
  $registry = "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\SNMP\Parameters\PermittedManagers"
  $indices = (Get-Item -Path $registry).Property
  $raw = Get-ItemProperty -Path $registry
  $indices | Foreach-Object {
    $raw | Select-Object -ExpandProperty $_
  }
}

function Force-SnmpAuthSources {
  param(
    [String[]] $sources
  )
  function Flush-SnmpAuthSources {
    $registry = "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\SNMP\Parameters\PermittedManagers"
    $indices = (Get-Item -Path $registry).Property
    $indices | Foreach-Object {
      Remove-ItemProperty -Path $registry -Name $_
    }
  }
  $indice = 1
  $registry = "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\SNMP\Parameters\PermittedManagers"
  Flush-SnmpAuthSources
  $sources | Foreach-Object {
    New-ItemProperty -Path $registry -Name $indice -Value $_ | Out-Null
    $indice++
  }
}

# If $force is set to $true, flush all the sources that are not explicitly
# listed in the $expected input.
function Check-SnmpAuthSources {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'result')]
  param(
    [String[]] $expected,
    [Switch] $force
  )
  $currentSources = Get-SnmpAuthSources
  [Rudder.Logger]::Log.Debug("Found configured SNMP sources:")
  $currentSources | Foreach-Object { [Rudder.Logger]::Log.Debug($_) }

  if (Compare-Object ($currentSources | Sort-Object -Unique) $currentSources) {
    return $false
  }

  if ($force) {
    return (Compare-Object $expected $currentSources)
  }

  $result = $true
  $null = $expected | Foreach-Object {
    if ($currentSources -notcontains $_) {
      [Rudder.Logger]::Log.Debug("Missing " + $_)
      $result = $false
    }
  }
  return $result
}

function Build-Expected-SnmpAuthSources {
  param(
    [String[]] $expected,
    [Switch] $force
  )
  if ($force) {
    return (((Get-SnmpAuthSources) + $expected) | Sort-Object -Unique)
  }
  return $expected
}

function Manage-SnmpSources {
  param(
    [String[]] $sources,
    [Switch] $force,
    [Rudder.PolicyMode] $policyMode,
    $acls
  )
  function CheckApply {
    [OutputType("Rudder.ApplyResult")]
    param(
      [String[]] $sources,
      [Switch] $force
    )
    $localErrors = [System.Collections.Generic.List[Rudder.InfoLog]]::new()
    try {
      $expected = Build-Expected-SnmpAuthSources -Expected $sources -Force:$force
      [Rudder.Logger]::Log.Debug("Expecting SNMP sources:")
      $expected | Foreach-Object { [Rudder.Logger]::Log.Debug($_) }

      if (Check-SnmpAuthSources -Expected $expected -Force:$force) {
        return [Rudder.ApplyResult]::Success("SNMP authorized sources are already configured.")
      }

      if ($policyMode -eq ([Rudder.PolicyMode]::Audit)) {
        return [Rudder.ApplyResult]::Error("SNMP authorized sources configuration did not match the expected one.")
      }

      # Try to repair
      Force-SnmpAuthSources -Sources $expected
      if (Check-SnmpAuthSources -Expected $expected -Force:$force) {
        return [Rudder.ApplyResult]::Repaired("SNMP authorized sources were reconfigured to match the expected configuration")
      } else {
        $message = "Could not repair the SNMP authorized sources to match the expected configuration. Current state:`n"
        Get-SnmpAuthSources | Foreach-Object {
          $message += $_ + "`n"
        }
        return [Rudder.ApplyResult]::Repaired($message)
      }
    } catch {
      $localErrors.Add([Rudder.InfoLog]::Error((Format-Exception $_)))
      return [Rudder.ApplyResult]::Error(
        "An unknown error occurred while checking SNMP authorized sources.",
        $localErrors
      )
    }
  }

  $localResult = CheckApply -Sources $sources -Acls $acls -Force:$force -PolicyMode $policyMode
  return [Rudder.MethodResult]::new(
    $localResult.Status,
    $localResult.Message,
    (Get-FunctionName),
    $localResult.InfoLogs
  )
}
