#####################################################################################
# Copyright 2011-2017 Normation SAS
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

######################################################
# Configure the ntp
# If ntp is not installed, install it (linux)
# Change the server configuration, and restart the daemon
# if the configuration changed
# Caution : a missing feature in cfe prevents from adding ,0x1 at the end of the domain name
# so it's only safe to use with ips for now

bundle agent check_clock_configuration
{

  vars:
      "technique_name" string => "ntpConfiguration";
      "ntpServers" slist => {&CLOCK_NTPSERVERS: { "&it&"};separator=", "&};

      "target_timezone" string => ifelse( strcmp("&CLOCK_TIMEZONE&", "custom"), "&CLOCK_TIMEZONE_CUSTOM&", "&CLOCK_TIMEZONE&" );

    # Package name def

    !SuSE_10::
      "rudder_ntp_package_name" string => "ntp";
    SuSE_10::
      "rudder_ntp_package_name" string => "xntp";

    # Service name def
    aix:: 
      "rudder_ntp_service_name" string => "xntpd";
    redhat::
      "rudder_ntp_service_name" string => "ntpd";
    !redhat.!aix::
      "rudder_ntp_service_name" string => "ntp";

    !aix::
      "rudder_ntp_timezone" string => "${tz_variables.tz_linux[${target_timezone}]}";
      "rudder_ntp_timezone_path_canonified" string => canonify("/usr/share/zoneinfo/${rudder_ntp_timezone}");

    # Only used in log reporting
    SuSE.!systemd::
      "reporting_timezone_file" string => "(/etc/sysconfig/clock)";
      "reporting_timezone_name" string => "SuSE";
    redhat.!systemd::
      "reporting_timezone_file" string => "(/etc/sysconfig/clock)";
      "reporting_timezone_name" string => "Redhat";
    debian.!systemd::
      "reporting_timezone_file" string => "(/etc/timezone)";
      "reporting_timezone_name" string => "Debian";
    systemd::
      "reporting_timezone_file" string => "";
      "reporting_timezone_name" string => "Systemd";


  classes:

    !aix::
      "clock_vardef" expression => isvariable("tz_variables.tz_linux[${target_timezone}]");
    
    any::
      # We don't edit the TZ if no valid variable is present - probably user input field gone wrong.
      "clock_timezone_nochange" expression => strcmp("&CLOCK_TIMEZONE&","dontchange");
      "clock_timezone_noedit"   expression => "clock_timezone_nochange|!clock_vardef";

      "clock_hwclock_sync"      expression => strcmp("&CLOCK_HWSYNC_ENABLE&","true");

      "ntp_enabled"             expression => strcmp("&SYNCH_ENABLED&","true");
      "ntp_config_file_exists"  expression => fileexists("/etc/ntp.conf");

      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";

  files:

    # Adjust ntp.conf (Add the servers)
    ntp_config_file_exists|(package_present_ntp_repaired|package_present_xntp_repaired)::
      "/etc/ntp.conf"
        edit_line => setNtpServer("@{this.ntpServers}"),
        edit_defaults => noempty_backup,
        classes => kept_if_else("ntpconf_kept", "ntpconf_repaired", "ntpconf_error");

    # Copy the correct localtime file (distro independant)
    !aix.!clock_timezone_noedit::
      "/etc/localtime"
        copy_from => digest_cp("/usr/share/zoneinfo/${rudder_ntp_timezone}"),
        perms => system_owned("0644"),
        comment => "Updating the /etc/localtime file",
        classes => kept_if_else("localtime_kept", "localtime_repaired", "localtime_error");

    # Edit the distro dependant files to set the TZ on boot
    !systemd.redhat.!clock_timezone_noedit::
      "/etc/sysconfig/clock"
        edit_line => EditCentOSTimezone("${rudder_ntp_timezone}"),
        edit_defaults => noempty_backup,
        classes => kept_if_else("redhattz_kept", "redhattz_repaired", "redhattz_error");

    !systemd.SuSE.!clock_timezone_noedit::
      "/etc/sysconfig/clock"
        edit_line => EditSuSETimezone("${rudder_ntp_timezone}"),
        edit_defaults => noempty_backup,
        classes => kept_if_else("susetz_kept", "susetz_repaired", "susetz_error");

    !systemd.debian.!clock_timezone_noedit::
      "/etc/timezone"
        edit_defaults => empty_backup,
        edit_line => EditDebianTimezone("${rudder_ntp_timezone}"),
        classes => kept_if_else("debiantz_kept", "debiantz_repaired", "debiantz_error");

  methods:
    ntp_enabled::
    # Install the NTP package
      "ntp" usebundle => package_present("${rudder_ntp_package_name}", "latest", "default", "default");

    # Service commands
      "start_ntp_service" usebundle => service_ensure_running("${rudder_ntp_service_name}");

    ntp_enabled.(ntpconf_repaired|localtime_repaired|debiantz_repaired|susetz_repaired|redhattz_repaired)::
      "restart_ntp_service" usebundle => service_restart("${rudder_ntp_service_name}");

    ## Reporting

    pass3.!ntp_enabled::
      "any" usebundle => rudder_common_report("${technique_name}", "result_na", "&TRACKINGKEY&", "Package status",    "None", "Time synch is not managed by this technique, skipping");
      "any" usebundle => rudder_common_report("${technique_name}", "result_na", "&TRACKINGKEY&", "Service status",    "None", "Time synch is not managed by this technique, skipping");
      "any" usebundle => rudder_common_report("${technique_name}", "result_na", "&TRACKINGKEY&", "Service restart",   "None", "Time synch is not managed by this technique, skipping");
      "any" usebundle => rudder_common_report("${technique_name}", "result_na", "&TRACKINGKEY&", "Time synch configuration", "None", "Time synch is not managed by this technique, skipping");

    pass3.ntp_enabled::
    # Package install
      "package_install" usebundle => rudder_common_reports_generic("${technique_name}", "package_present_${rudder_ntp_package_name}", "&TRACKINGKEY&", "Package status", "None", "The ${rudder_ntp_package_name} package presence");

    # Service running
      "service_running" usebundle => rudder_common_reports_generic("${technique_name}", "service_ensure_running_${rudder_ntp_service_name}", "&TRACKINGKEY&", "Service status", "None", "Service ${rudder_ntp_service_name} running state");

    # Service restart
      "service_restart" usebundle => rudder_common_reports_generic("${technique_name}", "service_restart_${rudder_ntp_service_name}", "&TRACKINGKEY&", "Service restart", "None", "Service ${rudder_ntp_package_name} restart"),
        ifvarclass => "ntpconf_repaired|localtime_repaired|debiantz_repaired|susetz_repaired|redhattz_repaired";

      "any" usebundle => rudder_common_report("${technique_name}", "result_na", "&TRACKINGKEY&", "Service restart", "None", "${rudder_ntp_service_name} did not need to be restarted"),
        ifvarclass => "!(ntpconf_repaired|localtime_repaired|debiantz_repaired|susetz_repaired|redhattz_repaired)";

    # NTP conf file
      "any" usebundle => rudder_common_report("ntpConfiguration", "result_repaired", "&TRACKINGKEY&", "Time synch configuration", "None", "${rudder_ntp_service_name} configuration updated"),
        ifvarclass => "ntpconf_repaired";

      "any" usebundle => rudder_common_report("ntpConfiguration", "result_error", "&TRACKINGKEY&", "Time synch configuration", "None", "${rudder_ntp_service_name} configuration could not be changed"),
        ifvarclass => "ntpconf_error";

      "any" usebundle => rudder_common_report("ntpConfiguration", "result_success", "&TRACKINGKEY&", "Time synch configuration", "None", "${rudder_ntp_service_name} configuration was kept"),
        ifvarclass => "ntpconf_kept";

    # Global reports for the "Time zone" component's parts
    pass3.aix::
      "any" usebundle => rudder_common_report("ntpConfiguration", "result_na", "&TRACKINGKEY&", "Time zone", "None", "Time zone is not managed on AIX nodes");

    pass3.(localtime_repaired|redhattz_repaired|debiantz_repaired|susetz_repaired)::
      "any" usebundle => rudder_common_report("ntpConfiguration", "result_repaired", "&TRACKINGKEY&", "Time zone", "None", "Time zone ${target_timezone} was reset");

    pass3.localtime_kept.!localtime_repaired.!localtime_error.(systemd|(redhat.redhattz_kept)|(debian.debiantz_kept)|(SuSE.susetz_kept))::
      "any" usebundle => rudder_common_report("ntpConfiguration", "result_success", "&TRACKINGKEY&", "Time zone", "None", "Time zone ${target_timezone} was already correctly configured");

    pass3.clock_timezone_nochange.!aix::
      "any" usebundle => rudder_common_report("ntpConfiguration", "result_na", "&TRACKINGKEY&", "Time zone", "None", "Time zone edition disabled");

    pass3.!clock_timezone_nochange.!clock_vardef::
      "any" usebundle => rudder_common_report("ntpConfiguration", "result_error", "&TRACKINGKEY&", "Time zone", "None", "Time zone provided is not valid: ${target_timezone}");

    pass3.localtime_error.!(redhattz_error|debiantz_error|susetz_error)::
      "any" usebundle => rudder_common_report("ntpConfiguration", "result_error", "&TRACKINGKEY&", "Time zone", "None", "Time zone ${target_timezone} could not be set (localtime file could not be changed)");
    pass3.(redhattz_error|debiantz_error|susetz_error)::
      "any" usebundle => rudder_common_report("ntpConfiguration", "result_error", "&TRACKINGKEY&", "Time zone", "None", "Could not update ${reporting_timezone_name}-style time zone parameters ${reporting_timezone_file}");

    # Global reports for the "Hardware clock (RTC)" component
    pass3.aix::
      "any" usebundle => rudder_common_report("ntpConfiguration", "result_na", "&TRACKINGKEY&", "Hardware clock (RTC)", "None", "Hardware clock is not synchronized on AIX");

    pass3.(!aix.!ntp_hwclock_sync_error.!ntp_hwclock_synced.clock_hwclock_sync)::
      "any" usebundle => rudder_common_report("ntpConfiguration", "result_success", "&TRACKINGKEY&", "Hardware clock (RTC)", "None", "It is not yet time to synchronize the hardware clock with the NTP time. Skipping...");

    pass3.ntp_hwclock_synced::
      "any" usebundle => rudder_common_report("ntpConfiguration", "result_success", "&TRACKINGKEY&", "Hardware clock (RTC)", "None", "The hardware clock has been synchronized with the NTP time");

    pass3.ntp_hwclock_sync_error::
      "any" usebundle => rudder_common_report("ntpConfiguration", "result_error", "&TRACKINGKEY&", "Hardware clock (RTC)", "None", "The hardware clock could not be synchronized with the NTP time");

    pass3.!clock_hwclock_sync.!aix::
      "any" usebundle => rudder_common_report("ntpConfiguration", "result_na", "&TRACKINGKEY&", "Hardware clock (RTC)", "None", "No synchronization with the hardware clock was requested");

  commands:

    # HW clock sync command
    !aix.clock_hwclock_sync::
      "/sbin/hwclock"
        args => "--systohc",
        action => if_elapsed("&CLOCK_SYNCSCHED&"),
        classes => cf2_if_else("ntp_hwclock_synced", "ntp_hwclock_sync_error"),
        comment => "synchronizing hardware clock";
}

