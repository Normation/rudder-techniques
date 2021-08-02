# Must be run after the others components
bundle agent system_reload_rudder_services {
  vars:
      "trackingkey"         string => "&TRACKINGKEY&";
      "jetty_service_name"  string => "${rudder_webapp.service_name}";
      "apache_service_name" string => "${rudder_apache.service_name}";
      "relayd_service_name" string => "${rudder_relayd.service_name}";
      "slapd_service_name"  string => "${rudder_slapd.service_name}";

    any::
      "jetty_prefix"        string => canonify("service_restart_${jetty_service_name}");
      "apache_prefix"       string => canonify("service_reload_${apache_service_name}");
      "relayd_prefix"       string => canonify("service_restart_${relayd_service_name}");
      "slapd_prefix"        string => canonify("service_restart_${slapd_service_name}");


      "prefixes"             slist => {
                                        "${jetty_prefix}",
                                        "${apache_prefix}",
                                        "${relayd_prefix}",
                                        "${slapd_prefix}"
                                      };

      "technique_name"      string => "Server common";
      "component_name"      string => "Reload Rudder services";

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
      "any" usebundle => _method_reporting_context("${component_name}", "None");
    rudder_server_system_restart_slapd::
      "any" usebundle => service_restart("${slapd_service_name}");
    rudder_server_system_restart_jetty::
      "any" usebundle => service_restart("${jetty_service_name}");
    rudder_server_system_restart_apache::
      "any" usebundle => service_reload("${apache_service_name}");
    rudder_server_system_restart_relayd::
      "any" usebundle => service_restart("${relayd_service_name}");
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