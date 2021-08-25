# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: 2021 Normation SAS

##########################################################################
# Group management Technique                                             #
#                                                                        #
# Objective : Apply group policies on the target host                    #
##########################################################################


bundle agent check_usergroup_grp_parameters_&RudderUniqueID& {

  vars:
		&USERGROUP_GROUP_NAME:{name |"usergroup_group_name[&i&]" string => "&name&";
}&

        &USERGROUP_GROUP_CREATE:{create |"usergroup_group_create[&i&]" string => "&create&";
}&

        &USERGROUP_GROUP_SET_GID:{setgid |"usergroup_group_set_gid[&i&]" string => "&setgid&";
}&

        &USERGROUP_GROUP_GID:{gid |"usergroup_group_gid[&i&]" string => "&gid&";
}&

        &USERGROUP_GROUP_ENFORCE_CONTENT:{enforce_content |"usergroup_group_enforce_content[&i&]" string => "&enforce_content&";
}&

        &USERGROUP_GROUP_CONTENT:{content |"usergroup_group_content[&i&]" string => "&content&";
}&

        &USERGROUP_GROUP_POLICY:{policy |"usergroup_group_policy[&i&]" string => "&policy&";
}&

        &TRACKINGKEY:{directiveId |"usergroup_group_directive_id[&i&]" string => "&directiveId&";
}&

      "usergroup_group_index" slist => getindices("usergroup_group_name");

  methods:

      "any"
        usebundle => check_usergroup_group_parameters_grouphandle_&RudderUniqueID&("${usergroup_group_name[${usergroup_group_index}]}", "${usergroup_group_create[${usergroup_group_index}]}", "${usergroup_group_set_gid[${usergroup_group_index}]}", "${usergroup_group_gid[${usergroup_group_index}]}","${usergroup_group_enforce_content[${usergroup_group_index}]}", "${usergroup_group_content[${usergroup_group_index}]}", "${usergroup_group_index}", "${usergroup_group_directive_id[${usergroup_group_index}]}");

}

