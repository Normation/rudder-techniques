# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: 2025 Normation SAS

#
# Configure the port numbers/listen addresses in the OpenSSH configuration file
# The first argument is the name of parameter in the config file, second is the values (either a string or a slist)
#
bundle edit_line rudder_openssh_server_parameters_configuration(parameter_name, values)
{
  vars:
      "entries" slist => maplist("${parameter_name} ${this}", "values");

  delete_lines:
      "${parameter_name}.*"
        delete_select => ncf_delete_if_not_in_list("@{this.entries}");

  insert_lines:
      "${entries}";
}
