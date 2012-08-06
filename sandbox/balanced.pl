use 5.010;
use strict;
use warnings;

use Benchmark qw(timeit countit timestr);
use List::Util qw(min);
use Regexp::Common qw /balanced/;
use Getopt::Long;
my $example;
my $length = 1000;
my $string;
my $pp              = 0;
my $do_regex        = 1;
my $iteration_count = -4;
my $getopt_result   = GetOptions(
    "length=i"  => \$length,
    "count=i"   => \$iteration_count,
    "example=s" => \$example,
    "string=s"  => \$string,
    "pp"        => \$pp,
    "regex!"    => \$do_regex,
);

if ($pp) {
    die 'PP not currently implemented';
    require Marpa::PP;
    'Marpa::PP'->VERSION(0.010000);
    say "Marpa::PP ", $Marpa::PP::VERSION;
    no strict 'refs';
    *{'main::Marpa::grammar_new'} = \&Marpa::PP::Grammar::new;
    *{'main::Marpa::recce_new'}   = \&Marpa::PP::Recognizer::new;
} ## end if ($pp)
else {
    require Marpa::R2;
    'Marpa::R2'->VERSION(0.020000);
    say "Marpa::R2 ", $Marpa::R2::VERSION;
}

my $tchrist_regex = '(\\((?:[^()]++|(?-1))*+\\))';

if ( defined $string ) {
    die "Bad string: $string" if not $string =~ /\A [()]+ \z/xms;
    say "Testing $string";
    do_marpa_r2($string);
    do_regex_old($string);
    do_regex($string);
    exit 0;
} ## end if ( defined $string )

$length += 0;
if ( $length <= 0 ) {
    die "Bad length $length";
}

$example //= "final";
my $s;
CREATE_S: {
    my $s_balanced = '(()())((';
    if ( $example eq 'pos2_simple' ) {
        $s = '(' . '()' . ( '(' x ( $length - length $s_balanced ) );
        last CREATE_S;
    }
    if ( $example eq 'pos2' ) {
        $s = '(' . $s_balanced . ( '(' x ( $length - length $s_balanced ) );
        last CREATE_S;
    }
    if ( $example eq 'final' ) {
        $s = ( '(' x ( $length - length $s_balanced ) ) . $s_balanced;
        last CREATE_S;
    }
    die qq{Example "$example" not known};
} ## end CREATE_S:

sub concat {
    my ( undef, @args ) = @_;
    return join q{}, grep {defined} @args;
}

sub arg0 {
    my ( undef, $arg0 ) = @_;
    return $arg0;
}

sub arg1 {
    my ( undef, undef, $arg1 ) = @_;
    return $arg1;
}

my $marpa_answer_shown;
my $thin_answer_shown;
my $regex_old_answer_shown;
my $regex_answer_shown;

my $grammar_args = {
    start => 'S',
    rules => [
        [ S => [qw(prefix first_balanced endmark )], 'main::arg1' ],
        {   lhs    => 'S',
            rhs    => [qw(prefix first_balanced )],
            action => 'main::arg1'
        },
        { lhs => 'prefix',      rhs => [qw(prefix_char)], min => 0 },
        { lhs => 'prefix_char', rhs => [qw(xlparen)] },
        { lhs => 'prefix_char', rhs => [qw(rparen)] },
        { lhs => 'lparen',      rhs => [qw(xlparen)] },
        { lhs => 'lparen',      rhs => [qw(ilparen)] },
        {   lhs    => 'first_balanced',
            rhs    => [qw(xlparen balanced_sequence rparen)],
            action => 'main::arg0'
        },
        {   lhs => 'balanced',
            rhs => [qw(lparen balanced_sequence rparen)],
        },
        {   lhs => 'balanced_sequence',
            rhs => [qw(balanced)],
            min => 0,
        },
    ],
};

sub thick_grammar_generate {
    my $grammar = Marpa::R2::Grammar->new($grammar_args);
    $grammar->set( { terminals => [qw(xlparen ilparen rparen endmark )] } );

    $grammar->precompute();
    return $grammar;
} ## end sub thick_grammar_generate

