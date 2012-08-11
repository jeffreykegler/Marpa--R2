use 5.010;
use strict;
use warnings;

use Benchmark qw(timeit countit timestr);
use List::Util qw(min);
use Regexp::Common qw /balanced/;
use Getopt::Long;
my $example;
my $length;
my $string;
my $pp              = 0;
my $do_only = 0;
my $do_regex;
my $do_thin;
my $do_thinsl;
my $do_retrace;
my $do_r2;
my $do_flm;
my $do_timing = 1;
my $random = 0;
my $iteration_count = -4;
my $getopt_result   = GetOptions(
    "length=i"  => \$length,
    "count=i"   => \$iteration_count,
    "example=s" => \$example,
    "string=s"  => \$string,
    "random!" => \$random,
    "regex!"    => \$do_regex,
    "thin!"     => \$do_thin,
    "thinsl!"     => \$do_thinsl,
    "retrace!"     => \$do_retrace,
    "only!"     => \$do_only,
    "r2!"       => \$do_r2,
    "flm!"       => \$do_flm,
    "time!"       => \$do_timing,
);
die "getopt failed" if not defined $getopt_result;

{
    require Marpa::R2;
    'Marpa::R2'->VERSION(0.020000);
    say "Marpa::R2 ", $Marpa::R2::VERSION;
}

# Apply defaults
if ( !$do_only ) {
    $do_regex   //= 0;
    $do_thin    //= 1;
    $do_thinsl   //= 1;
    $do_retrace //= 1;
    $do_r2      //= 1;
    $do_flm     //= 0;
} ## end if ( !$do_only )

my $number_of_modes = (defined $string ? 1 : 0) +
(defined $example ? 1 : 0) +
($random ? 1 : 0) ;
if ($number_of_modes > 1) {
    die qq{"example", "random" and "string" options are mutually exclusive\n};
}

my $tchrist_regex = '(\\((?:[^()]++|(?-1))*+\\))';

my $s;

CREATE_STRING: {

    if ( defined $string ) {
        die "Bad string: $string" if not $string =~ /\A [()]+ \z/xms;
        say "Testing $string";
        $s      = $string;
        $length = length $s;
        last CREATE_STRING;
    } ## end if ( defined $string )

    if ($random) {
        $do_timing = 0;
        $length //= 10;
        $s = join "", map { ; rand(2) < 1 ? '(' : ')' } 0 .. $length - 1;
        say "Testing ", substr $s, 0, 100;
        last CREATE_STRING;
    } ## end if ($random)

    $length //= 1000;
    die "Bad length $length" if $length <= 0;

    $example //= "final";
    my $s_balanced = '(()())((';
    if ( $example eq 'pos2_simple' ) {
        $s = '(' . '()' . ( '(' x ( $length - length $s_balanced ) );
        last CREATE_STRING;
    }
    if ( $example eq 'pos2' ) {
        $s = '(' . $s_balanced . ( '(' x ( $length - length $s_balanced ) );
        last CREATE_STRING;
    }
    if ( $example eq 'final' ) {
        $s = ( '(' x ( $length - length $s_balanced ) ) . $s_balanced;
        last CREATE_STRING;
    }
    die qq{Example "$example" not known};

} ## end CREATE_STRING:

sub concat {
    my (undef, @args) = @_;
    return join q{}, grep { defined } @args;
}
sub arg0 {
    my (undef, $arg0) = @_;
    return $arg0;
}

sub arg1 {
    my (undef, undef, $arg1) = @_;
    return $arg1;
}

my $marpa_answer_shown;
my $flm_answer_shown;
my $r2_answer_shown;
my $thin_answer_shown;
my $thinsl_answer_shown;
my $retrace_answer_shown;
my $regex_old_answer_shown;
my $regex_answer_shown;

