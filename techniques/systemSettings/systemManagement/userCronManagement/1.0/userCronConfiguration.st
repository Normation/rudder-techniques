#####################################################################################
# Configure user cron in /var/spool/cron/crontabs
#####################################################################################

bundle agent user_cron_configuration_&RudderUniqueID&
{

  vars:

    &USER_CRON_TAG:{cron_tag |"cron_tag[&i&]" string => "&cron_tag&";
}&

    &USER_CRON_USER:{cron_user |"cron_user[&i&]" string => "&cron_user&";
}&

&USER_CRON_COMMAND:{cron_command |"cron_command[&i&]" string => "&cron_command&";
}&

    &USER_CRON_FREQUENCY:{cron_frequency |"cron_frequency[&i&]" string => "&cron_frequency&";
}&


    &TRACKINGKEY:{uuid |"cron_uuid[&i&]" string => "&uuid&";
}&

      "cron_index" slist => getindices("cron_tag");
      
      
    solaris|debian|bsd|aix::
      "cron_base_path" string => "/var/spool/cron/crontabs";
    suse::
      "cron_base_path" string => "/var/spool/cron/tabs";
    redhat::
      "cron_base_path" string => "/var/spool/cron";


    pass1::
      # compute group for cronta file. crontab on debian,est the gid of user
      "user_complete_data_${cron_index}" data => getuserinfo("${cron_user[${cron_index}]}"),
                               if => "user_${cron_index}_exists";
    
    pass1.debian::
      "user_gid_${cron_index}" string => "crontab";
    pass1.!debain::
      "user_gid_${cron_index}" string => "${user_complete_data_${cron_index}[gid]}",
                                   if => "user_${cron_index}_exists";
                               
  classes:
  
      "user_${cron_index}_exists" expression => userexists("${cron_user[${cron_index}]}");

    pass2::
      "user_cron_configuration_need_reload_posthook" expression => "user_cron_file_configuration_${cron_index}_&RudderUniqueID&_repaired",
                                                          scope => "namespace";           
    any::
      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";


  files:
      "${cron_base_path}/${cron_user[${cron_index}]}"
        create        => "true",
        perms         => mog("600", "${cron_user[${cron_index}]}", "${user_gid_${cron_index}}"),
        edit_line     => append_or_replace_crontab_with_tag_entry_&RudderUniqueID&("${cron_tag[${cron_index}]}", "${cron_command[${cron_index}]}", "${cron_frequency[${cron_index}]}", "${cron_index}"),
        classes       => classes_generic("user_cron_file_configuration_${cron_index}_&RudderUniqueID&"),
        if            => "user_${cron_index}_exists";


  methods:
    pass3::
    # Reports about the creation of the cron entries
      "any" usebundle => rudder_common_reports_generic_index("userCronConfiguration", "user_cron_file_configuration_${cron_index}_&RudderUniqueID&", "${cron_uuid[${cron_index}]}", "User cron entry", "${cron_tag[${cron_index}]}", "The cron entry for user ${cron_user[${cron_index}]} with tag ${cron_tag[${cron_index}]} ", "${cron_index}");
      
      "user_absent" usebundle => rudder_common_report_index("userCronConfiguration", "result_error", "${cron_uuid[${cron_index}]}", "User cron entry", "${cron_tag[${cron_index}]}", "The user ${cron_user[${cron_index}]}, for tag ${cron_tag[${cron_index}]} does not exists", "${cron_index}"),
                           if => "!user_${cron_index}_exists";
      
}

      
# check if line with the #tag exist, with a different command
# If so, replace it, else add it
bundle edit_line append_or_replace_crontab_with_tag_entry_&RudderUniqueID&(tag, command, frequency, index) {
  vars:
      "eline"
        comment     => "An escaped version of the frequency + command",
        string      => escape("${frequency} ${command}");


  insert_lines:

    "${frequency} ${command} #${tag}"
      # NOTE: this is only to ensure that insert is attempted *after* the replace,
      ifvarclass    => canonify("user_cron_configuration_replace_step_attempted_${index}_&RudderUniqueID&");

    replace_patterns:
    "^(?!${eline}.* #${tag}.*$)(.* #${tag}.*)$"
      comment       => "Replace the frequency/command here",
      replace_with  => value("${frequency} ${command} #${tag}"),
      classes       => always("user_cron_configuration_replace_step_attempted_${index}_&RudderUniqueID&");

}

