#####################################################################################
# Copyright 2011-2012 Normation SAS
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

######################################################
# Configures the APT Package Manager                 #
######################################################

bundle agent check_apt_settings
{

  vars:

    debian_4::

      "apt_detected_distro" string => "etch";

    debian_5::

      "apt_detected_distro" string => "lenny";

    debian_6::

      "apt_detected_distro" string => "squeeze";

    debian_7::

        "apt_detected_distro" string => "wheezy";

    debian_8::

        "apt_detected_distro" string => "jessie";

    ubuntu_karmic|ubuntu_9_10::

      "apt_detected_distro" string => "karmic";

    ubuntu_lucid|ubuntu_10_4::

      "apt_detected_distro" string => "lucid";

    ubuntu_maverick|ubuntu_10_10::

      "apt_detected_distro" string => "maverick";

    ubuntu_natty|ubuntu_11_4::

        "apt_detected_distro" string => "natty";

    ubuntu_oneiric|ubuntu_11_10::

        "apt_detected_distro" string => "oneiric";

    ubuntu_precise|ubuntu_12_4::

        "apt_detected_distro" string => "precise";

    ubuntu_quantal|ubuntu_12_10::

        "apt_detected_distro" string => "quantal";

    ubuntu_raring|ubuntu_13_4::

        "apt_detected_distro" string => "raring";

    ubuntu_saucy|ubuntu_13_10::

        "apt_detected_distro" string => "saucy";

    ubuntu_trusty|ubuntu_14_4::

        "apt_detected_distro" string => "trusty";

    ubuntu_utopic|ubuntu_14_10::

        "apt_detected_distro" string => "utopic";

    ubuntu_vivid|ubuntu_15_4::

        "apt_detected_distro" string => "vivid";

    ubuntu_willy|ubuntu_15_10::

        "apt_detected_distro" string => "willy";
    apt_installrecommends_edit::

      "aptconf[APT::Install-Recommends]" string => "&APT_INSTALLRECOMMENDS&";

    apt_installsuggests_edit::

      "aptconf[APT::Install-Suggests]" string => "&APT_INSTALLSUGGESTS&";

    any::

&if (APT_HTTPPROXY_URL)&

      "aptconf[Acquire::http::Proxy]" string => "\"&APT_HTTPPROXY_URL&\";";

&endif&

&if (APT_FTPPROXY_URL)&

      "aptconf[Acquire::ftp::Proxy]" string => "\"&APT_FTPPROXY_URL&\";";

&endif&


    &APT_URL:{apt_url |"apt_url[&i&]" string => "&apt_url&";
}&

    &APT_COMPONENT_MAIN, APT_COMPONENT_CONTRIB, APT_COMPONENT_NON_FREE, APT_COMPONENT_RESTRICTED, APT_COMPONENT_UNIVERSE, APT_COMPONENT_MULTIVERSE, APT_COMPONENT_CUSTOM:{main, contrib, nonfree, restricted, universe, multiverse, custom |"apt_components[&i&]" string => "&main& &contrib& &nonfree& &restricted& &universe& &multiverse& &custom&";
}&

    &APT_DISTRIBUTION, APT_DISTRO_AUTODETECT:{apt_distro, apt_autodetect |"apt_distro[&i&]" string => "&if (apt_autodetect)&${apt_detected_distro}&else&&apt_distro&&endif&";
}&

  classes:

    # Repositories edition ?
      "apt_repositories_edit" not => strcmp("&APT_ADDREPOSITORIES&","false");

    # Disable repositories ?
      "apt_disablerepositories" not => strcmp("&APT_DISABLEREPOSITORIES&","false");

    # InstallRecommends edition ?
      "apt_installrecommends_edit" not => strcmp("&APT_INSTALLRECOMMENDS&","dontchange");

    # InstallSuggests edition ?
      "apt_installsuggests_edit" not => strcmp("&APT_INSTALLSUGGESTS&","dontchange");

    any::
      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";

  files:

    debian.apt_repositories_edit::

      "/etc/apt/sources.list.d/rudder-apt.list"
        create => "true",
        perms => m("644"),
        edit_line => set_apt_config_values_tier1("check_apt_settings.apt_url", "check_apt_settings.apt_distro", "check_apt_settings.apt_components"),
        edit_defaults => empty_backup,
        classes => kept_if_else("apt_tier1_kept", "apt_tier1_validated", "apt_tier1_failed");

    debian::

      "/etc/apt/apt.conf.d/99rudder"
        create => "true",
        perms => m("644"),
        edit_defaults => empty_backup,
        edit_line => set_apt_config_values_tier2("check_apt_settings.aptconf"),
        classes => kept_if_else("apt_tier2_kept", "apt_tier2_validated", "apt_tier2_failed");

    debian.apt_disablerepositories.(apt_tier1_validated|apt_tier1_kept)::

      "/etc/apt/sources.list"
        create => "true",
        perms => m("644"),
        edit_defaults => noempty_backup,
        edit_line => comment_lines_matching("^[^#].*$","#"),
        classes => kept_if_else("apt_disabled_kept", "apt_disabled_validated", "apt_disabled_failed");

      "/etc/apt/sources.list.d/.*"
        edit_line => comment_lines_matching("^[^#].*$","#"),
        edit_defaults => noempty_backup,
        file_select => not_rudderaptlist,
        classes => kept_if_else("apt_disabled_kept", "apt_disabled_validated", "apt_disabled_failed");


  methods:

    # SUCCESS if:
    ## Do not need to edit repositories or repositories good = ((apt_tier1_kept|!apt_repositories_edit).!apt_tier1_validated)
    ## and
    ## APT Config good = (apt_tier2_kept.!apt_tier2_validated)
    ## and
    ## No need to disable other repositories (not require or already disabled) = ((!apt_disablerepositories|(apt_disabled_kept|!apt_repositories_edit)).!apt_disabled_validated)
    ## and
    ## No error = !(apt_tier1_failed|apt_tier2_failed|apt_disabled_failed)
    pass3.(((apt_tier1_kept|!apt_repositories_edit).!apt_tier1_validated).(apt_tier2_kept.!apt_tier2_validated).((!apt_disablerepositories|(apt_disabled_kept|!apt_repositories_edit)).!apt_disabled_validated).!(apt_tier1_failed|apt_tier2_failed|apt_disabled_failed))::
      "any" usebundle => rudder_common_report("aptPackageManagerSettings", "result_success", "&TRACKINGKEY&", "aptPackageManagerSettings", "None", "APT settings were all already correct");

    # REPAIRED if:
    ## Need to edit repositories and no error= apt_tier1_validated
    ## or
    ## Need to edit APT config and no error = apt_tier2_validated
    ## or
    ## Need to disable other repositories and no error= apt_disabled_validated
    ## and
    ## No error = !(apt_tier1_failed|apt_tier2_failed|apt_disabled_failed)
    pass3.((apt_tier1_validated|apt_tier2_validated|apt_disabled_validated).(!apt_tier1_failed|!apt_tier2_failed|!apt_disabled_failed))::
      "any" usebundle => rudder_common_report("aptPackageManagerSettings", "result_repaired", "&TRACKINGKEY&", "aptPackageManagerSettings", "None", "Some APT settings were reset");

      # Clear package caches, same class as for repaired reporting
      "force_package_list_update" usebundle => file_remove("/var/rudder/cfengine-community/state/software_update_timestamp_apt-get");



    pass3.apt_tier1_kept::
      "any" usebundle => rudder_common_report("aptPackageManagerSettings", "log_info", "&TRACKINGKEY&", "aptPackageManagerSettings", "None", "APT repositories already correct");

    pass3.apt_tier2_kept::
      "any" usebundle => rudder_common_report("aptPackageManagerSettings", "log_info", "&TRACKINGKEY&", "aptPackageManagerSettings", "None", "APT configuration parameters already correct");

    pass3.apt_tier1_validated::
      "any" usebundle => rudder_common_report("aptPackageManagerSettings", "log_repaired", "&TRACKINGKEY&", "aptPackageManagerSettings", "None", "APT repositories have been reset");

    pass3.apt_tier2_validated::
      "any" usebundle => rudder_common_report("aptPackageManagerSettings", "log_repaired", "&TRACKINGKEY&", "aptPackageManagerSettings", "None", "APT configuration parameters have been reset");

    pass3.apt_tier1_failed::
      "any" usebundle => rudder_common_report("aptPackageManagerSettings", "result_error", "&TRACKINGKEY&", "aptPackageManagerSettings", "None", "APT repositories could not be edited");

    pass3.apt_tier2_failed::
      "any" usebundle => rudder_common_report("aptPackageManagerSettings", "result_error", "&TRACKINGKEY&", "aptPackageManagerSettings", "None", "APT configuration could not be set");

    pass3.apt_disablerepositories::
      "any" usebundle => rudder_common_report("aptPackageManagerSettings", "log_info", "&TRACKINGKEY&", "aptPackageManagerSettings", "None", "APT repository purge has been requested");

    pass3.apt_disabled_validated::
      "any" usebundle => rudder_common_report("aptPackageManagerSettings", "log_repaired", "&TRACKINGKEY&", "aptPackageManagerSettings", "None", "APT repositories deactivation is done");

    pass3.apt_disabled_failed::
      "any" usebundle => rudder_common_report("aptPackageManagerSettings", "result_error", "&TRACKINGKEY&", "aptPackageManagerSettings", "None", "APT repositories deactivation is failed");

    pass3.(!debian)::
      "any" usebundle => rudder_common_report("aptPackageManagerSettings", "result_error", "&TRACKINGKEY&", "aptPackageManagerSettings", "None", "APT cannot be configured on non Debian OSes");

}

