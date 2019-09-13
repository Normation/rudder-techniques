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
      &TRACKINGKEY:{uuid |  "trackingkey[&i&]" string => "&uuid&";
}&


    "index" slist => getindices("file");

    "args"  slist => { "${file[${index}]}", "${key[${index}]}", "${value[${index}]}","${separator[${index}]}", "${option[${index}]}" };
    "report_param[${index}]"         string => join("_", args);
    "canonified_params[${index}]"    string => canonify("${report_param[${index}]}");

    "class_prefix_${index}"          string => "file_ensure_key_value_${canonified_params[${index}]}";
    "technique_name"                 string => "Manage keys-values file";


  methods:
    "apply_${index}"   usebundle => file_ensure_key_value_option("${file[${index}]}", "${key[${index}]}", "${value[${index}]}", "${separator[${index}]}", "${option[${index}]}");
    "report_${index}"  usebundle => rudder_common_reports_generic_index("${technique_name}", "${class_prefix_${index}}",    "${trackingkey[${index}]}", "File", "${file[${index}]}", "The key -> value ${key[${index}]} ${separator[${index}]} ${value[${index}]} with ${option[${index}]} spacing around the separator", "${index}");

}
