# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: 2021 Normation SAS

##############################################################
# Sets the MOTD according to the value given in the Directive.
##############################################################

bundle agent rudder_motd_configuration(class_prefix, service_name, trackingkey, params)
{
  vars:
      "rudder_motd_payload"     string => "${${params}[payload]}";
      "rudder_motd_location"    string => "${${params}[location]}";
      "rudder_motd_empty"       string => "${${params}[file_empty]}";

    aix::
      "rudder_motd_group"       string => "bin";
    !aix::
      "rudder_motd_group"       string => "root";

    debian::
      "rudder_motd_file"         slist => { "/etc/motd", "/etc/motd.tail" };
    !debian::
      "rudder_motd_file"         slist => { "/etc/motd" };

    pass2.set_banner::
      "banner_files"             slist => { "/etc/issue", "/etc/issue.net" };

    pass2::
      "rudder_motd_issue_files"  slist => { @{rudder_motd_file}, @{banner_files} },
                                policy => "ifdefined";


  classes:
      "rudder_motd_absent"         not => fileexists("/etc/motd");

      "set_banner"          expression => strcmp("true", "${${params}[banner]}");

      "pass2"               expression => "pass1";
      "pass1"               expression => "any";

  files:
    # Set every MOTD file to the wanted value
    pass2::
      "${rudder_motd_issue_files}"
        create        => "true",
        edit_defaults => rudder_empty_select("${rudder_motd_empty}"),
        perms         => mog("644", "root", "${rudder_motd_group}"),
        edit_line     => rudder_line_insertion("${rudder_motd_payload}", "${rudder_motd_location}"),
        classes       => classes_generic("${class_prefix}_file_edition");

  methods:
    # Here, we will define reports for elements which only have a local visibility (like the MOTD file presence detection).
    pass2.rudder_motd_absent::
      "any"
        usebundle  => rudder_common_report("${service_name}", "log_repaired", "${trackingkey}", "MOTD Configuration", "None", "The ${service_name} file was absent, it will be created");
}

# The reporting is made on separate bundles to abstract the complexity
# inherent to the normal ordering.
bundle agent rudder_motd_configuration_reporting(class_prefix, service_name, trackingkey)
{
  methods:
      "any" usebundle => rudder_common_reports_generic("${service_name}", "${class_prefix}_file_edition", "${trackingkey}", "MOTD Configuration", "None", "The ${service_name} file");
}
