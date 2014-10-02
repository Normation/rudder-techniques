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

##########################################################################
# Installs requested packages by OS                                      #
#                                                                        #
# - RPM_PACKAGE_REDLIST --> The OS dependant packages to install         #
#                                                                        #
# - RPM_PACKAGE_REDACTION -->  The action to be made on these packages   #
#                                                                        #
# - RPM_PACKAGE_VERSION -->  The optionnal package version               #
#                                                                        #
##########################################################################

bundle agent check_rpm_package_installation {

	vars:
      &RPM_PACKAGE_CHECK_INTERVAL:{check_interval |"rpm_package_check_interval" string => "&check_interval&";
      }&

      "package_number" int => readstringarrayidx("rpm_data","${sys.workdir}/inputs/rpmPackageInstallation/4.0/rpmPackageInstallationData", "#[^\n]*",":",9000,1600000);
&! We need to use the i0 notation to have indexes starting at 0, as in readstringarrayidx !&

		&RPM_PACKAGE_REDLIST:{name |"rpm_package[&i0&]" string => "&name&";
		}&

		&RPM_PACKAGE_VERSION:{version |"rpm_version[&i0&]" string => "&version&";
		}&

		"index_rpmpkg" slist => getindices("rpm_package");

    # If the promises have been updated, we need to remove previously
    # defined persistent classes (by setting there persistence to 1 minutes)
    # and cancelling also the classes for this run
    rudder_promises_generated_repaired::
      "unpersist_rpm_kept_classes_${index_rpmpkg}"
        string  => "undefine",
        classes => rudder_always_classes_persist("rpm_package_install_kept_${index_rpmpkg}", "1");

      "rpm_kept_classes_purged_${index_rpmpkg}"
        string  => "undefine",
        classes => cancel_all_classes("rpm_package_install_kept_${index_rpmpkg}");

      "unpersist_rpm_repaired_classes_${index_rpmpkg}"
        string  => "undefine",
        classes => rudder_always_classes_persist("rpm_package_installed_${index_rpmpkg}", "1");

      "rpm_repaired_classes_purged_${index_rpmpkg}"
        string  => "undefine",
        classes => cancel_all_classes("rpm_package_installed_${index_rpmpkg}");

      "unpersist_rpm_error_classes_${index_rpmpkg}"
        string  => "undefine",
        classes => rudder_always_classes_persist("rpm_package_install_failed_${index_rpmpkg}", "1");

      "rpm_error_classes_purged_${index_rpmpkg}"
        string  => "undefine",
        classes => cancel_all_classes("rpm_package_install_failed_${index_rpmpkg}");

      "unpersist_zmd_kept_classes"
        string  => "undefine",
        classes => rudder_always_classes_persist("zmd_kept", "1");

      "zmd_kept_classes_purged"
        string  => "undefine",
        classes => cancel_all_classes("zmd_kept");

      "unpersist_zmd_repaired_classes"
        string  => "undefine",
        classes => rudder_always_classes_persist("zmd_restarted", "1");

      "zmd_repaired_classes_purged"
        string  => "undefine",
        classes => cancel_all_classes("zmd_restarted");

      "unpersist_zmd_error_classes"
        string  => "undefine",
        classes => rudder_always_classes_persist("could_not_restart_zmd", "1");

      "zmd_error_classes_purged"
        string  => "undefine",
        classes => cancel_all_classes("could_not_restart_zmd");


	classes:

		"$(index_rpmpkg)_package_version_defined" not => strcmp("$(rpm_data[$(index_rpmpkg)][1])", "default");

	processes:

		SuSE_10::

			"/usr/lib/zmd/zmd.exe"
				restart_class => "zmd_restart";

	commands:

		zmd_restart::

			"/etc/init.d/novell-zmd"
				args       => "restart",
        classes    => kept_if_else_persist("zmd_kept", "zmd_restarted", "could_not_restart_zmd", "${rpm_package_check_interval}"),
        ifvarclass => "!(zmd_kept|zmd_restarted|could_not_restart_zmd)",
				comment    => "Restart the ZMD daemon";

	packages:

		redhat|SuSE::
			"$(rpm_package[$(index_rpmpkg)])"
				package_policy  => "$(rpm_data[$(index_rpmpkg)][0])",
				package_method  => generic_nobulk("30"),
        classes => class_trigger_rpm_retcodes("rpm_package_installed_${index_rpmpkg}", "rpm_package_install_failed_${index_rpmpkg}", "rpm_package_install_kept_${index_rpmpkg}", "${rpm_package_check_interval}"),
        ifvarclass => "!${index_rpmpkg}_package_version_defined.!(rpm_package_installed_${index_rpmpkg}|rpm_package_install_failed_${index_rpmpkg}|rpm_package_install_kept_${index_rpmpkg})",
				comment => "Handling $(rpm_package[$(index_rpmpkg)]) using yum_nobulk, policy : $(rpm_data[$(index_rpmpkg)][0])";

			"$(rpm_package[$(index_rpmpkg)])"
				package_policy   => "$(rpm_data[$(index_rpmpkg)][0])",
				package_method   => generic_nobulk("30"),
				package_select   => "$(rpm_data[$(index_rpmpkg)][2])",
				package_version  => "$(rpm_version[$(index_rpmpkg)])",
        classes => class_trigger_rpm_retcodes("rpm_package_installed_${index_rpmpkg}", "rpm_package_install_failed_${index_rpmpkg}", "rpm_package_install_kept_${index_rpmpkg}", "${rpm_package_check_interval}"),
        ifvarclass => "${index_rpmpkg}_package_version_defined.!(rpm_package_installed_${index_rpmpkg}|rpm_package_install_failed_${index_rpmpkg}|rpm_package_install_kept_${index_rpmpkg})",
				comment => "Handling $(rpm_package[$(index_rpmpkg)]) using yum_nobulk, policy : $(rpm_data[$(index_rpmpkg)][0])";

	reports:

		redhat|SuSE::

			"@@packageInstallation@@result_repaired@@$(rpm_data[$(index_rpmpkg)][3])@@RHEL/CentOS/SuSE packages@@$(rpm_package[$(index_rpmpkg)])@@$(g.execRun)##$(g.uuid)@#Performed repair action for RPM package $(rpm_package[$(index_rpmpkg)]) to comply with policy: $(rpm_data[$(index_rpmpkg)][0])"
        ifvarclass => canonify("rpm_package_installed_${index_rpmpkg}");

			"@@packageInstallation@@result_error@@$(rpm_data[$(index_rpmpkg)][3])@@RHEL/CentOS/SuSE packages@@$(rpm_package[$(index_rpmpkg)])@@$(g.execRun)##$(g.uuid)@#Error taking action for RPM package $(rpm_package[$(index_rpmpkg)]) with policy: $(rpm_data[$(index_rpmpkg)][0])"
        ifvarclass => canonify("rpm_package_install_failed_${index_rpmpkg}");

			"@@packageInstallation@@result_success@@$(rpm_data[$(index_rpmpkg)][3])@@RHEL/CentOS/SuSE packages@@$(rpm_package[$(index_rpmpkg)])@@$(g.execRun)##$(g.uuid)@#No action required for RPM package $(rpm_package[$(index_rpmpkg)]) with policy: $(rpm_data[$(index_rpmpkg)][0])"
        ifvarclass => canonify("rpm_package_install_kept_${index_rpmpkg}");

			# ZMD Process presence related reports

			"@@packageInstallation@@result_success@@$(rpm_data[$(index_rpmpkg)][3])@@ZMD process@@None@@$(g.execRun)##$(g.uuid)@#ZMD process presence verification not necessary. Skipping ..."
				ifvarclass => "!SuSE_10";

			"@@packageInstallation@@result_success@@$(rpm_data[$(index_rpmpkg)][3])@@ZMD process@@None@@$(g.execRun)##$(g.uuid)@#The ZMD process is present. Skipping ..."
				ifvarclass => "SuSE_10.!zmd_restart";

			"@@packageInstallation@@result_repaired@@$(rpm_data[$(index_rpmpkg)][3])@@ZMD process@@None@@$(g.execRun)##$(g.uuid)@#The ZMD daemon was successfully restarted"
				ifvarclass => "SuSE_10.zmd_restarted";

			"@@packageInstallation@@result_error@@$(rpm_data[$(index_rpmpkg)][3])@@ZMD process@@None@@$(g.execRun)##$(g.uuid)@#The ZMD daemon failed to restart"
				ifvarclass => "SuSE_10.could_not_restart_zmd";

}

