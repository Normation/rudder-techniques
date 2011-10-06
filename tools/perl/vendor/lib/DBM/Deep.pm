package DBM::Deep;

use 5.006_000;

use strict;
use warnings FATAL => 'all';
no warnings 'recursion';

our $VERSION = q(1.0021);

use Scalar::Util ();

use overload
    '""' => sub { overload::StrVal( $_[0] ) },
    fallback => 1;

use constant DEBUG => 0;

use DBM::Deep::Engine;

sub TYPE_HASH   () { DBM::Deep::Engine->SIG_HASH  }
sub TYPE_ARRAY  () { DBM::Deep::Engine->SIG_ARRAY }

# This is used in all the children of this class in their TIE<type> methods.
sub _get_args {
    my $proto = shift;

    my $args;
    if (scalar(@_) > 1) {
        if ( @_ % 2 ) {
            $proto->_throw_error( "Odd number of parameters to " . (caller(1))[2] );
        }
        $args = {@_};
    }
    elsif ( ref $_[0] ) {
        unless ( eval { local $SIG{'__DIE__'}; %{$_[0]} || 1 } ) {
            $proto->_throw_error( "Not a hashref in args to " . (caller(1))[2] );
        }
        $args = $_[0];
    }
    else {
        $args = { file => shift };
    }

    return $args;
}

# Class constructor method for Perl OO interface.
# Calls tie() and returns blessed reference to tied hash or array,
# providing a hybrid OO/tie interface.
sub new {
    my $class = shift;
    my $args = $class->_get_args( @_ );
    my $self;

    if (defined($args->{type}) && $args->{type} eq TYPE_ARRAY) {
        $class = 'DBM::Deep::Array';
        require DBM::Deep::Array;
        tie @$self, $class, %$args;
    }
    else {
        $class = 'DBM::Deep::Hash';
        require DBM::Deep::Hash;
        tie %$self, $class, %$args;
    }

    return bless $self, $class;
}

# This initializer is called from the various TIE* methods. new() calls tie(),
# which allows for a single point of entry.
sub _init {
    my $class = shift;
    my ($args) = @_;

    # locking implicitly enables autoflush
    if ($args->{locking}) { $args->{autoflush} = 1; }

    # These are the defaults to be optionally overridden below
    my $self = bless {
        type        => TYPE_HASH,
        base_offset => undef,
        staleness   => undef,
        engine      => undef,
    }, $class;

    unless ( exists $args->{engine} ) {
        my $class =
            exists $args->{dbi}   ? 'DBM::Deep::Engine::DBI'  :
            exists $args->{_test} ? 'DBM::Deep::Engine::Test' :
                                    'DBM::Deep::Engine::File' ;

        eval "use $class"; die $@ if $@;
        $args->{engine} = $class->new({
            %{$args},
            obj => $self,
        });
    }

    # Grab the parameters we want to use
    foreach my $param ( keys %$self ) {
        next unless exists $args->{$param};
        $self->{$param} = $args->{$param};
    }

    eval {
        local $SIG{'__DIE__'};

        $self->lock_exclusive;
        $self->_engine->setup( $self );
        $self->unlock;
    }; if ( $@ ) {
        my $e = $@;
        eval { local $SIG{'__DIE__'}; $self->unlock; };
        die $e;
    }

    return $self;
}

sub TIEHASH {
    shift;
    require DBM::Deep::Hash;
    return DBM::Deep::Hash->TIEHASH( @_ );
}

sub TIEARRAY {
    shift;
    require DBM::Deep::Array;
    return DBM::Deep::Array->TIEARRAY( @_ );
}

sub lock_exclusive {
    my $self = shift->_get_self;
    return $self->_engine->lock_exclusive( $self, @_ );
}
*lock = \&lock_exclusive;

sub lock_shared {
    my $self = shift->_get_self;
    # cluck() the problem with cached File objects.
    unless ( $self->_engine ) {
        require Carp;
        require Data::Dumper;
        Carp::cluck( Data::Dumper->Dump( [$self], ['self'] ) );
    }
    return $self->_engine->lock_shared( $self, @_ );
}

sub unlock {
    my $self = shift->_get_self;
    return $self->_engine->unlock( $self, @_ );
}

