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

bundle agent root_integrity_check {

  files:

      "${g.rudder_var}/configuration-repository"
        create => "true",
        action => WarnOnly,
        classes => if_else("rudder_integrity_ok", "rudder_integrity_failed");

  reports:

    linux::

      "@@DistributePolicy@@result_success@@&TRACKINGKEY&@@Check configuration-repository folder@@None@@${g.execRun}##${g.uuid}@#The ${g.rudder_var}/configuration-repository directory is present"
        ifvarclass => "rudder_integrity_ok.!rudder_integrity_failed";

      "@@DistributePolicy@@result_error@@&TRACKINGKEY&@@Check configuration-repository folder@@None@@${g.execRun}##${g.uuid}@#EMERGENCY: THE ${g.rudder_var}/configuration-repository DIRECTORY IS *ABSENT*. THIS ORCHESTRATOR WILL *NOT* OPERATE CORRECTLY."
        ifvarclass => "!rudder_integrity_ok|rudder_integrity_failed";

}
