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

bundle agent check_openvpn_client_configuration
{

  vars:

      &OVPN_CLIENT_REMOTE_SERVER, OVPN_CLIENT_REMOTE_PORT:{server, port |"ovpn_client_remote[&i&]" string => "&server& &port&";
}&

      "ovpn_client[dev]" string => "&OVPN_CLIENT_TUNTAP&";

      "ovpn_client[proto]" string => "&OVPN_CLIENT_REMOTE_PROTOCOL&";

      "ovpn_client[script-security]" string => "2";

      "ovpn_client[verb]" string => "&OVPN_CLIENT_LOGGING_VERBOSITY&";

    ovpn_client_pskmode::

      "ovpn_client[secret]" string => "&OVPN_CLIENT_PSKFILE&";

    ovpn_client_randomize::

      "ovpn_client[remote-random]" string => "";

    ovpn_client_pwauth::

      "ovpn_client[auth-user-pass]" string => "/etc/openvpn/keyring.pwd";

    ovpn_client_keepretrying::

      "ovpn_client[resolv-retry]" string => "infinite";

    ovpn_client_logtofile.ovpn_client_appendfile::

      "ovpn_client[log-append]" string => "&OVPN_CLIENT_LOGGING_FILE&";

    ovpn_client_logtofile.!ovpn_client_appendfile::

      "ovpn_client[log]" string => "&OVPN_CLIENT_LOGGING_FILE&";


  classes:

    # Security : if not there, OpenVPN too, so don't bother anymore
      "openvpn_bin_present" expression => fileexists("/usr/sbin/openvpn");

    # Autostart ?
      "ovpn_client_autostart" expression => strcmp("&OVPN_CLIENT_AUTOSTART&","true");

    # PSK mode ?
      "ovpn_client_pskmode" expression => strcmp("&OVPN_CLIENT_KEYMODE&","psk");

    # Randomize remotes ?
      "ovpn_client_randomize" expression => strcmp("&OVPN_CLIENT_REMOTE_RANDOMIZE&","true");

    # Use user/password ?
      "ovpn_client_pwauth" expression => strcmp("&OVPN_CLIENT_REMOTE_AUTH&","true");

    # Do not use user/password ?
      "ovpn_client_nopwauth" expression => strcmp("&OVPN_CLIENT_REMOTE_AUTH&","false");

    # Log to file ?
      "ovpn_client_logtofile" expression => strcmp("&OVPN_CLIENT_LOGGING_TARGET&","file");

    # Append logs ?
      "ovpn_client_appendfile" expression => strcmp("&OVPN_CLIENT_LOGGING_BEHAVIOR&","true");

    # Keep retrying connection ?
      "ovpn_client_keepretrying" expression => strcmp("&OVPN_CLIENT_REMOTE_KEEPTRYING&","true");

  files:

    (debian|redhat|SuSE)::

      "/etc/rc2.d/S.*openvpn.*"
        create => "true",
                                #depth_search => recurse("0"),
                                #file_select => openvpn_startlink,
        action => WarnOnly,
        classes => if_else("openvpn_bootstarted", "openvpn_unbootstarted");

      "/etc/openvpn/rudder.conf"
        create => "true",
        perms => m("644"),
        edit_line => set_openvpn_config_values_tier1("check_openvpn_client_configuration.ovpn_client_remote"),
        edit_defaults => noempty_backup,
        classes => kept_if_else("openvpn_tier1_kept", "openvpn_tier1_validated", "openvpn_tier1_failed");

      "/etc/openvpn/rudder.conf"
        create => "true",
        perms => m("644"),
        edit_line => set_openvpn_config_values_tier2("check_openvpn_client_configuration.ovpn_client"),
        edit_defaults => noempty_backup,
        classes => kept_if_else("openvpn_tier2_kept", "openvpn_tier2_validated", "openvpn_tier2_failed");

    ovpn_client_pwauth::

      "/etc/openvpn/keyring.pwd"
        create => "true",
        edit_defaults => noempty_backup,
        perms => mog("600", "root", "root"),
        edit_line => set_openvpn_config_values_keyring("&OVPN_CLIENT_REMOTE_USER&", "&OVPN_CLIENT_REMOTE_PASS&"),
        edit_defaults => noempty_backup,
        classes => kept_if_else("openvpn_keyring_kept", "openvpn_keyring_validated", "openvpn_keyring_failed");

  processes:

    (SuSE|debian|redhat).ovpn_client_autostart::

      "/usr/sbin/openvpn"
        restart_class => "openvpn_down",
        comment => "Ensuring openvpn is up";

  commands:

    (openvpn_tier1_validated|openvpn_tier2_validated|openvpn_keyring_validated|openvpn_down).ovpn_client_autostart::
      "/etc/init.d/openvpn"
        args => "restart",
        classes => cf2_if_else("openvpn_restarted", "cant_restart_openvpn"),
        comment => "restarting openvpn";

    (debian.openvpn_unbootstarted).openvpn_bin_present::
      "/usr/sbin/update-rc.d"
        args => "openvpn defaults",
        classes => cf2_if_else("openvpn_bootstarted_ok", "openvpn_still_unbootstarted"),
        comment => "adding openvpn to the startup scripts";

    (redhat.openvpn_unbootstarted).openvpn_bin_present::
      "/sbin/chkconfig"
        args => "--add openvpn",
        classes => cf2_if_else("openvpn_bootstarted_ok", "openvpn_still_unbootstarted"),
        comment => "adding openvpn to the startup scripts";

    # YES I know this isn't DRY but CF3 does not support nested parenthesis yet
    (SuSE.openvpn_unbootstarted).openvpn_bin_present::
      "/sbin/chkconfig"
        args => "--add openvpn",
        classes => cf2_if_else("openvpn_bootstarted_ok", "openvpn_still_unbootstarted"),
        comment => "adding openvpn to the startup scripts";

  reports:

    openvpn_tier1_kept::
      "@@openvpnClientConfiguration@@log_info@@&TRACKINGKEY&@@OpenVPN configuration@@None@@${g.execRun}##${g.uuid}@#OpenVPN remotes list edition not needed";

    openvpn_tier2_kept::
      "@@openvpnClientConfiguration@@log_info@@&TRACKINGKEY&@@OpenVPN configuration@@None@@${g.execRun}##${g.uuid}@#OpenVPN general configuration is OK";

    openvpn_keyring_kept::
      "@@openvpnClientConfiguration@@log_info@@&TRACKINGKEY&@@OpenVPN configuration@@None@@${g.execRun}##${g.uuid}@#OpenVPN password keyring present";

    openvpn_tier1_validated::
      "@@openvpnClientConfiguration@@log_repaired@@&TRACKINGKEY&@@OpenVPN configuration@@None@@${g.execRun}##${g.uuid}@#OpenVPN remotes list edition done";

    openvpn_tier2_validated::
      "@@openvpnClientConfiguration@@log_repaired@@&TRACKINGKEY&@@OpenVPN configuration@@None@@${g.execRun}##${g.uuid}@#OpenVPN general configuration done";

    openvpn_keyring_validated::
      "@@openvpnClientConfiguration@@log_repaired@@&TRACKINGKEY&@@OpenVPN configuration@@None@@${g.execRun}##${g.uuid}@#OpenVPN keyring written";

    openvpn_tier1_failed::
      "@@openvpnClientConfiguration@@result_error@@&TRACKINGKEY&@@OpenVPN configuration@@None@@${g.execRun}##${g.uuid}@#OpenVPN remotes list edition failed";

    openvpn_tier2_failed::
      "@@openvpnClientConfiguration@@result_error@@&TRACKINGKEY&@@OpenVPN configuration@@None@@${g.execRun}##${g.uuid}@#OpenVPN general configuration failed";

    openvpn_keyring_failed::
      "@@openvpnClientConfiguration@@result_error@@&TRACKINGKEY&@@OpenVPN configuration@@None@@${g.execRun}##${g.uuid}@#OpenVPN keyring could not be written";

    ovpn_client_nopwauth.((openvpn_tier1_validated.openvpn_tier2_validated)|(openvpn_tier1_kept.openvpn_tier2_kept))::
      "@@openvpnClientConfiguration@@result_success@@&TRACKINGKEY&@@OpenVPN configuration@@None@@${g.execRun}##${g.uuid}@#OpenVPN configuration is set correctly";

    ovpn_client_pwauth.((openvpn_tier1_validated.openvpn_tier2_validated.openvpn_keyring_validated)|(openvpn_tier1_kept.openvpn_tier2_kept.openvpn_keyring_kept))::
      "@@openvpnClientConfiguration@@result_success@@&TRACKINGKEY&@@OpenVPN configuration@@None@@${g.execRun}##${g.uuid}@#OpenVPN configuration is set correctly";

    (openvpn_tier1_validated.openvpn_tier2_validated.openvpn_keyring_validated)|(openvpn_tier1_kept.openvpn_tier2_kept.openvpn_keyring_kept)::
      "@@openvpnClientConfiguration@@result_success@@&TRACKINGKEY&@@OpenVPN configuration@@None@@${g.execRun}##${g.uuid}@#OpenVPN configuration is set correctly"
        ifvarclass => canonify("ovpn_client_pwauth");

    ovpn_client_autostart.openvpn_bootstarted_ok::
      "@@openvpnClientConfiguration@@result_repaired@@&TRACKINGKEY&@@OpenVPN configuration@@None@@${g.execRun}##${g.uuid}@#OpenVPN is now starting on boot";

    ovpn_client_autostart.openvpn_still_unbootstarted::
      "@@openvpnClientConfiguration@@result_error@@&TRACKINGKEY&@@OpenVPN configuration@@None@@${g.execRun}##${g.uuid}@#OpenVPN could not be set to start on boot";

    ovpn_client_autostart.openvpn_bootstarted::
      "@@openvpnClientConfiguration@@log_info@@&TRACKINGKEY&@@OpenVPN configuration@@None@@${g.execRun}##${g.uuid}@#OpenVPN already set to start on boot";

    openvpn_restarted::
      "@@openvpnClientConfiguration@@log_repaired@@&TRACKINGKEY&@@OpenVPN configuration@@None@@${g.execRun}##${g.uuid}@#OpenVPN restarted";

    cant_restart_openvpn::
      "@@openvpnClientConfiguration@@result_error@@&TRACKINGKEY&@@OpenVPN configuration@@None@@${g.execRun}##${g.uuid}@#Could not restart OpenVPN";

    !openvpn_bin_present::
      "@@openvpnClientConfiguration@@result_error@@&TRACKINGKEY&@@OpenVPN configuration@@None@@${g.execRun}##${g.uuid}@#OpenVPN binary is not present. Something is wrong (installation failure?)";

}

