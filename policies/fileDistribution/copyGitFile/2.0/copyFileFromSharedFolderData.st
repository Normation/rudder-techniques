#####################################################################################
# Copyright 2011-2013 Normation SAS
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
# List of files to copy from the shared folder
# Format of the file (filename cannot be there, as it may contain cfengine variable that would be unexpanded)
# recursion:owner:group:compare_method:perm:destination:uuid
&COPYFILE_RECURSION,COPYFILE_OWNER,COPYFILE_GROUP,COPYFILE_COMPARE_METHOD,COPYFILE_PERM,COPYFILE_DESTINATION,TRACKINGKEY:{recursion,owner,group,compare_method,perm,destination,uuid|&recursion&:&owner&:&group&:&compare_method&:&perm&:&destination&:&uuid&
}&