bundle edit_line set_apt_config_values_tier1(apt_url, apt_distro, apt_components)
{

  vars:

      "apt_index" slist => getindices("${apt_url}");

  insert_lines:
      "${rudder_parameters.rudder_file_edit_header}"
        location => start,
        insert_type => "preserve_block";

      "deb ${${apt_url}[${apt_index}]} ${${apt_distro}[${apt_index}]} ${${apt_components}[${apt_index}]}";

}

bundle edit_line set_apt_config_values_tier2(tab)

 # Sets the RHS of configuration items in the file of the form
 # LHS RHS
 # If the line is commented out with #, it gets uncommented first.
 # Adds a new line if none exists.
 # The argument is an associative array containing v[LHS]="rhs"

 # Based on set_variable_values from cfengine_stdlib.cf, modified to
 # use whitespace as separator, and to handle commented-out lines.

{
  vars:
      "index" slist => getindices("${tab}");

  # Be careful if the index string contains funny chars
      "cindex[${index}]" string => canonify("${index}");

  field_edits:

  # If the line is there, but commented out, first uncomment it
      "#+${index}\s+.*"
        edit_field => col("\s+","1","${index}","set");

  # match a line starting like the key something
      "${index}\s+.*"
        edit_field => col("\s+","2","${${tab}[${index}]}","set"),
        classes => if_ok("not_${cindex[${index}]}");

  insert_lines:

  "// ### File managed by Rudder, edit with care ###"
        location => start;

      "${index} ${${tab}[${index}]}"
        ifvarclass => "!not_${cindex[${index}]}";

}

body file_select not_rudderaptlist
{
        leaf_name => { "^[^rudder.*?\.list].*" };
        file_result => "leaf_name";
}
