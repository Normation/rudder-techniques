#! /bin/env perl 

# ============================================================================

# $Id: table.pl,v 6.0 2009/09/09 15:05:33 dtown Rel $

# Copyright (c) 2000-2009 David M. Town <dtown@cpan.org>
# All rights reserved.

# This program is free software; you may redistribute it and/or modify it
# under the same terms as the Perl 5 programming language system itself.

# ============================================================================

use strict;
use warnings;

use Net::SNMP qw( snmp_dispatcher SNMP_PORT );

# Create the SNMP session 
my ($session, $error) = Net::SNMP->session(
   -hostname  => $ARGV[0] || 'localhost',
   -community => $ARGV[1] || 'public',
   -port      => $ARGV[2] || SNMP_PORT,
   -version   => 'snmpv2c',
);

# Was the session created?
if (!defined $session) {
   printf "ERROR: %s.\n", $error;
   exit 1;
}

# iso.org.dod.internet.mgmt.interfaces.ifTable
my $OID_ifTable = '1.3.6.1.2.1.2.2';

printf "\n== SNMPv2c blocking get_table(): %s ==\n\n", $OID_ifTable;

my $result;

if (defined ($result = $session->get_table(-baseoid => $OID_ifTable))) {
   for ($session->var_bind_names()) {
      printf "%s => %s\n", $_, $result->{$_};
   }
   print "\n";
} else {
   printf "ERROR: %s.\n\n", $session->error();
}

$session->close();


###
## Now a non-blocking example
###

printf "\n== SNMPv2c non-blocking get_table(): %s ==\n\n", $OID_ifTable;

# Blocking and non-blocking objects cannot exist at the
# same time.  We must clear the reference to the blocking
# object or the creation of the non-blocking object will
# fail.

$session = undef;

# Create the non-blocking SNMP session
($session, $error) = Net::SNMP->session(
   -hostname    => $ARGV[0] || 'localhost',
   -community   => $ARGV[1] || 'public',
   -port        => $ARGV[2] || SNMP_PORT,
   -nonblocking => 1,
   -version     => 'snmpv2c',
);

# Was the session created?
if (!defined $session) {
   printf "ERROR: %s.\n", $error;
   exit 1;
}

if (!defined $session->get_table(-baseoid  => $OID_ifTable,
                                 -callback => \&print_results_cb))
{
   printf "ERROR: %s.\n", $session->error();
}

# Start the event loop
snmp_dispatcher();

print "\n";

exit 0;

sub print_results_cb
{
   my ($session) = @_;

   if (!defined $session->var_bind_list()) {
      printf "ERROR: %s.\n", $session->error();
   } else {
      for ($session->var_bind_names()) {
         printf "%s => %s\n", $_, $session->var_bind_list()->{$_};
      }
   }

   return;
}

# ============================================================================

