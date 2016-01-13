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
if ! diff -Nauwq ${REPOSITORY_PATH}/techniques/system/server-roles/1.0/rudder-logrotate.st ${REPOSITORY_PATH}/initial-promises/node-server/server-roles/logrotate.conf/rudder
then
  echo "Logrotate files ${REPOSITORY_PATH}/techniques/system/server-roles/1.0/rudder-logrotate.st and ${REPOSITORY_PATH}/initial-promises/node-server/server-roles/logrotate.conf/rudder differ"
  exit 7
fi

# Check that minicurl is synchronized from techniques to initial-promises
if ! diff -Nauwq ${REPOSITORY_PATH}/techniques/system/common/1.0/minicurl.st ${REPOSITORY_PATH}/initial-promises/node-server/common/utilities/minicurl
then
  echo "The minicurl utility in ${REPOSITORY_PATH}/techniques/system/common/1.0/minicurl.st and ${REPOSITORY_PATH}/initial-promises/node-server/common/utilities/minicurl differ"
  exit 8
fi

# Check that no StringTemplate thingies were put into the initial-promises ( lines beginning with & or StringTemplate iterators )
if grep -E -r '^\s*&|&[a-zA-Z_]&' ${REPOSITORY_PATH}/initial-promises
then
  echo "There are some StringTemplate definitions in the initial promises"
  exit 9
fi

# Check that we are not using classes to detect distribution version as DistributionVersion (which does not exists)
find ${REPOSITORY_PATH}/techniques -type f -name "*.st" | while read filename
do
  CHECK_CLASS_DISTRIB=`egrep 'debian[1-9]|redhat[1-9]|centos[1-9]' "$filename" | wc -l`
  if [ ${CHECK_CLASS_DISTRIB} -ne 0 ]
  then
    echo "Reason: found invalid use of class DistributionVersion that does not exists in file ${filename}"
    exit 8
  fi
done

# Check that we are not using the non-existant class cfengine_community (which does not exist)
find ${REPOSITORY_PATH} -type f -name "*.st" -or -name "*.cf" | while read filename
do
  if grep -q 'cfengine_community' "${filename}"; then
    echo "Found invalid use of class cfengine_community that does not exists in file ${filename}. Use community_edition instead."
    exit 8
  fi
done


# Check that techniques are written in normal ordering
${REPOSITORY_PATH}/scripts/technique-files -l -i -f '*.cf' -f '*.st' "${REPOSITORY_PATH}" | grep -v cfengine_stdlib | xargs ${REPOSITORY_PATH}/scripts/ordering.pl || exit 9

# Check that techniques do not contain $()
${REPOSITORY_PATH}/scripts/technique-files -l -i -f '*.cf' -f '*.st' "${REPOSITORY_PATH}" | grep -v cfengine_stdlib | while read filename
do
  if grep '$(' "${filename}" >/dev/null; then
    echo "The file ${filename} contains deprecated \$() syntax"
    exit 10
  fi
done

# check that techniques do not use reports:
${REPOSITORY_PATH}/scripts/technique-files -l -f '*.cf' -f '*.st' "${REPOSITORY_PATH}" | grep -v initial-promises | egrep -v "techniques/system/common/1.0/(rudder_stdlib.st|update.st|promises.st|process_matching.st|rudder_stdlib_core.st)|techniques/system/distributePolicy/1.0/rsyslogConf.st" | grep -v cfengine_stdlib | while read filename
do
  if egrep '^[[:space:]]*reports:' "${filename}" >/dev/null; then
    echo "The file ${filename} uses reports: instead of rudder_common_report"
    exit 11
  fi
done

# Check that we never use group "root" in perms
${REPOSITORY_PATH}/scripts/technique-files -l -i -f '*.cf' -f '*.st' "${REPOSITORY_PATH}" | while read filename
do
  if egrep -q "^[^#]*perms\s*=>\s*mog\([^,]+,\s*[^,]+,\s*['\"]root['\"]\)" ${filename}; then
    echo "The file ${filename} attempts to use the 'root' group - use '0' instead for UNIX compatibility"
    exit 12
  fi
done

# Check that no removed deprecated techniques come back (via erroneous merges, for example)
${REPOSITORY_PATH}/scripts/technique-files -d "${REPOSITORY_PATH}/techniques" | while read name
do

  # Get relative technique version/name path
  TECHNIQUE=$(echo ${name} | sed "s%${REPOSITORY_PATH}/techniques/%%")

  if ! egrep "^${TECHNIQUE}" ${REPOSITORY_PATH}/maintained-techniques > /dev/null; then
    echo "Unexpected technique version ${TECHNIQUE} found. Maybe it is deprecated but has come back via a merge. Please remove it, or if it's a new version, add it to maintained-techniques."
    exit 13
  fi
done

# Check that all technique versions listed as maintained are indeed present
cat ${REPOSITORY_PATH}/maintained-techniques | while read name
do

  # Skip comments
  if echo ${name} | egrep "^[   ]*#" > /dev/null; then continue; fi

  if [ ! -d ${REPOSITORY_PATH}/techniques/${name} ]; then
    echo "Supposedly maintained technique version ${name} is missing"
    exit 14
  fi
done
