#!/bin/bash
# Bundle of tests for Rudder Policy Templates
set -e

trap on_exit EXIT

function on_exit()
{
EXIT_STATUS=$?
if [ ${EXIT_STATUS} -ne 0 ]; then
	echo "ERROR: This repository seems corrupted"
	if [ ${EXIT_STATUS} -eq 1 ]; then
		echo "Reason: There is a 'techniques' folder in the repository. Use 'policies'"\
			 "instead"
	elif [ ${EXIT_STATUS} -eq 2 ]; then
		echo "Reason: There are 'metadata.xml' files in the repository. Use 'policy.xml'"\
			 "instead"
	fi
	exit
else
	echo "This repository seems clean"
fi
}

# Check that there is no "techniques" folder at the repository root
TECHNIQUES_EXISTS=$(find .. -type d -name "techniques" | wc -l)
if [ ${TECHNIQUES_EXISTS} -ne 0 ];then
	exit 1
fi

# Check that there are no "metadata.xml" files in each of policy folder
METADATA_EXISTS=$(find .. -type f -name "metadata.xml" | wc -l)
if [ ${METADATA_EXISTS} -ne 0 ];then
	exit 2
fi
