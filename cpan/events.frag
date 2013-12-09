	{
	  AV *event;
	  SV *event_data[5];
	  event_data[0] = newSVpvs ("'trace");
	  event_data[1] = newSVpvs ("lexer reading codepoint");
	  event_data[2] = newSViv ((IV) codepoint);
	  event_data[3] = newSViv ((IV) slr->perl_pos);
	  event_data[4] = newSViv (slr->current_lexer->index);
	  event = av_make (Dim (event_data), event_data);
	  av_push (slr->r1_wrapper->event_queue, newRV_noinc ((SV *) event));
	}
		      {
			AV *event;
			SV *event_data[6];
			event_data[0] = newSVpvs ("'trace");
			event_data[1] = newSVpvs ("lexer rejected codepoint");
			event_data[2] = newSViv ((IV) codepoint);
			event_data[3] = newSViv ((IV) slr->perl_pos);
			event_data[4] = newSViv ((IV) symbol_id);
			event_data[5] = newSViv ((IV)slr->current_lexer->index);
			event = av_make (Dim (event_data), event_data);
			av_push (slr->r1_wrapper->event_queue,
				 newRV_noinc ((SV *) event));
		      }
		      {
			AV *event;
			SV *event_data[6];
			event_data[0] = newSVpvs ("'trace");
			event_data[1] = newSVpvs ("lexer accepted codepoint");
			event_data[2] = newSViv ((IV) codepoint);
			event_data[3] = newSViv ((IV) slr->perl_pos);
			event_data[4] = newSViv ((IV) symbol_id);
			event_data[5] = newSViv ((IV)slr->current_lexer->index);
			event = av_make (Dim (event_data), event_data);
			av_push (slr->r1_wrapper->event_queue,
				 newRV_noinc ((SV *) event));
		      }

		{
		  AV *event;
		  SV *event_data[6];
		  event_data[0] = newSVpvs ("'trace");
		  event_data[1] = newSVpvs ("discarded lexeme");
		  /* We do not have the lexeme, but we have the 
		   * lexer rule.
		   * The upper level will have to figure things out.
		   */
		  event_data[2] = newSViv (rule_id);
		  event_data[3] = newSViv (slr->start_of_lexeme);
		  event_data[4] = newSViv (slr->end_of_lexeme);
		  event_data[5] = newSViv (slr->current_lexer->index);
		  event = av_make (Dim (event_data), event_data);
		  av_push (slr->r1_wrapper->event_queue,
			   newRV_noinc ((SV *) event));
		}

	    {
	      AV *event;
	      SV *event_data[5];
	      event_data[0] = newSVpvs ("'trace");
	      event_data[1] = newSVpvs ("ignored lexeme");
	      event_data[2] = newSViv (g1_lexeme);
	      event_data[3] = newSViv (slr->start_of_lexeme);
	      event_data[4] = newSViv (slr->end_of_lexeme);
	      event = av_make (Dim (event_data), event_data);
	      av_push (slr->r1_wrapper->event_queue,
		       newRV_noinc ((SV *) event));
	    }
	    {
	      AV *event;
	      SV *event_data[2];
	      Marpa_Symbol_ID completed_symbol =
		marpa_g_event_value (&marpa_event);
	      event_data[0] = newSVpvs ("symbol completed");
	      event_data[1] = newSViv (completed_symbol);
	      event = av_make (Dim (event_data), event_data);
	      av_push (r_wrapper->event_queue, newRV_noinc ((SV *) event));
	    }
	    {
	      AV *event;
	      SV *event_data[2];
	      Marpa_Symbol_ID nulled_symbol =
		marpa_g_event_value (&marpa_event);
	      event_data[0] = newSVpvs ("symbol nulled");
	      event_data[1] = newSViv (nulled_symbol);
	      event = av_make (Dim (event_data), event_data);
	      av_push (r_wrapper->event_queue, newRV_noinc ((SV *) event));
	    }
	    {
	      AV *event;
	      SV *event_data[2];
	      Marpa_Symbol_ID predicted_symbol =
		marpa_g_event_value (&marpa_event);
	      event_data[0] = newSVpvs ("symbol predicted");
	      event_data[1] = newSViv (predicted_symbol);
	      event = av_make (Dim (event_data), event_data);
	      av_push (r_wrapper->event_queue, newRV_noinc ((SV *) event));
	    }

