bundle agent monitorPartitionSize {

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


    storage:

        "$(partition[$(index)][path])"
            volume  => freespacecheck("$(partition[$(index)][freesize])"),
            classes => if_notkept("monitorPartitionSize_partition_$(index)_full"),
            comment => "Check free space available on $(partition[$(index)][path])";


    commands:
        "$(partition[$(index)][repaired_cmd])"
            classes => rudder_common_classes("monitorPartitionSize_repaired_cmd_$(index)"),
            contain => in_shell,
            ifvarclass => "monitorPartitionSize_repaired_cmd_run_$(index).monitorPartitionSize_partition_$(index)_full";


    reports:

        (linux|windows)::

            # Partition status reporting
            # Success
            "@@monitorPartitionSize@@result_success@@$(partition[$(index)][uuid])@@Partition@@$(partition[$(index)][path])@@$(g.execRun)##$(g.uuid)@#The partition $(partition[$(index)][path]) has enough free space"
				ifvarclass => "!monitorPartitionSize_partition_$(index)_full";

            # Repaired
            "@@monitorPartitionSize@@result_error@@$(partition[$(index)][uuid])@@Partition@@$(partition[$(index)][path])@@$(g.execRun)##$(g.uuid)@#The partition $(partition[$(index)][path]) has not enough free space"
                ifvarclass => "monitorPartitionSize_partition_$(index)_full";

            # Repaired command execution reporting
            # Success not set
			"@@monitorPartitionSize@@result_success@@$(partition[$(index)][uuid])@@Command execution on threshold@@$(partition[$(index)][repaired_cmd])@@$(g.execRun)##$(g.uuid)@#Under threshold command execution was not set"
				ifvarclass => "!monitorPartitionSize_repaired_cmd_run_$(index)";

            # Success not needed
			"@@monitorPartitionSize@@result_success@@$(partition[$(index)][uuid])@@Command execution on threshold@@$(partition[$(index)][repaired_cmd])@@$(g.execRun)##$(g.uuid)@#Under threshold command execution was not needed"
				ifvarclass => "monitorPartitionSize_repaired_cmd_run_$(index).!monitorPartitionSize_partition_$(index)_full";

            # Repaired
			"@@monitorPartitionSize@@result_repaired@@$(partition[$(index)][uuid])@@Command execution on threshold@@$(partition[$(index)][repaired_cmd])@@$(g.execRun)##$(g.uuid)@#Under threshold command executed - $(partition[$(index)][repaired_cmd])"
				ifvarclass => "monitorPartitionSize_repaired_cmd_run_$(index).monitorPartitionSize_repaired_cmd_$(index)_repaired";

            # Error
			"@@monitorPartitionSize@@result_error@@$(partition[$(index)][uuid])@@Command execution on threshold@@$(partition[$(index)][repaired_cmd])@@$(g.execRun)##$(g.uuid)@#Under threshold command failed to execute"
				ifvarclass => "monitorPartitionSize_repaired_cmd_run_$(index).monitorPartitionSize_repaired_cmd_$(index)_error";

}

body volume freespacecheck(threshold) {
    freespace      => "$(threshold)";
}

