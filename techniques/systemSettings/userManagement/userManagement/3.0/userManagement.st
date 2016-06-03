#####################################################################################
# Copyright 2011 Normation SAS
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
# User/Group management PT                                               #
#                                                                        #
# Objective : Apply user/group policies on the target host               #
##########################################################################

bundle agent check_usergroup_user_parameters
{

  vars:

    &USERGROUP_USER_LOGIN:{login |"usergroup_user_login[&i&]" string => "&login&";
}&

    &USERGROUP_USER_NAME:{name |"usergroup_user_fullname[&i&]" string => "&name&";
}&

    &USERGROUP_USER_PASSWORD:{password |"usergroup_user_password[&i&]" string => "&password&";
}&

    &USERGROUP_USER_PASSWORD_POLICY:{passwordpol |"usergroup_user_password_policy[&i&]" string => "&passwordpol&";
}&

    &USERGROUP_USER_ACTION:{action |"usergroup_user_action[&i&]" string => "&action&";
}&

    &USERGROUP_USER_SET_UID:{setuid |"usergroup_user_setuid[&i&]" string => "&setuid&";
}&

    &USERGROUP_USER_UID:{uid |"usergroup_user_uid[&i&]" string => "&uid&";
}&

    &USERGROUP_USER_SET_GID:{setgid |"usergroup_user_setgid[&i&]" string => "&setgid&";
}&

    &USERGROUP_USER_GID:{gid |"usergroup_user_gid[&i&]" string => "&gid&";
}&

    &USERGROUP_USER_FORCE_LOCAL:{forcelocal |"usergroup_user_forcelocal[&i&]" string => "&forcelocal&";
}&

    &USERGROUP_USER_HOME_PERSONNALIZE:{homeperso |"usergroup_user_home_perso[&i&]" string => "&homeperso&";
}&

    &USERGROUP_USER_HOME:{home |"usergroup_user_home[&i&]" string => "&home&";
}&

    &USERGROUP_USER_SHELL:{shell |"usergroup_user_shell[&i&]" string => "&shell&";
}&

    &TRACKINGKEY:{directiveId |"usergroup_directive_id[&i&]" string => "&directiveId&";
}&

      "usergroup_user_index" slist => getindices("usergroup_user_login");


    any_2nd_pass::

      # Options to use whether Fullname is defined or not
      "nameopt[${usergroup_user_index}]"
        string => "",
        ifvarclass => "usermanagement_user_nameempty_${usergroup_user_index}";

      ## On UNIX
      "nameopt[${usergroup_user_index}]"
        string => "-c \"${usergroup_user_fullname[${usergroup_user_index}]}\"",
        ifvarclass => "!usermanagement_user_nameempty_${usergroup_user_index}.!windows";

      ## On Windows
      "nameopt[${usergroup_user_index}]"
        string => "/FULLNAME:\"${usergroup_user_fullname[${usergroup_user_index}]}\"",
        ifvarclass => "!usermanagement_user_nameempty_${usergroup_user_index}.windows";

      ## Part of reports to return whether Fullname is defined or not
      "repname[${usergroup_user_index}]"
        string => "Without any defined full name",
        ifvarclass => "usermanagement_user_nameempty_${usergroup_user_index}";

      "repname[${usergroup_user_index}]"
        string => "${usergroup_user_fullname[${usergroup_user_index}]}",
        ifvarclass => "!usermanagement_user_nameempty_${usergroup_user_index}";

  classes:

    # Actions

      "usermanagement_user_update_${usergroup_user_index}" expression => strcmp("${usergroup_user_action[${usergroup_user_index}]}","add");

      "usermanagement_user_remove_${usergroup_user_index}" expression => strcmp("${usergroup_user_action[${usergroup_user_index}]}","remove");

      "usermanagement_user_checkpres_${usergroup_user_index}" expression => strcmp("${usergroup_user_action[${usergroup_user_index}]}","checkhere");

      "usermanagement_user_checkabs_${usergroup_user_index}" expression => strcmp("${usergroup_user_action[${usergroup_user_index}]}","checknothere");

      "usermanagement_user_setuid_${usergroup_user_index}" expression => strcmp("${usergroup_user_setuid[${usergroup_user_index}]}","true");

      "usermanagement_user_setgid_${usergroup_user_index}" expression => strcmp("${usergroup_user_setgid[${usergroup_user_index}]}","true");

      "usermanagement_user_group_exists_${usergroup_user_index}" expression => groupexists("${usergroup_user_gid[${usergroup_user_index}]}");

      "usermanagement_user_forcelocal_${usergroup_user_index}" expression => strcmp("${usergroup_user_forcelocal[${usergroup_user_index}]}","true");

      "usermanagement_user_pershome_${usergroup_user_index}" not => strcmp("${usergroup_user_home_perso[${usergroup_user_index}]}","true");

      "usermanagement_user_custom_home_defined_${usergroup_user_index}" expression => isvariable("usergroup_user_home[${usergroup_user_index}]");

      "usermanagement_user_exists_${usergroup_user_index}" expression => userexists("${usergroup_user_login[${usergroup_user_index}]}");

      "usermanagement_user_pwoneshot_${usergroup_user_index}" expression => strcmp("${usergroup_user_password_policy[${usergroup_user_index}]}","oneshot");

      "usermanagement_user_pweverytime_${usergroup_user_index}" expression => strcmp("${usergroup_user_password_policy[${usergroup_user_index}]}","everytime");

      "usermanagement_user_pwempty_${usergroup_user_index}" not => isvariable("usergroup_user_password[${usergroup_user_index}]");

      "usermanagement_user_nameempty_${usergroup_user_index}" not => isvariable("usergroup_user_fullname[${usergroup_user_index}]");

    # Class 'any' is executed before others classes defined.
    # Same as 'any' but execution will be after all classes defined
      "any_2nd_pass" expression => "any";

      "showtime" expression => isvariable("nameopt[1]");

  commands:

&if(NOVA)&
    windows.showtime::

      "\"${sys.winsysdir}\net.exe\""
        args => "USER ${usergroup_user_login[${usergroup_user_index}]} ${usergroup_user_password[${usergroup_user_index}]} /ADD ${nameopt[${usergroup_user_index}]}",
        classes => cf2_if_else("usermanagement_login_add_${usergroup_user_index}_repaired", "usermanagement_login_add_${usergroup_user_index}_error"),
        comment => "Create the user ${usergroup_user_login[${usergroup_user_index}]}",
        ifvarclass => "!usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_update_${usergroup_user_index}";

      "\"${sys.winsysdir}\net.exe\""
        args => "USER ${usergroup_user_login[${usergroup_user_index}]} /DELETE",
        classes => cf2_if_else("usermanagement_login_remove_${usergroup_user_index}_repaired", "usermanagement_login_remove_${usergroup_user_index}_error"),
        comment => "Delete the user ${usergroup_user_login[${usergroup_user_index}]}",
        ifvarclass => "usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_remove_${usergroup_user_index}";

      "\"${sys.winsysdir}\net.exe\""
        args => "USER ${usergroup_user_login[${usergroup_user_index}]} ${usergroup_user_password[${usergroup_user_index}]}",
        ifvarclass => "(usermanagement_login_add_${usergroup_user_index}_repaired.usermanagement_user_pwoneshot_${usergroup_user_index}.!usermanagement_user_pwempty_${usergroup_user_index})|(usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_pweverytime_${usergroup_user_index}.!usermanagement_user_pwempty_${usergroup_user_index})";
&endif&

    linux.showtime::

      # Default
      "/usr/sbin/useradd"
        args => "-m ${nameopt[${usergroup_user_index}]} -s ${usergroup_user_shell[${usergroup_user_index}]} ${usergroup_user_login[${usergroup_user_index}]}",
        classes => cf2_if_else("usermanagement_login_add_${usergroup_user_index}_repaired", "usermanagement_login_add_${usergroup_user_index}_error"),
        comment => "Create the user",
        ifvarclass => "!usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_update_${usergroup_user_index}.!usermanagement_user_pershome_${usergroup_user_index}.!usermanagement_user_setuid_${usergroup_user_index}.!usermanagement_user_setgid_${usergroup_user_index}";

      # Default + homedir
      "/usr/sbin/useradd"
        args => "-m ${nameopt[${usergroup_user_index}]} -s ${usergroup_user_shell[${usergroup_user_index}]} -d ${usergroup_user_home[${usergroup_user_index}]} ${usergroup_user_login[${usergroup_user_index}]}",
        classes => cf2_if_else("usermanagement_login_add_${usergroup_user_index}_repaired", "usermanagement_login_add_${usergroup_user_index}_error"),
        comment => "Create the user",
        ifvarclass => "!usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_update_${usergroup_user_index}.usermanagement_user_pershome_${usergroup_user_index}.usermanagement_user_custom_home_defined_${usergroup_user_index}.!usermanagement_user_setuid_${usergroup_user_index}.!usermanagement_user_setgid_${usergroup_user_index}";

      # Default + homedir + GID
      "/usr/sbin/useradd"
        args => "-m ${nameopt[${usergroup_user_index}]} -s ${usergroup_user_shell[${usergroup_user_index}]} -g ${usergroup_user_gid[${usergroup_user_index}]} -d ${usergroup_user_home[${usergroup_user_index}]} ${usergroup_user_login[${usergroup_user_index}]}",
        classes => cf2_if_else("usermanagement_login_add_${usergroup_user_index}_repaired", "usermanagement_login_add_${usergroup_user_index}_error"),
        comment => "Create the user",
        ifvarclass => "!usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_update_${usergroup_user_index}.usermanagement_user_pershome_${usergroup_user_index}.usermanagement_user_custom_home_defined_${usergroup_user_index}.!usermanagement_user_setuid_${usergroup_user_index}.usermanagement_user_setgid_${usergroup_user_index}.usermanagement_user_group_exists_${usergroup_user_index}";

      # Default + UID
      "/usr/sbin/useradd"
        args => "-m ${nameopt[${usergroup_user_index}]} -s ${usergroup_user_shell[${usergroup_user_index}]} -u ${usergroup_user_uid[${usergroup_user_index}]} ${usergroup_user_login[${usergroup_user_index}]}",
        classes => cf2_if_else("usermanagement_login_add_${usergroup_user_index}_repaired", "usermanagement_login_add_${usergroup_user_index}_error"),
        comment => "Create the user",
        ifvarclass => "!usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_update_${usergroup_user_index}.usermanagement_user_setuid_${usergroup_user_index}.!usermanagement_user_pershome_${usergroup_user_index}.!usermanagement_user_setgid_${usergroup_user_index}";

      # Default + UID + GID
      "/usr/sbin/useradd"
        args => "-m ${nameopt[${usergroup_user_index}]} -s ${usergroup_user_shell[${usergroup_user_index}]} -u ${usergroup_user_uid[${usergroup_user_index}]} -g ${usergroup_user_gid[${usergroup_user_index}]} ${usergroup_user_login[${usergroup_user_index}]}",
        classes => cf2_if_else("usermanagement_login_add_${usergroup_user_index}_repaired", "usermanagement_login_add_${usergroup_user_index}_error"),
        comment => "Create the user",
        ifvarclass => "!usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_update_${usergroup_user_index}.usermanagement_user_setuid_${usergroup_user_index}.!usermanagement_user_pershome_${usergroup_user_index}.usermanagement_user_setgid_${usergroup_user_index}.usermanagement_user_group_exists_${usergroup_user_index}";

      # Default + UID + homedir
      "/usr/sbin/useradd"
        args => "-m ${nameopt[${usergroup_user_index}]} -s ${usergroup_user_shell[${usergroup_user_index}]} -u ${usergroup_user_uid[${usergroup_user_index}]} -d ${usergroup_user_home[${usergroup_user_index}]} ${usergroup_user_login[${usergroup_user_index}]}",
        classes => cf2_if_else("usermanagement_login_add_${usergroup_user_index}_repaired", "usermanagement_login_add_${usergroup_user_index}_error"),
        comment => "Create the user",
        ifvarclass => "!usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_update_${usergroup_user_index}.usermanagement_user_setuid_${usergroup_user_index}.usermanagement_user_pershome_${usergroup_user_index}.usermanagement_user_custom_home_defined_${usergroup_user_index}.!usermanagement_user_setgid_${usergroup_user_index}";

      # Default + UID + homedir + GID
      "/usr/sbin/useradd"
        args => "-m ${nameopt[${usergroup_user_index}]} -s ${usergroup_user_shell[${usergroup_user_index}]} -u ${usergroup_user_uid[${usergroup_user_index}]} -g ${usergroup_user_gid[${usergroup_user_index}]} -d ${usergroup_user_home[${usergroup_user_index}]} ${usergroup_user_login[${usergroup_user_index}]}",
        classes => cf2_if_else("usermanagement_login_add_${usergroup_user_index}_repaired", "usermanagement_login_add_${usergroup_user_index}_error"),
        comment => "Create the user",
        ifvarclass => "!usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_update_${usergroup_user_index}.usermanagement_user_setuid_${usergroup_user_index}.usermanagement_user_pershome_${usergroup_user_index}.usermanagement_user_custom_home_defined_${usergroup_user_index}.usermanagement_user_setgid_${usergroup_user_index}.usermanagement_user_group_exists_${usergroup_user_index}";

      "/usr/sbin/userdel"
        args => "${usergroup_user_login[${usergroup_user_index}]}",
        classes => cf2_if_else("usermanagement_login_remove_${usergroup_user_index}_repaired", "usermanagement_login_remove_${usergroup_user_index}_error"),
        comment => "Delete the user ${usergroup_user_login[${usergroup_user_index}]}",
        ifvarclass => "usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_remove_${usergroup_user_index}";

  files:

      "/etc/passwd"
        create => "false",
        edit_line => set_user_fullname("${usergroup_user_login[${usergroup_user_index}]}","${usergroup_user_index}","${usergroup_user_fullname[${usergroup_user_index}]}"),
        ifvarclass => "usermanagement_user_update_${usergroup_user_index}.!usermanagement_user_nameempty_${usergroup_user_index}";

      "/etc/passwd"
        create => "false",
        edit_line => set_user_fullname("${usergroup_user_login[${usergroup_user_index}]}","${usergroup_user_index}","${usergroup_user_fullname[${usergroup_user_index}]}"),
        action => warn_only,
        ifvarclass => "usermanagement_user_checkpres_${usergroup_user_index}.!usermanagement_user_nameempty_${usergroup_user_index}";

      # Set default GID if account exists
      "/etc/passwd"
        create => "false",
        edit_line => set_user_field("${usergroup_user_login[${usergroup_user_index}]}", 4, "${usergroup_user_gid[${usergroup_user_index}]}"),
        classes    => kept_if_else("usermanagement_user_gid_ok_${usergroup_user_index}", "usermanagement_user_gid_repaired_${usergroup_user_index}", "usermanagement_user_gid_failed_${usergroup_user_index}"),
        ifvarclass => "usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_setgid_${usergroup_user_index}";

      # Enforce UID if user exists and setuid is checked
      "/etc/passwd"
        create => "false",
        edit_line => set_user_field("${usergroup_user_login[${usergroup_user_index}]}", 3, "${usergroup_user_uid[${usergroup_user_index}]}"),
        classes    => rudder_common_classes("usermanagement_user_uid_${usergroup_user_index}"),
        ifvarclass => "usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_setuid_${usergroup_user_index}";

      # Define password when user has already been created
      "/etc/shadow"
        create     => "false",
        edit_line  => set_user_field("${usergroup_user_login[${usergroup_user_index}]}", 2, "${usergroup_user_password[${usergroup_user_index}]}"),
        classes    => kept_if_else("usermanagement_user_password_ok_${usergroup_user_index}", "usermanagement_user_password_repaired_${usergroup_user_index}", "usermanagement_user_password_failed_${usergroup_user_index}"),
        ifvarclass => "(usermanagement_login_add_${usergroup_user_index}_repaired.usermanagement_user_pwoneshot_${usergroup_user_index}.!usermanagement_user_pwempty_${usergroup_user_index})|(usermanagement_user_update_${usergroup_user_index}.usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_pweverytime_${usergroup_user_index}.!usermanagement_user_pwempty_${usergroup_user_index})";

      # Force user creation by modifying files directly
      "/etc/passwd"
      create => "false",
      edit_line => append_or_change_user("${usergroup_user_login[${usergroup_user_index}]}", "${usergroup_user_login[${usergroup_user_index}]}:x:${usergroup_user_uid[${usergroup_user_index}]}:${usergroup_user_gid[${usergroup_user_index}]}:${usergroup_user_fullname[${usergroup_user_index}]}:${usergroup_user_home[${usergroup_user_index}]}:${usergroup_user_shell[${usergroup_user_index}]}"),
      ifvarclass => "usermanagement_user_forcelocal_${usergroup_user_index}.usermanagement_user_pershome_${usergroup_user_index}"; 

      "/etc/passwd"
      create => "false",
      edit_line => append_or_change_user("${usergroup_user_login[${usergroup_user_index}]}", "${usergroup_user_login[${usergroup_user_index}]}:x:${usergroup_user_uid[${usergroup_user_index}]}:${usergroup_user_gid[${usergroup_user_index}]}:${usergroup_user_fullname[${usergroup_user_index}]}:/home/${usergroup_user_login[${usergroup_user_index}]}:${usergroup_user_shell[${usergroup_user_index}]}"),
      ifvarclass => "usermanagement_user_forcelocal_${usergroup_user_index}.!usermanagement_user_pershome_${usergroup_user_index}"; 

      "/etc/shadow"
      create => "false",
      edit_line => append_or_change_passwd("${usergroup_user_login[${usergroup_user_index}]}", "${usergroup_user_login[${usergroup_user_index}]}:${usergroup_user_password[${usergroup_user_index}]}:::99999:7:::"),
      ifvarclass => "usermanagement_user_forcelocal_${usergroup_user_index}"; 


  # Call user homedir creation for locally forced accounts
  methods:

      "any" usebundle => force_create_user_homedir("${usergroup_user_home[${usergroup_user_index}]}", "${usergroup_user_uid[${usergroup_user_index}]}", "${usergroup_user_gid[${usergroup_user_index}]}"),
        ifvarclass => "usermanagement_user_forcelocal_${usergroup_user_index}.usermanagement_user_pershome_${usergroup_user_index}";

      "any" usebundle => force_create_user_homedir("/home/${usergroup_user_login[${usergroup_user_index}]}", "${usergroup_user_uid[${usergroup_user_index}]}", "${usergroup_user_gid[${usergroup_user_index}]}"),
        ifvarclass => "usermanagement_user_forcelocal_${usergroup_user_index}.!usermanagement_user_pershome_${usergroup_user_index}";


  reports:

    (linux|windows).showtime::

      # Add user
      ## Does exist (Success)
      "@@userGroupManagement@@result_success@@${usergroup_directive_id[${usergroup_user_index}]}@@Users@@${usergroup_user_login[${usergroup_user_index}]}@@${g.execRun}##${g.uuid}@#The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) is already present on the system"
        ifvarclass => "usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_update_${usergroup_user_index}.!usermanagement_login_add_${usergroup_user_index}_repaired.(usermanagement_user_nameempty_${usergroup_user_index}|usermanagement_fullname_edit_${usergroup_user_index}_kept)";

      ## Seems to exist with a wrong Full Name (Repaired)
      "@@userGroupManagement@@result_repaired@@${usergroup_directive_id[${usergroup_user_index}]}@@Users@@${usergroup_user_login[${usergroup_user_index}]}@@${g.execRun}##${g.uuid}@#The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) had a wrong fullname"
        ifvarclass => "usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_update_${usergroup_user_index}.!usermanagement_user_nameempty_${usergroup_user_index}.(usermanagement_fullname_edit_${usergroup_user_index}_repaired|usermanagement_fullname_edit_${usergroup_user_index}_error)";

      ## Added (Repaired)
      "@@userGroupManagement@@result_repaired@@${usergroup_directive_id[${usergroup_user_index}]}@@Users@@${usergroup_user_login[${usergroup_user_index}]}@@${g.execRun}##${g.uuid}@#The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) has been added to the system"
        ifvarclass => "!usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_update_${usergroup_user_index}.usermanagement_login_add_${usergroup_user_index}_repaired";

      ## Error
      "@@userGroupManagement@@result_error@@${usergroup_directive_id[${usergroup_user_index}]}@@Users@@${usergroup_user_login[${usergroup_user_index}]}@@${g.execRun}##${g.uuid}@#The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) could not be added to the system"
        ifvarclass => "!usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_update_${usergroup_user_index}.usermanagement_login_add_${usergroup_user_index}_error";

      ## Could not be added, for the default path was not selected, but the custom one was not defined
      "@@userGroupManagement@@result_error@@${usergroup_directive_id[${usergroup_user_index}]}@@Users@@${usergroup_user_login[${usergroup_user_index}]}@@${g.execRun}##${g.uuid}@#The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) could not be added to the system because the default home directory was not selected, but the custom path was not specified"
        ifvarclass => "!usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_update_${usergroup_user_index}.usermanagement_user_pershome_${usergroup_user_index}.!usermanagement_user_custom_home_defined_${usergroup_user_index}";

      # Remove user
      ## Does not exist (Success)
      "@@userGroupManagement@@result_success@@${usergroup_directive_id[${usergroup_user_index}]}@@Users@@${usergroup_user_login[${usergroup_user_index}]}@@${g.execRun}##${g.uuid}@#The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) does not exist, as required"
        ifvarclass => "!usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_remove_${usergroup_user_index}";

      ## Removed (Repaired)
      "@@userGroupManagement@@result_repaired@@${usergroup_directive_id[${usergroup_user_index}]}@@Users@@${usergroup_user_login[${usergroup_user_index}]}@@${g.execRun}##${g.uuid}@#The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) has been removed from the system"
        ifvarclass => "usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_remove_${usergroup_user_index}.usermanagement_login_remove_${usergroup_user_index}_repaired";

      ## Error
      "@@userGroupManagement@@result_error@@${usergroup_directive_id[${usergroup_user_index}]}@@Users@@${usergroup_user_login[${usergroup_user_index}]}@@${g.execRun}##${g.uuid}@#The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) could not be removed from the system"
        ifvarclass => "usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_remove_${usergroup_user_index}.usermanagement_login_remove_${usergroup_user_index}_error";

      # Check user not exists
      ## Does not exist (Success)
      "@@userGroupManagement@@result_success@@${usergroup_directive_id[${usergroup_user_index}]}@@Users@@${usergroup_user_login[${usergroup_user_index}]}@@${g.execRun}##${g.uuid}@#The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) is not present on the system, which is in accordance with the non presence policy"
        ifvarclass => "!usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_checkabs_${usergroup_user_index}";

      ## Does exist (Error)
      "@@userGroupManagement@@result_error@@${usergroup_directive_id[${usergroup_user_index}]}@@Users@@${usergroup_user_login[${usergroup_user_index}]}@@${g.execRun}##${g.uuid}@#The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) is present on the system, which violates the non presence policy"
        ifvarclass => "usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_checkabs_${usergroup_user_index}";

      # Check user exists
      ## Does exist (Success)
      "@@userGroupManagement@@result_success@@${usergroup_directive_id[${usergroup_user_index}]}@@Users@@${usergroup_user_login[${usergroup_user_index}]}@@${g.execRun}##${g.uuid}@#The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) is present on the system, which is in conformance with the presence policy"
        ifvarclass => "usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_checkpres_${usergroup_user_index}.(usermanagement_user_nameempty_${usergroup_user_index}|usermanagement_fullname_edit_${usergroup_user_index}_kept)";

      ## Seems to exist with a wrong Full Name (Error)
      "@@userGroupManagement@@result_error@@${usergroup_directive_id[${usergroup_user_index}]}@@Users@@${usergroup_user_login[${usergroup_user_index}]}@@${g.execRun}##${g.uuid}@#The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) is present on the system, but does not have the right fullname"
        ifvarclass => "usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_checkpres_${usergroup_user_index}.!usermanagement_user_nameempty_${usergroup_user_index}.(usermanagement_fullname_edit_${usergroup_user_index}_repaired|usermanagement_fullname_edit_${usergroup_user_index}_error)";

      ## Does not exist (Error)
      "@@userGroupManagement@@result_error@@${usergroup_directive_id[${usergroup_user_index}]}@@Users@@${usergroup_user_login[${usergroup_user_index}]}@@${g.execRun}##${g.uuid}@#The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) is not present on the system, which violates the presence policy"
        ifvarclass => "!usermanagement_user_exists_${usergroup_user_index}.usermanagement_user_checkpres_${usergroup_user_index}";

      # Password handling
      ## Is OK (Success)
      "@@userGroupManagement@@result_success@@${usergroup_directive_id[${usergroup_user_index}]}@@Password@@${usergroup_user_login[${usergroup_user_index}]}@@${g.execRun}##${g.uuid}@#The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) password is OK"
        ifvarclass => "usermanagement_user_password_ok_${usergroup_user_index}";

      ## Has been changed (Repaired)
      "@@userGroupManagement@@result_repaired@@${usergroup_directive_id[${usergroup_user_index}]}@@Password@@${usergroup_user_login[${usergroup_user_index}]}@@${g.execRun}##${g.uuid}@#The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) password has been changed"
        ifvarclass => "usermanagement_user_password_repaired_${usergroup_user_index}";

      ## Could not be changed (Error)
      "@@userGroupManagement@@result_error@@${usergroup_directive_id[${usergroup_user_index}]}@@Password@@${usergroup_user_login[${usergroup_user_index}]}@@${g.execRun}##${g.uuid}@#The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) password could NOT be changed !"
        ifvarclass => "usermanagement_user_password_failed_${usergroup_user_index}";

      ## Change not needed (Success)
      "@@userGroupManagement@@result_success@@${usergroup_directive_id[${usergroup_user_index}]}@@Password@@${usergroup_user_login[${usergroup_user_index}]}@@${g.execRun}##${g.uuid}@#The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) password change is not required"
        ifvarclass => "(!usermanagement_user_password_ok_${usergroup_user_index}.!usermanagement_user_password_repaired_${usergroup_user_index}.!usermanagement_user_password_failed_${usergroup_user_index}).usermanagement_user_pwoneshot_${usergroup_user_index}.usermanagement_user_exists_${usergroup_user_index}";

      # GID handling
      ## Is OK (Success)
      "@@userGroupManagement@@result_success@@${usergroup_directive_id[${usergroup_user_index}]}@@Group ID@@${usergroup_user_login[${usergroup_user_index}]}@@${g.execRun}##${g.uuid}@#The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) Group ID is OK"
        ifvarclass => "usermanagement_user_gid_ok_${usergroup_user_index}";

      ## Has been changed (Repaired)
      "@@userGroupManagement@@result_repaired@@${usergroup_directive_id[${usergroup_user_index}]}@@Group ID@@${usergroup_user_login[${usergroup_user_index}]}@@${g.execRun}##${g.uuid}@#The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) Group ID has been changed"
        ifvarclass => "usermanagement_user_gid_repaired_${usergroup_user_index}";

      ## Could not be changed (Error)
      "@@userGroupManagement@@result_error@@${usergroup_directive_id[${usergroup_user_index}]}@@Group ID@@${usergroup_user_login[${usergroup_user_index}]}@@${g.execRun}##${g.uuid}@#The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) Group ID could NOT be changed !"
        ifvarclass => "usermanagement_user_gid_failed_${usergroup_user_index}";

      ## Change not needed (Success)
      "@@userGroupManagement@@result_success@@${usergroup_directive_id[${usergroup_user_index}]}@@Group ID@@${usergroup_user_login[${usergroup_user_index}]}@@${g.execRun}##${g.uuid}@#The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) Group ID change is not required"
        ifvarclass => "!usermanagement_user_gid_ok_${usergroup_user_index}.!usermanagement_user_gid_repaired_${usergroup_user_index}.!usermanagement_user_gid_failed_${usergroup_user_index}";

      # UID handling
      ## Is OK (Success)
      "@@userGroupManagement@@result_success@@${usergroup_directive_id[${usergroup_user_index}]}@@User ID@@${usergroup_user_login[${usergroup_user_index}]}@@${g.execRun}##${g.uuid}@#The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) UID is OK"
        ifvarclass => "usermanagement_user_uid_${usergroup_user_index}_kept";

      ## Has been changed (Repaired)
      "@@userGroupManagement@@result_repaired@@${usergroup_directive_id[${usergroup_user_index}]}@@User ID@@${usergroup_user_login[${usergroup_user_index}]}@@${g.execRun}##${g.uuid}@#The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) UID has been changed"
        ifvarclass => "usermanagement_user_uid_${usergroup_user_index}_repaired";

      ## Could not be changed (Error)
      "@@userGroupManagement@@result_error@@${usergroup_directive_id[${usergroup_user_index}]}@@User ID@@${usergroup_user_login[${usergroup_user_index}]}@@${g.execRun}##${g.uuid}@#The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) UID could NOT be changed !"
        ifvarclass => "usermanagement_user_uid_${usergroup_user_index}_error";

      ## Change not needed (Success)
      "@@userGroupManagement@@result_success@@${usergroup_directive_id[${usergroup_user_index}]}@@User ID@@${usergroup_user_login[${usergroup_user_index}]}@@${g.execRun}##${g.uuid}@#The user ${usergroup_user_login[${usergroup_user_index}]} ( ${repname[${usergroup_user_index}]} ) UID change is not required"
        ifvarclass => "!usermanagement_user_uid_${usergroup_user_index}_kept.!usermanagement_user_uid_${usergroup_user_index}_repaired.!usermanagement_user_uid_${usergroup_user_index}_error";

}

