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

#######################################################
#
# promises.cf
#
#######################################################
body common control {

    inputs => {       
        &INPUTLIST&
    };

    bundlesequence => { @(va.bs) &BUNDLELIST& , @(va.end)};
    
	output_prefix => "rudder"; 

&if(NOVA)&
	host_licenses_paid => "&LICENSESPAID&";

&endif&
}

bundle common va {
  vars:
    "bs" slist => { "startExecution", "clean_red_button", "update", "set_red_button", "internal_security", "check_red_button_status", "process_matching", "check_cf_processes", "check_uuid", "check_log_system", "check_cron_daemon", "garbage_collection", "check_binaries_freshness", "e2s_enable"
     };


    "end" slist => { "endExecution" };


# definition of the machine roles
&NODEROLE&
}

#########################################################
# Control execution
#########################################################
bundle agent startExecution {
  reports:
	linux|windows::
		"@@Common@@log_info@@&TRACKINGKEY&@@common@@StartRun@@$(g.execRun)##$(g.uuid)@#Start execution";
}

bundle agent endExecution {
  reports:
	linux|windows::
		"@@Common@@log_info@@&TRACKINGKEY&@@common@@EndRun@@$(g.execRun)##$(g.uuid)@#End execution";
}

##########################################################
# Red Button part.
# When the file $(sys.workdir)/inputs/stop exists, we must stop the
# execution of the agent on all client machines
##########################################################
bundle agent clean_red_button() {
  commands:
	safe.policy_server::
 		"$(sys.workdir)/bin/cf-runagent"
 			args => "-Dsafe",
 			comment => "Propagate the safe information to children";
 			
  files:
    safe.policy_server::
	"/var/rudder/share/[a-f0-9A-F\-]+/rules/cfengine-(community|nova)/stopFile"
		delete => tidy,
		comment => "Deleting the stop file on clients promises, cfengine is good to go";
             
	safe.!policy_server::
        "${sys.workdir}/inputs/stopFile" 
             delete => tidy,
             comment => "Deleting the stop file, cfengine is good to go";
             
   reports:
     safe::
		"@@Common@@result_repaired@@&TRACKINGKEY&@@Red Button@@None@@$(g.execRun)##$(g.uuid)@#Authorizing Cfengine to restart";
}

bundle agent set_red_button() {
  classes:
	policy_server::
		"danger" expression => fileexists("/var/rudder/share/root/stopFile");
  methods:
  	danger::
  		"any" usebundle => setStopFile;
  	
  	danger.policy_server::
  		"any" usebundle => stopClients;
}

bundle agent setStopFile {
 files:
    danger.!policy_server::
        "${sys.workdir}/inputs/stopFile" 
            create => "true";
    danger.policy_server::
        "/var/rudder/share/[a-f0-9A-F\-]+/rules/cfengine-(community|nova)/stopFile"
        create => "true";


  
  reports:
     danger.!policy_server::
		"@@Common@@result_repaired@@&TRACKINGKEY&@@Red Button@@None@@$(g.execRun)##$(g.uuid)@#Creating local stop file for this node";
     danger.policy_server::
		"@@Common@@result_repaired@@&TRACKINGKEY&@@Red Button@@None@@$(g.execRun)##$(g.uuid)@#Creating stop files for all clients of this policy server";
    
}

bundle agent stopClients {
 classes:
	policy_server::
		"danger" expression => fileexists("/var/rudder/share/root/stopFile");

 commands:
 	danger.policy_server::
 		"$(sys.workdir)/bin/cf-runagent"
 			args => "-Ddanger",
 			comment => "Propagate the danger information to children";  
 
 reports:
     danger.policy_server::
		"@@Common@@log_repaired@@&TRACKINGKEY&@@Red Button@@None@@$(g.execRun)##$(g.uuid)@#Actively stopping CFEngine operations on all clients of this policy server (via cf-runagent)";
 
}

bundle agent check_red_button_status() {
	classes:
		!policy_server::
			"should_not_continue" expression => fileexists("${sys.workdir}/inputs/stopFile");

	reports:
		!should_not_continue::
			"@@Common@@result_success@@&TRACKINGKEY&@@Red Button@@None@@$(g.execRun)##$(g.uuid)@#Red Button is not in effect, continuing as normal...";
}


###################################################
# Check that CFengine services are up 
###################################################
bundle agent check_cf_processes {

processes:

	linux::

		"$(sys.workdir)/bin/cf-serverd"  restart_class => "start_server";
		"$(sys.workdir)/bin/cf-execd"    restart_class => "start_executor";

	windows::

		"$(escaped_workdir)\/bin\/cf-serverd"  restart_class => "start_server";
		"$(escaped_workdir)\/bin\/cf-execd"    restart_class => "start_executor";

commands:

	start_server::
		"$(sys.cf_serverd)",
			action => u_ifwin_bg,
			classes => outcome("server");
	
	start_executor::
		"$(sys.cf_execd)",
			action => u_ifwin_bg,
			classes => outcome("executor");

}

#######################################################
# UUID file enforcing

