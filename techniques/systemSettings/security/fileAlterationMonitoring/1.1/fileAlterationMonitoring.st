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


bundle agent file_alteration_monitor
{

  vars:

      &MONITOR_ENTITY_NAME:{name |"monitor_entity[&i&][name]" string => "&name&";
}&
      &TRACKINGKEY:{uuid |"monitor_entity[&i&][uuid]" string => "&uuid&";
}&
      "index" slist => getindices("monitor_entity");

  classes:

      "isfile_${index}" expression => isplain("${monitor_entity[${index}][name]}");
      "isdir_${index}" expression  => isdir("${monitor_entity[${index}][name]}");

      # Should the file reports an error if the file does not exist ?
      &MONITOR_NOFILE_BEHAVIOR:{ nofile | "nofile_reports_error_&i&" expression  => strcmp("&nofile&", "true"); 
}&


  files:

      "${monitor_entity[${index}][name]}"

        ifvarclass => "isdir_${index}",
        changes => detect_all_change,
        classes => kept_if_else("${index}_kept", "${index}_changed", "${index}_error"),
        depth_search => recurse("inf");

      "${monitor_entity[${index}][name]}"

        ifvarclass => "isfile_${index}",
        changes => detect_all_change,
        classes => kept_if_else("${index}_kept", "${index}_changed", "${index}_error");


  reports:

    linux|windows::

      "@@fileAlterationMonitoring@@result_success@@${monitor_entity[${index}][uuid]}@@File or directory to monitor@@${monitor_entity[${index}][name]}@@${g.execRun}##${g.uuid}@#The content of ${monitor_entity[${index}][name]} is consistent"
        ifvarclass => "${index}_kept";

      "@@fileAlterationMonitoring@@result_repaired@@${monitor_entity[${index}][uuid]}@@File or directory to monitor@@${monitor_entity[${index}][name]}@@${g.execRun}##${g.uuid}@#The content of ${monitor_entity[${index}][name]} is INCONSISTENT: Either the file has changed or one of the elements in the directory has"
        ifvarclass => "${index}_changed";

      "@@fileAlterationMonitoring@@result_error@@${monitor_entity[${index}][uuid]}@@File or directory to monitor@@${monitor_entity[${index}][name]}@@${g.execRun}##${g.uuid}@#The content of ${monitor_entity[${index}][name]} could not be checked"
        ifvarclass => "${index}_error";

      "@@fileAlterationMonitoring@@result_error@@${monitor_entity[${index}][uuid]}@@File or directory to monitor@@${monitor_entity[${index}][name]}@@${g.execRun}##${g.uuid}@#The entity ${monitor_entity[${index}][name]} does not exist: alteration monitoring was forced but impossible"
        ifvarclass => "!(isdir_${index}|isfile_${index}).!nofile_reports_error_${index}";

      "@@fileAlterationMonitoring@@result_success@@${monitor_entity[${index}][uuid]}@@File or directory to monitor@@${monitor_entity[${index}][name]}@@${g.execRun}##${g.uuid}@#No alteration monitoring is required for entity ${monitor_entity[${index}][name]}"
        ifvarclass => "!(isdir_${index}|isfile_${index}).nofile_reports_error_${index}";

      "@@fileAlterationMonitoring@@log_warn@@${monitor_entity[${index}][uuid]}@@File or directory to monitor@@${monitor_entity[${index}][name]}@@${g.execRun}##${g.uuid}@#The entity ${monitor_entity[${index}][name]} does not exist"
        ifvarclass => "!(isdir_${index}|isfile_${index}).nofile_reports_error_${index}";
}
