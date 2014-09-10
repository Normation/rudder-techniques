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
#CAUTION : the loop for windows does not work well, a bug is opened (#82)

bundle agent check_dns_configuration
{
  vars:

      "resolvers" slist => {&DNS_RESOLVERS: { "&it&" };separator=", "&};

      "searchlist"  slist => {&DNS_SEARCHLIST: { "&it&" };separator=", "&};

      "options"  slist => {&DNS_OPTIONS: { "&it&" };separator=", "&};

      "spaced_searchlist" string => join(" ", "searchlist");

      "spaced_options" string => join(" ", "options");

&if(NOVA)&
    windows::
      "searchkey" string => join("\,", searchlist);
      "resolvkey" string => join("\,", resolvers);
      "adapters" string => execresult("\"${g.rudder_sbin}\registrydns.bat\"", "noshell"),
        comment => "Fetching all the adapter";
      "adapterslist" slist => splitstring("${adapters}", ";", "15");
&endif&

  classes:

                  # DNS Resolver edition ?
      "dns_resolver_edit" not => strcmp("&DNS_RESOLVERS_EDIT&","false");

                  # DNS Search suffix edition ?
      "dns_searchlist_edit" not => strcmp("&DNS_SEARCHLIST_EDIT&","false");

                  # DNS options edition ?
      "dns_options_edit" not => strcmp("&DNS_OPTIONS_EDIT&","false");

  files:

    linux::

      "${sys.resolv}"
        create     => "true",
        edit_line  => resolv_edition("${this.spaced_searchlist}",  "@{this.resolvers}", "${this.spaced_options}"),
        edit_defaults => noempty_backup,
        classes    => kept_if_else("dns_kept", "dns_repaired", "cant_repair_dns");


&if(NOVA)&
  methods:
    windows.dns_resolver_edit::
      "any" usebundle => checkDNS(${adapterslist}, ${resolvkey});

  databases:

    windows.dns_resolver_edit::
      "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
        database_operation => "verify",
        database_type => "ms_registry",
        database_rows => { "NameServer,REG_SZ,${resolvkey}"},
        comment => "Set the top level resolver",
        classes => kept_if_else("dns_resolver_kept", "dns_repaired_resolver", "cant_repair_dns_resolver");

    windows.dns_searchlist_edit::
      "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
        database_operation => "verify",
        database_type => "ms_registry",
        database_rows => { "SearchList,REG_SZ,${searchkey}"},
        comment => "Set the search list",
        classes => kept_if_else("dns_searchlist_kept", "dns_repaired_searchlist", "cant_repair_dns_searchlist");
&endif&

  reports:

    dns_resolver_edit::
      "@@ConfigureDNS@@log_debug@@&TRACKINGKEY&@@dnsConfiguration@@None@@${g.execRun}##${g.uuid}@#Settings are to edit DNS resolvers";

    dns_searchlist_edit::
      "@@ConfigureDNS@@log_debug@@&TRACKINGKEY&@@dnsConfiguration@@None@@${g.execRun}##${g.uuid}@#Settings are to edit DNS searchlist";

    (linux.dns_repaired)::
      "@@ConfigureDNS@@result_repaired@@&TRACKINGKEY&@@dnsConfiguration@@None@@${g.execRun}##${g.uuid}@#DNS settings were updated";

    windows.((dns_repaired_resolver.!cant_repair_dns_resolver.dns_resolver_edit)|(dns_repaired_searchlist.!cant_repair_dns_searchlist.dns_searchlist_edit))::
      "@@ConfigureDNS@@result_repaired@@&TRACKINGKEY&@@dnsConfiguration@@None@@${g.execRun}##${g.uuid}@#DNS settings were updated";

    cant_repair_dns::
      "@@ConfigureDNS@@result_error@@&TRACKINGKEY&@@dnsConfiguration@@None@@${g.execRun}##${g.uuid}@#Could not edit the ${sys.resolv} configuration file";

    cant_repair_dns_searchlist::
      "@@ConfigureDNS@@result_error@@&TRACKINGKEY&@@dnsConfiguration@@None@@${g.execRun}##${g.uuid}@#Could not set DNS search list in the Windows registry";

    cant_repair_dns_resolver::
      "@@ConfigureDNS@@result_error@@&TRACKINGKEY&@@dnsConfiguration@@None@@${g.execRun}##${g.uuid}@#Could not set DNS resolver list in the Windows registry";

    linux.dns_kept.!dns_repaired.!cant_repair_dns::
      "@@ConfigureDNS@@result_success@@&TRACKINGKEY&@@dnsConfiguration@@None@@${g.execRun}##${g.uuid}@#The DNS is correctly configured";

&if(NOVA)&
    #windows and something to do
    windows.((dns_resolver_edit.dns_resolver_kept.!dns_repaired_resolver)|!dns_resolver_edit).((dns_searchlist_edit.dns_searchlist_kept.!dns_repaired_searchlist)|!dns_searchlist_edit)::
      "@@ConfigureDNS@@result_success@@&TRACKINGKEY&@@dnsConfiguration@@None@@${g.execRun}##${g.uuid}@#The DNS is correctly configured";
&endif&

&if(COMMUNITY)&
    windows::
      "@@ConfigureDNS@@result_error@@&TRACKINGKEY&@@dnsConfiguration@@None@@${g.execRun}##${g.uuid}@#Can't repair the dns configuration on a Windows with community edition";
&endif&
}

&if(NOVA)&
######################################################
# For each adapter passed in arguement, add the value
# NameServer, regKey
######################################################
bundle agent checkDNS(adapter, regKey)
{
  classes:
      "valid" expression => regcmp("{.*","${adapter}"),
        comment => "A valid adapter starts with {";


  databases:
    valid::
      "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\${adapter}"
        database_operation => "verify",
        database_type => "ms_registry",
        database_rows => { "NameServer,REG_SZ,${regKey}"},
        classes => kept_if_else("dns_resolver_kept", "dns_repaired_resolver", "cant_repair_dns_resolver");

}
&endif&

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

"#############################################################
### This file is protected by your Rudder infrastructure. ###
### Manually editing the file might lead your Rudder      ###
### infrastructure to change back the server's            ###
### configuration and/or to raise a compliance alert.     ###
#############################################################
"
        location => start,
        insert_type => "preserve_block";

    dns_options_edit::
      "options ${options}";

    dns_searchlist_edit::
      "search ${search}";

    dns_resolver_edit::
      "nameserver ${list}";

}
