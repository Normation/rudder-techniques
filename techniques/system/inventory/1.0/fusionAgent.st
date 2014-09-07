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


bundle agent doInventory
{

  vars:

    # If curl is available, use it
    !windows.curl_installed::
      "download_command"   string => "${g.rudder_curl} -s -f --proxy '' -o \"${g.rudder_var_tmp}/uuid.txt\" http://${server_info.cfserved}/uuid";

    # If not, use minicurl instead
    !windows.!curl_installed::
      "download_command"   string => "${g.minicurl} --get --file \"${g.rudder_var_tmp}/uuid.txt\" --url http://${server_info.cfserved}/uuid";

&if(NOVA)&
    # On windows, always use curl
    windows::
      "download_command"   string => "\"${g.rudder_base_sbin}\curl\curl.exe\" -s -f --proxy '' -o \"${g.rudder_var_tmp}\uuid.txt\" http://${server_info.cfserved}/uuid";
&endif&

    uuid_succesfully_downloaded::
      "policy_server_uuid" string => readfile("${g.rudder_var_tmp}/uuid.txt", 50);

  classes:
      "splaying" expression => splayclass("${sys.host}${sys.ipv4}","hourly");

    # The force_inventory class may be specified by the user at runtime, or defined here
      "force_inventory" expression => fileexists("${g.rudder_base}/etc/force_inventory");

    uuid_succesfully_downloaded::
      "uuid_valid" expression => regcmp("[a-z0-9-]+","${policy_server_uuid}");
      "uuid_validity_checked"
        expression => "any",
        comment    => "This dummy class is just used for ordering the report using !uuid_valid below";

  commands:

      "${download_command}"
        comment => "Getting the uuid from the server",
        classes => if_else("uuid_succesfully_downloaded","could_not_download_uuid");

  methods:

    uuid_valid.force_inventory::
      "any" usebundle => fusionAgent;
      "any" usebundle => listInstalledVM;
      "any" usebundle => generateExtraInformations;
      "any" usebundle => turnUsersToUnicode;
      "any" usebundle => addInformationsToInventory;
      "any" usebundle => moveInventoryToFinalDestination;
      "any" usebundle => sendInventory;
      "any" usebundle => cleanForceInventoryFlagFile;

    # Workaround the wrong class expansion
    uuid_valid.Night.splaying.!inventory_sent::
      "any" usebundle => fusionAgent;
      "any" usebundle => listInstalledVM;
      "any" usebundle => generateExtraInformations;
      "any" usebundle => turnUsersToUnicode;
      "any" usebundle => addInformationsToInventory;
      "any" usebundle => moveInventoryToFinalDestination;
      "any" usebundle => sendInventory;

  reports:
    could_not_download_uuid::
      "@@Inventory@@result_error@@&TRACKINGKEY&@@inventory@@None@@${g.execRun}##${g.uuid}@#Could not retrieve the UUID of the policy server";

    uuid_succesfully_downloaded.uuid_validity_checked.!uuid_valid::
      "@@Inventory@@result_error@@&TRACKINGKEY&@@inventory@@None@@${g.execRun}##${g.uuid}@#Could not retrieve a valid UUID from the policy server";

      # Send reports to confirm this PT's success even if we don't need to send an inventory
    inventory_sent::
      "@@Inventory@@log_info@@&TRACKINGKEY&@@inventory@@None@@${g.execRun}##${g.uuid}@#An inventory was already sent less than 8 hours ago";

    !(Night.splaying).!force_inventory::
      "@@Inventory@@result_success@@&TRACKINGKEY&@@inventory@@None@@${g.execRun}##${g.uuid}@#Next inventory scheduled between 00:00 and 06:00";

}

