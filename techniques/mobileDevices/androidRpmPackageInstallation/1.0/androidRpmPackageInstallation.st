#####################################################################################
# Copyright 2011-2013 Normation SAS
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

bundle agent android_rpm_pkg_installation {

	vars:
		&ANDROID_RPM_PACKAGE_NAME:{name |"rpm_package[&i&]" string => "&name&";
		}&

		&ANDROID_RPM_PACKAGE_PATH:{path |"rpm_path[&i&]" string => "&path&";
		}&

		&ANDROID_RPM_PACKAGE_ACTION:{action |"rpm_action[&i&]" string => "&action&";
		}&

		&ANDROID_RPM_PACKAGE_VERSION:{version |"rpm_version[&i&]" string => "&version&";
		}&

		&ANDROID_RPM_PACKAGE_ARCHITECTURE:{arch |"rpm_arch[&i&]" string => "&arch&";
		}&

		&TRACKINGKEY:{piuuid |"rpm_policy_instance_uuid[&i&]" string => "&piuuid&";
		}&

		"index_rpmpkg" slist => getindices("rpm_package");

	packages:

		android::

			"$(rpm_package[$(index_rpmpkg)])"
				package_policy         => "$(rpm_action[$(index_rpmpkg)])",
				package_version        => "$(rpm_version[$(index_rpmpkg)])",
				package_architectures  => { "$(rpm_arch[$(index_rpmpkg)])" },
				package_method         => android_rpm_filebased("$(rpm_path[$(index_rpmpkg)])/", "/system/sbin/rpm"),
				classes                => kept_if_else("rpm_package_install_kept_$(rpm_package[$(index_rpmpkg)])", "rpm_package_installed_$(rpm_package[$(index_rpmpkg)])", "rpm_package_install_failed_$(rpm_package[$(index_rpmpkg)])"),
				comment                => "Handling $(rpm_package[$(index_rpmpkg)]) using Android RPM installation method, policy : $(rpm_action[$(index_rpmpkg)])";

	reports:

		android::

			"@@androidRpmPackageInstallation@@result_repaired@@$(rpm_policy_instance_uuid[$(index_rpmpkg)])@@RPM packages@@$(rpm_package[$(index_rpmpkg)])@@$(g.execRun)##$(g.uuid)@#Performed repair action for RPM package $(rpm_package[$(index_rpmpkg)]) to comply with policy: $(rpm_action[$(index_rpmpkg)])"
				ifvarclass => canonify("rpm_package_installed_$(rpm_package[$(index_rpmpkg)])");

			"@@androidRpmPackageInstallation@@result_error@@$(rpm_policy_instance_uuid[$(index_rpmpkg)])@@RPM packages@@$(rpm_package[$(index_rpmpkg)])@@$(g.execRun)##$(g.uuid)@#Error taking action for RPM package $(rpm_package[$(index_rpmpkg)]) with policy: $(rpm_action[$(index_rpmpkg)])"
				ifvarclass => canonify("rpm_package_install_failed_$(rpm_package[$(index_rpmpkg)])");

			"@@androidRpmPackageInstallation@@result_success@@$(rpm_policy_instance_uuid[$(index_rpmpkg)])@@RPM packages@@$(rpm_package[$(index_rpmpkg)])@@$(g.execRun)##$(g.uuid)@#No action required for RPM package $(rpm_package[$(index_rpmpkg)]) with policy: $(rpm_action[$(index_rpmpkg)])"
				ifvarclass => canonify("rpm_package_install_kept_$(rpm_package[$(index_rpmpkg)])");

		!android::

			"@@androidRpmPackageInstallation@@result_repaired@@$(rpm_policy_instance_uuid[$(index_rpmpkg)])@@RPM packages@@$(rpm_package[$(index_rpmpkg)])@@$(g.execRun)##$(g.uuid)@#Can not operate on the given package ($(rpm_path[$(index_rpmpkg)])/$(rpm_package[$(index_rpmpkg)])): This is NOT an Android OS";

}

body package_method android_rpm_filebased(path, rpm_binary)

# Contributed by Aleksey Tsalolikhin. Written on 29-Feb-2012.
# Based on yum_rpm body in COPBL by Trond Hasle Amundsen.
# Purpose: install packages from local filesystem-based package repository.
# Note: Specify the path to the local package repository in the argument.
  
# Example of how to use it:
#
# {{{
# packages:
# "epel-release"
# package_policy => "add",
# package_version => "5-4",
# package_architectures => { "noarch" },
# package_method => rpm_filebased("/repo/RPMs");
# }}}

{
  package_file_repositories => { "$(path)" };
    
  package_name_convention => "$(name)-$(version).$(arch).rpm";
  # The above is a change from Tron's yum_rpm body. When package_file_repositories is in play,
  # package_name_convention has to match the file name, not the package name, per the
  # CFEngine 3 Reference Manual

  # set it to "0" to avoid caching of list during upgrade. Default is 240.
  package_list_update_ifelapsed => "0";
  
  # The rest is unchanged from Trond's yum_rpm body
  package_changes => "individual";
  package_list_command => "/system/bin/rpm --nosignature --nodigest -qa --qf '%{name} %{version}-%{release} %{arch}\n' | /system/xbin/grep -v 'Option\|type:\|rpmcli\|rpmQVS\|my_value \|Last option\|Got opt\|config files\| 0 0\|List\|poptG\|_progname\|bigMode ='";

  package_list_name_regex => "^(\S+?)\s\S+?\s\S+$";
  package_list_version_regex => "^\S+?\s(\S+?)\s\S+$";
  package_list_arch_regex => "^\S+?\s\S+?\s(\S+)$";
  
  package_installed_regex => ".*";
  
  package_add_command => "/system/sbin/rpm -ihv ";
  package_update_command => "/system/sbin/rpm -Uhv ";
  package_delete_command => "/system/sbin/rpm -e --allmatches";
  package_verify_command => "/system/sbin/rpm -V";
}
