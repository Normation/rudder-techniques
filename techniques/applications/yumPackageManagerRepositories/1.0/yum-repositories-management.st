bundle agent yum_repositories_management_&RudderUniqueID& {

  vars:
      &YUM_REPO_ID:{repo_id |"repo_id[&i&]" string => "&repo_id&";
}&
      &YUM_REPO_NAME:{repo_name |"repo_name[&i&]" string => "&repo_name&";
}&
      &YUM_REPO_ACTION:{repo_action |"repo_action[&i&]" string => "&repo_action&";
}&

      &YUM_REPO_URL:{repo_url |"repo_url[&i&]" string => "&repo_url&";
}&
      &YUM_REPO_ENABLED:{repo_enabled |"repo_enabled[&i&]" string => "&repo_enabled&";
}&
      &YUM_REP_GPG_CHECK:{repo_gpg_check |"repo_gpg_check[&i&]" string => "&repo_gpg_check&";
}&
      &YUM_REPO_GPG_URI:{repo_gpg_uri |"repo_gpg_uri[&i&]" string => "&repo_gpg_uri&";
}&
      &TRACKINGKEY:{uuid |"trackingkey[&i&]" string => "&uuid&";
}&

      "index" slist => getindices("repo_id");


      # Construct the identifier string to grep: \[repo_id\], with start and end line
      # there may be some spaces after the repo identifier
      "grep_repo_id[${index}]" string => "^\[${repo_id[${index}]}\]\s*$";
      
    pass1::
      "filename[${index}]" string => execresult("${paths.grep} -rl '${grep_repo_id[${index}]}' /etc/yum.repos.d", "noshell");
      
      # override filename if repo is absent
      "filename[${index}]" string => "/etc/yum.repos.d/rudder-${repo_id[${index}]}.repo",
                                if => "repo_entry_absent_${index}";
      
      "canonified_filename[${index}]" string => canonify("${filename[${index}]}");

  classes:
      "delete_repo_${index}" expression => strcmp("${repo_action[${index}]}", "delete");

      "is_yum_present"       expression => fileexists("/usr/bin/yum");

    pass1::
      "repo_entry_absent_${index}" expression => strcmp("${filename[${index}]}", "");

    any::
      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";


  methods:
    pass2.is_yum_present::
      # create or enforce entries
      # if file doesn't exist yet, we need to precreate it with an empty section, and a blank line
      "create file ${index}"       usebundle => file_content("${filename[${index}]}", "[${repo_id[${index}]}]
", "false"),
                                          if => "!delete_repo_${index}.repo_entry_absent_${index}";
      "set repo name ${index}"     usebundle => file_key_value_present_in_ini_section("${filename[${index}]}", "${repo_id[${index}]}", "name", "${repo_name[${index}]}"),
                                          if => "!delete_repo_${index}";
      "set repo url ${index}"      usebundle => file_key_value_present_in_ini_section("${filename[${index}]}", "${repo_id[${index}]}", "baseurl", "${repo_url[${index}]}"),
                                          if => "!delete_repo_${index}";
      "set repo enabled ${index}"  usebundle => file_key_value_present_in_ini_section("${filename[${index}]}", "${repo_id[${index}]}", "enabled", "${repo_enabled[${index}]}"),
                                          if => "!delete_repo_${index}";
      "set repo gpgcheck ${index}" usebundle => file_key_value_present_in_ini_section("${filename[${index}]}", "${repo_id[${index}]}", "gpgcheck", "${repo_gpg_check[${index}]}"),
                                          if => "!delete_repo_${index}";
      "set repo gpg uri ${index}"  usebundle => file_key_value_present_in_ini_section("${filename[${index}]}", "${repo_id[${index}]}", "gpgkey", "${repo_gpg_uri[${index}]}"),
                                          if => "!delete_repo_${index}";


      # report
      # Using old_class_prefix to avoid having to copy all classes. Drawback is
      # if there are several repos managed in the same file, there will be
      # classes colision
      "report for modification"    usebundle => rudder_common_reports_generic_index("Package sources (Yum)", "file_key_value_present_in_ini_section_${canonified_filename[${index}]}", "${trackingkey[${index}]}", "Repositories", "${repo_id[${index}]}", "Setting repository ${repo_name[${index}]} with id ${repo_id[${index}]} ", "${index}"),
                                          if => "!delete_repo_${index}";
                                          
      # Deletion of repo
      "delete repo ${index}"      usebundle => clean_repo_file_&RudderUniqueID&("${index}"),
                                         if => "delete_repo_${index}.!repo_entry_absent_${index}";      
      
      "report for deletion"       usebundle => rudder_common_reports_generic_index("Package sources (Yum)", "yum_repositories_repo_removed_${repo_id[${index}]}", "${trackingkey[${index}]}", "Repositories", "${repo_id[${index}]}", "Deleting repository with id ${repo_id[${index}]} ", "${index}"),
                                         if => "delete_repo_${index}.!repo_entry_absent_${index}";

      "repo not there"            usebundle => rudder_common_report_index("Package sources (Yum)", "result_success", "${trackingkey[${index}]}", "Repositories", "${repo_id[${index}]}", "Deleting repository with id ${repo_id[${index}]} ", "${index}"),
                                          if => "repo_entry_absent_${index}";

      "trigger refresh if repo changed ${index}" usebundle => yum_repositories_set_refresh_condition_for_post_hook,
                                                        if => "file_key_value_present_in_ini_section_${canonified_filename[${index}]}_repaired|yum_repositories_repo_removed_${repo_id[${index}]}_repaired";

  !is_yum_present::
      "not a yum system"           usebundle => rudder_common_report_index("Package sources (Yum)", "result_na", "${trackingkey[${index}]}", "Repositories", "${repo_id[${index}]}", "Yum is not available on this system, skipping", "${index}");
}

# Delete repo entrys
bundle agent clean_repo_file_&RudderUniqueID&(index) {
  vars:
      # search all sections in the repos
      "grep_string_${index}"           string => "'^\[.*\]\s*$'";
      "numberofentriesinfile_${index}" string =>  execresult("${paths.grep} -cl '${grep_string_${index}}' /etc/yum.repos.d/${yum_repositories_management_&RudderUniqueID&.filename[${index}]}", "noshell");
      
      # innder class prefix
      "inner_class_prefix_file_absent_${index}" string => "file_absent_${yum_repositories_management_&RudderUniqueID&.canonified_filename[${index}]}";
      "inner_class_prefix_section_absent_${index}" string => "file_ini_section_absent_${yum_repositories_management_&RudderUniqueID&.canonified_filename[${index}]}_${yum_repositories_management_&RudderUniqueID&.repo_id[${index}]}";
  classes:
      "multiple_section_in_file_${index}" not => strcmp("${numberofentriesinfile_${index}}", "1");

  methods:
      # Deletion of repo
      "delete repo ${index}"      usebundle => file_absent("${yum_repositories_management_&RudderUniqueID&.filename[${index}]}"),
                                         if => "!multiple_section_in_file_${index}";
      # Deletion of repo
      "delete repo ${index}"      usebundle => file_ini_section_absent("${yum_repositories_management_&RudderUniqueID&.filename[${index}]}", "${yum_repositories_management_&RudderUniqueID&.repo_id[${index}]}"),
                                         if => "multiple_section_in_file_${index}";
      
      "combine class"             usebundle => ncf_classes_combine_two("${inner_class_prefix_file_absent_${index}}", "${inner_class_prefix_section_absent_${index}}", "yum_repositories_repo_removed_${yum_repositories_management_&RudderUniqueID&.repo_id[${index}]}");
}

