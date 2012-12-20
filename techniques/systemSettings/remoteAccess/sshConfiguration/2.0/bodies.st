body classes rudder_common_setclass(prefix)
{
promise_kept     => { "${prefix}_kept" };
promise_repaired => { "${prefix}_repaired" };
repair_failed    => { "${prefix}_error" };
repair_denied    => { "${prefix}_error" };
repair_timeout   => { "${prefix}_error" };
}

bundle edit_line rudder_openssh_server_configuration_tier1(portlist)
{

  delete_lines:
    "Port.*";

  insert_lines:
    "Port $(portlist)";

}

bundle edit_line rudder_openssh_server_configuration_tier2(tab)
{

 # Sets the RHS of configuration items in the file of the form
 # LHS RHS
 # If the line is commented out with #, it gets uncommented first.
 # Adds a new line if none exists.
 # The argument is an associative array containing v[LHS]="rhs"

 # Based on set_variable_values from cfengine_stdlib.cf, modified to
 # use whitespace as separator, and to handle commented-out lines.

  vars:
    "index" slist => getindices("$(tab)");

    # Be careful if the index string contains funny chars
    "cindex[$(index)]" string => canonify("$(index)");

  field_edits:

    # If the line is there, but commented out, first uncomment it
    "#+$(index)\s+.*"
      edit_field => col("\s+","1","$(index)","set");

    # match a line starting like the key something
    "$(index)\s+.*"
      edit_field => col("\s+","2","$($(tab)[$(index)])","set"),
      classes => if_ok("not_$(cindex[$(index)])");

  insert_lines:

    "#############################################################
### This file is protected by your Rudder infrastructure. ###
### Manually editing the file might lead your Rudder      ###
### infrastructure to change back the server’s            ###
### configuration and/or to raise a compliance alert.     ###
#############################################################
"
      location => start,
      insert_type => "preserve_block";

    "$(index) $($(tab)[$(index)])",
      ifvarclass => "!not_$(cindex[$(index)])";

}

