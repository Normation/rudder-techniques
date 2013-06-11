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

		&USERGROUP_GROUP_CONTENT:{content |"usergroup_group_content[&i&]" string => "&content&";
}&

		&USERGROUP_GROUP_POLICY:{policy |"usergroup_group_policy[&i&]" string => "&policy&";
}&

		&TRACKINGKEY:{directiveId |"usergroup_group_directive_id[&i&]" string => "&directiveId&";
}&

		"usergroup_group_index" slist => getindices("usergroup_group_name");

	methods:

      "any"
        usebundle => check_usergroup_group_parameters_grouphandle("${usergroup_group_name[${usergroup_group_index}]}", "${usergroup_group_create[${usergroup_group_index}]}", "${usergroup_group_content[${usergroup_group_index}]}", "${usergroup_group_index}", "${usergroup_group_directive_id[${usergroup_group_index}]}");

}

bundle agent check_usergroup_group_parameters_grouphandle(name, create, content, index, directiveId) {

	classes:

		"groupmanagement_group_$(index)_absent" not => groupexists("$(name)");
      "groupmanagement_group_${index}_create" expression => strcmp("${create}", "true");

	vars:

		"userlist" slist => splitstring("$(content)",",","16");


	commands:

      "/usr/sbin/groupadd"
        args => "-f \"${name}\"",
        classes => if_else("groupmanagement_group_add_${index}_repaired", "groupmanagement_group_add_${index}_error"),
        ifvarclass => "groupmanagement_group_${index}_absent.groupmanagement_group_${index}_create",
        comment => "Add the group ${name} if it doesn't exists";

	files:

		"/etc/group"
			edit_line => groups_file_append("$(name)", "@(check_usergroup_group_parameters_grouphandle.userlist)"),
			classes => kept_if_else("groupmanagement_group_add_$(index)_kept", "groupmanagement_group_add_$(index)_repaired", "groupmanagement_group_add_$(index)_error"),
			ifvarclass => "!groupmanagement_group_$(index)_absent|groupmanagement_group_add_$(index)_repaired",
			comment => "Set users on the group $(name) only if the group is already present";

	reports:

		linux::

			"@@groupManagement@@result_success@@$(directiveId)@@Groups@@$(name)@@$(g.execRun)##$(g.uuid)@#The group $(name) is already present and compliant with the policy"
				ifvarclass => "groupmanagement_group_add_$(index)_kept.!(groupmanagement_group_add_$(index)_repaired|groupmanagement_group_add_$(index)_error)";

			"@@groupManagement@@result_repaired@@$(directiveId)@@Groups@@$(name)@@$(g.execRun)##$(g.uuid)@#The group $(name) has been updated"
				ifvarclass => "groupmanagement_group_add_$(index)_repaired.!(groupmanagement_group_add_$(index)_kept|groupmanagement_group_add_$(index)_error)";

			"@@groupManagement@@result_error@@$(directiveId)@@Groups@@$(name)@@$(g.execRun)##$(g.uuid)@#The group $(name) could not be created or updated"
				ifvarclass => "groupmanagement_group_add_$(index)_error";

      "@@groupManagement@@result_success@@${directiveId}@@Groups@@${name}@@${g.execRun}##${g.uuid}@#The group ${name} is not present and not set to be created"
        ifvarclass => "groupmanagement_group_${index}_absent.!groupmanagement_group_${index}_create";
}

bundle edit_line groups_file_append(group,userlist)
{

vars:

	"finalgroup" string => join(",","userlist");

field_edits:

	"$(group):.*"

	# Set field of the file to parameter
	# /etc/group entry is: groupname:x:gid:users
	edit_field => col(":","4","$(finalgroup)","set");

}
