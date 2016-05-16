package Future::HTTP;
use strict;

=head1 NAME

Future::HTTP - provide the most appropriate HTTP client with a Future API

=cut

use vars qw($implementation @loops $VERSION);
$VERSION = '0.01';

@loops = (
    # POE support would be nice
    # IO::Async support would be nice
    # Mojolicious support would be nice
    # LWP::UserAgent support would be nice
    ['AnyEvent.pm'    => 'Future::HTTP::AnyEvent'],
    ['AE.pm'          => 'Future::HTTP::AnyEvent'],
    ['Future/HTTP.pm' => 'Future::HTTP::Tiny'], # The fallback
);

sub new {
    my( $factoryclass, @args ) = @_;
    
    $implementation ||= $factoryclass->best_implementation();
    
    # return a new instance
    $implementation->new(@args);
}

sub best_implementation {
    my( $class, @candidates ) = @_;

    # Find the currently running/loaded event loop(s)
    for my $loop (@loops) {
        if( $INC{$loop->[0]}) {
            push @candidates, $loop->[1];
        };
    };
    
    for my $impl (@candidates) {
        if( eval "require $impl; 1" ) {
            return $impl;
        };
    };
};

# We support the L<AnyEvent::HTTP> API first

# We should support more APIs than just the one of HTTP::Tiny, later

1;