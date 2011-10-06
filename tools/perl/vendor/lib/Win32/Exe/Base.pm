# $File: //local/member/autrijus/Win32-Exe/lib/Win32/Exe/Base.pm $ $Author: autrijus $
# $Revision: #8 $ $Change: 1130 $ $Date: 2004-02-17T15:40:29.640821Z $

package Win32::Exe::Base;

use strict;
use base 'Parse::Binary';
use constant BASE_CLASS => 'Win32::Exe';
use constant FORMAT => (
    Data	    => 'a',
);

sub align {
    my ($self, $value, $boundary) = @_;
    my $n = ($value % $boundary) or return $value;
    return($value + $boundary - $n);
}

sub pad {
    my ($self, $value, $bounary) = @_;
    my $x = length($value) % $bounary or return '';
    return "\0" x ($bounary - $x);
}

sub decode_ucs2 {
    my ($self, $string) = @_;
    return join('', map chr($_), unpack("v*", $string));
}

sub encode_ucs2 {
    my ($self, $string) = @_;
    return pack("v*", map ord($_), split(//, $string));
}

1;
