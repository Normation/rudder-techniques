bundle agent rudder_reverse_proxy_apache_installation(service_name, internal_name, params) {
  vars:

    redhat::

      "apache_package_name" string => "httpd";

    !redhat::

      "apache_package_name" string => "apache2";

  classes:

    "rudder_reverse_proxy_apache_install_package" expression => strcmp("${${params}[package_install]}", "true");

  packages:

    # Too bad SuSE 10 uses a different bundle, things would be so simple if it was not the case...
    SuSE_10.rudder_reverse_proxy_apache_install_package::

      "${apache_package_name}"
        package_policy  => "add",
        package_method  => rudder_rug,
        classes         => classes_generic("rudder_reverse_proxy_apache_package"),
        comment         => "Installing apache using the rug interface";

    !SuSE_10.rudder_reverse_proxy_apache_install_package::

      "${apache_package_name}"
        package_policy  => "add",
        package_method  => generic,
        classes         => classes_generic("rudder_reverse_proxy_apache_package"),
        comment         => "Installing apache using generic interface";

}

# The reporting is made on separate bundles to abstract the complexity
# inherent to the normal ordering.
bundle agent rudder_reverse_proxy_apache_installation_reporting(service_name, internal_name, params) {
  classes:

    "rudder_reverse_proxy_apache_install_package" expression => strcmp("${${params}[package_install]}", "true");

  methods:
    "any" usebundle => rudder_common_reports_generic("${internal_name}", "rudder_reverse_proxy_apache_package", "${${params}[tracking_key]}", "Installation parameters", "None", "The ${service_name} package installation");

    # Special case if no installation is needed
    "any"
      usebundle  => rudder_common_report("${internal_name}", "result_success", "${${params}[tracking_key]}", "Installation parameters", "None", "${service_name} installation is not required. Skipping..."),
      ifvarclass => "!rudder_reverse_proxy_apache_install_package";

}
