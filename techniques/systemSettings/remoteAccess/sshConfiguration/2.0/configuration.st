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

bundle agent rudder_openssh_server_configuration(service_name)
{

  vars:

      # Generic variables
      # This is the file to edit
      "rudder_openssh_server_config"
        string => "&OPENSSH_SERVER_CONFFILE&";

      "sshPorts"
        slist => {&OPENSSH_SERVER_PORTS: { "&it&" };separator=", "&};

    # OS Specific parameters
    debian::
      "rudder_openssh_server_startup_init_name"
        string => "/etc/init.d/ssh";
      "rudder_openssh_server_startup_init_activation_command"
        string => "/usr/sbin/update-rc.d -f ssh remove \&\& /usr/sbin/update-rc.d ssh defaults";
    SuSE::
      "rudder_openssh_server_startup_script_regex"
        string => "/etc/init.d/rc3.d/S.*ssh.*";
    (debian|redhat)::
      "rudder_openssh_server_startup_script_regex"
        string => "/etc/rc2.d/S.*ssh.*";
    (SuSE|redhat)::
      "rudder_openssh_server_startup_init_name"
        string => "/etc/init.d/sshd";
      "rudder_openssh_server_startup_init_activation_command"
        string => "/sbin/chkconfig --del sshd \&\& /sbin/chkconfig --add sshd";

    # Class specific parameters
    rudder_openssh_server_address_family_edit::
      "sshd[AddressFamily]"
        string => "&OPENSSH_SERVER_ADDRESSFAMILY&";

    rudder_openssh_server_protocol_edit::
      "sshd[Protocol]"
        string => "&OPENSSH_SERVER_PROTOCOL&";

    rudder_openssh_server_max_sessions_edit.!redhat.!SuSE::
      "sshd[MaxSessions]"
        string => "&OPENSSH_SERVER_MAXSESSIONS&";

    rudder_openssh_server_challenge_response_authentication_edit::
      "sshd[ChallengeResponseAuthentication]"
        string => "&OPENSSH_SERVER_CHALLENGERESPONSEAUTHENTICATION&";

    rudder_openssh_server_password_authentication_edit::
      "sshd[PasswordAuthentication]"
        string => "&OPENSSH_SERVER_PASSWORDAUTHENTICATION&";

    rudder_openssh_server_pubkey_authentication_edit::
      "sshd[PubkeyAuthentication]"
        string => "&OPENSSH_SERVER_PUBKEYAUTHENTICATION&";

    rudder_openssh_server_permit_empty_passwords_edit::
      "sshd[PermitEmptyPasswords]"
        string => "&OPENSSH_SERVER_PERMITEMPTYPASSWORDS&";

    rudder_openssh_server_permit_root_login_edit::
      "sshd[PermitRootLogin]"
        string => "&OPENSSH_SERVER_PERMITROOTLOGIN&";

    rudder_openssh_server_max_auth_tries_edit::
      "sshd[MaxAuthTries]"
        string => "&OPENSSH_SERVER_MAXAUTHTRIES&";

    rudder_openssh_server_login_grace_time_edit::
      "sshd[LoginGraceTime]"
        string => "&OPENSSH_SERVER_LOGINGRACETIME&";

    rudder_openssh_server_use_privilege_separation_edit::
      "sshd[UsePrivilegeSeparation]"
        string => "&OPENSSH_SERVER_USEPRIVILEGESEPARATION&";

    rudder_openssh_server_strict_modes_edit::
      "sshd[StrictModes]"
        string => "&OPENSSH_SERVER_STRICTMODES&";

    rudder_openssh_server_allow_agent_forwarding_edit.!redhat.!SuSE::
      "sshd[AllowAgentForwarding]"
        string => "&OPENSSH_SERVER_ALLOWAGENTFORWARDING&";

    rudder_openssh_server_allow_tcp_forwarding_edit::
      "sshd[AllowTcpForwarding]"
        string => "&OPENSSH_SERVER_ALLOWTCPFORWARDING&";

    rudder_openssh_server_permit_tunnel_edit.!SuSE::
      "sshd[PermitTunnel]"
        string => "&OPENSSH_SERVER_PERMITTUNNEL&";

    rudder_openssh_server_permit_user_environment_edit::
      "sshd[PermitUserEnvironment]"
        string => "&OPENSSH_SERVER_PERMITUSERENVIRONMENT&";

    rudder_openssh_server_x11_forwarding_edit::
      "sshd[X11Forwarding]"
        string => "&OPENSSH_SERVER_X11FORWARDING&";

    rudder_openssh_server_print_lastlog_edit::
      "sshd[PrintLastLog]"
        string => "&OPENSSH_SERVER_PRINTLASTLOG&";

    rudder_openssh_server_printmotd_edit::
      "sshd[PrintMotd]"
        string => "&OPENSSH_SERVER_PRINTMOTD&";

    rudder_openssh_server_tcp_keepalive_edit::
      "sshd[TCPKeepAlive]"
        string => "&OPENSSH_SERVER_TCPKEEPALIVE&";

    rudder_openssh_server_log_level_edit::
      "sshd[LogLevel]"
        string => "&OPENSSH_SERVER_LOGLEVEL&";

    rudder_openssh_server_syslog_facility_edit::
      "sshd[SyslogFacility]"
        string => "&OPENSSH_SERVER_SYSLOGFACILITY&";

  classes:
    # Security : if not there, SSH too, so don't bother anymore
      "rudder_openssh_server_binary_present"
        expression => fileexists("/usr/sbin/sshd");

    # AddressFamily edition ?
      "rudder_openssh_server_address_family_edit"
        not => strcmp("&OPENSSH_SERVER_ADDRESSFAMILY&","dontchange");

    # Ports edition ?
      "rudder_openssh_server_ports_edit"
        not => strcmp("&OPENSSH_SERVER_PORTSEDIT&","false");

    # Protocol edition ?
      "rudder_openssh_server_protocol_edit"
        not => strcmp("&OPENSSH_SERVER_PROTOCOL&","dontchange");

    # MaxSessions edition ?
      "rudder_openssh_server_max_sessions_edit"
        not => strcmp("&OPENSSH_SERVER_MAXSESSIONS&","dontchange");

    # ChallengeResponseAuthentication edition ?
      "rudder_openssh_server_challenge_response_authentication_edit"
        not => strcmp("&OPENSSH_SERVER_CHALLENGERESPONSEAUTHENTICATION&","dontchange");

    #  PasswordAuthentication edition ?
      "rudder_openssh_server_password_authentication_edit"
        not => strcmp("&OPENSSH_SERVER_PASSWORDAUTHENTICATION&","dontchange");

    # PubkeyAuthentication edition ?
      "rudder_openssh_server_pubkey_authentication_edit"
        not => strcmp("&OPENSSH_SERVER_PUBKEYAUTHENTICATION&","dontchange");

    # PermitEmptyPasswords edition ?
      "rudder_openssh_server_permit_empty_passwords_edit"
        not => strcmp("&OPENSSH_SERVER_PERMITEMPTYPASSWORDS&","dontchange");

    # PermitRootLogin edition ?
      "rudder_openssh_server_permit_root_login_edit"
        not => strcmp("&OPENSSH_SERVER_PERMITROOTLOGIN&","dontchange");

    # MaxAuthTries edition ?
      "rudder_openssh_server_max_auth_tries_edit"
        not => strcmp("&OPENSSH_SERVER_MAXAUTHTRIES&","dontchange");

    # LoginGraceTime edition ?
      "rudder_openssh_server_login_grace_time_edit"
        not => strcmp("&OPENSSH_SERVER_LOGINGRACETIME&","dontchange");

    # UsePrivilegeSeparation edition ?
      "rudder_openssh_server_use_privilege_separation_edit"
        not => strcmp("&OPENSSH_SERVER_USEPRIVILEGESEPARATION&","dontchange");

    # StrictModes edition ?
      "rudder_openssh_server_strict_modes_edit"
        not => strcmp("&OPENSSH_SERVER_STRICTMODES&","dontchange");

    # AllowAgentForwarding edition ?
      "rudder_openssh_server_allow_agent_forwarding_edit"
        not => strcmp("&OPENSSH_SERVER_ALLOWAGENTFORWARDING&","dontchange");

    # AllowTcpForwarding edition ?
      "rudder_openssh_server_allow_tcp_forwarding_edit"
        not => strcmp("&OPENSSH_SERVER_ALLOWTCPFORWARDING&","dontchange");

    # PermitTunnel edition ?
      "rudder_openssh_server_permit_tunnel_edit"
        not => strcmp("&OPENSSH_SERVER_PERMITTUNNEL&","dontchange");

    # PermitUserEnvironment edition ?
      "rudder_openssh_server_permit_user_environment_edit"
        not => strcmp("&OPENSSH_SERVER_PERMITUSERENVIRONMENT&","dontchange");

    # X11Forwarding edition ?
      "rudder_openssh_server_x11_forwarding_edit"
        not => strcmp("&OPENSSH_SERVER_X11FORWARDING&","dontchange");

    # PrintLastLog edition ?
      "rudder_openssh_server_print_lastlog_edit"
        not => strcmp("&OPENSSH_SERVER_PRINTLASTLOG&","dontchange");

    # PrintMotd edition ?
      "rudder_openssh_server_printmotd_edit"
        not => strcmp("&OPENSSH_SERVER_PRINTMOTD&","dontchange");

    # TCPKeepAlive edition ?
      "rudder_openssh_server_tcp_keepalive_edit"
        not => strcmp("&OPENSSH_SERVER_TCPKEEPALIVE&","dontchange");

    # LogLevel edition ?
      "rudder_openssh_server_log_level_edit"
        not => strcmp("&OPENSSH_SERVER_LOGLEVEL&","dontchange");

    # SyslogFacility edition ?
      "rudder_openssh_server_syslog_facility_edit"
        not => strcmp("&OPENSSH_SERVER_SYSLOGFACILITY&","dontchange");

  files:
    linux::
      "${rudder_openssh_server_config}"
        edit_line => rudder_common_disclaimer,
        comment   => "Insert the standard Rudder disclaimer in the OpenSSHd configuration file";

    (debian|redhat|SuSE)::
      # This promise will detect if there is a startup script for OpenSSH enabled on the system,
      # and set a class if there is one indeed.
      "${rudder_openssh_server_startup_script_regex}"
        create  => "true",
        action  => WarnOnly,
        classes => if_else("rudder_openssh_server_activated_on_boot_kept", "rudder_openssh_server_activation_detection_failed");

    (debian|redhat|SuSE).rudder_openssh_server_ports_edit::
      "${rudder_openssh_server_config}"
        edit_line => rudder_openssh_server_port_configuration("@{this.sshPorts}"),
        classes   => rudder_common_classes("rudder_openssh_server_ports"),
        comment   => "Edit the OpenSSH listening ports in the configuration file";

    (debian|redhat|SuSE)::
      "${rudder_openssh_server_config}"
        edit_line => set_config_values("rudder_openssh_server_configuration.sshd"),
        classes   => rudder_common_classes("rudder_openssh_server_configuration"),
        comment   => "Edit the OpenSSH configuration file";

  methods:
    # Here, we will define reports for elements which only have a local visibility (like the sshd binary detection).
      "any"
        usebundle  => rudder_common_report("${service_name}", "result_error", "&TRACKINGKEY&", "SSH installation", "None", "The ${service_name} is not installed, although it should have been"),
        ifvarclass => "!rudder_openssh_server_binary_present";

    # Warn about features that are not implemented on all platforms
      "any"
        usebundle  => rudder_common_report("${service_name}", "log_warn", "&TRACKINGKEY&", "SSH configuration", "None", "The ${service_name} parameter \"agent forwarding\" isn't implemented on Red Hat/CentOS/SuSE"),
        ifvarclass => "rudder_openssh_server_allow_agent_forwarding_edit.(redhat|SuSE)";
      "any"
        usebundle  => rudder_common_report("${service_name}", "log_warn", "&TRACKINGKEY&", "SSH configuration", "None", "The ${service_name} parameter \"max sessions\" isn't implemented on Red Hat/CentOS/SuSE"),
        ifvarclass => "rudder_openssh_server_max_sessions_edit.(redhat|SuSE)";
      "any"
        usebundle  => rudder_common_report("${service_name}", "log_warn", "&TRACKINGKEY&", "SSH configuration", "None", "The ${service_name} parameter \"permit tunnel\" isn't implemented on SuSE"),
        ifvarclass => "rudder_openssh_server_permit_tunnel_edit.(redhat|SuSE)";

  processes:
    (debian|redhat|SuSE)::
      "/usr/sbin/sshd"
        restart_class => "rudder_openssh_server_down",
        comment       => "Checking whether OpenSSH is up or not";

  commands:
    (debian|redhat|SuSE).(rudder_openssh_server_ports_repaired|rudder_openssh_server_configuration_repaired|rudder_openssh_server_down)::
      "${rudder_openssh_server_startup_init_name}"
        args    => "restart",
        classes => cf2_if_else("rudder_openssh_server_daemon_restart_repaired", "rudder_openssh_server_daemon_restart_error"),
        comment => "Restarting the OpenSSH server daemon";

    (debian|redhat|SuSE).!rudder_openssh_server_activated_on_boot_kept.rudder_openssh_server_binary_present::
      "${rudder_openssh_server_startup_init_activation_command}"
        contain => in_shell,
        classes => cf2_if_else("rudder_openssh_server_activated_on_boot_repaired", "rudder_openssh_server_activated_on_boot_error"),
        comment => "Adding the OpenSSH daemon to the startup scripts";
}

