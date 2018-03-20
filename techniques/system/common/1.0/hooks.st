#####################################################################################
# Copyright 2018 Normation SAS
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


# This file contains the collection of pre and post hooks for techniques
# They all have a unique parameter, which is a JSON containing parameters, and all the list of reports, in the form
# '{"parameters":{"name":"sudo","destination":"/etc/sudoers"},"reports":
#[{"id":"32377fd7-02fd-43d0aab7-28460a91347b@@7aefa930-5493-4ec6-9d6b-f093b03ad709@@0","mode":"enforce", "technique":"sudoers", "name":"check_sudo_installed", "value":"None"},
#  {"id":"92377fd7-02fd-43d0-aab7-28460a91347b@@9b575791-dc9b-409e-8841-e57f4b887e43@@0","mode":"audit", "technique":"sudoers", "name":"check_sudo_installed", "value":"None"}
#  ]}';
# By convention, if any of reports is in enforce, then the hook will perform the action, otherwise it will only audit


# 
# Ensure that a package is present
# Parameters are:
#     "name"      : Package Name
#     "condition" : Condition on when to check the package (not mandatory)
# Reports format is
#     "id"        : Rule id
#     "mode"      : enforce or audit
#     "technique" : technique name
#     "name"      : component name for reporting
#     "value"     : component value for reporting
bundle agent runhook_package(json) {
  vars:
      "definitions" data => parsejson("${json}");

      "parameters"  data => mergedata("definitions[parameters]");

      "reporting"   data => mergedata("definitions[reports]");

      "reportkeys" slist => getindices("reporting");

      "condition" string => "${parameters[condition]}";

    pass1.is_enforce::
      "set_dry_mode"   string => "false";

    pass1.!is_enforce::
      "set_dry_mode"   string => "true";

    pass1.is_condition_defined::
      "class_condition" string => "${conditions}";

    pass1.!is_condition_defined::
      "class_condition" string => "any";


  classes:
      "is_condition_defined"            not => strcmp("${conditions}", "");

      # define if there is at least one enforce
      "is_enforce"               expression => strcmp("${reporting[${reportkeys}][mode]}", "enforce");

      # For reporting, detect each enforce/audit
      "is_enforce_${reportkeys}" expression => strcmp("${reporting[${reportkeys}][mode]}", "enforce");


    any::
      "pass2" expression => "pass1";
      "pass1" expression => "any";


  methods:
    pass2::
      "configure_dry_run_mode_${reporting[0][id]}"
         usebundle => set_dry_run_mode("${set_dry_mode}");

      "install_package"
        usebundle  => package_present("${parameters[name]}", "", "", ""),
        ifvarclass => "${class_condition}";

      # here we need to report correctly based on each mode for each directive
      "reporting" 
        usebundle  => _rudder_common_reports_generic_hooks("${reporting[${reportkeys}][technique]}", "package_present_${parameters[name]}", "${reporting[${reportkeys}][id]}", "${reporting[${reportkeys}][name]}", "${reporting[${reportkeys}][value]}", "Installing package ${parameters[name]}", "${reporting[${reportkeys}][mode]}"),
        ifvarclass => "${class_condition}";

      "na_report"
        usebundle  => _rudder_common_report_hooks("${reporting[${reportkeys}][technique]}", "result_na", "${reporting[${reportkeys}][id]}", "${reporting[${reportkeys}][name]}", "${reporting[${reportkeys}][value]}", "Installing package ${parameters[name]}", "${reporting[${reportkeys}][mode]}"),
        ifvarclass => "!${class_condition}";

      "clean_reporting_context_${reporting[0][id]}"
        usebundle  => clean_reporting_context;

  reports:
    inform.pass2::
      "Executing hook runhook_package to install package ${parameters[name]} - Audit mode: ${set_dry_mode} - Condition is {class_condition}";

}


########################################################
## Sudo Parameters specific hooks
########################################################

# This is a pre hook for sudoParameters
# If any of report mode is enforce, then it will effectively check /etc/sudoers existance, and copy it to /etc/sudoers.rudder
# If all are in audit mode, then it won't do anything
# This method does not report at all
bundle agent runhook_sudo_pre_hook(json) {
  vars:
      "definitions" data => parsejson("${json}");

      "parameters"  data => mergedata("definitions[parameters]");

      "reporting"   data => mergedata("definitions[reports]");

      "reportkeys" slist => getindices("reporting");

    pass1.is_enforce::
      "set_dry_mode"  string => "false";

    pass1.!is_enforce::
      "set_dry_mode"  string => "true";

  classes:
      # define if there is at least one enforce
      "is_enforce"            expression => strcmp("${reporting[${reportkeys}][mode]}", "enforce");

      # For reporting, detect each enforce/audit
      "is_enforce_${reportkeys}" expression => strcmp("${reporting[${reportkeys}][mode]}", "enforce");

    is_enforce::
      "sudoconfiguration_sudoers_present" expression => fileexists("/etc/sudoers");


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
        perms     => mog("0440", "root", "0"),
        classes   => kept_if_else("sudoconfiguration_sudoers_tmp_copy_kept", "sudoconfiguration_sudoers_tmp_copy_repaired", "sudoconfiguration_sudoers_tmp_copy_error"),
        comment   => "Copying sudoers to a temporary file for editing";

    # If there is no /etc/sudoers file, remove our local copy before
    # rebuilding, so that success/repaired reports make sense for the
    # /etc/sudoers file, not just for our copy of it, and set result classes
    # as if we had set it up correctly.
    !sudoconfiguration_sudoers_present::
      "/etc/sudoers.rudder"
        delete  => tidy,
        classes => kept_if_else("sudoconfiguration_sudoers_tmp_copy_kept", "sudoconfiguration_sudoers_tmp_copy_repaired", "sudoconfiguration_sudoers_tmp_copy_error"),
        comment => "Remove temporary copy of /etc/sudoers that Rudder keeps in /etc/sudoers.rudder";


}


