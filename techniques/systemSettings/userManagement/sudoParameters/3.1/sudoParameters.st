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
# Sudo configuration Technique                                                  #
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

                &SUDO_DESCRIPTION:{description |"sudo_entity_description[&i&]" string => "&description&";
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

    pass1.visudo_use_strict_mode::
      "strict_mode" string => "-s ";

    pass1.!visudo_use_strict_mode::
      "strict_mode" string => "";

  classes:

      "sudoconfiguration_sudoers_present" expression => fileexists("/etc/sudoers");

      # Check the version of visudo; if before 1.7 (so 1.6 or less), we need to use strict mode
      # For version 1.7, bugs in the strict parsing prevent from using safely the strict mode (see http://www.sudo.ws/bugs/show_bug.cgi?id=519 )
      # Versions after 1.7 don't need to have Aliases defined before they are used, and strict mode only checks that, so we can safely ignore it
      # visudo -V can returns several lines, so we need to keep only the visudo version line
      "visudo_use_strict_mode" expression => returnszero("/usr/sbin/visudo  -V | grep 'visudo version' | /bin/sed -e 's/visudo version \([0-9]\+\)\.\([0-9]\+\)\..*/\1 \2/p' | /usr/bin/awk '{ if(($1<1)||($1==1 \&\& $2<=6)) { exit 0 }; exit 1 }'", "useshell");

    any::
      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";

  files:

    # Only copy /etc/sudoers if it exists (this is to avoid falling into an
    # error report below)
    sudoconfiguration_sudoers_present::
      "/etc/sudoers.rudder"
        copy_from => digest_cp("/etc/sudoers"),
        perms => mog("0440", "root", "0"),
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
        edit_line => sudo_add_line("check_sudo_parameters.sudo_entity_type", "check_sudo_parameters.sudo_entity_name", "check_sudo_parameters.sudo_entity_nopasswd", "check_sudo_parameters.sudo_entity_all", "check_sudo_parameters.sudo_entity_command", "check_sudo_parameters.sudo_directive_id"),
        create => "true",
        edit_defaults => noempty_backup,
        perms => mog("0440", "root", "0"),
        classes => kept_if_else("sudoconfiguration_sudoers_tmp_edit_kept", "sudoconfiguration_sudoers_tmp_edit_repair", "sudoconfiguration_sudoers_tmp_edit_error"),
        comment => "Editing temporary sudoers file";

    sudoconfiguration_sudoers_valid::

      "/etc/sudoers"
        copy_from => digest_cp("/etc/sudoers.rudder"),
        create => "true",
        perms => mog("0440", "root", "0"),
        classes => kept_if_else("sudoconfiguration_sudoers_copy_kept", "sudoconfiguration_sudoers_copy_repaired", "sudoconfiguration_sudoers_copy_error"),
        comment => "Copying sudoers to its final home";

  methods:

      "any"
        usebundle => check_sudo_installation("${sudo_directive_id[${sudo_index}]}");

    # Only copy /etc/sudoers if it exists (this is to avoid falling into an
    # error report below)
    sudoconfiguration_sudoers_present::
      "any"
        usebundle =>  file_copy_from_local_source("/etc/sudoers", "/etc/sudoers.rudder");

    # Question: how do we manage transition from previous version to current version, to prevent duplicated lines ?


    # If there is no /etc/sudoers file, remove our local copy before
    # rebuilding, so that success/repaired reports make sense for the
    # /etc/sudoers file, not just for our copy of it, and set result classes
    # as if we had set it up correctly.
    !sudoconfiguration_sudoers_present::
      "any"
        usebundle =>  file_remove("/etc/sudoers.rudder");


    # Edit sudoers.rudder file if it's been copied or purged
    (file_copy_from_local_source__etc_sudoers_rudder_ok.!file_copy_from_local_source__etc_sudoers_rudder_error)|(file_remove__etc_sudoers_rudder_ok)::

    
    pass3.(sudoconfiguration_sudoers_copy_kept.!sudoconfiguration_sudoers_copy_repaired)::

      "any" usebundle => rudder_common_report("sudoParameters", "result_success", "${sudo_directive_id[${sudo_index}]}", "sudoersFile", "None", "The sudoers file did not require any modification");

    pass3.sudoconfiguration_sudoers_copy_repaired::

      "any" usebundle => rudder_common_report("sudoParameters", "result_repaired", "${sudo_directive_id[${sudo_index}]}", "sudoersFile", "None", "The sudoers file was fixed and successfully updated");

    pass3.(sudoconfiguration_sudoers_tmp_edit_error|sudoconfiguration_sudoers_copy_error|sudoconfiguration_sudoers_tmp_copy_error)::

      "any" usebundle => rudder_common_report("sudoParameters", "result_error", "${sudo_directive_id[${sudo_index}]}", "sudoersFile", "None", "The sudoers file could NOT be edited!");

    pass3.sudoconfiguration_sudoers_invalid::
      "any" usebundle => rudder_common_report("sudoParameters", "result_error", "${sudo_directive_id[${sudo_index}]}", "sudoersFile", "None", "The generated sudoers file is invalid. Not updating /etc/sudoers. This should not happen.");

    pass3.sudo_all_lines_defined::
      "any" usebundle => rudder_common_report("sudoParameters", "log_warn", "${sudo_directive_id[${sudo_index}]}", "Permissions", "${sudo_entity_name[${sudo_index}]}", "Entry for ${sudo_entity_type[${sudo_index}]} ${sudo_entity_name[${sudo_index}]} is invalid (no command given), and has been ignored"), 
        ifvarclass => "!sudo_${sudo_index}_command_notempty.!sudo_${sudo_index}_alldo";

      "any" usebundle => rudder_common_report("sudoParameters", "result_repaired", "${sudo_directive_id[${sudo_index}]}", "Permissions", "${sudo_entity_name[${sudo_index}]}", "The ${sudo_entity_type[${sudo_index}]} ${sudo_entity_name[${sudo_index}]} has been handled"),
        ifvarclass => canonify("line_${sudo_index}_added");

      "any" usebundle => rudder_common_report("sudoParameters", "result_success", "${sudo_directive_id[${sudo_index}]}", "Permissions", "${sudo_entity_name[${sudo_index}]}", "The ${sudo_entity_type[${sudo_index}]} ${sudo_entity_name[${sudo_index}]} is already present"),
        ifvarclass => canonify("line_${sudo_index}_kept");

      "any" usebundle => rudder_common_report("sudoParameters", "result_error", "${sudo_directive_id[${sudo_index}]}", "Permissions", "${sudo_entity_name[${sudo_index}]}", "The ${sudo_entity_type[${sudo_index}]} ${sudo_entity_name[${sudo_index}]} could not be handled"),
        ifvarclass => canonify("line_${sudo_index}_add_failed");

  commands:

    (sudoconfiguration_sudoers_tmp_edit_repair|sudoconfiguration_sudoers_tmp_edit_kept).pass2::

      "/usr/sbin/visudo"
        args => "-c ${strict_mode} -f /etc/sudoers.rudder",
        classes => cf2_if_else("sudoconfiguration_sudoers_valid", "sudoconfiguration_sudoers_invalid"),
        comment => "Checking new sudoers validity";

}

