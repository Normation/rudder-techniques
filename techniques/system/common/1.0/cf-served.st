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

#######################################################
#
# Server specific configuration
#
#######################################################

bundle server access_rules
{
&if(CLIENTSLIST)&
  # Access rules are only defined on a policy server. Standard nodes should not share any files.
  access:

    policy_server::
      &if(NOVA)&
      "&UUID&"
        handle        => "policy_server_uuid",
        resource_type => "literal",
        admit         => {".*"};
      &endif&

      "${def.dir_masterfiles}"
        handle  => "grant_access_policy",
        comment => "Grant access to the policy updates",
        maproot => {  @{def.acl}  },
        admit   => {  @{def.acl}  };

      "${g.rudder_tools}"
        maproot => {  @{def.acl}  },
        admit   => {  @{def.acl}  };

      "${g.rudder_ncf_origin_common}"
        maproot => {  @{def.acl}  },
        admit   => {  @{def.acl}  };

      "${g.rudder_ncf_origin_tools}"
        maproot => {  @{def.acl}  },
        admit   => {  @{def.acl}  };

      "${g.rudder_ncf_origin_local}"
        maproot => {  @{def.acl}  },
        admit   => {  @{def.acl}  };

      &if(SHARED_FILES_FOLDER)&
      "&SHARED_FILES_FOLDER&"
        comment => "Grant access to the share files",
        maproot => {  @{def.acl}  },
        admit   => {  @{def.acl}  };

      &endif&


    any::
    &MANAGED_NODES_NAME, MANAGED_NODES_ID : {host, uuid |
      "/var/rudder/share/&uuid&/"
        maproot => { host2ip("&host&"), escape("&host&")  },
        admit   => { host2ip("&host&"), escape("&host&")  };

     } &


      # the policy server must have access to the cfengine folder
      "${sys.workdir}"
        maproot => { host2ip("&POLICYSERVER&"), escape("&POLICYSERVER&")  },
        admit   => { host2ip("&POLICYSERVER&"), escape("&POLICYSERVER&")  };
&endif&

  roles:
      # Allow user root to set any class
      ".*"  authorize => { "root" };
}

bundle common def
{
  vars:
      "policy_server_file"
        string  => translatepath("${sys.workdir}/policy_server.dat"),
        comment => "Path to file containing address to policy server";

      "policy_server"
        string  => readfile("${policy_server_file}", 40),
        comment => "IP address to locate your policy host.";

      "dir_masterfiles" string => translatepath("${sys.workdir}/masterfiles");

   # List here the IP masks that we grant access to on the server

&if(CLIENTSLIST)&
    policy_server::
      "acl" slist => {
      &ALLOWEDNETWORK:{net|"&net&",}&
    };
&endif&
    !policy_server::
      "acl" slist => {
      "${def.policy_server}"
    };
}


body server control
{
        trustkeysfrom     => {
          "127.0.0.0/8" , "::1",
          @{def.acl} ,
          &ALLOWCONNECT: { host2ip("&it&"), "&it&", }&
          &if(CLIENTSLIST)&
          &MANAGED_NODES_NAME: { host2ip("&it&"), "&it&"};separator=", "&
          &endif&
        }; #trustkey allows the exchange of keys

        allowconnects     => {
          @{def.acl} ,
          &ALLOWCONNECT: { host2ip("&it&"), "&it&", }&
          &if(CLIENTSLIST)&
          &MANAGED_NODES_NAME: { host2ip("&it&"), "&it&"};separator=", "&
          &endif&
        };

        allowallconnects  => {
          @{def.acl} ,
          &ALLOWCONNECT: { host2ip("&it&"), "&it&", }&
          &if(CLIENTSLIST)&
          &MANAGED_NODES_NAME: { host2ip("&it&"), "&it&"};separator=", "&
          &endif&
        };

        maxconnections    => "1000";
        logallconnections => "true";

        cfruncommand      => "${sys.workdir}/bin/cf-agent -f failsafe.cf \&\& ${sys.workdir}/bin/cf-agent";
        allowusers        => {
          "&POLICYSERVER_ADMIN&",
&if(CLIENTSLIST)&
          &ADMIN : {admin | "&admin&" };separator=", "&
&endif&
        };

        denybadclocks => "&DENYBADCLOCKS&";

        skipverify        => { "127.0.0.0/8" , "::1",  @{def.acl}  };

    community_edition::
        port => "&COMMUNITYPORT&";

}

#######################################################

&if(CLIENTSLIST)&
body runagent control
{
        hosts => {
          &CLIENTSLIST: { "&it&",}&
        };

        max_children => "25";

    community_edition::
        port => "&COMMUNITYPORT&";
}
&endif&

