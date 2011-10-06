# $File: //local/member/autrijus/Win32-Exe/lib/Win32/Exe/DebugTable.pm $ $Author: autrijus $
# $Revision: #6 $ $Change: 1130 $ $Date: 2004-02-17T15:40:29.640821Z $

package Win32::Exe::DebugTable;

use strict;
use base 'Win32::Exe::Base';
use constant FORMAT => (
    'DebugDirectory'	=> [ 'a28', '*', 1 ],
);

1;
