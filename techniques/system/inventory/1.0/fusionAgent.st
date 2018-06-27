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
# This file launch a fusion-inventory agent
# inventory in local.
# If fusion agent is not installed,
# the installation is done
#
# Then the inventory file is improved with external informations (UUID, cf-key, VMs)

# Compute the inventory time
bundle agent computeInventoryTime
{
  vars:
      "run_interval"             int   => "&AGENT_RUN_INTERVAL&";

      "inventory_time_hours"     slist => { "Hr00", "Hr01", "Hr02", "Hr03", "Hr04", "Hr05" };
      "inventory_time_selection" slist => maplist("${this}_select", "inventory_time_hours");

  classes:
      "splaying"                   expression => splayclass("${sys.host}${sys.ipv4}","hourly");

      "inventory_run_selection" select_class => { "@{computeInventoryTime.inventory_time_selection}"};

      # If this is the default 5 minute schedule, this is the standart case
      "default_schedule" expression => isgreaterthan("6", "${run_interval}");

      # If the interval is between 6 and 59 minutes, then we "splay" by the select_class, so between Midnight and 5 am
      "less_than_one_hour_interval" expression => isgreaterthan("59", "${run_interval}");

      # Compute if we are currently in the hour where the inventory should be done
      "inventory_hour_selection" expression => "${inventory_time_hours}.${inventory_time_hours}_select";

       # Inventory will be during the night, at the hour selected, with a splay is this is the default schedule, else at the first run during the selected hour
       # if the interval is less than one hour, else at the first run of the night
       "inventory_time" expression => "Night.((splaying.default_schedule.inventory_hour_selection)|(!default_schedule.less_than_one_hour_interval.inventory_hour_selection)|(!less_than_one_hour_interval))",
                             scope => "namespace";
}

bundle agent doInventory
{
  vars:
    resend_inventory::
      "cant_send_inventory" string => "undefine", 
                            classes => cancel_all_classes("cant_send_inventory");
      
  classes:
      "disable_inventory" expression => fileexists("${g.rudder_disable_inventory_file}");

    cant_send_inventory::
      "resend_inventory" expression => "any",
                         scope => "namespace";

  methods:
    ignore_disable_inventory|!disable_inventory::
      "any" usebundle => doInventory_always;
    !(ignore_disable_inventory|!disable_inventory)::
      "any" usebundle => rudder_common_report("Inventory", "log_warn", "&TRACKINGKEY&", "inventory", "None", "The file ${g.rudder_disable_inventory_file} is present, so Rudder will not send an inventory. Use 'rudder agent inventory -f' to override this temporarily");
}
bundle agent doInventory_always
{

  vars:

    uuid_succesfully_downloaded::
      "policy_server_uuid" string => readfile("${sys.workdir}/rudder-server-uuid.txt", 50);

  classes:
    # The force_inventory class may be specified by the user at runtime, or defined here
      "force_inventory" expression => fileexists("${g.rudder_base}/etc/force_inventory"),
                             scope => "namespace";

    uuid_succesfully_downloaded::
      "uuid_valid" expression => regcmp("[a-z0-9-]+","${policy_server_uuid}");
      "uuid_validity_checked"
        expression => "any",
        comment    => "This dummy class is just used for ordering the report using !uuid_valid below";

    any::
      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";
&if(INITIAL)&
      "initial_promises" expression => "any",
                              scope => "namespace";
&endif&

  files:
    # Clean policy server uuid file defined in 2.11 or earlier version, as location in 3.0+ is ${sys.workdir}/rudder-server-uuid.txt
    "${g.rudder_var_tmp}/uuid.txt"
      delete => tidy;

  methods:
      # Compute the inventory time
      "any" usebundle => computeInventoryTime;

    force_inventory|((inventory_time|initial_promises).!inventory_sent)::
      "any" usebundle => download_server_uuid;

    uuid_valid.(force_inventory|((inventory_time|initial_promises).!inventory_sent))::
      "any" usebundle => fusionAgent;
      "any" usebundle => checkInventoryFile;

    uuid_valid.(force_inventory|((inventory_time|initial_promises).!inventory_sent)).inventory_valid::
      "any" usebundle => moveInventoryToFinalDestination;
      "any" usebundle => signInventories;
      "any" usebundle => compressInventories;

    uuid_valid.(force_inventory|resend_inventory|((inventory_time|initial_promises).!inventory_sent)).inventory_valid::
      "any" usebundle => sendInventory;
      "any" usebundle => cleanForceInventoryFlagFile;

    pass3.uuid_succesfully_downloaded.uuid_validity_checked.!uuid_valid::
      "any" usebundle => rudder_common_report("Inventory", "result_error", "&TRACKINGKEY&", "inventory", "None", "Could not retrieve a valid UUID from the policy server");

    # Send reports to confirm this technique success even if we don't need to send an inventory
    pass3.inventory_sent::
      "any" usebundle => rudder_common_report("Inventory", "log_info", "&TRACKINGKEY&", "inventory", "None", "An inventory was already sent less than 8 hours ago");

    pass3.!(Night.splaying).!force_inventory::
      "any" usebundle => rudder_common_report("Inventory", "result_success", "&TRACKINGKEY&", "inventory", "None", "Next inventory scheduled between 00:00 and 06:00");

}

