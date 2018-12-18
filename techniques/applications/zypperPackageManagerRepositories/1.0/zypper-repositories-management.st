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
# Configures the Zypper repositories                 #
######################################################

bundle agent zypper_repositories_management
{

  vars:

      &ZYPPER_REPO_NAME:{zypper_name |"zypper_name[&i&]" string => "&zypper_name&";
}&
      &ZYPPER_REPO_URL:{zypper_url |"zypper_url[&i&]" string => "&zypper_url&";
}&
      &ZYPPER_REPO_TYPE:{zypper_type |"zypper_type[&i&]" string => "&zypper_type&";
}&
      &ZYPPER_REPO_ENABLED:{zypper_enabled |"zypper_enabled[&i&]" string => "&zypper_enabled&";
}&
      &ZYPPER_REPO_AUTOREFRESH:{zypper_autorefresh |"zypper_autorefresh[&i&]" string => "&zypper_autorefresh&";
}&

      &TRACKINGKEY:{directiveId |"zypper_uuid[&i&]" string => "&directiveId&";
}&

      # List of all the files to permit deletion of others repos 
      "zypper_files" slist => { &ZYPPER_REPO_NAME: { "rudder-&it&.repo" };separator=", "&};

      "zypper_index" slist => getindices("zypper_name");

      "zypper_reports_value" slist => getvalues("zypper_uuid");

  classes:
      # Disable repositories if the value of the variable start by true
      # Since variable is unique, it can contain only one value, however, it is repeated
      # as many time as there are instance of the directive, rendering the strcmp unusable in this case
      "zypper_disable_other_repositories" expression  => regcmp("true.*", "&ZYPPER_REPO_DISABLE_OTHER_REPOSITORIES&");

  files:

    SuSE::
      "/etc/zypp/repos.d/rudder-${zypper_name[${zypper_index}]}.repo"
        create        => "true",
        perms         => m("644"),
        edit_line     => configure_zypper_repos("${zypper_name[${zypper_index}]}", "${zypper_url[${zypper_index}]}", "${zypper_enabled[${zypper_index}]}", "${zypper_type[${zypper_index}]}", "${zypper_autorefresh[${zypper_index}]}", "${this.promise_dirname}/zypper-repo.tml"),
        edit_defaults => empty_backup,
        classes       => rudder_common_classes("zypper_repo_${zypper_index}");

    SuSE.zypper_disable_other_repositories::

      "/etc/zypp/repos.d/"
        delete       => tidy,
        file_select  => ex_list("@{zypper_files}"),
        depth_search => recurse("inf"),
        classes      => rudder_common_classes("zypper_other_repos_disabled"),
        comment      => "Delete the unwanted repos as requested";

  methods:
    SuSE::
      "repos_${zypper_index}" usebundle => rudder_common_reports_generic_index("Zypper Repositories Management", "zypper_repo_${zypper_index}", "${zypper_uuid[${zypper_index}]}", "Repositories", "${zypper_name[${zypper_index}]}", "Repository ${zypper_name[${zypper_index}]}", "${zypper_index}");

      # Clear package caches
      "force_package_list_update" usebundle => file_remove("/var/rudder/cfengine-community/state/software_update_timestamp_zypper"),
        ifvarclass => "zypper_repo_${zypper_index}_repaired";
      "force_available_package_updates_list_update" usebundle => file_remove("/var/rudder/cfengine-community/state/software_available_updates.csv"),
        ifvarclass => "zypper_repo_${zypper_index}_repaired";

    !SuSE::
      "repos_${zypper_index}" usebundle => rudder_common_report_index("Zypper Repositories Management", "result_na", "${zypper_uuid[${zypper_index}]}", "Repositories", "${zypper_name[${zypper_index}]}", "Repository ${zypper_name[${zypper_index}]} can only be added on SUSE/SLES systems", "${zypper_index}");

    # we must report on the deletion of other reports for all instances of the directives
    SuSE.zypper_disable_other_repositories::
      "deletion_${zypper_reports_value}" usebundle => rudder_common_reports_generic_index("Zypper Repositories Management", "zypper_other_repos_disabled", "${zypper_reports_value}", "Purge other repositories", "None", "Deletion of others repositories", "${zypper_index}");

    # For deletion of others repos, if there is effectively no others files in the folders, then
    # CFEngine will not define any classes at all: since there is nothing to promise on, there
    # is no outcome.
    # So, if disable_other_repositories is defined, but no any zypper_other_repos_disabled classes,
    # we must consider the promise to be kept
      "deletion_${zypper_reports_value}" 
        usebundle  => rudder_common_report("Zypper Repositories Management", "result_success", "${zypper_reports_value}", "Purge other repositories", "None", "Every repository other than the defined ones were already disable"),
        ifvarclass => "!zypper_other_repos_disabled_kept.!zypper_other_repos_disabled_repaired.!zypper_other_repos_disabled_error";


    SuSE.!zypper_disable_other_repositories::
      "deletion_${zypper_reports_value}" usebundle => rudder_common_report("Zypper Repositories Management", "result_na", "${zypper_reports_value}", "Purge other repositories", "None", "The repository deactivation has not been requested. Skipping...");

    !SuSE::
      "deletion_${zypper_reports_value}" usebundle => rudder_common_report("Zypper Repositories Management", "result_na", "${zypper_reports_value}", "Purge other repositories", "None", "Deletion of others repositories is available only on SUSE/SLES systems");
}

bundle edit_line configure_zypper_repos(zypper_name, zypper_url, zypper_enabled, zypper_type, zypper_autorefresh, template)
{

  insert_lines:

      "${template}"
        insert_type => "file",
        expand_scalars => "true";
}
