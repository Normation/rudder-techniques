# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: 2021 Normation SAS

######################################################
# Setups the Zypper Package Manager                  #
######################################################

bundle agent zypper_package_manager_setup
{

  vars:

      "directive_id"  string => "&TRACKINGKEY&";

      "zmdconf[main][solver.onlyRequires]" string => "&ZYPPER_INSTALLRECOMMENDS&";

      "zypper_sections" slist => getindices("zmdconf");

      "class_prefix"   string => "zypper_package_manager_setup";

  files:

    SuSE::
      "/etc/zypp/zypp.conf"
        create        => "true",
        perms         => mog("644", "root", "0"),
        edit_defaults => noempty_backup,
        edit_line     => set_variable_values_ini("zypper_package_manager_setup.zmdconf", "${zypper_sections}"),
        classes       => classes_generic("${class_prefix}");


  methods:
    SuSE::
      "suse" usebundle => rudder_common_reports_generic("Zypper package manager setup", "${class_prefix}", "${directive_id}", "General settings", "None", "The Zypper package manager setup");

    !SuSE::
      "not applicable" usebundle => rudder_common_report("Zypper package manager setup", "result_na", "${directive_id}", "General settings", "None", "The Zypper package manager setup is not applicable on this system");
}
