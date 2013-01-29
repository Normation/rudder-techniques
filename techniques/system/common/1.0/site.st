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
# Site specific promises
#
#######################################################

bundle common g
{
vars:

 windows::
   "rudder_base" string  => "$(sys.winprogdir)\Rudder";
   "rudder_sbin" string  => "$(rudder_base)\sbin";
   "rudder_var" string  => "$(sys.winprogdir)\Rudder\var";
   "rudder_var_tmp" string  => "$(rudder_var)\tmp"; # tmp generated data
   "rudder_base_sbin" string  => "$(rudder_base)\sbin"; #folder where tools are installed
   "rudder_inventories"  string => "$(rudder_var)\inventories";
   "rudder_base_sbin_arg" string => "$(sys.winprogdir)\Rudder\sbin"; # for the installer command line
   "rudder_dependencies" string => "$(rudder_sbin)";
   "escaped_workdir" string => escape("$(sys.workdir)");

   # The time at which the execution started
   "execRun" string => execresult("\"${g.rudder_sbin}\getDate.bat\"", "noshell");

 windows.!cygwin::
   "uuid_file" string => "${rudder_base}\etc\uuid.hive";

 (linux|cygwin).!android::
    "rudder_base" string => "/opt/rudder";
    "rudder_var"  string => "/var/rudder";
    "rudder_sbin" string  => "$(rudder_base)/sbin";
    "rudder_var_tmp" string  => "$(rudder_var)/tmp"; # tmp generated data
    "rudder_base_sbin" string  => "$(rudder_base)/sbin"; #folder where tools are installed
    "rudder_inventories" string  => "$(rudder_var)/inventories";
    "uuid_file" string => "${rudder_base}/etc/uuid.hive";
    "rudder_dependencies" string => "/var/rudder/tools";
    "crontab" string => "/etc/crontab";
    "rudder_curl" string => "/usr/bin/curl";
    "rudder_rm" string => "/bin/rm";
    # The time at which the execution started
    "execRun" string => execresult("/bin/date --rfc-3339=second", "noshell");

 android::
    "rudder_base" string => "/data/rudder";
    "rudder_var"  string => "/data/rudder";
    "rudder_sbin" string  => "$(rudder_base)/sbin";
    "rudder_var_tmp" string  => "$(rudder_var)/tmp"; # tmp generated data
    "rudder_base_sbin" string  => "$(rudder_base)/sbin"; #folder where tools are installed
    "rudder_inventories" string  => "$(rudder_var)/inventories";
    "uuid_file" string => "${rudder_base}/etc/uuid.hive";
    "rudder_dependencies" string => "$(rudder_var)/tools";
    "crontab" string => "/etc/crontab";
    "rudder_curl" string => "/system/bin/curl";
    "rudder_rm" string => "/system/xbin/rm";

    # The time at which the execution started
    # "execRun" string => execresult("/system/xbin/date \"+%Y-%m-%d %T%z\"", "noshell"); <= Problem with the timezone (missing semicolon)
    "execRun" string => execresult("/system/xbin/date \"+%Y-%m-%d %T+02:00\"", "noshell");


 any::
   "uuid" string => readfile("$(g.uuid_file)", 60);
   "server_shares_folder" string  => "/var/rudder/share/${uuid}/promises/shares";
   "rudder_var_reports" string => "$(rudder_var)/reports";
   "davuser" string => "&DAVUSER&";
   "davpw" string => "&DAVPASSWORD&";
   "excludedreps" slist => { "\.X11", ".*kde.*", "\.svn", "perl" };
   "rudder_dependencies_origin" string => "/var/rudder/tools";

}