bundle agent check_uuid {
  files:
	"${g.uuid_file}"
		create    => "true",
       		edit_line => enforce_content("${g.uuid}"),
       		edit_defaults => noempty_backup,
		perms => m("644"),
       		comment => "Setting the uuid variable in a machine";
			
}


#######################################################
# Check the log system, and configure it accordingly
# This only works with unix flavoured system

bundle agent check_log_system {
  processes:
	"rsyslogd"
		process_count => islaunched("rsyslogd");

	"syslog-ng"
		process_count => islaunched("syslogng");

	"[^r]syslogd"
		process_count => islaunched("syslogd");

  files:
  	linux.rsyslogd.!policy_server::
  	  "/etc/rsyslog.d/rudder-agent.conf"
  		edit_line => append_if_no_lines("#Rudder log system$(const.n)if $syslogfacility-text == 'local6' and $programname startswith 'rudder' then @@$(server_info.cfserved):514"),
		create => "true",
		edit_defaults => empty_backup,
  		classes => class_trigger("rsyslog_repaired" , "rsyslog_failed", "rsyslog_kept");

	"/etc/rsyslog.conf"
		edit_line => append_if_no_lines("$IncludeConfig /etc/rsyslog.d/*.conf"),
		comment => "Add the rsyslog.conf.d include if not already present",
                classes => class_trigger("rsyslog_repaired" , "rsyslog_failed", "rsyslog_kept");


	linux.syslogng.!SuSE.!policy_server::
		"/etc/syslog-ng/syslog-ng.conf"
			edit_line => append_if_no_line("# Autogenerated by rudder, do not edit${const.n}filter f_local_rudder{facility(local6) and program(\"rudder.*\");};destination loghost {tcp(\"$(server_info.cfserved)\" port (514));};log {source(src);filter(f_local_rudder);destination(loghost);};"),
			classes => class_trigger("syslog_ng_repaired" , "syslog_ng_failed", "syslog_ng_kept");

  	linux.syslogng.SuSE.!policy_server::
		"/etc/syslog-ng/syslog-ng.conf"
			edit_line => append_if_no_line("# Autogenerated by rudder, do not edit${const.n}filter f_local_rudder{facility(local6) and program(\"rudder.*\");};destination loghost {tcp(\"$(server_info.cfserved)\" port (514));};log {source(src);filter(f_local_rudder);destination(loghost);};"),
			classes => class_trigger("syslog_ng_repaired" , "syslog_ng_failed", "syslog_ng_kept");

    linux.syslogd.!policy_server::
      "/etc/syslog.conf"
      edit_line => fix_syslogd("@$(server_info.cfserved)"),
      classes => class_trigger("syslogd_repaired" , "syslogd_failed", "syslogd_kept");
      #Probably, we want to do something if it is repaired ?

      
  commands:
  	SuSE.(syslog_ng_repaired|rsyslog_repaired|syslogd_repaired)::
  		"/etc/init.d/syslog"
  			args => "restart",
  			comment => "Restarting syslog-ng after it's been updated";
  	syslog_ng_repaired.!SuSE::
  		"/etc/init.d/syslog-ng"
  			args => "restart",
  			comment => "Restarting syslog-ng after it's been updated";

    rsyslog_repaired.!SuSE::
      "/etc/init.d/rsyslog"
        args => "restart",
        comment => "Restarting rsyslog after it's been updated";

    syslogd_repaired.!SuSE::
      "/etc/init.d/syslog"
        args => "restart",
        comment => "Restarting rsyslog after it's been updated";


  reports:
    linux.no_rsyslogd.no_syslogng.no_syslogd::
    	"@@Common@@result_error@@&TRACKINGKEY&@@Log system for reports@@None@@$(g.execRun)##$(g.uuid)@#Logging system not recognized, cannot setup logs for report centralization";

	syslogd::
		"@@Common@@log_info@@&TRACKINGKEY&@@Log system for reports@@None@@$(g.execRun)##$(g.uuid)@#Detected running syslog as syslogd";
	syslogng::
		"@@Common@@log_info@@&TRACKINGKEY&@@Log system for reports@@None@@$(g.execRun)##$(g.uuid)@#Detected running syslog as syslog-ng";
	rsyslogd::
		"@@Common@@log_info@@&TRACKINGKEY&@@Log system for reports@@None@@$(g.execRun)##$(g.uuid)@#Detected running syslog as rsyslog";
    	
    syslogd_failed|syslog_ng_failed|rsyslog_failed::
    	"@@Common@@result_error@@&TRACKINGKEY&@@Log system for reports@@None@@$(g.execRun)##$(g.uuid)@#Logging system could not be configured for report centralization";

    syslogd_repaired|syslog_ng_repaired|rsyslog_repaired::
    	"@@Common@@result_repaired@@&TRACKINGKEY&@@Log system for reports@@None@@$(g.execRun)##$(g.uuid)@#Configured logging system for report centralization";

	(syslogd.syslogd_kept.!syslogd_failed.!syslogd_repaired)|(syslogng.syslog_ng_kept.!syslog_ng_failed.!syslog_ng_repaired)|(rsyslogd.rsyslog_kept.!rsyslog_failed.!rsyslog_repaired)::
    	"@@Common@@result_success@@&TRACKINGKEY&@@Log system for reports@@None@@$(g.execRun)##$(g.uuid)@#Logging system for report centralization is already correctly configured";
} 

