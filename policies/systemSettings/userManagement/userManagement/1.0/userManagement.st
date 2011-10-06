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

	methods:

		"any"

			usebundle => check_usergroup_user_parameters_userhandle("$(usergroup_user_login[$(usergroup_user_index)])", "$(usergroup_user_fullname[$(usergroup_user_index)])", "$(usergroup_user_password[$(usergroup_user_index)])", "$(usergroup_user_password_policy[$(usergroup_user_index)])", "$(usergroup_user_action[$(usergroup_user_index)])", "$(usergroup_user_home_perso[$(usergroup_user_index)])", "$(usergroup_user_home[$(usergroup_user_index)])", "$(usergroup_user_shell[$(usergroup_user_index)])", "$(usergroup_policy_instance_uuid[$(usergroup_user_index)])");

}

bundle agent check_usergroup_user_parameters_userhandle(login, name, password, passwordpolicy, action, homeperso, home, shell, piuuid) {

	# I'd really like to do that and stream the password directly to useradd, but cfengine does not currently permits the use of crypt in hash()
	#vars:
	#
	#	"pwcrypt" string => hash("$(password)","crypt");

	classes:

		# Actions

		"user_update" expression => strcmp("$(action)","add");

		"user_remove" expression => strcmp("$(action)","remove");

		"user_checkpres" expression => strcmp("$(action)","checkhere");

		"user_checkabs" expression => strcmp("$(action)","checknothere");

		"user_pershome" not => strcmp("$(homeperso)","true");

		"user_exists" expression => userexists("$(login)");

		"user_pwoneshot" expression => strcmp("$(passwordpolicy)","oneshot");

		"user_pweverytime" expression => strcmp("$(passwordpolicy)","everytime");

	commands:

		!user_exists.user_update.windows::

			"\"${sys.winsysdir}\net.exe\""
				args => "USER $(login) $(password) /ADD /FULLNAME:\"$(name)\"",
				classes => cf2_if_else("login_added", "login_add_failed"),
				comment => "Create the user";

		user_exists.user_remove.windows::

			"\"${sys.winsysdir}\net.exe\""
				args => "USER $(login) /DELETE",
				classes => cf2_if_else("login_removed", "login_remove_failed"),
				comment => "Create the user";

		(login_added.user_pwoneshot.windows)|(user_exists.user_pweverytime.windows)::

			"\"${sys.winsysdir}\net.exe\""
				args => "USER $(login) $(password)";

		!user_exists.user_update.!user_pershome.linux::

			"/usr/sbin/useradd"
				args => "-m -c \"$(name)\" -s $(shell) $(login)",
				classes => cf2_if_else("login_added", "login_add_failed"),
				comment => "Create the user";

		!user_exists.user_update.user_pershome.linux::

			"/usr/sbin/useradd"
				args => "-m -c \"$(name)\" -s $(shell) -d $(home) $(login)",
				classes => cf2_if_else("login_added", "login_add_failed"),
				comment => "Create the user";

		login_added.user_pwoneshot.linux::

			"/bin/echo -e \"$(password)\n$(password)\" | /usr/bin/passwd $(login)"
				contain => in_shell;


		user_exists.user_pweverytime.linux::

			"/bin/echo -e \"$(password)\n$(password)\" | /usr/bin/passwd $(login)"
				contain => in_shell;

		user_exists.user_remove.linux::

			"/usr/sbin/userdel"
				args => "$(login)",
				classes => cf2_if_else("login_removed", "login_remove_failed"),
				comment => "Delete the user";

	reports:

		!user_exists.user_update.login_added::
			"@@userGroupManagement@@result_repaired@@$(piuuid)@@Users@@$(login)@@$(g.execRun)##$(g.uuid)@#The user $(login) ( $(name) ) has been added to the system";

		!user_exists.user_update.login_add_failed::
			"@@userGroupManagement@@result_error@@$(piuuid)@@Users@@$(login)@@$(g.execRun)##$(g.uuid)@#The user $(login) ( $(name) ) could not be added to the system";

		user_exists.user_remove.login_removed::
			"@@userGroupManagement@@result_repaired@@$(piuuid)@@Users@@$(login)@@$(g.execRun)##$(g.uuid)@#The user $(login) ( $(name) ) has been removed from the system";

		user_exists.user_remove.login_remove_failed::
			"@@userGroupManagement@@result_error@@$(piuuid)@@Users@@$(login)@@$(g.execRun)##$(g.uuid)@#The user $(login) ( $(name) ) could not be removed from the system";

		!user_exists.user_remove::
			"@@userGroupManagement@@result_success@@$(piuuid)@@Users@@$(login)@@$(g.execRun)##$(g.uuid)@#The user $(login) ( $(name) ) does not exist, as required";

		user_exists.user_update::
			"@@userGroupManagement@@result_success@@$(piuuid)@@Users@@$(login)@@$(g.execRun)##$(g.uuid)@#The user $(login) ( $(name) ) is already present on the system";

		user_exists.user_checkabs::
			"@@userGroupManagement@@log_warn@@$(piuuid)@@Users@@$(login)@@$(g.execRun)##$(g.uuid)@#The user $(login) ( $(name) ) is present on the system, which violates the non presence policy";

		!user_exists.user_checkabs::
			"@@userGroupManagement@@result_success@@$(piuuid)@@Users@@$(login)@@$(g.execRun)##$(g.uuid)@#The user $(login) ( $(name) ) is not present on the system, which is in accordance with the non presence policy";

		user_exists.user_checkpres::
			"@@userGroupManagement@@result_success@@$(piuuid)@@Users@@$(login)@@$(g.execRun)##$(g.uuid)@#The user $(login) ( $(name) ) is present on the system, which is in conformance with the presence policy";

		!user_exists.user_checkpres::
			"@@userGroupManagement@@log_warn@@$(piuuid)@@Users@@$(login)@@$(g.execRun)##$(g.uuid)@#The user $(login) ( $(name) ) is not present on the system, which violates the presence policy";

}
