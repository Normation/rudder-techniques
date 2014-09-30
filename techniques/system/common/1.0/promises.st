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
body common control
{

    any::
        output_prefix => "rudder";

        inputs => {
          &INPUTLIST&
        };

        bundlesequence => { @{va.bs} &BUNDLELIST& , @{va.end} };

&if(NOVA)&
        host_licenses_paid => "&LICENSESPAID&";

&endif&
}

bundle common va
{
  vars:
    policy_server::
      "bs" slist => {
        "startExecution",
        "clean_red_button",
        "update",
        "set_red_button",
        "internal_security",
        "check_red_button_status",
        "process_matching",
        "check_cf_processes",
        "check_uuid",
        "check_log_system",
        "check_rsyslog_version",
        "check_cron_daemon",
        "garbage_collection",
        "check_binaries_freshness",
        "e2s_enable",
        "check_zypper"
      };

    !policy_server::
      "bs" slist => {
        "startExecution",
        "clean_red_button",
        "update",
        "set_red_button",
        "internal_security",
        "check_red_button_status",
        "process_matching",
        "check_cf_processes",
        "check_cron_daemon",
        "garbage_collection",
        "check_binaries_freshness",
        "check_log_system",
        "check_rsyslog_version",
        "e2s_enable",
        "check_zypper",
        "check_uuid"
      };

    any::
      "end" slist => { "endExecution" };


# definition of the machine roles
&NODEROLE&
}

bundle common rudder_roles
{

  classes:
      # Abort if no uuid is defined
      "should_not_continue" not => fileexists("${g.uuid_file}");

      "disable_agent" expression => fileexists("${g.rudder_base}/etc/disable-agent");

      # Policy Server is a machine which delivers promises
      "policy_server" expression => strcmp("root","${g.uuid}");
      # Root Server is the top policy server machine
      "root_server" expression => strcmp("root","${g.uuid}");
}

#########################################################
# Control execution
#########################################################
bundle agent startExecution
{
  reports:
    linux|windows::
      "@@Common@@log_info@@&TRACKINGKEY&@@common@@StartRun@@${g.execRun}##${g.uuid}@#Start execution";
}

bundle agent endExecution
{
  reports:
    linux|windows::
      "@@Common@@log_info@@&TRACKINGKEY&@@common@@EndRun@@${g.execRun}##${g.uuid}@#End execution";

    rudder_promises_generated_error|no_update::
		"*********************************************************************************
* rudder-agent could not get an updated configuration from the policy server.   *
* This can be caused by a network issue, an unavailable server, or if this      *
* node was deleted from the Rudder root server.                                 *
* Any existing configuration policy will continue to be applied without change. *
*********************************************************************************";
}

##########################################################
# Red Button part.
# When the file ${sys.workdir}/inputs/stop exists, we must stop the
# execution of the agent on all client machines
##########################################################
bundle agent clean_red_button()
{
  files:
    safe.policy_server::
      "${g.rudder_var}/share/[a-f0-9A-F\-]+/rules/cfengine-(community|nova)/stopFile"
        delete => tidy,
        comment => "Deleting the stop file on clients promises, cfengine is good to go";

    safe.!policy_server::
      "${sys.workdir}/inputs/stopFile"
        delete => tidy,
        comment => "Deleting the stop file, cfengine is good to go";

  commands:
    safe.policy_server::
      "${sys.workdir}/bin/cf-runagent"
        args => "-Dsafe",
        comment => "Propagate the safe information to children";

  reports:
    safe::
      "@@Common@@result_repaired@@&TRACKINGKEY&@@Red Button@@None@@${g.execRun}##${g.uuid}@#Authorizing Cfengine to restart";
}

bundle agent set_red_button()
{
  classes:
    policy_server::
      "danger" expression => fileexists("${g.rudder_var}/share/root/stopFile");
  methods:
    danger::
      "any" usebundle => setStopFile;

    danger.policy_server::
      "any" usebundle => stopClients;
}

