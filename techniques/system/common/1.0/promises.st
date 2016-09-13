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

        protocol_version   => "classic";

        inputs => {
          @{va.ncf_inputs},
          &INPUTLIST&
        };

        bundlesequence => { @{va.bs} &BUNDLELIST& , @{va.end} };

    android::
        # if native syslog is not available, use cfengine implementation (eg: android)
        syslog_host => "${server_info.cfserved}";
        syslog_port => "&SYSLOGPORT&";
}

bundle common va
{
  vars:

      "end" slist => { "restart_services", "_clean_current_expected_reports_file", "endExecution" };

    policy_server::

      "bs" slist => {
        "startup",
        "check_disable_agent",
        "clean_red_button",
        "update",
        "configuration",
        "set_red_button",
        "internal_security",
        "check_red_button_status",
        "check_cf_processes",
        "check_uuid",
        "check_log_system",
        "check_rsyslog_version",
        "garbage_collection",
        "setup_cronjob",
        "check_cron_daemon",
        "check_binaries_freshness",
        "check_zypper",
        "get_environment_variables",
        "properties",
        "nxlog_enable",
        "configuration"
      };

    !policy_server::

      "bs" slist => {
        "startup",
        "check_disable_agent",
        "clean_red_button",
        "update",
        "configuration",
        "set_red_button",
        "internal_security",
        "check_red_button_status",
        "check_cf_processes",
        "garbage_collection",
        "setup_cronjob",
        "check_cron_daemon",
        "check_binaries_freshness",
        "check_log_system",
        "check_rsyslog_version",
        "nxlog_enable",
        "check_zypper",
        "check_uuid",
        "get_environment_variables",
        "properties",
        "configuration"
      };

    !android.!windows::
      "rudder_var"     string => "/var/rudder";
    android::
      "rudder_var"     string => "/data/rudder";

    !windows::
      "ncf_path"       string => "${rudder_var}/ncf";
      "rudder_tools"   string => "${rudder_var}/tools";
      "shell_type"     string => "useshell";
      "list_compatible_inputs" string => "NCF_CACHE_PATH=${sys.workdir}/state /bin/sh ${ncf_path}/common/10_ncf_internals/list-compatible-inputs";


    windows::
      "rudder_base"    string => "${sys.winprogdir}\Rudder";
      "rudder_tools"   string => "${rudder_base}\sbin";
      "ncf_path"       string => "${rudder_base}\var\ncf";
      "shell_type"     string => "powershell";
      # \& is for powershell commands
      "list_compatible_inputs" string => "\& '${ncf_path}\common\10_ncf_internals\list-compatible-inputs.ps1\'";

    any::
      "path_ncf_common_inputs_10" slist => splitstring(execresult("${list_compatible_inputs} ${sys.cf_version} '${ncf_path}' common/10_ncf_internals", "${shell_type}"), "\n", 10000);
      "path_ncf_common_inputs_20" slist => splitstring(execresult("${list_compatible_inputs} ${sys.cf_version} '${ncf_path}' common/20_cfe_basics", "${shell_type}"), "\n", 10000);
      "path_ncf_common_inputs_30" slist => splitstring(execresult("${list_compatible_inputs} ${sys.cf_version} '${ncf_path}' common/30_generic_methods", "${shell_type}"), "\n", 10000);
      "path_ncf_common_inputs_40" slist => splitstring(execresult("${list_compatible_inputs} ${sys.cf_version} '${ncf_path}' common/40_it_ops_knowledge", "${shell_type}"), "\n", 10000);
      "path_ncf_common_inputs_50" slist => splitstring(execresult("${list_compatible_inputs} ${sys.cf_version} '${ncf_path}' common/50_techniques", "${shell_type}"), "\n", 10000);
      "path_ncf_common_inputs_60" slist => splitstring(execresult("${list_compatible_inputs} ${sys.cf_version} '${ncf_path}' common/60_services", "${shell_type}"), "\n", 10000);

      "path_ncf_local_inputs_10" slist => splitstring(execresult("${list_compatible_inputs} ${sys.cf_version} '${ncf_path}' local/10_ncf_internals", "${shell_type}"), "\n", 10000);
      "path_ncf_local_inputs_20" slist => splitstring(execresult("${list_compatible_inputs} ${sys.cf_version} '${ncf_path}' local/20_cfe_basics", "${shell_type}"), "\n", 10000);
      "path_ncf_local_inputs_30" slist => splitstring(execresult("${list_compatible_inputs} ${sys.cf_version} '${ncf_path}' local/30_generic_methods", "${shell_type}"), "\n", 10000);
      "path_ncf_local_inputs_40" slist => splitstring(execresult("${list_compatible_inputs} ${sys.cf_version} '${ncf_path}' local/40_it_ops_knowledge", "${shell_type}"), "\n", 10000);
      "path_ncf_local_inputs_50" slist => splitstring(execresult("${list_compatible_inputs} ${sys.cf_version} '${ncf_path}' local/50_techniques", "${shell_type}"), "\n", 10000);
      "path_ncf_local_inputs_60" slist => splitstring(execresult("${list_compatible_inputs} ${sys.cf_version} '${ncf_path}' local/60_services", "${shell_type}"), "\n", 10000);

      # Must concatenate all lists + filter, as maplist on an empty element returns cf_null
      "raw_path_ncf_inputs" slist => { @{path_ncf_common_inputs_10}, @{path_ncf_local_inputs_10}, @{path_ncf_common_inputs_20}, @{path_ncf_local_inputs_20}, @{path_ncf_common_inputs_30}, @{path_ncf_local_inputs_30}, @{path_ncf_common_inputs_40}, @{path_ncf_local_inputs_40}, @{path_ncf_common_inputs_50}, @{path_ncf_local_inputs_50}, @{path_ncf_common_inputs_60}, @{path_ncf_local_inputs_60}},
                           policy => "ifdefined";

       "raw_ncf_inputs"     slist => maplist("${ncf_path}/${this}", @{raw_path_ncf_inputs});
       # Need to remove cf_null from the list
       "ncf_inputs"         slist => filter("${ncf_path}/cf_null", "raw_ncf_inputs", "false", "true", 10000);

    # definition of the machine roles
&NODEROLE&
}

