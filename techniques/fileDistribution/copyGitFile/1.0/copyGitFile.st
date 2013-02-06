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

#############################################################################
# Checks if a file matches a given content from GIT and if not, updates it. #
#############################################################################

bundle agent download_file_from_git
{

  vars:

                &COPYFILE_GIT_NAME:{name |"copyfile_git_name[&i&]" string => "&name&";
}&

                &COPYFILE_GIT_REPO:{repo |"copyfile_git_repo[&i&]" string => "&repo&";
}&

                &COPYFILE_GIT_BRANCH:{branch |"copyfile_git_branch[&i&]" string => "&branch&";
}&

                &COPYFILE_GIT_RUDDERNAME:{ruddername |"copyfile_git_ruddername[&i&]" string => "&ruddername&";
}&

                &COPYFILE_GIT_OWNER:{owner |"copyfile_git_owner[&i&]" string => "&owner&";
}&

                &COPYFILE_GIT_GROUP:{group |"copyfile_git_group[&i&]" string => "&group&";
}&

                &COPYFILE_GIT_PERM:{perms |"copyfile_git_perms[&i&]" string => "&perms&";
}&

                &COPYFILE_GIT_DEST:{destination |"copyfile_git_dest[&i&]" string => "&destination&";
}&

                &TRACKINGKEY:{directiveId |"copyfile_git_uuid[&i&]" string => "&directiveId&";
}&

      "index" slist => getindices("copyfile_git_name");

  methods:

      "any" usebundle => check_git_installation("$(copyfile_git_uuid[${index}])");

      "any" usebundle => download_file_from_git_unit("$(copyfile_git_name[${index}])", "$(copyfile_git_repo[${index}])", "$(copyfile_git_branch[${index}])", "$(copyfile_git_ruddername[${index}])", "$(copyfile_git_owner[${index}])", "$(copyfile_git_group[${index}])", "$(copyfile_git_perms[${index}])", "$(copyfile_git_dest[${index}])", "$(copyfile_git_uuid[${index}])");

}

bundle agent download_file_from_git_unit(name, repo, branch, ruddername, owner, group, perms, dest, uuid)
{

  classes:

      "repoexists" expression => isdir("/var/rudder/tmp/${ruddername}");

  commands:

    !repoexists::

      "/usr/bin/git"
        args => "clone ${repo} \"/var/rudder/tmp/${ruddername}\"",
        classes => kept_if_else("repo_clone_kept", "repo_clone_ok", "repo_clone_failed"),
        comment => "Cloning ${repo} on /var/rudder/tmp/${ruddername}";

    repoexists::

      "/usr/bin/git"
        args => "fetch",
        contain => in_dir("/var/rudder/tmp/${ruddername}"),
        classes => kept_if_else("repo_fetch_kept", "repo_fetch_ok", "repo_fetch_failed"),
        comment => "Cloning ${repo} on /var/rudder/tmp/${ruddername}";

    (repo_fetch_ok|repo_fetch_kept)::

      "/usr/bin/git"
        args => "checkout ${branch}",
        contain => in_dir("/var/rudder/tmp/${ruddername}"),
        classes => kept_if_else("repo_clone_ok", "repo_cloned", "repo_clone_failed"),
        comment => "Cloning ${repo} on /var/rudder/tmp/${ruddername}";

  files:

    repoexists::

      "${dest}"
        copy_from => local_cp("/var/rudder/tmp/${ruddername}/${name}"),
        create => "true",
        perms => mog("${perms}", "${owner}", "${group}"),
        classes => kept_if_else("file_copy_kept", "file_copy_ok", "file_copy_failed"),
        comment => "Copying /var/rudder/tmp/${ruddername}/${name} to ${dest}...";

  reports:

    file_copy_kept.(!file_copy_failed|!file_copy_ok)::

      "@@copyGitFile@@result_success@@${uuid}@@GIT File@@${name}@@${g.execRun}##${g.uuid}@#The file ${dest} is up to date. Skipping ...";

    file_copy_ok::

      "@@copyGitFile@@result_repaired@@${uuid}@@GIT File@@${name}@@${g.execRun}##${g.uuid}@#The file ${dest} has been successfully copied";

    file_copy_failed::

      "@@copyGitFile@@result_error@@${uuid}@@GIT File@@${name}@@${g.execRun}##${g.uuid}@#The file ${dest} could not be copied";

}

bundle agent check_git_installation(directiveId)
{

  packages:

    (debian|redhat)::

      "git"
        package_policy  => "add",
        package_method  => generic,
        classes => kept_if_else("git_here", "git_installed", "cant_install_git"),
        comment => "Installing git using generic interface";

    SuSE::

      "git-core"
        package_policy  => "add",
        package_method  => generic,
        classes => kept_if_else("git_here", "git_installed", "cant_install_git"),
        comment => "Installing git using generic interface";
  reports:

    git_here::
      "@@copyGitFile@@result_success@@${directiveId}@@GIT Installation@@None@@${g.execRun}##${g.uuid}@#git already installed";

    git_installed::
      "@@copyGitFile@@result_repaired@@${directiveId}@@GIT Installation@@None@@${g.execRun}##${g.uuid}@#git installed";

    cant_install_git::
      "@@copyGitFile@@result_error@@${directiveId}@@GIT Installation@@None@@${g.execRun}##${g.uuid}@#Can't install git";

}
