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

# Configures AutoFS map files

bundle agent rudder_autofs_mount_point_configuration(technique_name, mnt_type)
{
  files:
    any::
      "${rudder_autofs_master.map_file[$(mnt_type)]}"
        edit_defaults => empty,
        edit_line     => rudder_autofs_mount_point_edit_map("${mnt_type}"),
        create        => "true",
        classes       => kept_if_else(
                           "rudder_autofs_mount_point_configuration_${mnt_type}_kept",
                           "rudder_autofs_mount_point_configuration_${mnt_type}_repaired",
                           "rudder_autofs_mount_point_configuration_${mnt_type}_failed"
                           ),
        comment       => "Apply all config changes to AutoFS ${mnt_type} map file";
}
