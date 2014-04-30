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
	echo "Usage: $0 server filename archiveDir failedDir"
}

# Check number of arguments
if [ $# -ne 4 ]; then
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
GZIP_BINARY="/bin/gzip"

# If the file appears to be compressed, attempt to uncompress it
# ${VARIABLE##*.} extracts the file extension
if [ "z${BASENAME##*.}" = "zgz" ]; then
	${GZIP_BINARY} -d ${FILENAME}
	# ${VARIABLE%.*} removes the last extension of the file, here: .gz
        FILENAME="${FILENAME%.*}"
fi

# Attempt to send the file
HTTP_CODE=`${CURL_BINARY} --proxy '' -f -F file=@${FILENAME} -o /dev/null -w '%{http_code}' ${SERVER}`
SEND_COMMAND_RET=$?

# Abort if sending failed
if [ ${SEND_COMMAND_RET} -eq 7 -o "z${HTTP_CODE}" = "z503" ]; then
	# Endpoint is unavailable (ret == 7) or too busy (HTTP_CODE == 503), try again later
	# Just leave this file in the incoming directory, it will be retried soon
	exit ${SEND_COMMAND_RET}
elif [ ${SEND_COMMAND_RET} -ne 0 ]; then
	mv "${FILENAME}" "${FAILEDDIR}/${BASENAME}-$(date --rfc-3339=date)"
	exit ${SEND_COMMAND_RET}
fi

# At this point, sending succeeded, archive original file
mv ${FILENAME} ${ARCHIVEDIR}

# All went well
exit 0
