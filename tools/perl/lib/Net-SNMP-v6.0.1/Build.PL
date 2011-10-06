# -*- mode: perl -*-
# ============================================================================

# $Id: Build.PL,v 6.0 2009/09/09 15:05:32 dtown Rel $

# Build.PL file for the Perl module Net::SNMP.

# Copyright (c) 2008-2009 David M. Town <dtown@cpan.org>
# All rights reserved.

# This program is free software; you may redistribute it and/or modify it
# under the same terms as the Perl 5 programming language system itself.

# ============================================================================

use Module::Build;

Module::Build->new(
   module_name        => 'Net::SNMP',
   dist_author        => 'David M. Town <dtown@cpan.org>',
   dist_abstract      => 'Object oriented interface to SNMP',
   dist_version_from  => 'lib/Net/SNMP.pm',
   license            => 'perl',
   script_files       => [ 'snmpkey', ],
   PL_files           => { 'snmpkey.PL' => 'snmpkey', },
   build_requires     => {
      Test            => 0,
   },
   requires           => {
      perl            => '5.006',
      Carp            => 0,
      Errno           => 0,
      Exporter        => 0,
      IO::Socket      => 0,
      Math::BigInt    => 0,
   },
   recommends         => {
      Crypt::DES      => '2.03',  # SNMPv3
      Digest::MD5     => '2.11',  # SNMPv3
      Digest::SHA1    => '1.02',  # SNMPv3
      Digest::HMAC    => '1.00',  # SNMPv3
      Crypt::Rijndael => '1.02',  # SNMPv3 - AES Cipher Algorithm 
      Socket6         => '0.23',  # UDP/IPv6 or TCP/IPv6 Transport Domain 
   },
   meta_merge         => {
      resources       => {
         bugtracker   =>
            'http://rt.cpan.org/Public/Dist/Display.html?Name=Net-SNMP',
         CPANForum    => 'http://www.cpanforum.com/dist/Net-SNMP',
      },
   },
   create_license     => 1,
)->create_build_script();

exit 0;

# ============================================================================
