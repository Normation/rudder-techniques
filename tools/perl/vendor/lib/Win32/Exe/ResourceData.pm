# $File: //local/member/autrijus/Win32-Exe/lib/Win32/Exe/ResourceData.pm $ $Author: autrijus $
# $Revision: #6 $ $Change: 1130 $ $Date: 2004-02-17T15:40:29.640821Z $

package Win32::Exe::ResourceData;

use strict;
use base 'Win32::Exe::Base';
use constant FORMAT => (
    VirtualAddress  => 'V',
    Size	    => 'V',
    CodePage	    => 'V',
);

sub Data {
    my ($self) = @_;
    return $self->{data} if defined $self->{data};

    my $section = $self->first_parent('Resources');
    my $addr = $self->VirtualAddress or return;
    return $section->substr(
	$addr - $section->VirtualAddress,
	$self->Size
    );
}

sub SetData {
    my ($self, $data) = @_;
    $self->{data} = $data;
}

sub object {
    my ($self) = @_;
    return $self->{object};
}

sub path {
    my ($self) = @_;
    return $self->parent->path;
}

sub initialize {
    my ($self) = @_;

    my ($base) = $self->path or return;
    $base =~ /^#RT_(?!ICON$)(\w+)$/ or return;
    $self->VirtualAddress or return;

    my $data = $self->Data;
    my $class = ucfirst(lc($1));
    $class =~ s/_(\w)/\U$1/g;
    $class = $self->require_class("Resource::$class") or return;

    my $obj = $class->new(\$data, { parent => $self });
    $obj->initialize;
    $self->{object} = $obj;
}

1;
