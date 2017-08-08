#####################################################################################
# Copyright 2016 Normation SAS
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

bundle agent manage_key_value_file {
  vars:
      &MANAGE_KEY_VALUE_FILEPATH:{file |  "file[&i&]"        string => "&file&";
}&
      &MANAGE_KEY_VALUE_KEY:{key |  "key[&i&]"         string => "&key&";
}&
      &MANAGE_KEY_VALUE_VALUE:{value |  "value[&i&]"       string => "&value&";
}&
      &MANAGE_KEY_VALUE_SEPARATOR:{separator |  "separator[&i&]"   string => "&separator&";
}&
      &TRACKINGKEY:{uuid |  "trackingkey[&i&]" string => "&uuid&";
}&


    "index" slist => getindices("file");

    "canonified_file[${index}]"      string => canonify("${file[${index}]}");
    "class_prefix_${index}"          string => "file_ensure_key_value_${canonified_file[${index}]}";
    "technique_name"                 string => "Manage keys-values file";
  methods:
    "apply_${index}"   usebundle => file_ensure_key_value("${file[${index}]}", "${key[${index}]}", "${value[${index}]}", "${separator[${index}]}");
    "report_${index}"  usebundle => rudder_common_reports_generic_index("${technique_name}", "${class_prefix_${index}}",    "${trackingkey[${index}]}", "File", "${file[${index}]}", "The key -> value ${key[${index}]} ${separator[${index}]} ${value[${index}]}", "${index}");

}
