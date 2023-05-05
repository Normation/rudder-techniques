# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: 2021 Normation SAS

# Manage SSH Key - per user
# Allow to set keys for users, and optionnaly to flush all keys that are not managed by Rudder.


# Available data, coming from pre-hook:
#   class: ssh_key_distribution_<username>_to_flush            :if set, it is requested to flush the key of user
#          ssh_key_distribution_user_${userlist}_exists        :if set, the user exists on system
#   var: runhook_sshKeyDistribution_pre_hook.userlist          :list of user managed
#        runhook_sshKeyDistribution_pre_hook.homedir[<user>]   :homedir for user <user>
#        runhook_sshKeyDistribution_pre_hook.gid[<user>]       :gid for user <user>
#   files: first <username>.authorized_keys.tmp                :empty temp file for ssh keys

# Keys are put in the tmp file (overriding audit) and in the user ssh keys (abiding the audit mode)
#   if a key is not compliant for a user, in audit mode, it will define the  class ssh_key_distribution_<user>_prevent_flush to prevent flushing the keys, as it would change a key in audit

# Then in post-hook:
#    if all keys are kept status, then we compare the file sizes. If equals, then all is kept (resp compliant). If differents, in non audit, we flush the ssh key with the .tmp file, and flush component is repaired, in audit, they are all non compliant, with a message saying there are there, but there are extra keys
#    if any is in repaired, in enforce then we copy the ssh key from the .tmp, and keep the status of each keys, in audit we keep the compliant/non compliant status
#    if a key is non-compliant (in audit), there won't ben any flushing for this user.
#
# Please note that the last report of the Technique (component "Flush SSH file") is in the posthook of this technique

