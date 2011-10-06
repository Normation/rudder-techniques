#! /bin/env perl

# ============================================================================

# $Id: example1.pl,v 6.0 2009/09/09 15:05:32 dtown Rel $

# Copyright (c) 2000-2009 David M. Town <dtown@cpan.org>
# All rights reserved.

# This program is free software; you may redistribute it and/or modify it
# under the same terms as the Perl 5 programming language system itself.

# ============================================================================

use strict;
use warnings;

use Net::SNMP;

my $OID_sysUpTime = '1.3.6.1.2.1.1.3.0';

my ($session, $error) = Net::SNMP->session(
   -hostname  => shift || 'localhost',
   -community => shift || 'public',
);

if (!defined $session) {
   printf "ERROR: %s.\n", $error;
   exit 1;
}

my $result = $session->get_request(-varbindlist => [ $OID_sysUpTime ],);

if (!defined $result) {
   printf "ERROR: %s.\n", $session->error();
   $session->close();
   exit 1;
}

printf "The sysUpTime for host '%s' is %s.\n",
       $session->hostname(), $result->{$OID_sysUpTime};

$session->close();

exit 0;

# ============================================================================

