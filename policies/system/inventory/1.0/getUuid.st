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

############################################################
# Get the uuid from the Rudder server
############################################################

# Get the file from the promises server
bundle agent fusion_getuuid
{

commands:

    linux::
		"/usr/bin/curl"
			args => "-o \"$(g.rudder_var_tmp)/uuid.txt\" http://${server_info.cfserved}/uuid",
			comment => "Getting the uuid from the server";

    windows::
		"\"${g.rudder_base_sbin}\curl\curl.exe\""
			args => "-o \"$(g.rudder_var_tmp)\uuid.txt\" http://${server_info.cfserved}/uuid",
			comment => "Getting the uuid from the server";

}
