require "spec_helper"
# Test with an inexistent template file, should failed
describe file("/var/rudder/tmp/templates") do
  it { should be_directory }
  it { should be_mode 750 }
  it { should be_owned_by "root" }
end

describe file("/tmp/test3.conf") do
  it { should_not exist }
end

describe command("rudder agent run -r") do
  its(:stdout) { should match /^R: @@fileTemplate@@result_error@@.*?@@.*?@@.*?@@Load Template from a file or text input@@\/tmp\/test3.conf@@.*?The copy of the file.*?from the policy server to .*? could not be repaired$/m} 
end

