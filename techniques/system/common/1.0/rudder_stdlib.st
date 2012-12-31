#####################################################################################
# Copyright 2012 Normation SAS
#####################################################################################
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, Version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#####################################################################################
#
# Rudder Promise Body and Bundle Library
#
# This library includes standardized bundles and bodies to be used as part of the
# "best practices" in the Techniques writing
#

##################################################
# classes body
##################################################

#
# Automatically defines classes bases on a given prefix
# The classes are defined based on the romises outcome
#
body classes rudder_common_classes(prefix)
{
  promise_kept     => { "${prefix}_kept" };
  promise_repaired => { "${prefix}_repaired" };
  repair_failed    => { "${prefix}_failed" , "${prefix}_error" };
  repair_denied    => { "${prefix}_denied" , "${prefix}_error" };
  repair_timeout   => { "${prefix}_timeout", "${prefix}_error" };
}


##################################################
# files bundles
##################################################

#
# Insert the standard Rudder disclaimer into a file
#
bundle edit_line rudder_common_disclaimer
{
  insert_lines:
    "#############################################################
### This file is protected by your Rudder infrastructure. ###
### Manually editing the file might lead your Rudder      ###
### infrastructure to change back the server’s            ###
### configuration and/or to raise a compliance alert.     ###
#############################################################
"
      location => start,
      insert_type => "preserve_block";
}


################################################
# Reporting bundles
################################################

#
# Create and send a report to the server
# This bundle takes 6 parameters :
# technique_name : the name of the technique, human readable
# status         : the status of the Component, among the following values
#    result_success
#    result_error
#    result_repaired
#    log_repaired (for logging only)
#    log_warn     (for logging only)
#    log_info     (for logging only)
#    log_debug    (for logging only)
#    log_trace    (for logging only)
# identifier     : the identifier of the current Rule and Directive
# component_name : the name of the component within the Technique
# component_key  : the value of the component reference variable (or None if undefined)
# message        : An explanation message understandable by a human
#
bundle agent rudder_common_report(technique_name, status, identifier, component_name, component_key, message)
{
  reports:
    linux|!linux::
      "@@${technique_name}@@${status}@@${identifier}@@${component_name}@@${component_key}@@$(g.execRun)##$(g.uuid)@#${message}";
}


#
# Automatically create reports based on existing classes starting by 
# class_prefix (as defined by the body classes rudder_common_classes)
# Takes 6 parameters
# technique_name : the name of the technique, human readable
# class_prefix   : the prefix of a set of classes to reporting on (suffixes with "kept", "repaired" or "error")
# identifier     : the identifier of the current Rule and Directive
# component_name : the name of the component within the Technique
# component_key  : the value of the component reference variable (None if it does not exists)
# message_prefix : The begining of an explanation message understandable by a human
#
bundle agent rudder_common_reports_generic(technique_name, class_prefix, identifier, component_name, component_key, message_prefix)
{
  methods:
    "success"
      usebundle  => rudder_common_report("${technique_name}", "result_success", "${identifier}", "${component_name}", "${component_key}", "${message_prefix} was correct"),
      ifvarclass => "${class_prefix}_kept.!${class_prefix}_repaired.!${class_prefix}_error";

    "repaired"
      usebundle  => rudder_common_report("${technique_name}", "result_repaired", "${identifier}", "${component_name}", "${component_key}", "${message_prefix} was repaired"),
      ifvarclass => "${class_prefix}_repaired.!${class_prefix}_error";

    "error"
      usebundle  => rudder_common_report("${technique_name}", "result_error", "${identifier}", "${component_name}", "${component_key}", "${message_prefix} could not be repaired"),
      ifvarclass => "${class_prefix}_error";
}