bundle common inventory
{
  vars:
&if(NOVA)&
    windows::
    # Files names
      "UserListFile_cp" string => "\"${g.rudder_var_tmp}\UserList.tmp\"";
      "UserListFile"    string => "\"${g.rudder_var_tmp}\UserList.list\"";
      "cpuid_tool"      string => "\"${g.rudder_tools}\cpuid-windows-V1.0.vbs\"";
&endif&

    android::
      "cpuid_tool"      string => "${g.rudder_tools}/cpuid-android-V1.0.sh";

    !aix.!windows.!android::
      "cpuid_tool"      string => "${g.rudder_tools}/cpuid-linux-V1.0.sh";

    any::
      "CPUIDFile" string => "${g.rudder_var_tmp}/cpuid.arc";

  classes:

    windows::

      "rudder_inventory_userlist_tool_present" expression => fileexists("\"${g.rudder_tools}\userlist.bat\"");

    any::

      "rudder_inventory_cpuid_tool_present"    expression => fileexists("${cpuid_tool}");

}

bundle agent fusionAgent
{
  vars:
    SuSE.xen_dom0::
      "xen_tools_package" string => "xen-tools";
    SuSE.xen_domu_pv::
      "xen_tools_package" string => "xen-tools-domU";
    debian::
      "xen_tools_package" string => "xenstore-utils";
    !debian.!SuSE::
      "xen_tools_package" string => "xen";


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

  packages:
    xen.!redhat::
      "${xen_tools_package}"
        package_policy => "add",
        package_method => generic,
        classes        => cf2_if_else("xen_installed", "cant_install_xen"),
        comment        => "Installing xen package for extended data";

    xen.redhat::
      "${xen_tools_package}"
        package_policy => "add",
        package_method => rudder_yum,
        classes        => cf2_if_else("xen_installed", "cant_install_xen"),
        comment        => "Installing xen package for extended data";

  commands:
    !windows.inventoryfoldercreated::
      "${g.rudder_base}/bin/run-inventory --local=${g.rudder_var_tmp}/inventory --scan-homedirs"
        classes => cf2_if_else("run_inventory", "inventory_failed"),
        comment => "Generating inventory, in the temporary folder";

&if(NOVA)&
    windows::
      "\"C:\Program Files\Rudder\sbin\run-inventory.bat\""
        args => "--local=\"${g.rudder_var_tmp}\inventory\" --scan-homedirs 2>nul",
        contain => in_shell,
        classes => cf2_if_else("run_inventory", "inventory_failed"),
        comment => "Generating inventory";
&endif&

  reports:
    run_inventory::
      "@@Inventory@@log_debug@@&TRACKINGKEY&@@inventory@@None@@${g.execRun}##${g.uuid}@#Running inventory";

    inventory_failed::
      "@@Inventory@@result_error@@&TRACKINGKEY&@@inventory@@None@@${g.execRun}##${g.uuid}@#Could not execute the inventory";

    cant_install_curl::
      "@@Inventory@@result_error@@&TRACKINGKEY&@@inventory@@None@@${g.execRun}##${g.uuid}@#Could not install curl";

    cant_install_ocs::
      "@@Inventory@@result_error@@&TRACKINGKEY&@@inventory@@None@@${g.execRun}##${g.uuid}@#Could not install ocs";

    cant_install_xen::
      "@@Inventory@@result_error@@&TRACKINGKEY&@@inventory@@None@@${g.execRun}##${g.uuid}@#Could not install xen utils on xen systems";

    xen_installed::
      "@@Inventory@@log_info@@&TRACKINGKEY&@@inventory@@None@@${g.execRun}##${g.uuid}@#Xen utils installed";

    curl_installed::
      "@@Inventory@@log_info@@&TRACKINGKEY&@@inventory@@None@@${g.execRun}##${g.uuid}@#Curl installed";

}

