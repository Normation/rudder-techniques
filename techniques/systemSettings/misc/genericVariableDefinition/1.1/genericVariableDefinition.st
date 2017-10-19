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

bundle common generic_variable_definition
{

  vars:

&GENERIC_VARIABLE_NAME, GENERIC_VARIABLE_CONTENT:{name, content |"&name&" string => "&content&";
}&

}

bundle agent generic_variable_def_report
{
  vars:
                &TRACKINGKEY:{directiveId |"generic_name_uuid[&i&]" string => "&directiveId&";
}&
                &GENERIC_VARIABLE_NAME:{name |"generic_variable_name[&i&]" string => "&name&";
}&

      "generic_variable_name_index" slist => getindices("generic_name_uuid");

  reports:

    cfengine_3::

      "@@genericVariableDefinition@@result_success@@${generic_name_uuid[${generic_variable_name_index}]}@@Variable definition@@${generic_variable_name[${generic_variable_name_index}]}@@${g.execRun}##${g.uuid}@#A generic variable definition is set for variable ${generic_variable_name[${generic_variable_name_index}]}";

}
