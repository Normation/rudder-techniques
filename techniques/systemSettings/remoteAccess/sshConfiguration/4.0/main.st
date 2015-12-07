#####################################################################################
# Copyright 2011-2013 Normation SAS
#####################################################################################
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, Version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#####################################################################################

#####################################################################################
# Configure the OpenSSH server 
#####################################################################################
# If ssh is not installed, install it (linux)
# Change the server configuration, and restart the daemon
# if the configuration changed
# WARNING : You may inadvertently create conflict with processManagement !
# This promise restarts sshd if not there, which could be done by processManagement too.
# dontchange is a generic value to prohibit the edition of the value
#####################################################################################

bundle agent rudder_openssh_server_configuration(class_prefix, service_name, params) {

  vars:

    # OS Specific parameters

    debian::

      "rudder_openssh_server_startup_command"
        string => "/etc/init.d/ssh restart";

      "rudder_openssh_server_startup_activation_command"
        string => "/usr/sbin/update-rc.d -f ssh remove \&\& /usr/sbin/update-rc.d ssh defaults";

    SuSE::
      "rudder_openssh_server_startup_script_regex"
        string => "/etc/init.d/rc3.d/S.*ssh.*";

    (debian|redhat)::
      "rudder_openssh_server_startup_script_regex"
        string => "/etc/rc2.d/S.*ssh.*";

    (SuSE|redhat)::
      "rudder_openssh_server_startup_command"
        string => "/etc/init.d/sshd restart";
      "rudder_openssh_server_startup_activation_command"
        string => "/sbin/chkconfig --del sshd \&\& /sbin/chkconfig --add sshd";

    aix::

      "rudder_openssh_server_startup_command"
        string => "/usr/bin/stopsrc -s sshd \&\& until /usr/bin/lssrc -s sshd | ${paths.grep} -q inoperative; do ${paths.perl} -e 'select(undef,undef,undef,.25)'; done; /usr/bin/startsrc -s sshd";

      # Here are the details about the arguments given to mkssys:
      ## -p: Specifies the absolute path to the subsystem executable program.
      ## -s: Specifies a name that uniquely identifies the subsystem.
      ## -G: Specifies that the subsystem belongs to the Group specified.
      ## -u: Specifies the user ID for the subsystem.
      ## -S: Specifies that the subsystem uses the signals communication method.
      ## -f: Specifies the signal sent to the subsystem when a forced stop of the subsystem is requested.
      ## -n: Specifies the signal sent to the subsystem when a normal stop of the subsystem is requested.
      ## -a: Specifies any arguments that must be passed to the command, started as the subsystem.
      ## -R: Specifies that the subsystem is restarted if the subsystem stops abnormally.
      ## -Q: Specifies that multiple instances of the subsystem are not allowed to run at the same time.
      "rudder_openssh_server_startup_activation_command"
        string => "/usr/bin/mkssys -p /usr/sbin/sshd -s sshd -G ssh -u 0 -S -f 9 -n 15 -a '-D' -R -Q >/dev/null ; /usr/sbin/mkitab 'sshd:2:once:/usr/bin/startsrc -s sshd'";

    any::
      # Copy the list of Ports in the local bundle
      # This is mandatory because we cannot use remote slist in CFEngine 3.2
      "rudder_openssh_server_config_ports"
        slist => { "@{${params}[sshd_config_ports]}" };

  classes:

      "rudder_openssh_server_ports_edit"
        not   => strcmp("${${params}[edit_ports]}","false"),
        scope => "namespace";

    aix::
      # lssrc is clever, and kept in a cache the entry if the daemon is still running, so grepping
      # /etc/inittab instead, to be sure that service is defined at boot
      # Adding scope namespace so that the class is available for the reporting also
      "${class_prefix}_activated_on_boot_kept"
        expression => returnszero("/usr/bin/grep -q -E ^sshd: /etc/inittab", "useshell"),
        scope      => "namespace";

  files:

      "${${params}[sshd_config_file]}"
        edit_line => rudder_common_disclaimer,
        comment   => "Insert the standard Rudder disclaimer in the OpenSSHd configuration file";

    (debian|redhat|SuSE)::
      # This promise will detect if there is a startup script for OpenSSH enabled on the system,
      # and set a class if there is one indeed.
      "${rudder_openssh_server_startup_script_regex}"
        create  => "true",
        action  => WarnOnly,
        classes => if_else("${class_prefix}_activated_on_boot_kept", "${class_prefix}_activation_detection_failed");

    rudder_openssh_server_ports_edit::
      "${${params}[sshd_config_file]}"
        edit_line => rudder_openssh_server_port_configuration("@{this.rudder_openssh_server_config_ports}"),
        classes   => rudder_common_classes("${class_prefix}_ports"),
        comment   => "Edit the OpenSSH listening ports in the configuration file";

    any::
      "${${params}[sshd_config_file]}"
        edit_line => set_config_values("${params}[config]"),
        classes   => rudder_common_classes("${class_prefix}_configuration"),
        comment   => "Edit the OpenSSH configuration file";

  methods:

    !aix.debian::

      "bootstart_ssh" usebundle => service_ensure_started_at_boot("ssh"),
                     ifvarclass => "${class_prefix}_binary_present";

      "restart_ssh"   usebundle => service_restart("ssh"),
                     ifvarclass => "${class_prefix}_ports_repaired|${class_prefix}_configuration_repaired|${class_prefix}_down";
    !aix.!debian::

      "bootstart_ssh" usebundle => service_ensure_started_at_boot("sshd"),
                     ifvarclass => "${class_prefix}_binary_present";

      "restart_ssh"   usebundle => service_restart("sshd"),
                     ifvarclass => "${class_prefix}_ports_repaired|${class_prefix}_configuration_repaired|${class_prefix}_down";

    !aix::

      "any"
        usebundle  => rudder_common_report("${service_name}", "log_repaired", "${${params}[report]}", "SSH process", "None", "The ${service_name} was not running, trying to restart..."),
        ifvarclass => "${class_prefix}_down";

      "any"
        usebundle  => rudder_common_report("${service_name}", "result_success", "${${params}[report]}", "SSH process", "None", "The ${service_name} service is running"),
        ifvarclass => "!${class_prefix}_down.!(service_restart_ssh_reached|service_restart_sshd_reached)";

      "any"
        usebundle  => rudder_common_report("${service_name}", "result_repaired", "${${params}[report]}", "SSH process", "None", "Restarted the ${service_name}"),
        ifvarclass => "service_restart_ssh_ok|service_restart_sshd_ok";

      "any"
        usebundle  => rudder_common_report("${service_name}", "result_error", "${${params}[report]}", "SSH process", "None", "Could not restart the ${service_name}"),
        ifvarclass => "service_restart_ssh_not_ok|service_restart_sshd_not_ok";

      "any"
        usebundle  => rudder_common_report("${service_name}", "result_success", "${${params}[report]}", "SSH start at boot", "None", "OpenSSH is starting on boot as required"),
        ifvarclass => "service_ensure_started_at_boot_ssh_ok|service_ensure_started_at_boot_sshd_ok";

      "any"
        usebundle  => rudder_common_report("${service_name}", "result_repaired", "${${params}[report]}", "SSH start at boot", "None", "OpenSSH has been set to start on boot"),
        ifvarclass => "service_ensure_started_at_boot_ssh_repaired|service_ensure_started_at_boot_sshd_repaired";

      "any"
        usebundle  => rudder_common_report("${service_name}", "result_error", "${${params}[report]}", "SSH start at boot", "None", "Can not set OpenSSH to start on boot"),
        ifvarclass => "service_ensure_started_at_boot_ssh_not_ok|service_ensure_started_at_boot_sshd_not_ok";

  processes:

      "/usr/sbin/sshd"
        restart_class => "${class_prefix}_down",
        comment       => "Checking whether OpenSSH is up or not";

  commands:

    aix::

      "${rudder_openssh_server_startup_command}"
        classes    => cf2_if_else("${class_prefix}_daemon_restart_repaired", "${class_prefix}_daemon_restart_error"),
        ifvarclass => "${class_prefix}_ports_repaired|${class_prefix}_configuration_repaired|${class_prefix}_down",
        comment    => "Restarting the OpenSSH server daemon";

      "${rudder_openssh_server_startup_activation_command}"
        contain => in_shell,
        classes => cf2_if_else("${class_prefix}_activated_on_boot_repaired", "${class_prefix}_activated_on_boot_error"),
        ifvarclass => "(!${class_prefix}_activated_on_boot_kept).${class_prefix}_binary_present",
        comment => "Adding the OpenSSH daemon to the startup scripts";

}