case MARPA_SLR_UNKNOWN_EVENT:
	    {
	      AV *event;
	      const char *result_string = event_type_to_string (event_type);
	      SV *event_data[2];
	      event_data[0] = newSVpvs ("unknown event");
	      if (!result_string)
		{
		  result_string =
		    form ("event(%d): unknown event code, %d", event_ix,
			  event_type);
		}
	      event_data[1] = newSVpv (result_string, 0);
	      event = av_make (Dim (event_data), event_data);
	      av_push (r_wrapper->event_queue, newRV_noinc ((SV *) event));
	    }

case MARPA_SLR_EVENT_TRACE_DISCARDED_LEXEME;
		    {
		      AV *event;
		      SV *event_data[6];
		      event_data[0] = newSVpvs ("'trace");
		      event_data[1] = newSVpvs ("discarded lexeme");
		      /* We do not have the lexeme, but we have the 
		       * lexer rule.
		       * The upper level will have to figure things out.
		       */
		      event_data[2] = newSViv (rule_id);
		      event_data[3] = newSViv (slr->start_of_lexeme);
		      event_data[4] = newSViv (slr->end_of_lexeme);
		      event_data[5] = newSViv (slr->current_lexer->index);
		      event = av_make (Dim (event_data), event_data);
		      av_push (slr->r1_wrapper->event_queue,
			       newRV_noinc ((SV *) event));
		    }

case MARPA_SLR_EVENT_TRACE_G1_UNEXPECTED_LEXEME;
		    {
		      AV *event;
		      SV *event_data[6];
		      event_data[0] = newSVpvs ("'trace");
		      event_data[1] = newSVpvs ("g1 unexpected lexeme");
		      event_data[2] = newSViv (slr->start_of_lexeme);	/* start */
		      event_data[3] = newSViv (slr->end_of_lexeme);	/* end */
		      event_data[4] = newSViv (g1_lexeme);	/* lexeme */
		      event_data[5] = newSViv ((IV)slr->current_lexer->index);
		      event = av_make (Dim (event_data), event_data);
		      av_push (slr->r1_wrapper->event_queue,
			       newRV_noinc ((SV *) event));
		    }

case MARPA_SLR_EVENT_TRACE_G1_BEFORE_LEXEME_EVENT;
		  {
		    AV *event;
		    SV *event_data[5];
		    event_data[0] = newSVpvs ("'trace");
		    event_data[1] = newSVpvs ("g1 before lexeme event");
		    event_data[2] = newSViv (slr->start_of_pause_lexeme);	/* start */
		    event_data[3] = newSViv (slr->end_of_pause_lexeme);	/* end */
		    event_data[4] = newSViv (slr->pause_lexeme);	/* lexeme */
		    event = av_make (Dim (event_data), event_data);
		    av_push (slr->r1_wrapper->event_queue,
			     newRV_noinc ((SV *) event));
		  }

case MARPA_SLR_EVENT_BEFORE_LEXEME;
		{
		  AV *event;
		  SV *event_data[2];
		  event_data[0] = newSVpvs ("before lexeme");
		  event_data[1] = newSViv (slr->pause_lexeme);	/* lexeme */
		  event = av_make (Dim (event_data), event_data);
		  av_push (slr->r1_wrapper->event_queue,
			   newRV_noinc ((SV *) event));
		}

case MARPA_SLR_EVENT_TRACE_G1_ATTEMPTING_LEXEME;
	      {
		AV *event;
		SV *event_data[5];
		event_data[0] = newSVpvs ("'trace");
		event_data[1] = newSVpvs ("g1 attempting lexeme");
		event_data[2] = newSViv (slr->start_of_lexeme);	/* start */
		event_data[3] = newSViv (slr->end_of_lexeme);	/* end */
		event_data[4] = newSViv (g1_lexeme);	/* lexeme */
		event = av_make (Dim (event_data), event_data);
		av_push (slr->r1_wrapper->event_queue,
			 newRV_noinc ((SV *) event));
	      }