my $grammar_args =
    {   start => 'S',
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

sub do_r2 {
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

    my $recce         = Marpa::R2::Recognizer->new( { grammar => $grammar } );
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
            $event_count = $recce->read( 'xlparen' );
        }
        else {
            # say "Adding rparen at $location";
            $event_count = $recce->read('rparen');
        }
	if ($event_count and grep { $_->[0] eq 'SYMBOL_EXPECTED' } @{$recce->events()}) {
	    $end_of_match = $location + 1;
	    last CHAR;
	}
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
	if ($event_count and grep { $_->[0] eq 'SYMBOL_EXPECTED' } @{$recce->events()}) {
	    $end_of_match = $location + 1;
	}
    } ## end CHAR: while ( ++$location < $string_length )

    my $report = $recce->progress($end_of_match);

    # say Dumper($report);
    my $start_of_match = List::Util::min map { $_->[2] }
        grep { $_->[1] < 0 && $_->[0] == $first_balanced_rule } @{$report};
    my $value = substr $s, $start_of_match, $end_of_match - $start_of_match;
    return 0 if $r2_answer_shown;
    $r2_answer_shown = $value;
    say qq{r2: "$value" at $start_of_match-$end_of_match};
    return 0;

} ## end sub do_r2e

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
} ## end sub do_regex

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
    $thin_grammar->sequence_new( $s_prefix,            $s_prefix_char, {min => 0} );
    $thin_grammar->sequence_new( $s_balanced_sequence, $s_balanced,    {min => 0} );

    $thin_grammar->precompute();

    my $thin_recce = Marpa::R2::Thin::R->new($thin_grammar);
    $thin_recce->start_input();
    $thin_recce->expected_symbol_event_set( $s_endmark, 1 );
    $thin_recce->ruby_slippers_set( 1 );

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
	    $thin_recce->alternative($s_xlparen, 0, 1);
	    $event_count = $thin_recce->earleme_complete();
        }
        else {
            # say "Adding rparen at $location";
	    $thin_recce->alternative($s_rparen, 0, 1);
	    $event_count = $thin_recce->earleme_complete();
        }
        if ( $event_count
            and grep { $_ eq 'MARPA_EVENT_SYMBOL_EXPECTED' }
            map { ;($thin_grammar->event($_))[0] } ( 0 .. $event_count - 1 ) )
        {
            $end_of_match = $location + 1;
            last CHAR;
        } ## end if ( $event_count and grep { $_->[0] eq ...})
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
        last CHAR if $thin_recce->alternative($token, 0, 1);
        my $event_count = $thin_recce->earleme_complete();
        if ( $event_count
            and grep { $_ eq 'MARPA_EVENT_SYMBOL_EXPECTED' }
            map { ;($thin_grammar->event($_))[0] } ( 0 .. $event_count - 1 ) )
        {
	    $end_of_match = $location + 1;
	}
    } ## end CHAR: while ( ++$location < $string_length )

    my $start_of_match = $end_of_match;
    $thin_recce->progress_report_start($end_of_match);
    ITEM: while (1) {
        my ($rule_id, $dot_position, $item_origin) = $thin_recce->progress_item();
        last ITEM if not defined $rule_id;
	next ITEM if $dot_position >= 0;
        next ITEM if $rule_id != $first_balanced_rule;
	$start_of_match = $item_origin if $item_origin < $start_of_match;
    }

    my $value = substr $s, $start_of_match, $end_of_match - $start_of_match;
    return 0 if $thin_answer_shown;
    $thin_answer_shown = $value;
    say qq{thin: "$value" at $start_of_match-$end_of_match};
    return 0;

} ## end sub do_thin

