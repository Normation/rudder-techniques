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

#  Copyright (C) Normation

bundle agent check_motd_configuration
{

classes:

		"motd_absent" not => fileexists("/etc/motd");

vars:

		"motd" string => "&MOTD&";

		"motd_empty" string => "&MOTD_EMPTY&";

		"motd_uuid" string => "&TRACKINGKEY&";

	debian::

		"motd_file" slist => { "/etc/motd", "/etc/motd.tail" };

	!debian::

		"motd_file" slist => { "/etc/motd" };

files:

	!windows::

		"$(motd_file)"

			create => "true",
			edit_defaults => rudder_empty_select("$(motd_empty)"),
			perms  => mog("644", "root", "root"),
			edit_line => insert_lines("$(motd)"),
			classes => kept_if_else("motd_file_kept", "motd_file_edited", "motd_file_failed");

reports:

	motd_file_kept.!motd_file_edited::

		"@@motdConfiguration@@result_success@@$(motd_uuid)@@motdConfiguration@@None@@$(g.execRun)##$(g.uuid)@#The MOTD is in conformance with the policy";

	motd_file_edited::

		"@@motdConfiguration@@result_repaired@@$(motd_uuid)@@motdConfiguration@@None@@$(g.execRun)##$(g.uuid)@#The MOTD was successfully edited to match the policy";

	motd_file_failed::

		"@@motdConfiguration@@result_error@@$(motd_uuid)@@motdConfiguration@@None@@$(g.execRun)##$(g.uuid)@#Could not edit the MOTD";

	!windows.motd_absent::

		"@@motdConfiguration@@log_repaired@@$(motd_uuid)@@motdConfiguration@@None@@$(g.execRun)##$(g.uuid)@#The MOTD file was absent, I will create it";

	windows::

		"@@motdConfiguration@@result_error@@$(motd_uuid)@@motdConfiguration@@None@@$(g.execRun)##$(g.uuid)@#This is a Windows machine. This Policy Template currently incompatible with it";

}
