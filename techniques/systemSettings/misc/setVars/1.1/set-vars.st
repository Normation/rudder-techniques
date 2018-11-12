#####################################################################################
# Copyright 2018 Normation SAS
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

# Define one or more variable on rudder
#   -Variables can be defined by a Json  file or a text input
#    -Allowed types are string and dict

bundle agent set_vars_RudderUniqueID {
  vars:
      #Tracking key
      &TRACKINGKEY:{key | "trackingkey[&i&]" string => "&key&";}&
      #Shared files
      "directory_server" string => "&SHARED_FILES_FOLDER&";
      "directory_agent" string => "/var/rudder/resources";

      #Variable type : dict or string
      &SET_VARS_TYPE: {type|"types[&i&]" string => "&type&";}&
      #Variable name and prefix
      &SET_VARS_NAME: {name|"complete_names[&i&]" string => "&name&";}&
      "strTok[${index}]" slist => splitstring("${complete_names[${index}]}", "\.", "2"); 
      "prefixes[${index}]" string => nth("strTok[${index}]", 0);
      "names[${index}]" string => nth("strTok[${index}]", 1);

      #Values src
      &SET_VARS_SRC: {src|"src_types[&i&]" string => "&src&";}&

      #Name of the Json file in case of a file src type
      &SET_VARS_FILE_NAME: {file_name|"files_names[&i&]" string => "&file_name&";}&

      #Entries in the text input case, can be a command to execute
&SET_VARS_STRING: {entry|"entries[&i&]" string => "&entry&";}&

      #Index
      "index" slist => getindices("complete_names");

      #Values
      "values[${index}]" string => "${entries[${index}]}",
       ifvarclass => "textSrc_${index}";
      "values[${index}]" string => execresult("${entries[${index}]}", "noshell"),
       ifvarclass => "commandSrc_${index}";


      #Canonified stuff
      "files_names_canon[${index}]" string => canonify("${files_names[${index}]}");
      "names_canon[${index}]" string => canonify("${names[${index}]}");

  classes:
      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";

      "dictType_${index}" expression => strcmp("${types[${index}]}", "dict");
      "stringType_${index}" expression => strcmp("${types[${index}]}", "string");

      "textSrc_${index}" expression => strcmp("${src_types[${index}]}", "input");
      "remote_file_source_${index}" expression => strcmp("${src_types[${index}]}", "remote_file");
      "local_file_source_${index}" expression => strcmp("${src_types[${index}]}", "local_file");
      "fileSrc_${index}" expression => "local_file_source_${index}|remote_file_source_${index}";
      "commandSrc_${index}" expression => strcmp("${src_types[${index}]}", "command");

  methods:
      #Downloading files from the server
      "prepare" usebundle => directory_create("${directory_agent}");

      "download_${index}"
        usebundle =>file_copy_from_remote_source("${directory_server}/${files_names[${index}]}", "${directory_agent}/${files_names_canon[${index}]}"),
        ifvarclass => "remote_file_source_${index}";

      "download_${index}"
        usebundle =>file_copy_from_local_source("${files_names[${index}]}", "${directory_agent}/${files_names_canon[${index}]}"),
        ifvarclass => "local_file_source_${index}";

      #String type variable case
      "load_${names[${index}]}"
        usebundle => variable_string("${prefixes[${index}]}", "${names[${index}]}", "${values[${index}]}"),
        ifvarclass => "stringType_${index}.(textSrc_${index}|commandSrc_${index})";


      "load_${names[${index}]}"
        usebundle => variable_string_from_file("${prefixes[${index}]}", "${names[${index}]}", "${directory_agent}/${files_names_canon[${index}]}"),
        ifvarclass => "stringType_${index}.fileSrc_${index}";

      #Dict type variable case
      "load_${names[${index}]}"
        usebundle => variable_dict("${prefixes[${index}]}", "${names[${index}]}", "${values[${index}]}"),
        ifvarclass => "dictType_${index}.(textSrc_${index}|commandSrc_${index})";

      "load_${names[${index}]}"
        usebundle => variable_dict_from_file("${prefixes[${index}]}", "${names[${index}]}", "${directory_agent}/${files_names_canon[${index}]}"),
        ifvarclass => "dictType_${index}.fileSrc_${index}";


################################################################################
#                                    REPORTING                                 # 
################################################################################

      "any" usebundle => rudder_common_reports_generic("setVars", "variable_string_${names_canon[${index}]}", "${trackingkey[${index}]}", "Load rudder variables", "${complete_names[${index}]}", "Definition of string variable ${complete_names[${index}]}"),
        ifvarclass => "stringType_${index}.(textSrc_${index}|commandSrc_${index})";

      "any" usebundle => rudder_common_reports_generic("setVars", "variable_string_from_file_${names_canon[${index}]}", "${trackingkey[${index}]}", "Load rudder variables", "${complete_names[${index}]}", "Definition of string variable ${complete_names[${index}]}"),
        ifvarclass => "stringType_${index}.fileSrc_${index}";

      "any" usebundle => rudder_common_reports_generic("setVars", "variable_dict_${names_canon[${index}]}", "${trackingkey[${index}]}", "Load rudder variables", "${complete_names[${index}]}", "Definition of dict variable ${complete_names[${index}]}"),
        ifvarclass => "dictType_${index}.(textSrc_${index}|commandSrc_${index})";

      "any" usebundle => rudder_common_reports_generic("setVars", "variable_dict_from_file_${names_canon[${index}]}", "${trackingkey[${index}]}", "Load rudder variables", "${complete_names[${index}]}", "Definition of dict variable ${complete_names[${index}]}"),
        ifvarclass => "dictType_${index}.fileSrc_${index}";

}

