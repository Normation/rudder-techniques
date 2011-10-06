# $File: //local/member/autrijus/Win32-Exe/lib/Win32/Exe/Resource.pm $ $Author: autrijus $
# $Revision: #7 $ $Change: 1130 $ $Date: 2004-02-17T15:40:29.640821Z $

package Win32::Exe::Resource;

use strict;
use base 'Win32::Exe::Base';

sub object {
    my ($self) = @_;
    return $self;
}

sub path {
    my ($self) = @_;
    return $self->parent->path;
}

sub CodePage {
    return 1252;
}

sub PathName {
    my ($self) = @_;
    return $self->{pathname} || $self->first_parent('ResourceEntry')->PathName;
}

sub SetPathName {
    my ($self, $value) = @_;
    $self->{pathname} = $value;
}

sub Data {
    my ($self) = @_;
    return $self->dump;
}

1;
