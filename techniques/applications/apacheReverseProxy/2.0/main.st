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

#####################################################################################
# This Technique installs and configures Apache HTTPd to act as a reverse proxy
# server.. See metadata.xml for more details.
#####################################################################################

bundle agent rudder_reverse_proxy_apache
{
  vars:

    # Common declarations
    "rudder_reverse_proxy_apache_service_name"
      string => "Apache (as a reverse proxy)";
    "rudder_reverse_proxy_apache_internal_name"
      string => "apacheReverseProxy";

    # Parameters
    "rudder_reverse_proxy_params[package_install]"
      string => "&APACHE_REVERSE_PROXY_INSTALL&";

    "rudder_reverse_proxy_params[proxies]"
      string => "&APACHE_REVERSE_PROXY_URL_SRC,APACHE_REVERSE_PROXY_URL_DST,APACHE_REVERSE_PROXY_TIMEOUT:{src, dst, timeout|ProxyPass &src& &dst& connectiontimeout=5 timeout=&timeout&${const.n}ProxyPassReverse &src& &dst&
}&";
    "rudder_reverse_proxy_params[selinux]"
      string => "&APACHE_REVERSE_PROXY_ADJUST_SELINUX&";

    "rudder_reverse_proxy_params[tracking_key]"
      string => "&TRACKINGKEY&";

  methods:
    # Note:
    # The reporting is made on separate bundles to abstract the complexity
    # inherent to the normal ordering.
    "any" usebundle => rudder_reverse_proxy_apache_installation("${rudder_reverse_proxy_apache_service_name}", "${rudder_reverse_proxy_apache_internal_name}", "rudder_reverse_proxy_apache.rudder_reverse_proxy_params");
    "any" usebundle => rudder_reverse_proxy_apache_installation_reporting("${rudder_reverse_proxy_apache_service_name}", "${rudder_reverse_proxy_apache_internal_name}", "rudder_reverse_proxy_apache.rudder_reverse_proxy_params");
    "any" usebundle => rudder_reverse_proxy_apache_configuration("${rudder_reverse_proxy_apache_service_name}", "${rudder_reverse_proxy_apache_internal_name}", "rudder_reverse_proxy_apache.rudder_reverse_proxy_params");
    "any" usebundle => rudder_reverse_proxy_apache_configuration_reporting("${rudder_reverse_proxy_apache_service_name}", "${rudder_reverse_proxy_apache_internal_name}", "rudder_reverse_proxy_apache.rudder_reverse_proxy_params");

}