sub do_marpa_r2 {
    my ($s) = @_;

    my $grammar_args = {
        start => 'S',
        rules => [
            [ S => [qw(prefix first_balanced endmark )] ],
            {   lhs => 'S',
                rhs => [qw(prefix first_balanced )]
            },
            { lhs => 'prefix',      rhs => [qw(prefix_char)], min => 0 },
            { lhs => 'prefix_char', rhs => [qw(xlparen)] },
            { lhs => 'prefix_char', rhs => [qw(rparen)] },
            { lhs => 'lparen',      rhs => [qw(xlparen)] },
            { lhs => 'lparen',      rhs => [qw(ilparen)] },
            {   lhs => 'first_balanced',
                rhs => [qw(xlparen balanced_sequence rparen)],
            },
            {   lhs => 'balanced',
                rhs => [qw(lparen balanced_sequence rparen)],
            },
            {   lhs => 'balanced_sequence',
                rhs => [qw(balanced)],
                min => 0,
            },
        ],
    };

    my $grammar = Marpa::R2::Grammar->new($grammar_args);

    $grammar->precompute();

    my ($first_balanced_rule) =
        grep { ( $grammar->rule($_) )[0] eq 'first_balanced' }
        $grammar->rule_ids();

    my $recce = Marpa::R2::Recognizer->new( { grammar => $grammar } );
    $recce->expected_symbol_event_set( 'endmark', 1 );

    my $location      = 0;
    my $string_length = length $s;
    my $end_of_match;

    # find the match which ends first -- the one which starts
    # first must start at or before it does
    CHAR: while ( $location < $string_length ) {
        my $value = substr $s, $location, 1;
        my $event_count;
        if ( $value eq '(' ) {

            # say "Adding xlparen at $location";
            $event_count = $recce->read('xlparen');
        }
        else {
            # say "Adding rparen at $location";
            $event_count = $recce->read('rparen');
        }
        if ( $event_count
            and grep { $_->[0] eq 'SYMBOL_EXPECTED' } @{ $recce->events() } )
        {
            $end_of_match = $location + 1;
            last CHAR;
        } ## end if ( $event_count and grep { $_->[0] eq 'SYMBOL_EXPECTED'...})
        $location++;
    } ## end CHAR: while ( $location < $string_length )

    if ( not defined $end_of_match ) {
        say "No balanced parens";
        return 0;
    }

    CHAR: while ( ++$location < $string_length ) {
        my $value = substr $s, $location, 1;
        my $token = $value eq '(' ? 'ilparen' : 'rparen';

        # say "Adding $token at $location";
        my $event_count = $recce->read($token);
        last CHAR if not defined $event_count;
        if ( $event_count
            and grep { $_->[0] eq 'SYMBOL_EXPECTED' } @{ $recce->events() } )
        {
            $end_of_match = $location + 1;
        }
    } ## end CHAR: while ( ++$location < $string_length )

    my $report = $recce->progress($end_of_match);

    # say Dumper($report);
    my $start_of_match = List::Util::min map { $_->[2] }
        grep { $_->[1] < 0 && $_->[0] == $first_balanced_rule } @{$report};
    my $value = substr $s, $start_of_match, $end_of_match - $start_of_match;
    return 0 if $marpa_answer_shown;
    $marpa_answer_shown = $value;
    say qq{Marpa::R2: "$value" at $start_of_match-$end_of_match};
    return 0;

} ## end sub do_marpa_r2

sub do_regex_old {
    my ($s) = @_;
    my $answer =
          $s =~ /$RE{balanced}{-parens=>'()'}{-keep}/
        ? $1
        : 'no balanced parentheses';
    return 0 if $regex_old_answer_shown;
    $regex_old_answer_shown = $answer;
    say qq{regex_old answer: "$answer"};
    return 0;
} ## end sub do_regex_old

sub do_regex {
    my ($s) = @_;
    my $answer =
          $s =~ $tchrist_regex
        ? $1
        : 'no balanced parentheses';
    return 0 if $regex_answer_shown;
    $regex_answer_shown = $answer;
    say qq{regex: "$answer"};
    return 0;
} ## end sub do_regex

