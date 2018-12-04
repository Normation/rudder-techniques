#####################################################################################
# Copyright 2018 Normation SAS
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


bundle agent snmp {

  vars:
      "unparsed_sources" string => "&SNMP_AUTHORIZED_SOURCES&";
      "sources" slist => splitstring("${unparsed_sources}",",","99999999999");
      "sources" slist => {""},
        ifvarclass => "accept_all_sources";

      &SNMP_COMMUNITY_ACL:{acl | "acl[&i&]" string => "&acl&";
      }&
      &SNMP_COMMUNITY_NAME:{name | "name[&i&]" string => "&name&";
      }&

      "snmp_package" string  => "snmpd";
      "snmp_service" string  => "snmpd";
      "canonified_snmp_package" string => canonify("${snmp_package}");
      "canonified_snmp_service" string => canonify("${snmp_service}");

      "snmp_conf_file" string => "/etc/snmp/snmpd.conf";
      "canonified_snmp_conf_file" string => canonify("${snmp_conf_file}");

      pass2:: 
        ## Create the section flags
        "rudder_section_start_flag" string => "######## Communities managed by Rudder ########";
        "rudder_section_end_flag" string => "########              END              ########";
        ## Create the communities block
        "community_indice" slist => getindices("name");
        "lines[${sources}_${community_indice}]" string => "${acl[${community_indice}]} ${name[${community_indice}]} ${sources}";
        "communities" slist => getvalues("lines");
        "block" string => join("
", communities);

        ## Classes prefixes
        "package_prefix" string => "package_install_${canonified_snmp_package}";
        "service_reload_prefix" string => "service_reload_${canonified_snmp_service}";
        "service_running_prefix" string => "service_ensure_running_${canonified_snmp_service}";
        "block_prefix" string => "file_block_present_in_section_${canonified_snmp_conf_file}";


  classes:
      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";
      "accept_all_sources" expression => strcmp("${unparsed_sources}", "any");

      pass3::
        "report_repaired" expression => "${block_prefix}_repaired|${service_reload_prefix}_repaired|${service_running_prefix}_repaired";
        "report_error" expression => "${block_prefix}_error|${service_reload_prefix}_error|${service_running_prefix}_error";

  methods:
    # SNMP installation
    "any" usebundle => package_install("${snmp_package}");
    "any" usebundle => rudder_common_reports_generic("SNMP installation", "package_install_${canonified_snmp_package}", "&TRACKINGKEY&", "SNMP installation", "None", "Installation of the SNMP agent package");

    # SNMP Community Configuration Section
    pass2::
      "any" usebundle => file_block_present_in_section("${snmp_conf_file}", "${rudder_section_start_flag}",${rudder_section_end_flag}, "${block}");
    pass3::
      "any" usebundle => service_reload("${snmp_service}"),
        ifvarclass => "${block_prefix}_repaired";
      "any" usebundle => service_ensure_running("${snmp_service}");

    # Reports are dubbed since communities and authorized sources are linked (same reports)
    pass3.report_error::
      "error"  usebundle => rudder_common_report("SNMP configuration", "result_error", "&TRACKINGKEY&", "Authorized Servers", "None", "Authorized SNMP sources");
      "error"  usebundle => rudder_common_report("SNMP configuration", "result_error", "&TRACKINGKEY&", "Communities configuration", "None", "Communities configuration");
    pass3.report_repaired::
      "repair" usebundle => rudder_common_report("SNMP configuration", "result_repaired",  "&TRACKINGKEY&", "Authorized Servers", "None", "Authorized SNMP sources");
      "repair" usebundle => rudder_common_report("SNMP configuration", "result_repaired",  "&TRACKINGKEY&", "Communities configuration", "None", "Communities configuration");
    pass3.!report_repaired.!report_error::

      "success" usebundle => rudder_common_report("SNMP configuration", "result_success",  "&TRACKINGKEY&", "Authorized Servers", "None", "Authorized SNMP sources"),
        ifvarclass => "!${service_reload_prefix}_reached";

      "success" usebundle => rudder_common_report("SNMP configuration", "result_success",  "&TRACKINGKEY&", "Communities configuration", "None", "Communities configuration"),
        ifvarclass => "!${service_reload_prefix}_reached";

      "error"  usebundle => rudder_common_report("SNMP configuration", "result_error", "&TRACKINGKEY&", "Authorized Servers", "None", "Something went wrong while configuring SNMP authorized sources"),
        ifvarclass => "${service_reload_prefix}_reached";
      "error"  usebundle => rudder_common_report("SNMP configuration", "result_error", "&TRACKINGKEY&", "Communities configuration", "None", "Something went wrong while configuring SNMP communities"),
        ifvarclass => "${service_reload_prefix}_reached";

}

