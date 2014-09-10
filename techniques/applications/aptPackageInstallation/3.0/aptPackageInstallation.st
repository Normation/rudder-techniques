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
# - APT_PACKAGE_DEBLIST --> The OS dependant packages to install         #
#                                                                        #
# - APT_PACKAGE_DEBACTION -->  The action to be made on these packages   #
#                                                                        #
##########################################################################

bundle agent check_apt_package_installation
{

  vars:
    &APT_PACKAGE_DEBLIST:{name |"apt_package[&i&]" string => "&name&";
    }&

    &APT_PACKAGE_DEBACTION:{action |"apt_action[&i&]" string => "&action&";
    }&

    &APT_PACKAGE_ALLOW_UNTRUSTED:{untrusted |"apt_allow_untrusted[&i&]" string => "&untrusted&";
    }&

    &APT_PACKAGE_VERSION_DEFINITION:{definition |"apt_version_definition[&i&]" string => "&definition&";
    }&

    &APT_PACKAGE_VERSION_CRITERION:{version_criterion |"apt_version_criterion[&i&]" string => "&version_criterion&";
    }&

    &APT_PACKAGE_VERSION:{version |"apt_version[&i&]" string => "&version&";
    }&

    &TRACKINGKEY:{piuuid |"apt_policy_instance_uuid[&i&]" string => "&piuuid&";
    }&

    # "debian_packagelist"  slist => {&APT_PACKAGE_DEBLIST: { "&it&" };separator=", "&};

      "index_aptpkg" slist => getindices("apt_package");

  classes:

      "${index_aptpkg}_package_version_defined" not => strcmp("${apt_version_definition[${index_aptpkg}]}", "default");

  packages:

    debian::
      "${apt_package[${index_aptpkg}]}"
        package_policy  => "${apt_action[${index_aptpkg}]}",
        package_method  => apt_nobulk("30", "${apt_allow_untrusted[${index_aptpkg}]}"),
        classes => kept_if_else("debian_install_kept_${apt_package[${index_aptpkg}]}", "debian_installed_${apt_package[${index_aptpkg}]}", "debian_install_failed_${apt_package[${index_aptpkg}]}"),
        ifvarclass => "!${index_aptpkg}_package_version_defined",
        comment => "Handling ${apt_package[${index_aptpkg}]} using apt_nobulk, policy : ${apt_action[${index_aptpkg}]}";

      "${apt_package[${index_aptpkg}]}"
        package_policy  => "${apt_action[${index_aptpkg}]}",
        package_method  => apt_nobulk("30", "${apt_allow_untrusted[${index_aptpkg}]}"),
        package_select   => "${apt_version_criterion[${index_aptpkg}]}",
        package_version  => "${apt_version[${index_aptpkg}]}",
        classes => kept_if_else("debian_install_kept_${apt_package[${index_aptpkg}]}", "debian_installed_${apt_package[${index_aptpkg}]}", "debian_install_failed_${apt_package[${index_aptpkg}]}"),
        ifvarclass => "${index_aptpkg}_package_version_defined",
        comment => "Handling ${apt_package[${index_aptpkg}]} using apt_nobulk, policy : ${apt_action[${index_aptpkg}]}";

  reports:

    debian::

      "@@packageInstallation@@result_repaired@@${apt_policy_instance_uuid[${index_aptpkg}]}@@Debian/Ubuntu packages@@${apt_package[${index_aptpkg}]}@@${g.execRun}##${g.uuid}@#Performed repair action for deb package ${apt_package[${index_aptpkg}]} with policy: ${apt_action[${index_aptpkg}]}"
        ifvarclass => canonify("debian_installed_${apt_package[${index_aptpkg}]}");

      "@@packageInstallation@@result_error@@${apt_policy_instance_uuid[${index_aptpkg}]}@@Debian/Ubuntu packages@@${apt_package[${index_aptpkg}]}@@${g.execRun}##${g.uuid}@#Error taking action for deb package ${apt_package[${index_aptpkg}]} with policy: ${apt_action[${index_aptpkg}]}"
        ifvarclass => canonify("debian_install_failed_${apt_package[${index_aptpkg}]}");

      "@@packageInstallation@@result_success@@${apt_policy_instance_uuid[${index_aptpkg}]}@@Debian/Ubuntu packages@@${apt_package[${index_aptpkg}]}@@${g.execRun}##${g.uuid}@#No action required for deb package ${apt_package[${index_aptpkg}]} with policy: ${apt_action[${index_aptpkg}]}"
        ifvarclass => canonify("debian_install_kept_${apt_package[${index_aptpkg}]}");

}

body package_method apt_nobulk(apt_pkg_timeout, allow_untrusted)
{

    debian::
        package_changes => "individual";
        package_list_update_ifelapsed => "${apt_pkg_timeout}";

        package_list_command => "/usr/bin/dpkg -l";
        package_list_name_regex    => ".i\s+([^\s:]+).*";
        package_list_version_regex => ".i\s+[^\s]+\s+([^\s]+).*";
        package_installed_regex => ".i.*"; # packages that have been uninstalled may be listed
        package_name_convention => "${name}";

        package_add_command => "/usr/bin/env DEBIAN_FRONTEND=noninteractive LC_ALL=C /usr/bin/apt-get -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef -o APT::Get::AutomaticRemove=false -o Apt::Get::AllowUnauthenticated=${allow_untrusted} --yes install";
        package_list_update_command => "/usr/bin/apt-get update";
        package_delete_command => "/usr/bin/env DEBIAN_FRONTEND=noninteractive LC_ALL=C /usr/bin/apt-get -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef -o APT::Get::AutomaticRemove=false --yes -q remove";
        package_update_command => "/usr/bin/env DEBIAN_FRONTEND=noninteractive LC_ALL=C /usr/bin/apt-get -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef -o APT::Get::AutomaticRemove=false -o Apt::Get::AllowUnauthenticated=${allow_untrusted} --yes install";
        package_verify_command => "/usr/bin/dpkg -s";
        package_noverify_returncode => "1";

}
