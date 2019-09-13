###############################################################
# Installs the NFS client


bundle agent check_nfs_client_installation
{
  vars:
    linux.!redhat.!SuSE::
      "rudder_nfs_client_package" string => "nfs-common";
    redhat::
      "rudder_nfs_client_package" string => "nfs-utils";
    SuSE::
      "rudder_nfs_client_package" string => "nfs-client";

  methods:
      "any" usebundle => package_present("${rudder_nfs_client_package}");
    linux::
      "any" usebundle => rudder_common_reports_generic("nfsClient", "package_present_${rudder_nfs_client_package}", "&TRACKINGKEY&", "NFS Client package install", "None", "The ${rudder_nfs_client_package} package installation");
    !linux::
      "any" usebundle => rudder_common_report("nfsClient", "result_na", "&TRACKINGKEY&", "NFS Client package install", "None", "Support to check if NFS client is installed not available on this platform");
}
