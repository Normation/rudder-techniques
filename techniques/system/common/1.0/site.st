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
      "rudder_base"                string => "${sys.winprogdir}\Rudder";
      "rudder_bin"                 string => "${rudder_base}\bin";
      "rudder_sbin"                string => "${rudder_base}\sbin";
      "rudder_var"                 string => "${sys.winprogdir}\Rudder\var";
      "rudder_var_tmp"             string => "${rudder_var}\tmp"; # tmp generated data
      "rudder_base_sbin"           string => "${rudder_base}\sbin"; #folder where tools are installed
      "rudder_inventories"         string => "${rudder_var}\inventories";
      "rudder_base_sbin_arg"       string => "${sys.winprogdir}\Rudder\sbin"; # for the installer command line
      "rudder_dependencies"        string => "${rudder_sbin}";
      "escaped_workdir"            string => escape("${sys.workdir}");

    windows.!cygwin::
      "uuid_file"                  string => "${rudder_base}\etc\uuid.hive";

      # The time at which the execution started
      "execRun_cmd" string => "\"${g.rudder_sbin}\getDate.bat\"";

    linux|cygwin::
      "rudder_base"                string => "/opt/rudder";
      "rudder_var"                 string => "/var/rudder";
      "rudder_bin"                 string => "${rudder_base}/bin";
      "rudder_sbin"                string => "${rudder_base}/sbin";
      "rudder_var_tmp"             string => "${rudder_var}/tmp"; # tmp generated data
      "rudder_base_sbin"           string => "${rudder_base}/sbin"; #folder where tools are installed
      "rudder_inventories"         string => "${rudder_var}/inventories";
      "uuid_file"                  string => "${rudder_base}/etc/uuid.hive";
      "rudder_dependencies"        string => "/var/rudder/tools";
      "crontab"                    string => "/etc/crontab";

    # The time at which the execution started
    (linux|cygwin).!(centos_3|redhat_3|centos_4|redhat_4)::
      "execRun_cmd"                string => "/bin/date --rfc-3339=second";
    (linux|cygwin).(centos_3|redhat_3|centos_4|redhat_4)::
      # We would like to use date's "--rfc-3339=second" option here, but it is not available on older OSes (RHEL 3/4, AIX 5...)
      "execRun_cmd"                string => "/bin/date -u \"+%Y-%m-%d %T+00:00\"";

   any::
     "uuid"                        string => readfile("${g.uuid_file}", 60);
     "server_shares_folder"        string  => "/var/rudder/share/${uuid}/promises/shares";
     "rudder_var_reports"          string => "${rudder_var}/reports";
     "davuser"                     string => "&DAVUSER&";
     "davpw"                       string => "&DAVPASSWORD&";
     "excludedreps"                slist => { "\.X11", ".*kde.*", "\.svn", "perl" };
     "rudder_dependencies_origin"  string => "/var/rudder/tools";
     # The time at which the execution started
     "execRun"                     string => execresult("${execRun_cmd}", "noshell");

}
