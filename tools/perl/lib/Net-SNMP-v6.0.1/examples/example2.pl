#! /bin/env perl

# ============================================================================

# $Id: example2.pl,v 6.0 2009/09/09 15:05:32 dtown Rel $

# Copyright (c) 2000-2009 David M. Town <dtown@cpan.org>
# All rights reserved.

# This program is free software; you may redistribute it and/or modify it
# under the same terms as the Perl 5 programming language system itself.

# ============================================================================

use strict;
use warnings;

use Net::SNMP;

my $OID_sysContact = '1.3.6.1.2.1.1.4.0';

my ($session, $error) = Net::SNMP->session(
   -hostname     => 'myv3host.example.com',
   -version      => 'snmpv3',
   -username     => 'myv3Username',
   -authprotocol => 'sha1',
   -authkey      => '0x6695febc9288e36282235fc7151f128497b38f3f',
   -privprotocol => 'des',
   -privkey      => '0x6695febc9288e36282235fc7151f1284',
);

if (!defined $session) {
   printf "ERROR: %s.\n", $error;
   exit 1;
}

my $result = $session->set_request(
   -varbindlist => [ $OID_sysContact, OCTET_STRING, 'Help Desk x911' ],
);

if (!defined $result) {
   printf "ERROR: %s.\n", $session->error();
   $session->close();
   exit 1;
}

printf "The sysContact for host '%s' was set to '%s'.\n",
       $session->hostname(), $result->{$OID_sysContact};

$session->close();

exit 0;

# ============================================================================

