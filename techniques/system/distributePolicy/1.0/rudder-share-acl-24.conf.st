&MANAGED_NODES_CERT_UUID, MANAGED_NODES_CERT_CN: {uuid, cn |
Alias /policies/&uuid& /var/rudder/share/&uuid&
<Location /policies/&uuid&>
  AuthMerging And
  Require user &cn&
</Location>

&