bundle common rudder_roles
{

  classes:
      # Policy Server is a machine which delivers promises
      "policy_server" expression => strcmp("root","${g.uuid}");
      # Root Server is the top policy server machine
      "root_server" expression => strcmp("root","${g.uuid}");


      # on changes only, we only reports on repaired or error message
      "changes_only" expression => strcmp("&RUDDER_REPORT_MODE&", "changes-only");

      # full compliance is the default mode
      "full_compliance" not => "changes_only";
}

#########################################################
# Control execution
#########################################################
bundle agent startup
{
  methods:
    # Should we send a message stating this agent is starting up?
    # Always do it in "full_compliance" mode
    # In other modes, only do it here if we need to send it as a "heartbeat", that is if it hasn't already been sent recently enough
    full_compliance|!heartbeat_sent::
      "Send start message"
        usebundle => startExecution,
        action    => immediate;
}

##########################################################
# Check for "disable-agent" file and cleanly stop and
# warn about this if it is present
#
# All promises in this bundle MUST have action=>immediate,
# to avoid locking issues in case of several close runs.
##########################################################
bundle agent check_disable_agent
{
  vars:
      "components" slist => { "cf-serverd", "cf-execd", "cf-monitord" };

  classes:
      "should_disable_agent" expression => fileexists("${g.rudder_disable_agent_file}"),
                             action     => immediate;

      # Only define this class when we're ready to die - this is a special class name in "abortclasses"
      "should_not_continue"
        expression => "should_disable_agent.!ignore_disable_agent",
        ifvarclass => "abort_report_done",
        action     => immediate;

  processes:
    should_disable_agent::
      "${sys.workdir}/bin/${components}"
        signals       => { "term", "kill" },
        action        => immediate;

  reports:
    should_disable_agent::
      "FATAL: The file ${g.rudder_disable_agent_file} is present. Rudder will kill all running daemons and halt immediately."
        classes => if_ok("abort_report_done"),
        action  => immediate;

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

      "${sys.workdir}/inputs/stopFile"
        delete => tidy,
        comment => "Deleting the stop file, cfengine is good to go";

  methods:
    safe::
      "any" usebundle => rudder_common_report("Common", "result_repaired", "&TRACKINGKEY&", "Red Button", "None", "Authorizing Cfengine to restart");

  commands:
    safe.policy_server::
      "${sys.workdir}/bin/cf-runagent"
        args => "-Dsafe",
        comment => "Propagate the safe information to children";

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



  methods:
    danger.!policy_server::
      "any" usebundle => rudder_common_report("Common", "result_repaired", "&TRACKINGKEY&", "Red Button", "None", "Creating local stop file for this node");
    danger.policy_server::
      "any" usebundle => rudder_common_report("Common", "result_repaired", "&TRACKINGKEY&", "Red Button", "None", "Creating stop files for all clients of this policy server");

}

