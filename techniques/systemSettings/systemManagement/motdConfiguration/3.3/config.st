##############################################################################
# This Technique configures a machine MOTD. See metadata.xml for more details.
##############################################################################

bundle agent rudder_motd
{
  vars:
      "rudder_motd_service_name"        string => "MOTD";

      # Prefix for all the defined classes
      "rudder_motd_class_prefix"        string => "rudder_motd";

      "rudder_motd_config[payload]"     string => "&MOTD&";

      "rudder_motd_config[location]"    string => "&MOTD_LOCATION&";

      "rudder_motd_config[file_empty]"  string => "&MOTD_EMPTY&";

      "rudder_motd_config[banner]"      string => "&MOTD_BANNER&";

      "rudder_motd_config[trackingkey]" string => "&TRACKINGKEY&";

  methods:
    # Note:
    # The reporting is made on separate bundles to abstract the complexity
    # inherent to the normal ordering.
      "any" usebundle => rudder_motd_configuration("${rudder_motd_class_prefix}", "${rudder_motd_service_name}", "${rudder_motd_config[trackingkey]}", "rudder_motd.rudder_motd_config");
      "any" usebundle => rudder_motd_configuration_reporting("${rudder_motd_class_prefix}", "${rudder_motd_service_name}", "${rudder_motd_config[trackingkey]}");
}