bundle agent setStopFile
{
  files:
    danger.!policy_server::
      "${sys.workdir}/inputs/stopFile"
        create => "true";
    danger.policy_server::
      "${g.rudder_var}/share/[a-f0-9A-F\-]+/rules/cfengine-(community|nova)/stopFile"
        create => "true";



  reports:
    danger.!policy_server::
      "@@Common@@result_repaired@@&TRACKINGKEY&@@Red Button@@None@@${g.execRun}##${g.uuid}@#Creating local stop file for this node";
    danger.policy_server::
      "@@Common@@result_repaired@@&TRACKINGKEY&@@Red Button@@None@@${g.execRun}##${g.uuid}@#Creating stop files for all clients of this policy server";

}

bundle agent stopClients
{
  classes:
    policy_server::
      "danger" expression => fileexists("${g.rudder_var}/share/root/stopFile");

  commands:
    danger.policy_server::
      "${sys.workdir}/bin/cf-runagent"
        args => "-Ddanger",
        comment => "Propagate the danger information to children";

  reports:
    danger.policy_server::
      "@@Common@@log_repaired@@&TRACKINGKEY&@@Red Button@@None@@${g.execRun}##${g.uuid}@#Actively stopping CFEngine operations on all clients of this policy server (via cf-runagent)";

}

bundle agent check_red_button_status()
{
  classes:
    !policy_server::
      "should_not_continue" expression => fileexists("${sys.workdir}/inputs/stopFile");

  reports:
    !should_not_continue::
      "@@Common@@result_success@@&TRACKINGKEY&@@Red Button@@None@@${g.execRun}##${g.uuid}@#Red Button is not in effect, continuing as normal...";
}


###################################################
# Check that CFengine services are up
###################################################
bundle agent check_cf_processes
{
  vars:

      # process_term defines how many maximum instances of this
      # binary should be running before attempting to SIGTERM them.
      # process_kill is the same for SIGKILL.

      "process_term[execd]" string => "2";
      "process_kill[execd]" string => "5";

      "process_term[agent]" string => "5";
      "process_kill[agent]" string => "8";

      "binaries"            slist  => getindices("process_term");

  processes:

    linux::

      "${sys.workdir}/bin/cf-serverd"  restart_class => "start_server";
      "${sys.workdir}/bin/cf-execd"    restart_class => "start_executor";

      # If there are more than 2 cf-execd's, it means cf-execd is starting to
      # go crazy, so we ask politely to these processes to shut down.

      "${sys.workdir}/bin/cf-${binaries}"
        process_count => check_range("${binaries}", "0","${process_term[${binaries}]}"),
        signals       => { "term" },
        classes       => if_repaired("${binaries}_has_gone_wild"),
        comment       => "Checking if cf-${binaries} has gone wild";

      # If there are too much cf-execd's/cf-agents running, it means that they are really
      # going crazy. Let's be a bit less polite and more violent about killing them.
      #
      # These two promises overlap, because when you go past the 2/5-limit treshold,
      # you still leave a chance for them to die with SIGTERM before the SIGKILL.
      #
      # Reason: The backend databases that stores the classes and some runtime
      # parameters do really not appreciate beeing killed violently and may prevent
      # the agent from operating properly.

      "${sys.workdir}/bin/cf-${binaries}"
        process_count => check_range("${binaries}", "0","${process_kill[${binaries}]}"),
        signals       => { "kill" },
        classes       => if_repaired("${binaries}_has_gone_really_wild"),
        comment       => "Checking if cf-${binaries} has gone really wild";

&if(NOVA)&
    windows::

      # Windows does only implement SIGTERM. Using SIGKILL makes no sense on it.

      "cf-${binaries}"
        process_count => check_range("${binaries}", "0","${process_term[${binaries}]}"),
        signals       => { "term" },
        classes       => if_repaired("${binaries}_has_gone_wild"),
        comment       => "Checking if cf-${binaries} has gone wild";

      "${g.escaped_workdir}\/bin\/cf-serverd"
        restart_class => "start_server";
      "cf-execd"
        restart_class => "start_executor";
&endif&

  commands:

    start_server.!disable_agent::
      "${sys.cf_serverd}"
        action  => u_ifwin_bg,
        classes => outcome("server");

    start_executor.!disable_agent::
      "${sys.cf_execd}"
        action  => u_ifwin_bg,
        classes => outcome("executor");

  reports:

    (linux|windows)::

      "@@Common@@result_success@@&TRACKINGKEY&@@Process checking@@None@@${g.execRun}##${g.uuid}@#There is an acceptable number of CFEngine processes running on the machine"
      # Here, I can not use the binaries variable as CFEngine will iterate and output two reports, breaking the reporting.
        ifvarclass => "!agent_has_gone_wild.!agent_has_gone_really_wild.!execd_has_gone_wild.!execd_has_gone_really_wild";

      "@@Common@@result_repaired@@&TRACKINGKEY&@@Process checking@@None@@${g.execRun}##${g.uuid}@#Warning, more than ${process_term[${binaries}]} cf-${binaries} processes were detected. They have been sent a graceful termination signal."
        ifvarclass => "${binaries}_has_gone_wild.!${binaries}_has_gone_really_wild";

      "@@Common@@result_error@@&TRACKINGKEY&@@Process checking@@None@@${g.execRun}##${g.uuid}@#ALERT: more than ${process_term[${binaries}]} cf-${binaries} processes were detected. Killing processes that do not respect graceful termination signals."
        ifvarclass => "${binaries}_has_gone_really_wild";

    disable_agent::
      "@@Common@@log_info@@hasPolicyServer-root@@common-root@@2@@Process checking@@None@@${g.execRun}##${g.uuid}@#The disable-agent configuration file is present, no CFEngine processes will be started";

}

