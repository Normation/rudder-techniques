# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: 2021 Normation SAS

######################################################
# Configures the RUG/YaST Package Managers using ZMD #
######################################################

bundle agent check_zmd_settings
{

  vars:

        &TRACKINGKEY:{policyInstanceId |"zmdconf_uuid[&i&]" string => "&policyInstanceId&";
}&
    !no_proxy_edit::

      "zmdconf[Network][proxy-url]" string => "&ZMD_PROXY_URL&";

    proxy_edit_user::

      "zmdconf[Network][proxy-username]" string => "&ZMD_PROXY_USER&";

    proxy_edit_password::

      "zmdconf[Network][proxy-password]" string => "&ZMD_PROXY_PASSWORD&";

    class_ok::

    &ZMD_URL:{zmd_url |"zmd_url[&i&]" string => "&zmd_url&";
}&
    &ZMD_NAME:{zmd_name |"zmd_name[&i&]" string => "&zmd_name&";
}&
      "zmd_index" slist => getindices("zmd_url");

&if(ZMD_SET_REFRESH_INTERVAL)&
      "zmdconf[Server][refresh-interval]" string => "&ZMD_REFRESH_INTERVAL&";
&endif&

      "zmdconf[Advanced][security-level]" string => "&ZMD_SOURCEPOLICY&";

      "zmdconf[Server][remote-enabled]" string => "&ZMD_REMOTE_ENABLED&";

      "zmdconf[Debug][syslog-level]" string => "&ZMD_SYSLOG_LEVEL&";

      "zmd_sections" slist => getindices("zmdconf");

  classes:

    # Repositories edition ?
      "zmd_repositories_edit" not => strcmp("&ZMD_ADDREPOSITORIES&","false");

    # Disable repositories ?
      "zmd_disablerepositories" not => strcmp("&ZMD_DISABLEREPOSITORIES&","false");

    # Is the checkzmd script present ?
      "checkzmd_present" expression => fileexists("${this.promise_dirname}/checkzmd.pl");

    # Do we want to set the proxy ?
      "no_proxy_edit" expression => strcmp("&ZMD_PROXY_URL&", "");

    # Do we want to set the proxy username ?
      "proxy_edit_user" not => strcmp("&ZMD_PROXY_USER&", "");

    # Do we want to set the proxy username ?
      "proxy_edit_password" not => strcmp("&ZMD_PROXY_PASSWORD&", "");

      "class_ok" expression => strcmp("true", "true");

      "showtime" expression => isvariable("zmd_sections");

    any::
      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";

  files:

    showtime.SuSE::
      "/etc/zmd/zmd.conf"
        create => "true",
        perms => mog("600", "root", "0"),
        edit_defaults => noempty_backup,
        edit_line => set_advanced_zmd_config_values("check_zmd_settings.zmdconf", "${zmd_sections}"),
        classes => kept_if_else("zmd_conf_kept", "zmd_conf_validated", "zmd_conf_failed");


  methods:

    showtime.SuSE.(zmd_restart|zmd_conf_validated)::

      "restart_zmd" usebundle => service_restart("novell-zmd");

    # ZMD settings edition

    pass3.zmd_conf_kept::
      "any" usebundle => rudder_common_report("zmdPackageManagerSettings", "result_success", "${zmdconf_uuid[${zmd_index}]}", "General settings", "None", "ZMD settings were all already correct");

    pass3.zmd_conf_validated::
      "any" usebundle => rudder_common_report("zmdPackageManagerSettings", "result_repaired", "${zmdconf_uuid[${zmd_index}]}", "General settings", "None", "Some ZMD settings were reset");

    pass3.zmd_conf_failed::
      "any" usebundle => rudder_common_report("zmdPackageManagerSettings", "result_error", "${zmdconf_uuid[${zmd_index}]}", "General settings", "None", "ZMD repositories could not be edited");
      "any" usebundle => rudder_common_report("zmdPackageManagerSettings", "result_error", "&TRACKINGKEY&", "General settings", "None", "ZMD repositories could not be edited");

    # Ignore non-SuSE OSes

    pass3.(!SuSE)::
      "any" usebundle => rudder_common_report("zmdPackageManagerSettings", "result_error", "${zmdconf_uuid[${zmd_index}]}", "zmdPackageManagerSettings", "None", "ZMD cannot be configured on non SuSE OSes");

    pass3.SuSE::

      # Repositories

      "any" usebundle => rudder_common_report("zmdPackageManagerSettings", "result_success", "${zmdconf_uuid[${zmd_index}]}", "Repository", "${zmd_url[${zmd_index}]}", "The ZMD source ${zmd_name[${zmd_index}]} is not here but no edition required. Skipping..."),
        ifvarclass => "index_${zmd_index}_not_matched.!zmd_repositories_edit";

      "any" usebundle => rudder_common_report("zmdPackageManagerSettings", "result_success", "${zmdconf_uuid[${zmd_index}]}", "Repository", "${zmd_url[${zmd_index}]}", "The ZMD source ${zmd_name[${zmd_index}]} was already here. Skipping..."),
        ifvarclass => "index_${zmd_index}_matched.!source_${zmd_index}_subscribed";

      "any" usebundle => rudder_common_report("zmdPackageManagerSettings", "result_repaired", "${zmdconf_uuid[${zmd_index}]}", "Repository", "${zmd_url[${zmd_index}]}", "The ZMD source ${zmd_name[${zmd_index}]} has been successfully added"),
        ifvarclass => "index_${zmd_index}_not_matched.source_${zmd_index}_subscribed";

      "any" usebundle => rudder_common_report("zmdPackageManagerSettings", "result_error", "${zmdconf_uuid[${zmd_index}]}", "Repository", "${zmd_url[${zmd_index}]}", "The ZMD source ${zmd_name[${zmd_index}]} was NOT added : Could not register the source !"),
        ifvarclass => "source_${zmd_index}_failed";

      "any" usebundle => rudder_common_report("zmdPackageManagerSettings", "result_error", "${zmdconf_uuid[${zmd_index}]}", "Repository", "${zmd_url[${zmd_index}]}", "The ZMD source ${zmd_name[${zmd_index}]} was NOT added : Could not subscribe to the source !"),
        ifvarclass => "source_${zmd_index}_subfailed";

      # ZMD Process presence related reports

    pass3.SuSE.!zmd_restart::
      "any" usebundle => rudder_common_report("zmdPackageManagerSettings", "result_success", "${zmdconf_uuid[${zmd_index}]}", "ZMD process", "None", "The ZMD process is present. Skipping ...");

    pass3.SuSE.service_restart_novell_zmd_ok::
      "any" usebundle => rudder_common_report("zmdPackageManagerSettings", "result_repaired", "${zmdconf_uuid[${zmd_index}]}", "ZMD process", "None", "The ZMD daemon was successfully restarted");

    pass3.SuSE.service_restart_novell_zmd_not_ok::
      "any" usebundle => rudder_common_report("zmdPackageManagerSettings", "result_error", "${zmdconf_uuid[${zmd_index}]}", "ZMD process", "None", "The ZMD daemon failed to restart");

  processes:

      "/usr/lib/zmd/zmd.exe"
        restart_class => "zmd_restart";

  commands:

    showtime.SuSE.checkzmd_present::

      "${this.promise_dirname}/checkzmd.pl \"${zmd_name[${zmd_index}]}\" \"${zmd_url[${zmd_index}]}\" ${zmd_index}"
        contain => in_shell,
        module => "true",
        comment => "Analyzing ZMD's output";

    showtime.SuSE.zmd_repositories_edit::

      "/usr/bin/rug"
        args => "sa --type=zypp \"${zmd_url[${zmd_index}]}\" \"${zmd_name[${zmd_index}]}\"",
        ifvarclass => "index_${zmd_index}_not_matched",
        classes => kept_if_else("source_${zmd_index}_kept", "source_${zmd_index}_added", "source_${zmd_index}_failed"),
        comment => "Add the ${zmd_index} as a new source";

      "/usr/bin/rug"
        args => "subscribe \"${zmd_name[${zmd_index}]}\"",
        ifvarclass => "source_${zmd_index}_added",
        classes => kept_if_else("source_${zmd_index}_subkept", "source_${zmd_index}_subscribed", "source_${zmd_index}_subfailed"),
        comment => "Subscribe ${zmd_index} as a new source";

}


