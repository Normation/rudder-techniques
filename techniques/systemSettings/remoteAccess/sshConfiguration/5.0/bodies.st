#####################################################################################
# Copyright 2011-2013 Normation SAS
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

#
# Configure the port numbers/listen addresses in the OpenSSH configuration file
# The first arguement is the name of parameter in the config file, second is the values (either a string or a slist)
#
bundle edit_line rudder_openssh_server_parameters_configuration(parameter_name, values)
{
  vars:
      "entries" slist => maplist("${parameter_name} ${this}", "values");

  delete_lines:
      "${parameter_name}.*"
        delete_select => rudder_delete_if_not_in_list("@{this.entries}");

  insert_lines:
      "${entries}";
}
