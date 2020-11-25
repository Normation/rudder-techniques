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


      # Construct the identifier string : \[repo_id\]
      "grep_repo_id[${index}]" string => "\[${repo_id[${index}]}\]";
      
    pass1::
      "filename[${index}]" string => execresult("${paths.grep} -rl '${grep_repo_id[${index}]}' /etc/yum.repos.d", "noshell");
      
      # override filename if repo is absent
      "filename[${index}]" string => "/etc/yum.repos.d/rudder-${repo_id[${index}]}.repo",
                                if => "repo_entry_absent_${index}";
      
      "canonified_filename[${index}]" string => canonify("${filename[${index}]}");

  classes:
      "delete_repo_${index}" expression => strcmp("${repo_action$[${index}]}", "delete");

    pass1::
      "repo_entry_absent_${index}" expression => strcmp("${filename[${index}]}", "");


    any::
      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";


  methods:
    pass3::
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
      "delete repo ${index}"      usebundle => file_absent("${filename[${index}]}"),
                                         if => "delete_repo_${index}";
      "report for deletion"       usebundle => rudder_common_reports_generic_index("Package sources (Yum)", "file_absent_${canonified_filename[${index}]}", "${trackingkey[${index}]}", "Repositories", "${repo_id[${index}]}", "Deleting repository with id ${repo_id[${index}]} ", "${index}"),
                                          if => "delete_repo_${index}";
}
