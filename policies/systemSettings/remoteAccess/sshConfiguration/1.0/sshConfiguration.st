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

######################################################
# Configure the OpenSSH server 
# If ssh is not installed, install it (linux)
# Change the server configuration, and restart the daemon
# if the configuration changed
# WARNING : You may inadvertently create conflict with processManagement !
# This promise restarts sshd if not there, which could be done by processManagement too.
# dontchange is a generic value to prohibit the edition of the value

bundle agent check_ssh_configuration {

	classes:

		# Security : if not there, SSH too, so don't bother anymore
		"ssh_initd_present" expression => fileexists("/usr/sbin/sshd");

		# AddressFamily edition ?
		"ssh_addressfamily_edit" not => strcmp("&SSH_ADDRESSFAMILY&","dontchange");

		# Ports edition ?
		"ssh_ports_edit" not => strcmp("&SSH_PORTSEDIT&","false");

		# Protocol edition ?
		"ssh_protocol_edit" not => strcmp("&SSH_PROTOCOL&","dontchange");

		# MaxSessions edition ?
		"ssh_maxsessions_edit" not => strcmp("&SSH_MAXSESSIONS&","dontchange");

		# ChallengeResponseAuthentication edition ?
		"ssh_challengeresponseauthentication_edit" not => strcmp("&SSH_CHALLENGERESPONSEAUTHENTICATION&","dontchange");

		#  PasswordAuthentication edition ?
		"ssh_passwordauthentication_edit" not => strcmp("&SSH_PASSWORDAUTHENTICATION&","dontchange");

		# PubkeyAuthentication edition ?
		"ssh_pubkeyauthentication_edit" not => strcmp("&SSH_PUBKEYAUTHENTICATION&","dontchange");

		# PermitEmptyPasswords edition ?
		"ssh_permitemptypasswords_edit" not => strcmp("&SSH_PERMITEMPTYPASSWORDS&","dontchange");

		# PermitRootLogin edition ?
		"ssh_permitrootlogin_edit" not => strcmp("&SSH_PERMITROOTLOGIN&","dontchange");

		# MaxAuthTries edition ?
		"ssh_maxauthtries_edit" not => strcmp("&SSH_MAXAUTHTRIES&","dontchange");

		# LoginGraceTime edition ?
		"ssh_logingracetime_edit" not => strcmp("&SSH_LOGINGRACETIME&","dontchange");

		# UsePrivilegeSeparation edition ?
		"ssh_useprivilegeseparation_edit" not => strcmp("&SSH_USEPRIVILEGESEPARATION&","dontchange");

		# StrictModes edition ?
		"ssh_strictmodes_edit" not => strcmp("&SSH_STRICTMODES&","dontchange");

		# AllowAgentForwarding edition ?
		"ssh_allowagentforwarding_edit" not => strcmp("&SSH_ALLOWAGENTFORWARDING&","dontchange");

		# AllowTcpForwarding edition ?
		"ssh_allowtcpforwarding_edit" not => strcmp("&SSH_ALLOWTCPFORWARDING&","dontchange");

		# PermitTunnel edition ?
		"ssh_permittunnel_edit" not => strcmp("&SSH_PERMITTUNNEL&","dontchange");

		# PermitUserEnvironment edition ?
		"ssh_permituserenvironment_edit" not => strcmp("&SSH_PERMITUSERENVIRONMENT&","dontchange");

		# X11Forwarding edition ?
		"ssh_x11forwarding_edit" not => strcmp("&SSH_X11FORWARDING&","dontchange");

		# PrintLastLog edition ?
		"ssh_printlastlog_edit" not => strcmp("&SSH_PRINTLASTLOG&","dontchange");

		# PrintMotd edition ?
		"ssh_printmotd_edit" not => strcmp("&SSH_PRINTMOTD&","dontchange");

		# TCPKeepAlive edition ?
		"ssh_tcpkeepalive_edit" not => strcmp("&SSH_TCPKEEPALIVE&","dontchange");

		# LogLevel edition ?
		"ssh_loglevel_edit" not => strcmp("&SSH_LOGLEVEL&","dontchange");

		# SyslogFacility edition ?
		"ssh_syslogfacility_edit" not => strcmp("&SSH_SYSLOGFACILITY&","dontchange");

	vars:

		# This is the file to edit
                "sshdconfig" string => "&SSHD_CONFFILE&";

                "sshPorts"  slist => {&SSH_PORTS: { "&it&" };separator=", "&};

		ssh_addressfamily_edit::

			"sshd[AddressFamily]" string => "&SSH_ADDRESSFAMILY&";

		ssh_protocol_edit::

			"sshd[Protocol]" string => "&SSH_PROTOCOL&";

		ssh_maxsessions_edit.!redhat.!SuSE::

			"sshd[MaxSessions]" string => "&SSH_MAXSESSIONS&";

		ssh_challengeresponseauthentication_edit::

			"sshd[ChallengeResponseAuthentication]" string => "&SSH_CHALLENGERESPONSEAUTHENTICATION&";

		ssh_passwordauthentication_edit::

			"sshd[PasswordAuthentication]" string => "&SSH_PASSWORDAUTHENTICATION&";

		ssh_pubkeyauthentication_edit::

			"sshd[PubkeyAuthentication]" string => "&SSH_PUBKEYAUTHENTICATION&";

		ssh_permitemptypasswords_edit::

			"sshd[PermitEmptyPasswords]" string => "&SSH_PERMITEMPTYPASSWORDS&";

		ssh_permitrootlogin_edit::

			"sshd[PermitRootLogin]" string => "&SSH_PERMITROOTLOGIN&";

		ssh_maxauthtries_edit::

			"sshd[MaxAuthTries]" string => "&SSH_MAXAUTHTRIES&";

		ssh_logingracetime_edit::

			"sshd[LoginGraceTime]" string => "&SSH_LOGINGRACETIME&";

		ssh_useprivilegeseparation_edit::

			"sshd[UsePrivilegeSeparation]" string => "&SSH_USEPRIVILEGESEPARATION&";

		ssh_strictmodes_edit::

			"sshd[StrictModes]" string => "&SSH_STRICTMODES&";

		ssh_allowagentforwarding_edit.!redhat.!SuSE::

			"sshd[AllowAgentForwarding]" string => "&SSH_ALLOWAGENTFORWARDING&";

		ssh_allowtcpforwarding_edit::

			"sshd[AllowTcpForwarding]" string => "&SSH_ALLOWTCPFORWARDING&";

		ssh_permittunnel_edit.!SuSE::

			"sshd[PermitTunnel]" string => "&SSH_PERMITTUNNEL&";

		ssh_permituserenvironment_edit::

			"sshd[PermitUserEnvironment]" string => "&SSH_PERMITUSERENVIRONMENT&";

		ssh_x11forwarding_edit::

			"sshd[X11Forwarding]" string => "&SSH_X11FORWARDING&";

		ssh_printlastlog_edit::

			"sshd[PrintLastLog]" string => "&SSH_PRINTLASTLOG&";

		ssh_printmotd_edit::

			"sshd[PrintMotd]" string => "&SSH_PRINTMOTD&";

		ssh_tcpkeepalive_edit::

			"sshd[TCPKeepAlive]" string => "&SSH_TCPKEEPALIVE&";

		ssh_loglevel_edit::

			"sshd[LogLevel]" string => "&SSH_LOGLEVEL&";

		ssh_syslogfacility_edit::

			"sshd[SyslogFacility]" string => "&SSH_SYSLOGFACILITY&";

	processes:

		(debian|redhat|SuSE)::

			"/usr/sbin/sshd"
				restart_class => "ssh_down",
				comment => "Ensuring ssh is up";

	commands:

		debian.(ssh_tier1_validated|ssh_tier2_validated|ssh_down)::
			"/etc/init.d/ssh"
				args => "restart",
				classes => cf2_if_else("ssh_restarted", "cant_restart_ssh"),
				comment => "restarting ssh";

		(redhat|SuSE).(ssh_tier1_validated|ssh_tier2_validated|ssh_down)::
			"/etc/init.d/sshd"
				args => "restart",
				classes => cf2_if_else("ssh_restarted", "cant_restart_ssh"),
				comment => "restarting ssh";

		debian.!ssh_bootstarted.ssh_initd_present::
			"/usr/sbin/update-rc.d ssh remove && /usr/sbin/update-rc.d ssh defaults"
				contain => in_shell,
				classes => cf2_if_else("ssh_bootstarted_ok", "ssh_still_unbootstarted"),
				comment => "adding ssh to the startup scripts";

		(redhat|SuSE).!ssh_bootstarted.ssh_initd_present::
			"/sbin/chkconfig --del sshd && /sbin/chkconfig --add sshd"
				contain => in_shell,
				classes => cf2_if_else("ssh_bootstarted_ok", "ssh_still_unbootstarted"),
				comment => "adding ssh to the startup scripts";

	files:

		SuSE::

                        "/etc/init.d/rc3.d/S.*ssh.*"
                                create => "true",
                                #depth_search => recurse("0"),
                                #file_select => ssh_startlink,
                                action => WarnOnly,
                                classes => if_else("ssh_bootstarted", "ssh_rc_error");

		(debian|redhat)::

                        "/etc/rc2.d/S.*ssh.*"
                                create => "true",
                                #depth_search => recurse("0"),
                                #file_select => ssh_startlink,
                                action => WarnOnly,
                                classes => if_else("ssh_bootstarted", "ssh_rc_error");

		(debian|redhat|SuSE).ssh_ports_edit::

			"$(sshdconfig)"
				edit_line => set_ssh_config_values_tier1("@(this.sshPorts)"),
				classes =>  kept_if_else("ssh_tier1_kept", "ssh_tier1_validated", "ssh_tier1_failed");

		(debian|redhat|SuSE)::

			"$(sshdconfig)"
				edit_line => set_ssh_config_values_tier2("check_ssh_configuration.sshd"),
				classes => kept_if_else("ssh_tier2_kept", "ssh_tier2_validated", "ssh_tier2_failed");

	reports:


		# SSH Process
		ssh_down::
			"@@sshConfiguration@@log_repaired@@&TRACKINGKEY&@@SSH process@@None@@$(g.execRun)##$(g.uuid)@#SSH service was not running, trying to restart...";

		!ssh_down::
			"@@sshConfiguration@@result_success@@&TRACKINGKEY&@@SSH process@@None@@$(g.execRun)##$(g.uuid)@#SSH service is running";

		ssh_restarted::
			"@@sshConfiguration@@result_repaired@@&TRACKINGKEY&@@SSH process@@None@@$(g.execRun)##$(g.uuid)@#Restarted SSH service";

		cant_restart_ssh::
			"@@sshConfiguration@@result_error@@&TRACKINGKEY&@@SSH process@@None@@$(g.execRun)##$(g.uuid)@#Could not restart SSH";


		# SSH configuration file
		ssh_tier1_kept::
			"@@sshConfiguration@@log_info@@&TRACKINGKEY&@@SSH configuration@@None@@$(g.execRun)##$(g.uuid)@#SSH configuration (tier1) is already compliant";

		ssh_tier2_kept::
			"@@sshConfiguration@@log_info@@&TRACKINGKEY&@@SSH configuration@@None@@$(g.execRun)##$(g.uuid)@#SSH configuration (tier2) is already compliant";

		ssh_tier1_validated::
			"@@sshConfiguration@@log_repaired@@&TRACKINGKEY&@@SSH configuration@@None@@$(g.execRun)##$(g.uuid)@#Fixed SSH configuration (tier1)";

		ssh_tier2_validated::
			"@@sshConfiguration@@log_repaired@@&TRACKINGKEY&@@SSH configuration@@None@@$(g.execRun)##$(g.uuid)@#Fixed SSH configuration (tier2)";

		ssh_tier1_failed::
			"@@sshConfiguration@@result_error@@&TRACKINGKEY&@@SSH configuration@@None@@$(g.execRun)##$(g.uuid)@#Editing SSH configuration (tier1) failed";

		ssh_tier2_failed::
			"@@sshConfiguration@@result_error@@&TRACKINGKEY&@@SSH configuration@@None@@$(g.execRun)##$(g.uuid)@#Editing SSH configuration (tier2) failed";

		(ssh_tier1_validated|!ssh_port_edit).ssh_tier2_validated::
			"@@sshConfiguration@@result_repaired@@&TRACKINGKEY&@@SSH configuration@@None@@$(g.execRun)##$(g.uuid)@#SSH configuration successfully set";

		(ssh_tier1_kept|!ssh_port_edit).ssh_tier2_kept.!ssh_tier1_validated.!ssh_tier2_validated::
			"@@sshConfiguration@@result_success@@&TRACKINGKEY&@@SSH configuration@@None@@$(g.execRun)##$(g.uuid)@#SSH configuration was already correct";


		# SSH start on boot
		ssh_bootstarted::
			"@@sshConfiguration@@result_success@@&TRACKINGKEY&@@SSH start at boot@@None@@$(g.execRun)##$(g.uuid)@#SSH is already set to start on boot";

		ssh_rc_error::
			"@@sshConfiguration@@log_info@@&TRACKINGKEY&@@SSH start at boot@@None@@$(g.execRun)##$(g.uuid)@#Error checking if SSH is set to be started on boot";

		ssh_bootstarted_ok::
			"@@sshConfiguration@@result_repaired@@&TRACKINGKEY&@@SSH start at boot@@None@@$(g.execRun)##$(g.uuid)@#SSH was set to run on boot";

		ssh_still_unbootstarted::
			"@@sshConfiguration@@result_error@@&TRACKINGKEY&@@SSH start at boot@@None@@$(g.execRun)##$(g.uuid)@#SSH could not be set to start on boot";

			
		# This is a safety net, but should never happen
		!ssh_initd_present::
			"@@sshConfiguration@@result_error@@&TRACKINGKEY&@@SSH installation@@None@@$(g.execRun)##$(g.uuid)@#SSH is not installed, although it should have been installed";


		# Warn about features that are not implemented on all platforms
		ssh_allowagentforwarding_edit.(redhat|SuSE)::
			"@@sshConfiguration@@log_warn@@&TRACKINGKEY&@@SSH configuration@@None@@$(g.execRun)##$(g.uuid)@#SSH agent forwarding isn't implemented on Red Hat/CentOS/SuSE";

		ssh_maxsessions_edit.(redhat|SuSE)::
			"@@sshConfiguration@@log_warn@@&TRACKINGKEY&@@SSH configuration@@None@@$(g.execRun)##$(g.uuid)@#SSH max sessions isn't implemented on Red Hat/CentOS/SuSE";

		ssh_permittunnel_edit.(redhat|SuSE)::
			"@@sshConfiguration@@log_warn@@&TRACKINGKEY&@@SSH configuration@@None@@$(g.execRun)##$(g.uuid)@#SSH permit tunnel isn't implemented on SuSE";
}