bundle agent check_ssh_key_distribution_&RudderUniqueID&
{

  meta:
      # Tags are necessaary for pre/post hook - to identify all the bundles for the differents directives
      "tags" slist => { "check_ssh_key_distribution_technique" };

  vars:

    any::
      "technique_name"  string  => "sshKeyDistribution";
      "component_name"  string  => "SSH key";


      &SSH_KEY_DISTRIBUTION_TAG:{key_tag |"sshkey_distribution_tag[&i&]" string => "&key_tag&";
}&
      &SSH_KEY_DISTRIBUTION_NAME:{distribution_name |"sshkey_distribution_name[&i&]" string => "&distribution_name&";
}&
      # Canonified name is necessary for hooks and class definitions. A login may contains a dash
      &SSH_KEY_DISTRIBUTION_NAME:{distribution_name |"sshkey_distribution_c_name[&i&]" string => canonify("&distribution_name&");
}&
&SSH_KEY_DISTRIBUTION_KEY:{distribution_key |"sshkey_distribution_key[&i&]" string => "&distribution_key&";
}&
      &SSH_KEY_DISTRIBUTION_EDIT_TYPE:{distribution_edit_type |"sshkey_distribution_edit_type[&i&]" string => "&distribution_edit_type&";
}&
      &TRACKINGKEY:{uuid |"sshkey_distribution_uuid[&i&]" string => "&uuid&";
}&

      "sshkey_distribution_index"
        slist   => getindices("sshkey_distribution_name");


      "is_audit_mode" string => "false",
                  if => "!(dry_run|global_dry_run)";

      "is_audit_mode" string => "true",
                  if => "dry_run|global_dry_run";


      "key_class_prefix[${sshkey_distribution_index}]"
        string  => canonify("${sshkey_distribution_tag[${sshkey_distribution_index}]}_${sshkey_distribution_uuid[${sshkey_distribution_index}]}");

      "ssh_types" string => "ssh-rsa|ssh-dss|ssh-ed25519|ecdsa-sha2-nistp521|ecdsa-sha2-nistp384|ecdsa-sha2-nistp256|ssh-dsa";

    # Extract key content from the keys
    # -E option to get rid of escaping char
      "sshkey_distribution_key_content_${sshkey_distribution_index}"
        string => execresult("${paths.echo} '${sshkey_distribution_key[${sshkey_distribution_index}]}' | ${paths.sed} -E 's/(.*\s+)?(${ssh_types})\s+(\S+)(\s.*)?/\3/'", "useshell"),
        if => "correct_ssh_key_format_${sshkey_distribution_index}";

  classes:
    pass2::
      # if a key for a given user is non compliant, in audit mode, then we prevent all flushing.
      "ssh_key_distribution_${sshkey_distribution_c_name[${sshkey_distribution_index}]}_prevent_flush" expression => "any",
        if => "(dry_run|global_dry_run).${key_class_prefix[${sshkey_distribution_index}]}_&RudderUniqueID&_error",
        scope      => "namespace";

    any::

      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";

      "correct_ssh_key_format_${sshkey_distribution_index}" expression => regcmp("(.*\s+)?(${ssh_types})\s+(\S+)(\s.*)?", "${sshkey_distribution_key[${sshkey_distribution_index}]}");

      "home_directory_${sshkey_distribution_index}_defined"        not => strcmp("${runhook_sshKeyDistribution_pre_hook.homedir[${sshkey_distribution_c_name[${sshkey_distribution_index}]}]}", "");
      "home_directory_${sshkey_distribution_index}_exists"  expression => isdir("${runhook_sshKeyDistribution_pre_hook.homedir[${sshkey_distribution_c_name[${sshkey_distribution_index}]}]}");

  files:
    pass2::
      # if home dir doesn't exist, create it with correct permission
      # Skip if home dir is undefined for the given user
      "${runhook_sshKeyDistribution_pre_hook.homedir[${sshkey_distribution_c_name[${sshkey_distribution_index}]}]}/."
        create        => "true",
        perms         => mog("700", "${sshkey_distribution_name[${sshkey_distribution_index}]}", "${runhook_sshKeyDistribution_pre_hook.gid[${sshkey_distribution_c_name[${sshkey_distribution_index}]}]}"),
        if => and( "ssh_key_distribution_user_${sshkey_distribution_c_name[${sshkey_distribution_index}]}_exists",
                   "correct_ssh_key_format_${sshkey_distribution_index}",
                   "!home_directory_${sshkey_distribution_index}_exists",
                   "home_directory_${sshkey_distribution_index}_defined"
                 );

      "${runhook_sshKeyDistribution_pre_hook.homedir[${sshkey_distribution_c_name[${sshkey_distribution_index}]}]}/.ssh/."
        create        => "true",
        perms         => mog("700", "${sshkey_distribution_name[${sshkey_distribution_index}]}", "${runhook_sshKeyDistribution_pre_hook.gid[${sshkey_distribution_c_name[${sshkey_distribution_index}]}]}"),
        if => and( "ssh_key_distribution_user_${sshkey_distribution_c_name[${sshkey_distribution_index}]}_exists",
                   "correct_ssh_key_format_${sshkey_distribution_index}",
                   "home_directory_${sshkey_distribution_index}_defined"
                 );


      # Caution, it can report both repaired and kept (permission ok + file repaired)
      "${runhook_sshKeyDistribution_pre_hook.homedir[${sshkey_distribution_c_name[${sshkey_distribution_index}]}]}/.ssh/authorized_keys"
        create        => "true",
        perms         => mog("600", "${sshkey_distribution_name[${sshkey_distribution_index}]}", "${runhook_sshKeyDistribution_pre_hook.gid[${sshkey_distribution_c_name[${sshkey_distribution_index}]}]}"),
        edit_line     => append_or_replace_ssh_key_&RudderUniqueID&("${sshkey_distribution_key[${sshkey_distribution_index}]}", "${sshkey_distribution_key_content_${sshkey_distribution_index}}", "${sshkey_distribution_index}"),
# should also define a class for the user
        classes       => classes_generic_two("${key_class_prefix[${sshkey_distribution_index}]}_&RudderUniqueID&", "check_ssh_key_distribution_user_key_${sshkey_distribution_c_name[${sshkey_distribution_index}]}"),
        if => and( "ssh_key_distribution_user_${sshkey_distribution_c_name[${sshkey_distribution_index}]}_exists",
                   "correct_ssh_key_format_${sshkey_distribution_index}",
                   "home_directory_${sshkey_distribution_index}_defined"
                 );

       # insert in temp file as well, inconditionnaly
      "${runhook_sshKeyDistribution_pre_hook.temp_ssh_key_path}/${sshkey_distribution_name[${sshkey_distribution_index}]}.authorized_keys.tmp"
        perms         => m("600"),
        edit_line     => append_or_replace_ssh_key_&RudderUniqueID&("${sshkey_distribution_key[${sshkey_distribution_index}]}", "${sshkey_distribution_key_content_${sshkey_distribution_index}}", "${sshkey_distribution_index}"),
        if => and( "ssh_key_distribution_user_${sshkey_distribution_c_name[${sshkey_distribution_index}]}_exists",
                   "correct_ssh_key_format_${sshkey_distribution_index}",
                   "home_directory_${sshkey_distribution_index}_defined"
                 );


  methods:
    pass2::
      "SSH Key Report"
        usebundle     => rudder_common_reports_generic(
          "${technique_name}", "${key_class_prefix[${sshkey_distribution_index}]}_&RudderUniqueID&",
          "${sshkey_distribution_uuid[${sshkey_distribution_index}]}", "${component_name}", "${sshkey_distribution_tag[${sshkey_distribution_index}]}",
          "SSH key \"${sshkey_distribution_tag[${sshkey_distribution_index}]}\" for user ${sshkey_distribution_name[${sshkey_distribution_index}]}"
        ),
        if => and( "ssh_key_distribution_user_${sshkey_distribution_c_name[${sshkey_distribution_index}]}_exists",
                   "correct_ssh_key_format_${sshkey_distribution_index}"
                 );

      "Wrong SSH Key Format Report"
        usebundle     => rudder_common_report(
          "${technique_name}", "result_error",
          "${sshkey_distribution_uuid[${sshkey_distribution_index}]}", "${component_name}", "${sshkey_distribution_tag[${sshkey_distribution_index}]}",
          "Wrong SSH key format \"${sshkey_distribution_tag[${sshkey_distribution_index}]}\" for user ${sshkey_distribution_name[${sshkey_distribution_index}]}"
        ),
        if => and( "!correct_ssh_key_format_${sshkey_distribution_index}",
                   "ssh_key_distribution_user_${sshkey_distribution_c_name[${sshkey_distribution_index}]}_exists"
                 );

      "No User Exist Report"
        usebundle     => rudder_common_report(
          "${technique_name}", "result_error",
          "${sshkey_distribution_uuid[${sshkey_distribution_index}]}", "${component_name}", "${sshkey_distribution_tag[${sshkey_distribution_index}]}",
          "The user ${sshkey_distribution_name[${sshkey_distribution_index}]} does NOT exist on this machine, not adding SSH key"
        ),
        if => and( "!ssh_key_distribution_user_${sshkey_distribution_c_name[${sshkey_distribution_index}]}_exists",
                   "correct_ssh_key_format_${sshkey_distribution_index}"
                 );

      "No User Exist and Wrong SSH Key Format Report"
        usebundle     => rudder_common_report(
          "${technique_name}", "result_error",
          "${sshkey_distribution_uuid[${sshkey_distribution_index}]}", "${component_name}", "${sshkey_distribution_tag[${sshkey_distribution_index}]}",
          "The user ${sshkey_distribution_name[${sshkey_distribution_index}]} does NOT exist on this machine, and the SSH key format is wrong"
        ),
        if => and( "!ssh_key_distribution_user_${sshkey_distribution_c_name[${sshkey_distribution_index}]}_exists",
                   "!correct_ssh_key_format_${sshkey_distribution_index}"
                 );

      "No User Home Defined For Target User"
        usebundle     => rudder_common_report(
          "${technique_name}", "result_error",
          "${sshkey_distribution_uuid[${sshkey_distribution_index}]}", "${component_name}", "${sshkey_distribution_tag[${sshkey_distribution_index}]}",
          "The user ${sshkey_distribution_name[${sshkey_distribution_index}]} does NOT have a home defined on this machine"
        ),
        if => and( "!home_directory_${sshkey_distribution_index}_defined",
                   "ssh_key_distribution_user_${sshkey_distribution_c_name[${sshkey_distribution_index}]}_exists"
                 );

}

# authorized_keys file contains one line per key, in the following format:
# (optional-options\s)(<keytype>)\s(the_key=)(\soptional-comment)
# where
#   - keytype is one of ssh-rsa or ssh-dss
#   - key value ends with "="
#   - no spaces are allowed in options, except in double-quoted strings
#
bundle edit_line append_or_replace_ssh_key_&RudderUniqueID&(keyspec, key_content, index)
{

  vars:
    any::
      "eline"
        comment     => "An escaped version of the keyspec - \Q..\E do not escape everything",
        string      => escape("${keyspec}");
      "key" string  => escape("${key_content}");

  insert_lines:
    "${keyspec}"
      # NOTE: this is only to ensure that insert is attempted *after* the replace,
      # as normally insert step precedes the replace, see
      # (https://cfengine.com/docs/3.5/manuals-language-concepts-normal-ordering.html)
      if => canonify("ssh_key_distribution_replace_step_attempted_${index}_&RudderUniqueID&");

  replace_patterns:
    "^(?!${eline}$)(.* ${key} .*)$"
      comment       => "Replace a key here",
      replace_with  => value("${keyspec}"),
      classes       => always("ssh_key_distribution_replace_step_attempted_${index}_&RudderUniqueID&");

}

