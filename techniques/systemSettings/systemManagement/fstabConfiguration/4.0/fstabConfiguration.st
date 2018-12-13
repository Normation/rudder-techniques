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

##########################################################################
# Fstab configuration PT                                                 #
# ---------------------------------------------------------------------- #
# Objective : Configure /etc/fstab according to the given parameters     #
##########################################################################

bundle agent check_fstab_configuration
{

  vars:

    &FSTAB_ORIGIN:{origin |"fstab[&i&][origin]" string => "&origin&";
}&
    &FSTAB_MOUNT_SELECTOR:{selector |"fstab[&i&][selector]" string => "&selector&";
}&
    &FSTAB_DESTINATION:{destination |"fstab[&i&][destination]" string => "&destination&";
}&
    &FSTAB_FILESYSTEM:{filesystem |"fstab[&i&][filesystem]" string => "&filesystem&";
}&

    &FSTAB_DEFAULTS, FSTAB_ASYNC, FSTAB_ATIME, FSTAB_NOAUTO, FSTAB_DEV, FSTAB_EXEC, FSTAB_SUID, FSTAB_USER, FSTAB_USERS, FSTAB_GROUP, FSTAB_MAND, FSTAB_NETDEV, FSTAB_OWNER, FSTAB_READWRITE, FSTAB_MISCOPTIONS: {defaults, async, atime, noauto, dev, exec, suid, user, users, group, mand, netdev, owner, readwrite, miscoptions | "fstab_raw_options_&i&" slist => { "&defaults&", "&async&", "&atime&", "&noauto&", "&dev&", "&exec&", "&suid&", "&user&", "&users&", "&group&", "&mand&", "&netdev&", "&owner&", "&readwrite&", "&miscoptions&" };
}&

    &FSTAB_DUMP:{dump |"fstab[&i&][dump]" string => "&dump&";
}&
    &FSTAB_FSCKORDER:{fsckorder |"fstab[&i&][fsckorder]" string => "&fsckorder&";
}&
    &FSTAB_ALTERONLY:{alteronly |"fstab_alteronly[&i&]" string => "&alteronly&";
}&
    &TRACKINGKEY:{uuid |"fstab[&i&][uuid]" string => "&uuid&";
}&

    # We create an index of every fstab entry we will add ( this will be 1, 2, 3 ... )
      "fstab_index" slist => getindices("fstab");

    # We create a clean list of options : we list them, remove the blanks and join them as a plain string
      "fstab_filtered_options_${fstab_index}" slist => grep(".+","fstab_raw_options_${fstab_index}");
      "fstab[${fstab_index}][options]" string => join(",", "fstab_filtered_options_${fstab_index}");

    # We prepare an array defining the order of the statements in the files ( required by the edit field as seen below )
      "fields[destination]" string => "2";
      "fields[filesystem]" string => "3";
      "fields[options]" string => "4";
      "fields[dump]" string => "5";
      "fields[fsckorder]" string => "6";

  files:

      "/etc/fstab"
        edit_line => fstab_add_line("check_fstab_configuration.fstab", "check_fstab_configuration.fields", "check_fstab_configuration.fstab_alteronly"),
        create => "true",
        edit_defaults => noempty_backup,
        perms => mog("0644", "root", "0"),
        classes => kept_if_else("fstab_kept", "fstab_edited", "fstab_failed"),
        comment => "Editing the fstab file";

  methods:

    fstab_kept.!fstab_edited::

      "any" usebundle => rudder_common_report_index("fstabConfiguration", "log_info", "${fstab[${fstab_index}][uuid]}", "fstabConfiguration", "None", "The fstab file was in accordance with the required policy", "${fstab_index}");

    fstab_edited::

      "any" usebundle => rudder_common_report_index("fstabConfiguration", "log_info", "${fstab[${fstab_index}][uuid]}", "fstabConfiguration", "None", "The fstab file was edited by at least one instance of this technique", "${fstab_index}");

    fstab_failed::

      "any" usebundle => rudder_common_report_index("fstabConfiguration", "log_warn", "${fstab[${fstab_index}][uuid]}", "fstabConfiguration", "None", "The fstab file could NOT be edited by at least one instance of this technique!", "${fstab_index}");

    any::
      "any" usebundle => rudder_common_report_index("fstabConfiguration", "result_error", "${fstab[${fstab_index}][uuid]}", "fstabConfiguration", "${fstab[${fstab_index}][destination]}", "The entry for ${fstab[${fstab_index}][destination]} is invalid, for it doesn't contain an origin : how can it be updated/inserted/deleted?", "${fstab_index}"),
        ifvarclass => "invalid_${fstab_index}";

      "any" usebundle => rudder_common_report_index("fstabConfiguration", "result_repaired", "${fstab[${fstab_index}][uuid]}", "fstabConfiguration", "${fstab[${fstab_index}][destination]}", "The entry for ${fstab[${fstab_index}][origin]} to ${fstab[${fstab_index}][destination]} has been handled", "${fstab_index}"),
        ifvarclass => "line_${fstab_index}_handled";

      "any" usebundle => rudder_common_report_index("fstabConfiguration", "result_success", "${fstab[${fstab_index}][uuid]}", "fstabConfiguration", "${fstab[${fstab_index}][destination]}", "The entry for ${fstab[${fstab_index}][origin]} to ${fstab[${fstab_index}][destination]} is already in accordance with the policy", "${fstab_index}"),
        ifvarclass => "line_${fstab_index}_kept.!line_${fstab_index}_handled.!empty_origin_${fstab_index}";

      "any" usebundle => rudder_common_report_index("fstabConfiguration", "result_success", "${fstab[${fstab_index}][uuid]}", "fstabConfiguration", "${fstab[${fstab_index}][destination]}", "The entry for ${fstab[${fstab_index}][destination]} contained the proper fields", "${fstab_index}"),
        ifvarclass => "line_${fstab_index}_kept.!line_${fstab_index}_handled.empty_origin_${fstab_index}";

      "any" usebundle => rudder_common_report_index("fstabConfiguration", "result_error", "${fstab[${fstab_index}][uuid]}", "fstabConfiguration", "${fstab[${fstab_index}][destination]}", "The entry for ${fstab[${fstab_index}][origin]} to ${fstab[${fstab_index}][destination]} could not be handled", "${fstab_index}"),
        ifvarclass => "line_${fstab_index}_handle_failed";

      "any" usebundle => rudder_common_report_index("fstabConfiguration", "result_success", "${fstab[${fstab_index}][uuid]}", "fstabConfiguration", "${fstab[${fstab_index}][destination]}", "The entry for ${fstab[${fstab_index}][origin]} to ${fstab[${fstab_index}][destination]} was not present but policy required alteration only. This line will be ignored", "${fstab_index}"),
        ifvarclass => "!addentry_${fstab_index}.!line_${fstab_index}_handled.!line_${fstab_index}_kept.!line_${fstab_index}_handle_failed.use_origin_${fstab_index}";

      "any" usebundle => rudder_common_report_index("fstabConfiguration", "result_success", "${fstab[${fstab_index}][uuid]}", "fstabConfiguration", "${fstab[${fstab_index}][destination]}", "The entry for ${fstab[${fstab_index}][destination]} was not present but policy required alteration only. This line will be ignored", "${fstab_index}"),
        ifvarclass => "!addentry_${fstab_index}.!line_${fstab_index}_handled.!line_${fstab_index}_kept.!line_${fstab_index}_handle_failed.!use_origin_${fstab_index}";
}

