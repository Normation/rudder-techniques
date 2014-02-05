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

# Configures AutoFS

bundle agent rudder_autofs_master_configuration(technique_name)
{
  files:
    any::
      "${rudder_autofs_master.master_file}"
        edit_defaults => empty,
        edit_line     => rudder_autofs_master_edit_master,
        create        => "true",
        classes       => kept_if_else(
                           "rudder_autofs_master_configuration_kept",
                           "rudder_autofs_master_configuration_repaired",
                           "rudder_autofs_master_configuration_failed"
                           ),
        comment       => "Apply all config changes to AutoFS master file";
}
