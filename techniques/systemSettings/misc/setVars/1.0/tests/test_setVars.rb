require "spec_helper"
describe file("/var/rudder/resources") do
  it {should be_directory}
  it {should be_mode 755}
  its(:content) { should match // }
end

describe file("/tmp/result") do
  it {should be_file}
  its(:content) { should match /^[\s\S]*?OK[\s\S]*?OK[\s\S]*?OK[\s\S]*?\${prefix4\.str2}[\s\S]*?test seems ok[\s\S]*?Sure OK[\s\S]*?test2 is ok[\s\S]*?test4 is ok[\s\S]*?\${prefix5.dict1\[key1\]} \${prefix5\.dict1\[key2\]}[\s\S]*?\${prefix6\.dict2\[key1\]} \${prefix6\.dict2\[key2\]}[\s\S]*?\${prefix7\.dict1\[key1\]} \${prefix7\.dict1\[key2\]}$/ }
end

