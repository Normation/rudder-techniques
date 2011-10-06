#! /bin/env perl 

# ============================================================================

# $Id: snmpgetbulk.pl,v 6.0 2009/09/09 15:05:32 dtown Rel $

# Copyright (c) 2000-2009 David M. Town <dtown@cpan.org>
# All rights reserved.

# This program is free software; you may redistribute it and/or modify it
# under the same terms as the Perl 5 programming language system itself.

# ============================================================================

use strict;
use warnings;

use Net::SNMP 6.0 qw( snmp_type_ntop DEBUG_ALL );
use Getopt::Std;

our $SCRIPT  = 'snmpgetbulk';
our $VERSION = 'v6.0.0';

our %OPTS;

# Validate the command line options.
if (!getopts('a:A:c:dD:E:m:n:p:r:t:u:v:x:X:', \%OPTS)) {
   usage();
}

# Do we have enough information?
if (@ARGV < 4) {
   usage();
}

# Create the SNMP session.
my ($s, $e) = Net::SNMP->session(
   -hostname  => shift,
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
   exists($OPTS{v}) ? (-version      =>  $OPTS{v}) : (-version => 'snmpv2c'),
   exists($OPTS{x}) ? (-privprotocol =>  $OPTS{x}) : (),
   exists($OPTS{X}) ? (-privpassword =>  $OPTS{X}) : (),
);

# Was the session created?
if (!defined $s) {
   abort($e);
}

my @args = (
   exists($OPTS{E}) ? (-contextengineid => $OPTS{E}) : (),
   exists($OPTS{n}) ? (-contextname     => $OPTS{n}) : (),
   -nonrepeaters   => shift,
   -maxrepetitions => shift,
   -varbindlist    => \@ARGV,
);

# Send the SNMP message.
if (!defined $s->get_bulk_request(@args)) {
   abort($s->error());
}

# Print the results.
for ($s->var_bind_names()) {
   printf "%s = %s: %s\n",
          $_,
          snmp_type_ntop($s->var_bind_types()->{$_}),
          $s->var_bind_list()->{$_};
}

# Close the session.
$s->close();

exit 0;

# [functions] ----------------------------------------------------------------

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
Usage: $SCRIPT [options] <hostname> <non-repeaters> <max-repetitions> <oid> [...] 
Options: -v 2c|3        SNMP version
         -d             Enable debugging
   SNMPv2c:
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