#######################################################
# UUID file enforcing

bundle agent check_uuid
{
  files:
      "${g.uuid_file}"
        create        => "true",
        edit_line     => enforce_content("${g.uuid}"),
        edit_defaults => noempty_backup,
        perms         => m("644"),
        comment       => "Setting the uuid variable in a machine";
}


#######################################################
# Check the log system, and configure it accordingly
# This only works with unix flavoured system

bundle agent check_log_system
{

  vars:
    debian::

      "syslog_ng_source" string => "s_src";

    SuSE::

      "syslog_ng_source" string => "src";

    redhat::

      "syslog_ng_source" string => "s_sys";

    any::
      "syslog_conf_comment"   string => "# Autogenerated by rudder, do not edit${const.n}";
      "syslog_ng_conf_prefix" string => "filter f_local_rudder{facility(local6) and program(\"rudder.*\");};destination loghost {tcp(\"";
      "syslog_ng_conf_suffix" string => "\" port (&SYSLOGPORT&));};log {source(${syslog_ng_source});filter(f_local_rudder);destination(loghost);";
      "syslog_ng_conf_final"  string => "flags(final);};";
      "syslog_ng_conf"        string => concat("${syslog_conf_comment}", "${syslog_ng_conf_prefix}", "${server_info.cfserved}", "${syslog_ng_conf_suffix}", "${syslog_ng_conf_final}");
      "syslog_ng_conf_regex"  string => concat(escape("${syslog_ng_conf_prefix}"), "[^\"]+", escape("${syslog_ng_conf_suffix}"), ".*");

  classes:

      "rsyslogd" expression => fileexists("/etc/rsyslog.conf");

      "syslogng" expression => fileexists("/etc/syslog-ng/syslog-ng.conf");

      "syslogd" expression => fileexists("/etc/syslog.conf");

  files:
    linux.rsyslogd::
      "/etc/rsyslog.conf"
        edit_line => append_if_no_lines("$IncludeConfig /etc/rsyslog.d/*.conf"),
        edit_defaults => noempty_backup,
        comment => "Add the rsyslog.conf.d include if not already present",
        classes => kept_if_else("rsyslog_kept", "rsyslog_repaired" , "rsyslog_failed");

    linux.rsyslogd.!policy_server::
      "/etc/rsyslog.d/rudder-agent.conf"
        edit_line => append_if_no_lines("#Rudder log system${const.n}if $syslogfacility-text == 'local6' and $programname startswith 'rudder' then @@${server_info.cfserved}:&SYSLOGPORT&${const.n}if $syslogfacility-text == 'local6' and $programname startswith 'rudder' then ~"),
        create => "true",
        edit_defaults => empty_backup,
        classes => kept_if_else("rsyslog_kept", "rsyslog_repaired" , "rsyslog_failed");

    SuSE.rsyslogd.policy_server::
      # For SuSE, ensure that SYSLOG_DAEMON is set to 'rsyslogd' even if another syslog has been installed before
      "/etc/sysconfig/syslog"
        edit_line => ensure_rsyslogd_on_suse,
        edit_defaults => noempty_backup,
				classes   => kept_if_else("rsyslog_kept", "rsyslog_repaired" , "rsyslog_failed");

    linux.syslogng.!policy_server::
      "/etc/syslog-ng/syslog-ng.conf"
        edit_line => edit_syslog_conf_file("${syslog_ng_conf}", "${syslog_ng_conf_regex}"),
        edit_defaults => noempty_backup,
        classes => kept_if_else("syslog_ng_kept", "syslog_ng_repaired" , "syslog_ng_failed");

    linux.syslogd.!policy_server::
      "/etc/syslog.conf"
        edit_line => fix_syslogd("@${server_info.cfserved}"),
        edit_defaults => noempty_backup,
        classes => kept_if_else("syslogd_kept", "syslogd_repaired" , "syslogd_failed");
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

    rsyslog_repaired.!(SuSE|fedora)::
      "/etc/init.d/rsyslog"
        args => "restart",
        comment => "Restarting rsyslog after it's been updated";

    rsyslog_repaired.fedora::
      "/bin/systemctl"
        args => "restart rsyslog",
        comment => "Restarting rsyslog after it's been updated";

    syslogd_repaired.!SuSE::
      "/etc/init.d/syslog"
        args => "restart",
        comment => "Restarting rsyslog after it's been updated";


  reports:

    syslogd::
      "@@Common@@log_info@@&TRACKINGKEY&@@Log system for reports@@None@@${g.execRun}##${g.uuid}@#Detected running syslog as syslogd";
    syslogng::
      "@@Common@@log_info@@&TRACKINGKEY&@@Log system for reports@@None@@${g.execRun}##${g.uuid}@#Detected running syslog as syslog-ng";
    rsyslogd::
      "@@Common@@log_info@@&TRACKINGKEY&@@Log system for reports@@None@@${g.execRun}##${g.uuid}@#Detected running syslog as rsyslog";

    syslogd_failed|syslog_ng_failed|rsyslog_failed::
      "@@Common@@result_error@@&TRACKINGKEY&@@Log system for reports@@None@@${g.execRun}##${g.uuid}@#Logging system could not be configured for report centralization";

    syslogd_repaired|syslog_ng_repaired|rsyslog_repaired::
      "@@Common@@result_repaired@@&TRACKINGKEY&@@Log system for reports@@None@@${g.execRun}##${g.uuid}@#Configured logging system for report centralization";

    (syslogd.syslogd_kept.!syslogd_failed.!syslogd_repaired)|(syslogng.syslog_ng_kept.!syslog_ng_failed.!syslog_ng_repaired)|(rsyslogd.rsyslog_kept.!rsyslog_failed.!rsyslog_repaired)::
      "@@Common@@result_success@@&TRACKINGKEY&@@Log system for reports@@None@@${g.execRun}##${g.uuid}@#Logging system for report centralization is already correctly configured";
}

