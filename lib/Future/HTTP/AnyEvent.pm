package Future::HTTP::AnyEvent;
use strict;
use Future;
use AnyEvent::HTTP ();
use AnyEvent::Future 'as_future_cb';
use Moo 2; # or Moo::Lax if you can't have Moo v2
use Filter::signatures;
no warnings 'experimental';
use feature 'signatures';

use vars qw($VERSION);
$VERSION = '0.01';

=head1 NAME

Future::HTTP::AnyEvent - asynchronous HTTP client with a Future interface

=cut

sub BUILDARGS( $class, %options ) {
    return {}
}

sub future_from_result {
    my( $self, $body, $headers ) = @_;
    
    if( $headers->{Status} =~ /^2../ ) {
        return Future->done($body, $headers);
    } else {
        return Future->fail($body, $headers);
    }
}

sub http_request($self,$method,$url,%options) {
    as_future_cb( sub($done_cb, $fail_cb) {
        AnyEvent::HTTP::http_request($method => $url, %options, $done_cb)
    })->then(sub ($body, $headers) {
        return $self->future_from_result($body, $headers);
    });
}

sub http_get($self,$url,%options) {
    as_future_cb( sub($done_cb, $fail_cb) {
        AnyEvent::HTTP::http_get($url, %options, $done_cb)
    })->then(sub ($body, $headers) {
        return $self->future_from_result($body, $headers);
    });
}

sub http_head($self,$url,%options) {
    as_future_cb( sub($done_cb, $fail_cb) {
        AnyEvent::HTTP::http_head($url, %options, $done_cb)
    })->then(sub ($body, $headers) {
        return $self->future_from_result($body, $headers);
    });
}

sub http_post($self,$url,%options) {
    as_future_cb( sub($done_cb,$fail_cb) {
        my $body = delete $options{ body };
        AnyEvent::HTTP::http_post($url, $body, %options, $done_cb)
    })->then(sub ($body, $headers) {
        return $self->future_from_result($body, $headers);
    });
}

1;