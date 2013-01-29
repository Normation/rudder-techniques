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

bundle agent rudder_android_system_configuration(technique_name) {

  classes:
    android::
      "rudder_android_system_language_set" not => strcmp("&ANDROID_SYSTEM_LANGUAGE&", execresult("/system/bin/cf-droid language get", "noshell"));
      "rudder_android_system_keyboard_layout_set" not => strcmp("&ANDROID_SYSTEM_KEYBOARD_LAYOUT&", "fr");
      "rudder_android_system_screen_resolution_set" not => strcmp("&ANDROID_SYSTEM_SCREEN_RESOLUTION&", execresult("/system/bin/androVM-prop get vbox_graph_mode", "noshell"));
      "rudder_android_system_time_zone_set" not => strcmp("&ANDROID_SYSTEM_TIME_ZONE&", execresult("/system/bin/cf-droid timezone get", "noshell"));

  commands:
    android.rudder_android_system_language_set::
      "/system/bin/cf-droid language set &ANDROID_SYSTEM_LANGUAGE&"
        classes   => rudder_common_classes("rudder_android_system_language"),
        comment => "Setting the Android system language";

    android.rudder_android_system_keyboard_layout_set::
      "/system/bin/cf-droid layout set &ANDROID_SYSTEM_KEYBOARD_LAYOUT&"
        classes   => rudder_common_classes("rudder_android_system_keyboard_layout"),
        comment => "Setting the Android system keyboard layout";

    android.rudder_android_system_screen_resolution_set::
      "/system/bin/androVM-prop set vbox_graph_mode &ANDROID_SYSTEM_SCREEN_RESOLUTION&"
        classes   => rudder_common_classes("rudder_android_system_screen_resolution"),
        comment => "Setting the Android system language";

    android.rudder_android_system_time_zone_set::
      "/system/bin/cf-droid language set &ANDROID_SYSTEM_TIME_ZONE&"
        classes   => rudder_common_classes("rudder_android_system_time_zone"),
        comment => "Setting the Android system time zone";

  methods:
    # Here, we will define reports for elements which only have a local visibility.
    "any"
      usebundle  => rudder_common_report("${technique_name}", "result_error", "&TRACKINGKEY&", "User interface", "None", "This Technique is not intended to run on OSes other than Android. Skipping..."),
      ifvarclass => "!android";
    "any"
      usebundle  => rudder_common_report("${technique_name}", "result_error", "&TRACKINGKEY&", "Keyboard settings", "None", "This Technique is not intended to run on OSes other than Android. Skipping..."),
      ifvarclass => "!android";
    "any"
      usebundle  => rudder_common_report("${technique_name}", "result_error", "&TRACKINGKEY&", "Screen resolution", "None", "This Technique is not intended to run on OSes other than Android. Skipping..."),
      ifvarclass => "!android";
    "any"
      usebundle  => rudder_common_report("${technique_name}", "result_error", "&TRACKINGKEY&", "Time settings", "None", "This Technique is not intended to run on OSes other than Android. Skipping..."),
      ifvarclass => "!android";
    "any"
      usebundle  => rudder_common_report("${technique_name}", "result_success", "&TRACKINGKEY&", "User interface", "None", "The Android system language is OK"),
      ifvarclass => "android.!rudder_android_system_language_set";
    "any"
      usebundle  => rudder_common_report("${technique_name}", "result_success", "&TRACKINGKEY&", "Keyboard settings", "None", "The Android keyboard layout is OK"),
      ifvarclass => "android.!rudder_android_system_keyboard_layout_set";
    "any"
      usebundle  => rudder_common_report("${technique_name}", "result_success", "&TRACKINGKEY&", "Screen resolution", "None", "The Android screen resolution is OK"),
      ifvarclass => "android.!rudder_android_system_screen_resolution_set";
    "any"
      usebundle  => rudder_common_report("${technique_name}", "result_success", "&TRACKINGKEY&", "Time settings", "None", "The Android time zone is OK"),
      ifvarclass => "android.!rudder_android_system_time_zone_set";

}

bundle agent rudder_android_system_configuration_reporting(technique_name)
{
  methods:
    # Language configuration
    "any" usebundle => rudder_common_reports_generic("${technique_name}", "rudder_android_system_language", "&TRACKINGKEY&", "User interface", "None", "The Android language configuration");
    # Keyboard layout configuration
    "any" usebundle => rudder_common_reports_generic("${technique_name}", "rudder_android_system_keyboard_layout", "&TRACKINGKEY&", "Keyboard settings", "None", "The Android keyboard layout");
    # Screen resolution configuration
    "any" usebundle => rudder_common_reports_generic("${technique_name}", "rudder_android_system_screen_resolution", "&TRACKINGKEY&", "Screen resolution", "None", "The Android screen resolution");
    # Time zone configuration
    "any" usebundle => rudder_common_reports_generic("${technique_name}", "rudder_android_system_time_zone", "&TRACKINGKEY&", "Time settings", "None", "The Android time zone");

}
