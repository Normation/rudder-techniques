#####################################################################################
# Copyright 2011 Normation SAS
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

bundle agent internal_security
{
  vars:

    !windows::

      "mode"  string => "600";
      "user"  string => "root";
      "group" string => "0"; # This is "root" on most UNIX-like systems, but "system" on AIX

    #windows::

    #	"mode"  string => "755";
    #	"user"  string => "Administrator";
    #	"group" string => "Administrators";

  files:

    !windows::

      "${sys.workdir}/inputs"
        depth_search => recurse("inf"),
        perms        => mog("${mode}", "${user}", "${group}"),
        classes      => kept_if_else("security_sanitization_ok", "security_sanitization_repaired", "security_sanitization_failed");

      "${sys.workdir}/inputs"
        perms   => mog("${mode}", "${user}", "${group}"),
        classes => kept_if_else("security_sanitization_ok", "security_sanitization_repaired", "security_sanitization_failed");

      "${sys.workdir}/ppkeys"
        depth_search => recurse("inf"),
        perms        => mog("${mode}", "${user}", "${group}"),
        classes      => kept_if_else("security_sanitization_ok", "security_sanitization_repaired", "security_sanitization_failed");

      "${ys.workdir}/ppkeys"
        perms   => mog("${mode}", "${user}", "${group}"),
        classes => kept_if_else("security_sanitization_ok", "security_sanitization_repaired", "security_sanitization_failed");

  reports:

    security_sanitization_ok.!security_sanitization_repaired::
      "@@Common@@result_success@@&TRACKINGKEY&@@Security parameters@@None@@${g.execRun}##${g.uuid}@#The internal environment security is acceptable";

    security_sanitization_repaired::
      "@@Common@@result_repaired@@&TRACKINGKEY&@@Security parameters@@None@@${g.execRun}##${g.uuid}@#Some internal security parameters were adjusted";

    security_sanitization_failed::
      "@@Common@@result_error@@&TRACKINGKEY&@@Security parameters@@None@@${g.execRun}##${g.uuid}@#The internal environment security is NOT acceptable!";

    windows::
      "@@Common@@result_success@@&TRACKINGKEY&@@Security parameters@@None@@${g.execRun}##${g.uuid}@#No internal security parameters defined for Windows OSes yet";
}
