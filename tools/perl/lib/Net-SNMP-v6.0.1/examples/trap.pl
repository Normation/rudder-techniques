#! //bin/env perl

# ============================================================================

# $Id: trap.pl,v 6.0 2009/09/09 15:05:33 dtown Rel $

# Copyright (c) 2000-2009 David M. Town <dtown@cpan.org>
# All rights reserved.

# This program is free software; you may redistribute it and/or modify it
# under the same terms as the Perl 5 programming language system itself.

# ============================================================================

use strict;
use warnings;

use Net::SNMP qw( :ALL );

my ($session, $error) = Net::SNMP->session(
   -hostname  => $ARGV[0] || 'localhost',
   -community => $ARGV[1] || 'public',
   -port      => SNMP_TRAP_PORT,      # Need to use port 162 
);

if (!defined $session) {
   printf "ERROR: %s.\n", $error;
   exit 1;
}

## Trap example specifying all values.

my $result = $session->trap(
   -enterprise   => '1.3.6.1.4.1',
   -agentaddr    => '10.10.1.1',
   -generictrap  => WARM_START,
   -specifictrap => 0,
   -timestamp    => 12363000,
   -varbindlist  => [
      '1.3.6.1.2.1.1.1.0', OCTET_STRING, 'Hub',
      '1.3.6.1.2.1.1.5.0', OCTET_STRING, 'Closet Hub',
   ],
);

if (!defined $result) {
   printf "ERROR: %s.\n", $session->error();
} else {
   printf "Trap-PDU sent.\n";
}

## A second trap example using mainly default values.

my @varbind = ( '1.3.6.1.2.1.2.2.1.7.0', INTEGER, 1, );

$result = $session->trap(-varbindlist  => \@varbind);

if (!defined $result) {
   printf "ERROR: %s.\n", $session->error();
} else {
   printf "Trap-PDU sent.\n";
}

$session->close();

## Create a new object with the version set to SNMPv2c 
## to send a snmpV2-trap.

($session, $error) = Net::SNMP->session(
   -hostname  => $ARGV[0] || 'localhost',
   -community => $ARGV[1] || 'public',
   -port      => SNMP_TRAP_PORT,      # Need to use port 162
   -version   => 'snmpv2c',
);

if (!defined $session) {
   printf "ERROR: %s.\n", $error;
   exit 1;
}

$result = $session->snmpv2_trap(
   -varbindlist => [
      '1.3.6.1.2.1.1.3.0',     TIMETICKS,         600,
      '1.3.6.1.6.3.1.1.4.1.0', OBJECT_IDENTIFIER, '1.3.6.1.4.1',
      '1.3.6.1.2.1.1.1.0',     OCTET_STRING,      'Hub',
      '1.3.6.1.2.1.1.5.0',     OCTET_STRING,      'Closet Hub',
   ]
);

if (!defined $result) {
   printf "ERROR: %s.\n", $session->error();
} else {
   printf "SNMPv2-Trap-PDU sent.\n";
}

$session->close();

exit 0;

# ============================================================================
