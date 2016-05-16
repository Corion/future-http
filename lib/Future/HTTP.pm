package Future::HTTP;
use strict;
use Filter::signatures;
no warnings 'experimental';
use feature 'signatures';

=head1 NAME

Future::HTTP - provide the most appropriate HTTP client with a Future API

=cut

use vars qw($implementation @loops $VERSION);
$VERSION = '0.01';

@loops = (
    # Mojolicious support would be nice, should use Future::Mojo and Mojolicious::UserAgent I guess
    ['AnyEvent.pm'    => 'Future::HTTP::AnyEvent'],
    ['AE.pm'          => 'Future::HTTP::AnyEvent'],
    # POE support would be nice
    # IO::Async support would be nice
    # LWP::UserAgent support would be nice
    
    # The fallback, will always catch due to loading Future::HTTP
    ['Future/HTTP.pm' => 'Future::HTTP::Tiny'],
);

sub new($factoryclass, @args) {
    $implementation ||= $factoryclass->best_implementation();
    
    # return a new instance
    $implementation->new(@args);
}

sub best_implementation( $class, @candidates ) {
    
    if(! @candidates) {
        @candidates = @loops;
    };

    # Find the currently running/loaded event loop(s)
    my @applicable_implementations = map {
        $_->[1]
    } grep {
        $INC{$_->[0]}
    } @candidates;
    
    # Check which one we can load:
    for my $impl (@applicable_implementations) {
        if( eval "require $impl; 1" ) {
            return $impl;
        };
    };
};

# We support the L<AnyEvent::HTTP> API first

# We should support more APIs like HTTP::Tiny, later
# See L<Future::HTTP::API::HTTPTiny>.

1;