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

bundle agent check_apache_configuration
{


  vars:

      # Ports
      "apache_ports" slist => {&APACHE_PORTS: { "&it&" };separator=", "&};

      # List of all the files to permit on the vhost directory
      "vhosts_files" slist => { "ports.conf", "security.conf", &APACHE_VHOST_FQDN: { "vhost-&it&.conf" };separator=", "&};

      # Security config
      "apache_security[ServerTokens]" string => "&APACHE_SERVERTOKENS&";

      "apache_security[ServerSignature]" string => "&APACHE_SERVERSIGNATURE&";

      "apache_security[TraceEnable]" string => "&APACHE_TRACEENABLE&";

      # Virtual Hosts
      &APACHE_VHOST_FQDN:{fqdn |"apache_vhost_fqdn[&i&]" string => "&fqdn&";
}&
      &APACHE_VHOST_PORT:{port |"apache_vhost_port[&i&]" string => "&port&";
}&
      &APACHE_VHOST_ROOT:{root |"apache_vhost_root[&i&]" string => "&root&";
}&
      &APACHE_VHOST_EXPIRES:{expires |"apache_vhost_expires[&i&]" string => "&expires&";
}&
      &APACHE_VHOST_EXPIRES_TTL:{expires_ttl |"apache_vhost_expires_ttl[&i&]" string => "&expires_ttl&";
}&
      &APACHE_VHOST_ALIAS_ONE_SRC:{alias_one_src |"apache_vhost_alias_one_src[&i&]" string => "&alias_one_src&";
}&
      &APACHE_VHOST_ALIAS_ONE_DST:{alias_one_dst |"apache_vhost_alias_one_dst[&i&]" string => "&alias_one_dst&";
}&
      &APACHE_VHOST_ALIAS_TWO_SRC:{alias_two_src |"apache_vhost_alias_two_src[&i&]" string => "&alias_two_src&";
}&
      &APACHE_VHOST_ALIAS_TWO_DST:{alias_two_dst |"apache_vhost_alias_two_dst[&i&]" string => "&alias_two_dst&";
}&
      &APACHE_VHOST_ALIAS_THREE_SRC:{alias_three_src |"apache_vhost_alias_three_src[&i&]" string => "&alias_three_src&";
}&
      &APACHE_VHOST_ALIAS_THREE_DST:{alias_three_dst |"apache_vhost_alias_three_dst[&i&]" string => "&alias_three_dst&";
}&

      "apache_vhost_index" slist => getindices("apache_vhost_fqdn");

      # For reporting reason, we need to have the exact list of specified modules to check
      "apache_modules_defined" slist => { &APACHE_MODULES: { "&it&" };separator=", "& };


      # Modules that are installed by default
      "apache_modules" slist => { "expires", "alias", @{apache_modules_defined} },
        policy => "ifdefined";

  classes:

    debian::

      # Security : if not there, Apache too, so don't bother anymore
      "apache_bin_present" expression => fileexists("/usr/sbin/apache2");

    redhat::

      "apache_bin_present" expression => fileexists("/usr/sbin/httpd");

    SuSE::

      "apache_bin_worker" expression => fileexists("/usr/sbin/httpd2-worker");
      "apache_bin_prefork" expression => fileexists("/usr/sbin/httpd2-prefork");
      "apache_bin_present" expression => "apache_bin_prefork|apache_bin_worker";

    any::

      # Autostart ?
      "apache_autostart" expression => strcmp("&APACHE_AUTOSTART&","true");

      # Adjust SELinux ?
      "apache_selinux_adjust" expression => strcmp("&APACHE_SELINUX&","true");

      # Is the SELinux binary "chcon" present ?
      "selinux_bin_present" expression => fileexists("/usr/bin/chcon");

      # Define if the list of module to verify has been specified by the user
      "apache_modules_nok" expression => strcmp("&APACHE_MODULES&","none");
      "apache_modules_ok" not => strcmp("&APACHE_MODULES&","none");

      # Check if the variable apache_modules is defined so that they can be managed
      "apache_module_list_defined" expression => isvariable("apache_modules");

  files:

    debian::

      "/etc/rc2.d/S.*apache2.*"
        create => "true",
                                #depth_search => recurse("0"),
                                #file_select => apache_startlink,
        action => WarnOnly,
        classes => if_else("apache_bootstarted", "apache_unbootstarted");

      "/etc/apache2/ports.conf"
        create => "true",
        perms => m("644"),
        edit_defaults => noempty_backup,
        edit_line => set_apache_config_ports("@{check_apache_configuration.apache_ports}"),
        classes => kept_if_else_hook("apache_ports_kept", "apache_ports_repaired", "apache_ports_failed", "apache_change");

      "/etc/apache2/conf.d/security"
        create => "true",
        perms => m("644"),
        edit_defaults => empty_backup,
        edit_line => set_apache_config_security("check_apache_configuration.apache_security"),
        classes => kept_if_else_hook("apache_security_kept", "apache_security_repaired", "apache_security_failed", "apache_change");

      "/etc/httpd/sites-enabled"
        delete => tidy,
        classes => if_repaired("apache_change"),
        file_select => ex_list("@{vhosts_files}"),
        depth_search => recurse("inf");

      "/etc/apache2/sites-enabled/vhost-${apache_vhost_fqdn[${apache_vhost_index}]}.conf"
        create => "true",
        perms => m("644"),
        edit_defaults => empty_backup,
        edit_line => set_apache_config_vhost("${apache_vhost_fqdn[${apache_vhost_index}]}", "${apache_vhost_port[${apache_vhost_index}]}", "${apache_vhost_root[${apache_vhost_index}]}", "${apache_vhost_expires[${apache_vhost_index}]}", "${apache_vhost_expires_ttl[${apache_vhost_index}]}", "${apache_vhost_alias_one_src[${apache_vhost_index}]}", "${apache_vhost_alias_one_dst[${apache_vhost_index}]}", "${apache_vhost_alias_two_src[${apache_vhost_index}]}", "${apache_vhost_alias_two_dst[${apache_vhost_index}]}", "${apache_vhost_alias_three_src[${apache_vhost_index}]}", "${apache_vhost_alias_three_dst[${apache_vhost_index}]}", "${g.rudder_dependencies}/apache-vhost.tpl"),
        classes => kept_if_else_hook("apache_vhost_${apache_vhost_index}_kept", "apache_vhost_${apache_vhost_index}_repaired", "apache_vhost_${apache_vhost_index}_failed", "apache_change");

    redhat::

      "/etc/rc2.d/S.*httpd.*"
        create => "true",
                                #depth_search => recurse("0"),
                                #file_select => apache_startlink,
        action => WarnOnly,
        classes => if_else("apache_bootstarted", "apache_unbootstarted");

      "/etc/httpd/rudder.conf.d"
        delete => tidy,
        classes => if_repaired("apache_change"),
        file_select => ex_list("@{vhosts_files}"),
        depth_search => recurse("inf");

      "/etc/httpd/conf.d/welcome.conf"
        rename => disable,
        comment => "Disable an annoying file";

      "/etc/httpd/conf/httpd.conf"
        create => "true",
        perms => m("644"),
        edit_defaults => noempty_backup,
        edit_line => cleanup_redhat_apache("check_apache_configuration.apache_security"),
        classes => kept_if_else_hook("apache_ports_kept", "apache_ports_repaired", "apache_ports_failed", "apache_change");

      "/etc/httpd/rudder.conf.d/."
        perms => mog("755", "root", "root"),
        create => "true",
        comment => "Make sure the rudder configuration directory exists";

      "/etc/httpd/rudder.conf.d/ports.conf"
        create => "true",
        perms => m("644"),
        edit_defaults => noempty_backup,
        edit_line => set_apache_config_ports("@{check_apache_configuration.apache_ports}"),
        classes => kept_if_else_hook("apache_ports_kept", "apache_ports_repaired", "apache_ports_failed", "apache_change");

      "/etc/httpd/rudder.conf.d/security.conf"
        create => "true",
        perms => m("644"),
        edit_defaults => noempty_backup,
        edit_line => set_apache_config_security("check_apache_configuration.apache_security"),
        classes => kept_if_else_hook("apache_security_kept", "apache_security_repaired", "apache_security_failed", "apache_change");

      "/etc/httpd/rudder.conf.d/vhost-${apache_vhost_fqdn[${apache_vhost_index}]}.conf"
        create => "true",
        perms => m("644"),
        edit_defaults => empty_backup,
        edit_line => set_apache_config_vhost("${apache_vhost_fqdn[${apache_vhost_index}]}", "${apache_vhost_port[${apache_vhost_index}]}", "${apache_vhost_root[${apache_vhost_index}]}", "${apache_vhost_expires[${apache_vhost_index}]}", "${apache_vhost_expires_ttl[${apache_vhost_index}]}", "${apache_vhost_alias_one_src[${apache_vhost_index}]}", "${apache_vhost_alias_one_dst[${apache_vhost_index}]}", "${apache_vhost_alias_two_src[${apache_vhost_index}]}", "${apache_vhost_alias_two_dst[${apache_vhost_index}]}", "${apache_vhost_alias_three_src[${apache_vhost_index}]}", "${apache_vhost_alias_three_dst[${apache_vhost_index}]}", "${g.rudder_dependencies}/apache-vhost.tpl"),
        classes => kept_if_else_hook("apache_vhost_${apache_vhost_index}_kept", "apache_vhost_${apache_vhost_index}_repaired", "apache_vhost_${apache_vhost_index}_failed", "apache_change");

    SuSE::

      "/etc/rc.d/rc3.d/S.*apache2.*"
        create => "true",
                                #depth_search => recurse("0"),
                                #file_select => apache_startlink,
        action => WarnOnly,
        classes => if_else("apache_bootstarted", "apache_unbootstarted");

      "/etc/apache2/rudder.conf.d"
        delete => tidy,
        classes => if_repaired("apache_change"),
        file_select => ex_list("@{vhosts_files}"),
        depth_search => recurse("inf");

      "/etc/apache2/httpd.conf"
        create => "true",
        perms => m("644"),
        edit_defaults => noempty_backup,
        edit_line => cleanup_redhat_apache("check_apache_configuration.apache_security"),
        classes => kept_if_else_hook("apache_ports_kept", "apache_ports_repaired", "apache_ports_failed", "apache_change");

      "/etc/apache2/rudder.conf.d/."
        perms => mog("755", "root", "root"),
        create => "true",
        comment => "Make sure the rudder configuration directory exists";

      "/etc/apache2/listen.conf"
        create => "true",
        perms => m("644"),
        edit_defaults => noempty_backup,
        edit_line => set_apache_config_ports("@{check_apache_configuration.apache_ports}"),
        classes => kept_if_else_hook("apache_ports_kept", "apache_ports_repaired", "apache_ports_failed", "apache_change");

      "/etc/apache2/rudder.conf.d/security.conf"
        create => "true",
        perms => m("644"),
        edit_defaults => noempty_backup,
        edit_line => set_apache_config_security("check_apache_configuration.apache_security"),
        classes => kept_if_else_hook("apache_security_kept", "apache_security_repaired", "apache_security_failed", "apache_change");

      "/etc/apache2/rudder.conf.d/vhost-${apache_vhost_fqdn[${apache_vhost_index}]}.conf"
        create => "true",
        perms => m("644"),
        edit_defaults => empty_backup,
        edit_line => set_apache_config_vhost("${apache_vhost_fqdn[${apache_vhost_index}]}", "${apache_vhost_port[${apache_vhost_index}]}", "${apache_vhost_root[${apache_vhost_index}]}", "${apache_vhost_expires[${apache_vhost_index}]}", "${apache_vhost_expires_ttl[${apache_vhost_index}]}", "${apache_vhost_alias_one_src[${apache_vhost_index}]}", "${apache_vhost_alias_one_dst[${apache_vhost_index}]}", "${apache_vhost_alias_two_src[${apache_vhost_index}]}", "${apache_vhost_alias_two_dst[${apache_vhost_index}]}", "${apache_vhost_alias_three_src[${apache_vhost_index}]}", "${apache_vhost_alias_three_dst[${apache_vhost_index}]}", "${g.rudder_dependencies}/apache-vhost.tpl"),
        classes => kept_if_else_hook("apache_vhost_${apache_vhost_index}_kept", "apache_vhost_${apache_vhost_index}_repaired", "apache_vhost_${apache_vhost_index}_failed", "apache_change");

    linux::

      "${apache_vhost_root[${apache_vhost_index}]}/."
        perms => mog("755", "root", "root"),
        create => "true",
        classes => if_repaired("root_${apache_vhost_root[${apache_vhost_index}]}_created"),
        comment => "Make sure the root directory exists";

  processes:

    debian.apache_autostart::

      "/usr/sbin/apache2"
        restart_class => "apache_down",
        comment => "Ensuring apache is up";

    redhat.apache_autostart::

      "/usr/sbin/httpd"
        restart_class => "apache_down",
        comment => "Ensuring apache is up";

    SuSE.apache_bin_prefork.apache_autostart::

      "/usr/sbin/httpd2-prefork"
        restart_class => "apache_down",
        comment => "Ensuring apache is up";

    SuSE.!apache_bin_prefork.apache_autostart::

      "/usr/sbin/httpd2-worker"
        restart_class => "apache_down",
        comment => "Ensuring apache is up";

  commands:

    debian.apache_module_list_defined::

      "/usr/sbin/a2enmod"
        args => "${apache_modules}",
        classes => cf2_if_else("apache_module_${apache_modules}_enabled", "apache_module_${apache_vhost_index}_not_apache_modules"),
        comment => "Enable Apache modules on Debian";

    apache_selinux_adjust.selinux_bin_present::

      "/usr/bin/chcon"
        args => "-R --type=httpd_sys_content_t \"${apache_vhost_root[${apache_vhost_index}]}\"",
        classes => cf2_if_else("apache_selinux_${apache_vhost_index}_adjusted", "apache_selinux_${apache_vhost_index}_not_adjusted"),
        comment => "Set SELinux context for Apache VHosts";

    (SuSE|debian).(apache_down|apache_change)::
      "/etc/init.d/apache2"
        args => "restart",
        classes => cf2_if_else("apache_restarted", "cant_restart_apache"),
        comment => "restarting apache";

    redhat.(apache_down|apache_change)::
      "/etc/init.d/httpd"
        args => "restart",
        classes => cf2_if_else("apache_restarted", "cant_restart_apache"),
        comment => "restarting apache";

    (debian.apache_unbootstarted).apache_bin_present::
      "/usr/sbin/update-rc.d"
        args => "apache2 defaults",
        classes => cf2_if_else("apache_bootstarted_ok", "apache_still_unbootstarted"),
        comment => "adding apache to the startup scripts";

    (redhat.apache_unbootstarted).apache_bin_present::
      "/sbin/chkconfig"
        args => "--add httpd",
        classes => cf2_if_else("apache_bootstarted_ok", "apache_still_unbootstarted"),
        comment => "adding apache to the startup scripts";

    (SuSE.apache_unbootstarted).apache_bin_present::
      "/sbin/chkconfig"
        args => "--add apache2",
        classes => cf2_if_else("apache_bootstarted_ok", "apache_still_unbootstarted"),
        comment => "adding apache to the startup scripts";

  reports:
    # if the list is not defined, there is nothing to report !
    apache_modules_nok::
      "@@apacheServerConfiguration@@result_success@@&TRACKINGKEY&@@Module settings@@none@@${g.execRun}##${g.uuid}@#No Apache modules configured to be enabled, no changes made";

    # if the list if defined by the user, we report on each element of this list
    debian.apache_module_list_defined.apache_modules_ok::
      "@@apacheServerConfiguration@@result_success@@&TRACKINGKEY&@@Module settings@@${apache_modules_defined}@@${g.execRun}##${g.uuid}@#The Apache module ${apache_modules_defined} was successfully enabled"
        ifvarclass => canonify("apache_module_${apache_modules_defined}_enabled");

      "@@apacheServerConfiguration@@result_error@@&TRACKINGKEY&@@Module settings@@${apache_modules_defined}@@${g.execRun}##${g.uuid}@#Could not enable apache module ${apache_modules_defined} !"
        ifvarclass => canonify("apache_module_${apache_modules_defined}_not_enabled");

    !debian.apache_modules_ok::
      "@@apacheServerConfiguration@@result_error@@&TRACKINGKEY&@@Module settings@@${apache_modules_defined}@@${g.execRun}##${g.uuid}@#The module verification only applies on Debian systems !";


    apache_selinux_adjust.selinux_bin_present::

      "@@apacheServerConfiguration@@result_success@@&TRACKINGKEY&@@SELinux context@@${apache_vhost_fqdn[${apache_vhost_index}]}@@${g.execRun}##${g.uuid}@#The SELinux context definition was successful for directory ${apache_vhost_root[${apache_vhost_index}]}"
        ifvarclass => canonify("apache_selinux_${apache_vhost_index}_adjusted");

      "@@apacheServerConfiguration@@result_error@@&TRACKINGKEY&@@SELinux context@@${apache_vhost_fqdn[${apache_vhost_index}]}@@${g.execRun}##${g.uuid}@#The SELinux context definition for directory ${apache_vhost_root[${apache_vhost_index}]} has failed !"
        ifvarclass => canonify("apache_selinux_${apache_vhost_index}_not_adjusted");

    apache_selinux_adjust.!selinux_bin_present::

      "@@apacheServerConfiguration@@result_error@@&TRACKINGKEY&@@SELinux context@@${apache_vhost_fqdn[${apache_vhost_index}]}@@${g.execRun}##${g.uuid}@#The automatic SELinux context definition was enabled but SELinux binaries";

    !apache_selinux_adjust::
      "@@apacheServerConfiguration@@result_success@@&TRACKINGKEY&@@SELinux context@@${apache_vhost_fqdn[${apache_vhost_index}]}@@${g.execRun}##${g.uuid}@#No SELinux context definition required for ${apache_vhost_root[${apache_vhost_index}]}";

    apache_ports_kept.!apache_ports_repaired.!apache_ports_failed::
      "@@apacheServerConfiguration@@result_success@@&TRACKINGKEY&@@Port settings edition@@None@@${g.execRun}##${g.uuid}@#Apache HTTPD port settings OK";

    apache_ports_repaired.!apache_ports_failed::
      "@@apacheServerConfiguration@@result_repaired@@&TRACKINGKEY&@@Port settings edition@@None@@${g.execRun}##${g.uuid}@#Apache HTTPD port settings reset";

    apache_ports_failed::
      "@@apacheServerConfiguration@@result_error@@&TRACKINGKEY&@@Port settings edition@@None@@${g.execRun}##${g.uuid}@#Apache HTTPD port settings could not be set !";

    apache_security_kept.!apache_security_repaired.!apache_security_failed::
      "@@apacheServerConfiguration@@result_success@@&TRACKINGKEY&@@Security settings edition@@None@@${g.execRun}##${g.uuid}@#Apache HTTPD security settings OK";

    apache_security_repaired.!apache_security_failed::
      "@@apacheServerConfiguration@@result_repaired@@&TRACKINGKEY&@@Security settings edition@@None@@${g.execRun}##${g.uuid}@#Apache HTTPD security settings reset";

    apache_security_failed::
      "@@apacheServerConfiguration@@result_error@@&TRACKINGKEY&@@Security settings edition@@None@@${g.execRun}##${g.uuid}@#Apache HTTPD security settings could not be set !";

    linux::
      "@@apacheServerConfiguration@@result_success@@&TRACKINGKEY&@@Virtual host settings@@${apache_vhost_fqdn[${apache_vhost_index}]}@@${g.execRun}##${g.uuid}@#Apache HTTPD virtualhost ${apache_vhost_fqdn[${apache_vhost_index}]} already set"
        ifvarclass => "apache_vhost_${apache_vhost_index}_kept.!apache_vhost_${apache_vhost_index}_repaired.!apache_vhost_${apache_vhost_index}_failed";

      "@@apacheServerConfiguration@@result_repaired@@&TRACKINGKEY&@@Virtual host settings@@${apache_vhost_fqdn[${apache_vhost_index}]}@@${g.execRun}##${g.uuid}@#Apache HTTPD virtualhost ${apache_vhost_fqdn[${apache_vhost_index}]} reset"
        ifvarclass => "apache_vhost_${apache_vhost_index}_repaired.!apache_vhost_${apache_vhost_index}_failed";

      "@@apacheServerConfiguration@@result_error@@&TRACKINGKEY&@@Virtual host settings@@${apache_vhost_fqdn[${apache_vhost_index}]}@@${g.execRun}##${g.uuid}@#Apache HTTPD virtualhost ${apache_vhost_fqdn[${apache_vhost_index}]} could not be set !"
        ifvarclass => "apache_vhost_${apache_vhost_index}_failed";

      "@@apacheServerConfiguration@@log_info@@&TRACKINGKEY&@@Virtual host settings@@${apache_vhost_fqdn[${apache_vhost_index}]}@@${g.execRun}##${g.uuid}@#The root directory ${apache_vhost_root[${apache_vhost_index}]} was created"
        ifvarclass => canonify("root_${apache_vhost_root[${apache_vhost_index}]}_created");

    apache_autostart.apache_bootstarted.!apache_unboostarted::
      "@@apacheServerConfiguration@@result_success@@&TRACKINGKEY&@@Apache bootstart@@None@@${g.execRun}##${g.uuid}@#Apache HTTPD is correctly set to start on boot";

    apache_autostart.apache_unboostarted.apache_bootstarted_ok.!apache_still_unbootstarted::
      "@@apacheServerConfiguration@@result_repaired@@&TRACKINGKEY&@@Apache bootstart@@None@@${g.execRun}##${g.uuid}@#Apache HTTPD is now starting on boot";

    apache_autostart.apache_still_unbootstarted.apache_still_unbootstarted::
      "@@apacheServerConfiguration@@result_error@@&TRACKINGKEY&@@Apache bootstart@@None@@${g.execRun}##${g.uuid}@#Apache HTTPD could not be set to start on boot";

    !apache_autostart::
      "@@apacheServerConfiguration@@result_success@@&TRACKINGKEY&@@Apache bootstart@@None@@${g.execRun}##${g.uuid}@#Don't have to check if Apache HTTPD should be started automatically";


    apache_restarted::
      "@@apacheServerConfiguration@@log_info@@&TRACKINGKEY&@@apacheServer@@None@@${g.execRun}##${g.uuid}@#Apache HTTPD restarted";

    cant_restart_apache::
      "@@apacheServerConfiguration@@result_error@@&TRACKINGKEY&@@apacheServer@@None@@${g.execRun}##${g.uuid}@#Could not restart Apache HTTPD";

    !apache_bin_present::
      "@@apacheServerConfiguration@@result_error@@&TRACKINGKEY&@@Apache2 installation@@None@@${g.execRun}##${g.uuid}@#Apache binary is not present. Something is wrong (installation failure ?)";

}

