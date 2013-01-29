#####################################################################################
# Copyright 2011-2013 Normation SAS
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

#####################################################################################
# This Technique installs and configures OpenSSH. See metadata.xml for more details.
#####################################################################################

bundle agent rudder_android_system
{
  vars:
    "technique_name"
      string => "Android system management";

  methods:
    # Note:
    # The reporting is made on separate bundles to abstract the complexity
    # inherent to the normal ordering.
    "any" usebundle => rudder_android_system_configuration("${technique_name}");
    "any" usebundle => rudder_android_system_configuration_reporting("${technique_name}");
}