sub _copy_value {
    my $self = shift->_get_self;
    my ($spot, $value) = @_;

    if ( !ref $value ) {
        ${$spot} = $value;
    }
    else {
        my $r = Scalar::Util::reftype( $value );
        my $tied;
        if ( $r eq 'ARRAY' ) {
            $tied = tied(@$value);
        }
        elsif ( $r eq 'HASH' ) {
            $tied = tied(%$value);
        }
        else {
            __PACKAGE__->_throw_error( "Unknown type for '$value'" );
        }

        if ( eval { local $SIG{'__DIE__'}; $tied->isa( __PACKAGE__ ) } ) {
            ${$spot} = $tied->_repr;
            $tied->_copy_node( ${$spot} );
        }
        else {
            if ( $r eq 'ARRAY' ) {
                ${$spot} = [ @{$value} ];
            }
            else {
                ${$spot} = { %{$value} };
            }
        }

        my $c = Scalar::Util::blessed( $value );
        if ( defined $c && !$c->isa( __PACKAGE__ ) ) {
            ${$spot} = bless ${$spot}, $c
        }
    }

    return 1;
}

sub export {
    my $self = shift->_get_self;

    my $temp = $self->_repr;

    $self->lock_exclusive;
    $self->_copy_node( $temp );
    $self->unlock;

    my $classname = $self->_engine->get_classname( $self );
    if ( defined $classname ) {
      bless $temp, $classname;
    }

    return $temp;
}

sub _check_legality {
    my $self = shift;
    my ($val) = @_;

    my $r = Scalar::Util::reftype( $val );

    return $r if !defined $r || '' eq $r;
    return $r if 'HASH' eq $r;
    return $r if 'ARRAY' eq $r;

    __PACKAGE__->_throw_error(
        "Storage of references of type '$r' is not supported."
    );
}

sub import {
    return if !ref $_[0]; # Perl calls import() on use -- ignore

    my $self = shift->_get_self;
    my ($struct) = @_;

    my $type = $self->_check_legality( $struct );
    if ( !$type ) {
        __PACKAGE__->_throw_error( "Cannot import a scalar" );
    }

    if ( substr( $type, 0, 1 ) ne $self->_type ) {
        __PACKAGE__->_throw_error(
            "Cannot import " . ('HASH' eq $type ? 'a hash' : 'an array')
            . " into " . ('HASH' eq $type ? 'an array' : 'a hash')
        );
    }

    my %seen;
    my $recurse;
    $recurse = sub {
        my ($db, $val) = @_;

        my $obj = 'HASH' eq Scalar::Util::reftype( $db ) ? tied(%$db) : tied(@$db);
        $obj ||= $db;

        my $r = $self->_check_legality( $val );
        if ( 'HASH' eq $r ) {
            while ( my ($k, $v) = each %$val ) {
                my $r = $self->_check_legality( $v );
                if ( $r ) {
                    my $temp = 'HASH' eq $r ? {} : [];
                    if ( my $c = Scalar::Util::blessed( $v ) ) {
                        bless $temp, $c;
                    }
                    $obj->put( $k, $temp );
                    $recurse->( $temp, $v );
                }
                else {
                    $obj->put( $k, $v );
                }
            }
        }
        elsif ( 'ARRAY' eq $r ) {
            foreach my $k ( 0 .. $#$val ) {
                my $v = $val->[$k];
                my $r = $self->_check_legality( $v );
                if ( $r ) {
                    my $temp = 'HASH' eq $r ? {} : [];
                    if ( my $c = Scalar::Util::blessed( $v ) ) {
                        bless $temp, $c;
                    }
                    $obj->put( $k, $temp );
                    $recurse->( $temp, $v );
                }
                else {
                    $obj->put( $k, $v );
                }
            }
        }
    };
    $recurse->( $self, $struct );

    return 1;
}

