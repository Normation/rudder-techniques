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

###############################################################
# Installs SSH, and checks wether it is started on boot or not.


bundle agent check_ssh_installation {

	packages:
		(debian|redhat)::
			"openssh-server"
				package_policy  => "add",
				package_method  => rudder_generic,
				classes => kept_if_else("ssh_here", "ssh_installed", "cant_install_ssh"),
				comment => "Installing ssh using generic interface";

		SuSE::
			"openssh"
				package_policy  => "add",
				package_method  => rudder_generic,
				classes => kept_if_else("ssh_here", "ssh_installed", "cant_install_ssh"),
				comment => "Installing ssh using generic interface";

	reports:
		ssh_here::
			"@@sshConfiguration@@result_success@@&TRACKINGKEY&@@SSH installation@@None@@$(g.execRun)##$(g.uuid)@#The SSH package was already installed";

		ssh_installed::
			"@@sshConfiguration@@result_repaired@@&TRACKINGKEY&@@SSH installation@@None@@$(g.execRun)##$(g.uuid)@#The SSH package was installed";

		cant_install_ssh::
			"@@sshConfiguration@@result_error@@&TRACKINGKEY&@@SSH installation@@None@@$(g.execRun)##$(g.uuid)@#Can't install the SSH package";
}
