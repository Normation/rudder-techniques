#####################################################################################
#
#  Copyright (c) 2016 Janos Mattyasovszky
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#####################################################################################

bundle agent check_repo_gpg_key_RudderUniqueID
{

  vars:

      &GPG_KEY_ACTION:{action |"repo_gpg_action[&i&]" string => "&action&";
}&

      &GPG_KEY_HASH,GPG_KEY_NAME:{hash,name |"repo_gpg_hash[&i&]" string => "&hash&", comment => "&name&";
}&

      &TRACKINGKEY:{uuid |"repo_gpg_uuid[&i&]" string => "&uuid&";
}&

      "keyid" slist => getindices("repo_gpg_hash");

&GPG_KEY_CONTENT:{content |"repo_gpg_content[&i&]" string => "&content&";
}&

      "repo_gpg_hash_lc[${keyid}]" string => execresult("${paths.echo} ${repo_gpg_hash[${keyid}]} | ${paths.tr} \"[:upper:]\" \"[:lower:]\"","useshell"),
        comment => "We need lower case to query RPM and it's also used in the apt-based module for class definition.";

      "repo_gpg_hash_uc[${keyid}]" string => execresult("${paths.echo} ${repo_gpg_hash[${keyid}]} | ${paths.tr} \"[:lower:]\" \"[:upper:]\"","useshell"),
        comment => "To remove a key from APT we need the hash in explicit capital letters, lower/mixed case just does not work, even if it reports OK.";

      "repo_gpg_file[${keyid}]" string => "${runhook_repoGpgKeyManagementGetKeys.repo_gpg_homedir}/key_${keyid}_content",
        comment => "File to store the content of the key, used for later verification and import";


  classes:

      "repo_gpg_key_${keyid}_action_remove"
        expression => strcmp("${repo_gpg_action[${keyid}]}","del"),
        comment    => "We defined this class to set the requested action for this key: Remove it from the trusted keys";

      "repo_gpg_key_${keyid}_action_add"
        expression => strcmp("${repo_gpg_action[${keyid}]}","add"),
        comment    => "We defined this class to set the requested action for this key: Import it as a trusted key";

      "repo_gpg_has_gpg_binary"
        expression => isexecutable("${runhook_repoGpgKeyManagementGetKeys.repo_gpg_binary}"),
        comment    => "This defines if we have an executable gpg binary, necessary for gpg validation or enumerate the gpg keys on an RPM system";

      "repo_gpg_has_awk_binary"
        and     => { isvariable("paths.awk"), isexecutable("${paths.awk}") },
        comment => "We use awk to parse gpg's output, so it's required to be present for this to work...";

      "repo_gpg_uses_apt"
        and     => { isvariable("paths.apt_key"), isexecutable("${paths.apt_key}"), "repo_gpg_has_awk_binary" },
        comment => "We use apt if the path is known and is executable";

      "repo_gpg_has_rpm"
        and     => { isvariable("paths.rpm"), isexecutable("${paths.rpm}") },
        comment => "Here we check if it's and rpm-based system, but this does not mean we actually can handle the actions: we just know we could run";

      "repo_gpg_uses_rpm"
        and     => { "repo_gpg_has_rpm", "repo_gpg_has_gpg_binary", "repo_gpg_has_awk_binary" },
        comment => "We also need the GPG binary if on RPM-Based systems to check the long hash";

      "repo_gpg_key_${keyid}_has_last8_uc"
        expression => regextract(".{8}(.{8})", "${repo_gpg_hash_uc[${keyid}]}", "repo_gpg_hash_last8_uc[${keyid}]"),
        ifvarclass => "repo_gpg_uses_apt.repo_gpg_key_${keyid}_action_remove",
        comment    => "We need the last 8 UPPER-cased chars for apt-key del, it does not work with the full length key ID.";

      "repo_gpg_key_${keyid}_has_last8_lc"
        expression => regextract(".{8}(.{8})", "${repo_gpg_hash_lc[${keyid}]}", "repo_gpg_hash_last8_lc[${keyid}]"),
        ifvarclass => "repo_gpg_uses_rpm.repo_gpg_key_${keyid}_action_remove",
        comment    => "We also need the last 8 lower-cased chars for rpm -e for package removal, so we cut it down...";

  files:
      "${repo_gpg_file[${keyid}]}"
        comment       => "Create a temporary file to import the GPG key if it's not already imported and is required to be present.",
        create        => "true",
        edit_line     => insert_lines( "${repo_gpg_content[${keyid}]}" ),
        edit_defaults => empty,
        classes       => classes_generic("repo_gpg_file_${keyid}_created_RudderUniqueID"),
        ifvarclass    => "hook_repo_gpg_homedir_created_ok.hook_repo_gpg_hashes_read_ok.!hook_repo_gpg_key_${repo_gpg_hash_lc[${keyid}]}_present.repo_gpg_key_${keyid}_action_add";

      "${repo_gpg_file[${keyid}]}"
        comment    => "Remove temporary file if the GPG key has been successful.",
        delete     => tidy,
        classes    => classes_generic("repo_gpg_file_${keyid}_deleted_RudderUniqueID"),
        ifvarclass => "repo_gpg_key_${keyid}_imported_RudderUniqueID_ok";

  methods:

      ## Handle import/remove reports

      "any" usebundle => repo_gpg_report_RudderUniqueID("result_success",  "${keyid}", "The GPG Key is already imported"),
          ifvarclass => "repo_gpg_key_${keyid}_action_add.hook_repo_gpg_key_${repo_gpg_hash_lc[${keyid}]}_present";

      "any" usebundle => repo_gpg_report_RudderUniqueID("audit_noncompliant",  "${keyid}", "The GPG Key is not imported"),
           ifvarclass => "(dry_run|global_dry_run).repo_gpg_key_${keyid}_action_add.!hook_repo_gpg_key_${repo_gpg_hash_lc[${keyid}]}_present";


      "any" usebundle => repo_gpg_report_RudderUniqueID("result_repaired", "${keyid}", "The GPG Key was imported successfully"),
        ifvarclass => "repo_gpg_key_${keyid}_imported_RudderUniqueID_ok";

      "any" usebundle => repo_gpg_report_RudderUniqueID("result_error",    "${keyid}", "The GPG Key could not be imported"),
        ifvarclass => "repo_gpg_key_${keyid}_imported_RudderUniqueID_error";

      "any" usebundle => repo_gpg_report_RudderUniqueID("result_success",  "${keyid}", "The GPG Key is not imported"),
        ifvarclass => "repo_gpg_key_${keyid}_action_remove.hook_repo_gpg_hashes_read_ok.!hook_repo_gpg_key_${repo_gpg_hash_lc[${keyid}]}_present";

      "any" usebundle => repo_gpg_report_RudderUniqueID("result_repaired", "${keyid}", "The GPG Key was removed successfully"),
        ifvarclass => "repo_gpg_key_${keyid}_removed_RudderUniqueID_ok";

      "any" usebundle => repo_gpg_report_RudderUniqueID("result_error",    "${keyid}", "The GPG Key could not be removed"),
        ifvarclass => "repo_gpg_key_${keyid}_removed_RudderUniqueID_error";

      ## Handle temporary file related errors

      "any" usebundle => repo_gpg_report_RudderUniqueID("result_error",    "${keyid}", "The temporary file could not be created"),
        ifvarclass => "repo_gpg_file_${keyid}_created_RudderUniqueID_error";

      "any" usebundle => repo_gpg_report_RudderUniqueID("log_warn",        "${keyid}", "The temporary file could not be removed."),
        comment    => "This actually is not causing the file not being imported, it just leaves an unnecessary tmp file behind, which should not count as a hard error",
        ifvarclass => "repo_gpg_file_${keyid}_deleted_RudderUniqueID_error";

      ## Handle the hash verification failures

      "any" usebundle => repo_gpg_report_RudderUniqueID("result_error", "${keyid}", "The key's content contains multiple pubkeys!"),
        ifvarclass => "repo_gpg_hash_${keyid}_verified_RudderUniqueID_ok.repo_gpg_file_${repo_gpg_hash_lc[${keyid}]}_multikeyed";

      "any" usebundle => repo_gpg_report_RudderUniqueID("result_error", "${keyid}", "The key's content does not match the hash"),
        ifvarclass => "repo_gpg_hash_${keyid}_verified_RudderUniqueID_ok.!repo_gpg_file_${repo_gpg_hash_lc[${keyid}]}_validated";

      "any" usebundle => repo_gpg_report_RudderUniqueID("log_info",     "${keyid}", "The key's content belongs to the hash"),
        ifvarclass => "repo_gpg_hash_${keyid}_verified_RudderUniqueID_ok.repo_gpg_file_${repo_gpg_hash_lc[${keyid}]}_validated.!repo_gpg_file_${repo_gpg_hash_lc[${keyid}]}_multikeyed";

      "any" usebundle => repo_gpg_report_RudderUniqueID("result_error", "${keyid}", "The key's verification failed due to an unknown error!"),
        ifvarclass => "repo_gpg_hash_${keyid}_verified_RudderUniqueID_reached.repo_gpg_hash_${keyid}_verified_RudderUniqueID_error";

      "any" usebundle => repo_gpg_report_RudderUniqueID("result_error", "${keyid}", "The gpg binary '${runhook_repoGpgKeyManagementGetKeys.repo_gpg_binary}' is missing to verify the key!"),
        ifvarclass => "repo_gpg_file_${keyid}_created_RudderUniqueID_ok.!repo_gpg_has_gpg_binary";

      ## Handle generic issues

      "any" usebundle => repo_gpg_report_RudderUniqueID("result_error", "${keyid}", "Could not enumerate the existing keys"),
        ifvarclass => "hook_repo_gpg_hashes_read_error";

      "any" usebundle => repo_gpg_report_RudderUniqueID("result_na",    "${keyid}", "Can only handle RPM and APT at the moment."),
        ifvarclass => "!(repo_gpg_has_rpm|repo_gpg_uses_apt).repo_gpg_has_awk_binary";

      "any" usebundle => repo_gpg_report_RudderUniqueID("result_error", "${keyid}", "The gpg binary '${runhook_repoGpgKeyManagementGetKeys.repo_gpg_binary}' is missing, which is required to manage GPG keys on an RPM-Based system!"),
        ifvarclass => "repo_gpg_has_rpm.!repo_gpg_has_gpg_binary";

      "any" usebundle => repo_gpg_report_RudderUniqueID("result_error", "${keyid}", "The awk binary is missing from the system, this technique requires it!"),
        ifvarclass => "!repo_gpg_has_awk_binary";

  commands:

    repo_gpg_uses_apt|repo_gpg_uses_rpm::
       # we completly skip the command in dry run, so that it doesn't wrongly set the _reached class
      "${runhook_repoGpgKeyManagementGetKeys.repo_gpg_binary} ${runhook_repoGpgKeyManagementGetKeys.repo_gpg_options} ${repo_gpg_file[${keyid}]} | ${paths.awk} -v HASH='${repo_gpg_hash_lc[${keyid}]}' -F':' '$1 == \"pub\" { ++count; if (tolower($5) == HASH) { printf \"+repo_gpg_file_%s_validated\n\", HASH; } } END { if (count > 1) { printf \"+repo_gpg_file_%s_multikeyed\n\", HASH; } }'"
        comment    => "We verify the content of the key-field matches the actual hash that was provided by the user. We also check for multiple keys present in one key-field, which is not acceptable",
        ifvarclass => "!(dry_run|global_dry_run).repo_gpg_file_${keyid}_created_RudderUniqueID_ok.repo_gpg_has_gpg_binary",
        classes    => classes_generic("repo_gpg_hash_${keyid}_verified_RudderUniqueID"),
        contain    => outputable,
        module     => "true";

    repo_gpg_uses_apt::

      "${paths.apt_key} add ${repo_gpg_file[${keyid}]}"
        ifvarclass => "repo_gpg_hash_${keyid}_verified_RudderUniqueID_ok.repo_gpg_file_${repo_gpg_hash_lc[${keyid}]}_validated.!repo_gpg_file_${repo_gpg_hash_lc[${keyid}]}_multikeyed",
        comment    => "When verified_ok is defined, we already know the key needs to be added and is not present so we only need to check if the key is valid which we want to add",
        classes    => classes_generic("repo_gpg_key_${keyid}_imported_RudderUniqueID");

      "${paths.apt_key} del ${repo_gpg_hash_last8_uc[${keyid}][1]}"
        comment    => "This removes the GPG key from APT if it is present and needs to be removed",
        ifvarclass => "repo_gpg_key_${keyid}_action_remove.hook_repo_gpg_key_${repo_gpg_hash_lc[${keyid}]}_present.repo_gpg_key_${keyid}_has_last8_uc",
        classes    => classes_generic("repo_gpg_key_${keyid}_removed_RudderUniqueID");

    repo_gpg_uses_rpm::

      "${paths.rpm} --quiet --import ${repo_gpg_file[${keyid}]}"
        comment    => "This imports the GPG key if the necessary tmp file has been created and it needs to be imported and is not present",
        ifvarclass => "repo_gpg_hash_${keyid}_verified_RudderUniqueID_ok.repo_gpg_file_${repo_gpg_hash_lc[${keyid}]}_validated.!repo_gpg_file_${repo_gpg_hash_lc[${keyid}]}_multikeyed",
        classes    => classes_generic("repo_gpg_key_${keyid}_imported_RudderUniqueID");

      "${paths.rpm} --quiet --erase --allmatches gpg-pubkey-${repo_gpg_hash_last8_lc[${keyid}][1]}"
        comment    => "This removes the GPG key from RPM if it is present and needs to be removed",
        ifvarclass => "repo_gpg_key_${keyid}_action_remove.hook_repo_gpg_key_${repo_gpg_hash_lc[${keyid}]}_present.repo_gpg_key_${keyid}_has_last8_lc",
        classes    => classes_generic("repo_gpg_key_${keyid}_removed_RudderUniqueID");

}

bundle agent repo_gpg_report_RudderUniqueID(status, gpg_key_id, message)
{
  methods:
      "report" usebundle => rudder_common_report("repoGpgKeyManagement", "${status}", "${check_repo_gpg_key_RudderUniqueID.repo_gpg_uuid[${gpg_key_id}]}", "Repository GPG Key Management", "${check_repo_gpg_key_RudderUniqueID.repo_gpg_hash[${gpg_key_id}]}", "${message}");
}

