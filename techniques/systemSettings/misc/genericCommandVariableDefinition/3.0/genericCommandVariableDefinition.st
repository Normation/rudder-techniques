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

  classes:
    any::
      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";

  methods:

    pass3::

      "any" usebundle => rudder_common_report_index("genericCommandVariableDefinition", "result_success", "${generic_command_name_uuid[${generic_cmd_variable_name_index}]}", "Variable command definition", "${generic_cmd_variable_name[${generic_cmd_variable_name_index}]}", "A generic command variable definition is set for variable ${generic_cmd_variable_name[${generic_cmd_variable_name_index}]}", "${generic_cmd_variable_name_index}");

}
