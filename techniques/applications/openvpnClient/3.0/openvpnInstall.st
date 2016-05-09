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

    any::
      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";

  packages:
    linux.!SuSE::
      "openvpn"
        package_policy  => "add",
        package_method  => generic,
        classes => kept_if_else("openvpn_here", "openvpn_installed", "cant_install_openvpn"),
        comment => "Installing openvpn using generic interface";

  methods:
    pass3.((openvpn_here|openvpn_present))::
      "any" usebundle => rudder_common_report("openvpnConfiguration", "result_success", "&TRACKINGKEY&", "OpenVPN install", "None", "openvpn already installed");

    pass3.openvpn_installed::
      "any" usebundle => rudder_common_report("openvpnConfiguration", "result_repaired", "&TRACKINGKEY&", "OpenVPN install", "None", "openvpn installed");

    pass3.cant_install_openvpn::
      "any" usebundle => rudder_common_report("openvpnConfiguration", "result_error", "&TRACKINGKEY&", "OpenVPN install", "None", "Can't install openvpn");

    pass3.(!linux)::
      "any" usebundle => rudder_common_report("openvpnConfiguration", "result_success", "&TRACKINGKEY&", "OpenVPN install", "None", "Support to check if openvpn is installed not available on this platform");

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

}