bundle agent stopClients
{
  classes:
    policy_server::
      "danger" expression => fileexists("${g.rudder_var}/share/root/stopFile");

  methods:
    danger.policy_server::
      "any" usebundle => rudder_common_report("Common", "log_repaired", "&TRACKINGKEY&", "Red Button", "None", "Actively stopping CFEngine operations on all clients of this policy server (via cf-runagent)");

  commands:
    danger.policy_server::
      "${sys.workdir}/bin/cf-runagent"
        args => "-Ddanger",
        comment => "Propagate the danger information to children";

}

bundle agent check_red_button_status()
{
  classes:
    !policy_server::
      "should_not_continue" expression => fileexists("${sys.workdir}/inputs/stopFile");

  methods:
    !should_not_continue::
      "any" usebundle => rudder_common_report("Common", "result_success", "&TRACKINGKEY&", "Red Button", "None", "Red Button is not in effect, continuing as normal...");

}


###################################################
# Check that CFEngine services are up
###################################################
bundle agent check_cf_processes
{
  methods:
    !ignore_disable_agent::
      "any" usebundle => check_cf_processes_running;
}
bundle agent check_cf_processes_running
{
  vars:

      # process_term defines how many maximum instances of this
      # binary should be running before attempting to SIGTERM them.
      # process_kill is the same for SIGKILL.
    !windows::
      # On windows, cf-execd is a service, and there can be only one instance of it running (by design)
      "process_term[execd]" string => "2";
      "process_kill[execd]" string => "5";

    any::
      "process_term[agent]" string => "5";
      "process_kill[agent]" string => "8";

      "binaries"            slist  => getindices("process_term");

  classes:
    any::
      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";

  methods:
    pass3::

      "any" usebundle => rudder_common_report("Common", "result_success", "&TRACKINGKEY&", "Process checking", "None", "There is an acceptable number of CFEngine processes running on the machine"),
      # Here, I can not use the binaries variable as CFEngine will iterate and output two reports, breaking the reporting.
        ifvarclass => "!agent_has_gone_wild.!agent_has_gone_really_wild.!execd_has_gone_wild.!execd_has_gone_really_wild";

      "any" usebundle => rudder_common_report("Common", "result_repaired", "&TRACKINGKEY&", "Process checking", "None", "Warning, more than ${process_term[${binaries}]} cf-${binaries} processes were detected. They have been sent a graceful termination signal."),
        ifvarclass => "${binaries}_has_gone_wild.!${binaries}_has_gone_really_wild";

      "any" usebundle => rudder_common_report("Common", "result_error", "&TRACKINGKEY&", "Process checking", "None", "ALERT: more than ${process_term[${binaries}]} cf-${binaries} processes were detected. Killing processes that do not respect graceful termination signals."),
        ifvarclass => "${binaries}_has_gone_really_wild";

  processes:
    windows::
      # Using the path on windows fails, as process are not reported the same way
      # And unfortunately, the cf-serverd is not a service.
      "cf-serverd"  restart_class => "start_server";

    !windows::

      "${sys.workdir}/bin/cf-serverd"  restart_class => "start_server";
      "${sys.workdir}/bin/cf-execd"    restart_class => "start_executor";

      # If there are more than 2 cf-execd's, it means cf-execd is starting to
      # go crazy, so we ask politely to these processes to shut down.

      "${sys.workdir}/bin/cf-${binaries}"
        process_count => check_range("${binaries}", "0","${process_term[${binaries}]}"),
        signals       => { "term" },
        classes       => if_repaired("${binaries}_has_gone_wild"),
        comment       => "Checking if cf-${binaries} has gone wild";

      # If there are too much cf-execd's/cf-agents running, it means that they are really
      # going crazy. Let's be a bit less polite and more violent about killing them.
      #
      # These two promises overlap, because when you go past the 2/5-limit treshold,
      # you still leave a chance for them to die with SIGTERM before the SIGKILL.
      #
      # Reason: The backend databases that stores the classes and some runtime
      # parameters do really not appreciate beeing killed violently and may prevent
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

  services:
    # By design, there can be only one cf-execd service running on Windows
    windows::
      "CfengineNovaExec"
        service_policy => "start",
        service_method => u_bootstart,
        comment => "Start the executor windows service now and at boot time";

&endif&

  commands:

    start_server::
      "${sys.cf_serverd}"
        action  => u_ifwin_bg,
        classes => outcome("server");

    start_executor::
      "${sys.cf_execd}"
        action  => u_ifwin_bg,
        classes => outcome("executor");

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

    use_tcp::
      "rsyslog_rule_prefix"   string => "@@";
      "syslogng_rule_prefix"  string => "tcp";
    use_udp::
      "rsyslog_rule_prefix"   string => "@";
      "syslogng_rule_prefix"  string => "udp";

    rsyslogd.rsyslog_version_5_6_4_ok::

      "rsyslogd_message_reduction" string => "$RepeatedMsgReduction off${const.n}";
      
    rsyslogd.rsyslog_version_5_6_4_not_ok::

      "rsyslogd_message_reduction" string => "";


    any::

      "syslog_conf_comment"   string => "# Autogenerated by rudder, do not edit${const.n}";
      "syslog_ng_conf_prefix" string => "filter f_local_rudder{facility(local6) and program(\"rudder.*\");};destination rudder_loghost {";
      "syslog_ng_conf_proto"  string => "${syslogng_rule_prefix}";
      "syslog_ng_conf_start"  string => "(\"";
      "syslog_ng_conf_port"   string => "\" port (";
      "syslog_ng_conf_portno" string => "&SYSLOGPORT&";
      "syslog_ng_conf_suffix" string => "));};log {source(${syslog_ng_source});filter(f_local_rudder);destination(rudder_loghost);";
      "syslog_ng_conf_final"  string => "flags(final);};";

      "syslog_ng_conf"        string => concat("${syslog_conf_comment}", "${syslog_ng_conf_prefix}", "${syslog_ng_conf_proto}", "${syslog_ng_conf_start}", "${server_info.cfserved}", "${syslog_ng_conf_port}", "${syslog_ng_conf_portno}", "${syslog_ng_conf_suffix}", "${syslog_ng_conf_final}");
      "syslog_ng_conf_regex"  string => concat(escape("${syslog_ng_conf_prefix}"), "(tcp|udp)", escape("${syslog_ng_conf_start}"), "[^\"]+", escape("${syslog_ng_conf_port}"), "[0-9]+", escape("${syslog_ng_conf_suffix}"), ".*");

  classes:

    !android::
      "rsyslogd" expression => fileexists("/etc/rsyslog.conf");

      "syslogng" expression => fileexists("/etc/syslog-ng/syslog-ng.conf");

      "syslogd" expression => fileexists("/etc/syslog.conf");

    any::
      "use_udp" expression => strcmp("&RUDDER_SYSLOG_PROTOCOL&", "UDP");
      "use_tcp" expression => strcmp("&RUDDER_SYSLOG_PROTOCOL&", "TCP");

      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";

      "check_rsyslog_version_present" expression => fileexists("${g.rudder_tools}/check-rsyslog-version");

  files:

    !windows.rsyslogd::
      "/etc/rsyslog.conf"
        edit_line => append_if_no_lines("$IncludeConfig /etc/rsyslog.d/*.conf"),
        edit_defaults => noempty_backup,
        comment => "Add the rsyslog.conf.d include if not already present",
        classes => kept_if_else("rsyslog_kept", "rsyslog_repaired" , "rsyslog_failed");

    (rsyslog_version_5_6_4_ok|rsyslog_version_5_6_4_not_ok).!windows.rsyslogd.!policy_server::
      "/etc/rsyslog.d/rudder-agent.conf"
        edit_line => append_if_no_lines("#Rudder log system${const.n}${rsyslogd_message_reduction}${const.n}if $syslogfacility-text == 'local6' and $programname startswith 'rudder' then ${rsyslog_rule_prefix}${server_info.cfserved}:&SYSLOGPORT&${const.n}if $syslogfacility-text == 'local6' and $programname startswith 'rudder' then ~"),
        create => "true",
        edit_defaults => empty_backup,
        classes       => rudder_common_classes("rsyslog");

    SuSE.rsyslogd.policy_server::
      # For SuSE, ensure that SYSLOG_DAEMON is set to 'rsyslogd' even if another syslog has been installed before
      "/etc/sysconfig/syslog"
        edit_line => ensure_rsyslogd_on_suse,
        edit_defaults => noempty_backup,
        classes       => rudder_common_classes("rsyslog");

    !windows.syslogng.!policy_server::
      "/etc/syslog-ng/syslog-ng.conf"
        edit_line => edit_syslog_conf_file("${syslog_ng_conf}", "${syslog_ng_conf_regex}"),
        edit_defaults => noempty_backup,
        classes       => rudder_common_classes("syslog_ng");

    !windows.syslogd.!policy_server::
      "/etc/syslog.conf"
        edit_line => fix_syslogd("@${server_info.cfserved}"),
        edit_defaults => noempty_backup,
        classes       => rudder_common_classes("syslogd");

  methods:

    pass2.syslogd::
      "any" usebundle => rudder_common_report("Common", "log_info", "&TRACKINGKEY&", "Log system for reports", "None", "Detected running syslog as syslogd");

    pass2.syslogng::
      "any" usebundle => rudder_common_report("Common", "log_info", "&TRACKINGKEY&", "Log system for reports", "None", "Detected running syslog as syslog-ng");

    pass2.rsyslogd::
      "any" usebundle => rudder_common_report("Common", "log_info", "&TRACKINGKEY&", "Log system for reports", "None", "Detected running syslog as rsyslog");

    pass3.(syslogd_failed|syslog_ng_failed|rsyslog_failed)::
      "any" usebundle => rudder_common_report("Common", "result_error", "&TRACKINGKEY&", "Log system for reports", "None", "Logging system could not be configured for report centralization");

    pass3.!(syslogd_failed|syslog_ng_failed|rsyslog_failed).(syslogd_repaired|syslog_ng_repaired|rsyslog_repaired)::
      "any" usebundle => rudder_common_report("Common", "result_repaired", "&TRACKINGKEY&", "Log system for reports", "None", "Configured logging system for report centralization");

    pass3.!(syslogd_failed|syslog_ng_failed|rsyslog_failed).!(syslogd_repaired|syslog_ng_repaired|rsyslog_repaired).(syslogd.syslogd_kept|syslogng.syslog_ng_kept|rsyslogd.rsyslog_kept))::
      "any" usebundle => rudder_common_report("Common", "result_success", "&TRACKINGKEY&", "Log system for reports", "None", "Logging system for report centralization is already correctly configured");

    pass3.android::
      "any" usebundle => rudder_common_report("Common", "result_success", "&TRACKINGKEY&", "Log system for reports", "None", "This is an android machine: Logging system configuration skipped.");

  commands:

    solaris.(syslog_ng_repaired|rsyslog_repaired|syslogd_repaired)::
      "${paths.svcadm} refresh svc:/system/system-log:default";

    aix.syslogd_repaired::
      "/usr/bin/refresh -s syslogd";
      
    rsyslogd.check_rsyslog_version_present::
      # 5.6.4 is the first version mentionning RepeatedMsgReduction in http://www.rsyslog.com/change-log/
      # The option is probably older though.
      "${g.rudder_tools}/check-rsyslog-version 5.6.4"
        contain => in_shell,
        module  => "true",
        comment => "Check rsyslog version to know if it supports RepeatedMsgReduction";

}

