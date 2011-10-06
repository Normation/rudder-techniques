# -*- mode: perl -*- 
# ============================================================================

# $Id: ber.t,v 6.0 2009/09/09 15:07:48 dtown Rel $

# Test of the Basic Encoding Rules used by SNMP. 

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

use Net::SNMP::Message qw(:types SNMP_VERSION_2C TRANSLATE_OCTET_STRING);

#
# 1. Create a Net::SNMP::Message object
# 

my ($m, $e);

eval
{
   ($m, $e) = Net::SNMP::Message->new(-version => SNMP_VERSION_2C);
};

ok(($@ || $e), q{}, 'Failed to create Net::SNMP::Message object');

#
# 2. Validate INTEGER = 4294967295
#

eval
{
   $m->prepare(INTEGER, 4294967295);
   $e = $m->process() || $m->error();
};

ok(($@ || $e), 4294967295, 'Failed to properly handle INTEGER');

#
# 3. Validate INTEGER = -128
#

eval
{
   $m->clear();
   $m->prepare(INTEGER, -128);
   $e = $m->process() || $m->error();
};

ok(($@ || $e), -128, 'Failed to properly handle INTEGER');

#
# 4. Validate OCTET STRING = 'David M. Town'
#

eval
{
   $m->clear();
   $m->prepare(OCTET_STRING, 'David M. Town');
   $e = $m->process() || $m->error();
};

ok(($@ || $e), 'David M. Town', 'Failed to properly handle OCTET STRING');

#
# 5. Validate OCTET STRING = 0xdeadbeef 
#

eval
{
   $m->clear();
   $m->translate(TRANSLATE_OCTET_STRING);
   $m->prepare(OCTET_STRING, pack 'H*', 'deadbeef');
   $e = $m->process() || $m->error();
};

ok(($@ || $e), '0xdeadbeef', 'Failed to properly handle OCTET STRING');

#
# 6. Validate OBJECT IDENTIFIER = '.1.3.6.1.3.4294967295.365.0.1'
#

eval
{
   $m->clear();
   $m->prepare(OBJECT_IDENTIFIER, '.1.3.6.1.3.4294967295.365.0.1');
   $e = $m->process || $m->error();
};

ok(
   ($@ || $e),
   '.1.3.6.1.3.4294967295.365.0.1',
   'Failed to properly handle OBJECT IDENTIFIER'
);

#
# 7. Validate Counter64 = 18446744073709551615
#

eval
{
   $m->clear();
   $m->prepare(COUNTER64, '18446744073709551615');
   $e = $m->process() || $m->error();
};

ok(($@ || $e), '18446744073709551615', 'Failed to properly handle Counter64');

# ============================================================================
