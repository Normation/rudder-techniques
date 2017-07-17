require "spec_helper"
describe file("/var/rudder/tmp/templates") do
  it { should be_directory }
  it { should be_mode 750 }
  it { should be_owned_by "root" }
end

describe file("/var/rudder/tmp/templates/template1") do
  it {should be_file}
  its(:content) { should match /{{{vars.generic_variable_definition.nom1}}} habite {{{vars.generic_variable_definition.adresse1}}}/ }
end

describe file("/var/rudder/tmp/templates/_tmp_test2_conf.tpl") do
  it {should be_file}
  its(:content) { should match /{{{vars.generic_variable_definition.nom1}}} et {{{vars.generic_variable_definition.nom2}}} habitent {{{vars.generic_variable_definition.adresse1}}}/ }
end

describe file("/tmp/test1.conf") do
  it { should be_file }
  it { should be_mode 700 }
  it { should be_owned_by "root" }
  its(:content) { should match /Alice habite 1 chemin de la rue/}
end

describe file("/tmp/test2.conf") do
  it { should be_file }
  it { should be_mode 770 }
  it { should be_owned_by "root" }
  its(:content) { should match /Alice et Bob habitent 1 chemin de la rue/}
end


describe command("rm -f -R /tmp/toRepairPosthook") do
end

describe command("rm -f /tmp/test1.conf") do
end

describe command("rm -f /tmp/posthookTest") do
end

describe command("rm -f /tmp/persistentPosthooktest") do
end

describe command("rm -f /var/rudder/tmp/templates/*") do
end

