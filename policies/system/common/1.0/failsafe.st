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
}

bundle common g
{
	vars:
	 windows::
	   "rudder_base" string  => "$(sys.winprogdir)\Rudder";
	   "rudder_sbin" string  => "$(rudder_base)\sbin";
	   "rudder_dependencies" string => "$(rudder_sbin)";

	 linux|cygwin::
	    "rudder_base" string => "/opt/rudder";
	    "rudder_sbin" string  => "$(rudder_base)/sbin";
	    "rudder_base_sbin" string  => "$(rudder_base)/sbin"; #folder where tools are installed
	    "rudder_dependencies" string => "/var/rudder/tools";
 	

	 any::
	   "excludedreps" slist => { "\.X11", ".*kde.*", "\.svn", "perl" };
	   "rudder_dependencies_origin" string => "/var/rudder/tools";
	   "uuid" string => "&UUID&";

# definition of the node roles
	&NODEROLE&
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
    	linux|cygwin::
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
