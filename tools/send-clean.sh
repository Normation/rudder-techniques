#!/bin/bash

###############################################################################
# This script sends a file to a remote server and archives the local copy if
# transmission was successful.
###############################################################################
# Copyright 2010 (c) Normation SAS 
# Author: Jonathan CLARKE <jonathan.clarke@normation.com>
###############################################################################
# Return values:	-1: Error in script arguments
#					1 to XX: curl (or other send command) exit status
###############################################################################


function usage() {
	echo "Usage: $0 server filename archiveDir"
}

# Check number of arguments
if [ $# -ne 3 ]; then
	usage
	exit -1
fi

# Configuration
SERVER=$1
FILENAME=$2
ARCHIVEDIR=$3
SEND_COMMAND="curl -f -F file=@${FILENAME} ${SERVER}"

# Attempt to send the file
${SEND_COMMAND}
SEND_COMMAND_RET=$?

# Abort if sending failed
if [ ${SEND_COMMAND_RET} -ne 0 ]; then
	exit ${SEND_COMMAND_RET}
fi

# At this point, sending succeeded, archive original file
mv ${FILENAME} ${ARCHIVEDIR}

# All went well
exit 0
