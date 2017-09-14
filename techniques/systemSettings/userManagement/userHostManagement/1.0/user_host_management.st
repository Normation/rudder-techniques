#####################################################################################
# Copyright 2011-2016 Normation SAS
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

bundle agent user_host_management
{

  vars:

    &TRACKINGKEY:{directiveId |"trackingkey[&i&]" string => "&directiveId&";
}&

    &USER_NODE_MANAGEMENT_LOGIN:{login |"logins[&i&]" string => "&login&";
}&

    &USER_NODE_MANAGEMENT_POLICY:{policy |"policies[&i&]" string => "&policy&";
}&

    &USER_NODE_MANAGEMENT_PASSWORD:{password |"passwords[&i&]" string => "&password&";
}&

    &USER_NODE_MANAGEMENT_PASSWORD_AIX:{password |"aix_passwords[&i&]" string => "&password&";
    
}&

    "index" slist => getindices("logins");
    "descriptions[${index}]" string => "${logins[${index}]}";
    "home[${index}]" string => "/home/${logins[${index}]}";
    #"group[${index}]" string => "${logins[${index}]}";
    "group[${index}]" string => "";
    "shell[${index}]" string => "/bin/bash";
    "locked[${index}]" string => "false";

    "logins_canon[${index}]" string => canonify("${logins[${index}]}");
    
  classes:
    any::
      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";

    "present_policy_${index}" expression => strcmp("${policies[${index}]}", "present");
    "absent_policy_${index}" expression => strcmp("${policies[${index}]}", "absent");


    # with variables that are not unique, the emptyness detection is quite tricky
    # either the variable is not defined, or the variable value is ""
    "user_host_management_pw_no_variable_${index}"     not => isvariable("passwords[${index}]");
    "user_host_management_pw_no_value_${index}" expression => strcmp("", "${passwords[${index}]}");
    "user_host_management_pwempty_${index}"     expression => "user_host_management_pw_no_variable_${index}|user_host_management_pw_no_value_${index}";

    "user_host_group_exists_${index}" expression => groupexists("${group[${index}]}");


  methods:    
    "ensure_${index}_present" usebundle => user_create("${logins[${index}]}", "${descriptions[${index}]}", "${home[${index}]}", "${group[${index}]}", "${shell[${index}]}", "${locked[${index}]}"),
      ifvarclass => "present_policy_${index}";
    
    "ensure_${index}}_absent" usebundle => user_absent("${logins[${index}]}"),
      ifvarclass => "absent_policy_${index}";

    "ensure_${index}_password" usebundle => set_password("${logins[${index}]}", "${passwords[${index}]}", "${trackingkey[${index}]}", "${index}"),
      ifvarclass => "user_create_${logins_canon[${index}]}_ok.!user_host_management_pwempty_${index}";

    "ensure_${index}_home" usebundle => command_execution("mkdir -m 755 /home/${logins[${index}]}; chown ${logins[${index}]}: /home/${logins[${index}]}"),
      ifvarclass => "user_create_${logins_canon[${index}]}_ok.!user_host_management_pwempty_${index}";

    "ensure_${index}_pass2" usebundle => command_execution("echo ${passwords[${index}]} | passwd ${logins[${index}]} --stdin"),
      ifvarclass => "user_create_${logins_canon[${index}]}_ok.!user_host_management_pwempty_${index}";

    ################## REPORTING ################## 

    "any" usebundle => rudder_common_reports_generic("user_host_management", "user_create_${logins_canon[${index}]}", "${trackingkey[${index}]}", "User Present", "${logins[${index}]}", "Adding user ${logins[${index}]}"),
    ifvarclass => "present_policy_${index}";

    "any" usebundle => rudder_common_reports_generic("user_host_management", "user_absent_${logins_canon[${index}]}", "${trackingkey[${index}]}", "User Present", "${logins[${index}]}", "Deleting user ${logins[${index}]}"),
    ifvarclass => "absent_policy_${index}";
# Waiting for better reporting from the generic method on windows
#    "any" usebundle => rudder_common_report("user_host_management", "result_na", "${trackingkey[${index}]}", "Password", "${logins[${index}]}", "Absent policy selected"),
#    ifvarclass => "absent_policy_${index}";
#
#    "any" usebundle => rudder_common_report("user_host_management", "result_na", "${trackingkey[${index}]}", "Password", "${logins[${index}]}", "Empty password, it will be impossible to loggin"),
#    ifvarclass => "user_host_management_pwempty_${index}.!absent_policy_${index}";
#
}


bundle agent set_password (login, password, trackingkey, index) {

  vars:
    "login_canon" string => canonify("${login}");

  files:
    aix::
      # On AIX, if password is supplied and user must exist, then the second field needs to be a ! to allow login
      "/etc/passwd"
        create        => "false",
        edit_line     => set_colon_field("${login}", "2", "!"),
        edit_defaults => noempty_backup,
        classes       => classes_generic("user_host_management_password_${index}");

    #!windows.!aix::
    #  # Define password when user has already been created
    #  "/etc/shadow"
    #    create        => "false",
    #    edit_line     => set_user_field("${login}", 2, "${password}"),
    #    edit_defaults => noempty_backup,
    #    classes       => classes_generic("user_host_management_password_${index}");


    aix::
      "/etc/security/passwd"
        create        => "false",
        edit_line     => ncf_ensure_AIX_password("${login}", "${password}"),
        edit_defaults => noempty_backup,
        classes       => classes_generic("user_host_management_password_${index}");

      # set the last update date if password has been updated
      "/etc/security/passwd"
        create        => "false",
        edit_line     => ncf_edit_lastupdate_AIX_password("${login}"),
        edit_defaults => noempty_backup;
# See above
#  methods:
#    "any" usebundle => rudder_common_reports_generic("user_host_management", "user_host_management_password_${index}", "${trackingkey}", "Password", "${login}", "Setting password for the user ${login}");
#
}

