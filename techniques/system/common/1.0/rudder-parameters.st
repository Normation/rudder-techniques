# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: 2021 Normation SAS

# This file contain the Global Parameters, to be available within all
# promises, in the form ${rudder_parameters.parameterName}

# WARNING: This syntax will be deprecated, use the new one defined below ("rudder.parameters[]").

bundle common rudder_parameters {
  vars:
&RUDDER_PARAMETERS:{parameter |    "&parameter.escapedParameterName&" string => "&parameter.escapedValue&";
}&
}


# Read rudder global parameters and put them into the rudder bundle
#
# Parameters are available using the rudder.parameters container that contains the values
# Those values are read from /var/rudder/cfengine-community/inputs/rudder-parameters.json
#
# The file must contain at least a 2 levels JSON content, the first level is the namespace level
# (namely parameters) and the second level is the key level.
# The namespace name must comply with CFEngine variable names rules (ie [a-zA-Z_]+)
#

# The result key is available in the rudder.<namespace> data variable
# usage example: ${rudder.parameters[my_global_parameter]}
#
bundle agent rudder_global_parameters
{
  vars:
    # The files to read
    "parameters_file" string => "${this.promise_dirname}/../../rudder-parameters.json";

    # Read the files, 10MB maximum
    "parameters" data => readjson("${parameters_file}", "10000000");

    # Get namespace names
    "namespaces" slist => getindices("parameters");

    # Define the result variable
    "rudder.${namespaces}" data => mergedata("parameters[${namespaces}]", "{}");
}

