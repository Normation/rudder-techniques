#####################################################################################
# Copyright 2014 Normation SAS
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
# This code is originally part of the Evolve_freelib.cf, copyright Evolve Thinking ( www.evolvethinking.com )
# Original source can be found here https://github.com/evolvethinking/evolve_cfengine_freelib

bundle agent prevent_tcdb_deadlock
{
  meta:
      "purpose" string => "Workaround CFEngine tcdb corruption and deadlock issues";
      "readme" string => "See bug https://cfengine.com/dev/issues/3430";


  vars:
    redhat::
      "lsof" string => "/usr/sbin/lsof";

    !redhat::
      "lsof" string => "/usr/bin/lsof";

    any::
      "cf_lock_tcdb"
        comment => "Location of lock database",
        string => "${sys.workdir}/state/cf_lock.tcdb";

      "cf_lock_tcdb_lock"
        comment => "Location of lock database",
        string => "${cf_lock_tcdb}.lock";

      "lsof_pids_string"
        comment => "Count number of openings to cf_lock.tcdb",
        string => execresult( "${lsof} -t ${cf_lock_tcdb_lock}", "noshell" );

      "lsof_pids"
        comment => "Convert string to list",
        slist => splitstring( "${lsof_pids_string}", "\s+", "10" );

      "no_of_pids"
        comment => "Convert string returned from execresult to int",
        int => length( "lsof_pids" );

  classes:
      "kill_pids"
        expression => isgreaterthan( "${no_of_pids}", "1" );

  files:
    efl_bug3430_processes_kill_cf_agent_repaired::
      "${cf_lock_tcdb}" -> { "CFEngine bug 3430" }
        comment => "Remove corrupted lock file",
        handle => "efl_bug3430_files_delete_cf_lock_tcdb",
        classes => rudder_common_classes( "efl_bug3430_files_delete_cf_lock_tcdb" ),
        delete => tidy;

  processes:
    kill_pids::
      "cf-agent" -> { "CFEngine bug 3430" }
        comment => "Kill pids",
        handle => "efl_bug3430_processes_kill_cf_agent",
        signals => { "term", "kill" },
        classes => rudder_common_classes( "efl_bug3430_processes_kill_cf_agent" ),
        process_select => by_pid( "${lsof_pids}" );

  reports:
    efl_bug3430_processes_kill_cf_agent_repaired::
      "@@Common@@log_repaired@@&TRACKINGKEY&@@Update@@None@@${g.execRun}##${g.uuid}@#Multiple components were locking the tcdb database, resulting in a deadlock. They were successfully killed";

    efl_bug3430_processes_kill_cf_agent_error::
      "@@Common@@result_error@@&TRACKINGKEY&@@Update@@None@@${g.execRun}##${g.uuid}@#Multiple components were locking the tcdb database, resulting in a deadlock. However, they could not be killed";

    efl_bug3430_files_delete_cf_lock_tcdb_repaired::
      "@@Common@@log_repaired@@&TRACKINGKEY&@@Update@@None@@${g.execRun}##${g.uuid}@#Multiple components were locking the tcdb database. Lock was removed successfully";

    efl_bug3430_files_delete_cf_lock_tcdb_error::
      "@@Common@@result_error@@&TRACKINGKEY&@@Update@@None@@${g.execRun}##${g.uuid}@#Multiple components were locking the tcdb database. Lock could not be removed";
}
