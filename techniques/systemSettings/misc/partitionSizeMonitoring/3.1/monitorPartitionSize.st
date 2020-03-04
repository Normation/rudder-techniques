###########################################################################
# Monitor partition and optionnaly execute command if threshold is reached
# 
# Take a partition mount point and check free space
# Execute a command if threshold is reached
#

bundle agent monitor_partition_size_&RudderUniqueID& {

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


    any::
      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";

  methods:

    pass3.cfengine::

            # Partition status reporting
            # Success
      "any" usebundle => rudder_common_report_index("monitorPartitionSize", "result_success", "${partition[${index}][uuid]}", "Partition", "${partition[${index}][path]}", "The partition ${partition[${index}][path]} has enough free space", "${index}"),
                ifvarclass => "!monitorPartitionSize_partition_${index}_&RudderUniqueID&_full";

            # Error
      "any" usebundle => rudder_common_report_index("monitorPartitionSize", "result_error", "${partition[${index}][uuid]}", "Partition", "${partition[${index}][path]}", "The partition ${partition[${index}][path]} has not enough free space", "${index}"),
                ifvarclass => "monitorPartitionSize_partition_${index}_&RudderUniqueID&_full";

            # Repaired command execution reporting
            # NA not set
      "any" usebundle => rudder_common_report_index("monitorPartitionSize", "result_na", "${partition[${index}][uuid]}", "Command execution on threshold", "${partition[${index}][path]}", "Under threshold command execution was not set", "${index}"),
                ifvarclass => "!monitorPartitionSize_repaired_cmd_run_${index}";

            # Success not needed
      "any" usebundle => rudder_common_report_index("monitorPartitionSize", "result_success", "${partition[${index}][uuid]}", "Command execution on threshold", "${partition[${index}][path]}", "Under threshold command execution was not needed", "${index}"),
                ifvarclass => "monitorPartitionSize_repaired_cmd_run_${index}.!monitorPartitionSize_partition_${index}_&RudderUniqueID&_full";

            # Repaired
      "any" usebundle => rudder_common_report_index("monitorPartitionSize", "result_repaired", "${partition[${index}][uuid]}", "Command execution on threshold", "${partition[${index}][path]}", "Under threshold command executed - ${partition[${index}][repaired_cmd]}", "${index}"),
                ifvarclass => "monitorPartitionSize_repaired_cmd_run_${index}.monitorPartitionSize_repaired_cmd_${index}_&RudderUniqueID&_repaired";

            # Error
      "any" usebundle => rudder_common_report_index("monitorPartitionSize", "result_error", "${partition[${index}][uuid]}", "Command execution on threshold", "${partition[${index}][path]}", "Under threshold command failed to execute", "${index}"),
                ifvarclass => "monitorPartitionSize_repaired_cmd_run_${index}.monitorPartitionSize_repaired_cmd_${index}_&RudderUniqueID&_error";

    commands:
        "${partition[${index}][repaired_cmd]}"
            classes => classes_generic("monitorPartitionSize_repaired_cmd_${index}_&RudderUniqueID&"),
            contain => in_shell,
            ifvarclass => "monitorPartitionSize_repaired_cmd_run_${index}.monitorPartitionSize_partition_${index}_&RudderUniqueID&_full";


    storage:

        "${partition[${index}][path]}"
            volume  => freespacecheck_&RudderUniqueID&("${partition[${index}][freesize]}"),
            classes => if_notkept("monitorPartitionSize_partition_${index}_&RudderUniqueID&_full"),
            comment => "Check free space available on ${partition[${index}][path]}";


}

body volume freespacecheck_&RudderUniqueID&(threshold) {
    freespace => "${threshold}";
    # see https://dev.cfengine.com/issues/3016
    sensible_size  => "0";
    sensible_count => "0";
}

