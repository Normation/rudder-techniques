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

bundle common generic_cmd_var_def {

	vars:

		&GENERIC_COMMAND_VARIABLE_NAME, GENERIC_COMMAND_VARIABLE_BINARY, GENERIC_COMMAND_VARIABLE_SHELL:{name, binary, shell |"&name&" string => execresult("&binary&", "&shell&");
}&
		
}

bundle agent generic_cmd_var_def_report {
	vars:
                &TRACKINGKEY:{directiveId |"generic_command_name_uuid[&i&]" string => "&directiveId&";
}& 
                &GENERIC_COMMAND_VARIABLE_NAME:{name |"generic_cmd_variable_name[&i&]" string => "&name&";
}&

		"generic_cmd_variable_name_index" slist => getindices("generic_command_name_uuid");

	reports:

		(linux|!linux)::

			"@@genericCommandVariableDefinition@@result_success@@${generic_command_name_uuid[${generic_cmd_variable_name_index}]}@@Variable command definition@@${generic_cmd_variable_name[${generic_cmd_variable_name_index}]}@@${g.execRun}##${g.uuid}@#A generic command variable definition is set for variable ${generic_cmd_variable_name[${generic_cmd_variable_name_index}]}";

}
