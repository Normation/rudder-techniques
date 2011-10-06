# -*- mode: perl -*-
# ============================================================================

# $Id: Makefile.PL,v 6.0 2009/09/09 15:07:28 dtown Rel $

# Makefile for the Perl module Net::SNMP.

# Copyright (c) 1998-2009 David M. Town <dtown@cpan.org>
# All rights reserved.

# This program is free software; you may redistribute it and/or modify it
# under the same terms as the Perl 5 programming language system itself.

# ============================================================================

eval { require 5.006 } or die <<'EOD';

 This version of Net::SNMP uses syntax that is not supported 
 in versions of Perl earlier than v5.6.0.

 Unable to install Net::SNMP with the current version of Perl.

EOD

use ExtUtils::MakeMaker qw(WriteMakefile);

WriteMakefile(
   AUTHOR        => 'David M. Town <dtown@cpan.org>',
   ABSTRACT      => 'Object oriented interface to SNMP',
   NAME          => 'Net::SNMP',
   DISTNAME      => 'Net-SNMP',
   VERSION_FROM  => 'lib/Net/SNMP.pm',
   EXE_FILES     => [ 'snmpkey', ],
   PL_FILES      => { 'snmpkey.PL' => 'snmpkey', },
   PREREQ_PM     => {
      Carp         => 0,
      Errno        => 0,
      Exporter     => 0,
      IO::Socket   => 0,
      Math::BigInt => 0,
      Crypt::DES   => '2.03',  # SNMPv3
      Digest::MD5  => '2.11',  # SNMPv3
      Digest::SHA1 => '1.02',  # SNMPv3
      Digest::HMAC => '1.00',  # SNMPv3
   },
   dist          => {
      CI           => 'ci -u -sRel -m\"Changes for $(VERSION)\"',
      RCS_LABEL    => 'rcs -N$(VERSION_SYM): -q',
      COMPRESS     => 'gzip --best',
      SUFFIX       => 'gz',
   },
   ($ExtUtils::MakeMaker::VERSION ge '6.31' ? ( 'LICENSE' => 'perl' ) : ()),
);

exit 0;

# ============================================================================

