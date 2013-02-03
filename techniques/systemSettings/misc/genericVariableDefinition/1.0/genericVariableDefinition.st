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

bundle common generic_variable_definition {

  vars:

    &GENERIC_VARIABLE_NAME, GENERIC_VARIABLE_CONTENT:{name, content |"&name&" string => "&content&";
}&
}

bundle agent generic_variable_definition_report {

  reports:

    (linux|!linux)::

      "@@genericVariableDefinition@@result_success@@&TRACKINGKEY&@@genericVariableDefinition@@None@@${g.execRun}##${g.uuid}@#A generic variable definition Policy Instance is active";

}
