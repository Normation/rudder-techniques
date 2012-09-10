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
 "cf_components"       slist => { "cf-key", "cf-know",
                                  # "cf-monitord", Disabled
                                  "cf-promises", "cf-report",
                                  "cf-runagent", "cf-serverd" };

 windows::
   "stop_signal"              string => "kill";

 !windows::
   "stop_signal"              string => "term";


classes:

  "restart_cf" expression => "Hr05.Min00_05.!disable_agent";


processes:

  windows::
  # Always stop cf-monitord
  "${g.escaped_workdir}\/bin\/cf-monitord"  signals => { "$(stop_signal)" };

  linux::
  # Always stop cf-monitord
  "${sys.workdir}/bin/cf-monitord"  signals => { "$(stop_signal)" };

  restart_cf.!policy_server::
    "$(cf_components)" signals => { "$(stop_signal)" };

  # Policy servers have both Nova and Community, don't blindly kill the wrong processes
  restart_cf.policy_server::
    "${sys.workdir}/bin/$(cf_components)" signals => { "$(stop_signal)" };

  restart_cf.!windows::
    "${sys.workdir}/bin/cf-execd"  signals => { "$(stop_signal)" };

commands:

  restart_cf.!windows::

    "$(sys.cf_serverd)";
    "$(sys.cf_execd)";

&if(NOVA)&
services:

  restart_cf.windows::
    "CfengineNovaExec"
    service_policy => "stop",
           comment => "Stop the executor service, part of scheduled restart";

    "CfengineNovaExec"
    service_policy => "start",
           comment => "Start the executor service, part of scheduled restart";

&endif&

files:

    linux::

        "$(g.crontab)"

            create  => "true",
            edit_line => cron_add;

reports:

  restart_cf::
    "Reloaded configuration of all Cfengine components";

}

bundle edit_line cron_add
{

# Remove old lines to replace them with new version
delete_lines:
        "0,5,10,15,20,25,30,35,40,45,50,55 \* \* \* \* root if \[ \`ps -efww \| grep cf-execd \| grep \"/var/cfengine/bin/cf-execd\" \| grep -v grep \| wc -l\` -eq 0 \]; then /var/cfengine/bin/cf-execd; fi";
        "0,5,10,15,20,25,30,35,40,45,50,55 \* \* \* \* root if \[ \`ps -efww \| grep cf-execd \| grep \"/var/rudder/cfengine-community/bin/cf-execd\" \| grep -v grep \| wc -l\` -eq 0 \]; then /var/rudder/cfengine-community/bin/cf-execd; fi";

insert_lines:

    nova_edition::

        "0,5,10,15,20,25,30,35,40,45,50,55 * * * * root if [ ! -e /opt/rudder/etc/disable-agent -a `ps -efww | grep cf-execd | grep \"/var/cfengine/bin/cf-execd\" | grep -v grep | wc -l` -eq 0 ]; then /var/cfengine/bin/cf-execd; fi";

    community_edition::

        "0,5,10,15,20,25,30,35,40,45,50,55 * * * * root if [ ! -e /opt/rudder/etc/disable-agent -a `ps -efww | grep cf-execd | grep \"/var/rudder/cfengine-community/bin/cf-execd\" | grep -v grep | wc -l` -eq 0 ]; then /var/rudder/cfengine-community/bin/cf-execd; fi";

}
