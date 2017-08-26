package Future::HTTP::Handler;
use Moo::Role;
use Filter::signatures;
no warnings 'experimental::signatures';
use feature 'signatures';

has 'on_http_response' => (
    is => 'rw',
);

sub http_response_received( $self, $res, $body, $headers ) {
    $self->on_http_response( $res, $body, $headers )
        if $self->on_http_response;
    if( $headers->{Status} =~ /^[23]../ ) {
        $res->done($body, $headers);
    } else {
        $res->fail('error when connecting', $headers);
    }
}

1;