sub do_thinsl {
    my ($s) = @_;

    my $thinsl_grammar        = Marpa::R2::Thin::G->new( { if => 1 } );
    my $s_xlparen           = $thinsl_grammar->symbol_new();
    my $s_ilparen           = $thinsl_grammar->symbol_new();
    my $s_rparen            = $thinsl_grammar->symbol_new();
    my $s_lparen            = $thinsl_grammar->symbol_new();
    my $s_endmark           = $thinsl_grammar->symbol_new();
    my $s_start             = $thinsl_grammar->symbol_new();
    my $s_prefix            = $thinsl_grammar->symbol_new();
    my $s_first_balanced    = $thinsl_grammar->symbol_new();
    my $s_prefix_char       = $thinsl_grammar->symbol_new();
    my $s_balanced_sequence = $thinsl_grammar->symbol_new();
    my $s_balanced          = $thinsl_grammar->symbol_new();
    $thinsl_grammar->start_symbol_set($s_start);
    $thinsl_grammar->rule_new( $s_start,
        [ $s_prefix, $s_first_balanced, $s_endmark ] );
    $thinsl_grammar->rule_new( $s_start, [ $s_prefix, $s_first_balanced ] );
    $thinsl_grammar->rule_new( $s_prefix_char, [$s_xlparen] );
    $thinsl_grammar->rule_new( $s_prefix_char, [$s_rparen] );
    $thinsl_grammar->rule_new( $s_lparen,      [$s_xlparen] );
    $thinsl_grammar->rule_new( $s_lparen,      [$s_ilparen] );
    my $first_balanced_rule =
        $thinsl_grammar->rule_new( $s_first_balanced,
        [ $s_xlparen, $s_balanced_sequence, $s_rparen ] );
    $thinsl_grammar->rule_new( $s_balanced,
        [ $s_lparen, $s_balanced_sequence, $s_rparen ] );
    $thinsl_grammar->sequence_new( $s_prefix,            $s_prefix_char, {min => 0} );
    $thinsl_grammar->sequence_new( $s_balanced_sequence, $s_balanced,    {min => 0} );

    $thinsl_grammar->precompute();

    my $thinsl_recce = Marpa::R2::Thin::R->new($thinsl_grammar);

{
say STDERR "DEBUGGING!!!";
my $op_alternative = Marpa::R2::Thin::op('alternative');
my $op_alternative_ignore =  Marpa::R2::Thin::op('alternative;ignore');
my $op_earleme_complete = Marpa::R2::Thin::op('earleme_complete');
$thinsl_recce->char_register(ord('('), $op_alternative, $s_xlparen, $op_earleme_complete);
$thinsl_recce->char_register(ord(')'), $op_alternative, $s_rparen, $op_earleme_complete);
$thinsl_recce->string_read("(()())");
say STDERR "DEBUGGING!!!";
}

    $thinsl_recce->start_input();
    $thinsl_recce->expected_symbol_event_set( $s_endmark, 1 );
    $thinsl_recce->ruby_slippers_set( 1 );

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
	    $thinsl_recce->alternative($s_xlparen, 0, 1);
	    $event_count = $thinsl_recce->earleme_complete();
        }
        else {
            # say "Adding rparen at $location";
	    $thinsl_recce->alternative($s_rparen, 0, 1);
	    $event_count = $thinsl_recce->earleme_complete();
        }
        if ( $event_count
            and grep { $_ eq 'MARPA_EVENT_SYMBOL_EXPECTED' }
            map { ;($thinsl_grammar->event($_))[0] } ( 0 .. $event_count - 1 ) )
        {
            $end_of_match = $location + 1;
            last CHAR;
        } ## end if ( $event_count and grep { $_->[0] eq ...})
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
        last CHAR if $thinsl_recce->alternative($token, 0, 1);
        my $event_count = $thinsl_recce->earleme_complete();
        if ( $event_count
            and grep { $_ eq 'MARPA_EVENT_SYMBOL_EXPECTED' }
            map { ;($thinsl_grammar->event($_))[0] } ( 0 .. $event_count - 1 ) )
        {
	    $end_of_match = $location + 1;
	}
    } ## end CHAR: while ( ++$location < $string_length )

    my $start_of_match = $end_of_match;
    $thinsl_recce->progress_report_start($end_of_match);
    ITEM: while (1) {
        my ($rule_id, $dot_position, $item_origin) = $thinsl_recce->progress_item();
        last ITEM if not defined $rule_id;
	next ITEM if $dot_position >= 0;
        next ITEM if $rule_id != $first_balanced_rule;
	$start_of_match = $item_origin if $item_origin < $start_of_match;
    }

    my $value = substr $s, $start_of_match, $end_of_match - $start_of_match;
    return 0 if $thinsl_answer_shown;
    $thinsl_answer_shown = $value;
    say qq{thinsl: "$value" at $start_of_match-$end_of_match};
    return 0;

} ## end sub do_thin