#
# This is the post hook for sudoParameters
# The only real parameter useful in it is the report part for json
# If any of report mode is enforce, then it will effectively check /etc/sudoers.rudder and copy it if successful to
# /etc/sudoers
# It reports, as hardcoded, to component sudoersFile, with value None
bundle agent runhook_sudo_post_hook(json) {
  vars:
      "definitions" data => parsejson("${json}");

      "parameters"  data => mergedata("definitions[parameters]");

      "reporting"   data => mergedata("definitions[reports]");

      "reportkeys" slist => getindices("reporting");

    pass1.is_enforce::
      "set_dry_mode"  string => "false";

    pass1.!is_enforce::
      "set_dry_mode"  string => "true";

    pass1.visudo_use_strict_mode::
      "strict_mode" string => "-s ";

    pass1.!visudo_use_strict_mode::
      "strict_mode" string => "";

  classes:
      # define if there is at least one enforce
      "is_enforce"            expression => strcmp("${reporting[${reportkeys}][mode]}", "enforce");

      # For reporting, detect each enforce/audit
      "is_enforce_${reportkeys}" expression => strcmp("${reporting[${reportkeys}][mode]}", "enforce");

    is_enforce::
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
    # We copy only if we are in enforce and file is valid
    # If we are not in enforce, then the file has never been changed, so we cannot check nor validate anything.
    pass3.sudoconfiguration_sudoers_valid.is_enforce::

      "/etc/sudoers"
        copy_from => digest_cp("/etc/sudoers.rudder"),
        create => "true",
        perms => mog("0440", "root", "0"),
        classes => classes_generic("sudoconfiguration_sudoers_copy"),
        comment => "Copying sudoers to its final home";

  methods:
    pass1::
      "configure_dry_run_mode_${reporting[0][id]}" usebundle => set_dry_run_mode("${set_dry_mode}");

    pass3.((sudoconfiguration_sudoers_copy_kept.!sudoconfiguration_sudoers_copy_repaired)|(dry_run.sudoparameters_sudoers_tmp_file_ok))::
      "any" usebundle => _rudder_common_report_hooks("sudoParameters", "result_success", "${reporting[${reportkeys}][id]}", "sudoersFile", "None", "The sudoers file did not require any modification", "${reporting[${reportkeys}][mode]}");


    pass3.!dry_run.sudoconfiguration_sudoers_copy_repaired::

      "any" usebundle => _rudder_common_report_hooks("sudoParameters", "result_repaired", "${reporting[${reportkeys}][id]}", "sudoersFile", "None", "The sudoers file was fixed and successfully updated", "${reporting[${reportkeys}][mode]}");

    pass3.(sudoconfiguration_sudoers_tmp_edit_error|sudoconfiguration_sudoers_copy_error|sudoconfiguration_sudoers_tmp_copy_error)::

      "any" usebundle => _rudder_common_report_hooks("sudoParameters", "result_error", "${reporting[${reportkeys}][id]}", "sudoersFile", "None", "The sudoers file could NOT be edited!", "${reporting[${reportkeys}][mode]}");

    pass3.!dry_run.sudoconfiguration_sudoers_invalid::
      "any" usebundle => _rudder_common_report_hooks("sudoParameters", "result_error", "${reporting[${reportkeys}][id]}", "sudoersFile", "None", "The generated sudoers file is invalid. Not updating /etc/sudoers. This should not happen.", "${reporting[${reportkeys}][mode]}");


  commands:
    # if we don't have enforce, we don't run this command - so it's only if class is_enforce is set
    pass2.sudoparameters_sudoers_tmp_file_ok.is_enforce::
      "/usr/sbin/visudo"
        args => "-c ${strict_mode} -f /etc/sudoers.rudder",
        classes => cf2_if_else("sudoconfiguration_sudoers_valid", "sudoconfiguration_sudoers_invalid"),
        comment => "Checking new sudoers validity";

}
