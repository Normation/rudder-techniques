#!/bin/sh
#
# Copyright 2010-2014 (c) Normation SAS
# Author: Jonathan CLARKE <jonathan.clarke@normation.com>
# Author: Matthieu CERDA <matthieu.cerda@normation.com>
#
# This script sends a file to a remote server and archives the local copy if
# transmission was successful.
#
# Return values:
## 255:     Error in script arguments
## 1 to XX: curl (or other send command) exit status

# Pre-flight checks

usage() {
  echo "ERROR: Incorrect usage"
  echo "Example: $0 server filename archiveDir failedDir"
}

## Check number of arguments
if [ ${#} -ne 4 ]; then
  usage
  exit 255
fi

# Configuration

SERVER=${1}
FILENAME=${2}
ARCHIVEDIR=${3}
FAILEDDIR=${4}
BASENAME=$(basename ${2})

CURL_BINARY="/usr/bin/curl"
GZIP_BINARY="/bin/gzip"

# End of configuration

# 1 - Create the necessary directories if needed
for i in "${ARCHIVEDIR}" "${FAILEDDIR}"
do
  mkdir -p ${i}
done

# 2 - If the file appears to be compressed, attempt to uncompress it
#     ${VARIABLE##*.} extracts the file extension
if [ "${BASENAME##*.}" = "gz" ]
then
  ${GZIP_BINARY} -q -d ${FILENAME}
  # ${VARIABLE%.*} removes the last extension of the file, here: .gz
  FILENAME="${FILENAME%.*}"
fi

# 3 - Send the file
HTTP_CODE=$(${CURL_BINARY} --proxy '' -f -F file=@${FILENAME} -o /dev/null -w '%{http_code}' ${SERVER})
SEND_COMMAND_RET=$?

# 4 - Abort if sending failed
if [ ${SEND_COMMAND_RET} -eq 7 -o "${HTTP_CODE}" = "503" ]
then
  # Endpoint is unavailable (ret == 7) or too busy (HTTP_CODE == 503), try again later
  # Just leave this file in the incoming directory, it will be retried soon
  echo "WARNING: Unable to send ${FILENAME}, inventory endpoint is temporarily unavailable, will retry later"
  echo "This often happens due to rate-throttling in the endpoint to save on memory consumption. This is standard behavior."
  exit ${SEND_COMMAND_RET}
elif [ ${SEND_COMMAND_RET} -ne 0 ]
then
  echo "ERROR: Failed to send inventory ${FILENAME}, putting it in the failed directory"
  mv "${FILENAME}" "${FAILEDDIR}/${BASENAME}-$(date --rfc-3339=date)"
  exit ${SEND_COMMAND_RET}
fi

# 5 - Sending succeeded, archive original file
mv ${FILENAME} ${ARCHIVEDIR}

# 6 - That's all, folks
exit 0
