#####################################################################################
# Copyright 2011 Normation SAS
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

##########################################################################
# Installs requested packages by OS                                      #
#                                                                        #
# - RPM_PACKAGE_REDLIST --> The OS dependant packages to install         #
#                                                                        #
# - RPM_PACKAGE_REDACTION -->  The action to be made on these packages   #
#                                                                        #
##########################################################################

bundle agent check_rpm_package_installation
{

  vars:
    &RPM_PACKAGE_REDLIST:{name |"rpm_package[&i&]" string => "&name&";
    }&

    &RPM_PACKAGE_REDACTION:{action |"rpm_action[&i&]" string => "&action&";
    }&

    &TRACKINGKEY:{directiveId |"rpm_directive_id[&i&]" string => "&directiveId&";
    }&

      "index_rpmpkg" slist => getindices("rpm_package");

  packages:

    redhat::

      "${rpm_package[${index_rpmpkg}]}"
        package_policy  => "${rpm_action[${index_rpmpkg}]}",
        package_method  => yum_nobulk("30"),
        classes => class_trigger_rpm_retcodes("rpm_package_installed_${rpm_package[${index_rpmpkg}]}", "rpm_package_install_failed_${rpm_package[${index_rpmpkg}]}", "rpm_package_install_kept_${rpm_package[${index_rpmpkg}]}"),
        comment => "Handling ${rpm_package[${index_rpmpkg}]} using yum_nobulk, policy : ${rpm_action[${index_rpmpkg}]}";

    SuSE::

      "${rpm_package[${index_rpmpkg}]}"
        package_policy  => "${rpm_action[${index_rpmpkg}]}",
        package_method  => zypper_nobulk("30"),
        classes => class_trigger_rpm_retcodes("rpm_package_installed_${rpm_package[${index_rpmpkg}]}", "rpm_package_install_failed_${rpm_package[${index_rpmpkg}]}", "rpm_package_install_kept_${rpm_package[${index_rpmpkg}]}"),
        comment => "Handling ${rpm_package[${index_rpmpkg}]} using zypper_nobulk, policy : ${rpm_action[${index_rpmpkg}]}";

  reports:

    redhat|SuSE::

      "@@packageInstallation@@result_repaired@@${rpm_directive_id[${index_rpmpkg}]}@@RHEL/CentOS/SuSE packages@@${rpm_package[${index_rpmpkg}]}@@${g.execRun}##${g.uuid}@#Performed repair action for RPM package ${rpm_package[${index_rpmpkg}]} to comply with policy: ${rpm_action[${index_rpmpkg}]}"
        ifvarclass => canonify("rpm_package_installed_${rpm_package[${index_rpmpkg}]}");

      "@@packageInstallation@@result_error@@${rpm_directive_id[${index_rpmpkg}]}@@RHEL/CentOS/SuSE packages@@${rpm_package[${index_rpmpkg}]}@@${g.execRun}##${g.uuid}@#Error taking action for RPM package ${rpm_package[${index_rpmpkg}]} with policy: ${rpm_action[${index_rpmpkg}]}"
        ifvarclass => canonify("rpm_package_install_failed_${rpm_package[${index_rpmpkg}]}");

      "@@packageInstallation@@result_success@@${rpm_directive_id[${index_rpmpkg}]}@@RHEL/CentOS/SuSE packages@@${rpm_package[${index_rpmpkg}]}@@${g.execRun}##${g.uuid}@#No action required for RPM package ${rpm_package[${index_rpmpkg}]} with policy: ${rpm_action[${index_rpmpkg}]}"
        ifvarclass => canonify("rpm_package_install_kept_${rpm_package[${index_rpmpkg}]}");

}

body package_method yum_nobulk(rpm_pkg_timeout)
{

    redhat::
        package_changes => "individual";
        package_list_command => "/usr/bin/yum list installed";
        package_list_name_regex    => "([^.]+).*";
        package_list_version_regex => "[^\s]\s+([^\s]+).*";
        package_list_arch_regex    => "[^.]+\.([^\s]+).*";
        package_installed_regex => ".*installed.*";
        package_name_convention => "${name}.${arch}";
        package_delete_convention  => "${name}";
        package_list_update_ifelapsed => "${rpm_pkg_timeout}";
        package_add_command => "/usr/bin/yum -y install";
        package_delete_command => "/bin/rpm -e";
        package_update_command => "/usr/bin/yum -y update";
        package_verify_command => "/bin/rpm -V";

}

body package_method zypper_nobulk(rpm_pkg_timeout)
{

    SuSE::
        package_changes => "individual";
        package_list_command => "/bin/rpm -qa --queryformat \"i | repos | %{name} | %{version}-%{release} | %{arch}\n\"";
        package_list_update_ifelapsed => "${rpm_pkg_timeout}";
        package_installed_regex => "i.*";
        package_list_name_regex => "[^|]+\|[^|]+\|\s+([^\s]+).*";
        package_list_version_regex => "[^|]+\|[^|]+\|[^|]+\|\s+([^\s]+).*";
        package_list_arch_regex => "[^|]+\|[^|]+\|[^|]+\|[^|]+\|\s+([^\s]+).*";
        package_name_convention => "${name}";
        package_add_command => "/usr/bin/zypper --non-interactive install";
        package_delete_command => "/usr/bin/zypper --non-interactive remove --force-resolution";
        package_update_command => "/usr/bin/zypper --non-interactive update";
        package_verify_command => "/usr/bin/zypper --non-interactive verify$";
}

body classes class_trigger_rpm_retcodes(if,else,kept)
{
        promise_kept => { "${kept}" };
        promise_repaired => { "${if}" };
        repair_failed => { "${else}" };
        repair_denied    => { "${else}" };
        repair_timeout   => { "${else}" };

  # yum and rpm return 0 for almost anything so no difference between kept and repaired here
        kept_returncodes => { "0" };
        failed_returncodes => { "1" };
}

