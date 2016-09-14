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

# Autodetect wget or curl or curl usage and proxy configuration
PROXY_ENV = $(if $(PROXY), http_proxy=$(PROXY) ftp_proxy=$(PROXY))
WGET = wget -q -O
CURL = curl -s -o
FETCH = fetch -q -o
ifneq (,$(wildcard /usr/bin/curl))
GET = $(PROXY_ENV) $(CURL)
else
ifneq (,$(wildcard /usr/bin/fetch))
GET = $(PROXY_ENV) $(FETCH)
else
GET = $(PROXY_ENV) $(WGET)
endif
endif

all: rudder-templates-cli.jar test
	# The common technique
	sed -i -e 's/.*TRACKINGKEY.*/  "TRACKINGKEY": "hasPolicyServer-root@@common-root@@00",/' variables.json
	java -jar rudder-templates-cli.jar --outext .cf --outdir initial-promises/node-server/common/1.0/ techniques/system/common/1.0/*.st
	cp techniques/system/common/1.0/*.cf initial-promises/node-server/common/1.0/ || true
	mv initial-promises/node-server/common/1.0/failsafe.cf initial-promises/node-server/
	mv initial-promises/node-server/common/1.0/promises.cf initial-promises/node-server/
	mv initial-promises/node-server/common/1.0/rudder-system-directives.cf initial-promises/node-server/
	mv initial-promises/node-server/common/1.0/rudder-directives.cf initial-promises/node-server/
	mkdir -p initial-promises/node-server/common/cron
	cp techniques/system/common/1.0/rudder-agent-community-cron initial-promises/node-server/common/cron/
	cp techniques/system/common/1.0/rudder-agent-nova-cron initial-promises/node-server/common/cron/
	mv initial-promises/node-server/common/1.0/run-interval.cf initial-promises/node-server/run-interval
	mkdir -p initial-promises/node-server/common/utilities
	cp techniques/system/common/1.0/minicurl initial-promises/node-server/common/utilities/
	chmod +x initial-promises/node-server/common/utilities/minicurl
	# The inventory technique
	sed -i -e 's/.*TRACKINGKEY.*/  "TRACKINGKEY": "inventory-all@@inventory-all@@00",/' variables.json
	java -jar rudder-templates-cli.jar --outext .cf --outdir initial-promises/node-server/inventory/1.0/ techniques/system/inventory/1.0/*.st
	cp techniques/system/inventory/1.0/*.cf initial-promises/node-server/inventory/1.0/ || true
	# The distributePolicy technique
	sed -i -e 's/.*TRACKINGKEY.*/  "TRACKINGKEY": "root-DP@@root-distributePolicy@@00",/' variables.json
	java -jar rudder-templates-cli.jar --outext .cf --outdir initial-promises/node-server/distributePolicy/1.0/ techniques/system/distributePolicy/1.0/*.st
	cp techniques/system/distributePolicy/1.0/*.cf initial-promises/node-server/distributePolicy/1.0/ || true
	mkdir -p initial-promises/node-server/distributePolicy/ncf
	cp techniques/system/distributePolicy/1.0/rudder-ncf-conf initial-promises/node-server/distributePolicy/ncf/ncf.conf
	mkdir -p initial-promises/node-server/distributePolicy/rsyslog.conf
	mv initial-promises/node-server/distributePolicy/1.0/rudder-rsyslog-root.cf initial-promises/node-server/distributePolicy/rsyslog.conf/rudder-rsyslog-root.conf
	mv initial-promises/node-server/distributePolicy/1.0/rudder-rsyslog-relay.cf initial-promises/node-server/distributePolicy/rsyslog.conf/rudder-rsyslog-relay.conf
	# The server-roles technique
	sed -i -e 's/.*TRACKINGKEY.*/  "TRACKINGKEY": "server-roles@@server-roles-directive@@0",/' variables.json
	java -jar rudder-templates-cli.jar --outext .cf --outdir initial-promises/node-server/server-roles/1.0/ techniques/system/server-roles/1.0/*.st
	cp techniques/system/server-roles/1.0/*.cf initial-promises/node-server/server-roles/1.0/ || true
	mkdir -p initial-promises/node-server/server-roles/logrotate.conf/
	cp techniques/system/server-roles/1.0/rudder-logrotate initial-promises/node-server/server-roles/logrotate.conf/rudder
	mv initial-promises/node-server/server-roles/1.0/rudder-server-roles.cf initial-promises/node-server/rudder-server-roles.conf
	# Bring variables.json back to its initial state
	sed -i -e 's/.*TRACKINGKEY.*/  "TRACKINGKEY": "root-DP@@root-distributePolicy@@00",/' variables.json
	# Initial ncf reporting empty
	touch initial-promises/rudder_expected_reports.csv

rudder-templates-cli.jar:
	$(WGET) -O rudder-templates-cli.jar http://www.normation.com/tarball/rudder-templates-cli/rudder-templates-cli.jar

scripts/technique-files:
	$(GET) scripts/technique-files https://www.rudder-project.org/tools/technique-files
	chmod +x scripts/technique-files

test: scripts/technique-files
	cd scripts && ./check-techniques.sh

clean:
	rm -rf initial-promises/ scripts/technique-files
