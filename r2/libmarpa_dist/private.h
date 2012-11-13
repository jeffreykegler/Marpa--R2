/*
 * Copyright 2012 Jeffrey Kegler
 * This file is part of Marpa::R2.  Marpa::R2 is free software: you can
 * redistribute it and/or modify it under the terms of the GNU Lesser
 * General Public License as published by the Free Software Foundation,
 * either version 3 of the License, or (at your option) any later version.
 *
 * Marpa::R2 is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser
 * General Public License along with Marpa::R2.  If not, see
 * http://www.gnu.org/licenses/.
 */
/*
 * DO NOT EDIT DIRECTLY
 * This file is written by w2private_h.pl
 * It is not intended to be modified directly
 */


static RULE rule_new(GRAMMAR g,
const SYMID lhs, const SYMID *rhs, int length);
static int
duplicate_rule_cmp (const void *ap, const void *bp, void *param UNUSED);
static int sym_rule_cmp(
    const void* ap,
    const void* bp,
    void *param UNUSED);
static int cmp_by_aimid (const void* ap,
	const void* bp);
static int cmp_by_postdot_and_aimid (const void* ap,
	const void* bp);
static int AHFA_state_cmp(
    const void* ap,
    const void* bp,
    void *param UNUSED);
static int
cmp_by_irl_sort_key(const void* ap, const void* bp);
static AHFA
create_predicted_AHFA_state(
     GRAMMAR g,
     Bit_Vector prediction_rule_vector,
     IRL* irl_by_sort_key,
     DQUEUE states_p,
     AVL_TREE duplicates,
     AIM* item_list_working_buffer
     );
static Marpa_Error_Code invalid_source_type_code(unsigned int type);
static void earley_item_ambiguate (struct marpa_r * r, EIM item);
static void
postdot_items_create (RECCE r,
  Bit_Vector bv_ok_for_chain,
  ES current_earley_set);
static int report_item_cmp (
    const void* ap,
    const void* bp,
    void *param UNUSED);
static int bv_scan(Bit_Vector bv, unsigned int start,
                                    unsigned int* min, unsigned int* max);
static void transitive_closure(Bit_Matrix matrix);
static void * dstack_resize(struct s_dstack* this, size_t type_bytes);
static void*
_marpa_default_out_of_memory(void);
static void
set_error (GRAMMAR g, Marpa_Error_Code code, const char* message, unsigned int flags);
static inline void
grammar_unref (GRAMMAR g);
static inline GRAMMAR
grammar_ref (GRAMMAR g);
static inline void grammar_free(GRAMMAR g);
static inline void symbol_add( GRAMMAR g, SYM symbol);
static inline int xsy_id_is_valid(GRAMMAR g, XSYID xsy_id);
static inline int isy_is_valid(GRAMMAR g, ISYID isyid);
static inline void
rule_add (GRAMMAR g, RULE rule);
static inline void event_new(GRAMMAR g, int type);
static inline void int_event_new(GRAMMAR g, int type, int value);
static inline SYM
symbol_new (GRAMMAR g);
static inline ISY symbol_alias_create(GRAMMAR g, SYM symbol);
static inline ISY
isy_start(GRAMMAR g);
static inline ISY
isy_new(GRAMMAR g, XSY source);
static inline ISY
isy_clone(GRAMMAR g, XSY xsy);
static inline   XRL xrl_start (GRAMMAR g, const SYMID lhs, const SYMID * rhs, int length);
static inline XRL xrl_finish(GRAMMAR g, XRL rule);
static inline IRL
irl_start(GRAMMAR g, int length);
static inline void
irl_finish( GRAMMAR g, IRL irl);
static inline Marpa_Symbol_ID rule_lhs_get(RULE rule);
static inline Marpa_Symbol_ID* rule_rhs_get(RULE rule);
static inline int
symbol_instance_of_ahfa_item_get (AIM aim);
static inline int aim_is_valid(
GRAMMAR g, AIMID item_id);
static inline void AHFA_initialize(AHFA ahfa);
static inline AEX aex_of_ahfa_by_aim_get(AHFA ahfa, AIM sought_aim);
static inline int AHFA_state_id_is_valid(GRAMMAR g, AHFAID AHFA_state_id);
static inline AHFA
assign_AHFA_state (AHFA sought_state, AVL_TREE duplicates);
static inline AHFA to_ahfa_of_transition_get(TRANS transition);
static inline int completion_count_of_transition_get(TRANS transition);
static inline URTRANS transition_new(struct obstack *obstack, AHFA to_ahfa, int aim_ix);
static inline TRANS* transitions_new(GRAMMAR g, int isy_count);
static inline void transition_add(struct obstack *obstack, AHFA from_ahfa, ISYID isyid, AHFA to_ahfa);
static inline void completion_count_inc(struct obstack *obstack, AHFA from_ahfa, ISYID isyid);
static inline INPUT input_new (GRAMMAR g);
static inline void
input_unref (INPUT input);
static inline INPUT
input_ref (INPUT input);
static inline void input_free(INPUT input);
static inline void
recce_unref (RECCE r);
static inline RECCE recce_ref (RECCE r);
static inline void recce_free(struct marpa_r *r);
static inline ES current_es_of_r(RECCE r);
static inline ES
earley_set_new( RECCE r, EARLEME id);
static inline EIM earley_item_create(const RECCE r,
    const EIK_Object key);
static inline EIM
earley_item_assign (const RECCE r, const ES set, const ES origin,
		    const AHFA state);
static inline void trace_earley_item_clear(RECCE r);
static inline PIM*
pim_isy_p_find (ES set, ISYID isyid);
static inline PIM first_pim_of_es_by_isyid(ES set, ISYID isyid);
static inline void
completion_link_add (RECCE r,
		EIM item,
		EIM predecessor,
		EIM cause);
