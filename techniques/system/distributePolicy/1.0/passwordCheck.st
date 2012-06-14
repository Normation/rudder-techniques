#####################################################################################
# Copyright 2012 Normation SAS
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

bundle agent root_password_check {

	vars:

			# "no" int => getfields("RUDDER_PSQL_USERNAME:.*","/opt/rudder/etc/rudder-passwords.conf",":","psql_user");
			"no2" int => getfields("RUDDER_PSQL_PASSWORD:.*","/opt/rudder/etc/rudder-passwords.conf",":","psql_pass");

			# "no3" int => getfields("RUDDER_OPENLDAP_BIND_DN:.*","/opt/rudder/etc/rudder-passwords.conf",":","ldap_user");
			"no4" int => getfields("RUDDER_OPENLDAP_BIND_PASSWORD:.*","/opt/rudder/etc/rudder-passwords.conf",":","ldap_pass");

			# Build an array using these values

			"rudder[rudder.jdbc.password]" string => "$(psql_pass[2])";

			"rudder[ldap.authpw]" string => "$(ldap_pass[2])";

			"inventory[ldap.authpw]" string => "$(ldap_pass[2])";

			# I think it is not advisable to change the logins in this Technique, as it would go far further a plain password update. We really risk breaking things.
			# But, just in case, I will leave this here if somebody desires to do so.
			# "slapd[rootdn]" string => "$(ldap_user[2])";

			"slapd[rootpw]" string => "$(ldap_pass[2])"; # Looks like a bug, I can not use execresult("/opt/rudder/sbin/slappasswd -s $(ldap_pass[2])","noshell");

	files:

			"$(g.rudder_base)/etc/rudder-passwords.conf"
				perms => mog("600", "root", "root");

			"$(g.rudder_base)/etc/rudder-web.properties"
				edit_line => set_variable_values("root_password_check.rudder"),
				classes => kept_if_else("rudder_web_password_integrity_ok", "rudder_web_password_integrity_changed", "rudder_web_password_integrity_failed"),
			        comment => "Verifying the Rudder Webapp properties file passwords and users";

			"$(g.rudder_base)/etc/inventory-web.properties"
				edit_line => set_variable_values("root_password_check.inventory"),
				classes => kept_if_else("rudder_inventory_password_integrity_ok", "rudder_inventory_password_integrity_changed", "rudder_inventory_password_integrity_failed"),
			        comment => "Verifying the inventory Webapp properties file passwords and users";

			"$(g.rudder_base)/etc/openldap/slapd.conf"
				edit_line => update_slapd("root_password_check.slapd"),
        			classes => kept_if_else("rudder_ldap_password_integrity_ok", "rudder_ldap_password_integrity_changed", "rudder_ldap_password_integrity_failed"),
			        comment => "Verifying the Rudder LDAP file password and user";

	commands:

		rudder_web_password_integrity_changed::

			"/usr/bin/psql -q -c \"ALTER USER rudder WITH PASSWORD '$(psql_pass[2])'\"",
				contain => setuid_sh("postgres"),
				classes => if_else("postgres_updated", "postgres_update_failed");

		postgres_updated::

			"/etc/init.d/postgresql restart"
				contain => in_shell,
				classes => if_else("postgresql_restarted", "postgresql_restart_failed");

		(rudder_ldap_password_integrity_changed|rudder_web_password_integrity_changed|rudder_inventory_password_integrity_changed)::

			"/etc/init.d/slapd restart"
				contain => in_shell,
				classes => if_else("slapd_restarted", "slapd_restart_failed");

		(postgresql_restarted|slapd_restarted)::

			"/etc/init.d/jetty restart </dev/null >/dev/null 2>/dev/null"
				contain => in_shell,
				classes => if_else("jetty_restarted", "jetty_restart_failed");

	reports:

		linux::

			"@@DistributePolicy@@result_success@@&TRACKINGKEY&@@reports@@None@@$(g.execRun)##$(g.uuid)@#The Rudder Webapp configuration file is OK"
				ifvarclass => "(rudder_web_password_integrity_ok.rudder_inventory_password_integrity_ok).!(rudder_web_password_integrity_changed|rudder_inventory_password_integrity_changed).!(rudder_web_password_integrity_failed|rudder_inventory_password_integrity_failed)";

			"@@DistributePolicy@@result_repaired@@&TRACKINGKEY&@@reports@@None@@$(g.execRun)##$(g.uuid)@#The Rudder Webapp configuration file was updated"
				ifvarclass => "(rudder_web_password_integrity_changed|rudder_inventory_password_integrity_changed).!(rudder_web_password_integrity_failed|rudder_inventory_password_integrity_failed)";

			"@@DistributePolicy@@result_error@@&TRACKINGKEY&@@reports@@None@@$(g.execRun)##$(g.uuid)@#The Rudder Webapp configuration file could not be updated"
				ifvarclass => "rudder_web_password_integrity_failed|rudder_inventory_password_integrity_failed";

			"@@DistributePolicy@@log_info@@&TRACKINGKEY&@@reports@@None@@$(g.execRun)##$(g.uuid)@#Postgresql has been restarted"
				ifvarclass => "postgresql_restarted";

			"@@DistributePolicy@@log_info@@&TRACKINGKEY&@@reports@@None@@$(g.execRun)##$(g.uuid)@#Slapd has been restarted"
				ifvarclass => "slapd_restarted";

			"@@DistributePolicy@@log_info@@&TRACKINGKEY&@@reports@@None@@$(g.execRun)##$(g.uuid)@#Jetty has been restarted"
				ifvarclass => "jetty_restarted";

}

bundle edit_line update_slapd(tab) {

vars:

	"index" slist => getindices("$(tab)");

delete_lines:

	"$(index).*";

insert_lines:

	"$(index)		$($(tab)[$(index)])" location => after("^rootdn.*");

}
