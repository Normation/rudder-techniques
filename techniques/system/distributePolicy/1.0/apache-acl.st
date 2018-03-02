#####################################################################################
# Copyright 2017 Normation SAS
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

bundle agent apache_acl
{

  vars:
      "destination"        string => "/opt/rudder/etc/ssl";
      "ssl_ca_file"        string => "ca.cert";
      "ssl_ca_size"        string => filestat("${this.promise_dirname}/${ssl_ca_file}", "size");

    pass1::
      "src_ca_file" string => "${this.promise_dirname}/${ssl_ca_file}",
                ifvarclass => "!empty_ssl_ca";
      "src_ca_file" string => "${destination}/rudder.crt",
                ifvarclass => "empty_ssl_ca";

    redhat::
      "apache_service" string => "httpd";

    !redhat::
      "apache_service" string => "apache2";

  classes:
      "empty_ssl_ca" expression => strcmp("${ssl_ca_size}", "0");

      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";

  files:
    pass2::
      "${destination}/${ssl_ca_file}"
        create        => "true",
        perms         => mog("600", "root", "0"),
        copy_from     => ncf_local_cp_method("${src_ca_file}", "digest"),
        classes       => rudder_common_classes("rudder_apache_acl"),
        comment       => "Writing rudder apache ACL";

  methods:
    rudder_apache_acl_repaired::
      "reload_apache" usebundle => disable_reporting; 
      "reload_apache" usebundle => _method_reporting_context("Configure apache ACL", "None"); 
      "reload_apache" usebundle => service_reload("${apache_service}");
      "reload_apache" usebundle => enable_reporting; 

    rudder_apache_acl_ok.!rudder_apache_acl_repaired.!rudder_apache_acl_error::
      "any" usebundle => rudder_common_report("DistributePolicy", "result_success", "&TRACKINGKEY&", "Configure apache ACL", "None", "Apache ACLs are correct");

    rudder_apache_acl_repaired.!rudder_apache_acl_error::
      "any" usebundle => rudder_common_report("DistributePolicy", "result_repaired", "&TRACKINGKEY&", "Configure apache ACL", "None", "Apache ACLs have been repaired");

    rudder_apache_acl_error::
      "any" usebundle => rudder_common_report("DistributePolicy", "result_error", "&TRACKINGKEY&", "Configure apache ACL", "None", "Apache ACLs could not be edited");

    rudder_apache_acl_repaired::
      "any" usebundle => rudder_common_report("DistributePolicy", "log_repaired", "&TRACKINGKEY&", "Configure apache ACL", "None", "Apache has been reloaded successfully"),
            ifvarclass => "service_reload_${apache_service}_repaired";

      "any" usebundle => rudder_common_report("DistributePolicy", "result_error", "&TRACKINGKEY&", "Configure apache ACL", "None", "Apache failed to reload"),
            ifvarclass => "service_reload_${apache_service}_error";
}