sub do_retrace {
    my ($s) = @_;

    my $retrace_grammar     = Marpa::R2::Thin::G->new( { if => 1 } );
    my $s_start             = $retrace_grammar->symbol_new();
    my $s_target_end_marker = $retrace_grammar->symbol_new();
    my $s_target            = $retrace_grammar->symbol_new();
    my $s_prefix            = $retrace_grammar->symbol_new();
    my $s_prefix_char       = $retrace_grammar->symbol_new();
    $retrace_grammar->start_symbol_set($s_start);
    $retrace_grammar->rule_new( $s_start,
        [ $s_prefix, $s_target, $s_target_end_marker ] );
    $retrace_grammar->sequence_new( $s_prefix, $s_prefix_char, { min => 0 } );

    my $s_lparen                  = $retrace_grammar->symbol_new();
    my $s_rparen                  = $retrace_grammar->symbol_new();
    my $s_balanced_paren_sequence = $retrace_grammar->symbol_new();
    my $s_balanced_parens         = $retrace_grammar->symbol_new();
    my $target_rule =
        $retrace_grammar->rule_new( $s_target, [$s_balanced_parens] );
    $retrace_grammar->sequence_new( $s_balanced_paren_sequence,
        $s_balanced_parens, { min => 0 } );
    $retrace_grammar->rule_new( $s_balanced_parens,
        [ $s_lparen, $s_balanced_paren_sequence, $s_rparen ] );

    $retrace_grammar->precompute();

    my $retrace_recce = Marpa::R2::Thin::R->new($retrace_grammar);
    $retrace_recce->start_input();
    $retrace_recce->expected_symbol_event_set( $s_target_end_marker, 1 );
    $retrace_recce->ruby_slippers_set(1);

    my $location      = 0;
    my $string_length = length $s;
    my $end_of_match_earleme;

    # Add a check that we don't already expect the end_marker
    # at location 0 -- this will detect zero-length targets.

    # Find the prefix length
    CHAR: while ( $location < $string_length ) {
        my $value = substr $s, $location, 1;
        my $event_count;
        $retrace_recce->alternative( $s_prefix_char, 0, 1 );
        $value eq '(' and $retrace_recce->alternative( $s_lparen, 0, 1 );
        $value eq ')' and $retrace_recce->alternative( $s_rparen, 0, 1 );
        $event_count = $retrace_recce->earleme_complete();
        if ($event_count
            and grep { $_ eq 'MARPA_EVENT_SYMBOL_EXPECTED' }
            map { ; ( $retrace_grammar->event($_) )[0] }
            ( 0 .. $event_count - 1 )
            )
        {
            $end_of_match_earleme = $location + 1;
            last CHAR;
        } ## end if ( $event_count and grep { $_ eq ...})
        $location++;
    } ## end CHAR: while ( $location < $string_length )

    if ( not defined $end_of_match_earleme ) {
        say "No balanced parens";
        return 0;
    }
    my $start_of_match_earleme = $end_of_match_earleme - 1;

    $retrace_recce->progress_report_start($end_of_match_earleme);
    ITEM: while (1) {
        my ( $rule_id, $dot_position, $item_origin ) =
            $retrace_recce->progress_item();
        last ITEM if not defined $rule_id;
        next ITEM if $dot_position >= 0;
        next ITEM if $rule_id != $target_rule;
        $start_of_match_earleme = $item_origin
            if $item_origin < $start_of_match_earleme;
    } ## end ITEM: while (1)

    # Start the recognizer over again
    $retrace_recce = Marpa::R2::Thin::R->new($retrace_grammar);
    $retrace_recce->start_input();
    $retrace_recce->ruby_slippers_set(1);

    # Redo the prefix -- we know this must succeed, so no checking
    $location = 0;
    CHAR: while ( $location < $start_of_match_earleme ) {
        my $value = substr $s, $location, 1;
        $retrace_recce->alternative( $s_prefix_char, 0, 1 );
        $value eq '(' and $retrace_recce->alternative( $s_lparen, 0, 1 );
        $value eq ')' and $retrace_recce->alternative( $s_rparen, 0, 1 );
        $retrace_recce->earleme_complete();
        $location++;
    } ## end CHAR: while ( $location < $start_of_match_earleme )

    $retrace_recce->expected_symbol_event_set( $s_target_end_marker, 1 );

    # We are after the prefix, so now we just continue until exhausted
    CHAR: while ( $location < $string_length ) {
        my $value = substr $s, $location, 1;
        last CHAR
            if $retrace_recce->alternative(
            ( $value eq '(' ? $s_lparen : $s_rparen ),
            0, 1 );
        my $event_count = $retrace_recce->earleme_complete();
        if ($event_count) {
            my $exhausted = 0;
            EVENT:
            for my $event_type ( map { ( $retrace_grammar->event($_) )[0] }
                0 .. $event_count - 1 )
            {
                if ( $event_type eq 'MARPA_EVENT_SYMBOL_EXPECTED' ) {
                    $end_of_match_earleme = $location + 1;
                    next EVENT;
                }
                if ( $event_type eq 'MARPA_EVENT_EXHAUSTED' ) {
                    $exhausted = 1;
                    next EVENT;
                }
                die "Unknown event: $event_type";
            } ## end for my $event_type ( map { ( $retrace_grammar->event...)})
            last CHAR if $exhausted;
        } ## end if ($event_count)
        $location++;
    } ## end CHAR: while ( $location < $string_length )

    $start_of_match_earleme = $end_of_match_earleme;
    $retrace_recce->progress_report_start($end_of_match_earleme);
    ITEM: while (1) {
        my ( $rule_id, $dot_position, $item_origin ) =
            $retrace_recce->progress_item();
        last ITEM if not defined $rule_id;
        next ITEM if $dot_position >= 0;
        next ITEM if $rule_id != $target_rule;
        $start_of_match_earleme = $item_origin
            if $item_origin < $start_of_match_earleme;
    } ## end ITEM: while (1)

    my $start_of_match = $start_of_match_earleme;
    my $value = substr $s, $start_of_match,
        $end_of_match_earleme - $start_of_match_earleme;
    return 0 if $retrace_answer_shown;
    $retrace_answer_shown = $value;
    say
        qq{retrace: "$value" at $start_of_match_earleme-$end_of_match_earleme};
    return 0;

} ## end sub do_retrace