#XXX Need to keep track of who has a fh to this file in order to
#XXX close them all prior to optimize on Win32/cygwin
# Rebuild entire database into new file, then move
# it back on top of original.
sub optimize {
    my $self = shift->_get_self;

    # Optimizing is only something we need to do when we're working with our
    # own file format. Otherwise, let the other guy do the optimizations.
    return unless $self->_engine->isa( 'DBM::Deep::Engine::File' );

#XXX Need to create a new test for this
#    if ($self->_engine->storage->{links} > 1) {
#        $self->_throw_error("Cannot optimize: reference count is greater than 1");
#    }

    #XXX Do we have to lock the tempfile?

    #XXX Should we use tempfile() here instead of a hard-coded name?
    my $temp_filename = $self->_engine->storage->{file} . '.tmp';
    my $db_temp = __PACKAGE__->new(
        file => $temp_filename,
        type => $self->_type,

        # Bring over all the parameters that we need to bring over
        ( map { $_ => $self->_engine->$_ } qw(
            byte_size max_buckets data_sector_size num_txns
        )),
    );

    $self->lock_exclusive;
    $self->_engine->clear_cache;
    $self->_copy_node( $db_temp );
    $self->unlock;
    $db_temp->_engine->storage->close;
    undef $db_temp;

    ##
    # Attempt to copy user, group and permissions over to new file
    ##
    $self->_engine->storage->copy_stats( $temp_filename );

    # q.v. perlport for more information on this variable
    if ( $^O eq 'MSWin32' || $^O eq 'cygwin' ) {
        ##
        # Potential race condition when optmizing on Win32 with locking.
        # The Windows filesystem requires that the filehandle be closed
        # before it is overwritten with rename().  This could be redone
        # with a soft copy.
        ##
        $self->unlock;
        $self->_engine->storage->close;
    }

    if (!rename $temp_filename, $self->_engine->storage->{file}) {
        unlink $temp_filename;
        $self->unlock;
        $self->_throw_error("Optimize failed: Cannot copy temp file over original: $!");
    }

    $self->unlock;
    $self->_engine->storage->close;

    $self->_engine->storage->open;
    $self->lock_exclusive;
    $self->_engine->setup( $self );
    $self->unlock;

    return 1;
}

sub clone {
    my $self = shift->_get_self;

    return __PACKAGE__->new(
        type        => $self->_type,
        base_offset => $self->_base_offset,
        staleness   => $self->_staleness,
        engine      => $self->_engine,
    );
}

sub supports {
    my $self = shift->_get_self;
    return $self->_engine->supports( @_ );
}

#XXX Migrate this to the engine, where it really belongs and go through some
# API - stop poking in the innards of someone else..
{
    my %is_legal_filter = map {
        $_ => ~~1,
    } qw(
        store_key store_value
        fetch_key fetch_value
    );

    sub set_filter {
        my $self = shift->_get_self;
        my $type = lc shift;
        my $func = shift;

        if ( $is_legal_filter{$type} ) {
            $self->_engine->storage->{"filter_$type"} = $func;
            return 1;
        }

        return;
    }

    sub filter_store_key   { $_[0]->set_filter( store_key   => $_[1] ); }
    sub filter_store_value { $_[0]->set_filter( store_value => $_[1] ); }
    sub filter_fetch_key   { $_[0]->set_filter( fetch_key   => $_[1] ); }
    sub filter_fetch_value { $_[0]->set_filter( fetch_value => $_[1] ); }
}

sub begin_work {
    my $self = shift->_get_self;
    $self->lock_exclusive;
    my $rv = eval {
        local $SIG{'__DIE__'};
        $self->_engine->begin_work( $self, @_ );
    };
    my $e = $@;
    $self->unlock;
    die $e if $e;
    return $rv;
}

sub rollback {
    my $self = shift->_get_self;

    $self->lock_exclusive;
    my $rv = eval {
        local $SIG{'__DIE__'};
        $self->_engine->rollback( $self, @_ );
    };
    my $e = $@;
    $self->unlock;
    die $e if $e;
    return $rv;
}

sub commit {
    my $self = shift->_get_self;
    $self->lock_exclusive;
    my $rv = eval {
        local $SIG{'__DIE__'};
        $self->_engine->commit( $self, @_ );
    };
    my $e = $@;
    $self->unlock;
    die $e if $e;
    return $rv;
}

# Accessor methods
sub _engine {
    my $self = $_[0]->_get_self;
    return $self->{engine};
}

