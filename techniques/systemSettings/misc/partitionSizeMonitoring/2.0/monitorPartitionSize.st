#####################################################################################
# Copyright 2013 Normation SAS
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
                                                                                                                                                                                                                                                                                 
###########################################################################
# Monitor partition and optionnaly execute command if threshold is reached
# 
# Take a partition mount point and check free space
# Execute a command if threshold is reached
#

bundle agent monitor_partition_size {

    vars:

        &PARTITION_SIZE_MONITORING_PATH:{path |"partition[&i&][path]" string => "&path&";
}&
        &PARTITION_SIZE_MONITORING_FREE_SIZE:{freesize |"partition[&i&][freesize]" string => "&freesize&";
}&
        &PARTITION_SIZE_MONITORING_CMD_EXEC_REPAIRED_COMMAND:{repaired_cmd |"partition[&i&][repaired_cmd]" string => "&repaired_cmd&";
}&
        &TRACKINGKEY:{directiveId |"partition[&i&][uuid]" string => "&directiveId&";
}&

        "index" slist => getindices("partition");

    classes:

        # Set classes to define when to run command executions
        &PARTITION_SIZE_MONITORING_CMD_EXEC_REPAIRED_RUN:{repaired_cmd_run |"monitorPartitionSize_repaired_cmd_run_&i&" expression => strcmp("&repaired_cmd_run&", "true");
}&


    commands:
        "${partition[${index}][repaired_cmd]}"
            classes => rudder_common_classes("monitorPartitionSize_repaired_cmd_${index}"),
            contain => in_shell,
            ifvarclass => "monitorPartitionSize_repaired_cmd_run_${index}.monitorPartitionSize_partition_${index}_full";


    storage:

        "${partition[${index}][path]}"
            volume  => freespacecheck("${partition[${index}][freesize]}"),
            classes => if_notkept("monitorPartitionSize_partition_${index}_full"),
            comment => "Check free space available on ${partition[${index}][path]}";


    reports:

        (linux|windows)::

            # Partition status reporting
            # Success
            "@@monitorPartitionSize@@result_success@@${partition[${index}][uuid]}@@Partition@@${partition[${index}][path]}@@${g.execRun}##${g.uuid}@#The partition ${partition[${index}][path]} has enough free space"
                ifvarclass => "!monitorPartitionSize_partition_${index}_full";

            # Error
            "@@monitorPartitionSize@@result_error@@${partition[${index}][uuid]}@@Partition@@${partition[${index}][path]}@@${g.execRun}##${g.uuid}@#The partition ${partition[${index}][path]} has not enough free space"
                ifvarclass => "monitorPartitionSize_partition_${index}_full";

            # Repaired command execution reporting
            # Success not set
            "@@monitorPartitionSize@@result_success@@${partition[${index}][uuid]}@@Command execution on threshold@@${partition[${index}][path]}@@${g.execRun}##${g.uuid}@#Under threshold command execution was not set"
                ifvarclass => "!monitorPartitionSize_repaired_cmd_run_${index}";

            # Success not needed
            "@@monitorPartitionSize@@result_success@@${partition[${index}][uuid]}@@Command execution on threshold@@${partition[${index}][path]}@@${g.execRun}##${g.uuid}@#Under threshold command execution was not needed"
                ifvarclass => "monitorPartitionSize_repaired_cmd_run_${index}.!monitorPartitionSize_partition_${index}_full";

            # Repaired
            "@@monitorPartitionSize@@result_repaired@@${partition[${index}][uuid]}@@Command execution on threshold@@${partition[${index}][path]}@@${g.execRun}##${g.uuid}@#Under threshold command executed - ${partition[${index}][repaired_cmd]}"
                ifvarclass => "monitorPartitionSize_repaired_cmd_run_${index}.monitorPartitionSize_repaired_cmd_${index}_repaired";

            # Error
            "@@monitorPartitionSize@@result_error@@${partition[${index}][uuid]}@@Command execution on threshold@@${partition[${index}][path]}@@${g.execRun}##${g.uuid}@#Under threshold command failed to execute"
                ifvarclass => "monitorPartitionSize_repaired_cmd_run_${index}.monitorPartitionSize_repaired_cmd_${index}_error";

}

body volume freespacecheck(threshold) {
    freespace => "${threshold}";
}

