# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: 2021-2026 Normation SAS

bundle agent package_management_&RudderUniqueID& {

  vars:
      &PACKAGE_LIST:{name |"package[&i0&]" string => "&name&";
}&

      &TRACKINGKEY:{uuid |"trackingkey[&i0&]" string => "&uuid&";
}&

      &PACKAGE_STATE:{state |"state[&i0&]" string => "&state&";
}&

      &PACKAGE_VERSION:{version |"version[&i0&]" string => "&version&";
}&

      &PACKAGE_ARCHITECTURE:{architecture |"architecture[&i0&]" string => "&architecture&";
}&

      &PACKAGE_MANAGER:{manager |"manager[&i0&]" string => "&manager&";
}&

      &PACKAGE_MANAGER_OPTIONS:{manager_options |"manager_options[&i0&]" string => "&manager_options&";
}&

      &PACKAGE_MANAGER_ALLOW_UNTRUSTED:{manager_allow_untrusted |"manager_allow_untrusted[&i0&]" string => "&manager_allow_untrusted&";
}&

&PACKAGE_POST_HOOK_COMMAND:{command |"posthook[&i0&]" string => "&command&";
}&

      "index_pkg" slist => getindices("package");
      "unique"   string => canonify("&RudderUniqueID&");

  classes:
      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";

  methods:
    pass3::
      "unique" usebundle => package_management_action_&RudderUniqueID&("${package[${index_pkg}]}",
                                                                       "${state[${index_pkg}]}",
                                                                       "${version[${index_pkg}]}",
                                                                       "${architecture[${index_pkg}]}",
                                                                       "${manager[${index_pkg}]}",
                                                                       "${manager_options[${index_pkg}]}",
                                                                       "${manager_allow_untrusted[${index_pkg}]}",
                                                                       "${posthook[${index_pkg}]}",
                                                                       "${trackingkey[${index_pkg}]}",
                                                                       "${unique}_${index_pkg}");
}

# Thin wrapper around package_state_options that adds:
#
# - update-only mode
# - post-hook
#
bundle agent package_management_action_&RudderUniqueID&(package, state, version, architecture, manager, manager_options, manager_allow_untrusted, posthook, trackingkey, unique) {
  vars:
    pass1::
      # Allow untrusted
      "manager_final_options" string => "-o Apt::Get::AllowUnauthenticated=true ${manager_options}",
                                  if => "apt_allow_untrusted";
      "manager_final_options" string => "${manager_options}",
                                  if => "!apt_allow_untrusted";

      # Translate technique state to ncf_package state
      "ncf_state" string => "${state}",
                      if => "!state_upgrade_only";
      "ncf_state" string => "present",
                      if => "state_upgrade_only";

      # define inner class prefixes
      "inner_check_prefix"  string => "${unique}_check";
      "inner_action_prefix" string => "${unique}_fallout";

  classes:
      "state_upgrade_only" expression => strcmp("${state}", "upgrade_only");

      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";

    pass1::
      "posthook_specified"            not => strcmp("${posthook}", "");
      "manager_specified"             not => strcmp("${manager}", "default");
      "allow_unstrusted"       expression => strcmp("${manager_allow_untrusted}", "true");
      "manager_apt"            expression => strcmp("${manager}", "apt");
      "apt_allow_untrusted"    expression => "allow_unstrusted.((debian.!manager_specified)|manager_apt)";
      "already_installed"      expression => "${inner_check_prefix}_kept";

  methods:
    pass2.!pass3::
      "${unique}" usebundle => _method_reporting_context_v4("Package", "${package}", "${inner_check_prefix}");
      "${unique}" usebundle => disable_reporting;

      # Force to audit mode to verify if packages are already installed (whatever their version is)
      "${unique}" usebundle => push_dry_run_mode("true");
      "${unique}" usebundle => package_state_options("${package}", "any", "${architecture}", "${manager}", "present", "${manager_final_options}"),
                         if => "state_upgrade_only";
      "${unique}" usebundle => pop_dry_run_mode();

    pass3::
      "${unique}" usebundle => _method_reporting_context_v4("Package", "${package}", "${inner_action_prefix}");
      "${unique}" usebundle => enable_reporting;

      # Package
      "${unique}" usebundle => package_state_options("${package}", "${version}", "${architecture}", "${manager}", "${ncf_state}", "${manager_final_options}"),
                         if => "!(state_upgrade_only.!already_installed)";

      # Report special case when the state is "upgrade only" and the package was not found on the machine
      "${unique}" usebundle => rudder_common_report("packageManagement", "result_na", "${trackingkey}", "Package", "${package}", "Upgrade only set for package ${package} but this package was not found on the machine."),
                         if => "state_upgrade_only.!already_installed";

      # Post-modification script
      "${unique}" usebundle => _method_reporting_context("Post-modification script", "${package}");

      "${unique}" usebundle => command_execution("${posthook}"),
                         if => "posthook_specified.${inner_action_prefix}_repaired";

      "${unique}" usebundle => rudder_common_report("packageManagement", "result_na", "${trackingkey}", "Post-modification script", "${package}", "No post-modification script was defined"),
                         if => "!posthook_specified";

      "${unique}" usebundle => rudder_common_report("packageManagement", "result_na", "${trackingkey}", "Post-modification script", "${package}", "Post-modification script was not to be run"),
                         if => "posthook_specified.!${inner_action_prefix}_repaired";
}