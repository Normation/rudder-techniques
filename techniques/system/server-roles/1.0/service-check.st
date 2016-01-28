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

bundle agent generic_process_check_process(binary, initscript, name, check_on_relay_server) {

  vars:

      "c_initscript" string => canonify("${initscript}");

  classes:

      # Raise this class if we are handling a process that should be checked even on
      # relay servers.
      "process_exception_on_relay" expression => strcmp("${check_on_relay_server}", "true");

  methods:

    (root_server|process_exception_on_relay)::

      "start_process" usebundle => service_ensure_running_path("${initscript}", "${binary}");

      "any"           usebundle => rudder_common_reports_generic("server-roles", "service_ensure_running_${c_initscript}", "&TRACKINGKEY&", "Check ${name} process", "None", "Check ${name} process running");

    !(root_server|process_exception_on_relay)::

      "any" usebundle => rudder_common_report("server-roles", "result_na", "&TRACKINGKEY&", "Check ${name} process", "None", "The ${name} process do not need to be checked on relay servers. Skipping...");

}

bundle agent generic_process_check_bootstart(binary, initscript, name) {

  vars:

      "c_initscript" string => canonify("${initscript}");

  methods:

      "bootstart_service" usebundle => service_ensure_started_at_boot("${initscript}");
      "any" usebundle => rudder_common_reports_generic("server-roles", "service_ensure_started_at_boot_${c_initscript}", "&TRACKINGKEY&", "Check ${name} boot script", "None", "Check ${name} boot starting parameters");

}