bundle edit_line set_advanced_zmd_config_values(tab, sectionName)
{
 # Sets the RHS of configuration items in the file of the form
 # LHS=RHS
 # If the line is commented out with #, it gets uncommented first.
 # Adds a new line if none exists.
 # The argument is an associative array containing tab[SectionName][LHS]="RHS"
 # don't change value when the RHS is dontchange

 # Based on set_variable_values from cfengine_stdlib.cf, modified to
 # use section to define were to write, and to handle commented-out lines.

 # CAUTION : for it to work nicely, you should use Cfengine with the commit n°3229
 # otherwise you may risk a segfault

  vars:
      "index" slist => getindices("${tab}[${sectionName}]");

  # Be careful if the index string contains funny chars
      "cindex[${index}]" string => canonify("${index}");

  classes:
      "edit_${cindex[${index}]}" not => strcmp("${${tab}[${sectionName}][${index}]}","dontchange");

  field_edits:

  # If the line is there, but commented out, first uncomment it
      "#+${index}=.*"
        select_region => INI_section("${sectionName}"),
        edit_field => col("=","1","${index}","set"),
        ifvarclass => "edit_${cindex[${index}]}";

  # match a line starting like the key something
      "${index}=.*"
        edit_field => col("=","2","${${tab}[${sectionName}][${index}]}","set"),
        select_region => INI_section("${sectionName}"),
        classes => if_ok("not_${cindex[${index}]}"),
        ifvarclass => "edit_${cindex[${index}]}";

  insert_lines:
      "[${sectionName}]"
        location => start;

      "${index}=${${tab}[${sectionName}][${index}]}"
        select_region => INI_section("${sectionName}"),
        ifvarclass => "!not_${cindex[${index}]}.edit_${cindex[${index}]}";

}


