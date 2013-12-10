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
      "rudder_tools"               string => "${rudder_sbin}";
      "rudder_ncf"                 string => "${rudder_base}\ncf";
      "escaped_workdir"            string => escape("${sys.workdir}");
      "rudder_curl"                string => "${rudder_base_sbin}\curl\curl.exe";
      # The time at which the execution started
      "execRun_cmd" string => "\"${g.rudder_sbin}\getDate.bat\"";

      # DEPRECATED: This variable is used in pre-2.9 Techniques.
      "rudder_dependencies"        string => "${rudder_sbin}";

    windows.!cygwin::
      "uuid_file"                  string => "${rudder_base}\etc\uuid.hive";
      "rudder_disable_agent_file"  string => "${rudder_base}\etc\disable-agent";

    linux|cygwin::
      "rudder_base"                string => "/opt/rudder";
      "rudder_var"                 string => "/var/rudder";
      "rudder_bin"                 string => "${rudder_base}/bin";
      "rudder_sbin"                string => "${rudder_base}/sbin";
      "rudder_var_tmp"             string => "${rudder_var}/tmp"; # tmp generated data
      "rudder_base_sbin"           string => "${rudder_base}/sbin"; #folder where tools are installed
      "rudder_inventories"         string => "${rudder_var}/inventories";
      "uuid_file"                  string => "${rudder_base}/etc/uuid.hive";
      "rudder_disable_agent_file"  string => "${rudder_base}/etc/disable-agent";
      "rudder_tools"               string => "${rudder_var}/tools";
      "rudder_ncf"                 string => "${rudder_var}/ncf";
      "crontab"                    string => "/etc/crontab";
      "rudder_curl"                string => "/usr/bin/curl";
      "rudder_rm"                  string => "/bin/rm";
      # The time at which the execution started
      "execRun_cmd" string => "/bin/date --rfc-3339=second";

      # DEPRECATED: This variable is used in pre-2.9 Techniques.
      "rudder_dependencies"        string => "${rudder_var}/tools";

    android::
      "rudder_base"                string => "/data/rudder";
      "rudder_var"                 string => "/data/rudder";
      "rudder_sbin"                string => "${rudder_base}/sbin";
      "rudder_var_tmp"             string => "${rudder_var}/tmp"; # tmp generated data
      "rudder_base_sbin"           string => "${rudder_base}/sbin"; #folder where tools are installed
      "rudder_inventories"         string => "${rudder_var}/inventories";
      "uuid_file"                  string => "${rudder_base}/etc/uuid.hive";
      "rudder_tools"               string => "${rudder_var}/tools";
      "rudder_ncf"                 string => "${rudder_var}/ncf";
      "crontab"                    string => "/etc/crontab";
      "rudder_curl"                string => "/system/bin/curl";
      "rudder_rm"                  string => "/system/xbin/rm";

      # The time at which the execution started
      "execRun"                    string => execresult("/system/xbin/date \"+%Y-%m-%d %T%z\" | sed 's/\([-+][0-9][0-9]\)\([0-9][0-9]\)$/\1:\2/'", "useshell");

      # DEPRECATED: This variable is used in pre-2.9 Techniques.
      "rudder_dependencies"        string => "${rudder_var}/tools";

    any::
      "uuid"                        string => readfile("$(g.uuid_file)", 60);
      "server_shares_folder"        string  => "/var/rudder/share/${uuid}/promises/shares";
      "rudder_var_reports"          string => "$(rudder_var)/reports";
      "davuser"                     string => "&DAVUSER&";
      "davpw"                       string => "&DAVPASSWORD&";
      "excludedreps"                slist => { "\.X11", ".*kde.*", "\.svn", "perl" };
      "rudder_tools_origin"         string => "/var/rudder/tools";
      "rudder_ncf_origin_common"    string => "/usr/share/ncf/tree";
      "rudder_ncf_origin_local"     string => "/var/rudder/configuration-repository/ncf";
      # The time at which the execution started
      "execRun"                     string => execresult("${execRun_cmd}", "noshell");

      # DEPRECATED: This variable is used in pre-2.9 Techniques.
      "rudder_dependencies_origin"  string => "/var/rudder/tools";

}
