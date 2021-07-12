####################################################################################
# Copyright 2021 Normation SAS
####################################################################################
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

  methods:
      # Force certificates and permissions
      "any" usebundle => apache_cert("${trackingkey}", "${technique_name}");

      # Force allowed networks
      "any" usebundle => system_rudder_apache_networks_configuration;

      # Force webdav user/password
      "any" usebundle => system_rudder_apache_webdav_configuration;

      # Configure log rotation
      "any" usebundle => system_apache_logrotate;

      # Check that apache is running and enabled
      "any" usebundle => _method_reporting_context("Apache service", "Started");
      "any" usebundle => service_started("${rudder_apache.service_name}");

      "any" usebundle => _method_reporting_context("Apache service", "Enabled");
      "any" usebundle => service_enabled("${rudder_apache.service_name}");
}
