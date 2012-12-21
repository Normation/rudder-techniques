#
# Configure the port numbers in the OpenSSH configuration file
# The argument can be either a string or a slist
#
bundle edit_line rudder_openssh_server_port_configuration(portlist)
{
  delete_lines:
    "Port.*";

  insert_lines:
    "Port $(portlist)";
}
