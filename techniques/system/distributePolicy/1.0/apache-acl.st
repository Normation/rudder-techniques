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
      "destination"        string => "/opt/rudder/etc";
      "acl_file[nodes_22]" string => "rudder-share-acl.conf";
      "acl_file[nodes_24]" string => "rudder-share-acl-24.conf";
      "ssl_ca_file"        string => "ca.cert";

      "index"             slist => getindices("acl_file");

    redhat::
      "apache_service" string => "httpd";

    !redhat::
      "apache_service" string => "apache2";

  files:

      "${destination}/${acl_file[${index}]}"
        create        => "true",
        perms         => mog("600", "root", "0"),
        copy_from     => local_cp("${this.promise_dirname}/${acl_file[${index}]}"),
        classes       => rudder_common_classes("rudder_apache_acl"),
        comment       => "Writing rudder apache ACL";

      "${destination}/ssl/${ssl_ca_file}"
        create        => "true",
        perms         => mog("600", "root", "0"),
        copy_from     => local_cp("${this.promise_dirname}/${ssl_ca_file}"),
        classes       => rudder_common_classes("rudder_apache_acl"),
        comment       => "Writing rudder apache ACL";

  methods:
    rudder_apache_acl_repaired::
      "any" usebundle => service_reload("${apache_service}");

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
