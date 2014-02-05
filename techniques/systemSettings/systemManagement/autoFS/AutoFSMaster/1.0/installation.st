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

# Installs AutoFS

bundle agent rudder_autofs_master_installation(technique_name)
{
  packages:
    debian|redhat::
      "autofs"
        package_policy => "add",
        package_method => generic,
        classes        => kept_if_else(
                            "rudder_autofs_master_installation_kept",
                            "rudder_autofs_master_installation_repaired",
                            "rudder_autofs_master_installation_failed"
                            ),
        comment        => "Installing AutoFS using generic method";
}
