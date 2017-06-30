package Future::HTTP::Tiny::threaded;
# Maybe this should be named Future::threaded
# and be a worker-pool backend instead of this
# specific thing tied to Future::HTTP
use strict;
use Future;
use Future::HTTP::Tiny;
use threads;
use parent 'Future'; # we will return a subclass, maybe?
use Moo 2; # or Moo::Lax if you can't have Moo v2
use Filter::signatures;
no warnings 'experimental::signatures';
use feature 'signatures';

use vars qw($VERSION @pool $max_threads);
$VERSION = '0.06';
$max_threads = 4;

# a worker pool of one background thread
# Whoa! These should be class variables, not per-Future!!
has pool => (
    is => 'lazy',
    default => sub { \@pool }
);

# Where we store the pending requests
has requests => (
    is => 'lazy',
    default => sub { Thread::Queue->new() },
);

# per thread hash of responses. Likely overkill.
has responses => (
    is => 'lazy',
    default => sub { +{} },
);

=head1 NAME

Future::HTTP::Tiny::threaded - asynchronous HTTP client with a Future interface

=head1 DESCRIPTION

This is the default aynchronous backend using L<threads>.
It is chosen if no supported event loop could
be detected but L<threads> is loaded. It will execute the requests
asynchronously using a pool of worker threads.

Care is taken that a future response callback will only be executed with
the thread that issued it, not with the thread that made the network request.

=cut

sub threaded_future( $self, $future,$tid=threads->id ) {
    # Make sure we have a place to put our response:
    $self->responses->{$tid} ||= Threads::Queue->new;
    my $res = Future->new;
    $self->requests->enqueue( [$future,$tid,$res] );
    $res
}

sub maybe_spawn_worker( $self ) {
    if( 0+@{ $self->pool } < $max_threads ) {
        $self->spawn_worker( $self->requests, $self->responses );
    }
}

sub spawn_worker( $self, $requests, $responses ) {
    async {
        while( defined my $task = $requests->dequeue() ) {
            my( $request, $tid,$user ) = @$task;
            $responses->{$tid}->enqueue( [ $user, $request->await ] );
        };
    }
}

=begin later

sub await($self) {
    my( $tid ) = threads->id;
    # Now, block this thread while getting things dispatched
    # until even this future is satisfied
    # This means hoping that the workers put us into the
    # ->responses->{$tid} queue and we find ourselves there:
    my $q = $self->responses->{$tid};
    while( my $next = $q->dequeue ) {
        my( $user, $results ) = @$next; 
        $user->done(@$results);
        last if $user eq $self;
    };
}

=cut

1;