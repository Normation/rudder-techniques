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

# Configure mount points in auto.master file
bundle edit_line rudder_autofs_master_edit_master
{
  vars:
    any::
      "um_index" slist => getindices(
        "rudder_autofs_unmanaged_map.mount_point"
        );

  classes:
    "rudder_autofs_master_have_managed_maps"
      expression => isvariable("rudder_autofs_mount_point.technique_name");

    "rudder_autofs_master_have_unmanaged_maps"
      expression => isvariable("rudder_autofs_unmanaged_map.technique_name");

  insert_lines:
    any::

      "# Master Map for automounter
# This file has the following format:
# mount-point [map-type[,format]:]map [options]
# For details of the format look at auto.master(5).
#
# This file is managed by Rudder, any manual changes
# here will be lost.
#
# Process mounts specified in the following map files
";

    rudder_autofs_master_have_managed_maps::
      "/-  ${rudder_autofs_master.map_file[direct]}";
      "${rudder_autofs_master.indirect_mount_root}  ${rudder_autofs_master.map_file[indirect]}";

    rudder_autofs_master_have_unmanaged_maps::
      "$(rudder_autofs_unmanaged_map.mount_point[${um_index}])  $(rudder_autofs_unmanaged_map.mount_map[${um_index}])  $(rudder_autofs_unmanaged_map.mount_options[${um_index}])";
}
