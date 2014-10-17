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

######################################################
# Configures the Zypper Package Manager              #
######################################################

bundle agent check_zypper_settings
{

  vars:

    &ZYPPER_NAME:{zypper_name |"zypper_name[&i&]" string => "&zypper_name&";
}&
    &ZYPPER_URL:{zypper_url |"zypper_url[&i&]" string => "&zypper_url&";
}&
    &ZYPPER_TYPE:{zypper_type |"zypper_type[&i&]" string => "&zypper_type&";
}&
    &ZYPPER_ENABLED:{zypper_enabled |"zypper_enabled[&i&]" string => "&zypper_enabled&";
}&
        &TRACKINGKEY:{policyInstanceId |"zypper_uuid[&i&]" string => "&policyInstanceId&";
}&

                # List of all the files to permit on the vhost directory
      "zypper_files" slist => { &ZYPPER_NAME: { "rudder-&it&.repo" };separator=", "&};

      "zypper_index" slist => getindices("zypper_name");

      "zmdconf[main][solver.onlyRequires]" string => "&ZYPPER_INSTALLRECOMMENDS&";

      "zypper_sections" slist => getindices("zmdconf");

  classes:

    # Repositories edition ?
      "zypper_repositories_edit" expression => strcmp("&ZYPPER_ADDREPOSITORIES&","true");

    # Disable repositories ?
      "zypper_disablerepositories" not => strcmp("&ZYPPER_DISABLEREPOSITORIES&","false");

  files:

    SuSE::
      "/etc/zypp/zypp.conf"
        create => "true",
        perms => mog("644", "root", "root"),
        edit_defaults => noempty_backup,
        edit_line => set_advanced_zypper_config_values("check_zypper_settings.zmdconf", "${zypper_sections}"),
        classes => kept_if_else("zypper_conf_kept", "zypper_conf_validated", "zypper_conf_failed");

    SuSE.zypper_repositories_edit::

                        #"/etc/zypp/repos.d/rudder-defined.repo"
                        #        create => "true",
                        #        perms => m("644"),
                        #        edit_line => set_zypper_repos("check_zypper_settings.zypper_name", "check_zypper_settings.zypper_url", "check_zypper_settings.zypper_enabled", "check_zypper_settings.zypper_type"),
                        #        edit_defaults => empty_backup,
                        #        classes =>  kept_if_else("zypper_tier1_kept", "zypper_tier1_validated", "zypper_tier1_failed");

      "/etc/zypp/repos.d/rudder-${zypper_name[${zypper_index}]}.repo"
        create => "true",
        perms => m("644"),
        edit_line => set_zypper_repos("${zypper_name[${zypper_index}]}", "${zypper_url[${zypper_index}]}", "${zypper_enabled[${zypper_index}]}", "${zypper_type[${zypper_index}]}", "${g.rudder_dependencies}/zypper-repo.tpl"),
        edit_defaults => empty_backup,
        classes => kept_if_else("zypper_${zypper_index}_kept", "zypper_${zypper_index}_validated", "zypper_${zypper_index}_failed");

    SuSE.zypper_disablerepositories::

      "/etc/zypp/repos.d/.*"
        delete => tidy,
        file_select => ex_list("@{zypper_files}"),
        depth_search => recurse("inf"),
        classes => kept_if_else("repos_disabled_kept", "repos_disabled_ok", "repos_disabled_fail"),
        comment => "Delete the unwanted repos as requested";

  reports:

    # ZYPPER settings edition

    zypper_conf_kept.!zypper_conf_validated.!zypper_conf_failed::
      "@@zypperPackageManagerSettings@@result_success@@${zypper_uuid[${zypper_index}]}@@General settings@@None@@${g.execRun}##${g.uuid}@#Zypper settings were all already correct";

    zypper_conf_validated::
      "@@zypperPackageManagerSettings@@result_repaired@@${zypper_uuid[${zypper_index}]}@@General settings@@None@@${g.execRun}##${g.uuid}@#Some Zypper settings were reset";

    zypper_conf_failed::
      "@@zypperPackageManagerSettings@@result_error@@${zypper_uuid[${zypper_index}]}@@General settings@@None@@${g.execRun}##${g.uuid}@#Zypper repositories could not be edited";

    # Zypper repositories desactivation

    zypper_disablerepositories.!repos_disabled_ok.!repos_disabled_fail::
      "@@zypperPackageManagerSettings@@result_success@@${zypper_uuid[${zypper_index}]}@@Repository deactivation@@None@@${g.execRun}##${g.uuid}@#Every repository other than the defined ones were already disabled";

    zypper_disablerepositories.repos_disabled_ok::
      "@@zypperPackageManagerSettings@@result_repaired@@${zypper_uuid[${zypper_index}]}@@Repository deactivation@@None@@${g.execRun}##${g.uuid}@#Every repository other than the defined ones were disabled";

    zypper_disablerepositories.repos_disabled_fail::
      "@@zypperPackageManagerSettings@@result_error@@${zypper_uuid[${zypper_index}]}@@Repository deactivation@@None@@${g.execRun}##${g.uuid}@#Could not disable the other repositories!";

    !zypper_disablerepositories::
      "@@zypperPackageManagerSettings@@result_success@@${zypper_uuid[${zypper_index}]}@@Repository deactivation@@None@@${g.execRun}##${g.uuid}@#The repository desactivation has not been requested. Skipping...";

    # Ignore non-SuSE OSes

    !SuSE::
      "@@zypperPackageManagerSettings@@result_error@@${zypper_uuid[${zypper_index}]}@@zypperPackageManagerSettings@@None@@${g.execRun}##${g.uuid}@#ZYPPER cannot be configured on non SuSE OSes";

    !zypper_repositories_edit::

      "@@zypperPackageManagerSettings@@result_success@@${zypper_uuid[${zypper_index}]}@@Repository@@${zypper_name[${zypper_index}]}@@${g.execRun}##${g.uuid}@#The source ${zypper_name[${zypper_index}]} will NOT be added as the repository addition parameter is off in the Policy Instance. Skipping...";

    SuSE::

                # Repositories

      "@@zypperPackageManagerSettings@@result_success@@${zypper_uuid[${zypper_index}]}@@Repository@@${zypper_name[${zypper_index}]}@@${g.execRun}##${g.uuid}@#The Zypper source ${zypper_name[${zypper_index}]} was already here. Skipping..."
        ifvarclass => "zypper_${zypper_index}_kept.!zypper_${zypper_index}_validated";

      "@@zypperPackageManagerSettings@@result_repaired@@${zypper_uuid[${zypper_index}]}@@Repository@@${zypper_name[${zypper_index}]}@@${g.execRun}##${g.uuid}@#The Zypper source ${zypper_name[${zypper_index}]} has been successfully added"
        ifvarclass => "zypper_${zypper_index}_validated";

      "@@zypperPackageManagerSettings@@result_error@@${zypper_uuid[${zypper_index}]}@@Repository@@${zypper_name[${zypper_index}]}@@${g.execRun}##${g.uuid}@#The Zypper source ${zypper_name[${zypper_index}]} was NOT added!"
        ifvarclass => "zypper_${zypper_index}_error";


}