bundle agent download_server_uuid
{
  vars:

    # If curl is available, use it
    !windows.curl_installed::
      "download_command"   string => "${g.rudder_curl} -L -k -1 -s -f --proxy '' -o \"${sys.workdir}/rudder-server-uuid.txt\" ${g.inventory_upload_protocol}://${server_info.policy_server}/uuid";

    # If not, use minicurl instead
    !windows.!curl_installed::
      "download_command"   string => "${g.minicurl} --no-verify --get --file \"${sys.workdir}/rudder-server-uuid.txt\" --url http://${server_info.policy_server}/uuid";

&if(NOVA)&
    # On windows, always use curl
    windows::
      "download_command"   string => "\"${g.rudder_base_sbin}\curl\curl.exe\" -L -k -1 -s -f --noproxy '${server_info.policy_server}' -o \"${sys.workdir}\rudder-server-uuid.txt\" ${g.inventory_upload_protocol}://${server_info.cfserved}/uuid";
&endif&

  methods:
    could_not_download_uuid::
      "any" usebundle => rudder_common_report("Inventory", "result_error", "&TRACKINGKEY&", "inventory", "None", "Could not retrieve the UUID of the policy server");

  commands:

      "${download_command}"
        comment => "Getting the uuid from the server",
        classes => if_else("uuid_succesfully_downloaded","could_not_download_uuid");

}

bundle agent fusionAgent
{
  vars:
    # guarding execresult to save a lot of time during policy validation
    !windows.(force_inventory|inventory_time|initial_promises)::
      "fusion_inventory_version" string => execresult("${g.rudder_base}/bin/run-inventory --version | ${paths.path[grep]} '[0-9]\.[0-9]' | ${paths.path[sed]} 's%.*(\([0-9]\+\)\.\([0-9]\+\).*).*%\1\2%'", "useshell");
      "inventory_path"           string => "${g.rudder_var_tmp}/inventory", policy => "overridable"; # Default value
      "inventory_path_edition"   string => "${g.rudder_var_tmp}/inventory/.*.ocs", policy => "overridable"; # Default value for editing the inventory files


    !windows.fusion_inventory_version_23_or_later::
      # FusionInventory 2.3+ permits to specify the exact inventory file name we want
      "inventory_path"           string => "${g.rudder_var_tmp}/inventory/${sys.uqhost}-${g.uuid}.ocs";
      "inventory_path_edition"   string => "${g.rudder_var_tmp}/inventory/${sys.uqhost}-${g.uuid}.ocs";

    windows:: # We assume we always have FusionInventory 2.3+ on Windows
      "inventory_path"           string => "${g.rudder_var_tmp}\inventory\${sys.uqhost}-${g.uuid}.ocs";
      "inventory_path_edition"   string => "${g.rudder_var_tmp}\inventory\${sys.uqhost}-${g.uuid}.ocs";

  classes:
    !windows::
      # CFEngine doesn't have a ">=" operator, so I'm using "! <" instead
      "fusion_inventory_version_23_or_later" not => islessthan("${fusion_inventory_version}", "23");

    any::
      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";

  files:
    !windows|cygwin::
      "${g.rudder_var_tmp}/inventory/."
        create => "true",
        comment => "Creating inventory directory",
        classes => if_ok("inventoryfoldercreated");

      "${g.rudder_var_reports}/."
        create => "true";

&if(NOVA)&
    windows.!cygwin::
      "${g.rudder_var_tmp}\inventory\."
        create => "true",
        comment => "Creating inventory directory",
        classes => if_ok("inventoryfoldercreated");

      "${g.rudder_var_reports}\."
        create => "true";
&endif&

  methods:
    pass3.run_inventory::
      "any" usebundle => rudder_common_report("Inventory", "log_debug", "&TRACKINGKEY&", "inventory", "None", "Running inventory");

    pass3.inventory_failed::
      "any" usebundle => rudder_common_report("Inventory", "result_error", "&TRACKINGKEY&", "inventory", "None", "Could not execute the inventory");

  commands:
    !windows.inventoryfoldercreated::
      "${g.rudder_base}/bin/run-inventory --local=${inventory_path}"
        classes => cf2_if_else("run_inventory", "inventory_failed"),
        comment => "Generating inventory, in the temporary folder";

&if(NOVA)&
    windows::
      "\"C:\Program Files\Rudder\sbin\run-inventory.bat\""
        args => "--local=\"${inventory_path}\" 2>nul",
        contain => in_shell,
        classes => cf2_if_else("run_inventory", "inventory_failed"),
        comment => "Generating inventory";
&endif&

}

