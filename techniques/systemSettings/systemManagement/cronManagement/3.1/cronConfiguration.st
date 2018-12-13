#####################################################################################
# Copyright 2016 Normation SAS
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

      "cron_map[hourly]"  string => "0 * * * *";
      "cron_map[daily]"   string => "0 0 * * *";
      "cron_map[weekly]"  string => "0 0 * * 0";
      "cron_map[monthly]" string => "0 0 1 * *";

    pass1::
      # if we have non default value (user or frequency), construct the time + user
      "${cron_index}_cron_parameter" string => "${cron_manual[${cron_index}]} ${cron_user[${cron_index}]}",
        ifvarclass => "${cron_index}_custom_frequency";

      "${cron_index}_cron_parameter" string => "${cron_map[${cron_frequency[${cron_index}]}]} ${cron_user[${cron_index}]}",
        ifvarclass => "!${cron_index}_custom_frequency.${cron_index}_manual";

  classes:

      "crontab_absent" not => fileexists("/etc/crontab");

      # if user is not default, or if frequency is user defined, then we need to fallback to manual
      "${cron_index}_custom_frequency" expression => strcmp("${cron_frequency[${cron_index}]}", "d");
      "${cron_index}_non_default_user"        not => strcmp("${cron_user[${cron_index}]}", "root");

      "${cron_index}_manual"           expression => "${cron_index}_custom_frequency|${cron_index}_non_default_user";

    any::
      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";

  files:

    pass2::

      "/etc/cron.d/${cron_name[${cron_index}]}"
        create        => "true",
        edit_defaults => empty_backup,
        perms         => mog("644", "root", "0"),
        edit_line     => insert_lines("${${cron_index}_cron_parameter} ${cron_command[${cron_index}]}"),
        ifvarclass    => "${cron_index}_manual",
        classes       => kept_if_else("cron_file_${cron_index}_kept", "cron_file_${cron_index}_edited", "cron_file_${cron_index}_failed");

      "/etc/cron.${cron_frequency[${cron_index}]}/${cron_name[${cron_index}]}"
        create        => "true",
        edit_defaults => empty_backup,
        perms         => mog("755", "root", "0"),
        edit_line     => insert_lines("${cron_command[${cron_index}]}"),
        ifvarclass    => "!${cron_index}_manual",
        classes       => kept_if_else("cron_file_${cron_index}_kept", "cron_file_${cron_index}_edited", "cron_file_${cron_index}_failed");

  methods:

    pass3.cron_restart.!redhat::

      "restart_cron" usebundle => service_restart("cron");

    pass3.cron_restart.redhat::

      "restart_cron" usebundle => service_restart("crond");

    pass3::

    # Reports about the creation of the cron entries

      "any" usebundle => rudder_common_report_index("cronConfiguration", "result_success", "${cron_uuid[${cron_index}]}", "Cron entry", "${cron_name[${cron_index}]}", "The cron file ${cron_name[${cron_index}]} was present. Skipping...", "${cron_index}"),
        ifvarclass => "cron_file_${cron_index}_kept.!cron_file_${cron_index}_edited";

      "any" usebundle => rudder_common_report_index("cronConfiguration", "result_repaired", "${cron_uuid[${cron_index}]}", "Cron entry", "${cron_name[${cron_index}]}", "The cron file ${cron_name[${cron_index}]} was created successfully", "${cron_index}"),
        ifvarclass => "cron_file_${cron_index}_edited";

      "any" usebundle => rudder_common_report_index("cronConfiguration", "result_error", "${cron_uuid[${cron_index}]}", "Cron entry", "${cron_name[${cron_index}]}", "Could not create the cron file ${cron_name[${cron_index}]}", "${cron_index}"),
        ifvarclass => "cron_file_${cron_index}_failed";

    # Reports about the cron process presence

    pass3.!cron_restart::
      "any" usebundle => rudder_common_report_index("cronConfiguration", "result_success", "${cron_uuid[${cron_index}]}", "Cron process", "None", "The cron process is running. Skipping...", "${cron_index}");

    pass3.cron_restart.(service_restart_cron_ok|service_restart_crond_ok)::
      "any" usebundle => rudder_common_report_index("cronConfiguration", "result_repaired", "${cron_uuid[${cron_index}]}", "Cron process", "None", "The cron process has been restarted", "${cron_index}");

    pass3.cron_restart.(service_restart_cron_not_ok|service_restart_crond_not_ok)::
      "any" usebundle => rudder_common_report_index("cronConfiguration", "result_success", "${cron_uuid[${cron_index}]}", "Cron process", "None", "Could not restart the cron process!", "${cron_index}");

    pass3.cron_absent::

      "any" usebundle => rudder_common_report_index("cronConfiguration", "log_warn", "${cron_uuid[${cron_index}]}", "cronConfiguration", "None", "The crontab is absent", "${cron_index}");

  processes:
      "cron"
        process_select => cron_bin,
        restart_class => "cron_restart";

}
