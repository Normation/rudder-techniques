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
# Configures the RUG/YaST Package Managers using ZMD #
######################################################

bundle agent check_zmd_settings {

	classes:

		# Repositories edition ?
		"zmd_repositories_edit" not => strcmp("&ZMD_ADDREPOSITORIES&","false");

		# Disable repositories ?
		"zmd_disablerepositories" not => strcmp("&ZMD_DISABLEREPOSITORIES&","false");

		# Package sources policy edition ?
		"zmd_sources_policy_edit" not => strcmp("&ZMD_SOURCEPOLICY&","dontchange");

		# Is the checkzmd script present ?
		"checkzmd_present" expression => fileexists("${g.rudder_dependencies}/checkzmd.pl");

	vars:

		zmd_sources_policy_edit::

			"zmdconf[security-level]" string => "&ZMD_SOURCEPOLICY&";

		any::

		&ZMD_URL:{zmd_url |"zmd_url[&i&]" string => "&zmd_url&";
}&

		&ZMD_NAME:{zmd_name |"zmd_name[&i&]" string => "&zmd_name&";
}&

                &TRACKINGKEY:{uuid |"zmd_uuid[&i&]" string => "&uuid&";
}&

		"zmd_index" slist => getindices("zmd_url");

	processes:

		"/usr/lib/zmd/zmd.exe"
			restart_class => "zmd_restart";

	commands:

		SuSE.checkzmd_present::

			"${g.rudder_dependencies}/checkzmd.pl \"$(zmd_name[$(zmd_index)])\" \"$(zmd_url[$(zmd_index)])\" $(zmd_index)"
				contain => in_shell,
				module => "true",
				comment => "Analyzing ZMD's output";

		SuSE.zmd_repositories_edit::

			"/usr/bin/rug"
				args => "sa --type=zypp \"$(zmd_url[$(zmd_index)])\" \"$(zmd_name[$(zmd_index)])\"",
				ifvarclass => "index_$(zmd_index)_not_matched",
				classes => kept_if_else("source_$(zmd_index)_kept", "source_$(zmd_index)_added", "source_$(zmd_index)_failed"),
				comment => "Add the $(zmd_index) as a new source";

			"/usr/bin/rug"
				args => "subscribe \"$(zmd_name[$(zmd_index)])\"",
				ifvarclass => "source_$(zmd_index)_added",
				classes => kept_if_else("source_$(zmd_index)_subkept", "source_$(zmd_index)_subscribed", "source_$(zmd_index)_subfailed"),
				comment => "Subscribe $(zmd_index) as a new source";
				
		SuSE.(zmd_restart|zmd_conf_validated)::

			"/etc/init.d/novell-zmd"
				args => "restart",
				classes => kept_if_else("zmd_kept", "zmd_restarted", "could_not_restart_zmd"),
				comment => "Restart the ZMD daemon";
	files:

		SuSE::

			"/etc/zmd/zmd.conf"
				create => "true",
				perms => mog("600", "root", "root"),
				edit_defaults => std_defs,
				edit_line => set_zmd_config_values("check_zmd_settings.zmdconf"),
				classes => kept_if_else("zmd_conf_kept", "zmd_conf_validated", "zmd_conf_failed");

	reports:


		# ZMD settings edition

		zmd_conf_kept::
			"@@zmdPackageManagerSettings@@result_success@@&TRACKINGKEY&@@General settings@@None@@$(g.execRun)##$(g.uuid)@#ZMD settings were all already correct";

		zmd_conf_validated::
			"@@zmdPackageManagerSettings@@result_repaired@@&TRACKINGKEY&@@General settings@@None@@$(g.execRun)##$(g.uuid)@#Some ZMD settings were reset";

		zmd_conf_failed::
			"@@zmdPackageManagerSettings@@result_error@@&TRACKINGKEY&@@General settings@@None@@$(g.execRun)##$(g.uuid)@#ZMD repositories could not be edited";

		# Ignore non-SuSE OSes

		!SuSE::
			"@@zmdPackageManagerSettings@@result_error@@&TRACKINGKEY&@@zmdPackageManagerSettings@@None@@$(g.execRun)##$(g.uuid)@#ZMD cannot be configured on non SuSE OSes";

		SuSE::

			# Repositories

			"@@zmdPackageManagerSettings@@result_success@@&TRACKINGKEY&@@Repository@@$(zmd_url[$(zmd_index)])@@$(g.execRun)##$(g.uuid)@#The ZMD source $(zmd_name[$(zmd_index)]) was already here. Skipping..."
				ifvarclass => "index_$(zmd_index)_matched.!source_$(zmd_index)_subscribed";

			"@@zmdPackageManagerSettings@@result_repaired@@&TRACKINGKEY&@@Repository@@$(zmd_url[$(zmd_index)])@@$(g.execRun)##$(g.uuid)@#The ZMD source $(zmd_name[$(zmd_index)]) has been successfully added"
				ifvarclass => "index_$(zmd_index)_not_matched.source_$(zmd_index)_subscribed";

			"@@zmdPackageManagerSettings@@result_error@@&TRACKINGKEY&@@Repository@@$(zmd_url[$(zmd_index)])@@$(g.execRun)##$(g.uuid)@#The ZMD source $(zmd_name[$(zmd_index)]) was NOT added : Could not register the source !"
				ifvarclass => "source_$(zmd_index)_failed";

			"@@zmdPackageManagerSettings@@result_error@@&TRACKINGKEY&@@Repository@@$(zmd_url[$(zmd_index)])@@$(g.execRun)##$(g.uuid)@#The ZMD source $(zmd_name[$(zmd_index)]) was NOT added : Could not subscribe to the source !"
				ifvarclass => "source_$(zmd_index)_subfailed";


			# ZMD Process presence related reports

			"@@zmdPackageManagerSettings@@result_success@@&TRACKINGKEY&@@ZMD process@@None@@$(g.execRun)##$(g.uuid)@#The ZMD process is present. Skipping ..."
				ifvarclass => "!zmd_restart";

			"@@zmdPackageManagerSettings@@result_repaired@@&TRACKINGKEY&@@ZMD process@@None@@$(g.execRun)##$(g.uuid)@#The ZMD daemon was successfully restarted"
				ifvarclass => "zmd_restarted";

			"@@zmdPackageManagerSettings@@result_error@@&TRACKINGKEY&@@ZMD process@@None@@$(g.execRun)##$(g.uuid)@#The ZMD daemon failed to restart"
				ifvarclass => "could_not_restart_zmd";

}

bundle edit_line set_zmd_config_values(tab)

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

# 	"// #############################################################
# // ### This file is protected by your Rudder infrastructure. ###
# // ### Manually editing the file might lead your Rudder      ###
# // ### infrastructure to change back the server’s            ###
# // ### configuration and/or to raise a compliance alert.     ###
# // #############################################################
# "
#                 location => start,
#                 insert_type => "preserve_block";

	"$(index)=$($(tab)[$(index)])",
		ifvarclass => "!not_$(cindex[$(index)])";

}
