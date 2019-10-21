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

# rudder-agent-community-cron is a mustache template that is not rendered at postinstall
# It needs to be "correctly" built to avoid breaking the cron service
# Need to also remove all lines starting with comment
ifneq (,$(wildcard /tmp/slackware))
CRON_AGENT = $(shell perl -0777 -pe 's|\{\{\#classes.slackware}}(.*?)\{\{/classes.slackware}}.*?\{\{\^classes.slackware}}(.*?)\{\{/classes.slackware}}|\1|sg' techniques/system/common/1.0/rudder-agent-community-cron)
else
CRON_AGENT = $(shell perl -0777 -pe 's|\{\{\#classes.slackware}}(.*?)\{\{/classes.slackware}}.*?\{\{\^classes.slackware}}(.*?)\{\{/classes.slackware}}|\2|sg' techniques/system/common/1.0/rudder-agent-community-cron)
endif

all: initial-promises bootstrap-promises/rudder.json bootstrap-promises/promises.cf

initial-promises: rudder-templates-cli.jar test

	# The common technique
	sed -i -e 's/.*TRACKINGKEY.*/  "TRACKINGKEY": "hasPolicyServer-root@@common-root@@00",/' variables.json
	java -jar rudder-templates-cli.jar --outext .cf --outdir initial-promises/node-server/common/1.0/ techniques/system/common/1.0/*.st
	cp techniques/system/common/1.0/*.cf initial-promises/node-server/common/1.0/ || true
	mv initial-promises/node-server/common/1.0/failsafe.cf initial-promises/node-server/
	mv initial-promises/node-server/common/1.0/promises.cf initial-promises/node-server/
	mv initial-promises/node-server/common/1.0/rudder-system-directives.cf initial-promises/node-server/
	mv initial-promises/node-server/common/1.0/rudder-directives.cf initial-promises/node-server/
	mv initial-promises/node-server/common/1.0/rudder-vars.cf initial-promises/node-server/rudder-vars.json
	mkdir -p initial-promises/node-server/common/cron
	echo "$(CRON_AGENT)" > initial-promises/node-server/common/cron/rudder-agent-community-cron
	mv initial-promises/node-server/common/1.0/run_interval.cf initial-promises/node-server/run_interval
	mkdir -p initial-promises/node-server/common/utilities
	# The inventory technique
	sed -i -e 's/.*TRACKINGKEY.*/  "TRACKINGKEY": "inventory-all@@inventory-all@@00",/' variables.json
	java -jar rudder-templates-cli.jar --outext .cf --outdir initial-promises/node-server/inventory/1.0/ techniques/system/inventory/1.0/*.st
	cp techniques/system/inventory/1.0/*.cf initial-promises/node-server/inventory/1.0/ || true
	mv initial-promises/node-server/inventory/1.0/test-inventory.pl.cf initial-promises/node-server/inventory/1.0/test-inventory.pl
	# The distributePolicy technique
	sed -i -e 's/.*TRACKINGKEY.*/  "TRACKINGKEY": "root-DP@@root-distributePolicy@@00",/' variables.json
	java -jar rudder-templates-cli.jar --outext .cf --outdir initial-promises/node-server/distributePolicy/1.0/ techniques/system/distributePolicy/1.0/*.st
	cp techniques/system/distributePolicy/1.0/*.cf initial-promises/node-server/distributePolicy/1.0/ || true
	mkdir -p initial-promises/node-server/distributePolicy/ncf
	mkdir -p initial-promises/node-server/distributePolicy/rsyslog.conf
	mv initial-promises/node-server/distributePolicy/1.0/rudder-rsyslog-root.cf initial-promises/node-server/distributePolicy/rsyslog.conf/rudder-rsyslog-root.conf
	mv initial-promises/node-server/distributePolicy/1.0/rudder-rsyslog-relay.cf initial-promises/node-server/distributePolicy/rsyslog.conf/rudder-rsyslog-relay.conf
	# The server-roles technique
	sed -i -e 's/.*TRACKINGKEY.*/  "TRACKINGKEY": "server-roles@@server-roles-directive@@0",/' variables.json
	java -jar rudder-templates-cli.jar --outext .cf --outdir initial-promises/node-server/server-roles/1.0/ techniques/system/server-roles/1.0/*.st
	cp techniques/system/server-roles/1.0/*.cf initial-promises/node-server/server-roles/1.0/ || true
	cp techniques/system/server-roles/1.0/relayd.conf.tpl initial-promises/node-server/server-roles/1.0/
	mkdir -p initial-promises/node-server/server-roles/logrotate.conf/
	cp techniques/system/server-roles/1.0/rudder-logrotate initial-promises/node-server/server-roles/logrotate.conf/rudder
	mv initial-promises/node-server/server-roles/1.0/rudder-server-roles.cf initial-promises/node-server/rudder-server-roles.conf
	# Bring variables.json back to its initial state
	sed -i -e 's/.*TRACKINGKEY.*/  "TRACKINGKEY": "root-DP@@root-distributePolicy@@00",/' variables.json
	# Initial ncf reporting empty (for compatibility with pre-4.3 servers)
	touch initial-promises/rudder_expected_reports.csv
	# Provide a default rudder.json
	cp variables.json initial-promises/node-server/rudder.json

bootstrap-promises/rudder.json:
	cp variables.json $@

bootstrap-promises/promises.cf:
	cp bootstrap-promises/failsafe.cf bootstrap-promises/promises.cf

rudder-templates-cli.jar:
	$(GET) rudder-templates-cli.jar https://repository.rudder.io/build-dependencies/rudder-templates-cli/rudder-templates-cli.jar

scripts/technique-files:
	$(GET) scripts/technique-files https://repository.rudder.io/tools/technique-files
	chmod +x scripts/technique-files

test: scripts/technique-files
	cd scripts && ./check-techniques.sh

clean:
	rm -rf initial-promises/ scripts/technique-files