sub do_thin {
    my ($s) = @_;

    my $thin_grammar        = Marpa::R2::Thin::G->new( { if => 1 } );
    my $s_xlparen           = $thin_grammar->symbol_new();
    my $s_ilparen           = $thin_grammar->symbol_new();
    my $s_rparen            = $thin_grammar->symbol_new();
    my $s_lparen            = $thin_grammar->symbol_new();
    my $s_endmark           = $thin_grammar->symbol_new();
    my $s_start             = $thin_grammar->symbol_new();
    my $s_prefix            = $thin_grammar->symbol_new();
    my $s_first_balanced    = $thin_grammar->symbol_new();
    my $s_prefix_char       = $thin_grammar->symbol_new();
    my $s_balanced_sequence = $thin_grammar->symbol_new();
    my $s_balanced          = $thin_grammar->symbol_new();
    $thin_grammar->start_symbol_set($s_start);
    $thin_grammar->rule_new( $s_start,
        [ $s_prefix, $s_first_balanced, $s_endmark ] );
    $thin_grammar->rule_new( $s_start, [ $s_prefix, $s_first_balanced ] );
    $thin_grammar->rule_new( $s_prefix_char, [$s_xlparen] );
    $thin_grammar->rule_new( $s_prefix_char, [$s_rparen] );
    $thin_grammar->rule_new( $s_lparen,      [$s_xlparen] );
    $thin_grammar->rule_new( $s_lparen,      [$s_ilparen] );
    my $first_balanced_rule =
        $thin_grammar->rule_new( $s_first_balanced,
        [ $s_xlparen, $s_balanced_sequence, $s_rparen ] );
    $thin_grammar->rule_new( $s_balanced,
        [ $s_lparen, $s_balanced_sequence, $s_rparen ] );
    $thin_grammar->sequence_new( $s_prefix, $s_prefix_char, { min => 0 } );
    $thin_grammar->sequence_new( $s_balanced_sequence, $s_balanced,
        { min => 0 } );

    $thin_grammar->precompute();

    my $thin_recce = Marpa::R2::Thin::R->new($thin_grammar);
    $thin_recce->start_input();
    $thin_recce->expected_symbol_event_set( $s_endmark, 1 );

    my $location      = 0;
    my $string_length = length $s;
    my $end_of_match;

    # find the match which ends first -- the one which starts
    # first must start at or before it does
    CHAR: while ( $location < $string_length ) {
        my $value = substr $s, $location, 1;
        my $event_count;
        if ( $value eq '(' ) {

            # say "Adding xlparen at $location";
            $thin_recce->alternative( $s_xlparen, 0, 1 );
            $event_count = $thin_recce->earleme_complete();
        } ## end if ( $value eq '(' ) )
        else {
            # say "Adding rparen at $location";
            $thin_recce->alternative( $s_rparen, 0, 1 );
            $event_count = $thin_recce->earleme_complete();
        }
        if ($event_count
            and grep { $_ eq 'MARPA_EVENT_SYMBOL_EXPECTED' }
            map { ; ( $thin_grammar->event($_) )[0] }
            ( 0 .. $event_count - 1 )
            )
        {
            $end_of_match = $location + 1;
            last CHAR;
        } ## end if ( $event_count and grep { $_ eq ...})
        $location++;
    } ## end CHAR: while ( $location < $string_length )

    if ( not defined $end_of_match ) {
        say "No balanced parens";
        return 0;
    }

    CHAR: while ( ++$location < $string_length ) {
        my $value = substr $s, $location, 1;
        my $token = $value eq '(' ? $s_ilparen : $s_rparen;

        # say "Adding $token at $location";
        last CHAR if not defined $thin_recce->alternative( $token, 0, 1 );
        my $event_count = $thin_recce->earleme_complete();
        if ($event_count
            and grep { $_ eq 'MARPA_EVENT_SYMBOL_EXPECTED' }
            map { ; ( $thin_grammar->event($_) )[0] }
            ( 0 .. $event_count - 1 )
            )
        {
            $end_of_match = $location + 1;
        } ## end if ( $event_count and grep { $_ eq ...})
    } ## end CHAR: while ( ++$location < $string_length )

    my $start_of_match = $end_of_match;
    $thin_recce->progress_report_start($end_of_match);
    ITEM: while (1) {
        my ( $rule_id, $dot_position, $item_origin ) =
            $thin_recce->progress_item();
        last ITEM if not defined $rule_id;
        next ITEM if $dot_position >= 0;
        next ITEM if $rule_id != $first_balanced_rule;
        $start_of_match = $item_origin if $item_origin < $start_of_match;
    } ## end ITEM: while (1)

    my $value = substr $s, $start_of_match, $end_of_match - $start_of_match;
    return 0 if $thin_answer_shown;
    $thin_answer_shown = $value;
    say qq{Marpa::R2::Thin: "$value" at $start_of_match-$end_of_match};
    return 0;

} ## end sub do_thin

my $tests = {
    marpa_r2      => sub { do_marpa_r2($s) },
    marpa_r2_thin => sub { do_thin($s) },
};
$tests->{regex} = sub { do_regex($s) }
    if $do_regex;
Benchmark::cmpthese( $iteration_count, $tests );

my $answer = '(()())';
say +( $marpa_answer_shown eq $answer
    ? 'R2 Answer matches'
    : 'R2 ANSWER DOES NOT MATCH!' );
say +( $thin_answer_shown eq $answer
    ? 'Thin Answer matches'
    : 'Thin ANSWER DOES NOT MATCH!' );
if ($do_regex) {
    say +( $regex_answer_shown eq $answer
        ? 'Regex Answer matches'
        : 'Regex ANSWER DOES NOT MATCH!' );
}