static inline void
leo_link_add (RECCE r,
		EIM item,
		LIM predecessor,
		EIM cause);
static inline void trace_source_link_clear(RECCE r);
static inline int
alternative_insertion_point (RECCE r, ALT new_alternative);
static inline int alternative_cmp(const ALT_Const a, const ALT_Const b);
static inline ALT alternative_pop(RECCE r, EARLEME earleme);
static inline int alternative_insert(RECCE r, ALT new_alternative);
static inline void earley_set_update_items(RECCE r, ES set);
static inline void r_update_earley_sets(RECCE r);
static inline void ur_node_stack_init(URS stack);
static inline void ur_node_stack_reset(URS stack);
static inline void ur_node_stack_destroy(URS stack);
static inline UR ur_node_new(URS stack, UR prev);
static inline void
ur_node_push (URS stack, EIM earley_item, AEX aex);
static inline UR
ur_node_pop (URS stack);
static inline int psia_test_and_set(
    struct obstack* obs,
    struct s_bocage_setup_per_es* per_es_data,
    EIM earley_item,
    AEX ahfa_element_ix);
static inline AEX lim_base_data_get(LIM leo_item, EIM* p_base);
static inline AIM base_aim_of_lim(LIM leo_item);
static inline DAND draft_and_node_new(struct obstack *obs, OR predecessor, OR cause);
static inline void draft_and_node_add(struct obstack *obs, OR parent, OR predecessor, OR cause);
static inline TOK and_node_token(AND and_node);
static inline void
bocage_unref (BOCAGE b);
static inline BOCAGE
bocage_ref (BOCAGE b);
static inline void
bocage_free (BOCAGE b);
static inline void
order_unref (ORDER o);
static inline ORDER
order_ref (ORDER o);
static inline void order_free(ORDER o);
static inline ANDID and_order_ix_is_valid(ORDER o, OR or_node, int ix);
static inline ANDID and_order_get(ORDER o, OR or_node, int ix);
static inline void tree_exhaust(TREE t);
static inline void
tree_unref (TREE t);
static inline TREE
tree_ref (TREE t);
static inline void tree_free(TREE t);
static inline void
tree_pause (TREE t);
static inline void
tree_unpause (TREE t);
static inline int tree_or_node_try(TREE tree, ORID or_node_id);
static inline void tree_or_node_release(TREE tree, ORID or_node_id);
static inline void
value_unref (VALUE v);
static inline VALUE
value_ref (VALUE v);
static inline void value_free(VALUE v);
static inline int symbol_is_valued_set (
    VALUE v, XSYID xsy_id, int value);
static inline int lbv_bits_to_size(int bits);
static inline Bit_Vector
lbv_obs_new0 (struct obstack *obs, int bits);
static inline LBV lbv_copy(
  struct obstack* obs, LBV old_lbv, int bits);
static inline LBV lbv_fill(
  LBV lbv, int bits);
static inline unsigned int bv_bits_to_size(unsigned int bits);
static inline unsigned int bv_bits_to_unused_mask(unsigned int bits);
static inline Bit_Vector bv_create(unsigned int bits);
static inline Bit_Vector
bv_obs_create (struct obstack *obs, unsigned int bits);
static inline Bit_Vector bv_shadow(Bit_Vector bv);
static inline Bit_Vector bv_obs_shadow(struct obstack * obs, Bit_Vector bv);
static inline Bit_Vector bv_copy(Bit_Vector bv_to, Bit_Vector bv_from);
static inline Bit_Vector bv_clone(Bit_Vector bv);
static inline Bit_Vector bv_obs_clone(struct obstack *obs, Bit_Vector bv);
static inline void bv_free(Bit_Vector vector);
static inline void bv_fill(Bit_Vector bv);
static inline void bv_clear(Bit_Vector bv);
static inline void bv_over_clear(Bit_Vector bv, unsigned int bit);
static inline void bv_bit_set(Bit_Vector vector, unsigned int bit);
static inline void bv_bit_clear(Bit_Vector vector, unsigned int bit);
static inline int bv_bit_test(Bit_Vector vector, unsigned int bit);
static inline int
bv_bit_test_and_set (Bit_Vector vector, unsigned int bit);
static inline int bv_is_empty(Bit_Vector addr);
static inline void bv_not(Bit_Vector X, Bit_Vector Y);
static inline void bv_and(Bit_Vector X, Bit_Vector Y, Bit_Vector Z);
static inline void bv_or(Bit_Vector X, Bit_Vector Y, Bit_Vector Z);
static inline void bv_or_assign(Bit_Vector X, Bit_Vector Y);
static inline unsigned int
bv_count (Bit_Vector v);
static inline void
rhs_closure (GRAMMAR g, Bit_Vector bv, XRLID ** xrl_list_x_rh_sym);
static inline Bit_Matrix matrix_obs_create(struct obstack *obs, unsigned int rows, unsigned int columns);
static inline int matrix_columns(Bit_Matrix matrix);
static inline Bit_Vector matrix_row(Bit_Matrix matrix, unsigned int row);
static inline void matrix_bit_set(Bit_Matrix matrix, unsigned int row, unsigned int column);
static inline void matrix_bit_clear(Bit_Matrix matrix, unsigned int row, unsigned int column);
static inline int matrix_bit_test(Bit_Matrix matrix, unsigned int row, unsigned int column);
static inline void
psar_init (const PSAR psar, int length);
static inline void psar_destroy(const PSAR psar);
static inline PSL psl_new(const PSAR psar);
static inline void psar_reset(const PSAR psar);
static inline void psar_dealloc(const PSAR psar);
static inline void psl_claim(
    PSL* const psl_owner, const PSAR psar);
static inline PSL psl_alloc(const PSAR psar);
