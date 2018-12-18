#!/usr/bin/env perl

use strict;
use warnings;

# checkzmd.pl
# By Matthieu CERDA
# (C) Normation
#
# Splits the output of the rug command
# and checks if the given url's matches
# one of the configured catalogs

sub Logic {

        # Variables init
        my $name = $_[0];
        my $url = $_[1];
	my $index = $_[2];
        my $validation = 0;

	my $rug_cmd = '/usr/bin/rug catalogs --uri';

	# my $rug_cmd = './rug';

        open(RUG_CMD, "$rug_cmd |") or die;

        while ( defined( my $line = <RUG_CMD> ) )
        {
				# print $line;
				chomp($line); # Suppress CR/LF

				if ( my ($regexp) = ( $line =~ m/^.*\| (.*?) +\| (\S*)\s*/ ) )
				{
                        # Does this words matches the wanted ones ?
                        if ( ( $name eq $1 )&&( $url eq $2 ) )
                        {
                                print("+index_".$index."_matched");
				exit(0);
                        }
                }
        }
	print("+index_".$index."_not_matched");
}

#if ( !defined($ARGV[0]) )
#{
#        die("+route_validation_error");
#}

Logic(@ARGV);
