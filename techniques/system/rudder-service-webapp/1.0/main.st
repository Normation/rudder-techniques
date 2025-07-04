# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: 2021 Normation SAS

bundle common rudder_webapp {
  vars:
    "service_name" string => "rudder-jetty";
}

bundle agent system_rudder_webapp {
  vars:
    any::
      "trackingkey"        string => "&TRACKINGKEY&";
      "technique_name"     string => "Rudder Webapp";

  methods:
      # Generate ncf hash file
      "any" usebundle => update_ncf_hash;
      # Generate ncf archive files
      "any" usebundle => update_archives;
      # Check pgpass and db credentials
      "any" usebundle => system_compress_webapp_log;
      "any" usebundle => system_root_integrity_check("${trackingkey}", "${technique_name}");
      "any" usebundle => system_rudder_jetty_alive_check;
      "any" usebundle => system_rudder_webapp_properties;

      # Check that rudder-jetty is running and enabled
    !is_rudder_bootstrap::
      "any" usebundle => _method_reporting_context_v4("Rudder-jetty service", "Started", "jetty_started");
      "any" usebundle => service_started("${rudder_webapp.service_name}");
    any::
      "any" usebundle => _method_reporting_context_v4("Rudder-jetty service", "Enabled", "jetty_enabled");
      "any" usebundle => service_enabled("${rudder_webapp.service_name}");
}
