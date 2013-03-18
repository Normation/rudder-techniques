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

# This technique configures AutoFS mount points, see metadata.xml for details.

bundle agent rudder_autofs_mount_point
{
  vars:
    any::
      "technique_name" string => "AutoFS mount point";
      "bundles" slist => {
        "rudder_autofs_mount_point_configuration",
        "rudder_autofs_mount_point_reporting",
        };
      "mnt_types" slist => {"direct", "indirect"};

      &AUTOFS_MOUNT_POINT_KEY: {key |"mount_key[&i&]" string => "&key&";
}&
      &AUTOFS_MOUNT_POINT_OPTIONS: {opts |"mount_options[&i&]" string => "&opts&";
}&
      &AUTOFS_MOUNT_POINT_LOCATION: {loc |"mount_location[&i&]" string => "&loc&";
}&

  methods:
    "method ${bundles}(${mnt_types})"
      usebundle => ${bundles}("${technique_name}", "${mnt_types}");
}

bundle agent rudder_autofs_mount_point_reporting(technique_name, mnt_type)
{
  reports:

    a|!a::

      "@@AutoFSMountPoint@@result_success@@&TRACKINGKEY&@@AutoFS ${mnt_type} mounts configuration@@None@@$(g.execRun)##$(g.uuid)@#${technique_name} ${mnt_type} configuration is already compliant"
        ifvarclass => "rudder_autofs_mount_point_configuration_${mnt_type}_kept.!(rudder_autofs_mount_point_configuration_${mnt_type}_repaired|rudder_autofs_mount_point_configuration_${mnt_type}_failed)";

      "@@AutoFSMountPoint@@result_repaired@@&TRACKINGKEY&@@AutoFS ${mnt_type} mounts configuration@@None@@$(g.execRun)##$(g.uuid)@#${technique_name} ${mnt_type} configuration repaired"
        ifvarclass => "rudder_autofs_mount_point_configuration_${mnt_type}_repaired.!rudder_autofs_mount_point_configuration_${mnt_type}_failed";

      "@@AutoFSMountPoint@@result_error@@&TRACKINGKEY&@@AutoFS ${mnt_type} mounts configuration@@None@@$(g.execRun)##$(g.uuid)@#Failed to repair ${technique_name} ${mnt_type} configuration"
        ifvarclass => "rudder_autofs_mount_point_configuration_${mnt_type}_failed";
}
