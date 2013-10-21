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

#
# This promise installs and configures centreon E2S
#
# This program monitors the windows event log and sends every
# Nova related information to a remote syslog, the Rudder main server
# in our case.
#
# Warning : This obviously is Windows specific


bundle agent e2s_enable
{

  methods:

    windows::

#        "any" usebundle => e2sGet;
      "any" usebundle => e2sInstall;
      "any" usebundle => e2sConfigure;
&if(NOVA)&
      "any" usebundle => e2sLaunch;
&endif&

  reports:
    e2s_tool_copied|e2s_installed|e2s_configure_repaired|e2s_service_repaired::
      "@@Common@@log_repaired@@&TRACKINGKEY&@@Log system for reports@@None@@${g.execRun}##${g.uuid}@#Centreon E2S service was not installed, configured and running. Fixed.";

    e2s_tool_kept.!e2s_tool_copied.!cannot_copy_e2s.!e2s_installed.!e2s_install_failed.e2s_configure_kept.!e2s_configure_repaired.!e2s_configure_error.e2s_service_kept.!e2s_service_repaired.!e2s_service_error::
      "@@Common@@result_success@@&TRACKINGKEY&@@Log system for reports@@None@@${g.execRun}##${g.uuid}@#Centreon E2S service already installed, configured and running as expected.";

}

bundle common e2sCommon
{

  vars:
    windows::
      "e2s_exe" string => "${g.rudder_dependencies}/centreon-e2s.exe";
      "e2s_tpl" string => "${g.rudder_dependencies}/e2s.tpl";

}

bundle agent e2sGet
{

  files:
    windows::
      "${g.rudder_sbin}/centreon_e2s.exe"
        copy_from => scp("${e2sCommon.e2s_exe}", "${server_info.cfserved}","digest","true","true","false"),
        perms     => m("0700"),
        classes   => kept_if_else("e2s_tool_kept", "e2s_tool_copied", "cannot_copy_e2s"),
        comment   => "Copying tool for e2s installation";

      "${g.rudder_sbin}/e2s.tpl"
        copy_from => scp("${e2sCommon.e2s_tpl}", "${server_info.cfserved}","digest","true","true","false"),
        perms     => m("0700"),
        classes   => kept_if_else("e2s_tool_kept", "e2s_tool_copied", "cannot_copy_e2s"),
        comment   => "Copying tool for e2s conversion";

  reports:

    e2s_tool_copied::
      "@@Common@@log_repaired@@&TRACKINGKEY&@@Log system for reports@@None@@${g.execRun}##${g.uuid}@#Copied E2S utilities";

    cannot_copy_e2s::
      "@@Common@@result_error@@&TRACKINGKEY&@@Log system for reports@@None@@${g.execRun}##${g.uuid}@#Could not copy E2S utilities";

}

bundle agent e2sInstall
{

  classes:

    !x86_64::
      "e2s_ok" expression => fileexists("${sys.winprogdir}\Centreon\Centreon E2S\Centreon-EventLog-2-Syslog.exe");

    x86_64::
      "e2s_ok" expression => fileexists("${sys.winprogdir86}\Centreon\Centreon E2S\Centreon-EventLog-2-Syslog.exe");

  commands:

    windows.!e2s_ok::

      "\"${g.rudder_sbin}\centreon-e2s.exe\""
        args    => "/S",
        contain => outputable_dir("${g.rudder_sbin}"),
        classes => cf2_if_else("e2s_installed", "e2s_install_failed"),
        comment => "Installing Centreon E2S";

  reports:

    e2s_installed::
      "@@Common@@log_repaired@@&TRACKINGKEY&@@Log system for reports@@None@@${g.execRun}##${g.uuid}@#Installed Centreon E2S";
    e2s_install_failed::
      "@@Common@@result_error@@&TRACKINGKEY&@@Log system for reports@@None@@${g.execRun}##${g.uuid}@#Failed to install Centreon E2S";

}

bundle agent e2sConfigure
{

  vars:
    !x86_64::
      "e2s_config_file" string => "${sys.winprogdir}\Centreon\Centreon E2S\Configuration.xml";
    x86_64::
      "e2s_config_file" string => "${sys.winprogdir86}\Centreon\Centreon E2S\Configuration.xml";

  files:

      "${e2s_config_file}"
        create        => "true",
        classes       => kept_if_else("e2s_configure_kept", "e2s_configure_repaired", "e2s_configure_error"),
        edit_line     => e2s_parameters("${server_info.cfserved}", "&SYSLOGPORT&", "TCP", "${e2sCommon.e2s_tpl}"),
        edit_defaults => empty_backup;

  reports:
    e2s_configure_error::
      "@@Common@@result_error@@&TRACKINGKEY&@@Log system for reports@@None@@${g.execRun}##${g.uuid}@#Failed to configure Centreon E2S";
    e2s_configure_repaired::
      "@@Common@@log_repaired@@&TRACKINGKEY&@@Log system for reports@@None@@${g.execRun}##${g.uuid}@#Update Centreon E2S configuration";

}

&if(NOVA)&
bundle agent e2sLaunch
{

  services:

      "Centreon-E2S"
        service_policy => "start",
        service_method => u_bootstart,
        classes        => kept_if_else("e2s_service_kept", "e2s_service_repaired", "e2s_service_error");

  reports:
    e2s_service_error::
      "@@Common@@result_error@@&TRACKINGKEY&@@Log system for reports@@None@@${g.execRun}##${g.uuid}@#Error while checking or restarting Centreon E2S service";
    e2s_service_repaired::
      "@@Common@@log_repaired@@&TRACKINGKEY&@@Log system for reports@@None@@${g.execRun}##${g.uuid}@#Centreon E2S was restarted";

    e2s_service_kept.!e2s_configure_repaired::
      "@@Common@@result_success@@&TRACKINGKEY&@@Log system for reports@@None@@${g.execRun}##${g.uuid}@#Centreon E2S was correctly configured";
}
&endif&

bundle edit_line e2s_parameters(server, port, protocol, template)
{
  insert_lines:

      "${template}"
        insert_type    => "file",
        expand_scalars => "true";

}

body delete nodir
{
        rmdirs => "false";
}
