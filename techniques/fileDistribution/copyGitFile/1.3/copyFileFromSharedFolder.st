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


bundle agent download_from_shared_folder
{

  vars:

                &COPYFILE_NAME:{name |"copyfile[&i&][name]" string => "&name&";
}&

                &COPYFILE_RECURSION:{rec |"copyfile[&i&][recursion]" string => "&rec&";
}&

                &COPYFILE_OWNER:{owner |"copyfile[&i&][owner]" string => "&owner&";
}&

                &COPYFILE_GROUP:{group |"copyfile[&i&][group]" string => "&group&";
}&

                &COPYFILE_COMPARE_METHOD:{compare_method |"copyfile[&i&][compare_method]" string => "&compare_method&";
}&

                &COPYFILE_PERM:{perms |"copyfile[&i&][perm]" string => "&perms&";
}&

                &COPYFILE_DESTINATION:{destination |"copyfile[&i&][destination]" string => "&destination&";
}&

                &COPYFILE_POST_HOOK_COMMAND:{command |"copyfile[&i&][posthook]" string => "&command&";
}&

                &TRACKINGKEY:{piuuid |"copyfile[&i&][uuid]" string => "&piuuid&";
}&
      "shared_folder" string => "&SHARED_FILES_FOLDER&";

      "index" slist => getindices("copyfile");

  classes:
      "is_valid" not => strcmp("&SHARED_FILES_FOLDER&", "");

      "is_file_${index}" not => isdir("${copyfile[${index}][destination]}");
      "exist_${index}" expression => fileexists("${copyfile[${index}][destination]}");

                # Set a class to define when we need to run the post-modification hook
                &COPYFILE_POST_HOOK_RUN:{run |"execute_command_&i&" expression => strcmp("&run&", "true");
}&


  files:
    is_valid::

      "${copyfile[${index}][destination]}"
        copy_from => scp("&SHARED_FILES_FOLDER&/${copyfile[${index}][name]}", "${server_info.cfserved}", "${copyfile[${index}][compare_method]}", "false", "false", "false"),
        depth_search => recurse("${copyfile[${index}][recursion]}"),
        perms => mog("${copyfile[${index}][perm]}"
             , "${copyfile[${index}][owner]}"
             , "${copyfile[${index}][group]}"),
        comment => "Enforce content of ${copyfile[${index}][destination]} based on the content on the Rudder server with ${copyfile[${index}][compare_method]} method",
        classes => kept_if_else("copy_file_${index}_kept", "copy_file_${index}_modified", "copy_file_${index}_failed"),
        ifvarclass => "!exist_${index}|!is_file_${index}";

    # If it's a file, the depth_search prevents from enforcing the file content
      "${copyfile[${index}][destination]}"
        copy_from => scp("&SHARED_FILES_FOLDER&/${copyfile[${index}][name]}", "${server_info.cfserved}", "${copyfile[${index}][compare_method]}", "false", "false", "false"),
        perms => mog("${copyfile[${index}][perm]}"
             , "${copyfile[${index}][owner]}"
             , "${copyfile[${index}][group]}"),
        comment => "Enforce content of file ${copyfile[${index}][destination]} based on the content on the Rudder server with ${copyfile[${index}][compare_method]} method",
        classes => kept_if_else("copy_file_${index}_kept", "copy_file_${index}_modified", "copy_file_${index}_failed"),
        ifvarclass => "exist_${index}.is_file_${index}";

  commands:
      "${copyfile[${index}][posthook]}"
        contain => in_shell,
        classes => if_else("copyfile_posthook_${index}_command_run_ok", "copyfile_posthook_${index}_command_run_failed"),
        ifvarclass => "execute_command_${index}.copy_file_${index}_modified.!copy_file_${index}_failed",
        comment => "Execute the posthook command if a file was changed";

  reports:
    !is_valid::
      "@@copyFile@@result_error@@${copyfile[${index}][uuid]}@@Copy file@@${copyfile[${index}][name]}@@${g.execRun}##${g.uuid}@#There is no shared folder on the Rudder Server, so it's not possible to copy a file from it";
    linux|!linux::
      "@@copyFile@@result_success@@${copyfile[${index}][uuid]}@@Copy file@@${copyfile[${index}][name]}@@${g.execRun}##${g.uuid}@#The content of the file(s) is valid"
        ifvarclass => "copy_file_${index}_kept.!copy_file_${index}_modified.!copy_file_$(index)_failed";

      "@@copyFile@@result_repaired@@${copyfile[${index}][uuid]}@@Copy file@@${copyfile[${index}][name]}@@${g.execRun}##${g.uuid}@#The content or permissions of the file(s) has been repaired"
        ifvarclass => "copy_file_${index}_modified.!copy_file_$(index)_failed";

      "@@copyFile@@result_error@@${copyfile[${index}][uuid]}@@Copy file@@${copyfile[${index}][name]}@@${g.execRun}##${g.uuid}@#The content or permissions of the file(s) could not have been repaired for some reason"
        ifvarclass => "copy_file_${index}_failed";

    #posthook reports
      "@@copyFile@@result_success@@${copyfile[${index}][uuid]}@@Post-modification hook@@${copyfile[${index}][name]}@@${g.execRun}##${g.uuid}@#No post-hook command for ${copyfile[${index}][destination]} was defined, not executing"
        ifvarclass => "!execute_command_${index}";

      "@@copyFile@@result_success@@${copyfile[${index}][uuid]}@@Post-modification hook@@${copyfile[${index}][name]}@@${g.execRun}##${g.uuid}@#${copyfile[${index}][destination]} was already in the desired state, so no command was executed"
        ifvarclass => "execute_command_${index}.copy_file_${index}_kept.!copy_file_${index}_modified";

      "@@copyFile@@result_success@@${copyfile[${index}][uuid]}@@Post-modification hook@@${copyfile[${index}][name]}@@${g.execRun}##${g.uuid}@#The post-hook command for ${copyfile[${index}][destination]} was correctly executed"
        ifvarclass => "copyfile_posthook_${index}_command_run_ok";

      "@@copyFile@@result_error@@${copyfile[${index}][uuid]}@@Post-modification hook@@${copyfile[${index}][name]}@@${g.execRun}##${g.uuid}@#The post-hook command for ${copyfile[${index}][destination]} couldn't be executed"
        ifvarclass => "copyfile_posthook_${index}_command_run_failed";

      # A copy_from + perms could result in any combinaision of success/repaired/failed, so we have to cover the failed.modified which results in no copy
      "@@copyFile@@result_error@@$(copyfile[$(index)][uuid])@@Post-modification hook@@$(copyfile[$(index)][name])@@$(g.execRun)##$(g.uuid)@#$(copyfile[$(index)][destination]) couldn't be copied, so the post-hook command is not executed"
        ifvarclass => "execute_command_$(index).copy_file_$(index)_failed";
}
