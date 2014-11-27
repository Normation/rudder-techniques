#!/usr/bin/perl -w

use strict;
use warnings;

use XML::Parser;

my $xmlfile;

if($ARGV[0] ne "")
{
# stop beeing too verbose
#    print "Opening $ARGV[0]...\n";
    $xmlfile = shift @ARGV;              # the file to parse
}
else
{
    die("Syntax : xwf.pl file");
}
 
# initialize parser object and parse the string
my $parser = XML::Parser->new( ErrorContext => 2 );
eval { $parser->parsefile( $xmlfile ); };
 
# report any error that stopped parsing, or announce success
if( $@ ) {
    $@ =~ s/at \/.*?$//s;               # remove module line number
    print STDERR "\nERROR in '$xmlfile':\n$@\n";
    exit 1;
} else {
# stop beeing too verbose
#    print STDERR "'$xmlfile' is well-formed\n";
    exit 0;
}
