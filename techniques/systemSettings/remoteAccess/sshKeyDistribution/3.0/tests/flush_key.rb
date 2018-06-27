require 'spec_helper'


def test_flushKey(status)
  describe user('flushKeyTesting') do
    it { should exist }
    it { should have_home_directory '/home/flushKeyTesting' }
  end

  describe file('/home/flushKeyTesting/.ssh') do
    it { should be_directory }
    it { should be_mode 700 }
    it { should be_owned_by 'flushKeyTesting' }
  end

  #Testing /home/?/.ssh/authorized_keys file
  describe file('/home/flushKeyTesting/.ssh/authorized_keys') do
    it { should be_file }
    it { should be_mode 600 }
    it { should be_owned_by 'flushKeyTesting' }
  end

  #Testing /home/?/.ssh/authorized_keys file
  describe file('/home/flushKeyTesting/.ssh/authorized_keys') do
    it { should be_file }
    it { should be_mode 600 }
    it { should be_owned_by 'flushKeyTesting' }

    it { should contain 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC+D2shtMtcTHPopDymV90PTj9ORTdOimAp9GRrPoO0DgEJFvzjb2N6elWZaOHikMjSZ6L+fc9J1fFJw2wmTOu84470qNGSjUi1XmkWkMzni/c7DCWXmHdmfyGM3DAMheheu9w4FIhnelU0jIcHeB2W1gvGOEkbyphAizZvaAT5paOiVnxE9DvC+xGnJFqlyWRRvF88teeO+HDFBBqoCNnBDHtlKzAQNmPKwckns5dBmxV/oV/9fjs0MoFhvcFBs2bMJGZmQjeGNdHLzfvggEpaB8pmdhlVqKqq7DdoUfIeoS4ekzEuQEe0aaEFPF/lJjKtBYO0e//Fkc+BKpN0z5MbzN5W6oai9G6uGImSYBN8N0EsdEVm39OBHycJRtA1N0L4127LnL4OangGY6SVkN2FSDbrXcCyPUES/opuYxXQaEH8m2tKmrq7TiDPB9XFTCZ0WQJTW36t9VrTVZPMdMFcX7E1ZWDKVQ/9/k+M9G1pBLvi4iUzTBbvqvDE0A1NQDB4C1QsrcXkdqoCq3yeTdfPNcCnRGLZ2vYSkVZK4kvSYRS/691Z2tZutbsx0oKP0rrWisWLZqjIpTgT6Bf2U+lUpHMoMVmqKsSE6iRbRBubwxhwOl/BIkvG3bvgPKUcv9pAwXLMBQM/elmGrU7L5lFeUV4EnEtX4aTq+BapvF+Tvw== your_email@example.com' }
  end

  if status == "success"
    message_status = "correct"
  else
    message_status = status
  end

  test_report_present('sshKeyDistribution', "result_#{status}", 'SSH key', 'Non flushing key', "SSH key \"Non flushing key\" for user flushKeyTesting was #{message_status}")
  test_report_present('sshKeyDistribution', "result_#{status}", 'SSH key', 'Flushing key', "SSH key \"Flushing key\" for user flushKeyTesting was #{message_status}")
end


test_flushKey('repaired')