bundle edit_line set_ssh_config_values_tier1(portlist)

{
delete_lines:

   "Port.*";

insert_lines:

   "Port $(portlist)";

}

bundle edit_line set_ssh_config_values_tier2(tab)

 # Sets the RHS of configuration items in the file of the form
 # LHS RHS
 # If the line is commented out with #, it gets uncommented first.
 # Adds a new line if none exists.
 # The argument is an associative array containing v[LHS]="rhs"

 # Based on set_variable_values from cfengine_stdlib.cf, modified to
 # use whitespace as separator, and to handle commented-out lines.

{
vars:
  "index" slist => getindices("$(tab)");

  # Be careful if the index string contains funny chars
  "cindex[$(index)]" string => canonify("$(index)");

field_edits:

  # If the line is there, but commented out, first uncomment it
  "#+$(index)\s+.*"
     edit_field => col("\s+","1","$(index)","set");

  # match a line starting like the key something
  "$(index)\s+.*"
     edit_field => col("\s+","2","$($(tab)[$(index)])","set"),
       	classes => if_ok("not_$(cindex[$(index)])");

insert_lines:

"#############################################################
### This file is protected by your Rudder infrastructure. ###
### Manually editing the file might lead your Rudder      ###
### infrastructure to change back the server’s            ###
### configuration and/or to raise a compliance alert.     ###
#############################################################
"
                location => start,
                insert_type => "preserve_block";

	"$(index) $($(tab)[$(index)])",
		ifvarclass => "!not_$(cindex[$(index)])";

}
