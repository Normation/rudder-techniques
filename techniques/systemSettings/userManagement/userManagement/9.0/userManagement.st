# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: 2021 Normation SAS

##########################################################################
# User management Technique                                              #
#                                                                        #
# Objective : Apply user/group policies on the target host               #
##########################################################################

bundle agent check_usergroup_user_parameters_&RudderUniqueID&
{

  vars:

    &USERGROUP_USER_LOGIN:{login |"usergroup_user_login[&i&]" string => "&login&";
}&

    &USERGROUP_USER_GROUP:{group |"usergroup_user_groupname[&i&]" string => "&group&";
}&

    &USERGROUP_FORCE_USER_GROUP:{force_group |"usergroup_force_user_groupname[&i&]" string => "&force_group&";
}&

    &USERGROUP_USER_NAME:{name |"usergroup_user_fullname[&i&]" string => "&name&";
}&

    &USERGROUP_USER_PASSWORD:{password |"usergroup_user_password[&i&]" string => "&password&";
}&

    &USERGROUP_USER_PASSWORD_AIX:{password |"usergroup_user_password_aix[&i&]" string => "&password&";
}&

    &USERGROUP_USER_PASSWORD_POLICY:{passwordpol |"usergroup_user_password_policy[&i&]" string => "&passwordpol&";
}&

    &USERGROUP_USER_ACTION:{action |"usergroup_user_action[&i&]" string => "&action&";
}&

    &USERGROUP_USER_UID:{uid |"usergroup_user_uid[&i&]" string => "&uid&";
}&

    &USERGROUP_USER_HOME_PERSONNALIZE:{homeperso |"usergroup_user_home_perso[&i&]" string => "&homeperso&";
}&

    &USERGROUP_USER_HOME_MOVE:{homemove |"usergroup_user_home_move[&i&]" string => "&homemove&";
}&

    &USERGROUP_USER_HOME:{home |"usergroup_user_home[&i&]" string => "&home&";
}&

    &USERGROUP_USER_SHELL:{shell |"usergroup_user_shell[&i&]" string => "&shell&";
}&

    &TRACKINGKEY:{directiveId |"usergroup_directive_id[&i&]" string => "&directiveId&";
}&

      "index" slist => getindices("usergroup_user_login");


    any_2nd_pass::

      # 1 - Options to use whether Fullname is defined or not
      "nameopt[${index}]"
        string => "",
            if => "usermanagement_user_nameempty_${index}";

      ## On UNIX
      "nameopt[${index}]"
        string => "-c \"${usergroup_user_fullname[${index}]}\"",
            if => "!usermanagement_user_nameempty_${index}";

      ## Part of reports to return whether Fullname is defined or not
      "repname[${index}]"
        string => "Without any defined full name",
            if => "usermanagement_user_nameempty_${index}";

      "repname[${index}]"
        string => "${usergroup_user_fullname[${index}]}",
            if => "!usermanagement_user_nameempty_${index}";

      # 2 - On UNIX, choose between using no group name or using a custom one
      "groupopt[${index}]"
        string => "",
            if => and( "usermanagement_user_groupempty_${index}",
                       "!usermanagement_user_force_user_in_group_${index}"
                     );

      "groupopt[${index}]"
        string => "-g ${usergroup_user_groupname[${index}]}",
            if => and( "!usermanagement_user_groupempty_${index}",
                       "!usermanagement_user_force_user_in_group_${index}"
                     );

      "groupopt[${index}]"
        string => "-g ${usergroup_user_login[${index}]}",
            if => "usermanagement_user_force_user_in_group_${index}";

      # 3 - on UNIX force user id if provided
      "useropt[${index}]"
        string => "",
            if => "usermanagement_user_uid_empty_${index}";

      "useropt[${index}]"
        string => "-u ${usergroup_user_uid[${index}]}",
            if => "!usermanagement_user_uid_empty_${index}";

    any_2nd_pass.!pass2::


      "usermanagement_user_move_home_dir_from[${index}]" string => execresult("${paths.grep} '^${usergroup_user_login[${index}]}:' /etc/passwd | ${paths.cut} -d: -f6", "useshell"),
           if => "usermanagement_user_exists_${index}";

      # Get current user gid (or name) to compare it with the setted on, if we need to force it
      "user_current_gid[${index}]"   string => execresult("/usr/bin/id -g ${usergroup_user_login[${index}]}", "noshell"),
                                                        if => and( "usermanagement_force_user_group_defined_${index}",
                                                                   "usermanagement_user_exists_${index}",
                                                                   "usermanagement_user_group_is_gid_${index}"
                                                                 );

      "user_current_gid[${index}]"   string => execresult("/usr/bin/id -g -n ${usergroup_user_login[${index}]}", "noshell"),
                                                        if => and( "usermanagement_force_user_group_defined_${index}",
                                                                   "usermanagement_user_exists_${index}",
                                                                   "!usermanagement_user_group_is_gid_${index}"
                                                                 );


  classes:

    # Actions

      "usermanagement_user_update_${index}" expression => strcmp("${usergroup_user_action[${index}]}","add");

      "usermanagement_user_remove_${index}" expression => strcmp("${usergroup_user_action[${index}]}","remove");

      "usermanagement_user_checkpres_${index}" expression => strcmp("${usergroup_user_action[${index}]}","checkhere");

      "usermanagement_user_checkabs_${index}" expression => strcmp("${usergroup_user_action[${index}]}","checknothere");

      "usermanagement_user_pershome_${index}" not => strcmp("${usergroup_user_home_perso[${index}]}","true");

      "usermanagement_user_custom_home_no_variable_${index}"     not => isvariable("usergroup_user_home[${index}]");
      "usermanagement_user_custom_home_no_value_${index}" expression => strcmp("", "${usergroup_user_home[${index}]}");
      "usermanagement_user_custom_home_defined_${index}"  expression => and( "!usermanagement_user_custom_home_no_variable_${index}",
                                                                                            "!usermanagement_user_custom_home_no_value_${index}"
                                                                                          );

      # If we ask to personnalize home, but not define it, it is invalid
      "usermanagement_user_home_pershome_invalid_${index}" expression => and( "usermanagement_user_pershome_${index}",
                                                                                             "!usermanagement_user_custom_home_defined_${index}"
                                                                                           );

      # Asked to move the home directory
      "usermanagement_user_custom_home_move_${index}" expression => strcmp("${usergroup_user_home_move[${index}]}","true");

      # The request to move home is valid: the path to move to is defined, and we asked to personalize
      "usermanagement_user_custom_home_move_valid_${index}" expression => and( "usermanagement_user_custom_home_move_${index}",
                                                                                              "usermanagement_user_custom_home_defined_${index}",
                                                                                              "usermanagement_user_pershome_${index}"
                                                                                            );

      "usermanagement_user_exists_${index}" expression => userexists("${usergroup_user_login[${index}]}");

      "usermanagement_group_exists_${index}" expression => groupexists("${usergroup_user_groupname[${index}]}");

      "usermanagement_user_pwoneshot_${index}" expression => strcmp("${usergroup_user_password_policy[${index}]}","oneshot");

      "usermanagement_user_pweverytime_${index}" expression => strcmp("${usergroup_user_password_policy[${index}]}","everytime");

      # with variables that are not unique, the emptyness detection is quite tricky
      # either the variable is not defined, or the variable value is ""
      "usermanagement_user_pw_no_variable_${index}"     not => isvariable("usergroup_user_password[${index}]");
      "usermanagement_user_pw_no_value_${index}" expression => strcmp("", "${usergroup_user_password[${index}]}");
      "usermanagement_user_pwempty_${index}"     expression => or( "usermanagement_user_pw_no_variable_${index}",
                                                                                  "usermanagement_user_pw_no_value_${index}"
                                                                                );

      "usermanagement_user_name_no_variable_${index}"     not => isvariable("usergroup_user_fullname[${index}]");
      "usermanagement_user_name_no_value_${index}" expression => strcmp("", "${usergroup_user_fullname[${index}]}");
      "usermanagement_user_nameempty_${index}"     expression => or( "usermanagement_user_name_no_variable_${index}",
                                                                                    "usermanagement_user_name_no_value_${index}"
                                                                                  );

      "usermanagement_user_group_no_variable_${index}"     not => isvariable("usergroup_user_groupname[${index}]");
      "usermanagement_user_group_no_value_${index}" expression =>  strcmp("", "${usergroup_user_groupname[${index}]}");
      "usermanagement_user_groupempty_${index}"     expression => or( "usermanagement_user_group_no_variable_${index}",
                                                                                     "usermanagement_user_group_no_value_${index}"
                                                                                   );


      # check if user set a gid or a group name
      "usermanagement_user_group_is_gid_${index}"        expression => regcmp("[0-9]+", "${usergroup_user_groupname[${index}]}"),
                                                                                if => "!usermanagement_user_groupempty_${index}";

      "usermanagement_force_user_group_${index}"         expression => strcmp("true", "${usergroup_force_user_groupname[${index}]}");
      "usermanagement_force_user_group_defined_${index}" expression => and( "usermanagement_force_user_group_${index}",
                                                                                           "!usermanagement_user_groupempty_${index}"
                                                                                         );


      "usermanagement_user_uid_no_variable_${index}"     not => isvariable("usergroup_user_uid[${index}]");
      "usermanagement_user_uid_no_value_${index}" expression => strcmp("", "${usergroup_user_uid[${index}]}");
      "usermanagement_user_uid_empty_${index}"    expression => or( "usermanagement_user_uid_no_variable_${index}",
                                                                                   "usermanagement_user_uid_no_value_${index}"
                                                                                 );

      "usermanagement_user_groupmatchesname_${index}" expression => strcmp("${usergroup_user_login[${index}]}", "${usergroup_user_groupname[${index}]}");

      # Group doesn't exist and group name is defined
      "usermanagement_user_group_definition_error_${index}" expression => or(and( "!usermanagement_group_exists_${index}",
                                                                                                 "usermanagement_user_groupmatchesname_${index}"
                                                                                               ),
                                                                                            and( "!usermanagement_user_groupempty_${index}",
                                                                                                 "!usermanagement_group_exists_${index}"
                                                                                               )
                                                                                            );

      # check if user exists when enforcing ids
      "usermanagement_uid_exists_${index}" expression => userexists("${usergroup_user_uid[${index}]}"),
                                                                  if => "!usermanagement_user_uid_empty_${index}";
      
      # UID is defined and already exists
      "usermanagement_user_uid_definition_error_${index}" expression => "!usermanagement_user_uid_empty_${index}.usermanagement_uid_exists_${index}";

      # if we want to create a user, and a group with the username exists (no group name defined),then we need to force addition of user to that group (mandatory for debian and redhat, non mandatory for SLES)
      "usermanagement_user_force_user_in_group_${index}" expression => groupexists("${usergroup_user_login[${index}]}"),
          if => and( "usermanagement_user_groupempty_${index}",
                     "!usermanagement_user_nameempty_${index}"
                   );

    # Class 'any' is executed before others classes defined.
    # Same as 'any' but execution will be after all classes defined
      "any_2nd_pass" expression => "any";
      "showtime"     expression => isvariable("nameopt[1]");

    showtime::
      # if defined, we can move the user home (because we know the previous value)
      "usermanagement_user_current_home_defined_${index}" expression => isvariable("usermanagement_user_move_home_dir_from[${index}]");

      # Must move the home if:
      # - home is not the same as the defined home on the node for user
      # - we asked to personnalize, and the values are valid
      "usermanagement_user_current_home_is_invalid_${index}" not => strcmp("${usermanagement_user_move_home_dir_from[${index}]}", "${usergroup_user_home[${index}]}"),
           if => and( "usermanagement_user_current_home_defined_${index}",
                      "usermanagement_user_pershome_${index}",
                      "!usermanagement_user_home_pershome_invalid_${index}"
                    );

     # check if we need to change the user GID
     # We need to change it if:
     # usermanagement_force_user_group_defined and user_current_gid is different from usergroup_user_groupname
     # if usermanagement_force_user_group but not usermanagement_force_user_group_defined, we'll need to report an error (cannot set to no group)
     "usermanagement_user_current_group_is_invalid_${index}" not => strcmp("${user_current_gid[${index}]}", "${usergroup_user_groupname[${index}]}"),
         if => "usermanagement_force_user_group_defined_${index}";


    any::
      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";

  files:
    pass3::
      "/etc/passwd"
        create        => "false",
        edit_line     => set_user_fullname_&RudderUniqueID&("${usergroup_user_login[${index}]}","${index}","${usergroup_user_fullname[${index}]}"),
        edit_defaults => noempty_backup,
                   if => and( "usermanagement_user_update_${index}",
                              "!usermanagement_user_nameempty_${index}"
                            );

      "/etc/passwd"
        create        => "false",
        edit_line     => set_user_fullname_&RudderUniqueID&("${usergroup_user_login[${index}]}","${index}","${usergroup_user_fullname[${index}]}"),
        edit_defaults => noempty_backup,
        action        => WarnOnly,
                   if => and( "usermanagement_user_checkpres_${index}",
                              "!usermanagement_user_nameempty_${index}"
                            );

      "/etc/passwd"
        create        => "false",
        edit_line     => set_user_shell_&RudderUniqueID&("${usergroup_user_login[${index}]}","${index}","${usergroup_user_shell[${index}]}"),
        edit_defaults => noempty_backup,
                   if => "usermanagement_user_update_${index}";

      "/etc/passwd"
        create        => "false",
        edit_line     => set_user_shell_&RudderUniqueID&("${usergroup_user_login[${index}]}","${index}","${usergroup_user_shell[${index}]}"),
        edit_defaults => noempty_backup,
        action        => WarnOnly,
                   if => "usermanagement_user_checkpres_${index}";

    pass3.aix::
      # On AIX, if password is supplied and user must exist, then the second field needs to be a ! to allow login
      "/etc/passwd"
        create        => "false",
        edit_line     => set_colon_field("${usergroup_user_login[${index}]}", "2", "!"),
        edit_defaults => noempty_backup,
        classes       => classes_generic("usermanagement_user_password_${index}_&RudderUniqueID&"),
                   if => or( and( "usermanagement_login_add_${index}_&RudderUniqueID&_repaired",
                                  "usermanagement_user_pwoneshot_${index}",
                                  "!usermanagement_user_pwempty_${index}"
                                ),
                             and( "usermanagement_user_update_${index}",
                                  "usermanagement_user_exists_${index}",
                                  "usermanagement_user_pweverytime_${index}",
                                  "!usermanagement_user_pwempty_${index}"
                                )
                           );

    pass3.!aix::
      # Define password when user has already been created
      "/etc/shadow"
        create        => "false",
        edit_line     => set_user_field("${usergroup_user_login[${index}]}", 2, "${usergroup_user_password[${index}]}"),
        edit_defaults => noempty_backup,
        classes       => classes_generic("usermanagement_user_password_${index}_&RudderUniqueID&"),
                   if => or( and( "usermanagement_login_add_${index}_&RudderUniqueID&_repaired",
                                  "usermanagement_user_pwoneshot_${index}",
                                  "!usermanagement_user_pwempty_${index}"
                                ),
                             and( "usermanagement_user_update_${index}",
                                  "usermanagement_user_exists_${index}",
                                  "usermanagement_user_pweverytime_${index}",
                                  "!usermanagement_user_pwempty_${index}"
                                )
                           );

      # Check password if we are in "check only (account should exist)
      # Due to https://tracker.mender.io/browse/CFE-2424, if password is correct, no class is defined. Waiting for fix in the agent
      "/etc/shadow"
        create        => "false",
        edit_line     => set_user_field("${usergroup_user_login[${index}]}", 2, "${usergroup_user_password[${index}]}"),
        edit_defaults => noempty_backup,
        action        => WarnOnly,
        classes       => classes_generic("usermanagement_user_password_${index}_&RudderUniqueID&"),
                   if => and( "!usermanagement_user_pwempty_${index}",
                              "usermanagement_user_exists_${index}",
                              "usermanagement_user_pweverytime_${index}",
                              "usermanagement_user_checkpres_${index}"
                            );

    pass3.aix::
      "/etc/security/passwd"
        create        => "false",
        edit_line     => ncf_ensure_AIX_password("${usergroup_user_login[${index}]}", "${usergroup_user_password_aix[${index}]}"),
        edit_defaults => noempty_backup,
        classes       => classes_generic("usermanagement_user_password_${index}_&RudderUniqueID&"),
                   if => or( and( "usermanagement_login_add_${index}_&RudderUniqueID&_repaired",
                                  "usermanagement_user_pwoneshot_${index}",
                                  "!usermanagement_user_pwempty_${index}"
                                ),
                             and( "usermanagement_user_update_${index}",
                                  "usermanagement_user_exists_${index}",
                                  "usermanagement_user_pweverytime_${index}",
                                  "!usermanagement_user_pwempty_${index}"
                                )
                           );

      # set the last update date if password has been updated
      "/etc/security/passwd"
        create        => "false",
        edit_line     => ncf_edit_lastupdate_AIX_password("${usergroup_user_login[${index}]}"),
        edit_defaults => noempty_backup,
                  if  => and( "usermanagement_user_password_${index}_&RudderUniqueID&_repaired",
                              or( and( "usermanagement_login_add_${index}_&RudderUniqueID&_repaired",
                                       "usermanagement_user_pwoneshot_${index}",
                                       "!usermanagement_user_pwempty_${index}"
                                     ),
                                  and( "usermanagement_user_update_${index}",
                                       "usermanagement_user_exists_${index}",
                                       "usermanagement_user_pweverytime_${index}",
                                       "!usermanagement_user_pwempty_${index}"
                                     )
                                )
                            );


      "/etc/security/passwd"
        create        => "false",
        edit_line     => ncf_ensure_AIX_password("${usergroup_user_login[${index}]}", "${usergroup_user_password_aix[${index}]}"),
        edit_defaults => noempty_backup,
        action        => WarnOnly,
        classes       => classes_generic("usermanagement_user_password_${index}_&RudderUniqueID&"),
                   if => and( "!usermanagement_user_pwempty_${index}",
                              "usermanagement_user_exists_${index}",
                              "usermanagement_user_pweverytime_${index}",
                              "usermanagement_user_checkpres_${index}"
                            );


  methods:
    pass3.showtime::

      # Add user
      ## Does exist (Success), and gid not requested to be changed
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_success", "${usergroup_directive_id[${index}]}", "Users", "${usergroup_user_login[${index}]}", "The user ${usergroup_user_login[${index}]} ( ${repname[${index}]} ) is already present on the system", "${index}"),
          if => and( "usermanagement_user_exists_${index}",
                     "usermanagement_user_update_${index}",
                     "!usermanagement_login_add_${index}_&RudderUniqueID&_repaired",
                     "usermanagement_shell_edit_${index}_&RudderUniqueID&_kept",
                     "!usermanagement_force_user_group_${index}",
                     or( "usermanagement_user_nameempty_${index}",
                         "usermanagement_fullname_edit_${index}_&RudderUniqueID&_kept"
                       )
                   );

      ## Does exist (Success), and gid already correct
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_success", "${usergroup_directive_id[${index}]}", "Users", "${usergroup_user_login[${index}]}", "The user ${usergroup_user_login[${index}]} ( ${repname[${index}]} ) is already present on the system", "${index}"),
          if => and( "usermanagement_user_exists_${index}",
                     "usermanagement_user_update_${index}",
                     "!usermanagement_login_add_${index}_&RudderUniqueID&_repaired",
                     "usermanagement_shell_edit_${index}_&RudderUniqueID&_kept",
                     "usermanagement_force_user_group_defined_${index}",
                     "!usermanagement_user_current_group_is_invalid_${index}",
                     or( "usermanagement_user_nameempty_${index}",
                         "usermanagement_fullname_edit_${index}_&RudderUniqueID&_kept"
                       )
                   );


      ## Does exist (Success), with a wrong gid
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_repaired", "${usergroup_directive_id[${index}]}", "Users", "${usergroup_user_login[${index}]}", "The user ${usergroup_user_login[${index}]} ( ${repname[${index}]} ) is already present on the system, but had the wrong gid", "${index}"),
          if => and( "usermanagement_user_exists_${index}",
                     "usermanagement_user_update_${index}",
                     "!usermanagement_login_add_${index}_&RudderUniqueID&_repaired",
                     "usermanagement_shell_edit_${index}_&RudderUniqueID&_kept",
                     "usermanagement_force_user_group_defined_${index}",
                     "usermanagement_user_gid_change_${index}_&RudderUniqueID&_repaired",
                     or( "usermanagement_user_nameempty_${index}",
                         "usermanagement_fullname_edit_${index}_&RudderUniqueID&_kept"
                       )
                   );


      ## Seems to exist with a wrong Full Name (Repaired)
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_repaired", "${usergroup_directive_id[${index}]}", "Users", "${usergroup_user_login[${index}]}", "The user ${usergroup_user_login[${index}]} ( ${repname[${index}]} ) had a wrong fullname", "${index}"),
          if => and( "usermanagement_user_exists_${index}",
                     "usermanagement_user_update_${index}",
                     "!usermanagement_user_nameempty_${index}",
                     "usermanagement_fullname_edit_${index}_&RudderUniqueID&_repaired",
                     "usermanagement_shell_edit_${index}_&RudderUniqueID&_kept"
                   );

      ## Seems to exist with a wrong Shell (Repaired)
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_repaired", "${usergroup_directive_id[${index}]}", "Users", "${usergroup_user_login[${index}]}", "The user ${usergroup_user_login[${index}]} ( ${repname[${index}]} ) had a wrong shell", "${index}"),
          if => and( "usermanagement_user_exists_${index}",
                     "usermanagement_user_update_${index}",
                     "usermanagement_shell_edit_${index}_&RudderUniqueID&_repaired",
                     not( or( "usermanagement_fullname_edit_${index}_&RudderUniqueID&_repaired",
                              "usermanagement_fullname_edit_${index}_&RudderUniqueID&_error"
                            )
                        )
                   );

      ## Seems to exist with a wrong Full Name and Shell (Repaired)
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_repaired", "${usergroup_directive_id[${index}]}", "Users", "${usergroup_user_login[${index}]}", "The user ${usergroup_user_login[${index}]} ( ${repname[${index}]} ) had a wrong fullname and shell", "${index}"),
          if => and( "usermanagement_user_exists_${index}",
                     "usermanagement_user_update_${index}",
                     "!usermanagement_user_nameempty_${index}",
                     "usermanagement_fullname_edit_${index}_&RudderUniqueID&_repaired",
                     "usermanagement_shell_edit_${index}_&RudderUniqueID&_repaired"
                   );


      ## Error in audit mode
      ## Seems to exist with a wrong Full Name (Error)
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_error", "${usergroup_directive_id[${index}]}", "Users", "${usergroup_user_login[${index}]}", "The user ${usergroup_user_login[${index}]} ( ${repname[${index}]} ) is present on the system, but does not have the right fullname", "${index}"),
          if => and( "usermanagement_user_exists_${index}",
                     "usermanagement_user_update_${index}",
                     "!usermanagement_user_nameempty_${index}",
                     "usermanagement_fullname_edit_${index}_&RudderUniqueID&_error",
                     "usermanagement_shell_edit_${index}_&RudderUniqueID&_kept"
                   );

     ## Seems to exist with a wrong Shell (Error)
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_error", "${usergroup_directive_id[${index}]}", "Users", "${usergroup_user_login[${index}]}", "The user ${usergroup_user_login[${index}]} ( ${repname[${index}]} ) is present on the system, but does not have the right shell", "${index}"),
          if => and( "usermanagement_user_exists_${index}",
                     "usermanagement_user_update_${index}",
                     "!usermanagement_user_nameempty_${index}",
                     "usermanagement_shell_edit_${index}_&RudderUniqueID&_error",
                     "usermanagement_fullname_edit_${index}_&RudderUniqueID&_kept"
                   );

      ## Seems to exist with a wrong Shell and wrong Full Name (Error)
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_error", "${usergroup_directive_id[${index}]}", "Users", "${usergroup_user_login[${index}]}", "The user ${usergroup_user_login[${index}]} ( ${repname[${index}]} ) is present on the system, but does not have the right fullname not shell", "${index}"),
          if => and( "usermanagement_user_exists_${index}",
                     "usermanagement_user_update_${index}",
                     "!usermanagement_user_nameempty_${index}",
                     "usermanagement_fullname_edit_${index}_&RudderUniqueID&_error",
                     "usermanagement_shell_edit_${index}_&RudderUniqueID&_error"
                   );


      ## Does not exist (Error)
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_error", "${usergroup_directive_id[${index}]}", "Users", "${usergroup_user_login[${index}]}", "The user ${usergroup_user_login[${index}]} ( ${repname[${index}]} ) is not present on the system, which violates the presence policy", "${index}"),
          if => and( "!usermanagement_user_exists_${index}",
                     or( "usermanagement_user_checkpres_${index}",
                         "usermanagement_user_update_${index}"
                       )
                   );


       ## Seems to exist with a wrong Shell (Error)
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_error", "${usergroup_directive_id[${index}]}", "Users", "${usergroup_user_login[${index}]}", "The user ${usergroup_user_login[${index}]} ( ${repname[${index}]} ) is present on the system, but does not have the right shell", "${index}"),
          if => and( "usermanagement_user_exists_${index}",
                     "usermanagement_user_update_${index}",
                     "usermanagement_shell_edit_${index}_&RudderUniqueID&_error",
                     or( and( "!usermanagement_user_nameempty_${index}",
                              "usermanagement_fullname_edit_${index}_&RudderUniqueID&_kept"
                            ),
                         "usermanagement_user_nameempty_${index}"
                       )
                   );


      ## Added (Repaired)
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_repaired", "${usergroup_directive_id[${index}]}", "Users", "${usergroup_user_login[${index}]}", "The user ${usergroup_user_login[${index}]} ( ${repname[${index}]} ) has been added to the system", "${index}"),
          if => and( "usermanagement_user_exists_${index}",
                     "usermanagement_user_update_${index}",
                     "usermanagement_login_add_${index}_&RudderUniqueID&_repaired"
                   );

      ## Error
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_error", "${usergroup_directive_id[${index}]}", "Users", "${usergroup_user_login[${index}]}", "The user ${usergroup_user_login[${index}]} ( ${repname[${index}]} ) could not be added to the system", "${index}"),
          if => and( "!usermanagement_user_exists_${index}",
                      "usermanagement_user_update_${index}",
                      "usermanagement_login_add_${index}_&RudderUniqueID&_error",
                      not("dry_run|global_dry_run")
                   );

      ## Could not be added, for the default path was not selected, but the custom one was not defined
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_error", "${usergroup_directive_id[${index}]}", "Users", "${usergroup_user_login[${index}]}", "The user ${usergroup_user_login[${index}]} ( ${repname[${index}]} ) could not be added to the system because the default home directory was not selected, but the custom path was not specified", "${index}"),
          if => and( "!usermanagement_user_exists_${index}",
                     "usermanagement_user_update_${index}",
                     "usermanagement_user_pershome_${index}",
                     "!usermanagement_user_custom_home_defined_${index}"
                   );

      ## Could not be added, as a custom group was asked for and did not exist on the system
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_error", "${usergroup_directive_id[${index}]}", "Users", "${usergroup_user_login[${index}]}", "The user ${usergroup_user_login[${index}]} ( ${repname[${index}]} ) could not be added to the system because the custom group \"${usergroup_user_groupname[${index}]}\" does not exist", "${index}"),
          if => and( "usermanagement_user_update_${index}",
                     "!usermanagement_user_exists_${index}",
                     "usermanagement_user_group_definition_error_${index}"
                   );

      ## Could not be added, as a custom uid was asked for and did exist on the system
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_error", "${usergroup_directive_id[${index}]}", "Users", "${usergroup_user_login[${index}]}", "The user ${usergroup_user_login[${index}]} ( ${repname[${index}]} ) could not be added to the system because the custom uid \"${usergroup_user_uid[${index}]}\" already exists", "${index}"),
          if => and( "usermanagement_user_update_${index}",
                     "!usermanagement_user_exists_${index}",
                     "usermanagement_user_uid_definition_error_${index}"
                   );

      ## Could not set the gid, as it was requested, but with no gid provided
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_error", "${usergroup_directive_id[${index}]}", "Users", "${usergroup_user_login[${index}]}", "The user ${usergroup_user_login[${index}]} ( ${repname[${index}]} ) could not have its gid updated because it was not provided", "${index}"),
          if => and( "usermanagement_user_exists_${index}",
                     "usermanagement_user_update_${index}",
                     "usermanagement_force_user_group_${index}",
                     "usermanagement_user_groupempty_${index}"
                   );

      ## Does exist with a wrong gid that could not be repaired
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_error", "${usergroup_directive_id[${index}]}", "Users", "${usergroup_user_login[${index}]}", "The user ${usergroup_user_login[${index}]} ( ${repname[${index}]} ) is already present on the system, but with wrong gid that cannot be fixed", "${index}"),
          if => and( "usermanagement_user_exists_${index}",
                     "usermanagement_user_update_${index}",
                     "!usermanagement_login_add_${index}_&RudderUniqueID&_repaired",
                     "usermanagement_force_user_group_defined_${index}",
                     "usermanagement_user_gid_change_${index}_&RudderUniqueID&_error",
                     or( "usermanagement_user_nameempty_${index}",
                         "usermanagement_fullname_edit_${index}_&RudderUniqueID&_kept"
                       )
                   );


      # Remove user
      ## Does not exist (Success)
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_success", "${usergroup_directive_id[${index}]}", "Users", "${usergroup_user_login[${index}]}", "The user ${usergroup_user_login[${index}]} ( ${repname[${index}]} ) does not exist, as required", "${index}"),
          if => and( "!usermanagement_user_exists_${index}",
                      "usermanagement_user_remove_${index}"
                   );

      ## Removed (Repaired)
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_repaired", "${usergroup_directive_id[${index}]}", "Users", "${usergroup_user_login[${index}]}", "The user ${usergroup_user_login[${index}]} ( ${repname[${index}]} ) has been removed from the system", "${index}"),
          if => and( "usermanagement_user_exists_${index}",
                     "usermanagement_user_remove_${index}",
                     "usermanagement_login_remove_${index}_&RudderUniqueID&_repaired"
                   );

      ## Error
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_error", "${usergroup_directive_id[${index}]}", "Users", "${usergroup_user_login[${index}]}", "The user ${usergroup_user_login[${index}]} ( ${repname[${index}]} ) could not be removed from the system", "${index}"),
          if => and( "usermanagement_user_exists_${index}",
                     "usermanagement_user_remove_${index}",
                     "usermanagement_login_remove_${index}_&RudderUniqueID&_error"
                   );

      # Check user not exists
      ## Does not exist (Success)
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_success", "${usergroup_directive_id[${index}]}", "Users", "${usergroup_user_login[${index}]}", "The user ${usergroup_user_login[${index}]} ( ${repname[${index}]} ) is not present on the system, which is in accordance with the non presence policy", "${index}"),
          if => and( "!usermanagement_user_exists_${index}",
                     "usermanagement_user_checkabs_${index}"
                   );

      ## Does exist (Error)
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_error", "${usergroup_directive_id[${index}]}", "Users", "${usergroup_user_login[${index}]}", "The user ${usergroup_user_login[${index}]} ( ${repname[${index}]} ) is present on the system, which violates the non presence policy", "${index}"),
          if => and( "usermanagement_user_exists_${index}",
                     "usermanagement_user_checkabs_${index}"
                   );

      # Check user exists
      ## Does exist (Success)
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_success", "${usergroup_directive_id[${index}]}", "Users", "${usergroup_user_login[${index}]}", "The user ${usergroup_user_login[${index}]} ( ${repname[${index}]} ) is present on the system, which is in conformance with the presence policy", "${index}"),
          if => and( "usermanagement_user_exists_${index}",
                     "usermanagement_user_checkpres_${index}",
                     "usermanagement_shell_edit_${index}_&RudderUniqueID&_kept",
                     or( "usermanagement_user_nameempty_${index}",
                         "usermanagement_fullname_edit_${index}_&RudderUniqueID&_kept"
                       )
                   );

      ## Seems to exist with a wrong Full Name (Error)
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_error", "${usergroup_directive_id[${index}]}", "Users", "${usergroup_user_login[${index}]}", "The user ${usergroup_user_login[${index}]} ( ${repname[${index}]} ) is present on the system, but does not have the right fullname", "${index}"),
          if => and( "usermanagement_user_exists_${index}",
                     "usermanagement_user_checkpres_${index}",
                     "!usermanagement_user_nameempty_${index}",
                     "usermanagement_shell_edit_${index}_&RudderUniqueID&_kept",
                     or( "usermanagement_fullname_edit_${index}_&RudderUniqueID&_repaired",
                         "usermanagement_fullname_edit_${index}_&RudderUniqueID&_error"
                       )
                   );

     ## Seems to exist with a wrong Shell (Error)
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_error", "${usergroup_directive_id[${index}]}", "Users", "${usergroup_user_login[${index}]}", "The user ${usergroup_user_login[${index}]} ( ${repname[${index}]} ) is present on the system, but does not have the right shell", "${index}"),
          if => and( "usermanagement_user_exists_${index}",
                     "usermanagement_user_checkpres_${index}",
                     or( "usermanagement_user_nameempty_${index}",
                         "usermanagement_fullname_edit_${index}_&RudderUniqueID&_kept"
                       ),
                     or( "usermanagement_shell_edit_${index}_&RudderUniqueID&_repaired",
                         "usermanagement_shell_edit_${index}_&RudderUniqueID&_error"
                       )
                    );

      ## Seems to exist with a wrong Shell and wrong Full Name (Error)
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_error", "${usergroup_directive_id[${index}]}", "Users", "${usergroup_user_login[${index}]}", "The user ${usergroup_user_login[${index}]} ( ${repname[${index}]} ) is present on the system, but does not have the right fullname not shell", "${index}"),
          if => and( "usermanagement_user_exists_${index}",
                     "usermanagement_user_checkpres_${index}",
                     "!usermanagement_user_nameempty_${index}",
                     or( "usermanagement_fullname_edit_${index}_&RudderUniqueID&_repaired",
                         "usermanagement_fullname_edit_${index}_&RudderUniqueID&_error"
                       ),
                     or( "usermanagement_shell_edit_${index}_&RudderUniqueID&_repaired",
                         "usermanagement_shell_edit_${index}_&RudderUniqueID&_error"
                       )
                   );
 

      ### Password handling
      "any" usebundle => rudder_common_reports_generic_index("userGroupManagement", "usermanagement_user_password_${index}_&RudderUniqueID&", "${usergroup_directive_id[${index}]}", "Password", "${usergroup_user_login[${index}]}", "The user ${usergroup_user_login[${index}]} ( ${repname[${index}]} ) password", "${index}"),
          if => not("usermanagement_user_checkpres_${index}");

      ## Password handling in check only
      "any" usebundle => rudder_common_reports_generic_index("userGroupManagement", "usermanagement_user_password_${index}_&RudderUniqueID&", "${usergroup_directive_id[${index}]}", "Password", "${usergroup_user_login[${index}]}", "The check of password for user ${usergroup_user_login[${index}]} ( ${repname[${index}]} ) ", "${index}"),
          if => "usermanagement_user_checkpres_${index}";

      ## Change not needed (Success)
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_success", "${usergroup_directive_id[${index}]}", "Password", "${usergroup_user_login[${index}]}", "The user ${usergroup_user_login[${index}]} ( ${repname[${index}]} ) password change is not required", "${index}"),
          if => and( and( "!usermanagement_user_password_${index}_&RudderUniqueID&_kept",
                          "!usermanagement_user_password_${index}_&RudderUniqueID&_repaired",
                          "!usermanagement_user_password_${index}_&RudderUniqueID&_error"
                         ),
                         or(
                             "usermanagement_user_pwempty_${index}",
                             "usermanagement_user_remove_${index}",
                             and( "usermanagement_user_pwoneshot_${index}",
                                  "usermanagement_user_exists_${index}"
                                ),
                             and( "usermanagement_user_update_${index}",
                                  "!usermanagement_user_exists_${index}",
                                  or( "usermanagement_user_group_definition_error_${index}",
                                      "usermanagement_user_uid_definition_error_${index}"
                                    )
                                )
                           )
                    );


      ## Change not needed (N/A)
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_na", "${usergroup_directive_id[${index}]}", "Password", "${usergroup_user_login[${index}]}", "The user ${usergroup_user_login[${index}]} ( ${repname[${index}]} ) password change is not required", "${index}"),
          if => or( and( and( "!usermanagement_user_password_${index}_&RudderUniqueID&_kept",
                              "!usermanagement_user_password_${index}_&RudderUniqueID&_repaired",
                              "!usermanagement_user_password_${index}_&RudderUniqueID&_error"
                            ),
                          or( "usermanagement_user_checkpres_${index}.usermanagement_user_pwoneshot_${index}",
                              "usermanagement_user_checkpres_${index}.!usermanagement_user_exists_${index}"
                            )
                        ),
                    "usermanagement_user_checkabs_${index}"
                   );

      ## Error when no password class defined and not in a previous N/A or Success case
      #  This huge statement is built from three previous password reports:
      #  (no class _reached defined).!(change not needed Success).!(change not needed N/A)
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_error", "${usergroup_directive_id[${index}]}", "Password", "${usergroup_user_login[${index}]}", "The user ${usergroup_user_login[${index}]} ( ${repname[${index}]} ) password could not be verified", "${index}"),
             if => and( "!usermanagement_user_password_${index}_&RudderUniqueID&_reached",
                         not( or( and( and( "!usermanagement_user_password_${index}_&RudderUniqueID&_kept",
                                            "!usermanagement_user_password_${index}_&RudderUniqueID&_repaired",
                                            "!usermanagement_user_password_${index}_&RudderUniqueID&_error"
                                          ),
                                        or( "usermanagement_user_checkpres_${index}.usermanagement_user_pwoneshot_${index}",
                                            "usermanagement_user_checkpres_${index}.!usermanagement_user_exists_${index}"
                                          )
                                     )
                                )
                            ),
                         not( and( and( "!usermanagement_user_password_${index}_&RudderUniqueID&_kept",
                                        "!usermanagement_user_password_${index}_&RudderUniqueID&_repaired",
                                        "!usermanagement_user_password_${index}_&RudderUniqueID&_error"
                                      ),
                                    or(
                                        "usermanagement_user_pwempty_${index}",
                                        "usermanagement_user_remove_${index}",
                                        and( "usermanagement_user_pwoneshot_${index}",
                                             "usermanagement_user_exists_${index}"
                                           ),
                                        and( "usermanagement_user_update_${index}",
                                             "!usermanagement_user_exists_${index}",
                                             or( "usermanagement_user_group_definition_error_${index}",
                                                 "usermanagement_user_uid_definition_error_${index}"
                                               )
                                           )
                                        )
                                 )
                            )
                      );
                           

      # Homedir management
      ## In case of user to remove or to check absent, this is a result_na
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_na", "${usergroup_directive_id[${index}]}", "Home directory", "${usergroup_user_login[${index}]}", "The user ${usergroup_user_login[${index}]} should not be present, it doesn't need to have its home directory checked", "${index}"),
          if => or( "usermanagement_user_remove_${index}",
                    "usermanagement_user_checkabs_${index}"
                  );

      ## In case of check user present or update, but with default home, this is result_na
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_na", "${usergroup_directive_id[${index}]}", "Home directory", "${usergroup_user_login[${index}]}", "The user ${usergroup_user_login[${index}]} doesn't need to have its home directory checked", "${index}"),
          if => and( "!usermanagement_user_pershome_${index}",
                     or( "usermanagement_user_update_${index}",
                         "usermanagement_user_checkpres_${index}"
                       )
                   );

      ## In case of check user present or update, but the home is already correct, this is success
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_success", "${usergroup_directive_id[${index}]}", "Home directory", "${usergroup_user_login[${index}]}", "The user ${usergroup_user_login[${index}]} home directory is valid", "${index}"),
          if => and( "usermanagement_user_pershome_${index}",
                      "!usermanagement_user_home_pershome_invalid_${index}",
                      "!usermanagement_user_current_home_is_invalid_${index}",
                      or( "usermanagement_user_update_${index}",
                          "usermanagement_user_checkpres_${index}"
                        )
                   );

      ## In case of check user present or update, but the custome home directory is not valid
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_error", "${usergroup_directive_id[${index}]}", "Home directory", "${usergroup_user_login[${index}]}", "The given home directory for user ${usergroup_user_login[${index}]} is invalid", "${index}"),
          if => and( "usermanagement_user_pershome_${index}",
                      "usermanagement_user_home_pershome_invalid_${index}",
                      or( "usermanagement_user_update_${index}",
                          "usermanagement_user_checkpres_${index}"
                        )
                    );

      ## In case of update, but the home was not correct, and could be changed, this is repaired
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_repaired", "${usergroup_directive_id[${index}]}", "Home directory", "${usergroup_user_login[${index}]}", "The user ${usergroup_user_login[${index}]} home directory was changed (but not moved)", "${index}"),
          if => and( "usermanagement_user_pershome_${index}",
                     "usermanagement_user_current_home_is_invalid_${index}",
                     "usermanagement_user_update_${index}",
                     or( "usermanagement_login_home_change_${index}_&RudderUniqueID&_repaired",
                         "!usermanagement_login_home_change_${index}_&RudderUniqueID&_error"
                       )
                   );

      ## In case of update, but the home was not correct, and could not be changed, this is error
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_error", "${usergroup_directive_id[${index}]}", "Home directory", "${usergroup_user_login[${index}]}", "The user ${usergroup_user_login[${index}]} home directory could not be changed", "${index}"),
          if => and( "usermanagement_user_pershome_${index}",
                     "usermanagement_login_home_change_${index}_&RudderUniqueID&_error",
                     "usermanagement_user_current_home_is_invalid_${index}",
                     "usermanagement_user_update_${index}"
                   );

      ## In case of update, but the home was not correct, and could be moved, this is repaired
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_repaired", "${usergroup_directive_id[${index}]}", "Home directory", "${usergroup_user_login[${index}]}", "The user ${usergroup_user_login[${index}]} home directory was moved", "${index}"),
          if => and( "usermanagement_user_pershome_${index}",
                     "usermanagement_login_home_move_${index}_&RudderUniqueID&_repaired",
                     "!usermanagement_login_home_move_${index}_&RudderUniqueID&_error",
                     "usermanagement_user_current_home_is_invalid_${index}",
                     "usermanagement_user_update_${index}"
                   );

      ## In case of update, but the home was not correct, and could not be moved, this is error
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_error", "${usergroup_directive_id[${index}]}", "Home directory", "${usergroup_user_login[${index}]}", "The user ${usergroup_user_login[${index}]} home directory could not be moved", "${index}"),
          if => and( "usermanagement_user_pershome_${index}",
                     "usermanagement_login_home_move_${index}_&RudderUniqueID&_error",
                     "usermanagement_user_current_home_is_invalid_${index}",
                     "usermanagement_user_update_${index}"
                   );

      ## In case of check only, and the home was not correct, this is error
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_error", "${usergroup_directive_id[${index}]}", "Home directory", "${usergroup_user_login[${index}]}", "The user ${usergroup_user_login[${index}]} home directory was invalid", "${index}"),
          if => and( "usermanagement_user_pershome_${index}",
                     "usermanagement_user_current_home_is_invalid_${index}",
                     "usermanagement_user_checkpres_${index}"
                   );

  commands:
    showtime::

      "/usr/sbin/useradd"
        args => "${useropt[${index}]} ${groupopt[${index}]} -m ${nameopt[${index}]} -s ${usergroup_user_shell[${index}]} ${usergroup_user_login[${index}]}",
        classes => cf2_if_else("usermanagement_login_add_${index}_&RudderUniqueID&_repaired", "usermanagement_login_add_${index}_&RudderUniqueID&_error"),
        comment => "Create the user",
             if => and( "!usermanagement_user_uid_definition_error_${index}",
                        "!usermanagement_user_group_definition_error_${index}",
                        "!usermanagement_user_exists_${index}",
                        "usermanagement_user_update_${index}",
                        "!usermanagement_user_pershome_${index}"
                      );

      "/usr/sbin/useradd"
        args => "${useropt[${index}]} ${groupopt[${index}]} -m ${nameopt[${index}]} -s ${usergroup_user_shell[${index}]} -d ${usergroup_user_home[${index}]} ${usergroup_user_login[${index}]}",
        classes => cf2_if_else("usermanagement_login_add_${index}_&RudderUniqueID&_repaired", "usermanagement_login_add_${index}_&RudderUniqueID&_error"),
        comment => "Create the user with a custom home directory",
             if => and( "!usermanagement_user_uid_definition_error_${index}",
                        "!usermanagement_user_group_definition_error_${index}",
                        "!usermanagement_user_exists_${index}",
                        "usermanagement_user_update_${index}",
                        "usermanagement_user_pershome_${index}",
                        "usermanagement_user_custom_home_defined_${index}"
                       );

      "/usr/sbin/userdel"
        args => "${usergroup_user_login[${index}]}",
        classes => cf2_if_else("usermanagement_login_remove_${index}_&RudderUniqueID&_repaired", "usermanagement_login_remove_${index}_&RudderUniqueID&_error"),
        comment => "Delete the user ${usergroup_user_login[${index}]}",
             if => and( "usermanagement_user_exists_${index}",
                        "usermanagement_user_remove_${index}"
                      );

      # Change user home dir
      ## Move the home dir
      "/usr/sbin/usermod"
        args       => "-d ${usergroup_user_home[${index}]} -m ${usergroup_user_login[${index}]}",
        classes    => cf2_if_else("usermanagement_login_home_move_${index}_&RudderUniqueID&_repaired", "usermanagement_login_home_move_${index}_&RudderUniqueID&_error"),
        comment    => "Change home directory (move it)",
                if => and( "usermanagement_user_update_${index}",
                           "usermanagement_user_current_home_is_invalid_${index}",
                           "usermanagement_user_custom_home_move_valid_${index}"
                         );

      ## Doesn't move the home dir
      "/usr/sbin/usermod"
        args       => "-d ${usergroup_user_home[${index}]} ${usergroup_user_login[${index}]}",
        classes    => cf2_if_else("usermanagement_login_home_change_${index}_&RudderUniqueID&_repaired", "usermanagement_login_home_change_${index}_&RudderUniqueID&_error"),
        comment    => "Change home directory definition for user (doesn't move files)",
                if => and( "usermanagement_user_update_${index}",
                           "usermanagement_user_current_home_is_invalid_${index}",
                           "!usermanagement_user_custom_home_move_${index}"
                         );

      ## Change the user gid if necessary
      "/usr/sbin/usermod"
        args       => "-g ${usergroup_user_groupname[${index}]} ${usergroup_user_login[${index}]}",
        classes    => classes_generic("usermanagement_user_gid_change_${index}_&RudderUniqueID&"),
        comment    => "Change user gid for user ${usergroup_user_login[${index}]}",
                if => and( "usermanagement_user_update_${index}",
                           "usermanagement_user_current_group_is_invalid_${index}"
                         );

}

bundle edit_line set_user_fullname_&RudderUniqueID&(user,user_index,fullname)
{
  field_edits:
      "${user}:.*"
      # Edit GECOS on /etc/passwd
        edit_field => col(":", "5", "${fullname}", "set"),
        classes    => classes_generic("usermanagement_fullname_edit_${user_index}_&RudderUniqueID&");

}

bundle edit_line set_user_shell_&RudderUniqueID&(user,user_index,shell)
{
  field_edits:
      "${user}:.*"
      # Edit shell on /etc/passwd
        edit_field => col(":", "7", "${shell}", "set"),
        classes    => classes_generic("usermanagement_shell_edit_${user_index}_&RudderUniqueID&");
}