bundle agent rudder_openssh_server_configuration_reporting(class_prefix, service_name, params)
{
  methods:
      # Port edition defined
      "any" usebundle => rudder_common_reports_generic("${service_name}", "${class_prefix}_ports", "${${params}[report]}", "SSH port configuration", "None", "The ${service_name} port configuration"),
        ifvarclass => "${class_prefix}_ports_edit";
      # When no port edition is defined
      "any" 
        usebundle  => rudder_common_report("${service_name}", "result_success", "${${params}[report]}", "SSH port configuration", "None", "The ${service_name} port configuration is not set to be edited"),
        ifvarclass => "!${class_prefix}_ports_edit";

      # SSH configuration
      "any" usebundle => rudder_common_reports_generic("${service_name}", "${class_prefix}_configuration", "${${params}[report]}", "SSH configuration", "None", "The ${service_name} configuration");

    aix::

      # SSH start on boot
      "any" usebundle => rudder_common_reports_generic("${service_name}", "${class_prefix}_activated_on_boot", "${${params}[report]}", "SSH start at boot", "None", "The ${service_name} boot starting configuration");

      "any"
        usebundle  => rudder_common_report("${service_name}", "log_repaired", "${${params}[report]}", "SSH process", "None", "The ${service_name} was not running, trying to restart..."),
        ifvarclass => "${class_prefix}_down";

      "any"
        usebundle  => rudder_common_report("${service_name}", "result_success", "${${params}[report]}", "SSH process", "None", "The ${service_name} service is running"),
        ifvarclass => "!${class_prefix}_down.!${class_prefix}_daemon_restart_repaired.!${class_prefix}_daemon_restart_error";

      "any"
        usebundle  => rudder_common_report("${service_name}", "result_repaired", "${${params}[report]}", "SSH process", "None", "Restarted the ${service_name}"),
        ifvarclass => "${class_prefix}_daemon_restart_repaired.!${class_prefix}_daemon_restart_error";

      "any"
        usebundle  => rudder_common_report("${service_name}", "result_error", "${${params}[report]}", "SSH process", "None", "Could not restart the ${service_name}"),
        ifvarclass => "${class_prefix}_daemon_restart_error";

      "any"
        usebundle  => rudder_common_report("${service_name}", "log_info", "${${params}[report]}", "SSH start at boot", "None", "Error checking if the ${service_name} is set to be started on boot"),
        ifvarclass => "${class_prefix}_activation_detection_failed";      

}