#######################################################
# Check the version of rsyslog, and correct the conf
# file if > 5.7.1
# This is done in another bundle than check_log_system
# as it would make it too complex to read and maintain
# (we would have needed to delay the restart of the services
# at later iteration)

bundle agent check_rsyslog_version {
  vars:
    SuSE::
      "syslog_restart_cmd" string => "/etc/init.d/syslog restart";

    fedora::
      "syslog_restart_cmd" string => "/bin/systemctl restart rsyslog";

    !(SuSE|fedora)::
      "syslog_restart_cmd" string => "/etc/init.d/rsyslog restart";

  classes:
      "check_rsyslog_version_present" expression => fileexists("${g.rudder_dependencies}/check_rsyslog_version");
      "rsyslogd" expression => fileexists("/etc/rsyslog.conf");

  files:
    rsyslogd.rsyslog_greater_than_5_7_1::
      "/etc/rsyslog.d/remove_limit.conf"
        edit_line => append_if_no_lines("$SystemLogRateLimitInterval 0"),
        edit_defaults => noempty_backup,
        create    => "true",
        comment   => "Add a config line in the rsyslog.conf file to prevent from dropping rudder messages",
        classes   => rudder_common_classes("rsyslog_limit");

  commands:
    rsyslogd.check_rsyslog_version_present::
      "${g.rudder_dependencies}/check_rsyslog_version"
        contain => in_shell,
        module  => "true",
        comment => "Check rsyslog version in order to add or not a configuration line in rsyslog.conf";

    rsyslog_limit_repaired::
      "${syslog_restart_cmd}"
        args => "restart",
        classes => cf2_if_else("rsyslog_restarted", "cant_restart_rsyslog"),
        comment => "restarting rsyslog";
   
  reports:
    rsyslogd.!check_rsyslog_version_present::
      "@@Common@@result_error@@&TRACKINGKEY&@@Log system for reports@@None@@${g.execRun}##${g.uuid}@#The file  ${g.rudder_dependencies}/check_rsyslog_version is missing";

    rsyslog_limit_error::
      "@@Common@@result_error@@&TRACKINGKEY&@@Log system for reports@@None@@${g.execRun}##${g.uuid}@#Could not remove limitation of message in rsyslog";

    rsyslog_limit_repaired::
      "@@Common@@log_repaired@@&TRACKINGKEY&@@Log system for reports@@None@@${g.execRun}##${g.uuid}@#Updated the rsyslog configuration to remove limitation of messages";

    rsyslog_restarted::
      "@@Common@@log_repaired@@&TRACKINGKEY&@@Log system for reports@@None@@${g.execRun}##${g.uuid}@#Configured logging system for report centralization";

    cant_restart_rsyslog::
      "@@Common@@result_error@@&TRACKINGKEY&@@Log system for reports@@None@@${g.execRun}##${g.uuid}@#Could not restart the logging system";



}

