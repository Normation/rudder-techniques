# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: 2021 Normation SAS

###############################################################
# Installs SSH, and checks whether it is started on boot or not.
###############################################################

bundle agent rudder_openssh_server_installation(class_prefix, service_name, params)
{
  vars:
    linux.!SuSE::
      "rudder_openssh_server_package_name"
        string => "openssh-server";
    SuSE::
      "rudder_openssh_server_package_name"
        string => "openssh";

    any::
      "c_rudder_openssh_server_package_name" string => canonify("${rudder_openssh_server_package_name}");

  methods:
    linux::
      "any" usebundle => package_present("${rudder_openssh_server_package_name}", "", "", "");
}

bundle agent rudder_openssh_server_installation_reporting(class_prefix, service_name, params)
{
  methods:
      "any" usebundle => rudder_common_reports_generic("${service_name}", "package_present_${rudder_openssh_server_installation.c_rudder_openssh_server_package_name}", "${${params}[report]}", "SSH installation", "None", "The ${service_name} package installation");

    !linux::
      "any" usebundle  => rudder_common_report("${service_name}", "result_success", "${${params}[report]}", "SSH installation", "None", "Support to check if ${service_name} is installed not available on this platform");

}

# This bundle is common because it defines a class that we reuse in the configuration part,
# when configuring the service, to not configure the service if the binary is not there
bundle common rudder_openssh_server_check_ssh_installation
{
  classes:
      # Security : if not there, SSH too, so do not bother anymore
      # I cannot use the class_prefix in the class definition, because it is a bundle common
      # and for some reason, CFEngine complains about it not being canonified
      "rudder_openssh_server_binary_present"
        expression => fileexists("/usr/sbin/sshd");
}

bundle agent rudder_openssh_server_check_ssh_installation_reporting(class_prefix, service_name, params)
{
  methods:
    # Make a report about the lack of proper sshd binary
    "any"
      usebundle  => rudder_common_report("${service_name}", "result_error", "${${params}[report]}", "SSH installation", "None", "The ${service_name} is not installed, although it should have been"),
      ifvarclass => "!${class_prefix}_binary_present";
}