bundle agent rudder_openssh_server_configuration_reporting(service_name)
{
  methods:
    # SSH configuration file
      "any" usebundle => rudder_common_reports_generic("OpenSSH server", "rudder_openssh_server_ports", "&TRACKINGKEY&", "SSH port configuration", "None", "The ${service_name} port configuration");
      "any" usebundle => rudder_common_reports_generic("OpenSSH server", "rudder_openssh_server_configuration", "&TRACKINGKEY&", "SSH configuration", "None", "The ${service_name} configuration");
    # SSH start on boot
      "any" usebundle => rudder_common_reports_generic("OpenSSH server", "rudder_openssh_server_activated_on_boot", "&TRACKINGKEY&", "SSH start at boot", "None", "The ${service_name} boot starting configuration");

      "any"
        usebundle  => rudder_common_report("${service_name}", "log_repaired", "&TRACKINGKEY&", "SSH process", "None", "The ${service_name} was not running, trying to restart..."),
        ifvarclass => "rudder_openssh_server_down";

      "any"
        usebundle  => rudder_common_report("${service_name}", "result_success", "&TRACKINGKEY&", "SSH process", "None", "The ${service_name} service is running"),
        ifvarclass => "!rudder_openssh_server_down.!rudder_openssh_server_daemon_restart_repaired.!rudder_openssh_server_daemon_restart_error";

      "any"
        usebundle  => rudder_common_report("${service_name}", "result_repaired", "&TRACKINGKEY&", "SSH process", "None", "Restarted the ${service_name}"),
        ifvarclass => "rudder_openssh_server_daemon_restart_repaired.!rudder_openssh_server_daemon_restart_error";

      "any"
        usebundle  => rudder_common_report("${service_name}", "result_error", "&TRACKINGKEY&", "SSH process", "None", "Could not restart the ${service_name}"),
        ifvarclass => "rudder_openssh_server_daemon_restart_error";

      "any"
        usebundle  => rudder_common_report("${service_name}", "log_info", "&TRACKINGKEY&", "SSH start at boot", "None", "Error checking if the ${service_name} is set to be started on boot"),
        ifvarclass => "rudder_openssh_server_activation_detection_failed";
}
