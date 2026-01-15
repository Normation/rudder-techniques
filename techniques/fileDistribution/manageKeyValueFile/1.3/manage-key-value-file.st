# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: 2021 Normation SAS

bundle agent manage_key_value_file_&RudderUniqueID& {
  vars:
      &MANAGE_KEY_VALUE_FILEPATH:{file |  "file[&i&]"        string => "&file&";
}&
      &MANAGE_KEY_VALUE_KEY:{key |  "key[&i&]"         string => "&key&";
}&
      &MANAGE_KEY_VALUE_VALUE:{value |  "value[&i&]"       string => "&value&";
}&
      &MANAGE_KEY_VALUE_SEPARATOR:{separator |  "separator[&i&]"   string => "&separator&";
}&
      &MANAGE_KEY_VALUE_OPTION:{option |  "option[&i&]"   string => "&option&";
}&
&MANAGE_KEY_VALUE_POST_HOOK_COMMAND:{post_hook |  "post_hook[&i&]"   string => "&post_hook&";
}&
    "index"                          slist => getindices("file");
    "hash[${index}]"                 string => hash("${file[${index}]} ${key[${index}]} ${value[${index}]} ${separator[${index}]} ${option[${index}]}", "sha256");

  classes:
      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";

  methods:
    pass3::
      "${report_data.method_id}" usebundle => manage_key_value_file_edit_&RudderUniqueID&("File", "${file[${index}]}", "${file[${index}]}", "${key[${index}]}", "${value[${index}]}", "${separator[${index}]}", "${option[${index}]}", "${hash[${index}]}");
      "${report_data.method_id}" usebundle => manage_key_value_file_posthook_&RudderUniqueID&("Post-modification script", "${file[${index}]}", "${post_hook[${index}]}", "${hash[${index}]}");
}

bundle agent manage_key_value_file_posthook_&RudderUniqueID&(c_name, c_key, command, hash) {
  classes:
      "pass3"      expression => "pass2";
      "pass2"      expression => "pass1";
      "pass1"      expression => "any";
      "hook_empty" expression => strcmp("${command}", "");

  methods:
    pass3::
      "${report_data.method_id}" usebundle => _method_reporting_context_v4("${c_name}", "${c_key}", "${hash}_posthook");
    "pass3.(hook_empty|!${hash}_repaired)"::
      "${report_data.method_id}" usebundle => _classes_noop("${report_data.method_id}");

    "pass3.!(hook_empty|!${hash}_repaired)"::
      "${report_data.method_id}" usebundle => call_method("command_execution");
      "${report_data.method_id}" usebundle => command_execution("${command}");
      "${report_data.method_id}" usebundle => call_method_classes_caller;
      "${report_data.method_id}" usebundle => call_method_end("command_execution");

    pass3::
      "${report_data.method_id}" usebundle => log_rudder_v4("${c_key}", "The hook '${command}'", "");
}

bundle agent manage_key_value_file_edit_&RudderUniqueID&(c_name, c_key, file, key, value, separator, option, hash) {
  classes:
      "pass3"            expression => "pass2";
      "pass2"            expression => "pass1";
      "pass1"            expression => "any";
  methods:
    pass3::
      "${report_data.method_id}" usebundle => _method_reporting_context_v4("${c_name}", "${c_key}", "${hash}_edit");
      "${report_data.method_id}" usebundle => call_method("${hash}");
      "${report_data.method_id}" usebundle => file_ensure_key_value_option("${file}", "${key}", "${value}", "${separator}", "${option}");
      # Copy the resulting condition to the ${hash} prefix
      "${report_data.method_id}" usebundle => call_method_classes("${hash}");
      "${report_data.method_id}" usebundle => call_method_classes_caller;
      "${report_data.method_id}" usebundle => call_method_end("${hash}");
      "${report_data.method_id}" usebundle => log_rudder_v4("${file}", "The key -> value ${key} ${separator} ${value} with ${option} spacing around the separator", "");
}
