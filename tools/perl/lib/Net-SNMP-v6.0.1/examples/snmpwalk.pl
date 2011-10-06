#! /bin/env perl 

# ============================================================================

# $Id: snmpwalk.pl,v 6.0 2009/09/09 15:05:33 dtown Rel $

# Copyright (c) 2000-2009 David M. Town <dtown@cpan.org>
# All rights reserved.

# This program is free software; you may redistribute it and/or modify it
# under the same terms as the Perl 5 programming language system itself.

# ============================================================================

use strict;
use warnings;

use Net::SNMP 6.0 qw( :snmp DEBUG_ALL ENDOFMIBVIEW );
use Getopt::Std;

our $SCRIPT  = 'snmpwalk';
our $VERSION = 'v6.0.0';

our %OPTS;

# Validate the command line options.
if (!getopts('a:A:c:CdD:E:m:n:p:r:t:u:v:x:X:', \%OPTS)) {
   usage();
}

# Do we have enough/too much information?
if (@ARGV != 2) {
   if (@ARGV == 1) {
      push @ARGV, '1.3.6.1.2.1'; # mib-2
   } else {
      usage();
   }
}

# Create the SNMP session.
my ($s, $e) = Net::SNMP->session(
   -hostname => shift,
   exists($OPTS{a}) ? (-authprotocol =>  $OPTS{a}) : (),
   exists($OPTS{A}) ? (-authpassword =>  $OPTS{A}) : (),
   exists($OPTS{c}) ? (-community    =>  $OPTS{c}) : (),
   exists($OPTS{D}) ? (-domain       =>  $OPTS{D}) : (),
   exists($OPTS{d}) ? (-debug        => DEBUG_ALL) : (),
   exists($OPTS{m}) ? (-maxmsgsize   =>  $OPTS{m}) : (),
   exists($OPTS{p}) ? (-port         =>  $OPTS{p}) : (),
   exists($OPTS{r}) ? (-retries      =>  $OPTS{r}) : (),
   exists($OPTS{t}) ? (-timeout      =>  $OPTS{t}) : (),
   exists($OPTS{u}) ? (-username     =>  $OPTS{u}) : (),
   exists($OPTS{v}) ? (-version      =>  $OPTS{v}) : (),
   exists($OPTS{x}) ? (-privprotocol =>  $OPTS{x}) : (),
   exists($OPTS{X}) ? (-privpassword =>  $OPTS{X}) : (),
);

# Was the session created?
if (!defined $s) {
   abort($e);
}

# Perform repeated get-next-requests or get-bulk-requests (SNMPv2c/v3) 
# until the last returned OBJECT IDENTIFIER is no longer a child of
# the OBJECT IDENTIFIER passed in on the command line.

my @args = (
   exists($OPTS{E}) ? (-contextengineid => $OPTS{E}) : (),
   exists($OPTS{n}) ? (-contextname     => $OPTS{n}) : (),
   -varbindlist    => [($ARGV[0] eq q{.}) ? '0' : $ARGV[0]],
);

my $last_oid = $ARGV[0];

if ($s->version() == SNMP_VERSION_1) {

   while (defined $s->get_next_request(@args)) {
      my $oid = ($s->var_bind_names())[0];
      lex_check($last_oid, $oid);
      if (!oid_base_match($ARGV[0], $oid)) {
         last;
      }
      display($s, ($last_oid = $oid));
      @args = (-varbindlist => [$last_oid]);
   }

} else {

   push @args, -maxrepetitions => 25;

   GET_BULK: while (defined $s->get_bulk_request(@args)) {

      my @oids = $s->var_bind_names();

      if (!scalar @oids) {
         abort('Received an empty varBindList');
      }

      for my $oid (@oids) {
         # Make sure we have not hit the end of the MIB.
         if ($s->var_bind_types()->{$oid} == ENDOFMIBVIEW) {
            display($s, $oid);
            last GET_BULK;
         }
         lex_check($last_oid, $oid);
         if (!oid_base_match($ARGV[0], $oid)) {
            last GET_BULK;
         }
         display($s, ($last_oid = $oid));
      }

      @args = (-maxrepetitions => 25, -varbindlist => [$last_oid]);
   }

}

# Let the user know about any errors.
if ($s->error()) {
   abort($s->error());
}

# Close the session.
$s->close();

exit 0;

# [functions] ----------------------------------------------------------------

sub display
{
   my ($s, $oid) = @_;

   printf "%s = %s: %s\n",
          $oid,
          snmp_type_ntop($s->var_bind_types()->{$oid}),
          $s->var_bind_list()->{$oid};

   return;
}

sub lex_check
{
   my ($current, $next) = @_;

   return if exists $OPTS{C};

   if (oid_lex_cmp($current, $next) >= 0) {
      printf "%s: Lexicographical error detected in response.\n", $SCRIPT;
      printf "   Current: %s\n", $current;
      printf "   Next:    %s\n", $next;
      exit 1;
   }

   return;
}

sub abort
{
   printf "$SCRIPT: " . ((@_ > 1) ? shift(@_) : '%s') . ".\n", @_;
   exit 1;
}

sub usage
{
   print << "USAGE";
$SCRIPT $VERSION
Copyright (c) 2000-2009 David M. Town.  All rights reserved.
Usage: $SCRIPT [options] <hostname> [oid]
Options: -v 1|2c|3      SNMP version
         -C             Do not check lexicographical ordering
         -d             Enable debugging
   SNMPv1/SNMPv2c:
         -c <community> Community name
   SNMPv3:
         -u <username>  Username (required)
         -E <engineid>  Context Engine ID
         -n <name>      Context Name
         -a <authproto> Authentication protocol <md5|sha>
         -A <password>  Authentication password
         -x <privproto> Privacy protocol <des|3des|aes>
         -X <password>  Privacy password
   Transport Layer:
         -D <domain>    Domain <udp|udp6|tcp|tcp6>
         -m <octets>    Maximum message size
         -p <port>      Destination port
         -r <attempts>  Number of retries
         -t <secs>      Timeout period
USAGE
   exit 1;
}

# ============================================================================

