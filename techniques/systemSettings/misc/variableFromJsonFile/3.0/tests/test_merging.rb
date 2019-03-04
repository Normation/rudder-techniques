require "spec_helper"
describe file("/tmp/result") do
  it { should be_file}
  its(:content) { should match /value1\svalue2\svalue3\s\svalue3\s\svalue3\s\s(value1\s){3}value6\s\svalue1\svalue2\svalue3\s\svalue1\svalue1\svalue1\s*/ }
end
