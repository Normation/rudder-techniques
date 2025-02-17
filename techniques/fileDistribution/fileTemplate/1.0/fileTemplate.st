# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: 2021 Normation SAS

# Take a template from the policy server and expand it
#   -Copy the template in /var/rudder/tmp/templates/
#   -Expand the template
#   -Take options in considerations(like perms)
#   -Reporting

bundle agent fileTemplate_&RudderUniqueID& {
  vars:
      #Tracking key
      &TRACKINGKEY:{key | "trackingkey[&i&]" string => "&key&";}&

      #Place to copy the template on the local node
      "temp" string => "/var/rudder/tmp/templates";
      "dir_perms" string => "750";
      "dir_owner" string => "root";
      "dir_group" string => "root";

      #Place from where to take the template on the policy server
      #"relative_src" string => "/var/rudder/configuration-repository/shared-files";
      "relative_src" string => "&SHARED_FILES_FOLDER&";
      #Root own
      &FILE_TEMPLATE_OWNER: {owner|"dst_owner[&i&]" string => "&owner&";}&
      &FILE_TEMPLATE_GROUP_OWNER: {group|"dst_group[&i&]" string => "&group&";}&

      #Relative path of the template or name of it
      &FILE_TEMPLATE_TEMPLATE: {src_path|"src[&i&]" string => "&src_path&";}&
      "src[${index}]" string => "${dst_canon[${index}]}.tpl",
        ifvarclass => "raw_${index}";

      #Choose between raw template and load from file
      &FILE_TEMPLATE_RAW_OR_NOT: {rawornot|"rawOrNot[&i&]" string => "&rawornot&";}&

      #Raw template text
&FILE_TEMPLATE_RAW_TEMPLATE: {txt|"rawTemplate[&i&]" string => "&txt&";
}&

      #Absolute path of the template expansion
      &FILE_TEMPLATE_AGENT_DESTINATION_PATH: {dst_path|"dst[&i&]" string => "&dst_path&";}&

      #Permissions rights
      &FILE_TEMPLATE_PERMISSIONS: {perms|"perms[&i&]" string => "&perms&";}&

      #Type of the template
      &FILE_TEMPLATE_TEMPLATE_TYPE: {type|"types[&i&]" string => "&type&";}&

      #Post hook command
&FILE_TEMPLATE_TEMPLATE_POST_HOOK_COMMAND: {command |"posthook[&i&]" string => "&command&";
}&

      #Post hook persistence
      &FILE_TEMPLATE_PERSISTENT_POST_HOOK: {persistence | "persist[&i&]" string => "&persistence&";}&

      #Index
      "index" slist => getindices("dst");

      #Name of the template, from its location
      "name[${index}]" string => lastnode("${src[${index}]}", "/");

      #Canonified names for reporting
      "src_canon[${index}]" string => canonify("${relative_src}/${src[${index}]}");
      "dst_canon[${index}]" string => canonify("${dst[${index}]}");
      "temp_canon[${index}]" string => canonify("${temp}/${name[${index}]}");
      "temp_dir_canon" string => canonify("${temp}");
      "posthook_canon[${index}]" string => canonify("${posthook[${index}]}");

      #Cancel persistent classes
      "cancel" string => "cancel persistence",
               classes => cancel_all_classes("posthook_rerun_${index}_&RudderUniqueID&"),
               ifvarclass => "command_execution_${posthook_canon[${index}]}_ok";

  classes:
      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";

      "raw_${index}"                   expression => strcmp("${rawOrNot[${index}]}", "Raw");
      "no_posthook_specified_${index}" expression => strcmp("${posthook[${index}]}", "");
      "file_modified_${index}"         expression => "permissions_${dst_canon[${index}]}_repaired|file_from_template_${dst_canon[${index}]}_repaired";
      "posthook_launch_${index}"       expression => "!no_posthook_specified_${index}.file_modified_${index}";
      "posthook_persistent_${index}"   expression => strcmp("${persist[${index}]}", "true");

      #Check if the posthook is persistent and in error, set up a class for 10000 minutes => about 1 week
      "posthook_rerun_${index}_&RudderUniqueID&" expression => "posthook_persistent_${index}.command_execution_${posthook_canon[${index}]}_failed",
                                               scope => "namespace",
                                               persistence => "10000";

  methods:
      #Ensure the templates are in a safe place
      "create_${temp}"
        usebundle => directory_create(
          "${temp}"
        );

      "perms_${temp}"
        usebundle => permissions_dirs(
          "${temp}",
          "${dir_perms}",
          "${dir_owner}",
          "${dir_group}"
        );

      #Copy the raw template text to /var/rudder/tmp/templates
      "create_${src[${index}]}"
        usebundle => file_enforce_content(
          "${temp}/${name[${index}]}",
          "${rawTemplate[${index}]}",
          "true"
        ),
        ifvarclass => "raw_${index}";
      
      #Copy the template from the root server to /var/rudder/tmp/templates
      "copy_${src[${index}]}"
        usebundle => file_copy_from_remote_source(
          "${relative_src}/${src[${index}]}",
          "${temp}/${name[${index}]}"
        ),
        ifvarclass => "!raw_${index}.!root_server";

      # On the root server, we copy from itself
      "copy_${src[${index}]}"
        usebundle => file_copy_from_local_source(
          "${relative_src}/${src[${index}]}",
          "${temp}/${name[${index}]}"
        ),
        ifvarclass => "!raw_${index}.root_server";

      #Expand the template on the given location
      "expand_${src[${index}]}"
        usebundle => file_from_template_type(
          "${temp}/${name[${index}]}",
          "${dst[${index}]}",
          "${types[${index}]}"
        );

    #Check permissions
    "perms_${dst[${index}]}"
      usebundle => permissions(
        "${dst[${index}]}",
        "${perms[${index}]}",
        "${dst_owner[${index}]}",
        "${dst_group[${index}]}"
      );

    #Post-Hook command
    "post_hook_${index}"
      usebundle => command_execution(
        "${posthook[${index}]}"
      ),
      ifvarclass => "posthook_launch_${index}|posthook_rerun_${index}_&RudderUniqueID&";

################################################################################
#                                    REPORTING                                 # 
################################################################################

pass3::
#Creation of the directory containing the templates

      "any" usebundle => rudder_common_reports_generic("fileTemplate", "directory_create_${temp_dir_canon}", "${trackingkey[${index}]}", "Templates location", "${dst[${index}]}", "The presence of the directory ${temp}/ containing the templates ");


#permissions of the directory containing the templates

      "any" usebundle => rudder_common_reports_generic("fileTemplate", "permissions_${temp_dir_canon}", "${trackingkey[${index}]}", "Templates directory permissions", "${dst[${index}]}", "The permissions ${dir_perms}, owner=${dir_owner}, group=${dir_group} on the directory ${temp}/");


#File copy in /var/rudder/tmp/

      "any" usebundle => rudder_common_reports_generic("fileTemplate", "file_copy_from_remote_source_${temp_canon[${index}]}", "${trackingkey[${index}]}", "Load Template from a file or text input", "${dst[${index}]}", "The copy of the file ${relative_src}/${src[${index}]} from the policy server to ${temp}/${name[${index}]}"),
      ifvarclass => "!root_server";


      "any" usebundle => rudder_common_reports_generic("fileTemplate", "file_copy_from_local_source_${temp_canon[${index}]}", "${trackingkey[${index}]}", "Load Template from a file or text input", "${dst[${index}]}", "The copy of the file ${relative_src}/${src[${index}]} from the policy server to ${temp}/${name[${index}]}"),
      ifvarclass => "root_server";

#Creation of the file from a raw input template

      "any" usebundle => rudder_common_reports_generic("fileTemplate", "file_ensure_lines_present_${temp_canon[${index}]}", "${trackingkey[${index}]}", "Load Template from a file or text input", "${dst[${index}]}", "The creation of the template ${temp}/${src[${index}]}");
            

#Expand the template

      "any" usebundle => rudder_common_reports_generic("fileTemplate", "file_from_template_${dst_canon[${index}]}", "${trackingkey[${index}]}", "Expand template", "${dst[${index}]}", "The expansion of the template ${temp}/${name[${index}]} in ${dst[${index}]}");


#Permissions on the generated conf file

      "any" usebundle => rudder_common_reports_generic("fileTemplate", "permissions_${dst_canon[${index}]}", "${trackingkey[${index}]}", "Put permissions", "${dst[${index}]}", "The application of the rights ${perms[${index}]} on the file ${dst[${index}]}, owner=${dst_owner[${index}]}  group=${dst_group[${index}]}");


#Posthook condition
      #Case with execution
      
      "any" usebundle => rudder_common_reports_generic("fileTemplate", "command_execution_${posthook_canon[${index}]}", "${trackingkey[${index}]}", "Posthook", "${dst[${index}]}", "The command ${posthook[${index}]} from postHook execution "),
      ifvarclass => "command_execution_${posthook_canon[${index}]}_reached";


      #Case without execution

      "report_${index}" usebundle  => rudder_common_report("fileTemplate", "result_na", "${trackingkey[${index}]}", "Posthook", "${dst[${index}]}", "No post-modification needed to run"),
      ifvarclass => "!file_modified_${index}.!no_posthook_specified_${index}.!command_execution_${posthook_canon[${index}]}_reached";


      #Case where no posthook set

      "report_hook_${index}" usebundle  => rudder_common_report("fileTemplate", "result_na", "${trackingkey[${index}]}", "Posthook", "${dst[${index}]}", "No post-modification set to run"),
      ifvarclass => "no_posthook_specified_${index}";
}

