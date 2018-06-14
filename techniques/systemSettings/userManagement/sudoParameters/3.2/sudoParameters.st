#####################################################################################
# Copyright 2011-2018 Normation SAS
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

############################################################################
# Sudo configuration Technique                                             #
# -------------------------------------------------------------------------#
# Objective : Configure /etc/sudoers according to the given parameters     #
# In Enforce Mode, it creates a /etc/sudoers.rudder file, to edit it       #
#                  by enforcing sections of the format                     #
# # begin_section_${entity}                                                #
#   ALL=(ALL) $command                                                     #
# # end_section_${entity}                                                  #
#                                                                          #
# Once all editions have been checked, /etc/sudoers.rudder is checked      #
# with visudo command, and if valid, it replaces /etc/sudoers              #
#                                                                          #
# In Audit Mode, it will directly check the /etc/sudoers file, by checking #
# all the                                                                  #
#   ALL=(ALL) $command                                                     #
# without the section delimiter                                            #
# There is no validation with visudo of this file in Audit mode            #
############################################################################

# Depends on hooks runhook_package, runhook_sudo_pre_hook and runhook_sudo_post_hook

bundle agent check_sudo_parameters_RudderUniqueID
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

    # Define the file to edit
    # In dry-run, we cannot copy the /etc/sudoers to /etc/sudoers.rudder (as we don't change file in dry-run)
    # So the workaround is to check content of file /etc/sudoers in dry-run
    # It's done before pass1 to be sure that it won't be changed by any dry-run change
    !pass1.dry_run::
      "sudoers_file" string => "/etc/sudoers";

    !pass1.!dry_run::
      "sudoers_file" string => "/etc/sudoers.rudder";


    pass1::
      "entity[${sudo_index}]"
        string     => "%${sudo_entity_name[${sudo_index}]}",
        ifvarclass => "sudo_${sudo_index}_isgroup";

      "entity[${sudo_index}]"
        string     => "${sudo_entity_name[${sudo_index}]}",
        ifvarclass => "sudo_${sudo_index}_isuser";

      # used for reporting conditions
      "csection_name[${sudo_index}]"
        string     => canonify("# begin_section_${entity[${sudo_index}]}");

  classes:
      # Is it a group ?
      "sudo_${sudo_index}_isgroup" expression => strcmp("${sudo_entity_type[${sudo_index}]}","group");

      # Is it a user ?
      "sudo_${sudo_index}_isuser" expression => strcmp("${sudo_entity_type[${sudo_index}]}","user");

    any::
      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";

  methods:

    # Edit sudoers.rudder file if it's been copied or purged, or if we are in dry-run
    # These classes are set by runhook_sudo_pre_hook
    ((sudoconfiguration_sudoers_tmp_copy_kept|sudoconfiguration_sudoers_tmp_copy_repaired).(!sudoconfiguration_sudoers_tmp_copy_error))|dry_run::
      "any"
        usebundle => sudo_parameter_edit_sudoers_RudderUniqueID("${sudoers_file}", "check_sudo_parameters_RudderUniqueID.entity", "check_sudo_parameters_RudderUniqueID.sudo_entity_nopasswd", "check_sudo_parameters_RudderUniqueID.sudo_entity_all", "check_sudo_parameters_RudderUniqueID.sudo_entity_command");

    pass3::
      "any" usebundle => rudder_common_report("sudoParameters", "log_warn", "${sudo_directive_id[${sudo_index}]}", "Permissions", "${sudo_entity_name[${sudo_index}]}", "Entry for ${sudo_entity_type[${sudo_index}]} ${sudo_entity_name[${sudo_index}]} is invalid (no command given), and has been ignored"), 
        ifvarclass => "!sudo_${sudo_index}_RudderUniqueID_command_notempty.!sudo_${sudo_index}_RudderUniqueID_alldo";

      "any" usebundle => rudder_common_reports_generic("sudoParameters", "sudo_parameter_edited_section_${csection_name[${sudo_index}]}_RudderUniqueID", "${sudo_directive_id[${sudo_index}]}", "Permissions", "${sudo_entity_name[${sudo_index}]}", "The ${sudo_entity_type[${sudo_index}]} ${sudo_entity_name[${sudo_index}]}");

}

