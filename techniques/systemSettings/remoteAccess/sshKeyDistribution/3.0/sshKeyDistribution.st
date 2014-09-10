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

#  Copyright (C) Normation

bundle agent check_ssh_key_distribution
{

  vars:

    any::
      "technique_name"  string  => "sshKeyDistribution";
      "component_name"  string  => "SSH key";

      "config_basename" string  => "authorized_keys";

                &SSH_KEY_DISTRIBUTION_TAG:{key_tag |"sshkey_distribution_tag[&i&]" string => "&key_tag&";
}&
                &SSH_KEY_DISTRIBUTION_NAME:{distribution_name |"sshkey_distribution_name[&i&]" string => "&distribution_name&";
}&
                &SSH_KEY_DISTRIBUTION_KEY:{distribution_key |"sshkey_distribution_key[&i&]" string => "&distribution_key&";
}&
                &SSH_KEY_DISTRIBUTION_EDIT_TYPE:{distribution_edit_type |"sshkey_distribution_edit_type[&i&]" string => "&distribution_edit_type&";
}&
                &TRACKINGKEY:{uuid |"sshkey_distribution_uuid[&i&]" string => "&uuid&";
}&
      "sshkey_distribution_index"
        slist   => getindices("sshkey_distribution_name");

      "userdata_${sshkey_distribution_index}"
        string  => execresult("/usr/bin/getent passwd ${sshkey_distribution_name[${sshkey_distribution_index}]}", "noshell");

      "no_${sshkey_distribution_index}"
        int     => parsestringarray("userarray_${sshkey_distribution_index}", "${userdata_${sshkey_distribution_index}}", "", ":", "1000", "200000" );

      "key_class_prefix[${sshkey_distribution_index}]"
        string  => canonify("${sshkey_distribution_tag[${sshkey_distribution_index}]}_${sshkey_distribution_uuid[${sshkey_distribution_index}]}");

      "homedir[${sshkey_distribution_index}]"
        string  => "${userarray_${sshkey_distribution_index}[${sshkey_distribution_name[${sshkey_distribution_index}]}][5]}";

    !SuSE::
      "gid[${sshkey_distribution_index}]"
        string  => "${userarray_${sshkey_distribution_index}[${sshkey_distribution_name[${sshkey_distribution_index}]}][3]}";

    SuSE::
      "gid[${sshkey_distribution_index}]"
        string  => "users";

  classes:

      "begin_evaluation" expression => isvariable("sshkey_distribution_index");

    begin_evaluation::

      "user_${sshkey_distribution_index}_exists" expression => userexists("${sshkey_distribution_name[${sshkey_distribution_index}]}");

  files:

    linux::

      "${homedir[${sshkey_distribution_index}]}/.ssh/."
        create        => "true",
        ifvarclass    => canonify("user_${sshkey_distribution_index}_exists"),
        perms         => mog("700", "${sshkey_distribution_name[${sshkey_distribution_index}]}", "${gid[${sshkey_distribution_index}]}");

      "${homedir[${sshkey_distribution_index}]}/.ssh/${config_basename}"
        create        => "true",
        edit_defaults => rudder_empty_select("${sshkey_distribution_edit_type[${sshkey_distribution_index}]}"),
        perms         => mog("600", "${sshkey_distribution_name[${sshkey_distribution_index}]}", "${gid[${sshkey_distribution_index}]}"),
        edit_line     => append_or_replace_ssh_key("${sshkey_distribution_key[${sshkey_distribution_index}]}"),
        ifvarclass    => canonify("user_${sshkey_distribution_index}_exists"),
        classes       => rudder_common_classes("${key_class_prefix[${sshkey_distribution_index}]}");

  methods:

    linux::

      "SSH Key Report"
        ifvarclass    => "user_${sshkey_distribution_index}_exists",
        usebundle     => rudder_common_reports_generic(
          "${technique_name}", "${key_class_prefix[${sshkey_distribution_index}]}",
          "${sshkey_distribution_uuid[${sshkey_distribution_index}]}", "${component_name}", "${sshkey_distribution_tag[${sshkey_distribution_index}]}", "SSH key \"${sshkey_distribution_tag[${sshkey_distribution_index}]}\" for user ${sshkey_distribution_name[${sshkey_distribution_index}]}"
        );

      "No User Exist Report"
        ifvarclass    => "!user_${sshkey_distribution_index}_exists",
        usebundle     => rudder_common_report(
          "${technique_name}", "result_error",
          "${sshkey_distribution_uuid[${sshkey_distribution_index}]}", "${component_name}", "${sshkey_distribution_tag[${sshkey_distribution_index}]}", "The user ${sshkey_distribution_name[${sshkey_distribution_index}]} does NOT exist on this machine, not adding SSH key"
        );
}

# authorized_keys file contains one line per key, in the following format:
# (optional-options\s)(<keytype>)\s(the_key=)(\soptional-comment)
# where
#   - keytype is one of ssh-rsa or ssh-dss
#   - key value ends with "="
#   - no spaces are allowed in options, except in double-quoted strings
#
bundle edit_line append_or_replace_ssh_key(keyspec)
{
  vars:
    any::
      "eline"
        comment     => "An escaped version of the keyspec - \Q..\E do not escape everything",
        string      => escape("${keyspec}");
    key_parsed::
      "ckey" string => canonify("${keybits[3]}");
      "ekey" string => escape("${keybits[3]}");

  classes:
    "key_parsed" 
      # If the key hash happens to exceed 1000 chars $keybits[3] is going to be undefined because 
      # of some weird cfengine bugs, probably this one: https://cfengine.com/dev/issues/1258
      # Therefore we limit the regex to extract as much of the hash as possible to make it unique enough
      # without exceeding 1000 charachter limit.
      # The hashes of that length apparently correspond to DSS 2048 bits keys, generated i.e. on rhel 4,
      # with openssh v3.9p1-redhat. I believe that since openssh v4 DSS bitlengh is limited to 1024,
      # as required by FIPS.
      expression    => regextract("(.*\s+)?(ssh-rsa|ssh-dss)\s+(\S{1,1000})\S*(\s+.+)?\Z", "${keyspec}", "keybits" );

  insert_lines:
    "${keyspec}"
      # NOTE: this is only to ensure that insert is attempted *after* the replace,
      # as normally insert step precedes the replace, see
      # (https://cfengine.com/docs/3.5/manuals-language-concepts-normal-ordering.html)
      ifvarclass    => canonify("replace_step_attempted_${ckey}");

  replace_patterns:
    "^(?!${eline}$)(.*${ekey}.*)$"
      comment       => "Replace a key here",
      replace_with  => value("${keyspec}"),
      ifvarclass    => "key_parsed",
      classes       => always("replace_step_attempted_${ckey}");
}
