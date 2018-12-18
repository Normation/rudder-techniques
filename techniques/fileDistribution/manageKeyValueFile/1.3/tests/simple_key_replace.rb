require 'spec_helper'

describe file('/tmp/manage-key-value') do
  it { should be_file }
  it { should be_owned_by 'root' }
  its(:content) { should match /key=value/ }
end