sub _type {
    my $self = $_[0]->_get_self;
    return $self->{type};
}

sub _base_offset {
    my $self = $_[0]->_get_self;
    return $self->{base_offset};
}

sub _staleness {
    my $self = $_[0]->_get_self;
    return $self->{staleness};
}

# Utility methods
sub _throw_error {
    my $n = 0;
    while( 1 ) {
        my @caller = caller( ++$n );
        next if $caller[0] =~ m/^DBM::Deep/;

        die "DBM::Deep: $_[1] at $0 line $caller[2]\n";
    }
}

# Store single hash key/value or array element in database.
sub STORE {
    my $self = shift->_get_self;
    my ($key, $value) = @_;
    warn "STORE($self, '$key', '@{[defined$value?$value:'undef']}')\n" if DEBUG;

    unless ( $self->_engine->storage->is_writable ) {
        $self->_throw_error( 'Cannot write to a readonly filehandle' );
    }

    $self->lock_exclusive;

    # User may be storing a complex value, in which case we do not want it run
    # through the filtering system.
    if ( !ref($value) && $self->_engine->storage->{filter_store_value} ) {
        $value = $self->_engine->storage->{filter_store_value}->( $value );
    }

    eval {
        local $SIG{'__DIE__'};
        $self->_engine->write_value( $self, $key, $value );
    }; if ( my $e = $@ ) {
        $self->unlock;
        die $e;
    }

    $self->unlock;

    return 1;
}

# Fetch single value or element given plain key or array index
sub FETCH {
    my $self = shift->_get_self;
    my ($key) = @_;
    warn "FETCH($self, '$key')\n" if DEBUG;

    $self->lock_shared;

    my $result = $self->_engine->read_value( $self, $key );

    $self->unlock;

    # Filters only apply to scalar values, so the ref check is making
    # sure the fetched bucket is a scalar, not a child hash or array.
    return ($result && !ref($result) && $self->_engine->storage->{filter_fetch_value})
        ? $self->_engine->storage->{filter_fetch_value}->($result)
        : $result;
}

# Delete single key/value pair or element given plain key or array index
sub DELETE {
    my $self = shift->_get_self;
    my ($key) = @_;
    warn "DELETE($self, '$key')\n" if DEBUG;

    unless ( $self->_engine->storage->is_writable ) {
        $self->_throw_error( 'Cannot write to a readonly filehandle' );
    }

    $self->lock_exclusive;

    ##
    # Delete bucket
    ##
    my $value = $self->_engine->delete_key( $self, $key);

    if (defined $value && !ref($value) && $self->_engine->storage->{filter_fetch_value}) {
        $value = $self->_engine->storage->{filter_fetch_value}->($value);
    }

    $self->unlock;

    return $value;
}

# Check if a single key or element exists given plain key or array index
sub EXISTS {
    my $self = shift->_get_self;
    my ($key) = @_;
    warn "EXISTS($self, '$key')\n" if DEBUG;

    $self->lock_shared;

    my $result = $self->_engine->key_exists( $self, $key );

    $self->unlock;

    return $result;
}

# Clear all keys from hash, or all elements from array.
sub CLEAR {
    my $self = shift->_get_self;
    warn "CLEAR($self)\n" if DEBUG;

    my $engine = $self->_engine;
    unless ( $engine->storage->is_writable ) {
        $self->_throw_error( 'Cannot write to a readonly filehandle' );
    }

    $self->lock_exclusive;
    eval {
        local $SIG{'__DIE__'};
        $engine->clear( $self );
    };
    my $e = $@;
    warn "$e\n" if $e && DEBUG;

    $self->unlock;

    die $e if $e;

    return 1;
}

# Public method aliases
sub put    { (shift)->STORE( @_ )  }
sub get    { (shift)->FETCH( @_ )  }
sub store  { (shift)->STORE( @_ )  }
sub fetch  { (shift)->FETCH( @_ )  }
sub delete { (shift)->DELETE( @_ ) }
sub exists { (shift)->EXISTS( @_ ) }
sub clear  { (shift)->CLEAR( @_ )  }

sub _dump_file {shift->_get_self->_engine->_dump_file;}

1;
__END__
