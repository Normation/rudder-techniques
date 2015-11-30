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

    any::
      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";

  files:

    (debian|redhat|SuSE)::

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
        perms => mog("600", "root", "0"),
        edit_line => set_openvpn_config_values_keyring("&OVPN_CLIENT_REMOTE_USER&", "&OVPN_CLIENT_REMOTE_PASS&"),
        edit_defaults => noempty_backup,
        classes => kept_if_else("openvpn_keyring_kept", "openvpn_keyring_validated", "openvpn_keyring_failed");

  methods:

    openvpn_bin_present.ovpn_client_autostart::

      "autostart_openvpn" usebundle => service_ensure_started_at_boot("openvpn");

    ovpn_client_autostart.(openvpn_tier1_validated|openvpn_tier2_validated|openvpn_keyring_validated|openvpn_down)::

      "restart_openvpn"   usebundle => service_restart("openvpn");

    pass3.openvpn_tier1_kept::
      "any" usebundle => rudder_common_report("openvpnClientConfiguration", "log_info", "&TRACKINGKEY&", "OpenVPN configuration", "None", "OpenVPN remotes list edition not needed");

    pass3.openvpn_tier2_kept::
      "any" usebundle => rudder_common_report("openvpnClientConfiguration", "log_info", "&TRACKINGKEY&", "OpenVPN configuration", "None", "OpenVPN general configuration is OK");

    pass3.openvpn_keyring_kept::
      "any" usebundle => rudder_common_report("openvpnClientConfiguration", "log_info", "&TRACKINGKEY&", "OpenVPN configuration", "None", "OpenVPN password keyring present");

    pass3.openvpn_tier1_validated::
      "any" usebundle => rudder_common_report("openvpnClientConfiguration", "log_repaired", "&TRACKINGKEY&", "OpenVPN configuration", "None", "OpenVPN remotes list edition done");

    pass3.openvpn_tier2_validated::
      "any" usebundle => rudder_common_report("openvpnClientConfiguration", "log_repaired", "&TRACKINGKEY&", "OpenVPN configuration", "None", "OpenVPN general configuration done");

    pass3.openvpn_keyring_validated::
      "any" usebundle => rudder_common_report("openvpnClientConfiguration", "log_repaired", "&TRACKINGKEY&", "OpenVPN configuration", "None", "OpenVPN keyring written");

    pass3.openvpn_tier1_failed::
      "any" usebundle => rudder_common_report("openvpnClientConfiguration", "result_error", "&TRACKINGKEY&", "OpenVPN configuration", "None", "OpenVPN remotes list edition failed");

    pass3.openvpn_tier2_failed::
      "any" usebundle => rudder_common_report("openvpnClientConfiguration", "result_error", "&TRACKINGKEY&", "OpenVPN configuration", "None", "OpenVPN general configuration failed");

    pass3.openvpn_keyring_failed::
      "any" usebundle => rudder_common_report("openvpnClientConfiguration", "result_error", "&TRACKINGKEY&", "OpenVPN configuration", "None", "OpenVPN keyring could not be written");

    pass3.(ovpn_client_nopwauth.((openvpn_tier1_validated.openvpn_tier2_validated)|(openvpn_tier1_kept.openvpn_tier2_kept)))::
      "any" usebundle => rudder_common_report("openvpnClientConfiguration", "result_success", "&TRACKINGKEY&", "OpenVPN configuration", "None", "OpenVPN configuration is set correctly");

    pass3.(ovpn_client_pwauth.((openvpn_tier1_validated.openvpn_tier2_validated.openvpn_keyring_validated)|(openvpn_tier1_kept.openvpn_tier2_kept.openvpn_keyring_kept)))::
      "any" usebundle => rudder_common_report("openvpnClientConfiguration", "result_success", "&TRACKINGKEY&", "OpenVPN configuration", "None", "OpenVPN configuration is set correctly");

    pass3.((openvpn_tier1_validated.openvpn_tier2_validated.openvpn_keyring_validated)|(openvpn_tier1_kept.openvpn_tier2_kept.openvpn_keyring_kept))::
      "any" usebundle => rudder_common_report("openvpnClientConfiguration", "result_success", "&TRACKINGKEY&", "OpenVPN configuration", "None", "OpenVPN configuration is set correctly"),
        ifvarclass => canonify("ovpn_client_pwauth");

    pass3.ovpn_client_autostart.service_ensure_started_at_boot_openvpn_repaired::
      "any" usebundle => rudder_common_report("openvpnClientConfiguration", "log_repaired", "&TRACKINGKEY&", "OpenVPN configuration", "None", "OpenVPN is now starting on boot");

    pass3.ovpn_client_autostart.service_ensure_started_at_boot_openvpn_not_ok::
      "any" usebundle => rudder_common_report("openvpnClientConfiguration", "result_error", "&TRACKINGKEY&", "OpenVPN configuration", "None", "OpenVPN could not be set to start on boot");

    pass3.ovpn_client_autostart.service_ensure_started_at_boot_openvpn_ok::
      "any" usebundle => rudder_common_report("openvpnClientConfiguration", "log_info", "&TRACKINGKEY&", "OpenVPN configuration", "None", "OpenVPN already set to start on boot");

    pass3.service_restart_openvpn_ok::
      "any" usebundle => rudder_common_report("openvpnClientConfiguration", "log_repaired", "&TRACKINGKEY&", "OpenVPN configuration", "None", "OpenVPN restarted");

    pass3.service_restart_openvpn_not_ok::
      "any" usebundle => rudder_common_report("openvpnClientConfiguration", "result_error", "&TRACKINGKEY&", "OpenVPN configuration", "None", "Could not restart OpenVPN");

    pass3.(!openvpn_bin_present)::
      "any" usebundle => rudder_common_report("openvpnClientConfiguration", "result_error", "&TRACKINGKEY&", "OpenVPN configuration", "None", "OpenVPN binary is not present. Something is wrong (installation failure?)");

  processes:

    ovpn_client_autostart::

      "/usr/sbin/openvpn"
        restart_class => "openvpn_down",
        comment => "Ensuring openvpn is up";

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
      "${rudder_parameters.rudder_file_edit_header}"
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
