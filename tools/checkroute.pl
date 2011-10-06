#!/usr/bin/env perl

use strict;
use warnings;

# splitroute.pl
# By Matthieu CERDA
# (C) Normation
#
# Splits the output of the route -ne command
# and checks if the given route matches one
# present in the kernel routing table.

sub Logic {

	# Variables init
	my $route = $_[0];
	my $mask = $_[1];
	my $gateway = $_[2];
	my $index = $_[3];
	my $isforced = $_[4];
	my $given_os = $_[5];
	my $validation = 0;
	my $route_cmd;
	my ($r1, $r2, $r3, $r4) = split(/\./, $route, 4);
	my ($m1, $m2, $m3, $m4) = split(/\./, $mask, 4);
	my ($g1, $g2, $g3, $g4) = split(/\./, $gateway, 4);

	# print("Route given : $route\n");

	if ( $given_os eq "windows" )
	{
		$route_cmd = 'C:\WINDOWS\System32\route.exe PRINT';
	}
	else
	{
		$route_cmd = '/sbin/route -ne';
	}

	open(ROUTE_CMD, "$route_cmd |") or die;

	while ( defined( my $line = <ROUTE_CMD> ) )
	{

		chomp($line); # Suppress CR/LF

		# If this line is a valid route and not some dummy text
		if ( my ($regexp) = ( $line =~ m/\b(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\b\ *\b(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\b\ *\b(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\b/ ) )
		{
			# Does this route matches the wanted one ?
			if ( (( $route eq $1 )&&( $gateway eq $2 )&&( $mask eq $3 ))||((( $route eq $1 )&&( $gateway eq $3 )&&( $mask eq $2 ))&&( $given_os eq "windows" )) )
			{
				if ( $isforced eq "delete" )
				{
					print("+route_" . $index . "_delete");
				}
				elsif ( $isforced eq "check-abs" )
				{
					print("+route_" . $index . "_found_warn");
				}
				else
				{
					print("+route_" . $index . "_found");
				}

				$validation = 1;

			}
		}
	}
	if ( $validation != 1 )
	{
		if ( $isforced eq "require" )
		{
			print("+route_" . $index . "_add");
		}
		elsif ( $isforced eq "check-pres" )
		{
			print("+route_" . $index . "_notfound_warn");
		}
		else
		{
			print("+route_" . $index . "_notfound");
		}
	}
}

if ( !defined($ARGV[0]) )
{
	die("+route_validation_error");
}

Logic(@ARGV);
