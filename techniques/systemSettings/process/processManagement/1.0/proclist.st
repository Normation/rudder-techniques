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

# List of the process parameters to enforce
# Format of the file :
# policyIsntanceId, name:maximum_instances:minimum_instances
&TRACKINGKEY, PROCESS_NAME, PROCESS_MIN_INSTANCES, PROCESS_MAX_INSTANCES, PROCESS_COMMAND, PROCESS_MAX_ARGS:{policyInstanceId, name, maxInst, minInst, command, args | &policyInstanceId&,&name&,&maxInst&,&minInst&,&command&,&args&
}&
