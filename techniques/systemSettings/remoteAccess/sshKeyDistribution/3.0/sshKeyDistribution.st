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

      "no_${sshkey_distribution_index}"
        int     => parsestringarray("userarray_${sshkey_distribution_index}", "${userdata_${sshkey_distribution_index}}", "", ":", "1000", "200000" );

      "key_class_prefix[${sshkey_distribution_index}]"
        string  => canonify("${sshkey_distribution_tag[${sshkey_distribution_index}]}_${sshkey_distribution_uuid[${sshkey_distribution_index}]}");

      "homedir[${sshkey_distribution_index}]"
        string  => "${userarray_${sshkey_distribution_index}[${sshkey_distribution_name[${sshkey_distribution_index}]}][5]}";

      "ssh_types" string => "ssh-rsa|ssh-dss|ssh-ed25519|ecdsa-sha2-nistp521|ecdsa-sha2-nistp384|ecdsa-sha2-nistp256|ssh-dsa";

    # Extract key content from the keys
    # -E option to get rid of escaping char
      "sshkey_distribution_key_content_${sshkey_distribution_index}"
        string => execresult("${paths.echo} '${sshkey_distribution_key[${sshkey_distribution_index}]}' | ${paths.sed} -E 's/(.*\s+)?(${ssh_types})\s+(\S+)(\s.*)?/\3/'", "useshell"),
        ifvarclass => "correct_ssh_key_format_${sshkey_distribution_index}";

    # Only Linuxes (not Slackware), Solaris and FreeBSD support PAM/getent
    (linux.!slackware)|solaris|freebsd::

      "userdata_${sshkey_distribution_index}"
        string  => execresult("/usr/bin/getent passwd ${sshkey_distribution_name[${sshkey_distribution_index}]}", "noshell");

    # On systems without PAM, directly read entries from /etc/passwd instead (compatibility)
    !((linux.!slackware)|solaris|freebsd)::

      "userdata_${sshkey_distribution_index}"
        string  => execresult("/usr/bin/grep ^${sshkey_distribution_name[${sshkey_distribution_index}]}: /etc/passwd", "noshell");

    any::
      "gid[${sshkey_distribution_index}]"
        string  => "${userarray_${sshkey_distribution_index}[${sshkey_distribution_name[${sshkey_distribution_index}]}][3]}";

  classes:
      "pass2" expression => "pass1";
      "pass1" expression => "any";
      "begin_evaluation" expression => isvariable("sshkey_distribution_index");

   pass2::
      "correct_ssh_key_format_${sshkey_distribution_index}" expression => regcmp("(.*\s+)?(${ssh_types})\s+(\S+)(\s.*)?", "${sshkey_distribution_key[${sshkey_distribution_index}]}"); 
    begin_evaluation::
      "user_${sshkey_distribution_index}_exists" expression => userexists("${sshkey_distribution_name[${sshkey_distribution_index}]}");

  files:

      "${homedir[${sshkey_distribution_index}]}/.ssh/."
        create        => "true",
        perms         => mog("700", "${sshkey_distribution_name[${sshkey_distribution_index}]}", "${gid[${sshkey_distribution_index}]}"),
        ifvarclass    => concat(canonify("user_${sshkey_distribution_index}_exists"),".correct_ssh_key_format_${sshkey_distribution_index}");

      "${homedir[${sshkey_distribution_index}]}/.ssh/${config_basename}"
        create        => "true",
        edit_defaults => rudder_empty_select("${sshkey_distribution_edit_type[${sshkey_distribution_index}]}"),
        perms         => mog("600", "${sshkey_distribution_name[${sshkey_distribution_index}]}", "${gid[${sshkey_distribution_index}]}"),
        edit_line     => append_or_replace_ssh_key("${sshkey_distribution_key[${sshkey_distribution_index}]}", "${sshkey_distribution_key_content_${sshkey_distribution_index}}", "${sshkey_distribution_index}"),
        classes       => rudder_common_classes("${key_class_prefix[${sshkey_distribution_index}]}"),
        ifvarclass    => concat(canonify("user_${sshkey_distribution_index}_exists"),".correct_ssh_key_format_${sshkey_distribution_index}");

  methods:

    pass2::

      "SSH Key Report"
        usebundle     => rudder_common_reports_generic(
          "${technique_name}", "${key_class_prefix[${sshkey_distribution_index}]}",
          "${sshkey_distribution_uuid[${sshkey_distribution_index}]}", "${component_name}", "${sshkey_distribution_tag[${sshkey_distribution_index}]}",
          "SSH key \"${sshkey_distribution_tag[${sshkey_distribution_index}]}\" for user ${sshkey_distribution_name[${sshkey_distribution_index}]}"
        ),
        ifvarclass    => "user_${sshkey_distribution_index}_exists.correct_ssh_key_format_${sshkey_distribution_index}";

      "Wrong SSH Key Format Report"
        usebundle     => rudder_common_report(
          "${technique_name}", "result_error",
          "${sshkey_distribution_uuid[${sshkey_distribution_index}]}", "${component_name}", "${sshkey_distribution_tag[${sshkey_distribution_index}]}",
          "Wrong SSH key format \"${sshkey_distribution_tag[${sshkey_distribution_index}]}\" for user ${sshkey_distribution_name[${sshkey_distribution_index}]}"
        ),
        ifvarclass    => "!correct_ssh_key_format_${sshkey_distribution_index}.user_${sshkey_distribution_index}_exists";

      "No User Exist Report"
        usebundle     => rudder_common_report(
          "${technique_name}", "result_error",
          "${sshkey_distribution_uuid[${sshkey_distribution_index}]}", "${component_name}", "${sshkey_distribution_tag[${sshkey_distribution_index}]}",
          "The user ${sshkey_distribution_name[${sshkey_distribution_index}]} does NOT exist on this machine, not adding SSH key"
        ),
        ifvarclass    => "!user_${sshkey_distribution_index}_exists.correct_ssh_key_format_${sshkey_distribution_index}";

      "No User Exist and Wrong SSH Key Format Report"
        usebundle     => rudder_common_report(
          "${technique_name}", "result_error",
          "${sshkey_distribution_uuid[${sshkey_distribution_index}]}", "${component_name}", "${sshkey_distribution_tag[${sshkey_distribution_index}]}",
          "The user ${sshkey_distribution_name[${sshkey_distribution_index}]} does NOT exist on this machine, and the SSH key format is wrong"
        ),
        ifvarclass    => "!user_${sshkey_distribution_index}_exists.!correct_ssh_key_format_${sshkey_distribution_index}";

}

# authorized_keys file contains one line per key, in the following format:
# (optional-options\s)(<keytype>)\s(the_key=)(\soptional-comment)
# where
#   - keytype is one of ssh-rsa or ssh-dss
#   - key value ends with "="
#   - no spaces are allowed in options, except in double-quoted strings
#
bundle edit_line append_or_replace_ssh_key(keyspec, key_content, index)
{

  vars:
    any::
      "eline"
        comment     => "An escaped version of the keyspec - \Q..\E do not escape everything",
        string      => escape("${keyspec}");
      "key" string => escape("${key_content}");

  insert_lines:

    "${keyspec}"
      # NOTE: this is only to ensure that insert is attempted *after* the replace,
      # as normally insert step precedes the replace, see
      # (https://cfengine.com/docs/3.5/manuals-language-concepts-normal-ordering.html)
      ifvarclass    => canonify("ssh_key_distribution_replace_step_attempted_${index}");

  replace_patterns:
    "^(?!${eline}$)(.*${key}.*)$"
      comment       => "Replace a key here",
      replace_with  => value("${keyspec}"),
      classes       => always("ssh_key_distribution_replace_step_attempted_${index}");

}