#######################################################
# Check the version of rsyslog, and correct the conf
# file if > 5.7.1
# This is done in another bundle than check_log_system
# as it would make it too complex to read and maintain
# (we would have needed to delay the restart of the services
# at later iteration)

bundle agent check_rsyslog_version {

  classes:
      "check_rsyslog_version_present" expression => fileexists("${g.rudder_tools}/check-rsyslog-version");
      "rsyslogd" expression => fileexists("/etc/rsyslog.conf");

    any::
      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";

  files:
    rsyslogd.rsyslog_version_5_7_1_ok::
      "/etc/rsyslog.d/remove_limit.conf"
        edit_line => append_if_no_lines("$SystemLogRateLimitInterval 0"),
        edit_defaults => noempty_backup,
        create    => "true",
        comment   => "Add a config line in the rsyslog.conf file to prevent from dropping rudder messages",
        classes   => rudder_common_classes("rsyslog_limit");

  methods:

    pass3.(rsyslogd.!check_rsyslog_version_present)::
      "any" usebundle => rudder_common_report("Common", "result_error", "&TRACKINGKEY&", "Log system for reports", "None", "The file  ${g.rudder_tools}/check-rsyslog-version is missing");

    pass3.rsyslog_limit_error::
      "any" usebundle => rudder_common_report("Common", "result_error", "&TRACKINGKEY&", "Log system for reports", "None", "Could not remove limitation of message in rsyslog");

    pass3.rsyslog_limit_repaired::
      "any" usebundle => rudder_common_report("Common", "log_repaired", "&TRACKINGKEY&", "Log system for reports", "None", "Updated the rsyslog configuration to remove limitation of messages");

  commands:
    rsyslogd.check_rsyslog_version_present::
      "${g.rudder_tools}/check-rsyslog-version"
        contain => in_shell,
        module  => "true",
        comment => "Check rsyslog version in order to add or not a configuration line in rsyslog.conf";

}