# List all installed VM on the machine (based on VirtualBox)
# CAUTION : Issue with path containing a whitespace, it's not working with windows
bundle agent listInstalledVM
{
  commands:
    !windows.VirtualBoxInstalled::
      "/usr/bin/VBoxManage"
        args => "-q list vms > ${virtualMachines.VBoxListFile}",
        contain => outputable,
        classes => cf2_if_else("vb_listed", "cant_list_vb"),
        comment => "Generating file with list of VM";

&if(NOVA)&
    windows.VirtualBoxInstalled::
      "\"${virtualMachines.virtual_box_install_path}VBoxManage.exe\""
        args => "-q list vms > ${virtualMachines.VBoxListFile}",
        contain => outputable,
        classes => cf2_if_else("vb_listed", "cant_list_vb"),
        comment => "Generating file with list of VM";
&endif&

    !windows.VMWareInstalled::
      "${virtualMachines.VMWareScript}"
        contain => outputable,
        args => " > ${virtualMachines.VMWareListFile}",
        classes => cf2_if_else("vm_listed", "cant_list_vm"),
        comment => "Generating file with list of VM";

&if(NOVA)&
    windows.VMWareInstalled::
      "${virtualMachines.VMWareScript}"
        contain => outputable,
        args => " > ${virtualMachines.VMWareListFile}",
        classes => cf2_if_else("vm_listed", "cant_list_vm"),
        comment => "Generating file with list of VM";
&endif&

  files:
    VirtualBoxInstalled::
      "${virtualMachines.VBoxListFile}"
        create => "true",
        edit_line => xmlify(${virtualMachines.VBoxAttr}),
        comment => "Converting file into pseudo XML";

    VMWareInstalled::
      "${virtualMachines.VMWareListFile}"
        create => "true",
        edit_line => xmlify(${virtualMachines.VMWareAttr}),
        comment => "Converting file into pseudo XML";


  reports:
    cant_list_vm::
      "@@Inventory@@log_warn@@&TRACKINGKEY&@@inventory@@None@@${g.execRun}##${g.uuid}@#Could not list installed VMWare machines";

    cant_list_vb::
      "@@Inventory@@log_warn@@&TRACKINGKEY&@@inventory@@None@@${g.execRun}##${g.uuid}@#Could not list installed VirtualBox machines";
}

bundle agent generateExtraInformations
{
  commands:

&if(NOVA)&
    windows.rudder_inventory_userlist_tool_present::
      "\"${g.rudder_tools}\userlist.bat\""
        args => " > ${inventory.UserListFile_cp} ",
        contain => outputable,
        classes => cf2_if_else("userlist", "userlist_fail"),
        comment => "Generating file with list of users";

    windows.rudder_inventory_cpuid_tool_present::

      "${sys.winsysdir}\cscript.exe"
        args => "/Nologo \"${g.rudder_tools}/cpuid-windows-V1.0.vbs\" > \"${inventory.CPUIDFile}\"",
        contain => outputable,
        classes => cf2_if_else("cpuid", "cpuid_fail"),
        comment => "Generating file with CPUID information";
&endif&

    !windows.rudder_inventory_cpuid_tool_present::
      "${inventory.cpuid_tool}"
        args => " > ${inventory.CPUIDFile}",
        contain => outputable,
        classes => cf2_if_else("cpuid", "cpuid_fail"),
        comment => "Generating file with CPUID information";

  reports:
    userlist::
      "@@Inventory@@log_debug@@&TRACKINGKEY&@@inventory@@None@@${g.execRun}##${g.uuid}@#Generated the userlist";
    cpuid::
      "@@Inventory@@log_debug@@&TRACKINGKEY&@@inventory@@None@@${g.execRun}##${g.uuid}@#Generated the CPUID";


    userlist_fail::
      "@@Inventory@@result_error@@&TRACKINGKEY&@@inventory@@None@@${g.execRun}##${g.uuid}@#Could not generate the user list";

    cpuid_fail::
      "@@Inventory@@result_error@@&TRACKINGKEY&@@inventory@@None@@${g.execRun}##${g.uuid}@#Could not generate the cpuid";

    !rudder_inventory_userlist_tool_present::

      "@@Inventory@@log_debug@@&TRACKINGKEY&@@inventory@@None@@$(g.execRun)##$(g.uuid)@#The user list generation tool is not present yet. Skipping...";

    !rudder_inventory_cpuid_tool_present::

      "@@Inventory@@log_debug@@&TRACKINGKEY&@@inventory@@None@@$(g.execRun)##$(g.uuid)@#The CPUID generation tool is not present yet. Skipping...";

}