#######################################################
# Check if the cron daemon is running
# This only works with unix flavoured systems too

bundle agent check_cron_daemon
{

  vars:

    redhat.!fedora::
      "cron_bin" string => "crond$";
      "cron_restartcmd" string => "/etc/init.d/crond restart";

    fedora::
      "cron_bin" string => "/usr/sbin/crond -n$";
      "cron_restartcmd" string => "/bin/systemctl restart crond.service";

    ubuntu::
      "cron_bin" string => "cron$";
      "cron_restartcmd" string => "/etc/init.d/cron restart";

    !(redhat|fedora|ubuntu)::
      "cron_bin" string => "/usr/sbin/cron$";
      "cron_restartcmd" string => "/etc/init.d/cron restart";

  processes:

      "${cron_bin}"
        restart_class => "restart_crond";

  commands:

    restart_crond::

      "${cron_restartcmd}"

        comment => "Restarting crond",
        classes => kept_if_else("crond_ok" ,"crond_restarted" , "crond_failed");

  reports:

    crond_failed::
      "@@Common@@result_error@@&TRACKINGKEY&@@CRON Daemon@@None@@${g.execRun}##${g.uuid}@#The CRON daemon was not running and could not be restarted";

    crond_restarted::
      "@@Common@@result_repaired@@&TRACKINGKEY&@@CRON Daemon@@None@@${g.execRun}##${g.uuid}@#The CRON daemon has been successfully restarted";

    !restart_crond.!crond_restarted.!crond_failed::
      "@@Common@@result_success@@&TRACKINGKEY&@@CRON Daemon@@None@@${g.execRun}##${g.uuid}@#The CRON daemon is running";

}

########################################################
# Trash every output report older than 30 days         #
########################################################

bundle agent garbage_collection
{

  files:

      "${sys.workdir}/outputs"

        delete => tidy,
        file_select => days_old("30"),
        depth_search => recurse("inf");

      "${g.rudder_var}/modified-files"

        delete => tidy,
        file_select => days_old("30"),
        depth_search => recurse("inf");

}

