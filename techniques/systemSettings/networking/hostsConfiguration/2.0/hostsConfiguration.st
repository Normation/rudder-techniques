# (C) Normation 2011
#
# NOTE : I permitted the creation of the hosts file if absent, but on a purely
# functionnal side, its absence means a severe breakage of your IP stack. Be
# aware of this if a file creation is reported !
#

bundle agent check_hosts_configuration
{

  vars:

    &HOSTS_HOST:{host |"hosts_host[&i&]" string => "&host&";
}&

    &HOSTS_IP:{ip |"hosts_ip[&i&]" string => "&ip&";
}&

      "hosts_base_template" string => "&HOSTS_BASE_TEMPLATE&";

  classes:
    any::
      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";

  files:

      "/etc/hosts"

        create => "true",
        perms => m("644"),
&if (HOSTS_ENFORCE)&
        edit_defaults => empty_backup,
&else&
        edit_defaults => noempty_backup,
&endif&

        edit_line => set_hosts_values("check_hosts_configuration.hosts_host", "check_hosts_configuration.hosts_ip", "${hosts_base_template}"),
        classes => kept_if_else("hosts_edition_kept", "hosts_edition_done", "hosts_edition_failed");

  methods:

    pass3.cfengine::
&if (HOSTS_ENFORCE)&
      "any" usebundle => rudder_common_report("hostsConfiguration", "log_debug", "&TRACKINGKEY&", "hostsConfiguration", "None", "Hosts file content enforcement requested");
&endif&

    pass3.hosts_edition_done::
      "any" usebundle => rudder_common_report("hostsConfiguration", "result_repaired", "&TRACKINGKEY&", "hostsConfiguration", "None", "Hosts file was updated");

    pass3.(hosts_edition_kept.!hosts_edition_done)::
      "any" usebundle => rudder_common_report("hostsConfiguration", "result_success", "&TRACKINGKEY&", "hostsConfiguration", "None", "Hosts file already OK");

    pass3.hosts_edition_failed::
      "any" usebundle => rudder_common_report("hostsConfiguration", "result_error", "&TRACKINGKEY&", "hostsConfiguration", "None", "Hosts file could not be edited");

}

bundle edit_line set_hosts_values(hosts, ips, base_tmpl)
{

  vars:

      "hosts_index" slist => getindices("${hosts}");

  delete_lines:

      "${${ips}[${hosts_index}]}.*";

  insert_lines:

&if (HOSTS_ENFORCE)&

      "${base_tmpl}"
        insert_type => "preserve_block";

&endif&

      "${${ips}[${hosts_index}]}	${${hosts}[${hosts_index}]}";

}

