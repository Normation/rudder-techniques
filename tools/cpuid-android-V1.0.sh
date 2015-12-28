#!/system/xbin/sh

###############################################################################
# CPU Identification Program from CPUID
###############################################################################
# This program parses the /proc/cpuinfo file to output information about the
# system's processor(s) in a standard format, as described below.
#
# The output is in XML format on stdout, and follows the pattern below:
# <PROCESSORS>
#	<PROCESSOR>
#		<VENDOR>GenuineIntel</VENDOR>
#		<NAME>Intel(R) Core(TM)2 Duo CPU P8700 @ 2.53GHz</NAME>
#		<FAMILY>6</FAMILY>
#		<STEPPING>10</STEPPING>
#		<MODEL>23</MODEL>
#		<FREQUENCY>2614</FREQUENCY>
#	</PROCESSOR>
# </PROCESSORS>
#
# Processor speed is determined in MHz as follows:
#	1)	If /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq exists,
#		it's value is used
#	2)	Otherwise, the "cpu MHz" line from /proc/cpuinfo is used
###############################################################################
# This script has been tested on the following systems:
#	- CentOS 3.9 (Linux 2.4.21)
#	- CentOS 4.7 (Linux 2.6.9)
#	- CentOS 5.4 (Linux 2.6.18)
#	- Debian 3 sarge (Linux 2.4.27)
#	- Debian 4 etch (Linux 2.6.26)
#	- Debian 5 lenny (Linux 2.6.26)
#	- Ubuntu 9.10 (Linux 2.6.31)
###############################################################################
# Copyright (c) 2010, Normation SAS.
# All rights reserved.
###############################################################################

## 
# General parameters
##
ECHO="/system/xbin/echo -e"


##
# Print parameter line
#
# Args: $1, the name of the value
#		$2, the value
##
print_value_line() {
	KEY="$1"
	VALUE="$2"

	# Output XML line for value
	${ECHO} "\t\t<${KEY}>${VALUE}</${KEY}>"
}



##
# Function to parse a line into a key-value pair and output the XML format
#
# Args: $1, the line to parse
##
parse_line() {
	# Extract key and value from the line
	KEY=`echo "$1" | sed "s/^\([^\t]\+\)[ \t]\+: \(.\+\)$/\1/"`
	VALUE=`echo "$1" | sed "s/^\([^\t]\+\)[ \t]\+: \(.\+\)$/\2/"`

	# Convert key into standard format name
	# and process value if necessary (CPU frequency only)
	case ${KEY} in
		"vendor_id")	KEY="VENDOR"	;;
		"model")		KEY="MODEL"		;;
		"stepping")		KEY="STEPPING"	;;
		"cpu family")	KEY="FAMILY"	;;
		"model name")	KEY="NAME"		;;
		"cpu MHz")
			KEY="FREQUENCY"
			VALUE=`get_frequency "${VALUE}"`
			;;
		*)				return			;;
	esac

	# Output XML line for value
	print_value_line "${KEY}" "${VALUE}"
}


##
# Function to get the max processor frequency
#
# Use the cpufreq subsystem from /sys if available,
# otherwise use the value from cpuinfo given as $1.
#
# Args:	$1, frequency value from cpuinfo to fall back on.
##
get_frequency() {
	CPUFREQ_MAX_FILE=/sys/devices/system/cpu/cpu${COUNT}/cpufreq/cpuinfo_max_freq

	if [ -r ${CPUFREQ_MAX_FILE} ]
	then
		FREQUENCY=`cat ${CPUFREQ_MAX_FILE}`
		FREQUENCY=`expr ${FREQUENCY} / 1000`
	else
		FREQUENCY="$1"
	fi

	echo ${FREQUENCY}
}


##
# Check /proc/cpuinfo is readable
##
if [ ! -r /proc/cpuinfo ]
then
	echo "Couldn't read /proc/cpuinfo"
	exit 2
fi

##
# Initialize output and variables
##
INPROCESSOR=0
COUNT=0
${ECHO} "<PROCESSORS>"

##
# Read through all lines in /proc/cpuinfo
##
while read line
do

	# Begin a new processor
	if [ "${INPROCESSOR}" != "1" ]
	then
		${ECHO} "\t<PROCESSOR>"
		INPROCESSOR=1
	fi

	# End of processor description
	if [ -z "$line" ];
	then
		${ECHO} "\t</PROCESSOR>"
		INPROCESSOR=0
		COUNT=`expr ${COUNT} + 1`
		continue
	fi

	# Ignore lines we don't want
	echo "${line}" | grep "^\(vendor_id\|cpu family\|model\|model name\|stepping\|cpu MHz\)" > /dev/null
	if [ $? -ne 0 ]
	then
		continue
	fi
	
	# Parse and output the information we want in standard format
	parse_line "$line"

done < /proc/cpuinfo

##
# Cleanup and finish output
##
${ECHO} "</PROCESSORS>"
