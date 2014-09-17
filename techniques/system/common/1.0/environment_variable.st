#####################################################################################
# Copyright 2014 Normation SAS
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

bundle agent get_environment_variable
{
  vars:
    !windows::
      "script" string => "#! /bin/sh
env | sed 's/^/=/'";

  files:
    !windows::
      "${sys.workdir}/module/env"
        create        => "true",
        perms         => mog("755", "root", "0"),
        edit_line     => insert_lines("${script}"),
        edit_defaults => empty;
        
  commands:
    !windows::
      "${sys.workdir}/module/env"
        module => "true";
}
