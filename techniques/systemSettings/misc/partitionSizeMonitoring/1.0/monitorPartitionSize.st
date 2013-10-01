bundle agent monitorPartitionSize {

    vars:

        &PARTITION_SIZE_MONITORING_PATH:{path |"partition[&i&][path]" string => "&path&";
}&
        &PARTITION_SIZE_MONITORING_FREE_SIZE:{freesize |"partition[&i&][freesize]" string => "&freesize&";
}&
        &PARTITION_SIZE_MONITORING_CMD_EXEC_REPAIRED_COMMAND:{repaired_cmd |"partition[&i&][repaired_cmd]" string => "&repaired_cmd&";
}&
        &PARTITION_SIZE_MONITORING_CMD_EXEC_ERROR_COMMAND:{error_cmd |"partition[&i&][error_cmd]" string => "&error_cmd&";
}&
        &TRACKINGKEY:{directiveId |"partition[&i&][uuid]" string => "&directiveId&";
}&

        "index" slist => getindices("partition");

    classes:

        # Set classes to define when to run command executions
        &PARTITION_SIZE_MONITORING_CMD_EXEC_REPAIRED_RUN:{repaired_cmd_run |"monitorPartitionSize_repaired_cmd_run_&i&" expression => strcmp("&repaired_cmd_run&", "true");
}&

        &PARTITION_SIZE_MONITORING_CMD_EXEC_ERROR_RUN:{error_cmd_run |"monitorPartitionSize_error_cmd_run_&i&" expression => strcmp("&error_cmd_run&", "true");
}&


    storage:

        "$(partition[$(index)][path])"
            volume  => freespacecheck("partition[$(index)][freesize]"),
            classes => rudder_common_classes("monitorPartitionSize_partition_$(index)"),
            comment => "Check free space available on $(partition[$(index)][path])";


    commands:
        "$(partition[$(index)][repaired_cmd])"
            classes => rudder_common_classes("monitorPartitionSize_repaired_cmd_$(index)"),
            contain => in_shell,
            ifvarclass => "monitorPartitionSize_repaired_cmd_run_$(index).monitorPartitionSize_partition_$(index)_repaired";

        "$(partition[$(index)][error_cmd])"
            classes => rudder_common_classes("monitorPartitionSize_error_cmd_$(index)"),
            contain => in_shell,
            ifvarclass => "monitorPartitionSize_error_cmd_run_$(index).monitorPartitionSize_partition_$(index)_error";


    reports:

        (linux|windows)::

            # Partition status reporting
            # Success
            "@@monitorPartitionSize@@result_success@@$(partition[$(index)][uuid])@@Partition@@$(partition[$(index)][path])@@$(g.execRun)##$(g.uuid)@#The partition $(partition[$(index)][path]) has enough free space"
				ifvarclass => "monitorPartitionSize_partition_$(index)_kept";

            # Repaired
            "@@monitorPartitionSize@@result_repaired@@$(partition[$(index)][uuid])@@Partition@@$(partition[$(index)][path])@@$(g.execRun)##$(g.uuid)@#The partition $(partition[$(index)][path]) has not enough free space"
                ifvarclass => "monitorPartitionSize_partition_$(index)_repaired";
            # Error
            "@@monitorPartitionSize@@result_error@@$(partition[$(index)][uuid])@@Partition@@$(partition[$(index)][path])@@$(g.execRun)##$(g.uuid)@#There was an error checking partition $(partition[$(index)][path])"
                ifvarclass => "monitorPartitionSize_partition_$(index)_error";


            # Repaired command execution reporting
            # Success not set
			"@@monitorPartitionSize@@result_success@@$(partition[$(index)][uuid])@@Command execution on threshold@@$(partition[$(index)][repaired_cmd])@@$(g.execRun)##$(g.uuid)@#Under threshold command execution was not set"
				ifvarclass => "!monitorPartitionSize_repaired_cmd_run_$(index)";

            # Success not needed
			"@@monitorPartitionSize@@result_success@@$(partition[$(index)][uuid])@@Command execution on threshold@@$(partition[$(index)][repaired_cmd])@@$(g.execRun)##$(g.uuid)@#Under threshold command execution was not needed"
				ifvarclass => "monitorPartitionSize_repaired_cmd_run_$(index).!monitorPartitionSize_partition_$(index)_repaired";

            # Repaired
			"@@monitorPartitionSize@@result_repaired@@$(partition[$(index)][uuid])@@Command execution on threshold@@$(partition[$(index)][repaired_cmd])@@$(g.execRun)##$(g.uuid)@#Under threshold command executed - $(partition[$(index)][repaired_cmd])"
				ifvarclass => "monitorPartitionSize_repaired_cmd_run_$(index).monitorPartitionSize_repaired_cmd_$(index)_repaired";

            # Error
			"@@monitorPartitionSize@@result_error@@$(partition[$(index)][uuid])@@Command execution on threshold@@$(partition[$(index)][repaired_cmd])@@$(g.execRun)##$(g.uuid)@#Under threshold command failed to execute"
				ifvarclass => "monitorPartitionSize_repaired_cmd_run_$(index).monitorPartitionSize_repaired_cmd_$(index)_error";

            # Error command execution reporting
            # Success not set
			"@@monitorPartitionSize@@result_success@@$(partition[$(index)][uuid])@@Command execution on error@@$(partition[$(index)][error_cmd])@@$(g.execRun)##$(g.uuid)@#Error command execution was not set"
				ifvarclass => "!monitorPartitionSize_error_cmd_run_$(index)";

            # Success not needed
			"@@monitorPartitionSize@@result_success@@$(partition[$(index)][uuid])@@Command execution on error@@$(partition[$(index)][error_cmd])@@$(g.execRun)##$(g.uuid)@#Error command execution was not needed"
				ifvarclass => "monitorPartitionSize_error_cmd_run_$(index).!monitorPartitionSize_partition_$(index)_error";

            # Repaired
			"@@monitorPartitionSize@@result_repaired@@$(partition[$(index)][uuid])@@Command execution on error@@$(partition[$(index)][error_cmd])@@$(g.execRun)##$(g.uuid)@#Error command executed - $(partition[$(index)][error_cmd])"
				ifvarclass => "monitorPartitionSize_error_cmd_run_$(index).monitorPartitionSize_error_cmd_$(index)_repaired";

            # Error
			"@@monitorPartitionSize@@result_error@@$(partition[$(index)][uuid])@@Command execution on error@@$(partition[$(index)][error_cmd])@@$(g.execRun)##$(g.uuid)@#Error command failed to execute"
				ifvarclass => "monitorPartitionSize_error_cmd_run_$(index).monitorPartitionSize_error_cmd_$(index)_error";


}

body volume freespacecheck(threshold) {
    freespace      => "$(threshold)";
}

