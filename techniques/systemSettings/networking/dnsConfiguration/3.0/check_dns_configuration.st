#####################################################################################
# Copyright 2011 Normation SAS
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

#Check the dns configuration, and correct it if required

bundle agent check_dns_configuration
{
  vars:

      "resolvers" slist => {&DNS_RESOLVERS: { "&it&" };separator=", "&};

      "searchlist"  slist => {&DNS_SEARCHLIST: { "&it&" };separator=", "&};

      "options"  slist => {&DNS_OPTIONS: { "&it&" };separator=", "&};

      "spaced_searchlist" string => join(" ", "searchlist");

      "spaced_options" string => join(" ", "options");

  classes:

                  # DNS Resolver edition ?
      "dns_resolver_edit" not => strcmp("&DNS_RESOLVERS_EDIT&","false");

                  # DNS Search suffix edition ?
      "dns_searchlist_edit" not => strcmp("&DNS_SEARCHLIST_EDIT&","false");

                  # DNS options edition ?
      "dns_options_edit" not => strcmp("&DNS_OPTIONS_EDIT&","false");

    any::
      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";

  files:

      "${sys.resolv}"
        create     => "true",
        edit_line  => resolv_edition("${this.spaced_searchlist}",  "@{this.resolvers}", "${this.spaced_options}"),
        edit_defaults => noempty_backup,
        classes    => kept_if_else("dns_kept", "dns_repaired", "cant_repair_dns");

  methods:

    pass3.dns_resolver_edit::
      "any" usebundle => rudder_common_report("ConfigureDNS", "log_debug", "&TRACKINGKEY&", "dnsConfiguration", "None", "Settings are to edit DNS resolvers");

    pass3.dns_searchlist_edit::
      "any" usebundle => rudder_common_report("ConfigureDNS", "log_debug", "&TRACKINGKEY&", "dnsConfiguration", "None", "Settings are to edit DNS searchlist");

    pass3.dns_repaired::
      "any" usebundle => rudder_common_report("ConfigureDNS", "result_repaired", "&TRACKINGKEY&", "dnsConfiguration", "None", "DNS settings were updated");

    pass3.cant_repair_dns::
      "any" usebundle => rudder_common_report("ConfigureDNS", "result_error", "&TRACKINGKEY&", "dnsConfiguration", "None", "Could not edit the ${sys.resolv} configuration file");

    pass3.dns_kept.!dns_repaired.!cant_repair_dns::
      "any" usebundle => rudder_common_report("ConfigureDNS", "result_success", "&TRACKINGKEY&", "dnsConfiguration", "None", "The DNS is correctly configured");

}

#######################################################
# Add lines in the file, formated for resolv.conf file
bundle edit_line resolv_edition(search, list, options)
{

  classes:

                        # DNS Resolver edition ?
      "dns_resolver_edit" not => strcmp("&DNS_RESOLVERS_EDIT&","false");

                        # DNS Search suffix edition ?
      "dns_searchlist_edit" not => strcmp("&DNS_SEARCHLIST_EDIT&","false");

                        # DNS options edition ?
      "dns_options_edit" not => strcmp("&DNS_OPTIONS_EDIT&","false");

  delete_lines:

    dns_searchlist_edit::
      "search.*";

    dns_resolver_edit::
      "nameserver.*";

    dns_options_edit::
      "options.*";

  insert_lines:
      "${rudder_parameters.rudder_file_edit_header}"
        location => start,
        insert_type => "preserve_block";

    dns_options_edit::
      "options ${options}";

    dns_searchlist_edit::
      "search ${search}";

    dns_resolver_edit::
      "nameserver ${list}";

}
