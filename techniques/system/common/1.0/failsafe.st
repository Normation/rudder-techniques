# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: 2021 Normation SAS

#
# Failsafe file
#

body common control
{
        bundlesequence     => { "check_uuid", "update_action", "rudder_persist_update_classes" };

        inputs             => { "common/1.0/common.cf", "common/1.0/update.cf" };
        output_prefix      => "rudder";

        protocol_version   => "2";

        tls_min_version => "1.3";
}

&if(INITIAL)&

@if feature(copyfrom_restrict_keys)
body agent control
{
  known_policy_server::
    copyfrom_restrict_keys => { "${rudder_update_conf.policy_server_hash}" };
    default_timeout => "10";
}
@endif

&endif&

&if(!INITIAL)&

@if feature(copyfrom_restrict_keys)
body agent control
{
    copyfrom_restrict_keys => { "&POLICY_SERVER_KEY&" };
    default_timeout => "10";
}
@endif

&endif&

bundle common g
{
  vars:
      "rudder_base"              string => "/opt/rudder";
      "rudder_var"               string => "/var/rudder";
      "rudder_log"               string => "/var/log/rudder";
      "rudder_bin"               string => "${rudder_base}/bin";
      "rudder_sbin"              string => "${rudder_base}/sbin";
      "rudder_base_sbin"         string => "${rudder_base}/sbin"; #folder where tools are installed
      "rudder_ncf"               string => "${rudder_var}/ncf";
      "uuid_file"                string => "${rudder_base}/etc/uuid.hive";

    any::
      "uuid"                     string => readfile("${g.uuid_file}", 60);
      "ncf_excludedreps"          slist => { "50_techniques" };
      "rudder_ncf_origin_common" string => "/usr/share/ncf/tree";
      "rudder_ncf_origin_local"  string => "&CONFIGURATION_REPOSITORY_FOLDER&/ncf";

      "rudder_ncf_hash_file"          string => "ncf_hash_file";
      "rudder_ncf_origin_common_hash" string => "${rudder_ncf_origin_common}/${rudder_ncf_hash_file}";
      "rudder_ncf_origin_local_hash"  string => "${rudder_ncf_origin_local}/${rudder_ncf_hash_file}";

      # We would like to use date's "--rfc-3339=second" option here, but it is not available on older OSes (RHEL 3/4, AIX 5...)
      "execRun"                  string => execresult("/bin/date -u \"+%Y-%m-%d %T+00:00\"", "noshell");

  classes:
      # OS classes for compatibility
      "SUSE" expression => "sles|sled|opensuse";
      "SuSE" expression => "sles|sled|opensuse";
      "suse" expression => "sles|sled|opensuse";
      "redhat" expression => "amzn|amazon_linux";
      # sles 12 and after already have this
      "sles_11" expression => "SLES_11";
      "sles_11_1" expression => "SLES_11_1";
      "sles_11_2" expression => "SLES_11_2";
      "sles_11_3" expression => "SLES_11_3";
      "sles_11_4" expression => "SLES_11_4";


      # Root Server is the top policy server machine
      "root_server"         expression => strcmp("root","${g.uuid}");

      # We are in the failsafe phase
      "failsafe" expression => "any";
}

############################################

body depth_search recurse(d)
{
        depth => "${d}";
}

#perms validation
body perms u_p(p)
{
        mode  => "${p}";
        rxdirs => "true";
}

#server may be a list
body copy_from cp(from,server)
{
        servers     => { "${server}" };
        source      => "${from}";
        compare     => "digest";
        portnumber => "${system_common.community_port}";

}

body action immediate
{
        ifelapsed => "0";
}

body depth_search recurse_ignore(d,list)
{
        depth => "${d}";
        exclude_dirs => { @{list} };
}

body delete tidy
{
        dirlinks => "delete";
        rmdirs   => "true";
}

body file_select exclude(name)
{
        leaf_name  => { "${name}"};
        file_result => "!leaf_name";
}

# Define a class no matter what the outcome of the promise is
body classes always(x)
{
  promise_repaired => { "${x}" };
  promise_kept => { "${x}" };
  repair_failed => { "${x}" };
  repair_denied => { "${x}" };
  repair_timeout => { "${x}" };
}
