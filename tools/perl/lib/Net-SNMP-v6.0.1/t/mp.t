# -*- mode: perl -*- 
# ============================================================================

# $Id: mp.t,v 6.0 2009/09/09 15:07:49 dtown Rel $

# Test of the Message Processing Model. 

# Copyright (c) 2001-2009 David M. Town <dtown@cpan.org>.
# All rights reserved.

# This program is free software; you may redistribute it and/or modify it
# under the same terms as the Perl 5 programming language system itself.

# ============================================================================

use strict;
use Test;

BEGIN
{
   $|  = 1;
   $^W = 1;
   plan tests => 7
}

use Net::SNMP::MessageProcessing;
use Net::SNMP::PDU qw( OCTET_STRING SNMP_VERSION_2C );
use Net::SNMP::Security;
use Net::SNMP::Transport;

#
# 1. Get the Message Processing instance 
#

my $m;

eval
{
   $m = Net::SNMP::MessageProcessing->instance();
};

ok(defined $m, 1, 'Failed to get Net::SNMP::MessageProcessing instance');

#
# 2. Create a Security object
#

my ($s, $e);

eval
{
   ($s, $e) = Net::SNMP::Security->new(-version => SNMP_VERSION_2C);
};

ok(($@ || $e), q{}, 'Failed to create Net::SNMP::Security object');

#
# 3. Create a Transport Layer object
#

my $t;

eval
{
   ($t, $e) = Net::SNMP::Transport->new();
};

ok(($@ || $e), q{}, 'Failed to create Net::SNMP::Transport object');

#
# 4. Create a PDU object
#

my $p;

eval
{
   ($p, $e) = Net::SNMP::PDU->new(
      -version   => SNMP_VERSION_2C,
      -transport => $t,
      -security  => $s,
   );
};

ok(($@ || $e), q{}, 'Failed to create Net::SNMP::PDU object');

#
# 5. Prepare the PDU
#

eval
{
   $p->prepare_set_request(['1.3.6.1.2.1.1.4.0', OCTET_STRING, 'dtown']);
   $e = $p->error();
};

ok(($@ || $e), q{}, 'Failed to prepare set-request');

#
# 6. Prepare the Message
#

eval
{
   $p = $m->prepare_outgoing_msg($p);
   $e = $m->error();
};

ok(($@ || $e), q{}, 'Failed to prepare Message');

#
# 7. Process the message (should get error)
#

eval
{
   $m->prepare_data_elements($p);
   $e = $m->error();
};

ok(($@ || $e), qr/expected/i, 'Failed to process Message');

# ============================================================================
