#!/bin/sh

useradd -m keyTesting

# Force keys to be present
rudder agent run > /dev/null
