# $File: //local/member/autrijus/Win32-Exe/lib/Win32/Exe/Resource/Icon.pm $ $Author: autrijus $
# $Revision: #6 $ $Change: 1130 $ $Date: 2004-02-17T15:40:29.640821Z $

package Win32::Exe::Resource::Icon;

use strict;
use base 'Win32::Exe::Resource';
use constant FORMAT => (
    Width	    => 'C',
    Height	    => 'C',
    ColorCount	    => 'C',
    _		    => 'C',
    Planes	    => 'v',
    BitCount	    => 'v',
    ImageSize	    => 'V',
    I_RVA1	    => 'v',
    I_RVA2	    => 'v',
);

sub Id {
    my ($self) = @_;
    return $self->I_RVA1;
}

sub SetId {
    my ($self, $value) = @_;
    return $self->SetI_RVA1($value);
}

sub ImageOffset {
    my ($self) = @_;
    return $self->I_RVA1 + (($self->I_RVA2 || 0) * 65536);
}

sub SetImageOffset {
    my ($self, $value) = @_;
    $self->SetI_RVA1($value % 65536);
    $self->SetI_RVA2(int($value / 65536));
}

sub Data {
    my ($self) = @_;
    return $self->parent->substr($self->ImageOffset, $self->ImageSize);
}

sub dump {
    my ($self) = @_;
    my $parent = $self->parent;
    my $dump = $self->SUPER::dump;
    substr($dump, -2, 2, '') unless $parent->is_type('IconFile');
    return $dump;
}

1;