bundle edit_line sudo_add_line(type, name, nopasswd, alldo, command, directiveId)
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


      "lines_name[${index}]" string => "${${name}[${index}]}\s+",
        ifvarclass => "sudo_${index}_isuser";

      "lines_name[${index}]" string => "%${${name}[${index}]}\s+",
        ifvarclass => "sudo_${index}_isgroup";

      "all_lines" slist => getvalues("lines");

  classes:
      # some classes are used by reporting from parent bundle (scope namespace)

      # Is it a group ?
      "sudo_${index}_isgroup" expression => strcmp("${${type}[${index}]}","group");

      # Is it a user ?
      "sudo_${index}_isuser" expression => strcmp("${${type}[${index}]}","user");

      # Disable password asking ?
      "sudo_${index}_nopasswd" expression => strcmp("${${nopasswd}[${index}]}","true");

      # Should we enable ALL as command ?
      "sudo_${index}_alldo" expression => strcmp("${${alldo}[${index}]}","true"),
                            scope => "namespace";

      # Is command empty ?
      "sudo_${index}_command_notempty" not => strcmp("${${command}[${index}]}",""),
                                       scope => "namespace";

      "check_sudo_parameters_sudo_add_line_classes_defined" expression => "any";

      "check_sudo_parameters_sudo_add_line_vars_defined"    expression => isvariable("lines[${index}]");

      "sudo_all_lines_defined"    expression => isvariable("all_lines"),
                                  scope => "namespace";

    # Check if line is already there
    pass1::
      "sudo_${index}_line_present" expression => regline("${lines[${index}]}", "/etc/sudoers.rudder");

      "sudo_${index}_line_name_present" expression => regline("${lines_name[${index}]}", "/etc/sudoers.rudder");

    any::
      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";


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

}

