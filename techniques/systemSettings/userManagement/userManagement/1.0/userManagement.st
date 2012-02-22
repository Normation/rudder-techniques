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


		nos::

			"nameopt[$(usergroup_user_index)]"
				string => "",
				ifvarclass => "user_nameempty_$(usergroup_user_index)";

			"nameopt[$(usergroup_user_index)]"
				string => "-c \"$(usergroup_user_fullname[$(usergroup_user_index)])\"",
				ifvarclass => "!user_nameempty_$(usergroup_user_index).!windows";

			"nameopt[$(usergroup_user_index)]"
				string => "/FULLNAME:\"$(usergroup_user_fullname[$(usergroup_user_index)])\"",
				ifvarclass => "!user_nameempty_$(usergroup_user_index).windows";

			"repname[$(usergroup_user_index)]"
				string => "Without any defined full name",
				ifvarclass => "user_nameempty_$(usergroup_user_index)";

			"repname[$(usergroup_user_index)]"
				string => "$(usergroup_user_fullname[$(usergroup_user_index)])",
				ifvarclass => "!user_nameempty_$(usergroup_user_index)";

	classes:

		# Actions

		"user_update_$(usergroup_user_index)" expression => strcmp("$(usergroup_user_action[$(usergroup_user_index)])","add");

		"user_remove_$(usergroup_user_index)" expression => strcmp("$(usergroup_user_action[$(usergroup_user_index)])","remove");

		"user_checkpres_$(usergroup_user_index)" expression => strcmp("$(usergroup_user_action[$(usergroup_user_index)])","checkhere");

		"user_checkabs_$(usergroup_user_index)" expression => strcmp("$(usergroup_user_action[$(usergroup_user_index)])","checknothere");

		"user_pershome_$(usergroup_user_index)" not => strcmp("$(usergroup_user_home_perso[$(usergroup_user_index)])","true");

		"user_exists_$(usergroup_user_index)" expression => userexists("$(usergroup_user_login[$(usergroup_user_index)])");

		"user_pwoneshot_$(usergroup_user_index)" expression => strcmp("$(usergroup_user_password_policy[$(usergroup_user_index)])","oneshot");

		"user_pweverytime_$(usergroup_user_index)" expression => strcmp("$(usergroup_user_password_policy[$(usergroup_user_index)])","everytime");

		"user_pwempty_$(usergroup_user_index)" not => isvariable("usergroup_user_password[$(usergroup_user_index)]");
		
		"user_nameempty_$(usergroup_user_index)" not => isvariable("usergroup_user_fullname[$(usergroup_user_index)]");

		"nos" expression => "any";

		"showtime" expression => isvariable("nameopt[1]");

	commands:

		windows.showtime::

			"\"${sys.winsysdir}\net.exe\""
				args => "USER $(usergroup_user_login[$(usergroup_user_index)]) $(usergroup_user_password[$(usergroup_user_index)]) /ADD $(nameopt[$(usergroup_user_index)])",
				classes => cf2_if_else("login_added_$(usergroup_user_index)", "login_add_failed_$(usergroup_user_index)"),
				comment => "Create the user",
				ifvarclass => "!user_exists_$(usergroup_user_index).user_update_$(usergroup_user_index)";

			"\"${sys.winsysdir}\net.exe\""
				args => "USER $(usergroup_user_login[$(usergroup_user_index)]) /DELETE",
				classes => cf2_if_else("login_removed_$(usergroup_user_index)", "login_remove_failed_$(usergroup_user_index)"),
				comment => "Create the user",
				ifvarclass => "!user_exists_$(usergroup_user_index).user_update_$(usergroup_user_index)";

			"\"${sys.winsysdir}\net.exe\""
				args => "USER $(usergroup_user_login[$(usergroup_user_index)]) $(usergroup_user_password[$(usergroup_user_index)])",
				ifvarclass => "(login_added_$(usergroup_user_index).user_pwoneshot_$(usergroup_user_index).!user_pwempty_$(usergroup_user_index))|(user_exists_$(usergroup_user_index).user_pweverytime_$(usergroup_user_index).!user_pwempty_$(usergroup_user_index))";

		linux.showtime::

			"/usr/sbin/useradd"
				args => "-m $(nameopt[$(usergroup_user_index)]) -s $(usergroup_user_shell[$(usergroup_user_index)]) $(usergroup_user_login[$(usergroup_user_index)])",
				classes => cf2_if_else("login_added_$(usergroup_user_index)", "login_add_failed_$(usergroup_user_index)"),
				comment => "Create the user",
				ifvarclass => "!user_exists_$(usergroup_user_index).user_update_$(usergroup_user_index).!user_pershome_$(usergroup_user_index)";

			"/usr/sbin/useradd"
				args => "-m $(nameopt[$(usergroup_user_index)]) -s $(usergroup_user_shell[$(usergroup_user_index)]) -d $(usergroup_user_home[$(usergroup_user_index)]) $(usergroup_user_login[$(usergroup_user_index)])",
				classes => cf2_if_else("login_added_$(usergroup_user_index)", "login_add_failed_$(usergroup_user_index)"),
				comment => "Create the user",
				ifvarclass => "!user_exists_$(usergroup_user_index).user_update_$(usergroup_user_index).user_pershome_$(usergroup_user_index)";

			"/bin/echo -e \"$(usergroup_user_password[$(usergroup_user_index)])\n$(usergroup_user_password[$(usergroup_user_index)])\" | /usr/bin/passwd $(usergroup_user_login[$(usergroup_user_index)])"
				contain => in_shell,
				ifvarclass => "login_added_$(usergroup_user_index).user_pwoneshot_$(usergroup_user_index).!user_pwempty_$(usergroup_user_index)";

			"/bin/echo -e \"$(usergroup_user_password[$(usergroup_user_index)])\n$(usergroup_user_password[$(usergroup_user_index)])\" | /usr/bin/passwd $(usergroup_user_login[$(usergroup_user_index)])"
				contain => in_shell,
				ifvarclass => "user_exists_$(usergroup_user_index).user_pweverytime_$(usergroup_user_index).!user_pwempty_$(usergroup_user_index)";

			"/usr/sbin/userdel"
				args => "$(usergroup_user_login[$(usergroup_user_index)])",
				classes => cf2_if_else("login_removed_$(usergroup_user_index)", "login_remove_failed_$(usergroup_user_index)"),
				comment => "Delete the user",
				ifvarclass => "user_exists_$(usergroup_user_index).user_remove_$(usergroup_user_index)";

	reports:

		(linux|windows).showtime::

			"@@userGroupManagement@@result_repaired@@$(usergroup_policy_instance_uuid[$(usergroup_user_index)])@@Users@@$(usergroup_user_login[$(usergroup_user_index)])@@$(g.execRun)##$(g.uuid)@#The user $(usergroup_user_login[$(usergroup_user_index)]) ( $(repname[$(usergroup_user_index)]) ) has been added to the system"
				ifvarclass => "!user_exists_$(usergroup_user_index).user_update_$(usergroup_user_index).login_added_$(usergroup_user_index)";

			"@@userGroupManagement@@result_error@@$(usergroup_policy_instance_uuid[$(usergroup_user_index)])@@Users@@$(usergroup_user_login[$(usergroup_user_index)])@@$(g.execRun)##$(g.uuid)@#The user $(usergroup_user_login[$(usergroup_user_index)]) ( $(repname[$(usergroup_user_index)]) ) could not be added to the system"
				ifvarclass => "!user_exists_$(usergroup_user_index).user_update_$(usergroup_user_index).login_add_failed_$(usergroup_user_index)";

			"@@userGroupManagement@@result_repaired@@$(usergroup_policy_instance_uuid[$(usergroup_user_index)])@@Users@@$(usergroup_user_login[$(usergroup_user_index)])@@$(g.execRun)##$(g.uuid)@#The user $(usergroup_user_login[$(usergroup_user_index)]) ( $(repname[$(usergroup_user_index)]) ) has been removed from the system"
				ifvarclass => "user_exists_$(usergroup_user_index).user_remove_$(usergroup_user_index).login_removed_$(usergroup_user_index)";

			"@@userGroupManagement@@result_error@@$(usergroup_policy_instance_uuid[$(usergroup_user_index)])@@Users@@$(usergroup_user_login[$(usergroup_user_index)])@@$(g.execRun)##$(g.uuid)@#The user $(usergroup_user_login[$(usergroup_user_index)]) ( $(repname[$(usergroup_user_index)]) ) could not be removed from the system"
				ifvarclass => "user_exists_$(usergroup_user_index).user_remove_$(usergroup_user_index).login_remove_failed_$(usergroup_user_index)";

			"@@userGroupManagement@@result_success@@$(usergroup_policy_instance_uuid[$(usergroup_user_index)])@@Users@@$(usergroup_user_login[$(usergroup_user_index)])@@$(g.execRun)##$(g.uuid)@#The user $(usergroup_user_login[$(usergroup_user_index)]) ( $(repname[$(usergroup_user_index)]) ) does not exist, as required"
				ifvarclass => "!user_exists_$(usergroup_user_index).user_remove_$(usergroup_user_index)";

			"@@userGroupManagement@@result_success@@$(usergroup_policy_instance_uuid[$(usergroup_user_index)])@@Users@@$(usergroup_user_login[$(usergroup_user_index)])@@$(g.execRun)##$(g.uuid)@#The user $(usergroup_user_login[$(usergroup_user_index)]) ( $(repname[$(usergroup_user_index)]) ) is already present on the system"
				ifvarclass => "user_exists_$(usergroup_user_index).user_update_$(usergroup_user_index).!login_added_$(usergroup_user_index)";

			"@@userGroupManagement@@log_warn@@$(usergroup_policy_instance_uuid[$(usergroup_user_index)])@@Users@@$(usergroup_user_login[$(usergroup_user_index)])@@$(g.execRun)##$(g.uuid)@#The user $(usergroup_user_login[$(usergroup_user_index)]) ( $(repname[$(usergroup_user_index)]) ) is present on the system, which violates the non presence policy"
				ifvarclass => "user_exists_$(usergroup_user_index).user_checkabs_$(usergroup_user_index)";

			"@@userGroupManagement@@result_success@@$(usergroup_policy_instance_uuid[$(usergroup_user_index)])@@Users@@$(usergroup_user_login[$(usergroup_user_index)])@@$(g.execRun)##$(g.uuid)@#The user $(usergroup_user_login[$(usergroup_user_index)]) ( $(repname[$(usergroup_user_index)]) ) is not present on the system, which is in accordance with the non presence policy"
				ifvarclass => "!user_exists_$(usergroup_user_index).user_checkabs_$(usergroup_user_index)";

			"@@userGroupManagement@@result_success@@$(usergroup_policy_instance_uuid[$(usergroup_user_index)])@@Users@@$(usergroup_user_login[$(usergroup_user_index)])@@$(g.execRun)##$(g.uuid)@#The user $(usergroup_user_login[$(usergroup_user_index)]) ( $(repname[$(usergroup_user_index)]) ) is present on the system, which is in conformance with the presence policy"
				ifvarclass => "user_exists_$(usergroup_user_index).user_checkpres_$(usergroup_user_index)";

			"@@userGroupManagement@@log_warn@@$(usergroup_policy_instance_uuid[$(usergroup_user_index)])@@Users@@$(usergroup_user_login[$(usergroup_user_index)])@@$(g.execRun)##$(g.uuid)@#The user $(usergroup_user_login[$(usergroup_user_index)]) ( $(repname[$(usergroup_user_index)]) ) is not present on the system, which violates the presence policy"
				ifvarclass => "!user_exists_$(usergroup_user_index).user_checkpres_$(usergroup_user_index)";

}
