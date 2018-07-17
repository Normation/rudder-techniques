#####################################################################################
# Copyright 2017 Normation SAS
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

# Warning: The content of this technique is very close to the content of the package_state() bundle in ncf
# particularly the log message building. All changes made here should also be done in ncf too.

bundle agent package_management {

  vars:
      &PACKAGE_LIST:{name |"package[&i0&]" string => "&name&";
}&

      &TRACKINGKEY:{uuid |"trackingkey[&i0&]" string => "&uuid&";
}&

      &PACKAGE_STATE:{state |"state[&i0&]" string => "&state&";
}&

      # For the two following variables, we override the general value with the content of the specific value
      # if it has been selected (thanks to to *_specified_${index_pkg} classes).
      &PACKAGE_VERSION:{version |"version[&i0&]" string => "&version&";
}&
      &PACKAGE_VERSION_SPECIFIC:{version |"version[&i0&]" string => "&version&", ifvarclass => "version_specified_${index_pkg}";
}&

      &PACKAGE_ARCHITECTURE:{architecture |"architecture[&i0&]" string => "&architecture&";
}&
      &PACKAGE_ARCHITECTURE_SPECIFIC:{architecture |"architecture[&i0&]" string => "&architecture&", ifvarclass => "architecture_specified_${index_pkg}";
}&

      &PACKAGE_MANAGER:{manager |"manager[&i0&]" string => "&manager&";
}&

      &PACKAGE_MANAGER_ALLOW_UNTRUSTED:{allow_untrusted |"allow_untrusted[&i0&]" string => "&allow_untrusted&";
}&

      &PACKAGE_MANAGER_OPTIONS:{manager_options |"manager_options[&i0&]" string => "&manager_options&";
}&

      &PACKAGE_MANAGER_ALLOW_UNTRUSTED:{manager_allow_untrusted |"manager_allow_untrusted[&i0&]" string => "&manager_allow_untrusted&";
}&

      &PACKAGE_POST_HOOK_COMMAND:{command |"posthook[&i0&]" string => "&command&";
}&

      "index_pkg" slist => getindices("package");

      # Build class prefixes with canonified variables
      "class_prefix_package[${index_pkg}]" string => canonify("package_${state[${index_pkg}]}_${package[${index_pkg}]}");
      "class_prefix_script[${index_pkg}]" string => canonify("command_execution_${posthook[${index_pkg}]}");

      # Build string vars used for reporting

      # State
      "state_description[${index_pkg}]" string     => "Presence",
                                        ifvarclass => "state_present_${index_pkg}";
      "state_description[${index_pkg}]" string     => "Absence",
                                        ifvarclass => "!state_present_${index_pkg}";

      # Architecture
      "architecture_description[${index_pkg}]" string     => " for ${architecture[${index_pkg}]} architecture ",
                                               ifvarclass => "architecture_specified_${index_pkg}";
      "architecture_description[${index_pkg}]" string     => " ",
                                               ifvarclass => "!architecture_specified_${index_pkg}";

      # Version
      "version_description[${index_pkg}]" string     => "in latest available version",
                                          ifvarclass => "version_latest_${index_pkg}.state_present_${index_pkg}";
      "version_description[${index_pkg}]" string     => "in any version",
                                          ifvarclass => "!version_latest_${index_pkg}.!version_specified_${index_pkg}";
      "version_description[${index_pkg}]" string     => "in version ${version[${index_pkg}]}",
                                          ifvarclass => "version_specified_${index_pkg}";
      # Non compatibility check is done by the "package_state_options" this is just to inform the user
      "version_description[${index_pkg}]" string     => "in latest available version is not supported and",
                                          ifvarclass => "version_latest_${index_pkg}.!state_present_${index_pkg}";

      # Allow untrusted
      "manager_final_options[${index_pkg}]" string => "-o Apt::Get::AllowUnauthenticated=true ${manager_options[${index_pkg}]}",
                                        ifvarclass => "apt_allow_untrusted_${index_pkg}";
      "manager_final_options[${index_pkg}]" string => "${manager_options[${index_pkg}]}",
                                        ifvarclass => "!apt_allow_untrusted_${index_pkg}";

      # Message for old agents
      "incompatible_error" string => "This technique is not compatible with Rudder 3.1 or older. Skipping.";

      # Name of the ncf bundle. We use a variable to avoid breaking the syntax if the bundle does not exist.
      "bundle_name" string => "package_state_options";
   
  classes:
      # This class is different from the one in ncf (where a version number and latest are considered "specified")
      "version_specified_${index_pkg}" expression => strcmp("${version[${index_pkg}]}", "specific");
      "architecture_specified_${index_pkg}" expression => strcmp("${architecture[${index_pkg}]}", "specific");
      "posthook_specified_${index_pkg}" not => strcmp("${posthook[${index_pkg}]}", "");
      "manager_specified_${index_pkg}" not => strcmp("${manager[${index_pkg}]}", "default");
      "state_present_${index_pkg}" expression => strcmp("${state[${index_pkg}]}", "present");
      "version_latest_${index_pkg}" expression => strcmp("${version[${index_pkg}]}", "latest");
      "allow_unstrusted_${index_pkg}" expression => strcmp("${manager_allow_untrusted[${index_pkg}]}", "true");
      "manager_apt_${index_pkg}" expression => strcmp("${manager[${index_pkg}]}", "apt");
      "apt_allow_untrusted_${index_pkg}" expression => "allow_unstrusted_${index_pkg}.((debian.!manager_specified_${index_pkg})|manager_apt_${index_pkg})";

      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";

  methods:
    # 3.2 does not support agents older than 2.11, hence CFEngine 3.6
    pass2.cfengine_3_6::
      "report_${index_pkg}" usebundle  => rudder_common_report_index("packageManagement", "result_error", "${trackingkey[${index_pkg}]}", "Package", "${package[${index_pkg}]}", "${incompatible_error}", "${index_pkg}");
      "report_${index_pkg}" usebundle  => rudder_common_report_index("packageManagement", "result_error", "${trackingkey[${index_pkg}]}", "Post-modification script", "${package[${index_pkg}]}", "${incompatible_error}", "${index_pkg}");

    # The pass2 is not strictly necessary but prevent future issues if the behavior of pre-evaluation changes (because the evaluation of vars + classes takes 2 passes)
    pass2.!cfengine_3_6::
      # Package
      "package_${index_pkg}" usebundle => ${bundle_name}("${package[${index_pkg}]}", "${version[${index_pkg}]}", "${architecture[${index_pkg}]}", "${manager[${index_pkg}]}", "${state[${index_pkg}]}", "${manager_final_options[${index_pkg}]}");

      "report_${index_pkg}" usebundle => rudder_common_reports_generic_index("packageManagement", "${class_prefix_package[${index_pkg}]}", "${trackingkey[${index_pkg}]}", "Package", "${package[${index_pkg}]}", "${state_description[${index_pkg}]} of package ${package[${index_pkg}]}${architecture_description[${index_pkg}]}${version_description[${index_pkg}]}", "${index_pkg}");

      # Post-modification script
      "post_hook_${index_pkg}" usebundle  => command_execution("${posthook[${index_pkg}]}"),
                               ifvarclass => "posthook_specified_${index_pkg}.${class_prefix_package[${index_pkg}]}_repaired";

      "report_${index_pkg}" usebundle  => rudder_common_reports_generic_index("packageManagement", "${class_prefix_script[${index_pkg}]}", "${trackingkey[${index_pkg}]}", "Post-modification script", "${package[${index_pkg}]}", "Execution of the post-modification script", "${index_pkg}"),
                            ifvarclass => "${class_prefix_script[${index_pkg}]}_reached";

      "report_${index_pkg}" usebundle  => rudder_common_report_index("packageManagement", "result_na", "${trackingkey[${index_pkg}]}", "Post-modification script", "${package[${index_pkg}]}", "No post-modification script was set to run", "${index_pkg}"),
                            ifvarclass => "!${class_prefix_script[${index_pkg}]}_reached";

}

