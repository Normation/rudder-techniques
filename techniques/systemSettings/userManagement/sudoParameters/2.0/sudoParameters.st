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
# Sudo configuration PT                                                  #
# ---------------------------------------------------------------------- #
# Objective : Configure /etc/sudoers according to the given parameters   #
##########################################################################

bundle agent check_sudo_parameters
{
  vars:

                &SUDO_TYPE:{type |"sudo_entity_type[&i&]" string => "&type&";
}&

                &SUDO_NAME:{name |"sudo_entity_name[&i&]" string => "&name&";
}&

                &SUDO_NOPASSWD:{nopasswd |"sudo_entity_nopasswd[&i&]" string => "&nopasswd&";
}&

                &SUDO_ALL:{alldo |"sudo_entity_all[&i&]" string => "&alldo&";
}&

                &SUDO_COMMAND:{command |"sudo_entity_command[&i&]" string => "&command&";
}&

                &TRACKINGKEY:{directiveId |"sudo_directive_id[&i&]" string => "&directiveId&";
}&

      "sudo_index" slist => getindices("sudo_entity_type");

    pass_1.visudo_use_strict_mode::
      "strict_mode" string => "-s ";

    pass_1.!visudo_use_strict_mode::
      "strict_mode" string => "";

  classes:

      "sudoconfiguration_sudoers_present" expression => fileexists("/etc/sudoers");

      # Check the version of visudo; if before 1.7 (so 1.6 or less), we need to use strict mode
      # For version 1.7, bugs in the strict parsing prevent from using safely the strict mode (see http://www.sudo.ws/bugs/show_bug.cgi?id=519 )
      # Versions after 1.7 don't need to have Aliases defined before they are used, and strict mode only checks that, so we can safely ignore it
      # visudo -V can returns several lines, so we need to keep only the visudo version line
      "visudo_use_strict_mode" expression => returnszero("/usr/sbin/visudo  -V | grep 'visudo version' | /bin/sed -e 's/visudo version \([0-9]\+\)\.\([0-9]\+\)\..*/\1 \2/p' | /usr/bin/awk '{ if(($1<1)||($1==1 \&\& $2<=6)) { exit 0 }; exit 1 }'", "useshell");

      "pass_1" expression => "any";
      "pass_2" expression => isvariable("strict_mode");
  files:

    # Only copy /etc/sudoers if it exists (this is to avoid falling into an
    # error report below)
    sudoconfiguration_sudoers_present::
      "/etc/sudoers.rudder"
        copy_from => digest_cp("/etc/sudoers"),
        perms => mog("0440", "root", "root"),
        classes => kept_if_else("sudoconfiguration_sudoers_tmp_copy_kept", "sudoconfiguration_sudoers_tmp_copy_repaired", "sudoconfiguration_sudoers_tmp_copy_error"),
        comment => "Copying sudoers to a temporary file for editing";

    # If there is no /etc/sudoers file, remove our local copy before
    # rebuilding, so that success/repaired reports make sense for the
    # /etc/sudoers file, not just for our copy of it, and set result classes
    # as if we had set it up correctly.
    !sudoconfiguration_sudoers_present::
      "/etc/sudoers.rudder"
        delete  => tidy,
        classes => kept_if_else("sudoconfiguration_sudoers_tmp_copy_kept", "sudoconfiguration_sudoers_tmp_copy_repaired", "sudoconfiguration_sudoers_tmp_copy_error"),
        comment => "Remove temporary copy of /etc/sudoers that Rudder keeps in /etc/sudoers.rudder";


    ((sudoconfiguration_sudoers_tmp_copy_kept|sudoconfiguration_sudoers_tmp_copy_repaired).(!sudoconfiguration_sudoers_tmp_copy_error))::
      "/etc/sudoers.rudder"
        edit_line => sudo_add_line("check_sudo_parameters.sudo_entity_type", "check_sudo_parameters.sudo_entity_name", "check_sudo_parameters.sudo_entity_nopasswd", "check_sudo_parameters.sudo_entity_all", "check_sudo_parameters.sudo_entity_command", "check_sudo_parameters.sudo_directive_id", "${sudo_force_content}"),
        create => "true",
        edit_defaults => noempty_backup,
        perms => mog("0440", "root", "root"),
        classes => kept_if_else("sudoconfiguration_sudoers_tmp_edit_kept", "sudoconfiguration_sudoers_tmp_edit_repair", "sudoconfiguration_sudoers_tmp_edit_error"),
        comment => "Editing temporary sudoers file";

    sudoconfiguration_sudoers_valid::

      "/etc/sudoers"
        copy_from => digest_cp("/etc/sudoers.rudder"),
        create => "true",
        perms => mog("0440", "root", "root"),
        classes => kept_if_else("sudoconfiguration_sudoers_copy_kept", "sudoconfiguration_sudoers_copy_repaired", "sudoconfiguration_sudoers_copy_error"),
        comment => "Copying sudoers to its final home";

  methods:

      "any"

        usebundle => check_sudo_installation("${sudo_directive_id[${sudo_index}]}");

  commands:

    (sudoconfiguration_sudoers_tmp_edit_repair|sudoconfiguration_sudoers_tmp_edit_kept).pass_2::

      "/usr/sbin/visudo"
        args => "-c ${strict_mode} -f /etc/sudoers.rudder",
        classes => cf2_if_else("sudoconfiguration_sudoers_valid", "sudoconfiguration_sudoers_invalid"),
        comment => "Checking new sudoers validity";

  reports:

    sudoconfiguration_sudoers_copy_kept.!sudoconfiguration_sudoers_copy_repaired::

      "@@sudoParameters@@result_success@@${sudo_directive_id[${sudo_index}]}@@sudoersFile@@None@@${g.execRun}##${g.uuid}@#The sudoers file did not require any modification";

    sudoconfiguration_sudoers_copy_repaired::

      "@@sudoParameters@@result_repaired@@${sudo_directive_id[${sudo_index}]}@@sudoersFile@@None@@${g.execRun}##${g.uuid}@#The sudoers file was fixed and successfully updated";

    sudoconfiguration_sudoers_tmp_edit_error|sudoconfiguration_sudoers_copy_error|sudoconfiguration_sudoers_tmp_copy_error::

      "@@sudoParameters@@result_error@@${sudo_directive_id[${sudo_index}]}@@sudoersFile@@None@@${g.execRun}##${g.uuid}@#The sudoers file could NOT be edited!";

    sudoconfiguration_sudoers_invalid::
      "@@sudoParameters@@result_error@@${sudo_directive_id[${sudo_index}]}@@sudoersFile@@None@@${g.execRun}##${g.uuid}@#The generated sudoers file is invalid. Not updating /etc/sudoers. This should not happen.";

}

