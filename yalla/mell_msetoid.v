(* mell_msetoid example file for yalla library *)
(* Coq 8.6 *)
(* v 1.0   Olivier Laurent *)


(** * Example of a concrete use of the yalla library: multi-set based MELL up to an equivalence relation *)

Require Import Morphisms.

Require Import Injective.
Require Import fmsetoidlist.
Require Import List_more.
Require Import Permutation_more.


(** ** 0. load the [ll] library *)

Require ll.


(** ** 1. define formulas *)

Inductive formula : Set :=
| var : formulas.Atom -> formula
| covar : formulas.Atom -> formula
| one : formula
| bot : formula
| tens : formula -> formula -> formula
| parr : formula -> formula -> formula
| oc : formula -> formula
| wn : formula -> formula.

Fixpoint dual A :=
match A with
| var x     => covar x
| covar x   => var x
| one       => bot
| bot       => one
| tens A B  => parr (dual B) (dual A)
| parr A B  => tens (dual B) (dual A)
| oc A      => wn (dual A)
| wn A      => oc (dual A)
end.


(** ** 2. define embedding into [formulas.formula] *)

Fixpoint mell2ll A :=
match A with
| var x    => formulas.var x
| covar x  => formulas.covar x
| one      => formulas.one
| bot      => formulas.bot
| tens A B => formulas.tens (mell2ll A) (mell2ll B)
| parr A B => formulas.parr (mell2ll A) (mell2ll B)
| oc A     => formulas.oc (mell2ll A)
| wn A     => formulas.wn (mell2ll A)
end.

Lemma mell2ll_inj : injective mell2ll.
Proof with try reflexivity.
intros A.
induction A ; intros B Heq ;
  destruct B ; inversion Heq ;
  try apply IHA in H0 ;
  try apply IHA1 in H0 ;
  try apply IHA2 in H1 ; subst...
Qed.

Lemma mell2ll_dual : forall A, formulas.dual (mell2ll A) = mell2ll (dual A).
Proof.
induction A ; simpl ;
  rewrite ? IHA ;
  rewrite ? IHA1 ;
  rewrite ? IHA2 ;
  reflexivity.
Qed.

Lemma mell2ll_map_wn : forall l,
  map mell2ll (map wn l) = map formulas.wn (map mell2ll l).
Proof with try reflexivity.
induction l...
simpl ; rewrite IHl...
Qed.

Lemma mell2ll_map_wn_inv : forall l1 l2,
  map formulas.wn l1 = map mell2ll l2 ->
    exists l2', l2 = map wn l2' /\ l1 = map mell2ll l2'.
Proof with try assumption ; try reflexivity.
induction l1 ; intros l2 Heq ;
  destruct l2 ; inversion Heq...