bundle edit_line cleanup_redhat_apache(tab)

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

  delete_lines:

      "^.*${index}.*$";
      "^NameVirtualHost.*((?!443).)*$";
      "^Listen.*((?!443).)*$";

  insert_lines:

    redhat::

      "Include /etc/httpd/rudder.conf.d/*.conf";

    (debian|SuSE)::

      "Include /etc/apache2/rudder.conf.d/*.conf";

}

bundle edit_line set_apache_config_ports(ports)
{

  delete_lines:

      "^NameVirtualHost.*((?!443).)*$";
      "^Listen.*((?!443).)*$";

  insert_lines:

      "NameVirtualHost *:${ports}";
      "Listen ${ports}";

}

bundle edit_line set_apache_config_security(tab)

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

  delete_lines:

      "^.*${index}.*$";

  field_edits:

  # If the line is there, but commented out, first uncomment it
      "#+${index}\s+.*"
        edit_field => col("\s+","1","${index}","set");

  # match a line starting like the key something
      "${index}\s+.*"
        edit_field => col("\s+","2","${${tab}[${index}]}","set"),
        classes => if_ok("not_${cindex[${index}]}");

  insert_lines:

      "${index} ${${tab}[${index}]}"
        ifvarclass => "!not_${cindex[${index}]}";

}

