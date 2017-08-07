require 'spec_helper'

describe service('ntp') do
    it { should be_enabled }
    it { should_not be_running }
end

describe service('ssh') do
    it { should be_enabled }
    it { should be_running }
end

describe service('cron') do
    it { should_not be_enabled }
    it { should be_running }
end

describe command('/bin/cat /tmp/test_output.log') do
  its(:stdout) { should match /[\s\S]*?The service status \"stopped\" for ntp was repaired[\s\S]*?The command \/bin\/true from postHook execution  was repaired/ }
end

