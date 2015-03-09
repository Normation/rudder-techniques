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
# This Technique installs and configures OpenSSH. See metadata.xml for more details.
#####################################################################################

bundle agent rudder_openssh_server
{
  vars:
      "rudder_openssh_server_service_name"
        string => "OpenSSH server";

      # Prefix for all the defined classes
      "rudder_class_prefix"
        string => "rudder_openssh_server";

      # This is the file to edit
      "rudder_openssh_server_config[sshd_config_file]"
        string => "&OPENSSH_SERVER_CONFFILE&";

      "rudder_openssh_server_config[sshd_config_ports]"
        slist  => {&OPENSSH_SERVER_PORTS: { "&it&" };separator=", "&};

      # This is the reporting information to be added
      "rudder_openssh_server_config[report]"
        string => "&TRACKINGKEY&";

      # Variable that holds if we want to edit ports
      "rudder_openssh_server_config[edit_ports]"
        string => "&OPENSSH_SERVER_PORTSEDIT&";

    # Class specific parameters
    rudder_openssh_server_address_family_edit.!(debian_3|redhat_3|redhat_4|centos_3|centos_4)::
      "rudder_openssh_server_config[config][AddressFamily]"
        string => "&OPENSSH_SERVER_ADDRESSFAMILY&";

    rudder_openssh_server_protocol_edit::
      "rudder_openssh_server_config[config][Protocol]"
        string => "&OPENSSH_SERVER_PROTOCOL&";

    rudder_openssh_server_max_sessions_edit.!(redhat|SuSE|debian_3|debian_4|aix_5_3|aix_5_2|aix_5_1)::
      "rudder_openssh_server_config[config][MaxSessions]"
        string => "&OPENSSH_SERVER_MAXSESSIONS&";

    rudder_openssh_server_challenge_response_authentication_edit::
      "rudder_openssh_server_config[config][ChallengeResponseAuthentication]"
        string => "&OPENSSH_SERVER_CHALLENGERESPONSEAUTHENTICATION&";

    rudder_openssh_server_password_authentication_edit::
      "rudder_openssh_server_config[config][PasswordAuthentication]"
        string => "&OPENSSH_SERVER_PASSWORDAUTHENTICATION&";

    rudder_openssh_server_pubkey_authentication_edit::
      "rudder_openssh_server_config[config][PubkeyAuthentication]"
        string => "&OPENSSH_SERVER_PUBKEYAUTHENTICATION&";

    rudder_openssh_server_permit_empty_passwords_edit::
      "rudder_openssh_server_config[config][PermitEmptyPasswords]"
        string => "&OPENSSH_SERVER_PERMITEMPTYPASSWORDS&";

    rudder_openssh_server_permit_root_login_edit::
      "rudder_openssh_server_config[config][PermitRootLogin]"
        string => "&OPENSSH_SERVER_PERMITROOTLOGIN&";

    rudder_openssh_server_max_auth_tries_edit.!(debian_3|redhat_3|centos_3)::
      "rudder_openssh_server_config[config][MaxAuthTries]"
        string => "&OPENSSH_SERVER_MAXAUTHTRIES&";

    rudder_openssh_server_login_grace_time_edit::
      "rudder_openssh_server_config[config][LoginGraceTime]"
        string => "&OPENSSH_SERVER_LOGINGRACETIME&";

    rudder_openssh_server_use_privilege_separation_edit::
      "rudder_openssh_server_config[config][UsePrivilegeSeparation]"
        string => "&OPENSSH_SERVER_USEPRIVILEGESEPARATION&";

    rudder_openssh_server_strict_modes_edit::
      "rudder_openssh_server_config[config][StrictModes]"
        string => "&OPENSSH_SERVER_STRICTMODES&";

    rudder_openssh_server_allow_agent_forwarding_edit.!(redhat|SuSE|debian_3|debian_4)::
      "rudder_openssh_server_config[config][AllowAgentForwarding]"
        string => "&OPENSSH_SERVER_ALLOWAGENTFORWARDING&";

    rudder_openssh_server_allow_tcp_forwarding_edit::
      "rudder_openssh_server_config[config][AllowTcpForwarding]"
        string => "&OPENSSH_SERVER_ALLOWTCPFORWARDING&";

    rudder_openssh_server_permit_tunnel_edit.!(SuSE|debian_3|redhat_3|redhat_4|centos_3|centos_4)::
      "rudder_openssh_server_config[config][PermitTunnel]"
        string => "&OPENSSH_SERVER_PERMITTUNNEL&";

    rudder_openssh_server_permit_user_environment_edit::
      "rudder_openssh_server_config[config][PermitUserEnvironment]"
        string => "&OPENSSH_SERVER_PERMITUSERENVIRONMENT&";

    rudder_openssh_server_x11_forwarding_edit::
      "rudder_openssh_server_config[config][X11Forwarding]"
        string => "&OPENSSH_SERVER_X11FORWARDING&";

    rudder_openssh_server_print_lastlog_edit::
      "rudder_openssh_server_config[config][PrintLastLog]"
        string => "&OPENSSH_SERVER_PRINTLASTLOG&";

    rudder_openssh_server_printmotd_edit::
      "rudder_openssh_server_config[config][PrintMotd]"
        string => "&OPENSSH_SERVER_PRINTMOTD&";

    rudder_openssh_server_tcp_keepalive_edit.!(redhat_3|centos_3)::
      "rudder_openssh_server_config[config][TCPKeepAlive]"
        string => "&OPENSSH_SERVER_TCPKEEPALIVE&";

    rudder_openssh_server_log_level_edit::
      "rudder_openssh_server_config[config][LogLevel]"
        string => "&OPENSSH_SERVER_LOGLEVEL&";

    rudder_openssh_server_syslog_facility_edit::
      "rudder_openssh_server_config[config][SyslogFacility]"
        string => "&OPENSSH_SERVER_SYSLOGFACILITY&";

  classes:
      # AddressFamily edition ?
      "rudder_openssh_server_address_family_edit"
        not => strcmp("&OPENSSH_SERVER_ADDRESSFAMILY&","dontchange");

      # Protocol edition ?
      "rudder_openssh_server_protocol_edit"
        not => strcmp("&OPENSSH_SERVER_PROTOCOL&","dontchange");

      # MaxSessions edition ?
      "rudder_openssh_server_max_sessions_edit"
        not => strcmp("&OPENSSH_SERVER_MAXSESSIONS&","dontchange");

      # ChallengeResponseAuthentication edition ?
      "rudder_openssh_server_challenge_response_authentication_edit"
        not => strcmp("&OPENSSH_SERVER_CHALLENGERESPONSEAUTHENTICATION&","dontchange");

      # PasswordAuthentication edition ?
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

      # Defines a class to describe we are at the second iteration
      # When iteration_2 is defined, it means all the variable are defined
      "iteration_2"
        expression => "iteration_1";

      "iteration_1"
        expression => "any";


  methods:
      # Note:
      # The reporting is made on separate bundles to abstract the complexity
      # inherent to the normal ordering.
      "any" usebundle => rudder_openssh_server_installation("${rudder_class_prefix}", "${rudder_openssh_server_service_name}", "rudder_openssh_server.rudder_openssh_server_config");
      "any" usebundle => rudder_openssh_server_installation_reporting("${rudder_class_prefix}", "${rudder_openssh_server_service_name}", "rudder_openssh_server.rudder_openssh_server_config");
      "any" usebundle => rudder_openssh_server_check_ssh_installation();
      "any" usebundle => rudder_openssh_server_check_ssh_installation_reporting("${rudder_class_prefix}", "${rudder_openssh_server_service_name}", "rudder_openssh_server.rudder_openssh_server_config");


    iteration_2::
      "any" usebundle => rudder_openssh_server_configuration("${rudder_class_prefix}", "${rudder_openssh_server_service_name}", "rudder_openssh_server.rudder_openssh_server_config");
      "any" usebundle => rudder_openssh_server_configuration_reporting("${rudder_class_prefix}", "${rudder_openssh_server_service_name}", "rudder_openssh_server.rudder_openssh_server_config");

    # Warn about features that are not implemented on all platforms

    "any"
      usebundle  => rudder_common_report("${rudder_openssh_server_service_name}", "log_warn", "&TRACKINGKEY&", "SSH configuration", "None", "The ${rudder_openssh_server_service_name} parameter \"address family\" isn't implemented on Red Hat/CentOS/SuSE/Debian 3 and 4"),
      ifvarclass => "rudder_openssh_server_address_family_edit.(debian_3|redhat_3|redhat_4|centos_3|centos_4)";
    "any"
      usebundle  => rudder_common_report("${rudder_openssh_server_service_name}", "log_warn", "&TRACKINGKEY&", "SSH configuration", "None", "The ${rudder_openssh_server_service_name} parameter \"maximum authentication attemps per connection\" isn't implemented on Red Hat/CentOS"), 
      ifvarclass => "rudder_openssh_server_max_auth_tries_edit.(redhat_3|centos_3|debian_3)";

    "any"
      usebundle  => rudder_common_report("${rudder_openssh_server_service_name}", "log_warn", "&TRACKINGKEY&", "SSH configuration", "None", "The ${rudder_openssh_server_service_name} parameter \"agent forwarding\" isn't implemented on Red Hat/CentOS/SuSE/Debian 3 and 4"),
      ifvarclass => "rudder_openssh_server_allow_agent_forwarding_edit.(redhat|SuSE|debian_3|debian_4)";
    "any"
      usebundle  => rudder_common_report("${rudder_openssh_server_service_name}", "log_warn", "&TRACKINGKEY&", "SSH configuration", "None", "The ${rudder_openssh_server_service_name} parameter \"max sessions\" isn't implemented on Red Hat/CentOS/SuSE/Debian 3 and 4"),
      ifvarclass => "rudder_openssh_server_max_sessions_edit.(redhat|SuSE|debian_3|debian_4|aix_5_3|aix_5_2|aix_5_1)";
    "any"
      usebundle  => rudder_common_report("${rudder_openssh_server_service_name}", "log_warn", "&TRACKINGKEY&", "SSH configuration", "None", "The ${rudder_openssh_server_service_name} parameter \"permit tunnel\" isn't implemented on SuSE/Debian 3/Redhat/CentOS3 and 4"),
      ifvarclass => "rudder_openssh_server_permit_tunnel_edit.(SuSE|debian_3|redhat_3|redhat_4|centos_3|centos_4)";
    "any"
      usebundle  => rudder_common_report("${rudder_openssh_server_service_name}", "log_warn", "&TRACKINGKEY&", "SSH configuration", "None", "The ${rudder_openssh_server_service_name} parameter \"TCP Keep Alive (Time before disconnect)\" isn't implemented on Red Hat/CentOS 3"),
      ifvarclass => "rudder_openssh_server_tcp_keepalive_edit.(redhat_3|centos_3)";


}