case MARPA_SLR_EVENT_TRACE_G1_DUPLICATE_LEXEME;
		  {
		    AV *event;
		    SV *event_data[5];
		    event_data[0] = newSVpvs ("'trace");
		    event_data[1] = newSVpvs ("g1 duplicate lexeme");
		    event_data[2] = newSViv (slr->start_of_lexeme);	/* start */
		    event_data[3] = newSViv (slr->end_of_lexeme);	/* end */
		    event_data[4] = newSViv (g1_lexeme);	/* lexeme */
		    event = av_make (Dim (event_data), event_data);
		    av_push (slr->r1_wrapper->event_queue,
			     newRV_noinc ((SV *) event));
		  }
case MARPA_SLR_EVENT_TRACE_G1_ACCEPTED_LEXEME;
		  {
		    AV *event;
		    SV *event_data[6];
		    event_data[0] = newSVpvs ("'trace");
		    event_data[1] = newSVpvs ("g1 accepted lexeme");
		    event_data[2] = newSViv (slr->start_of_lexeme);	/* start */
		    event_data[3] = newSViv (slr->end_of_lexeme);	/* end */
		    event_data[4] = newSViv (g1_lexeme);	/* lexeme */
		    event_data[5] = newSViv ((IV)slr->current_lexer->index);
		    event = av_make (Dim (event_data), event_data);
		    av_push (slr->r1_wrapper->event_queue,
			     newRV_noinc ((SV *) event));
		  }


case MARPA_SLR_EVENT_TRACE_AFTER_LEXEME:
{
  struct marpa_slrvs_event_after_lexeme *event =
    &marpa_slr_event.after_lexeme_t;
  AV *event_av = newAV ();
  av_push (event_av, newSVpvs ("'trace"));
  av_push (event_av, newSVpvs ("g1 pausing after lexeme"));
  av_push (event_av, newSViv (event->start_of_lexeme));	/* start */
  av_push (event_av, newSViv (event->end_of_lexeme));	/* end */
  av_push (event_av, newSViv (event->lexeme));	/* lexeme */
  av_push (slr->r1_wrapper->event_queue, newRV_noinc ((SV *) event_av));
}

case MARPA_SLR_EVENT_AFTER_LEXEME:
{
  struct marpa_slrvs_event_after_lexeme *event =
    &marpa_slr_event.after_lexeme_t;
  AV *event_av = newAV ();;
  av_push (event_av, newSVpvs ("after lexeme"));
  av_push (event_av, newSViv (event->lexeme));	/* lexeme */
  av_push (slr->r1_wrapper->event_queue, newRV_noinc ((SV *) event_av));
}

case MARPA_SLR_EVENT_LEXER_RESTARTED_RECCE:
{
  struct marpa_slrvs_lexer_restarted_recce *event =
    &marpa_slr_event.lexer_restarted_recce_t;
  AV *event_av = newAV ();
  av_push (event_av, newSVpvs ("'trace"));
  av_push (event_av, newSVpv ("lexer restarted recognizer", 0));
  av_push (event_av, newSViv ((IV) event->perl_pos));
  av_push (event_av, newSViv ((IV) event->current_lexer_ix));
  av_push (slr->r1_wrapper->event_queue, newRV_noinc ((SV *) event_av));
  break;
}

case MARPA_SLR_EVENT_TRACE_CHANGE_LEXERS:
{
  struct marpa_slrvs_trace_change_lexers *event =
    &marpa_slr_event.trace_change_lexers_t;
  AV *event_av = newAV ();
  av_push (event_av, newSVpvs ("'trace"));
  av_push (event_av, newSVpv ("changing lexers", 0));
  av_push (event_av, newSViv ((IV) event->perl_pos));
  av_push (event_av, newSViv ((IV) event->old_lexer_ix));
  av_push (event_av, newSViv ((IV) event->new_lexer_ix));
  av_push (slr->r1_wrapper->event_queue, newRV_noinc ((SV *) event_av));
  break;
}

case MARPA_SLR_EVENT_NO_ACCEPTABLE_INPUT:
{
  struct marpa_slrvs_no_acceptable_input *event =
    &marpa_slr_event.no_acceptable_input_t;
  AV *event_av = newAV ();
  av_push (event_av, newSVpvs ("no acceptable input"));
  av_push (slr->r1_wrapper->event_queue, newRV_noinc ((SV *) event_av));
  break;
}