#######################################################
# Copy the CFengine binaries from the /opt repository
# to the CFengine working directory

bundle agent check_binaries_freshness
{

  vars:

    community_edition::

      "components" slist => { "cf-agent", "cf-serverd", "cf-execd", "cf-monitord", "cf-promises", "cf-runagent", "cf-report", "cf-key" };

    nova_edition::

      "components" slist => { "cf-agent", "cf-serverd", "cf-execd", "cf-monitord", "cf-promises", "cf-runagent", "cf-report", "cf-key", "cf-hub" };

  files:

      "${sys.workdir}/bin/${components}"
        perms => u_p("700"),
        copy_from => cp("${g.rudder_bin}/${components}", "localhost"),
        classes => kept_if_else("binaries_fresh", "binaries_rotten", "binaries_missing"),
        action => immediate,
        comment => "Copying the CFengine binaries from ${g.rudder_sbin}/sbin to ${sys.workdir}/bin";

  reports:

    binaries_fresh.!binaries_rotten.!binaries_missing::
      "@@Common@@result_success@@&TRACKINGKEY&@@Binaries update@@None@@${g.execRun}##${g.uuid}@#The CFengine binaries in ${sys.workdir}/bin are up to date";

    binaries_rotten.!binaries_missing::
      "@@Common@@result_repaired@@&TRACKINGKEY&@@Binaries update@@None@@${g.execRun}##${g.uuid}@#The CFengine binaries have been updated in ${sys.workdir}/bin";

    binaries_missing::
      "@@Common@@result_error@@&TRACKINGKEY&@@Binaries update@@None@@${g.execRun}##${g.uuid}@#An error occurred while updating the CFengine binaries in ${sys.workdir}/bin";

}

#######################################################

body agent control
{
    # if default runtime is 5 mins we need this for long jobs
        ifelapsed => "1";

    #define here some environment variables
        environment => { "DEBIAN_FRONTEND=noninteractive" };

        abortclasses => { "should_not_continue" };

        agentfacility => "LOG_LOCAL6";

  # Repository where to put the copy of modified files
    linux::
        default_repository => "${g.rudder_var}/modified-files";

&if(NOVA)&
#    windows::
#	default_repository => "c:\Program Files\Rudder\modified-files";
&endif&
}

#######################################################

body executor control
{
        splaytime => "1";

        exec_command => "${sys.cf_agent} -f failsafe.cf \&\& ${sys.cf_agent}";
        schedule         => { "Min00", "Min05", "Min10", "Min15", "Min20", "Min25", "Min30", "Min35", "Min40", "Min45", "Min50", "Min55" };
        executorfacility => "LOG_DAEMON";
}

########################################################

#Enforce that the file only contains this information
bundle edit_line enforce_content(str)
{

  delete_lines:
      "${str}" not_matching => "true";

  insert_lines:
      "${str}";
}

# Fix syslogd content : caution, the @ must be in the argument
bundle edit_line fix_syslogd(syslogd)
{
  delete_lines:
    any::
      "^(local6)\s+(?!${syslogd}).*"
        comment => "Delete missconfigured rudder syslogd destination";

  insert_lines:
    any::
      "# Rudder specific logging parameters";
      "local6.*						${syslogd}"
        comment => "Add the rudder syslogd destination";
}


bundle edit_line edit_syslog_conf_file(line_to_add, pattern_to_remove)
{

  delete_lines:
      "${pattern_to_remove}";
      "\$\(syslog_ng_conf\)";


  insert_lines:
      "${line_to_add}"
        location => syslogng_log_part;

}

body location syslogng_log_part
{

        select_line_matching => "^\s*log\s*\{.*";
        before_after => "before";
        first_last => "first";

}

bundle edit_line ensure_rsyslogd_on_suse
{
  field_edits:

      # match a line starting like 'SYSLOG_DAEMON=something'
      "^SYSLOG_DAEMON=.*$"
        edit_field => col("=","2","\"rsyslogd\"","set"),
        comment => "Match a line starting like key = something";
}
