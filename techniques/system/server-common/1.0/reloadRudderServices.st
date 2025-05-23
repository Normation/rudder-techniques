# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: 2021 Normation SAS

# Must be run after the others components
bundle agent system_reload_rudder_services {
  vars:
      "trackingkey"         string => "&TRACKINGKEY&";
      "jetty_service_name"  string => "${rudder_webapp.service_name}";
      "apache_service_name" string => "${rudder_apache.service_name}";
      "relayd_service_name" string => "${rudder_relayd.service_name}";
      "slapd_service_name"  string => "${rudder_slapd.service_name}";
      "cf_serverd_service_name" string => "${system_common.cf_serverd_service_name}";

      "jetty_prefix"          string => canonify("service_restart_${jetty_service_name}");
      "apache_reload_prefix"  string => canonify("service_reload_${apache_service_name}");
      "apache_restart_prefix" string => canonify("service_restart_${apache_service_name}");
      "relayd_reload_prefix"  string => canonify("service_reload_${relayd_service_name}");
      "relayd_restart_prefix" string => canonify("service_restart_${relayd_service_name}");
      "cfserverd_reload_or_restart_prefix"
                              string => canonify("service_action_${cf_serverd_service_name}");
      "slapd_prefix"          string => canonify("service_restart_${slapd_service_name}");

      "prefixes"              slist => {
                                         "${jetty_prefix}",
                                         "${apache_reload_prefix}",
                                         "${apache_restart_prefix}",
                                         "${relayd_reload_prefix}",
                                         "${relayd_restart_prefix}",
                                         "${cfserverd_reload_or_restart_prefix}",
                                         "${slapd_prefix}"
                                       };

      "technique_name"       string => "Server common";
      "component_name"       string => "Reload Rudder services";

  classes:
      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";

    pass3::
      "restart_rudder_services_error"    expression => "${prefixes}_error";
    pass3.!restart_rudder_services_error::
      "restart_rudder_services_repaired" expression => "${prefixes}_repaired";
    pass3.!restart_rudder_services_error.!restart_rudder_services_repaired::
      "restart_rudder_services_na"       expression => "any";

  methods:
      "any" usebundle => disable_reporting;
      "any" usebundle => _method_reporting_context_v4("${component_name}", "None", "restart_rudder_services");
    rudder_server_system_restart_slapd::
      "any" usebundle => service_restart("${slapd_service_name}");
    rudder_server_system_restart_jetty::
      "any" usebundle => service_restart("${jetty_service_name}");
    rudder_server_system_restart_apache::
      "any" usebundle => service_restart("${apache_service_name}");
    rudder_server_system_reload_apache.!rudder_server_system_restart_apache::
      "any" usebundle => service_reload("${apache_service_name}");
    rudder_server_system_reload_relayd.!rudder_server_system_restart_relayd::
      "any" usebundle => service_reload("${relayd_service_name}");
    rudder_server_system_restart_relayd::
      "any" usebundle => service_restart("${relayd_service_name}");
    rudder_server_system_reload_cf_serverd::
      "any" usebundle => service_action("${cf_serverd_service_name}", "reload-or-restart");
    pass3::
      "any" usebundle => enable_reporting;

      # Reporting
      "report_error"   usebundle  => rudder_common_report("${technique_name}", "result_error",    "${trackingkey}", "${component_name}", "None", "Failed to restart the rudder services"),
                       ifvarclass => "restart_rudder_services_error";
      "report_repaired" usebundle => rudder_common_report("${technique_name}", "result_repaired", "${trackingkey}", "${component_name}", "None", "Rudder services were restarted"),
                       ifvarclass => "restart_rudder_services_repaired";
      "report_na"      usebundle  => rudder_common_report("${technique_name}", "result_na",       "${trackingkey}", "${component_name}", "None", "No Rudder services restart needed"),
                       ifvarclass => "restart_rudder_services_na";
}
