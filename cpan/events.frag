case MARPA_SLRTR_CODEPOINT_READ:
{
  struct marpa_slrtr_codepoint_read_s *event =
    &marpa_slr_event.t_trace_codepoint_read;
  AV *event_av = newAV ();

  av_push (event_av, newSVpvs ("'trace"));
  av_push (event_av, newSVpvs ("lexer reading codepoint"));
  av_push (event_av, newSViv ((IV) event->codepoint));
  av_push (event_av, newSViv ((IV) event->perl_pos));
  av_push (event_av, newSViv ((IV) event->current_lexer_ix));
  av_push (slr->r1_wrapper->event_queue, newRV_noinc ((SV *) event_av));
}

case MARPA_SLRTR_CODEPOINT_REJECTED:
{
  struct marpa_slrtr_codepoint_rejected_s *event =
    &marpa_slr_event.t_trace_codepoint_rejected;
  AV *event_av = newAV ();

  av_push (event_av, newSVpvs ("'trace"));
  av_push (event_av, newSVpvs ("lexer rejected codepoint"));
  av_push (event_av, newSViv ((IV) event->codepoint));
  av_push (event_av, newSViv ((IV) event->perl_pos));
  av_push (event_av, newSViv ((IV) event->symbol_id));
  av_push (event_av, newSViv ((IV) event->current_lexer_ix));
  av_push (slr->r1_wrapper->event_queue, newRV_noinc ((SV *) event_av));
}

case MARPA_SLRTR_CODEPOINT_ACCEPTED:
{
  struct marpa_slrtr_codepoint_accepted_s *event =
    &marpa_slr_event.t_trace_codepoint_accepted;
  AV *event_av = newAV ();

  av_push (event_av, newSVpvs ("'trace"));
  av_push (event_av, newSVpvs ("lexer accepted codepoint"));
  av_push (event_av, newSViv ((IV) event->codepoint));
  av_push (event_av, newSViv ((IV) event->perl_pos));
  av_push (event_av, newSViv ((IV) event->symbol_id));
  av_push (event_av, newSViv ((IV) event->current_lexer_ix));
  av_push (slr->r1_wrapper->event_queue, newRV_noinc ((SV *) event_av));
}

case MARPA_SLRTR_DISCARDED_LEXEME:
{
  struct marpa_slrtr_discarded_lexeme_s *event =
    &marpa_slr_event.t_trace_discarded_lexeme;
  AV *event_av = newAV ();

  av_push (event_av, newSVpvs ("'trace"));
  av_push (event_av, newSVpvs ("discarded lexeme"));
  /* We do not have the lexeme, but we have the 
   * lexer rule.
   * The upper level will have to figure things out.
   */
  av_push (event_av, newSViv ((IV) event->rule_id));
  av_push (event_av, newSViv ((IV) event->start_of_lexeme));
  av_push (event_av, newSViv ((IV) event->end_of_lexeme));
  av_push (event_av, newSViv ((IV) event->current_lexer_ix));
  av_push (slr->r1_wrapper->event_queue, newRV_noinc ((SV *) event_av));
}

case MARPA_SLRTR_IGNORED_LEXEME:
{
  struct marpa_slrtr_ignored_lexeme_s *event =
    &marpa_slr_event.t_trace_ignored_lexeme;
  AV *event_av = newAV ();

  av_push (event_av, newSVpvs ("'trace"));
  av_push (event_av, newSVpvs ("ignored lexeme"));
  av_push (event_av, newSViv ((IV) event->lexeme));
  av_push (event_av, newSViv ((IV) event->start_of_lexeme));
  av_push (event_av, newSViv ((IV) event->end_of_lexeme));
  av_push (slr->r1_wrapper->event_queue, newRV_noinc ((SV *) event_av));
}

case MARPA_SLREV_SYMBOL_COMPLETED:
{
  struct marpa_slrev_symbol_completed_s *event =
    &marpa_slr_event.t_symbol_completed;
  AV *event_av = newAV ();
  av_push (event_av, newSVpvs ("symbol completed"));
  av_push (event_av, newSViv ((IV) event->completed_symbol));
  av_push (r_wrapper->event_queue, newRV_noinc ((SV *) event_av));
}