bundle edit_line set_user_fullname(user,user_index,fullname)
{
  field_edits:
      "${user}:.*"
      # Edit GECOS on /etc/passwd
        edit_field => col(":", "5", "${fullname}", "set"),
        classes => kept_if_else("usermanagement_fullname_edit_${user_index}_kept","usermanagement_fullname_edit_${user_index}_repaired","usermanagement_fullname_edit_${user_index}_error");

}

bundle edit_line append_or_change_user(user, user_string) {
    delete_lines:
        "^.*$(user).*";

    insert_lines:
        "$(user_string)",
            comment => "Append users into a password file format",
            classes => cf2_if_else("usermanagement_login_add_${usergroup_user_index}_repaired", "usermanagement_login_add_${usergroup_user_index}_error");
}

bundle edit_line append_or_change_passwd(user, pass_string) {
    delete_lines:
        "^.*$(user).*";

    insert_lines:
        "$(pass_string)"
            comment => "Append user password in shadow file format",
            classes => kept_if_else("usermanagement_user_password_ok_${usergroup_user_index}", "usermanagement_user_password_repaired_${usergroup_user_index}", "usermanagement_user_password_failed_${usergroup_user_index}");
}

bundle agent force_create_user_homedir(home, uid, gid) {
    files:
        "$(home)/."
            create => "true",
            perms => mog("700", "$(uid)", "$(gid)");

}

