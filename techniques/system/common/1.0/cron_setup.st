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

bundle agent setup_cronjob
{
  vars:

  files:

    linux::

      # Temporary cron file added by rudder-agent postinst to prevent from UUID removal.
      # When this promise will be generated, this cron will be useless then removed.
      # (see http://www.rudder-project.org/redmine/issues/3925 and http://www.rudder-project.org/redmine/issues/3930).
      "/etc/cron.d/rudder-agent-uuid"
        delete => tidy;

    community_edition.!aix::

      "/etc/cron.d/rudder-agent"
        create        => "true",
        perms         => mog("644", "root", "root"),
        edit_defaults => empty_backup,
        edit_line     => expand_template("${sys.workdir}/inputs/common/cron/rudder_agent_community_cron");
&if(NOVA)&

    nova_edition.!aix.!windows::

      "/etc/cron.d/rudder-agent-nova"
        create        => "true",
        perms         => mog("644", "root", "root"),
        edit_defaults => empty_backup,
        edit_line     => expand_template("${sys.workdir}/inputs/common/cron/rudder_agent_nova_cron");
&endif&

    aix::

      # Cleanup the crontab
      "/var/spool/cron/crontabs/root"
        edit_defaults => noempty_backup,
        edit_line => delete_lines_matching("0,5,10,15,20,25,30,35,40,45,50,55 \* \* \* \* if \[ -x /opt/rudder/bin/check-rudder-agent \]; then /opt/rudder/bin/check-rudder-agent; fi");

      # Add Rudder entry
      "/var/spool/cron/crontabs/root"
        create        => "true",
        perms         => mog("600", "root", "cron"),
        edit_line     => insert_lines("0,5,10,15,20,25,30,35,40,45,50,55 * * * * if [ -x /opt/rudder/bin/check-rudder-agent ]; then /opt/rudder/bin/check-rudder-agent >/dev/null; fi"),
        classes       => rudder_common_classes("rudder_aix_crontab_insertion"),
        comment       => "Insert an AIX-compatible user crontab to run /opt/rudder/bin/check-rudder-agent";

}

#######################################################
# Check if the cron daemon is running
# This only works with unix flavoured systems too

bundle agent check_cron_daemon
{
  classes:

    any::
      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";

  methods:

    pass2.!redhat.!fedora.restart_crond::

      "restart_cron" usebundle => service_restart("cron");

    pass2.(redhat|fedora).restart_crond::

      "restart_cron" usebundle => service_restart("crond");

    pass3.(service_restart_cron_not_ok|service_restart_crond_not_ok)::
      "any" usebundle => rudder_common_report("Common", "result_error", "&TRACKINGKEY&", "CRON Daemon", "None", "The CRON daemon was not running and could not be restarted");

    pass3.(service_restart_cron_repaired|service_restart_crond_repaired)::
      "any" usebundle => rudder_common_report("Common", "result_repaired", "&TRACKINGKEY&", "CRON Daemon", "None", "The CRON daemon has been successfully restarted");

    pass3.!restart_crond.!android.!windows)::
      "any" usebundle => rudder_common_report("Common", "result_success", "&TRACKINGKEY&", "CRON Daemon", "None", "The CRON daemon is running");

    pass3.(android|windows)::
      "any" usebundle => rudder_common_report("Common", "result_na", "&TRACKINGKEY&", "CRON Daemon", "None", "This is a system without CRON: CRON verifications skipped !");

  processes:

    !android.!windows.!aix::
      "cron"
        process_select => cron_bin,
        restart_class => "restart_crond";

}
