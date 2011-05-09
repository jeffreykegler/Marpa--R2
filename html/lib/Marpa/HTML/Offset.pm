package Marpa::HTML::Offset;

use 5.010;
use strict;
use warnings;
use integer;

use Carp;

sub import {
    my ( $class, @fields ) = @_;
    my $pkg        = caller;
    my $prefix     = $pkg . q{::};
    my $offset     = -1;
    my $in_comment = 0;

    ## no critic (TestingAndDebugging::ProhibitNoStrict)
    no strict 'refs';
    ## use critic
    FIELD: for my $field (@fields) {

        if ($in_comment) {
            $in_comment = $field ne ':}' && $field ne '}';
            next FIELD;
        }

        PROCESS_OPTION: {
            last PROCESS_OPTION if $field !~ /\A [{:] /xms;
            if ( $field =~ / \A [:] package [=] (.*) /xms ) {
                $prefix = $1 . q{::};
                next FIELD;
            }
            if ( $field =~ / \A [:]? [{] /xms ) {
                $in_comment++;
                next FIELD;
            }
        } ## end PROCESS_OPTION:

        if ( $field !~ s/\A=//xms ) {
            $offset++;
        }

        if ( $field =~ / \A ( [^=]* ) = ( [0-9+-]* ) \z/xms ) {
            $field  = $1;
            $offset = $2 + 0;
        }

        Carp::croak("Unacceptable field name: $field")
            if $field =~ /[^A-Z0-9_]/xms;
        my $field_name = $prefix . $field;
        *{$field_name} = sub () {$offset};
    } ## end for my $field (@fields)
    return 1;
} ## end sub import

1;
