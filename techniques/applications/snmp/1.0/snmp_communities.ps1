function Translate-AclToDword {
  param(
    [String] $acl
  )
  switch ($acl) {
    rocommunity { 4 }
    rwcommunity { 8 }
    default { throw "Unexpected acl type '${acl}'" }
  }
}

function Get-SnmpCommunities {
  $registry = "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\SNMP\Parameters\ValidCommunities"
  $indices = (Get-Item -Path $registry).Property
  $hash = @{}
  $raw = Get-ItemProperty -Path $registry
  $null = $indices | Foreach-Object {
    $hash.Add($_, ($raw | Select-Object -ExpandProperty $_))
  }
  $hash
}

function Force-SnmpCommunities {
  param(
    [Hashtable] $communities
  )
  $registry = "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\SNMP\Parameters\ValidCommunities"

  (Get-Item -Path $registry).Property | Foreach-Object {
    [Rudder.Logger]::Log.Debug("Removing entry '${_}'")
    Remove-ItemProperty -Path $registry -Name $_
  }

  $communities.Keys | Foreach-Object {
    [Rudder.Logger]::Log.Debug("Adding entry '${_}' = '$($communities[$_])'")
    New-ItemProperty -Path $registry -Name $_ -Value $communities[$_] -PropertyType String | Out-Null
  }
}

# If $force is set to $true, flush all the sources that are not explicitly
# listed in the $expected input.
function Check-SnmpCommunities {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'result')]
  param(
    [Parameter(Mandatory = $true)]
    [Hashtable] $expected,

    [Parameter(Mandatory = $true)]
    [Switch] $force
  )
  $result = $true
  $currentCommu = Get-SnmpCommunities
  try {
    # test that all entries in the expected records are defined
    $expected.Keys | Foreach-Object {
      if ($currentCommu[$_] -ne $expected[$_]) {
        $result = $false
      }
    }

    if ($force) {
      $result = $expected.Length -eq $currentCommu.Length
    }
    return $result
  } catch {
    return $false
  } finally {
    [Rudder.Logger]::Log.Debug("Comparing expected and found communities.`nFOUND:")
    $currentCommu.Keys | Foreach-Object {
      [Rudder.Logger]::Log.Debug( "'${_}' = '$($currentCommu[$_])'")
    }
    [Rudder.Logger]::Log.Debug("EXPECTED:")
    $expected.Keys | Foreach-Object {
      [Rudder.Logger]::Log.Debug("'${_}' = '$($expected[$_])'")
    }
    [Rudder.Logger]::Log.Debug("--> returning ${result}")
  }
}

function Build-Expected-SnmpCommunities {
  param(
    [String[]] $names,
    [String[]] $acls,
    [Switch] $force
  )
  $hash = @{}
  for ($i=0; $i -lt $names.Length; $i++) {
    $hash.Add($names[$i], (Translate-AclToDword -Acl $acls[$i]))
  }

  if ($force) {
    $current = Get-SnmpCommunities
    $current.Keys | Foreach-Object {
      if ($_ -notin $hash.Keys) {
        $hash.Add($_, $current[$_])
      }
    }
  }
  return $hash
}

#### MAIN STUFF

function Manage-Communities {
  param(
    [String[]] $names,
    [String[]] $acls,
    [Switch] $force,
    [Rudder.PolicyMode] $policyMode
  )

  function CheckApply {
    [OutputType("Rudder.ApplyResult")]
    param(
      [String[]] $names,
      [String[]] $acls,
      [Switch] $force,
      [Rudder.PolicyMode] $policyMode
    )
    $localErrors = [System.Collections.Generic.List[Rudder.InfoLog]]::new()
    try {
      $expected = Build-Expected-SnmpCommunities -Names $names -Acls $acls -Force:$force
      if (Check-SnmpCommunities -Expected $expected -Force:$force) {
        return [Rudder.ApplyResult]::Success("SNMP Communities are already configured.")
      }

      if ($policyMode -eq ([Rudder.PolicyMode]::Audit)) {
        return [Rudder.ApplyResult]::Error("SNMP Communities do not match the expected configuration.")
      }

      # Try to repair
      Force-SnmpCommunities -Communities $expected
      if (Check-SnmpCommunities -Expected $expected -Force:$force) {
        return [Rudder.ApplyResult]::Repaired("SNMP Communities were reconfigured to match the expected configuration.")
      } else {
        $message = "Could not repair the SNMP communities to match the expected configuration. Current state:`n"
        $current = Get-SnmpCommunities
        $current.Key | Foreach-Object {
          $message += "'${_}' = '$($current[$_])'`n"
        }
        return [Rudder.ApplyResult]::Repaired($message)
      }
    } catch {
      $localErrors.Add([Rudder.InfoLog]::Error((Format-Exception $_)))
      return [Rudder.ApplyResult]::Error(
        "An unknown error occurred while checking SNMP communities.",
        $localErrors
      )
    }
  }

  $localResult = CheckApply -Names $names -Acls $acls -Force:$force -PolicyMode $policyMode
  return [Rudder.MethodResult]::new(
    $localResult.Status,
    $localResult.Message,
    (Get-FunctionName),
    $localResult.InfoLogs
  )
}
