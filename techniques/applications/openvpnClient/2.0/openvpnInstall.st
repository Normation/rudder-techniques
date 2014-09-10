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

####################
# Installs OpenVPN #
####################

bundle agent check_openvpn_installation
{

  classes:
      "openvpn_present" expression => fileexists("/etc/init.d/openvpn");

  packages:
    (debian|redhat)::
      "openvpn"
        package_policy  => "add",
        package_method  => generic,
        classes => kept_if_else("openvpn_here", "openvpn_installed", "cant_install_openvpn"),
        comment => "Installing openvpn using generic interface";

  commands:
    SuSE.!openvpn_present.64_bit::
      "/bin/rpm"
        args => "-Uvh ${g.rudder_var}/tools/openvpn-2.2.1-1.x86_64.rpm",
        classes => kept_if_else("openvpn_here", "openvpn_installed", "cant_install_openvpn"),
        comment => "Installing openvpn using plain RPM";

    SuSE.!openvpn_present.32_bit::
      "/bin/rpm"
        args => "-Uvh ${g.rudder_var}/tools/openvpn-2.2.1-1.i686.rpm",
        classes => kept_if_else("openvpn_here", "openvpn_installed", "cant_install_openvpn"),
        comment => "Installing openvpn using plain RPM";

  reports:
    (openvpn_here|openvpn_present)::
      "@@openvpnConfiguration@@result_success@@&TRACKINGKEY&@@OpenVPN install@@None@@${g.execRun}##${g.uuid}@#openvpn already installed";

    openvpn_installed::
      "@@openvpnConfiguration@@result_repaired@@&TRACKINGKEY&@@OpenVPN install@@None@@${g.execRun}##${g.uuid}@#openvpn installed";

    cant_install_openvpn::
      "@@openvpnConfiguration@@result_error@@&TRACKINGKEY&@@OpenVPN install@@None@@${g.execRun}##${g.uuid}@#Can't install openvpn";

}
