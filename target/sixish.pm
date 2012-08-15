use 5.010;
use strict;
use warnings;

sub do_sixish {
    my ($s) = @_;

    my $resl_grammar     = Marpa::R2::Thin::G->new( { if => 1 } );
    my $s_start             = $resl_grammar->symbol_new();
    my $s_target_end_marker = $resl_grammar->symbol_new();
    my $s_target            = $resl_grammar->symbol_new();
    my $s_prefix            = $resl_grammar->symbol_new();
    my $s_prefix_char       = $resl_grammar->symbol_new();
    $resl_grammar->start_symbol_set($s_start);
    $resl_grammar->rule_new( $s_start,
        [ $s_prefix, $s_target, $s_target_end_marker ] );
    $resl_grammar->sequence_new( $s_prefix, $s_prefix_char, { min => 0 } );

    my $s_lparen                  = $resl_grammar->symbol_new();
    my $s_rparen                  = $resl_grammar->symbol_new();
    my $s_balanced_paren_sequence = $resl_grammar->symbol_new();
    my $s_balanced_parens         = $resl_grammar->symbol_new();
    my $target_rule =
        $resl_grammar->rule_new( $s_target, [$s_balanced_parens] );
    $resl_grammar->sequence_new( $s_balanced_paren_sequence,
        $s_balanced_parens, { min => 0 } );
    $resl_grammar->rule_new( $s_balanced_parens,
        [ $s_lparen, $s_balanced_paren_sequence, $s_rparen ] );

    $resl_grammar->precompute();

    my $resl_recce = Marpa::R2::Thin::R->new($resl_grammar);
    $resl_recce->start_input();
    $resl_recce->expected_symbol_event_set( $s_target_end_marker, 1 );

    $resl_recce->char_register(
        ord('('),               $op_alternative_ignore, $s_lparen,
        $op_alternative_ignore, $s_prefix_char,         $op_earleme_complete
    );
    $resl_recce->char_register(
        ord(')'),               $op_alternative_ignore, $s_rparen,
        $op_alternative_ignore, $s_prefix_char,         $op_earleme_complete
    );

    my $string_length = length $s;
    my $end_of_match_earleme;

    $resl_recce->input_string_set($s);
    my $event_count = $resl_recce->input_string_read();
    if ( not $event_count ) {
        say "No balanced parens";
        return 0;
    }
    if ( $event_count < 0 ) {
        die "Token rejected";
    }

    if (grep { $_ eq 'MARPA_EVENT_SYMBOL_EXPECTED' }
        map { ; ( $resl_grammar->event($_) )[0] } ( 0 .. $event_count - 1 )
        )
    {

        $end_of_match_earleme = $resl_recce->input_string_pos();
    } ## end if ( grep { $_ eq 'MARPA_EVENT_SYMBOL_EXPECTED' } map...)

    # For arbitrary targets,
    # Add a check that we don't already expect the end_marker
    # at location 0? This will detect zero-length targets?

    if ( not defined $end_of_match_earleme ) {
        say "No balanced parens";
        return 0;
    }

    my $start_of_match_earleme = $end_of_match_earleme - 1;

    $resl_recce->progress_report_start($end_of_match_earleme);
    ITEM: while (1) {
        my ( $rule_id, $dot_position, $item_origin ) =
            $resl_recce->progress_item();
        last ITEM if not defined $rule_id;
        next ITEM if $dot_position >= 0;
        next ITEM if $rule_id != $target_rule;
        $start_of_match_earleme = $item_origin
            if $item_origin < $start_of_match_earleme;
    } ## end ITEM: while (1)

    # Start the recognizer over again
    $resl_recce = Marpa::R2::Thin::R->new($resl_grammar);
    $resl_recce->start_input();

    $resl_recce->char_register(
        ord('('),               $op_alternative_ignore, $s_lparen,
        $op_alternative_ignore, $s_prefix_char,         $op_earleme_complete
    );
    $resl_recce->char_register(
        ord(')'),               $op_alternative_ignore, $s_rparen,
        $op_alternative_ignore, $s_prefix_char,         $op_earleme_complete
    );

    $resl_recce->input_string_set(substr $s, 0, $start_of_match_earleme);
    die if defined $resl_recce->input_string_read();

    $resl_recce->char_register( ord('('), $op_alternative, $s_lparen,
        $op_earleme_complete );
    $resl_recce->char_register( ord(')'), $op_alternative, $s_rparen,
        $op_earleme_complete );
    $resl_recce->input_string_set( substr $s, $start_of_match_earleme );
    $resl_recce->expected_symbol_event_set( $s_target_end_marker, 1 );

    READ: while (1) {
        my $event_count = $resl_recce->input_string_read();
        last READ if not defined $event_count;
        last READ if $event_count <= 0;
        my $exhausted = 0;
        EVENT:
        for my $event_type ( map { ( $resl_grammar->event($_) )[0] }
            0 .. $event_count - 1 )
        {
            if ( $event_type eq 'MARPA_EVENT_SYMBOL_EXPECTED' ) {
                $end_of_match_earleme = $start_of_match_earleme + $resl_recce->input_string_pos();
                next EVENT;
            }
            if ( $event_type eq 'MARPA_EVENT_EXHAUSTED' ) {
                $exhausted = 1;
                next EVENT;
            }
            die "Unknown event: $event_type";
        } ## end for my $event_type ( map { ( $resl_grammar->event($_)...)})
        last READ if $exhausted;
    } ## end READ: while (1)

    $start_of_match_earleme = $end_of_match_earleme;
    $resl_recce->progress_report_start($end_of_match_earleme);
    ITEM: while (1) {
        my ( $rule_id, $dot_position, $item_origin ) =
            $resl_recce->progress_item();
        last ITEM if not defined $rule_id;
        next ITEM if $dot_position >= 0;
        next ITEM if $rule_id != $target_rule;
        $start_of_match_earleme = $item_origin
            if $item_origin < $start_of_match_earleme;
    } ## end ITEM: while (1)

    my $start_of_match = $start_of_match_earleme;
    my $value = substr $s, $start_of_match,
        $end_of_match_earleme - $start_of_match_earleme;
    return 0 if $sixish_answer_shown;
    $sixish_answer_shown = $value;
    say
        qq{resl: "$value" at $start_of_match_earleme-$end_of_match_earleme};
    return 0;

} ## end sub do_resl

1;
