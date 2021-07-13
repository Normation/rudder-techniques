# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: 2021 Normation SAS

bundle common generic_variable_definition
{

  vars:

&GENERIC_VARIABLE_NAME, GENERIC_VARIABLE_CONTENT:{name, content |"&name&" string => "&content&",
        policy => "overridable";
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

  classes:
    any::
      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";

  methods:

    pass3.((linux|!linux))::

      "any" usebundle => rudder_common_report_index("genericVariableDefinition", "result_success", "${generic_name_uuid[${generic_variable_name_index}]}", "Variable definition", "${generic_variable_name[${generic_variable_name_index}]}", "A generic variable definition is set for variable ${generic_variable_name[${generic_variable_name_index}]}", "${generic_variable_name_index}");

}

