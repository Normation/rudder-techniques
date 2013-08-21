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

        "package_number" int => readstringarrayidx("rpm_data","${sys.workdir}/inputs/rpmPackageInstallation/5.0/rpmPackageInstallationData", "#[^\n]*",":",9000,1600000);
        &! We need to use the i0 notation to have indexes starting at 0, as in readstringarrayidx !&

        &RPM_PACKAGE_REDLIST:{name |"rpm_package[&i0&]" string => "&name&";
        }&

        &RPM_PACKAGE_VERSION:{version |"rpm_version[&i0&]" string => "&version&";
        }&

        &RPM_PACKAGE_POST_HOOK_COMMAND:{command |"rpm_posthook[&i0&]" string => "&command&";
        }&

        "index_rpmpkg" slist => getindices("rpm_package");

        "classes_to_cancel_on_update" slist => { "rpm_package_installation_${index_rpmpkg}_kept", "rpm_package_installation_${index_rpmpkg}_repaired", "rpm_package_installation_${index_rpmpkg}_error", "zmd_kept", "zmd_restarted", "could_not_restart_zmd" };

    classes:

        &RPM_PACKAGE_POST_HOOK_RUN:{run |"execute_command_&i0&" expression => strcmp("&run&", "true");
        }&

        "$(index_rpmpkg)_package_version_defined" not => strcmp("$(rpm_data[$(index_rpmpkg)][1])", "default");

        rudder_promises_generated_repaired::
            "check_rpm_package_installation_class_purged_${classes_to_cancel_on_update}"
                expression => "any",
                classes => cancel_all_classes("${classes_to_cancel_on_update}");

    processes:

        SuSE_10::

            "/usr/lib/zmd/zmd.exe"
                restart_class => "zmd_restart";

    commands:

        "${rpm_posthook[${index_rpmpkg}]}"
            classes => rudder_common_classes("rpm_posthook_${index_rpmpkg}"),
            contain => in_shell,
            ifvarclass => "execute_command_${index_rpmpkg}.rpm_package_installation_${index_rpmpkg}_repaired.!rpm_package_installation_${index_rpmpkg}_error";

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
                classes => rudder_common_classes_persist("rpm_package_installation_${index_rpmpkg}", "${rpm_package_check_interval}"),
                ifvarclass => "!${index_rpmpkg}_package_version_defined.!(rpm_package_installation_${index_rpmpkg}_repaired|rpm_package_installation_${index_rpmpkg}_error|rpm_package_installation_${index_rpmpkg}_kept)",
                comment => "Handling $(rpm_package[$(index_rpmpkg)]) using yum_nobulk, policy : $(rpm_data[$(index_rpmpkg)][0])";

            "$(rpm_package[$(index_rpmpkg)])"
                package_policy   => "$(rpm_data[$(index_rpmpkg)][0])",
                package_method   => generic_nobulk("30"),
                package_select   => "$(rpm_data[$(index_rpmpkg)][2])",
                package_version  => "$(rpm_version[$(index_rpmpkg)])",
                classes => rudder_common_classes_persist("rpm_package_installation_${index_rpmpkg}", "${rpm_package_check_interval}"),
                ifvarclass => "${index_rpmpkg}_package_version_defined.!(rpm_package_installation_${index_rpmpkg}_repaired|rpm_package_installation_${index_rpmpkg}_error|rpm_package_installation_${index_rpmpkg}_kept)",
                comment => "Handling $(rpm_package[$(index_rpmpkg)]) using yum_nobulk, policy : $(rpm_data[$(index_rpmpkg)][0])";

    reports:

        redhat|SuSE::
            "@@packageInstallation@@result_repaired@@$(rpm_data[$(index_rpmpkg)][3])@@RHEL/CentOS/SuSE packages@@$(rpm_package[$(index_rpmpkg)])@@$(g.execRun)##$(g.uuid)@#Performed repair action for RPM package $(rpm_package[$(index_rpmpkg)]) to comply with policy: $(rpm_data[$(index_rpmpkg)][0])"
                ifvarclass => "rpm_package_installation_${index_rpmpkg}_repaired";

            "@@packageInstallation@@result_error@@$(rpm_data[$(index_rpmpkg)][3])@@RHEL/CentOS/SuSE packages@@$(rpm_package[$(index_rpmpkg)])@@$(g.execRun)##$(g.uuid)@#Error taking action for RPM package $(rpm_package[$(index_rpmpkg)]) with policy: $(rpm_data[$(index_rpmpkg)][0])"
                ifvarclass => "rpm_package_installation_${index_rpmpkg}_error";

            "@@packageInstallation@@result_success@@$(rpm_data[$(index_rpmpkg)][3])@@RHEL/CentOS/SuSE packages@@$(rpm_package[$(index_rpmpkg)])@@$(g.execRun)##$(g.uuid)@#No action required for RPM package $(rpm_package[$(index_rpmpkg)]) with policy: $(rpm_data[$(index_rpmpkg)][0])"
                ifvarclass => "rpm_package_installation_${index_rpmpkg}_kept";

            # Update seems to not be able to define classes in some non-update cases
            "@@packageInstallation@@result_success@@$(rpm_data[$(index_rpmpkg)][3])@@RHEL/CentOS/SuSE packages@@$(rpm_package[$(index_rpmpkg)])@@$(g.execRun)##$(g.uuid)@#No action taken for RPM package $(rpm_package[$(index_rpmpkg)]) with policy: $(rpm_data[$(index_rpmpkg)][0])"
                ifvarclass => "!rpm_package_installation_${index_rpmpkg}_kept.!rpm_package_installation_${index_rpmpkg}_repaired.!rpm_package_installation_${index_rpmpkg}_error";

            # Post hooks handling
            # Repaired
            "@@packageInstallation@@result_repaired@@$(rpm_data[$(index_rpmpkg)][3])@@Post-modification hook@@$(rpm_package[$(index_rpmpkg)])@@$(g.execRun)##$(g.uuid)@#Successfully executed post hook ($(rpm_posthook[$(index_rpmpkg)]) for RPM package $(rpm_package[$(index_rpmpkg)])"
                ifvarclass => "rpm_posthook_${index_rpmpkg}_repaired";

            # Error
            "@@packageInstallation@@result_error@@$(rpm_data[$(index_rpmpkg)][3])@@Post-modification hook@@$(rpm_package[$(index_rpmpkg)])@@$(g.execRun)##$(g.uuid)@#Error executing post hook ($(rpm_posthook[$(index_rpmpkg)])) for RPM package $(rpm_package[$(index_rpmpkg)])"
                ifvarclass => "rpm_posthook_${index_rpmpkg}_error";

            # Nothing because kept
            "@@packageInstallation@@result_success@@$(rpm_data[$(index_rpmpkg)][3])@@Post-modification hook@@$(rpm_package[$(index_rpmpkg)])@@$(g.execRun)##$(g.uuid)@#No post hook execution required for RPM package $(rpm_package[$(index_rpmpkg)])"
                ifvarclass => "rpm_posthook_${index_rpmpkg}_kept";

            # Nothing because no post hook set
            "@@packageInstallation@@result_success@@$(rpm_data[$(index_rpmpkg)][3])@@Post-modification hook@@$(rpm_package[$(index_rpmpkg)])@@$(g.execRun)##$(g.uuid)@#No post hook execution set for RPM package $(rpm_package[$(index_rpmpkg)])"
                ifvarclass => "!execute_command_${index_rpmpkg}";


    # ZMD Process presence related reports
    (redhat|SuSE).!SuSE_10::
      "@@packageInstallation@@result_success@@$(rpm_data[$(index_rpmpkg)][3])@@ZMD process@@None@@$(g.execRun)##$(g.uuid)@#ZMD process presence verification not necessary. Skipping ...";

    (redhat|SuSE).SuSE_10.!zmd_restart::
      "@@packageInstallation@@result_success@@$(rpm_data[$(index_rpmpkg)][3])@@ZMD process@@None@@$(g.execRun)##$(g.uuid)@#The ZMD process is present. Skipping ...";

    (redhat|SuSE).SuSE_10.zmd_restarted::
      "@@packageInstallation@@result_repaired@@$(rpm_data[$(index_rpmpkg)][3])@@ZMD process@@None@@$(g.execRun)##$(g.uuid)@#The ZMD daemon was successfully restarted";

    (redhat|SuSE).SuSE_10.could_not_restart_zmd::
      "@@packageInstallation@@result_error@@$(rpm_data[$(index_rpmpkg)][3])@@ZMD process@@None@@$(g.execRun)##$(g.uuid)@#The ZMD daemon failed to restart";

}

body package_method generic_nobulk(rpm_pkg_timeout) {

    package_changes => "individual";

    redhat::
        package_list_command => "/usr/bin/yum list installed";
        package_list_name_regex    => "([^.]+).*";
        package_list_version_regex => "[^\s]\s+([^\s]+).*";
        package_list_arch_regex    => "[^.]+\.([^\s]+).*";
        package_installed_regex => ".*installed.*";
        package_name_convention => "${name}";
        package_list_update_ifelapsed => "$(rpm_pkg_timeout)";
        package_add_command => "/usr/bin/yum -y install";
        package_update_command => "/usr/bin/yum -y update";
        package_delete_command => "/bin/rpm -e";
        package_verify_command => "/bin/rpm -V";

    SuSE_11::
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