case MARPA_SLREV_SYMBOL_NULLED:
{
  struct marpa_slrev_symbol_nulled_s *event = &marpa_slr_event.t_symbol_nulled;
  AV *event_av = newAV ();
  av_push (event_av, newSVpvs ("symbol nulled"));
  av_push (event_av, newSViv ((IV) event->nulled_symbol));
  av_push (r_wrapper->event_queue, newRV_noinc ((SV *) event_av));
}

case MARPA_SLREV_SYMBOL_PREDICTED:
{
  struct marpa_slrev_symbol_predicted_s *event =
    &marpa_slr_event.t_symbol_predicted;
  AV *event_av = newAV ();

  av_push (event_av, newSVpvs ("symbol predicted"));
  av_push (event_av, newSViv ((IV) event->predicted_symbol));
  av_push (r_wrapper->event_queue, newRV_noinc ((SV *) event_av));
}

case MARPA_SLREV_MARPA_R_UNKNOWN:
{
  /* An unknown Marpa_Recce event */
  struct marpa_slrev_marpa_r_unknown_s *event =
    &marpa_slr_event.t_marpa_r_unknown;
  AV *event_av = newAV ();
  av_push (event_av, newSVpvs ("unknown event"));
  av_push (event_av, newSVpv (event->result_string, 0));
  av_push (r_wrapper->event_queue, newRV_noinc ((SV *) event_av));
}

case MARPA_SLRTR_G1_UNEXPECTED_LEXEME:
{
  struct marpa_slrtr_g1_unexpected_lexeme_s *event =
    &marpa_slr_event.t_trace_g1_unexpected_lexeme;
  AV *event_av = newAV ();
  av_push (event_av, newSVpvs ("'trace"));
  av_push (event_av, newSVpvs ("g1 unexpected lexeme"));
  av_push (event_av, newSViv ((IV) event->start_of_lexeme));	/* start */
  av_push (event_av, newSViv ((IV) event->end_of_lexeme));	/* end */
  av_push (event_av, newSViv ((IV) event->lexeme));	/* lexeme */
  av_push (event_av, newSViv ((IV) event->current_lexer_ix));
  av_push (slr->r1_wrapper->event_queue, newRV_noinc ((SV *) event_av));
}

case MARPA_SLRTR_BEFORE_LEXEME_EVENT:
{
  struct marpa_slrtr_before_lexeme_s *event =
    &marpa_slr_event.t_trace_before_lexeme;
  AV *event_av = newAV ();
  av_push (event_av, newSVpvs ("'trace"));
  av_push (event_av, newSVpvs ("g1 before lexeme event"));
  av_push (event_av, newSViv ((IV) event->start_of_pause_lexeme));	/* start */
  av_push (event_av, newSViv ((IV) event->end_of_pause_lexeme));	/* end */
  av_push (event_av, newSViv ((IV) event->pause_lexeme));	/* lexeme */
  av_push (slr->r1_wrapper->event_queue, newRV_noinc ((SV *) event_av));
}

case MARPA_SLREV_BEFORE_LEXEME:
{
  struct marpa_slrev_before_lexeme_s *event = &marpa_slr_event.t_before_lexeme;
  AV *event_av = newAV ();
  av_push (event_av, newSVpvs ("before lexeme"));
  av_push (event_av, newSViv ((IV) event->pause_lexeme));	/* lexeme */
  av_push (slr->r1_wrapper->event_queue, newRV_noinc ((SV *) event_av));
}

case MARPA_SLRTR_G1_ATTEMPTING_LEXEME:
{
  struct marpa_slrtr_attempting_lexeme_s *event =
    &marpa_slr_event.t_trace_attempting_lexeme;
  AV *event_av = newAV ();
  av_push (event_av, newSVpvs ("'trace"));
  av_push (event_av, newSVpvs ("g1 attempting lexeme"));
  av_push (event_av, newSViv ((IV) event->start_of_lexeme));	/* start */
  av_push (event_av, newSViv ((IV) event->end_of_lexeme));	/* end */
  av_push (event_av, newSViv ((IV) event->lexeme));	/* lexeme */
  av_push (slr->r1_wrapper->event_queue, newRV_noinc ((SV *) event_av));
}

case MARPA_SLRTR_G1_DUPLICATE_LEXEME:
{
  struct marpa_slrtr_duplicate_lexeme_s *event =
    &marpa_slr_event.t_trace_duplicate_lexeme;
  AV *event_av = newAV ();
  av_push (event_av, newSVpvs ("'trace"));
  av_push (event_av, newSVpvs ("g1 duplicate lexeme"));
  av_push (event_av, newSViv ((IV) event->start_of_lexeme));	/* start */
  av_push (event_av, newSViv ((IV) event->end_of_lexeme));	/* end */
  av_push (event_av, newSViv ((IV) event->lexeme));	/* lexeme */
  av_push (slr->r1_wrapper->event_queue, newRV_noinc ((SV *) event_av));
}

