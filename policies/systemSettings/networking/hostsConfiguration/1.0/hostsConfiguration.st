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

# (C) Normation 2011
#
# NOTE : I permitted the creation of the hosts file if absent, but on a purely
# functionnal side, its absence means a severe breakage of your IP stack. Be
# aware of this if a file creation is reported !
#

bundle agent check_hosts_configuration {

	vars:

		&HOSTS_HOST:{host |"hosts_host[&i&]" string => "&host&";
}&

		&HOSTS_IP:{ip |"hosts_ip[&i&]" string => "&ip&";
}&

	files:

		linux::

			"/etc/hosts"

				create => "true",
				perms => m("644"),
&if (HOSTS_ENFORCE)&
				edit_defaults => empty_backup,
&else&
				edit_defaults => noempty_backup,
&endif&

				edit_line => set_hosts_values("check_hosts_configuration.hosts_host", "check_hosts_configuration.hosts_ip"),
				classes => kept_if_else("hosts_edition_kept", "hosts_edition_done", "hosts_edition_failed");

		windows::

			"$(sys.winsysdir)\drivers\etc\hosts"

				create => "true",
				# perms => m("644"),
&if (HOSTS_ENFORCE)&
				edit_defaults => empty_backup,
&else&
				edit_defaults => noempty_backup,
&endif&

				edit_line => set_hosts_values("check_hosts_configuration.hosts_host", "check_hosts_configuration.hosts_ip"),
				classes => kept_if_else("hosts_edition_kept", "hosts_edition_done", "hosts_edition_failed");


	reports:

		(linux|windows)::
&if (HOSTS_ENFORCE)&
			"@@hostsConfiguration@@log_debug@@&TRACKINGKEY&@@hostsConfiguration@@None@@$(g.execRun)##$(g.uuid)@#Hosts file content enforcement requested";
&endif&

		hosts_edition_done::
			"@@hostsConfiguration@@result_repaired@@&TRACKINGKEY&@@hostsConfiguration@@None@@$(g.execRun)##$(g.uuid)@#Hosts file was updated";

		hosts_edition_kept.!hosts_edition_done::
			"@@hostsConfiguration@@result_success@@&TRACKINGKEY&@@hostsConfiguration@@None@@$(g.execRun)##$(g.uuid)@#Hosts file already OK";

		hosts_edition_failed::
			"@@hostsConfiguration@@result_error@@&TRACKINGKEY&@@hostsConfiguration@@None@@$(g.execRun)##$(g.uuid)@#Hosts file could not be edited";


}

bundle edit_line set_hosts_values(hosts, ips) {

vars:

	"hosts_index" slist => getindices("$(hosts)");

insert_lines:

&if (HOSTS_ENFORCE)&
	"127.0.0.1	localhost";
	"127.0.1.1	$(sys.host)";
	"##";
	"# The following lines are desirable for IPv6 capable hosts";
	"::1     localhost ip6-localhost ip6-loopback";
	"fe00::0 ip6-localnet";
	"ff00::0 ip6-mcastprefix";
	"ff02::1 ip6-allnodes";
	"ff02::2 ip6-allrouters";
	"ff02::3 ip6-allhosts";
	"###";
	"## Here follows all the rudder defined hosts :";
&endif&

	"$($(ips)[$(hosts_index)])	$($(hosts)[$(hosts_index)])";

}