###################################################################
# Trash every output report and modified files older than the TTL #
###################################################################

bundle agent garbage_collection
{
  vars:
      "log_files_to_rotate" slist => {
					"${sys.workdir}/cf3.${sys.uqhost}.runlog",
                                        "${sys.workdir}/promise_summary.log",
                                        "${sys.workdir}/cf_notkept.log",
                                        "${sys.workdir}/cf_repair.log",
				     };

  files:

      "${sys.workdir}/outputs"

        delete => tidy,
        file_select => days_old("&CFENGINE_OUTPUTS_TTL&"),
        depth_search => recurse("inf"),
        action => if_elapsed_day;

      "${g.rudder_var}/modified-files"

        delete => tidy,
        file_select => days_old("&MODIFIED_FILES_TTL&"),
        depth_search => recurse("inf");

      "${log_files_to_rotate}"
        comment     => "Rotate file if above specified size",
        rename      => rotate("10"),
        file_select => bigger_than("1M");

  methods:

       # Directly call the cleanup bundle from ncf's logger_rudder
       "clean old expected reports files" usebundle => _clean_old_expected_reports_file("&CFENGINE_OUTPUTS_TTL&");

}

#######################################################
# Copy the CFEngine binaries from the /opt repository
# to the CFEngine working directory

bundle agent check_binaries_freshness
{

  vars:

    community_edition::

      "components" slist => { "cf-agent", "cf-serverd", "cf-execd", "cf-monitord", "cf-promises", "cf-runagent", "cf-key", "rpmvercmp" };

  files:

    !android.!nova_edition::
      "${sys.workdir}/bin/${components}"
        perms => u_p("700"),
        copy_from => cp("${g.rudder_bin}/${components}", "localhost"),
        classes => kept_if_else("binaries_fresh", "binaries_rotten", "binaries_missing"),
        action => immediate,
        comment => "Copying the CFEngine binaries from ${g.rudder_sbin}/sbin to ${sys.workdir}/bin";

  methods:

    binaries_fresh.!binaries_rotten.!binaries_missing::
      "any" usebundle => rudder_common_report("Common", "result_success", "&TRACKINGKEY&", "Binaries update", "None", "The CFEngine binaries in ${sys.workdir}/bin are up to date");

    binaries_rotten.!binaries_missing::
      "any" usebundle => rudder_common_report("Common", "result_repaired", "&TRACKINGKEY&", "Binaries update", "None", "The CFEngine binaries have been updated in ${sys.workdir}/bin");

    binaries_missing::
      "any" usebundle => rudder_common_report("Common", "result_error", "&TRACKINGKEY&", "Binaries update", "None", "An error occurred while updating the CFEngine binaries in ${sys.workdir}/bin");

    android::
      "any" usebundle => rudder_common_report("Common", "result_success", "&TRACKINGKEY&", "Binaries update", "None", "This is an android machine: no CFEngine binaries update needed");

    nova_edition::
      "any" usebundle => rudder_common_report("Common", "result_na", "&TRACKINGKEY&", "Binaries update", "None", "This is an CFEngine enterprise system: binaries update are handled differently");

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

        skipidentify => "&SKIPIDENTIFY&";

  # Repository where to put the copy of modified files
        default_repository => "${g.rudder_var}/modified-files";

}

