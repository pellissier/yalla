(* llfoc library for yalla *)


(* output in Type *)


(** * Focusing in Linear Logic *)

Require Import Omega.
Require Import Psatz.
Require Import CMorphisms.

Require Import List_more.
Require Import List_Type.
Require Import List_Type_more.
Require Import Permutation_Type_more.
Require Import Permutation_Type_solve.
Require Import genperm_Type.

Require Import ll_fragments.


(** ** Synchronous and asynchronous formulas *)
Inductive sformula : formula -> Prop :=
| pvar : forall x, sformula (var x)
| pone : sformula one
| ptens : forall A B, sformula (tens A B)
| pzero : sformula zero
| pplus : forall A B, sformula (aplus A B)
| poc : forall A, sformula (oc A).

Inductive aformula : formula -> Prop :=
| ncovar : forall x, aformula (covar x)
| nbot : aformula bot
| nparr : forall A B, aformula (parr A B)
| ntop : aformula top
| nwith : forall A B, aformula (awith A B)
| nwn : forall A, aformula (wn A).

Lemma polarity : forall A, {sformula A} + {aformula A}.
Proof.
induction A ;
  try (now (left ; constructor)) ;
  try (now (right ; constructor)).
Defined.

Lemma disj_polarity : forall A, ~ (sformula A /\ aformula A).
Proof.
induction A ; intros [Hp Hn] ; inversion Hp ; inversion Hn.
Qed.

Lemma sformula_dual : forall A, sformula (dual A) -> aformula A.
Proof.
intros A Hp ; destruct A ; inversion Hp ; constructor.
Qed.

Lemma aformula_dual : forall A, aformula (dual A) -> sformula A.
Proof.
intros A Hn ; destruct A ; inversion Hn ; constructor.
Qed.


(** ** The weakly focused system [llfoc] *)

Definition tFoc x :=
  { sformula x } + { exists X, x = covar X } + { exists y, x = wn y } + { x = top }.

Lemma tFoc_dec : forall x, tFoc x + (tFoc x -> False).
Proof with myeeasy.
induction x ;
  try (now (left ; left ; left ; left ; constructor)) ;
  try (now (left ; left ; left ; right ; eexists ; reflexivity)) ;
  try (now (left ; left ; right ; eexists ; reflexivity)) ;
  try (now (left ; right ; reflexivity)) ;
  try (now (right ; intros [[[ H | [X H] ] | [X H] ] | H] ; inversion H)).
Qed.

Lemma tFocl_dec : forall l, Forall_Type tFoc l + (Forall_Type tFoc l -> False).
Proof with myeasy.
induction l.
- left ; constructor.
- destruct (tFoc_dec a).
  + destruct IHl.
    * left ; constructor...
    * right ; intros H.
      inversion H ; subst ; intuition.
  + right ; intros H.
    inversion H ; subst ; intuition.
Qed.

Lemma not_tFoc : forall x, (tFoc x -> False) ->
  (x = bot) + { y | x = parr (fst y) (snd y) } + { y | x = awith (fst y) (snd y) }.
Proof with myeasy.
destruct x ; intros HnF ;
  try (now (exfalso ; apply HnF ; left ; left ; left ; constructor)) ;
  try (now (exfalso ; apply HnF ; left ; left ; right ; eexists ; reflexivity)) ;
  try (now (exfalso ; apply HnF ; left ; right ; eexists ; reflexivity)) ;
  try (now (exfalso ; apply HnF ; right ; reflexivity)).
- left ; left...
- left ; right ; exists (x1,x2)...
- right ; eexists (x1,x2)...
Qed.

