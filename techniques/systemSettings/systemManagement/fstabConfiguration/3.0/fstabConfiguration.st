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

    !windows::

      "/etc/fstab"
        edit_line => fstab_add_line("check_fstab_configuration.fstab", "check_fstab_configuration.fields", "check_fstab_configuration.fstab_alteronly"),
        create => "true",
        edit_defaults => noempty_backup,
        perms => mog("0644", "root", "root"),
        classes => kept_if_else("fstab_kept", "fstab_edited", "fstab_failed"),
        comment => "Editing the fstab file";

  reports:

    fstab_kept.!fstab_edited::

      "@@fstabConfiguration@@log_info@@${fstab[${fstab_index}][uuid]}@@fstabConfiguration@@None@@${g.execRun}##${g.uuid}@#The fstab file was in accordance with the required policy";

    fstab_edited::

      "@@fstabConfiguration@@log_info@@${fstab[${fstab_index}][uuid]}@@fstabConfiguration@@None@@${g.execRun}##${g.uuid}@#The fstab file was edited by at least one instance of this technique";

    fstab_failed::

      "@@fstabConfiguration@@log_warn@@${fstab[${fstab_index}][uuid]}@@fstabConfiguration@@None@@${g.execRun}##${g.uuid}@#The fstab file could NOT be edited by at least one instance of this technique!";

&if(NOVA)&
    windows::

      "@@fstabConfiguration@@result_error@@${fstab[${fstab_index}][uuid]}@@fstabConfiguration@@None@@${g.execRun}##${g.uuid}@#The fstabConfiguration Technique is not intended to be run on windows. Skipping.";
&endif&

}

bundle edit_line fstab_add_line(data_array, fields, alteronly)
{

  vars:

      "index" slist => getindices("${data_array}");
      "indices_fields" slist => getindices("${fields}");

  classes:

      "addentry_${index}" expression => strcmp("${${alteronly}[${index}]}", "false");
      "delentry_${index}" expression => strcmp("${${alteronly}[${index}]}", "delete");
      "empty_origin_${index}" expression => strcmp("${${data_array}[${index}][origin]}", "");
      "use_origin_${index}" expression => strcmp("${${data_array}[${index}][selector]}", "origin");

  # Cannot handle an addition without the origin, nor handle a reference on the origin if there aren't any
      "invalid_${index}" expression => "empty_origin_${index}.(use_origin_${index}|addentry_${index})";

  field_edits:

      "^${${data_array}[${index}][origin]}[ \t].*"
        edit_field => col("[ \t]+","${${fields}[${indices_fields}]}","${${data_array}[${index}][${indices_fields}]}","set"),
        classes => kept_if_else("line_${index}_kept", "line_${index}_handled", "line_${index}_handle_failed"),
        ifvarclass => "use_origin_${index}.!invalid_${index}";

      "^[^#]*[ \t]${${data_array}[${index}][destination]}[ \t].*"
        edit_field => col("[ \t]+","${${fields}[${indices_fields}]}","${${data_array}[${index}][${indices_fields}]}","set"),
        classes => kept_if_else("line_${index}_kept", "line_${index}_handled", "line_${index}_handle_failed"),
        ifvarclass => "!use_origin_${index}";

  insert_lines:

      "${${data_array}[${index}][origin]} ${${data_array}[${index}][destination]} ${${data_array}[${index}][filesystem]} ${${data_array}[${index}][options]} ${${data_array}[${index}][dump]} ${${data_array}[${index}][fsckorder]}"
        ifvarclass => "addentry_${index}.!line_${index}_handled.!invalid_${index}",
        classes => kept_if_else("line_${index}_kept", "line_${index}_handled", "line_${index}_handle_failed");

  delete_lines:

      "^${${data_array}[${index}][origin]}[ \t]+.*"
        ifvarclass => "delentry_${index}.use_origin_${index}.!invalid_${index}",
        classes => kept_if_else("line_${index}_kept", "line_${index}_handled", "line_${index}_handle_failed");

      "^[^#]+[ \t]+${${data_array}[${index}][destination]}[ \t]+.*"
        ifvarclass => "delentry_${index}.!use_origin_${index}",
        classes => kept_if_else("line_${index}_kept", "line_${index}_handled", "line_${index}_handle_failed");
  reports:

    linux::

      "@@fstabConfiguration@@result_error@@${${data_array}[${index}][uuid]}@@fstabConfiguration@@${${data_array}[${index}][destination]}@@${g.execRun}##${g.uuid}@#The entry for ${${data_array}[${index}][destination]} is invalid, for it doesn't contain an origin : how can it be updated/inserted/deleted?"
        ifvarclass => "invalid_${index}";

      "@@fstabConfiguration@@result_repaired@@${${data_array}[${index}][uuid]}@@fstabConfiguration@@${${data_array}[${index}][destination]}@@${g.execRun}##${g.uuid}@#The entry for ${${data_array}[${index}][origin]} to ${${data_array}[${index}][destination]} has been handled"
        ifvarclass => "line_${index}_handled";

      "@@fstabConfiguration@@result_success@@${${data_array}[${index}][uuid]}@@fstabConfiguration@@${${data_array}[${index}][destination]}@@${g.execRun}##${g.uuid}@#The entry for ${${data_array}[${index}][origin]} to ${${data_array}[${index}][destination]} is already in accordance with the policy"
        ifvarclass => "line_${index}_kept.!line_${index}_handled.!empty_origin_${index}";

      "@@fstabConfiguration@@result_success@@${${data_array}[${index}][uuid]}@@fstabConfiguration@@${${data_array}[${index}][destination]}@@${g.execRun}##${g.uuid}@#The entry for ${${data_array}[${index}][destination]} contained the proper fields"
        ifvarclass => "line_${index}_kept.!line_${index}_handled.empty_origin_${index}";

      "@@fstabConfiguration@@result_error@@${${data_array}[${index}][uuid]}@@fstabConfiguration@@${${data_array}[${index}][destination]}@@${g.execRun}##${g.uuid}@#The entry for ${${data_array}[${index}][origin]} to ${${data_array}[${index}][destination]} could not be handled"
        ifvarclass => "line_${index}_handle_failed";

      "@@fstabConfiguration@@result_success@@${${data_array}[${index}][uuid]}@@fstabConfiguration@@${${data_array}[${index}][destination]}@@${g.execRun}##${g.uuid}@#The entry for ${${data_array}[${index}][origin]} to ${${data_array}[${index}][destination]} was not present but policy required alteration only. This line will be ignored"
        ifvarclass => "!addentry_${index}.!line_${index}_handled.!line_${index}_kept.!line_${index}_handle_failed.use_origin_${index}";

      "@@fstabConfiguration@@result_success@@${${data_array}[${index}][uuid]}@@fstabConfiguration@@${${data_array}[${index}][destination]}@@${g.execRun}##${g.uuid}@#The entry for ${${data_array}[${index}][destination]} was not present but policy required alteration only. This line will be ignored"
        ifvarclass => "!addentry_${index}.!line_${index}_handled.!line_${index}_kept.!line_${index}_handle_failed.!use_origin_${index}";
}
