require "spec_helper"

# First run is done by technique scenario => persistent posthook launched
describe command("rudder agent run -r") do
  its(:stdout) { should match /^R: @@fileTemplate@@result_na@@.*?@@.*?@@.*?@@Posthook@@\/tmp\/posthookTest@@.*?No post-modification needed to run$/m}

  its(:stdout) { should match /^R: @@fileTemplate@@result_error@@.*?@@.*?@@.*?@@Posthook@@\/tmp\/persistentPosthooktest@@.*?The command .*?from postHook execution  could not be repaired$/m}
end

# Force the execution of the posthook
describe command("rm -f /tmp/posthookTest /tmp/persistentPosthookTest") do
end

describe command("rudder agent run -r") do
  its(:stdout) { should match /^R: @@fileTemplate@@result_repaired@@.*?@@.*?@@.*?@@Posthook@@\/tmp\/posthookTest@@.*?The command .*?from postHook execution  was repaired$/m}

  its(:stdout) { should match /^R: @@fileTemplate@@result_error@@.*?@@.*?@@.*?@@Posthook@@\/tmp\/persistentPosthooktest@@.*?The command .*?from postHook execution  could not be repaired$/m}
end

# We retry to ensure that the persistent one continues

describe command("rudder agent run -r") do

  its(:stdout) { should match /^R: @@fileTemplate@@result_na@@.*?@@.*?@@.*?@@Posthook@@\/tmp\/posthookTest@@.*?No post-modification needed to run$/m}

  its(:stdout) { should match /^R: @@fileTemplate@@result_error@@.*?@@.*?@@.*?@@Posthook@@\/tmp\/persistentPosthooktest@@.*?The command .*?from postHook execution  could not be repaired$/m}
end

# Resolution of the persistent posthook
describe command("mkdir /tmp/toRepairPosthook; rudder agent run -r") do

  its(:stdout) { should match /^R: @@fileTemplate@@result_na@@.*?@@.*?@@.*?@@Posthook@@\/tmp\/posthookTest@@.*?No post-modification needed to run$/m}

  its(:stdout) { should match /^R: @@fileTemplate@@result_repaired@@.*?@@.*?@@.*?@@Posthook@@\/tmp\/persistentPosthooktest@@.*?The command .*?from postHook execution  was repaired$/m}
end

describe command("rm -rf /tmp/toRepairPosthook") do
end

