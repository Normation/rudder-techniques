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
# Configure the port numbers in the OpenSSH configuration file
# The argument can be either a string or a slist
#
bundle edit_line rudder_openssh_server_port_configuration(portlist)
{
  vars:
      "ports" slist => maplist("Port ${this}", "portlist");

  delete_lines:
      "Port.*"
         delete_select => delete_if_not_in_list("@{this.ports}");

  insert_lines:
      "${ports}";
}

#
# Configure listen adresses  in the OpenSSH configuration file
# The argument can be either a string or a slist
#
bundle edit_line rudder_openssh_server_address_configuration(addresslist)
{
  vars:
      "addresses" slist => maplist("ListenAddress ${this}", "addresslist");

  delete_lines:
      "ListenAddress.*"
         delete_select => delete_if_not_in_list("@{this.addresses}");

  insert_lines:
      "${addresses}";
}
