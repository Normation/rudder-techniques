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

# Define variables with locations of unmanaged maps

bundle agent rudder_autofs_unmanaged_map
{
  vars:
    any::
      &AUTOFS_UNMANAGED_MAP_MOUNT_POINT: {mntpoint |"mount_point[&i&]" string => "&mntpoint&";
}&
      &AUTOFS_UNMANAGED_MAP_MOUNT_MAP: {mntmap |"mount_map[&i&]" string => "&mntmap&";
}&
      &AUTOFS_UNMANAGED_MAP_MOUNT_OPTIONS: {mntopts |"mount_options[&i&]" string => "&mntopts&";
}&

      # for reports
      "technique_name" string => "AutoFS unmanaged map";
      &TRACKINGKEY:{directiveId |"uuid[&i&]" string => "&directiveId&";
}&
      "uuid_index" slist => getindices("uuid");

  reports:
    a|!a::
      "@@AutoFSUnmanagedMap@@result_success@@${uuid[$(uuid_index)]}@@${technique_name} mount points@@${mount_map[$(uuid_index)]}@@$(g.execRun)##$(g.uuid)@#${technique_name} defined for $(mount_map[$(uuid_index)])";
}
