package FusionInventory::Agent::Task::OcsDeploy::P2P;

use POE qw(Component::Client::HTTP);

use HTTP::Request::Common qw(GET);
use Net::IP;
use strict;
use warnings;

sub fisher_yates_shuffle {
    my $deck = shift;  # $deck is a reference to an array
    return unless @$deck; # must not be empty!

    my $i = @$deck;
    while (--$i) {
        my $j = int rand ($i+1);
        @$deck[$i,$j] = @$deck[$j,$i];
    }
}

sub findMirrorWithPOE {
    my ( $self, $orderId, $fragId ) = @_;

    my $config = $self->{config};
    my $logger = $self->{logger};
    my $network = $self->{network};

    $logger->debug("looking for a peer in the network");

    my @addresses;

    #if ($config->{'rpc-ip'}) {
    #    $addresses{$config->{'rpc-ip'}}=1;
    if ( $^O =~ /^linux/x ) {
        foreach (`/sbin/ifconfig`) {
            if
            (/inet\saddr:(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3}).*Mask:(255)\.(255).(\d+)\.(\d+)$/x) {
                push @addresses, { 
                    ip => [ $1, $2, $3, $4 ],
                    mask => [ $5, $6, $7, $8 ]
                };
            }

        }
    } elsif ( $^O =~ /^MSWin/x ) {
        foreach (`route print`) {
            if (/^\s+(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})\s+(255)\.(255)\.(\d+)\.(\d+)/x) {
                push @addresses, { 
                    ip => [ $1, $2, $3, $4 ],
                    mask => [ $5, $6, $7, $8 ]
                };
            }
        }
    }

    my @ipToTestList;
    foreach my $addr (@addresses) {
        next if $addr->{ip}[0] == 127; # Ignore 127.x.x.x addresses
        next if $addr->{ip}[0] == 169; # Ignore 169.x.x.x range too

        my @begin;
        my @end;

        foreach my $idx (0..3) {
            push @begin, $addr->{ip}[$idx] & (255 & $addr->{mask}[$idx]);
            push @end, $addr->{ip}[$idx] | (255 - $addr->{mask}[$idx]);
        }

        my $ipStart = sprintf("%d.%d.%d.%d", @begin);
        my $ipEnd = sprintf("%d.%d.%d.%d", @end);

        my $ipInterval = new Net::IP ($ipStart.' - '.$ipEnd) || die  (Net::IP::Error());

        next if $ipStart eq $ipEnd;
        
        $logger->debug("Scanning from $ipStart to $ipEnd");

        if ($ipInterval->size() > 1200) {
            $logger->debug("Range to large: ".$ipInterval->size()." (max 1200)");
            next;
        }

        do {
            my $ipToTest = $ipInterval->ip();
            #        next if $ip eq $ipToTest; # Ignore myself :)
            push @ipToTestList, $ipToTest;
        } while (++$ipInterval);

    }

    POE::Component::Client::HTTP->spawn(
        Alias   => 'ua',
        #MaxSize => 4096,    # Remove for unlimited page sizes.
        Timeout => 10,
        Streaming => 10,
    );

    my $found;
    my $running = 0;

    my $port = $config->{'rpc-port'} || 62354;

    fisher_yates_shuffle(\@ipToTestList);

    my $ipFound;
             POE::Session->create(
            inline_states => {
                _start => sub {
                    $_[KERNEL]->yield( "add", 0 ) if @ipToTestList;
            },
            add => sub {
                if ($running == 0) {
                    foreach (0..4) {
                        my $ipToTest = shift @ipToTestList;
                        # number of running connexion, See Windows 4226 mesage
                        $_[KERNEL]->post(ua => request => got_response => GET "http://$ipToTest:$port/deploy/$orderId/$orderId-$fragId" );
                        $running++;
                    }
                }
                $_[KERNEL]->delay( add => 1.1 ) if !$ipFound && @ipToTestList;
            },

                # A response has arrived.  Display it.
                got_response => sub {
                    my ($self, $kernel, $session, $heap, $request_packet, $response_packet, $wheel_id) = @_[OBJECT, KERNEL, SESSION, HEAP, ARG0, ARG1, ARG3];

                    # The original HTTP::Request object.  If several requests
                    # were made, this can help match the response back to its
                    # request.
                    my $http_request = $request_packet->[0];

                    # The HTTP::Response object.
                    my ($http_response, $data) = @$response_packet;

                    if ($http_response->is_success()) {
                        $ipFound = $http_response->base->host;
                    }

                    if ($ipFound)  {
                        $kernel->post(ua => 'shutdown');
                    }

                    if (@ipToTestList % 50 == 0) {
                        $logger->debug(
                            "still ".
                            int(@ipToTestList).
                            " IP to test");
                    }
                    $running--;
                },
            },
        );

# Run everything, and exit when it's all done.
    $poe_kernel->run();

    if ($ipFound) {
        $logger->debug("Peer found at ".$ipFound);
        return $ipFound;
    } else {
        $logger->debug("No peer found");
        return;
    }
}

1;
