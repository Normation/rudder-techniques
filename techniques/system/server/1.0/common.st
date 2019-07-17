# Common variable for server system technique
bundle common server_common {
  vars:
    "directiveId"            string => "&TRACKINGKEY&";
    "send_metrics"           string => "&SEND_METRICS&";
    "directiveId"            string => "&TRACKINGKEY&";
    "report_db_name"         string => "&RUDDER_REPORTS_DB_NAME&";
    "report_db_user"         string => "&RUDDER_REPORTS_DB_USER&";
    "relay_sync_method"      string => "&RELAY_SYNC_METHOD&";
    "relay_sync_promises"    string => "&RELAY_SYNC_PROMISES&";
    "relay_sync_sharedfiles" string => "&RELAY_SYNC_SHAREDFILES&";
    "cmdb_endpoint"          string => "&CMDBENDPOINT&";

  classes:
&if(CMDBENDPOINT)&
    "has_cmdb_endpoint" expression => "any", scope => "namespace";
&endif&
}
