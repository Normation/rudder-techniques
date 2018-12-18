#####################################################################################
# Copyright 2018 Normation SAS
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


bundle agent job_scheduler_RudderUniqueID
{
  vars:

    &JOB_COMMAND:{command |"job_scheduler_command[&i&]" string => "&command&";
}&
    &JOB_TIMEOUT:{timeout |"job_scheduler_timeout[&i&]" string => "&timeout&";
}&
    &JOB_KEPTCODES:{keptcodes |"job_scheduler_keptcodes[&i&]" string => "&keptcodes&";
}&
    &JOB_REPAIRCODES:{repaircodes |"job_scheduler_repaircodes[&i&]" string => "&repaircodes&";
}&
    &JOB_ERRORCODES:{errorcodes |"job_scheduler_errorcodes[&i&]" string => "&errorcodes&";
}&
    &JOB_TIME_MIN:{mintime |"job_scheduler_time_min[&i&]" string => "&mintime&";
}&
    &JOB_TIME_MAX:{maxtime |"job_scheduler_time_max[&i&]" string => "&maxtime&";
}&
    &TRACKINGKEY:{uuid |"job_scheduler_uuids[&i&]" string => "&uuid&";
}&

      "iterator"                               slist => getindices("job_scheduler_uuids");

      "job_scheduler_canon_name[${iterator}]" string => canonify("${job_scheduler_command[${iterator}]}");


      
      "kept_returncodes_${iterator}"          slist => splitstring("${job_scheduler_keptcodes[${iterator}]}",",","128");

      "repaired_returncodes_${iterator}"      slist => splitstring("${job_scheduler_repaircodes[${iterator}]}",",","128");

      "error_returncodes_${iterator}"         slist => splitstring("${job_scheduler_errorcodes[${iterator}]}",",","128");

      "agent_run_interval"                   string => "5",
                                             unless => isvariable("g.agent_run_interval");

      "agent_run_interval"                   string => "${g.agent_run_interval}",
                                                 if => isvariable("g.agent_run_interval");

    pass1::
      "max_execution_delay_hours_real_${iterator}" string => eval("${job_scheduler_time_max[${iterator}]}-${job_scheduler_time_min[${iterator}]}", "math", "infix"),
                                               ifvarclass => "min_time_before_max_time_${iterator}";

      "max_execution_delay_hours_real_${iterator}" string => eval("24-${job_scheduler_time_min[${iterator}]}+${job_scheduler_time_max[${iterator}]}", "math", "infix"),
                                               ifvarclass => "!min_time_before_max_time_${iterator}";

      "max_execution_delay_hours_${iterator}" string => format("%d", "${max_execution_delay_hours_real_${iterator}}");

  classes:
      # we need to check if min time is greater than max time or not
      "min_time_before_max_time_${iterator}" expression => islessthan("${job_scheduler_time_min[${iterator}]}", "${job_scheduler_time_max[${iterator}]}");

    any::
      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";


  methods:
    pass2::
      # check if the job should run
      "schedule_${iterator}" usebundle => 
         schedule_simple("${job_scheduler_canon_name[${iterator}]}_RudderUniqueID", "${agent_run_interval}", 0, "${max_execution_delay_hours_${iterator}}", "0", "${job_scheduler_time_min[${iterator}]}", "0", "0", "24", "0", "nodups");


    pass3::
      # Note: if the command has not been executed (ever or since > frequency), no report will be sent until the splayclass is defined
      # This will cause Rudder to report an "Unknown" status, and is by design

      "any" usebundle => rudder_common_report_index("jobScheduler", "result_success", "${job_scheduler_uuids[${iterator}]}", "Job", "${job_scheduler_command[${iterator}]}", "Job returned a success return code after the last completed execution (${job_scheduler_command[${iterator}]})", "${iterator}"),
        ifvarclass => "${job_scheduler_canon_name[${iterator}]}_RudderUniqueID_kept";

      "any" usebundle => rudder_common_report_index("jobScheduler", "result_repaired", "${job_scheduler_uuids[${iterator}]}", "Job", "${job_scheduler_command[${iterator}]}", "Job returned a repaired return code on last completed execution (${job_scheduler_command[${iterator}]})", "${iterator}"),
        ifvarclass => "${job_scheduler_canon_name[${iterator}]}_RudderUniqueID_repaired";

      "any" usebundle => rudder_common_report_index("jobScheduler", "result_error", "${job_scheduler_uuids[${iterator}]}", "Job", "${job_scheduler_command[${iterator}]}", "Job failed on last completed execution (${job_scheduler_command[${iterator}]})", "${iterator}"),
        ifvarclass => "${job_scheduler_canon_name[${iterator}]}_RudderUniqueID_error";

      "any" usebundle => rudder_common_report_index("jobScheduler", "log_info", "${job_scheduler_uuids[${iterator}]}", "Job", "${job_scheduler_command[${iterator}]}", "Job has been launched (${job_scheduler_command[${iterator}]}), result will be reported on next run", "${iterator}"),
        ifvarclass => "schedule_simple_${job_scheduler_canon_name[${iterator}]}_RudderUniqueID_repaired.!job_scheduler_lock_${iterator}_RudderUniqueID",
        # we define here the persistent class, as the command exection is done on the last iteration
        comment    => "Define a persistent class to prevent multiple job executions",
        classes    => rudder_always_classes_persist("job_scheduler_lock_${iterator}_RudderUniqueID", "5");

      "any" usebundle => rudder_common_report_index("jobScheduler", "result_error", "${job_scheduler_uuids[${iterator}]}", "Job", "${job_scheduler_command[${iterator}]}", "Schedule is not valid (from ${job_scheduler_time_min[${iterator}]} to ${job_scheduler_time_max[${iterator}]}", "${iterator}"),
        ifvarclass => "schedule_simple_${job_scheduler_canon_name[${iterator}]}_RudderUniqueID_error";

      "any" usebundle => rudder_common_report_index("jobScheduler", "log_info", "${job_scheduler_uuids[${iterator}]}", "Job", "${job_scheduler_command[${iterator}]}", "The command will be run at a random time after ${job_scheduler_time_min[${iterator}]}:00 on this node", "${iterator}");

  commands:

    pass2::
      "${job_scheduler_command[${iterator}]}"
        action     => bg("10", "${job_scheduler_timeout[${iterator}]}"),
        contain    => in_shell,
        ifvarclass => "schedule_simple_${job_scheduler_canon_name[${iterator}]}_RudderUniqueID_repaired.!job_scheduler_lock_${iterator}",
        classes    => common_classes_exclusive_persist_codes("${job_scheduler_canon_name[${iterator}]}_RudderUniqueID",
                      "1440", # Persist the reporting classes for 24 hours, this technique deals with daily jobs (for now anyway)
                      "@{job_scheduler_RudderUniqueID.kept_returncodes_${iterator}}",
                      "@{job_scheduler_RudderUniqueID.repaired_returncodes_${iterator}}",
                      "@{job_scheduler_RudderUniqueID.error_returncodes_${iterator}}");

}

