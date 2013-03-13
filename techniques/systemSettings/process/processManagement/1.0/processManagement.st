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

# Enforce the defined process parameters

bundle agent process_management
{
  vars:

      "dim_array" int =>  readstringarray("file","${sys.workdir}/inputs/processManagement/proclist","#[^\n]*",",",15,4000);

      "procList" slist => getindices("file");

      "blacklist" slist => {&PROCESS_BLACKLIST: { "&it&"};separator=","&};

#processes:

#	"${blacklist}"
#			comment => "Kill the process",
#			signals => { "stop", "term", "kill" },
#			classes => kept_if_else("${blacklist}_ok", "${blacklist}_killed", "${blacklist}_kill_failed");

  methods:

      "any" usebundle => check_process("${file[${procList}][0]}",
      "${file[${procList}][1]}",
      "${file[${procList}][2]}",
      "${file[${procList}][3]}",
      "${file[${procList}][4]}",
      "${file[${procList}][5]}");

#reports:
#		"@@ProcessManagement@@result_error@@${directiveId}@@Blacklisted process@@${blacklist}@@${g.execRun}##${g.uuid}@#${blacklist}: the process could not be killed"
#			ifvarclass => canonify("${blacklist}_kill_failed");

#		"@@ProcessManagement@@result_repaired@@${directiveId}@@Blacklisted process@@${blacklist}@@${g.execRun}##${g.uuid}@#${blacklist}: the process has been killed (as requested)"
#			ifvarclass => canonify("${blacklist}_killed");

#		"@@ProcessManagement@@result_success@@${directiveId}@@Blacklisted process@@${blacklist}@@${g.execRun}##${g.uuid}@#${blacklist}: the process is not running (as requested)"
#			ifvarclass => canonify("${blacklist}_ok");

}

bundle agent check_process(directiveId, name, maxInst, minInst, command, args)
{

  classes:

      "${name}_command_empty" expression => strcmp("command","");

  processes:

      "${name}"
        comment => "Enforcing process parameters",
        process_count => check_process_count("${name}", "${maxInst}","${minInst}"),
        restart_class => "${name}_restart",
        classes => kept_if_else("${name}_ok", "${name}_anomaly", "${name}_error");

  commands:

      "${command}"
        args => "${args}",
        classes => kept_if_else("${name}_restart_ok", "${name}_restart_ok", "${name}_restart_error"),
        ifvarclass => and( canonify("${name}_restart"), not(canonify("${name}_command_empty")) );

      "/etc/init.d/${name}"
        args => "restart",
        classes => kept_if_else("${name}_restart_ok", "${name}_restart_ok", "${name}_restart_error"),
        ifvarclass => and( canonify("${name}_restart"), canonify("${name}_command_empty") );

  reports:

    (linux|!linux)::

      "@@ProcessManagement@@result_error@@${directiveId}@@Process@@${name}@@${g.execRun}##${g.uuid}@#${name}: the process count could't be checked"
        ifvarclass => canonify("${name}_error");

      "@@ProcessManagement@@log_info@@${directiveId}@@Process@@${name}@@${g.execRun}##${g.uuid}@#${name}: the process instance count is out of the permitted range"
        ifvarclass => canonify("${name}_anomaly");

      "@@ProcessManagement@@log_info@@${directiveId}@@Process@@${name}@@${g.execRun}##${g.uuid}@#${name}: the process will be restarted"
        ifvarclass => canonify("${name}_restart");

      "@@ProcessManagement@@result_success@@${directiveId}@@Process@@${name}@@${g.execRun}##${g.uuid}@#${name}: the process was in range (${minInst}-${maxInst})"
        ifvarclass => canonify("${name}_ok");

      "@@ProcessManagement@@result_repaired@@${directiveId}@@Process@@${name}@@${g.execRun}##${g.uuid}@#${name}: the process has been restarted"
        ifvarclass => canonify("${name}_restart_ok");

      "@@ProcessManagement@@result_error@@${directiveId}@@Process@@${name}@@${g.execRun}##${g.uuid}@#${name}: the process could not be restarted"
        ifvarclass => canonify("${name}_restart_error");


}

body process_count check_process_count(name, max, min)
{
        match_range => irange("${min}","${max}");
        out_of_range_define => { "${name}_anomaly" };
}

