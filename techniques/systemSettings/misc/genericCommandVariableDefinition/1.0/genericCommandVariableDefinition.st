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

bundle common generic_command_variable_definition {

	vars:

		&GENERIC_COMMAND_VARIABLE_NAME, GENERIC_COMMAND_VARIABLE_BINARY:{name, binary |"&name&" string => execresult("&binary&", "noshell");
}&
		
}

bundle agent generic_command_variable_def_report {
	vars:
                &TRACKINGKEY:{directiveId |"generic_command_name_uuid[&i&]" string => "&directiveId&";
}& 
                &GENERIC_COMMAND_VARIABLE_NAME:{name |"generic_command_variable_name[&i&]" string => "&name&";
}&

		"generic_command_variable_name_index" slist => getindices("generic_command_name_uuid");

	reports:

		(linux|!linux)::

			"@@genericCommandVariableDefinition@@result_success@@$(generic_command_name_uuid[$(generic_command_variable_name_index)])@@Variable definition@@$(generic_command_variable_name[$(generic_command_variable_name_index)])@@$(g.execRun)##$(g.uuid)@#A generic command variable definition is set for variable $(generic_command_variable_name[$(generic_command_variable_name_index)])";

}