bundle agent turnUsersToUnicode
{

&if(NOVA)&
  commands:
    windows::
      "\"${g.rudder_tools}\iconv.exe\""
        args => " -f CP850 -t UTF-8 ${inventory.UserListFile_cp} > ${inventory.UserListFile} ",
        contain => outputable_dir("${g.rudder_tools}"),
        classes => cf2_if_else("userlist", "userlist_fail"),
        comment => "Generating file with list of users in UTF";

&endif&
  reports:

    windows::
      "@@Inventory@@log_debug@@&TRACKINGKEY&@@inventory@@None@@${g.execRun}##${g.uuid}@#This is a windows machine. User list has been converted to Unicode";
}

# adding data to the inventory :
# UUID and CFKey in <DEVICEID>,
# list of VM in <CONTENT>
bundle agent addInformationsToInventory
{
  vars:
&if(NOVA)&
    windows.!cygwin::
      "CFKEY_cmd"      string => "${sys.winsysdir}\cmd.exe /c \"type \"${sys.workdir}\ppkeys\localhost.pub\"\"";
      "USER"           string => getenv("USERNAME", 40);
      "RUDDERUUID_cmd" string => "${sys.winsysdir}\cscript.exe /Nologo \"${g.rudder_tools}/uuid.vbs\"";
      "polserv_uuid"   string => readfile( "${g.rudder_var_tmp}\uuid.txt" , "50" );
      # Somehow, using the variable rather than the path fails with readstringlist
      "users" slist => { readstringlist("C:\Program Files\Rudder\var\tmp\UserList.list","#.*","[\n| |\r]",50,4000) };
&endif&

    cygwin::
      "mywinpath"      string => execresult("/usr/bin/echo $WINDIR ", "useshell");
      "CFKEY_cmd"      string => "/usr/bin/cat ${sys.workdir}/ppkeys/localhost.pub";
      "USER_cmd"       string => "/usr/bin/whoami";
      "RUDDERUUID_cmd" string => "${sys.winsysdir}\cscript.exe /Nologo ${g.rudder_tools}/uuid.vbs";
      "polserv_uuid"   string => readfile( "${g.rudder_var_tmp}/uuid.txt" , "50" );
      "users"          slist => { readstringlist("${inventory.UserListFile}","#.*","[\n| |\r]",10,4000) };


    xen.SuSE.xen_domu_pv::
      "VMRUDDERUUID_cmd" string => "/bin/xenstore-read vm";

    xen.(centos|redhat|(SuSE.xen_dom0))::
      "VMRUDDERUUID_cmd" string => "/usr/bin/xenstore-read vm";

    xen.(!SuSE.!centos.!redhat)::
      "VMRUDDERUUID_cmd" string => "/usr/sbin/xenstore-read vm";

    xen::
      "VMRUDDERUUID" string => execresult("${VMRUDDERUUID_cmd}", "noshell");

    xen.xenrudderuuid::
      "RUDDERUUID" string => "${vmarray[1]}";

    !windows::
      "polserv_uuid"          string => readfile( "${g.rudder_var_tmp}/uuid.txt" , "50" );

    android::
      "RUDDERUUID_cmd"        string => "/system/xbin/sqlite3 /data/data/com.android.providers.settings/databases/settings.db \"select value from secure where name = 'android_id'\"";
      "CFKEY_cmd"             string => "/system/bin/cat ${sys.workdir}/ppkeys/localhost.pub";
      "USER_cmd"              string => "/system/xbin/whoami";
      "usersnumber"           int =>  "1";
      "users"                 slist => {"root"};
      "android_kernelname"    string => "linux";
      "android_kernelversion" string => execresult("/system/xbin/uname -r", "noshell");
      "android_name"          string => "Android";
      "android_version"       string => execresult("/system/bin/getprop ro.build.version.release", "noshell");
      "android_fullname"      string => "Android ${android_version}";
      "logdate"               string => execresult("/system/bin/date '+%Y-%m-%d %H:%M:%S'", "noshell");

    linux.!xen::
      "RUDDERUUID_cmd" string => "/usr/sbin/dmidecode -s system-uuid";

    aix::
      "RUDDERUUID_cmd" string => "/usr/bin/uname -f";

    !windows.!android::
      "CFKEY_cmd"      string => "/bin/cat ${sys.workdir}/ppkeys/localhost.pub";
      "USER_cmd"       string => "/usr/bin/whoami";
      "usersnumber"    int =>  readstringarray("userslist","/etc/passwd","#[^\n]*",":",50,16000);
      "users"          slist => getindices("userslist");

    any::
      "CFKEY"      string => execresult("${CFKEY_cmd}", "noshell");

      "USER"       string => execresult("${USER_cmd}", "noshell");

    !xen::
      "RUDDERUUID" string => execresult("${RUDDERUUID_cmd}", "noshell");


  classes:
    xen::
      "xenrudderuuid" expression => regextract("/vm/(.*)", "${VMRUDDERUUID}", "vmarray");

    any::
      "uuiddefined" expression => isvariable("RUDDERUUID");

  files:
&if(NOVA)&
    windows::
      "C:/Progra~1/Rudder/var/tmp/inventory/.*.ocs"
        edit_line => add_information_to_inventory(${RUDDERUUID}, ${CFKEY}, ${USER}, ${polserv_uuid}),
        edit_defaults => def_no_backup;

      "C:/Progra~1/Rudder/var/tmp/inventory/.*.ocs"
        edit_line => add_users_information_to_inventory(@{addInformationsToInventory.users}),
        edit_defaults => def_no_backup;
&endif&

    !windows.uuiddefined::
      "${g.rudder_var_tmp}/inventory/.*.ocs"
        edit_line => add_information_to_inventory(${RUDDERUUID}, ${CFKEY}, ${USER}, ${polserv_uuid}),
        edit_defaults => def_no_backup;

      "${g.rudder_var_tmp}/inventory/.*.ocs"
        edit_line => add_users_information_to_inventory(@{addInformationsToInventory.users}),
        edit_defaults => def_no_backup;

    android::
      "${g.rudder_var_tmp}/inventory/.*.ocs"
        edit_line => add_information_to_android_inventory(${android_fullname}, ${android_kernelname}, ${android_kernelversion}, ${android_name}, ${android_version}),
        edit_defaults => def_no_backup;

      "${g.rudder_var_tmp}/inventory/.*.ocs"
        edit_line => add_accesslog_to_android_inventory(${logdate}),
        edit_defaults => def_no_backup;
}


