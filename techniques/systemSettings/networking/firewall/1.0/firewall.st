# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: 2021 Normation SAS

# Here we have our firewall configuration (iptables or nftables)
# But format may not be exactly what the output of iptables-save or nft export.
# What we will do it to maintain an export from a previous run to be able to compare
# with current export and detect changes.
# This way we will be able to report config diffs and fix the config when necessary.

bundle agent rudder_firewall {
  vars:
      "config"    string => "&FIREWALL_CONF&";
      "firewall"  string => "rudder_firewall_&FIREWALL_IMPL&";
      "posthook"  string => "&FIREWALL_POST_HOOK_COMMAND&";
      "reference" string => "/var/rudder/tmp/firewall.ref";

  methods:
      "any" usebundle => rudder_set_force_component_none("true");
      "en1" usebundle => enable_reporting;
      # Package
      "any" usebundle => _method_reporting_context("Installation", "None");
      "any" usebundle => package_present("${${firewall}.package}", "", "", "");
      # Configuration
      "any" usebundle => _method_reporting_context("Firewall configuration", "None");
      "any" usebundle => file_from_string_mustache("${${firewall}.conf_pre}${config}", "${${firewall}.file}");
      "en2" usebundle => disable_reporting;
      "any" usebundle => condition_from_expression("rudder_firewall_broken_template", "true"),
                   if => canonify("file_from_string_mustache_${${firewall}.file}_error");
      "en3" usebundle => enable_reporting;
    rudder_firewall_broken_template::
      "any" usebundle => rudder_common_report("firewall", "result_na", "&TRACKINGKEY&", "Firewall changes", "None", "Configuration is broken, skipping changes check");
      "any" usebundle => rudder_common_report("firewall", "result_na", "&TRACKINGKEY&", "Service activation", "None", "Configuration is broken, skipping service activation");
      "any" usebundle => rudder_common_report("firewall", "result_na", "&TRACKINGKEY&", "Service start", "None", "Configuration is broken, skipping service start");
    !rudder_firewall_broken_template::
      # Changes
      "any" usebundle => _method_reporting_context("Firewall changes", "None");
      "any" usebundle => variable_string_from_file("firewall_technique", "firewall_conf_ref", "${reference}");
      "en4" usebundle => disable_reporting;
      "any" usebundle => variable_string_from_command("firewall_technique", "firewall_conf", "${${firewall}.dump_cmd}");
      "any" usebundle => rudder_firewall_condition_from_string_compare("rudder_firewall_technique_conf", "${firewall_technique.firewall_conf_ref}", "${firewall_technique.firewall_conf}
");
      "any" usebundle => rudder_common_report("firewall", "log_warn", "&TRACKINGKEY&", "Load configuration", "None", "Firewall configuration was modified since previous agent run"),
                   if => canonify("variable_string_from_file_${reference}_ok.rudder_firewall_technique_conf_false");
      "any" usebundle => condition_from_expression("rudder_firewall_conf_repaired", "true"),
                   # needed because we cannot use the expression in a canonify directly
                   if => canonify("file_from_string_mustache_${${firewall}.file}_repaired");
      "any" usebundle => condition_from_expression("rudder_firewall_reload", "rudder_firewall_conf_repaired_true|rudder_firewall_technique_conf_false");
      # Service
      "en5" usebundle => enable_reporting;
      "any" usebundle => _method_reporting_context("Service activation", "None");
      "any" usebundle => service_enabled("${${firewall}.service}");
      "any" usebundle => _method_reporting_context("Service start", "None");
      "any" usebundle => service_started("${${firewall}.service}");
      # Reload
    rudder_firewall_reload_true::
      "any" usebundle => _method_reporting_context("Load configuration", "None");
      "any" usebundle => service_reload("${${firewall}.service}");
      "en6" usebundle => disable_reporting;
      # Dump just after change (not totally atomic here)
      "any" usebundle => variable_string_from_command("firewall_technique", "current_config_new", "${${firewall}.dump_cmd}");
      "any" usebundle => file_content("${reference}", "${firewall_technique.current_config_new}", "true");
      "en7" usebundle => enable_reporting;
    rudder_firewall_broken_template|rudder_firewall_reload_false::
      "any" usebundle => rudder_common_report("firewall", "result_na", "&TRACKINGKEY&", "Load configuration", "None", "Firewall configuration did not require modification");
    any::
      # Post-hook
      "any" usebundle => rudder_firewall_condition_from_string_compare("rudder_firewall_disable_posthook", "${posthook}", "");
    rudder_firewall_reload_true.rudder_firewall_disable_posthook_false::
      "any" usebundle => _method_reporting_context("Post-modification script", "None");
      "any" usebundle => command_execution("${posthook}");
    rudder_firewall_broken_template|rudder_firewall_reload_false|rudder_firewall_disable_posthook_true::
      "any" usebundle => rudder_common_report("firewall", "result_na", "&TRACKINGKEY&", "Post-modification script", "None", "Post-hook command was not applicable");
    any::
      "any" usebundle => rudder_set_force_component_none("false");
}

# Uses the systemd service, compatible with recent debian, rhel and derivatives
bundle common rudder_firewall_nftables {
  vars:
      "package"  string => "nftables";
      "service"  string => "nftables";
      "dump_cmd" string => "nft --stateless list ruleset";
    redhat::
      "file"     string => "/etc/sysconfig/nftables.conf";
      # integrated to the systemd service
      "conf_pre" string => "";
    debian::
      "file"     string => "/etc/nftables.conf";
      # in the beginning of the conf
      "conf_pre" string => "flush ruleset${const.n}";
}

bundle agent rudder_firewall_condition_from_string_compare(condition_prefix, string1, string2) {
  classes:
      "${condition_prefix}_reached"   scope => "namespace";
      "${condition_prefix}_true" expression => strcmp("${string1}", "${string2}"), scope => "namespace";
      "${condition_prefix}_false"       not => "${condition_prefix}_true", scope => "namespace";
}


