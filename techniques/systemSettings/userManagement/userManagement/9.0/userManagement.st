#####################################################################################
# Copyright 2011-2018 Normation SAS
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

##########################################################################
# User management Technique                                              #
#                                                                        #
# Objective : Apply user/group policies on the target host               #
##########################################################################

bundle agent check_usergroup_user_parameters_RudderUniqueID
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

      "usergroup_user_index" slist => getindices("usergroup_user_login");


    any_2nd_pass::

      # 1 - Options to use whether Fullname is defined or not
      "nameopt[${usergroup_user_index}]"
        string => "",
        ifvarclass => "usermanagement_user_nameempty_${usergroup_user_index}";

      ## On UNIX
      "nameopt[${usergroup_user_index}]"
        string => "-c \"${usergroup_user_fullname[${usergroup_user_index}]}\"",
        ifvarclass => "!usermanagement_user_nameempty_${usergroup_user_index}";

      ## Part of reports to return whether Fullname is defined or not
      "repname[${usergroup_user_index}]"
        string => "Without any defined full name",
        ifvarclass => "usermanagement_user_nameempty_${usergroup_user_index}";

      "repname[${usergroup_user_index}]"
        string => "${usergroup_user_fullname[${usergroup_user_index}]}",
        ifvarclass => "!usermanagement_user_nameempty_${usergroup_user_index}";

      # 2 - On UNIX, choose between using no group name or using a custom one
      "groupopt[${usergroup_user_index}]"
        string => "",
        ifvarclass => "usermanagement_user_groupempty_${usergroup_user_index}.!usermanagement_user_force_user_in_group_${usergroup_user_index}";

      "groupopt[${usergroup_user_index}]"
        string => "-g ${usergroup_user_groupname[${usergroup_user_index}]}",
        ifvarclass => "!usermanagement_user_groupempty_${usergroup_user_index}.!usermanagement_user_force_user_in_group_${usergroup_user_index}";

      "groupopt[${usergroup_user_index}]"
        string     => "-g ${usergroup_user_login[${usergroup_user_index}]}",
        ifvarclass => "usermanagement_user_force_user_in_group_${usergroup_user_index}";

      # 3 - on UNIX force user id if provided
      "useropt[${usergroup_user_index}]"
        string => "",
        ifvarclass => "usermanagement_user_uid_empty_${usergroup_user_index}";

      "useropt[${usergroup_user_index}]"
        string => "-u ${usergroup_user_uid[${usergroup_user_index}]}",
        ifvarclass => "!usermanagement_user_uid_empty_${usergroup_user_index}";

    any_2nd_pass.!pass2::


      "usermanagement_user_move_home_dir_from[${usergroup_user_index}]" string => execresult("${paths.grep} '^${usergroup_user_login[${usergroup_user_index}]}:' /etc/passwd | ${paths.cut} -d: -f6", "useshell"),
        ifvarclass => "usermanagement_user_exists_${usergroup_user_index}";

      # Get current user gid (or name) to compare it with the setted on, if we need to force it
      "user_current_gid[${usergroup_user_index}]"   string => execresult("/usr/bin/id -g ${usergroup_user_login[${usergroup_user_index}]}", "noshell"),
                                                ifvarclass => "usermanagement_force_user_group_defined_${usergroup_user_index}.usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_group_is_gid_${usergroup_user_index}";

      "user_current_gid[${usergroup_user_index}]"   string => execresult("/usr/bin/id -g -n ${usergroup_user_login[${usergroup_user_index}]}", "noshell"),
                                                ifvarclass => "usermanagement_force_user_group_defined_${usergroup_user_index}.usermanagement_user_exists_${usergroup_user_index}.!usermanagement_user_group_is_gid_${usergroup_user_index}";


  classes:

    # Actions

      "usermanagement_user_update_${usergroup_user_index}" expression => strcmp("${usergroup_user_action[${usergroup_user_index}]}","add");

      "usermanagement_user_remove_${usergroup_user_index}" expression => strcmp("${usergroup_user_action[${usergroup_user_index}]}","remove");

      "usermanagement_user_checkpres_${usergroup_user_index}" expression => strcmp("${usergroup_user_action[${usergroup_user_index}]}","checkhere");

      "usermanagement_user_checkabs_${usergroup_user_index}" expression => strcmp("${usergroup_user_action[${usergroup_user_index}]}","checknothere");

      "usermanagement_user_pershome_${usergroup_user_index}" not => strcmp("${usergroup_user_home_perso[${usergroup_user_index}]}","true");

      "usermanagement_user_custom_home_no_variable_${usergroup_user_index}"     not => isvariable("usergroup_user_home[${usergroup_user_index}]");
      "usermanagement_user_custom_home_no_value_${usergroup_user_index}" expression => strcmp("", "usergroup_user_home[${usergroup_user_index}]");
      "usermanagement_user_custom_home_defined_${usergroup_user_index}" expression  => "!usermanagement_user_custom_home_no_variable_${usergroup_user_index}.!usermanagement_user_custom_home_no_value_${usergroup_user_index}";

      # If we ask to personnalize home, but not define it, it is invalid
      "usermanagement_user_home_pershome_invalid_${usergroup_user_index}" expression => "usermanagement_user_pershome_${usergroup_user_index}.!usermanagement_user_custom_home_defined_${usergroup_user_index}";

      # Asked to move the home directory
      "usermanagement_user_custom_home_move_${usergroup_user_index}" expression => strcmp("${usergroup_user_home_move[${usergroup_user_index}]}","true");

      # The request to move home is valid: the path to move to is defined, and we asked to personalize
      "usermanagement_user_custom_home_move_valid_${usergroup_user_index}" expression => "usermanagement_user_custom_home_move_${usergroup_user_index}.usermanagement_user_custom_home_defined_${usergroup_user_index}.usermanagement_user_pershome_${usergroup_user_index}";

      "usermanagement_user_exists_${usergroup_user_index}" expression => userexists("${usergroup_user_login[${usergroup_user_index}]}");

      "usermanagement_group_exists_${usergroup_user_index}" expression => groupexists("${usergroup_user_groupname[${usergroup_user_index}]}");

      "usermanagement_user_pwoneshot_${usergroup_user_index}" expression => strcmp("${usergroup_user_password_policy[${usergroup_user_index}]}","oneshot");

      "usermanagement_user_pweverytime_${usergroup_user_index}" expression => strcmp("${usergroup_user_password_policy[${usergroup_user_index}]}","everytime");

      # with variables that are not unique, the emptyness detection is quite tricky
      # either the variable is not defined, or the variable value is ""
      "usermanagement_user_pw_no_variable_${usergroup_user_index}"     not => isvariable("usergroup_user_password[${usergroup_user_index}]");
      "usermanagement_user_pw_no_value_${usergroup_user_index}" expression => strcmp("", "${usergroup_user_password[${usergroup_user_index}]}");
      "usermanagement_user_pwempty_${usergroup_user_index}"     expression => "usermanagement_user_pw_no_variable_${usergroup_user_index}|usermanagement_user_pw_no_value_${usergroup_user_index}";

      "usermanagement_user_name_no_variable_${usergroup_user_index}"     not => isvariable("usergroup_user_fullname[${usergroup_user_index}]");
      "usermanagement_user_name_no_value_${usergroup_user_index}" expression => strcmp("", "${usergroup_user_fullname[${usergroup_user_index}]}");
      "usermanagement_user_nameempty_${usergroup_user_index}"     expression => "usermanagement_user_name_no_variable_${usergroup_user_index}|usermanagement_user_name_no_value_${usergroup_user_index}";

      "usermanagement_user_group_no_variable_${usergroup_user_index}"     not => isvariable("usergroup_user_groupname[${usergroup_user_index}]");
      "usermanagement_user_group_no_value_${usergroup_user_index}" expression =>  strcmp("", "${usergroup_user_groupname[${usergroup_user_index}]}");
      "usermanagement_user_groupempty_${usergroup_user_index}"     expression => "usermanagement_user_group_no_variable_${usergroup_user_index}|usermanagement_user_group_no_value_${usergroup_user_index}";


      # check if user set a gid or a group name
      "usermanagement_user_group_is_gid_${usergroup_user_index}"   expression => regcmp("[0-9]+", "usergroup_user_fullname[${usergroup_user_index}]"),
                                                                   ifvarclass => "!usermanagement_user_groupempty_${usergroup_user_index}";

      "usermanagement_force_user_group_${usergroup_user_index}"    expression =>  strcmp("true", "${usergroup_force_user_groupname[${usergroup_user_index}]}");
      "usermanagement_force_user_group_defined_${usergroup_user_index}" expression => "usermanagement_force_user_group_${usergroup_user_index}.!usermanagement_user_groupempty_${usergroup_user_index}";


      "usermanagement_user_uid_no_variable_${usergroup_user_index}"     not => isvariable("usergroup_user_uid[${usergroup_user_index}]");
      "usermanagement_user_uid_no_value_${usergroup_user_index}" expression => strcmp("", "${usergroup_user_uid[${usergroup_user_index}]}");
      "usermanagement_user_uid_empty_${usergroup_user_index}"     expression => "usermanagement_user_uid_no_variable_${usergroup_user_index}|usermanagement_user_uid_no_value_${usergroup_user_index}";

      "usermanagement_user_groupmatchesname_${usergroup_user_index}" expression => strcmp("${usergroup_user_login[${usergroup_user_index}]}", "${usergroup_user_groupname[${usergroup_user_index}]}");

      # Group doesn't exist and group name is defined
      "usermanagement_user_group_definition_error_${usergroup_user_index}" expression => "(!usermanagement_group_exists_${usergroup_user_index}.usermanagement_user_groupmatchesname_${usergroup_user_index})|(!usermanagement_user_groupempty_${usergroup_user_index}.!usermanagement_group_exists_${usergroup_user_index})";

      # check if user exists when enforcing ids
      "usermanagement_uid_exists_${usergroup_user_index}" expression => userexists("${usergroup_user_uid[${usergroup_user_index}]}"),
                                                          ifvarclass => "!usermanagement_user_uid_empty_${usergroup_user_index}";
      
      # UID is defined and already exists
      "usermanagement_user_uid_definition_error_${usergroup_user_index}" expression => "!usermanagement_user_uid_empty_${usergroup_user_index}.usermanagement_uid_exists_${usergroup_user_index}";

      # if we want to create a user, and a group with the username exists (no group name defined),then we need to force addition of user to that group (mandatory for debian and redhat, non mandatory for SLES)
      "usermanagement_user_force_user_in_group_${usergroup_user_index}" expression => groupexists("${usergroup_user_login[${usergroup_user_index}]}"),
        ifvarclass => "usermanagement_user_groupempty_${usergroup_user_index}.!usermanagement_user_nameempty_${usergroup_user_index}";

    # Class 'any' is executed before others classes defined.
    # Same as 'any' but execution will be after all classes defined
      "any_2nd_pass" expression => "any";

      "showtime" expression => isvariable("nameopt[1]");

    showtime::
      # if defined, we can move the user home (because we know the previous value)
      "usermanagement_user_current_home_defined_${usergroup_user_index}" expression => isvariable("usermanagement_user_move_home_dir_from[${usergroup_user_index}]");

      # Must move the home if:
      # - home is not the same as the defined home on the node for user
      # - we asked to personnalize, and the values are valid
      "usermanagement_user_current_home_is_invalid_${usergroup_user_index}" not => strcmp("${usermanagement_user_move_home_dir_from[${usergroup_user_index}]}", "${usergroup_user_home[${usergroup_user_index}]}"),
         ifvarclass => "usermanagement_user_current_home_defined_${usergroup_user_index}.usermanagement_user_pershome_${usergroup_user_index}.!usermanagement_user_home_pershome_invalid_${usergroup_user_index}";

     # check if we need to change the user GID
     # We need to change it if:
     # usermanagement_force_user_group_defined and user_current_gid is different from usergroup_user_groupname
     # if usermanagement_force_user_group but not usermanagement_force_user_group_defined, we'll need to report an error (cannot set to no group)
     "usermanagement_user_current_group_is_invalid_${usergroup_user_index}" not => strcmp("${user_current_gid[${usergroup_user_index}]}", "${usergroup_user_groupname[${usergroup_user_index}]}"),
         ifvarclass => "usermanagement_force_user_group_defined_${usergroup_user_index}";


    any::
      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";

  files:
      "/etc/passwd"
        create        => "false",
        edit_line     => set_user_fullname_RudderUniqueID("${usergroup_user_login[${usergroup_user_index}]}","${usergroup_user_index}","${usergroup_user_fullname[${usergroup_user_index}]}"),
        edit_defaults => noempty_backup,
        ifvarclass    => "usermanagement_user_update_${usergroup_user_index}.!usermanagement_user_nameempty_${usergroup_user_index}";

      "/etc/passwd"
        create        => "false",
        edit_line     => set_user_fullname_RudderUniqueID("${usergroup_user_login[${usergroup_user_index}]}","${usergroup_user_index}","${usergroup_user_fullname[${usergroup_user_index}]}"),
        edit_defaults => noempty_backup,
        action        => WarnOnly,
        ifvarclass    => "usermanagement_user_checkpres_${usergroup_user_index}.!usermanagement_user_nameempty_${usergroup_user_index}";

      "/etc/passwd"
        create        => "false",
        edit_line     => set_user_shell_RudderUniqueID("${usergroup_user_login[${usergroup_user_index}]}","${usergroup_user_index}","${usergroup_user_shell[${usergroup_user_index}]}"),
        edit_defaults => noempty_backup,
        ifvarclass    => "usermanagement_user_update_${usergroup_user_index}";

      "/etc/passwd"
        create        => "false",
        edit_line     => set_user_shell_RudderUniqueID("${usergroup_user_login[${usergroup_user_index}]}","${usergroup_user_index}","${usergroup_user_shell[${usergroup_user_index}]}"),
        edit_defaults => noempty_backup,
        action        => WarnOnly,
        ifvarclass    => "usermanagement_user_checkpres_${usergroup_user_index}";

    aix::
      # On AIX, if password is supplied and user must exist, then the second field needs to be a ! to allow login
      "/etc/passwd"
        create        => "false",
        edit_line     => set_colon_field("${usergroup_user_login[${usergroup_user_index}]}", "2", "!"),
        edit_defaults => noempty_backup,
        classes       => classes_generic("usermanagement_user_password_${usergroup_user_index}_RudderUniqueID"),
        ifvarclass    => "(usermanagement_login_add_${usergroup_user_index}_RudderUniqueID_repaired.usermanagement_user_pwoneshot_${usergroup_user_index}.!usermanagement_user_pwempty_${usergroup_user_index})|(usermanagement_user_update_${usergroup_user_index}.usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_pweverytime_${usergroup_user_index}.!usermanagement_user_pwempty_${usergroup_user_index})";

    !aix::
      # Define password when user has already been created
      "/etc/shadow"
        create        => "false",
        edit_line     => set_user_field("${usergroup_user_login[${usergroup_user_index}]}", 2, "${usergroup_user_password[${usergroup_user_index}]}"),
        edit_defaults => noempty_backup,
        classes       => classes_generic("usermanagement_user_password_${usergroup_user_index}_RudderUniqueID"),
        ifvarclass    => "(usermanagement_login_add_${usergroup_user_index}_RudderUniqueID_repaired.usermanagement_user_pwoneshot_${usergroup_user_index}.!usermanagement_user_pwempty_${usergroup_user_index})|(usermanagement_user_update_${usergroup_user_index}.usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_pweverytime_${usergroup_user_index}.!usermanagement_user_pwempty_${usergroup_user_index})";

      # Check password if we are in "check only (account should exist)
      # Due to https://tracker.mender.io/browse/CFE-2424, if password is correct, no class is defined. Waiting for fix in the agent
      "/etc/shadow"
        create        => "false",
        edit_line     => set_user_field("${usergroup_user_login[${usergroup_user_index}]}", 2, "${usergroup_user_password[${usergroup_user_index}]}"),
        edit_defaults => noempty_backup,
        action        => WarnOnly,
        classes       => classes_generic("usermanagement_user_password_${usergroup_user_index}_RudderUniqueID"),
        ifvarclass    => "!usermanagement_user_pwempty_${usergroup_user_index}.usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_pweverytime_${usergroup_user_index}.usermanagement_user_checkpres_${usergroup_user_index}";

    aix::
      "/etc/security/passwd"
        create        => "false",
        edit_line     => ncf_ensure_AIX_password("${usergroup_user_login[${usergroup_user_index}]}", "${usergroup_user_password_aix[${usergroup_user_index}]}"),
        edit_defaults => noempty_backup,
        classes       => classes_generic("usermanagement_user_password_${usergroup_user_index}_RudderUniqueID"),
        ifvarclass    => "(usermanagement_login_add_${usergroup_user_index}_RudderUniqueID_repaired.usermanagement_user_pwoneshot_${usergroup_user_index}.!usermanagement_user_pwempty_${usergroup_user_index})|(usermanagement_user_update_${usergroup_user_index}.usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_pweverytime_${usergroup_user_index}.!usermanagement_user_pwempty_${usergroup_user_index})";

      # set the last update date if password has been updated
      "/etc/security/passwd"
        create        => "false",
        edit_line     => ncf_edit_lastupdate_AIX_password("${usergroup_user_login[${usergroup_user_index}]}"),
        edit_defaults => noempty_backup,
        ifvarclass    => "usermanagement_user_password_${usergroup_user_index}_RudderUniqueID_repaired.((usermanagement_login_add_${usergroup_user_index}_RudderUniqueID_repaired.usermanagement_user_pwoneshot_${usergroup_user_index}.!usermanagement_user_pwempty_${usergroup_user_index})|(usermanagement_user_update_${usergroup_user_index}.usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_pweverytime_${usergroup_user_index}.!usermanagement_user_pwempty_${usergroup_user_index}))";


      "/etc/security/passwd"
        create        => "false",
        edit_line     => ncf_ensure_AIX_password("${usergroup_user_login[${usergroup_user_index}]}", "${usergroup_user_password_aix[${usergroup_user_index}]}"),
        edit_defaults => noempty_backup,
        action        => WarnOnly,
        classes       => classes_generic("usermanagement_user_password_${usergroup_user_index}_RudderUniqueID"),
        ifvarclass    => "!usermanagement_user_pwempty_${usergroup_user_index}.usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_pweverytime_${usergroup_user_index}.usermanagement_user_checkpres_${usergroup_user_index}";


  methods:
    pass3.showtime::

      # Add user
      ## Does exist (Success), and gid not requested to be changed
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_success", "${usergroup_directive_id[${usergroup_user_index}]}", "Users", "${usergroup_user_login[${usergroup_user_index}]}", "The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) is already present on the system", "${usergroup_user_index}"),
        ifvarclass => "usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_update_${usergroup_user_index}.!usermanagement_login_add_${usergroup_user_index}_RudderUniqueID_repaired.(usermanagement_user_nameempty_${usergroup_user_index}|usermanagement_fullname_edit_${usergroup_user_index}_RudderUniqueID_kept).usermanagement_shell_edit_${usergroup_user_index}_RudderUniqueID_kept.!usermanagement_force_user_group_${usergroup_user_index}";

      ## Does exist (Success), and gid already correct
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_success", "${usergroup_directive_id[${usergroup_user_index}]}", "Users", "${usergroup_user_login[${usergroup_user_index}]}", "The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) is already present on the system", "${usergroup_user_index}"),
        ifvarclass => "usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_update_${usergroup_user_index}.!usermanagement_login_add_${usergroup_user_index}_RudderUniqueID_RudderUniqueID_repaired.(usermanagement_user_nameempty_${usergroup_user_index}|usermanagement_fullname_edit_${usergroup_user_index}_RudderUniqueID_kept).usermanagement_shell_edit_${usergroup_user_index}_RudderUniqueID_kept.(usermanagement_force_user_group_defined_${usergroup_user_index}.!usermanagement_user_current_group_is_invalid_${usergroup_user_index})";

      ## Does exist (Success), with a wrong gid
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_repaired", "${usergroup_directive_id[${usergroup_user_index}]}", "Users", "${usergroup_user_login[${usergroup_user_index}]}", "The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) is already present on the system, but had the wrong gid", "${usergroup_user_index}"),
        ifvarclass => "usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_update_${usergroup_user_index}.!usermanagement_login_add_${usergroup_user_index}_RudderUniqueID_repaired.(usermanagement_user_nameempty_${usergroup_user_index}|usermanagement_fullname_edit_${usergroup_user_index}_RudderUniqueID_kept).usermanagement_shell_edit_${usergroup_user_index}_RudderUniqueID_kept.(usermanagement_force_user_group_defined_${usergroup_user_index}.usermanagement_user_gid_change_${usergroup_user_index}_RudderUniqueID_repaired)";


      ## Seems to exist with a wrong Full Name (Repaired)
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_repaired", "${usergroup_directive_id[${usergroup_user_index}]}", "Users", "${usergroup_user_login[${usergroup_user_index}]}", "The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) had a wrong fullname", "${usergroup_user_index}"),
        ifvarclass => "usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_update_${usergroup_user_index}.!usermanagement_user_nameempty_${usergroup_user_index}.(usermanagement_fullname_edit_${usergroup_user_index}_RudderUniqueID_repaired|usermanagement_fullname_edit_${usergroup_user_index}_RudderUniqueID_error).usermanagement_shell_edit_${usergroup_user_index}_RudderUniqueID_kept";

      ## Seems to exist with a wrong Shell (Repaired)
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_repaired", "${usergroup_directive_id[${usergroup_user_index}]}", "Users", "${usergroup_user_login[${usergroup_user_index}]}", "The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) had a wrong shell", "${usergroup_user_index}"),
        ifvarclass => "usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_update_${usergroup_user_index}.(usermanagement_shell_edit_${usergroup_user_index}_RudderUniqueID_repaired|usermanagement_shell_edit_${usergroup_user_index}_RudderUniqueID_error).!(usermanagement_fullname_edit_${usergroup_user_index}_RudderUniqueID_repaired|usermanagement_fullname_edit_${usergroup_user_index}_RudderUniqueID_error)";

      ## Seems to exist with a wrong Full Name and Shell (Repaired)
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_repaired", "${usergroup_directive_id[${usergroup_user_index}]}", "Users", "${usergroup_user_login[${usergroup_user_index}]}", "The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) had a wrong fullname and shell", "${usergroup_user_index}"),
        ifvarclass => "usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_update_${usergroup_user_index}.!usermanagement_user_nameempty_${usergroup_user_index}.(usermanagement_fullname_edit_${usergroup_user_index}_RudderUniqueID_repaired|usermanagement_fullname_edit_${usergroup_user_index}_RudderUniqueID_error).usermanagement_shell_edit_${usergroup_user_index}_RudderUniqueID_repaired";



      ## Added (Repaired)
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_repaired", "${usergroup_directive_id[${usergroup_user_index}]}", "Users", "${usergroup_user_login[${usergroup_user_index}]}", "The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) has been added to the system", "${usergroup_user_index}"),
        ifvarclass => "usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_update_${usergroup_user_index}.usermanagement_login_add_${usergroup_user_index}_RudderUniqueID_repaired";

      ## Error
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_error", "${usergroup_directive_id[${usergroup_user_index}]}", "Users", "${usergroup_user_login[${usergroup_user_index}]}", "The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) could not be added to the system", "${usergroup_user_index}"),
        ifvarclass => "!usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_update_${usergroup_user_index}.usermanagement_login_add_${usergroup_user_index}_RudderUniqueID_error";

      ## Could not be added, for the default path was not selected, but the custom one was not defined
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_error", "${usergroup_directive_id[${usergroup_user_index}]}", "Users", "${usergroup_user_login[${usergroup_user_index}]}", "The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) could not be added to the system because the default home directory was not selected, but the custom path was not specified", "${usergroup_user_index}"),
        ifvarclass => "!usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_update_${usergroup_user_index}.usermanagement_user_pershome_${usergroup_user_index}.!usermanagement_user_custom_home_defined_${usergroup_user_index}";

      ## Could not be added, as a custom group was asked for and did not exist on the system
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_error", "${usergroup_directive_id[${usergroup_user_index}]}", "Users", "${usergroup_user_login[${usergroup_user_index}]}", "The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) could not be added to the system because the custom group \"${usergroup_user_groupname[${usergroup_user_index}]}\" does not exist", "${usergroup_user_index}"),
        ifvarclass => "usermanagement_user_update_${usergroup_user_index}.!usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_group_definition_error_${usergroup_user_index}";

      ## Could not be added, as a custom uid was asked for and did exist on the system
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_error", "${usergroup_directive_id[${usergroup_user_index}]}", "Users", "${usergroup_user_login[${usergroup_user_index}]}", "The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) could not be added to the system because the custom uid \"${usergroup_user_uid[${usergroup_user_index}]}\" already exists", "${usergroup_user_index}"),
        ifvarclass => "usermanagement_user_update_${usergroup_user_index}.!usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_uid_definition_error_${usergroup_user_index}";

      ## Could not set the gid, as it was requested, but with no gid provided
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_error", "${usergroup_directive_id[${usergroup_user_index}]}", "Users", "${usergroup_user_login[${usergroup_user_index}]}", "The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) could not have its gid updated because it was not provided", "${usergroup_user_index}"),
        ifvarclass => "usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_update_${usergroup_user_index}.usermanagement_force_user_group_${usergroup_user_index}.usermanagement_user_groupempty_${usergroup_user_index}";

      ## Does exist with a wrong gid that could not be repaired
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_error", "${usergroup_directive_id[${usergroup_user_index}]}", "Users", "${usergroup_user_login[${usergroup_user_index}]}", "The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) is already present on the system, but with wrong gid that cannot be fixed", "${usergroup_user_index}"),
        ifvarclass => "usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_update_${usergroup_user_index}.!usermanagement_login_add_${usergroup_user_index}_RudderUniqueID_repaired.(usermanagement_user_nameempty_${usergroup_user_index}|usermanagement_fullname_edit_${usergroup_user_index}_RudderUniqueID_kept).(usermanagement_force_user_group_defined_${usergroup_user_index}.usermanagement_user_gid_change_${usergroup_user_index}_RudderUniqueID_error)";


      # Remove user
      ## Does not exist (Success)
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_success", "${usergroup_directive_id[${usergroup_user_index}]}", "Users", "${usergroup_user_login[${usergroup_user_index}]}", "The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) does not exist, as required", "${usergroup_user_index}"),
        ifvarclass => "!usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_remove_${usergroup_user_index}";

      ## Removed (Repaired)
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_repaired", "${usergroup_directive_id[${usergroup_user_index}]}", "Users", "${usergroup_user_login[${usergroup_user_index}]}", "The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) has been removed from the system", "${usergroup_user_index}"),
        ifvarclass => "usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_remove_${usergroup_user_index}.usermanagement_login_remove_${usergroup_user_index}_RudderUniqueID_repaired";

      ## Error
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_error", "${usergroup_directive_id[${usergroup_user_index}]}", "Users", "${usergroup_user_login[${usergroup_user_index}]}", "The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) could not be removed from the system", "${usergroup_user_index}"),
        ifvarclass => "usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_remove_${usergroup_user_index}.usermanagement_login_remove_${usergroup_user_index}_RudderUniqueID_error";

      # Check user not exists
      ## Does not exist (Success)
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_success", "${usergroup_directive_id[${usergroup_user_index}]}", "Users", "${usergroup_user_login[${usergroup_user_index}]}", "The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) is not present on the system, which is in accordance with the non presence policy", "${usergroup_user_index}"),
        ifvarclass => "!usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_checkabs_${usergroup_user_index}";

      ## Does exist (Error)
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_error", "${usergroup_directive_id[${usergroup_user_index}]}", "Users", "${usergroup_user_login[${usergroup_user_index}]}", "The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) is present on the system, which violates the non presence policy", "${usergroup_user_index}"),
        ifvarclass => "usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_checkabs_${usergroup_user_index}";

      # Check user exists
      ## Does exist (Success)
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_success", "${usergroup_directive_id[${usergroup_user_index}]}", "Users", "${usergroup_user_login[${usergroup_user_index}]}", "The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) is present on the system, which is in conformance with the presence policy", "${usergroup_user_index}"),
        ifvarclass => "usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_checkpres_${usergroup_user_index}.(usermanagement_user_nameempty_${usergroup_user_index}|usermanagement_fullname_edit_${usergroup_user_index}_RudderUniqueID_kept).usermanagement_shell_edit_${usergroup_user_index}_RudderUniqueID_kept";

      ## Seems to exist with a wrong Full Name (Error)
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_error", "${usergroup_directive_id[${usergroup_user_index}]}", "Users", "${usergroup_user_login[${usergroup_user_index}]}", "The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) is present on the system, but does not have the right fullname", "${usergroup_user_index}"),
        ifvarclass => "usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_checkpres_${usergroup_user_index}.!usermanagement_user_nameempty_${usergroup_user_index}.(usermanagement_fullname_edit_${usergroup_user_index}_RudderUniqueID_repaired|usermanagement_fullname_edit_${usergroup_user_index}_RudderUniqueID_error).usermanagement_shell_edit_${usergroup_user_index}_RudderUniqueID_kept";

     ## Seems to exist with a wrong Shell (Error)
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_error", "${usergroup_directive_id[${usergroup_user_index}]}", "Users", "${usergroup_user_login[${usergroup_user_index}]}", "The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) is present on the system, but does not have the right shell", "${usergroup_user_index}"),
        ifvarclass => "usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_checkpres_${usergroup_user_index}.!usermanagement_user_nameempty_${usergroup_user_index}.(usermanagement_shell_edit_${usergroup_user_index}_RudderUniqueID_repaired|usermanagement_shell_edit_${usergroup_user_index}_RudderUniqueID_error).usermanagement_fullname_edit_${usergroup_user_index}_RudderUniqueID_kept";

      ## Seems to exist with a wrong Shell and wrong Full Name (Error)
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_error", "${usergroup_directive_id[${usergroup_user_index}]}", "Users", "${usergroup_user_login[${usergroup_user_index}]}", "The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) is present on the system, but does not have the right fullname not shell", "${usergroup_user_index}"),
        ifvarclass => "usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_checkpres_${usergroup_user_index}.!usermanagement_user_nameempty_${usergroup_user_index}.(usermanagement_fullname_edit_${usergroup_user_index}_RudderUniqueID_repaired|usermanagement_fullname_edit_${usergroup_user_index}_RudderUniqueID_error).(usermanagement_shell_edit_${usergroup_user_index}_RudderUniqueID_repaired|usermanagement_shell_edit_${usergroup_user_index}_RudderUniqueID_error)";
 

      ## Does not exist (Error)
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_error", "${usergroup_directive_id[${usergroup_user_index}]}", "Users", "${usergroup_user_login[${usergroup_user_index}]}", "The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) is not present on the system, which violates the presence policy", "${usergroup_user_index}"),
        ifvarclass => "!usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_checkpres_${usergroup_user_index}";

      ### Password handling
      "any" usebundle => rudder_common_reports_generic_index("userGroupManagement", "usermanagement_user_password_${usergroup_user_index}_RudderUniqueID", "${usergroup_directive_id[${usergroup_user_index}]}", "Password", "${usergroup_user_login[${usergroup_user_index}]}", "The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) password", "${usergroup_user_index}"),
           ifvarclass => "!usermanagement_user_checkpres_${usergroup_user_index}";

      ## Password handling in check only
      "any" usebundle => rudder_common_reports_generic_index("userGroupManagement", "usermanagement_user_password_${usergroup_user_index}_RudderUniqueID", "${usergroup_directive_id[${usergroup_user_index}]}", "Password", "${usergroup_user_login[${usergroup_user_index}]}", "The check of password for user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) ", "${usergroup_user_index}"),
           ifvarclass => "usermanagement_user_checkpres_${usergroup_user_index}";

      ## Change not needed (Success)
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_success", "${usergroup_directive_id[${usergroup_user_index}]}", "Password", "${usergroup_user_login[${usergroup_user_index}]}", "The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) password change is not required", "${usergroup_user_index}"),
        ifvarclass => "((!usermanagement_user_password_${usergroup_user_index}_RudderUniqueID_kept.!usermanagement_user_password_${usergroup_user_index}_RudderUniqueID_repaired.!usermanagement_user_password_${usergroup_user_index}_RudderUniqueID_error).((usermanagement_user_pwoneshot_${usergroup_user_index}.usermanagement_user_exists_${usergroup_user_index})|usermanagement_user_pwempty_${usergroup_user_index}|(usermanagement_user_update_${usergroup_user_index}.!usermanagement_user_exists_${usergroup_user_index}.(usermanagement_user_group_definition_error_${usergroup_user_index}|usermanagement_user_uid_definition_error_${usergroup_user_index}))))|usermanagement_user_remove_${usergroup_user_index}";

      ## Change not needed (N/A)
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_na", "${usergroup_directive_id[${usergroup_user_index}]}", "Password", "${usergroup_user_login[${usergroup_user_index}]}", "The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) password change is not required", "${usergroup_user_index}"),
        ifvarclass => "(!usermanagement_user_password_${usergroup_user_index}_RudderUniqueID_kept.!usermanagement_user_password_${usergroup_user_index}_RudderUniqueID_repaired.!usermanagement_user_password_${usergroup_user_index}_RudderUniqueID_error).((usermanagement_user_checkpres_${usergroup_user_index}.usermanagement_user_pwoneshot_${usergroup_user_index})|(usermanagement_user_checkpres_${usergroup_user_index}.!usermanagement_user_exists_${usergroup_user_index}))|usermanagement_user_checkabs_${usergroup_user_index}";

      ## Error when no password class defined and not in a previous N/A or Success case
      #  This huge statement is built from three previous password reports:
      #  (no class _reached defined).!(change not needed Success).!(change not needed N/A)
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_error", "${usergroup_directive_id[${usergroup_user_index}]}", "Password", "${usergroup_user_login[${usergroup_user_index}]}", "The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) password could not be verified", "${usergroup_user_index}"),
           ifvarclass => "!(usermanagement_user_password_${usergroup_user_index}_RudderUniqueID_reached).!((!usermanagement_user_password_${usergroup_user_index}_RudderUniqueID_kept.!usermanagement_user_password_${usergroup_user_index}_RudderUniqueID_repaired.!usermanagement_user_password_${usergroup_user_index}_RudderUniqueID_error).((usermanagement_user_checkpres_${usergroup_user_index}.usermanagement_user_pwoneshot_${usergroup_user_index})|(usermanagement_user_checkpres_${usergroup_user_index}.!usermanagement_user_exists_${usergroup_user_index}))|usermanagement_user_checkabs_${usergroup_user_index}).!(((!usermanagement_user_password_${usergroup_user_index}_RudderUniqueID_kept.!usermanagement_user_password_${usergroup_user_index}_RudderUniqueID_repaired.!usermanagement_user_password_${usergroup_user_index}_RudderUniqueID_error).((usermanagement_user_pwoneshot_${usergroup_user_index}.usermanagement_user_exists_${usergroup_user_index})|usermanagement_user_pwempty_${usergroup_user_index}|(usermanagement_user_update_${usergroup_user_index}.!usermanagement_user_exists_${usergroup_user_index}.(usermanagement_user_group_definition_error_${usergroup_user_index}|usermanagement_user_uid_definition_error_${usergroup_user_index}))))|usermanagement_user_remove_${usergroup_user_index})";


      # Homedir management
      ## In case of user to remove or to check absent, this is a result_na
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_na", "${usergroup_directive_id[${usergroup_user_index}]}", "Home directory", "${usergroup_user_login[${usergroup_user_index}]}", "The user ${usergroup_user_login[${usergroup_user_index}]} should not be present, it doesn't need to have its home directory checked", "${usergroup_user_index}"),
        ifvarclass => "usermanagement_user_remove_${usergroup_user_index}|usermanagement_user_checkabs_${usergroup_user_index}";

      ## In case of check user present or update, but with default home, this is result_na
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_na", "${usergroup_directive_id[${usergroup_user_index}]}", "Home directory", "${usergroup_user_login[${usergroup_user_index}]}", "The user ${usergroup_user_login[${usergroup_user_index}]} doesn't need to have its home directory checked", "${usergroup_user_index}"),
        ifvarclass => "!usermanagement_user_pershome_${usergroup_user_index}.(usermanagement_user_update_${usergroup_user_index}|usermanagement_user_checkpres_${usergroup_user_index})";

      ## In case of check user present or update, but the home is already correct, this is success
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_success", "${usergroup_directive_id[${usergroup_user_index}]}", "Home directory", "${usergroup_user_login[${usergroup_user_index}]}", "The user ${usergroup_user_login[${usergroup_user_index}]} home directory is valid", "${usergroup_user_index}"),
        ifvarclass => "usermanagement_user_pershome_${usergroup_user_index}.!usermanagement_user_current_home_is_invalid_${usergroup_user_index}.(usermanagement_user_update_${usergroup_user_index}|usermanagement_user_checkpres_${usergroup_user_index})";

      ## In case of update, but the home was not correct, and could be changed, this is repaired
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_repaired", "${usergroup_directive_id[${usergroup_user_index}]}", "Home directory", "${usergroup_user_login[${usergroup_user_index}]}", "The user ${usergroup_user_login[${usergroup_user_index}]} home directory was changed (but not moved)", "${usergroup_user_index}"),
        ifvarclass => "usermanagement_user_pershome_${usergroup_user_index}.(usermanagement_login_home_change_${usergroup_user_index}_RudderUniqueID_repaired.!usermanagement_login_home_change_${usergroup_user_index}_RudderUniqueID_error).usermanagement_user_current_home_is_invalid_${usergroup_user_index}.usermanagement_user_update_${usergroup_user_index}";

      ## In case of update, but the home was not correct, and could not be changed, this is error
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_error", "${usergroup_directive_id[${usergroup_user_index}]}", "Home directory", "${usergroup_user_login[${usergroup_user_index}]}", "The user ${usergroup_user_login[${usergroup_user_index}]} home directory could not be changed", "${usergroup_user_index}"),
        ifvarclass => "usermanagement_user_pershome_${usergroup_user_index}.usermanagement_login_home_change_${usergroup_user_index}_RudderUniqueID_error.usermanagement_user_current_home_is_invalid_${usergroup_user_index}.usermanagement_user_update_${usergroup_user_index}";

      ## In case of update, but the home was not correct, and could be moved, this is repaired
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_repaired", "${usergroup_directive_id[${usergroup_user_index}]}", "Home directory", "${usergroup_user_login[${usergroup_user_index}]}", "The user ${usergroup_user_login[${usergroup_user_index}]} home directory was moved", "${usergroup_user_index}"),
        ifvarclass => "usermanagement_user_pershome_${usergroup_user_index}.(usermanagement_login_home_move_${usergroup_user_index}_RudderUniqueID_repaired.!usermanagement_login_home_move_${usergroup_user_index}_RudderUniqueID_error).usermanagement_user_current_home_is_invalid_${usergroup_user_index}.usermanagement_user_update_${usergroup_user_index}";

      ## In case of update, but the home was not correct, and could not be moved, this is error
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_error", "${usergroup_directive_id[${usergroup_user_index}]}", "Home directory", "${usergroup_user_login[${usergroup_user_index}]}", "The user ${usergroup_user_login[${usergroup_user_index}]} home directory could not be moved", "${usergroup_user_index}"),
        ifvarclass => "usermanagement_user_pershome_${usergroup_user_index}.usermanagement_login_home_move_${usergroup_user_index}_RudderUniqueID_error.usermanagement_user_current_home_is_invalid_${usergroup_user_index}.usermanagement_user_update_${usergroup_user_index}";

      ## In case of check only, and the home was not correct, this is error
      "any" usebundle => rudder_common_report_index("userGroupManagement", "result_error", "${usergroup_directive_id[${usergroup_user_index}]}", "Home directory", "${usergroup_user_login[${usergroup_user_index}]}", "The user ${usergroup_user_login[${usergroup_user_index}]} home directory was invalid", "${usergroup_user_index}"),
        ifvarclass => "usermanagement_user_pershome_${usergroup_user_index}.usermanagement_user_current_home_is_invalid_${usergroup_user_index}.usermanagement_user_checkpres_${usergroup_user_index}";

  commands:
    showtime::

      "/usr/sbin/useradd"
        args => "${useropt[${usergroup_user_index}]} ${groupopt[${usergroup_user_index}]} -m ${nameopt[${usergroup_user_index}]} -s ${usergroup_user_shell[${usergroup_user_index}]} ${usergroup_user_login[${usergroup_user_index}]}",
        classes => cf2_if_else("usermanagement_login_add_${usergroup_user_index}_RudderUniqueID_repaired", "usermanagement_login_add_${usergroup_user_index}_RudderUniqueID_error"),
        comment => "Create the user",
        ifvarclass => "!usermanagement_user_uid_definition_error_${usergroup_user_index}.!usermanagement_user_group_definition_error_${usergroup_user_index}.!usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_update_${usergroup_user_index}.!usermanagement_user_pershome_${usergroup_user_index}";

      "/usr/sbin/useradd"
        args => "${useropt[${usergroup_user_index}]} ${groupopt[${usergroup_user_index}]} -m ${nameopt[${usergroup_user_index}]} -s ${usergroup_user_shell[${usergroup_user_index}]} -d ${usergroup_user_home[${usergroup_user_index}]} ${usergroup_user_login[${usergroup_user_index}]}",
        classes => cf2_if_else("usermanagement_login_add_${usergroup_user_index}_RudderUniqueID_repaired", "usermanagement_login_add_${usergroup_user_index}_RudderUniqueID_error"),
        comment => "Create the user with a custom home directory",
        ifvarclass => "!usermanagement_user_uid_definition_error_${usergroup_user_index}.!usermanagement_user_group_definition_error_${usergroup_user_index}.!usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_update_${usergroup_user_index}.usermanagement_user_pershome_${usergroup_user_index}.usermanagement_user_custom_home_defined_${usergroup_user_index}";

      "/usr/sbin/userdel"
        args => "${usergroup_user_login[${usergroup_user_index}]}",
        classes => cf2_if_else("usermanagement_login_remove_${usergroup_user_index}_RudderUniqueID_repaired", "usermanagement_login_remove_${usergroup_user_index}_RudderUniqueID_error"),
        comment => "Delete the user ${usergroup_user_login[${usergroup_user_index}]}",
        ifvarclass => "usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_remove_${usergroup_user_index}";

      # Change user home dir
      ## Move the home dir
      "/usr/sbin/usermod"
        args       => "-d ${usergroup_user_home[${usergroup_user_index}]} -m ${usergroup_user_login[${usergroup_user_index}]}",
        classes    => cf2_if_else("usermanagement_login_home_move_${usergroup_user_index}_RudderUniqueID_repaired", "usermanagement_home_move_${usergroup_user_index}_RudderUniqueID_error"),
        comment    => "Change home directory (move it)",
        ifvarclass => "usermanagement_user_update_${usergroup_user_index}.usermanagement_user_current_home_is_invalid_${usergroup_user_index}.usermanagement_user_custom_home_move_valid_${usergroup_user_index}";

      ## Doesn't move the home dir
      "/usr/sbin/usermod"
        args       => "-d ${usergroup_user_home[${usergroup_user_index}]} ${usergroup_user_login[${usergroup_user_index}]}",
        classes    => cf2_if_else("usermanagement_login_home_change_${usergroup_user_index}_RudderUniqueID_repaired", "usermanagement_login_home_change_${usergroup_user_index}_RudderUniqueID_error"),
        comment    => "Change home directory definition for user (doesn't move files)",
        ifvarclass => "usermanagement_user_update_${usergroup_user_index}.usermanagement_user_current_home_is_invalid_${usergroup_user_index}.!usermanagement_user_custom_home_move_${usergroup_user_index}";

      ## Change the user gid if necessary
      "/usr/sbin/usermod"
        args       => "-g ${usergroup_user_groupname[${usergroup_user_index}]} ${usergroup_user_login[${usergroup_user_index}]}",
        classes    => classes_generic("usermanagement_user_gid_change_${usergroup_user_index}_RudderUniqueID"),
        comment    => "Change user gid for user ${usergroup_user_login[${usergroup_user_index}]}",
        ifvarclass => "usermanagement_user_update_${usergroup_user_index}.usermanagement_user_current_group_is_invalid_${usergroup_user_index}";

}

bundle edit_line set_user_fullname_RudderUniqueID(user,user_index,fullname)
{
  field_edits:
      "${user}:.*"
      # Edit GECOS on /etc/passwd
        edit_field => col(":", "5", "${fullname}", "set"),
        classes    => classes_generic("usermanagement_fullname_edit_${user_index}_RudderUniqueID");

}

bundle edit_line set_user_shell_RudderUniqueID(user,user_index,shell)
{
  field_edits:
      "${user}:.*"
      # Edit shell on /etc/passwd
        edit_field => col(":", "7", "${shell}", "set"),
        classes    => classes_generic("usermanagement_shell_edit_${user_index}_RudderUniqueID");
}

