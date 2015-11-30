#####################################################################################
# Copyright 2014 Normation SAS
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
# Setups the Zypper Package Manager                  #
######################################################

bundle agent zypper_package_manager_setup
{

  vars:

      "directive_id"  string => "&TRACKINGKEY&";

      "zmdconf[main][solver.onlyRequires]" string => "&ZYPPER_INSTALLRECOMMENDS&";

      "zypper_sections" slist => getindices("zmdconf");

      "class_prefix"   string => "zypper_package_manager_setup";
  classes:
      

  files:

    SuSE::
      "/etc/zypp/zypp.conf"
        create        => "true",
        perms         => mog("644", "root", "0"),
        edit_defaults => noempty_backup,
        edit_line     => set_variable_values_ini("zypper_package_manager_setup.zmdconf", "${zypper_sections}"),
        classes       => rudder_common_classes("${class_prefix}");


  methods:
    SuSE::
      "suse" usebundle => rudder_common_reports_generic("Zypper package manager setup", "${class_prefix}", "${directive_id}", "General settings", "None", "The Zypper package manager setup");

    !SuSE::
      "not applicable" usebundle => rudder_common_report("Zypper package manager setup", "result_na", "${directive_id}", "General settings", "None", "The Zypper package manager setup is not applicable on this system");
}
