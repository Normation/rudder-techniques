#####################################################################################
# Copyright 2011 Normation SAS
#####################################################################################
#
# Author : Matthieu CERDA
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

bundle agent check_cron_configuration
{

  vars:

    &CRON_NAME:{cron_name |"cron_name[&i&]" string => "&cron_name&";
}&

    &CRON_COMMAND:{cron_command |"cron_command[&i&]" string => "&cron_command&";
}&

    &CRON_USER:{cron_user |"cron_user[&i&]" string => "&cron_user&";
}&

    &CRON_FREQUENCY:{cron_frequency |"cron_frequency[&i&]" string => "&cron_frequency&";
}&

    &CRON_MANUAL:{cron_manual |"cron_manual[&i&]" string => "&cron_manual&";
}&

    &TRACKINGKEY:{uuid |"cron_uuid[&i&]" string => "&uuid&";
}&

      "cron_index" slist => getindices("cron_name");

      "normalorderingtwist" string => "done";

    redhat::
      "cron_bin"        string => "crond$";
      "cron_restartcmd" string => "/etc/init.d/crond restart";

    ubuntu::
      "cron_bin"        string => "cron$";
      "cron_restartcmd" string => "/etc/init.d/cron restart";

    !(redhat|ubuntu)::
      "cron_bin"        string => "/usr/sbin/cron$";
      "cron_restartcmd" string => "/etc/init.d/cron restart";

  classes:

      "crontab_absent" not => fileexists("/etc/crontab");

      "normalorderingtwist" expression => strcmp("${normalorderingtwist}", "done");

    normalorderingtwist::

      "${cron_index}_manual" expression => strcmp("${cron_frequency[${cron_index}]}", "d");

      "showtime" expression => strcmp("true", "true");

  files:

    showtime::

      "/etc/cron.d/${cron_name[${cron_index}]}"
        create => "true",
        edit_defaults => empty_backup,
        perms  => mog("644", "root", "root"),
        edit_line => insert_lines("${cron_manual[${cron_index}]} ${cron_user[${cron_index}]} ${cron_command[${cron_index}]}"),
        ifvarclass => "${cron_index}_manual",
        classes => kept_if_else("cron_file_${cron_index}_kept", "cron_file_${cron_index}_edited", "cron_file_${cron_index}_failed");

      "/etc/cron.${cron_frequency[${cron_index}]}/${cron_name[${cron_index}]}"
        create => "true",
        edit_defaults => empty_backup,
        perms  => mog("755", "root", "root"),
        edit_line => insert_lines("${cron_command[${cron_index}]}"),
        ifvarclass => "!${cron_index}_manual",
        classes => kept_if_else("cron_file_${cron_index}_kept", "cron_file_${cron_index}_edited", "cron_file_${cron_index}_failed");

  processes:

      "${cron_bin}"
        restart_class => "cron_restart";

  commands:

    cron_restart::
      "${cron_restartcmd}"
        args => "restart",
        classes => kept_if_else("cron_kept", "cron_restarted", "could_not_restart_cron"),
        comment => "Restart the cron daemon";

  reports:

    linux::

    # Reports about the creation of the cron entries

      "@@cronConfiguration@@result_success@@${cron_uuid[${cron_index}]}@@Cron entry@@${cron_name[${cron_index}]}@@${g.execRun}##${g.uuid}@#The cron file ${cron_name[${cron_index}]} was present. Skipping..."
        ifvarclass => "cron_file_${cron_index}_kept.!cron_file_${cron_index}_edited";

      "@@cronConfiguration@@result_repaired@@${cron_uuid[${cron_index}]}@@Cron entry@@${cron_name[${cron_index}]}@@${g.execRun}##${g.uuid}@#The cron file ${cron_name[${cron_index}]} was created successfully"
        ifvarclass => "cron_file_${cron_index}_edited";

      "@@cronConfiguration@@result_error@@${cron_uuid[${cron_index}]}@@Cron entry@@${cron_name[${cron_index}]}@@${g.execRun}##${g.uuid}@#Could not create the cron file ${cron_name[${cron_index}]}"
        ifvarclass => "cron_file_${cron_index}_failed";

    # Reports about the cron process presence

    !cron_restart::
      "@@cronConfiguration@@result_success@@${cron_uuid[${cron_index}]}@@Cron process@@None@@${g.execRun}##${g.uuid}@#The cron process is running. Skipping...";

    cron_restarted::
      "@@cronConfiguration@@result_repaired@@${cron_uuid[${cron_index}]}@@Cron process@@None@@${g.execRun}##${g.uuid}@#The cron process has been restarted";

    could_not_restart_cron::
      "@@cronConfiguration@@result_success@@${cron_uuid[${cron_index}]}@@Cron process@@None@@${g.execRun}##${g.uuid}@#Could not restart the cron process!";

    !windows.cron_absent::

      "@@cronConfiguration@@log_warn@@${cron_uuid[${cron_index}]}@@cronConfiguration@@None@@${g.execRun}##${g.uuid}@#The crontab is absent";

    windows::

      "@@cronConfiguration@@result_error@@${cron_uuid[${cron_index}]}@@cronConfiguration@@None@@${g.execRun}##${g.uuid}@#This is a Windows machine. This Technique currently incompatible with it";

}
