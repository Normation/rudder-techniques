#! /bin/env perl

# ============================================================================

# $Id: snmpkey.PL,v 6.0 2009/09/09 15:07:48 dtown Rel $

# Copyright (c) 2001-2009 David M. Town <dtown@cpan.org>
# All rights reserved.

# This program is free software; you may redistribute it and/or modify it
# under the same terms as the Perl 5 programming language system itself.

# ============================================================================

use strict;
use warnings;

use Config;

my $file = shift || 'snmpkey';

my $fh;

open($fh, q{>}, "$file") || die "Failed to open file '$file' [$!]";

print {$fh} "$Config{startperl}\n";

print {$fh} <<'AS-IS';

# ============================================================================

# $Id: snmpkey.PL,v 6.0 2009/09/09 15:07:48 dtown Rel $

# Copyright (c) 2001-2009 David M. Town <dtown@cpan.org>
# All rights reserved.

# This program is free software; you may redistribute it and/or modify it
# under the same terms as the Perl 5 programming language system itself.

# ============================================================================

=head1 NAME

snmpkey - Create SNMPv3 security keys for the Net::SNMP module

=head1 USAGE

The C<snmpkey> utility generates security keys based on a password and
an authoritativeEngineID passed on the command line.  This key can then
be used by the Net::SNMP module instead of the plain text password when
creating SNMPv3 objects.

   snmpkey <authProto> <password> <authEngineID> [<privProto> [<password>]]

=head1 DESCRIPTION

The User-based Security Model used by SNMPv3 defines an algorithm which
"localizes" a plain text password to a specific authoritativeEngineID using
a one-way hash.  This resulting key is used by the SNMP application instead
of the plain text password for security reasons.

The Net::SNMP module allows the user to either provide a plain text password
or a localized key to the object constructor when configuring authentication
or privacy.  The C<snmpkey> utility can be used to generate the key to be
used by the B<-authkey> or B<-privkey> named arguments when they are passed 
to the Net::SNMP C<session()> constructor.

=head1 REQUIRED ARGUMENTS

The C<snmpkey> utility requires at least three command line arguments.  The
first argument defines which hash algorithm to use when creating the authKey.
Either HMAC-MD5-96 or HMAC-SHA-96 can be specified with the string 'md5' or 
'sha' respectively.  This choice must match the algorithm passed to the 
B<-authprotocol> argument when creating the Net::SNMP object.  The second 
argument is the plain text password that is to be localized to create the 
authKey.  The third required argument is the authoritativeEngineID of the 
remote SNMP engine associated with the Net::SNMP argument B<-hostname>.  The 
authoritativeEngineID is to be entered as a hexadecimal string 10 to 64 
characters (5 to 32 octets) long and can be prefixed with an optional "0x".

The last two arguments are optional and can be used to determine how the
privKey will be generated.  By default, the fourth argument assumes a value
of 'des' corresponding to the default privacy protocol defined in the 
User-based Security Model.  The Net::SNMP module supports CBC-3DES-EDE and
CFB128-AES-128 as alternatives to the default protocol CBC-DES.  These
protocols can be chosen by specifying the string '3des' or 'aes' respectively.
This choice must match the protocol passed to the B<-privprotocol> argument 
when creating the Net::SNMP object.  The last argument can be used to specify 
the plain text password that is to be localized to create the privKey.  If 
this argument is not specified, the authKey password is used.

=head1 AUTHOR

David M. Town <dtown@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2001-2009 David M. Town.  All rights reserved.

This program is free software; you may redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

L<Net::SNMP>

=cut

# ============================================================================

use strict;
use warnings;

use Net::SNMP::Security::USM 4.0;

our $SCRIPT  = 'snmpkey';
our $VERSION = v6.0.0;

# Do we have enough/too much information?
if ((@ARGV < 3) || (@ARGV > 5)) {
   usage();
}

my ($usm, $error) = Net::SNMP::Security::USM->new(
   -authoritative => 1, # Undocumented / unsupported argument
   -username      => 'initial',
   -authprotocol  => $ARGV[0],
   -authpassword  => $ARGV[1],
   -engineid      => $ARGV[2],
   -privprotocol  => (@ARGV > 3) ? $ARGV[3] : 'des',
   -privpassword  => (@ARGV > 4) ? $ARGV[4] : $ARGV[1]
);

if (!defined $usm) {
   abort($error);
}

printf "authKey: 0x%s\n", unpack 'H*', $usm->auth_key();
printf "privKey: 0x%s\n", unpack 'H*', $usm->priv_key();

exit 0;

# [functions] ----------------------------------------------------------------

sub abort
{
   printf "$SCRIPT: " . ((@_ > 1) ? shift(@_) : '%s') . ".\n", @_;
   exit 1;
}

sub usage
{
   printf "%s v%vd\n", $SCRIPT, $VERSION;
   print << "USAGE";
Copyright (c) 2001-2009 David M. Town.  All rights reserved.
All rights reserved.
Usage: $SCRIPT <authProto> <password> <authEngineID> [<privProto> [<password>]]
       <authProto> = md5|sha
       <privProto> = des|3des|aes
USAGE
   exit 1;
}

# ============================================================================

AS-IS

close($fh) || die "Failed to close file '$file' [$!]";

chmod(0755, $file) || die "Failed to set permissions for file '$file' [$!]";

exit 0;

# ============================================================================