bundle edit_line setNtpServer(serverlist)
{
  delete_lines:
      "server.*";

  insert_lines:
      "${rudder_parameters.rudder_file_edit_header}"
        location => start,
        insert_type => "preserve_block";

      "server ${serverlist}";

}

bundle edit_line EditCentOSTimezone(tz)
{

  insert_lines:
      "${rudder_parameters.rudder_file_edit_header}"
        location => start,
        insert_type => "preserve_block";

  replace_patterns:

# Ensure the ZONE is correct

      "^[# ]*ZONE\=(?!${tz}).*$"

        replace_with => value("ZONE=${tz}");

# Change UTC

      "^[# ]*UTC=\+.*$"
        replace_with => value("UTC=false");

# Change ARC

      "^[# ]*ARC\s+.*$"
        replace_with => value("ARC=false");
}

bundle edit_line EditSuSETimezone(tz)
{

  insert_lines:
      "${rudder_parameters.rudder_file_edit_header}"
        location => start,
        insert_type => "preserve_block";

  replace_patterns:

# Ensure the TIMEZONE is correct

      "^[# ]*TIMEZONE\=(?!\"${tz}\").*$"

        replace_with => value("TIMEZONE=\"${tz}\"");

# Ensure the DEFAULT_TIMEZONE is correct

      "^[# ]*DEFAULT_TIMEZONE\=(?!\"${tz}\").*$"

        replace_with => value("DEFAULT_TIMEZONE=\"${tz}\"");

# Ensure the SYSTOHC is correct

      "^[# ]*SYSTOHC\=(?!\"yes\").*$"

        replace_with => value("SYSTOHC=\"yes\"");

}

bundle edit_line EditDebianTimezone(tz)
{

  insert_lines:

# Ensure the ZONE is correct

      "${tz}";

}
