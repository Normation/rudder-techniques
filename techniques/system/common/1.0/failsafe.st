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
        bundlesequence     => { "check_lock_db_problem", "init_files", "update" };

        inputs             => { "common/1.0/update.cf" };
        output_prefix      => "rudder";
}

body agent control {
        skipidentify => "&SKIPIDENTIFY&";
}

bundle common g
{
  vars:
    android::
      "rudder_base"              string => "/data/rudder";
      "rudder_var"               string => "/data/rudder";

    !windows.!android::
      "rudder_base"              string => "/opt/rudder";

    solaris::
      "rudder_var"               string => "/opt/rudder/var";

    !windows.!android.!solaris::
      "rudder_var"               string => "/var/rudder";

    !windows::
      "rudder_bin"               string => "${rudder_base}/bin";
      "rudder_sbin"              string => "${rudder_base}/sbin";
      "rudder_base_sbin"         string => "${rudder_base}/sbin"; #folder where tools are installed
      "rudder_tools"             string => "${rudder_var}/tools";
      "rudder_ncf"               string => "${rudder_var}/ncf";

&if(NOVA)&
    windows::
      "rudder_base"              string => "${sys.winprogdir}\Rudder";
      "rudder_var"               string => "${sys.winprogdir}\Rudder\var";
      "rudder_bin"               string => "${rudder_base}\bin";
      "rudder_sbin"              string => "${rudder_base}\sbin";
      "rudder_tools"             string => "${rudder_sbin}";
      "rudder_ncf"               string => "${rudder_var}\ncf";
&endif&

    any::
      "uuid"                     string => "&UUID&";
      "excludedreps"             slist  => { "\.X11", ".*kde.*", "\.svn", "perl" };
      "rudder_tools_origin"      string => "/var/rudder/tools";
      "rudder_ncf_origin_common" string => "/usr/share/ncf/tree";
      "rudder_ncf_origin_local"  string => "/var/rudder/configuration-repository/ncf";

    # The time at which the execution started
    (linux|cygwin).!(centos_3|redhat_3|centos_4|redhat_4)::
      "execRun"                  string => execresult("/bin/date --rfc-3339=second", "noshell");
    (linux|cygwin).(centos_3|redhat_3|centos_4|redhat_4)::
      # We would like to use date's "--rfc-3339=second" option here, but it is not available on older OSes (RHEL 3/4, AIX 5...)
      "execRun"                  string => execresult("/bin/date -u \"+%Y-%m-%d %T+00:00\"", "noshell");
&if(NOVA)&
    windows.!cygwin::
      "execRun"                  string => execresult("\"${g.rudder_sbin}\getDate.bat\"", "noshell");
&endif&
    android::
      "execRun"                  string => execresult("/system/xbin/date \"+%Y-%m-%d %T+02:00\"", "noshell");
    aix::
      # AIX's date command doesn't have a "%z" option, so we fake it by using UTC
      "execRun"                  string => execresult("/bin/date -u \"+%Y-%m-%d %T+00:00\"", "noshell");
    !linux.!cygwin.!windows.!android.!aix::
      "execRun"                  string => execresult("/bin/date \"+%Y-%m-%d %T%:z\"", "noshell");

# definition of the node roles
  &NODEROLE&
}

bundle common rudder_roles
{
  classes:
      # Abort if no uuid is defined
      "should_not_continue" not        => fileexists("${g.uuid_file}");
      # Policy Server is a machine which delivers promises
      "policy_server"       expression => strcmp("root","${g.uuid}");
      # Root Server is the top policy server machine
      "root_server"         expression => strcmp("root","${g.uuid}");

      # We are in the failsafe phase
      "failsafe" expression => "any";
}

############################################

#generate a key if not present
bundle agent init_files
{
  vars:
      "components"            slist  => { "cf-agent", "cf-serverd", "cf-execd", "cf-monitord", "cf-promises", "cf-runagent", "cf-key", "cf-hub" };

    nova_edition::
      "cfengine_install_path" string => "/usr/local";
    community_edition::
      "cfengine_install_path" string => "${g.rudder_base}";

  classes:
      "missing_key" not => fileexists("${sys.workdir}/ppkeys/localhost.priv");

  files:
    cfengine_community.!windows::
      "${sys.workdir}/bin/${components}"
        perms     => u_p("700"),
        copy_from => cp("${cfengine_install_path}/bin/${components}","localhost"),
        action    => immediate;


  commands:
    cygwin.missing_key::
      "${sys.workdir}/bin/cf-key.exe";

&if(NOVA)&
    windows.missing_key.!cygwin::
      "\"${sys.workdir}\bin\cf-key\"";
&endif&

    !windows.!cygwin.missing_key::
      "${sys.workdir}/bin/cf-key";
}

# This bundle will check the "last successful inputs update", and if it is older
# than 1 hour, remove cf_lock.db (and only this DB), to give CFEngine a chance
# to run properly again.
bundle agent check_lock_db_problem{
  vars:

    cfengine_3_0|cfengine_3_1|cfengine_3_2::
      "cf_lock_filename" string => "cf_lock.db";

    !(cfengine_3_0|cfengine_3_1|cfengine_3_2)::
      "cf_lock_filename" string => "cf_lock.tcdb";

  files:
      # The aim of this promise is to create a class when this file is older
      # than one hour. The class can not be created without touching but in
      # order to not modifing the mtime we use WarnOnly.
      "${sys.workdir}/last_successful_inputs_update"
        file_select => over_an_hour,
        touch       => "true",
        action      => WarnOnly,
        classes     => success("last_successful_inputs_update_too_old", "last_successful_inputs_update_check_error", "last_successful_inputs_update_ok");

      "${sys.workdir}/state/${cf_lock_filename}"
        delete     => tidy,
        ifvarclass => "last_successful_inputs_update_too_old",
        classes    => success("cf_lock_removed", "cf_lock_error_removing", "cf_lock_not_deleted");

  reports:
    cf_lock_removed::
      "@@Common@@log_repaired@@&TRACKINGKEY&@@Update@@None@@${g.execRun}##${g.uuid}@#Promises had not been updated for over an hour, this could indicate a broken lockfile. cf_lock DB file was removed.";

    cf_lock_error_removing::
      "@@Common@@result_error@@&TRACKINGKEY&@@Update@@None@@${g.execRun}##${g.uuid}@#Promises have not been updated for over an hour, this could indicate a broken lockfile, but an error occured when trying to remove it";
}

body file_select over_an_hour()
{
        # Select file which are older than one hour
        # Use of positive mtime instead of negative one
        # In order to avoid corner effects
        mtime       => irange(ago(0,0,0,1,0,0), now);
        file_result => "!mtime";
}

body depth_search recurse(d)
{
        depth => "${d}";
}

#perms validation
body perms u_p(p)
{
        mode  => "${p}";
}

#server may be a list
body copy_from cp(from,server)
{
        servers     => { "${server}" };
        source      => "${from}";
        compare     => "digest";
    community_edition::
        portnumber => "&COMMUNITYPORT&";

}

body copy_from copy_digest(from)
{
        source      => "${from}";
        copy_backup => "false";
        preserve    => "true";
        compare     => "digest";
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

body action WarnOnly
{
        action_policy => "warn";
}

body file_select exclude(name)
{
        leaf_name  => { "$(name)"};
        file_result => "!leaf_name";
}

