#####################################################################################
# Copyright 2016 Normation SAS
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

bundle agent manage_key_value_file_RudderUniqueID {
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
      &TRACKINGKEY:{uuid |  "trackingkey[&i&]" string => "&uuid&";
}&


    "index" slist => getindices("file");

    "args"  slist => { "${file[${index}]}", "${key[${index}]}", "${value[${index}]}","${separator[${index}]}", "${option[${index}]}" };
    "report_param[${index}]"         string => join("_", args);
    "canonified_params[${index}]"    string => canonify("${report_param[${index}]}");
    "canonified_hook[${index}]"      string => canonify("${post_hook[${index}]}");

    "class_prefix_${index}"          string => "file_ensure_key_value_${canonified_params[${index}]}";
    "hook_class_prefix_${index}"     string => "command_execution_${canonified_hook[${index}]}";
    "technique_name"                 string => "Manage keys-values file";

  classes:
    "hook_empty_${index}"        expression => strcmp("${post_hook[${index}]}", "");

  methods:
    "apply_${index}"   usebundle => file_ensure_key_value_option("${file[${index}]}", "${key[${index}]}", "${value[${index}]}", "${separator[${index}]}", "${option[${index}]}");
    "report_${index}"  usebundle => rudder_common_reports_generic_index("${technique_name}", "${class_prefix_${index}}", "${trackingkey[${index}]}", "File", "${file[${index}]}", "The key -> value ${key[${index}]} ${separator[${index}]} ${value[${index}]} with ${option[${index}]} spacing around the separator", "${index}");

  # call post-hooks
    "apply_${index}"   usebundle => command_execution("${post_hook[${index}]}"),
                      ifvarclass => "!hook_empty_${index}.${class_prefix_${index}}_repaired";
    "na_report"        usebundle => _classes_noop("${hook_class_prefix_${index}}"),
                      ifvarclass => "hook_empty_${index}|${class_prefix_${index}}_kept|${class_prefix_${index}}_error";
    "report_${index}"  usebundle => rudder_common_reports_generic_index("${technique_name}", "${hook_class_prefix_${index}}", "${trackingkey[${index}]}", "Post-modification script", "${file[${index}]}", "The hook '${post_hook[${index}]}'", "${index}");

}
