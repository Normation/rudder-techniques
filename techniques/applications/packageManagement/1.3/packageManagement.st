# Warning: The content of this technique is very close to the content of the package_state() bundle in ncf
# particularly the log message building. All changes made here should also be done in ncf too.

bundle agent package_management_&RudderUniqueID& {

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

      &PACKAGE_VERSION_SPECIFIC:{version |"version[&i0&]" string => "&version&", ifvarclass => "version_specified_&i0&";
}&

      &PACKAGE_ARCHITECTURE:{architecture |"architecture[&i0&]" string => "&architecture&";
}&
      &PACKAGE_ARCHITECTURE_SPECIFIC:{architecture |"architecture[&i0&]" string => "&architecture&", ifvarclass => "architecture_specified_&i0&";
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


      # Build string vars used for reporting

      # Architecture
      "architecture_description[${index_pkg}]" string     => " for ${architecture[${index_pkg}]} architecture ",
                                               ifvarclass => "architecture_specified_${index_pkg}";
      "architecture_description[${index_pkg}]" string     => " ",
                                               ifvarclass => "!architecture_specified_${index_pkg}";

      # Allow untrusted
      "manager_final_options[${index_pkg}]" string => "-o Apt::Get::AllowUnauthenticated=true ${manager_options[${index_pkg}]}",
                                        ifvarclass => "apt_allow_untrusted_${index_pkg}";
      "manager_final_options[${index_pkg}]" string => "${manager_options[${index_pkg}]}",
                                        ifvarclass => "!apt_allow_untrusted_${index_pkg}";

      # Name of the ncf bundle. We use a variable to avoid breaking the syntax if the bundle does not exist.
      "bundle_name" string => "package_state_options";


    pass1::
      # Translate technique state to ncf_package state
      "ncf_state[${index_pkg}]" string => "${state[${index_pkg}]}",
                            ifvarclass => "!state_upgrade_only_${index_pkg})";
      "ncf_state[${index_pkg}]" string => "present",
                            ifvarclass => "state_upgrade_only_${index_pkg})";

      # Build class prefixes with canonified variables
      "class_prefix_package[${index_pkg}]" string => canonify("package_${state[${index_pkg}]}_${package[${index_pkg}]}");
      "class_prefix_script[${index_pkg}]" string => canonify("command_execution_${posthook[${index_pkg}]}");

      # define inner class prefix
      "full_inner_class_prefix_${index_pkg}" string => canonify("package_state_options_${package[${index_pkg}]}_${version[${index_pkg}]}_${architecture[${index_pkg}]}_${manager[${index_pkg}]}_${ncf_state[${index_pkg}]}_${manager_final_options[${index_pkg}]}");
      "inner_class_prefix_${index_pkg}"      string => string_head("${full_inner_class_prefix_${index_pkg}}", "1000");

      # define inner class prefix for package "already" installed status
      "full_inner_already_installed_class_prefix_${index_pkg}" string => canonify("package_state_options_${package[${index_pkg}]}_any_${architecture[${index_pkg}]}_${manager[${index_pkg}]}_present_${manager_final_options[${index_pkg}]}");
      "inner_already_installed_class_prefix_${index_pkg}"      string => string_head("${full_inner_already_installed_class_prefix_${index_pkg}}", "1000");


      # State
      "state_description[${index_pkg}]" string     => "Presence",
                                        ifvarclass => "state_present_${index_pkg}";
      "state_description[${index_pkg}]" string     => "Upgrade",
                                        ifvarclass => "state_upgrade_only_${index_pkg}";
      "state_description[${index_pkg}]" string     => "Absence",
                                        ifvarclass => "!(state_present_${index_pkg}|state_upgrade_only_${index_pkg})";

      # Version
      "version_description[${index_pkg}]" string     => "in latest available version",
                                          ifvarclass => "version_latest_${index_pkg}.(state_present_${index_pkg}|state_upgrade_only_${index_pkg})";
      "version_description[${index_pkg}]" string     => "in any version",
                                          ifvarclass => "!version_latest_${index_pkg}.!version_specified_${index_pkg}";
      "version_description[${index_pkg}]" string     => "in version ${version[${index_pkg}]}",
                                          ifvarclass => "version_specified_${index_pkg}";
      # Non compatibility check is done by the "package_state_options" this is just to inform the user
      "version_description[${index_pkg}]" string     => "in latest available version is not supported and",
                                          ifvarclass => "version_latest_${index_pkg}.!(state_present_${index_pkg}|state_upgrade_only_${index_pkg})";


  classes:
    any::
      "state_upgrade_only_${index_pkg}"     expression => strcmp("${state[${index_pkg}]}", "upgrade_only");
      "state_present_${index_pkg}"          expression => strcmp("${state[${index_pkg}]}", "present");

      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";

    pass1::
      # This class is different from the one in ncf (where a version number and latest are considered "specified")
      "version_specified_${index_pkg}"      expression => strcmp("${version[${index_pkg}]}", "specific");
      "architecture_specified_${index_pkg}" expression => strcmp("${architecture[${index_pkg}]}", "specific");
      "posthook_specified_${index_pkg}"            not => strcmp("${posthook[${index_pkg}]}", "");
      "manager_specified_${index_pkg}"             not => strcmp("${manager[${index_pkg}]}", "default");
      "version_latest_${index_pkg}"         expression => strcmp("${version[${index_pkg}]}", "latest");
      "allow_unstrusted_${index_pkg}"       expression => strcmp("${manager_allow_untrusted[${index_pkg}]}", "true");
      "manager_apt_${index_pkg}"            expression => strcmp("${manager[${index_pkg}]}", "apt");
      "apt_allow_untrusted_${index_pkg}"    expression => "allow_unstrusted_${index_pkg}.((debian.!manager_specified_${index_pkg})|manager_apt_${index_pkg})";
      "already_installed_${index_pkg}"      expression => "${inner_already_installed_class_prefix_${index_pkg}}_kept";

  methods:
    pass1::
      # Force to audit mode to verify if packages are already installed (whatever their version is)
      "force_dry_run_mode"             usebundle => push_dry_run_mode("true");
      "already_installed_${index_pkg}" usebundle => package_state_options("${package[${index_pkg}]}", "any", "${architecture[${index_pkg}]}", "${manager[${index_pkg}]}", "present", "${manager_final_options[${index_pkg}]}"),
        ifvarclass => "state_upgrade_only_${index_pkg}";
      "remove_force_dry_run_mode"      usebundle => pop_dry_run_mode();


    # The pass2 is not strictly necessary but prevent future issues if the behavior of pre-evaluation changes (because the evaluation of vars + classes takes 2 passes)
    pass2::
      # Package
      "package_${index_pkg}" usebundle => package_state_options("${package[${index_pkg}]}", "${version[${index_pkg}]}", "${architecture[${index_pkg}]}", "${manager[${index_pkg}]}", "${ncf_state[${index_pkg}]}", "${manager_final_options[${index_pkg}]}"),
                            ifvarclass => "!(state_upgrade_only_${index_pkg}.!already_installed_${index_pkg})";

      "report_${index_pkg}" usebundle => rudder_common_reports_generic_index("packageManagement", "${inner_class_prefix_${index_pkg}}", "${trackingkey[${index_pkg}]}", "Package", "${package[${index_pkg}]}", "${state_description[${index_pkg}]} of package ${package[${index_pkg}]}${architecture_description[${index_pkg}]}${version_description[${index_pkg}]}", "${index_pkg}"),
                           ifvarclass => "!(state_upgrade_only_${index_pkg}.!already_installed_${index_pkg})";

      # Report special case when the state is "upgrade only" and the package was not found on the machine
      "report_na_${index_pkg}" usebundle => rudder_common_report_index("packageManagement", "result_na", "${trackingkey[${index_pkg}]}", "Package", "${package[${index_pkg}]}", "Upgrade only set for package ${package[${index_pkg}]} but this package was not found on the machine.", "${index_pkg}"),
                              ifvarclass => "state_upgrade_only_${index_pkg}.!already_installed_${index_pkg}";

      # Post-modification script
      "post_hook_${index_pkg}"  usebundle => command_execution("${posthook[${index_pkg}]}"),
                               ifvarclass => "posthook_specified_${index_pkg}.${inner_class_prefix_${index_pkg}}_repaired";

      "report_${index_pkg}"     usebundle => rudder_common_report("packageManagement", "result_na", "${trackingkey[${index_pkg}]}", "Post-modification script", "${package[${index_pkg}]}", "No post-modification script was defined"),
                               ifvarclass => "!posthook_specified_${index_pkg}";

      "report_${index_pkg}"     usebundle => rudder_common_report("packageManagement", "result_na", "${trackingkey[${index_pkg}]}", "Post-modification script", "${package[${index_pkg}]}", "Post-modification script was not to be run"),
                               ifvarclass => "posthook_specified_${index_pkg}.!${inner_class_prefix_${index_pkg}}_repaired";

      "report_${index_pkg}"     usebundle => rudder_common_reports_generic_index("packageManagement", "${class_prefix_script[${index_pkg}]}", "${trackingkey[${index_pkg}]}", "Post-modification script", "${package[${index_pkg}]}", "Execution of the post-modification script", "${index_pkg}"),
                               ifvarclass => "posthook_specified_${index_pkg}.${inner_class_prefix_${index_pkg}}_repaired";
}

