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

bundle agent process_matching
{
  vars:

      # This deliberately excludes cf-execd which is handled separately below
      "cf_components" slist => {
        "cf-key",
        # "cf-monitord", Disabled
        "cf-promises",
        "cf-report",
        "cf-runagent",
        "cf-serverd"
      };

    windows::
      "stop_signal" string => "kill";

    !windows::
      "stop_signal" string => "term";


  classes:

      "restart_cf" expression => "Hr05.Min00_05.!disable_agent";

  files:

    linux::

      # This is to cleanup /etc/crontab from pre-2.5 usage
      # and initial promises before 2.7
      "${g.crontab}"
        edit_defaults => noempty_backup,
        edit_line => cron_cleanup;

    community_edition::

      "/etc/cron.d/rudder-agent"
        create        => "true",
        perms         => mog("644", "root", "root"),
        edit_defaults => empty_backup,
        edit_line     => expand_template("${sys.workdir}/inputs/common/cron/rudder_agent_community_cron");
&if(NOVA)&

    nova_edition::

      "/etc/cron.d/rudder-agent-nova"
        create        => "true",
        perms         => mog("644", "root", "root"),
        edit_defaults => empty_backup,
        edit_line     => expand_template("${sys.workdir}/inputs/common/cron/rudder_agent_nova_cron");
&endif&

  processes:

    windows::
      # Always stop cf-monitord
      "${g.escaped_workdir}\/bin\/cf-monitord" signals => { "${stop_signal}" };

    linux::
      # Always stop cf-monitord
      "${sys.workdir}/bin/cf-monitord"         signals => { "${stop_signal}" };

    restart_cf.!policy_server::
      "${cf_components}" signals => { "${stop_signal}" };

    # Policy servers have both Nova and Community, don't blindly kill the wrong processes
    restart_cf.policy_server::
      "${sys.workdir}/bin/${cf_components}" signals => { "${stop_signal}" };

    restart_cf.!windows::
      "${sys.workdir}/bin/cf-execd"         signals => { "${stop_signal}" };

&if(NOVA)&
  services:

    restart_cf.windows::
      "CfengineNovaExec"
        service_policy => "stop",
        comment        => "Stop the executor service, part of scheduled restart";

      "CfengineNovaExec"
        service_policy => "start",
        comment        => "Start the executor service, part of scheduled restart";

&endif&

  commands:

    restart_cf.!windows::

      "${sys.cf_serverd}";
      "${sys.cf_execd}";

  reports:

    restart_cf::
      "Reloaded configuration of all Cfengine components";

}

# This is to cleanup /etc/crontab from pre-2.5 usage
# and initial promises before 2.7
bundle edit_line cron_cleanup
{

# Remove old lines to replace them with new version
  delete_lines:

      "0,5,10,15,20,25,30,35,40,45,50,55 \* \* \* \* root if \[ \`ps -efww \| grep cf-execd \| grep \"/var/cfengine/bin/cf-execd\" \| grep -v grep \| wc -l\` -eq 0 \]; then /var/cfengine/bin/cf-execd; fi";
      "0,5,10,15,20,25,30,35,40,45,50,55 \* \* \* \* root if \[ \`ps -efww \| grep cf-execd \| grep \"/var/rudder/cfengine-community/bin/cf-execd\" \| grep -v grep \| wc -l\` -eq 0 \]; then /var/rudder/cfengine-community/bin/cf-execd; fi";
      "0,5,10,15,20,25,30,35,40,45,50,55 \* \* \* \* root if \[ ! -e /opt/rudder/etc/disable-agent -a \`ps -efww \| grep cf-execd \| grep \"/var/rudder/cfengine-community/bin/cf-execd\" \| grep -v grep \| wc -l\` -eq 0 \]; then /var/rudder/cfengine-community/bin/cf-execd; fi";
      "0,5,10,15,20,25,30,35,40,45,50,55 \* \* \* \* root if \[ ! -e /opt/rudder/etc/disable-agent -a \`ps -efww \| grep cf-execd \| grep \"/var/cfengine/bin/cf-execd\" \| grep -v grep \| wc -l\` -eq 0 \]; then /var/cfengine/bin/cf-execd; fi";
      "0,5,10,15,20,25,30,35,40,45,50,55 \* \* \* \* root if \[ ! -e /opt/rudder/etc/disable-agent -a \`ps -efww \| grep cf-execd \| grep \"/var/cfengine/bin/cf-execd\" \| grep -v grep \| wc -l\` -eq 0 \]; then /var/cfengine/bin/cf-agent -f failsafe.cf \&\& /var/cfengine/bin/cf-agent; fi";
      "0,5,10,15,20,25,30,35,40,45,50,55 \* \* \* \* root if \[ ! -e /opt/rudder/etc/disable-agent -a \`ps -efww \| grep cf-execd \| grep \"/var/rudder/cfengine-community/bin/cf-execd\" \| grep -v grep \| wc -l\` -eq 0 \]; then /var/rudder/cfengine-community/bin/cf-agent -f failsafe.cf \&\& /var/rudder/cfengine-community/bin/cf-agent; fi";
      "0,5,10,15,20,25,30,35,40,45,50,55 \* \* \* \* root if \[ ! -e /opt/rudder/etc/disable-agent -a \`ps -efww \| grep -E \"\(cf-execd\|cf-agent\)\" \| grep -E \"/var/cfengine/bin/\(cf-execd\|cf-agent\)\" \| grep -v grep \| wc -l\` -eq 0 ]; then /var/cfengine/bin/cf-agent -f failsafe.cf \&\& /var/cfengine/bin/cf-agent; fi";
      "0,5,10,15,20,25,30,35,40,45,50,55 \* \* \* \* root if \[ ! -e /opt/rudder/etc/disable-agent -a \`ps -efww \| grep -E \"\(cf-execd\|cf-agent\)\" \| grep -E \"/var/rudder/cfengine-community/bin/\(cf-execd\|cf-agent\)\" \| grep -v grep \| wc -l\` -eq 0 ]; then /var/rudder/cfengine-community/bin/cf-agent -f failsafe.cf \&\& /var/rudder/cfengine-community/bin/cf-agent; fi";
      # Remove entry with wrong escapements from /etc/crontab
      "0,5,10,15,20,25,30,35,40,45,50,55 \* \* \* \* root if \[ ! -e /opt/rudder/etc/disable-agent -a \`ps -efww \| grep -E \"\(cf-execd\|cf-agent\)\" \| grep -E \"/var/rudder/cfengine-community/bin/\(cf-execd\|cf-agent\)\" \| grep -v grep \| wc -l\` -eq 0 ]; then /var/rudder/cfengine-community/bin/cf-agent -f failsafe.cf \\\&\\\& /var/rudder/cfengine-community/bin/cf-agent; fi";

}