- exists nil ; split...
- apply IHl1 in H1.
  destruct f ; inversion H0 ; subst.
  destruct H1 as (l2' & Heq1 & H1) ; subst.
  exists (f :: l2') ; split...
Qed.


(** *** 2bis. sequents *)

Instance fmsetoid_formula : FinMultisetoid (list _) formula :=
  FMoidConstr_list formula.


(** ** 3. define proofs *)

Inductive mell : list formula -> Prop :=
| ax_r : forall X, mell (add (covar X) (add (var X) empty))
| ex_r : forall m1 m2, mell m1 -> meq m1 m2 -> mell m2
| one_r : mell (add one empty)
| bot_r : forall l, mell l -> mell (add bot l)
| tens_r : forall A B l1 l2,
              mell (add A l1) -> mell (add B l2) ->
              mell (add (tens A B) (sum l1 l2))
| parr_r : forall A B l,
             mell (add A (add B l)) ->
             mell (add (parr A B) l)
| oc_r : forall A l,
           mell (add A (fmmap wn l)) ->
           mell (add (oc A) (fmmap wn l))
| de_r : forall A l,
           mell (add A l) ->
           mell (add (wn A) l)
| wk_r : forall A l,
           mell l ->
           mell (add (wn A) l)
| co_r : forall A l,
           mell (add (wn A) (add (wn A) l)) ->
           mell (add (wn A) l).

Instance mell_meq : Proper (meq ==> iff) mell.
Proof.
intros m1 m2 Heq.
split ; intros Hmell.
- apply ex_r in Heq ; assumption.
- symmetry in Heq.
  apply ex_r in Heq ; assumption.
Qed.


(** ** 4. characterize corresponding [ll] fragment *)

(*
Definition mell_fragment A := exists B, A = mell2ll B.

Lemma mell_is_fragment : ll.fragment mell_fragment.
Proof.
intros A HfA B Hsf.
induction Hsf ; 
  try (apply IHHsf ;
       destruct HfA as [B0 HfA] ;
       destruct B0 ; inversion HfA ; subst ;
       eexists ; reflexivity).
assumption.
Qed.
*)

(** cut / axioms / mix0 / mix2 / permutation *)
Definition pfrag_mell := ll.mk_pfrag false (fun _ => False) false false true.
(*                                   cut   axioms           mix0  mix2  perm  *)


(** ** 5. prove equivalence of proof predicates *)

Lemma mell2mellfrag : forall m,
  mell m -> exists s, ll.ll pfrag_mell (map mell2ll (elts m)) s.
Proof with try reflexivity ; try eassumption.
intros l pi.
induction pi ;
  try destruct IHpi as [s' pi'] ;
  try destruct IHpi1 as [s1' pi1'] ;
  try destruct IHpi2 as [s2' pi2'] ;
  eexists ; simpl ; rewrite ? map_app ;
  try (now (constructor ; eassumption)).
- apply meq_perm in H.
  eapply ll.ex_r...
  apply Permutation_map...
- eapply ll.ex_r.
  + apply ll.tens_r.
    * assert (Helt := Permutation_map mell2ll (elts_add A l1)).
      apply (ll.ex_r _ _ _ _ pi1') in Helt.
      simpl in Helt...
    * assert (Helt := Permutation_map mell2ll (elts_add B l2)).
      apply (ll.ex_r _ _ _ _ pi2') in Helt.
      simpl in Helt...
  + apply Permutation_cons...
    rewrite <- map_app.
    apply Permutation_map.
    unfold sum.
    rewrite list2fm_app.
    rewrite sum_comm.
    unfold sum.
    unfold list2fm.
    simpl.
    rewrite ? fold_id.
    reflexivity.
- unfold fmmap.
  unfold list2fm.
  unfold add.
  unfold empty.
  simpl.
  rewrite fold_id.
  rewrite mell2ll_map_wn.
  unfold elts in pi'.
  unfold add in pi'.
  unfold fmmap in pi'.
  unfold list2fm in pi'.
  simpl in pi'.
  rewrite fold_id in pi'.
  rewrite mell2ll_map_wn in pi'.
  apply ll.oc_r...
- change (map mell2ll l) with (map formulas.wn nil ++ map mell2ll l).
  apply ll.co_r...
Qed.

Lemma mellfrag2mell : forall m s,
  ll.ll pfrag_mell (map mell2ll (elts m)) s -> mell m.
Proof with try eassumption ; try reflexivity.
intros m s pi.
remember (map mell2ll (elts m)) as l.
revert m Heql ; induction pi ; intros m Heql ;
  try (now (destruct m ; inversion Heql ;
            destruct f ; inversion H0)) ;
  try (now inversion f).
- destruct m ; inversion Heql.
  destruct m ; inversion H1.
  destruct f ; inversion H0 ; subst.
  destruct f0 ; inversion H2 ; subst.
  destruct m ; inversion H3.
  apply ax_r.
- subst.
  simpl in H.
  apply Permutation_map_inv in H.
  destruct H as (l' & Heq & HP) ; subst.
  eapply ex_r.
  + apply IHpi...
  + symmetry...
- destruct m ; inversion Heql.
  destruct f ; inversion H0 ; subst.
  destruct m ; inversion H1.
  apply one_r.
- destruct m ; inversion Heql.
  destruct f ; inversion H0 ; subst.
  apply bot_r.
  apply IHpi...
- destruct m ; inversion Heql.
  destruct f ; inversion H0 ; subst.
  assert (Heq := H1).
  decomp_map H1 ; subst.
  replace (tens f1 f2 :: l0 ++ l3)
     with (add (tens f1 f2) (sum l0 l3)).
  + rewrite sum_comm.
    apply tens_r.
    * apply IHpi1...
    * apply IHpi2...
  + unfold sum.
    unfold list2fm.
    unfold add.
    simpl.
    rewrite fold_id...
- destruct m ; inversion Heql.
  destruct f ; inversion H0 ; subst.
  apply parr_r.
  apply IHpi...
- destruct m ; inversion Heql.
  destruct f ; inversion H0 ; subst.
  apply mell2ll_map_wn_inv in H1.
  destruct H1 as (m' & Heq1 & Heq2) ; subst.
  replace (oc f :: map wn m')
     with (add (oc f) (fmmap wn m')).
  + apply oc_r.
    apply IHpi.
    unfold add.
    unfold fmmap.
    unfold list2fm.
    simpl.
    rewrite fold_id.
    rewrite mell2ll_map_wn...
  + unfold fmmap.
    unfold list2fm.
    unfold add.
    simpl.
    rewrite fold_id...
- destruct m ; inversion Heql.
  destruct f ; inversion H0 ; subst.
  apply de_r.
  apply IHpi...
- destruct m ; inversion Heql.
  destruct f ; inversion H0 ; subst.
  apply wk_r.
  apply IHpi...
- destruct m ; inversion Heql.
  destruct f ; inversion H0 ; subst.
  assert (Heq := H1).
  decomp_map H1 ; subst.
  apply mell2ll_map_wn_inv in H3.
  destruct H3 as (m' & Heq1 & Heq2) ; subst.
  apply co_r.
  eapply ex_r ; [ | symmetry ; apply Permutation_cons ;
                               [reflexivity | apply Permutation_middle ] ].
  apply IHpi.
  change (formulas.wn (mell2ll f)) with (mell2ll (wn f)).
  rewrite <- mell2ll_map_wn.
  list_simpl.
  reflexivity.
- inversion H.
Qed.


(** ** 6. import properties *)

(** *** axiom expansion *)

Lemma ax_gen_r : forall A, mell (add (dual A) (add A empty)).
Proof.
intro A.
destruct (@ll.ax_exp pfrag_mell (formulas.dual (mell2ll A)))
  as [s Hax].
rewrite formulas.bidual in Hax.
rewrite mell2ll_dual in Hax.
eapply mellfrag2mell.
eapply ll.ex_r ; [ eassumption | reflexivity ].
Qed.

(** *** cut elimination *)

Lemma cut_r : forall A m1 m2, 
  mell (add A m1) -> mell (add (dual A) m2) -> mell (sum m1 m2).
Proof with try eassumption.
intros A m1 m2 pi1 pi2.
destruct (mell2mellfrag _ pi1) as [s1 pi1'] ; simpl in pi1'.
destruct (mell2mellfrag _ pi2) as [s2 pi2'] ; simpl in pi2'.
rewrite <- mell2ll_dual in pi2'.
assert (forall l : list formulas.formula, ~ ll.pgax pfrag_mell l)
  as Hax by (intros l Hax ; inversion Hax).
apply (ll.cut_r_axfree Hax _ _ _ _ _ pi2') in pi1'.
destruct pi1' as [s pi].
eapply mellfrag2mell.
apply (ll.ex_r _ _ _ _ pi).
rewrite <- map_app.
apply Permutation_map.
unfold sum ; unfold list2fm ; unfold add ; simpl.
rewrite fold_id.
reflexivity.
Qed.




