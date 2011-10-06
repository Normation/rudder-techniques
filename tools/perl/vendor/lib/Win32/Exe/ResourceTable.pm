# $File: //local/member/autrijus/Win32-Exe/lib/Win32/Exe/ResourceTable.pm $ $Author: autrijus $
# $Revision: #5 $ $Change: 1130 $ $Date: 2004-02-17T15:40:29.640821Z $

package Win32::Exe::ResourceTable;

use strict;
use base 'Win32::Exe::Base';
use constant FORMAT => (
    DebugDirectory	    => 'V',
    TimeStamp		    => 'V',
    VersionMajor	    => 'v',
    VersionMinor	    => 'v',
    NumNameEntry	    => 'v',
    NumIdEntry		    => 'v',
    'ResourceEntry::Name'   => [ 'a8', '{$NumNameEntry}', 1 ],
    'ResourceEntry::Id'	    => [ 'a8', '{$NumIdEntry}', 1 ],
);

sub set_path {
    my ($self, $path) = @_;
    $self->{path} = $path;
}

sub path {
    my ($self) = @_;
    wantarray ? @{$self->{path}} : $self->{path};
}

sub depth {
    my ($self) = @_;
    scalar @{$self->{path}};
}


1;
