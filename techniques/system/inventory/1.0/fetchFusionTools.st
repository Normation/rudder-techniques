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

############################################################
# Fetch PERL and Curl
############################################################

bundle agent fetchFusionTools
{
  methods:
    debian|redhat::
      "any" usebundle => package_present("curl", "", "", "");

    package_present_curl_error::
      "any" usebundle => rudder_common_report("Inventory", "result_error", "&TRACKINGKEY&", "inventory", "None", "Installing 'curl' failed. Inventory registration will fail if curl is unavailable");
}

body perms myperms
{
        mode => "0700";
}
