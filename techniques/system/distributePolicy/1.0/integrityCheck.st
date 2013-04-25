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

                        "$(g.rudder_var)/configuration-repository"
                                create => "true",
                                action => WarnOnly,
                                classes => if_else("rudder_integrity_ok", "rudder_integrity_failed");

    "${g.rudder_var}/configuration-repository/.git/index.lock"
      delete       => tidy,
      file_select  => rudder_common_minutes_old("5"),
      classes      => rudder_common_classes("rudder_git_lock"");
      comment      => "Delete the git locking file in the configuration-repository if older than 5 minutes";

	reports:

		linux::

			"@@DistributePolicy@@result_success@@&TRACKINGKEY&@@Check configuration-repository folder@@None@@$(g.execRun)##$(g.uuid)@#The $(g.rudder_var)/configuration-repository directory is present"
				ifvarclass => "rudder_integrity_ok.!rudder_integrity_failed";

			"@@DistributePolicy@@result_error@@&TRACKINGKEY&@@Check configuration-repository folder@@None@@$(g.execRun)##$(g.uuid)@#EMERGENCY: THE $(g.rudder_var)/configuration-repository DIRECTORY IS *ABSENT*. THIS ORCHESTRATOR WILL *NOT* OPERATE CORRECTLY."
				ifvarclass => "!rudder_integrity_ok|rudder_integrity_failed";

    rudder_git_lock_kept.!rudder_git_lock_repaired.!rudder_git_lock_failed::
      "@@DistributePolicy@@result_success@@&TRACKINGKEY&@@Check configuration-repository GIT lock@@None@@$(g.execRun)##$(g.uuid)@#The $(g.rudder_var)/configuration-repository GIT lock file is not present or not older than 5 minutes";

    rudder_git_lock_repaired.!rudder_git_lock_failed::
      "@@DistributePolicy@@result_repaired@@&TRACKINGKEY&@@Check configuration-repository GIT lock@@None@@$(g.execRun)##$(g.uuid)@#WARNING: THE $(g.rudder_var)/configuration-repository GIT LOCK FILE WAS OLDER THAN 5 MINUTES AND HAS BEEN DELETED";

    rudder_git_lock_failed::
      "@@DistributePolicy@@result_error@@&TRACKINGKEY&@@Check configuration-repository GIT lock@@None@@$(g.execRun)##$(g.uuid)@#TheEMERGENCY: THE $(g.rudder_var)/configuration-repository GIT LOCK FILE IS OLDER THAN 5 MINUTES AND COULD NOT BE DELETED. THIS ORCHESTRATOR WILL *NOT* OPERATE CORRECTLY.";

}