bundle agent sudo_parameter_edit_sudoers_RudderUniqueID(filename, entity, nopasswd, alldo, command)
{
  vars:

      "index" slist => getindices("${entity}");

    pass1::

      "command_all[${index}]" string => "ALL=(ALL) NOPASSWD:ALL",
                      ifvarclass => "(sudo_${index}_RudderUniqueID_alldo.sudo_${index}_RudderUniqueID_nopasswd).(sudo_${index}_RudderUniqueID_command_notempty|sudo_${index}_RudderUniqueID_alldo)";

      "command_all[${index}]" string => "ALL=(ALL) ALL",
                      ifvarclass => "(sudo_${index}_RudderUniqueID_alldo.!sudo_${index}_RudderUniqueID_nopasswd).(sudo_${index}_RudderUniqueID_command_notempty|sudo_${index}_RudderUniqueID_alldo)";

      "command_all[${index}]" string => "ALL=(ALL) NOPASSWD:${${command}[${index}]}",
                      ifvarclass => "(sudo_${index}_RudderUniqueID_nopasswd.!sudo_${index}_RudderUniqueID_alldo).(sudo_${index}_RudderUniqueID_command_notempty|sudo_${index}_RudderUniqueID_alldo)";

      "command_all[${index}]" string => "ALL=(ALL) ${${command}[${index}]}",
                      ifvarclass => "(!sudo_${index}_RudderUniqueID_nopasswd.!sudo_${index}_RudderUniqueID_alldo).(sudo_${index}_RudderUniqueID_command_notempty|sudo_${index}_RudderUniqueID_alldo)";


  classes:
      # some classes are used by reporting from parent bundle (scope namespace)

      # Disable password asking ?
      "sudo_${index}_RudderUniqueID_nopasswd" expression => strcmp("${${nopasswd}[${index}]}","true");

      # Should we enable ALL as command ?
      "sudo_${index}_RudderUniqueID_alldo" expression => strcmp("${${alldo}[${index}]}","true"),
                            scope => "namespace";
    pass2::
      # Is command empty ?
      "sudo_${index}_RudderUniqueID_command_notempty" not => strcmp("${${command}[${index}]}",""),
                                       scope => "namespace";

      # detect if file has been changed by edition
      "sudoparameters_sudoers_tmp_file_ok"
                         not => classmatch("sudo_parameter_edited_section_.*_RudderUniqueID_error"),
                       scope => "namespace";

      "sudoparameters_sudoers_tmp_file_error"
                   expression => classmatch("sudo_parameter_edited_section_.*_RudderUniqueID_error"),
                        scope => "namespace";

    any::
      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";


  files:
    "${filename}"
        create        => "true",
        edit_defaults => noempty_backup,
        perms         => mog("0440", "root", "0"),
        comment       => "Sanitize environment",
        edit_line     => sudo_parameter_sanitize_env_RudderUniqueID;


  methods:
    pass2::
      "edit_file" usebundle => sudo_parameter_ensure_block_section_RudderUniqueID("${filename}", "${${entity}[${index}]}", "${command_all[${index}]}", "# begin_section_${${entity}[${index}]}", "# end_section_${${entity}[${index}]}");

}

# Sanitize the environement
bundle edit_line sudo_parameter_sanitize_env_RudderUniqueID
{
  insert_lines:
    replace_attempted_env_reset::
      "Defaults	env_reset";

  replace_patterns:
    "^(?!Defaults	env_reset$)Defaults\s+env_reset$"
      comment      => "Normalize env_reset setting",
      replace_with => value("Defaults	env_reset"),
      classes      => always("replace_attempted_env_reset");

}

bundle agent sudo_parameter_ensure_block_section_RudderUniqueID(filename, entity, command, begin, end) {
  vars:
      "escaped_entity"   string => escape("${entity}");
      "escaped_command"  string => escape("${command}");
      "escaped_begin"    string => escape("${begin}");
      "canonified_begin" string => canonify("${begin}");

  # In enforce mode
  # Edit the file using ncf_ensure_section_content_and_purge_type
  # It will remove all lines starting by entity in the file, and ensure content of block begin-entity	command-end
  # In audit mode, we don't want to ensure it is in a section - if the value is preexisting, then it's fine
  files:
    !dry_run::
      "${filename}" 
        create        => "true",
        edit_defaults => noempty_backup,
        perms         => mog("0440", "root", "0"),
        edit_line     => ncf_ensure_section_content_and_purge_type("${begin}", "${end}", "${entity}	${command}", "preserve_block", "${escaped_entity}"),
        classes       => classes_generic("sudo_parameter_edited_section_${canonified_begin}_RudderUniqueID");

    dry_run::
      "${filename}" 
        create        => "true",
        edit_defaults => noempty_backup,
        perms         => mog("0440", "root", "0"),
        edit_line     => insert_lines("${entity}	${command}"),
        classes       => classes_generic("sudo_parameter_edited_section_${canonified_begin}_RudderUniqueID");
}