bundle edit_line set_zypper_repos(zypper_name, zypper_url, zypper_enabled, zypper_type, template)
{

  insert_lines:

      "${template}"
        insert_type => "file",
        expand_scalars => "true";

}

bundle edit_line set_zypper_repos_BROKEN(zypper_name, zypper_url, zypper_enabled, zypper_type)
{

  vars:

      "zypper_index" slist => getindices("${zypper_name}");

  insert_lines:

        "#############################################################
### This file is protected by your Rudder infrastructure. ###
### Manually editing the file might lead your Rudder      ###
### infrastructure to change back the server's            ###
### configuration and/or to raise a compliance alert.     ###
#############################################################
"
        location => start,
        insert_type => "preserve_block";

      "[${${zypper_name}[${zypper_index}]}]"
        classes => kept_if_else("source_${zypper_index}_kept", "source_${zypper_index}_ok", "source_${zypper_index}_failed");

      "name=${${zypper_name}[${zypper_index}]}"
        select_region => INI_section("${${zypper_name}[${zypper_index}]}"),
        classes => kept_if_else("source_${zypper_index}_kept", "source_${zypper_index}_ok", "source_${zypper_index}_failed");

      "enabled=${${zypper_enabled}[${zypper_index}]}"
        select_region => INI_section("${${zypper_name}[${zypper_index}]}"),
        classes => kept_if_else("source_${zypper_index}_kept", "source_${zypper_index}_ok", "source_${zypper_index}_failed");

      "autorefresh=0"
        select_region => INI_section("${${zypper_name}[${zypper_index}]}"),
        classes => kept_if_else("source_${zypper_index}_kept", "source_${zypper_index}_ok", "source_${zypper_index}_failed");

      "baseurl=${${zypper_url}[${zypper_index}]}"
        select_region => INI_section("${${zypper_name}[${zypper_index}]}"),
        classes => kept_if_else("source_${zypper_index}_kept", "source_${zypper_index}_ok", "source_${zypper_index}_failed");

      "type=${${zypper_type}[${zypper_index}]}"
        select_region => INI_section("${${zypper_name}[${zypper_index}]}"),
        classes => kept_if_else("source_${zypper_index}_kept", "source_${zypper_index}_ok", "source_${zypper_index}_failed");

      "keeppackages=0"
        select_region => INI_section("${${zypper_name}[${zypper_index}]}"),
        classes => kept_if_else("source_${zypper_index}_kept", "source_${zypper_index}_ok", "source_${zypper_index}_failed");

  reports:

  # Repositories
      "@@zypperPackageManagerSettings@@result_success@@${zypper_uuid[${zypper_index}]}@@Repository@@${zypper_url[${zypper_index}]}@@${g.execRun}##${g.uuid}@#The ZYPPER source ${zypper_name[${zypper_index}]} was already here. Skipping..."
        ifvarclass => "source_${zypper_index}_kept.!source_${zypper_index}_ok";

      "@@zypperPackageManagerSettings@@result_repaired@@${zypper_uuid[${zypper_index}]}@@Repository@@${zypper_url[${zypper_index}]}@@${g.execRun}##${g.uuid}@#The ZYPPER source ${zypper_name[${zypper_index}]} has been successfully added"
        ifvarclass => "source_${zypper_index}_ok";

      "@@zypperPackageManagerSettings@@result_error@@${zypper_uuid[${zypper_index}]}@@Repository@@${zypper_url[${zypper_index}]}@@${g.execRun}##${g.uuid}@#The ZYPPER source ${zypper_name[${zypper_index}]} was NOT added!"
        ifvarclass => "source_${zypper_index}_failed";

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
      "index" slist => getindices("${tab}[${sectionName}]");

  # Be careful if the index string contains funny chars
      "cindex[${index}]" string => canonify("${index}");

  classes:
      "edit_${cindex[${index}]}" not => strcmp("${${tab}[${sectionName}][${index}]}","dontchange");

  field_edits:

  # If the line is there, but commented out, first uncomment it
      "#+${index}=.*"
        select_region => INI_section("${sectionName}"),
        edit_field => col("=","1","${index}","set"),
        ifvarclass => "edit_${cindex[${index}]}";

  # match a line starting like the key something
      "${index}=.*"
        edit_field => col("=","2","${${tab}[${sectionName}][${index}]}","set"),
        select_region => INI_section("${sectionName}"),
        classes => if_ok("not_${cindex[${index}]}"),
        ifvarclass => "edit_${cindex[${index}]}";

  insert_lines:
      "${index}=${${tab}[${sectionName}][${index}]}"
        select_region => INI_section("${sectionName}"),
        ifvarclass => "!not_${cindex[${index}]}.edit_${cindex[${index}]}";

}

body file_select not_rudderzypperrepo
{
        leaf_name => { "^[^rudder-defined.*?\.repo].*" };
        file_result => "leaf_name";
}
