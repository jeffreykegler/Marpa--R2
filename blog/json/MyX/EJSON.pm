package MyX::EJSON;

use 5.010;
use strict;
use warnings;

use Carp qw/croak/;
use MarpaX::ESLIF;

sub new {
    my ($class, $log) = @_;

    my $eslif = MarpaX::ESLIF->new($log); # This is a multiton
    my $eslifJson = MarpaX::ESLIF::JSON->new( $eslif, 0 );

    return $eslifJson;
}

sub doparse {
    my ($self, $input) = @_;

    return $self->decode($input) // do { croak 'Parse failure' };
}

1;
