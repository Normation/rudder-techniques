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

#  Copyright (C) Normation

bundle agent check_ssh_key_distribution
{

classes:

	"begin_evaluation" expression => isvariable("sshkey_distribution_index");

		begin_evaluation::

			"index_$(sshkey_distribution_index)_exists" expression => userexists("$(sshkey_distribution_name[$(sshkey_distribution_index)])");

vars:

                &SSH_KEY_DISTRIBUTION_NAME:{distribution_name |"sshkey_distribution_name[&i&]" string => "&distribution_name&";
}&
                &SSH_KEY_DISTRIBUTION_KEY:{distribution_key |"sshkey_distribution_key[&i&]" string => "&distribution_key&";
}&
                &SSH_KEY_DISTRIBUTION_EDIT_TYPE:{distribution_edit_type |"sshkey_distribution_edit_type[&i&]" string => "&distribution_edit_type&";
}&
                &TRACKINGKEY:{uuid |"sshkey_distribution_uuid[&i&]" string => "&uuid&";
}&
                "sshkey_distribution_index" slist => getindices("sshkey_distribution_name");

		"no_$(sshkey_distribution_index)" int => getfields("$(sshkey_distribution_name[$(sshkey_distribution_index)]):.*","/etc/passwd",":","userdata_$(sshkey_distribution_index)");

files:

	linux.!SuSE::

		"$(userdata_$(sshkey_distribution_index)[6])/.ssh/."
			create => "true",
			ifvarclass => canonify("index_$(sshkey_distribution_index)_exists"),
			perms  => mog("700", "$(sshkey_distribution_name[$(sshkey_distribution_index)])", "$(sshkey_distribution_name[$(sshkey_distribution_index)])");

		"$(userdata_$(sshkey_distribution_index)[6])/.ssh/authorized_keys"
			create => "true",
			edit_defaults => rudder_empty_select("$(sshkey_distribution_edit_type[$(sshkey_distribution_index)])"),
			perms  => mog("600", "$(sshkey_distribution_name[$(sshkey_distribution_index)])", "$(sshkey_distribution_name[$(sshkey_distribution_index)])"),
			edit_line => insert_lines("$(sshkey_distribution_key[$(sshkey_distribution_index)])"),
			ifvarclass => canonify("index_$(sshkey_distribution_index)_exists"),
			classes => kept_if_else("line_$(sshkey_distribution_index)_ok","line_$(sshkey_distribution_index)_added","line_$(sshkey_distribution_index)_failed");

	SuSE::

		"$(userdata_$(sshkey_distribution_index)[6])/.ssh/."
			create => "true",
			ifvarclass => canonify("index_$(sshkey_distribution_index)_exists"),
			perms  => mog("700", "$(sshkey_distribution_name[$(sshkey_distribution_index)])", "users");

		"$(userdata_$(sshkey_distribution_index)[6])/.ssh/authorized_keys"
			create => "true",
			edit_defaults => rudder_empty_select("$(sshkey_distribution_edit_type[$(sshkey_distribution_index)])"),
			perms  => mog("600", "$(sshkey_distribution_name[$(sshkey_distribution_index)])", "users"),
			edit_line => insert_lines("$(sshkey_distribution_key[$(sshkey_distribution_index)])"),
			ifvarclass => canonify("index_$(sshkey_distribution_index)_exists"),
			classes => kept_if_else("line_$(sshkey_distribution_index)_ok","line_$(sshkey_distribution_index)_added","line_$(sshkey_distribution_index)_failed");

reports:

	linux::

		"@@sshKeyDistribution@@result_repaired@@$(sshkey_distribution_uuid[$(sshkey_distribution_index)])@@SSH key@@$(sshkey_distribution_name[$(sshkey_distribution_index)])@@$(g.execRun)##$(g.uuid)@#SSH key for user $(sshkey_distribution_name[$(sshkey_distribution_index)]) was put in place"
			ifvarclass => "line_$(sshkey_distribution_index)_added";

		"@@sshKeyDistribution@@result_success@@$(sshkey_distribution_uuid[$(sshkey_distribution_index)])@@SSH key@@$(sshkey_distribution_name[$(sshkey_distribution_index)])@@$(g.execRun)##$(g.uuid)@#SSH key for user $(sshkey_distribution_name[$(sshkey_distribution_index)]) was already present"
			ifvarclass => "line_$(sshkey_distribution_index)_ok.!line_$(sshkey_distribution_index)_added";

		"@@sshKeyDistribution@@result_error@@$(sshkey_distribution_uuid[$(sshkey_distribution_index)])@@SSH key@@$(sshkey_distribution_name[$(sshkey_distribution_index)])@@$(g.execRun)##$(g.uuid)@#SSH key for user $(sshkey_distribution_name[$(sshkey_distribution_index)]) could not be added"
			ifvarclass => "line_$(sshkey_distribution_index)_failed";

		"@@sshKeyDistribution@@result_error@@$(sshkey_distribution_uuid[$(sshkey_distribution_index)])@@SSH key@@$(sshkey_distribution_name[$(sshkey_distribution_index)])@@$(g.execRun)##$(g.uuid)@#The user $(sshkey_distribution_name[$(sshkey_distribution_index)]) does NOT exist on this machine, not adding SSH key"
			ifvarclass => "!index_$(sshkey_distribution_index)_exists";

}
