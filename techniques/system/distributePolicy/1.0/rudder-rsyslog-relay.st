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
#*.*	/var/log/all.log
*.*	/var/log/rudder/reports/all.log

# Direct to DB
$ActionQueueType Direct
$ActionQueueSaveOnShutdown on

# We start by logging all the Windows and Linux message
:programname, contains, "rudder" /var/log/rudder/reports/linuxlog.log
:programname, contains, "Cfengine_Nova" /var/log/rudder/reports/winlog.log

# Filtering by content
# Process :
# We first log the data in the file, then forward it to the root server, and we drop the message

if $programname startswith 'rudder' and $msg startswith '  R: @@' then /var/log/rudder/reports/extLinuxReport.log

if $programname startswith 'rudder' and $msg startswith '  R: @@' then @@${server_info.cfserved}:&SYSLOGPORT&

# We shouldn't have any rudder message here left
if $programname startswith 'rudder' then ~
