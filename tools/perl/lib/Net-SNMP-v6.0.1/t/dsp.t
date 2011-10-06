# -*- mode: perl -*- 
# ============================================================================

# $Id: dsp.t,v 6.1 2010/09/10 00:01:22 dtown Rel $

# Test of the Net::SNMP Dispatcher and Transport Domain objects. 

# Copyright (c) 2009 David M. Town <dtown@cpan.org>.
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
   plan tests => 15
}

use Net::SNMP::Dispatcher;
use Net::SNMP::Transport;

#
# 1. Create transmit and receive Transport Domain objects
#

my ($r, $tr, $ts) = (100);

eval
{
   while ((!defined $tr || !defined $ts) && $r-- > 0) {
      my $p = (int rand(65535 - 1025)) + 1025;
      $tr = Net::SNMP::Transport->new(-localport => $p);
      $ts = Net::SNMP::Transport->new(-port => $p);
   }
};

ok(
   defined $tr && defined $ts, 1,
   'Failed to create Net::SNMP::Transport objects'
);

#
# 2. Get the Dispatcher instance
#

my $d;

eval
{
   $d = Net::SNMP::Dispatcher->instance();
};

ok(defined $d, 1, 'Failed to get the Net::SNMP::Dispatcher instance');

#
# 3. Register the receive Transport Domain object
#

eval
{
   $r = $d->register($tr, [\&trans_recv]);
};

ok($r, $tr, 'Failed to register receive transport - trans_recv()');

#
# 4. Schedule timer test 1 - timer_test()
#

eval
{
   $r = $d->schedule(1, [\&timer_test, 1, time]);
};

ok(defined $r, 1, 'Failed to schedule timer test 1 - timer_test()');

#
# 5. Schedule timer test 2 - timer_test()
#

eval
{
   $r = $d->schedule(2, [\&timer_test, 2, time]);
};

ok(defined $r, 1, 'Failed to schedule timer test 2 - timer_test()');

#
# 6. Schedule timer test 3 - trans_send()
#

eval
{
   $r = $d->schedule(3, [\&trans_send, 3, time, $ts]);
};

ok(defined $r, 1, 'Failed to schedule timer test 3 - trans_send()');

#
# 7. Schedule timer test 4 - trans_dereg()
#

eval
{
   $r = $d->schedule(4, [\&trans_dereg, 4, time, $tr]);
};

ok(defined $r, 1, 'Failed to schedule timer test 4 - trans_dereg()');


$d->loop();

exit 0;

#
# 8. - 9. Validate that timer tests 1 and 2 executed within 1 second tolerence 
#

sub timer_check
{
   my ($c, $s) = @_;

   my $d = time - $s;

   return (($d >= $c - 1) && ($d <= $c + 1)) ? $c : $d;
}

sub timer_test
{
   my ($d, $c, $s) = @_;

   ok(timer_check($c, $s), $c, "timer_test(): Timer test $c failed");

   return;
}

#
# 10. - 11. Validate timer test 3 and Net::SNMP::Transport->send()
#

sub trans_send
{
   my ($d, $c, $s, $t) = @_;

   ok(timer_check($c, $s), $c, "trans_send(): Timer test $c failed");

   $c = $t->send(' ');

   ok($c, 1, 'trans_send(): Transport send() failed');

   return;
}

#
# 12. - 13. Validate the transport registration and transport recv()
#

sub trans_recv
{
   my ($d, $t) = @_;

   ok(defined $t, 1, 'trans_recv(): Transport registration failed');

   my $b;

   my $c = $t->recv($b, 10, 0);

   ok(defined $c, 1, 'trans_recv(): Transport recv() failed');

   return;
}

#
# 14. - 15. Validate timer test 4 and transport deregistration
#

sub trans_dereg
{
   my ($d, $c, $s, $t) = @_;

   ok(timer_check($c, $s), $c, "trans_dereg(): Timer test $c failed");

   $c = $d->deregister($t);

   ok($c, $t, 'trans_dereg(): Failed to deregister receive transport');

   return;
}

# ============================================================================
