# $File: //local/member/autrijus/Win32-Exe/lib/Win32/Exe/PE/Header.pm $ $Author: autrijus $
# $Revision: #5 $ $Change: 1130 $ $Date: 2004-02-17T15:40:29.640821Z $

package Win32::Exe::PE::Header;

use strict;
use base 'Win32::Exe::PE';
use constant SUBFORMAT => (
    Magic2	    => 'v',
    LMajor	    => 'C',
    LMinor	    => 'C',
    CodeSize	    => 'V',
    IDataSize	    => 'V',
    UDataSize	    => 'V',
    EntryPointRVA   => 'V',
    BaseOfCode	    => 'V',
    Data	    => 'a*',
);
use constant MEMBER_CLASS => 'Data';
use constant DISPATCH_FIELD => 'Magic2';
use constant DISPATCH_TABLE => (
    0x20b   => 'PE::Header::PE32Plus',
    '*'     => 'PE::Header::PE32',
);

1;