bundle agent check_usergroup_group_parameters_grouphandle_&RudderUniqueID&(name, create, setgid, gid, enforce_content, content, index, directiveId) {

    vars:

        "userlist" slist => splitstring("${content}",",","16");
        "current_gid_for_group"                                 int => getgid("${name}");

    classes:

        "groupmanagement_group_${index}_absent"          not => groupexists("${name}");
        "groupmanagement_group_${index}_create"          expression => strcmp("${create}", "true");
        "groupmanagement_group_${index}_setgid"          expression => strcmp("${setgid}", "true");
        "groupmanagement_group_${index}_enforce_content" expression => strcmp("${enforce_content}", "true");

        # can only set the gid if group is not already taken, or exists but is registered to ${name}
      !pass1::
        "groupmanagement_gid_${index}_already_taken"     expression => groupexists("${gid}");
        "groupmanagement_gid_${index}_allocated_ok"      expression => strcmp("${current_gid_for_group}", "${gid}");
        "gid_may_be_changed_${index}"                    expression => "!groupmanagement_gid_${index}_already_taken|(groupmanagement_gid_${index}_already_taken.groupmanagement_gid_${index}_allocated_ok)";

    any::
      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";

    files:

        # Enforce group content on if groupmanagement_group_${index}_enforce_content is set
        "/etc/group"
            edit_line     => groups_file_set_&RudderUniqueID&("${name}", "@(check_usergroup_group_parameters_grouphandle_&RudderUniqueID&.userlist)"),
            edit_defaults => noempty_backup,
            classes       => classes_generic("groupmanagement_group_add_${index}_&RudderUniqueID&"),
            ifvarclass    => "groupmanagement_group_${index}_enforce_content.(!groupmanagement_group_${index}_absent|groupmanagement_group_add_${index}_&RudderUniqueID&_repaired)",
            comment       => "Set users on the group ${name} only if the group is already present";

        # Append group content on if groupmanagement_group_${index}_enforce_content is not set
        "/etc/group"
            edit_line     => append_user_field("${name}", "4", "@(check_usergroup_group_parameters_grouphandle_&RudderUniqueID&.userlist)"),
            edit_defaults => noempty_backup,
            classes       => classes_generic("groupmanagement_group_add_${index}_&RudderUniqueID&"),
            ifvarclass    => "!groupmanagement_group_${index}_enforce_content.(!groupmanagement_group_${index}_absent|groupmanagement_group_add_${index}_&RudderUniqueID&_repaired)",
            comment       => "Append users on the group ${name} only if the group is already present";

        # Enforce GID if setgid has been set
        "/etc/group"
            create     => "false",
            edit_line  => set_user_field("${name}", 3, "${gid}"),
            classes    => classes_generic("groupmanagement_group_gid_${index}_&RudderUniqueID&"),
            ifvarclass => "!groupmanagement_group_${index}_absent.groupmanagement_group_${index}_setgid.gid_may_be_changed_${index}";



  methods:

    pass3.cfengine::

      "any" usebundle => rudder_common_report_index("groupManagement", "result_success", "${directiveId}", "Groups", "${name}", "The group ${name} is already present and compliant with the policy", "${index}"),
                ifvarclass => "groupmanagement_group_add_${index}_&RudderUniqueID&_kept.!(groupmanagement_group_add_${index}_&RudderUniqueID&_repaired|groupmanagement_group_add_${index}_&RudderUniqueID&_error)";

      "any" usebundle => rudder_common_report_index("groupManagement", "result_repaired", "${directiveId}", "Groups", "${name}", "The group ${name} has been updated", "${index}"),
                ifvarclass => "groupmanagement_group_add_${index}_&RudderUniqueID&_repaired.!groupmanagement_group_add_${index}_&RudderUniqueID&_error";

      "any" usebundle => rudder_common_report_index("groupManagement", "result_error", "${directiveId}", "Groups", "${name}", "The group ${name} could not be created or updated", "${index}"),
                ifvarclass => "groupmanagement_group_add_${index}_&RudderUniqueID&_error";

      "any" usebundle => rudder_common_report_index("groupManagement", "result_success", "${directiveId}", "Groups", "${name}", "The group ${name} is not present and not set to be created", "${index}"),
                ifvarclass => "groupmanagement_group_${index}_absent.!groupmanagement_group_${index}_create";

       #Group enforce GID
      "any" usebundle => rudder_common_reports_generic_index("groupManagement", "groupmanagement_group_gid_${index}_&RudderUniqueID&", "${directiveId}", "Group enforce GID", "${name}", "The group ${name} gid set to ${gid}", "${index}"),
                ifvarclass => "!groupmanagement_group_${index}_absent.groupmanagement_group_${index}_setgid.gid_may_be_changed_${index}";

      "any" usebundle => rudder_common_report_index("groupManagement", "result_error", "${directiveId}", "Group enforce GID", "${name}", "The group ${name} gid cannot be set to already used gid ${gid}", "${index}"),
                ifvarclass => "!groupmanagement_group_${index}_absent.groupmanagement_group_${index}_setgid.!gid_may_be_changed_${index}";


      ## when group is not created
      "any" usebundle => rudder_common_report_index("groupManagement", "result_na", "${directiveId}", "Group enforce GID", "${name}", "The group ${name} is not present", "${index}"),
                ifvarclass => "groupmanagement_group_${index}_absent.groupmanagement_group_${index}_setgid.!groupmanagement_group_add_${index}_&RudderUniqueID&_repaired.!groupmanagement_group_add_${index}_&RudderUniqueID&_error";


      ## when group is created
      "any" usebundle => rudder_common_report_index("groupManagement", "result_success", "${directiveId}", "Group enforce GID", "${name}", "The group ${name} gid set  to ${gid}", "${index}"),
                ifvarclass => "groupmanagement_group_${index}_absent.groupmanagement_group_${index}_setgid.groupmanagement_group_add_${index}_&RudderUniqueID&_repaired";

      "any" usebundle => rudder_common_report_index("groupManagement", "result_error", "${directiveId}", "Group enforce GID", "${name}", "The group ${name} could not be created", "${index}"),
                ifvarclass => "groupmanagement_group_${index}_absent.groupmanagement_group_${index}_setgid.groupmanagement_group_add_${index}_&RudderUniqueID&_error";


      "any" usebundle => rudder_common_report_index("groupManagement", "result_na", "${directiveId}", "Group enforce GID", "${name}", "The group ${name} is not set to have its gid set", "${index}"),
                ifvarclass => "!groupmanagement_group_${index}_absent.!groupmanagement_group_${index}_setgid";

      "any" usebundle => rudder_common_report_index("groupManagement", "result_na", "${directiveId}", "Group enforce GID", "${name}", "The group ${name} is not set to have its gid set", "${index}"),
                ifvarclass => "groupmanagement_group_${index}_absent.!groupmanagement_group_${index}_setgid";



    commands:

      !aix::
        "/usr/sbin/groupadd"
            args => "-f \"${name}\"",
            classes => if_else("groupmanagement_group_add_${index}_&RudderUniqueID&_repaired", "groupmanagement_group_add_${index}_&RudderUniqueID&_error"),
            ifvarclass => "groupmanagement_group_${index}_absent.groupmanagement_group_${index}_create.!groupmanagement_group_${index}_setgid",
            comment => "Add the group ${name} if it doesn't exists";

        "/usr/sbin/groupadd"
            args => "\"${name}\" -g \"${gid}\"",
            classes => if_else("groupmanagement_group_add_${index}_&RudderUniqueID&_repaired", "groupmanagement_group_add_${index}_&RudderUniqueID&_error"),
            ifvarclass => "groupmanagement_group_${index}_absent.groupmanagement_group_${index}_create.groupmanagement_group_${index}_setgid",
            comment => "Add the group ${name} with GID ${gid} if it doesn't exists";

      aix::
        "/usr/bin/mkgroup"
            args => "${name}",
            classes => if_else("groupmanagement_group_add_${index}_&RudderUniqueID&_repaired", "groupmanagement_group_add_${index}_&RudderUniqueID&_error"),
            ifvarclass => "groupmanagement_group_${index}_absent.groupmanagement_group_${index}_create.!groupmanagement_group_${index}_setgid",
            comment => "Add the group ${name} if it doesn't exists";

        "/usr/bin/mkgroup"
            args => "id=${gid} ${name}",
            classes => if_else("groupmanagement_group_add_${index}_&RudderUniqueID&_repaired", "groupmanagement_group_add_${index}_&RudderUniqueID&_error"),
            ifvarclass => "groupmanagement_group_${index}_absent.groupmanagement_group_${index}_create.groupmanagement_group_${index}_setgid",
            comment => "Add the group ${name} with GID ${gid} if it doesn't exists";

}

bundle edit_line groups_file_set_&RudderUniqueID&(group,userlist)
{

vars:

    "finalgroup" string => join(",","userlist");

field_edits:

    "${group}:.*"

      # Set field of the file to parameter
      # /etc/group entry is: groupname:x:gid:users
      edit_field => col(":","4","${finalgroup}","set");

}
