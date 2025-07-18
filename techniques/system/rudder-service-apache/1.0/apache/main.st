# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: 2021 Normation SAS

bundle common rudder_apache {
  vars:
    any::
      "service_name"   string => "apache2";
      "group_name"     string => "www";
    redhat::
      "service_name"   string => "httpd";
      "group_name"     string => "apache";
    debian::
      "group_name"     string => "www-data";
}

bundle agent system_rudder_apache_configuration {
  vars:
      "trackingkey"     string => "&TRACKINGKEY&";
      "technique_name"  string => "Rudder apache";
      "https_port"      string => "&HTTPS_POLICY_DISTRIBUTION_PORT&";

  methods:
      # Force certificates and permissions
      "any" usebundle => apache_cert("${trackingkey}", "${technique_name}");

      # Force allowed networks
      "any" usebundle => system_rudder_apache_networks_configuration;

      # Force webdav user/password
      "any" usebundle => system_rudder_apache_webdav_configuration("${trackingkey}", "${technique_name}");

      # Configure log rotation
      "any" usebundle => system_apache_logrotate;

      # Check that apache is running and enabled
      "any" usebundle => _method_reporting_context_v4("Apache service", "Started", "apache_started");
      "any" usebundle => service_started("${rudder_apache.service_name}");

      "any" usebundle => _method_reporting_context_v4("Apache service", "Enabled", "apache_enabled");
      "any" usebundle => service_enabled("${rudder_apache.service_name}");
}
