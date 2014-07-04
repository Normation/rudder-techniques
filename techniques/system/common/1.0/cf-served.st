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
&if(MANAGED_NODES_NAME)&
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
  &if(SKIPIDENTIFY)&
    &MANAGED_NODES_NAME, MANAGED_NODES_ID : {host, uuid |
      "/var/rudder/share/&uuid&/"
        maproot => { escape("&host&")  },
        admit   => { escape("&host&")  };

     } &
  &else&
    &MANAGED_NODES_NAME, MANAGED_NODES_ID : {host, uuid |
      "/var/rudder/share/&uuid&/"
        maproot => { host2ip("&host&"), escape("&host&")  },
        admit   => { host2ip("&host&"), escape("&host&")  };

     } &
  &endif&

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
        string  => readfile("${policy_server_file}", 2048),
        comment => "IP address or hostname to locate your policy host.";

      "dir_masterfiles" string => translatepath("${sys.workdir}/masterfiles");

   # List here the IP masks that we grant access to on the server

&if(AUTHORIZED_NETWORKS)&
    policy_server::
      "acl" slist => {
      "127.0.0.0/8" , "::1",
      "${def.policy_server}", # the policy server can connect to a relay
      &AUTHORIZED_NETWORKS:{net|"&net&",}&
    };
&endif&
    !policy_server::
      "acl" slist => {
      "${def.policy_server}"
    };
}


body server control
{
&if(SKIPIDENTIFY)&
        trustkeysfrom     => {
          @{def.acl} ,
          &if(MANAGED_NODES_NAME)&
          &MANAGED_NODES_NAME: {
          "&it&"};separator=", "&
          &endif&
        }; #trustkey allows the exchange of keys

        allowconnects     => {
          @{def.acl} ,
          &if(MANAGED_NODES_NAME)&
          &MANAGED_NODES_NAME: {
          "&it&"};separator=", "&
          &endif&
        };

        allowallconnects  => {
          @{def.acl} ,
          &if(MANAGED_NODES_NAME)&
          &MANAGED_NODES_NAME: {
          "&it&"};separator=", "&
          &endif&
        };
&else&
        trustkeysfrom     => {
          @{def.acl} ,
          &if(MANAGED_NODES_NAME)&
          &MANAGED_NODES_NAME: {
          host2ip("&it&"), "&it&"};separator=", "&
          &endif&
        }; #trustkey allows the exchange of keys

        allowconnects     => {
          @{def.acl} ,
          &if(MANAGED_NODES_NAME)&
          &MANAGED_NODES_NAME: {
          host2ip("&it&"), "&it&"};separator=", "&
          &endif&
        };

        allowallconnects  => {
          @{def.acl} ,
          &if(MANAGED_NODES_NAME)&
          &MANAGED_NODES_NAME: {
          host2ip("&it&"), "&it&"};separator=", "&
          &endif&
        };
&endif&
        maxconnections    => "1000";
        logallconnections => "true";

        cfruncommand      => "${sys.workdir}/bin/cf-agent -f failsafe.cf \&\& ${sys.workdir}/bin/cf-agent";
        allowusers        => {
          "&POLICYSERVER_ADMIN&",
          &MANAGED_NODES_ADMIN : {admin | "&admin&" };separator=", "&
        };

        denybadclocks => "&DENYBADCLOCKS&";

    community_edition::
        port => "&COMMUNITYPORT&";

}

#######################################################

&if(MANAGED_NODES_NAME)&
body runagent control
{
        hosts => {
          &MANAGED_NODES_NAME: {
          "&it&",}&
        };

        max_children => "25";

    community_edition::
        port => "&COMMUNITYPORT&";
}
&endif&

