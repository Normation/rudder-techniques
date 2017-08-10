#####################################################################################
# Copyright 2015 Normation SAS
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

bundle agent variable_from_json_file
{
  vars:
    &VARIABLE_FROM_JSON_FILE_JSON_FILE:{json_file |  "json_file[&i&]"        string => "&json_file&";
}&
    &TRACKINGKEY:{piuuid |  "trackingkey[&i&]"      string => "&piuuid&";
}&
    &VARIABLE_FROM_JSON_FILE_VARIABLE_NAME:{name |  "complete_name[&i&]"      string => "&name&";
}&
    &VARIABLE_FROM_JSON_FILE_BASE_FILE:{base_file |  "base_file[&i&]"      string => "&base_file&";
}&

    &VARIABLE_FROM_JSON_FILE_SOURCE:{source |  "sources[&i&]"      string => "&source&";
}&
    &VARIABLE_FROM_JSON_FILE_BASE_SOURCE:{base_source |  "base_sources[&i&]"      string => "&base_source&";
}&
    "directory_server" string => "/var/rudder/configuration-repository/shared-files";
    "directory_agent"  string => "/var/rudder/resources";
    "directory_agent_canon" string => canonify("${directory_agent}");
    "prefix"           string => "tmp_merging_json_files";

    

    "variable_index"   slist  => getindices("complete_name");
    "index"            slist  => getindices("json_file");
    "files_index"      slist  => sort("index", "int");
    "tmp_index_1[${variable_index}]"      string  => eval("${variable_index} -1", "math", "infix"); 
    "index_from_zero[${variable_index}]" string => format("%d", "${tmp_index_1[${variable_index}]}");

    "strTok[${variable_index}]" slist => splitstring("${complete_name[${variable_index}]}", "\.", "2");
    "prefixes[${variable_index}]" string => nth("strTok[${variable_index}]", 0);
    "names[${variable_index}]" string => nth("strTok[${variable_index}]", 1);

    #Making an array with the unique trackingkey, with shell for the moment. Waiting for future feature on 
    # string template implementation in the webapp
    "cmd" string => "/usr/bin/uniq << EOF ${const.n}&TRACKINGKEY:{piuuid |&piuuid&};separator="${const.n}"&${const.n}EOF${const.n}"; 

    "long_keys" string => execresult("${cmd}", "useshell");
    "long_keys_list" slist => splitstring("${long_keys}", "${const.n}", "999");
    "unique_keys[${variable_index}]" string => nth("long_keys_list", "${index_from_zero[${variable_index}]}");


    #Making an array containing the complete_name as many times as their respectives 
    #number of files to merge. The array's length must be equal to the trackingkey array length.
    "name_list[${files_index}]" string => "${complete_name[${variable_index}]}",
      ifvarclass => "same_key_${variable_index}_${files_index}";

    "base_file_canon[${variable_index}]" string => canonify("${base_file[${variable_index}]}");
    "json_file_canon[${files_index}]" string => canonify("${json_file[${files_index}]}");


  classes:
    "same_key_${variable_index}_${files_index}" expression => strcmp("${unique_keys[${variable_index}]}", "${trackingkey[${files_index}]}");
    "not_empty_input_${files_index}" not => strcmp("", "${json_file[${files_index}]}");

    "base_remote_source_${variable_index}" expression => strcmp("remote", "${base_sources[${variable_index}]}");
    "base_local_source_${variable_index}" expression => strcmp("local", "${base_sources[${variable_index}]}");
    "remote_source_${files_index}" expression => strcmp("remote", "${sources[${files_index}]}");
    "local_source_${files_index}" expression => strcmp("local", "${sources[${files_index}]}");
    "pass3" expression => "pass2";
    "pass2" expression => "pass1";
    "pass1" expression => "any";


  methods:
    #Load the differents Json File
    "prepare" usebundle => directory_create("${directory_agent}");
    #Base file
    #Remote source
    "download_base_files_${variable_index}" 
        usebundle => file_copy_from_remote_source(
          "${directory_server}/${base_file[${variable_index}]}",
          "${directory_agent}/${base_file_canon[${variable_index}]}"
        ),
        ifvarclass => "base_remote_source_${variable_index}";

    #Local source
    "download_base_files_${variable_index}" 
        usebundle => file_copy_from_local_source(
          "${base_file[${variable_index}]}",
          "${directory_agent}/${base_file_canon[${variable_index}]}"
        ),
        ifvarclass => "base_local_source_${variable_index}";

    "apply_base_file_${variable_index}"
        usebundle => variable_dict_from_file(
          "${prefixes[${variable_index}]}",
          "${names[${variable_index}]}",
          "${directory_agent}/${base_file_canon[${variable_index}]}"
        );

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

    "apply_other_files_${files_index}"
        usebundle => variable_dict_from_file(
          "${prefix}",
          "${json_file_canon[${files_index}]}",
          "${directory_agent}/${json_file_canon[${files_index}]}"
        ),
        ifvarclass => "not_empty_input_${files_index}";


    #Merging
    "merging_${files_index}" usebundle => merge("${name_list[${files_index}]}" , "${prefix}.${json_file_canon[${files_index}]}", "${json_file[${files_index}]}", "${trackingkey[${files_index}]}"),
        ifvarclass => "not_empty_input_${files_index}";
    
    #Reporting
    #File copy
    #Remote
    "any" usebundle => rudder_common_reports_generic("variableFromJsonFile", "file_copy_from_remote_source_${directory_agent_canon}_${json_file_canon[${files_index}]}", "${trackingkey[${files_index}]}", "File copy", "${json_file[${files_index}]}", "Copy of ${directory_server}/${json_file[${files_index}]} from the policy server to ${directory_agent}"),
        ifvarclass => "not_empty_input_${files_index}.remote_source_${files_index}";

    #Local
    "any" usebundle => rudder_common_reports_generic("variableFromJsonFile", "file_copy_from_local_source_${directory_agent_canon}_${json_file_canon[${files_index}]}", "${trackingkey[${files_index}]}", "File copy", "${json_file[${files_index}]}", "Copy of ${json_file[${files_index}]} to ${directory_agent}"),
        ifvarclass => "not_empty_input_${files_index}.local_source_${files_index}";

    #Variable definition
    "any" usebundle => rudder_common_reports_generic("variableFromJsonFile", "variable_dict_from_file_${json_file_canon[${files_index}]}", "${trackingkey[${files_index}]}", "Overriding file", "${json_file[${files_index}]}", "${json_file[${files_index}]} loading"),
        ifvarclass => "not_empty_input_${files_index}";

    #Not applicable
    pass3::
      "any" usebundle => rudder_common_report("variableFromJsonFile", "result_na", "${trackingkey[${files_index}]}", "File copy", "${json_file[${files_index}]}", "No merging files precised"),
          ifvarclass => "!not_empty_input_${files_index}";
      "any" usebundle => rudder_common_report("variableFromJsonFile", "result_na", "${trackingkey[${files_index}]}", "Overriding file", "${json_file[${files_index}]}", "No merging files precised"),
          ifvarclass => "!not_empty_input_${files_index}";
      "any" usebundle => rudder_common_report("variableFromJsonFile", "result_na", "${trackingkey[${files_index}]}", "Variable definition", "${json_file[${files_index}]}", "No merging files precised"),
          ifvarclass => "!not_empty_input_${files_index}";
}

bundle agent merge(complete_var_name, file_var, file_name, trackingkey) {
  vars:
    "strTok" slist => splitstring("${complete_var_name}", "\.", "2");
    "prefix" string => nth("strTok", 0);
    "name" string => nth("strTok", 1);

  methods:
    "any" usebundle => variable_dict_merge("${prefix}", "${name}", "${complete_var_name}", "${file_var}");
    "any" usebundle => rudder_common_reports_generic("variableFromJsonFile", "variable_dict_merge_${name}", "${trackingkey}", "Variable definition", "${file_name}", "Merging ${file_var} with ${complete_var_name} in ${complete_var_name}");
}

