bundle agent job_scheduler {
	vars:
		"all_hours" ilist => { "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23" };

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
		"iterator" slist => getindices("job_scheduler_uuids");

		"job_scheduler_canon_name[$(iterator)]" string => canonify("$(job_scheduler_command[$(iterator)])");

		"kept_returncodes_$(iterator)" slist => splitstring("$(job_scheduler_keptcodes[$(iterator)])",",","128");

		"repaired_returncodes_$(iterator)" slist => splitstring("$(job_scheduler_repaircodes[$(iterator)])",",","128");

		"error_returncodes_$(iterator)" slist => splitstring("$(job_scheduler_errorcodes[$(iterator)])",",","128");

		nos::

			"test_hours_$(iterator)[$(all_hours)]" string => "job_scheduler_$(all_hours)_$(iterator)",
				ifvarclass => "test_$(all_hours)_$(iterator)";

				# This should work, but produces errors when CFEngine checks the promises like: "Unable to parse class expression: [garbage]"
				# ifvarclass => or(and(isgreaterthan("$(all_hours)", "$(job_scheduler_time_min[$(iterator)])"), islessthan("$(all_hours)", "$(job_scheduler_time_max[$(iterator)])")), strcmp("$(job_scheduler_time_min[$(iterator)])", "$(all_hours)"));

		nos2::

			"test_hours_list_$(iterator)" slist => getvalues("test_hours_$(iterator)");

	classes:

		"job_scheduler_random_time" expression => splayclass("$(sys.host)$(sys.ipv4)","hourly");

		# This is only necessary because the above ifvarclass produces errors like: "Unable to parse class expression: [garbage]"
		"test_$(all_hours)_enclosed_$(iterator)" and => { isgreaterthan("$(all_hours)", "$(job_scheduler_time_min[$(iterator)])"), islessthan("$(all_hours)", "$(job_scheduler_time_max[$(iterator)])") };
		"test_$(all_hours)_$(iterator)"          or  => { "test_$(all_hours)_enclosed_$(iterator)", strcmp("$(job_scheduler_time_min[$(iterator)])", "$(all_hours)") };

		nos2::
		"run_time_$(iterator)" select_class => { "@(test_hours_list_$(iterator))" };

		any::
		"nos2" expression => "nos";
		"nos" expression => "any";

	commands:

		nos2::
			"$(job_scheduler_command[$(iterator)])"
				action     => bg("10", "$(job_scheduler_timeout[$(iterator)])"),
				contain    => in_shell,
				ifvarclass => "job_scheduler_$(all_hours)_$(iterator).Hr$(all_hours).job_scheduler_random_time",
				classes    => kept_if_else_exclusive_persist("$(job_scheduler_canon_name[$(iterator)])_ok",
				                                             "$(job_scheduler_canon_name[$(iterator)])_repaired",
				                                             "$(job_scheduler_canon_name[$(iterator)])_failed",
				                                             "1440", # Persist the reporting classes for 24 hours, this PT deals with daily jobs (for now anyway)
				                                             "@(job_scheduler.kept_returncodes_$(iterator))",
				                                             "@(job_scheduler.repaired_returncodes_$(iterator))",
				                                             "@(job_scheduler.error_returncodes_$(iterator))");

	reports:
		(linux|windows).nos2::
			# Note: if the command has not been executed (ever or since > frequency), no report will be sent until the splayclass is defined
			# This will cause Rudder to report an "Unknown" status, and is by design
			"@@jobScheduler@@result_success@@$(job_scheduler_uuids[$(iterator)])@@Job@@$(job_scheduler_command[$(iterator)])@@$(g.execRun)##$(g.uuid)@#Job returned a success return code after the last completed execution ($(job_scheduler_command[$(iterator)]))"
				ifvarclass => "$(job_scheduler_canon_name[$(iterator)])_ok";
			"@@jobScheduler@@result_repaired@@$(job_scheduler_uuids[$(iterator)])@@Job@@$(job_scheduler_command[$(iterator)])@@$(g.execRun)##$(g.uuid)@#Job returned a repaired return code on last completed execution ($(job_scheduler_command[$(iterator)]))"
				ifvarclass => "$(job_scheduler_canon_name[$(iterator)])_repaired";
			"@@jobScheduler@@result_error@@$(job_scheduler_uuids[$(iterator)])@@Job@@$(job_scheduler_command[$(iterator)])@@$(g.execRun)##$(g.uuid)@#Job failed on last completed execution ($(job_scheduler_command[$(iterator)]))"
				ifvarclass => "$(job_scheduler_canon_name[$(iterator)])_failed";
		
			"@@jobScheduler@@log_info@@$(job_scheduler_uuids[$(iterator)])@@Job@@$(job_scheduler_command[$(iterator)])@@$(g.execRun)##$(g.uuid)@#Job has been launched ($(job_scheduler_command[$(iterator)])), result will be reported on next run"
				ifvarclass => "job_scheduler_$(all_hours)_$(iterator).Hr$(all_hours).job_scheduler_random_time";

			"@@jobScheduler@@log_info@@$(job_scheduler_uuids[$(iterator)])@@Job@@$(job_scheduler_command[$(iterator)])@@$(g.execRun)##$(g.uuid)@#The command will be run at a random time after $(all_hours):00 on this node ($(job_scheduler_command[$(iterator)]))"
				ifvarclass => "job_scheduler_$(all_hours)_$(iterator)";

}

body classes kept_if_else_exclusive_persist(kept, repaired, failed, persist, keptcodes, repairedcodes, errorcodes) {

	kept_returncodes => { "@(keptcodes)" };
	repaired_returncodes => { "@(repairedcodes)" };
	failed_returncodes => { "@(errorcodes)" };

	promise_kept     => { "$(kept)" };
	cancel_kept      => { "$(repaired)", "$(failed)" };

	promise_repaired => { "$(repaired)" };
	cancel_repaired  => { "$(kept)", "$(failed)" };

	repair_failed    => { "$(failed)" };
	repair_denied    => { "$(failed)" };
	repair_timeout   => { "$(failed)" };
	cancel_notkept   => { "$(kept)", "$(repaired)" };

	persist_time     => "$(persist)";

}
