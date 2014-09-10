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
      "ntpServers" slist => {&CLOCK_NTPSERVERS: { "&it&"};separator=", "&};

    windows::
      # For windows, we must extract both ip and domain name values
      #"ipv4" slist => grep("(?:\\d{1,3}\.){3}\\d{1,3}","ntpServers");

      #domain slist => not one of the above
      # check that list aren't empty using reglist

      &if(CLOCK_FQDNNTP)&
      "keytemp" string => join("\,0x1 ", ntpServers);
      "serverskey" string => "${keytemp}\,0x1";
      &else&
      "serverskey" string => join(" ", ntpServers);
      &endif&


    clock_set_france::

      "linux_timezone" string => "Europe/Paris";
      "windows_timezone" string => "Romance Standard Time";

    clock_set_uk::

      "linux_timezone" string => "Europe/London";
      "windows_timezone" string => "GMT Standard Time";

    clock_set_germany::

      "linux_timezone" string => "Europe/Berlin";
      "windows_timezone" string => "W. Europe Standard Time";

    clock_set_spain::

      "linux_timezone" string => "Europe/Madrid";
      "windows_timezone" string => "Romance Standard Time";

    clock_set_italy::

      "linux_timezone" string => "Europe/Rome";
      "windows_timezone" string => "W. Europe Standard Time";

    clock_set_us_pacific::

      "linux_timezone" string => "US/Pacific";
      "windows_timezone" string => "Pacific Standard Time";

    clock_set_us_mountain::

      "linux_timezone" string => "US/Mountain";
      "windows_timezone" string => "Mountain Standard Time";

    clock_set_us_central::

      "linux_timezone" string => "US/Central";
      "windows_timezone" string => "Central Standard Time";

    clock_set_eastern::

      "linux_timezone" string => "US/Eastern";
      "windows_timezone" string => "Eastern Standard Time";

    clock_set_canada::

      "linux_timezone" string => "America/Canada";
      "windows_timezone" string => "Atlantic Standard Time";

    clock_set_belgium::

      "linux_timezone" string => "Europe/Brussels";
      "windows_timezone" string => "Romance Standard Time";

    clock_set_luxembourg::

      "linux_timezone" string => "Europe/Luxembourg";
      "windows_timezone" string => "Romance Standard Time";

    clock_set_netherlands::

      "linux_timezone" string => "Europe/Amsterdam";
      "windows_timezone" string => "W. Europe Standard Time";

    clock_set_norway::

      "linux_timezone" string => "Europe/Oslo";
      "windows_timezone" string => "Romance Standard Time";

    clock_set_beijing::

      "linux_timezone" string => "Europe/Paris";
      "windows_timezone" string => "China Standard Time";

  classes:

    (linux|windows)::

      "clock_vardef" expression => isvariable("linux_timezone");

      "clock_timezone_noedit" expression => strcmp("&CLOCK_TIMEZONE&","dontchange");

      "clock_set_france" expression => strcmp("&CLOCK_TIMEZONE&","france");
      "clock_set_uk" expression => strcmp("&CLOCK_TIMEZONE&","uk");
      "clock_set_germany" expression => strcmp("&CLOCK_TIMEZONE&","germany");
      "clock_set_spain" expression => strcmp("&CLOCK_TIMEZONE&","spain");
      "clock_set_italy" expression => strcmp("&CLOCK_TIMEZONE&","italy");
      "clock_set_us_pacific" expression => strcmp("&CLOCK_TIMEZONE&","us-pacific");
      "clock_set_us_mountain" expression => strcmp("&CLOCK_TIMEZONE&","us-mountain");
      "clock_set_us_central" expression => strcmp("&CLOCK_TIMEZONE&","us-central");
      "clock_set_us_eastern" expression => strcmp("&CLOCK_TIMEZONE&","us-eastern");
      "clock_set_canada" expression => strcmp("&CLOCK_TIMEZONE&","canada");
      "clock_set_belgium" expression => strcmp("&CLOCK_TIMEZONE&","belgium");
      "clock_set_luxembourg" expression => strcmp("&CLOCK_TIMEZONE&","luxembourg");
      "clock_set_netherlands" expression => strcmp("&CLOCK_TIMEZONE&","netherlands");
      "clock_set_norway" expression => strcmp("&CLOCK_TIMEZONE&","norway");
      "clock_set_beijing" expression => strcmp("&CLOCK_TIMEZONE&","beijing");
  files:

    # Adjust ntp.conf (Add the servers)
    (debian|redhat|SuSE)::
      "/etc/ntp.conf"
        edit_line => setNtpServer("@{this.ntpServers}"),
        edit_defaults => noempty_backup,
        classes => kept_if_else("ntpconf_kept", "repaired_ntpconf", "not_repaired_ntpconf");

    # Copy the correct localtime file (distro independant)
    !clock_timezone_noedit.linux.clock_vardef::
      "/etc/localtime"
        copy_from => digest_cp("/usr/share/zoneinfo/${linux_timezone}"),
        comment => "Updating the /etc/localtime file",
        classes => kept_if_else("localtime_kept", "repaired_localtime", "not_repaired_localtime");

    # Edit the distro dependant files to set the TZ on boot
    (redhat.!clock_timezone_noedit).clock_vardef::
      "/etc/sysconfig/clock"
        edit_line => EditCentOSTimezone("${linux_timezone}"),
        edit_defaults => noempty_backup,
        classes => kept_if_else("redhattz_kept", "repaired_redhattz", "not_repaired_redhattz");

    (SuSE.!clock_timezone_noedit).clock_vardef::
      "/etc/sysconfig/clock"
        edit_line => EditSuSETimezone("${linux_timezone}"),
        edit_defaults => noempty_backup,
        classes => kept_if_else("susetz_kept", "repaired_susetz", "not_repaired_susetz");

    (debian.!clock_timezone_noedit).clock_vardef::
      "/etc/timezone"
        edit_defaults => empty_backup,
        edit_line => EditDebianTimezone("${linux_timezone}"),
        classes => kept_if_else("debiantz_kept", "repaired_debiantz", "not_repaired_debiantz");

  # Install the NTP package
  packages:
    debian.!redhat::
      "ntp"
        package_policy  => "add",
        package_method  => apt,
        classes => kept_if_else("ntp_install_kept", "ntp_installed", "cant_install_ntp"),
        comment => "Installing ntp using apt";

    redhat::
      "ntp"
        package_policy  => "add",
        package_method  => rudder_yum,
        classes => kept_if_else("ntp_install_kept", "ntp_installed", "cant_install_ntp"),
        comment => "Installing ntp using yum";

    SuSE_11::
      "ntp"
        package_policy => "add",
        package_method => zypper,
        classes => kept_if_else("ntp_install_kept", "ntp_installed", "cant_install_ntp"),
        comment => "Installing ntp using zypper";
    SuSE_10::
      "xntp"
        package_policy => "add",
        package_method => rudder_rug,
        classes => kept_if_else("ntp_install_kept", "ntp_installed", "cant_install_ntp"),
        comment => "Installing xntp using rug";

  processes:

    # If NTP is down, define its restart class
      "ntpd"
        restart_class => "ntpd_down";

  commands:

    # Restart commands
    (debian|SuSE).(repaired_ntpconf|repaired_localtime|repaired_debiantz|repaired_susetz|ntpd_down)::
      "/etc/init.d/ntp"
        args => "restart",
        classes => cf2_if_else("ntp_restarted", "cant_restart_ntp"),
        comment => "restarting ntp";

    redhat.(repaired_ntpconf|repaired_localtime|repaired_redhattz|ntpd_down)::
      "/etc/init.d/ntpd"
        args => "restart",
        classes => cf2_if_else("ntp_restarted", "cant_restart_ntp"),
        comment => "restarting ntp";

    (windows.!clock_timezone_noedit).clock_vardef::
      "\"${sys.winsysdir}\rundll32.exe\""
        args => "shell32.dll,Control_RunDLL %SystemRoot%\system32\TIMEDATE.cpl,,/Z ${windows_timezone}",
        contain => in_shell,
        comment => "set the windows time zone";

    (windows.!clock_timezone_noedit).ntp_regset::
      "\"${sys.winsysdir}\net.exe\""
        args => "stop W32Time",
        contain => in_shell,
        classes => cf2_if_else("ntp_winsvcstop", "ntp_winsvcstop"),
        comment => "Restart the windows NTP service";

    (windows.!clock_timezone_noedit).ntp_winsvcstop::
      "\"${sys.winsysdir}\net.exe\""
        args => "start W32Time",
        contain => in_shell,
        classes => cf2_if_else("ntp_win32time_started", "ntp_win32time_error"),
        comment => "Restart the windows NTP service";

    # HW clock sync command
    (debian|redhat|SuSE)::
      "/sbin/hwclock"
        args => "--systohc",
        action => if_elapsed("&CLOCK_SYNCSCHED&"),
        classes => cf2_if_else("ntp_hwclock_synced", "ntp_hwclock_sync_error"),
        comment => "synchronizing hardware clock";

