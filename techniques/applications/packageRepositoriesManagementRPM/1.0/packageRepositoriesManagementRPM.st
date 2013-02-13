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
# Configures the Zypper Package Manager Repositories #
######################################################

bundle agent check_pkg_manager_repositories {

	vars:

		&PKG_MGR_NAME:{pkg_mgr_name |"pkg_mgr_name[&i&]" string => "&pkg_mgr_name&";
}&
		&PKG_MGR_URL:{pkg_mgr_url |"pkg_mgr_url[&i&]" string => "&pkg_mgr_url&";
}&
		&PKG_MGR_TYPE:{pkg_mgr_type |"pkg_mgr_type[&i&]" string => "&pkg_mgr_type&";
}&
		&PKG_MGR_ENABLED:{pkg_mgr_enabled |"pkg_mgr_enabled[&i&]" string => "&pkg_mgr_enabled&";
}&

                # List of all the files to permit on the vhost directory
                "pkg_mgr_files" slist => { &PKG_MGR_NAME: { "rudder-&it&.repo" };separator=", "&};

		"pkg_mgr_index" slist => getindices("pkg_mgr_name");

	classes:

		# Disable repositories ?
		"pkg_mgr_disablerepositories" not => strcmp("&PKG_MGR_DISABLEREPOSITORIES&","false");

	files:

		SuSE::
                        "/etc/zypp/repos.d/rudder-$(pkg_mgr_name[$(pkg_mgr_index)]).repo"
                                create => "true",
                                perms => m("644"),
                                edit_line => set_zypper_repos("$(pkg_mgr_name[$(pkg_mgr_index)])", "$(pkg_mgr_url[$(pkg_mgr_index)])", "$(pkg_mgr_enabled[$(pkg_mgr_index)])", "$(pkg_mgr_type[$(pkg_mgr_index)])", "$(g.rudder_dependencies)/zypper-repo.tpl"),
                                edit_defaults => empty_backup,
                                classes =>  kept_if_else("pkg_mgr_$(pkg_mgr_index)_kept", "pkg_mgr_$(pkg_mgr_index)_validated", "pkg_mgr_$(pkg_mgr_index)_failed");

		SuSE.pkg_mgr_disablerepositories::

                        "/etc/zypp/repos.d/.*"
                                delete => tidy,
                                file_select => ex_list("@(pkg_mgr_files)"),
                                depth_search => recurse("inf"),
                                classes => kept_if_else("repos_disabled_kept", "repos_disabled_ok", "repos_disabled_fail"),
				comment => "Delete the unwanted repos as requested";

	reports:
		# Zypper repositories desactivation

                pkg_mgr_disablerepositories.!repos_disabled_ok.!repos_disabled_fail::
                        "@@Package repositories management RPM@@result_success@@&TRACKINGKEY&@@General settings@@None@@$(g.execRun)##$(g.uuid)@#Every repository other than the defined ones were already disabled";

                pkg_mgr_disablerepositories.repos_disabled_ok::
                        "@@Package repositories management RPM@@result_repaired@@&TRACKINGKEY&@@General settings@@None@@$(g.execRun)##$(g.uuid)@#Every repository other than the defined ones were disabled";

                pkg_mgr_disablerepositories.repos_disabled_fail::
                        "@@Package repositories management RPM@@result_error@@&TRACKINGKEY&@@General settings@@None@@$(g.execRun)##$(g.uuid)@#Could not disable the other repositories!";

                !pkg_mgr_disablerepositories::
                        "@@Package repositories management RPM@@result_success@@&TRACKINGKEY&@@General settings@@None@@$(g.execRun)##$(g.uuid)@#The repository desactivation has not been requested. Skipping...";

		# Ignore non-SuSE OSes

		!SuSE::
			"@@Package repositories management RPM@@result_error@@&TRACKINGKEY&@@zypperPackageManagerSettings@@None@@$(g.execRun)##$(g.uuid)@#ZYPPER cannot be configured on non SuSE OSes";

		!pkg_mgr_repositories_edit::

			"@@Package repositories management RPM@@result_success@@&TRACKINGKEY&@@Repository@@$(pkg_mgr_name[$(pkg_mgr_index)])@@$(g.execRun)##$(g.uuid)@#The source $(pkg_mgr_name[$(pkg_mgr_index)]) will NOT be added as the repository addition parameter is off in the Policy Instance. Skipping...";

		SuSE::

                # Repositories

                        "@@Package repositories management RPM@@result_success@@&TRACKINGKEY&@@Repository@@$(pkg_mgr_name[$(pkg_mgr_index)])@@$(g.execRun)##$(g.uuid)@#The Zypper source $(pkg_mgr_name[$(pkg_mgr_index)]) was already here. Skipping..."
                                ifvarclass => "pkg_mgr_$(pkg_mgr_index)_kept.!pkg_mgr_$(pkg_mgr_index)_validated";

                        "@@Package repositories management RPM@@result_repaired@@&TRACKINGKEY&@@Repository@@$(pkg_mgr_name[$(pkg_mgr_index)])@@$(g.execRun)##$(g.uuid)@#The Zypper source $(pkg_mgr_name[$(pkg_mgr_index)]) has been successfully added"
                                ifvarclass => "pkg_mgr_$(pkg_mgr_index)_validated";

                        "@@Package repositories management RPM@@result_error@@&TRACKINGKEY&@@Repository@@$(pkg_mgr_name[$(pkg_mgr_index)])@@$(g.execRun)##$(g.uuid)@#The Zypper source $(pkg_mgr_name[$(pkg_mgr_index)]) was NOT added!"
                                ifvarclass => "pkg_mgr_$(pkg_mgr_index)_error";


}

bundle edit_line set_zypper_repos(zypper_name, zypper_url, zypper_enabled, zypper_type, template)
{

insert_lines:

                "$(template)"
                        insert_type => "file",
                        expand_scalars => "true";

}
