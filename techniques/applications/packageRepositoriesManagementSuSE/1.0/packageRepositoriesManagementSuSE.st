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
# Configures the SuSE Package Manager                #
######################################################

bundle agent check_pkg_manager_repositories
{

  vars:

      &TRACKINGKEY:{directiveId |"pkg_mgr_uuid[&i&]" string => "&directiveId&";
}&

      &PKG_MGR_NAME:{pkg_mgr_name |"pkg_mgr_name[&i&]" string => "&pkg_mgr_name&";
}&
      &PKG_MGR_URL:{pkg_mgr_url |"pkg_mgr_url[&i&]" string => "&pkg_mgr_url&";
}&
      &PKG_MGR_TYPE:{pkg_mgr_type |"pkg_mgr_type[&i&]" string => "&pkg_mgr_type&";
}&
      &PKG_MGR_ENABLED:{pkg_mgr_enabled |"pkg_mgr_enabled[&i&]" string => "&pkg_mgr_enabled&";
}&

      # List of all the files containing the repositories configuration for Zypper
      "pkg_mgr_files" slist => { &PKG_MGR_NAME: { "rudder-&it&.repo" };separator=", "&};

      "pkg_mgr_index" slist => getindices("pkg_mgr_name");

  classes:

    # Disable repositories ?
      "pkg_mgr_disablerepositories" expression => strcmp("&PKG_MGR_DISABLEREPOSITORIES&","true");

    # Is the checkzmd script present ?
      "checkzmd_present"            expression => fileexists("${g.rudder_dependencies}/checkzmd.pl");
        
  files:

    SLES_11::

      "/etc/zypp/repos.d/rudder-${pkg_mgr_name[${pkg_mgr_index}]}.repo"
        create         => "true",
        perms          => m("644"),
        edit_line      => set_zypper_repos(
                                          "${pkg_mgr_name[${pkg_mgr_index}]}",
                                          "${pkg_mgr_url[${pkg_mgr_index}]}",
                                          "${pkg_mgr_enabled[${pkg_mgr_index}]}",
                                          "${pkg_mgr_type[${pkg_mgr_index}]}",
                                          "${g.rudder_dependencies}/zypper-repo.tpl"
                                          ),
        edit_defaults => empty_backup,
        classes       => kept_if_else("pkg_mgr_${pkg_mgr_index}_kept", "pkg_mgr_${pkg_mgr_index}_validated", "pkg_mgr_${pkg_mgr_index}_failed");

    SLES_11.pkg_mgr_disablerepositories::

      "/etc/zypp/repos.d/.*"
        delete       => tidy,
        file_select  => ex_list("@{pkg_mgr_files}"),
        depth_search => recurse("inf"),
        classes      => kept_if_else("repos_disabled_kept", "repos_disabled_ok", "repos_disabled_fail"),
        comment      => "Delete the unwanted repos as requested";

  processes:
        
      "/usr/lib/zmd/zmd.exe"
        restart_class => "zmd_restart";

  commands:

    SLES_10.checkzmd_present::
        
      "${g.rudder_dependencies}/checkzmd.pl \"${pkg_mgr_name[${pkg_mgr_index}]}\" \"${pkg_mgr_url[${pkg_mgr_index}]}\" ${pkg_mgr_index}"
        contain => in_shell,
        module  => "true",
        comment => "Analyzing ZMD's output";

    SLES_10::

      "/usr/bin/rug"
        args       => "sa --type=\"${pkg_mgr_type[${pkg_mgr_index}]}\" \"${pkg_mgr_url[${pkg_mgr_index}]}\" \"${pkg_mgr_name[${pkg_mgr_index}]}\"",
        contain    => in_shell,
        ifvarclass => "index_${pkg_mgr_index}_not_matched",
        classes    => kept_if_else("source_${pkg_mgr_index}_kept", "source_${pkg_mgr_index}_added", "source_${pkg_mgr_index}_failed"),
        comment    => "Add the ${pkg_mgr_index} as a new source";
        
      "/usr/bin/rug"
        args       => "subscribe \"${pkg_mgr_name[${pkg_mgr_index}]}\"",
        ifvarclass => "source_${pkg_mgr_index}_added",
        classes    => kept_if_else("source_${pkg_mgr_index}_subkept", "source_${pkg_mgr_index}_subscribed", "source_${pkg_mgr_index}_subfailed"),
        comment    => "Subscribe ${pkg_mgr_index} as a new source";


  reports:

    # Zypper repositories desactivation

    pkg_mgr_disablerepositories.!repos_disabled_ok.!repos_disabled_fail::
      "@@packageRepositoriesManagementRPM@@result_success@@${pkg_mgr_uuid[${pkg_mgr_index}]}@@Repository settings@@None@@${g.execRun}##${g.uuid}@#Every repository other than the defined ones were already disabled";

    pkg_mgr_disablerepositories.repos_disabled_ok::
      "@@packageRepositoriesManagementRPM@@result_repaired@@${pkg_mgr_uuid[${pkg_mgr_index}]}@@Repository settings@@None@@${g.execRun}##${g.uuid}@#Every repository other than the defined ones were disabled";

    pkg_mgr_disablerepositories.repos_disabled_fail::
      "@@packageRepositoriesManagementRPM@@result_error@@${pkg_mgr_uuid[${pkg_mgr_index}]}@@Repository settings@@None@@${g.execRun}##${g.uuid}@#Could not disable the other repositories!";

    !pkg_mgr_disablerepositories::
      "@@packageRepositoriesManagementRPM@@result_success@@${pkg_mgr_uuid[${pkg_mgr_index}]}@@Repository settings@@None@@${g.execRun}##${g.uuid}@#The repository desactivation has not been requested. Skipping...";


    # Ignore non-SuSE OSes

    !SuSE::
      "@@packageRepositoriesManagementRPM@@result_error@@${pkg_mgr_uuid[${pkg_mgr_index}]}@@Repository@@None@@${g.execRun}##${g.uuid}@#SuSE package manager cannot be configured on non SuSE OSes";

    SuSE::
      # Repositories

      "@@packageRepositoriesManagementRPM@@result_success@@${pkg_mgr_uuid[${pkg_mgr_index}]}@@Repository@@${pkg_mgr_name[${pkg_mgr_index}]}@@${g.execRun}##${g.uuid}@#The package manager source ${pkg_mgr_name[${pkg_mgr_index}]} was already here. Skipping..."
        ifvarclass => "SLES_11.(pkg_mgr_${pkg_mgr_index}_kept.!(pkg_mgr_${pkg_mgr_index}_validated|pkg_mgr_${pkg_mgr_index}_failed))|SLES_10.(index_${pkg_mgr_index}_matched.!index_${pkg_mgr_index}_not_matched)";

      "@@packageRepositoriesManagementRPM@@result_repaired@@${pkg_mgr_uuid[${pkg_mgr_index}]}@@Repository@@${pkg_mgr_name[${pkg_mgr_index}]}@@${g.execRun}##${g.uuid}@#The package manager source ${pkg_mgr_name[${pkg_mgr_index}]} has been successfully added"
        ifvarclass => "SLES_11.(pkg_mgr_${pkg_mgr_index}_validated.!pkg_mgr_${pkg_mgr_index}_failed)|SLES_10.((source_${pkg_mgr_index}_added.!source_${pkg_mgr_index}_failed).(source_${pkg_mgr_index}_subscribed.!source_${pkg_mgr_index}_subfailed))";

      "@@packageRepositoriesManagementRPM@@result_error@@${pkg_mgr_uuid[${pkg_mgr_index}]}@@Repository@@${pkg_mgr_name[${pkg_mgr_index}]}@@${g.execRun}##${g.uuid}@#The package manager source ${pkg_mgr_name[${pkg_mgr_index}]} was NOT added!"
        ifvarclass => "SLES_11.pkg_mgr_${pkg_mgr_index}_failed|SLES_10.source_${pkg_mgr_index}_failed";


}

bundle edit_line set_zypper_repos(zypper_name, zypper_url, zypper_enabled, zypper_type, template)
{

  insert_lines:

      "${template}"
        insert_type => "file",
        expand_scalars => "true";

}
