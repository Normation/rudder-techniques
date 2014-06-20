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

# Rsyslog Rudder configuration

# Provides TCP syslog reception
$ModLoad imtcp
$InputTCPServerRun &SYSLOGPORT&

# Provide udp for snare and compatibility with older syslog
$ModLoad imudp
$UDPServerRun &SYSLOGPORT&

# for Snare client
$EscapeControlCharactersOnReceive off

# Log everything
*.*	/var/log/rudder/reports/all.log

# Direct to DB
$ActionQueueType Direct
$ActionQueueSaveOnShutdown on

# Filtering by content
# Process :
# We forward the log to the root server, and we drop the message
if $programname startswith 'rudder' then @@${server_info.cfserved}:&SYSLOGPORT&

# We shouldn't have any rudder message here left
if $programname startswith 'rudder' then ~
