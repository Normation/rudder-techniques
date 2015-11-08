### Copyright (c) 2015 Janos Mattyasovszky

### The MIT License (MIT)
### Permission is hereby granted, free of charge, to any person obtaining a copy
### of this software and associated documentation files (the "Software"), to deal
### in the Software without restriction, including without limitation the rights
### to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
### copies of the Software, and to permit persons to whom the Software is
### furnished to do so, subject to the following conditions:
###
### The above copyright notice and this permission notice shall be included in all
### copies or substantial portions of the Software.
###
### THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
### IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
### FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
### AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
### LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
### OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
### SOFTWARE.


bundle agent check_repo_gpg_key
{

  vars:
    &GPG_KEY_ACTION:{action |"repo_gpg_action[&i&]" string => "&action&";
}&

    &GPG_KEY_HASH:{hash |"repo_gpg_hash[&i&]" string => "&hash&";
}&

    &TRACKINGKEY:{uuid |"repo_gpg_uuid[&i&]" string => "&uuid&";
}&

    "index_repo_gpg_keys" slist => getindices("repo_gpg_hash");

    ## Unfortunately string_downcase() is only available in 3.6.0, so we need to hack it with some shell execution
    "repo_gpg_hash_lc[${index_repo_gpg_keys}]" string => execresult("/bin/echo ${repo_gpg_hash[${index_repo_gpg_keys}]} | tr \"[:upper:]\" \"[:lower:]\"","useshell");

&GPG_KEY_CONTENT:{content |"repo_gpg_content[&i&]" string => "&content&";
}&

  classes:
    "repo_gpg_key_${index_repo_gpg_keys}_remove"
      expression => strcmp("${repo_gpg_action[${index_repo_gpg_keys}]}","del");

    "repo_gpg_key_${index_repo_gpg_keys}_add"
      expression => strcmp("${repo_gpg_action[${index_repo_gpg_keys}]}","add");

  commands:

   debian|ubuntu::
    "/usr/bin/apt-key adv --fingerprint 0x${repo_gpg_hash_lc[${index_repo_gpg_keys}]}"
      contain    => silent,
      comment    => "This calls directly gpg for the APT keyring. Could be improved by only fetching the content once and then matching the managed keys by that",
      classes    => if_else("repo_gpg_key_${index_repo_gpg_keys}_present", "repo_gpg_key_${index_repo_gpg_keys}_missing");

    "/usr/bin/apt-key add ${g.rudder_var_tmp}/gpg_key_${index_repo_gpg_keys}_content"
      ifvarclass => "repo_gpg_key_${index_repo_gpg_keys}_add.repo_gpg_key_${index_repo_gpg_keys}_missing.gpg_key_file_${index_repo_gpg_keys}_created",
      classes    => if_else("repo_gpg_key_${index_repo_gpg_keys}_imported", "repo_gpg_key_${index_repo_gpg_keys}_add_import_error");

    "/usr/bin/apt-key del 0x${repo_gpg_hash_lc[${index_repo_gpg_keys}]}"
      comment    => "This removes the GPG key from APT if it is present and needs to be removed",
      ifvarclass => "repo_gpg_key_${index_repo_gpg_keys}_remove.repo_gpg_key_${index_repo_gpg_keys}_present",
      classes    => if_else("repo_gpg_key_${index_repo_gpg_keys}_removed", "repo_gpg_key_${index_repo_gpg_keys}_remove_error");

   redhat|SuSE::
    "/bin/rpm --quiet -q gpg-pubkey-${repo_gpg_hash_lc[${index_repo_gpg_keys}]}"
      comment    => "This checks if each GPG key is installed or is missing, and defines appropriate classes for this to work with",
      classes    => if_else("repo_gpg_key_${index_repo_gpg_keys}_present", "repo_gpg_key_${index_repo_gpg_keys}_missing");

    "/bin/rpm --quiet -e gpg-pubkey-${repo_gpg_hash_lc[${index_repo_gpg_keys}]}"
      comment    => "This removes the GPG key from RPM if it is present and needs to be removed",
      ifvarclass => "repo_gpg_key_${index_repo_gpg_keys}_remove.repo_gpg_key_${index_repo_gpg_keys}_present",
      classes    => if_else("repo_gpg_key_${index_repo_gpg_keys}_removed", "repo_gpg_key_${index_repo_gpg_keys}_remove_error");

    "/bin/rpm --quiet --import ${g.rudder_var_tmp}/gpg_key_${index_repo_gpg_keys}_content"
      comment    => "This imports the GPG key if the necessary tmp file has been created and it needs to be imported and is not present",
      ifvarclass => "repo_gpg_key_${index_repo_gpg_keys}_add.repo_gpg_key_${index_repo_gpg_keys}_missing.gpg_key_file_${index_repo_gpg_keys}_created",
      classes    => if_else("repo_gpg_key_${index_repo_gpg_keys}_imported", "repo_gpg_key_${index_repo_gpg_keys}_add_import_error");

  files:
    "${g.rudder_var_tmp}/gpg_key_${index_repo_gpg_keys}_content"
      comment       => "Create a temporary file for repo to import the GPG key. Unfortunately rpm does not accept /dev/stdin or -",
      create        => "true",
      edit_line     => set_gpg_file_content( "${repo_gpg_content[${index_repo_gpg_keys}]}" ),
      edit_defaults => empty_nobackup,
      ifvarclass    => "!repo_gpg_key_${index_repo_gpg_keys}_present.repo_gpg_key_${index_repo_gpg_keys}_add",
      classes       => if_else("gpg_key_file_${index_repo_gpg_keys}_created", "gpg_key_file_${index_repo_gpg_keys}_create_failed");

    "${g.rudder_var_tmp}/gpg_key_${index_repo_gpg_keys}_content"
      comment    => "Remove temporary file if the GPG key has been imported successfully",
      delete     => tidy,
      ifvarclass => "repo_gpg_key_${index_repo_gpg_keys}_imported";

  reports:
    
    "@@repoGpgKeyManagement@@result_repaired@@${repo_gpg_uuid[${index_repo_gpg_keys}]}@@GPG Key Management@@${repo_gpg_hash[${index_repo_gpg_keys}]}@@${g.execRun}##${g.uuid}@#The GPG Key was imported successfully" 
      ifvarclass => "repo_gpg_key_${index_repo_gpg_keys}_imported";

    "@@repoGpgKeyManagement@@result_success@@${repo_gpg_uuid[${index_repo_gpg_keys}]}@@GPG Key Management@@${repo_gpg_hash[${index_repo_gpg_keys}]}@@${g.execRun}##${g.uuid}@#The GPG Key is already imported" 
      ifvarclass => "repo_gpg_key_${index_repo_gpg_keys}_add.repo_gpg_key_${index_repo_gpg_keys}_present";

    "@@repoGpgKeyManagement@@result_error@@${repo_gpg_uuid[${index_repo_gpg_keys}]}@@GPG Key Management@@${repo_gpg_hash[${index_repo_gpg_keys}]}@@${g.execRun}##${g.uuid}@#The GPG Key could not be imported"
      ifvarclass => "repo_gpg_key_${index_repo_gpg_keys}_add_import_error";

    "@@repoGpgKeyManagement@@result_repaired@@${repo_gpg_uuid[${index_repo_gpg_keys}]}@@GPG Key Management@@${repo_gpg_hash[${index_repo_gpg_keys}]}@@${g.execRun}##${g.uuid}@#The GPG Key was removed successfully"
      ifvarclass => "repo_gpg_key_${index_repo_gpg_keys}_removed"; 

    "@@repoGpgKeyManagement@@result_success@@${repo_gpg_uuid[${index_repo_gpg_keys}]}@@GPG Key Management@@${repo_gpg_hash[${index_repo_gpg_keys}]}@@${g.execRun}##${g.uuid}@#The GPG Key is not imported"
      ifvarclass => "repo_gpg_key_${index_repo_gpg_keys}_remove.repo_gpg_key_${index_repo_gpg_keys}_missing";

    "@@repoGpgKeyManagement@@result_error@@${repo_gpg_uuid[${index_repo_gpg_keys}]}@@GPG Key Management@@${repo_gpg_hash[${index_repo_gpg_keys}]}@@${g.execRun}##${g.uuid}@#The GPG Key could not be removed"
      ifvarclass => "repo_gpg_key_${index_repo_gpg_keys}_remove_error";

    "@@repoGpgKeyManagement@@result_error@@${repo_gpg_uuid[${index_repo_gpg_keys}]}@@GPG Key Management@@${repo_gpg_hash[${index_repo_gpg_keys}]}@@${g.execRun}##${g.uuid}@#The temporary file could not be created"
      ifvarclass => "gpg_key_file_${index_repo_gpg_keys}_create_failed";

}

bundle edit_line set_gpg_file_content(c)
{
  insert_lines:
    "${c}";
}

body edit_defaults empty_nobackup
{
   empty_file_before_editing => "true";
   edit_backup               => "false";
}