bundle edit_line sudo_add_line(type, name, nopasswd, alldo, command, directiveId, force)
{

  vars:

      "index" slist => getindices("${type}");

    check_sudo_parameters_sudo_add_line_classes_defined::

      "lines[${index}]"
        string => "%${${name}[${index}]}	ALL=(ALL) NOPASSWD:ALL",
        ifvarclass => "(sudo_${index}_isgroup.sudo_${index}_alldo.sudo_${index}_nopasswd).(sudo_${index}_command_notempty|sudo_${index}_alldo)";

      "lines[${index}]" string => "%${${name}[${index}]}	ALL=(ALL) ALL",
        ifvarclass => "(sudo_${index}_isgroup.sudo_${index}_alldo.!sudo_${index}_nopasswd).(sudo_${index}_command_notempty|sudo_${index}_alldo)";

      "lines[${index}]" string => "%${${name}[${index}]}	ALL=(ALL) NOPASSWD:${${command}[${index}]}",
        ifvarclass => "(sudo_${index}_isgroup.sudo_${index}_nopasswd.!sudo_${index}_alldo).(sudo_${index}_command_notempty|sudo_${index}_alldo)";

      "lines[${index}]" string => "%${${name}[${index}]}	ALL=(ALL) ${${command}[${index}]}",
        ifvarclass => "(sudo_${index}_isgroup.!sudo_${index}_nopasswd.!sudo_${index}_alldo).(sudo_${index}_command_notempty|sudo_${index}_alldo)";


      "lines[${index}]" string => "${${name}[${index}]}	ALL=(ALL) NOPASSWD:ALL",
        ifvarclass => "(sudo_${index}_isuser.sudo_${index}_alldo.sudo_${index}_nopasswd).(sudo_${index}_command_notempty|sudo_${index}_alldo)";

      "lines[${index}]" string => "${${name}[${index}]}	ALL=(ALL) ALL",
        ifvarclass => "(sudo_${index}_isuser.sudo_${index}_alldo.!sudo_${index}_nopasswd).(sudo_${index}_command_notempty|sudo_${index}_alldo)";

      "lines[${index}]" string => "${${name}[${index}]}	ALL=(ALL) NOPASSWD:${${command}[${index}]}",
        ifvarclass => "(sudo_${index}_isuser.sudo_${index}_nopasswd.!sudo_${index}_alldo).(sudo_${index}_command_notempty|sudo_${index}_alldo)";

      "lines[${index}]" string => "${${name}[${index}]}	ALL=(ALL) ${${command}[${index}]}",
        ifvarclass => "(sudo_${index}_isuser.!sudo_${index}_nopasswd.!sudo_${index}_alldo).(sudo_${index}_command_notempty|sudo_${index}_alldo)";

      "all_lines" slist => getvalues("lines");

  classes:

      "sudo_force_content" expression => strcmp("true", "${force}");

  # Is it a group ?
      "sudo_${index}_isgroup" expression => strcmp("${${type}[${index}]}","group");

  # Is it a user ?
      "sudo_${index}_isuser" expression => strcmp("${${type}[${index}]}","user");

  # Disable password asking ?
      "sudo_${index}_nopasswd" expression => strcmp("${${nopasswd}[${index}]}","true");

  # Should we enable ALL as command ?
      "sudo_${index}_alldo" expression => strcmp("${${alldo}[${index}]}","true");

  # Is command empty ?
      "sudo_${index}_command_notempty" not => strcmp("${${command}[${index}]}","");

      "check_sudo_parameters_sudo_add_line_classes_defined" expression => "any";

      "check_sudo_parameters_sudo_add_line_vars_defined"    expression => isvariable("lines[${index}]");

      "all_lines_defined"    expression => isvariable("all_lines");


  delete_lines:

    all_lines_defined.force::

      ".*"
        delete_select => sudo_select_nomatch("${all_lines}"),
        classes => if_repaired("line_deleted");

  insert_lines:
    replace_attempted_env_reset::
      "Defaults	env_reset";

    check_sudo_parameters_sudo_add_line_vars_defined::
      "${lines[${index}]}"
        classes => kept_if_else("line_${index}_kept", "line_${index}_added", "line_${index}_add_failed");

  replace_patterns:
	"^(?!Defaults	env_reset$)Defaults\s+env_reset$"
		comment => "Normalize env_reset setting",
		replace_with => value("Defaults	env_reset"),
		classes => always("replace_attempted_env_reset");

  reports:

    all_lines_defined::

      "@@sudoParameters@@log_warn@@${${directiveId}[${index}]}@@Permissions@@${${name}[${index}]}@@${g.execRun}##${g.uuid}@#Entry for ${${type}[${index}]} ${${name}[${index}]} is invalid (no command given), and has been ignored"
        ifvarclass => "!sudo_${index}_command_notempty.!sudo_${index}_alldo";

      "@@sudoParameters@@result_repaired@@${${directiveId}[${index}]}@@Permissions@@${${name}[${index}]}@@${g.execRun}##${g.uuid}@#The ${${type}[${index}]} ${${name}[${index}]} has been handled"
        ifvarclass => canonify("line_${index}_added");

      "@@sudoParameters@@result_success@@${${directiveId}[${index}]}@@Permissions@@${${name}[${index}]}@@${g.execRun}##${g.uuid}@#The ${${type}[${index}]} ${${name}[${index}]} is already present"
        ifvarclass => canonify("line_${index}_kept");

      "@@sudoParameters@@result_error@@${${directiveId}[${index}]}@@Permissions@@${${name}[${index}]}@@${g.execRun}##${g.uuid}@#The ${${type}[${index}]} ${${name}[${index}]} could not be handled"
        ifvarclass => canonify("line_${index}_add_failed");

    all_lines_defined.force.line_deleted::

      "@@sudoParameters@@result_repaired@@sudoersFile@@None@@${g.execRun}##${g.uuid}@#Some lines were deleted from the sudoers file. This implies either a manual edition or an intrusion attempt";

}

bundle agent check_sudo_installation(directiveId)
{

  packages:
    linux::
      "sudo"
        package_policy  => "add",
        package_method  => generic,
        classes => kept_if_else("sudoconfiguration_sudo_install_kept", "sudoconfiguration_sudo_install_repaired", "sudoconfiguration_sudo_install_error"),
        comment => "Installing sudo using generic interface";

  reports:
    sudoconfiguration_sudo_install_kept::
      "@@sudoParameters@@result_success@@${directiveId}@@Install@@None@@${g.execRun}##${g.uuid}@#sudo already installed";

    sudoconfiguration_sudo_install_repaired::
      "@@sudoParameters@@result_repaired@@${directiveId}@@Install@@None@@${g.execRun}##${g.uuid}@#sudo has been successfully installed";

    sudoconfiguration_sudo_install_error::
      "@@sudoParameters@@result_error@@${directiveId}@@Install@@None@@${g.execRun}##${g.uuid}@#Can't install sudo";

}

body delete_select sudo_select_nomatch(s)
{
        delete_if_not_match_from_list => { "Defaults	env_reset", @{s} };
}
