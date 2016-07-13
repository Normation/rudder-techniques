require 'spec_helper'

describe file('/tmp/simple_content_enforce') do
  it { should be_file }
  it { should be_owned_by 'root' }
  its(:content) { should match /contenttest/ }
end
