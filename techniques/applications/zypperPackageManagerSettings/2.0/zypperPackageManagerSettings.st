#####################################################################################
# Copyright 2013 Normation SAS
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

######################################################
# Configures the Zypper Package Manager              #
######################################################

bundle agent check_zypper_settings {

  vars:

    "zypper_uuid"                        string => "&TRACKINGKEY&";

    "zmdconf[main][solver.onlyRequires]" string => "&ZYPPER_INSTALLRECOMMENDS&";

    "zypper_sections"                    slist  => getindices("zmdconf");

  files:

    SuSE::
      "/etc/zypp/zypp.conf"
        create        => "true",
        perms         => mog("644", "root", "root"),
        edit_defaults => noempty_backup,
        edit_line     => set_advanced_zypper_config_values("check_zypper_settings.zmdconf", "${zypper_sections}"),
        classes       => kept_if_else("zypper_conf_kept", "zypper_conf_validated", "zypper_conf_failed");

  reports:

    # ZYPPER settings edition

    zypper_conf_kept.!zypper_conf_validated.!zypper_conf_failed::
      "@@zypperPackageManagerSettings@@result_success@@${zypper_uuid}@@General settings@@None@@${g.execRun}##${g.uuid}@#Zypper settings were all already correct";

    zypper_conf_validated.!zypper_conf_failed::
      "@@zypperPackageManagerSettings@@result_repaired@@${zypper_uuid}@@General settings@@None@@${g.execRun}##${g.uuid}@#Some Zypper settings were reset";

    zypper_conf_failed::
      "@@zypperPackageManagerSettings@@result_error@@${zypper_uuid}@@General settings@@None@@${g.execRun}##${g.uuid}@#Zypper repositories could not be edited";

    # Ignore non-SuSE OSes

    !SuSE::
      "@@zypperPackageManagerSettings@@result_error@@${zypper_uuid}@@General Settings@@None@@${g.execRun}##${g.uuid}@#Zypper cannot be configured on non SuSE OSes";

}

bundle edit_line set_advanced_zypper_config_values(tab, sectionName)
{
 # Sets the RHS of configuration items in the file of the form
 # LHS=RHS
 # If the line is commented out with #, it gets uncommented first.
 # Adds a new line if none exists.
 # The argument is an associative array containing tab[SectionName][LHS]="RHS"
 # don't change value when the RHS is dontchange

 # Based on set_variable_values from cfengine_stdlib.cf, modified to
 # use section to define were to write, and to handle commented-out lines.

 # CAUTION : for it to work nicely, you should use Cfengine with the commit n°3229
 # otherwise you may risk a segfault

  vars:
      "index"            slist  => getindices("${tab}[${sectionName}]");

  # Be careful if the index string contains funny chars
      "cindex[${index}]" string => canonify("${index}");

  classes:
      "edit_${cindex[${index}]}" not => strcmp("${${tab}[${sectionName}][${index}]}","dontchange");

  field_edits:

  # If the line is there, but commented out, first uncomment it
      "#+${index}=.*"
        select_region => INI_section("${sectionName}"),
        edit_field    => col("=","1","${index}","set"),
        ifvarclass    => "edit_${cindex[${index}]}";

  # match a line starting like the key something
      "${index}=.*"
        edit_field    => col("=","2","${${tab}[${sectionName}][${index}]}","set"),
        select_region => INI_section("${sectionName}"),
        classes       => if_ok("not_${cindex[${index}]}"),
        ifvarclass    => "edit_${cindex[${index}]}";

  insert_lines:
      "${index}=${${tab}[${sectionName}][${index}]}",
        select_region => INI_section("${sectionName}"),
        ifvarclass    => "!not_${cindex[${index}]}.edit_${cindex[${index}]}";

}

body file_select not_rudderzypperrepo
{
        leaf_name   => { "^[^rudder-defined.*?\.repo].*" };
        file_result => "leaf_name";
}
