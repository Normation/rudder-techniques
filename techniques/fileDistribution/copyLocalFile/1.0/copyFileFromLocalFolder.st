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


bundle agent copy_file_from_local
{

  vars:

                &COPYLOCALFILE_NAME:{name |"copylocalfile[&i&][name]" string => "&name&";
}&

                &COPYLOCALFILE_RECURSION:{rec |"copylocalfile[&i&][recursion]" string => "&rec&";
}&

                &COPYLOCALFILE_OWNER:{owner |"copylocalfile[&i&][owner]" string => "&owner&";
}&

                &COPYLOCALFILE_GROUP:{group |"copylocalfile[&i&][group]" string => "&group&";
}&

                &COPYLOCALFILE_COMPARE_METHOD:{compare_method |"copylocalfile[&i&][compare_method]" string => "&compare_method&";
}&

                &COPYLOCALFILE_PERM:{perms |"copylocalfile[&i&][perm]" string => "&perms&";
}&

                &COPYLOCALFILE_DESTINATION:{destination |"copylocalfile[&i&][destination]" string => "&destination&";
}&

                &COPYLOCALFILE_POST_HOOK_COMMAND:{command |"copylocalfile[&i&][posthook]" string => "&command&";
}&

                &TRACKINGKEY:{piuuid |"copylocalfile[&i&][uuid]" string => "&piuuid&";
}&
      "shared_folder" string => "&SHARED_FILES_FOLDER&";


      "index" slist => getindices("copylocalfile");

  classes:
      "is_valid" not => strcmp("&SHARED_FILES_FOLDER&", "");

      "is_file_${index}" not => isdir("${copylocalfile[${index}][destination]}");
      "exist_${index}" expression => fileexists("${copylocalfile[${index}][destination]}");

                # Set a class to define when we need to run the post-modification hook
                &COPYLOCALFILE_POST_HOOK_RUN:{run |"execute_command_&i&" expression => strcmp("&run&", "true");
}&


  files:
    is_valid::

      "${copylocalfile[${index}][destination]}"
        copy_from    => local_copy("${copylocalfile[${index}][name]}", "${copylocalfile[${index}][compare_method]}", "false", "true"),
        depth_search => recurse("${copylocalfile[${index}][recursion]}"),
        perms        => mog("${copylocalfile[${index}][perm]}", "${copylocalfile[${index}][owner]}", "${copylocalfile[${index}][group]}"),
        comment      => "Enforce content of ${copylocalfile[${index}][destination]} based on the content of ${copylocalfile[${index}][name]} with ${copylocalfile[${index}][compare_method]} method",
        classes      => kept_if_else("copy_file_${index}_kept", "copy_file_${index}_modified", "copy_file_${index}_failed"),
        ifvarclass   => "!exist_${index}|!is_file_${index}";

    # If it's a file, the depth_search prevents from enforcing the file content
      "${copylocalfile[${index}][destination]}"
        copy_from  => local_copy("${copylocalfile[${index}][name]}", "${copylocalfile[${index}][compare_method]}", "false", "true"),
        perms      => mog("${copylocalfile[${index}][perm]}", "${copylocalfile[${index}][owner]}", "${copylocalfile[${index}][group]}"),
        comment    => "Enforce content of file ${copylocalfile[${index}][destination]} based on the content of ${copylocalfile[${index}][name]} with ${copylocalfile[${index}][compare_method]} method",
        classes    => kept_if_else("copy_file_${index}_kept", "copy_file_${index}_modified", "copy_file_${index}_failed"),
        ifvarclass => "exist_${index}.is_file_${index}";

  commands:
      "${copylocalfile[${index}][posthook]}"
        contain => in_shell,
        classes => if_else("copylocalfile_posthook_${index}_command_run_ok", "copylocalfile_posthook_${index}_command_run_failed"),
        ifvarclass => "execute_command_${index}.copy_file_${index}_modified.!copy_file_${index}_failed",
        comment => "Execute the posthook command if a file was changed";

  reports:
    !is_valid::
      "@@copylocalfile@@result_error@@${copylocalfile[${index}][uuid]}@@Copy file@@${copylocalfile[${index}][name]}@@${g.execRun}##${g.uuid}@#There is no shared folder on the Rudder Server, so it's not possible to copy a file from it";
    linux|windows::
      "@@copylocalfile@@result_success@@${copylocalfile[${index}][uuid]}@@Copy file@@${copylocalfile[${index}][name]}@@${g.execRun}##${g.uuid}@#The content of the file(s) is valid"
        ifvarclass => "copy_file_${index}_kept.!copy_file_${index}_modified.!copy_file_$(index)_failed";

      "@@copylocalfile@@result_repaired@@${copylocalfile[${index}][uuid]}@@Copy file@@${copylocalfile[${index}][name]}@@${g.execRun}##${g.uuid}@#The content or permissions of the file(s) has been repaired"
        ifvarclass => "copy_file_${index}_modified.!copy_file_$(index)_failed";

      "@@copylocalfile@@result_error@@${copylocalfile[${index}][uuid]}@@Copy file@@${copylocalfile[${index}][name]}@@${g.execRun}##${g.uuid}@#The content or permissions of the file(s) could not have been repaired for some reason"
        ifvarclass => "copy_file_${index}_failed";

    #posthook reports
      "@@copylocalfile@@result_success@@${copylocalfile[${index}][uuid]}@@Post-modification hook@@${copylocalfile[${index}][name]}@@${g.execRun}##${g.uuid}@#No post-hook command for ${copylocalfile[${index}][destination]} was defined, not executing"
        ifvarclass => "!execute_command_${index}";

      "@@copylocalfile@@result_success@@${copylocalfile[${index}][uuid]}@@Post-modification hook@@${copylocalfile[${index}][name]}@@${g.execRun}##${g.uuid}@#${copylocalfile[${index}][destination]} was already in the desired state, so no command was executed"
        ifvarclass => "execute_command_${index}.copy_file_${index}_kept.!copy_file_${index}_modified";

      "@@copylocalfile@@result_success@@${copylocalfile[${index}][uuid]}@@Post-modification hook@@${copylocalfile[${index}][name]}@@${g.execRun}##${g.uuid}@#The post-hook command for ${copylocalfile[${index}][destination]} was correctly executed"
        ifvarclass => "copylocalfile_posthook_${index}_command_run_ok";

      "@@copylocalfile@@result_error@@${copylocalfile[${index}][uuid]}@@Post-modification hook@@${copylocalfile[${index}][name]}@@${g.execRun}##${g.uuid}@#The post-hook command for ${copylocalfile[${index}][destination]} couldn't be executed"
        ifvarclass => "copylocalfile_posthook_${index}_command_run_failed";

      # A copy_from + perms could result in any combinaision of success/repaired/failed, so we have to cover the failed.modified which results in no copy
      "@@copylocalfile@@result_error@@$(copylocalfile[$(index)][uuid])@@Post-modification hook@@$(copylocalfile[$(index)][name])@@$(g.execRun)##$(g.uuid)@#$(copylocalfile[$(index)][destination]) couldn't be copied, so the post-hook command is not executed"
        ifvarclass => "execute_command_$(index).copy_file_$(index)_failed";
}

body copy_from local_copy(from, compare, preserve, purge)
{                                                                                                                                                                                                                                                                                
        source   => "${from}";                                                                                                                                                                                                                                                   
        compare  => "${compare}";                                                                                                                                                                                                                                                
        verify   => "true";                                                                                                                                                                                                                                                      
        preserve => "${preserve}"; #preserver permissions                                                                                                                                                                                                                        
        purge    => "${purge}";                                                                                                                                                                                                                                                  
}                                                                                                                                                                                                                                                                                


