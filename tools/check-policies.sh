#!/bin/bash
# Bundle of tests for Rudder Policy Templates
set -e

#Set variables
REPOSITORY_PATH=${REPOSITORY_PATH:=$(cd .. && echo $PWD)}

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
	elif [ ${EXIT_STATUS} -eq 3 ]; then
		echo "Reason: XML file(s) seems to be not valid in the repository."
	fi
else
	echo "This repository seems clean"
fi
}

# Check that there is no "techniques" folder at the repository root
TECHNIQUES_EXISTS=$(find ${REPOSITORY_PATH} -type d -name "techniques" | wc -l)
if [ ${TECHNIQUES_EXISTS} -ne 0 ];then
	exit 1
fi

# Check that there are no "metadata.xml" files in each of policy folder
METADATA_EXISTS=$(find ${REPOSITORY_PATH} -type f -name "metadata.xml" | wc -l)
if [ ${METADATA_EXISTS} -ne 0 ];then
	exit 2
fi

# Check that all XML files are well-formed
XML_VALID=$(find ${REPOSITORY_PATH} -type f -name "*.xml" | xargs -L 1 ${REPOSITORY_PATH}/tools/xval.pl)
if [ ${METADATA_EXISTS} -ne 0 ];then
    exit 3
fi
