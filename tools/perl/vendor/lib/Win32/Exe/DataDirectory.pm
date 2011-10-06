# $File: //local/member/autrijus/Win32-Exe/lib/Win32/Exe/DataDirectory.pm $ $Author: autrijus $
# $Revision: #6 $ $Change: 1130 $ $Date: 2004-02-17T15:40:29.640821Z $

package Win32::Exe::DataDirectory;

use strict;
use base 'Win32::Exe::Base';
use constant FORMAT => (
    VirtualAddress  => 'V',
    Size	    => 'V',
);

1;