bundle edit_line set_openvpn_config_values_tier1(remotes)
{

  vars:

      "remotes_index" slist => getindices("${remotes}");

  delete_lines:

      "remote\ .*";

  insert_lines:

      "remote ${${remotes}[${remotes_index}]}";

}

bundle edit_line set_openvpn_config_values_tier2(tab)

 # Sets the RHS of configuration items in the file of the form
 # LHS RHS
 # If the line is commented out with #, it gets uncommented first.
 # Adds a new line if none exists.
 # The argument is an associative array containing v[LHS]="rhs"

 # Based on set_variable_values from cfengine_stdlib.cf, modified to
 # use whitespace as separator, and to handle commented-out lines.

{
  vars:
      "index" slist => getindices("${tab}");

  # Be careful if the index string contains funny chars
      "cindex[${index}]" string => canonify("${index}");

  field_edits:

  # If the line is there, but commented out, first uncomment it
      "#+${index}\s+.*"
        edit_field => col("\s+","1","${index}","set");

  # match a line starting like the key something
      "${index}\s+.*"
        edit_field => col("\s+","2","${${tab}[${index}]}","set"),
        classes => if_ok("not_${cindex[${index}]}");

  insert_lines:

"#############################################################
### This file is protected by your Rudder infrastructure. ###
### Manually editing the file might lead your Rudder      ###
### infrastructure to change back the server's            ###
### configuration and/or to raise a compliance alert.     ###
#############################################################
"
        location => start,
        insert_type => "preserve_block";

      "${index} ${${tab}[${index}]}"
        ifvarclass => "!not_${cindex[${index}]}";

}

bundle edit_line set_openvpn_config_values_keyring(user, pass)
{

  insert_lines:

      "${user}";
      "${pass}";

}