sub do_flm {
    my ($s) = @_;

    my $flm_grammar        = Marpa::R2::Thin::G->new( { if => 1 } );
    my $s_start = $flm_grammar->symbol_new();
    my $s_target_start_marker      = $flm_grammar->symbol_new();
    my $s_target_end_marker      = $flm_grammar->symbol_new();
    my $s_target      = $flm_grammar->symbol_new();
    my $s_prefix            = $flm_grammar->symbol_new();
    my $s_physical_char       = $flm_grammar->symbol_new();
    my $s_prefix_char       = $flm_grammar->symbol_new();
    $flm_grammar->start_symbol_set($s_start);
    $flm_grammar->rule_new( $s_start,
        [ $s_prefix, $s_target_start_marker, $s_target, $s_target_end_marker ] );
    $flm_grammar->rule_new( $s_prefix_char, [ $s_physical_char ] );
    $flm_grammar->rule_new( $s_prefix_char, [ $s_target_start_marker ] );
    $flm_grammar->sequence_new( $s_prefix, $s_prefix_char, { min => 0 } );

    my $s_lparen                  = $flm_grammar->symbol_new();
    my $s_rparen                  = $flm_grammar->symbol_new();
    my $s_balanced_paren_sequence = $flm_grammar->symbol_new();
    my $s_balanced_parens         = $flm_grammar->symbol_new();
    my $target_rule = $flm_grammar->rule_new( $s_target, [ $s_balanced_parens ] );
    $flm_grammar->sequence_new( $s_balanced_paren_sequence, $s_balanced_parens,
        { min => 0 } );
    $flm_grammar->rule_new( $s_balanced_parens,
        [ $s_lparen, $s_balanced_paren_sequence, $s_rparen ] );

    $flm_grammar->precompute();

    my $flm_recce = Marpa::R2::Thin::R->new($flm_grammar);
    $flm_recce->start_input();
    $flm_recce->expected_symbol_event_set( $s_target_end_marker, 1 );
    $flm_recce->ruby_slippers_set( 1 );

    my $location      = 0;
    my $string_length = length $s;
    my $end_of_match_earley_set;

    # Add a check that we don't already expect the end_marker
    # at location 0 -- this will detect zero-length targets.

    # Find the prefix length
    CHAR: while ( $location < $string_length ) {
        my $value = substr $s, $location, 1;
        my $event_count;
	my $token_symbol = $value eq '(' ? $s_lparen : $s_rparen;
	$flm_recce->alternative( $s_target_start_marker, 0, 1);
	$flm_recce->alternative( $token_symbol, 0, 2);
	$event_count = $flm_recce->earleme_complete();
        if ($event_count
            and grep { $_ eq 'MARPA_EVENT_SYMBOL_EXPECTED' }
            map { ; ( $flm_grammar->event($_) )[0] }
            ( 0 .. $event_count - 1 )
            )
        {
	   die "Zero length target at location $location\n",
	   "Zero length targets are not allowed";
	}
	$flm_recce->alternative( $token_symbol, 0, 1);
	$flm_recce->alternative( $s_physical_char, 0, 1);
	$event_count = $flm_recce->earleme_complete();
        if ($event_count
            and grep { $_ eq 'MARPA_EVENT_SYMBOL_EXPECTED' }
            map { ; ( $flm_grammar->event($_) )[0] }
            ( 0 .. $event_count - 1 )
            )
        {
            $end_of_match_earley_set = $flm_recce->latest_earley_set();
            last CHAR;
        } ## end if ( $event_count and grep { $_ eq ...})
        $location++;
    } ## end CHAR: while ( $location < $string_length )

    if ( not defined $end_of_match_earley_set ) {
        say "No balanced parens";
        return 0;
    }

    # We are after the prefix, so now we just continue until exhausted
    CHAR: for ( $location++; $location < $string_length; $location++ ) {
        my $value = substr $s, $location, 1;
        last CHAR
            if $flm_recce->alternative(
            ( $value eq '(' ? $s_lparen : $s_rparen ),
            0, 2 );
        for ( 0, 1 ) {
            my $event_count = $flm_recce->earleme_complete();
            if ($event_count) {
                my $exhausted = 0;
                EVENT:
                for my $event_type ( map { ( $flm_grammar->event($_) )[0] }
                    0 .. $event_count - 1 )
                {
                    if ( $event_type eq 'MARPA_EVENT_SYMBOL_EXPECTED' ) {
                        $end_of_match_earley_set = $flm_recce->latest_earley_set();
                        next EVENT;
                    }
                    if ( $event_type eq 'MARPA_EVENT_EXHAUSTED' ) {
                        $exhausted = 1;
                        next EVENT;
                    }
                    die "Unknown event: $event_type";
                } ## end for my $event_type ( map { ( $flm_grammar->event($_)...)})
                last CHAR if $exhausted;
            } ## end if ($event_count)
        } ## end for ( 0, 1 )
    } ## end CHAR: for ( $location++; $location < $string_length; $location...)

    my $start_of_match_earley_set = $end_of_match_earley_set;
    $flm_recce->progress_report_start($end_of_match_earley_set);
    ITEM: while (1) {
        my ( $rule_id, $dot_position, $item_origin ) =
            $flm_recce->progress_item();
        last ITEM if not defined $rule_id;
        next ITEM if $dot_position >= 0;
        next ITEM if $rule_id != $target_rule;
        $start_of_match_earley_set = $item_origin if $item_origin < $start_of_match_earley_set;
    } ## end ITEM: while (1)

  my $start_of_match_earleme = $flm_recce->earleme( $start_of_match_earley_set );
  my $end_of_match_earleme = $flm_recce->earleme( $end_of_match_earley_set );
    my $start_of_match = ($start_of_match_earleme-1)/2;
    my $end_of_match = $end_of_match_earleme/2;
    my $value = substr $s, $start_of_match, $end_of_match - $start_of_match;
    return 0 if $flm_answer_shown;
    $flm_answer_shown = $value;
    say qq{flm: "$value" at $start_of_match-$end_of_match};
    return 0;

} ## end sub do_flm

