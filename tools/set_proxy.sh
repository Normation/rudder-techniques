#!/bin/sh

# Script to set a proxy for inventory on a node

# Restore initial promises, set the proxy, and send an inventory to the server

# Check if some arguments have been given
if [ $# -gt 0 ]
then
  PROXYCONFIG=${1}
  if [ ${PROXYCONFIG} = "usage" ]
  then
    echo "Usage: set_proxy.sh proxyname:port"
    echo "Example: set_proxy.sh localproxy:3128"
    echo ""
    echo "Restore initial promises, edit in rudder promises the proxy, and"
    echo "run an inventory"
    exit 1
  fi
else
  echo "ERROR: You must pass the proxy to use as a parameter, in the format proxyname:port"
  echo "You can run 'set_proxy.sh usage' from more details"
  exit 1
fi

echo "Restoring initial promises"
rudder agent reset
echo ""

echo -n "Editing promises to set proxy to ${PROXYCONFIG}..."
sed -i "s/--proxy ''/--proxy '${PROXYCONFIG}'/" /var/rudder/cfengine-community/inputs/inventory/1.0/fusionAgent.cf
echo "Done"
echo ""

echo "Sending inventory to the server"
rudder agent inventory