# Check that the inventory file is valid
bundle agent checkInventoryFile
{
  vars:
      "inventory_file"     slist => findfiles("${g.rudder_var_tmp}/inventory/*.ocs");
      "inventory_file_count" int => length("inventory_file");
    !windows.has_rudder_perl::
      "perl_command" string => "/opt/rudder/bin/perl -I /opt/rudder/lib/perl5";
    !windows.!has_rudder_perl::
      "perl_command" string => "/usr/bin/perl -I /opt/rudder/lib/perl5";
    windows::
      "perl_command" string => "C:\Program Files\FusionInventory-Agent\perl\bin\perl.exe";

  classes:
      # To check if inventory file is there, we need to count the file (filexists is not enough if inventory_file is an empty list))
      "inventory_file_exist" expression => isgreaterthan("${inventory_file_count}", "0");
      "has_rudder_perl" expression => fileexists("/opt/rudder/bin/perl");
    pass1.inventory_file_exist.!windows::
      "inventory_valid" expression => returnszero("${perl_command} ${this.promise_dirname}/test-inventory.pl ${inventory_file}", "noshell"),
                        scope => "namespace";

    pass1.inventory_file_exist.windows::
      "inventory_valid" expression => returnszero("\"${perl_command}\" \"${this.promise_dirname}/test-inventory.pl\" \"${inventory_file}\"", "noshell"),
                        scope => "namespace";

    any::
      "pass2" expression => "pass1";
      "pass1" expression => "any";

  methods:
    pass2.inventory_file_exist.!inventory_valid::
      "any" usebundle => rudder_common_report("Inventory", "result_error", "&TRACKINGKEY&", "inventory", "None", "Generated inventory has been detected as invalid");

  reports:
    pass2.inventory_file_exist.!inventory_valid::
      # Print information to the user in addition to the reporting
      "********************************************************************************
* WARNING Generated inventory is not valid, as it is missing mandatory fields. *
* Not sending it to the Rudder Server                                          *
* You can get a full error message by running: ${perl_command} ${this.promise_dirname}/test-inventory.pl ${inventory_file} 
********************************************************************************";
}

# Move the inventory file in the shared directory
bundle agent moveInventoryToFinalDestination
{
  files:
      "${g.rudder_inventories}"
        copy_from    => copy("${g.rudder_var_tmp}/inventory"),
        depth_search => recurse_visible(1),
        file_select  => by_name("@{g.inventory_file_types}"),
        comment      => "Moving inventory files to the final location";
}

# sign inventories
bundle agent signInventories
{
  vars:

    !windows::
      # Keep "/opt/rudder/bin/signature.sh" as a fallback until we don't support agents < 4.0 anymore
      "sign_script" string => ifelse(fileexists("${g.rudder_base}/bin/rudder-sign"), "${g.rudder_base}/bin/rudder-sign", "${g.rudder_base}/bin/signature.sh");
    windows::
      "sign_script" string => "C:\Windows\System32\WindowsPowershell\v1.0\powershell.exe -ExecutionPolicy Bypass -File \"C:\Program Files\Rudder\sbin\signature.ps1\" -file";

  classes:
      "sign_script_exists" expression => fileexists("${sign_script}");

  files:

    !windows.sign_script_exists::
      "${g.rudder_inventories}"
        transformer  => "${sign_script} \"${this.promiser}\"",
        depth_search => recurse_visible(1),
        file_select  => by_name("@{g.uncompressed_inventory_file_types}"),
        comment      => "Signing inventory files";
}

# compress inventories if possible
bundle agent compressInventories
{
  files:

    !windows.gzip_installed::

      "${g.rudder_inventories}"
        transformer  => "${g.gzip} -fq ${this.promiser}",
        depth_search => recurse_visible(1),
        file_select  => by_name("@{g.uncompressed_inventory_file_types}"),
        comment      => "gzip inventory files";
}

