#!/bin/sh

#This is the SNMP OID for the rudder agent health
echo 1.3.6.1.4.1.35061.2.3.1
echo string
rudder agent health -n
exit 0