# Move the inventory file in the shared directory
bundle agent moveInventoryToFinalDestination
{
  files:
      "${g.rudder_inventories}"
        copy_from => copy("${g.rudder_var_tmp}/inventory"),
        depth_search => recurse_visible(1),
        file_select => inventory_files,
        comment => "Moving inventory files to the final location";

}


# Send the file to the promises server
bundle agent sendInventory
{

  vars:

      "download_endpoint"         string => "http://${server_info.cfserved}/inventory-updates/";

    # If curl is available, use it
    !windows.curl_installed::
      "download_command_prefix"   string => "${g.rudder_curl} -f -s --proxy '' --user ${g.davuser}:${g.davpw} -T";
      "download_command_suffix"   string => "${download_endpoint}";

    # If not, use minicurl instead
    !windows.!curl_installed::
      "download_command_prefix"   string => "${g.minicurl} --put --authentication ${g.davuser}:${g.davpw} --file";
      "download_command_suffix"   string => "--url ${download_endpoint}";

&if(NOVA)&
    # On windows, always use curl
    windows::
      "download_command_prefix"   string => "\"${g.rudder_base_sbin}\curl.exe\" -f -s --user ${g.davuser}:${g.davpw} -T";
      "download_command_suffix"   string => "${download_endpoint}";
&endif&

  files:

    !windows::
      "${g.rudder_inventories}"
        transformer => "${download_command_prefix} ${this.promiser} ${download_command_suffix}",
        depth_search => recurse_visible(1),
        file_select => inventory_files,
        classes => persistant_class("inventory_sent", "cant_send_inventory", 480),
        comment => "Sending the inventory to the server";

&if(NOVA)&
    # On windows, the this.promiser variable is not evaluated the same way. We are forced to duplicate this block
    windows::
      "${g.rudder_inventories}"
        transformer => "${download_command_prefix} \"${this.promiser}\" ${download_command_suffix}",
        depth_search => recurse_visible(1),
        file_select => inventory_files,
        classes => persistant_class("inventory_sent", "cant_send_inventory", 480),
        comment => "Sending the inventory to the server";
&endif&

  # Once we've successfully sent all inventories, remove them
    !windows.inventory_sent.!cant_send_inventory::
      "${g.rudder_inventories}"
        transformer  => "${g.rudder_rm} -f ${this.promiser}",
        depth_search => recurse_visible(1),
        file_select  => inventory_files,
        classes      => if_else("inventory_file_deleted", "cant_delete_inventory_file"),
        comment      => "Cleaning up inventory files already sent to the server";

      "${g.rudder_var_tmp}/inventory"
        transformer  => "${g.rudder_rm} -f ${this.promiser}",
        depth_search => recurse_visible(1),
        file_select  => inventory_files,
        classes      => if_else("inventory_file_deleted", "cant_delete_inventory_file"),
        comment      => "Cleaning up inventory files already sent to the server";

  reports:
    inventory_sent::
      "@@Inventory@@result_success@@&TRACKINGKEY&@@inventory@@None@@${g.execRun}##${g.uuid}@#The inventory has been successfully sent";

    cant_send_inventory::
      "@@Inventory@@result_error@@&TRACKINGKEY&@@inventory@@None@@${g.execRun}##${g.uuid}@#Could not send the inventory";

    cant_delete_inventory_file::
      "@@Inventory@@log_warn@@&TRACKINGKEY&@@inventory@@None@@${g.execRun}##${g.uuid}@#Could not delete inventory file after sending to server";
}