&if(NOVA)&
  databases:

    windows::

      "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\W32Time\Parameters"

        database_operation => "create",
        database_rows => { "Type,REG_SZ,NTP", "NtpServer,REG_SZ,${serverskey}"},
        database_type => "ms_registry",
        comment => "Editing the windows registry to set the required NTP entries",
        classes => kept_if_else("ntp_regkept", "ntp_regset", "ntp_regfail");
&endif&

  reports:


    # Global report for the "Time synchronization (NTP)" component - Linux
    ntp_install_kept.ntpconf_kept.!ntpd_down::
      "@@ntpConfiguration@@result_success@@&TRACKINGKEY&@@Time synchronization (NTP)@@None@@${g.execRun}##${g.uuid}@#ntp daemon installed, configured and running";

    ntp_installed|repaired_ntpconf|ntp_restarted::
      "@@ntpConfiguration@@result_repaired@@&TRACKINGKEY&@@Time synchronization (NTP)@@None@@${g.execRun}##${g.uuid}@#ntp service (package, configuration and/or process) repaired";

    # Global report for the "Time synchronization (NTP)" component - Windows
    ntp_regkept::
      "@@ntpConfiguration@@result_success@@&TRACKINGKEY&@@Time synchronization (NTP)@@None@@${g.execRun}##${g.uuid}@#NTP service configured and running";

    ntp_regset.ntp_win32time_started::
      "@@ntpConfiguration@@result_repaired@@&TRACKINGKEY&@@Time synchronization (NTP)@@None@@${g.execRun}##${g.uuid}@#NTP service repaired, it is now configured and running";

    # Individual reports for the "Time synchronization (NTP)" component's parts
    cant_install_ntp::
      "@@ntpConfiguration@@result_error@@&TRACKINGKEY&@@Time synchronization (NTP)@@None@@${g.execRun}##${g.uuid}@#ntp package could not be installed";

    ntp_installed::
      "@@ntpConfiguration@@log_repaired@@&TRACKINGKEY&@@Time synchronization (NTP)@@None@@${g.execRun}##${g.uuid}@#ntp package installed";

    ntp_install_kept::
      "@@ntpConfiguration@@log_info@@&TRACKINGKEY&@@Time synchronization (NTP)@@None@@${g.execRun}##${g.uuid}@#ntp package already installed";

    repaired_ntpconf::
      "@@ntpConfiguration@@log_repaired@@&TRACKINGKEY&@@Time synchronization (NTP)@@None@@${g.execRun}##${g.uuid}@#ntpd configuration updated";

    not_repaired_ntpconf::
      "@@ntpConfiguration@@result_error@@&TRACKINGKEY&@@Time synchronization (NTP)@@None@@${g.execRun}##${g.uuid}@#ntpd configuration could not be changed";

    ntpd_down::
      "@@ntpConfiguration@@log_info@@&TRACKINGKEY&@@Time synchronization (NTP)@@None@@${g.execRun}##${g.uuid}@#ntpd process was not running";

    ntp_restarted::
      "@@ntpConfiguration@@log_repaired@@&TRACKINGKEY&@@Time synchronization (NTP)@@None@@${g.execRun}##${g.uuid}@#ntpd process restarted";

    cant_restart_ntp::
      "@@ntpConfiguration@@result_error@@&TRACKINGKEY&@@Time synchronization (NTP)@@None@@${g.execRun}##${g.uuid}@#ntpd process could not be restarted";

    ntp_regset::
      "@@ntpConfiguration@@log_repaired@@&TRACKINGKEY&@@Time synchronization (NTP)@@None@@${g.execRun}##${g.uuid}@#NTP service configured in the Windows registry. W32Time will restart";

    ntp_regfail::
      "@@ntpConfiguration@@result_error@@&TRACKINGKEY&@@Time synchronization (NTP)@@None@@${g.execRun}##${g.uuid}@#NTP service could not be configured in the Windows registry";

    ntp_regkept::
      "@@ntpConfiguration@@log_info@@&TRACKINGKEY&@@Time synchronization (NTP)@@None@@${g.execRun}##${g.uuid}@#NTP service was already configured in the Windows registry";

    ntp_win32time_started::
      "@@ntpConfiguration@@log_info@@&TRACKINGKEY&@@Time synchronization (NTP)@@None@@${g.execRun}##${g.uuid}@#NTP service (W32Time) restarted";


    # Global reports for the "Time zone" component's parts
    repaired_localtime|repaired_redhattz|repaired_debiantz|repaired_susetz::
      "@@ntpConfiguration@@result_repaired@@&TRACKINGKEY&@@Time zone@@None@@${g.execRun}##${g.uuid}@#Time zone was reset";

    localtime_kept.((redhat.redhattz_kept)|(debian.debiantz_kept)|(SuSE.susetz_kept))::
      "@@ntpConfiguration@@result_success@@&TRACKINGKEY&@@Time zone@@None@@${g.execRun}##${g.uuid}@#Time zone was already correctly configured";

    clock_timezone_noedit::
      "@@ntpConfiguration@@result_success@@&TRACKINGKEY&@@Time zone@@None@@${g.execRun}##${g.uuid}@#Time zone edition disabled";

    # Individual reports for the "Time zone" component's parts
    repaired_localtime::
      "@@ntpConfiguration@@log_repaired@@&TRACKINGKEY&@@Time zone@@None@@${g.execRun}##${g.uuid}@#Time zone was reset (localtime file changed)";

    not_repaired_localtime::
      "@@ntpConfiguration@@result_error@@&TRACKINGKEY&@@Time zone@@None@@${g.execRun}##${g.uuid}@#Time zone could not be set (localtime file could not be changed)";

    localtime_kept::
      "@@ntpConfiguration@@log_info@@&TRACKINGKEY&@@Time zone@@None@@${g.execRun}##${g.uuid}@#Time zone was already set (localtime file didn't need changing)";

    repaired_redhattz::
      "@@ntpConfiguration@@log_repaired@@&TRACKINGKEY&@@Time zone@@None@@${g.execRun}##${g.uuid}@#Red Hat-style specific time zone parameters updated (/etc/sysconfig/clock)";

    not_repaired_redhattz::
      "@@ntpConfiguration@@result_error@@&TRACKINGKEY&@@Time zone@@None@@${g.execRun}##${g.uuid}@#Could not update Red Hat-style time zone parameters (/etc/sysconfig/clock)";

    redhattz_kept::
      "@@ntpConfiguration@@log_info@@&TRACKINGKEY&@@Time zone@@None@@${g.execRun}##${g.uuid}@#Red Hat-style time zone parameters already correct (/etc/sysconfig/clock)";

    repaired_debiantz::
      "@@ntpConfiguration@@log_repaired@@&TRACKINGKEY&@@Time zone@@None@@${g.execRun}##${g.uuid}@#Debian-style time zone parameters updated (/etc/timezone)";

    not_repaired_debiantz::
      "@@ntpConfiguration@@result_error@@&TRACKINGKEY&@@Time zone@@None@@${g.execRun}##${g.uuid}@#Could not update Debian-style time zone parameters (/etc/timezone)";

    debiantz_kept::
      "@@ntpConfiguration@@log_info@@&TRACKINGKEY&@@Time zone@@None@@${g.execRun}##${g.uuid}@#Debian-style time zone parameters already correct (/etc/timezone)";

    repaired_susetz::
      "@@ntpConfiguration@@log_repaired@@&TRACKINGKEY&@@Time zone@@None@@${g.execRun}##${g.uuid}@#SuSE-style time zone parameters updated (/etc/sysconfig/clock)";

    not_repaired_susetz::
      "@@ntpConfiguration@@result_error@@&TRACKINGKEY&@@Time zone@@None@@${g.execRun}##${g.uuid}@#Could not update SuSE-style time zone parameters (/etc/sysconfig/clock)";

    susetz_kept::
      "@@ntpConfiguration@@log_info@@&TRACKINGKEY&@@Time zone@@None@@${g.execRun}##${g.uuid}@#SuSE-style time zone parameters already correct (/etc/sysconfig/clock)";

    # Global reports for the "Hardware clock (RTC)" component
    (!windows.!ntp_hwclock_sync_error.!ntp_hwclock_synced)::
      "@@ntpConfiguration@@result_success@@&TRACKINGKEY&@@Hardware clock (RTC)@@None@@${g.execRun}##${g.uuid}@#It is not yet time to synchronize the hardware clock with the NTP time. Skipping...";

    ntp_hwclock_synced::
      "@@ntpConfiguration@@result_success@@&TRACKINGKEY&@@Hardware clock (RTC)@@None@@${g.execRun}##${g.uuid}@#The hardware clock has been synchronized with the NTP time";

    ntp_hwclock_sync_error::
      "@@ntpConfiguration@@result_error@@&TRACKINGKEY&@@Hardware clock (RTC)@@None@@${g.execRun}##${g.uuid}@#The hardware clock could not be synchronized with the NTP time";

    windows::
      "@@ntpConfiguration@@result_success@@&TRACKINGKEY&@@Hardware clock (RTC)@@None@@${g.execRun}##${g.uuid}@#The hardware clock is automatically synchronized with the NTP time on Windows";

}


bundle edit_line setNtpServer(serverlist)
{
  delete_lines:
      "server.*";

  insert_lines:

"#############################################################
### This file is protected by your Rudder infrastructure. ###
### Manually editing the file might lead your Rudder      ###
### infrastructure to change back the server's            ###
### configuration and/or to raise a compliance alert.     ###
#############################################################
"
        location => start,
        insert_type => "preserve_block";

      "server ${serverlist}";

}

bundle edit_line EditCentOSTimezone(tz)
{

  insert_lines:

"#############################################################
### This file is protected by your Rudder infrastructure. ###
### Manually editing the file might lead your Rudder      ###
### infrastructure to change back the server's            ###
### configuration and/or to raise a compliance alert.     ###
#############################################################
"
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

"#############################################################
### This file is protected by your Rudder infrastructure. ###
### Manually editing the file might lead your Rudder      ###
### infrastructure to change back the server's            ###
### configuration and/or to raise a compliance alert.     ###
#############################################################
"
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
