def test_sshKeyDistribution(status)
  describe user('keyTesting') do
    it { should exist }
    it { should have_home_directory '/home/keyTesting' }
  end

  describe file('/home/keyTesting/.ssh') do
    it { should be_directory }
    it { should be_mode 700 }
    it { should be_owned_by 'keyTesting' }
  end

  #Testing /home/?/.ssh/authorized_keys file
  describe file('/home/keyTesting/.ssh/authorized_keys') do
    it { should be_file }
    it { should be_mode 600 }
    it { should be_owned_by 'keyTesting' }

    it { should contain 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC+D2shtMtcTHPopDymV90PTj9ORTdOimAp9GRrPoO0DgEJFvzjb2N6elWZaOHikMjSZ6L+fc9J1fFJw2wmTOu84470qNGSjUi1XmkWkMzni/c7DCWXmHdmfyGM3DAMheheu9w4FIhnelU0jIcHeB2W1gvGOEkbyphAizZvaAT5paOiVnxE9DvC+xGnJFqlyWRRvF88teeO+HDFBBqoCNnBDHtlKzAQNmPKwckns5dBmxV/oV/9fjs0MoFhvcFBs2bMJGZmQjeGNdHLzfvggEpaB8pmdhlVqKqq7DdoUfIeoS4ekzEuQEe0aaEFPF/lJjKtBYO0e//Fkc+BKpN0z5MbzN5W6oai9G6uGImSYBN8N0EsdEVm39OBHycJRtA1N0L4127LnL4OangGY6SVkN2FSDbrXcCyPUES/opuYxXQaEH8m2tKmrq7TiDPB9XFTCZ0WQJTW36t9VrTVZPMdMFcX7E1ZWDKVQ/9/k+M9G1pBLvi4iUzTBbvqvDE0A1NQDB4C1QsrcXkdqoCq3yeTdfPNcCnRGLZ2vYSkVZK4kvSYRS/691Z2tZutbsx0oKP0rrWisWLZqjIpTgT6Bf2U+lUpHMoMVmqKsSE6iRbRBubwxhwOl/BIkvG3bvgPKUcv9pAwXLMBQM/elmGrU7L5lFeUV4EnEtX4aTq+BapvF+Tvw== your_email@example.com' }

    it { should contain 'ssh-dss AAAAB3NzaC1kc3MAAACBAOJNYPOSTzd7enfH7AUgRacgDX1Nhxw7wPdxmcSzBc2dA3/fQKJN8CAMF6Vv+viiVZNRw+eZ7X22/dxuvOKg+8EudCYNul06XXTkWwSCDlPfd0SCIkq6mxbFMXIktuO+wwfn2/+oZHc/A5iXRUcqpbjxaPkq4817YwX8R0figS63AAAAFQCOKIEOiC5VPX9zpMMKw74QRo1KKQAAAIBkooEEh71dM4zCveA5+A0LgTunFTTpk0NBxrha2YSgcDieiAKbsNW6qGuTu02mB4VpoyR24zG01EWD+miR8K6BStPLWHzUys/nQadasE12D/Yx4IA0nWCBUyj9ZFgq1WokqgQnqyavWOKHnrFYZWQ3x3mQ3Z5j0kMnsLAxCbkhqQAAAIEAg1pNWuK/LTYckhf1MtrJi7Wk1MQ753lwsb6Ss8Z8RFshrlXqr94RWImfHENFEmB6aNYpQA6QHj1DpHm7FIyfytGLyD+HLcWnOKj0h3rAc9wuM8lL42BnLSFTrRkfV4B+F5l8oIvUAkATI8+FxudV79KCCI80dMx1q8PpJW4kjLI= your_email@example.com' }

    it { should contain 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILDUSoQOYhbavSUO7TlPAU+oR9Cg7h065pWnmFS4n3Sz your_email@example.com' }

    it { should contain 'ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBAAtPBLSQDtNGREb5pEizAdzMy/krvphpMH1ZuzKxYFOBLJ982L3p5Nm2t+Cz21jhSb3k7+Nk+WnE+BQzlQOkloXjwDouAafGG1R4nXNOV91e2glRYTxvOhsECOIPZsqXEysR3RatRKic9aq+PvYGNKWyRkmEGli/WXTEPJnIxn+jVsXMg== your_email@example.com' }

    it { should contain 'some options ssh-dsa AAAAB3NzaC1kc3MAAACBAM/BnbkjcAaOgE7SBQMl0e4ukCC5BYkZP/KdAMryzyWTSKIL2Vq40HiklAvqb66MRNmx3rCdQFIscjR+P3gcreTfUJVXWp73X+ulST7qzWSl0GmCmo5FIJCOjK33GSj1FycQyeAds5Uw9w3XfdZ5nI+AqPt9nFmNObvm9+WeaqT5AAAAFQD/X/2ZvJF6veB3eEvf31mJmAaGYwAAAIAmUN29yLrfMkOm7ZPb8/Hj7JgBLlzfR58o0lS2NHdHefc5BpMviMb4v/s1p1K7+SgiSxOXkpD1gaV1cIAphPwrnIlJ7nOU6OCs5Ew50nW1nJmIU3pMMLz3X73uy8D6LAOF5JO/JbTKutE6+WhE8CjYMZ0n2QttMHuQxAd3rjhUdAAAAIEAlehtI/RggAt5EaYBbV8FLJT2kGV8olkKdwGd2h1cKEmo0LfCHC0P2h23VDz+8d3oCsBt5xvQYwS71UCBgSGNJyTS/CQ5EJWdQZxchqubgSB/D79EvlxkN/FHqY2ZCpNkBrVIP4gQ/orNSEbBmpyX+gr4/FUyQZNfk1WiWwrvBzI= your_email@example.com' }

    it { should contain 'ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBCyK0YmNGuYgUTFkSZ6Vkk5VQRdpkR6OKa3GJgfTloCWKZ3ekkPblSgY+u6q16TVXD4Ns1EXU2Wciwtt/uJSeZA= your_email@example.com' }

    it { should contain 'ecdsa-sha2-nistp384 AAAAE2VjZHNhLXNoYTItbmlzdHAzODQAAAAIbmlzdHAzODQAAABhBA6XHkxw3OsUnCqtETy6G3wM4aH715rUxDCJCcmEVpsTdXW9ejG7/Ms6r4ef060EeBcdxZE50ML4DX/LMDq0/yEH7/uqios6VWZe/FCd+/szVK+0V/XTzPMlbzBb+TwK4Q== your_email@example.com' }

    it { should_not contain 'ssh-wrong AAAAE2VjZHNhLXNoYTItbmlzdHAzODQAAAAIbmlzdHAzODQAAABhBA6XHkxw3OsUnCqtETy6G3wM4aH715rUxDCJCcmEVpsTdXW9ejG7/Ms6r4ef060EeBcdxZE50ML4DX/LMDq0/yEH7/uqios6VWZe/FCd+/szVK+0V/XTzPMlbzBb+TwK4Q== your_email@example.com' }

    it { should_not contain 'ssh-wrong-remove AAAAE2VjZHNhLXNoYTItbmlzdHAzODQAAAAIbmlzdHAzODQAAABhBA6XHkxw3OsUnCqtETy6G3wM4aH715rUxDCJCcmEVpsTdXW9ejG7/Ms6r4ef060EeBcdxZE50ML4DX/LMDq0/yEH7/uqios6VWZe/FCd+/szVK+0V/XTzPMlbzBb+TwK4Q== your_email@example.com' }
  end

  #Testing reporting

  if status == "success"
    message_status = "correct"
  else
    message_status = status
  end

  test_report_present('sshKeyDistribution', "result_#{status}", 'SSH key', 'key-rsa', "SSH key \"key-rsa\" for user keyTesting was #{message_status}")
  test_report_present('sshKeyDistribution', "result_#{status}", 'SSH key', 'key-dss', "SSH key \"key-dss\" for user keyTesting was #{message_status}")
  test_report_present('sshKeyDistribution', "result_#{status}", 'SSH key', 'key-ed25519', "SSH key \"key-ed25519\" for user keyTesting was #{message_status}")
  test_report_present('sshKeyDistribution', "result_#{status}", 'SSH key', 'key-ecdsa-256', "SSH key \"key-ecdsa-256\" for user keyTesting was #{message_status}")
  test_report_present('sshKeyDistribution', "result_#{status}", 'SSH key', 'key-ecdsa-384', "SSH key \"key-ecdsa-384\" for user keyTesting was #{message_status}")
  test_report_present('sshKeyDistribution', "result_#{status}", 'SSH key', 'key-ecdsa-521', "SSH key \"key-ecdsa-521\" for user keyTesting was #{message_status}")
  test_report_present('sshKeyDistribution', "result_#{status}", 'SSH key', 'key-dsa', "SSH key \"key-dsa\" for user keyTesting was #{message_status}")
  #Failing ones
  test_report_present('sshKeyDistribution', "result_error", 'SSH key', 'key-wrong-remove', "Wrong SSH key format \"key-wrong-remove\" for user keyTesting")
  test_report_present('sshKeyDistribution', "result_error", 'SSH key', 'key-wrong-format', "Wrong SSH key format \"key-wrong-format\" for user keyTesting")
end

