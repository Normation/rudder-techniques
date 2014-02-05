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

# This technique installs and configures AutoFS, see metadata.xml for details.

bundle agent rudder_autofs_master
{
  vars:
    any::
      "technique_name" string => "AutoFS Master";
      "bundles" slist => {
        "rudder_autofs_master_installation",
        "rudder_autofs_master_installation_reporting",
        "rudder_autofs_master_configuration",
        "rudder_autofs_master_configuration_reporting",
        };

      # Configuration variables
      "master_file" string => "&AUTOFS_MASTER_CONFFILE&";
      "map_file[direct]" string => "&AUTOFS_MASTER_MANAGED_DIRECT_MAP_FILE&";
      "map_file[indirect]" string => "&AUTOFS_MASTER_MANAGED_INDIRECT_MAP_FILE&";
      "indirect_mount_root" string => "&AUTOFS_MASTER_MANAGED_INDIRECT_MOUNT_ROOT&";

  methods:
    "method ${bundles}" usebundle => ${bundles}("${technique_name}");
}

bundle agent rudder_autofs_master_installation_reporting(technique_name)
{
  reports:
    rudder_autofs_master_installation_kept::
      "@@AutoFSMaster@@result_success@@&TRACKINGKEY&@@${technique_name} installation@@None@@$(g.execRun)##$(g.uuid)@#The ${technique_name} packages were already installed";

    rudder_autofs_master_installation_repaired::
      "@@AutoFSMaster@@result_repaired@@&TRACKINGKEY&@@${technique_name} installation@@None@@$(g.execRun)##$(g.uuid)@#The ${technique_name} packages were installed";

    rudder_autofs_master_installation_failed::
      "@@AutoFSMaster@@result_error@@&TRACKINGKEY&@@${technique_name} installation@@None@@$(g.execRun)##$(g.uuid)@#Can't install ${technique_name} packages";
}

bundle agent rudder_autofs_master_configuration_reporting(technique_name)
{
  reports:
    rudder_autofs_master_configuration_kept.!(rudder_autofs_master_configuration_repaired|rudder_autofs_master_configuration_failed)::
      "@@AutoFSMaster@@result_success@@&TRACKINGKEY&@@${technique_name} configuration@@None@@$(g.execRun)##$(g.uuid)@#${technique_name} configuration is already compliant";

    rudder_autofs_master_configuration_repaired.!rudder_autofs_master_configuration_failed::
      "@@AutoFSMaster@@result_repaired@@&TRACKINGKEY&@@${technique_name} configuration@@None@@$(g.execRun)##$(g.uuid)@#${technique_name} configuration repaired";

    rudder_autofs_master_configuration_failed::
      "@@AutoFSMaster@@result_error@@&TRACKINGKEY&@@${technique_name} configuration@@None@@$(g.execRun)##$(g.uuid)@#Failed to repair ${technique_name} configuration";
}
