# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: 2016 Normation SAS

bundle agent check_cron_configuration_&RudderUniqueID&
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
        classes       => classes_generic("cron_file_${cron_index}_&RudderUniqueID&");

      "/etc/cron.${cron_frequency[${cron_index}]}/${cron_name[${cron_index}]}"
        create        => "true",
        edit_defaults => empty_backup,
        perms         => mog("755", "root", "0"),
        edit_line     => insert_lines("${cron_command[${cron_index}]}"),
        ifvarclass    => "!${cron_index}_manual",
        classes       => classes_generic("cron_file_${cron_index}_&RudderUniqueID&");

  methods:
    pass3::
    # Reports about the creation of the cron entries

      "any" usebundle => rudder_common_reports_generic_index("cronConfiguration", "cron_file_${cron_index}_&RudderUniqueID&", "${cron_uuid[${cron_index}]}", "Cron entry", "${cron_name[${cron_index}]}", "The cron file ${cron_name[${cron_index}]} ", "${cron_index}");
}
