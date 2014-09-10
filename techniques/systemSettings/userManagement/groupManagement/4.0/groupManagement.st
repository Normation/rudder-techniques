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
# Group management PT                                                    #
#                                                                        #
# Objective : Apply group policies on the target host                    #
##########################################################################

# I was forced to truncate brutally the name, as on CF3 3.1.4 more than 32 chars on the bundle name leads to arrays corruption
bundle agent check_usergroup_grp_parameters {

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
        usebundle => check_usergroup_group_parameters_grouphandle("${usergroup_group_name[${usergroup_group_index}]}", "${usergroup_group_create[${usergroup_group_index}]}", "${usergroup_group_set_gid[${usergroup_group_index}]}", "${usergroup_group_gid[${usergroup_group_index}]}","${usergroup_group_enforce_content[${usergroup_group_index}]}", "${usergroup_group_content[${usergroup_group_index}]}", "${usergroup_group_index}", "${usergroup_group_directive_id[${usergroup_group_index}]}");

}

bundle agent check_usergroup_group_parameters_grouphandle(name, create, setgid, gid, enforce_content, content, index, directiveId) {

    vars:

        "userlist" slist => splitstring("${content}",",","16");


    classes:

        "groupmanagement_group_${index}_absent"          not => groupexists("${name}");
        "groupmanagement_group_${index}_create"          expression => strcmp("${create}", "true");
        "groupmanagement_group_${index}_setgid"          expression => strcmp("${setgid}", "true");
        "groupmanagement_group_${index}_enforce_content" expression => strcmp("${enforce_content}", "true");

    files:

        # Enforce group content on if groupmanagement_group_${index}_enforce_content is set
        "/etc/group"
            edit_line => groups_file_append("${name}", "@(check_usergroup_group_parameters_grouphandle.userlist)"),
            edit_defaults => noempty_backup,
            classes => rudder_common_classes("groupmanagement_group_add_${index}"),
            ifvarclass => "groupmanagement_group_${index}_enforce_content.(!groupmanagement_group_${index}_absent|groupmanagement_group_add_${index}_repaired)",
            comment => "Set users on the group ${name} only if the group is already present";

        # Enforce GID if setgid has been set
        "/etc/group"
            create     => "false",
            edit_line  => set_user_field("${name}", 3, "${gid}"),
            classes    => rudder_common_classes("groupmanagement_group_gid_${index}"),
            ifvarclass => "!groupmanagement_group_${index}_absent.groupmanagement_group_${index}_setgid";

    commands:

        "/usr/sbin/groupadd"
            args => "-f \"${name}\"",
            classes => if_else("groupmanagement_group_add_${index}_repaired", "groupmanagement_group_add_${index}_error"),
            ifvarclass => "groupmanagement_group_${index}_absent.groupmanagement_group_${index}_create.!groupmanagement_group_${index}_setgid",
            comment => "Add the group ${name} if it doesn't exists";

        "/usr/sbin/groupadd"
            args => "-f \"${name}\" -g \"${gid}\"",
            classes => if_else("groupmanagement_group_add_${index}_repaired", "groupmanagement_group_add_${index}_error"),
            ifvarclass => "groupmanagement_group_${index}_absent.groupmanagement_group_${index}_create.groupmanagement_group_${index}_setgid",
            comment => "Add the group ${name} with GID ${gid} if it doesn't exists";

    reports:

        linux::

            "@@groupManagement@@result_success@@${directiveId}@@Groups@@${name}@@${g.execRun}##${g.uuid}@#The group ${name} is already present and compliant with the policy"
                ifvarclass => "groupmanagement_group_add_${index}_kept.!(groupmanagement_group_add_${index}_repaired|groupmanagement_group_add_${index}_error)";

            "@@groupManagement@@result_success@@${directiveId}@@Groups@@${name}@@${g.execRun}##${g.uuid}@#The group ${name} is already present and doesn't require to have its content enforced"
                ifvarclass => "!groupmanagement_group_${index}_enforce_content.!(groupmanagement_group_add_${index}_kept.groupmanagement_group_add_${index}_repaired|groupmanagement_group_add_${index}_error)";

            "@@groupManagement@@result_repaired@@${directiveId}@@Groups@@${name}@@${g.execRun}##${g.uuid}@#The group ${name} has been updated"
                ifvarclass => "groupmanagement_group_add_${index}_repaired.!(groupmanagement_group_add_${index}_kept|groupmanagement_group_add_${index}_error)";

            "@@groupManagement@@result_error@@${directiveId}@@Groups@@${name}@@${g.execRun}##${g.uuid}@#The group ${name} could not be created or updated"
                ifvarclass => "groupmanagement_group_add_${index}_error";

            "@@groupManagement@@result_success@@${directiveId}@@Groups@@${name}@@${g.execRun}##${g.uuid}@#The group ${name} is not present and not set to be created"
                ifvarclass => "groupmanagement_group_${index}_absent.!groupmanagement_group_${index}_create";
}

bundle edit_line groups_file_append(group,userlist)
{

vars:

	"finalgroup" string => join(",","userlist");

field_edits:

	"${group}:.*"

	# Set field of the file to parameter
	# /etc/group entry is: groupname:x:gid:users
	edit_field => col(":","4","${finalgroup}","set");

}
