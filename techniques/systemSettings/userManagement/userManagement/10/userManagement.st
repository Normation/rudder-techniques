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

    &USERGROUP_USER_SECONDARY_GROUPS:{secgroup |"usergroup_user_secondary_groupsname[&i&]" string => "&secgroup&";
}&

    &USERGROUP_FORCE_USER_SECONDARY_GROUPS:{force_group |"usergroup_force_user_secondary_groupsname[&i&]" string => "&force_group&";
}&

    &USERGROUP_USER_NAME:{name |"usergroup_user_fullname[&i&]" string => "&name&";
}&

    &USERGROUP_USER_PASSWORD:{password |"usergroup_user_password[&i&]" string => "&password&";
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

      "usergroup_user_index" slist => getindices("usergroup_user_login");

      # number of days since epoch
      "now"               int => now();
      "epoch_days_str" string => eval("${now}/86400", math, infix);
      "epoch_days"        int => int("${epoch_days_str}");


    any_2nd_pass::

      # 1 - Options to use whether Fullname is defined or not
      "nameopt[${usergroup_user_index}]"
        string => "",
            if => "usermanagement_user_nameempty_${usergroup_user_index}";

      ## On UNIX
      "nameopt[${usergroup_user_index}]"
        string => "-c \"${usergroup_user_fullname[${usergroup_user_index}]}\"",
            if => "!usermanagement_user_nameempty_${usergroup_user_index}";

      ## Part of reports to return whether Fullname is defined or not
      "repname[${usergroup_user_index}]"
        string => "Without any defined full name",
            if => "usermanagement_user_nameempty_${usergroup_user_index}";

      "repname[${usergroup_user_index}]"
        string => "${usergroup_user_fullname[${usergroup_user_index}]}",
            if => "!usermanagement_user_nameempty_${usergroup_user_index}";

      # 2 - On UNIX, choose between using no group name or using a custom one
      "groupopt[${usergroup_user_index}]"
        string => "",
            if => and( "usermanagement_user_groupempty_${usergroup_user_index}",
                       "!usermanagement_user_force_user_in_group_${usergroup_user_index}"
                     );

      "groupopt[${usergroup_user_index}]"
        string => "-g ${usergroup_user_groupname[${usergroup_user_index}]}",
            if => and( "!usermanagement_user_groupempty_${usergroup_user_index}",
                       "!usermanagement_user_force_user_in_group_${usergroup_user_index}"
                     );

      "groupopt[${usergroup_user_index}]"
        string => "-g ${usergroup_user_login[${usergroup_user_index}]}",
            if => "usermanagement_user_force_user_in_group_${usergroup_user_index}";

      # 3 - on UNIX force user id if provided
      "useropt[${usergroup_user_index}]"
        string => "",
            if => "usermanagement_user_uid_empty_${usergroup_user_index}";

      "useropt[${usergroup_user_index}]"
        string => "-u ${usergroup_user_uid[${usergroup_user_index}]}",
            if => "!usermanagement_user_uid_empty_${usergroup_user_index}";

      # define inner class prefix of secondary group management
      "args"                           slist => { "${login}", "${groups}", "${force}" };
      "inner_classprefix_secondary_group_${usergroup_user_index}"
        string => canonify(string_head("user_secondary_groups_${usergroup_user_login[${usergroup_user_index}]}_${usergroup_user_secondary_groupsname[${usergroup_user_index}]}_${usergroup_force_user_secondary_groupsname[${usergroup_user_index}]}", 1000)),
            if => "!usermanagement_user_secondary_groupsempty_${usergroup_user_index}";

    any_2nd_pass.!pass2::


      "usermanagement_user_move_home_dir_from[${usergroup_user_index}]" string => execresult("${paths.grep} '^${usergroup_user_login[${usergroup_user_index}]}:' /etc/passwd | ${paths.cut} -d: -f6", "useshell"),
           if => "usermanagement_user_exists_${usergroup_user_index}";

  classes:
    !pass1::
      # detect first if the user exist
      "usermanagement_user_exists_${usergroup_user_index}" expression => userexists("${usergroup_user_login[${usergroup_user_index}]}");

      "usermanagement_user_add_${usergroup_user_index}"        expression => strcmp("${usergroup_user_action[${usergroup_user_index}]}","add");
      "usermanagement_user_updateonly_${usergroup_user_index}" expression => strcmp("${usergroup_user_action[${usergroup_user_index}]}","updateonly");
      "usermanagement_user_remove_${usergroup_user_index}"     expression => strcmp("${usergroup_user_action[${usergroup_user_index}]}","remove");

      # If we ask to update only and user does not exist, then we won't do anything
      "usermanagement_user_skipall_${usergroup_user_index}" expression => and("!usermanagement_user_exists_${usergroup_user_index}", "usermanagement_user_updateonly_${usergroup_user_index}");
      "usermanagement_user_create_${usergroup_user_index}"  expression => and("!usermanagement_user_exists_${usergroup_user_index}", "usermanagement_user_add_${usergroup_user_index}");
      "usermanagement_user_update_${usergroup_user_index}"  expression => and(
                                                                              "usermanagement_user_exists_${usergroup_user_index}",
                                                                               or(
                                                                                 "usermanagement_user_add_${usergroup_user_index}",
                                                                                 "usermanagement_user_updateonly_${usergroup_user_index}"
                                                                               )
                                                                             );

    # Actions
    any::
      # NOTE: usergroup_user_home_perso is true when we use the default home, and thus usermanagement_user_pershome_ is true when we don't want to use the default home
      "usermanagement_user_pershome_${usergroup_user_index}" not => strcmp("${usergroup_user_home_perso[${usergroup_user_index}]}","true");

      "usermanagement_user_custom_home_no_variable_${usergroup_user_index}"     not => isvariable("usergroup_user_home[${usergroup_user_index}]");
      "usermanagement_user_custom_home_no_value_${usergroup_user_index}" expression => strcmp("", "${usergroup_user_home[${usergroup_user_index}]}");
      "usermanagement_user_custom_home_defined_${usergroup_user_index}"  expression => and( "!usermanagement_user_custom_home_no_variable_${usergroup_user_index}",
                                                                                            "!usermanagement_user_custom_home_no_value_${usergroup_user_index}"
                                                                                          );

      # If we ask to personnalize home, but not define it, it is invalid
      "usermanagement_user_home_pershome_invalid_${usergroup_user_index}" expression => and( "usermanagement_user_pershome_${usergroup_user_index}",
                                                                                             "!usermanagement_user_custom_home_defined_${usergroup_user_index}"
                                                                                           );

      # Asked to move the home directory
      "usermanagement_user_custom_home_move_${usergroup_user_index}" expression => strcmp("${usergroup_user_home_move[${usergroup_user_index}]}","true");

      # The request to move home is valid: the path to move to is defined, and we asked to personalize
      "usermanagement_user_custom_home_move_valid_${usergroup_user_index}" expression => and( "usermanagement_user_custom_home_move_${usergroup_user_index}",
                                                                                              "usermanagement_user_custom_home_defined_${usergroup_user_index}",
                                                                                              "usermanagement_user_pershome_${usergroup_user_index}"
                                                                                            );



      "usermanagement_group_exists_${usergroup_user_index}" expression => groupexists("${usergroup_user_groupname[${usergroup_user_index}]}");

      "usermanagement_user_pwoneshot_${usergroup_user_index}" expression => strcmp("${usergroup_user_password_policy[${usergroup_user_index}]}","oneshot");

      "usermanagement_user_pweverytime_${usergroup_user_index}" expression => strcmp("${usergroup_user_password_policy[${usergroup_user_index}]}","everytime");

      # with variables that are not unique, the emptiness detection is quite tricky
      # either the variable is not defined, or the variable value is ""
      "usermanagement_user_pw_no_variable_${usergroup_user_index}"     not => isvariable("usergroup_user_password[${usergroup_user_index}]");
      "usermanagement_user_pw_no_value_${usergroup_user_index}" expression => strcmp("", "${usergroup_user_password[${usergroup_user_index}]}");
      "usermanagement_user_pwempty_${usergroup_user_index}"     expression => or( "usermanagement_user_pw_no_variable_${usergroup_user_index}",
                                                                                  "usermanagement_user_pw_no_value_${usergroup_user_index}"
                                                                                );

      "usermanagement_user_name_no_variable_${usergroup_user_index}"     not => isvariable("usergroup_user_fullname[${usergroup_user_index}]");
      "usermanagement_user_name_no_value_${usergroup_user_index}" expression => strcmp("", "${usergroup_user_fullname[${usergroup_user_index}]}");
      "usermanagement_user_nameempty_${usergroup_user_index}"     expression => or( "usermanagement_user_name_no_variable_${usergroup_user_index}",
                                                                                    "usermanagement_user_name_no_value_${usergroup_user_index}"
                                                                                  );

      "usermanagement_user_group_no_variable_${usergroup_user_index}"     not => isvariable("usergroup_user_groupname[${usergroup_user_index}]");
      "usermanagement_user_group_no_value_${usergroup_user_index}" expression =>  strcmp("", "${usergroup_user_groupname[${usergroup_user_index}]}");
      "usermanagement_user_groupempty_${usergroup_user_index}"     expression => or( "usermanagement_user_group_no_variable_${usergroup_user_index}",
                                                                                     "usermanagement_user_group_no_value_${usergroup_user_index}"
                                                                                   );

      "usermanagement_force_user_group_${usergroup_user_index}"         expression => strcmp("true", "${usergroup_force_user_groupname[${usergroup_user_index}]}");
      "usermanagement_force_user_group_defined_${usergroup_user_index}" expression => and( "usermanagement_force_user_group_${usergroup_user_index}",
                                                                                           "!usermanagement_user_groupempty_${usergroup_user_index}"
                                                                                         );
      # check if secondary groups are defined
      "usermanagement_user_secondary_groups_no_variable_${usergroup_user_index}"     not => isvariable("usergroup_user_secondary_groupsname[${usergroup_user_index}]");
      "usermanagement_user_secondary_groups_no_value_${usergroup_user_index}" expression => strcmp("", "${usergroup_user_secondary_groupsname[${usergroup_user_index}]}");
      "usermanagement_user_secondary_groupsempty_${usergroup_user_index}"     expression => or( "usermanagement_user_secondary_groups_no_variable_${usergroup_user_index}",
                                                                                                "usermanagement_user_secondary_groups_no_value_${usergroup_user_index}"
                                                                                              );

      "usermanagement_user_uid_no_variable_${usergroup_user_index}"     not => isvariable("usergroup_user_uid[${usergroup_user_index}]");
      "usermanagement_user_uid_no_value_${usergroup_user_index}" expression => strcmp("", "${usergroup_user_uid[${usergroup_user_index}]}");
      "usermanagement_user_uid_empty_${usergroup_user_index}"    expression => or( "usermanagement_user_uid_no_variable_${usergroup_user_index}",
                                                                                   "usermanagement_user_uid_no_value_${usergroup_user_index}"
                                                                                  );

      "usermanagement_user_groupmatchesname_${usergroup_user_index}" expression => strcmp("${usergroup_user_login[${usergroup_user_index}]}", "${usergroup_user_groupname[${usergroup_user_index}]}");

      # Group doesn't exist and group name is defined
      "usermanagement_user_group_definition_error_${usergroup_user_index}" expression => or(and( "!usermanagement_group_exists_${usergroup_user_index}",
                                                                                                 "usermanagement_user_groupmatchesname_${usergroup_user_index}"
                                                                                               ),
                                                                                            and( "!usermanagement_user_groupempty_${usergroup_user_index}",
                                                                                                 "!usermanagement_group_exists_${usergroup_user_index}"
                                                                                               )
                                                                                            );

      # check if user exists when enforcing ids
      "usermanagement_uid_exists_${usergroup_user_index}" expression => userexists("${usergroup_user_uid[${usergroup_user_index}]}"),
                                                                  if => "!usermanagement_user_uid_empty_${usergroup_user_index}";

      # UID is defined and already exists
      "usermanagement_user_uid_definition_error_${usergroup_user_index}" expression => "!usermanagement_user_uid_empty_${usergroup_user_index}.usermanagement_uid_exists_${usergroup_user_index}";

      # if we want to create a user, and a group with the username exists (no group name defined),then we need to force addition of user to that group (mandatory for debian and redhat, non mandatory for SLES)
      "usermanagement_user_force_user_in_group_${usergroup_user_index}" expression => groupexists("${usergroup_user_login[${usergroup_user_index}]}"),
          if => and( "usermanagement_user_groupempty_${usergroup_user_index}",
                     "!usermanagement_user_nameempty_${usergroup_user_index}"
                   );

    # Class 'any' is executed before others classes defined.
    # Same as 'any' but execution will be after all classes defined
      "any_2nd_pass" expression => "any";
      "showtime"     expression => isvariable("nameopt[1]");

    showtime::
      # if defined, we can move the user home (because we know the previous value)
      "usermanagement_user_current_home_defined_${usergroup_user_index}" expression => isvariable("usermanagement_user_move_home_dir_from[${usergroup_user_index}]");

      # Must move the home if:
      # - home is not the same as the defined home on the node for user
      # - we asked to personnalize, and the values are valid
      "usermanagement_user_current_home_is_invalid_${usergroup_user_index}" not => strcmp("${usermanagement_user_move_home_dir_from[${usergroup_user_index}]}", "${usergroup_user_home[${usergroup_user_index}]}"),
           if => and( "usermanagement_user_current_home_defined_${usergroup_user_index}",
                      "usermanagement_user_pershome_${usergroup_user_index}",
                      "!usermanagement_user_home_pershome_invalid_${usergroup_user_index}"
                    );


    pass2::
      # create classes for the reporting (error case mostly)
      "usermanagement_user_creation_failed_${usergroup_user_index}" expression =>
      and( "!usermanagement_user_exists_${usergroup_user_index}",
                     "usermanagement_user_create_${usergroup_user_index}",
                     or (
                       "usermanagement_user_group_definition_error_${usergroup_user_index}",
                       "usermanagement_login_add_${usergroup_user_index}_&RudderUniqueID&_error"
                     )
                   );
    any::
      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";

  methods:
    pass3::
      # Creation is done in the commands: section

      #####################
      # Update user section
      #####################
      "en_&RudderUniqueID&" usebundle => enable_reporting;

      ###############
      # User deletion
      "any" usebundle => delete_&RudderUniqueID&("${usergroup_user_login[${usergroup_user_index}]}", "${usergroup_user_index}"),
                   if => "usermanagement_user_remove_${usergroup_user_index}";

      ###############
      # Primary group
      "any" usebundle => primary_group_&RudderUniqueID&("${usergroup_user_login[${usergroup_user_index}]}", "${usergroup_user_groupname[${usergroup_user_index}]}", "${usergroup_user_index}"),
                   if => "usermanagement_user_update_${usergroup_user_index}.usermanagement_force_user_group_defined_${usergroup_user_index}";

      # no primary group has been set
      "any" usebundle  => rudder_common_report_index("userGroupManagement", "result_na", "${usergroup_directive_id[${usergroup_user_index}]}", "User primary group", "${usergroup_user_login[${usergroup_user_index}]}", "No primary group defined for user", "${usergroup_user_index}"),
                    if => "usermanagement_user_update_${usergroup_user_index}.!usermanagement_force_user_group_defined_${usergroup_user_index}";

      # Don't exist and in update only or deletion
      "any" usebundle  => rudder_common_report_index("userGroupManagement", "result_na", "${usergroup_directive_id[${usergroup_user_index}]}", "User primary group", "${usergroup_user_login[${usergroup_user_index}]}", "User primary group is not checked in this mode", "${usergroup_user_index}"),
                    if => "usermanagement_user_skipall_${usergroup_user_index}|usermanagement_user_remove_${usergroup_user_index}";

      # Couldn't create the user
      "any" usebundle  => rudder_common_report_index("userGroupManagement", "result_error", "${usergroup_directive_id[${usergroup_user_index}]}", "User primary group", "${usergroup_user_login[${usergroup_user_index}]}", "User could not be created", "${usergroup_user_index}"),
                    if => "usermanagement_user_creation_failed_${usergroup_user_index}";

      # User created
      "any" usebundle  => rudder_common_report_index("userGroupManagement", "result_repaired", "${usergroup_directive_id[${usergroup_user_index}]}", "User primary group", "${usergroup_user_login[${usergroup_user_index}]}", "User ${usergroup_user_login[${usergroup_user_index}]} has been created", "${usergroup_user_index}"),
                    if => "usermanagement_login_add_${usergroup_user_index}_&RudderUniqueID&_repaired";
      ###############
      # Password
      # Note: the password should also be checked at creation, because otherwise it won't be set at 1st run
      "any" usebundle => password_&RudderUniqueID&("${usergroup_user_login[${usergroup_user_index}]}", "${usergroup_user_password[${usergroup_user_index}]}", "${usergroup_user_index}"),
                    if => and( or( "usermanagement_user_create_${usergroup_user_index}",
                                   "usermanagement_user_update_${usergroup_user_index}"
                                 ),
                               "usermanagement_user_pweverytime_${usergroup_user_index}",
                               "!usermanagement_user_pwempty_${usergroup_user_index}"
                             );

      # no password supplied
      "any" usebundle  => rudder_common_report_index("userGroupManagement", "result_na", "${usergroup_directive_id[${usergroup_user_index}]}", "Password", "${usergroup_user_login[${usergroup_user_index}]}", "No password defined for user", "${usergroup_user_index}"),
                    if => and( or( "usermanagement_user_create_${usergroup_user_index}",
                                   "usermanagement_user_update_${usergroup_user_index}"
                                 ),
                               "usermanagement_user_pwempty_${usergroup_user_index}"
                             );

      # password not checked everytime
      "any" usebundle  => rudder_common_report_index("userGroupManagement", "result_na", "${usergroup_directive_id[${usergroup_user_index}]}", "Password", "${usergroup_user_login[${usergroup_user_index}]}", "Password only checked at creation", "${usergroup_user_index}"),
                    if => "usermanagement_user_update_${usergroup_user_index}.usermanagement_user_pwoneshot_${usergroup_user_index}.!usermanagement_user_pwempty_${usergroup_user_index}";

      # In update only or deletion
      "any" usebundle  => rudder_common_report_index("userGroupManagement", "result_na", "${usergroup_directive_id[${usergroup_user_index}]}", "Password", "${usergroup_user_login[${usergroup_user_index}]}", "User password is not checked in this mode", "${usergroup_user_index}"),
                    if => "usermanagement_user_skipall_${usergroup_user_index}|usermanagement_user_remove_${usergroup_user_index}";

      # Couldn't create the user
      # this is an error, but we don't want to duplicate the report from the test of password in the actual call by the GM
      "any" usebundle  => rudder_common_report_index("userGroupManagement", "result_error", "${usergroup_directive_id[${usergroup_user_index}]}", "Password", "${usergroup_user_login[${usergroup_user_index}]}", "User could not be created", "${usergroup_user_index}"),
                    if => "usermanagement_user_creation_failed_${usergroup_user_index}.(!(usermanagement_user_update_${usergroup_user_index}|usermanagement_user_create_${usergroup_user_index}).usermanagement_user_pweverytime_${usergroup_user_index}.!usermanagement_user_pwempty_${usergroup_user_index})";

      ################
      # User full name
      "any" usebundle => fullname_&RudderUniqueID&("${usergroup_user_login[${usergroup_user_index}]}", "${usergroup_user_fullname[${usergroup_user_index}]}", "${usegroup_user_index}"),
                   if => "usermanagement_user_update_${usergroup_user_index}.!usermanagement_user_nameempty_${usergroup_user_index}";

      # no full name has been set
      "any" usebundle  => rudder_common_report_index("userGroupManagement", "result_na", "${usergroup_directive_id[${usergroup_user_index}]}", "User full name", "${usergroup_user_login[${usergroup_user_index}]}", "No full name defined for user", "${usergroup_user_index}"),
                    if => "usermanagement_user_update_${usergroup_user_index}.usermanagement_user_nameempty_${usergroup_user_index}";

      # Don't exist and in update only or deletion
      "any" usebundle  => rudder_common_report_index("userGroupManagement", "result_na", "${usergroup_directive_id[${usergroup_user_index}]}", "User full name", "${usergroup_user_login[${usergroup_user_index}]}", "Full name is not checked in this mode", "${usergroup_user_index}"),
                    if => "usermanagement_user_skipall_${usergroup_user_index}|usermanagement_user_remove_${usergroup_user_index}";

      # Couldn't create the user
      "any" usebundle  => rudder_common_report_index("userGroupManagement", "result_error", "${usergroup_directive_id[${usergroup_user_index}]}", "User full name", "${usergroup_user_login[${usergroup_user_index}]}", "User could not be created", "${usergroup_user_index}"),
                    if => "usermanagement_user_creation_failed_${usergroup_user_index}";

      # User created
      "any" usebundle  => rudder_common_report_index("userGroupManagement", "result_repaired", "${usergroup_directive_id[${usergroup_user_index}]}", "User full name", "${usergroup_user_login[${usergroup_user_index}]}", "User ${usergroup_user_login[${usergroup_user_index}]} has been created", "${usergroup_user_index}"),
                    if => "usermanagement_login_add_${usergroup_user_index}_&RudderUniqueID&_repaired";
      ###############
      # Default shell
      "any" usebundle => default_shell_&RudderUniqueID&("${usergroup_user_login[${usergroup_user_index}]}", "${usergroup_user_shell[${usergroup_user_index}]}", "${usergroup_user_index}"),
                   if => "usermanagement_user_update_${usergroup_user_index}";

      # Don't exist and in update only or deletion
      "any" usebundle  => rudder_common_report_index("userGroupManagement", "result_na", "${usergroup_directive_id[${usergroup_user_index}]}", "User default shell", "${usergroup_user_login[${usergroup_user_index}]}", "User default shell is not checked in this mode", "${usergroup_user_index}"),
                    if => "usermanagement_user_skipall_${usergroup_user_index}|usermanagement_user_remove_${usergroup_user_index}";

      # Couldn't create the user
      "any" usebundle  => rudder_common_report_index("userGroupManagement", "result_error", "${usergroup_directive_id[${usergroup_user_index}]}", "User default shell", "${usergroup_user_login[${usergroup_user_index}]}", "User could not be created", "${usergroup_user_index}"),
                    if => "usermanagement_user_creation_failed_${usergroup_user_index}";

      # User created
      "any" usebundle  => rudder_common_report_index("userGroupManagement", "result_repaired", "${usergroup_directive_id[${usergroup_user_index}]}", "User default shell", "${usergroup_user_login[${usergroup_user_index}]}", "User ${usergroup_user_login[${usergroup_user_index}]} has been created", "${usergroup_user_index}"),
                    if => "usermanagement_login_add_${usergroup_user_index}_&RudderUniqueID&_repaired";
      ###############
      # Home directory
      # This is a specific case - as the move is not handled by generic method
      ## In case of user to remove this is a result_na
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_na", "${usergroup_directive_id[${usergroup_user_index}]}", "Home directory", "${usergroup_user_login[${usergroup_user_index}]}", "The user ${usergroup_user_login[${usergroup_user_index}]} should not be present, it doesn't need to have its home directory checked", "${usergroup_user_index}"),
          if => "usermanagement_user_remove_${usergroup_user_index}";

      ## In case of user present or update, but with default home, this is result_na
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_na", "${usergroup_directive_id[${usergroup_user_index}]}", "Home directory", "${usergroup_user_login[${usergroup_user_index}]}", "The user ${usergroup_user_login[${usergroup_user_index}]} doesn't need to have its home directory checked", "${usergroup_user_index}"),
          if => and( "!usermanagement_user_pershome_${usergroup_user_index}", "usermanagement_user_update_${usergroup_user_index}" );

      ## In case of check user present or update, but the home is already correct, this is success
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_success", "${usergroup_directive_id[${usergroup_user_index}]}", "Home directory", "${usergroup_user_login[${usergroup_user_index}]}", "The user ${usergroup_user_login[${usergroup_user_index}]} home directory is valid", "${usergroup_user_index}"),
          if => and( "usermanagement_user_pershome_${usergroup_user_index}",
                      "!usermanagement_user_home_pershome_invalid_${usergroup_user_index}",
                      "!usermanagement_user_current_home_is_invalid_${usergroup_user_index}",
                      "usermanagement_user_update_${usergroup_user_index}"
                   );

      ## In case of check user present or update, but the custom home directory is not valid
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_error", "${usergroup_directive_id[${usergroup_user_index}]}", "Home directory", "${usergroup_user_login[${usergroup_user_index}]}", "The given home directory for user ${usergroup_user_login[${usergroup_user_index}]} is invalid", "${usergroup_user_index}"),
          if => and( "usermanagement_user_pershome_${usergroup_user_index}",
                      "usermanagement_user_home_pershome_invalid_${usergroup_user_index}",
                      "usermanagement_user_update_${usergroup_user_index}"
                    );

      ## In case of update, but the home was not correct, and could be changed, this is repaired
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_repaired", "${usergroup_directive_id[${usergroup_user_index}]}", "Home directory", "${usergroup_user_login[${usergroup_user_index}]}", "The user ${usergroup_user_login[${usergroup_user_index}]} home directory was changed (but not moved)", "${usergroup_user_index}"),
          if => and( "usermanagement_user_pershome_${usergroup_user_index}",
                     "usermanagement_user_current_home_is_invalid_${usergroup_user_index}",
                     "usermanagement_user_update_${usergroup_user_index}",
                     "!usermanagement_user_custom_home_move_${usergroup_user_index}",
                     or( "usermanagement_login_home_change_${usergroup_user_index}_&RudderUniqueID&_repaired",
                         "!usermanagement_login_home_change_${usergroup_user_index}_&RudderUniqueID&_error"
                       )
                   );

      ## In case of update, but the home was not correct, and could not be changed, this is error
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_error", "${usergroup_directive_id[${usergroup_user_index}]}", "Home directory", "${usergroup_user_login[${usergroup_user_index}]}", "The user ${usergroup_user_login[${usergroup_user_index}]} home directory could not be changed", "${usergroup_user_index}"),
          if => and( "usermanagement_user_pershome_${usergroup_user_index}",
                     "usermanagement_login_home_change_${usergroup_user_index}_&RudderUniqueID&_error",
                     "usermanagement_user_current_home_is_invalid_${usergroup_user_index}",
                     "usermanagement_user_update_${usergroup_user_index}"
                   );

      ## In case of update, but the home was not correct, and could be moved, this is repaired
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_repaired", "${usergroup_directive_id[${usergroup_user_index}]}", "Home directory", "${usergroup_user_login[${usergroup_user_index}]}", "The user ${usergroup_user_login[${usergroup_user_index}]} home directory was moved", "${usergroup_user_index}"),
          if => and( "usermanagement_user_pershome_${usergroup_user_index}",
                     "usermanagement_login_home_move_${usergroup_user_index}_&RudderUniqueID&_repaired",
                     "!usermanagement_login_home_move_${usergroup_user_index}_&RudderUniqueID&_error",
                     "usermanagement_user_current_home_is_invalid_${usergroup_user_index}",
                     "usermanagement_user_update_${usergroup_user_index}"
                   );

      ## In case of update, but the home was not correct, and could not be moved, this is error
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_error", "${usergroup_directive_id[${usergroup_user_index}]}", "Home directory", "${usergroup_user_login[${usergroup_user_index}]}", "The user ${usergroup_user_login[${usergroup_user_index}]} home directory could not be moved", "${usergroup_user_index}"),
          if => and( "usermanagement_user_pershome_${usergroup_user_index}",
                     "usermanagement_login_home_move_${usergroup_user_index}_&RudderUniqueID&_error",
                     "usermanagement_user_current_home_is_invalid_${usergroup_user_index}",
                     "usermanagement_user_update_${usergroup_user_index}"
                   );

      # Couldn't create the user
      "any" usebundle  => rudder_common_report_index("userGroupManagement", "result_error", "${usergroup_directive_id[${usergroup_user_index}]}", "Home directory", "${usergroup_user_login[${usergroup_user_index}]}", "User could not be created", "${usergroup_user_index}"),
                    if => "usermanagement_user_creation_failed_${usergroup_user_index}";

      # User created
      "any" usebundle  => rudder_common_report_index("userGroupManagement", "result_repaired", "${usergroup_directive_id[${usergroup_user_index}]}", "Home directory", "${usergroup_user_login[${usergroup_user_index}]}", "User ${usergroup_user_login[${usergroup_user_index}]} has been created", "${usergroup_user_index}"),
                    if => "usermanagement_login_add_${usergroup_user_index}_&RudderUniqueID&_repaired";

      # User doesn't exist and we are in update
      "any" usebundle  => rudder_common_report_index("userGroupManagement", "result_na", "${usergroup_directive_id[${usergroup_user_index}]}", "Home directory", "${usergroup_user_login[${usergroup_user_index}]}", "User does not exist, not checking home directory", "${usergroup_user_index}"),
                    if => "!usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_updateonly_${usergroup_user_index}";
      ############################
      # set/check secondary groups
      # Note: the secondary group should also be checked at creation, because otherwise it won't be set at 1st run

      "any" usebundle => secondary_group_&RudderUniqueID&("${usergroup_user_login[${usergroup_user_index}]}", "${usergroup_user_secondary_groupsname[${usergroup_user_index}]}", "${usergroup_force_user_secondary_groupsname[${usergroup_user_index}]}", "${usergroup_user_index}"),
                   if => "!usermanagement_user_secondary_groupsempty_${usergroup_user_index}.(usermanagement_user_update_${usergroup_user_index}|usermanagement_user_create_${usergroup_user_index})";

      # no secondary group has been set
      "any" usebundle  => rudder_common_report_index("userGroupManagement", "result_na", "${usergroup_directive_id[${usergroup_user_index}]}", "User secondary groups", "${usergroup_user_login[${usergroup_user_index}]}", "No secondary groups defined for user", "${usergroup_user_index}"),
                    if => and( "usermanagement_user_secondary_groupsempty_${usergroup_user_index}",
                               or( "usermanagement_user_update_${usergroup_user_index}",
                                   "usermanagement_user_create_${usergroup_user_index}"
                                 )
                             );

      # Don't exist and in update only or deletion
      "any" usebundle  => rudder_common_report_index("userGroupManagement", "result_na", "${usergroup_directive_id[${usergroup_user_index}]}", "User secondary groups", "${usergroup_user_login[${usergroup_user_index}]}", "User secondary groups are not checked in this mode", "${usergroup_user_index}"),
                    if => "usermanagement_user_skipall_${usergroup_user_index}|usermanagement_user_remove_${usergroup_user_index}";

      # Couldn't create the user
      "any" usebundle  => rudder_common_report_index("userGroupManagement", "result_error", "${usergroup_directive_id[${usergroup_user_index}]}", "User secondary groups", "${usergroup_user_login[${usergroup_user_index}]}", "User could not be created", "${usergroup_user_index}"),
                    if => "usermanagement_user_creation_failed_${usergroup_user_index}";

      #############################
      # Only reporting after that #

      # Users
      # Add user
      ## Does exist (Success)
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_success", "${usergroup_directive_id[${usergroup_user_index}]}", "Users", "${usergroup_user_login[${usergroup_user_index}]}", "The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) is already present on the system", "${usergroup_user_index}"),
          if => and( "usermanagement_user_exists_${usergroup_user_index}",
                     "usermanagement_user_create_${usergroup_user_index}",
                     "!usermanagement_login_add_${usergroup_user_index}_&RudderUniqueID&_repaired",
                     "!usermanagement_login_add_${usergroup_user_index}_&RudderUniqueID&_error"
                   );

      ## Created (repaired)
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_repaired", "${usergroup_directive_id[${usergroup_user_index}]}", "Users", "${usergroup_user_login[${usergroup_user_index}]}", "The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) has been created on the system", "${usergroup_user_index}"),
          if => and( "!usermanagement_user_exists_${usergroup_user_index}",
                     "usermanagement_user_create_${usergroup_user_index}",
                     "usermanagement_login_add_${usergroup_user_index}_&RudderUniqueID&_repaired",
                     "!usermanagement_login_add_${usergroup_user_index}_&RudderUniqueID&_error"
                   );

      ## Failed to create (error)
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_error", "${usergroup_directive_id[${usergroup_user_index}]}", "Users", "${usergroup_user_login[${usergroup_user_index}]}", "The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) could not be created on the system", "${usergroup_user_index}"),
          if => and( "!usermanagement_user_exists_${usergroup_user_index}",
                     "usermanagement_user_create_${usergroup_user_index}",
                     "usermanagement_login_add_${usergroup_user_index}_&RudderUniqueID&_error"
                   );

      ## Wrong group, didn't even try to create (error)
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_error", "${usergroup_directive_id[${usergroup_user_index}]}", "Users", "${usergroup_user_login[${usergroup_user_index}]}", "The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) can not be created as the group is invalid", "${usergroup_user_index}"),
          if => and( "!usermanagement_user_exists_${usergroup_user_index}",
                     "usermanagement_user_create_${usergroup_user_index}",
                     "usermanagement_user_group_definition_error_${usergroup_user_index}"
                   );

      ## update only if exist - does not exist: NA
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_na", "${usergroup_directive_id[${usergroup_user_index}]}", "Users", "${usergroup_user_login[${usergroup_user_index}]}", "The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) is not present", "${usergroup_user_index}"),
          if => and( "!usermanagement_user_exists_${usergroup_user_index}",
                     "usermanagement_user_updateonly_${usergroup_user_index}"
                   );

      ## create/update only if exist - exist: success
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_success", "${usergroup_directive_id[${usergroup_user_index}]}", "Users", "${usergroup_user_login[${usergroup_user_index}]}", "The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) is already present on the system", "${usergroup_user_index}"),
          if => "usermanagement_user_update_${usergroup_user_index}";

  commands:
    showtime::

      "/usr/sbin/useradd"
        args => "${useropt[${usergroup_user_index}]} ${groupopt[${usergroup_user_index}]} -m ${nameopt[${usergroup_user_index}]} -s ${usergroup_user_shell[${usergroup_user_index}]} ${usergroup_user_login[${usergroup_user_index}]}",
        classes => cf2_if_else("usermanagement_login_add_${usergroup_user_index}_&RudderUniqueID&_repaired", "usermanagement_login_add_${usergroup_user_index}_&RudderUniqueID&_error"),
        comment => "Create the user",
             if => and( "!usermanagement_user_uid_definition_error_${usergroup_user_index}",
                        "!usermanagement_user_group_definition_error_${usergroup_user_index}",
                        "usermanagement_user_create_${usergroup_user_index}",
                        "!usermanagement_user_pershome_${usergroup_user_index}"
                      );

      "/usr/sbin/useradd"
        args => "${useropt[${usergroup_user_index}]} ${groupopt[${usergroup_user_index}]} -m ${nameopt[${usergroup_user_index}]} -s ${usergroup_user_shell[${usergroup_user_index}]} -d ${usergroup_user_home[${usergroup_user_index}]} ${usergroup_user_login[${usergroup_user_index}]}",
        classes => cf2_if_else("usermanagement_login_add_${usergroup_user_index}_&RudderUniqueID&_repaired", "usermanagement_login_add_${usergroup_user_index}_&RudderUniqueID&_error"),
        comment => "Create the user with a custom home directory",
             if => and( "!usermanagement_user_uid_definition_error_${usergroup_user_index}",
                        "!usermanagement_user_group_definition_error_${usergroup_user_index}",
                        "usermanagement_user_create_${usergroup_user_index}",
                        "usermanagement_user_pershome_${usergroup_user_index}",
                        "usermanagement_user_custom_home_defined_${usergroup_user_index}"
                       );

      ## Change user home dir
      ## This cannot be done via the generic method because it is really a specific use case
      ## Move the home dir
      "/usr/sbin/usermod"
        args       => "-d ${usergroup_user_home[${usergroup_user_index}]} -m ${usergroup_user_login[${usergroup_user_index}]}",
        classes    => cf2_if_else("usermanagement_login_home_move_${usergroup_user_index}_&RudderUniqueID&_repaired", "usermanagement_login_home_move_${usergroup_user_index}_&RudderUniqueID&_error"),
        comment    => "Change home directory (move it)",
                if => and( "usermanagement_user_update_${usergroup_user_index}",
                           "usermanagement_user_current_home_is_invalid_${usergroup_user_index}",
                           "usermanagement_user_custom_home_move_valid_${usergroup_user_index}"
                         );

      ## Doesn't move the home dir
      "/usr/sbin/usermod"
        args       => "-d ${usergroup_user_home[${usergroup_user_index}]} ${usergroup_user_login[${usergroup_user_index}]}",
        classes    => cf2_if_else("usermanagement_login_home_change_${usergroup_user_index}_&RudderUniqueID&_repaired", "usermanagement_login_home_change_${usergroup_user_index}_&RudderUniqueID&_error"),
        comment    => "Change home directory definition for user (doesn't move files)",
                if => and( "usermanagement_user_update_${usergroup_user_index}",
                           "usermanagement_user_current_home_is_invalid_${usergroup_user_index}",
                           "!usermanagement_user_custom_home_move_${usergroup_user_index}"
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

bundle agent delete_&RudderUniqueID&(user_login, index) {
  vars:
      "id" string => canonify("&RudderUniqueID&_${index}");
  methods:
      "any" usebundle => _method_reporting_context_v4("Users", "${user_login}", "${id}");
      "any" usebundle => user_absent("${user_login}");
}

bundle agent primary_group_&RudderUniqueID&(user_login, group_name, index) {
  vars:
      "id" string => canonify("&RudderUniqueID&_${index}");
  methods:
      "any" usebundle => _method_reporting_context_v4("User primary group", "${user_login}", "${id}");
      "any" usebundle => user_primary_group("${user_login}", "${group_name}");
}

bundle agent password_&RudderUniqueID&(user_login, password, index) {
  vars:
      "id" string => canonify("&RudderUniqueID&_${index}");
  methods:
      "any" usebundle => _method_reporting_context_v4("Password", "${user_login}", "${id}");
      "any" usebundle => user_password_hash("${user_login}", "${password}"); #TODO check if changes the age
}

bundle agent fullname_&RudderUniqueID&(user_login, fullname, index) {
  vars:
      "id" string => canonify("&RudderUniqueID&_${index}");
  methods:
      "any" usebundle => _method_reporting_context_v4("User full name", "${user_login}", "${id}");
      "any" usebundle => user_fullname("${user_login}", "${fullname}");
}

bundle agent default_shell_&RudderUniqueID&(user_login, shell, index) {
  vars:
      "id" string => canonify("&RudderUniqueID&_${index}");
  methods:
      "any" usebundle => _method_reporting_context_v4("User default shell", "${user_login}", "${id}");
      "any" usebundle => user_shell("${user_login}", "${shell}");
}

bundle agent secondary_group_&RudderUniqueID&(user_login, groups, force_groups, index) {
  vars:
      "id" string => canonify("&RudderUniqueID&_${index}");
  methods:
      "any" usebundle => _method_reporting_context_v4("User secondary groups", "${user_login}", "${id}");
      "any" usebundle => user_secondary_groups("${user_login}", "${groups}", "${force_groups}");
}
