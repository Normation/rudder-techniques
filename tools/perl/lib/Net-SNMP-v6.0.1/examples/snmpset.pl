#! /bin/env perl 

# ============================================================================

# $Id: snmpset.pl,v 6.0 2009/09/09 15:05:33 dtown Rel $

# Copyright (c) 2000-2009 David M. Town <dtown@cpan.org>
# All rights reserved.

# This program is free software; you may redistribute it and/or modify it
# under the same terms as the Perl 5 programming language system itself.

# ============================================================================

use strict;
use warnings;

use Net::SNMP 6.0 qw( :asn1 snmp_type_ntop DEBUG_ALL );
use Getopt::Std;

our $SCRIPT  = 'snmpset';
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
   exists($OPTS{P}) ? (-protocol     =>  $OPTS{P}) : (),
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

# Convert the ASN.1 types to the respresentation expected by Net::SNMP.
if (convert_asn1_types(\@ARGV)) {
   usage();
}

my @args = (
   exists($OPTS{E}) ? (-contextengineid => $OPTS{E}) : (),
   exists($OPTS{n}) ? (-contextname     => $OPTS{n}) : (),
   -varbindlist    => \@ARGV,
);

# Send the SNMP message.
if (!defined $s->set_request(@args)) {
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

sub convert_asn1_types
{
   my ($argv) = @_;

   # Mapping table: { "user input character" => constant byte value } 

   my %asn1_types = (
      'a' => IPADDRESS,
      'c' => COUNTER32,
      'C' => COUNTER64,
      'g' => GAUGE32,
      'h' => OCTET_STRING,
      'i' => INTEGER32,
      'o' => OBJECT_IDENTIFIER,
      'p' => OPAQUE,
      's' => OCTET_STRING,
      't' => TIMETICKS,
   );

   # Expect [OBJECT IDENTIFIER, ASN.1 type, object value] combination.

   if ((ref($argv) ne 'ARRAY') || (scalar(@{$argv}) % 3)) {
      return 1;
   }

   for (my $i = 0; $i < scalar @{$argv}; $i += 3) {
      if (exists $asn1_types{$argv->[$i+1]}) {
         if ($argv->[$i+1] eq 'h') {
            if ($argv->[$i+2] =~ m/^(?:0x)?([A-F\d]+)$/i) {
               # Convert hexadecimal string.
               $argv->[$i+2] = pack 'H*', length($1) % 2 ? '0'.$1 : $1;
            } else {
               abort(sprintf q{The string "%s" is is expected in } .
                             q{hexadecimal format for type 'h'},
                             $argv->[$i+2]);
            }
         }
         $argv->[$i+1] = $asn1_types{$argv->[$i+1]};
      } else {
         abort(sprintf 'The ASN.1 type "%s" is unknown', $argv->[$i+1]);
      }
   }

   return 0;
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
Usage: $SCRIPT [options] <hostname> <oid> <type> <value> [...]
Options: -v 1|2c|3      SNMP version
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
Valid type values:
          a - IpAddress           i - INTEGER
          c - Counter             o - OBJECT IDENTIFIER
          C - Counter64           p - Opaque
          g - Gauge/Unsigned32    s - OCTET STRING          
          h - OCTET STRING (hex)  t - TimeTicks
USAGE
   exit 1;
}

# ============================================================================