#######################################################

body executor control
{
        splaytime => "&AGENT_RUN_SPLAYTIME&";
        schedule         => { &AGENT_RUN_SCHEDULE& };
        executorfacility => "LOG_DAEMON";

   windows::
        # CFEngine best practice is to use full paths on Windows
        exec_command => "${sys.cf_agent} -f \"${sys.workdir}\inputs\failsafe.cf\" \& ${sys.cf_agent}";

   !windows::
        exec_command => "${sys.cf_agent} -f failsafe.cf \&\& ${sys.cf_agent}";

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

      "^\s*local6.*"
        comment => "Delete all local6 facility related lines";

  insert_lines:

      "# Rudder specific logging parameters";
      "local6.notice ${syslogd}"
        comment => "Add the rudder syslogd destination";

}


bundle edit_line edit_syslog_conf_file(line_to_add, pattern_to_remove)
{

  delete_lines:
      "${pattern_to_remove}";

      # Remove any unexpanded variables that may have slipped through due to old bugs or race conditions at installation time
      "\$\(syslog_ng_conf\)";
      "\$\{syslog_ng_conf\}";

      # Remove the syslog config when the loghost was just called "loghost" (now called "rudder_loghost")
      # This was used in Rudder pre-3.0. We need to keep this in all versions that support upgrading from pre-3.0 versions (up to and including 2.11)
      # See http://www.rudder-project.org/redmine/issues/5773
      "filter\ f\_local\_rudder\{facility\(local6\)\ and\ program\(\"rudder\.\*\"\)\;\}\;destination\ loghost\ \{(tcp|udp)\(\"[^\"]+\".*";

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
