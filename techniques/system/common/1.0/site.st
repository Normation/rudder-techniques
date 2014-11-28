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

    android::
      "rudder_base"                string => "/data/rudder";
      "rudder_var"                 string => "/data/rudder";
      "rudder_curl"                string => "/system/bin/curl";
      "rudder_rm"                  string => "/system/xbin/rm";
      "rudder_tools_files_android" slist => { "cpuid-android-V1.0.sh" };

    !windows.!android::
      "rudder_base"                string => "/opt/rudder";
      "rudder_curl"                string => "/usr/bin/curl";
      "rudder_rm"                  string => "/bin/rm";

    solaris::
      "rudder_var"                 string => "/opt/rudder/var";

    !solaris.!windows.!android::
      "rudder_var"                 string => "/var/rudder";

    !windows::
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

      # DEPRECATED: This variable is used in pre-2.9 Techniques.
      "rudder_dependencies"        string => "${rudder_var}/tools";

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
      "rudder_curl"                string => "\"${rudder_base_sbin}\curl\curl.exe\"";
      "uuid_file"                  string => "${rudder_base}\etc\uuid.hive";
      "rudder_disable_agent_file"  string => "${rudder_base}\etc\disable-agent";
      "rudder_tools_files_windows" slist => { "uuid.vbs",
                                              "iconv.dll",
                                              "userlist.bat",
                                              "getDate.bat",
                                              "registrydns.bat",
                                              "iconv.exe",
                                              "curl/curl.exe",
                                              "curl/libcurl.dll",
                                              "curl/libssl32.dll",
                                              "curl/libeay32.dll",
                                              "cpuid-windows-v1.0.vbs",
                                              "fusionagent.exe",
                                              "centreon-e2s.exe",
                                              "e2s.tpl",
                                            };


      # DEPRECATED: This variable is used in pre-2.9 Techniques.
      "rudder_dependencies"        string => "${rudder_sbin}";

    aix::

      "gzip"                       string => "/usr/bin/gzip";

    !aix.!windows::

      "gzip"                       string => "/bin/gzip";

    any::
      "uuid"                        string => readfile("${g.uuid_file}", 60);
      "server_shares_folder"        string => "/var/rudder/share/${uuid}/promises/shares";
      "rudder_var_reports"          string => "${rudder_var}/reports";
      "davuser"                     string => "&DAVUSER&";
      "davpw"                       string => "&DAVPASSWORD&";
      "minicurl"                    string => "${rudder_bin}/rudder-perl ${sys.workdir}/inputs/common/utilities/minicurl";
      "excludedreps"                slist  => { "\.X11", ".*kde.*", "\.svn", "perl" };
      "rudder_tools_origin"         string => "/var/rudder/tools";
      "rudder_ncf_origin_common"    string => "/usr/share/ncf/tree";
      "rudder_ncf_origin_local"     string => "/var/rudder/configuration-repository/ncf";
      "inventory_upload_protocol"   string => "http";

      "uncompressed_inventory_file_types" slist => { ".*.ocs" };
      "inventory_file_types"              slist => { "@{uncompressed_inventory_file_types}", ".*.gz" };

      "server_roles_path"           string => "${rudder_base}/etc/server-roles.d/";

      "rudder_tools_updated_origin" string => "${rudder_tools_origin}/rudder_tools_updated";
      "rudder_tools_updated"        string => "${rudder_tools}/rudder_tools_updated";

      # DEPRECATED: This variable is used in pre-2.9 Techniques.
      "rudder_dependencies_origin"  string => "/var/rudder/tools";

    # The time at which the execution started
    windows.!cygwin::
      "execRun"                    string => execresult("\"${g.rudder_sbin}\getDate.bat\"", "noshell");
    android::
      "execRun"                    string => execresult("/system/xbin/date \"+%Y-%m-%d %T%z\" | sed 's/\([-+][0-9][0-9]\)\([0-9][0-9]\)$/\1:\2/'", "useshell");
    (!windows|cygwin).!android::
      # We would like to use date's "--rfc-3339=second" option here, but it is not available on older OSes (RHEL 3/4, AIX 5...)
      "execRun"                    string => execresult("/bin/date -u \"+%Y-%m-%d %T+00:00\"", "noshell");

    !windows.!android::
      "rudder_tools_files_unix"    slist => { "send-clean.sh",
                                              "cpuid-linux-V1.0.sh",
                                              "vmware_info.sh",
                                              "check_rsyslog_version",
                                              "apache-vhost.tpl",
                                            };

    SuSE::
      "rudder_tools_files_suse"    slist => { "openvpn-2.2.1-1.x86_64.rpm",
                                              "openvpn-2.2.1-1.i686.rpm",
                                              "zypper-repo.tpl",
                                              "check_zypper_version",
                                              "checkzmd.pl",
                                            };
    any::
      "rudder_tools_files"         slist => { @{rudder_tools_files_windows},
                                              @{rudder_tools_files_android},
                                              @{rudder_tools_files_unix},
                                              @{rudder_tools_files_suse},
                                              "checkroute.pl",
                                            }, policy => "ifdefined";

      # Heartbeat interval, in minutes. Only used when in "changes-only" compliance mode
      # In this mode, we should only send a "StartRun"/"EndRun" message pair if changes occur,
      # or if this interval has elapsed since we last sent one
      "heartbeat_interval" string => "&RUDDER_HEARTBEAT_INTERVAL&";

      "rudder_node_config_id" string => "&RUDDER_NODE_CONFIG_ID&";

  classes:

    # Utilities
    "gzip_installed"                 expression => isexecutable("${rudder_gzip}");
    "curl_installed"                 expression => isexecutable("${rudder_curl}");

    # Roles
    "rudder_server_roles_dir_exists" expression => isdir("${server_roles_path}");
    "role_rudder_server_root"        expression => fileexists("${rudder_base}/etc/server-roles.d/rudder-server-root");
    "role_rudder_inventory_ldap"     expression => fileexists("${rudder_base}/etc/server-roles.d/rudder-inventory-ldap");
    "role_rudder_jetty"              expression => fileexists("${rudder_base}/etc/server-roles.d/rudder-jetty");
    "role_rudder_webapp"             expression => fileexists("${rudder_base}/etc/server-roles.d/rudder-webapp");
    "role_rudder_inventory_endpoint" expression => fileexists("${rudder_base}/etc/server-roles.d/rudder-inventory-endpoint");
    "role_rudder_reports"            expression => fileexists("${rudder_base}/etc/server-roles.d/rudder-reports");
    "role_rudder_relay_top"          expression => fileexists("${rudder_base}/etc/server-roles.d/rudder-relay-top");

}
