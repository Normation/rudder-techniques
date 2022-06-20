# We need this to stay compatible with python 2

all: check

ifeq ($(shell which pylint),)
  PYLINT = pylint3
else
  PYLINT = pylint
endif
ifeq ($(shell which python),)
  PYTHON = python3
else
  PYTHON = python
endif

version:
	$(PYTHON) --version


test: version
	$(PYTHON) -m unittest discover

lint:
	$(PYLINT) .
	# blue breaks our little compatibility hack, skip it
	tail -n +12 system_update.py | blue --quiet --check
	blue --quiet --check test
	pycodestyle .
	bandit --quiet --severity-level medium --recursive .

check: lint test

fmt:
	blue .