body package_method generic_nobulk(rpm_pkg_timeout) {

redhat::
	package_changes => "individual";

	package_list_command => "/usr/bin/yum list installed";
	package_list_name_regex    => "([^.]+).*";
	package_list_version_regex => "[^\s]\s+([^\s]+).*";
	package_list_arch_regex    => "[^.]+\.([^\s]+).*";
	package_installed_regex => ".*installed.*";
	package_name_convention => "$(name).$(arch)";
	package_delete_convention  => "${name}";
	package_list_update_ifelapsed => "$(rpm_pkg_timeout)";
	package_add_command => "/usr/bin/yum -y install";
	package_delete_command => "/bin/rpm -e";
        package_update_command => "/usr/bin/yum -y update";
	package_verify_command => "/bin/rpm -V";

SuSE_11::
	package_changes => "individual";

	package_list_command => "/bin/rpm -qa --queryformat \"i | repos | %{name} | %{version}-%{release} | %{arch}\n\"";
	package_list_update_ifelapsed => "$(rpm_pkg_timeout)";
	package_installed_regex => "i.*";
	package_list_name_regex => "[^|]+\|[^|]+\|\s+([^\s]+).*";
	package_list_version_regex => "[^|]+\|[^|]+\|[^|]+\|\s+([^\s]+).*";
	package_list_arch_regex => "[^|]+\|[^|]+\|[^|]+\|[^|]+\|\s+([^\s]+).*";
	package_name_convention => "$(name)";
	package_add_command => "/usr/bin/zypper --non-interactive install";
	package_delete_command => "/usr/bin/zypper --non-interactive remove --force-resolution";
	package_update_command => "/usr/bin/zypper --non-interactive update";
	package_verify_command => "/usr/bin/zypper --non-interactive verify$";

SuSE_10::
	package_changes => "individual";

	package_list_command => "/bin/rpm -qa --queryformat \"i | repos | %{name} | %{version}-%{release} | %{arch}\n\"";
	package_list_update_ifelapsed => "$(rpm_pkg_timeout)";
	package_installed_regex => "i.*";
	package_list_name_regex    => "[^|]+\|[^|]+\|\s+([^\s]+).*";
	package_list_version_regex => "[^|]+\|[^|]+\|[^|]+\|\s+([^\s]+).*";
	package_list_arch_regex    => "[^|]+\|[^|]+\|[^|]+\|[^|]+\|\s+([^\s]+).*";

	package_name_convention => "$(name)";
	package_add_command => "/usr/bin/rug install -y";
	package_delete_command => "/usr/bin/rug remove -y";
	package_update_command => "/usr/bin/rug update -y";

	package_verify_command => "/usr/bin/rug verify -y$"; # $ means no args
}

body classes class_trigger_rpm_retcodes(if,else,kept, persist)
{
	promise_kept => { "$(kept)" };
	promise_repaired => { "$(if)" };
	repair_failed => { "$(else)" };
	repair_denied    => { "$(else)" };
	repair_timeout   => { "$(else)" };

	# yum and rpm return 0 for almost anything so no difference between kept and repaired here
	kept_returncodes => { "0" };
	failed_returncodes => { "1" };

  persist_time       => "${persist}";
}
