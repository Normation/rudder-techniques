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
      "@@${technique_name}@@${status}@@${identifier}@@${component_name}@@${component_key}@@${g.execRun}##${g.uuid}@#${message}";
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


##--------------------------------------------------------------
## Packages promises
##--------------------------------------------------------------

body package_method rudder_generic
{
  package_changes => "individual";

 SuSE::
  package_list_command => "/bin/rpm -qa --queryformat \"i | repos | %{name} | %{version}-%{release} | %{arch}\n\"";
  # set it to "0" to avoid caching of list during upgrade
  package_list_update_command => "/usr/bin/zypper list-updates";
  package_list_update_ifelapsed => "0";
  package_patch_list_command => "/usr/bin/zypper patches";
  package_installed_regex => "i.*";
  package_list_name_regex    => "[^|]+\|[^|]+\|\s+([^\s]+).*";
  package_list_version_regex => "[^|]+\|[^|]+\|[^|]+\|\s+([^\s]+).*";
  package_list_arch_regex    => "[^|]+\|[^|]+\|[^|]+\|[^|]+\|\s+([^\s]+).*";
  package_patch_installed_regex => ".*Installed.*|.*Not Applicable.*";
  package_patch_name_regex    => "[^|]+\|\s+([^\s]+).*";
  package_patch_version_regex => "[^|]+\|[^|]+\|\s+([^\s]+).*";
  package_name_convention => "$(name)";
  package_add_command => "/usr/bin/zypper --non-interactive install";
  package_delete_command => "/usr/bin/zypper --non-interactive remove --force-resolution";
  package_update_command => "/usr/bin/zypper --non-interactive update";
  package_patch_command => "/usr/bin/zypper --non-interactive patch$"; # $ means no args
  package_verify_command => "/usr/bin/zypper --non-interactive verify$";

 redhat::
  package_list_command => "/bin/rpm -qa --qf '%{name} %{version}-%{release} %{arch}\n'";
  package_patch_list_command => "/usr/bin/yum --quiet check-update";
  package_list_name_regex    => "^(\S+?)\s\S+?\s\S+$";
  package_list_version_regex => "^\S+?\s(\S+?)\s\S+$";
  package_list_arch_regex    => "^\S+?\s\S+?\s(\S+)$";
  package_installed_regex => ".*";
  package_name_convention => "$(name)";
  package_list_update_command => "/usr/bin/yum --quiet check-update";
  package_list_update_ifelapsed => "0";     # sometimes, caching is pretty disturbing
  package_patch_installed_regex => "^\s.*";
  package_patch_name_regex    => "([^.]+).*";
  package_patch_version_regex => "[^\s]\s+([^\s]+).*";
  package_patch_arch_regex    => "[^.]+\.([^\s]+).*";
  package_add_command    => "/usr/bin/yum -y install";
  package_update_command => "/usr/bin/yum -y update";
  package_patch_command => "/usr/bin/yum -y update";
  package_delete_command => "/bin/rpm -e --nodeps --allmatches";
  package_verify_command => "/bin/rpm -V";


 debian::
  package_list_command => "/usr/bin/dpkg -l";
  package_list_name_regex    => ".i\s+([^\s]+).*";
  package_list_version_regex => ".i\s+[^\s]+\s+([^\s]+).*";
  package_installed_regex => ".i.*"; # packages that have been uninstalled may be listed
  package_name_convention => "$(name)";
  package_list_update_ifelapsed => "240";		# 4 hours
 
 debian.have_aptitude::
  package_add_command => "/usr/bin/env DEBIAN_FRONTEND=noninteractive LC_ALL=C /usr/bin/aptitude -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef --assume-yes install";
  package_list_update_command => "/usr/bin/aptitude update";
  package_delete_command => "/usr/bin/env DEBIAN_FRONTEND=noninteractive LC_ALL=C /usr/bin/aptitude -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef --assume-yes remove";
  package_update_command =>  "/usr/bin/env DEBIAN_FRONTEND=noninteractive LC_ALL=C /usr/bin/aptitude -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef --assume-yes install";
  package_patch_command =>  "/usr/bin/env DEBIAN_FRONTEND=noninteractive LC_ALL=C /usr/bin/aptitude -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef --assume-yes install";
  package_verify_command =>  "/usr/bin/aptitude show";
  package_noverify_regex => "(State: not installed|E: Unable to locate package .*)";

  package_patch_list_command => "/usr/bin/aptitude --assume-yes --simulate --verbose full-upgrade";
  package_patch_name_regex => "^Inst\s+(\S+)\s+.*";
  package_patch_version_regex => "^Inst\s+\S+\s+\[?\(?([^\],\s]+).*";

 debian.!have_aptitude::
  package_add_command => "/usr/bin/env DEBIAN_FRONTEND=noninteractive LC_ALL=C /usr/bin/apt-get -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef --yes install";
  package_list_update_command => "/usr/bin/apt-get update";
  package_delete_command => "/usr/bin/env DEBIAN_FRONTEND=noninteractive LC_ALL=C /usr/bin/apt-get -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef --yes remove";
  package_update_command =>  "/usr/bin/env DEBIAN_FRONTEND=noninteractive LC_ALL=C /usr/bin/apt-get -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef --yes install";
  package_patch_command =>  "/usr/bin/env DEBIAN_FRONTEND=noninteractive LC_ALL=C /usr/bin/apt-get -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef --yes install";
  package_verify_command => "/usr/bin/dpkg -s";
  package_noverify_returncode => "1";
  package_patch_list_command => "/usr/bin/apt-get --just-print dist-upgrade";
  package_patch_name_regex => "^Inst\s+(\S+)\s+.*";
  package_patch_version_regex => "^Inst\s+\S+\s+\[?\(?([^\],\s]+).*";

 freebsd::
  package_list_command => "/usr/sbin/pkg_info";
  package_list_name_regex    => "([^\s]+)-.*";
  package_list_version_regex => "[^\s]+-([^\s]+).*";
  package_name_regex    => "([^\s]+)-.*";
  package_version_regex => "[^\s]+-([^\s]+).*";
  package_installed_regex => ".*";
  package_name_convention => "$(name)-$(version)";
  package_add_command => "/usr/sbin/pkg_add -r";
  package_delete_command => "/usr/sbin/pkg_delete";

 gentoo::
  package_list_command => "/bin/sh -c '/bin/ls -d /var/db/pkg/*/* | cut -c 13-'";
  package_list_name_regex => ".*/([^\s]+)-\d.*";
  package_list_version_regex => ".*/[^\s]+-(\d.*)";
  package_installed_regex => ".*";                          # all reported are installed
  package_name_convention => "$(name)";
  package_list_update_command => "/bin/true";               # I prefer manual syncing
  #package_list_update_command => "/usr/bin/emerge --sync"; # if you like automatic
  package_list_update_ifelapsed => "240";                   # should happen every 4 hours
    
  package_add_command => "/usr/bin/emerge -q --quiet-build";
  package_delete_command => "/usr/bin/emerge --depclean";
  package_update_command => "/usr/bin/emerge --update";
  package_patch_command => "/usr/bin/emerge --update";
  package_verify_command => "/usr/bin/emerge -s";
  package_noverify_regex => ".*(Not Installed|Applications found : 0).*";

 archlinux::
  package_list_command => "/usr/bin/pacman -Q";
  package_list_name_regex    => "(.*)\s+.*";
  package_list_version_regex => ".*\s+(.*)";
  package_installed_regex => ".*";
  package_name_convention => "$(name)";
  package_list_update_ifelapsed => "240";
  package_add_command => "/usr/bin/pacman -S --noconfirm --noprogressbar --needed";
  package_delete_command => "/usr/bin/pacman -Rs --noconfirm";
  package_update_command => "/usr/bin/pacman -S --noconfirm --noprogressbar --needed";
}
