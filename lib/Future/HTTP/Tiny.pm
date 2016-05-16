package Future::HTTP::Tiny;
use strict;
use Future;
use HTTP::Tiny;
use Moo 2; # or Moo::Lax if you can't have Moo v2
use Filter::signatures;
no warnings 'experimental';
use feature 'signatures';

use vars qw($VERSION);
$VERSION = '0.01';

has ua => (
    is => 'lazy',
    default => sub { HTTP::Tiny->new( %{ $_[0]->{ua_args}} ) }
);

has _ua_args => (
    is => 'ro',
    default => sub { +{} } ,
);

=head1 NAME

Future::HTTP::Tiny - synchronous HTTP client with a Future interface

=cut

sub BUILDARGS {
    my( $class, %options ) = @_;
    
    return {
        _ua_args => \%options,
    }
}

sub _request($self, $method, $url, %options) {
    
    # Munge the parameters for AnyEvent::HTTP to HTTP::Tiny
    for my $rename (
        ['body'    => 'content'],
        ['body_cb' => 'data_callback']
    ) {
        my( $from, $to ) = @$rename;
        if( $options{ $from }) {
            $options{ $to } = delete $options{ $from };
        };
    };
    
    # Execute the request (synchronously)
    my $result = $self->ua->request(
        $method => $url,
        \%options
    );
    
    # Convert the result back to a future
    my( $body ) = delete $result->{content};
    my( $headers ) = delete $result->{headers};
    $headers->{Status} = delete $result->{status};
    if( $headers->{Status} =~ /^2../ ) {
        return Future->done($body, $headers);
    } else {
        return Future->fail($body, $headers);
    }
}

sub http_request($self,$method,$url,%options) {
    $self->_request(
        $method => $url,
        %options
    )
}

sub http_get($self,$url,%options) {
    $self->_request(
        'GET' => $url,
        %options,
    )
}

sub http_head($self,$url,%options) {
    $self->_request(
        'HEAD' => $url,
        %options
    )
}

sub http_post($self,$url,$body,%options) {
    $self->_request(
        'POST' => $url,
        body   => $body,
        %options
    )
}

1;