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

######################################################
# Configures the RUG/YaST Package Managers using ZMD #
######################################################

bundle agent check_zmd_settings
{
  vars:

    proxy_edit::
      "zmdconf[Network][proxy-url]"      string => "&ZMD_PROXY_URL&";

    proxy_edit_user::
      "zmdconf[Network][proxy-username]" string => "&ZMD_PROXY_USER&";

    proxy_edit_password::
      "zmdconf[Network][proxy-password]" string => "&ZMD_PROXY_PASSWORD&";

    class_ok::
      &TRACKINGKEY:{directiveId |"zmdconf_uuid[&i&]" string => "&directiveId&";
}&

&if(ZMD_SET_REFRESH_INTERVAL)&
      "zmdconf[Server][refresh-interval]" string => "&ZMD_REFRESH_INTERVAL&";
&endif&
      "zmdconf[Advanced][security-level]" string => "&ZMD_SOURCEPOLICY&";

      "zmdconf[Server][remote-enabled]"   string => "&ZMD_REMOTE_ENABLED&";

      "zmdconf[Debug][syslog-level]"      string => "&ZMD_SYSLOG_LEVEL&";

      "zmd_sections"                      slist  => getindices("zmdconf");
      "zmd_index"                         slist  => getindices("zmdconf_uuid");

  classes:

      # Do we want to set the proxy ?
      "proxy_edit"          not => strcmp("&ZMD_PROXY_URL&", "");

      # Do we want to set the proxy username ?
      "proxy_edit_user"     not => strcmp("&ZMD_PROXY_USER&", "");

      # Do we want to set the proxy username ?
      "proxy_edit_password" not => strcmp("&ZMD_PROXY_PASSWORD&", "");

      # Check if any settings have to be checked
      "security_level_edit" not => strcmp("&ZMD_SOURCEPOLICY&", "dontchange");
      "remote_enabled_edit" not => strcmp("&ZMD_REMOTE_ENABLED&", "dontchange");
      "syslog_level_edit"   not => strcmp("&ZMD_SYSLOG_LEVEL&", "dontchange");
      "settings_edition"    or  => {
                                     "proxy_edit",
                                     "proxy_edit_user",
                                     "proxy_edit_password",
                                     "security_level_edit",
                                     "remote_enabled_edit",
                                     "syslog_level_edit"
                                     };

      "class_ok" expression => strcmp("true", "true");

  processes:

     "/usr/lib/zmd/zmd.exe" restart_class => "zmd_restart";

  commands:

    settings_edition.SuSE.checkzmd_present::
      "${g.rudder_dependencies}/checkzmd.pl \"$(zmd_name[$(zmd_index)])\" \"$(zmd_url[$(zmd_index)])\" $(zmd_index)"
        contain => in_shell,
        module => "true",
        comment => "Analyzing ZMD's output";

    settings_edition.SuSE.(zmd_restart|zmd_conf_validated)::
      "/etc/init.d/novell-zmd"
        args => "restart",
        classes => kept_if_else("zmd_kept", "zmd_restarted", "could_not_restart_zmd"),
        comment => "Restart the ZMD daemon";

  files:

    settings_edition.SuSE::
      "/etc/zmd/zmd.conf"
        create => "true",
        perms => mog("600", "root", "root"),
        edit_defaults => noempty_backup,
        edit_line => set_advanced_zmd_config_values("check_zmd_settings.zmdconf", "$(zmd_sections)"),
        classes => kept_if_else("zmd_conf_kept", "zmd_conf_validated", "zmd_conf_failed");

  reports:

    # ZMD settings edition
    !settings_edition::
      "@@zmdPackageManagerSettings@@result_success@@${zmdconf_uuid[${zmd_index}]}@@General settings@@None@@$(g.execRun)##$(g.uuid)@#No ZMD settings were specified. Skipping...";

    zmd_conf_kept::
      "@@zmdPackageManagerSettings@@result_success@@${zmdconf_uuid[${zmd_index}]}@@General settings@@None@@$(g.execRun)##$(g.uuid)@#ZMD settings were all already correct";

    zmd_conf_validated::
      "@@zmdPackageManagerSettings@@result_repaired@@${zmdconf_uuid[${zmd_index}]}@@General settings@@None@@$(g.execRun)##$(g.uuid)@#Some ZMD settings were reset";

    zmd_conf_failed::
      "@@zmdPackageManagerSettings@@result_error@@${zmdconf_uuid[${zmd_index}]}@@General settings@@None@@$(g.execRun)##$(g.uuid)@#ZMD repositories could not be edited";

    # Ignore non-SuSE OSes
    !SuSE::
      "@@zmdPackageManagerSettings@@result_error@@${zmdconf_uuid[${zmd_index}]}@@General settings@@None@@$(g.execRun)##$(g.uuid)@#ZMD cannot be configured on non SuSE OSes";

    SuSE::
    # ZMD Process presence related reports
      "@@zmdPackageManagerSettings@@result_success@@${zmdconf_uuid[${zmd_index}]}@@ZMD process@@None@@$(g.execRun)##$(g.uuid)@#The ZMD process is present. Skipping ..."
        ifvarclass => "!zmd_restart";

      "@@zmdPackageManagerSettings@@result_repaired@@${zmdconf_uuid[${zmd_index}]}@@ZMD process@@None@@$(g.execRun)##$(g.uuid)@#The ZMD daemon was successfully restarted"
        ifvarclass => "zmd_restarted";

      "@@zmdPackageManagerSettings@@result_error@@${zmdconf_uuid[${zmd_index}]}@@ZMD process@@None@@$(g.execRun)##$(g.uuid)@#The ZMD daemon failed to restart"
        ifvarclass => "could_not_restart_zmd";

}


bundle edit_line set_advanced_zmd_config_values(tab, sectionName)
{
# Sets the RHS of configuration items in the file of the form
# LHS=RHS
# If the line is commented out with #, it gets uncommented first.
# Adds a new line if none exists.
# The argument is an associative array containing tab[SectionName][LHS]="RHS"
# don't change value when the RHS is dontchange

 # Based on set_variable_values from cfengine_stdlib.cf, modified to
 # use section to define were to write, and to handle commented-out lines.

 # CAUTION : for it to work nicely, you should use Cfengine with the commit n°3229
 # otherwise you may risk a segfault 

  vars:

      "index"            slist  => getindices("$(tab)[$(sectionName)]");

       # Be careful if the index string contains funny chars
      "cindex[$(index)]" string => canonify("$(index)");

  classes:

      "edit_$(cindex[$(index)])" not => strcmp("$($(tab)[$(sectionName)][$(index)])","dontchange");

  field_edits:

      # If the line is there, but commented out, first uncomment it
      "#+$(index)=.*"
        select_region => INI_section("$(sectionName)"),
        edit_field    => col("=","1","$(index)","set"),
        ifvarclass    => "edit_$(cindex[$(index)])";

      # match a line starting like the key something
      "$(index)=.*"
        edit_field    => col("=","2","$($(tab)[$(sectionName)][$(index)])","set"),
        select_region => INI_section("$(sectionName)"),
        classes       => if_ok("not_$(cindex[$(index)])"),
        ifvarclass    => "edit_$(cindex[$(index)])";

  insert_lines:

      "[$(sectionName)]" location => start;

      "$(index)=$($(tab)[$(sectionName)][$(index)])",
        select_region => INI_section("$(sectionName)"),
        ifvarclass    => "!not_$(cindex[$(index)]).edit_$(cindex[$(index)])";
}