bundle agent ensure_block_section(filename, key, content, begin, end) {
  vars:
      "escaped_key"     string => escape("${key}");
      "escaped_content" string => escape("${content}");
      "escaped_begin"   string => escape("${begin}");
      "canonified_begin"  string => canonify("${begin}");
  classes:
      # not used
      "line_present" expression => regline("^${escaped_key}\s+${escaped_content}$", "${filename}");
      "section_present" expression => regline("^${escaped_begin}$", "${filename}");
      "key_present" expression => regline("^${escaped_key}\s+", "${filename}");

    any::
      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";


# several cases:
# - section is not there, nor is key => insert the block
# - section is not there, and the line is there
#   delete line, and insert the block
# - section is not there, and only the key is there
#   delete line, and insert the block

# - section is there, key is not there
#   force content of section
# - section is there, key is there
#   delete key, force content of section

# CAUTION, we should probably not delete keys in others sections (that is what happens now)
  files:
      "${filename}" 
         create => "true",
         edit_line => ncf_ensure_section_content_and_purge_type("${begin}", "${end}", "${key}	${content}", "preserve_block", "${escaped_key}"),
         classes =>  classes_generic("edited_section_${canonified_begin}");

  reports:
"edited_section_${canonified_begin}";
    "success"
ifvarclass => "edited_section_${canonified_begin}_kept";


    "repaired"
ifvarclass => "edited_section_${canonified_begin}_repaired";

    "error"
ifvarclass => "edited_section_${canonified_begin}_error";


}



# Enforce content in section.
# It will create the section if it does not exist yet.
# You can choose the insert_type:
# * Use "preserve_block" to insert blocks of text
# * Use "literal" to insert independant lines
# content_to_delete is a regexp to delete all lines (even outside section) matching the contet
bundle edit_line ncf_ensure_section_content_and_purge_type(section_start, section_end, content, insert_type, content_to_delete)
{
  vars:
      "csection"              string => canonify("$(section_start)");
      "escaped_section_start" string => escape(${section_start});
      "escaped_section_end"   string => escape(${section_end});

  classes:
      # Detect if section is already there
      "has_$(csection)" expression => regline("${escaped_section_start}", "$(edit.filename)");

      "content_to_delete_defined" not => strcmp("${content_to_delete}", "");

    any::
      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";


  delete_lines:
      ".*"
        select_region => ncf_section_selector("${escaped_section_start}", "${escaped_section_end}"),
        ifvarclass => "has_$(csection)";

    !pass2::
      "${content_to_delete}	.*"
        ifvarclass => "content_to_delete_defined";
 
  insert_lines:
      # Insert new, empty section if it doesn't exist already.
      "${section_start}
${section_end}"
        insert_type => "preserve_block",
        ifvarclass => "!has_$(csection)";
 
      # Insert missing lines or block into the section
      "$(content)"
        insert_type => "${insert_type}",
        select_region => ncf_section_selector("${escaped_section_start}", "${escaped_section_end}");
}



bundle agent check_sudo_installation(directiveId)
{

  classes:
    any::
      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";

  packages:
    linux::
      "sudo"
        package_policy  => "add",
        package_method  => generic,
        classes => kept_if_else("sudoconfiguration_sudo_install_kept", "sudoconfiguration_sudo_install_repaired", "sudoconfiguration_sudo_install_error"),
        comment => "Installing sudo using generic interface";

  methods:
    pass3.sudoconfiguration_sudo_install_kept::
      "any" usebundle => rudder_common_report("sudoParameters", "result_success", "${directiveId}", "Install", "None", "sudo already installed");

    pass3.sudoconfiguration_sudo_install_repaired::
      "any" usebundle => rudder_common_report("sudoParameters", "result_repaired", "${directiveId}", "Install", "None", "sudo has been successfully installed");

    pass3.sudoconfiguration_sudo_install_error::
      "any" usebundle => rudder_common_report("sudoParameters", "result_error", "${directiveId}", "Install", "None", "Can't install sudo");

    pass3.(!linux)::
      "any" usebundle => rudder_common_report("sudoParameters", "result_success", "${directiveId}", "Install", "None", "Support to check if sudo is installed not available on this platform");

}

body delete_select sudo_select_nomatch(s)
{
        delete_if_not_match_from_list => { "Defaults	env_reset", @{s} };
}
