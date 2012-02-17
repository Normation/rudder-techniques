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

# List of files permission
# Format of the file :
# directiveId:file:user:group:mode:edituser:editgroup:editmode:recursion
&TRACKINGKEY, FILEPERMISSION_FILENAME, FILEPERMISSION_USER, FILEPERMISSION_GROUP, FILEPERMISSION_MODE, FILEPERMISSION_EDITUSER, FILEPERMISSION_EDITGROUP, FILEPERMISSION_EDITMODE, FILEPERMISSION_RECURSION:{directiveId, fileName, user, group, perm, edituser, editgroup, editperm, recursion | &directiveId&:&fileName&:&user&:&group&:&perm&:&edituser&:&editgroup&:&editperm&:&recursion&
}&