#####################################################
#Adding the list of Virtual Machines into the report
#Adding the ids in the report
#####################################################
bundle edit_line add_information_to_inventory(RUDDERUUID, CFKEY, USER, POLSRVUUID)
{
  insert_lines:
      "<UUID>${g.uuid}</UUID>${const.n}<USER>${USER}</USER>${const.n}<AGENTSNAME>${const.n}</AGENTSNAME>${const.n}<MACHINEID>${RUDDERUUID}</MACHINEID>${const.n}<CFKEY>${CFKEY}</CFKEY>${const.n}<HOSTNAME>${sys.fqhost}</HOSTNAME>${const.n}<POLICY_SERVER>${POLSRVUUID}</POLICY_SERVER>${const.n}"
        location    => after_deviceid,
        insert_type => "preserve_block",
        comment     => "Add the UUID and CFKEY tags in the inventory file";

    any::
      "<VMS>${const.n}</VMS>${const.n}<USERSLIST>${const.n}</USERSLIST>"
        insert_type => "preserve_block",
        location    => after_content;

    rudder_inventory_cpuid_tool_present::

      "${inventory.CPUIDFile}"
        insert_type => "file",
        location => after_location("<HOSTNAME>"),
        comment => "Adding the CPUID data in the inventory file";

    nova_edition::
      "<AGENTNAME>Nova</AGENTNAME>"
        location => after_location("<AGENTSNAME>"),
        comment => "Adding the agent data in the inventory file";

    community_edition::
      "<AGENTNAME>Community</AGENTNAME>"
        location => after_location("<AGENTSNAME>"),
        comment => "Adding the agent data in the inventory file";

    VirtualBoxInstalled::
      "${virtualMachines.VBoxListFile}"
        insert_type => "file",
        location => after_location("<VMS>"),
        comment => "Adding the list of VM in the inventory file";

    VMWareInstalled::
      "${virtualMachines.VMWareListFile}"
        insert_type => "file",
        location => after_vm,
        comment => "Adding the list of VM in the inventory file";
}

