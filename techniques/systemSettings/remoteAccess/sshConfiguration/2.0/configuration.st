#####################################################################################
# Copyright 2011 Normation SAS
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

bundle agent rudder_openssh_server_configuration {

  classes:

    # Security : if not there, SSH too, so don't bother anymore
    "rudder_openssh_server_initd_present" expression => fileexists("/usr/sbin/sshd");

    # AddressFamily edition ?
    "rudder_openssh_server_addressfamily_edit" not => strcmp("&OPENSSH_SERVER_ADDRESSFAMILY&","dontchange");

    # Ports edition ?
    "rudder_openssh_server_ports_edit" not => strcmp("&OPENSSH_SERVER_PORTSEDIT&","false");

    # Protocol edition ?
    "rudder_openssh_server_protocol_edit" not => strcmp("&OPENSSH_SERVER_PROTOCOL&","dontchange");

    # MaxSessions edition ?
    "rudder_openssh_server_maxsessions_edit" not => strcmp("&OPENSSH_SERVER_MAXSESSIONS&","dontchange");

    # ChallengeResponseAuthentication edition ?
    "rudder_openssh_server_challengeresponseauthentication_edit" not => strcmp("&OPENSSH_SERVER_CHALLENGERESPONSEAUTHENTICATION&","dontchange");

    #  PasswordAuthentication edition ?
    "rudder_openssh_server_passwordauthentication_edit" not => strcmp("&OPENSSH_SERVER_PASSWORDAUTHENTICATION&","dontchange");

    # PubkeyAuthentication edition ?
    "rudder_openssh_server_pubkeyauthentication_edit" not => strcmp("&OPENSSH_SERVER_PUBKEYAUTHENTICATION&","dontchange");

    # PermitEmptyPasswords edition ?
    "rudder_openssh_server_permitemptypasswords_edit" not => strcmp("&OPENSSH_SERVER_PERMITEMPTYPASSWORDS&","dontchange");

    # PermitRootLogin edition ?
    "rudder_openssh_server_permitrootlogin_edit" not => strcmp("&OPENSSH_SERVER_PERMITROOTLOGIN&","dontchange");

    # MaxAuthTries edition ?
    "rudder_openssh_server_maxauthtries_edit" not => strcmp("&OPENSSH_SERVER_MAXAUTHTRIES&","dontchange");

    # LoginGraceTime edition ?
    "rudder_openssh_server_logingracetime_edit" not => strcmp("&OPENSSH_SERVER_LOGINGRACETIME&","dontchange");

    # UsePrivilegeSeparation edition ?
    "rudder_openssh_server_useprivilegeseparation_edit" not => strcmp("&OPENSSH_SERVER_USEPRIVILEGESEPARATION&","dontchange");

    # StrictModes edition ?
    "rudder_openssh_server_strictmodes_edit" not => strcmp("&OPENSSH_SERVER_STRICTMODES&","dontchange");

    # AllowAgentForwarding edition ?
    "rudder_openssh_server_allowagentforwarding_edit" not => strcmp("&OPENSSH_SERVER_ALLOWAGENTFORWARDING&","dontchange");

    # AllowTcpForwarding edition ?
    "rudder_openssh_server_allowtcpforwarding_edit" not => strcmp("&OPENSSH_SERVER_ALLOWTCPFORWARDING&","dontchange");

    # PermitTunnel edition ?
    "rudder_openssh_server_permittunnel_edit" not => strcmp("&OPENSSH_SERVER_PERMITTUNNEL&","dontchange");

    # PermitUserEnvironment edition ?
    "rudder_openssh_server_permituserenvironment_edit" not => strcmp("&OPENSSH_SERVER_PERMITUSERENVIRONMENT&","dontchange");

    # X11Forwarding edition ?
    "rudder_openssh_server_x11forwarding_edit" not => strcmp("&OPENSSH_SERVER_X11FORWARDING&","dontchange");

    # PrintLastLog edition ?
    "rudder_openssh_server_printlastlog_edit" not => strcmp("&OPENSSH_SERVER_PRINTLASTLOG&","dontchange");

    # PrintMotd edition ?
    "rudder_openssh_server_printmotd_edit" not => strcmp("&OPENSSH_SERVER_PRINTMOTD&","dontchange");

    # TCPKeepAlive edition ?
    "rudder_openssh_server_tcpkeepalive_edit" not => strcmp("&OPENSSH_SERVER_TCPKEEPALIVE&","dontchange");

    # LogLevel edition ?
    "rudder_openssh_server_loglevel_edit" not => strcmp("&OPENSSH_SERVER_LOGLEVEL&","dontchange");

    # SyslogFacility edition ?
    "rudder_openssh_server_syslogfacility_edit" not => strcmp("&OPENSSH_SERVER_SYSLOGFACILITY&","dontchange");

  vars:

    # This is the file to edit
    "rudder_openssh_server_config" string => "&OPENSSH_SERVER_CONFFILE&";

    "sshPorts"  slist => {&OPENSSH_SERVER_PORTS: { "&it&" };separator=", "&};

    rudder_openssh_server_addressfamily_edit::

      "sshd[AddressFamily]" string => "&OPENSSH_SERVER_ADDRESSFAMILY&";

    rudder_openssh_server_protocol_edit::

      "sshd[Protocol]" string => "&OPENSSH_SERVER_PROTOCOL&";

    rudder_openssh_server_maxsessions_edit.!redhat.!SuSE::

      "sshd[MaxSessions]" string => "&OPENSSH_SERVER_MAXSESSIONS&";

    rudder_openssh_server_challengeresponseauthentication_edit::

      "sshd[ChallengeResponseAuthentication]" string => "&OPENSSH_SERVER_CHALLENGERESPONSEAUTHENTICATION&";

    rudder_openssh_server_passwordauthentication_edit::

      "sshd[PasswordAuthentication]" string => "&OPENSSH_SERVER_PASSWORDAUTHENTICATION&";

    rudder_openssh_server_pubkeyauthentication_edit::

      "sshd[PubkeyAuthentication]" string => "&OPENSSH_SERVER_PUBKEYAUTHENTICATION&";

    rudder_openssh_server_permitemptypasswords_edit::

      "sshd[PermitEmptyPasswords]" string => "&OPENSSH_SERVER_PERMITEMPTYPASSWORDS&";

    rudder_openssh_server_permitrootlogin_edit::

      "sshd[PermitRootLogin]" string => "&OPENSSH_SERVER_PERMITROOTLOGIN&";

    rudder_openssh_server_maxauthtries_edit::

      "sshd[MaxAuthTries]" string => "&OPENSSH_SERVER_MAXAUTHTRIES&";

    rudder_openssh_server_logingracetime_edit::

      "sshd[LoginGraceTime]" string => "&OPENSSH_SERVER_LOGINGRACETIME&";

    rudder_openssh_server_useprivilegeseparation_edit::

      "sshd[UsePrivilegeSeparation]" string => "&OPENSSH_SERVER_USEPRIVILEGESEPARATION&";

    rudder_openssh_server_strictmodes_edit::

      "sshd[StrictModes]" string => "&OPENSSH_SERVER_STRICTMODES&";

    rudder_openssh_server_allowagentforwarding_edit.!redhat.!SuSE::

      "sshd[AllowAgentForwarding]" string => "&OPENSSH_SERVER_ALLOWAGENTFORWARDING&";

    rudder_openssh_server_allowtcpforwarding_edit::

      "sshd[AllowTcpForwarding]" string => "&OPENSSH_SERVER_ALLOWTCPFORWARDING&";

    rudder_openssh_server_permittunnel_edit.!SuSE::

      "sshd[PermitTunnel]" string => "&OPENSSH_SERVER_PERMITTUNNEL&";

    rudder_openssh_server_permituserenvironment_edit::

      "sshd[PermitUserEnvironment]" string => "&OPENSSH_SERVER_PERMITUSERENVIRONMENT&";

    rudder_openssh_server_x11forwarding_edit::

      "sshd[X11Forwarding]" string => "&OPENSSH_SERVER_X11FORWARDING&";

    rudder_openssh_server_printlastlog_edit::

      "sshd[PrintLastLog]" string => "&OPENSSH_SERVER_PRINTLASTLOG&";

    rudder_openssh_server_printmotd_edit::

      "sshd[PrintMotd]" string => "&OPENSSH_SERVER_PRINTMOTD&";

    rudder_openssh_server_tcpkeepalive_edit::

      "sshd[TCPKeepAlive]" string => "&OPENSSH_SERVER_TCPKEEPALIVE&";

    rudder_openssh_server_loglevel_edit::

      "sshd[LogLevel]" string => "&OPENSSH_SERVER_LOGLEVEL&";

    rudder_openssh_server_syslogfacility_edit::

      "sshd[SyslogFacility]" string => "&OPENSSH_SERVER_SYSLOGFACILITY&";

  processes:

    (debian|redhat|SuSE)::

      "/usr/sbin/sshd"
        restart_class => "rudder_openssh_server_down",
        comment => "Ensuring ssh is up";

  commands:

    debian.(rudder_openssh_server_tier1_validated|rudder_openssh_server_tier2_validated|rudder_openssh_server_down)::
      "/etc/init.d/ssh"
        args => "restart",
        classes => cf2_if_else("rudder_openssh_server_restarted", "cant_restart_ssh"),
        comment => "restarting ssh";

    (redhat|SuSE).(rudder_openssh_server_tier1_validated|rudder_openssh_server_tier2_validated|rudder_openssh_server_down)::
      "/etc/init.d/sshd"
        args => "restart",
        classes => cf2_if_else("rudder_openssh_server_restarted", "cant_restart_ssh"),
        comment => "restarting ssh";

    debian.!rudder_openssh_server_bootstarted.rudder_openssh_server_initd_present::
      "/usr/sbin/update-rc.d ssh remove \&\& /usr/sbin/update-rc.d ssh defaults"
        contain => in_shell,
        classes => cf2_if_else("rudder_openssh_server_bootstarted_ok", "rudder_openssh_server_still_unbootstarted"),
        comment => "adding ssh to the startup scripts";

    (redhat|SuSE).!rudder_openssh_server_bootstarted.rudder_openssh_server_initd_present::
      "/sbin/chkconfig --del sshd \&\& /sbin/chkconfig --add sshd"
        contain => in_shell,
        classes => cf2_if_else("rudder_openssh_server_bootstarted_ok", "rudder_openssh_server_still_unbootstarted"),
        comment => "adding ssh to the startup scripts";

  files:

    SuSE::

      "/etc/init.d/rc3.d/S.*ssh.*"
        create => "true",
        #depth_search => recurse("0"),
        #file_select => rudder_openssh_server_startlink,
        action => WarnOnly,
        classes => if_else("rudder_openssh_server_bootstarted", "rudder_openssh_server_rc_error");

    (debian|redhat)::

      "/etc/rc2.d/S.*ssh.*"
        create => "true",
        #depth_search => recurse("0"),
        #file_select => rudder_openssh_server_startlink,
        action => WarnOnly,
        classes => if_else("rudder_openssh_server_bootstarted", "rudder_openssh_server_rc_error");

    (debian|redhat|SuSE).rudder_openssh_server_ports_edit::

      "${rudder_openssh_server_config}"
        edit_line => rudder_openrudder_openssh_server_server_configuration_tier1("@{this.sshPorts}"),
        classes =>  kept_if_else("rudder_openssh_server_tier1_kept", "rudder_openssh_server_tier1_validated", "rudder_openssh_server_tier1_failed");

    (debian|redhat|SuSE)::

      "${rudder_openssh_server_config}"
        edit_line => rudder_openrudder_openssh_server_server_configuration_tier2("check_rudder_openssh_server_configuration.sshd"),
        classes => kept_if_else("rudder_openssh_server_tier2_kept", "rudder_openssh_server_tier2_validated", "rudder_openssh_server_tier2_failed");

  reports:


    # SSH Process
    rudder_openssh_server_down::
      "@@sshConfiguration@@log_repaired@@&TRACKINGKEY&@@SSH process@@None@@${g.execRun}##${g.uuid}@#SSH service was not running, trying to restart...";

    !rudder_openssh_server_down.!rudder_openssh_server_restarted.!cant_restart_ssh::
      "@@sshConfiguration@@result_success@@&TRACKINGKEY&@@SSH process@@None@@${g.execRun}##${g.uuid}@#SSH service is running";

    rudder_openssh_server_restarted.!cant_restart_ssh::
      "@@sshConfiguration@@result_repaired@@&TRACKINGKEY&@@SSH process@@None@@${g.execRun}##${g.uuid}@#Restarted SSH service";

    cant_restart_ssh::
      "@@sshConfiguration@@result_error@@&TRACKINGKEY&@@SSH process@@None@@${g.execRun}##${g.uuid}@#Could not restart SSH";


    # SSH configuration file
    rudder_openssh_server_tier1_kept::
      "@@sshConfiguration@@log_info@@&TRACKINGKEY&@@SSH configuration@@None@@${g.execRun}##${g.uuid}@#SSH configuration (tier1) is already compliant";

    rudder_openssh_server_tier2_kept::
      "@@sshConfiguration@@log_info@@&TRACKINGKEY&@@SSH configuration@@None@@${g.execRun}##${g.uuid}@#SSH configuration (tier2) is already compliant";

    rudder_openssh_server_tier1_validated::
      "@@sshConfiguration@@log_repaired@@&TRACKINGKEY&@@SSH configuration@@None@@${g.execRun}##${g.uuid}@#Fixed SSH configuration (tier1)";

    rudder_openssh_server_tier2_validated::
      "@@sshConfiguration@@log_repaired@@&TRACKINGKEY&@@SSH configuration@@None@@${g.execRun}##${g.uuid}@#Fixed SSH configuration (tier2)";

    rudder_openssh_server_tier1_failed::
      "@@sshConfiguration@@result_error@@&TRACKINGKEY&@@SSH configuration@@None@@${g.execRun}##${g.uuid}@#Editing SSH configuration (tier1) failed";

    rudder_openssh_server_tier2_failed::
      "@@sshConfiguration@@result_error@@&TRACKINGKEY&@@SSH configuration@@None@@${g.execRun}##${g.uuid}@#Editing SSH configuration (tier2) failed";

    (rudder_openssh_server_tier1_validated|!rudder_openssh_server_port_edit).rudder_openssh_server_tier2_validated::
      "@@sshConfiguration@@result_repaired@@&TRACKINGKEY&@@SSH configuration@@None@@${g.execRun}##${g.uuid}@#SSH configuration successfully set";

    (rudder_openssh_server_tier1_kept|!rudder_openssh_server_port_edit).rudder_openssh_server_tier2_kept.!rudder_openssh_server_tier1_validated.!rudder_openssh_server_tier2_validated::
      "@@sshConfiguration@@result_success@@&TRACKINGKEY&@@SSH configuration@@None@@${g.execRun}##${g.uuid}@#SSH configuration was already correct";


    # SSH start on boot
    rudder_openssh_server_bootstarted::
      "@@sshConfiguration@@result_success@@&TRACKINGKEY&@@SSH start at boot@@None@@${g.execRun}##${g.uuid}@#SSH is already set to start on boot";

    rudder_openssh_server_rc_error::
      "@@sshConfiguration@@log_info@@&TRACKINGKEY&@@SSH start at boot@@None@@${g.execRun}##${g.uuid}@#Error checking if SSH is set to be started on boot";

    rudder_openssh_server_bootstarted_ok::
      "@@sshConfiguration@@result_repaired@@&TRACKINGKEY&@@SSH start at boot@@None@@${g.execRun}##${g.uuid}@#SSH was set to run on boot";

    rudder_openssh_server_still_unbootstarted::
      "@@sshConfiguration@@result_error@@&TRACKINGKEY&@@SSH start at boot@@None@@${g.execRun}##${g.uuid}@#SSH could not be set to start on boot";

      
    # This is a safety net, but should never happen
    !rudder_openssh_server_initd_present::
      "@@sshConfiguration@@result_error@@&TRACKINGKEY&@@SSH installation@@None@@${g.execRun}##${g.uuid}@#SSH is not installed, although it should have been installed";


    # Warn about features that are not implemented on all platforms
    rudder_openssh_server_allowagentforwarding_edit.(redhat|SuSE)::
      "@@sshConfiguration@@log_warn@@&TRACKINGKEY&@@SSH configuration@@None@@${g.execRun}##${g.uuid}@#SSH agent forwarding isn't implemented on Red Hat/CentOS/SuSE";

    rudder_openssh_server_maxsessions_edit.(redhat|SuSE)::
      "@@sshConfiguration@@log_warn@@&TRACKINGKEY&@@SSH configuration@@None@@${g.execRun}##${g.uuid}@#SSH max sessions isn't implemented on Red Hat/CentOS/SuSE";

    rudder_openssh_server_permittunnel_edit.(redhat|SuSE)::
      "@@sshConfiguration@@log_warn@@&TRACKINGKEY&@@SSH configuration@@None@@${g.execRun}##${g.uuid}@#SSH permit tunnel isn't implemented on SuSE";
}
