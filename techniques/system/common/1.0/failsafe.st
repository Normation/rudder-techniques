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
# Failsafe file
#

body common control

{
bundlesequence => { "init_files", "update" };

inputs => { "common/1.0/update.cf" };
output_prefix => "rudder";

&if(NOVA)&
        host_licenses_paid => "&LICENSESPAID&";

&endif&
}

bundle common g
{
	vars:
	 any::
	   "uuid" string => "&UUID&";
	   "excludedreps" slist => { "\.X11", ".*kde.*", "\.svn", "perl" };
	   "rudder_dependencies_origin" string => "/var/rudder/tools";

	 windows::
	   "rudder_base" string  => "$(sys.winprogdir)\Rudder";
	   "rudder_sbin" string  => "$(rudder_base)\sbin";
	   "rudder_dependencies" string => "$(rudder_sbin)";

	 linux|cygwin::
	    "rudder_base" string => "/opt/rudder";
	    "rudder_sbin" string  => "$(rudder_base)/sbin";
	    "rudder_base_sbin" string  => "$(rudder_base)/sbin"; #folder where tools are installed
	    "rudder_dependencies" string => "/var/rudder/tools";
 	

# definition of the node roles
	&NODEROLE&
}

bundle common rudder_roles {

    classes:
        # Abort if no uuid is defined
        "should_not_continue" not => fileexists("${g.uuid_file}");
        # Policy Server is a machine which delivers promises
        "policy_server" expression => strcmp("root","$(g.uuid)");
        # Root Server is the top policy server machine
        "root_server" expression => strcmp("root","$(g.uuid)");
}

############################################

#generate a key if not present
bundle agent init_files {
	vars:
		"components" slist => { "cf-agent", "cf-serverd", "cf-execd", "cf-monitord", "cf-know", "cf-promises", "cf-runagent", "cf-report", "cf-key", "cf-hub" };

		nova_edition::
			"cfengine_install_path" string => "/usr/local";
		community_edition::
			"cfengine_install_path" string => "/opt/rudder";
        
    classes:
		"missing_key" not => fileexists("${sys.workdir}/ppkeys/localhost.priv");

    files:
    	cfengine_community.(linux|cygwin)::
	        "${sys.workdir}/bin/${components}" 
    	        perms => u_p("700"),
        	    copy_from => cp("${cfengine_install_path}/sbin/${components}","localhost"),
            	action => immediate;

		
    commands:
		cygwin.missing_key::
			"${sys.workdir}/bin/cf-key.exe";

		windows.missing_key.!cygwin::
			"\"$(sys.workdir)\bin\cf-key\"";
   
		linux.missing_key::
			"${sys.workdir}/bin/cf-key";
}

# This bundle will check the "last successful inputs update", and if it is older
# than 1 hour, remove cf_lock.db (and only this DB), to give CFEngine a chance
# to run properly again.
bundle agent check_lock_db_problem {
	files:
		# The aim of this promise is to create a class when this file is older
		# than one hour. The class can not be created without touching but in
		# order to not modifing the mtime we use warn_only.
		"${sys.workdir}/last_successful_inputs_update"
			file_select => over_an_hour,
			touch       => "true",
			action      => warn_only,
			classes     => success("last_successful_inputs_update_too_old", "last_successful_inputs_update_check_error", "last_successful_inputs_update_ok")

		"${sys.workdir}/state/cf_lock.db"
			delete     => tidy,
			ifvarclass => "last_successful_inputs_update_too_old",
			classes    => success("cf_lock_removed", "cf_lock_error_removing", "cf_lock_not_deleted");

	reports:
		cf_lock_removed::
			"@@Common@@log_repaired@@&TRACKINGKEY&@@Update@@None@@$(g.execRun)##$(g.uuid)@#Promises had not been updated for over an hour, this could indicate a broken lockfile. cf_lock.db was removed.";

		cf_lock_error_removing::
			"@@Common@@result_error@@&TRACKINGKEY&@@Update@@None@@$(g.execRun)##$(g.uuid)@#Promises have not been updated for over an hour, this could indicate a broken lockfile, but an error occured when trying to remove it";
}

body file_select over_an_hour()
{
	# Select file which are older than one hour
	# Use of positive mtime instead of negative one
	# In order to avoid corner effects
	mtime       => irange(2147483647, ago(0,0,0,1,0,0));
	file_result => "mtime";
}

body depth_search recurse(d)
{
depth => "$(d)";
}

#perms validation
body perms u_p(p) {
  mode  => "$(p)";
}

#server may be a list
body copy_from cp(from,server) {
  servers     => { "${server}" };
  source      => "$(from)";
  compare     => "digest";
community_edition::
  portnumber => "&COMMUNITYPORT&";

}

body action immediate
{
	ifelapsed => "0";
}

body depth_search recurse_ignore(d,list)
{
depth => "$(d)";
exclude_dirs => { @(list) };
}

body delete tidy
{
	dirlinks => "delete";
	rmdirs   => "true";
}

body action warn_only
{
action_policy => "warn";
ifelapsed => "60";
}