Lemma not_tFocl : forall l, (Forall_Type tFoc l -> False) ->
  { l' : _ & l = fst (snd l') ++ fst l' :: (snd (snd l'))
           & sum (sum (fst l' = bot) { B | fst l' = parr (fst B) (snd B) })
                                     { B | fst l' = awith (fst B) (snd B) } }.
Proof with myeeasy.
intros l HnF.
apply Forall_neg_Exists_Type in HnF.
- induction l ; inversion HnF ; subst.
  + exists (a,(nil,l))...
    simpl ; apply not_tFoc...
  + apply IHl in H0 as [l' Heq Hf] ; subst.
    exists (fst l',(a::fst (snd l'),snd (snd l')))...
- intros x.
  assert (Hd := tFoc_dec x).
  destruct Hd ; intuition.
Qed.

Definition option_prop {A:Type} (f:A->Prop) o :=
match o with
| Some a => f a
| None => True
end.

Definition polcont l A :=
match polarity A with
| left _ => l
| right _ => A :: l
end.
Definition polfoc A :=
match polarity A with
| left _ => Some A
| right _ => None
end.
Lemma polconts : forall A l, sformula A -> polcont l A = l.
Proof.
intros.
unfold polcont.
case (polarity A).
- intros ; reflexivity.
- intros.
  exfalso.
  eapply disj_polarity ; split ; eassumption.
Qed.
Lemma polconta : forall A l, aformula A -> polcont l A = A :: l.
Proof.
intros.
unfold polcont.
case (polarity A).
- intros.
  exfalso.
  eapply disj_polarity ; split ; eassumption.
- intros ; reflexivity.
Qed.
Lemma polfocs : forall A, sformula A -> polfoc A = Some A.
Proof.
intros.
unfold polfoc.
case (polarity A).
- intros ; reflexivity.
- intros.
  exfalso.
  eapply disj_polarity ; split ; eassumption.
Qed.
Lemma polfoca : forall A, aformula A -> polfoc A = None.
Proof.
intros.
unfold polfoc.
case (polarity A).
- intros.
  exfalso.
  eapply disj_polarity ; split ; eassumption.
- intros ; reflexivity.
Qed.

Lemma Permutation_middle_polcont : forall l1 l2 A B,
  Permutation_Type (B :: polcont (l1 ++ l2) A) (polcont (l1 ++ B :: l2) A).
Proof.
intros l1 l2 A B.
destruct (polarity A) as [Hs | Ha].
- rewrite 2 (polconts _ _ Hs).
  apply Permutation_Type_middle.
- rewrite 2 (polconta _ _ Ha).
  rewrite 2 (app_comm_cons _ _ A).
  apply Permutation_Type_middle.
Qed.

Inductive llfoc : list formula -> option formula -> Type :=
| ax_fr : forall X, llfoc (covar X :: nil) (Some (var X))
| ex_fr : forall l1 l2 Pi, llfoc l1 Pi -> Permutation_Type l1 l2 ->
                           llfoc l2 Pi
| foc_fr : forall A l, llfoc l (Some A) -> llfoc (A :: l) None
| one_fr : llfoc nil (Some one)
| bot_fr : forall l Pi, llfoc l Pi ->
                          llfoc (bot :: l) Pi
| tens_fr : forall A B l1 l2,
                    llfoc (polcont l1 A) (polfoc A) ->
                    llfoc (polcont l2 B) (polfoc B) ->
                    llfoc (l1 ++ l2) (Some (tens A B))
| parr_fr : forall A B l Pi,
                    llfoc (A :: B :: l) Pi ->
                    llfoc (parr A B :: l) Pi
| top_fr : forall l Pi, option_prop sformula Pi -> Forall_Type tFoc l ->
                    llfoc (top :: l) Pi
| plus_fr1 : forall A B l, llfoc (polcont l A) (polfoc A) ->
                             llfoc l (Some (aplus A B))
| plus_fr2 : forall A B l, llfoc (polcont l A) (polfoc A) ->
                             llfoc l (Some (aplus B A))
| with_fr : forall A B l Pi, llfoc (A :: l) Pi -> llfoc (B :: l) Pi ->
                        llfoc (awith A B :: l) Pi
| oc_fr : forall A l, llfoc (A :: map wn l) None ->
                        llfoc (map wn l) (Some (oc A))
| de_fr : forall A l, llfoc (polcont l A) (polfoc A) ->
                         llfoc (wn A :: l) None
| wk_fr : forall A l Pi, llfoc l Pi -> llfoc (wn A :: l) Pi
| co_fr : forall A l Pi, llfoc (wn A :: wn A :: l) Pi ->
                           llfoc (wn A :: l) Pi.

Fixpoint fpsize {l Pi} (pi : llfoc l Pi) :=
match pi with
| ax_fr _ => 1
| ex_fr _ _ _ pi0 _ => S (fpsize pi0)
| foc_fr _ _ pi0 => S (fpsize pi0)
| one_fr => 1
| bot_fr _ _ pi0 => S (fpsize pi0)
| tens_fr _ _ _ _ pi1 pi2 => S (fpsize pi1 + fpsize pi2)
| parr_fr _ _ _ _ pi0 => S (fpsize pi0)
| top_fr _ _ _ _ => 1
| plus_fr1 _ _ _ pi0 => S (fpsize pi0)
| plus_fr2 _ _ _ pi0 => S (fpsize pi0)
| with_fr _ _ _ _ pi1 pi2 => S (max (fpsize pi1) (fpsize pi2))
| oc_fr _ _ pi0 => S (fpsize pi0)
| de_fr _ _ pi0 => S (fpsize pi0)
| wk_fr _ _ _ pi0 => S (fpsize pi0)
| co_fr _ _ _ pi0 => S (fpsize pi0)
end.

Lemma top_gen_fr : forall l Pi, option_prop sformula Pi -> llfoc (top :: l) Pi.
Proof with myeeasy.
intros l.
remember (list_sum (map fsize l)) as n.
revert l Heqn ; induction n using (well_founded_induction lt_wf) ;
  intros l Heqn Pi Hs ; subst.
destruct (tFocl_dec l).
- apply top_fr...
- apply not_tFocl in f.
  destruct f as [(A & l1 & l2) Heq [[Hb | ([B C] & Hp)] | ([B C] & Hw)]] ;
    subst ; simpl ; simpl in H ; [simpl in Hb | simpl in Hp | simpl in Hw] ; subst.
  + apply (ex_fr (bot :: l2 ++ top :: l1)) ; [ apply bot_fr | perm_Type_solve ].
    apply (ex_fr (top :: l1 ++ l2)) ; [ eapply H | perm_Type_solve ]...
    rewrite 2 map_app ; rewrite 2 list_sum_app ; simpl...
  + apply (ex_fr (parr B C :: l2 ++ top :: l1)) ; [ apply parr_fr | perm_Type_solve ].
    apply (ex_fr (top :: l1 ++ B :: C :: l2)) ; [ eapply H | perm_Type_solve ]...
    rewrite 2 map_app ; rewrite 2 list_sum_app ; simpl...
  + apply (ex_fr (awith B C :: l2 ++ top :: l1)) ; [ apply with_fr | perm_Type_solve ].
    * apply (ex_fr (top :: l1 ++ B :: l2)) ; [ eapply H | perm_Type_solve ]...
      rewrite 2 map_app ; rewrite 2 list_sum_app ; simpl...
    * apply (ex_fr (top :: l1 ++ C :: l2)) ; [ eapply H | perm_Type_solve ]...
      rewrite 2 map_app ; rewrite 2 list_sum_app ; simpl...
Qed.

Lemma sync_focus : forall l A, llfoc l (Some A) -> sformula A.
Proof.
intros l A pi.
remember (Some A) as Pi ; revert HeqPi ; induction pi ;
  intros HeqPi ; inversion HeqPi ; subst ;
  try (now constructor) ;
  try apply IHpi ;
  try assumption.
apply IHpi1 ; assumption.
Qed.

Lemma llfoc_foc_is_llfoc_foc : forall l A, llfoc l (Some A) ->
  llfoc (polcont l A) (polfoc A).
Proof.
intros l A pi.
assert (Hs := sync_focus _ _ pi).
rewrite (polconts _ _ Hs).
rewrite (polfocs _ Hs).
apply pi.
Qed.

Lemma llfoc_cont_is_llfoc_cont : forall l A, aformula A ->
  llfoc (A :: l) None -> llfoc (polcont l A) (polfoc A).
Proof.
intros l A Ha pi.
rewrite (polconta _ _ Ha).
rewrite (polfoca _ Ha).
apply pi.
Qed.

Lemma bot_rev_f : forall l Pi (pi : llfoc l Pi),
  forall l1 l2, l = l1 ++ bot :: l2 ->
    { pi' : llfoc (l1 ++ l2) Pi & fpsize pi' < fpsize pi }.
Proof with myeeasy.
intros l Pi pi.
induction pi ; intros l1' l2' Heq ; subst.
- exfalso.
  destruct l1' ; inversion Heq.
  destruct l1' ; inversion H1.
- assert (HP := p).
  simpl ; apply Permutation_Type_vs_elt_inv in p.
  destruct p as ((l3 & l4) & Heq) ; subst.
  simpl in IHpi ; simpl in HP ; simpl.
  destruct (IHpi _ _ eq_refl) as [pi0 Hs].
  simpl in HP ; apply Permutation_Type_app_inv in HP.
  remember (ex_fr _ _ _ pi0 HP) as pi1.
  exists pi1.
  subst ; simpl ; omega.
- destruct l1' ; inversion Heq ; subst.
  + exfalso.
    clear IHpi ; apply sync_focus in pi.
    inversion pi.
  + destruct (IHpi _ _ eq_refl) as [pi0 Hs].
    remember (foc_fr _ _ pi0) as pi1.
    exists pi1.
    subst ; simpl ; omega.
- exfalso.
  destruct l1' ; inversion Heq.
- destruct l1' ; inversion Heq ; subst.
  + exists pi.
    simpl ; omega.
  + destruct (IHpi _ _ eq_refl) as [pi0 Hs].
    remember (bot_fr _ _ pi0) as pi1.
    exists pi1.
    subst ; simpl ; omega.
- dichot_Type_elt_app_exec Heq ; subst.
  + destruct (polarity A) as [Hs | Ha].
    * assert (H1 := IHpi1 _ _ (polconts _ _ Hs)).
      rewrite <- (polconts _ (l1' ++ l) Hs) in H1.
      destruct H1 as [pi1' Hs1].
      remember (tens_fr _ _ _ _ pi1' pi2) as pi.
      rewrite app_assoc.
      exists pi.
      subst ; simpl ; omega.
    * assert (polcont (l1' ++ bot :: l) A = (A :: l1') ++ bot :: l) as Hpa
        by (rewrite (polconta _ _ Ha) ; rewrite app_comm_cons ; reflexivity).
      assert (H1 := IHpi1 _ _ Hpa).
      rewrite <- app_comm_cons in H1.
      rewrite <- (polconta _ (l1' ++ l) Ha) in H1.
      destruct H1 as [pi1' Hs1].
      remember (tens_fr _ _ _ _ pi1' pi2) as pi.
      rewrite app_assoc.
      exists pi.
      subst ; simpl ; omega.
  + destruct (polarity B) as [Hs | Ha].
    * assert (H2 := IHpi2 _ _ (polconts _ _ Hs)).
      rewrite <- (polconts _ (l0 ++ l2') Hs) in H2.
      destruct H2 as [pi2' Hs2].
      remember (tens_fr _ _ _ _ pi1 pi2') as pi.
      rewrite <- app_assoc.
      exists pi.
      subst ; simpl ; omega.
    * assert (polcont (l0 ++ bot :: l2') B = (B :: l0) ++ bot :: l2') as Hpa
        by (rewrite (polconta _ _ Ha) ; rewrite app_comm_cons ; reflexivity).
      assert (H2 := IHpi2 _ _ Hpa).
      rewrite <- app_comm_cons in H2.
      rewrite <- (polconta _ (l0 ++ l2') Ha) in H2.
      destruct H2 as [pi2' Hs2].
      remember (tens_fr _ _ _ _ pi1 pi2') as pi.
      rewrite <- app_assoc.
      exists pi.
      subst ; simpl ; omega.
- destruct l1' ; inversion Heq ; subst.
  assert (A :: B :: l1' ++ bot :: l2' = (A :: B :: l1') ++ bot :: l2') as Heql
    by (list_simpl ; reflexivity).
  assert (H0 := IHpi _ _ Heql).
  rewrite <- 2 app_comm_cons in H0.
  destruct H0 as [pi0 Hs].
  remember (parr_fr _ _ _ _ pi0) as pi1.
  exists pi1 ; subst.
  simpl ; omega.
- exfalso.
  destruct l1' ; inversion Heq ; subst.
  apply Forall_Type_app_inv in f.
  destruct f as [_ f].
  inversion f ; subst.
  inversion H1 as [[[Ht | Ht] | Ht] | Ht] ; try now (inversion Ht).
- destruct (polarity A) as [Hs | Ha].
  + assert (H1 := IHpi _ _ (polconts _ _ Hs)).
    rewrite <- (polconts _ (l1' ++ l2') Hs) in H1.
    destruct H1 as [pi1' Hs1].
    remember (plus_fr1 _ B _ pi1') as pi0.
    exists pi0.
    subst ; simpl ; omega.
  + assert (polcont (l1' ++ bot :: l2') A = (A :: l1') ++ bot :: l2') as Hpa
      by (rewrite (polconta _ _ Ha) ; rewrite app_comm_cons ; reflexivity).
    assert (H1 := IHpi _ _ Hpa).
    rewrite <- app_comm_cons in H1.
    rewrite <- (polconta _ (l1' ++ l2') Ha) in H1.
    destruct H1 as [pi1' Hs1].
    remember (plus_fr1 _ B _ pi1') as pi0.
    exists pi0.
    subst ; simpl ; omega.
- destruct (polarity A) as [Hs | Ha].
  + assert (H1 := IHpi _ _ (polconts _ _ Hs)).
    rewrite <- (polconts _ (l1' ++ l2') Hs) in H1.
    destruct H1 as [pi1' Hs1].
    remember (plus_fr2 _ B _ pi1') as pi0.
    exists pi0.
    subst ; simpl ; omega.
  + assert (polcont (l1' ++ bot :: l2') A = (A :: l1') ++ bot :: l2') as Hpa
      by (rewrite (polconta _ _ Ha) ; rewrite app_comm_cons ; reflexivity).
    assert (H1 := IHpi _ _ Hpa).
    rewrite <- app_comm_cons in H1.
    rewrite <- (polconta _ (l1' ++ l2') Ha) in H1.
    destruct H1 as [pi1' Hs1].
    remember (plus_fr2 _ B _ pi1') as pi0.
    exists pi0.
    subst ; simpl ; omega.
- destruct l1' ; inversion Heq ; subst.
  assert (A :: l1' ++ bot :: l2' = (A :: l1') ++ bot :: l2') as Heql1
    by (list_simpl ; reflexivity).
  assert (B :: l1' ++ bot :: l2' = (B :: l1') ++ bot :: l2') as Heql2
    by (list_simpl ; reflexivity).
  assert (H1 := IHpi1 _ _ Heql1).
  assert (H2 := IHpi2 _ _ Heql2).
  rewrite <- app_comm_cons in H1.
  rewrite <- app_comm_cons in H2.
  destruct H1 as [pi1' Hs1].
  destruct H2 as [pi2' Hs2].
  remember (with_fr _ _ _ _ pi1' pi2') as pi.
  exists pi.
  subst ; simpl ; lia.
- exfalso.
  symmetry in Heq.
  decomp_map Heq.
  inversion Heq3.
- destruct l1' ; inversion Heq ; subst.
  destruct (polarity A) as [Hs | Ha].
  + assert (H1 := IHpi _ _ (polconts _ _ Hs)).
    rewrite <- (polconts _ (l1' ++ l2') Hs) in H1.
    destruct H1 as [pi1' Hs1].
    remember (de_fr _ _ pi1') as pi0.
    exists pi0.
    subst ; simpl ; omega.
  + assert (polcont (l1' ++ bot :: l2') A = (A :: l1') ++ bot :: l2') as Hpa
      by (rewrite (polconta _ _ Ha) ; rewrite app_comm_cons ; reflexivity).
    assert (H1 := IHpi _ _ Hpa).
    rewrite <- app_comm_cons in H1.
    rewrite <- (polconta _ (l1' ++ l2') Ha) in H1.
    destruct H1 as [pi1' Hs1].
    remember (de_fr _ _ pi1') as pi0.
    exists pi0.
    subst ; simpl ; omega.
- destruct l1' ; inversion Heq ; subst.
  destruct (IHpi _ _ eq_refl) as [pi0 Hs].
  remember (wk_fr A _ _ pi0) as pi1.
  exists pi1.
  subst ; simpl ; omega.
- destruct l1' ; inversion Heq ; subst.
  assert (wn A :: wn A :: l1' ++ bot :: l2' = (wn A :: wn A :: l1') ++ bot :: l2')
    as Heql by (list_simpl ; reflexivity).
  assert (H0 := IHpi _ _ Heql).
  rewrite <- 2 app_comm_cons in H0.
  destruct H0 as [pi0 Hs].
  remember (co_fr _ _ _ pi0) as pi1.
  exists pi1 ; subst.
  simpl ; omega.
Qed.

Lemma parr_rev_f : forall l Pi (pi : llfoc l Pi),
  forall A B l1 l2, l = l1 ++ parr A B :: l2 ->
    { pi' : llfoc (l1 ++ A :: B :: l2) Pi & fpsize pi' < fpsize pi }.
Proof with myeeasy.
intros l Pi pi.
induction pi ; intros A' B' l1' l2' Heq ; subst.
- exfalso.
  destruct l1' ; inversion Heq.
  destruct l1' ; inversion H1.
- assert (HP := p).
  simpl ; apply Permutation_Type_vs_elt_inv in p.
  destruct p as ((l3 & l4) & Heq) ; subst.
  simpl in IHpi ; simpl in HP ; simpl.
  destruct (IHpi _ _ _ _ eq_refl) as [pi0 Hs].
  simpl in HP ; apply Permutation_Type_app_inv in HP.
  apply (Permutation_Type_elt B') in HP.
  apply (Permutation_Type_elt A') in HP.
  remember (ex_fr _ _ _ pi0 HP) as pi1.
  exists pi1.
  subst ; simpl ; omega.
- destruct l1' ; inversion Heq ; subst.
  + exfalso.
    clear IHpi ; apply sync_focus in pi.
    inversion pi.
  + destruct (IHpi _ _ _ _ eq_refl) as [pi0 Hs].
    remember (foc_fr _ _ pi0) as pi1.
    exists pi1.
    subst ; simpl ; omega.
- exfalso.
  destruct l1' ; inversion Heq.
- destruct l1' ; inversion Heq ; subst.
  destruct (IHpi _ _ _ _ eq_refl) as [pi0 Hs].
  remember (bot_fr _ _ pi0) as pi1.
  exists pi1.
  subst ; simpl ; omega.
- dichot_Type_elt_app_exec Heq ; subst.
  + destruct (polarity A) as [Hs | Ha].
    * assert (H1 := IHpi1 _ _ _ _ (polconts _ _ Hs)).
      rewrite <- (polconts _ (l1' ++ A' :: B' :: l) Hs) in H1.
      destruct H1 as [pi1' Hs1].
      remember (tens_fr _ _ _ _ pi1' pi2) as pi.
      rewrite 2 app_comm_cons ; rewrite app_assoc.
      exists pi.
      subst ; simpl ; omega.
    * assert (polcont (l1' ++ parr A' B' :: l) A = (A :: l1') ++ parr A' B' :: l) as Hpa
        by (rewrite (polconta _ _ Ha) ; rewrite app_comm_cons ; reflexivity).
      assert (H1 := IHpi1 _ _ _ _ Hpa).
      rewrite <- app_comm_cons in H1.
      rewrite <- (polconta _ (l1' ++ A' :: B' :: l) Ha) in H1.
      destruct H1 as [pi1' Hs1].
      remember (tens_fr _ _ _ _ pi1' pi2) as pi.
      rewrite 2 app_comm_cons ; rewrite app_assoc.
      exists pi.
      subst ; simpl ; omega.
  + destruct (polarity B) as [Hs | Ha].
    * assert (H2 := IHpi2 _ _ _ _ (polconts _ _ Hs)).
      rewrite <- (polconts _ (l0 ++ A' :: B' :: l2') Hs) in H2.
      destruct H2 as [pi2' Hs2].
      remember (tens_fr _ _ _ _ pi1 pi2') as pi.
      rewrite <- app_assoc.
      exists pi.
      subst ; simpl ; omega.
    * assert (polcont (l0 ++ parr A' B' :: l2') B = (B :: l0) ++ parr A' B' :: l2') as Hpa
        by (rewrite (polconta _ _ Ha) ; rewrite app_comm_cons ; reflexivity).
      assert (H2 := IHpi2 _ _ _ _ Hpa).
      rewrite <- app_comm_cons in H2.
      rewrite <- (polconta _ (l0 ++ A' :: B' :: l2') Ha) in H2.
      destruct H2 as [pi2' Hs2].
      remember (tens_fr _ _ _ _ pi1 pi2') as pi.
      rewrite <- app_assoc.
      exists pi.
      subst ; simpl ; omega.
- destruct l1' ; inversion Heq ; subst.
  + exists pi.
    simpl ; omega.
  + assert (A :: B :: l1' ++ parr A' B' :: l2' = (A :: B :: l1') ++ parr A' B' :: l2')
      as Heql by (list_simpl ; reflexivity).
    assert (H0 := IHpi _ _ _ _ Heql).
    rewrite <- 2 app_comm_cons in H0.
    destruct H0 as [pi0 Hs].
    remember (parr_fr _ _ _ _ pi0) as pi1.
    exists pi1 ; subst.
    simpl ; omega.
- exfalso.
  destruct l1' ; inversion Heq ; subst.
  apply Forall_Type_app_inv in f.
  destruct f as [_ f].
  inversion f ; subst.
  inversion H1 as [[[Ht | Ht] | Ht] | Ht] ; try now (inversion Ht).
- destruct (polarity A) as [Hs | Ha].
  + assert (H1 := IHpi _ _ _ _ (polconts _ _ Hs)).
    rewrite <- (polconts _ (l1' ++ A' :: B' :: l2') Hs) in H1.
    destruct H1 as [pi1' Hs1].
    remember (plus_fr1 _ B _ pi1') as pi0.
    exists pi0.
    subst ; simpl ; omega.
  + assert (polcont (l1' ++ parr A' B' :: l2') A = (A :: l1') ++ parr A' B' :: l2') as Hpa
      by (rewrite (polconta _ _ Ha) ; rewrite app_comm_cons ; reflexivity).
    assert (H1 := IHpi _ _ _ _ Hpa).
    rewrite <- app_comm_cons in H1.
    rewrite <- (polconta _ (l1' ++ A' :: B' :: l2') Ha) in H1.
    destruct H1 as [pi1' Hs1].
    remember (plus_fr1 _ B _ pi1') as pi0.
    exists pi0.
    subst ; simpl ; omega.
- destruct (polarity A) as [Hs | Ha].
  + assert (H1 := IHpi _ _ _ _ (polconts _ _ Hs)).
    rewrite <- (polconts _ (l1' ++ A' :: B' :: l2') Hs) in H1.
    destruct H1 as [pi1' Hs1].
    remember (plus_fr2 _ B _ pi1') as pi0.
    exists pi0.
    subst ; simpl ; omega.
  + assert (polcont (l1' ++ parr A' B' :: l2') A = (A :: l1') ++ parr A' B' :: l2') as Hpa
      by (rewrite (polconta _ _ Ha) ; rewrite app_comm_cons ; reflexivity).
    assert (H1 := IHpi _ _ _ _ Hpa).
    rewrite <- app_comm_cons in H1.
    rewrite <- (polconta _ (l1' ++ A' :: B' :: l2') Ha) in H1.
    destruct H1 as [pi1' Hs1].
    remember (plus_fr2 _ B _ pi1') as pi0.
    exists pi0.
    subst ; simpl ; omega.
- destruct l1' ; inversion Heq ; subst.
  assert (A :: l1' ++ parr A' B' :: l2' = (A :: l1') ++ parr A' B' :: l2') as Heql1
    by (list_simpl ; reflexivity).
  assert (B :: l1' ++ parr A' B' :: l2' = (B :: l1') ++ parr A' B' :: l2') as Heql2
    by (list_simpl ; reflexivity).
  assert (H1 := IHpi1 _ _ _ _ Heql1).
  assert (H2 := IHpi2 _ _ _ _ Heql2).
  rewrite <- app_comm_cons in H1.
  rewrite <- app_comm_cons in H2.
  destruct H1 as [pi1' Hs1].
  destruct H2 as [pi2' Hs2].
  remember (with_fr _ _ _ _ pi1' pi2') as pi.
  exists pi.
  subst ; simpl ; lia.
- exfalso.
  symmetry in Heq.
  decomp_map Heq.
  inversion Heq3.
- destruct l1' ; inversion Heq ; subst.
  destruct (polarity A) as [Hs | Ha].
  + assert (H1 := IHpi _ _ _ _ (polconts _ _ Hs)).
    rewrite <- (polconts _ (l1' ++ A' :: B' :: l2') Hs) in H1.
    destruct H1 as [pi1' Hs1].
    remember (de_fr _ _ pi1') as pi0.
    exists pi0.
    subst ; simpl ; omega.
  + assert (polcont (l1' ++ parr A' B' :: l2') A = (A :: l1') ++ parr A' B' :: l2') as Hpa
      by (rewrite (polconta _ _ Ha) ; rewrite app_comm_cons ; reflexivity).
    assert (H1 := IHpi _ _ _ _ Hpa).
    rewrite <- app_comm_cons in H1.
    rewrite <- (polconta _ (l1' ++ A' :: B' :: l2') Ha) in H1.
    destruct H1 as [pi1' Hs1].
    remember (de_fr _ _ pi1') as pi0.
    exists pi0.
    subst ; simpl ; omega.
- destruct l1' ; inversion Heq ; subst.
  destruct (IHpi _ _ _ _ eq_refl) as [pi0 Hs].
  remember (wk_fr A _ _ pi0) as pi1.
  exists pi1.
  subst ; simpl ; omega.
- destruct l1' ; inversion Heq ; subst.
  assert (wn A :: wn A :: l1' ++ parr A' B' :: l2' = (wn A :: wn A :: l1') ++ parr A' B' :: l2')
    as Heql by (list_simpl ; reflexivity).
  assert (H0 := IHpi _ _ _ _ Heql).
  rewrite <- 2 app_comm_cons in H0.
  destruct H0 as [pi0 Hs].
  remember (co_fr _ _ _ pi0) as pi1.
  exists pi1 ; subst.
  simpl ; omega.
Qed.

Lemma with_rev_f : forall l Pi (pi : llfoc l Pi),
  forall A B l1 l2, l = l1 ++ awith A B :: l2 ->
    { pi' : llfoc (l1 ++ A :: l2) Pi & fpsize pi' < fpsize pi }
  * { pi' : llfoc (l1 ++ B :: l2) Pi & fpsize pi' < fpsize pi }.
Proof with myeeasy.
intros l Pi pi.
induction pi ; intros A' B' l1' l2' Heq ; subst.
- exfalso.
  destruct l1' ; inversion Heq.
  destruct l1' ; inversion H1.
- assert (HP := p).
  simpl ; apply Permutation_Type_vs_elt_inv in p.
  destruct p as ((l3 & l4) & Heq) ; subst.
  simpl in IHpi ; simpl in HP ; simpl.
  destruct (IHpi _ _ _ _ eq_refl) as [[pi01 Hs1] [pi02 Hs2]].
  simpl in HP ; apply Permutation_Type_app_inv in HP.
  assert (HP2 := HP).
  apply (Permutation_Type_elt B') in HP2.
  apply (Permutation_Type_elt A') in HP.
  remember (ex_fr _ _ _ pi01 HP) as pi1.
  remember (ex_fr _ _ _ pi02 HP2) as pi2.
  split ; [ exists pi1 | exists pi2 ] ; subst ; simpl ; omega.
- destruct l1' ; inversion Heq ; subst.
  + exfalso.
    clear IHpi ; apply sync_focus in pi.
    inversion pi.
  + destruct (IHpi _ _ _ _ eq_refl) as [[pi01 Hs1] [pi02 Hs2]].
    remember (foc_fr _ _ pi01) as pi1.
    remember (foc_fr _ _ pi02) as pi2.
    split ; [ exists pi1 | exists pi2 ] ; subst ; simpl ; omega.
- exfalso.
  destruct l1' ; inversion Heq.
- destruct l1' ; inversion Heq ; subst.
  destruct (IHpi _ _ _ _ eq_refl) as [[pi01 Hs1] [pi02 Hs2]].
  remember (bot_fr _ _ pi01) as pi1.
  remember (bot_fr _ _ pi02) as pi2.
  split ; [ exists pi1 | exists pi2 ] ; subst ; simpl ; omega.
- dichot_Type_elt_app_exec Heq ; subst.
  + destruct (polarity A) as [Hs | Ha].
    * assert (H1 := IHpi1 _ _ _ _ (polconts _ _ Hs)).
      rewrite <- (polconts _ (l1' ++ A' :: l) Hs) in H1.
      rewrite <- (polconts _ (l1' ++ B' :: l) Hs) in H1.
      destruct H1 as [[pi1' Hs1] [pi1'' Hs2]].
      remember (tens_fr _ _ _ _ pi1' pi2) as pi01.
      remember (tens_fr _ _ _ _ pi1'' pi2) as pi02.
      rewrite ? app_comm_cons ; rewrite 2 app_assoc.
      split ; [ exists pi01 | exists pi02 ] ; subst ; simpl ; omega.
    * assert (polcont (l1' ++ awith A' B' :: l) A = (A :: l1') ++ awith A' B' :: l) as Hpa
        by (rewrite (polconta _ _ Ha) ; rewrite app_comm_cons ; reflexivity).
      assert (H1 := IHpi1 _ _ _ _ Hpa).
      rewrite <- 2 app_comm_cons in H1.
      rewrite <- (polconta _ (l1' ++ A' :: l) Ha) in H1.
      rewrite <- (polconta _ (l1' ++ B' :: l) Ha) in H1.
      destruct H1 as [[pi1' Hs1] [pi2' Hs2]].
      remember (tens_fr _ _ _ _ pi1' pi2) as pi01.
      remember (tens_fr _ _ _ _ pi2' pi2) as pi02.
      rewrite ? app_comm_cons ; rewrite 2 app_assoc.
      split ; [ exists pi01 | exists pi02 ] ; subst ; simpl ; omega.
  + destruct (polarity B) as [Hs | Ha].
    * assert (H2 := IHpi2 _ _ _ _ (polconts _ _ Hs)).
      rewrite <- (polconts _ (l0 ++ A' :: l2') Hs) in H2.
      rewrite <- (polconts _ (l0 ++ B' :: l2') Hs) in H2.
      destruct H2 as [[pi1' Hs1] [pi1'' Hs2]].
      remember (tens_fr _ _ _ _ pi1 pi1') as pi01.
      remember (tens_fr _ _ _ _ pi1 pi1'') as pi02.
      rewrite <- 2 app_assoc.
      split ; [ exists pi01 | exists pi02 ] ; subst ; simpl ; omega.
    * assert (polcont (l0 ++ awith A' B' :: l2') B = (B :: l0) ++ awith A' B' :: l2') as Hpa
        by (rewrite (polconta _ _ Ha) ; rewrite app_comm_cons ; reflexivity).
      assert (H2 := IHpi2 _ _ _ _ Hpa).
      rewrite <- 2 app_comm_cons in H2.
      rewrite <- (polconta _ (l0 ++ A' :: l2') Ha) in H2.
      rewrite <- (polconta _ (l0 ++ B' :: l2') Ha) in H2.
      destruct H2 as [[pi1' Hs1] [pi1'' Hs2]].
      remember (tens_fr _ _ _ _ pi1 pi1') as pi01.
      remember (tens_fr _ _ _ _ pi1 pi1'') as pi02.
      rewrite <- 2 app_assoc.
      split ; [ exists pi01 | exists pi02 ] ; subst ; simpl ; omega.
- destruct l1' ; inversion Heq ; subst.
  assert (A :: B :: l1' ++ awith A' B' :: l2' = (A :: B :: l1') ++ awith A' B' :: l2')
    as Heql by (list_simpl ; reflexivity).
  assert (H0 := IHpi _ _ _ _ Heql).
  rewrite <- ? app_comm_cons in H0.
  destruct H0 as [[pi1' Hs1] [pi1'' Hs2]].
  remember (parr_fr _ _ _ _ pi1') as pi01.
  remember (parr_fr _ _ _ _ pi1'') as pi02.
  split ; [ exists pi01 | exists pi02 ] ; subst ; simpl ; omega.
- exfalso.
  destruct l1' ; inversion Heq ; subst.
  apply Forall_Type_app_inv in f.
  destruct f as [_ f].
  inversion f ; subst.
  inversion H1 as [[[Ht | Ht] | Ht] | Ht] ; try now (inversion Ht).
- destruct (polarity A) as [Hs | Ha].
  + assert (H1 := IHpi _ _ _ _ (polconts _ _ Hs)).
    rewrite <- (polconts _ (l1' ++ A' :: l2') Hs) in H1.
    rewrite <- (polconts _ (l1' ++ B' :: l2') Hs) in H1.
    destruct H1 as [[pi1' Hs1] [pi1'' Hs2]].
    remember (plus_fr1 _ B _ pi1') as pi01.
    remember (plus_fr1 _ B _ pi1'') as pi02.
    split ; [ exists pi01 | exists pi02 ] ; subst ; simpl ; omega.
  + assert (polcont (l1' ++ awith A' B' :: l2') A = (A :: l1') ++ awith A' B' :: l2') as Hpa
      by (rewrite (polconta _ _ Ha) ; rewrite app_comm_cons ; reflexivity).
    assert (H1 := IHpi _ _ _ _ Hpa).
    rewrite <- 2 app_comm_cons in H1.
    rewrite <- (polconta _ (l1' ++ A' :: l2') Ha) in H1.
    rewrite <- (polconta _ (l1' ++ B' :: l2') Ha) in H1.
    destruct H1 as [[pi1' Hs1] [pi1'' Hs2]].
    remember (plus_fr1 _ B _ pi1') as pi01.
    remember (plus_fr1 _ B _ pi1'') as pi02.
    split ; [ exists pi01 | exists pi02 ] ; subst ; simpl ; omega.
- destruct (polarity A) as [Hs | Ha].
  + assert (H1 := IHpi _ _ _ _ (polconts _ _ Hs)).
    rewrite <- (polconts _ (l1' ++ A' :: l2') Hs) in H1.
    rewrite <- (polconts _ (l1' ++ B' :: l2') Hs) in H1.
    destruct H1 as [[pi1' Hs1] [pi1'' Hs2]].
    remember (plus_fr2 _ B _ pi1') as pi01.
    remember (plus_fr2 _ B _ pi1'') as pi02.
    split ; [ exists pi01 | exists pi02 ] ; subst ; simpl ; omega.
  + assert (polcont (l1' ++ awith A' B' :: l2') A = (A :: l1') ++ awith A' B' :: l2') as Hpa
      by (rewrite (polconta _ _ Ha) ; rewrite app_comm_cons ; reflexivity).
    assert (H1 := IHpi _ _ _ _ Hpa).
    rewrite <- 2 app_comm_cons in H1.
    rewrite <- (polconta _ (l1' ++ A' :: l2') Ha) in H1.
    rewrite <- (polconta _ (l1' ++ B' :: l2') Ha) in H1.
    destruct H1 as [[pi1' Hs1] [pi1'' Hs2]].
    remember (plus_fr2 _ B _ pi1') as pi01.
    remember (plus_fr2 _ B _ pi1'') as pi02.
    split ; [ exists pi01 | exists pi02 ] ; subst ; simpl ; omega.
- destruct l1' ; inversion Heq ; subst.
  + split ; [ exists pi1 | exists pi2 ] ; subst ; simpl ; lia.
  + assert (A :: l1' ++ awith A' B' :: l2' = (A :: l1') ++ awith A' B' :: l2') as Heql1
      by (list_simpl ; reflexivity).
    assert (B :: l1' ++ awith A' B' :: l2' = (B :: l1') ++ awith A' B' :: l2') as Heql2
      by (list_simpl ; reflexivity).
    assert (H1 := IHpi1 _ _ _ _ Heql1).
    assert (H2 := IHpi2 _ _ _ _ Heql2).
    rewrite <- 2 app_comm_cons in H1.
    rewrite <- 2 app_comm_cons in H2.
    destruct H1 as [[pi1' Hs1] [pi1'' Hs1']].
    destruct H2 as [[pi2' Hs2] [pi2'' Hs2']].
    remember (with_fr _ _ _ _ pi1' pi2') as pi01.
    remember (with_fr _ _ _ _ pi1'' pi2'') as pi02.
    split ; [ exists pi01 | exists pi02 ] ; subst ; simpl ; lia.
- exfalso.
  symmetry in Heq.
  decomp_map Heq.
  inversion Heq3.
- destruct l1' ; inversion Heq ; subst.
  destruct (polarity A) as [Hs | Ha].
  + assert (H1 := IHpi _ _ _ _ (polconts _ _ Hs)).
    rewrite <- (polconts _ (l1' ++ A' :: l2') Hs) in H1.
    rewrite <- (polconts _ (l1' ++ B' :: l2') Hs) in H1.
    destruct H1 as [[pi1' Hs1] [pi1'' Hs2]].
    remember (de_fr _ _ pi1') as pi01.
    remember (de_fr _ _ pi1'') as pi02.
    split ; [ exists pi01 | exists pi02 ] ; subst ; simpl ; omega.
  + assert (polcont (l1' ++ awith A' B' :: l2') A = (A :: l1') ++ awith A' B' :: l2') as Hpa
      by (rewrite (polconta _ _ Ha) ; rewrite app_comm_cons ; reflexivity).
    assert (H1 := IHpi _ _ _ _ Hpa).
    rewrite <- 2 app_comm_cons in H1.
    rewrite <- (polconta _ (l1' ++ A' :: l2') Ha) in H1.
    rewrite <- (polconta _ (l1' ++ B' :: l2') Ha) in H1.
    destruct H1 as [[pi1' Hs1] [pi1'' Hs2]].
    remember (de_fr _ _ pi1') as pi01.
    remember (de_fr _ _ pi1'') as pi02.
    split ; [ exists pi01 | exists pi02 ] ; subst ; simpl ; omega.
- destruct l1' ; inversion Heq ; subst.
  destruct (IHpi _ _ _ _ eq_refl) as [[pi1' Hs1] [pi1'' Hs2]].
  remember (wk_fr A _ _ pi1') as pi01.
  remember (wk_fr A _ _ pi1'') as pi02.
  split ; [ exists pi01 | exists pi02 ] ; subst ; simpl ; omega.
- destruct l1' ; inversion Heq ; subst.
  assert (wn A :: wn A :: l1' ++ awith A' B' :: l2' = (wn A :: wn A :: l1') ++ awith A' B' :: l2')
    as Heql by (list_simpl ; reflexivity).
  assert (H0 := IHpi _ _ _ _ Heql).
  rewrite <- ? app_comm_cons in H0.
  destruct H0 as [[pi1' Hs1] [pi1'' Hs2]].
  remember (co_fr _ _ _ pi1') as pi01.
  remember (co_fr _ _ _ pi1'') as pi02.
  split ; [ exists pi01 | exists pi02 ] ; subst ; simpl ; omega.
Qed.

Lemma with_rev1_f : forall l Pi (pi : llfoc l Pi),
  forall A B l1 l2, l = l1 ++ awith A B :: l2 ->
    { pi' : llfoc (l1 ++ A :: l2) Pi & fpsize pi' < fpsize pi }.
Proof.
intros l Pi pi A B l1 l2 Heq.
eapply with_rev_f in Heq.
apply Heq.
Qed.

Lemma with_rev2_f : forall l Pi (pi : llfoc l Pi),
  forall A B l1 l2, l = l1 ++ awith A B :: l2 ->
    { pi' : llfoc (l1 ++ B :: l2) Pi & fpsize pi' < fpsize pi }.
Proof.
intros l Pi pi A B l1 l2 Heq.
eapply with_rev_f in Heq.
apply Heq.
Qed.

Lemma llfoc_to_ll : forall l Pi s, llfoc l Pi s ->
   (Pi = None -> exists s', ll_ll l s')
/\ (forall C, Pi = Some C -> exists s', ll_ll (C :: l) s').
Proof with (try PCperm_solve) ; myeeasy.
intros l Pi s pi ; induction pi ;
  (split ; [ intros HN ; inversion HN ; subst
           | intros D HD ; inversion HD ; subst ]) ;
  try (destruct IHpi as [IHpiN IHpiS]) ;
  try (destruct IHpi1 as [IHpi1N IHpi1S]) ;
  try (destruct IHpi2 as [IHpi2N IHpi2S]) ;
  try (destruct (IHpiS _ (eq_refl _)) as [s0' pi0']) ;
  try (destruct (IHpi1S _ (eq_refl _)) as [s1' pi1']) ;
  try (destruct (IHpi2S _ (eq_refl _)) as [s2' pi2']) ;
  try (destruct (IHpiN (eq_refl _)) as [s0' pi0']) ;
  try (destruct (IHpi1N (eq_refl _)) as [s1' pi1']) ;
  try (destruct (IHpi2N (eq_refl _)) as [s2' pi2']) ;
  try (now (eexists ; constructor ; myeeasy)) ;
  try (now (eexists ; eapply ex_r ;
             [ | apply perm_swap ] ; constructor ; myeeasy))...
- eexists ; eapply ex_r.
  + eassumption.
  + idtac...
- eexists ; eapply ex_r.
  + eassumption.
  + idtac...
- eexists...
- destruct (polarity A) as [HsA | HaA].
  + rewrite_all (polconts A l1 HsA).
    rewrite_all (polfocs A HsA).
    destruct (IHpi1S _ (eq_refl _)) as [s1' pi1'].
    destruct (polarity B) as [HsB | HaB].
    * rewrite_all (polconts B l2 HsB).
      rewrite_all (polfocs B HsB).
      destruct (IHpi2S _ (eq_refl _)) as [s2' pi2'].
      eexists ; eapply ex_r ; [ apply tens_r | ].
      -- eapply pi1'.
      -- eapply pi2'.
      -- idtac...
    * rewrite_all (polconta B l2 HaB).
      rewrite_all (polfoca B HaB).
      destruct (IHpi2N (eq_refl _)) as [s2' pi2'].
      eexists ; eapply ex_r ; [ apply tens_r | ].
      -- eapply pi1'.
      -- eapply pi2'.
      -- idtac...
  + rewrite_all (polconta A l1 HaA).
    rewrite_all (polfoca A HaA).
    destruct (IHpi1N (eq_refl _)) as [s1' pi1'].
    destruct (polarity B) as [HsB | HaB].
    * rewrite_all (polconts B l2 HsB).
      rewrite_all (polfocs B HsB).
      destruct (IHpi2S _ (eq_refl _)) as [s2' pi2'].
      eexists ; eapply ex_r ; [ apply tens_r | ].
      -- eapply pi1'.
      -- eapply pi2'.
      -- idtac...
    * rewrite_all (polconta B l2 HaB).
      rewrite_all (polfoca B HaB).
      destruct (IHpi2N (eq_refl _)) as [s2' pi2'].
      eexists ; eapply ex_r ; [ apply tens_r | ].
      -- eapply pi1'.
      -- eapply pi2'.
      -- idtac...
- eexists ; eapply ex_r ; [ apply parr_r | apply perm_swap ].
  eapply ex_r.
  + eassumption.
  + idtac...
- destruct (polarity A) as [Hs | Ha].
  + rewrite_all (polconts A l Hs).
    rewrite_all (polfocs A Hs).
    destruct (IHpiS _ (eq_refl _)) as [s0' pi0'].
    eexists ; apply plus_r1...
  + rewrite_all (polconta A l Ha).
    rewrite_all (polfoca A Ha).
    destruct (IHpiN (eq_refl _)) as [s0' pi0'].
    eexists ; apply plus_r1...
- destruct (polarity A) as [Hs | Ha].
  + rewrite_all (polconts A l Hs).
    rewrite_all (polfocs A Hs).
    destruct (IHpiS _ (eq_refl _)) as [s0' pi0'].
    eexists ; apply plus_r2...
  + rewrite_all (polconta A l Ha).
    rewrite_all (polfoca A Ha).
    destruct (IHpiN (eq_refl _)) as [s0' pi0'].
    eexists ; apply plus_r2...
- eexists ; eapply ex_r ; [ apply with_r | apply perm_swap ].
  + eapply ex_r ; [ apply pi1' | apply perm_swap ].
  + eapply ex_r ; [ apply pi2' | apply perm_swap ].
- destruct (polarity A) as [Hs | Ha].
  + rewrite_all (polconts A l Hs).
    rewrite_all (polfocs A Hs).
    destruct (IHpiS _ (eq_refl _)) as [s0' pi0'].
    eexists ; apply de_r...
  + rewrite_all (polconta A l Ha).
    rewrite_all (polfoca A Ha).
    destruct (IHpiN (eq_refl _)) as [s0' pi0'].
    eexists ; apply de_r...
- eexists ; apply co_std_r...
- eexists ; eapply ex_r ; [ apply co_std_r | apply perm_swap ].
  eapply ex_r.
  + eassumption.
  + idtac...
Qed.


(** ** The strongly focused system [llFoc] *)

Definition Foc x :=
  sformula x \/ (exists X, x = covar X) \/ (exists y, x = wn y).

Lemma Foc_dec : forall x, {Foc x} + {~ Foc x}.
Proof with myeeasy.
induction x ;
  try (now (left ; left ; constructor)) ;
  try (now (left ; right ; left ; eexists ; reflexivity)) ;
  try (now (left ; right ; right ; eexists ; reflexivity)).
- right.
  intros [H | [[X H] | [X H]]] ; inversion H.
- right.
  intros [H | [[X H] | [X H]]] ; inversion H.
- right.
  intros [H | [[X H] | [X H]]] ; inversion H.
- right.
  intros [H | [[X H] | [X H]]] ; inversion H.
Qed.

Lemma Focl_dec : forall l, {Forall Foc l} + {~ Forall Foc l}.
Proof with myeasy.
induction l.
- left ; constructor.
- destruct (Foc_dec a).
  + destruct IHl.
    * left ; constructor...
    * right ; intros H.
      inversion H ; subst.
      apply n in H3...
  + right ; intros H.
    inversion H ; subst.
    apply n in H2...
Qed.

Lemma not_Foc : forall x, ~ Foc x ->
  x = bot \/ (exists y z, x = parr y z) \/ x = top \/ (exists y z, x = awith y z).
Proof with myeasy.
destruct x ; intros HnF ;
  try (now (exfalso ; apply HnF ; left ; constructor)) ;
  try (now (exfalso ; apply HnF ; right ; left ; eexists ; reflexivity)) ;
  try (now (exfalso ; apply HnF ; right ; right ; eexists ; reflexivity)).
- left...
- right ; left ; eexists ; eexists...
- right ; right ; left...
- right ; right ; right ; eexists ; eexists...
Qed.

Lemma not_Focl : forall l, ~ Forall Foc l -> exists l1 l2 A,
  l = l1 ++ A :: l2 /\    (A = bot \/ (exists B C, A = parr B C)
                        \/ A = top \/ (exists B C, A = awith B C)).
Proof with myeeasy.
induction l ; intros HnF.
- exfalso.
  apply HnF.
  constructor.
- destruct (Foc_dec a).
  + destruct (Focl_dec l).
    * exfalso.
      apply HnF.
      constructor...
    * apply IHl in n.
      destruct n as (l1 & l2 & A & Heq & HA) ; subst.
      rewrite app_comm_cons.
      eexists ; eexists ; eexists ; split...
  + apply not_Foc in n.
    exists nil ; exists l ; exists a ; split...
Qed.

Inductive llFoc : list formula -> option formula -> Prop :=
| ax_Fr : forall X, llFoc (covar X :: nil) (Some (var X))
| ex_Fr : forall l1 l2 Pi, llFoc l1 Pi -> Permutation l1 l2 ->
                           llFoc l2 Pi
| foc_Fr : forall A l, llFoc l (Some A) ->
                       llFoc (A :: l) None
| one_Fr : llFoc nil (Some one)
| bot_Fr : forall l, llFoc l None -> llFoc (bot :: l) None
| tens_Fr : forall A B l1 l2,
                    llFoc (polcont l1 A) (polfoc A) ->
                    llFoc (polcont l2 B) (polfoc B) ->
                    Forall Foc l1 -> Forall Foc l2 ->
                    llFoc (l1 ++ l2) (Some (tens A B))
| parr_Fr : forall A B l, llFoc (A :: B :: l) None ->
                          llFoc (parr A B :: l) None
| top_Fr : forall l, Forall tFoc l -> llFoc (top :: l) None
| plus_Fr1 : forall A B l, llFoc (polcont l A) (polfoc A) ->
                           Forall Foc l ->
                           llFoc l (Some (aplus A B))
| plus_Fr2 : forall A B l, llFoc (polcont l A) (polfoc A) ->
                           Forall Foc l ->
                           llFoc l (Some (aplus B A))
| with_Fr : forall A B l, llFoc (A :: l) None ->
                          llFoc (B :: l) None ->
                          llFoc (awith A B :: l) None
| oc_Fr : forall A l, llFoc (A :: map wn l) None ->
                      llFoc (map wn l) (Some (oc A))
| de_Fr : forall A l, llFoc (polcont l A) (polfoc A) ->
                      llFoc (wn A :: l) None
| wk_Fr : forall A l, llFoc l None -> llFoc (wn A :: l) None
| co_Fr : forall A l, llFoc (wn A :: wn A :: l) None ->
                      llFoc (wn A :: l) None.

Instance llFoc_perm {Pi} : Proper ((@Permutation _) ==> Basics.impl) (fun l => llFoc l Pi).
Proof.
intros l1 l2 HP pi.
eapply ex_Fr ; eassumption.
Qed.

Lemma top_gen_Fr : forall l, llFoc (top :: l) None.
Proof with myeeasy.
intros l.
remember (list_sum (map fsize l)) as n.
revert l Heqn ; induction n using (well_founded_induction lt_wf) ;
  intros l Heqn ; subst.
destruct (tFocl_dec l).
- apply top_Fr...
- apply not_tFocl in n.
  destruct n as (l1 & l2 & A & Heq & [Hb | [(B & C & Hp) | (B & C & Hw)]]) ; subst.
  + rewrite app_comm_cons.
    eapply ex_Fr ; [ apply bot_Fr | apply Permutation_middle ].
    list_simpl ; eapply H...
    rewrite <- Permutation_middle.
    simpl ; omega.
  + rewrite app_comm_cons.
    eapply ex_Fr ; [ apply parr_Fr | apply Permutation_middle ].
    list_simpl ; eapply ex_Fr ;
    [ eapply H
    | etransitivity ; [ apply perm_swap
                      | apply (Permutation_cons (eq_refl _)) ;
                        etransitivity ; [ apply perm_swap |  ]]]...
    rewrite <- Permutation_middle.
    simpl ; omega.
  + rewrite app_comm_cons.
    eapply ex_Fr ; [ apply with_Fr | apply Permutation_middle ].
    * list_simpl ; eapply ex_Fr ;
        [ eapply H
        | etransitivity ; [ apply perm_swap | apply Permutation_cons ; reflexivity ]]...
      rewrite <- Permutation_middle.
      simpl ; omega.
    * list_simpl ; eapply ex_Fr ;
        [ eapply H
        | etransitivity ; [ apply perm_swap | apply Permutation_cons ; reflexivity ]]...
      rewrite <- Permutation_middle.
      simpl ; omega.
Qed.

Lemma sync_focus_F : forall l A, llFoc l (Some A) -> sformula A.
Proof.
intros l A pi.
remember (Some A) as Pi ; revert HeqPi ; induction pi ;
  intros HeqPi ; inversion HeqPi ; subst ;
  try (now constructor) ;
  try apply IHpi ;
  try assumption.
Qed.

Lemma Foc_context : forall l A, llFoc l (Some A) -> Forall Foc l.
Proof with myeeasy.
intros l A pi.
remember (Some A) as Pi.
revert A HeqPi ; induction pi ; intros P HeqPi ; subst ;
  try (now inversion HeqPi).
- constructor ; [ | constructor ].
  right ; left.
  eexists...
- rewrite <- H.
  eapply IHpi...
- apply Forall_app...
- clear ; remember (map wn l) as l0.
  revert l Heql0 ; induction l0 ; intros l Heql0 ;
    destruct l ; inversion Heql0 ; subst ; constructor.
  + right ; right ; eexists...
  + eapply IHl0...
Qed.

Lemma llFoc_foc_is_llFoc_foc : forall l A, llFoc l (Some A) ->
  llFoc (polcont l A) (polfoc A).
Proof.
intros l A pi.
assert (Hs := sync_focus_F _ _ pi).
rewrite (polconts _ _ Hs).
rewrite (polfocs _ Hs).
apply pi.
Qed.

Lemma incl_Foc : forall l l0 lw lw', llFoc l None ->
  Permutation l (map wn lw ++ l0) -> incl lw lw' ->
    llFoc (map wn lw' ++ l0) None.
Proof with myeeasy.
intros l l0 lw ; revert l l0 ; induction lw ; intros l l0 lw' pi HP Hsub.
- clear Hsub ; induction lw'.
  + eapply ex_Fr...
  + apply wk_Fr...
- destruct (incl_cons_inv _ _ _ Hsub) as [Hin Hi].
  eapply IHlw in pi ; [ | | apply Hi ].
  + apply in_split in Hin.
    destruct Hin as (l1 & l2 & Heq) ; subst.
    eapply ex_Fr ; [ apply co_Fr | ].
    * eapply ex_Fr ; [ apply pi | ].
      rewrite map_app ; simpl.
      rewrite <- app_assoc.
      rewrite <- app_comm_cons.
      symmetry ; apply Permutation_cons_app.
      rewrite app_assoc.
      apply Permutation_cons_app.
      reflexivity.
    * rewrite <- app_assoc.
      rewrite map_app ; simpl.
      rewrite <- app_assoc.
      rewrite <- app_comm_cons.
      apply Permutation_cons_app.
      reflexivity.
  + etransitivity ; [ apply HP | ].
    simpl ; apply Permutation_middle.
Qed.

Theorem llfoc_to_llFoc : forall l s,
    (llfoc l None s -> llFoc l None)
 /\ (forall C, llfoc l (Some C) s -> Forall Foc l ->
       exists lw lw' l0, Permutation l (map wn lw ++ l0) /\ incl lw' lw
                      /\ llFoc (map wn lw' ++ l0) (Some C))
 /\ (forall C, llfoc l (Some C) s -> ~ Forall Foc l ->
      (llFoc (C :: l) None) /\ llFoc (wn C :: l) None).
Proof with myeeasy.
intros l s ; revert l ;
  induction s using (well_founded_induction lt_wf) ; intros l ; nsplit 3 ;
    [ intros pi ; inversion pi | intros C pi HF ; inversion pi
    | intros C pi HnF ] ; subst.
(* first conjunct *)
- apply H in H0...
  eapply ex_Fr...
- destruct (Focl_dec l0).
  + eapply (proj1 (proj2 (H _ _ _))) in H0...
    destruct H0 as (lw & lw' & l1 & HP & Hs & IH).
    apply (Permutation_cons_app _ _ A) in HP.
    symmetry in HP.
    eapply ex_Fr...
    eapply incl_Foc...
    eapply ex_Fr ; [ apply foc_Fr | ]...
    apply Permutation_cons_app...
  + eapply (proj2 (proj2 (H _ _ _))) in H0...
    apply H0.
- apply H in H0...
  apply bot_Fr...
- apply H in H0...
  apply parr_Fr...
- apply top_Fr...
- apply H in H0...
  apply H in H1...
  apply with_Fr...
- destruct (polarity A) as [Hs | Ha].
  + rewrite (polconts _ _ Hs) in H0.
    rewrite (polfocs _ Hs) in H0.
    destruct (Focl_dec l0).
    * eapply (proj1 (proj2 (H _ _ _))) in H0...
      destruct H0 as (lw & lw' & l1 & HP & Hs' & IH).
      apply (Permutation_cons_app _ _ (wn A)) in HP.
      symmetry in HP.
      eapply ex_Fr...
      eapply incl_Foc...
      rewrite <- (polconts A (map wn lw' ++ l1) Hs) in IH.
      rewrite <- (polfocs A Hs) in IH.
      eapply ex_Fr ; [ apply de_Fr | ]...
      apply Permutation_cons_app...
    * eapply (proj2 (proj2 (H _ _ _))) in H0...
      apply H0.
  + rewrite (polconta _ _ Ha) in H0.
    rewrite (polfoca _ Ha) in H0.
    apply H in H0...
    rewrite <- (polconta A l0 Ha) in H0.
    rewrite <- (polfoca A Ha) in H0.
    apply de_Fr...
- apply H in H0...
  apply wk_Fr...
- apply H in H0...
  apply co_Fr...
(* second conjunct *) 
- exists nil ; exists nil ; exists (covar X :: nil) ; nsplit 3...
  + apply incl_nil.
  + list_simpl.
    apply ax_Fr.
- eapply (proj1 (proj2 (H _ _ _))) in H0...
  + destruct H0 as (lw & lw' & l0 & HP & Hs & IH).
    eexists ; eexists ; eexists ; nsplit 3...
    rewrite <- H1...
  + unfold Foc ; rewrite H1...
- exists nil ; exists nil ; exists nil ; nsplit 3...
  + apply incl_nil.
  + list_simpl.
    apply one_Fr.
- inversion HF ; subst.
  destruct H3 as [H' | [[X H'] | [X H']]] ; inversion H'.
- destruct (Forall_app_inv _ _ _ HF) as [HF1 HF2].
  destruct (polarity A) as [HsA | HaA] ; destruct (polarity B) as [HsB | HaB].
  + rewrite (polconts _ _ HsA) in H1.
    rewrite (polfocs _ HsA) in H1.
    rewrite (polconts _ _ HsB) in H3.
    rewrite (polfocs _ HsB) in H3.
    eapply (proj1 (proj2 (H _ _ _))) in H1...
    destruct H1 as (lw1 & lw1' & l01 & HP1 & Hs1 & pi1).
    eapply (proj1 (proj2 (H _ _ _))) in H3...
    destruct H3 as (lw2 & lw2' & l02 & HP2 & Hs2 & pi2).
    exists (lw1 ++ lw2) ; exists (lw1' ++ lw2') ; exists (l01 ++ l02) ; nsplit 3.
    * etransitivity ; [ apply (Permutation_app HP1 HP2) | ].
      list_simpl.
      apply Permutation_app_head.
      rewrite ? app_assoc.
      apply Permutation_app_tail.
      apply Permutation_app_comm.
    * apply incl_app_app...
    * eapply ex_Fr ; [ apply tens_Fr | ].
      -- rewrite (polconts _ _ HsA).
         rewrite (polfocs _ HsA)...
      -- rewrite (polconts _ _ HsB).
         rewrite (polfocs _ HsB)...
      -- apply Foc_context in pi1...
      -- apply Foc_context in pi2...
      -- list_simpl.
         apply Permutation_app_head.
         rewrite 2 app_assoc.
         apply Permutation_app_tail.
         apply Permutation_app_comm.
  + rewrite (polconts _ _ HsA) in H1.
    rewrite (polfocs _ HsA) in H1.
    rewrite (polconta _ _ HaB) in H3.
    rewrite (polfoca _ HaB) in H3.
    eapply (proj1 (proj2 (H _ _ _))) in H1...
    destruct H1 as (lw1 & lw1' & l01 & HP1 & Hs1 & pi1).
    eapply (proj1 (H _ _ _)) in H3.
    exists lw1 ; exists lw1' ; exists (l01 ++ l2) ; nsplit 3...
    * etransitivity ; [ apply (Permutation_app_tail _ HP1) | ].
      rewrite <- app_assoc...
    * eapply ex_Fr ; [ apply tens_Fr | ].
      -- rewrite (polconts _ _ HsA).
         rewrite (polfocs _ HsA)...
      -- rewrite (polconta _ _ HaB).
         rewrite (polfoca _ HaB)...
      -- apply Foc_context in pi1...
      -- assumption.
      -- rewrite <- app_assoc...
  + rewrite (polconta _ _ HaA) in H1.
    rewrite (polfoca _ HaA) in H1.
    rewrite (polconts _ _ HsB) in H3.
    rewrite (polfocs _ HsB) in H3.
    eapply (proj1 (H _ _ _)) in H1.
    eapply (proj1 (proj2 (H _ _ _))) in H3...
    destruct H3 as (lw2 & lw2' & l02 & HP2 & Hs2 & pi2).
    exists lw2 ; exists lw2' ; exists (l1 ++ l02) ; nsplit 3...
    * etransitivity ; [ apply (Permutation_app_head _ HP2) | ].
      rewrite 2 app_assoc...
      apply Permutation_app_tail.
      apply Permutation_app_comm.
    * eapply ex_Fr ; [ apply tens_Fr | ].
      -- rewrite (polconta _ _ HaA).
         rewrite (polfoca _ HaA)...
      -- rewrite (polconts _ _ HsB).
         rewrite (polfocs _ HsB)...
      -- assumption.
      -- apply Foc_context in pi2...
      -- rewrite 2 app_assoc...
         apply Permutation_app_tail.
         apply Permutation_app_comm.
  + rewrite (polconta _ _ HaA) in H1.
    rewrite (polfoca _ HaA) in H1.
    rewrite (polconta _ _ HaB) in H3.
    rewrite (polfoca _ HaB) in H3.
    eapply (proj1 (H _ _ _)) in H1.
    eapply (proj1 (H _ _ _)) in H3.
    exists nil ; exists nil ; exists (l1 ++ l2) ; nsplit 3...
    * apply incl_nil.
    * eapply ex_Fr ; [ apply tens_Fr | ].
      -- rewrite (polconta _ _ HaA).
         rewrite (polfoca _ HaA)...
      -- rewrite (polconta _ _ HaB).
         rewrite (polfoca _ HaB)...
      -- assumption.
      -- assumption.
      -- reflexivity.
- inversion HF ; subst.
  destruct H3 as [H' | [[X H'] | [X H']]] ; inversion H'.
- inversion HF ; subst.
  destruct H4 as [H' | [[X H'] | [X H']]] ; inversion H'.
- destruct (polarity A) as [HsA | HaA].
  + rewrite (polconts _ _ HsA) in H2.
    rewrite (polfocs _ HsA) in H2.
    eapply (proj1 (proj2 (H _ _ _))) in H2...
    destruct H2 as (lw & lw' & l0 & HP & Hs & IH).
    eexists ; eexists ; eexists ; nsplit 3...
    apply plus_Fr1.
    * rewrite (polconts _ _ HsA).
      rewrite (polfocs _ HsA)...
    * apply Foc_context in IH...
  + rewrite (polconta _ _ HaA) in H2.
    rewrite (polfoca _ HaA) in H2.
    apply H in H2...
    exists nil ; exists nil ; exists l ; nsplit 3...
    * apply incl_nil.
    * list_simpl.
      apply plus_Fr1...
      rewrite (polconta _ _ HaA).
      rewrite (polfoca _ HaA)...
- destruct (polarity A) as [HsA | HaA].
  + rewrite (polconts _ _ HsA) in H2.
    rewrite (polfocs _ HsA) in H2.
    eapply (proj1 (proj2 (H _ _ _))) in H2...
    destruct H2 as (lw & lw' & l0 & HP & Hs & IH).
    eexists ; eexists ; eexists ; nsplit 3...
    apply plus_Fr2.
    * rewrite (polconts _ _ HsA).
      rewrite (polfocs _ HsA)...
    * apply Foc_context in IH...
  + rewrite (polconta _ _ HaA) in H2.
    rewrite (polfoca _ HaA) in H2.
    apply H in H2...
    exists nil ; exists nil ; exists l ; nsplit 3...
    * apply incl_nil.
    * list_simpl.
      apply plus_Fr2...
      rewrite (polconta _ _ HaA).
      rewrite (polfoca _ HaA)...
- inversion HF ; subst.
  destruct H4 as [H' | [[X H'] | [X H']]] ; inversion H'.
- apply H in H2...
  exists nil ; exists nil ; exists (map wn l0) ; nsplit 3...
  + apply incl_nil.
  + list_simpl.
    apply oc_Fr...
- inversion HF ; subst.
  eapply (proj1 (proj2 (H _ _ _))) in H0...
  destruct H0 as (lw & lw' & l' & HP & Hs & IH).
  exists (A :: lw) ; exists lw' ; exists l' ; nsplit 3...
  + list_simpl ; apply Permutation_cons...
  + apply incl_tl...
- inversion HF ; subst.
  eapply (proj1 (proj2 (H _ _ _))) in H0...
  + destruct H0 as (lw & lw' & l' & HP & Hs & IH).
    symmetry in HP.
    assert (HP' := HP).
    apply Permutation_vs_cons_inv in HP'.
    destruct HP' as (l1' & l2' & Heq).
    dichot_elt_app_exec Heq ; subst.
    * decomp_map Heq0 ; subst.
      inversion Heq0 ; subst.
      assert (HP' := HP).
      list_simpl in HP'.  
      symmetry in HP'.
      apply Permutation_cons_app_inv in HP'.
      symmetry in HP'.
      apply Permutation_vs_cons_inv in HP'.
      destruct HP' as (l1' & l2' & Heq).
      rewrite app_assoc in Heq.
      dichot_elt_app_exec Heq ; subst.
      -- rewrite <- map_app in Heq1.
         decomp_map Heq1 ; subst.
         inversion Heq1 ; subst.
         exists (l2 ++ l4) ; exists lw' ; exists l' ; nsplit 3...
         ++ symmetry in HP.
            list_simpl in HP.
            apply Permutation_cons_app_inv in HP.
            list_simpl...
         ++ revert Hs Heq4 ; clear ; induction lw' ; intros Hs Heq4.
            ** apply incl_nil.
            ** destruct (incl_cons_inv _ _ _ Hs) as [Hin Hi].
               assert (HP := Permutation_middle l2 l4 x0).
               rewrite <- HP in Hin.
               inversion Hin ; subst.
               --- apply incl_cons.
                   +++ rewrite <- Heq4.
                       apply in_elt.
                   +++ apply IHlw'...
               --- apply incl_cons...
                   apply IHlw'...
      -- exists (l2 ++ x :: l4) ; exists (x :: lw') ; exists (l1 ++ l2') ; nsplit 3...
         ++ symmetry in HP.
            list_simpl in HP.
            apply Permutation_cons_app_inv in HP.
            list_simpl.
            etransitivity ; [ apply HP | ].
            rewrite ? app_assoc.
            apply Permutation_elt.
            list_simpl...
         ++ apply incl_cons...
            apply in_elt.
         ++ list_simpl.
            eapply ex_Fr...
            symmetry.
            rewrite ? app_assoc.
            apply Permutation_cons_app...
    * assert (HP' := HP).
      list_simpl in HP'.  
      symmetry in HP'.
      rewrite app_assoc in HP'.
      apply Permutation_cons_app_inv in HP'.
      symmetry in HP'.
      apply Permutation_vs_cons_inv in HP'.
      destruct HP' as (l1'' & l2'' & Heq).
      rewrite <- app_assoc in Heq.
      dichot_elt_app_exec Heq ; subst.
      -- decomp_map Heq0 ; subst.
         inversion Heq0 ; subst.
         exists (l3 ++ x :: l5) ; exists (x :: lw') ; exists (l1 ++ l2') ; nsplit 3...
         ++ symmetry in HP.
            list_simpl in HP.
            apply Permutation_cons_app_inv in HP.
            list_simpl.
            etransitivity ; [ apply HP | ].
            rewrite ? app_assoc.
            apply Permutation_elt.
            list_simpl...
         ++ apply incl_cons...
            apply in_elt.
         ++ list_simpl.
            eapply ex_Fr...
            symmetry.
            rewrite ? app_assoc.
            apply Permutation_cons_app...
      -- exists (A :: lw) ; exists (A :: A :: lw') ; exists (l2 ++ l2'') ; nsplit 3...
         ++ symmetry in HP.
            rewrite app_assoc in HP.
            apply Permutation_cons_app_inv in HP.
            list_simpl.
            etransitivity ; [ apply HP | ].
            list_simpl.
            rewrite <- Heq1.
            symmetry.
            rewrite ? app_assoc.
            apply Permutation_cons_app...
         ++ apply incl_cons ; [ | apply incl_cons ]...
            ** constructor...
            ** constructor...
            ** apply incl_tl...
         ++ list_simpl.
            eapply ex_Fr...
            symmetry.
            rewrite ? app_assoc.
            apply Permutation_cons_app.
            list_simpl.
            rewrite <- Heq1.
            rewrite ? app_assoc.
            apply Permutation_cons_app...
  + constructor...
(* third conjunct *)
- apply not_Focl in HnF.
  destruct HnF as
    (l1 & l2 & A & Heq & [Heq2 | [(B' & C' & Heq2) | [Heq2 | (B' & C' & Heq2)]]]) ;
    subst.
  + eapply bot_rev_f in pi...
    destruct pi as (s' & pi & Hs).
    destruct (Focl_dec (l1 ++ l2)) as [HF | HnF].
    * eapply (proj1 (proj2 (H _ _ _))) in pi...
      destruct pi as (lw & lw' & l0 & HP & Hsub & pi).
      split.
      -- apply foc_Fr in pi.
         eapply (incl_Foc _ (C :: l0)) in pi...
         ++ eapply ex_Fr ; [ apply bot_Fr | ]...
            rewrite (app_comm_cons _ _ C).
            apply Permutation_cons_app.
            list_simpl ; symmetry.
            apply Permutation_cons_app...
         ++ apply Permutation_cons_app...
      -- apply llFoc_foc_is_llFoc_foc in pi.
         apply de_Fr in pi.
         eapply (incl_Foc _ (wn C :: l0)) in pi...
         ++ eapply ex_Fr ; [ apply bot_Fr | ]...
            rewrite (app_comm_cons _ _ (wn C)).
            apply Permutation_cons_app.
            list_simpl ; symmetry.
            apply Permutation_cons_app...
         ++ apply Permutation_cons_app...
    * eapply (proj2 (proj2 (H _ _ _))) in pi...
      destruct pi as [pi1 pi2] ; split.
      -- eapply ex_Fr ; [ apply bot_Fr ; apply pi1 | ].
         rewrite (app_comm_cons _ (bot :: _) C).
         apply Permutation_cons_app.
         list_simpl...
      -- eapply ex_Fr ; [ apply bot_Fr ; apply pi2 | ].
         rewrite (app_comm_cons _ (bot :: _) (wn C)).
         apply Permutation_cons_app.
         list_simpl...
  + eapply parr_rev_f in pi...
    destruct pi as (s' & pi & Hs).
    destruct (Focl_dec (l1 ++ B' :: C' :: l2)) as [HF | HnF].
    * eapply (proj1 (proj2 (H _ _ _))) in pi...
      destruct pi as (lw & lw' & l0 & HP & Hsub & pi).
      split.
      -- apply foc_Fr in pi.
         eapply (incl_Foc _ (C :: l0)) in pi...
         ++ eapply ex_Fr ; [ apply parr_Fr ; eapply ex_Fr | ]...
            ** symmetry.
               etransitivity ; [ | apply Permutation_middle ].
               rewrite <- HP.
               symmetry.
               rewrite app_comm_cons.
               symmetry.
               apply Permutation_cons_app.
               apply Permutation_cons_app...
            ** rewrite (app_comm_cons _ _ C).
               apply Permutation_cons_app.
               list_simpl...
         ++ apply Permutation_cons_app...
      -- apply llFoc_foc_is_llFoc_foc in pi.
         apply de_Fr in pi.
         eapply (incl_Foc _ (wn C :: l0)) in pi...
         ++ eapply ex_Fr ; [ apply parr_Fr ; eapply ex_Fr | ]...
            ** symmetry.
               etransitivity ; [ | apply Permutation_middle ].
               rewrite <- HP.
               symmetry.
               rewrite app_comm_cons.
               symmetry.
               apply Permutation_cons_app.
               apply Permutation_cons_app...
            ** rewrite (app_comm_cons _ _ (wn C)).
               apply Permutation_cons_app.
               list_simpl...
         ++ apply Permutation_cons_app...
    * eapply (proj2 (proj2 (H _ _ _))) in pi...
      destruct pi as [pi1 pi2] ; split.
      -- eapply ex_Fr ; [ apply parr_Fr ; eapply ex_Fr ;
                          [ apply pi1 | ] | ]...
         ++ rewrite app_comm_cons.
            symmetry.
            apply Permutation_cons_app.
            apply Permutation_cons_app...
         ++ rewrite (app_comm_cons _ _ C).
            apply Permutation_cons_app...
      -- eapply ex_Fr ; [ apply parr_Fr ; eapply ex_Fr ;
                          [ apply pi2 | ] | ]...
         ++ rewrite app_comm_cons.
            symmetry.
            apply Permutation_cons_app.
            apply Permutation_cons_app...
         ++ rewrite (app_comm_cons _ _ (wn C)).
            apply Permutation_cons_app...
  + split ; (eapply ex_Fr ; [ apply top_gen_Fr | ])...
    * symmetry ; rewrite app_comm_cons.
      symmetry ; apply Permutation_middle.
    * symmetry ; rewrite app_comm_cons.
      symmetry ; apply Permutation_middle.
  + destruct (with_rev1_f _ _ _ pi _ _ _ _ (eq_refl _)) as (s1 & pi1 & Hs1)...
    destruct (with_rev2_f _ _ _ pi _ _ _ _ (eq_refl _)) as (s2 & pi2 & Hs2)...
    destruct (Focl_dec (l1 ++ l2)) as [HF | HnF].
    * apply Forall_app_inv in HF.
      destruct HF as [HF' HF''].
      destruct (Foc_dec B') as [HFB | HnFB].
      -- assert (Forall Foc (l1 ++ B' :: l2)) as HF1.
         { apply Forall_app...
           constructor... }
         eapply (proj1 (proj2 (H _ _ _))) in pi1...
         destruct pi1 as (lw1 & lw1' & l01 & HP1 & Hsub1 & pi1).
         destruct (Foc_dec C') as [HFC | HnFC].
         ++ assert (Forall Foc (l1 ++ C' :: l2)) as HF2.
            { apply Forall_app...
              constructor... }
            eapply (proj1 (proj2 (H _ _ _))) in pi2...
            destruct pi2 as (lw2 & lw2' & l02 & HP2 & Hsub2 & pi2).
            split.
            ** apply foc_Fr in pi1.
               apply foc_Fr in pi2.
               eapply (incl_Foc _ (C :: l01) lw1') in pi1 ; 
                 [ eapply (incl_Foc _ (C :: l02) lw2') in pi2 | | ]...
               --- eapply ex_Fr ; [ apply with_Fr ; eapply ex_Fr | ].
                   +++ apply pi1.
                   +++ symmetry.
                       etransitivity ; [ | apply Permutation_middle ].
                       rewrite <- HP1.
                       symmetry.
                       rewrite app_comm_cons.
                       symmetry.
                       apply Permutation_cons_app.
                       list_simpl ; reflexivity.
                   +++ apply pi2.
                   +++ symmetry.
                       etransitivity ; [ | apply Permutation_middle ].
                       rewrite <- HP2.
                       symmetry.
                       rewrite app_comm_cons.
                       symmetry.
                       apply Permutation_cons_app.
                       list_simpl ; reflexivity.
                   +++ rewrite (app_comm_cons _ (awith _ _ :: _) C).
                       apply Permutation_cons_app.
                       list_simpl...
               --- apply Permutation_cons_app...
               --- apply Permutation_cons_app...
            ** apply llFoc_foc_is_llFoc_foc in pi1.
               apply de_Fr in pi1.
               apply llFoc_foc_is_llFoc_foc in pi2.
               apply de_Fr in pi2.
               eapply (incl_Foc _ (wn C :: l01) lw1') in pi1 ; 
                 [ eapply (incl_Foc _ (wn C :: l02) lw2') in pi2 | | ]...
               --- eapply ex_Fr ; [ apply with_Fr ; eapply ex_Fr | ].
                   +++ apply pi1.
                   +++ symmetry.
                       etransitivity ; [ | apply Permutation_middle ].
                       rewrite <- HP1.
                       symmetry.
                       rewrite app_comm_cons.
                       symmetry.
                       apply Permutation_cons_app.
                       list_simpl ; reflexivity.
                   +++ apply pi2.
                   +++ symmetry.
                       etransitivity ; [ | apply Permutation_middle ].
                       rewrite <- HP2.
                       symmetry.
                       rewrite app_comm_cons.
                       symmetry.
                       apply Permutation_cons_app.
                       list_simpl ; reflexivity.
                   +++ rewrite (app_comm_cons _ (awith _ _ :: _) (wn C)).
                       apply Permutation_cons_app.
                       list_simpl...
               --- apply Permutation_cons_app...
               --- apply Permutation_cons_app...
         ++ eapply (proj2 (proj2 (H _ _ _))) in pi2...
            ** destruct pi2 as [pi2' pi2''] ; split.
               --- eapply ex_Fr ; [ apply with_Fr | ].
                   +++ apply foc_Fr in pi1.
                       eapply (incl_Foc _ (C :: l01) lw1') in pi1.
                       *** eapply ex_Fr ; [ apply pi1 | ].
                           etransitivity ; [ symmetry ; apply Permutation_middle | ].
                           rewrite <- HP1.
                           rewrite app_comm_cons.
                           symmetry.
                           apply Permutation_middle.
                       *** apply Permutation_middle.
                       *** apply Hsub1.
                   +++ eapply ex_Fr ; [ apply pi2' | ].
                       rewrite app_comm_cons.
                       symmetry ; apply Permutation_middle.
                   +++ rewrite (app_comm_cons _ _ C).
                       apply Permutation_middle.
               --- eapply ex_Fr ; [ apply with_Fr | ].
                   +++ apply llFoc_foc_is_llFoc_foc in pi1.
                       apply de_Fr in pi1.
                       eapply (incl_Foc _ (wn C :: l01) lw1') in pi1.
                       *** eapply ex_Fr ; [ apply pi1 | ].
                           etransitivity ; [ symmetry ; apply Permutation_middle | ].
                           rewrite <- HP1.
                           rewrite app_comm_cons.
                           symmetry.
                           apply Permutation_middle.
                       *** apply Permutation_middle.
                       *** apply Hsub1.
                   +++ eapply ex_Fr ; [ apply pi2'' | ].
                       rewrite app_comm_cons.
                       symmetry ; apply Permutation_middle.
                   +++ rewrite (app_comm_cons _ _ (wn C)).
                       apply Permutation_middle.
            ** intros HFF.
               apply Forall_app_inv in HFF.
               destruct HFF as [HF'1 HF'2].
               inversion HF'2 ; subst.
               apply HnFC...
      -- eapply (proj2 (proj2 (H _ _ _))) in pi1...
         ++ destruct (Foc_dec C') as [HFC | HnFC].
            ** assert (Forall Foc (l1 ++ C' :: l2)) as HF2.
               { apply Forall_app...
                 constructor... }
               eapply (proj1 (proj2 (H _ _ _))) in pi2...
               destruct pi2 as (lw2 & lw2' & l02 & HP2 & Hsub2 & pi2).
               split.
               --- apply foc_Fr in pi2.
                   eapply (incl_Foc _ (C :: l02) lw2') in pi2...
                   +++ eapply ex_Fr ; [ apply with_Fr ; eapply ex_Fr | ].
                       *** apply (proj1 pi1).
                       *** rewrite app_comm_cons.
                           symmetry ; apply Permutation_middle.
                       *** apply pi2.
                       *** etransitivity ; [ symmetry ; apply Permutation_middle | ].
                           rewrite <- HP2.
                           rewrite app_comm_cons.
                           symmetry.
                           apply Permutation_middle.
                       *** rewrite (app_comm_cons _ (awith _ _ :: _) C).
                           apply Permutation_cons_app.
                           list_simpl...
                   +++ apply Permutation_cons_app...
               --- apply llFoc_foc_is_llFoc_foc in pi2.
                   apply de_Fr in pi2.
                   eapply (incl_Foc _ (wn C :: l02) lw2') in pi2...
                   +++ eapply ex_Fr ; [ apply with_Fr ; eapply ex_Fr | ].
                       *** apply (proj2 pi1).
                       *** rewrite app_comm_cons.
                           symmetry ; apply Permutation_middle.
                       *** apply pi2.
                       *** etransitivity ; [ symmetry ; apply Permutation_middle | ].
                           rewrite <- HP2.
                           rewrite app_comm_cons.
                           symmetry.
                           apply Permutation_middle.
                       *** rewrite (app_comm_cons _ (awith _ _ :: _) (wn C)).
                           apply Permutation_cons_app.
                           list_simpl...
                   +++ apply Permutation_cons_app...
            ** eapply (proj2 (proj2 (H _ _ _))) in pi2...
               --- destruct pi2 as [pi2' pi2''] ; split.
                   +++ eapply ex_Fr ; [ apply with_Fr | ].
                       *** eapply ex_Fr ; [ apply (proj1 pi1) | ].
                           rewrite app_comm_cons.
                           symmetry ; apply Permutation_middle.
                       *** eapply ex_Fr ; [ apply pi2' | ].
                           rewrite app_comm_cons.
                           symmetry ; apply Permutation_middle.
                       *** rewrite (app_comm_cons _ _ C).
                           apply Permutation_middle.
                   +++ eapply ex_Fr ; [ apply with_Fr | ].
                       *** eapply ex_Fr ; [ apply (proj2 pi1) | ].
                           rewrite app_comm_cons.
                           symmetry ; apply Permutation_middle.
                       *** eapply ex_Fr ; [ apply pi2'' | ].
                           rewrite app_comm_cons.
                           symmetry ; apply Permutation_middle.
                       *** rewrite (app_comm_cons _ _ (wn C)).
                           apply Permutation_middle.
               --- intros HFF.
                   apply Forall_app_inv in HFF.
                   destruct HFF as [HF'1 HF'2].
                   inversion HF'2 ; subst.
                   apply HnFC...
         ++ intros HFF.
            apply Forall_app_inv in HFF.
            destruct HFF as [HF'1 HF'2].
            inversion HF'2 ; subst.
            apply HnFB...
    * assert (~ Forall Foc (l1 ++ B' :: l2)) as HF1.
      { intros HFF.
        apply Forall_app_inv in HFF.
        destruct HFF as [HF'1 HF'2].
        inversion HF'2.
        apply HnF.
        apply Forall_app... }
      assert (~ Forall Foc (l1 ++ C' :: l2)) as HF2.
      { intros HFF.
        apply Forall_app_inv in HFF.
        destruct HFF as [HF'1 HF'2].
        inversion HF'2.
        apply HnF.
        apply Forall_app... }
      eapply (proj2 (proj2 (H _ _ _))) in pi1...
      eapply (proj2 (proj2 (H _ _ _))) in pi2...
      split ; (eapply ex_Fr ; [ apply with_Fr | ]).
      -- eapply ex_Fr ; [ apply (proj1 pi1) | ].
         rewrite app_comm_cons.
         symmetry ; apply Permutation_middle.
      -- eapply ex_Fr ; [ apply (proj1 pi2) | ].
         rewrite app_comm_cons.
         symmetry ; apply Permutation_middle.
      -- rewrite (app_comm_cons _ _ C).
         apply Permutation_middle.
      -- eapply ex_Fr ; [ apply (proj2 pi1) | ].
         rewrite app_comm_cons.
         symmetry ; apply Permutation_middle.
      -- eapply ex_Fr ; [ apply (proj2 pi2) | ].
         rewrite app_comm_cons.
         symmetry ; apply Permutation_middle.
      -- rewrite (app_comm_cons _ _ (wn C)).
         apply Permutation_middle.
Unshelve. all : omega.
Qed.

Lemma llFoc_to_ll : forall l Pi, llFoc l Pi ->
   (Pi = None -> exists s', ll_ll l s')
/\ (forall C, Pi = Some C -> exists s', ll_ll (C :: l) s').
Proof with myeeasy.
intros l Pi pi ; induction pi ;
  (split ; [ intros HN ; inversion HN ; subst
           | intros D HD ; inversion HD ; subst ]) ;
  try (destruct IHpi as [IHpiN IHpiS]) ;
  try (destruct IHpi1 as [IHpi1N IHpi1S]) ;
  try (destruct IHpi2 as [IHpi2N IHpi2S]) ;
  try (destruct (IHpiS _ (eq_refl _)) as [s0' pi0']) ;
  try (destruct (IHpiN (eq_refl _)) as [s0' pi0']) ;
  try (destruct (IHpi1N (eq_refl _)) as [s1' pi1']) ;
  try (destruct (IHpi2N (eq_refl _)) as [s2' pi2']) ;
  try (now (eexists ; constructor ; myeeasy)) ;
  try (now (eexists ; eapply ex_r ; [ | apply perm_swap ] ; constructor ; myeeasy)) ;
  try (now (eexists ; eapply ex_r ; myeeasy)).
- eexists ; eapply ex_r...
  apply Permutation_cons...
- destruct (polarity A) as [HsA | HaA] ; destruct (polarity B) as [HsB | HaB].
  + rewrite_all (polfocs A HsA).
    rewrite_all (polfocs B HsB).
    destruct (IHpi1S _ (eq_refl _)) as [s1' pi1'].
    destruct (IHpi2S _ (eq_refl _)) as [s2' pi2'].
    eexists ; eapply ex_r ; [ apply tens_r | ].
    * apply pi1'.
    * apply pi2'.
    * rewrite (polconts _ _ HsA).
      rewrite (polconts _ _ HsB).
      PCperm_solve.
  + rewrite_all (polfocs A HsA).
    rewrite_all (polfoca B HaB).
    destruct (IHpi1S _ (eq_refl _)) as [s1' pi1'].
    destruct (IHpi2N (eq_refl _)) as [s2' pi2'].
    eexists ; eapply ex_r ; [ apply tens_r | ].
    * apply pi1'.
    * rewrite (polconta _ _ HaB) in pi2'.
      apply pi2'.
    * rewrite (polconts _ _ HsA).
      PCperm_solve.
  + rewrite_all (polfoca A HaA).
    rewrite_all (polfocs B HsB).
    destruct (IHpi1N (eq_refl _)) as [s1' pi1'].
    destruct (IHpi2S _ (eq_refl _)) as [s2' pi2'].
    eexists ; eapply ex_r ; [ apply tens_r | ].
    * rewrite (polconta _ _ HaA) in pi1'.
      apply pi1'.
    * apply pi2'.
    * rewrite (polconts _ _ HsB).
      PCperm_solve.
  + rewrite_all (polfoca A HaA).
    rewrite_all (polfoca B HaB).
    destruct (IHpi1N (eq_refl _)) as [s1' pi1'].
    destruct (IHpi2N (eq_refl _)) as [s2' pi2'].
    eexists ; eapply ex_r ; [ apply tens_r | ].
    * rewrite (polconta _ _ HaA) in pi1'.
      apply pi1'.
    * rewrite (polconta _ _ HaB) in pi2'.
      apply pi2'.
    * PCperm_solve.
- destruct (polarity A) as [HsA | HaA].
  + rewrite_all (polfocs A HsA).
    destruct (IHpiS _ (eq_refl _)) as [s' pi'].
    eexists ; eapply ex_r ; [ apply plus_r1 | ].
    * apply pi'.
    * rewrite (polconts _ _ HsA).
      PCperm_solve.
  + rewrite_all (polfoca A HaA).
    destruct (IHpiN (eq_refl _)) as [s' pi'].
    eexists ; eapply ex_r ; [ apply plus_r1 | ].
    * rewrite (polconta _ _ HaA) in pi'.
      apply pi'.
    * PCperm_solve.
- destruct (polarity A) as [HsA | HaA].
  + rewrite_all (polfocs A HsA).
    destruct (IHpiS _ (eq_refl _)) as [s' pi'].
    eexists ; eapply ex_r ; [ apply plus_r2 | ].
    * apply pi'.
    * rewrite (polconts _ _ HsA).
      PCperm_solve.
  + rewrite_all (polfoca A HaA).
    destruct (IHpiN (eq_refl _)) as [s' pi'].
    eexists ; eapply ex_r ; [ apply plus_r2 | ].
    * rewrite (polconta _ _ HaA) in pi'.
      apply pi'.
    * PCperm_solve.
- destruct (polarity A) as [HsA | HaA].
  + rewrite_all (polfocs A HsA).
    destruct (IHpiS _ (eq_refl _)) as [s' pi'].
    eexists ; eapply ex_r ; [ apply de_r | ].
    * apply pi'.
    * rewrite (polconts _ _ HsA).
      PCperm_solve.
  + rewrite_all (polfoca A HaA).
    destruct (IHpiN (eq_refl _)) as [s' pi'].
    eexists ; eapply ex_r ; [ apply de_r | ].
    * rewrite (polconta _ _ HaA) in pi'.
      apply pi'.
    * PCperm_solve.
- eexists ; apply co_std_r...
Qed.