my $tests = {};
$tests->{flm} = sub { do_flm($s) } if $do_flm;
$tests->{retrace} = sub { do_retrace($s) } if $do_retrace;
$tests->{regex} = sub { do_regex($s) } if $do_regex;
$tests->{thin} = sub { do_thin($s) } if $do_thin;
$tests->{thinsl} = sub { do_thinsl($s) } if $do_thinsl;
$tests->{r2} = sub { do_r2($s) } if $do_r2;

if ( !$do_timing ) {
    for my $test_name ( keys %{$tests} ) {
        my $closure = $tests->{$test_name};
        say "=== $test_name ===";
        $closure->();
    }
    exit 0;
} ## end if ( !$do_timing )

Benchmark::cmpthese ( $iteration_count, $tests );

my $answer = '(()())';
if ($do_retrace) {
    say +( $retrace_answer_shown eq $answer
        ? 'Retrace Answer matches'
        : 'Retrace ANSWER DOES NOT MATCH!' );
}
if ($do_flm) {
  say +($flm_answer_shown eq $answer ? 'FLM Answer matches' : 'FLM ANSWER DOES NOT MATCH!');
}
if ($do_r2) {
  say +($r2_answer_shown eq $answer ? 'R2 Answer matches' : 'R2 ANSWER DOES NOT MATCH!');
}
if ($do_thin) {
  say +($thin_answer_shown eq $answer ? 'Thin Answer matches' : 'Thin ANSWER DOES NOT MATCH!');
}
if ($do_thinsl) {
  say +($thinsl_answer_shown eq $answer ? 'ThinSL Answer matches' : 'ThinSL ANSWER DOES NOT MATCH!');
}
if ($do_regex) {
  say +($regex_answer_shown eq $answer ? 'Regex Answer matches' : 'Regex ANSWER DOES NOT MATCH!');
}
