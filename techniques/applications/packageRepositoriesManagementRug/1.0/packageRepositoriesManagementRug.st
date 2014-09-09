#####################################################################################
# Copyright 2013 Normation SAS
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

bundle agent check_rug_mgr_repositories {

	vars:
		class_ok::
		&TRACKINGKEY:{directiveId |"rug_mgr_conf[uuid][&i&]" string => "&directiveId&";
}&
		&ZMD_URL:{rug_mgr_url |"rug_mgr_url[&i&]" string => "&rug_mgr_url&";
}&
		&ZMD_NAME:{rug_mgr_name |"rug_mgr_name[&i&]" string => "&rug_mgr_name&";
}&
		"rug_mgr_index" slist => getindices("rug_mgr_url");

	classes:

		# Is the checkzmd script present ?
		"checkzmd_present" expression => fileexists("${g.rudder_dependencies}/checkzmd.pl");

		"class_ok" expression => strcmp("true", "true");

		"showtime" expression => isvariable("rug_mgr_sections");

	commands:

		showtime.SuSE.checkzmd_present::

			"${g.rudder_dependencies}/checkzmd.pl \"$(rug_mgr_name[$(rug_mgr_index)])\" \"$(rug_mgr_url[$(rug_mgr_index)])\" $(rug_mgr_index)"
				contain => in_shell,
				module => "true",
				comment => "Analyzing ZMD's output";

		showtime.SuSE::

			"/usr/bin/rug"
				args => "sa --type=zypp \"$(rug_mgr_url[$(rug_mgr_index)])\" \"$(rug_mgr_name[$(rug_mgr_index)])\"",
				ifvarclass => "index_$(rug_mgr_index)_not_matched",
				classes => kept_if_else("source_$(rug_mgr_index)_kept", "source_$(rug_mgr_index)_added", "source_$(rug_mgr_index)_failed"),
				comment => "Add the $(rug_mgr_index) as a new source";

			"/usr/bin/rug"
				args => "subscribe \"$(rug_mgr_name[$(rug_mgr_index)])\"",
				ifvarclass => "source_$(rug_mgr_index)_added",
				classes => kept_if_else("source_$(rug_mgr_index)_subkept", "source_$(rug_mgr_index)_subscribed", "source_$(rug_mgr_index)_subfailed"),
				comment => "Subscribe $(rug_mgr_index) as a new source";
				
	reports:
		# Ignore non-SuSE OSes

		!SuSE::
			"@@Package repositories management Rug@@result_error@@&TRACKINGKEY&@@Repository@@None@@$(g.execRun)##$(g.uuid)@#ZMD cannot be configured on non SuSE OSes";

		SuSE::

			# Repositories

			"@@Package repositories management Rug@@result_success@@&TRACKINGKEY&@@Repository@@$(rug_mgr_url[$(rug_mgr_index)])@@$(g.execRun)##$(g.uuid)@#The ZMD source $(rug_mgr_name[$(rug_mgr_index)]) was already here. Skipping..."
				ifvarclass => "index_$(rug_mgr_index)_matched.!source_$(rug_mgr_index)_subscribed";

			"@@Package repositories management Rug@@result_repaired@@&TRACKINGKEY&@@Repository@@$(rug_mgr_url[$(rug_mgr_index)])@@$(g.execRun)##$(g.uuid)@#The ZMD source $(rug_mgr_name[$(rug_mgr_index)]) has been successfully added"
				ifvarclass => "index_$(rug_mgr_index)_not_matched.source_$(rug_mgr_index)_subscribed";

			"@@Package repositories management Rug@@result_error@@&TRACKINGKEY&@@Repository@@$(rug_mgr_url[$(rug_mgr_index)])@@$(g.execRun)##$(g.uuid)@#The ZMD source $(rug_mgr_name[$(rug_mgr_index)]) was NOT added : Could not register the source !"
				ifvarclass => "source_$(rug_mgr_index)_failed";

			"@@Package repositories management Rug@@result_error@@&TRACKINGKEY&@@Repository@@$(rug_mgr_url[$(rug_mgr_index)])@@$(g.execRun)##$(g.uuid)@#The ZMD source $(rug_mgr_name[$(rug_mgr_index)]) was NOT added : Could not subscribe to the source !"
				ifvarclass => "source_$(rug_mgr_index)_subfailed";
}
