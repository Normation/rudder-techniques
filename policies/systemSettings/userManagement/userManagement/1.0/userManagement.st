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

bundle agent check_usergroup_user_parameters {

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

		&USERGROUP_USER_HOME_PERSONNALIZE:{homeperso |"usergroup_user_home_perso[&i&]" string => "&homeperso&";
}&

		&USERGROUP_USER_HOME:{home |"usergroup_user_home[&i&]" string => "&home&";
}&

		&USERGROUP_USER_SHELL:{shell |"usergroup_user_shell[&i&]" string => "&shell&";
}&

		&TRACKINGKEY:{piuuid |"usergroup_policy_instance_uuid[&i&]" string => "&piuuid&";
}&

		"usergroup_user_index" slist => getindices("usergroup_user_login");


		any_2nd_pass::

			# Options to use whether Fullname is defined or not
			"nameopt[$(usergroup_user_index)]"
				string => "",
				ifvarclass => "usermanagement_user_nameempty_$(usergroup_user_index)";

			## On UNIX
			"nameopt[$(usergroup_user_index)]"
				string => "-c \"$(usergroup_user_fullname[$(usergroup_user_index)])\"",
				ifvarclass => "!usermanagement_user_nameempty_$(usergroup_user_index).!windows";

			## On Windows
			"nameopt[$(usergroup_user_index)]"
				string => "/FULLNAME:\"$(usergroup_user_fullname[$(usergroup_user_index)])\"",
				ifvarclass => "!usermanagement_user_nameempty_$(usergroup_user_index).windows";

			## Part of reports to return whether Fullname is defined or not
			"repname[$(usergroup_user_index)]"
				string => "Without any defined full name",
				ifvarclass => "usermanagement_user_nameempty_$(usergroup_user_index)";

			"repname[$(usergroup_user_index)]"
				string => "$(usergroup_user_fullname[$(usergroup_user_index)])",
				ifvarclass => "!usermanagement_user_nameempty_$(usergroup_user_index)";

	classes:

		# Actions

		"usermanagement_user_update_$(usergroup_user_index)" expression => strcmp("$(usergroup_user_action[$(usergroup_user_index)])","add");

		"usermanagement_user_remove_$(usergroup_user_index)" expression => strcmp("$(usergroup_user_action[$(usergroup_user_index)])","remove");

		"usermanagement_user_checkpres_$(usergroup_user_index)" expression => strcmp("$(usergroup_user_action[$(usergroup_user_index)])","checkhere");

		"usermanagement_user_checkabs_$(usergroup_user_index)" expression => strcmp("$(usergroup_user_action[$(usergroup_user_index)])","checknothere");

		"usermanagement_user_pershome_$(usergroup_user_index)" not => strcmp("$(usergroup_user_home_perso[$(usergroup_user_index)])","true");

		"usermanagement_user_exists_$(usergroup_user_index)" expression => userexists("$(usergroup_user_login[$(usergroup_user_index)])");

		"usermanagement_user_pwoneshot_$(usergroup_user_index)" expression => strcmp("$(usergroup_user_password_policy[$(usergroup_user_index)])","oneshot");

		"usermanagement_user_pweverytime_$(usergroup_user_index)" expression => strcmp("$(usergroup_user_password_policy[$(usergroup_user_index)])","everytime");

		"usermanagement_user_pwempty_$(usergroup_user_index)" not => isvariable("usergroup_user_password[$(usergroup_user_index)]");
		
		"usermanagement_user_nameempty_$(usergroup_user_index)" not => isvariable("usergroup_user_fullname[$(usergroup_user_index)]");

		# Class 'any' is executed before others classes defined.
		# Same as 'any' but execution will be after all classes defined
		"any_2nd_pass" expression => "any";

		"showtime" expression => isvariable("nameopt[1]");

	commands:

		windows.showtime::

			"\"${sys.winsysdir}\net.exe\""
				args => "USER $(usergroup_user_login[$(usergroup_user_index)]) $(usergroup_user_password[$(usergroup_user_index)]) /ADD $(nameopt[$(usergroup_user_index)])",
				classes => cf2_if_else("usermanagement_login_add_$(usergroup_user_index)_repaired", "usermanagement_login_add_$(usergroup_user_index)_error"),
				comment => "Create the user $(usergroup_user_login[$(usergroup_user_index)])",
				ifvarclass => "!usermanagement_user_exists_$(usergroup_user_index).usermanagement_user_update_$(usergroup_user_index)";

			"\"${sys.winsysdir}\net.exe\""
				args => "USER $(usergroup_user_login[$(usergroup_user_index)]) /DELETE",
				classes => cf2_if_else("usermanagement_login_remove_$(usergroup_user_index)_repaired", "usermanagement_login_remove_$(usergroup_user_index)_error"),
				comment => "Delete the user $(usergroup_user_login[$(usergroup_user_index)])",
				ifvarclass => "!usermanagement_user_exists_$(usergroup_user_index).usermanagement_user_remove_$(usergroup_user_index)";

			"\"${sys.winsysdir}\net.exe\""
				args => "USER $(usergroup_user_login[$(usergroup_user_index)]) $(usergroup_user_password[$(usergroup_user_index)])",
				ifvarclass => "(usermanagement_login_add_$(usergroup_user_index)_repaired.usermanagement_user_pwoneshot_$(usergroup_user_index).!usermanagement_user_pwempty_$(usergroup_user_index))|(usermanagement_user_exists_$(usergroup_user_index).usermanagement_user_pweverytime_$(usergroup_user_index).!usermanagement_user_pwempty_$(usergroup_user_index))";

		linux.showtime::

			"/usr/sbin/useradd"
				args => "-m $(nameopt[$(usergroup_user_index)]) -s $(usergroup_user_shell[$(usergroup_user_index)]) $(usergroup_user_login[$(usergroup_user_index)])",
				classes => cf2_if_else("usermanagement_login_add_$(usergroup_user_index)_repaired", "usermanagement_login_add_$(usergroup_user_index)_error"),
				comment => "Create the user",
				ifvarclass => "!usermanagement_user_exists_$(usergroup_user_index).usermanagement_user_update_$(usergroup_user_index).!usermanagement_user_pershome_$(usergroup_user_index)";

			"/usr/sbin/useradd"
				args => "-m $(nameopt[$(usergroup_user_index)]) -s $(usergroup_user_shell[$(usergroup_user_index)]) -d $(usergroup_user_home[$(usergroup_user_index)]) $(usergroup_user_login[$(usergroup_user_index)])",
				classes => cf2_if_else("usermanagement_login_add_$(usergroup_user_index)_repaired", "usermanagement_login_add_$(usergroup_user_index)_error"),
				comment => "Create the user",
				ifvarclass => "!usermanagement_user_exists_$(usergroup_user_index).usermanagement_user_update_$(usergroup_user_index).usermanagement_user_pershome_$(usergroup_user_index)";

			# Define password only at user creation
			"/bin/echo -e \"$(usergroup_user_password[$(usergroup_user_index)])\n$(usergroup_user_password[$(usergroup_user_index)])\" | /usr/bin/passwd $(usergroup_user_login[$(usergroup_user_index)])"
				contain => in_shell,
				ifvarclass => "usermanagement_login_add_$(usergroup_user_index)_repaired.usermanagement_user_pwoneshot_$(usergroup_user_index).!usermanagement_user_pwempty_$(usergroup_user_index)";

			# Define password when user has already been created
			"/bin/echo -e \"$(usergroup_user_password[$(usergroup_user_index)])\n$(usergroup_user_password[$(usergroup_user_index)])\" | /usr/bin/passwd $(usergroup_user_login[$(usergroup_user_index)])"
				contain => in_shell,
				ifvarclass => "usermanagement_user_update_$(usergroup_user_index).usermanagement_user_exists_$(usergroup_user_index).usermanagement_user_pweverytime_$(usergroup_user_index).!usermanagement_user_pwempty_$(usergroup_user_index)";

			"/usr/sbin/userdel"
				args => "$(usergroup_user_login[$(usergroup_user_index)])",
				classes => cf2_if_else("usermanagement_login_remove_$(usergroup_user_index)_repaired", "usermanagement_login_remove_$(usergroup_user_index)_error"),
				comment => "Delete the user",
				ifvarclass => "usermanagement_user_exists_$(usergroup_user_index).usermanagement_user_remove_$(usergroup_user_index)";

	reports:

		(linux|windows).showtime::

			# Add user
			## Does exist (Success)
			"@@userGroupManagement@@result_success@@$(usergroup_policy_instance_uuid[$(usergroup_user_index)])@@Users@@$(usergroup_user_login[$(usergroup_user_index)])@@$(g.execRun)##$(g.uuid)@#The user $(usergroup_user_login[$(usergroup_user_index)]) ( $(repname[$(usergroup_user_index)]) ) is already present on the system"
				ifvarclass => "usermanagement_user_exists_$(usergroup_user_index).usermanagement_user_update_$(usergroup_user_index).!usermanagement_login_add_$(usergroup_user_index)_repaired";

			## Added
			"@@userGroupManagement@@result_repaired@@$(usergroup_policy_instance_uuid[$(usergroup_user_index)])@@Users@@$(usergroup_user_login[$(usergroup_user_index)])@@$(g.execRun)##$(g.uuid)@#The user $(usergroup_user_login[$(usergroup_user_index)]) ( $(repname[$(usergroup_user_index)]) ) has been added to the system"
				ifvarclass => "!usermanagement_user_exists_$(usergroup_user_index).usermanagement_user_update_$(usergroup_user_index).usermanagement_login_add_$(usergroup_user_index)_repaired";

			## Error
			"@@userGroupManagement@@result_error@@$(usergroup_policy_instance_uuid[$(usergroup_user_index)])@@Users@@$(usergroup_user_login[$(usergroup_user_index)])@@$(g.execRun)##$(g.uuid)@#The user $(usergroup_user_login[$(usergroup_user_index)]) ( $(repname[$(usergroup_user_index)]) ) could not be added to the system"
				ifvarclass => "!usermanagement_user_exists_$(usergroup_user_index).usermanagement_user_update_$(usergroup_user_index).usermanagement_login_add_$(usergroup_user_index)_error";

			# Remove user
			## Does not exist(Success)
			"@@userGroupManagement@@result_success@@$(usergroup_policy_instance_uuid[$(usergroup_user_index)])@@Users@@$(usergroup_user_login[$(usergroup_user_index)])@@$(g.execRun)##$(g.uuid)@#The user $(usergroup_user_login[$(usergroup_user_index)]) ( $(repname[$(usergroup_user_index)]) ) does not exist, as required"
				ifvarclass => "!usermanagement_user_exists_$(usergroup_user_index).usermanagement_user_remove_$(usergroup_user_index)";

			## Removed
			"@@userGroupManagement@@result_repaired@@$(usergroup_policy_instance_uuid[$(usergroup_user_index)])@@Users@@$(usergroup_user_login[$(usergroup_user_index)])@@$(g.execRun)##$(g.uuid)@#The user $(usergroup_user_login[$(usergroup_user_index)]) ( $(repname[$(usergroup_user_index)]) ) has been removed from the system"
				ifvarclass => "usermanagement_user_exists_$(usergroup_user_index).usermanagement_user_remove_$(usergroup_user_index).usermanagement_login_remove_$(usergroup_user_index)_repaired";

			## Error
			"@@userGroupManagement@@result_error@@$(usergroup_policy_instance_uuid[$(usergroup_user_index)])@@Users@@$(usergroup_user_login[$(usergroup_user_index)])@@$(g.execRun)##$(g.uuid)@#The user $(usergroup_user_login[$(usergroup_user_index)]) ( $(repname[$(usergroup_user_index)]) ) could not be removed from the system"
				ifvarclass => "usermanagement_user_exists_$(usergroup_user_index).usermanagement_user_remove_$(usergroup_user_index).usermanagement_login_remove_$(usergroup_user_index)_error";

			# Check user exists
			## Does not exist (Success)
			"@@userGroupManagement@@result_success@@$(usergroup_policy_instance_uuid[$(usergroup_user_index)])@@Users@@$(usergroup_user_login[$(usergroup_user_index)])@@$(g.execRun)##$(g.uuid)@#The user $(usergroup_user_login[$(usergroup_user_index)]) ( $(repname[$(usergroup_user_index)]) ) is not present on the system, which is in accordance with the non presence policy"
				ifvarclass => "!usermanagement_user_exists_$(usergroup_user_index).usermanagement_user_checkabs_$(usergroup_user_index)";

			## Does not exist (Error)
			"@@userGroupManagement@@log_warn@@$(usergroup_policy_instance_uuid[$(usergroup_user_index)])@@Users@@$(usergroup_user_login[$(usergroup_user_index)])@@$(g.execRun)##$(g.uuid)@#The user $(usergroup_user_login[$(usergroup_user_index)]) ( $(repname[$(usergroup_user_index)]) ) is present on the system, which violates the non presence policy"
				ifvarclass => "usermanagement_user_exists_$(usergroup_user_index).usermanagement_user_checkabs_$(usergroup_user_index)";

			# Check user exists
			## Does exist (Success)
			"@@userGroupManagement@@result_success@@$(usergroup_policy_instance_uuid[$(usergroup_user_index)])@@Users@@$(usergroup_user_login[$(usergroup_user_index)])@@$(g.execRun)##$(g.uuid)@#The user $(usergroup_user_login[$(usergroup_user_index)]) ( $(repname[$(usergroup_user_index)]) ) is present on the system, which is in conformance with the presence policy"
				ifvarclass => "usermanagement_user_exists_$(usergroup_user_index).usermanagement_user_checkpres_$(usergroup_user_index)";

			## Does not exist (Error)
			"@@userGroupManagement@@log_warn@@$(usergroup_policy_instance_uuid[$(usergroup_user_index)])@@Users@@$(usergroup_user_login[$(usergroup_user_index)])@@$(g.execRun)##$(g.uuid)@#The user $(usergroup_user_login[$(usergroup_user_index)]) ( $(repname[$(usergroup_user_index)]) ) is not present on the system, which violates the presence policy"
				ifvarclass => "!usermanagement_user_exists_$(usergroup_user_index).usermanagement_user_checkpres_$(usergroup_user_index)";

}
