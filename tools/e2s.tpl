<?xml version="1.0" encoding="utf-8"?>
<root>
	<!--
	#############################################################
	### This file is protected by your Rudder infrastructure. ###
	### Manually editing the file might lead your Rudder      ###
	### infrastructure to change back the server's            ###
	### configuration and/or to raise a compliance alert.     ###
	#############################################################
	-->
	<!-- Parameters of program -->
	<program>
		<debug>
			<!-- Set 1 to active debug -->
			<level>1</level>
			<!-- If debug is active, set interger between 0 and 2 -->
			<verbose>2</verbose>
			<!-- Rotation parameters-->
			<!-- In Mega Bytes-->
			<max_size>1</max_size>
			<!-- Number of file saved -->
			<file_number>5</file_number>
		</debug>
    <refresh_intervalle>1</refresh_intervalle>
  </program>
  <!-- Centreon Syslog Server(s) parameters -->
  <syslog_server>
    <!--<server>-->
		<!-- Centreon Syslog Server IP address or DNS name [, set integer between 1 and 65535 for port]-->
		<!--<address>192.168.1.1:514</address>-->
		<!-- Set TCP or UDP, no case sensitive and default UDP -->
		<!-- <protocole>UDP</protocole>-->
    <!--</server>-->
    <server>
		<!-- Centreon Syslog Server IP address or DNS name [, set integer between 1 and 65535 for port]-->
		<address>$(server):$(port)</address>
		<!-- <address>192.168.1.2:517</address>-->
		<!-- Set TCP or UDP, no case sensitive and default UDP -->
		<protocole>$(protocol)</protocole>
		<!-- Only used for TCP protocol, ignored for UDP -->
		<!-- It used if TCP Syslog server(s) is(are) not available -->
		<!-- Integer for number of element in memory buffer before write it into file buffer -->
		<memory_buffer>200</memory_buffer>
    </server>
  </syslog_server>
  <!-- List of filters for Cfengine Nova -->
  <filters>
    <filter>
      <event>
        <EventLogName>
          <item>Application</item>
		  <item>System</item>
        </EventLogName>
        <sources>
          <include>*</include>
        </sources>
        <id>
          <include>100</include>
          <include>101</include>
          <include>104</include>
          <include>105</include>
          <include>106</include>
        </id>
        <users>
          <include>*</include>
        </users>
        <computers>
          <include>*</include>
        </computers>
        <type>
          <include>Information</include>
        </type>
        <descriptions>
          <include>*</include>
        </descriptions>
      </event>
      <syslog>
        <level>notice</level>
        <Facility>local7</Facility>
      </syslog>
    </filter>
    <filter>
      <event>
        <EventLogName>
          <item>Application</item>
		  <item>System</item>
        </EventLogName>
        <sources>
          <include>*</include>
        </sources>
        <id>
          <include>107</include>
        </id>
        <users>
          <include>*</include>
        </users>
        <computers>
          <include>*</include>
        </computers>
        <type>
          <include>Warning</include>
        </type>
        <descriptions>
          <include>*</include>
        </descriptions>
      </event>
      <syslog>
        <level>warning</level>
        <Facility>local7</Facility>
      </syslog>
    </filter>
    <filter>
      <event>
        <EventLogName>
          <item>Application</item>
		  <item>System</item>
        </EventLogName>
        <sources>
          <include>*</include>
        </sources>
        <id>
          <include>102</include>
          <include>103</include>
        </id>
        <users>
          <include>*</include>
        </users>
        <computers>
          <include>*</include>
        </computers>
        <type>
          <include>Error</include>
        </type>
        <descriptions>
          <include>*</include>
        </descriptions>
      </event>
      <syslog>
        <level>error</level>
        <Facility>local7</Facility>
      </syslog>
    </filter>
  </filters>
</root>
