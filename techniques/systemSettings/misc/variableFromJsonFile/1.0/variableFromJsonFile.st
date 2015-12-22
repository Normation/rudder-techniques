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
    &JSON_FILE:{json_file |  "json_file[&i&]"        string => "&json_file&";
}&
    &NAMESPACE:{namespace |  "namespace[&i&]"        string => "&namespace&";
}&
    &VARIABLE_NAME:{name |  "name[&i&]"             string => "&name&";
}&
    &TRACKINGKEY:{piuuid |  "trackingkey[&i&]"      string => "&piuuid&";
}&

    "index" slist => getindices("json_file");

    "directory_server" string => "&SHARED_FILES_FOLDER&"; # shared files folder
    "directory_agent"  string => "/var/rudder/resources"; # we should use this directory from now on
    "technique_name"   string => "CFEngine variable definition using a JSON file";

    "canonified_json[${index}]"      string => canonify("${json_file[${index}]}");
    "class_prefix_download_${index}" string => canonify("file_copy_from_remote_source_${directory_agent}/${json_file[${index}]}");
    "class_prefix_apply_${index}"    string => canonify("variable_dict_from_file_${name[${index}]}");

  methods:
    "prepare"           usebundle => directory_create("${directory_agent}");
    "download_${index}" usebundle => file_copy_from_remote_source("${directory_server}/${json_file[${index}]}", "${directory_agent}/${canonified_json[${index}]}");
    "apply_${index}"    usebundle => variable_dict_from_file("${namespace[${index}]}", "${name[${index}]}", "${directory_agent}/${canonified_json[${index}]}");

# technique_name : the name of the technique, human readable
# class_prefix   : the prefix of a set of classes to reporting on (suffixes with "kept", "repaired" or "error")
# identifier     : the identifier of the current Rule and Directive
# component_name : the name of the component within the Technique
# component_key  : the value of the component reference variable (None if it does not exists)
# message_prefix : The begining of an explanation message understandable by a human
    "report download ${index}" usebundle => rudder_common_reports_generic("${technique_name}", "${class_prefix_download_${index}}", "${trackingkey[${index}]}", "File copy",           "${json_file[${index}]}", "The ${json_file[${index}]} file");

    "report apply ${index}"    usebundle => rudder_common_reports_generic("${technique_name}", "${class_prefix_apply_${index}}",    "${trackingkey[${index}]}", "Variable definition", "${json_file[${index}]}", "The ${namespace[${index}]}.${name[${index}]} variable");
}
