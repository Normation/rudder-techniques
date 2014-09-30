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

bundle agent root_postgres_check
{

  vars:

    SuSE::

      "configuration_statements" slist => { "host    all             rudder             ::1/128              md5", "host    all             rudder          127.0.0.1/32            md5" };

  files:

    SuSE::

      "/var/lib/pgsql/data/pg_hba.conf"
        edit_line => prepend("${configuration_statements}"),
        edit_defaults => noempty_backup,
        classes => kept_if_else("psql_conf_ok", "psql_conf_updated", "psql_conf_update_error"),
        comment => "Edit the SuSE postgresql configuration to enable account-less logins";

  commands:

    SuSE::

      "/etc/init.d/postgresql"
        args => "restart",
        classes => kept_if_else("psql_restart_ok", "psql_restart_ok", "psql_restart_error"),
        ifvarclass => "psql_conf_updated";

  reports:

    SuSE::

    # Report about the configuration file edition
      "@@DistributePolicy@@result_success@@&TRACKINGKEY&@@Check PostgreSQL configuration@@None@@${g.execRun}##${g.uuid}@#The SuSE specific postgresql configuration is present"
        ifvarclass => "psql_conf_ok.!psql_conf_updated.!psql_conf_update_error";

      "@@DistributePolicy@@result_repaired@@&TRACKINGKEY&@@Check PostgreSQL configuration@@None@@${g.execRun}##${g.uuid}@#The SuSE specific postgresql configuration has been added"
        ifvarclass => "psql_conf_updated.!psql_conf_update_error";

      "@@DistributePolicy@@result_error@@&TRACKINGKEY&@@Check PostgreSQL configuration@@None@@${g.execRun}##${g.uuid}@#The SuSE specific postgresql configuration could not be added"
        ifvarclass => "psql_conf_update_error";

    # Reports about Postgres restart status
      "@@DistributePolicy@@log_info@@&TRACKINGKEY&@@Check PostgreSQL configuration@@None@@${g.execRun}##${g.uuid}@#PostgreSQL has been restarted"
        ifvarclass => "psql_restart_ok";

      "@@DistributePolicy@@result_error@@&TRACKINGKEY&@@Check PostgreSQL configuration@@None@@${g.execRun}##${g.uuid}@#PostgreSQL restart has failed! Rudder is most certainly broken..."
        ifvarclass => "psql_restart_error";

    !SuSE::

      "@@DistributePolicy@@result_success@@&TRACKINGKEY&@@Check PostgreSQL configuration@@None@@${g.execRun}##${g.uuid}@#Their is no need of specific postgresql configuration on this system";
}
