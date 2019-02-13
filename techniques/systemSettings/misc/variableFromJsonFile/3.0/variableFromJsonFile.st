#####################################################################################
# Copyright 2019 Normation SAS
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

bundle agent variable_from_json_file_RudderUniqueID
{
  vars:
      &VARIABLE_FROM_JSON_FILE_JSON_FILE:{json_file | "json_file[&i&]" string => "&json_file&";
}&
      &TRACKINGKEY:{piuuid | "trackingkey[&i&]" string => "&piuuid&";
}&
      &VARIABLE_FROM_JSON_FILE_SOURCE:{source | "sources[&i&]" string => "&source&";
}&
      "complete_name"                        string => "&VARIABLE_FROM_JSON_FILE_VARIABLE_NAME&";
      "base_source"                          string => "&VARIABLE_FROM_JSON_FILE_BASE_SOURCE&";
      "base_file"                            string => "&VARIABLE_FROM_JSON_FILE_BASE_FILE&";

      "directory_server"                     string => "/var/rudder/configuration-repository/shared-files";
      "directory_agent"                      string => "/var/rudder/resources";
      "directory_agent_canon"                string => canonify("${directory_agent}");
      "prefix"                               string => "tmp_merging_json_files";

      "index"                                slist  => getindices("json_file");
      "files_index"                          slist  => sort("index", "int");
      "complete_name_canon"                  string => canonify("${complete_name}");
      "base_file_canon"                      string => canonify("${base_file}");
      "base_source_file_canon"               string => canonify("${directory_server}/${base_file}");
      "base_destination_file_canon"          string => canonify("${directory_agent}/${base_file}");
      "json_file_canon[${files_index}]"      string => canonify("${json_file[${files_index}]}");

      "name_list[${files_index}]"            string => "${complete_name}";
      "base_source_list[${files_index}]"     string => "${base_source}";
      "base_file_list[${files_index}]"       string => "${base_file}";
      "base_file_canon_list[${files_index}]" string => "${base_file_canon}";

      # Split the variable complete name in prefix and variable name
      "strTok"                                slist => splitstring("${complete_name}", "\.", "2");
      "variable_prefix"                      string => nth("strTok", 0);
      "variable_name"                        string => nth("strTok", 1);

  classes:
      "not_empty_input_${files_index}"                not => strcmp("", "${json_file[${files_index}]}");

      "base_remote_source"                     expression => strcmp("remote", "${base_source}");
      "base_local_source"                      expression => strcmp("local", "${base_source}");
      "base_remote_source_list_${files_index}" expression => "base_remote_source";
      "base_local_source_list_${files_index}"  expression => "base_local_source";

      "remote_source_${files_index}"           expression => strcmp("remote", "${sources[${files_index}]}");
      "local_source_${files_index}"            expression => strcmp("local", "${sources[${files_index}]}");
      "json_file_exists_${files_index}"        expression => fileexists("${json_file[${files_index}]}"),
        ifvarclass => "local_source_${files_index}";
      "json_file_exists_${files_index}"        expression => fileexists("${directory_agent}/${json_file_canon[${files_index}]}"),
        ifvarclass => "remote_source_${files_index}";

      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";

    pass3::
      "remote_base_file_ok" expression => "base_remote_source_list_${files_index}.file_copy_from_remote_source_${base_source_file_canon}_${base_destination_file_canon}_ok.variable_dict_from_file_${complete_name_canon}_${base_destination_file_canon}_ok";
      "local_base_file_ok"  expression => "base_local_source_list_${files_index}.file_copy_from_local_source_${base_file_canon}_${base_destination_file_canon}_ok.variable_dict_from_file_${complete_name_canon}_${base_destination_file_canon}_ok";
      "base_file_ok"        expression => "remote_base_file_ok|local_base_file_ok";


  methods:
    pass1::
      #Load the differents Json File
      "prepare" usebundle => directory_create("${directory_agent}");
      #Base file
      #Remote source
      "download_base_files" 
          usebundle => file_copy_from_remote_source(
            "${directory_server}/${base_file}",
            "${directory_agent}/${base_file_canon}"
          ),
          ifvarclass => "base_remote_source";

      #Local source
      "download_base_files" 
          usebundle => file_copy_from_local_source(
            "${base_file}",
            "${directory_agent}/${base_file_canon}"
          ),
          ifvarclass => "base_local_source";
   pass2::
      "apply_base_file"
          usebundle => variable_dict_from_file(
            "${variable_prefix}",
            "${variable_name}",
            "${directory_agent}/${base_file_canon}"
          );

    pass1::
      #Others files
      #Remote source
      "download_other_files_${files_index}" 
          usebundle => file_copy_from_remote_source(
            "${directory_server}/${json_file[${files_index}]}",
            "${directory_agent}/${json_file_canon[${files_index}]}"
          ),
          ifvarclass => "not_empty_input_${files_index}.remote_source_${files_index}";

      #Local source
      "download_other_files_${files_index}" 
          usebundle => file_copy_from_local_source(
            "${json_file[${files_index}]}",
            "${directory_agent}/${json_file_canon[${files_index}]}"
          ),
          ifvarclass => "not_empty_input_${files_index}.local_source_${files_index}";

    pass3::
      "apply_other_files_${files_index}"
          usebundle => variable_dict_from_file(
            "${prefix}",
            "${json_file_canon[${files_index}]}",
            "${directory_agent}/${json_file_canon[${files_index}]}"
          ),
          ifvarclass => "not_empty_input_${files_index}";

      #Merging
      "any" usebundle => variable_dict_merge("${variable_prefix}", "${variable_name}", "${complete_name}", "${prefix}.${json_file_canon[${files_index}]}"),
          ifvarclass => "not_empty_input_${files_index}.base_file_ok";
      "any" usebundle => rudder_common_reports_generic("variableFromJsonFile", "variable_dict_merge_${variable_name}", "${trackingkey[${files_index}]}", "Variable definition", "${json_file[${files_index}]}", "Merging ${prefix}.${json_file_canon[${files_index}]} with ${complete_name} in ${complete_name}"),
          ifvarclass => "not_empty_input_${files_index}.base_file_ok";
      
      #Reporting
      # Base file
      "any" usebundle => rudder_common_report_index("variableFromJsonFile", "result_success", "${trackingkey[${files_index}]}", "Base file", "${json_file[${files_index}]}", "Base variable definition from the shared file: ${base_file_list[${files_index}]} was correct", "${files_index}"),
          ifvarclass => "remote_base_file_ok";

      "any" usebundle => rudder_common_report_index("variableFromJsonFile", "result_success", "${trackingkey[${files_index}]}", "Base file", "${json_file[${files_index}]}", "Base variable definition from the local file: ${base_file_list[${files_index}]} was correct", "${files_index}"),
          ifvarclass => "local_base_file_ok";

      "any" usebundle => rudder_common_report_index("variableFromJsonFile", "result_error", "${trackingkey[${files_index}]}", "Base file", "${json_file[${files_index}]}", "Base variable definition from the shared file: ${base_file_list[${files_index}]}", "${files_index}"),
          ifvarclass => "!base_file_ok";

      #File copy
      #Remote
      "any" usebundle => rudder_common_reports_generic_index("variableFromJsonFile", "file_copy_from_remote_source_${directory_agent_canon}_${json_file_canon[${files_index}]}", "${trackingkey[${files_index}]}", "File copy", "${json_file[${files_index}]}", "Copy of ${directory_server}/${json_file[${files_index}]} from the policy server to ${directory_agent}", "${files_index}"),
          ifvarclass => "not_empty_input_${files_index}.remote_source_${files_index}";

      #Local
      "any" usebundle => rudder_common_reports_generic_index("variableFromJsonFile", "file_copy_from_local_source_${directory_agent_canon}_${json_file_canon[${files_index}]}", "${trackingkey[${files_index}]}", "File copy", "${json_file[${files_index}]}", "Copy of ${json_file[${files_index}]} to ${directory_agent}", "${files_index}"),
          ifvarclass => "not_empty_input_${files_index}.local_source_${files_index}";

      #Variable definition
      "any" usebundle => rudder_common_reports_generic_index("variableFromJsonFile", "variable_dict_from_file_${json_file_canon[${files_index}]}", "${trackingkey[${files_index}]}", "Overriding file", "${json_file[${files_index}]}", "${json_file[${files_index}]} loading", "${files_index}"),
          ifvarclass => "not_empty_input_${files_index}";

      # Error in the merging if the base variable could not be defined from the base file
      "any" usebundle => rudder_common_report_index("variableFromJsonFile", "result_error", "${trackingkey[${files_index}]}", "Variable definition", "${json_file[${files_index}]}", "Merging variable could not be executed since the base variable ${complete_name} could not be defined.", "${files_index}"),
          ifvarclass => "!base_file_ok";

      #Not applicable
      "any" usebundle => rudder_common_report_index("variableFromJsonFile", "result_na", "${trackingkey[${files_index}]}", "File copy", "${json_file[${files_index}]}", "No merging files precised", "${files_index}"),
          ifvarclass => "!not_empty_input_${files_index}";
      "any" usebundle => rudder_common_report_index("variableFromJsonFile", "result_na", "${trackingkey[${files_index}]}", "Overriding file", "${json_file[${files_index}]}", "No merging files precised", "${files_index}"),
          ifvarclass => "!not_empty_input_${files_index}";
      "any" usebundle => rudder_common_report_index("variableFromJsonFile", "result_na", "${trackingkey[${files_index}]}", "Variable definition", "${json_file[${files_index}]}", "No merging files precised", "${files_index}"),
          ifvarclass => "!not_empty_input_${files_index}";

}

