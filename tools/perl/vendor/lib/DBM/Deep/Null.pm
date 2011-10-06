package DBM::Deep::Null;

use 5.006_000;

use strict;
use warnings FATAL => 'all';

=head1 NAME

DBM::Deep::Null

=head1 PURPOSE

This is an internal-use-only object for L<DBM::Deep>. It acts as a NULL object
in the same vein as MARCEL's L<Class::Null>. I couldn't use L<Class::Null>
because DBM::Deep needed an object that always evaluated as undef, not an
implementation of the Null Class pattern.

=head1 OVERVIEW

It is used to represent null sectors in DBM::Deep.

=cut

use overload
    'bool'   => sub { undef },
    '""'     => sub { undef },
    '0+'     => sub { 0 },
    fallback => 1,
    nomethod => 'AUTOLOAD';

sub AUTOLOAD { return; }

1;
__END__
