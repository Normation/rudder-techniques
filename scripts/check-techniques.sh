#!/bin/bash
# Bundle of tests for Rudder Techniques
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
		echo "Reason: There is a 'policies' folder in the repository. Use 'techniques'"\
			 "instead"
	elif [ ${EXIT_STATUS} -eq 2 ]; then
		echo "Reason: There are 'policy.xml' files in the repository. Use 'metadata.xml'"\
			 "instead"
	elif [ ${EXIT_STATUS} -eq 3 ]; then
		echo "Reason: XML file(s) seems to be not valid in the repository."
	fi
else
	echo "This repository seems clean"
fi
}

# Check that there is no "techniques" folder at the repository root
TECHNIQUES_EXISTS=$(find ${REPOSITORY_PATH} -maxdepth 1 -type d -name "policies" | wc -l)
if [ ${TECHNIQUES_EXISTS} -ne 0 ];then
	exit 1
fi

# Check that there are no "metadata.xml" files in each of policy folder
METADATA_EXISTS=$(find ${REPOSITORY_PATH} -type f -name "policy.xml" | wc -l)
if [ ${METADATA_EXISTS} -ne 0 ];then
	exit 2
fi

# Check that all XML files are well-formed
if ! find ${REPOSITORY_PATH} -type f -name "*.xml" | xargs -L 1 ${REPOSITORY_PATH}/scripts/xval.pl
then
    exit 3
fi

# Check that the non-existant log level "log_error" is never used
find ${REPOSITORY_PATH} -type f -name "*.st" | while read filename
do
	if grep -rHn "log_error" "$filename" > /dev/null
	then
		echo "Reason: illegal log level 'log_error' found in $filename. Use result_error instead"
		exit 4
	fi
done

# Check that the deprecated body 'class_trigger' is never used
find ${REPOSITORY_PATH} -type f -name "*.st" | while read filename
do
	if egrep -rHn 'classes\s+=>\s+class_trigger\s*\(' "$filename" > /dev/null
	then
		echo "Reason: deprecated body 'class_trigger' found in $filename. Use kept_if_else instead"
		exit 5
	fi
done

# Check that there is no use of '&&' in the techniques causing trouble with CFEngine promise generation
find ${REPOSITORY_PATH}/techniques -type f -name "*.st" | while read filename
do
	CHECK_AMPERSAND=`egrep '((\\\&&)|([^\\\]&\\\&))|(\s+&&\s+)' "$filename" | wc -l`
    if [ ${CHECK_AMPERSAND} -ne 0 ]
    then
        echo "Reason: found presence of double ampersand which could prevent Rudder to generate CFEngine promises properly"
        exit 6
    fi
done

# Check that logrotate configurations are synchronized from techniques to initial-promises
ls ${REPOSITORY_PATH}/techniques/system/distributePolicy/1.0/logrotate.*.st | xargs -L1 basename | sed -r "s/^logrotate\.([^.]*)\.st$/\1/" | while read version
do
  if ! diff -Nauwq ${REPOSITORY_PATH}/techniques/system/distributePolicy/1.0/logrotate.${version}.st ${REPOSITORY_PATH}/initial-promises/node-server/distributePolicy/logrotate.conf/rudder.${version}
  then
    echo "Logrotate files ${REPOSITORY_PATH}/techniques/system/distributePolicy/1.0/logrotate.${version}.st and ${REPOSITORY_PATH}/initial-promises/node-server/distributePolicy/logrotate.conf/rudder.${version} differ"
    exit 7
  fi
done

