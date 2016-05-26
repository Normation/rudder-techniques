#####################################################################################
# Copyright 2016 Normation SAS
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

WGET := $(if $(PROXY), http_proxy=$(PROXY) ftp_proxy=$(PROXY)) /usr/bin/wget -q

all: rudder-templates-cli.jar
	cp techniques/system/common/1.0/rudder-stdlib.cf initial-promises/node-server/common/1.0/
	sed -i -e 's/.*TRACKINGKEY.*/  "TRACKINGKEY": "hasPolicyServer-root@@common-root@@00",/' variables.json
	java -jar rudder-templates-cli.jar --outext .cf --outdir initial-promises/node-server/common/1.0/ techniques/system/common/1.0/rudder-stdlib-core.st
	java -jar rudder-templates-cli.jar --outext .cf --outdir initial-promises/node-server/common/1.0/ techniques/system/common/1.0/cf-served.st
	java -jar rudder-templates-cli.jar --outext .cf --outdir initial-promises/node-server/common/1.0/ techniques/system/common/1.0/internal_security.st
	java -jar rudder-templates-cli.jar --outext .cf --outdir initial-promises/node-server/common/1.0/ techniques/system/common/1.0/rudder_lib.st
	java -jar rudder-templates-cli.jar --outext .cf --outdir initial-promises/node-server/common/1.0/ techniques/system/common/1.0/site.st
	java -jar rudder-templates-cli.jar --outext .cf --outdir initial-promises/node-server/common/1.0/ techniques/system/common/1.0/cron_setup.st
	java -jar rudder-templates-cli.jar --outext '' --outdir initial-promises/node-server/common/cron techniques/system/common/1.0/rudder_agent_community_cron.st
	java -jar rudder-templates-cli.jar --outext '' --outdir initial-promises/node-server/common/cron techniques/system/common/1.0/rudder_agent_nova_cron.st
	java -jar rudder-templates-cli.jar --outext '' --outdir initial-promises/node-server techniques/system/common/1.0/run_interval.st
	java -jar rudder-templates-cli.jar --outext '' --outdir initial-promises/node-server/common/utilities techniques/system/common/1.0/minicurl.st
	chmod +x initial-promises/node-server/common/utilities/minicurl
	sed -i -e 's/.*TRACKINGKEY.*/  "TRACKINGKEY": "inventory-all@@inventory-all@@00",/' variables.json
	java -jar rudder-templates-cli.jar --outext .cf --outdir initial-promises/node-server/inventory/1.0 techniques/system/inventory/1.0/virtualMachines.st
	java -jar rudder-templates-cli.jar --outext .cf --outdir initial-promises/node-server/inventory/1.0 techniques/system/inventory/1.0/fetchFusionTools.st
	java -jar rudder-templates-cli.jar --outext .cf --outdir initial-promises/node-server/inventory/1.0 techniques/system/inventory/1.0/fusionAgent.st
	sed -i -e 's/.*TRACKINGKEY.*/  "TRACKINGKEY": "root-DP@@root-distributePolicy@@00",/' variables.json
	cp techniques/system/distributePolicy/1.0/rudder-ncf-conf.st initial-promises/node-server/distributePolicy/ncf/ncf.conf
	java -jar rudder-templates-cli.jar --outext .conf --outdir initial-promises/node-server/distributePolicy/rsyslog.conf techniques/system/distributePolicy/1.0/rudder-rsyslog-root.st
	java -jar rudder-templates-cli.jar --outext .conf --outdir initial-promises/node-server/distributePolicy/rsyslog.conf techniques/system/distributePolicy/1.0/rudder-rsyslog-relay.st
	java -jar rudder-templates-cli.jar --outext .cf --outdir initial-promises/node-server/distributePolicy/1.0 techniques/system/distributePolicy/1.0/rsyslogConf.st
	java -jar rudder-templates-cli.jar --outext .cf --outdir initial-promises/node-server/distributePolicy/1.0 techniques/system/distributePolicy/1.0/propagatePromises.st
	sed -i -e 's/.*TRACKINGKEY.*/  "TRACKINGKEY": "server-roles@@server-roles-directive@@0",/' variables.json
	java -jar rudder-templates-cli.jar --outext .cf --outdir initial-promises/node-server/server-roles/1.0 techniques/system/server-roles/1.0/alive-check.st
	java -jar rudder-templates-cli.jar --outext .cf --outdir initial-promises/node-server/server-roles/1.0 techniques/system/server-roles/1.0/component-check.st
	java -jar rudder-templates-cli.jar --outext .cf --outdir initial-promises/node-server/server-roles/1.0 techniques/system/server-roles/1.0/compress-webapp-log.st
	java -jar rudder-templates-cli.jar --outext .cf --outdir initial-promises/node-server/server-roles/1.0 techniques/system/server-roles/1.0/integrity-check.st
	java -jar rudder-templates-cli.jar --outext .cf --outdir initial-promises/node-server/server-roles/1.0 techniques/system/server-roles/1.0/logrotate-check.st
	java -jar rudder-templates-cli.jar --outext .cf --outdir initial-promises/node-server/server-roles/1.0 techniques/system/server-roles/1.0/metrics-reporting.st
	java -jar rudder-templates-cli.jar --outext .cf --outdir initial-promises/node-server/server-roles/1.0 techniques/system/server-roles/1.0/network-check.st
	java -jar rudder-templates-cli.jar --outext .cf --outdir initial-promises/node-server/server-roles/1.0 techniques/system/server-roles/1.0/password-check.st
	java -jar rudder-templates-cli.jar --outext .cf --outdir initial-promises/node-server/server-roles/1.0 techniques/system/server-roles/1.0/postgres-check.st
	cp techniques/system/server-roles/1.0/rudder-logrotate.st initial-promises/node-server/server-roles/logrotate.conf/rudder
	java -jar rudder-templates-cli.jar --outext .conf --outdir initial-promises/node-server techniques/system/server-roles/1.0/rudder-server-roles.st
	java -jar rudder-templates-cli.jar --outext .cf --outdir initial-promises/node-server/server-roles/1.0 techniques/system/server-roles/1.0/servers-by-role.st
	java -jar rudder-templates-cli.jar --outext .cf --outdir initial-promises/node-server/server-roles/1.0 techniques/system/server-roles/1.0/service-check.st
	java -jar rudder-templates-cli.jar --outext .cf --outdir initial-promises/node-server/server-roles/1.0 techniques/system/server-roles/1.0/technique-reload.st

