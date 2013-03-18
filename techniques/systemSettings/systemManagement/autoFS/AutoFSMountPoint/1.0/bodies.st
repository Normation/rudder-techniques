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

# Configure mount points in a map file
bundle edit_line rudder_autofs_mount_point_edit_map(mnt_type)
{
  vars:
    any::
      "index" slist => getindices("rudder_autofs_mount_point.mount_key");

  classes:
    "rudder_autofs_mount_point_edit_map_direct"
      expression => strcmp("${mnt_type}", "direct");

    # classify the mount points as direct or indirect (to only insert those
    # specified by mnt_type parameter); direct mount points start with /
    "rudder_autofs_mount_point_edit_map_key_${index}_direct"
      expression => regcmp("/.*",
                           "${rudder_autofs_mount_point.mount_key[$(index)]}");
    "rudder_autofs_mount_point_edit_map_key_${index}_indirect"
      not => classify("rudder_autofs_mount_point_edit_map_key_${index}_direct");

  insert_lines:
    rudder_autofs_mount_point_edit_map_direct::
      "# This is an automounter direct map and it has the following format
# /mount-point/key [-options] location
";

    !rudder_autofs_mount_point_edit_map_direct::
      "# This is an automounter indirect map and it has the following format
# key [-options] location
";

    any::
      "# For details of the format look at autofs(5).
#
# This file is managed by Rudder, any manual changes
# here will be lost.
#
";

      "$(rudder_autofs_mount_point.mount_key[${index}])  $(rudder_autofs_mount_point.mount_options[${index}])  $(rudder_autofs_mount_point.mount_location[${index}])"
        ifvarclass => "rudder_autofs_mount_point_edit_map_key_${index}_${mnt_type}";
}
