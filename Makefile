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


all: initial-promises bootstrap-promises/rudder.json bootstrap-promises/promises.cf

initial-promises: rudder-templates-cli.jar test
	python generateInitialPolicies.py
	mkdir -p initial-promises/node-server/common/cron
	mkdir -p initial-promises/node-server/common/utilities
	touch initial-promises/rudder_expected_reports.csv
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
