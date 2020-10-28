# SPDX-License-Identifier: GPL-3.0
# SPDX-FileCopyrightText: 2020 Normation SAS

bundle agent ips_repository_&RudderUniqueID& {
  methods:
    "ips_repository" usebundle => ips_repository_real_&RudderUniqueID&("&IPS_PUBLISHER_NAME&", "&IPS_PUBLISHER_URL&", "&IPS_PUBLISHER_ENABLED&");
}

bundle agent ips_repository_real_&RudderUniqueID&(name, url, enabled)  {
  vars:
    "args"    slist => { ${name}, ${url}, ${enabled} };
    "prefix" string => "Publisher check_${report_data.directive_id}";

  classes:
    "publisher_enable_required" expression => strcmp("${enabled}", "true");

  methods:
    "${prefix}_0" usebundle => _method_reporting_context("Publisher check", "${name}");
    "${prefix}_0" usebundle => condition_from_command("publisher_exist_${name}", "pkg publisher ${name} >/dev/null 2>/dev/null", "0", "1");

    "${prefix}_1" usebundle => _method_reporting_context("Publisher create", "${name}");
    "${prefix}_1" usebundle => command_execution("pkg set-publisher -g \"${url}\" \"${name}\""),
                         if => concat("condition_from_command_publisher_exist_",canonify("${name}"),"_false");
    "${prefix}_1" usebundle => log_na_rudder("Skipping method publisher creation since publisher exists. ", "", "${prefix}_1", @{args}),
                     unless => concat("condition_from_command_publisher_exist_",canonify("${name}"),"_false");

    "${prefix}_2" usebundle => _method_reporting_context("Publisher url check", "${name}");
    "${prefix}_2" usebundle => condition_from_command("publisher_url_check_${name}", "test \"${const.dollar}(LANG=C pkg publisher \"${name}\" 2>/dev/null | grep \"Origin URI:\" | awk '{print ${const.dollar}3}')\" = \"${url}\"", "0", "1");

    "${prefix}_3" usebundle => _method_reporting_context("Update publisher url", "${name}");
    "${prefix}_3" usebundle => command_execution("pkg set-publisher -G * -g \"${url}\" \"${name}\""),
                         if => concat("condition_from_command_publisher_exist_",canonify("${name}"),"_true.publisher_url_check_",canonify("${name}"),"_false");
    "${prefix}_3" usebundle => log_na_rudder("Skipping publisher url update. ", "", "${prefix}_3", @{args}),
                     unless => concat("condition_from_command_publisher_exist_",canonify("${name}"),"_true.publisher_url_check_",canonify("${name}"),"_false");

    "${prefix}_4" usebundle => _method_reporting_context("Publisher enabled check", "${name}");
    "${prefix}_4" usebundle => condition_from_command("publisher_enable_check_${name}", "test \"${const.dollar}(LANG=C pkg publisher \"${name}\" 2>/dev/null | grep \"enabled:\" | awk '{print ${const.dollar}2}')\" = \"Yes\"", "0", "1");

    "${prefix}_5" usebundle => _method_reporting_context("Enable publisher", "${name}");
    "${prefix}_5" usebundle => command_execution("pkg set-publisher -e \"${name}\""),
                         if => concat("condition_from_command_publisher_exist_",canonify("${name}"),"_true.publisher_enable_required.publisher_enable_check_",canonify("${name}"),"_false");
    "${prefix}_5" usebundle => log_na_rudder("Skipping publisher enabling. ", "", "${prefix}_5", @{args}),
                     unless => concat("condition_from_command_publisher_exist_",canonify("${name}"),"_true.publisher_enable_required.publisher_enable_check_",canonify("${name}"),"_false");

    "${prefix}_6" usebundle => _method_reporting_context("Disable publisher", "${name}");
    "${prefix}_6" usebundle => command_execution("pkg set-publisher -d \"${name}\""),
                         if => concat("condition_from_command_publisher_exist_",canonify("${name}"),"_true.!publisher_enable_required.publisher_enable_check_",canonify("${name}"),"_true");
    "${prefix}_6" usebundle => log_na_rudder("Skipping publisher disabling. ", "", "${prefix}_6", @{args}),
                     unless => concat("condition_from_command_publisher_exist_",canonify("${name}"),"_true.ipublisher_enable_required_.publisher_enable_check_",canonify("${name}"),"_true");

}