bundle edit_line fstab_add_line(data_array, fields, alteronly)
{

  vars:

      "index" slist => getindices("${data_array}");
      "indices_fields" slist => getindices("${fields}");

  classes:

      # export variables to use them for reporting in parent bundle
      # we can do that even with ${index} because this bundle is called only once
      "addentry_${index}" expression => strcmp("${${alteronly}[${index}]}", "false"),
                          scope => "namespace";
      "delentry_${index}" expression => strcmp("${${alteronly}[${index}]}", "delete"),
                          scope => "namespace";
      "empty_origin_${index}" expression => strcmp("${${data_array}[${index}][origin]}", ""),
                          scope => "namespace";
      "use_origin_${index}" expression => strcmp("${${data_array}[${index}][selector]}", "origin"),
                          scope => "namespace";

  # Cannot handle an addition without the origin, nor handle a reference on the origin if there aren't any
      "invalid_${index}" expression => "empty_origin_${index}.(use_origin_${index}|addentry_${index})";

  delete_lines:

      "^${${data_array}[${index}][origin]}[ \t]+.*"
        ifvarclass => "delentry_${index}.use_origin_${index}.!invalid_${index}",
        classes => kept_if_else("line_${index}_kept", "line_${index}_handled", "line_${index}_handle_failed");

      "^[^#]+[ \t]+${${data_array}[${index}][destination]}[ \t]+.*"
        ifvarclass => "delentry_${index}.!use_origin_${index}",
        classes => kept_if_else("line_${index}_kept", "line_${index}_handled", "line_${index}_handle_failed");
  field_edits:

      "^${${data_array}[${index}][origin]}[ \t].*"
        edit_field => fstab_col("[ \t]+","${${fields}[${indices_fields}]}","${${data_array}[${index}][${indices_fields}]}","set"),
        classes => kept_if_else("line_${index}_kept", "line_${index}_handled", "line_${index}_handle_failed"),
        ifvarclass => "use_origin_${index}.!invalid_${index}";

      "^[^#]*[ \t]${${data_array}[${index}][destination]}[ \t].*"
        edit_field => fstab_col("[ \t]+","${${fields}[${indices_fields}]}","${${data_array}[${index}][${indices_fields}]}","set"),
        classes => kept_if_else("line_${index}_kept", "line_${index}_handled", "line_${index}_handle_failed"),
        ifvarclass => "!use_origin_${index}";

  insert_lines:

      "${${data_array}[${index}][origin]} ${${data_array}[${index}][destination]} ${${data_array}[${index}][filesystem]} ${${data_array}[${index}][options]} ${${data_array}[${index}][dump]} ${${data_array}[${index}][fsckorder]}"
        ifvarclass => "addentry_${index}.!line_${index}_handled.!invalid_${index}",
        classes => kept_if_else("line_${index}_kept", "line_${index}_handled", "line_${index}_handle_failed");

}

# Workaround for https://dev.cfengine.com/issues/6467
body edit_field fstab_col(split,col,newval,method)
{
 field_separator    => "${split}";
 select_field       => "${col}";
 value_separator    => ";";
 field_value        => "${newval}";
 field_operation    => "${method}";
 extend_fields      => "true";
 allow_blank_fields => "true";
}

