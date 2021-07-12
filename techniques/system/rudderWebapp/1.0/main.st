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
      # Check pgpass and db credentials
      "any" usebundle => system_compress_webapp_log;
      "any" usebundle => system_root_integrity_check("${trackingkey}", "${technique_name}");
      "any" usebundle => system_metrics_reporting("${trackingkey}", "${technique_name}");
      "any" usebundle => system_rudder_jetty_alive_check;
      "any" usebundle => system_rudder_webapp_properties;

      # Check that rudder-jetty is running and enabled
      "any" usebundle => _method_reporting_context("Rudder-jetty service", "Started");
      "any" usebundle => service_started("${rudder_webapp.service_name}");

      "any" usebundle => _method_reporting_context("Rudder-jetty service", "Enabled");
      "any" usebundle => service_enabled("${rudder_webapp.service_name}");
}
