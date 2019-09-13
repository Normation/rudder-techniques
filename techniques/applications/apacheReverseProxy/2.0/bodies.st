#
# Configure the reverse proxy entries used by Apache.
#
bundle edit_line insert_proxy_entries(entries)
{
  insert_lines:

    "<IfModule mod_proxy.c>
${entries}</IfModule>";

}

