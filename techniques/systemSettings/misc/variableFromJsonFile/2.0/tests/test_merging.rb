require "spec_helper"
describe file("/tmp/result") do
  it { should be_file}
  its(:content) { should match /value1\svalue2\svalue3[\s\S]+\${prefix2\.variable2\[key2\]}\svalue3[\s\S]+\${prefix3\.variable3\[key2\]}\svalue3[\s\S]+?(value1\s){3}.*\s.*\svalue6\s+value1\svalue2\svalue3\s(\$\{prefix6\.variable6\[key.\]\}\s){3}/ }
end