bundle edit_line set_apache_config_vhost(fqdn, port, root, exp, exp_ttl, alias_one_src, alias_one_dst, alias_two_src, alias_two_dst, alias_three_src, alias_three_dst, template)
{

  vars:

    mylock1::

      "mylock" string => "mylock",
        policy => "overridable";

    set_expires::

      "finexpire" string => "On",
        policy => "overridable";

    unset_expires::

      "finexpire" string => "Off",
        policy => "overridable";

    set_alias_one::

      "finalias_one" string => "Alias	${alias_one_src}	\"${alias_one_dst}\"",
        policy => "overridable";

    set_alias_two::

      "finalias_two" string => "Alias ${alias_two_src}	\"${alias_two_dst}\"",
        policy => "overridable";

    set_alias_three::

      "finalias_three" string => "Alias ${alias_three_src}	\"${alias_three_dst}\"",
        policy => "overridable";

    unset_alias_one::

      "finalias_one" string => "# Alias 1 disabled",
        policy => "overridable";

    unset_alias_two::

      "finalias_two" string => "# Alias 2 disabled",
        policy => "overridable";

    unset_alias_three::

      "finalias_three" string => "# Alias 3 disabled",
        policy => "overridable";

  classes:

      "set_expires" expression => strcmp("${exp}","true");
      "unset_expires" expression => strcmp("${exp}","false");

      "set_alias_one" not => strcmp("${alias_one_src}","Disabled");
      "set_alias_two" not => strcmp("${alias_two_src}","Disabled");
      "set_alias_three" not => strcmp("${alias_three_src}","Disabled");
      "unset_alias_one" expression => strcmp("${alias_one_src}","Disabled");
      "unset_alias_two" expression => strcmp("${alias_two_src}","Disabled");
      "unset_alias_three" expression => strcmp("${alias_three_src}","Disabled");

      "mylock1" expression => "any";

      "mylock" expression => strcmp("mylock", "${mylock}");

  insert_lines:

    mylock::

      "${template}"
        insert_type => "file",
        expand_scalars => "true";

}
