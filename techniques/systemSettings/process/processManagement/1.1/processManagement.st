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

  methods:

      "any" usebundle => check_process("${file[${procList}][0]}",
      "${file[${procList}][1]}",
      "${file[${procList}][2]}",
      "${file[${procList}][3]}",
      "${file[${procList}][4]}",
      "${file[${procList}][5]}");

}

bundle agent check_process(directiveId, name, maxInst, minInst, command, args)
{

  classes:

      "${name}_command_empty" expression => strcmp("command","");
      "${name}_arg_empty" expression => strcmp("args","");

  processes:

      "${name}"
        restart_class => "${name}_restart",
        comment       => "Verifying process presence";

      "${name}"
        process_count => check_process_count("${name}", "${maxInst}","${minInst}"),
        classes       => kept_if_else("${name}_ok", "${name}_anomaly", "${name}_error"),
        comment       => "Verifying process count";

  commands:

      "${command}"
        args => "${args}",
        classes => kept_if_else("${name}_restart_ok", "${name}_restart_ok", "${name}_restart_error"),
        ifvarclass => and( canonify("${name}_restart"), not(canonify("${name}_command_empty")), not(canonify("${name}_arg_empty")) );

      "${command}"
        classes => kept_if_else("${name}_restart_ok", "${name}_restart_ok", "${name}_restart_error"),
        ifvarclass => and( canonify("${name}_restart"), not(canonify("${name}_command_empty")), canonify("${name}_arg_empty") );

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