#######################################################
# Check if the cron daemon is running
# This only works with unix flavoured systems too

bundle agent check_cron_daemon {

    vars:

        (debian|SuSE)::

            "cron_bin" string => "/usr/sbin/cron";
            "cron_restartcmd" string => "/etc/init.d/cron restart";

        redhat::

            "cron_bin" string => "crond";
            "cron_restartcmd" string => "/etc/init.d/crond restart";

    processes:

            "$(cron_bin)"
                restart_class => "restart_crond";

    commands:

        restart_crond::

            "$(cron_restartcmd)"

                comment => "Restarting crond",
                classes => class_trigger("crond_restarted" , "crond_failed", "crond_ok");

    reports:

        crond_failed::
            "@@Common@@result_error@@&TRACKINGKEY&@@CRON Daemon@@None@@$(g.execRun)##$(g.uuid)@#The CRON daemon was not running and could not be restarted";

        crond_restarted::
            "@@Common@@result_repaired@@&TRACKINGKEY&@@CRON Daemon@@None@@$(g.execRun)##$(g.uuid)@#The CRON daemon has been successfully restarted";

        !restart_crond.!crond_restarted.!crond_failed::
            "@@Common@@result_success@@&TRACKINGKEY&@@CRON Daemon@@None@@$(g.execRun)##$(g.uuid)@#The CRON daemon is running";

}

########################################################
# Trash every output report older than 30 days         #
########################################################

bundle agent garbage_collection
{

	files:

		"$(sys.workdir)/outputs" 

			delete => tidy,
			file_select => days_old("30"),
			depth_search => recurse("inf");


}

#######################################################
# Copy the CFengine binaries from the /opt repository
# to the CFengine working directory

bundle agent check_binaries_freshness {

	vars:

		community_edition::

			"components" slist => { "cf-agent", "cf-serverd", "cf-execd", "cf-monitord", "cf-know", "cf-promises", "cf-runagent", "cf-report", "cf-key" };

		nova_edition::

			"components" slist => { "cf-agent", "cf-serverd", "cf-execd", "cf-monitord", "cf-know", "cf-promises", "cf-runagent", "cf-report", "cf-key", "cf-hub" };

	files:

		"${sys.workdir}/bin/${components}"
			perms => u_p("700"),
			copy_from => cp("${g.rudder_sbin}/${components}", "localhost"),
			classes => kept_if_else("binaries_fresh", "binaries_rotten", "binaries_missing"),
			action => immediate,
			comment => "Copying the CFengine binaries from ${g.rudder_sbin}/sbin to ${sys.workdir}/bin";

    reports:

        binaries_fresh.!binaries_rotten.!binaries_missing::
            "@@Common@@result_success@@&TRACKINGKEY&@@Binaries update@@None@@$(g.execRun)##$(g.uuid)@#The CFengine binaries in ${sys.workdir}/bin are up to date";

        binaries_rotten.!binaries_missing::
            "@@Common@@result_repaired@@&TRACKINGKEY&@@Binaries update@@None@@$(g.execRun)##$(g.uuid)@#The CFengine binaries have been updated in ${sys.workdir}/bin";

        binaries_missing::
            "@@Common@@result_error@@&TRACKINGKEY&@@Binaries update@@None@@$(g.execRun)##$(g.uuid)@#An error occurred while updating the CFengine binaries in ${sys.workdir}/bin";

}

#######################################################

body agent control {
    # if default runtime is 5 mins we need this for long jobs
    ifelapsed => "1";

    #define here some environment variables
    environment => { "DEBIAN_FRONTEND=noninteractive" }; 

	abortclasses => { "should_not_continue" };
	
	agentfacility => "LOG_LOCAL6";

	# Repository where to put the copy of modified files
	default_repository => "/var/rudder/modified-files";

}

#######################################################

body executor control {
    splaytime => "1";

    exec_command => "$(sys.workdir)/bin/cf-agent -f failsafe.cf \&\& $(sys.workdir)/bin/cf-agent";
    schedule         => { "Min00", "Min05", "Min10", "Min15", "Min20", "Min25", "Min30", "Min35", "Min40", "Min45", "Min50", "Min55" };
    executorfacility => "LOG_DAEMON";
}

########################################################

#Enforce that the file only contains this information
bundle edit_line enforce_content(str) {

	delete_lines:
  		"$(str)" not_matching => "true";

	insert_lines:
		"$(str)";
}

# Fix syslogd content : caution, the @ must be in the argument
bundle edit_line fix_syslogd(syslogd)
{
    delete_lines:
	any::
            "^(local6)\s+(?!$(syslogd)).*",
                comment => "Delete missconfigured rudder syslogd destination";

    insert_lines:
	any::
            "# Rudder specific logging parameters";
            "local6.*						$(syslogd)",
                comment => "Add the rudder syslogd destination";
}