# Send the file to the promises server
bundle agent sendInventory
{

  vars:
    !windows.!curl_installed::
      "protocol"                  string => "http";
    (windows|curl_installed)::
      "protocol"                  string => "${g.inventory_upload_protocol}";
&if(INITIAL)&
      "download_endpoint"         string => "${protocol}://${server_info.policy_server}/inventories/";
      "min_resend_delay"          string => "15";
&else&
      "download_endpoint"         string => "${protocol}://${server_info.policy_server}/inventory-updates/";
      "min_resend_delay"          string => "480";
&endif&

    # If curl is available, use it
    !windows.!aix::
      "download_command_prefix"   string => "${g.rudder_curl} -L -k -1 -f -s --proxy '' --user ${g.davuser}:${g.davpw} -T";
      "download_command_suffix"   string => "${download_endpoint}";

    # If not, use minicurl instead
    aix::
      "download_command_prefix"   string => "${g.minicurl} --no-verify --put --authentication ${g.davuser}:${g.davpw} --file";
      "download_command_suffix"   string => "--url ${download_endpoint}";

&if(NOVA)&
    # On windows, always use curl
    windows::
      "download_command_prefix"   string => "${g.rudder_curl} -L -k -1 -f -s --noproxy '${server_info.policy_server}' --user ${g.davuser}:${g.davpw} -T";
      "download_command_suffix"   string => "${download_endpoint}";
&endif&

  classes:
    any::
      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";
      "http_only" expression => strcmp("${protocol}", "http");

  files:

    !windows::
      "${g.rudder_inventories}"
        transformer => "${download_command_prefix} ${this.promiser} ${download_command_suffix}",
        depth_search => recurse_visible(1),
        file_select  => by_name("@{g.signed_inventory_file_types}"),
        classes      => persistant_class("inventory_sent", "cant_send_inventory", "${min_resend_delay}"),
        comment      => "Sending the inventory to the server";

&if(NOVA)&
    # On windows, the this.promiser variable is not evaluated the same way. We are forced to duplicate this block
    windows::
      "${g.rudder_inventories}"
        transformer => "${download_command_prefix} \"${this.promiser}\" ${download_command_suffix}",
        depth_search => recurse_visible(1),
        file_select => by_name("@{g.signed_inventory_file_types}"),
        classes => persistant_class("inventory_sent", "cant_send_inventory", "${min_resend_delay}"),
        comment => "Sending the inventory to the server";
&endif&

  # Once we've successfully sent all inventories, remove them
    !windows.inventory_sent.!cant_send_inventory::
      "${g.rudder_inventories}"
        transformer  => "${g.rudder_rm} -f ${this.promiser}",
        depth_search => recurse_visible(1),
        file_select  => by_name("@{g.signed_inventory_file_types}"),
        classes      => if_else("inventory_file_deleted", "cant_delete_inventory_file"),
        comment      => "Cleaning up inventory files already sent to the server";

      "${g.rudder_var_tmp}/inventory_sent"
        create       => "true",
        touch        => "true",
        comment      => "Create local info about successful upload";

      "${g.rudder_var_tmp}/inventory"
        transformer  => "${g.rudder_rm} -f ${this.promiser}",
        depth_search => recurse_visible(1),
        file_select  => fusion_by_name_old("@{g.signed_inventory_file_types}", 2),
        classes      => if_else("inventory_file_deleted", "cant_delete_inventory_file"),
        comment      => "Cleaning up inventory files already sent to the server";

  methods:
    pass3.inventory_sent::
      "any" usebundle => rudder_common_report("Inventory", "result_success", "&TRACKINGKEY&", "inventory", "None", "The inventory has been successfully sent");

    pass3.cant_send_inventory::
      "any" usebundle => rudder_common_report("Inventory", "result_error", "&TRACKINGKEY&", "inventory", "None", "Could not send the inventory");

    pass3.cant_delete_inventory_file::
      "any" usebundle => rudder_common_report("Inventory", "log_warn", "&TRACKINGKEY&", "inventory", "None", "Could not delete inventory file after sending to server");
    pass3.http_only::
      "any" usebundle => rudder_common_report("Inventory", "log_warn", "&TRACKINGKEY&", "inventory", "None", "Inventory sent via HTTP without TLS");

}
body file_select fusion_by_name_old(names,days)
{
      leaf_name   => { @(names) };
      mtime       => irange(0,ago(0,0,"${days}",0,0,0));
      file_result => "mtime.leaf_name";
}

bundle agent cleanForceInventoryFlagFile
{

  files:
      "${g.rudder_base}/etc/force_inventory"
        delete     => tidy,
        ifvarclass => "inventory_sent"; # if the force inventory file was present, and we successfully sent an inventory, clean up the flag file

}