rudder-templates-cli.jar:
	$(WGET) -O rudder-templates-cli.jar http://www.normation.com/tarball/rudder-templates-cli/rudder-templates-cli.jar

clean:
	rm -f initial-promises/node-server/common/1.0/rudder-stdlib.cf
	rm -f initial-promises/node-server/common/1.0/rudder-stdlib-core.cf
	rm -f initial-promises/node-server/common/1.0/cf-served.cf
	rm -f initial-promises/node-server/common/1.0/internal_security.cf
	rm -f initial-promises/node-server/common/1.0/rudder_lib.cf
	rm -f initial-promises/node-server/common/1.0/site.cf
	rm -f initial-promises/node-server/common/1.0/cron_setup.cf
	rm -f initial-promises/node-server/common/cron/rudder_agent_community_cron
	rm -f initial-promises/node-server/common/cron/rudder_agent_nova_cron
	rm -f initial-promises/node-server/common/utilities/minicurl
	rm -f initial-promises/node-server/inventory/1.0/virtualMachines.cf
	rm -f initial-promises/node-server/inventory/1.0/fetchFusionTools.cf
	rm -f initial-promises/node-server/inventory/1.0/fusionAgent.cf
	rm -f initial-promises/node-server/distributePolicy/ncf/ncf.conf
	rm -f initial-promises/node-server/distributePolicy/rsyslog.conf/rudder-rsyslog-root.conf
	rm -f initial-promises/node-server/distributePolicy/rsyslog.conf/rudder-rsyslog-relay.conf
	rm -f initial-promises/node-server/distributePolicy/1.0/techniques/system/distributePolicy/1.0/rsyslogConf.cf
	rm -f initial-promises/node-server/distributePolicy/1.0/propagatePromises.cf
	rm -f initial-promises/node-server/server-roles/1.0/alive-check.cf
	rm -f initial-promises/node-server/server-roles/1.0/component-check.cf
	rm -f initial-promises/node-server/server-roles/1.0/compress-webapp-log.cf
	rm -f initial-promises/node-server/server-roles/1.0/integrity-check.cf
	rm -f initial-promises/node-server/server-roles/1.0/logrotate-check.cf
	rm -f initial-promises/node-server/server-roles/1.0/metrics-reporting.cf
	rm -f initial-promises/node-server/server-roles/1.0/network-check.cf
	rm -f initial-promises/node-server/server-roles/1.0/password-check.cf
	rm -f initial-promises/node-server/server-roles/1.0/postgres-check.cf
	rm -f initial-promises/node-server/server-roles/logrotate.conf/rudder
	rm -f initial-promises/node-server/rudder-server-roles.conf
	rm -f initial-promises/node-server/server-roles/1.0/servers-by-role.cf
	rm -f initial-promises/node-server/server-roles/1.0/service-check.cf
	rm -f initial-promises/node-server/server-roles/1.0/technique-reload.cf
	rm -f initial-promises/node-server/run_interval