bundle edit_line add_information_to_android_inventory(fullname, kernelname, kernelversion, name, version)
{
  insert_lines:

    android::
      "<OPERATINGSYSTEM>${const.n}<FULL_NAME>${fullname}</FULL_NAME>${const.n}<KERNEL_NAME>${kernelname}</KERNEL_NAME>${const.n}<KERNEL_VERSION>${kernelversion}</KERNEL_VERSION>${const.n}<NAME>${name}</NAME>${const.n}<VERSION>${version}</VERSION>${const.n}</OPERATINGSYSTEM>"
        location    => after_location("<CONTENT>"),
        insert_type => "preserve_block",
        comment     => "Adding the list of OPERATINGSYSTEM part";
}

#this bundle is necessary for OCSInventory (but not for fusioninventory)
bundle edit_line add_accesslog_to_android_inventory(logdate)
{
  insert_lines:
    android::
      "<ACCESSLOG><LOGDATE>${logdate}</LOGDATE></ACCESSLOG>"
        location => after_location("</OPERATINGSYSTEM>"),
        comment => "Adding log date";
}

bundle edit_line add_users_information_to_inventory(userlist)
{
  insert_lines:

    (windows.rudder_inventory_userlist_tool_present)|!windows::

      "<USER>${userlist}</USER>${const.n}" location => after_users,
        comment => "Add the UUID and CFKEY tags in the inventory file";
}

#Locators
body location after_location(pos)
{
        select_line_matching => ".*${pos}.*";
        before_after => "after";
}

body location after_deviceid
{
        select_line_matching => ".*<DEVICEID>.*";
        before_after => "after";
}

body location after_content
{
        select_line_matching => ".*<CONTENT>.*";
        before_after => "after";
}
body location after_vm
{
        select_line_matching => ".*<VMS>.*";
        before_after => "after";
}
body location after_users
{
        select_line_matching => ".*<USERSLIST>.*";
        before_after => "after";
}

###############
# Editors
##############
# Convert a simple list in <VM TYPe="vmtype"><NAME>machine_name</NAME><UUID>value<UUID></VM>
bundle edit_line xmlify(ATTR)
{
  replace_patterns:
      "\"(.*)\" \{(.*)\}"
      replace_with=> xmled(${ATTR});

}

body replace_with xmled(attribute)
{
        replace_value => "<VM TYPE=\"${attribute}\"><NAME>${match.1}</NAME><UUID>${match.2}</UUID></VM>";
}


# select the inventory files that has the right extension
#I'd like to select also those older than 4 hours (ctime => irange(ago(0,0,0,4,0,0),now);) not working...
# (for some reason, ocs duplicated files over time)
body file_select inventory_files
{

    any::
        leaf_name => { ".*.ocs" };
        file_result => "leaf_name";

&if(NOVA)&
  #windows::
  #	leaf_name => { ".*.xml" };
  #	file_result => "leaf_name";
&endif&

}

body perms inventory_perms
{
        mode => "0700";
}


body file_select one_day_age
#
# we can build old "include", "exclude", and "ignore"
# from these as standard patterns - these bodies can
# form a library of standard patterns
#

{
        mtime     => irange(ago(1,0,0,0,0,0),ago(0,0,1,0,0,0));
        file_result => "mtime";
}

bundle agent cleanForceInventoryFlagFile
{

  files:
      "${g.rudder_base}/etc/force_inventory"
        delete     => tidy,
        ifvarclass => "inventory_sent"; # if the force inventory file was present, and we successfully sent an inventory, clean up the flag file

}
