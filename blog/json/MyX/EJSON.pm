package MyX::EJSON;

use 5.010;
use strict;
use warnings;

use MarpaX::ESLIF;

sub new {

    # my $eslif = MarpaX::ESLIF->new($log);
    my $eslif = MarpaX::ESLIF->new();

    # isa_ok($eslif, 'MarpaX::ESLIF');

    # $log->info('Creating JSON native grammar');
    my $eslifJson = MarpaX::ESLIF::JSON->new( $eslif, 0 );
    return $eslifJson;
}

sub doparse {
    my ($self, $inputs, $recursionLevel) = @_;
    my $rc;

    # $log->infof('Input: %s', $inputs);
    my $value = $self->decode($inputs);
    if (! defined($value)) {
        die("Failure with decode:\n$inputs\n");
    }
    # $log->infof('Decoded: %s', $value);
    #
    # Re-encode
    #
    # my $string = $eslifJson->encode($value);
    # $log->infof('Re-encoded: %s', $string);

    $rc = 1;
    goto done;

  err:
    $rc = 0;

  done:
    return $rc;
}
1;
