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
FAILEDDIR=$4
BASENAME=$(basename ${2})
CURL_BINARY="/usr/bin/curl"

# Attempt to send the file
${CURL_BINARY} --proxy '' -f -F file=@${FILENAME} ${SERVER}
SEND_COMMAND_RET=$?

# Abort if sending failed
if [ ${SEND_COMMAND_RET} -ne 0 ]; then
	mv "${FILENAME}" "${FAILEDDIR}/${BASENAME}-$(date --rfc-3339=date)"
	exit ${SEND_COMMAND_RET}
fi

# At this point, sending succeeded, archive original file
mv ${FILENAME} ${ARCHIVEDIR}

# All went well
exit 0