case MARPA_SLRTR_G1_ACCEPTED_LEXEME:
{
  struct marpa_slrtr_accepted_lexeme_s *event =
    &marpa_slr_event.t_trace_accepted_lexeme;
  AV *event_av = newAV ();
  av_push (event_av, newSVpvs ("'trace"));
  av_push (event_av, newSVpvs ("g1 accepted lexeme"));
  av_push (event_av, newSViv ((IV) event->start_of_lexeme));	/* start */
  av_push (event_av, newSViv ((IV) event->end_of_lexeme));	/* end */
  av_push (event_av, newSViv ((IV) event->lexeme));	/* lexeme */
  av_push (event_av, newSViv ((IV) event->current_lexer_ix));
  av_push (slr->r1_wrapper->event_queue, newRV_noinc ((SV *) event_av));
}

case MARPA_SLRTR_AFTER_LEXEME:
{
  struct marpa_slrtr_event_after_lexeme_s *event =
    &marpa_slr_event.t_after_lexeme;
  AV *event_av = newAV ();
  av_push (event_av, newSVpvs ("'trace"));
  av_push (event_av, newSVpvs ("g1 pausing after lexeme"));
  av_push (event_av, newSViv ((IV) event->start_of_lexeme));	/* start */
  av_push (event_av, newSViv ((IV) event->end_of_lexeme));	/* end */
  av_push (event_av, newSViv ((IV) event->lexeme));	/* lexeme */
  av_push (slr->r1_wrapper->event_queue, newRV_noinc ((SV *) event_av));
}

case MARPA_SLREV_AFTER_LEXEME:
{
  struct marpa_slrev_event_after_lexeme_s *event =
    &marpa_slr_event.t_after_lexeme;
  AV *event_av = newAV ();;
  av_push (event_av, newSVpvs ("after lexeme"));
  av_push (event_av, newSViv ((IV) event->lexeme));	/* lexeme */
  av_push (slr->r1_wrapper->event_queue, newRV_noinc ((SV *) event_av));
}

case MARPA_SLREV_LEXER_RESTARTED_RECCE:
{
  struct marpa_slrev_lexer_restarted_recce_s *event =
    &marpa_slr_event.t_lexer_restarted_recce;
  AV *event_av = newAV ();
  av_push (event_av, newSVpvs ("'trace"));
  av_push (event_av, newSVpv ("lexer restarted recognizer", 0));
  av_push (event_av, newSViv ((IV) event->perl_pos));
  av_push (event_av, newSViv ((IV) event->current_lexer_ix));
  av_push (slr->r1_wrapper->event_queue, newRV_noinc ((SV *) event_av));
  break;
}

case MARPA_SLRTR_CHANGE_LEXERS:
{
  struct marpa_slrtr_change_lexers_s *event =
    &marpa_slr_event.t_trace_change_lexers;
  AV *event_av = newAV ();
  av_push (event_av, newSVpvs ("'trace"));
  av_push (event_av, newSVpv ("changing lexers", 0));
  av_push (event_av, newSViv ((IV) event->perl_pos));
  av_push (event_av, newSViv ((IV) event->old_lexer_ix));
  av_push (event_av, newSViv ((IV) event->new_lexer_ix));
  av_push (slr->r1_wrapper->event_queue, newRV_noinc ((SV *) event_av));
  break;
}

case MARPA_SLREV_NO_ACCEPTABLE_INPUT:
{
  struct marpa_slrev_no_acceptable_input_s *event =
    &marpa_slr_event.t_no_acceptable_input;
  AV *event_av = newAV ();
  av_push (event_av, newSVpvs ("no acceptable input"));
  av_push (slr->r1_wrapper->event_queue, newRV_noinc ((SV *) event_av));
  break;
}

default:
{
  AV *event_av = newAV ();
  av_push (event_av, newSVpvs ("unknown SLR event"));
  av_push (event_av, newSViv ((IV) event_type));
  av_push (slr->r1_wrapper->event_queue, newRV_noinc ((SV *) event_av));
  break;
}
