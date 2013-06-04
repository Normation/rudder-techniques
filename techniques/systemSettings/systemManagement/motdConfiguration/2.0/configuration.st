#####################################################################################
# Copyright 2011-2013 Normation SAS
#####################################################################################
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

##############################################################
# Sets the MOTD according to the value given in the Directive.
##############################################################

bundle agent rudder_motd_configuration(service_name)
{

  classes:
      "rudder_motd_absent"         not => fileexists("/etc/motd");

  vars:
      "rudder_motd_payload" string => "&MOTD&";
      "rudder_motd_empty"   string => "&MOTD_EMPTY&";

    debian::
      "rudder_motd_file"    slist => { "/etc/motd", "/etc/motd.tail" };

    !debian::
      "rudder_motd_file"    slist => { "/etc/motd" };

  files:
    # Set every MOTD file to the wanted value
    !windows::
      "${rudder_motd_file}"
        create        => "true",
        edit_defaults => rudder_empty_select("${rudder_motd_empty}"),
        perms         => mog("644", "root", "root"),
        edit_line     => insert_lines("${rudder_motd_payload}"),
        classes       => rudder_common_classes("rudder_motd_file_edition");

  methods:
    # Here, we will define reports for elements which only have a local visibility (like the MOTD file presence detection).
    !windows.rudder_motd_absent::
      "any"
        usebundle  => rudder_common_report("${service_name}", "log_repaired", "&TRACKINGKEY&", "MOTD Configuration", "None", "The ${service_name} file was absent, it will be created");

    windows::
      "any"
        usebundle  => rudder_common_report("${service_name}", "result_error", "&TRACKINGKEY&", "MOTD Configuration", "None", "This is a Windows machine. This Technique currently incompatible with it");

}

# The reporting is made on separate bundles to abstract the complexity
# inherent to the normal ordering.
bundle agent rudder_motd_configuration_reporting(service_name)
{
  methods:
      "any" usebundle => rudder_common_reports_generic("${service_name}", "rudder_motd_file_edition", "&TRACKINGKEY&", "MOTD Configuration", "None", "The ${service_name} file");
}
