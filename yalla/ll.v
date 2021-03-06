(* ll library for yalla *)
(* Coq 8.6 *)
(* v 1.0   Olivier Laurent *)


(** * Linear Logic with explicit permutations *)

Require Import Omega.
Require Import Wf_nat.

Require Import Injective.
Require Import Bool_more.
Require Import List_more.
Require Import Permutation_more.
Require Import CyclicPerm.
Require Import Permutation_solve.
Require Import CPermutation_solve.
Require Import genperm.

Require Export basic_tactics.
Require Import flat_map_lemmas.
Require Export formulas.


(** ** Fragments for proofs *)

(** Parameters for [ll] provability:
 - [pcut], [pmix0] and [pmix2] determine whether the corresponding rule is in the system or not;
 - [pperm] is [false] for exchange rule modulo cyclic permutations and [true] for exchange rule modulo arbitrary permutations;
 - [pgax] determines the sequents which are valid as axioms in proofs.
*)
Record pfrag := mk_pfrag {
  pcut : bool ;
  pgax : list formula -> Prop ;
  pmix0 : bool ;
  pmix2 : bool ;
  pperm : bool }.

(** Order relation on proof fragments: [P] is more restrictive than [Q]. *)
Definition le_pfrag P Q :=
     Bool.leb (pcut P) (pcut Q)
  /\ (forall l, pgax P l -> pgax Q l)
  /\ Bool.leb (pmix0 P) (pmix0 Q)
  /\ Bool.leb (pmix2 P) (pmix2 Q)
  /\ Bool.leb (pperm P) (pperm Q).

Lemma le_pfrag_trans : forall P Q R,
  le_pfrag P Q -> le_pfrag Q R -> le_pfrag P R.
Proof with myeeasy.
intros P Q R H1 H2.
unfold le_pfrag in H1.
destruct H1 as (Hc1 & Ha1 & H01 & H21 & Hp1).
unfold le_pfrag in H2.
destruct H2 as (Hc2 & Ha2 & H02 & H22 & Hp2).
nsplit 5 ; try (eapply leb_trans ; myeeasy).
intros f Hax.
apply Ha2.
apply Ha1...
Qed.

(** Same proof fragment as [P] but with value [b] for [pcut]. *)
Definition cutupd_pfrag P b :=
  mk_pfrag b (pgax P) (pmix0 P) (pmix2 P) (pperm P).

(** Same proof fragment as [P] but with value [G] for [pgax]. *)
Definition axupd_pfrag P G :=
  mk_pfrag (pcut P) G (pmix0 P) (pmix2 P) (pperm P).

(** Same proof fragment as [P] but without the [cut] rule. *)
Definition cutrm_pfrag P := cutupd_pfrag P false.


(** ** Rules *)

(** The main predicate: [ll] proofs.

The [nat] parameter is a size of proofs.
Choices between [plus] and [max] in binary cases are determined by the behavious in cut elimination.

All rules have their main formula at first position in the conclusion.
 - [ax_r]: identity rule restricted to propositional variables (general case proved later)
 - [ex_r]: exchange rule (parametrized by [pperm P] to determine allowed permutations)
 - [mix0_r]: nullary linear mix rule (available only if [pmix0 P = true])
 - [mix2_r]: binary linear mix rule (the order of lists is matched with the [tens_r] case) (available only if [pmix2 P = true])
 - [one_r]: one rule
 - [bot_r]: bot rule
 - [tens_r]: tensor rule (the order of lists is imposed by the cyclic permutation case)
 - [parr_r]: par rule
 - [top_r]: par rule
 - [plus_r1]: plus left rule
 - [plus_r2]: plus right rule
 - [with_r]: with rule
 - [oc_r]: promotion rule (standard shape)
 - [de_r]: dereliction rule
 - [wk_r]: weakening rule
 - [co_r]: contraction rule with [wn] context inserted between principal formulas to be general enough in the cyclic permutation case
 - [cut_r]: cut rule (the order of lists is matched with the [tens_r] case) (available only if [pcut P = true])
 - [gax_r]: generic axiom rule (parametrized by the predicate [pgax P] over sequents)
*)
Inductive ll P : list formula -> nat -> Prop :=
| ax_r : forall X, ll P (covar X :: var X :: nil) 1
| ex_r : forall l1 l2 s, ll P l1 s -> PCperm (pperm P) l1 l2 -> ll P l2 (S s)
| mix0_r {f : pmix0 P = true} : ll P nil 1
| mix2_r {f : pmix2 P = true} : forall l1 l2 s1 s2, ll P l1 s1 -> ll P l2 s2 ->
                         ll P (l2 ++ l1) (S (s1 + s2))
| one_r : ll P (one :: nil) 1
| bot_r : forall l s, ll P l s -> ll P (bot :: l) (S s)
| tens_r : forall A B l1 l2 s1 s2, ll P (A :: l1) s1 -> ll P (B :: l2) s2 ->
                                   ll P (tens A B :: l2 ++ l1) (S (s1 + s2))
| parr_r : forall A B l s, ll P (A :: B :: l) s -> ll P (parr A B :: l) (S s)
| top_r : forall l, ll P (top :: l) 1
| plus_r1 : forall A B l s, ll P (A :: l) s -> ll P (aplus A B :: l) (S s)
| plus_r2 : forall A B l s, ll P (A :: l) s -> ll P (aplus B A :: l) (S s)
| with_r : forall A B l s1 s2, ll P (A :: l) s1 -> ll P (B :: l) s2 ->
                               ll P (awith A B :: l) (S (max s1 s2))
| oc_r : forall A l s, ll P (A :: map wn l) s -> ll P (oc A :: map wn l) (S s)
| de_r : forall A l s, ll P (A :: l) s -> ll P (wn A :: l) (S s)
| wk_r : forall A l s, ll P l s -> ll P (wn A :: l) (S s)
| co_r : forall A lw l s, ll P (wn A :: map wn lw ++ wn A :: l) s ->
                          ll P (wn A :: map wn lw ++ l) (S s)
| cut_r {f : pcut P = true} : forall A l1 l2 s1 s2,
    ll P (dual A :: l1) s1 -> ll P (A :: l2) s2 -> ll P (l2 ++ l1) (S (s1 + s2))
| gax_r : forall l, pgax P l -> ll P l 1.

Lemma psize_pos P : forall l s, ll P l s -> 0 < s.
Proof.
intros l s pi.
induction pi ; omega.
Qed.

Lemma stronger_pfrag P Q : le_pfrag P Q -> forall l s, ll P l s -> ll Q l s.
Proof with myeeasy.
intros Hle l s H.
induction H ; try (constructor ; myeasy ; fail).
- apply (ex_r _ l1)...
  inversion Hle...
  destruct H2 as (_ & _ & _ & Hp).
  unfold PCperm in H0.
  unfold PCperm.
  destruct (pperm P) ; destruct (pperm Q) ;
    simpl in Hp ; try inversion Hp...
  apply cperm_perm...
- unfold le_pfrag in Hle.
  rewrite f in Hle.
  destruct Hle as (_ & _ & Hmix0 & _).
  simpl in Hmix0...
  apply (@mix0_r _ Hmix0).
- unfold le_pfrag in Hle.
  rewrite f in Hle.
  destruct Hle as (_ & _ & _ & Hmix2 & _).
  simpl in Hmix2...
  apply (@mix2_r _ Hmix2)...
- unfold le_pfrag in Hle.
  destruct Hle as [Hcut _].
  rewrite f in Hcut.
  simpl in Hcut...
  eapply (@cut_r _ Hcut)...
- apply gax_r.
  apply Hle...
Qed.

(** *** Variants of rules *)

(** Weakening on a list of formulas *)
Lemma wk_list_r {P} : forall l l' s, ll P l' s -> exists s',
  ll P (map wn l ++ l') s'.
Proof with myeeasy.
induction l ; intros.
- eexists...
- apply IHl in H.
  destruct H as [s' H].
  eexists.
  apply wk_r...
Qed.

(** Contraction on a list of formulas *)
Lemma co_list_r {P} : forall l lw l' s,
  ll P (map wn l ++ map wn lw ++ map wn l ++ l') s -> exists s',
    ll P (map wn l ++ map wn lw ++ l') s'.
Proof with myeeasy ; try PCperm_solve.
induction l ; intros.
- eexists...
- simpl in H.
  rewrite app_assoc in H.
  rewrite <- map_app in H.
  apply co_r in H.
  rewrite map_app in H.
  eapply (ex_r _ _
    (map wn l ++ map wn lw ++ map wn l ++ l' ++ wn a :: nil))
    in H...
  apply IHl in H.
  destruct H as [s' H].
  eexists.
  eapply ex_r...
Qed.

(** More standard shape of contraction rule with adjacent principal formulas

(this is stricly weaker than [co_r] in the case of cyclic permutations only). *)
Lemma co_std_r {P} : forall A l s,
  ll P (wn A :: wn A :: l) s -> ll P (wn A :: l) (S s).
Proof.
intros A l s pi.
change (wn A :: l) with (wn A :: map wn nil ++ l).
apply co_r.
assumption.
Qed.

(** Standard contraction rule on a list of formulas *)
Lemma co_std_list_r {P} : forall l l' s,
  ll P (map wn l ++ map wn l ++ l') s -> exists s',
    ll P (map wn l ++ l') s'.
Proof.
intros l l' s pi.
change (map wn l ++ l') with (map wn l ++ map wn nil ++ l').
eapply co_list_r.
eassumption.
Qed.


(** *** Some tactics for manipulating rules *)

Ltac ex_apply_ax := eapply ex_r ;
  [ eapply ax_r | PCperm_solve ].
Ltac ex_apply_mix2 f Hl Hr := eapply ex_r ;
  [ eapply (@mix2_r _ f _ _ _ _ Hl Hr) | PCperm_solve ].
Ltac ex_apply_tens Hl Hr := eapply ex_r ;
  [ eapply (tens_r _ _ _ _ _ _ _ Hl Hr) | PCperm_solve ].
Ltac ex_apply_with Hl Hr := eapply ex_r ;
  [ eapply (with_r _ _ _ _ _ _ Hl Hr) | PCperm_solve ].
Ltac ex_apply_de H := eapply ex_r ;
  [ eapply (de_r _ _ _ _ H) | PCperm_solve ].

Ltac inversion_ll H f X l Hl Hr HP Hax :=
  match type of H with
  | ll _ _ _ => inversion H as [ X
                               | l ? ? Hl HP
                               | f
                               | f ? ? ? ? Hl Hr
                               | 
                               | ? ? Hl
                               | ? ? ? ? ? ? Hl Hr
                               | ? ? ? ? Hl
                               | l
                               | ? ? ? ? Hl
                               | ? ? ? ? Hl
                               | ? ? ? ? ? Hl Hr
                               | ? ? ? Hl
                               | ? ? ? Hl
                               | ? ? ? Hl
                               | ? ? ? ? Hl
                               | f ? ? ? ? ? Hl Hr
                               | l Hax] ; subst
  end.

Ltac ll_swap :=
  match goal with
  | |- ll ?P (?a1 :: ?a2 :: nil) _ => eapply ex_r ; [ | apply PCperm_swap ]
  end.
Ltac ll_swap_in H :=
  match goal with
  | H : ll ?P (?a1 :: ?a2 :: nil) _ |- _ =>
        eapply ex_r in H ;[ | apply PCperm_swap ]
  end.


(** ** Axiom expansion *)

Lemma ax_exp {P} : forall A, exists s, ll P (A :: dual A :: nil) s.
Proof with myeeasy.
induction A ;
  try (destruct IHA as [s IHA]) ;
  try (destruct IHA1 as [s1 IHA1] ; destruct IHA2 as [s2 IHA2]) ;
  eexists ; simpl.
- ex_apply_ax.
- apply ax_r.
- ll_swap.
  apply bot_r.
  apply one_r.
- apply bot_r.
  apply one_r.
- ll_swap.
  apply parr_r.
  ex_apply_tens IHA1 IHA2.
- apply parr_r.
  ll_swap_in IHA1.
  ll_swap_in IHA2.
  ex_apply_tens IHA2 IHA1.
- ll_swap.
  apply top_r.
- apply top_r.
- eapply plus_r1 in IHA1.
  ll_swap_in IHA1.
  eapply plus_r2 in IHA2.
  ll_swap_in IHA2.
  ex_apply_with IHA1 IHA2.
- apply with_r ; ll_swap.
  + apply plus_r1 ; ll_swap...
  + apply plus_r2 ; ll_swap...
- change (oc A :: wn (dual A) :: nil)
    with (oc A :: map wn (dual A :: nil)).
  apply oc_r.
  ll_swap_in IHA.
  ex_apply_de IHA.
- eapply de_r in IHA.
  ll_swap_in IHA.
  ll_swap.
  change (oc (dual A) :: wn A :: nil)
    with (oc (dual A) :: map wn (A :: nil)).
  apply oc_r...
Qed.

Lemma ax_exp_frag {P} : forall l s P', ll P' l s ->
  le_pfrag P' (axupd_pfrag P (fun x => pgax P x
                                       \/ exists A, x = A :: dual A :: nil))
    -> exists s', ll P l s'.
Proof with try eassumption ; try reflexivity.
intros l s P' pi Hlf.
induction pi ;
  try (destruct IHpi as [s' IHpi]) ;
  try (destruct IHpi1 as [s1' IHpi1]) ;
  try (destruct IHpi2 as [s2' IHpi2]) ;
  try (eexists ; constructor ; eassumption ; fail).
- eexists ; eapply ex_r...
  destruct Hlf as (_ & _ & _ & _ & Hp) ; simpl in Hp.
  unfold PCperm in H ; unfold PCperm.
  destruct (pperm P) ; destruct (pperm P') ;
    try (inversion Hp ; fail)...
  apply cperm_perm...
- destruct Hlf as (_ & _ & Hmix0 & _).
  rewrite f in Hmix0.
  simpl in Hmix0.
  eexists ; apply (@mix0_r _ Hmix0).
- destruct Hlf as (_ & _ & _ & Hmix2 & _).
  rewrite f in Hmix2.
  simpl in Hmix2.
  eexists ; apply (@mix2_r _ Hmix2)...
- destruct Hlf as (Hcut & _).
  rewrite f in Hcut.
  simpl in Hcut.
  eexists ; eapply (@cut_r _ Hcut)...
- destruct Hlf as (_ & Hlfax & _).
  apply Hlfax in H.
  destruct H.
  + eexists ; apply gax_r...
  + destruct H as [A HA] ; subst.
    apply ax_exp.
Qed.


(** ** Cut elimination *)

Lemma flat_map_wn_subst : forall A l0 ls l,
  flat_map (cons (wn (dual A))) ls = map wn l ->
    exists l', flat_map (app (map wn l0)) ls = map wn l'.
Proof with myeasy.
induction ls ; intros l HP.
- exists nil...
- simpl in HP.
  decomp_map HP ; subst.
  apply IHls in HP4.
  destruct HP4 as [l' HP4].
  exists ((l0 ++ l3) ++ l').
  simpl ; rewrite HP4 ; rewrite ? map_app...
Qed.

(* begin hide *)
Ltac key_case_oc_subst_ucase A l B lB rule IH HP :=
  let ls' := fresh "ls" in
  let l1 := fresh "l" in
  let Hls1 := fresh "Hls" in
  let Hls2 := fresh "Hls" in
  let Hls3 := fresh "Hls" in
  let HP1 := fresh HP in
  destruct (PCperm_subst_flat_map _ _ (map wn l) _ _ _ HP)
    as [ [l1 HP1] | (HeqA & x & ls' & ls'' & Heqls & HP1) ] ;
  [ destruct (HP1 lB) as (ls' & Hls1 & Hls2 & Hls3) ;
    apply IH in Hls1 ;
    let s' := fresh "s" in
    destruct Hls1 as [s' Hls1] ;
    eexists ;
    eapply ex_r ; [ | apply Hls3 ] ;
    eapply rule ;
    eapply ex_r ;
    myeeasy
  | try (exfalso ;
         assert (B <> wn (dual A))
           as Hnwn by (intro HA ; inversion HA) ;
         apply Hnwn ;
         myeeasy) ].

Lemma key_case_oc_subst_mix2_cperm {P} : forall A l ls l1 l2 l3 s1 s2,
  pmix2 P = true -> false = pperm P ->
  ll P l1 s1 -> ll P (l2 ++ l3) s2 ->
  (forall ls,
     CPermutation l1 (flat_map (cons (wn (dual A))) ls) ->
     exists s' : nat, ll P (flat_map (app (map wn l)) ls) s') ->
  (forall ls,
     CPermutation (l2 ++ l3) (flat_map (cons (wn (dual A))) ls) ->
       exists s' : nat, ll P (flat_map (app (map wn l)) ls) s') ->
     l3 ++ l1 ++ l2 = flat_map (cons (wn (dual A))) ls ->
     exists s' : nat, ll P (flat_map (app (map wn l)) ls) s'.
Proof with myeeasy ; try PCperm_solve.
intros A l ls l1 l2 l3 s1 s2 f0 Hpp H1 H2 IHll1 IHll2 HP.
apply app_app_vs_flat_map in HP.
destruct HP
  as [ (ls' & ls'' & ls''' & Heq1 & Heq2 & Heq3 & Heq4)
     | [ (x & l' & ls' & ls''' & Heq1 & Heq2 & Heq3 & Heq4)
     | [ (x & l' & ls' & ls'' & ls''' & Heq1 & Heq2 & Heq3 & Heq4 & Heq5)
     | [ (x' & l' & ls' & ls'' & ls''' & Heq1 & Heq2 & Heq3 & Heq4 & Heq5)
     |   (x & l' & x' & l'' & ls' & ls'' & ls''' &
           Heq1 & Heq2 & Heq3 & Heq4 & Heq5 & Heq6) ]]]] ; subst.
- destruct (IHll1 _ (cperm_refl _)) as [s1' IH1].
  rewrite <- flat_map_app in IHll2.
  destruct (IHll2 _ (cperm_refl _)) as [s2' IH2].
  rewrite flat_map_app in IH2.
  eexists.
  rewrite ? flat_map_app.
  eapply ex_r ; [ | unfold PCperm ; rewrite <- Hpp ; apply cperm_app_rot ]...
  eapply ex_r ; [ | unfold PCperm ; rewrite <- Hpp ; apply cperm_app_rot ]...
  apply (@mix2_r _ f0)...
- assert (CPermutation ((l' ++ flat_map (cons (wn (dual A))) ls''') ++
                               flat_map (cons (wn (dual A))) (ls' ++ x :: nil))
                       (flat_map (cons (wn (dual A)))
                              (ls''' ++ ls' ++ (x ++ l') :: nil)))
    as HP2
    by (simpl ; rewrite ? flat_map_app ;
        simpl ; rewrite <- ? app_assoc ; cperm_solve).
  destruct (IHll2 _ HP2) as [s2' IH2].
  rewrite ? flat_map_app in IH2 ; simpl in IH2 ; rewrite app_nil_r in IH2.
  eexists.
  rewrite ? flat_map_app ; simpl ; rewrite <- ? app_assoc.
  rewrite 2 app_assoc.
  eapply ex_r ; [ | unfold PCperm ; rewrite <- Hpp ; apply cperm_app_rot ].
  rewrite ? app_assoc.
  apply (@mix2_r _ f0)...
  rewrite <- ? app_assoc.
  eapply ex_r ; [ | unfold PCperm ; rewrite <- Hpp ; apply cperm ].
  rewrite <- ? app_assoc...
- rewrite <- flat_map_app in IHll2.
  destruct (IHll2 _ (cperm_refl _)) as [s2' IH2].
  rewrite flat_map_app in IH2.
  destruct ls'' using rev_ind.
  + eexists.
    rewrite ? flat_map_app in IH2 ; simpl in IH2 ; rewrite app_nil_r in IH2.
    rewrite ? app_assoc in IH2.
    rewrite ? flat_map_app ; simpl ; rewrite ? flat_map_app.
    rewrite <- ? app_assoc ; rewrite 2 app_assoc.
    eapply ex_r ; [ | unfold PCperm ; rewrite <- Hpp ; apply cperm_app_rot ].
    rewrite ? app_assoc.
    simpl in H1 ; rewrite app_nil_r in H1.
    apply (@mix2_r _ f0)...
  + assert (CPermutation (l' ++ flat_map (cons (wn (dual A))) (ls'' ++ x0 :: nil))
                         (flat_map (cons (wn (dual A))) (ls'' ++ (x0 ++ l') :: nil)))
      as HP1
      by (simpl ; rewrite ? flat_map_app ;
          simpl ; rewrite <- ? app_assoc ; cperm_solve).
    destruct (IHll1 _ HP1) as [s1' IH1].
    eexists.
    rewrite ? flat_map_app ; simpl ; rewrite ? flat_map_app.
    rewrite <- ? app_assoc ; rewrite app_assoc.
    eapply ex_r ; [ | unfold PCperm ; rewrite <- Hpp ; apply cperm_app_rot ].
    rewrite <- ? app_assoc ; rewrite 2 app_assoc.
    apply (@mix2_r _ f0).
    * simpl.
      rewrite flat_map_app in IH2 ; simpl in IH2 ; rewrite app_nil_r in IH2...
    * simpl.
      rewrite flat_map_app in IH1 ; simpl in IH1 ; rewrite app_nil_r in IH1.
      eapply ex_r ; [ | unfold PCperm ; rewrite <- Hpp ]...
- destruct (IHll1 _ (cperm_refl _)) as [s1' IH1].
  destruct ls' using rev_ind ; [ destruct ls''' using rev_ind | ].
  + eexists.
    rewrite flat_map_app in IH1 ; simpl in IH1 ; rewrite app_nil_r in IH1.
    rewrite app_assoc in IH1.
    simpl in H2 ; rewrite ? app_nil_r in H2.
    rewrite app_nil_l.
    rewrite flat_map_app ; simpl.
    rewrite app_nil_r ; rewrite ? app_assoc.
    apply (@mix2_r _ f0)...
  + simpl in IHll2.
    rewrite app_nil_r in IHll2.
    assert (CPermutation (l' ++ flat_map (cons (wn (dual A))) (ls''' ++ x :: nil))
                         (flat_map (cons (wn (dual A))) (ls''' ++ (x ++ l') :: nil)))
      as HP2.
    { rewrite ? flat_map_app ; simpl ; rewrite ? app_nil_r.
      rewrite app_comm_cons.
      apply cperm_app_rot. }
    apply IHll2 in HP2.
    destruct HP2 as [s2' HP2].
    eexists.
    rewrite flat_map_app in IH1 ; simpl in IH1 ; rewrite app_nil_r in IH1.
    rewrite app_assoc in IH1.
    rewrite flat_map_app in HP2 ; simpl in HP2 ; rewrite app_nil_r in HP2.
    rewrite app_nil_l.
    rewrite ? flat_map_app ; simpl ; rewrite ? flat_map_app ; simpl.
    rewrite ? app_assoc ; rewrite app_nil_r.
    rewrite <- 3 app_assoc.
    apply (@mix2_r _ f0)...
    eapply ex_r ; [ | unfold PCperm ; rewrite <- Hpp ]...
  + assert (CPermutation (l' ++ flat_map (cons (wn (dual A))) ls'''
                             ++ flat_map (cons (wn (dual A))) (ls' ++ x :: nil))
                         (flat_map (cons (wn (dual A))) (ls''' ++ ls' ++ (x ++ l') :: nil)))
      as HP2.
    { rewrite ? flat_map_app ; simpl ; rewrite ? app_nil_r.
      rewrite app_comm_cons.
      eapply (cperm_trans _ _ _) ; [ apply cperm | ].
      rewrite ? app_assoc... }
    rewrite <- app_assoc in IHll2.
    apply IHll2 in HP2.
    destruct HP2 as [s2' HP2].
    eexists.
    rewrite flat_map_app in IH1 ; simpl in IH1 ; rewrite app_nil_r in IH1.
    rewrite app_assoc in IH1.
    rewrite flat_map_app in HP2 ; simpl in HP2.
    rewrite flat_map_app in HP2 ; simpl in HP2 ; rewrite app_nil_r in HP2.
    rewrite ? flat_map_app ; simpl ; rewrite ? flat_map_app ; simpl.
    rewrite ? app_assoc ; rewrite app_nil_r.
    rewrite <- 4 app_assoc.
    eapply ex_r ; [ | unfold PCperm ; rewrite <- Hpp ; apply cperm ].
    rewrite <- ? app_assoc ; rewrite 2 app_assoc.
    apply (@mix2_r _ f0)...
    eapply ex_r ; [ | unfold PCperm ; rewrite <- Hpp ]...
- assert (CPermutation (l' ++ flat_map (cons (wn (dual A))) (ls'' ++ x' :: nil))
                       (flat_map (cons (wn (dual A))) (ls'' ++ (x' ++ l') :: nil)))
    as HP1.
  { rewrite ? flat_map_app ; simpl ; rewrite ? app_nil_r.
    rewrite app_comm_cons.
    apply cperm_app_rot. }
  apply IHll1 in HP1.
  destruct HP1 as [s1' HP1].
  assert (CPermutation ((l'' ++ flat_map (cons (wn (dual A))) ls''')
                             ++ flat_map (cons (wn (dual A))) (ls' ++ x :: nil))
            (flat_map (cons (wn (dual A))) (ls''' ++ ls' ++ (x ++ l'') :: nil)))
    as HP2.
  { rewrite <- app_assoc.
    eapply (cperm_trans _ _ _) ; [ apply cperm | ].
    rewrite ? flat_map_app ; simpl ; rewrite ? app_nil_r.
    rewrite app_comm_cons... }
  apply IHll2 in HP2.
  destruct HP2 as [s2' HP2].
  eexists.
  rewrite ? flat_map_app ; simpl ; rewrite ? flat_map_app ; simpl.
  rewrite <- ? app_assoc.
  rewrite 2 app_assoc.
  eapply ex_r ; [ | unfold PCperm ; rewrite <- Hpp ; apply cperm ].
  rewrite <- ? app_assoc.
  rewrite 3 app_assoc.
  apply (@mix2_r _ f0)...
  + apply (ex_r _ _ _ _ HP2).
    unfold PCperm ; rewrite <- Hpp.
    eapply (cperm_trans _ _ _) ; [ | apply cperm].
    rewrite ? flat_map_app...
  + apply (ex_r _ _ _ _ HP1).
    unfold PCperm ; rewrite <- Hpp.
    rewrite ? flat_map_app.
    rewrite <- ? app_assoc.
    eapply (cperm_trans _ _ _) ; [ | apply cperm]...
Qed.

Lemma key_case_oc_subst_cut_cperm {P} : forall A A0 l ls l1 l2 l3 s1 s2,
  pcut P = true -> false = pperm P ->
  ll P (dual A0 :: l1) s1 -> ll P (A0 :: l2 ++ l3) s2 ->
  (forall ls,
     CPermutation (dual A0 :: l1) (flat_map (cons (wn (dual A))) ls) ->
     exists s' : nat, ll P (flat_map (app (map wn l)) ls) s') ->
  (forall ls,
     CPermutation (A0 :: l2 ++ l3) (flat_map (cons (wn (dual A))) ls) ->
       exists s' : nat, ll P (flat_map (app (map wn l)) ls) s') ->
     l3 ++ l1 ++ l2 = flat_map (cons (wn (dual A))) ls ->
     exists s' : nat, ll P (flat_map (app (map wn l)) ls) s'.
Proof with myeeasy ; try PCperm_solve.
intros A A0 l ls l1 l2 l3 s1 s2 f Hpp H1 H2 IHll1 IHll2 HP.
apply app_app_vs_flat_map in HP.
destruct HP
  as [ (ls' & ls'' & ls''' & Heq1 & Heq2 & Heq3 & Heq4)
     | [ (x & l' & ls' & ls''' & Heq1 & Heq2 & Heq3 & Heq4)
     | [ (x & l' & ls' & ls'' & ls''' & Heq1 & Heq2 & Heq3 & Heq4 & Heq5)
     | [ (x' & l' & ls' & ls'' & ls''' & Heq1 & Heq2 & Heq3 & Heq4 & Heq5)
     |   (x & l' & x' & l'' & ls' & ls'' & ls'''
            & Heq1 & Heq2 & Heq3 & Heq4 & Heq5 & Heq6) ]]]] ; subst.
- rewrite <- flat_map_app in IHll2.
  destruct ls'' using rev_ind.
  + remember (ls''' ++ ls') as ls0.
    destruct ls0 using rev_ind.
    * symmetry in Heqls0.
      apply app_eq_nil in Heqls0.
      destruct Heqls0 ; subst.
      eexists.
      rewrite app_nil_l ; rewrite flat_map_app ; apply (@cut_r _ f A0)...
    * assert (CPermutation (A0 :: flat_map (cons (wn (dual A))) (ls0 ++ x :: nil))
                 (flat_map (cons (wn (dual A))) (ls0 ++ (x ++ A0 :: nil) :: nil)))
        as HC2 by (rewrite ? flat_map_app ; cperm_solve).
      apply IHll2 in HC2.
      destruct HC2 as [s2' IH2].
      rewrite flat_map_app in IH2 ; list_simpl in IH2.
      eexists.
      rewrite flat_map_app ; simpl.
      eapply ex_r ; [ | unfold PCperm ; rewrite <- Hpp ; apply cperm ].
      rewrite <- (app_nil_r (app _ _)).
      apply (@cut_r _ f A0)...
      eapply ex_r ; [ apply IH2 | ].
      rewrite <- flat_map_app.
      rewrite <- Heqls0.
      rewrite flat_map_app...
  + assert (CPermutation (dual A0 :: flat_map (cons (wn (dual A))) (ls'' ++ x :: nil))
               (flat_map (cons (wn (dual A))) (ls'' ++ (x ++ dual A0 :: nil) :: nil)))
      as HC1 by (rewrite ? flat_map_app ; cperm_solve).
    apply IHll1 in HC1.
    destruct HC1 as [s1' IH1].
    rewrite flat_map_app in IH1 ; list_simpl in IH1.
    remember (ls''' ++ ls') as ls0.
    destruct ls0 using rev_ind.
    * symmetry in Heqls0.
      apply app_eq_nil in Heqls0.
      destruct Heqls0 ; subst.
      eexists.
      rewrite app_nil_r ; rewrite flat_map_app ; apply (@cut_r _ f A0)...
      rewrite flat_map_app.
      eapply ex_r ; [ apply IH1 | ]...
    * assert (CPermutation (A0 :: flat_map (cons (wn (dual A))) (ls0 ++ x0 :: nil))
                           (flat_map (cons (wn (dual A))) (ls0 ++ (x0 ++ A0 :: nil) :: nil)))
        as HC2 by (rewrite ? flat_map_app ; cperm_solve).
      apply IHll2 in HC2.
      destruct HC2 as [s2' IH2].
      rewrite flat_map_app in IH2 ; list_simpl in IH2.
      eexists.
      rewrite ? flat_map_app ; simpl.
      apply (ex_r _ ((flat_map (app (map wn l)) ls''' ++ flat_map (app (map wn l)) ls')
                       ++ (flat_map (app (map wn l)) ls'' ++ (map wn l ++ x) ++ nil)))...
      apply (@cut_r _ f A0).
      -- eapply ex_r ; [ apply IH1 | ]...
      -- eapply ex_r ; [ apply IH2 | ].
         rewrite <- flat_map_app.
         rewrite <- Heqls0.
         rewrite flat_map_app...
- assert (CPermutation (A0 :: (l' ++ flat_map (cons (wn (dual A))) ls''') ++ 
                             flat_map (cons (wn (dual A))) (ls' ++ x :: nil))
             (flat_map (cons (wn (dual A))) (ls''' ++ ls' ++ (x ++ A0 :: l') :: nil)))
    as HC2 by (rewrite ? flat_map_app ; cperm_solve).
  apply IHll2 in HC2.
  destruct HC2 as [s2' IH2].
  rewrite flat_map_app in IH2 ; list_simpl in IH2.
  eexists.
  rewrite ? flat_map_app ; list_simpl.
  rewrite 3 app_assoc.
  eapply ex_r ; [ | unfold PCperm ; rewrite <- Hpp ; apply cperm ].
  list_simpl.
  rewrite ? app_assoc.
  apply (@cut_r _ f A0)...
  eapply ex_r ; [ apply IH2 | ].
  rewrite ? flat_map_app...
- rewrite <- flat_map_app in IHll2.
  destruct ls'' using rev_ind.
  + assert (CPermutation (A0 :: flat_map (cons (wn (dual A))) (ls''' ++ ls' ++ x :: nil))
               (flat_map (cons (wn (dual A))) (ls''' ++ ls' ++ (x ++ A0 :: nil) :: nil)))
      as HC2 by (rewrite ? flat_map_app ; cperm_solve).
    apply IHll2 in HC2.
    destruct HC2 as [s2' IH2].
    rewrite flat_map_app in IH2 ; list_simpl in IH2.
    eexists.
    rewrite flat_map_app ; list_simpl.
    rewrite 3 app_assoc.
    eapply ex_r ; [ | unfold PCperm ; rewrite <- Hpp ; apply cperm ].
    rewrite ? app_assoc.
    list_simpl in H1.
    apply (@cut_r _ f A0)...
    eapply ex_r ; [ apply IH2 | ].
    rewrite ? flat_map_app...
  + assert (CPermutation (dual A0 :: l' ++ flat_map (cons (wn (dual A))) (ls'' ++ x0 :: nil))
                      (flat_map (cons (wn (dual A))) (ls'' ++ (x0 ++ dual A0 :: l') :: nil)))
      as HC1 by (rewrite ? flat_map_app ; cperm_solve).
    apply IHll1 in HC1.
    destruct HC1 as [s1' IH1].
    rewrite flat_map_app in IH1 ; list_simpl in IH1.
    assert (CPermutation (A0 :: flat_map (cons (wn (dual A))) (ls''' ++ ls' ++ x :: nil))
               (flat_map (cons (wn (dual A))) (ls''' ++ ls' ++ (x ++ A0 :: nil) :: nil)))
      as HC2 by (rewrite ? flat_map_app ; cperm_solve).
    apply IHll2 in HC2.
    destruct HC2 as [s2' IH2].
    rewrite flat_map_app in IH2 ; list_simpl in IH2.
    eexists.
    rewrite ? flat_map_app ; simpl ; rewrite ? flat_map_app.
    apply (ex_r _ (((flat_map (app (map wn l)) ls''' ++ flat_map (app (map wn l)) ls') ++ map wn l ++ x)
                            ++ l' ++ (flat_map (app (map wn l)) ls'' ++ (map wn l ++ x0) ++ nil)))...
    apply (@cut_r _ f A0).
    -- eapply ex_r ; [ apply IH1 | ]...
    -- eapply ex_r ; [ apply IH2 | ].
       rewrite flat_map_app...
- assert (CPermutation (dual A0 :: flat_map (cons (wn (dual A))) (ls'' ++ x' :: nil))
             (flat_map (cons (wn (dual A))) (ls'' ++ (x' ++ dual A0 :: nil) :: nil)))
    as HC1 by (rewrite ? flat_map_app ; cperm_solve).
  apply IHll1 in HC1.
  destruct HC1 as [s1' IH1].
  rewrite flat_map_app in IH1 ; list_simpl in IH1.
  remember (ls''' ++ ls') as ls0.
  destruct ls0 using rev_ind.
  + symmetry in Heqls0.
    apply app_eq_nil in Heqls0.
    destruct Heqls0 ; subst.
    eexists.
    rewrite ? flat_map_app ; list_simpl.
    rewrite ? app_assoc.
    eapply ex_r ; [ | unfold PCperm ; rewrite <- Hpp ; apply cperm ].
    list_simpl in H2.
    apply (@cut_r _ f A0)...
    eapply ex_r ; [ apply IH1 | ]...
  + list_simpl in IHll2 ; rewrite <- flat_map_app in IHll2.
  rewrite <- Heqls0 in IHll2.
  assert (CPermutation (A0 :: l' ++ flat_map (cons (wn (dual A))) (ls0 ++ x :: nil))
         (flat_map (cons (wn (dual A))) (ls0 ++ (x ++ A0 :: l') :: nil)))
    as HC2 by (rewrite ? flat_map_app ; cperm_solve).
  apply IHll2 in HC2.
  destruct HC2 as [s2' IH2].
  rewrite flat_map_app in IH2 ; list_simpl in IH2.
  eexists.
  rewrite ? flat_map_app ; simpl.
  apply (ex_r _ ((l' ++ flat_map (app (map wn l)) ls''' ++ flat_map (app (map wn l)) ls')
                     ++ (flat_map (app (map wn l)) ls'' ++ (map wn l ++ x'))))...
  apply (@cut_r _ f A0).
  * eapply ex_r ; [ apply IH1 | ]...
  * eapply ex_r ; [ apply IH2 | ].
    rewrite <- flat_map_app.
    rewrite <- Heqls0.
    rewrite flat_map_app...
- assert (CPermutation (dual A0 :: l' ++ flat_map (cons (wn (dual A))) (ls'' ++ x' :: nil))
                    (flat_map (cons (wn (dual A))) (ls'' ++ (x' ++ dual A0 :: l') :: nil)))
    as HC1 by (rewrite ? flat_map_app ; cperm_solve).
  apply IHll1 in HC1.
  destruct HC1 as [s1' IH1].
  rewrite flat_map_app in IH1 ; list_simpl in IH1.
  list_simpl in IHll2 ; rewrite <- flat_map_app in IHll2.
  assert (CPermutation (A0 :: l'' ++ flat_map (cons (wn (dual A))) (ls''' ++ ls' ++ x :: nil))
                    (flat_map (cons (wn (dual A))) (ls''' ++ ls' ++ (x ++ A0 :: l'') :: nil)))
    as HC2 by (rewrite ? flat_map_app ; cperm_solve).
  apply IHll2 in HC2.
  destruct HC2 as [s2' IH2].
  rewrite ? flat_map_app in IH2 ; list_simpl in IH2.
  eexists.
  list_simpl ; rewrite ? flat_map_app ; list_simpl ; rewrite ? flat_map_app ; list_simpl.
  rewrite 6 app_assoc.
  eapply ex_r ; [ | unfold PCperm ; rewrite <- Hpp ; apply cperm ].
  list_simpl.
  rewrite 4 app_assoc.
  apply (@cut_r _ f A0).
  + eapply ex_r ; [ apply IH1 | ]...
  + eapply ex_r ; [ apply IH2 | ]...
Qed.
(* end hide *)

Section Cut_Elim.

Variable P : pfrag.
Hypothesis P_gax_atomic : forall l, pgax P l -> Forall atomic l.

(** If any occurence of [dual A] can be substituted with [map wn l]
(typically when we have a proof of [A :: map wn l])
then any family of occurrences of [wn (dual A)] in the conclusion of a proof
can be substituted with occurrences of [map wn l].
This correponds to applying the substitution at the leaves of the exponential trees of the [wn (dual A)] formulas. *)
Lemma key_case_oc_subst : forall A l ls l1 s1,
  (forall l2 l3 s2, ll P (l2 ++ (dual A) :: l3) s2 ->
     exists s', ll P (l2 ++ (map wn l) ++ l3) s') ->
  ll P l1 s1 ->
    PCperm (pperm P) l1 (flat_map (cons (wn (dual A))) ls) -> 
    exists s', ll P (flat_map (app (map wn l)) ls) s'.
Proof with myeeasy ; try PCperm_solve.
intros A l ls l1 s1 IHA H.
revert ls.
induction H ; intros ls HP.
- (* ax_r *)
  apply PCperm_length_2_inv in HP.
  destruct HP as [HP | HP] ; destruct ls ;
    simpl in HP ; inversion HP ; eapply wk_list_r ; ex_apply_ax.
- (* ex_r *)
  eapply IHll...
- (* mix0_r *)
  apply PCperm_nil in HP.
  destruct ls ; inversion HP.
  eexists.
  apply (@mix0_r _ f).
- (* mix2_r *)
  hyps_PCperm_unfold ; unfold PCperm in IHll1 ; unfold PCperm in IHll2 ;
    remember (pperm P) as pp eqn:Hpp ; destruct pp.
  + destruct ls.
    * symmetry in HP.
      apply Permutation_nil in HP.
      apply app_eq_nil in HP.
      destruct HP ; subst.
      eexists...
    * assert (HP1 := perm_flat_map_app (wn (dual A) :: nil) (l0 :: ls)).
      rewrite <- flat_map_cons_is_flat_map_app in HP1.
      assert (HP2 := Permutation_trans HP HP1).
      apply Permutation_app_app_inv in HP2.
      destruct HP2 as (l3 & l4 & l5 & l6 & HP3 & HP4 & HP5 & HP6).
      destruct l3 ; destruct l4.
      -- exfalso.
         symmetry in HP5.
         apply Permutation_nil in HP5.
         inversion HP5.
      -- assert (Permutation l1 (flat_map (cons (wn (dual A)))
                                (l6 :: flat_map (fun _ => (nil :: nil)) ls)))
           as IHP.
         { apply (Permutation_trans HP4).
           symmetry in HP5.
           apply (Permutation_app_tail l6) in HP5.
           apply (Permutation_trans HP5).
           simpl ; apply Permutation_cons...
           eapply Permutation_trans ; [ apply Permutation_app_comm | ].
           apply Permutation_app_head.
           clear ; induction ls... }
         apply IHll1 in IHP.
         destruct IHP as [s' IHP].
         eexists.
         symmetry in HP6.
         eapply ex_r ; [ | unfold PCperm ; rewrite <- Hpp ; symmetry ;
           apply perm_flat_map_app ].
         apply (ex_r _ _ _ _ (@mix2_r _ f _ _ _ _ IHP H0)).
         unfold PCperm ; rewrite <- Hpp.
         simpl ; rewrite <- ? app_assoc.
         apply (Permutation_trans (Permutation_app_tail _ HP3)).
         simpl ; apply (Permutation_trans (Permutation_app_swap _ _ _)).
         apply Permutation_app_head.
         rewrite app_assoc.
         apply (Permutation_trans (Permutation_app_tail _ HP6)).
         apply (Permutation_trans (Permutation_app_comm _ _)).
         simpl ; apply Permutation_app_tail.
         clear ; induction ls...
      -- assert (Permutation l2 (flat_map (cons (wn (dual A)))
                                (l5 :: flat_map (fun _ => (nil :: nil)) ls)))
           as IHP.
         { apply (Permutation_trans HP3).
           rewrite app_nil_r in HP5 ; symmetry in HP5.
           apply (Permutation_app_tail l5) in HP5.
           apply (Permutation_trans HP5).
           simpl ; apply Permutation_cons...
           eapply Permutation_trans ; [ apply Permutation_app_comm | ].
           apply Permutation_app_head.
           clear ; induction ls... }
         apply IHll2 in IHP.
         destruct IHP as [s' IHP].
         eexists.
         symmetry in HP6.
         eapply ex_r ; [ | unfold PCperm ; rewrite <- Hpp ; symmetry ;
           apply perm_flat_map_app ].
         apply (ex_r _ _ _ _ (@mix2_r _ f _ _ _ _ H IHP)).
         unfold PCperm ; rewrite <- Hpp.
         simpl ; rewrite <- ? app_assoc.
         apply Permutation_app_head.
         rewrite ? app_assoc.
         apply (Permutation_trans (Permutation_app_head _ HP4)).
         simpl ; rewrite <- ? app_assoc.
         eapply Permutation_trans.
         ++ apply Permutation_app_rot.
         ++ apply (Permutation_trans (Permutation_app_comm _ _)).
            apply (Permutation_trans (Permutation_app_tail _
                                       (Permutation_app_comm _ _))).
            apply (Permutation_trans (Permutation_app_tail _ HP6)).
            apply (Permutation_trans (Permutation_app_comm _ _)).
            simpl ; apply Permutation_app_tail.
            clear ; induction ls...
      -- assert (HPls := HP5).
         apply perm_flat_map_const in HP5.
         destruct HP5 as [ls' HP5].
         assert ((exists ls3, (f0 :: l3) = @flat_map (list formula) _
                                           (fun _ => wn (dual A) :: nil) ls3)
              /\ (exists ls4, (f1 :: l4) = @flat_map (list formula) _
                                           (fun _ => wn (dual A) :: nil) ls4))
           as Hls.
         { remember (f0 :: l3) as l3'.
           remember (f1 :: l4) as l4'.
           clear - HP5 ; revert l3' l4' HP5 ; induction ls' ; intros l3 l4 HP.
           - apply app_eq_nil in HP.
             destruct HP ; subst.
             split ; exists nil...
           - destruct l3.
             + destruct l4 ; inversion HP.
               rewrite <- (app_nil_l l4) in H1.
               apply IHls' in H1.
               destruct H1 as [[ls3 H3] [ls4 H4]] ; subst.
               split.
               * exists nil...
               * exists (a :: ls')...
             + inversion HP.
               apply IHls' in H1.
               destruct H1 as [[ls3 H3] [ls4 H4]] ; subst.
               split.
               * exists (a :: ls3)...
               * exists ls4... }
         destruct Hls as [[ls3 Hls3] [ls4 Hls4]].
         destruct ls3 ; [inversion Hls3 | ].
         destruct ls4 ; [inversion Hls4 | ].
         assert (Permutation l1 (flat_map (cons (wn (dual A)))
                                (l6 :: flat_map (fun _ => (nil :: nil)) ls4)))
           as IHP1.
         { apply (Permutation_trans HP4).
           assert (HP4' := Permutation_refl (f1 :: l4)).
           rewrite Hls4 in HP4' at 2.
           apply (Permutation_app_tail l6) in HP4'.
           apply (Permutation_trans HP4').
           simpl ; apply Permutation_cons...
           eapply Permutation_trans ; [ apply Permutation_app_comm | ].
           apply Permutation_app_head.
           clear ; induction ls4... }
         apply IHll1 in IHP1.
         destruct IHP1 as [s1' IHP1].
         assert (Permutation l2 (flat_map (cons (wn (dual A)))
                                (l5 :: flat_map (fun _ => (nil :: nil)) ls3)))
           as IHP2.
         { apply (Permutation_trans HP3).
           assert (HP3' := Permutation_refl (f0 :: l3)).
           rewrite Hls3 in HP3' at 2.
           apply (Permutation_app_tail l5) in HP3'.
           apply (Permutation_trans HP3').
           simpl ; apply Permutation_cons...
           eapply Permutation_trans ; [ apply Permutation_app_comm | ].
           apply Permutation_app_head.
           clear ; induction ls3... }
         apply IHll2 in IHP2.
         destruct IHP2 as [s2' IHP2].
         eexists.
         eapply ex_r ; [apply (@mix2_r _ f _ _ _ _ IHP1 IHP2) | ].
         unfold PCperm ; rewrite <- Hpp ; simpl.
         rewrite Hls3 in HPls.
         rewrite Hls4 in HPls.
         rewrite <- flat_map_app in HPls.
         apply (perm_flat_map_const_subst _ (@nil formula :: nil)) in HPls ;
               [ | intro Hnil ; inversion Hnil].
         apply (Permutation_flat_map (app (map wn l))) in HPls.
         simpl in HPls ; rewrite flat_map_app in HPls.
         simpl in HPls ; rewrite flat_map_app in HPls ; simpl in HPls.
         rewrite ? app_nil_r in HPls.
         apply (Permutation_app HP6) in HPls.
         symmetry in HPls.
         eapply Permutation_trans ;
           [ eapply Permutation_trans ; [ | apply HPls] | ]...
         clear ; assert (HP := perm_flat_map_app (map wn l) (l0 :: ls)).
         simpl in HP ; symmetry in HP.
         eapply Permutation_trans ; [ | apply HP].
         assert (Permutation (flat_map (app (map wn l))
                               (flat_map (fun _ => nil :: nil) ls))
                             (flat_map (fun _ => map wn l) ls))
           as HPf by (clear ; induction ls ; perm_solve)...
  + inversion HP.
    dichot_app_exec H2 ; subst.
    * rewrite <- app_assoc in H3.
      apply (key_case_oc_subst_mix2_cperm A l ls l1 l0 l4 s1 s2)...
    * apply (key_case_oc_subst_mix2_cperm A l ls l2 l5 l3 s2 s1)...
- (* one_r *)
  apply PCperm_length_1_inv in HP.
  destruct ls ; inversion HP.
- (* bot_r *)
  key_case_oc_subst_ucase A l bot (@nil formula) bot_r IHll HP.
- (* tens_r *)
  hyps_PCperm_unfold ; unfold PCperm in IHll1 ; unfold PCperm in IHll2 ;
    remember (pperm P) as pp eqn:Hpp ; destruct pp.
  + destruct ls.
    * symmetry in HP.
      apply Permutation_nil in HP.
      inversion HP.
    * assert (HP1 := perm_flat_map_app (wn (dual A) :: nil) (l0 :: ls)).
      rewrite <- flat_map_cons_is_flat_map_app in HP1.
      assert (HP2 := Permutation_trans HP HP1).
      rewrite app_comm_cons in HP2.
      apply Permutation_app_app_inv in HP2.
      destruct HP2 as (l3 & l4 & l5 & l6 & HP3 & HP4 & HP5 & HP6).
      assert (HP3' := HP3).
      symmetry in HP3'.
      apply Permutation_vs_cons_inv in HP3'.
      destruct HP3' as (l7 & l8 & Htens).
      destruct l3 ; destruct l4.
      -- exfalso.
         symmetry in HP5.
         apply Permutation_nil in HP5.
         inversion HP5.
      -- assert (Permutation (A0 :: l1) (flat_map (cons (wn (dual A)))
                             ((A0 :: l6) :: flat_map (fun _ => (nil :: nil)) ls)))
           as IHP.
         { apply (@Permutation_cons _ A0 A0) in HP4...
           apply (Permutation_trans HP4).
           symmetry in HP5.
           apply (Permutation_app_tail l6) in HP5.
           apply (@Permutation_cons _ A0 A0) in HP5...
           apply (Permutation_trans HP5).
           simpl ; apply (Permutation_trans (perm_swap _ _ _)).
           apply Permutation_cons...
           apply Permutation_cons...
           eapply Permutation_trans ; [ apply Permutation_app_comm | ].
           apply Permutation_app_head.
           clear ; induction ls... }
         apply IHll1 in IHP.
         destruct IHP as [s' IHP].
         eexists.
         symmetry in HP6.
         eapply ex_r ;
           [ | unfold PCperm ; rewrite <- Hpp ; symmetry ; apply perm_flat_map_app ].
         simpl in IHP.
         rewrite <- ? app_assoc in IHP.
         rewrite <- ? app_comm_cons in IHP.
         eapply ex_r in IHP ;
           [ | unfold PCperm ; rewrite <- Hpp ; symmetry ; apply Permutation_middle].
         apply (ex_r _ _ _ _ (@tens_r _ _ _ _ _ _ _ IHP H0)).
         unfold PCperm ; rewrite <- Hpp.
         simpl ; rewrite <- ? app_assoc.
         apply (Permutation_trans (Permutation_app_tail _ HP3)).
         simpl ; apply (Permutation_trans (Permutation_app_swap _ _ _)).
         apply Permutation_app_head.
         rewrite app_assoc.
         apply (Permutation_trans (Permutation_app_tail _ HP6)).
         apply (Permutation_trans (Permutation_app_comm _ _)).
         simpl ; apply Permutation_app_tail.
         clear ; induction ls...
      -- assert (HPls := HP5).
         apply perm_flat_map_const in HP5.
         destruct HP5 as [ls' HP5].
         rewrite app_nil_r in HP5.
         assert (exists l9, l5 = l9 ++ tens A0 B :: l8
                         /\ (f :: l3) ++ l9 = l7) as Htens2.
         { rewrite HP5 in Htens.
           rewrite HP5.
           clear - Htens ; revert ls' l8 Htens ; induction l7 ;
             intros l9 l8 Heq ; destruct l9.
           - exists nil ; split...
           - inversion Heq.
           - destruct l5 ; inversion Heq ; subst.
             exists (a :: l7) ; split...
           - inversion Heq ; subst.
             apply IHl7 in H1.
             destruct H1 as (l11 & Heq' & Heqf).
             exists l11 ; split...
             rewrite <- Heqf... }
         destruct Htens2 as (l11 & Htens2 & Hl7).
         assert (Permutation (B :: l2) (flat_map (cons (wn (dual A)))
                             ((B :: l11 ++ l8) ::
                                    flat_map (fun _ => (nil :: nil)) ls)))
           as IHP.
         { rewrite Htens2 in HP3.
           rewrite app_assoc in HP3.
           apply Permutation_cons_app_inv in HP3.
           apply (@Permutation_cons _ B B) in HP3...
           apply (Permutation_trans HP3).
           rewrite app_nil_r in HPls ; symmetry in HPls.
           apply (Permutation_app_tail (l11 ++ l8)) in HPls.
           symmetry.
           simpl ; apply (Permutation_trans (perm_swap _ _ _)).
           apply Permutation_cons...
           symmetry.
           rewrite <- app_assoc.
           rewrite app_comm_cons.
           apply (Permutation_trans HPls).
           simpl ; apply Permutation_cons...
           eapply Permutation_trans ; [ apply Permutation_app_comm | ].
           apply Permutation_app_head.
           clear ; induction ls... }
         apply IHll2 in IHP.
         destruct IHP as [s' IHP].
         eexists.
         symmetry in HP6.
         eapply ex_r ;
           [ | unfold PCperm ; rewrite <- Hpp ; symmetry ; apply perm_flat_map_app ].
         simpl in IHP.
         rewrite <- ? app_assoc in IHP.
         rewrite <- ? app_comm_cons in IHP.
         eapply ex_r in IHP ;
           [ | unfold PCperm ; rewrite <- Hpp ; symmetry ; apply Permutation_middle].
         apply (ex_r _ _ _ _ (@tens_r _ _ _ _ _ _ _ H IHP)).
         unfold PCperm ; rewrite <- Hpp.
         simpl ; rewrite ? app_assoc.
         rewrite ? app_comm_cons. 
         apply (Permutation_trans (Permutation_app_head _ HP4)).
         rewrite <- ? app_assoc.
         rewrite <- ? app_comm_cons.
         eapply Permutation_trans ; [ apply (Permutation_middle _ _ _) | ].
         apply Permutation_app_head.
         eapply Permutation_trans ; [ apply (Permutation_middle _ _ _) | ].
         rewrite (app_comm_cons l8).
         rewrite app_assoc.
         rewrite <- Htens2.
         simpl ; apply (Permutation_trans (Permutation_app_rot _ _ _)).
         apply (Permutation_trans (Permutation_app_comm _ _)) in HP6.
         apply (Permutation_trans (Permutation_app_head _ HP6)).
         simpl ; apply Permutation_app_tail.
         clear ; induction ls...
      -- assert (HPls := HP5).
         apply perm_flat_map_const in HP5.
         destruct HP5 as [ls' HP5].
         assert ((exists ls3, (f :: l3) = @flat_map (list formula) _
                                            (fun _ => wn (dual A) :: nil) ls3)
              /\ (exists ls4, (f0 :: l4) = @flat_map (list formula) _
                                           (fun _ => wn (dual A) :: nil) ls4))
           as Hls.
         { remember (f :: l3) as l3'.
           remember (f0 :: l4) as l4'.
           clear - HP5 ; revert l3' l4' HP5 ; induction ls' ; intros l3 l4 HP.
           - apply app_eq_nil in HP.
             destruct HP ; subst.
             split ; exists nil...
           - destruct l3.
             + destruct l4 ; inversion HP.
               rewrite <- (app_nil_l l4) in H1.
               apply IHls' in H1.
               destruct H1 as [[ls3 H3] [ls4 H4]] ; subst.
               split.
               * exists nil...
               * exists (a :: ls')...
             + inversion HP.
               apply IHls' in H1.
               destruct H1 as [[ls3 H3] [ls4 H4]] ; subst.
               split.
               * exists (a :: ls3)...
               * exists ls4... }
         destruct Hls as [[ls3 Hls3] [ls4 Hls4]].
         destruct ls3 ; [inversion Hls3 | ].
         destruct ls4 ; [inversion Hls4 | ].
         assert (Permutation (A0 :: l1) (flat_map (cons (wn (dual A)))
                             ((A0 :: l6) :: flat_map (fun _ => (nil :: nil)) ls4)))
           as IHP1.
         { symmetry.
           apply (Permutation_trans (perm_swap _ _ _)).
           apply Permutation_cons...
           symmetry.
           apply (Permutation_trans HP4).
           assert (HP4' := Permutation_refl (f0 :: l4)).
           rewrite Hls4 in HP4' at 2.
           apply (Permutation_app_tail l6) in HP4'.
           apply (Permutation_trans HP4').
           simpl ; apply Permutation_cons...
           eapply Permutation_trans ; [ apply Permutation_app_comm | ].
           apply Permutation_app_head.
           clear ; induction ls4... }
         apply IHll1 in IHP1.
         destruct IHP1 as [s1' IHP1].
         assert (exists l9, l5 = l9 ++ tens A0 B :: l8
                         /\ (f :: l3) ++ l9 = l7) as Htens2.
         { rewrite Hls3 in Htens.
           rewrite Hls3.
           remember (l9 :: ls3) as l11.
           clear - Htens ; revert l11 l8 Htens ; induction l7 ;
             intros l11 l8 Heq ; destruct l11.
           - exists nil ; split...
           - inversion Heq.
           - destruct l5 ; inversion Heq ; subst.
             exists (a :: l7) ; split...
           - inversion Heq ; subst.
             apply IHl7 in H1.
             destruct H1 as (l9 & Heq' & Heqf).
             exists l9 ; split...
             rewrite <- Heqf... }
         destruct Htens2 as (l11 & Htens2 & Hl7).
         assert (Permutation (B :: l2) (flat_map (cons (wn (dual A)))
                            ((B :: (l11 ++ l8)) ::
                                   flat_map (fun _ => (nil :: nil)) ls3)))
           as IHP2.
         { symmetry.
           apply (Permutation_trans (perm_swap _ _ _)).
           apply Permutation_cons...
           symmetry.
           rewrite Htens2 in HP3.
           rewrite ? app_assoc in HP3.
           apply Permutation_cons_app_inv in HP3.
           apply (Permutation_trans HP3).
           assert (HP3' := Permutation_refl (f :: l3)).
           rewrite Hls3 in HP3' at 2.
           apply (Permutation_app_tail (l11 ++ l8)) in HP3'.
           rewrite app_assoc in HP3'.
           apply (Permutation_trans HP3').
           simpl ; apply Permutation_cons...
           eapply Permutation_trans ; [ apply Permutation_app_comm | ].
           apply Permutation_app_head.
           clear ; induction ls3... }
         apply IHll2 in IHP2.
         destruct IHP2 as [s2' IHP2].
         eexists.
         simpl in IHP1 ; rewrite <- ? app_assoc in IHP1.
         rewrite <- ? app_comm_cons in IHP1.
         eapply ex_r in IHP1 ;
           [ | unfold PCperm ; rewrite <- Hpp ; symmetry ; apply Permutation_middle].
         simpl in IHP2 ; rewrite <- ? app_assoc in IHP2.
         rewrite <- ? app_comm_cons in IHP2.
         eapply ex_r in IHP2 ;
           [ | unfold PCperm ; rewrite <- Hpp ; symmetry ; apply Permutation_middle].
         apply (ex_r _ _ _ _ (@tens_r _ _ _ _ _ _ _ IHP1 IHP2)).
         unfold PCperm ; rewrite <- Hpp.
         rewrite Hls3 in HPls.
         rewrite Hls4 in HPls.
         rewrite <- flat_map_app in HPls.
         apply (perm_flat_map_const_subst _ (@nil formula :: nil)) in HPls ;
           [ | intro Hnil ; inversion Hnil].
         apply (Permutation_flat_map (app (map wn l))) in HPls.
         simpl in HPls ; rewrite flat_map_app in HPls.
         simpl in HPls ; rewrite flat_map_app in HPls ; simpl in HPls.
         rewrite ? app_nil_r in HPls.
         apply (Permutation_app HP6) in HPls.
         symmetry.
         apply (Permutation_trans (perm_flat_map_app _ _ )).
         apply (Permutation_trans (Permutation_app_comm _ _)).
         simpl in HPls ; simpl.
         replace (flat_map (fun _ => map wn l) ls) with
                 (flat_map (app (map wn l))
                     (flat_map (fun _ => nil :: nil) ls)).
         ++ apply (Permutation_trans HPls).
            rewrite Htens2...
         ++ clear ; induction ls ; simpl...
            rewrite IHls ; rewrite app_nil_r...
  + inversion HP.
    rewrite app_comm_cons in H2.
    dichot_app_exec H2 ; [ destruct l0 | ] ; subst.
    * simpl in H1 ; subst.
      destruct ls ; inversion H3.
    * inversion H1 ; subst.
      rewrite <- app_assoc in H3.
      apply app_app_vs_flat_map in H3.
      destruct H3
        as [ (ls' & ls'' & ls''' & Heq1 & Heq2 & Heq3 & Heq4)
         | [ (x & l' & ls' & ls''' & Heq1 & Heq2 & Heq3 & Heq4)
         | [ (x & l' & ls' & ls'' & ls''' & Heq1 & Heq2 & Heq3 & Heq4 & Heq5)
         | [ (x' & l' & ls' & ls'' & ls''' & Heq1 & Heq2 & Heq3 & Heq4 & Heq5)
         |   (x & l' & x' & l'' & ls' & ls'' & ls'''
                       & Heq1 & Heq2 & Heq3 & Heq4 & Heq5 & Heq6) ]]]] ;
        subst.
      -- destruct ls''' ; inversion Heq4.
      -- destruct l' ; [ destruct ls''' | ] ; inversion Heq4 ; subst.
         assert (CPermutation (B :: (l'
                                  ++ flat_map (cons (wn (dual A))) ls''')
                                  ++ flat_map (cons (wn (dual A)))
                                                             (ls' ++ x :: nil))
                              (flat_map (cons (wn (dual A)))
                                       (ls''' ++ ls' ++ (x ++ B :: l') :: nil)))
           as HP2 by (rewrite ? flat_map_app ; cperm_solve).
         apply IHll2 in HP2.
         destruct HP2 as [s2' HP2].
         eexists.
         rewrite ? flat_map_app ; simpl.
         rewrite <- ? app_assoc ; rewrite 3 app_assoc.
         eapply ex_r ; [ | unfold PCperm ; rewrite <- Hpp ; apply cperm ].
         rewrite <- ? app_comm_cons ; rewrite 3 app_assoc.
         apply tens_r...
         apply (ex_r _ _ _ _ HP2).
         unfold PCperm ; rewrite <- Hpp.
         rewrite ? flat_map_app...
      -- destruct ls''' ; inversion Heq5.
      -- destruct l' ; [ destruct ls''' | ] ; inversion Heq5 ; subst.
         assert (CPermutation (A0 :: flat_map (cons (wn (dual A)))
                                                           (ls'' ++ x' :: nil))
                              (flat_map (cons (wn (dual A)))
                                            (ls'' ++ (x' ++ A0 :: nil) :: nil)))
           as HP1 by (rewrite ? flat_map_app ; cperm_solve).
         apply IHll1 in HP1.
         destruct HP1 as [s1' HP1].
         destruct ls' using rev_ind ; [ destruct ls''' using rev_ind | ].
         ++ eexists.
            rewrite ? flat_map_app ; simpl ; rewrite app_nil_r.
            rewrite ? app_assoc.
            eapply ex_r ; [ | unfold PCperm ; rewrite <- Hpp ; apply cperm ].
            rewrite <- ? app_comm_cons.
            simpl in H0 ; rewrite ? app_nil_r in H0.
            apply tens_r...
            apply (ex_r _ _ _ _ HP1).
            unfold PCperm ; rewrite <- Hpp.
            rewrite ? flat_map_app...
         ++ simpl in IHll2 ; rewrite app_nil_r in IHll2.
            assert (CPermutation (B :: (l' ++ flat_map (cons (wn (dual A)))
                                                               (ls''' ++ x :: nil)))
                                 (flat_map (cons (wn (dual A)))
                                                  (ls''' ++ (x ++ B :: l') :: nil)))
              as HP2 by (rewrite ? flat_map_app ; cperm_solve).
            apply IHll2 in HP2.
            destruct HP2 as [s2' HP2].
            eexists.
            rewrite ? flat_map_app ; simpl.
            rewrite ? flat_map_app ; simpl ; rewrite app_nil_r.
            rewrite <- ? app_assoc ; rewrite <- ? app_comm_cons.
            rewrite 2 app_assoc.
            eapply ex_r ; [ | unfold PCperm ; rewrite <- Hpp ; apply cperm ].
            rewrite <- ? app_comm_cons.
            apply tens_r.
            ** apply (ex_r _ _ _ _ HP1).
               unfold PCperm ; rewrite <- Hpp.
               rewrite ? flat_map_app ; simpl...
            ** apply (ex_r _ _ _ _ HP2).
               unfold PCperm ; rewrite <- Hpp.
               rewrite ? flat_map_app ; simpl...
         ++ assert (CPermutation (B :: (l'
                                    ++ flat_map (cons (wn (dual A))) ls''')
                                    ++ flat_map (cons (wn (dual A)))
                                                                (ls' ++ x :: nil))
                                 (flat_map (cons (wn (dual A)))
                                         (ls''' ++ ls' ++ (x ++ B :: l') :: nil)))
              as HP2 by (rewrite ? flat_map_app ; cperm_solve).
            apply IHll2 in HP2.
            destruct HP2 as [s2' HP2].
            eexists.
            rewrite ? flat_map_app ; simpl.
            rewrite <- ? app_assoc ; rewrite <- ? app_comm_cons.
            rewrite 6 app_assoc.
            eapply ex_r ; [ | unfold PCperm ; rewrite <- Hpp ; apply cperm ].
            rewrite <- ? app_comm_cons.
            rewrite <- ? app_assoc ; rewrite 4 app_assoc.
            apply tens_r.
            ** apply (ex_r _ _ _ _ HP1).
               unfold PCperm ; rewrite <- Hpp.
               rewrite ? flat_map_app ; simpl...
            ** apply (ex_r _ _ _ _ HP2).
               unfold PCperm ; rewrite <- Hpp.
               rewrite ? flat_map_app ; simpl...
      -- destruct l'' ; [ destruct ls''' | ] ; inversion Heq6 ; subst.
         assert (CPermutation (A0 :: l' ++ flat_map (cons (wn (dual A)))
                                                                 (ls'' ++ x' :: nil))
                              (flat_map (cons (wn (dual A)))
                                                  (ls'' ++ (x' ++ A0 :: l') :: nil)))
           as HP1 by (rewrite ? flat_map_app ; cperm_solve).
         apply IHll1 in HP1.
         destruct HP1 as [s1' HP1].
         assert (CPermutation (B :: (l'' ++ flat_map (cons (wn (dual A))) ls''')
                                         ++ flat_map (cons (wn (dual A)))
                                                                   (ls' ++ x :: nil))
                              (flat_map (cons (wn (dual A)))
                                           (ls''' ++ ls' ++ (x ++ B :: l'') :: nil)))
           as HP2 by (rewrite ? flat_map_app ; cperm_solve).
         apply IHll2 in HP2.
         destruct HP2 as [s2' HP2].
         eexists.
         rewrite ? flat_map_app ; simpl.
         rewrite ? flat_map_app ; simpl.
         rewrite <- ? app_assoc ; rewrite <- ? app_comm_cons.
         rewrite 6 app_assoc.
         eapply ex_r ; [ | unfold PCperm ; rewrite <- Hpp ; apply cperm ].
         rewrite <- ? app_comm_cons.
         rewrite <- ? app_assoc ; rewrite 4 app_assoc.
         apply tens_r.
         ++ apply (ex_r _ _ _ _ HP1).
            unfold PCperm ; rewrite <- Hpp.
            rewrite ? flat_map_app ; simpl...
         ++ apply (ex_r _ _ _ _ HP2).
            unfold PCperm ; rewrite <- Hpp.
            rewrite ? flat_map_app ; simpl...
    * apply app_app_vs_flat_map in H3.
      destruct H3
        as [ (ls' & ls'' & ls''' & Heq1 & Heq2 & Heq3 & Heq4)
         | [ (x & l' & ls' & ls''' & Heq1 & Heq2 & Heq3 & Heq4)
         | [ (x & l' & ls' & ls'' & ls''' & Heq1 & Heq2 & Heq3 & Heq4 & Heq5)
         | [ (x' & l' & ls' & ls'' & ls''' & Heq1 & Heq2 & Heq3 & Heq4 & Heq5)
         |   (x & l' & x' & l'' & ls' & ls'' & ls''' &
                Heq1 & Heq2 & Heq3 & Heq4 & Heq5 & Heq6) ]]]] ;
        subst.
      -- destruct ls'' ; inversion Heq3.
      -- assert (CPermutation (A0 :: (l' ++ flat_map (cons (wn (dual A))) ls''') 
                                  ++ flat_map (cons (wn (dual A)))
                                                                   (ls' ++ x :: nil))
                              (flat_map (cons (wn (dual A)))
                                           (ls''' ++ ls' ++ (x ++ A0 :: l') :: nil)))
           as HP1 by (rewrite ? flat_map_app ; cperm_solve).
         apply IHll1 in HP1.
         destruct HP1 as [s1' HP1].
         eexists.
         rewrite ? flat_map_app ; simpl.
         rewrite <- ? app_assoc ; rewrite <- ? app_comm_cons ; rewrite <- ? app_assoc.
         rewrite 2 app_assoc.
         eapply ex_r ; [ | unfold PCperm ; rewrite <- Hpp ; apply cperm ].
         rewrite <- ? app_comm_cons.
         rewrite <- ? app_assoc.
         apply tens_r...
         apply (ex_r _ _ _ _ HP1).
         unfold PCperm ; rewrite <- Hpp.
         rewrite ? flat_map_app ; simpl...
      -- destruct l' ; [ destruct ls'' | ] ; inversion Heq4 ; subst.
         assert (CPermutation (A0 :: flat_map (cons (wn (dual A))) ls'''
                                  ++ flat_map (cons (wn (dual A)))
                                                               (ls' ++ x :: nil))
                              (flat_map (cons (wn (dual A)))
                                      (ls''' ++ ls' ++ (x ++ A0 :: nil) :: nil)))
           as HP1 by (rewrite ? flat_map_app ; cperm_solve).
         apply IHll1 in HP1.
         destruct HP1 as [s1' HP1].
         destruct ls'' using rev_ind.
         ++ eexists.
            rewrite ? flat_map_app ; simpl.
            rewrite <- ? app_assoc ; rewrite 2 app_assoc.
            eapply ex_r ; [ | unfold PCperm ; rewrite <- Hpp ; apply cperm ].
            rewrite <- ? app_comm_cons.
            rewrite <- ? app_assoc.
            simpl in H0 ; rewrite ? app_nil_r in H0.
            apply tens_r...
            apply (ex_r _ _ _ _ HP1).
            unfold PCperm ; rewrite <- Hpp.
            rewrite ? flat_map_app...
         ++ assert (CPermutation (B :: l' ++ flat_map (cons (wn (dual A)))
                                                                (ls'' ++ x0 :: nil))
                                 (flat_map (cons (wn (dual A)))
                                                  (ls'' ++ (x0 ++ B :: l') :: nil)))
              as HP2 by (rewrite ? flat_map_app ; cperm_solve).
            apply IHll2 in HP2.
            destruct HP2 as [s2' HP2].
            eexists.
            rewrite ? flat_map_app ; simpl.
            rewrite ? flat_map_app ; simpl ; rewrite app_nil_r.
            rewrite <- ? app_assoc ; rewrite 2 app_assoc.
            eapply ex_r ; [ | unfold PCperm ; rewrite <- Hpp ; apply cperm ].
            rewrite <- ? app_comm_cons.
            rewrite <- ? app_assoc ; rewrite 3 app_assoc.
            apply tens_r.
            ** apply (ex_r _ _ _ _ HP1).
               unfold PCperm ; rewrite <- Hpp.
               rewrite ? flat_map_app ; simpl...
            ** apply (ex_r _ _ _ _ HP2).
               unfold PCperm ; rewrite <- Hpp.
               rewrite ? flat_map_app ; simpl...
      -- destruct ls'' ; inversion Heq4.
      -- destruct l' ; [ destruct ls'' | ] ; inversion Heq5 ; subst.
         assert (CPermutation (A0 :: (l'' ++ flat_map (cons (wn (dual A))) ls''')
                                  ++ flat_map (cons (wn (dual A)))
                                                                    (ls' ++ x :: nil))
                              (flat_map (cons (wn (dual A)))
                                           (ls''' ++ ls' ++ (x ++ A0 :: l'') :: nil)))
           as HP1 by (rewrite ? flat_map_app ; cperm_solve).
         apply IHll1 in HP1.
         destruct HP1 as [s1' HP1].
         assert (CPermutation (B :: l' ++ flat_map (cons (wn (dual A)))
                                                                  (ls'' ++ x' :: nil))
                              (flat_map (cons (wn (dual A)))
                                                    (ls'' ++ (x' ++ B :: l') :: nil)))
           as HP2 by (rewrite ? flat_map_app ; cperm_solve).
         apply IHll2 in HP2.
         destruct HP2 as [s2' HP2].
         eexists.
         rewrite ? flat_map_app ; simpl.
         rewrite ? flat_map_app ; simpl.
         rewrite <- ? app_assoc ; rewrite 2 app_assoc.
         eapply ex_r ; [ | unfold PCperm ; rewrite <- Hpp ; apply cperm ].
         rewrite <- ? app_comm_cons.
         rewrite <- ? app_assoc ; rewrite 3 app_assoc.
         apply tens_r.
         ++ apply (ex_r _ _ _ _ HP1).
            unfold PCperm ; rewrite <- Hpp.
            rewrite ? flat_map_app ; simpl...
         ++ apply (ex_r _ _ _ _ HP2).
            unfold PCperm ; rewrite <- Hpp.
            rewrite ? flat_map_app ; simpl...
- (* parr_r *)
  key_case_oc_subst_ucase A l (parr A0 B) (A0 :: B :: nil) parr_r IHll HP.
- (* top_r *)
  destruct (PCperm_subst_flat_map _ _ (map wn l) _ _ _ HP)
    as [ [l1 HP1] | (HeqA & x & ls' & ls'' & Heqls & HP1) ].
  + destruct (HP1 nil) as (ls' & Hls1 & Hls2 & Hls3).
    eexists.
    eapply ex_r...
    eapply top_r.
  + inversion HeqA.
- (* plus_r1 *)
  key_case_oc_subst_ucase A l (aplus A0 B) (A0 :: nil) plus_r1 IHll HP.
- (* plus_r2 *)
  key_case_oc_subst_ucase A l (aplus B A0) (A0 :: nil) plus_r2 IHll HP.
- (* with_r *)
  hyps_PCperm_unfold ; unfold PCperm in IHll1 ; unfold PCperm in IHll2 ;
    remember (pperm P) as pp eqn:Hpp ; destruct pp.
  + destruct (perm_subst_flat_map _ (map wn l) _ _ _ HP)
        as [ [l1 HP1] | (HeqA & x & ls' & ls'' & Heqls & HP1) ].
    * destruct (HP1 (A0 :: nil)) as (ls' & Hls1 & Hls2 & Hls3).
      apply IHll1 in Hls1.
      destruct Hls1 as [s' Hls1].
      destruct (HP1 (B :: nil)) as (ls'' & Hls1' & Hls2' & Hls3').
      apply IHll2 in Hls1'.
      destruct Hls1' as [s'' Hls1'].
      eexists.
      eapply ex_r.
      -- eapply with_r.
         ++ eapply ex_r.
            apply Hls1.
            unfold PCperm ; rewrite <- Hpp ; apply Hls2.
         ++ eapply ex_r ; [ | unfold PCperm ; rewrite <- Hpp ].
            apply Hls1'.
            apply Hls2'.
       -- unfold PCperm ; rewrite <- Hpp...
    * inversion HeqA.
  + symmetry in HP.
    apply cperm_vs_cons_inv in HP.
    destruct HP as (l0l & l0r & Heq & HP) ; subst.
    symmetry in HP.
    destruct (elt_subst_flat_map _ (map wn l) _ _ _ _ HP)
      as [ (l1l & l1r & Hls0) | (HeqA & x & ls0' & ls0'' & Heqls & HP1) ].
    * destruct (Hls0 (A0 :: nil)) as (ls' & Hls1 & Hls2 & Hls3).
      destruct (Hls0 (B :: nil)) as (ls'' & Hls1' & Hls2' & Hls3').
      assert (CPermutation (A0 :: l0r ++ l0l) (l0l ++ A0 :: l0r))
        as Hls1'' by cperm_solve.
      simpl in Hls1.
      rewrite Hls1 in Hls1''.
      apply IHll1 in Hls1''.
      destruct Hls1'' as [s' Hls1''].
      assert (CPermutation (B :: l0r ++ l0l) (l0l ++ B :: l0r))
        as Hls1''' by cperm_solve.
      simpl in Hls1'.
      rewrite Hls1' in Hls1'''.
      apply IHll2 in Hls1'''.
      destruct Hls1''' as [s'' Hls1'''].
      eexists.
      rewrite <- Hls3.
      eapply ex_r.
      eapply with_r.
      -- apply (ex_r _ (l1l ++ A0 :: l1r) (A0 :: l1r ++ l1l))...
         simpl in Hls2.
         rewrite Hls2...
      -- apply (ex_r _ (l1l ++ B :: l1r) (B :: l1r ++ l1l))...
         simpl in Hls2'.
         rewrite Hls2'...
      -- PCperm_solve.
    * inversion HeqA.
- (* oc_r *)
  hyps_PCperm_unfold ; unfold PCperm in IHll ;
    remember (pperm P) as pp eqn:Hpp ; destruct pp.
  + destruct (perm_subst_flat_map _ (map wn l) _ _ _ HP)
      as [ [l1 HP1] | (HeqA & x & ls0' & ls0'' & Heqls & HP1) ].
    * destruct (HP1 (A0 :: nil)) as (ls' & Hls1 & Hls2 & Hls3).
      apply IHll in Hls1.
      destruct Hls1 as [s' Hls1].
      destruct (HP1 nil) as (ls'' & Hls1' & Hls2' & Hls3').
      assert (exists l1', l1 = map wn l1') as [l1' Hwn].
      { simpl in Hls1'.
        symmetry in Hls1'.
        apply Permutation_map_inv in Hls1'.
        destruct Hls1' as (l2 & Heq & _).
        apply (flat_map_wn_subst _ l) in Heq.
        destruct Heq as [l1' Hwn].
        rewrite Hwn in Hls2'.
        simpl in Hls2'.
        symmetry in Hls2'.
        apply Permutation_map_inv in Hls2'.
        destruct Hls2' as (l1'0 & Hls2' & _).
        eexists... }
      eexists.
      eapply ex_r ; [ | unfold PCperm ; rewrite <- Hpp ; apply Hls3' ].
      rewrite Hwn.
      apply oc_r.
      rewrite <- Hwn.
      simpl in Hls2.
      eapply ex_r ; [ | unfold PCperm ; rewrite <- Hpp]...
    * inversion HeqA.
  + symmetry in HP.
    apply cperm_vs_cons_inv in HP.
    destruct HP as (l0l & l0r & Heq & HP).
    symmetry in HP.
    destruct (elt_subst_flat_map _ (map wn l) _ _ _ _ HP)
      as [ (ls' & l1 & Hls0) | (HeqA & x & ls' & ls'' & Heqls & HP1) ].
    * destruct (Hls0 (A0 :: nil)) as (ls'' & Hls1 & Hls2 & Hls3).
      assert (CPermutation (A0 :: l0r ++ l0l) (l0l ++ A0 :: l0r))
        as Hls1'' by cperm_solve.
      simpl in Hls1.
      rewrite Hls1 in Hls1''.
      rewrite <- Heq in Hls1''.
      apply IHll in Hls1''.
      destruct Hls1'' as [s' Hls1''].
      destruct (Hls0 nil) as (ls''' & Hls1' & Hls2' & Hls3').
      assert (exists l1', l1 ++ ls' = map wn l1') as [l1' Hwn].
      { simpl in Hls1'.
        assert (CPermutation (l0l ++ l0r) (l0r ++ l0l))
          as HP2 by apply cperm.
        rewrite Hls1' in HP2.
        rewrite <- Heq in HP2.
        apply cperm_map_inv in HP2.
        destruct HP2 as [l1' HP2].
        apply (flat_map_wn_subst _ l) in HP2.
        destruct HP2 as [l' HP2].
        rewrite HP2 in Hls2'.
        simpl in Hls2'.
        decomp_map Hls2' ; subst.
        exists (l4 ++ l3).
        rewrite map_app... }
      eexists.
      assert (CPermutation (oc A0 :: l1 ++ ls') (ls' ++ oc A0 :: l1))
        as Hls3'' by cperm_solve.
      rewrite Hls3' in Hls3''.
      eapply ex_r ; [ | unfold PCperm ; rewrite <- Hpp ; apply Hls3'' ].
      rewrite Hwn.
      apply oc_r.
      rewrite <- Hwn.
      assert (CPermutation (A0 :: l1 ++ ls') (ls' ++ A0 :: l1))
        as Hls2'' by cperm_solve.
      simpl in Hls2.
      rewrite Hls2 in Hls2''.
      eapply ex_r ; [ | unfold PCperm ; rewrite <- Hpp]...
    * inversion HeqA.
- (* de_r *)
  key_case_oc_subst_ucase A l (wn A0) (A0 :: nil) de_r IHll HP.
  inversion HeqA ; subst.
  destruct ls0 using rev_ind.
  + destruct ls'' using rev_ind ; simpl in HP0 ; simpl.
    * specialize HP0 with ((dual A) :: nil).
      rewrite app_nil_r in HP0.
      rewrite app_nil_r.
      rewrite <- (app_nil_l (map wn l ++ x)).
      eapply IHA.
      apply (ex_r _ _ _ _ H)...
    * assert (PCperm (pperm P) (dual A :: l0)
                          (flat_map (cons (wn (dual A)))
                                 (ls'' ++ ((x0 ++ dual A :: x) :: nil))))
        as HP2.
      { specialize HP0 with (dual A :: nil).
        rewrite flat_map_app in HP0.
        rewrite ? flat_map_app.
        apply (PCperm_trans _ _ _ _ HP0)... }
      apply IHll in HP2.
      destruct HP2 as [s' HP2].
      rewrite flat_map_app in HP2.
      simpl in HP2.
      rewrite app_nil_r in HP2.
      rewrite ? app_assoc in HP2.
      apply IHA in HP2.
      destruct HP2 as [s'' HP2].
      eexists.
      rewrite flat_map_app.
      eapply ex_r...
  + assert (PCperm (pperm P) (dual A :: l0)
                        (flat_map (cons (wn (dual A)))
                                   (ls0 ++ (x0 ++ dual A :: x) :: ls'')))
      as HP2.
    { specialize HP0 with (dual A :: nil).
      rewrite flat_map_app in HP0.
      rewrite ? flat_map_app.
      apply (PCperm_trans _ _ _ _ HP0)... }
    apply IHll in HP2.
    destruct HP2 as [s' HP2].
    rewrite flat_map_app in HP2.
    simpl in HP2.
    rewrite <- ? app_assoc in HP2.
    rewrite 2 app_assoc in HP2.
    rewrite <- app_comm_cons in HP2.
    apply IHA in HP2.
    destruct HP2 as [s'' HP2].
    eexists.
    rewrite ? flat_map_app.
    eapply ex_r...
- (* wk_r *)
  key_case_oc_subst_ucase A l (wn A0) (@nil formula) wk_r IHll HP.
  inversion HeqA ; subst.
  destruct ls0 using rev_ind.
  + destruct ls'' using rev_ind ; simpl in HP0 ; simpl.
    * specialize HP0 with nil.
      rewrite app_nil_r in HP0 ; simpl in HP0.
      rewrite app_nil_r.
      apply (ex_r _ _ _ _ H) in HP0.
      eapply wk_list_r...
    * assert (PCperm (pperm P) l0
                          (flat_map (cons (wn (dual A)))
                                  (ls'' ++ ((x0 ++ x) :: nil))))
        as HP2.
      { specialize HP0 with nil.
        rewrite flat_map_app in HP0.
        rewrite ? flat_map_app.
        apply (PCperm_trans _ _ _ _ HP0)... }
      apply IHll in HP2.
      destruct HP2 as [s' HP2].
      rewrite flat_map_app in HP2.
      simpl in HP2.
      rewrite app_nil_r in HP2.
      rewrite ? app_assoc in HP2.
      rewrite flat_map_app.
      rewrite <- ? app_assoc.
      eapply wk_list_r.
      eapply ex_r...
  + assert (PCperm (pperm P) l0
                        (flat_map (cons (wn (dual A)))
                                   (ls0 ++ (x0 ++ x) :: ls'')))
        as HP2.
    { specialize HP0 with nil.
      rewrite flat_map_app in HP0.
      rewrite ? flat_map_app.
      apply (PCperm_trans _ _ _ _ HP0)... }
    apply IHll in HP2.
    destruct HP2 as [s' HP2].
    rewrite flat_map_app in HP2.
    simpl in HP2.
    rewrite <- ? app_assoc in HP2.
    apply (ex_r _ _ (x ++ flat_map (app (map wn l)) ls''
                       ++ flat_map (app (map wn l))
                                         ls0 ++ map wn l ++ x0))
      in HP2...
    apply (wk_list_r l) in HP2.
    destruct HP2 as [s'' HP2].
    eexists.
    rewrite ? flat_map_app.
    eapply ex_r...
- (* co_r *)
  hyps_PCperm_unfold ; unfold PCperm in IHll ;
    remember (pperm P) as pp eqn:Hpp ; destruct pp.
  + destruct (perm_subst_flat_map _ (map wn l) _ _ _ HP)
      as [ [l1 HP1] | (HeqA & x & ls0' & ls0'' & Heqls & HP1) ].
    * destruct (HP1 (wn A0 :: wn A0 :: nil)) as (ls' & Hls1 & Hls2 & Hls3).
      simpl in Hls1.
      assert (Permutation (wn A0 :: map wn lw ++ wn A0 :: l0)
                          (wn A0 :: wn A0 :: map wn lw ++ l0))
        as HP2 by perm_solve.
      apply (Permutation_trans HP2) in Hls1.
      apply IHll in Hls1.
      destruct Hls1 as [s' Hls1].
      eexists.
      eapply ex_r ; [ | unfold PCperm ; rewrite <- Hpp ; apply Hls3 ].
      rewrite <- (app_nil_l l1).
      change nil with (map wn nil).
      apply co_r.
      eapply ex_r ; [ | unfold PCperm ; rewrite <- Hpp]...
    * inversion HeqA ; subst.
      assert (Permutation (wn (dual A) ::
                              map wn lw ++ wn (dual A) :: l0)
                          (flat_map (cons (wn (dual A)))
                                            (nil :: ls0' ++ x :: ls0'')))
        as HP2 by perm_solve.
      apply IHll in HP2.
      destruct HP2 as [s' HP2].
      simpl in HP2.
      rewrite app_nil_r in HP2.
      rewrite flat_map_app in HP2.
      rewrite flat_map_app.
      assert (PCperm (pperm P)
                 (map wn l ++ flat_map (app (map wn l)) ls0'
                                  ++ flat_map (app (map wn l)) (x :: ls0''))
                 (map wn l ++ map wn nil ++ map wn l
                                  ++ flat_map (app (map wn l)) ls0'
                                  ++ x ++ flat_map (app (map wn l)) ls0''))
        as HP3 by (unfold PCperm ; rewrite <- Hpp ; perm_solve).
      apply (ex_r _ _ _ _ HP2) in HP3.
      apply co_list_r in HP3.
      destruct HP3 as [s'' HP3].
      eexists.
      eapply ex_r ; [ | unfold PCperm ; rewrite <- Hpp ]...
  + inversion HP ; clear HP.
    rewrite app_comm_cons in H1.
    dichot_app_exec H1 ; subst.
    * rewrite <- app_assoc in H2.
      replace (wn A0 :: map wn lw) with (map wn (A0 :: lw)) in H0...
      decomp_map H0 ; subst.
      apply app_app_vs_flat_map in H2.
      destruct H2
        as [ (ls' & ls'' & ls''' & Heq1 & Heq2 & Heq3 & Heq4)
         | [ (x & l' & ls' & ls''' & Heq1 & Heq2 & Heq3 & Heq4)
         | [ (x & l' & ls' & ls'' & ls''' & Heq1 & Heq2 & Heq3 & Heq4 & Heq5)
         | [ (x' & l' & ls' & ls'' & ls''' & Heq1 & Heq2 & Heq3 & Heq4 & Heq5)
         |   (x & l' & x' & l'' & ls' & ls'' & ls''' &
                Heq1 & Heq2 & Heq3 & Heq4 & Heq5 & Heq6) ]]]].
      -- destruct l4 ; destruct ls''' ; inversion Heq4.
         ++ simpl in H0 ; subst.
            destruct ls' ; inversion Heq2 ; subst.
            assert (CPermutation
                      (wn (dual A) :: map wn lw ++
                         wn (dual A) :: flat_map (cons (wn (dual A))) ls'')
                      (flat_map (cons (wn (dual A))) (l0 :: ls' ++ nil :: ls'')))
              as HC.
            { rewrite H2.
              simpl ; rewrite flat_map_app... }
            apply IHll in HC.
            destruct HC as [s' HC].
            simpl in HC ; rewrite ? flat_map_app in HC.
            simpl in HC ; rewrite <- ? app_assoc in HC.
            symmetry in Heq2.
            apply (flat_map_wn_subst _ l) in Heq2.
            destruct Heq2 as [l' Heq2].
            simpl in Heq2.
            rewrite <- app_assoc in Heq2.
            decomp_map Heq2.
            rewrite Heq2 in HC.
            rewrite Heq5 in HC.
            rewrite ? app_assoc in HC.
            rewrite <- (app_assoc _ (map wn l4) _) in HC.
            rewrite <- (map_app _ l4 l5) in HC.
            simpl in HC ; rewrite <- ? app_assoc in HC.
            apply co_list_r in HC.
            destruct HC as [s'' HC].
            rewrite map_app in HC.
            rewrite <- Heq2 in HC.
            rewrite <- Heq5 in HC.
            rewrite <- ? app_assoc in HC.
            eexists.
            rewrite ? flat_map_app.
            simpl ; rewrite <- ? app_assoc.
            rewrite app_nil_r...
         ++ inversion H0 ; subst ; subst.
            assert (CPermutation
                      (wn (dual A) :: map wn (l4 ++ l5) ++
                         wn (dual A) :: flat_map (cons (wn (dual A))) ls'')
                      (flat_map (cons (wn (dual A)))
                                                (l1 :: ls''' ++ ls' ++ nil :: ls'')))
              as HC.
            { rewrite ? map_app.
              rewrite H3.
              rewrite Heq2.
              simpl ; rewrite ? flat_map_app... }
            apply IHll in HC.
            destruct HC as [s' HC].
            symmetry in H3.
            decomp_map H3 ; subst.
            apply (flat_map_wn_subst _ l) in H4.
            destruct H4 as [lw1 Heq1].
            symmetry in Heq2.
            apply (flat_map_wn_subst _ l) in Heq2.
            destruct Heq2 as [lw2 Heq2].
            simpl in HC ; rewrite ? flat_map_app in HC.
            rewrite <- ? app_assoc in HC.
            rewrite Heq1 in HC.
            rewrite Heq2 in HC.
            replace 
              (map wn l2 ++ map wn lw1 ++ map wn lw2 ++ flat_map (app (map wn l))
                                                                        (nil :: ls''))
            with (map wn (l2 ++ lw1 ++ lw2) ++ flat_map (app (map wn l))
                                                                        (nil :: ls''))
              in HC ; [ | rewrite ? map_app ; rewrite <- ? app_assoc ; myeasy].
            simpl in HC ; rewrite <- app_assoc in HC.
            apply co_list_r in HC.
            destruct HC as [s'' HC].
            rewrite ? map_app in HC.
            rewrite <- Heq1 in HC.
            rewrite <- Heq2 in HC.
            eexists.
            eapply ex_r ; [ apply HC | unfold PCperm ; rewrite <- Hpp ]...
            simpl ; rewrite ? flat_map_app ; rewrite <- ? app_assoc ; simpl...
      -- destruct l' ; [ exfalso ; apply Heq1 ; myeasy | ].
         destruct l4 ; inversion Heq4.
         inversion H0 ; subst.
         assert (CPermutation
                  (wn A0 :: map wn (l4 ++ l5) ++ wn A0 :: l0)
                  (flat_map (cons (wn (dual A)))
                            (ls''' ++ ls' ++
                                (x ++ wn A0 :: l0 ++ wn A0 :: l') :: nil)))
           as HC.
         { rewrite ? map_app.
           rewrite H3.
           rewrite Heq3.
           simpl ; rewrite ? flat_map_app... }
         apply IHll in HC.
         destruct HC as [s' HC].
         rewrite ? flat_map_app in HC ; simpl in HC.
         rewrite app_nil_r in HC.
         apply (ex_r _ _
           (wn A0 :: l' ++ flat_map (app (map wn l)) ls''' ++
               flat_map (app (map wn l)) ls' ++
               map wn l ++ x ++ wn A0 :: l0))
           in HC ; [ | unfold PCperm ; rewrite <- Hpp ]...
         symmetry in H3.
         decomp_map H3.
         apply (flat_map_wn_subst _ l) in H4.
         clear Heq1.
         destruct H4 as [lw1 Heq1].
         rewrite flat_map_app in Heq3 ; simpl in Heq3 ; rewrite app_nil_r in Heq3.
         symmetry in Heq3.
         decomp_map Heq3 ; subst.
         apply (flat_map_wn_subst _ l) in Heq2.
         destruct Heq2 as [lw2 Heq2].
         rewrite Heq1 in HC.
         rewrite Heq2 in HC.
         rewrite ? app_assoc in HC.
         rewrite <- ? map_app in HC.
         apply co_r in HC.
         rewrite <- ? app_assoc in HC.
         rewrite ? map_app in HC.
         rewrite <- Heq1 in HC.
         rewrite <- Heq2 in HC.
         eexists.
         eapply ex_r ; [ apply HC | unfold PCperm ; rewrite <- Hpp ]...
         rewrite ? flat_map_app...
      -- destruct l4 ; destruct ls''' ; inversion Heq5.
         ++ destruct l5 ; inversion H0 ; subst.
            destruct ls' ; simpl in Heq3 ; inversion Heq3 ; subst.
            ** rewrite app_nil_r in H3 ; subst.
               assert (CPermutation
                         (wn (dual A) :: map wn lw ++
                            wn (dual A) :: l' ++
                                        flat_map (cons (wn (dual A))) ls'')
                         (flat_map (cons (wn (dual A)))
                                              (map wn lw :: l' :: ls'')))
                 as HC...
               apply IHll in HC.
               destruct HC as [s' HC].
               simpl in HC ; rewrite <- ? app_assoc in HC.
               apply co_list_r in HC.
               destruct HC as [s'' HC].
               eexists.
               list_simpl...
            ** symmetry in H3.
               decomp_map H3 ; subst.
               assert (CPermutation
                         (wn (dual A) :: map wn (l2 ++ l3) ++
                            wn (dual A) :: l'
                                         ++ flat_map (cons (wn (dual A))) ls'')
                         (flat_map (cons (wn (dual A)))
                                      (map wn l2 :: ls' ++ x :: l' :: ls'')))
                 as HC.
               { rewrite map_app.
                 rewrite <- H4.
                 simpl ; rewrite ? flat_map_app... }
               apply IHll in HC.
               destruct HC as [s' HC].
               simpl in HC ; rewrite ? flat_map_app in HC ; simpl in HC.
               rewrite <- ? app_assoc in HC.
               apply (flat_map_wn_subst _ l) in H4.
               destruct H4 as [lw1 H1].
               rewrite flat_map_app in H1 ; simpl in H1 ; rewrite app_nil_r in H1.
               decomp_map H1.
               rewrite H3 in HC.
               rewrite H5 in HC.
               rewrite (app_assoc _ (map wn l1)) in HC.
               rewrite <- map_app in HC.
               rewrite (app_assoc _ (map wn l)) in HC.
               rewrite <- map_app in HC.
               rewrite (app_assoc _ (map wn l6)) in HC.
               rewrite <- map_app in HC.
               apply co_list_r in HC.
               destruct HC as [s'' HC].
               eexists.
               rewrite ? map_app in HC.
               rewrite <- H3 in HC.
               rewrite <- H5 in HC.
               rewrite <- ? app_assoc in HC.
               simpl ; rewrite ? flat_map_app.
               simpl ; rewrite app_nil_r ; rewrite <- ? app_assoc...
         ++ inversion H0 ; subst ; subst.
            assert (CPermutation
                      (wn (dual A) :: map wn (l4 ++ l5) ++
                         wn (dual A) :: l' ++
                                        flat_map (cons (wn (dual A))) ls'')
                      (flat_map (cons (wn (dual A)))
                              (l1 :: ls''' ++ ls' ++ (x :: nil) ++ l' :: ls'')))
              as HC.
            { rewrite ? map_app.
              rewrite H3.
              rewrite Heq3.
              simpl ; rewrite ? flat_map_app... }
            apply IHll in HC.
            destruct HC as [s' HC].
            symmetry in H3.
            decomp_map H3 ; subst.
            apply (flat_map_wn_subst _ l) in H4.
            destruct H4 as [lw1 H1].
            symmetry in Heq3.
            apply (flat_map_wn_subst _ l) in Heq3.
            destruct Heq3 as [lw2 Heq3].
            rewrite flat_map_app in Heq3 ; simpl in Heq3 ; rewrite app_nil_r in Heq3.
            decomp_map Heq3 ; subst.
            simpl in HC ; rewrite ? flat_map_app in HC.
            rewrite <- ? app_assoc in HC.
            rewrite H1 in HC.
            rewrite Heq2 in HC.
            simpl in HC ; rewrite <- ? app_assoc in HC.
            rewrite (app_assoc _ (map wn lw1)) in HC.
            rewrite <- map_app in HC.
            rewrite (app_assoc _ (map wn l1)) in HC.
            rewrite <- map_app in HC.
            rewrite (app_assoc _ (map wn l)) in HC.
            rewrite <- map_app in HC.
            rewrite (app_assoc _ (map wn l7)) in HC.
            rewrite <- map_app in HC.
            apply co_list_r in HC.
            destruct HC as [s'' HC].
            eexists.
            rewrite ? map_app in HC.
            rewrite <- H1 in HC.
            rewrite <- Heq2 in HC.
            rewrite <- ? app_assoc in HC.
            simpl ; rewrite ? flat_map_app.
            simpl ; rewrite ? flat_map_app.
            simpl ; rewrite <- ? app_assoc...
            eapply ex_r ; [ | unfold PCperm ; rewrite <- Hpp ]...
      -- destruct l4 ; destruct l' ; inversion Heq5 ;
           try (exfalso ; apply Heq1 ; myeasy ; fail).
         inversion H0 ; subst.
         destruct l5 ; destruct ls' using rev_ind ; inversion Heq3.
         ++ destruct ls''' using rev_ind.
            ** assert (CPermutation
                       (wn A0 :: map wn l4 ++
                          wn A0 :: flat_map (cons (wn (dual A)))
                                                                 (ls'' ++ x' :: nil))
                       (flat_map (cons (wn (dual A)))
                          ((x' ++ (wn A0) :: (l' ++ wn A0 :: nil)) :: ls'')))
                 as HC.
               { rewrite ? map_app.
                rewrite H3.
                simpl ; rewrite ? flat_map_app... }
               rewrite app_nil_r in IHll.
               apply IHll in HC.
               destruct HC as [s' HC].
               simpl in HC.
               eapply (ex_r _ _ (wn A0 :: l' ++ wn A0 :: flat_map (app (map wn l)) ls''
                                           ++ map wn l ++ x'))
                 in HC ; [ | unfold PCperm ; rewrite <- Hpp ]...
               rewrite app_nil_r in H3 ; subst.
               apply co_r in HC.
               eexists.
               rewrite ? flat_map_app ; simpl ; rewrite app_nil_r.
               eapply ex_r ; [ | unfold PCperm ; rewrite <- Hpp ]...
            ** assert (CPermutation
                       (wn A0 :: map wn l4 ++
                          wn A0 :: flat_map (cons (wn (dual A)))
                                                     (ls'' ++ x' :: nil))
                       (flat_map (cons (wn (dual A)))
                          ((x' ++ ((wn A0) :: l')) :: ls'''
                                            ++ (x ++ wn A0 :: nil) :: ls'')))
                 as HC.
               { rewrite ? map_app.
                 rewrite H3.
                 simpl ; rewrite ? flat_map_app... }
               rewrite app_nil_r in IHll.
               apply IHll in HC.
               destruct HC as [s' HC].
               simpl in HC ; rewrite ? flat_map_app in HC ; simpl in HC.
               eapply (ex_r _ _ (wn A0 :: (l' ++ flat_map (app (map wn l)) ls''' ++
                                map wn l ++ x) ++ wn A0 ::
                                     flat_map (app (map wn l)) ls'' ++ map wn l ++ x'))
                 in HC ; [ | unfold PCperm ; rewrite <- Hpp ]...
               symmetry in H3.
               decomp_map H3.
               apply (flat_map_wn_subst _ l) in H4.
               destruct H4 as [lw1 H1].
               rewrite flat_map_app in H1 ; simpl in H1 ; rewrite app_nil_r in H1.
               decomp_map H1 ; subst.
               rewrite H5 in HC.
               rewrite <- ? map_app in HC.
               apply co_r in HC.
               eexists.
               rewrite ? map_app in HC.
               rewrite <- H5 in HC.
               simpl ; rewrite ? flat_map_app ; simpl.
               simpl ; rewrite ? flat_map_app ; simpl ; rewrite app_nil_r.
               eapply ex_r ; [ apply HC | unfold PCperm ; rewrite <- Hpp ]...
         ++ rewrite flat_map_app in H2 ; destruct ls' ; inversion H2.
         ++ assert (CPermutation
                      (wn A0 :: map wn (l4 ++ f :: l5) ++
                         wn A0 :: flat_map (cons (wn (dual A)))
                                                     (ls'' ++ x' :: nil))
                      (flat_map (cons (wn (dual A)))
                         ((x' ++ ((wn A0) :: l')) :: ls''' ++ ls'
                                           ++ (x ++ wn A0 :: nil) :: ls'')))
              as HC.
            { rewrite ? map_app.
              rewrite H3.
              rewrite Heq3.
              simpl ; rewrite ? flat_map_app... }
            apply IHll in HC.
            destruct HC as [s' HC].
            simpl in HC ; rewrite ? flat_map_app in HC ; simpl in HC.
            eapply (ex_r _ _ (wn A0 :: (l' ++ flat_map (app (map wn l)) ls'''
                                         ++ flat_map (app (map wn l)) ls' ++
                            map wn l ++ x) ++ wn A0 :: flat_map (app (map wn l)) ls''
                                                                     ++ map wn l ++ x'))
              in HC ; [ | unfold PCperm ; rewrite <- Hpp ]...
            symmetry in H3.
            decomp_map H3.
            apply (flat_map_wn_subst _ l) in H5.
            destruct H5 as [lw1 H1].
            symmetry in Heq3.
            rewrite flat_map_app in Heq3.
            simpl in Heq3 ; rewrite app_nil_r in Heq3.
            change (wn f :: map wn l5) with (map wn (f :: l5))
              in Heq3.
            decomp_map Heq3 ; subst.
            apply (flat_map_wn_subst _ l) in Heq2.
            destruct Heq2 as [lw2 Heq2].
            rewrite H1 in HC.
            rewrite Heq2 in HC.
            rewrite <- ? map_app in HC.
            apply co_r in HC.
            eexists.
            rewrite ? map_app in HC.
            rewrite <- H1 in HC.
            rewrite <- Heq2 in HC.
            simpl ; rewrite ? flat_map_app ; simpl.
            simpl ; rewrite ? flat_map_app ; simpl ; rewrite app_nil_r.
            eapply ex_r ; [ | unfold PCperm ; rewrite <- Hpp ]...
      -- destruct l4.
         ++ exfalso.
            apply Heq2.
            symmetry in Heq6.
            apply app_eq_nil in Heq6.
            apply Heq6.
         ++ inversion H0 ; subst.
            destruct l'' ; [ exfalso ; apply Heq2 ; myeasy | ].
            inversion Heq6 ; subst.
            assert (CPermutation
                      (wn A0 :: map wn (l4 ++ l5) ++
                         wn A0 :: l' ++ flat_map (cons (wn (dual A)))
                                                            (ls'' ++ x' :: nil))
                      (flat_map (cons (wn (dual A)))
                         ((x' ++ ((wn A0) :: l'')) :: ls''' ++ ls'
                                                ++ (x ++ wn A0 :: l') :: ls'')))
              as HC.
            { rewrite ? map_app.
              rewrite H3.
              rewrite Heq4.
              simpl ; rewrite ? flat_map_app ; simpl... }
            apply IHll in HC.
            destruct HC as [s' HC].
            symmetry in H3.
            decomp_map H3 ; subst.
            apply (flat_map_wn_subst _ l) in H4.
            destruct H4 as [lw1 H1].
            symmetry in Heq4.
            rewrite flat_map_app in Heq4.
            simpl in Heq4 ; rewrite app_nil_r in Heq4.
            decomp_map Heq4 ; subst.
            apply (flat_map_wn_subst _ l) in Heq3.
            destruct Heq3 as [lw2 Heq3].
            simpl in HC ; rewrite ? flat_map_app in HC ; simpl in HC.
            rewrite H1 in HC.
            rewrite Heq3 in HC.
            eapply (ex_r _ _ (wn A0 :: (map wn l1 ++ map wn lw1 ++ map wn lw2
                                                          ++ map wn l ++ map wn l6)
                         ++ wn A0 :: l' ++ flat_map (app (map wn l)) ls''
                                                                ++ map wn l ++ x'))
              in HC ; [ | unfold PCperm ; rewrite <- Hpp ]...
            rewrite <- ? map_app in HC.
            apply co_r in HC.
            eexists.
            rewrite ? map_app in HC.
            rewrite <- H1 in HC.
            rewrite <- Heq3 in HC.
            rewrite ? flat_map_app ; simpl.
            rewrite ? flat_map_app ; simpl.
            eapply ex_r ; [ apply HC | unfold PCperm ; rewrite <- Hpp ]...
    * apply app_app_vs_flat_map in H2.
      destruct H2
        as [ (ls' & ls'' & ls''' & Heq1 & Heq2 & Heq3 & Heq4)
           | [ (x & l' & ls' & ls''' & Heq1 & Heq2 & Heq3 & Heq4)
           | [ (x & l' & ls' & ls'' & ls''' & Heq1 & Heq2 & Heq3 & Heq4 & Heq5)
           | [ (x' & l' & ls' & ls'' & ls''' & Heq1 & Heq2 & Heq3 & Heq4 & Heq5)
           |   (x & l' & x' & l'' & ls' & ls'' & ls''' &
                  Heq1 & Heq2 & Heq3 & Heq4 & Heq5 & Heq6) ]]]] ;
      subst.
      -- destruct ls'' ; inversion Heq3 ; subst.
         symmetry in H2.
         decomp_map H2.
         apply (flat_map_wn_subst _ l) in H3.
         destruct H3 as [lw1 Heq1] ; subst.
         simpl in Heq3 ; inversion Heq3.
         rewrite map_app in H1.
         apply app_inv_head in H1.
         assert (CPermutation
                     (wn (dual A) :: map wn (l2 ++ l3) ++
                        wn (dual A) :: flat_map (cons (wn (dual A))) ls'''
                                         ++ flat_map (cons (wn (dual A))) ls')
                     (flat_map (cons (wn (dual A)))
                        (map wn l2 :: ls'' ++ nil :: ls''' ++ ls')))
           as HC.
         { rewrite ? map_app.
           rewrite H1.
           simpl ; rewrite ? flat_map_app ; simpl ; rewrite ? flat_map_app... }
         apply IHll in HC.
         destruct HC as [s' HC].
         simpl in HC ; rewrite ? flat_map_app in HC.
         rewrite <- ? app_assoc in HC ; simpl in HC.
         rewrite app_nil_r in HC.
         rewrite Heq1 in HC.
         rewrite (app_assoc _ (map wn lw1)) in HC.  
         rewrite <- map_app in HC.
         apply co_list_r in HC.
         destruct HC as [s'' HC].
         rewrite ? map_app in HC.
         rewrite <- Heq1 in HC.
         rewrite flat_map_app in HC.
         eexists.
         rewrite ? flat_map_app ; simpl.
         eapply ex_r ; [ | unfold PCperm ; rewrite <- Hpp ]...
      -- assert (CPermutation
                     (wn A0 :: map wn lw ++
                        wn A0 :: (l' ++ flat_map (cons (wn (dual A))) ls''')
                                         ++ flat_map (cons (wn (dual A)))
                                                               (ls' ++ x :: nil))
                     (flat_map (cons (wn (dual A)))
                        (ls''' ++ ls' ++ ((x ++ wn A0 :: map wn lw ++
                        wn A0 :: l') :: nil))))
           as HC by (rewrite ? flat_map_app ; cperm_solve).
         apply IHll in HC.
         destruct HC as [s' HC].
         simpl in HC ; rewrite ? flat_map_app in HC.
         simpl in HC ; rewrite app_nil_r in HC.
         eapply (ex_r _ _ (wn A0 :: map wn lw ++ wn A0 :: l'
                            ++ flat_map (app (map wn l)) ls'''
                            ++ flat_map (app (map wn l)) ls'
                            ++ map wn l ++ x))
           in HC ; [ | unfold PCperm ; rewrite <- Hpp ]...
         apply co_r in HC.
         eexists.
         rewrite ? flat_map_app ; simpl.
         eapply ex_r ; [ | unfold PCperm ; rewrite <- Hpp ]...
      -- destruct l' ; [ exfalso ; apply Heq1 ; myeasy | inversion Heq4 ] ; subst.
         destruct ls'' using rev_ind.
         ++ rewrite app_nil_r in H2 ; subst.
            assert (CPermutation
                      (wn A0 :: map wn lw ++
                         wn A0 :: flat_map (cons (wn (dual A))) ls'''
                                    ++ flat_map (cons (wn (dual A)))
                                                        (ls' ++ x :: nil))
                      (flat_map (cons (wn (dual A)))
                         (ls''' ++ ls' ++ ((x ++ wn A0 ::
                                     map wn lw ++ wn A0 :: nil) :: nil))))
              as HC by (rewrite ? flat_map_app ; cperm_solve).
            apply IHll in HC.
            destruct HC as [s' HC].
            simpl in HC ; rewrite ? flat_map_app in HC.
            simpl in HC ; rewrite app_nil_r in HC.
            eapply (ex_r _ _ (wn A0 :: map wn lw ++ wn A0
                               :: flat_map (app (map wn l)) ls'''
                               ++ flat_map (app (map wn l)) ls'
                               ++ map wn l ++ x))
              in HC ; [ | unfold PCperm ; rewrite <- Hpp ]...
            apply co_r in HC.
            eexists.
            rewrite ? flat_map_app ; simpl.
            eapply ex_r ; [ | unfold PCperm ; rewrite <- Hpp ]...
         ++ assert (CPermutation
                      (wn A0 :: map wn lw ++
                         wn A0 :: flat_map (cons (wn (dual A))) ls'''
                                    ++ flat_map (cons (wn (dual A)))
                                                           (ls' ++ x :: nil))
                      (flat_map (cons (wn (dual A)))
                         (ls''' ++ ls' ++ ((x ++ wn A0 :: l') :: ls''
                                              ++ (x0 ++ wn A0 :: nil) :: nil))))
              as HC.
            { rewrite H2.
              simpl ; rewrite ? flat_map_app ; simpl ;
                rewrite ? flat_map_app... }
            apply IHll in HC.
            destruct HC as [s' HC].
            simpl in HC ; rewrite ? flat_map_app in HC.
            simpl in HC ; rewrite ? flat_map_app in HC.
            simpl in HC ; rewrite app_nil_r in HC.
            eapply (ex_r _ _ (wn A0 :: (l' ++ flat_map (app (map wn l)) ls''
                       ++ map wn l ++ x0) ++ wn A0 :: flat_map (app (map wn l)) ls'''
                       ++ flat_map (app (map wn l)) ls' ++ map wn l ++ x))
              in HC ; [ | unfold PCperm ; rewrite <- Hpp ]...
            symmetry in H2.
            rewrite flat_map_app in H2.
            simpl in H2 ; rewrite app_nil_r in H2.
            decomp_map H2 ; subst.
            apply (flat_map_wn_subst _ l) in H2.
            destruct H2 as [lw1 H2].
            rewrite H2 in HC.
            rewrite <- ? map_app in HC.
            apply co_r in HC.
            rewrite ? map_app in HC.
            rewrite <- H2 in HC.
            eexists.
            rewrite ? flat_map_app ; simpl.
            rewrite ? flat_map_app ; simpl.
            eapply ex_r ; [ apply HC | unfold PCperm ; rewrite <- Hpp ]...
      -- destruct ls'' ; inversion Heq4 ; subst.
         ++ rewrite app_nil_r in H2 ; subst.
            assert (CPermutation
                      (wn (dual A) :: map wn lw ++
                         wn (dual A) ::
                              (l' ++ flat_map (cons (wn (dual A))) ls''')
                                  ++ flat_map (cons (wn (dual A))) ls')
                      (flat_map (cons (wn (dual A)))
                         (map wn lw :: l' :: ls''' ++ ls')))
              as HC by (simpl ; rewrite ? flat_map_app ; cperm_solve).
            apply IHll in HC.
            destruct HC as [s' HC].
            simpl in HC ; rewrite ? flat_map_app in HC.
            rewrite <- ? app_assoc in HC ; simpl in HC.
            apply co_list_r in HC.
            destruct HC as [s'' HC].
            eexists.
            rewrite ? flat_map_app ; simpl.
            eapply ex_r ; [ | unfold PCperm ; rewrite <- Hpp ]...
         ++ symmetry in H2.
            rewrite flat_map_app in H2 ; simpl in H2 ; rewrite app_nil_r in H2.
            decomp_map H2 ; inversion H3 ; subst.
            assert (CPermutation
                      (wn (dual A) :: map wn (l2 ++ l4 ++ dual A :: l6) ++
                       wn (dual A) ::
                               (l' ++ flat_map (cons (wn (dual A))) ls''')
                                          ++ flat_map (cons (wn (dual A))) ls')
                      (flat_map (cons (wn (dual A)))
                         (map wn l2 :: ls''
                                        ++ map wn l6 :: l' :: ls''' ++ ls')))
              as HC.
            { simpl ; rewrite ? flat_map_app ; rewrite ? map_app.
              simpl ; rewrite ? flat_map_app.
              rewrite <- H2... }
            apply IHll in HC.
            destruct HC as [s' HC].
            simpl in HC ; rewrite ? flat_map_app in HC.
            simpl in HC ; rewrite ? flat_map_app in HC.
            rewrite <- ? app_assoc in HC ; simpl in HC.
            apply (flat_map_wn_subst _ l) in H2.
            destruct H2 as [lw1 H2].
            rewrite H2 in HC.
            rewrite (app_assoc _ (map wn lw1)) in HC.
            rewrite <- map_app in HC.
            rewrite (app_assoc _ (map wn l)) in HC.
            rewrite <- map_app in HC.
            rewrite (app_assoc _ (map wn l6)) in HC.
            rewrite <- map_app in HC.
            apply co_list_r in HC.
            destruct HC as [s'' HC].
            eexists.
            rewrite ? map_app in HC.
            rewrite <- H2 in HC.
            rewrite ? flat_map_app ; simpl.
            eapply ex_r ; [ | unfold PCperm ; rewrite <- Hpp ]...
      -- destruct l' ; [ exfalso ; apply Heq1 ; myeasy | inversion Heq5 ] ; subst.
         symmetry in H2.
         rewrite flat_map_app in H2 ; simpl in H2 ; rewrite app_nil_r in H2.
         decomp_map H2 ; inversion H3 ; subst.
         assert (CPermutation
                     (wn A0 :: map wn (l1 ++ l3 ++ dual A :: l5) ++
                        wn A0 :: (l'' ++ flat_map (cons (wn (dual A))) ls''')
                               ++ flat_map (cons (wn (dual A))) (ls' ++ x :: nil))
                     (flat_map (cons (wn (dual A)))
                        (ls' ++ (x ++ wn A0 :: map wn l1) :: ls''
                                 ++ (map wn l5 ++ wn A0 :: l'') :: ls''')))
           as HC.
         { simpl ; rewrite ? flat_map_app ; rewrite ? map_app.
           simpl ; rewrite ? flat_map_app.
           simpl ; rewrite ? flat_map_app.
           rewrite <- H2... }
         apply IHll in HC.
         destruct HC as [s' HC].
         rewrite ? flat_map_app in HC ; simpl in HC.
         rewrite ? flat_map_app in HC ; simpl in HC.
         eapply (ex_r _ _ (wn A0 :: (map wn l1 ++ flat_map (app (map wn l)) ls''
                        ++ map wn l ++ map wn l5) ++ wn A0 :: l''
                        ++ flat_map (app (map wn l)) ls'''
                        ++ flat_map (app (map wn l)) ls' ++ map wn l ++ x))
           in HC ; [ | unfold PCperm ; rewrite <- Hpp ]...
         apply (flat_map_wn_subst _ l) in H2.
         destruct H2 as [lw1 H2].
         rewrite H2 in HC.
         rewrite <- ? map_app in HC.
         apply co_r in HC.
         eexists.
         rewrite ? map_app in HC.
         rewrite <- H2 in HC.
         rewrite ? flat_map_app ; simpl.
         rewrite ? flat_map_app ; simpl.
         eapply ex_r ; [ | unfold PCperm ; rewrite <- Hpp ]...
- (* cut_r *)
  hyps_PCperm_unfold ; unfold PCperm in IHll1 ; unfold PCperm in IHll2 ;
    remember (pperm P) as pp eqn:Hpp ; destruct pp.
  + destruct ls.
    * symmetry in HP.
      apply Permutation_nil in HP.
      apply app_eq_nil in HP.
      destruct HP ; subst.
      eexists.
      simpl.
      change nil with (@nil formula ++ nil).
      eapply cut_r...
    * assert (HP1 := perm_flat_map_app (wn (dual A) :: nil) (l0 :: ls)).
      rewrite <- flat_map_cons_is_flat_map_app in HP1.
      assert (HP2 := Permutation_trans HP HP1).
      apply Permutation_app_app_inv in HP2.
      destruct HP2 as (l3 & l4 & l5 & l6 & HP3 & HP4 & HP5 & HP6).
      destruct l3 ; destruct l4.
      -- exfalso.
         symmetry in HP5.
         apply Permutation_nil in HP5.
         inversion HP5.
      -- assert (Permutation (dual A0 :: l1)
                             (flat_map (cons (wn (dual A)))
                               ((dual A0 :: l6) :: flat_map (fun _ => (nil :: nil)) ls)))
           as IHP.
         { apply (Permutation_cons_app _ _ (dual A0)) in HP4.
           apply (Permutation_trans HP4).
           symmetry in HP5.
           apply (Permutation_app_tail (dual A0 :: l6)) in HP5.
           apply (Permutation_trans HP5).
           simpl ; apply Permutation_cons...
           eapply Permutation_trans ; [ apply Permutation_app_comm | ].
           rewrite app_comm_cons ; apply Permutation_app_head.
           clear ; induction ls... }
         apply IHll1 in IHP.
         destruct IHP as [s' IHP].
         eexists.
         symmetry in HP6.
         eapply ex_r ; [ | unfold PCperm ; rewrite <- Hpp ; symmetry ;
           apply perm_flat_map_app ].
         list_simpl in IHP.
         eapply ex_r in IHP ;
           [ | unfold PCperm ; rewrite <- Hpp ; symmetry ; apply Permutation_cons_app ]...
         apply (ex_r _ _ _ _ (@cut_r _ f _ _ _ _ _ IHP H0)).
         unfold PCperm ; rewrite <- Hpp.
         simpl ; rewrite <- ? app_assoc.
         apply (Permutation_trans (Permutation_app_tail _ HP3)).
         simpl ; apply (Permutation_trans (Permutation_app_swap _ _ _)).
         apply Permutation_app_head.
         rewrite app_assoc.
         apply (Permutation_trans (Permutation_app_tail _ HP6)).
         apply (Permutation_trans (Permutation_app_comm _ _)).
         simpl ; apply Permutation_app_tail.
         clear ; induction ls...
      -- assert (Permutation (A0 :: l2) (flat_map (cons (wn (dual A)))
                                ((A0 :: l5) :: flat_map (fun _ => (nil :: nil)) ls)))
           as IHP.
         { apply (Permutation_cons_app _ _ A0) in HP3.
           apply (Permutation_trans HP3).
           rewrite app_nil_r in HP5 ; symmetry in HP5.
           apply (Permutation_app_tail (A0 :: l5)) in HP5.
           apply (Permutation_trans HP5).
           simpl ; apply Permutation_cons...
           eapply Permutation_trans ; [ apply Permutation_app_comm | ].
           rewrite app_comm_cons ; apply Permutation_app_head.
           clear ; induction ls... }
         apply IHll2 in IHP.
         destruct IHP as [s' IHP].
         eexists.
         symmetry in HP6.
         eapply ex_r ; [ | unfold PCperm ; rewrite <- Hpp ; symmetry ;
           apply perm_flat_map_app ].
         list_simpl in IHP.
         eapply ex_r in IHP ;
           [ | unfold PCperm ; rewrite <- Hpp ; symmetry ; apply Permutation_cons_app ]...
         apply (ex_r _ _ _ _ (@cut_r _ f _ _ _ _ _ H IHP)).
         unfold PCperm ; rewrite <- Hpp.
         simpl ; rewrite <- ? app_assoc.
         apply Permutation_app_head.
         rewrite ? app_assoc.
         apply (Permutation_trans (Permutation_app_head _ HP4)).
         simpl ; rewrite <- ? app_assoc.
         eapply Permutation_trans.
         ++ apply Permutation_app_rot.
         ++ apply (Permutation_trans (Permutation_app_comm _ _)).
            apply (Permutation_trans (Permutation_app_tail _
                                       (Permutation_app_comm _ _))).
            apply (Permutation_trans (Permutation_app_tail _ HP6)).
            apply (Permutation_trans (Permutation_app_comm _ _)).
            simpl ; apply Permutation_app_tail.
            clear ; induction ls...
      -- assert (HPls := HP5).
         apply perm_flat_map_const in HP5.
         destruct HP5 as [ls' HP5].
         assert ((exists ls3, (f0 :: l3) = @flat_map (list formula) _
                                           (fun _ => wn (dual A) :: nil) ls3)
              /\ (exists ls4, (f1 :: l4) = @flat_map (list formula) _
                                           (fun _ => wn (dual A) :: nil) ls4))
           as Hls.
         { remember (f0 :: l3) as l3'.
           remember (f1 :: l4) as l4'.
           clear - HP5 ; revert l3' l4' HP5 ; induction ls' ; intros l3 l4 HP.
           - apply app_eq_nil in HP.
             destruct HP ; subst.
             split ; exists nil...
           - destruct l3.
             + destruct l4 ; inversion HP.
               rewrite <- (app_nil_l l4) in H1.
               apply IHls' in H1.
               destruct H1 as [[ls3 H3] [ls4 H4]] ; subst.
               split.
               * exists nil...
               * exists (a :: ls')...
             + inversion HP.
               apply IHls' in H1.
               destruct H1 as [[ls3 H3] [ls4 H4]] ; subst.
               split.
               * exists (a :: ls3)...
               * exists ls4... }
         destruct Hls as [[ls3 Hls3] [ls4 Hls4]].
         destruct ls3 ; [inversion Hls3 | ].
         destruct ls4 ; [inversion Hls4 | ].
         assert (Permutation (dual A0 :: l1) (flat_map (cons (wn (dual A)))
                                ((dual A0 :: l6) :: flat_map (fun _ => (nil :: nil)) ls4)))
           as IHP1.
         { apply (Permutation_cons_app _ _ (dual A0)) in HP4.
           apply (Permutation_trans HP4).
           assert (HP4' := Permutation_refl (f1 :: l4)).
           rewrite Hls4 in HP4' at 2.
           apply (Permutation_app_tail (dual A0 :: l6)) in HP4'.
           apply (Permutation_trans HP4').
           simpl ; apply Permutation_cons...
           eapply Permutation_trans ; [ apply Permutation_app_comm | ].
           rewrite app_comm_cons ; apply Permutation_app_head.
           clear ; induction ls4... }
         apply IHll1 in IHP1.
         destruct IHP1 as [s1' IHP1].
         assert (Permutation (A0 :: l2) (flat_map (cons (wn (dual A)))
                                ((A0 :: l5) :: flat_map (fun _ => (nil :: nil)) ls3)))
           as IHP2.
         { apply (Permutation_cons_app _ _ A0) in HP3.
           apply (Permutation_trans HP3).
           assert (HP3' := Permutation_refl (f0 :: l3)).
           rewrite Hls3 in HP3' at 2.
           apply (Permutation_app_tail (A0 :: l5)) in HP3'.
           apply (Permutation_trans HP3').
           simpl ; apply Permutation_cons...
           eapply Permutation_trans ; [ apply Permutation_app_comm | ].
           rewrite app_comm_cons ; apply Permutation_app_head.
           clear ; induction ls3... }
         apply IHll2 in IHP2.
         destruct IHP2 as [s2' IHP2].
         list_simpl in IHP1.
         eapply ex_r in IHP1 ;
           [ | unfold PCperm ; rewrite <- Hpp ; symmetry ; apply Permutation_cons_app ]...
         list_simpl in IHP2.
         eapply ex_r in IHP2 ;
           [ | unfold PCperm ; rewrite <- Hpp ; symmetry ; apply Permutation_cons_app ]...
         eexists.
         eapply ex_r ; [apply (@cut_r _ f A0 _ _ _ _ IHP1 IHP2) | ].
         unfold PCperm ; rewrite <- Hpp ; simpl.
         rewrite Hls3 in HPls.
         rewrite Hls4 in HPls.
         rewrite <- flat_map_app in HPls.
         apply (perm_flat_map_const_subst _ (@nil formula :: nil)) in HPls ;
               [ | intro Hnil ; inversion Hnil].
         apply (Permutation_flat_map (app (map wn l))) in HPls.
         simpl in HPls ; rewrite flat_map_app in HPls.
         simpl in HPls ; rewrite flat_map_app in HPls ; simpl in HPls.
         rewrite ? app_nil_r in HPls.
         apply (Permutation_app HP6) in HPls.
         symmetry in HPls.
         eapply Permutation_trans ;
           [ eapply Permutation_trans ; [ | apply HPls] | ]...
         clear ; assert (HP := perm_flat_map_app (map wn l) (l0 :: ls)).
         simpl in HP ; symmetry in HP.
         eapply Permutation_trans ; [ | apply HP].
         assert (Permutation (flat_map (app (map wn l))
                               (flat_map (fun _ => nil :: nil) ls))
                             (flat_map (fun _ => map wn l) ls))
           as HPf by (clear ; induction ls ; perm_solve)...
  + inversion HP.
    dichot_app_exec H2 ; subst.
    * rewrite <- app_assoc in H3.
      apply (key_case_oc_subst_cut_cperm A A0 l ls l1 l0 l4 s1 s2)...
    * apply (key_case_oc_subst_cut_cperm A (dual A0) l ls l2 l5 l3 s2 s1) ;
        try rewrite bidual...
- (* gax_r *)
  assert (HF := PCperm_Forall _ _ _ _ HP (P_gax_atomic _ H)).
  destruct ls.
  + apply PCperm_sym in HP.
    apply PCperm_nil in HP ; subst.
    eexists ; apply gax_r...
  + exfalso.
    inversion HF.
    inversion H2.
Qed.

(* begin hide *)
Ltac comm_oc1_P rule mkl0 mkl1 mkl2 x B lrule l0 l5 Hl1' Hr1' HP1 IHsize Hpp :=
  assert (Heq := HP1) ;
  apply Permutation_vs_cons_inv in Heq ;
  let l' := fresh "l" in
  let l'' := fresh "l" in
  destruct Heq as (l' & l'' & Heq) ;
  let Heq0 := fresh Heq in
  let Heq1 := fresh Heq in
  destruct l' ; inversion Heq as [[Heq0 Heq1]] ;
  subst ;
  try (eapply (ex_r _ _ (dual (wn x) :: mkl1 l' l'')) in Hl1' ; 
         [ | unfold PCperm ; rewrite <- Hpp ; clear ; perm_solve ] ;
         eapply IHsize in Hl1' ; myeeasy ; destruct Hl1' as [s1' Hl1']) ;
  try (eapply (ex_r _ _ (dual (wn x) :: mkl2 l' l'')) in Hr1' ; 
         [ | unfold PCperm ; rewrite <- Hpp ; clear ; perm_solve ] ;
        eapply IHsize in Hr1' ; myeeasy ;  destruct Hr1' as [s2' Hr1']) ;
  eexists ;
  eapply (ex_r _
    (mkl0 (l' ++ map wn l5 ++ lrule ++ (B :: map wn l0) ++ l''))) ;
    [ | unfold PCperm ; rewrite <- Hpp ;
        clear - HP1 ; simpl_hyp_perm_all ; perm_solve ] ;
  eapply rule ;
  first
  [ eapply (ex_r _ ((B :: map wn l0) ++ mkl1 l' l'' ++ map wn l5 ++ lrule)) ;
      [ apply Hl1' | unfold PCperm ; rewrite <- Hpp ; clear - HP1 ; perm_solve ]
  | eapply (ex_r _ ((B :: map wn l0) ++ mkl2 l' l'' ++ map wn l5 ++ lrule)) ;
      [ apply Hr1' | unfold PCperm ; rewrite <- Hpp ; clear - HP1 ; perm_solve ]
  | idtac ].

Ltac comm_oc1_C rule mkl0 mkl1 mkl2 x B lrule l0 l5 Hl1' Hr1' HP1 IHsize Hpp :=
  apply cperm_vs_cons_inv in HP1 ;
  let l' := fresh "l" in
  let l'' := fresh "l" in
  let Heq0 := fresh HP1 in
  destruct HP1 as (l' & l'' & Heq0 & HP1) ;
  let Heq1 := fresh HP1 in
  let Heq2 := fresh HP1 in
  destruct l' ; inversion HP1 as [[Heq1 Heq2]] ;
  subst ;
  try (eapply (ex_r _ _ (dual (wn x) :: mkl1 l'' l')) in Hl1' ; 
         [ | unfold PCperm ; rewrite <- Hpp ; clear ; cperm_solve ] ;
         eapply IHsize in Hl1' ; myeeasy ; destruct Hl1' as [s1' Hl1']) ;
  try (eapply (ex_r _ _ (dual (wn x) :: mkl2 l'' l')) in Hr1' ; 
         [ | unfold PCperm ; rewrite <- Hpp ; clear ; cperm_solve ] ;
         eapply IHsize in Hr1' ; myeeasy ; destruct Hr1' as [s2' Hr1']) ;
  eexists ;
  eapply (ex_r _
    (mkl0 (l' ++ map wn l5 ++ lrule ++ (B :: map wn l0) ++ l''))) ;
    [ | unfold PCperm ; rewrite <- Hpp ; clear - HP1 ; cperm_solve ] ;
  eapply rule ;
  first
  [ eapply (ex_r _ ((B :: map wn l0) ++ mkl1 l'' l' ++ map wn l5 ++ lrule)) ;
      [ apply Hl1' | unfold PCperm ; rewrite <- Hpp ; clear - HP1 ; cperm_solve ]
  | eapply (ex_r _ ((B :: map wn l0) ++ mkl2 l'' l' ++ map wn l5 ++ lrule)) ;
      [ apply Hr1' | unfold PCperm ; rewrite <- Hpp ; clear - HP1 ; cperm_solve ]
  | idtac ].

Ltac comm_oc1 rule mkl0 mkl1 mkl2 x B lrule l0 l5 Hl1' Hr1' HP1 IHsize Hpp :=
  hyps_PCperm_unfold ; unfold PCperm ; remember (pperm P) as pp eqn:Hpp ;
  destruct pp ;
  [ comm_oc1_P rule mkl0 mkl1 mkl2 x B lrule l0 l5 Hl1' Hr1' HP1 IHsize Hpp
  | comm_oc1_C rule mkl0 mkl1 mkl2 x B lrule l0 l5 Hl1' Hr1' HP1 IHsize Hpp ].
(* end hide *)

(** A cut on a [wn] formula cut be commuted up with any rule which does not touch this formula.
This contains the fact that a proof of [oc C :: _] (here [oc C] is [dual A]) can be deconstructed 
until one reaches an [oc_r] rule introducing [oc C] with a [wn] context. *)
Lemma comm_oc_wn : forall c s1 s A l1 l2 l0 lw l lrule B Brule,
  ll P (dual A :: l1) s1 -> fsize A <= c ->
  (forall (A1 : formula) (l0 l4 l5 : list formula) (s0 s2 : nat),
     ll P (dual A1 :: l0) s0 -> ll P (l4 ++ A1 :: l5) s2 ->
     s0 + s2 < s1 + S s -> fsize A1 <= c ->
     exists s' : nat, ll P (l4 ++ l0 ++ l5) s') ->
  l2 ++ A :: l0 = map wn lw -> 
  (forall s' lw', ll P (B :: map wn lw' ++ l) s' ->
                  ll P (Brule :: map wn lw' ++ lrule) (S s')) ->
  ll P (B :: map wn lw ++ l) s -> 
    exists s' : nat, ll P (Brule :: l2 ++ l1 ++ l0 ++ lrule) s'.
Proof with myeasy_perm.
intros c s1 s A l1 l2 l0 lw l lrule B Brule Hl Hc IHsize H1 Hrule Hl2.
decomp_map H1 ; subst.
assert (Hrule2 := Hrule _ _ Hl2).
rewrite map_app in Hrule2.
rewrite ? app_comm_cons in Hrule2.
rewrite <- app_assoc in Hrule2.
change (map wn (x :: l6) ++ lrule)
  with ((wn x) :: map wn l6 ++ lrule) in Hrule2.
inversion_ll Hl f1 X l' Hl1 Hr1 HP1 Hax.
- (* ex_r *)
  inversion_ll Hl1 f2 X l'' Hl1' Hr1' HP1' Hax.
  + (* ax_r *)
    apply PCperm_length_2_inv in HP1.
    destruct HP1 ; inversion H.
  + (* ex_r *)
    eapply (ex_r _ _ (dual (wn x) :: l1)) in Hl1'...
    eapply (IHsize _ _ _ _ _ _ Hl1') in Hrule2...
  + (* mix0_r *)
    apply PCperm_nil_cons in HP1...
  + (* mix2_r *)
    hyps_PCperm_unfold ; unfold PCperm ;
      remember (pperm P) as pp eqn:Hpp ; destruct pp.
    * assert (Heq := HP1).
      apply Permutation_vs_cons_inv in Heq.
      destruct Heq as (l' & l'' & Heq).
      symmetry in Heq.
      apply dichot_elt_app in Heq.
      destruct Heq as [(l''' & ? & ?) | (l''' & ? & ?)] ; subst.
      -- apply (ex_r _ _ (dual (wn x) :: l''' ++ l')) in Hr1'...
         apply (IHsize _ _ _ _ _ _ Hr1') in Hrule2...
         destruct Hrule2 as [s' Hrule2].
         eexists.
         apply (ex_r _ ((Brule :: map wn l4 ++ (l''' ++ l')
                                        ++ map wn l6 ++ lrule) ++ l0)) ;
           [ | unfold PCperm ; rewrite <- Hpp ; myeasy_perm ].
         apply (@mix2_r _ f2)...
      -- apply (ex_r _ _ (dual (wn x) :: l'' ++ l''')) in Hl1'...
         apply (IHsize _ _ _ _ _ _ Hl1') in Hrule2...
         destruct Hrule2 as [s' Hrule2].
         eexists.
         apply (ex_r _ ((Brule :: map wn l4 ++ (l'' ++ l''')
                                        ++ map wn l6 ++ lrule) ++ l2)) ;
           [ | unfold PCperm ; rewrite <- Hpp ; myeasy_perm ].
         apply (@mix2_r _ f2)...
    * apply cperm_vs_cons_inv in HP1.
      destruct HP1 as (l' & l'' & Heq0 & HP1).
      symmetry in HP1.
      apply dichot_elt_app in HP1.
      destruct HP1 as [(l''' & ? & ?) | (l''' & ? & ?)] ; subst.
      -- apply (ex_r _ _ (dual (wn x) :: l''' ++ l')) in Hr1'...
         apply (IHsize _ _ _ _ _ _ Hr1') in Hrule2...
         destruct Hrule2 as [s' Hrule2].
         eexists.
         apply (ex_r _ (l0 ++ l' ++ map wn l6 ++ lrule
                                          ++ Brule :: map wn l4 ++ l''')) ;
           [ | unfold PCperm ; rewrite <- Hpp ; myeasy_perm ].
         apply (@mix2_r _ f2)...
         apply (ex_r _ _ _ _ Hrule2)...
      -- apply (ex_r _ _ (dual (wn x) :: l'' ++ l''')) in Hl1'...
         apply (IHsize _ _ _ _ _ _ Hl1') in Hrule2...
         destruct Hrule2 as [s' Hrule2].
         eexists.
         apply (ex_r _ ((l''' ++ map wn l6 ++ lrule
                                    ++ Brule :: map wn l4 ++ l'') ++ l2)) ;
           [ | unfold PCperm ; rewrite <- Hpp ; myeasy_perm ].
         eapply (@mix2_r _ f2)...
         apply (ex_r _ _ _ _ Hrule2)...
  + (* one_r *)
    apply PCperm_length_1_inv in HP1.
    inversion HP1.
  + (* bot_r *)
    comm_oc1 bot_r (cons bot)
             (@app formula) foo
             x Brule lrule l4 l6 Hl1' Hr1' HP1 IHsize Hpp.
  + (* tens_r *)
    hyps_PCperm_unfold ; unfold PCperm ;
      remember (pperm P) as pp eqn:Hpp ; destruct pp.
    * assert (Heq := HP1).
      apply Permutation_vs_cons_inv in Heq.
      destruct Heq as (l' & l'' & Heq).
      destruct l' ; inversion Heq as [[Heq0 Heq1]].
      symmetry in Heq1.
      apply dichot_elt_app in Heq1.
      destruct Heq1 as [(l''' & ? & ?) | (l''' & ? & ?)] ; subst.
      -- apply (ex_r _ _ (dual (wn x) :: l''' ++ B0 :: l')) in Hr1'...
         apply (IHsize _ _ _ _ _ _ Hr1') in Hrule2...
         destruct Hrule2 as [s' Hrule2].
         eexists.
         apply (ex_r _ (tens A B0 :: (l' ++ map wn l6 ++ lrule
                                     ++ Brule :: map wn l4 ++ l''') ++ l0)) ;
           [ | unfold PCperm ; rewrite <- Hpp ; myeasy_perm ].
         eapply tens_r...
         apply (ex_r _ _ _ _ Hrule2)...
      -- apply (ex_r _ _ (dual (wn x) :: l'' ++ A :: l''')) in Hl1'...
         apply (IHsize _ _ _ _ _ _ Hl1') in Hrule2...
         destruct Hrule2 as [s' Hrule2].
         eexists.
         apply (ex_r _ (tens A B0 :: l2 ++ Brule :: map wn l4 ++ (l'' ++ l''')
                                                        ++ map wn l6 ++ lrule)) ;
           [ | unfold PCperm ; rewrite <- Hpp ; myeasy_perm ].
         eapply tens_r...
         apply (ex_r _ _ _ _ Hrule2).
         unfold PCperm ; rewrite <- Hpp...
    * apply cperm_vs_cons_inv in HP1.
      destruct HP1 as (l' & l'' & Heq0 & HP1).
      destruct l' ; inversion HP1 as [[Heq Heq1]].
      symmetry in Heq1.
      apply dichot_elt_app in Heq1.
      destruct Heq1 as [(l''' & ? & ?) | (l''' & ? & ?)] ; subst.
      -- apply (ex_r _ _ (dual (wn x) :: l''' ++ B0 :: l')) in Hr1'...
         apply (IHsize _ _ _ _ _ _ Hr1') in Hrule2...
         destruct Hrule2 as [s' Hrule2].
         eexists.
         apply (ex_r _ (tens A B0 :: (l' ++ map wn l6 ++ lrule
                                          ++ Brule :: map wn l4 ++ l''') ++ l0)) ;
           [ | unfold PCperm ; rewrite <- Hpp ; myeasy_perm ].
         eapply tens_r...
         apply (ex_r _ _ _ _ Hrule2)...
      -- apply (ex_r _ _ (dual (wn x) :: l'' ++ A :: l''')) in Hl1'...
         apply (IHsize _ _ _ _ _ _ Hl1') in Hrule2...
         destruct Hrule2 as [s' Hrule2].
         eexists.
         apply (ex_r _ (tens A B0 :: l2 ++ l''' ++ map wn l6 ++ lrule
                                                  ++ Brule :: map wn l4 ++ l'')) ;
           [ | unfold PCperm ; rewrite <- Hpp ; myeasy_perm ].
         eapply tens_r...
         apply (ex_r _ _ _ _ Hrule2)...
  + (* parr_r *)
    comm_oc1 parr_r (cons (parr A B0))
             (fun l' l'' => l' ++ A :: B0 :: l'') foo
             x Brule lrule l4 l6 Hl1' Hr1' HP1 IHsize Hpp.
  + (* top_r *)
    comm_oc1 top_r (cons top) foo foo
             x Brule lrule l4 l6 Hl1' Hr1' HP1 IHsize Hpp.
  + (* plus_r1 *)
    comm_oc1 plus_r1 (cons (aplus A B0))
             (fun l' l'' => l' ++ A :: l'') foo
             x Brule lrule l4 l6 Hl1' Hr1' HP1 IHsize Hpp.
  + (* plus_r2 *)
    comm_oc1 plus_r2 (cons (aplus B0 A))
             (fun l' l'' => l' ++ A :: l'') foo
             x Brule lrule l4 l6 Hl1' Hr1' HP1 IHsize Hpp.
  + (* with_r *)
    comm_oc1 with_r (cons (awith A B0))
             (fun l' l'' => l' ++ A :: l'')
             (fun l' l'' => l' ++ B0 :: l'')
             x Brule lrule l4 l6 Hl1' Hr1' HP1 IHsize Hpp.
  + (* oc_r *)
    hyps_PCperm_unfold ; unfold PCperm ;
      remember (pperm P) as pp eqn:Hpp ; destruct pp.
    * assert (A = dual x).
      { symmetry in HP1.
        apply (Permutation_in (dual (wn x))) in HP1 ;
          try constructor...
        destruct HP1.
        - inversion H...
        - revert H ; clear.
          induction l0 ; simpl ; intros...
          destruct H.
          + inversion H.
          + apply IHl0... }
      subst.
      change (oc (dual x)) with (dual (wn x)) in Hl1.
      eapply IHsize in Hl1...
      destruct Hl1 as [s' Hl1].
      eexists.
      eapply ex_r in Hl1...
      unfold PCperm ; rewrite <- Hpp...
    * assert (A = dual x /\ map wn l0 = l1) as [HA Hll1].
      { inversion HP1.
        clear - l3 H H0 ; destruct l2.
        - simpl in H0 ; subst.
          inversion H ; subst.
          rewrite app_nil_r.
          split ; reflexivity.
        - inversion H0.
          destruct l3.
          + inversion H ; subst.
            injection H4 ; intro HA.
            subst ; rewrite app_nil_r ; split ; reflexivity.
          + exfalso.
            inversion H ; subst.
            clear H0 ; revert l0 H3 ; clear ; induction l2 ; intros l0 H3.
            * destruct l0 ; inversion H3.
            * destruct l0 ; inversion H3.
              eapply IHl2... }
      subst.
      change (oc (dual x)) with (dual (wn x)) in Hl1.
      eapply (IHsize _ _ _ _ _ _ Hl1) in Hrule2...
  + (* de_r *)
    comm_oc1 de_r (cons (wn A))
             (fun l' l'' => l' ++ A :: l'') foo
             x Brule lrule l4 l6 Hl1' Hr1' HP1 IHsize Hpp.
  + (* wk_r *)
    comm_oc1 wk_r (cons (wn A))
             (fun l' l'' : list formula => l' ++ l'') foo
             x Brule lrule l4 l6 Hl1' Hr1' HP1 IHsize Hpp.
  + (* co_r *)
    hyps_PCperm_unfold ; unfold PCperm ;
      remember (pperm P) as pp eqn:Hpp ; destruct pp.
    * assert (Heq := HP1).
      apply Permutation_vs_cons_inv in Heq.
      destruct Heq as (l2 & l8 & Heq).
      destruct l2 ; inversion Heq as [[Heq0 Heq1]].
      assert (exists l2', l2 = map wn lw ++ l2') as Hl2'.
      { clear - Heq1 ; revert lw l0 Heq1 ; induction l2 ; intros lw l0 Heq ;
          destruct lw.
        - exists nil...
        - inversion Heq.
        - exists (a :: l2)...
        - inversion Heq.
          apply IHl2 in H1.
          destruct H1 as [l2' Heq2] ; subst.
          exists l2'... }
      destruct Hl2' as [l2' Heq2] ; subst.
      rewrite <- app_assoc in Heq1.
      apply app_inv_head in Heq1 ; subst.
      apply (ex_r _ _ (dual (wn x) :: l8 ++ 
             wn A :: map wn lw ++ wn A :: l2')) in Hl1' ; 
        [ | unfold PCperm ; rewrite <- Hpp ; myeasy_perm ].
      eapply IHsize in Hl1'...
      destruct Hl1' as [s1' Hl1'].
      eexists.
      apply (ex_r _ (wn A :: map wn lw ++ (l2' ++ map wn l6
                                  ++ lrule ++ (Brule :: map wn l4) ++ l8))) ;
        [ | unfold PCperm ; rewrite <- Hpp ; myeasy_perm ].
      eapply co_r.
      apply (ex_r _ ((Brule :: map wn l4) ++ (l8 ++ 
             wn A :: map wn lw ++ wn A :: l2') ++ map wn l6 ++ lrule)) ;
        [ | unfold PCperm ; rewrite <- Hpp ]...
    * apply cperm_vs_cons_inv in HP1 ;
      destruct HP1 as (l2 & l8 & Heq0 & HP1).
      destruct l2 ; inversion HP1 as [[Heq1 Heq2]].
      assert (exists l2', l2 = map wn lw ++ l2') as Hl2'.
      { clear - Heq2 ; revert lw l0 Heq2 ; induction l2 ; intros lw l0 Heq ;
          destruct lw.
        - exists nil...
        - inversion Heq.
        - exists (a :: l2)...
        - inversion Heq.
          apply IHl2 in H1.
          destruct H1 as [l2' Heq2] ; subst.
          exists l2'... }
      destruct Hl2' as [l2' Heq2'] ; subst.
      rewrite <- app_assoc in Heq2.
      apply app_inv_head in Heq2 ; subst.
      apply (ex_r _ _ (dual (wn x) :: l8 ++ 
             wn A :: map wn lw ++ wn A :: l2')) in Hl1' ; 
        [ | unfold PCperm ; rewrite <- Hpp ; myeasy_perm ].
      eapply IHsize in Hl1'...
      destruct Hl1' as [s1' Hl1'].
      eexists.
      apply (ex_r _ (wn  A :: map wn lw ++
             (l2' ++ map wn l6 ++ lrule ++
                                (Brule :: map wn l4) ++ l8))) ;
        [ | unfold PCperm ; rewrite <- Hpp ; myeasy_perm ].
      eapply co_r.
      apply (ex_r _ ((Brule :: map wn l4) ++ (l8 ++ wn A ::
             map wn lw ++ wn A :: l2') ++ map wn l6 ++ lrule)) ;
       [ | unfold PCperm ; rewrite <- Hpp ]...
  + (* cut_r *)
    hyps_PCperm_unfold ; unfold PCperm ;
      remember (pperm P) as pp eqn:Hpp ; destruct pp.
    * assert (Heq := HP1).
      apply Permutation_vs_cons_inv in Heq.
      destruct Heq as (l' & l'' & Heq).
      symmetry in Heq.
      apply dichot_elt_app in Heq.
      destruct Heq as [(l''' & ? & ?) | (l''' & ? & ?)] ; subst.
      -- apply (ex_r _ _ (dual (wn x) :: l''' ++ A :: l')) in Hr1'...
         apply (IHsize _ _ _ _ _ _ Hr1') in Hrule2...
         destruct Hrule2 as [s' Hrule2].
         eexists.
         apply (ex_r _ ((l' ++ map wn l6 ++ lrule ++ Brule :: map wn l4 ++ l''') ++ l0)) ;
           [ | unfold PCperm ; rewrite <- Hpp ; myeasy_perm ].
         apply (@cut_r _ f2 A)...
         eapply ex_r ; [ apply Hrule2 | ]...
      -- apply (ex_r _ _ (dual (wn x) :: l'' ++ dual A :: l''')) in Hl1'...
         apply (IHsize _ _ _ _ _ _ Hl1') in Hrule2...
         destruct Hrule2 as [s' Hrule2].
         eexists.
         apply (ex_r _ (l2 ++ (Brule :: map wn l4 ++ (l'' ++ l''')
                                        ++ map wn l6 ++ lrule))) ;
           [ | unfold PCperm ; rewrite <- Hpp ; myeasy_perm ].
         apply (@cut_r _ f2 A)...
         eapply ex_r ; [ apply Hrule2 | unfold PCperm ; rewrite <- Hpp ; myeasy_perm ].
    * apply cperm_vs_cons_inv in HP1.
      destruct HP1 as (l' & l'' & Heq0 & HP1).
      symmetry in HP1.
      apply dichot_elt_app in HP1.
      destruct HP1 as [(l''' & ? & ?) | (l''' & ? & ?)] ; subst.
      -- apply (ex_r _ _ (dual (wn x) :: l''' ++ A :: l')) in Hr1'...
         apply (IHsize _ _ _ _ _ _ Hr1') in Hrule2...
         destruct Hrule2 as [s' Hrule2].
         eexists.
         apply (ex_r _ ((l' ++ map wn l6 ++ lrule ++ Brule :: map wn l4 ++ l''')
                         ++ l0)) ;
           [ | unfold PCperm ; rewrite <- Hpp ; myeasy_perm ].
         apply (@cut_r _ f2 A)...
         apply (ex_r _ _ _ _ Hrule2)...
      -- apply (ex_r _ _ (dual (wn x) :: l'' ++ dual A :: l''')) in Hl1'...
         apply (IHsize _ _ _ _ _ _ Hl1') in Hrule2...
         destruct Hrule2 as [s' Hrule2].
         eexists.
         apply (ex_r _ (l2 ++ (l''' ++ map wn l6 ++ lrule
                                    ++ Brule :: map wn l4 ++ l''))) ;
           [ | unfold PCperm ; rewrite <- Hpp ; myeasy_perm ].
         eapply (@cut_r _ f2 A)...
         apply (ex_r _ _ _ _ Hrule2)...
  + (* gax_r *)
    exfalso.
    apply P_gax_atomic in Hax.
    eapply PCperm_Forall in HP1.
    apply HP1 in Hax.
    inversion Hax ; subst.
    inversion H1.
- (* mix2_r *) 
  rewrite <- (app_nil_l (_ :: l1)) in H.
  dichot_elt_app_exec H ; subst.
  + rewrite app_comm_cons in Hrule2.
    change (oc (dual x)) with (dual (wn x)) in Hr1.
    eapply (IHsize _ _ _ _ _ _ Hr1) in Hrule2...
    destruct Hrule2 as [s' Hrule2].
    apply (ex_r _ _ (map wn l6 ++ lrule ++
                             (Brule :: map wn l4) ++ l3)) in Hrule2...
    eexists.
    ex_apply_mix2 f1 Hl1 Hrule2.
  + apply eq_sym in H0 ;
    apply app_eq_nil in H0 ;
    destruct H0 ; subst.
    eapply IHsize in Hrule2...
- (* oc_r *)
  rewrite map_app in Hl2.
  rewrite ? app_comm_cons in Hl2.
  rewrite <- app_assoc in Hl2.
  change (map wn (x :: l6) ++ l)
    with ((wn x) :: map wn l6 ++ l) in Hl2.
  eapply IHsize in Hl2...
  destruct Hl2 as [s' Hl2].
  eexists.
  rewrite <- app_comm_cons in Hl2.
  rewrite ? app_assoc in Hl2.
  rewrite <- ? map_app in Hl2.
  rewrite ? app_assoc.
  rewrite <- ? map_app.
  eapply Hrule...
- (* cut_r *)
  rewrite <- (app_nil_l (_ :: l1)) in H.
  dichot_elt_app_exec H ; subst.
  + rewrite app_comm_cons in Hrule2.
    apply (ex_r _ _ (dual (wn x) :: l3 ++ A :: nil)) in Hr1...
    assert (0 < s0) by apply (psize_pos _ _ _ Hl1).
    eapply (IHsize _ _ _ _ _ _ Hr1) in Hrule2...
    destruct Hrule2 as [s' Hrule2].
    apply (ex_r _ _ (A :: map wn l6 ++ lrule ++
                             (Brule :: map wn l4) ++ l3)) in Hrule2...
    eexists.
    eapply ex_r ; [ apply (@cut_r _ f1 A _ _ _ _ Hl1 Hrule2) | ]...
  + apply eq_sym in H0 ;
    apply app_eq_nil in H0 ;
    destruct H0 ; subst.
    apply (ex_r _ _ (dual (wn x) :: l1 ++ dual A :: nil)) in Hl1...
    assert (0 < s2) by apply (psize_pos _ _ _ Hr1).
    apply (IHsize _ _ _ _ _ _ Hl1) in Hrule2...
    destruct Hrule2 as [s' Hrule2].
    apply (ex_r _ _ (dual A :: map wn l6 ++ lrule ++
                             (Brule :: map wn l4) ++ l1)) in Hrule2...
    eexists.
    eapply ex_r ; [ apply (@cut_r _ f1 A _ _ _ _ Hrule2 Hr1) | ]...
- (* gax_r *)
  exfalso.
  apply P_gax_atomic in Hax.
  inversion Hax as [ lax | hax tax Hax2 ].
  inversion Hax2.
Qed.

(* begin hide *)
Ltac ex_r_comm_P A Hr HP1 Hl1 l1 IHsize Hpp :=
  let l2' := fresh "l2'" in
  let l3' := fresh "l3'" in
  assert (Heq := HP1) ;
  apply Permutation_vs_cons_inv in Heq ;
  destruct Heq as (l2' & l3' & Heq) ; subst ;
  rewrite <- (bidual A) in Hr ;
  (eapply IHsize in Hl1 ; myeasy_perm ; try fsize_auto) ;
  destruct Hl1 as [s' Hl1] ;
  eexists ;
  rewrite <- (app_nil_l (dual _ :: l1)) in HP1 ;
  apply Permutation_app_inv in HP1 ;
  eapply ex_r ;
  unfold PCperm ; try rewrite <- Hpp ;
  myeasy_perm ; try fsize_auto.

Ltac ex_r_comm_C A Hr HP1 Hl1 IHsize :=
  let l2' := fresh "l2'" in
  let l3' := fresh "l3'" in
  apply cperm_vs_cons_inv in HP1 ;
  destruct HP1 as (l2' & l3' & HP1l & HP1r) ; subst ;
  rewrite <- (bidual A) in Hr ;
  (eapply IHsize in Hl1 ; myeasy_perm ; try fsize_auto) ;
  destruct Hl1 as [s' Hl1] ;
  eexists ;
  eapply ex_r ;
  myeasy_perm ; try fsize_auto.

Ltac mix2_r_comm A Hr Hl1 Hr1 l l0 l1 l2 l3 l4 H1 H2 f1 IHsize :=
  simpl in Hr ;
  rewrite <- (bidual A) in Hr ;
  rewrite <- (app_nil_l (_ :: l1)) in H1 ;
  dichot_elt_app_exec H1 ; subst ;
  [ (eapply (IHsize) in Hr1 ; myeasy_perm ; try fsize_auto) ;
    destruct Hr1 as [s' Hr1] ;
    eexists ;
    simpl ;
    try (apply (@mix2_r _ f1) ; (* 0-ary rule *)
         myeasy_perm ; try fsize_auto ; fail) ;
    try (apply (ex_r _ (l0 ++ l3 ++ l)) ; myeasy_perm ; try fsize_auto ;
                                                          (* 1-ary rule *)
         apply (@mix2_r _ f1) ; myeasy_perm ; try fsize_auto ; fail) ;
    try (apply (ex_r _ ((l4 ++ l0) ++ l ++ l2)) ; myeasy_perm ; try fsize_auto ;
                                                          (* 2-ary rule *)
         simpl in Hr1 ; rewrite app_assoc ;
         apply (@mix2_r _ f1) ; myeasy_perm ; try fsize_auto ; fail)
  | (eapply IHsize in Hl1 ; myeasy_perm ; try fsize_auto) ;
    destruct Hl1 as [s' Hl1] ;
    apply eq_sym in H2 ;
    apply app_eq_nil in H2 ;
    destruct H2 ; subst ;
    eexists ;
    try (myeasy_perm ; try fsize_auto ; fail) ; (* 0-ary rule *)
    try (apply (ex_r _ (l3 ++ l1)) ; myeasy_perm ; try fsize_auto ; fail) ;
                                                (* 1-ary rule *)
    try (apply (ex_r _ ((l4 ++ l0) ++ l1)) ; myeasy_perm ; try fsize_auto ; fail)
                                                (* 2-ary rule *) ].

Ltac comm_case rule Hl2 Hr2 IHsize :=
  try (rewrite ? app_comm_cons in Hl2 ;
       (eapply IHsize in Hl2 ; myeasy_perm ; try fsize_auto) ;
       destruct Hl2 as [s' Hl2]) ;
  try (rewrite app_comm_cons in Hr2 ;
       (eapply IHsize in Hr2 ; myeasy_perm ; try fsize_auto) ;
       destruct Hr2 as [s'' Hr2]) ;
  eexists ;
  rewrite <- app_comm_cons ;
  try (apply rule ; myeasy_perm ; try fsize_auto ; fail) ;
  try (rewrite ? app_assoc ;
       apply rule ; myeasy_perm ; try fsize_auto ;
       rewrite <- app_assoc ;
       myeasy_perm ; try fsize_auto ; fail) ;
  try (rewrite <- app_assoc ;
       apply rule ; myeasy_perm ; try fsize_auto ; fail).

Ltac goto_key_case A rule Hl Hr Hl1 Hr1 Hl2 Hr2 HP1
                   X l l' l0 l1 l2 l3 l4 H0 H1 H2 f1 IHsize Hax Hcut :=
  destruct l2 ; inversion H0 ; subst ;
  [ (* left-most formula on right side is cut one *)
    try rewrite app_nil_r ;
    inversion_ll Hl f1 X l' Hl1 Hr1 HP1 Hax ;
    [ (* ex_r / _ *)
      try ( hyps_PCperm_unfold ; remember (pperm P) as pp eqn:Hpp ; destruct pp ;
            [ ex_r_comm_P A Hr HP1 Hl1 l1 IHsize Hpp
            | ex_r_comm_C A Hr HP1 Hl1 IHsize ] ; fail)
    | (* mix2_r / _ *)
      try (mix2_r_comm A Hr Hl1 Hr1 l l0 l1 l2 l3 l4 H1 H2 f1 IHsize ; fail)
    | (* key cases *) ..
    | (* cut_r case *)
      try (rewrite Hcut in f1 ; inversion f1 ; fail)
    | (* gax_r case *)
      try (exfalso ; apply P_gax_atomic in Hax ;
           inversion Hax as [ lax | hax tax Hax2 ] ; inversion Hax2) ]
  | (* commutative case *)
    try (comm_case rule Hl2 Hr2 IHsize ; fail) ].
(* end hide *)

(** Key statement for cut elimination
by induction on the size of the cut formula and on the sum of the sizes of the hypotheses (lexicographically ordered).
It is proved under the assumption of atomic axioms closed under cut and exchange. *)
Theorem cut_elim :
  (forall l1 l2, pgax P l1 -> PCperm (pperm P) l1 l2 -> pgax P l2) ->
  (forall x l1 l2 l3, pgax P (dual x :: l1) -> pgax P (l2 ++ x :: l3) ->
     pgax P (l2 ++ l1 ++ l3)) ->
  forall c s A l1 l2 l3 s1 s2,
  ll P (dual A :: l1) s1 -> ll P (l2 ++ A :: l3) s2 ->
    s = s1 + s2 -> fsize A <= c -> exists s',
    ll P (l2 ++ l1 ++ l3) s'.
Proof with myeasy_perm ; try fsize_auto.
intros P_gax_ex P_gax_cutted.
case_eq (pcut P) ; intros P_cutfree.
{ intros c s A l1 l2 l3 s1 s2 Hl Hr Heqs Hc.
  eexists.
  apply (ex_r _ ((l3 ++ l2) ++ l1))...
  eapply cut_r...
  eapply ex_r ; [ apply Hr | ]... }
induction c using (well_founded_induction lt_wf).
assert (
  forall A l1 l2 l3 s1 s2,
    ll P (dual A :: l1) s1 ->
    ll P (l2 ++ A :: l3) s2 ->
    fsize A < c -> exists s' : nat, ll P (l2 ++ l1 ++ l3) s'
  ) as IHcut by (intros ; eapply H ; myeeasy).
clear H.
induction s using (well_founded_induction lt_wf).
assert (
  forall A l1 l2 l3 s1 s2,
    ll P (dual A :: l1) s1 ->
    ll P (l2 ++ A :: l3) s2 ->
    s1 + s2 < s -> fsize A <= c -> exists s' : nat, ll P (l2 ++ l1 ++ l3) s'
  ) as IHsize by (intros ; eapply H ; myeeasy).
clear H.
intros A l1 l2 l3 s1 s2 Hl Hr Heqs Hc.
rewrite_all Heqs ; clear s Heqs.
inversion_ll Hr f' X l' Hl2 Hr2 HP2 Hax.
- (* ax_r *)
  eexists.
  destruct l2 ; inversion H ; subst.
  + eapply ex_r in Hl...
  + destruct l2 ; inversion H2 ; subst.
    * eapply ex_r in Hl...
    * destruct l2 ; inversion H3.
- (* ex_r *)
  hyps_PCperm_unfold ; unfold PCperm ; remember (pperm P) as pp ; destruct pp.
  + assert (Heq := HP2) ;
      apply Permutation_vs_elt_inv in Heq ;
      destruct Heq as (l2' & l3' & Heq) ;
      subst.
    eapply IHsize in Hl2...
    destruct Hl2 as [s' Hl2].
    eexists.
    eapply ex_r in Hl2...
    unfold PCperm ; rewrite <- Heqpp...
  + apply cperm_vs_elt_inv in HP2.
    destruct HP2 as (lA1 & lA2 & HlA1 & HlA2) ;
      subst.
    eapply IHsize in Hl2...
    destruct Hl2 as [s' Hl2].
    eexists.
    eapply ex_r in Hl2...
    etransitivity ; [ apply PCperm_app_rot | ].
    rewrite <- HlA1...
- (* mix0_r *)
  destruct l2 ; inversion H.
- (* mix2_r *)
  dichot_elt_app_exec H ;
  [assert (HH:=Hr2) | assert (HH:=Hl2)] ;
  subst.
  + (* cut formula in left side *)
    eapply IHsize in HH...
    destruct HH as [s' HH].
    eexists.
    rewrite ? app_assoc.
    rewrite ? app_assoc in HH.
    apply (@mix2_r _ f')...
  + (* cut formula in right side *)
    eapply IHsize in HH...
    destruct HH as [s' HH].
    eexists.
    rewrite <- app_assoc.
    apply (@mix2_r _ f')...
- (* one_r *)
  goto_key_case one one_r Hl Hr Hl1 Hr1 Hl2 Hr2 HP1
                X l l' l0 l1 l2 l3 l4 H H0 H1 f1 IHsize Hax P_cutfree.
  + (* key case *)
     eexists...
  + (* commutative case *)
    destruct l2 ; inversion H.
- (* bot_r *)
  goto_key_case bot bot_r Hl Hr Hl1 Hr1 Hl2 Hr2 HP1
                X l l' l0 l1 l2 l3 l4 H H0 H1 f1 IHsize Hax P_cutfree.
  + (* key case *)
    eexists...
- (* tens_r *)
  goto_key_case (tens A0 B) tens_r Hl Hr Hl1 Hr1 Hl2 Hr2 HP1
                X l l' l0 l1 l2 l3 l4 H H0 H1 f1 IHsize Hax P_cutfree.
  + (* key case parr/tens *)
    rewrite <- (bidual B) in Hr2.
    rewrite <- (app_nil_l (dual B :: _)) in Hl1.
    eapply (IHcut _ _ nil (dual A0 :: _)) in Hr2...
    destruct Hr2 as [s' Hr2].
    simpl in Hr2.
    rewrite <- (bidual A0) in Hl2.
    eapply IHcut in Hl2...
    destruct Hl2 as [s'' Hl2].
    eexists.
    eapply (ex_r _ _ _ _ Hl2)...
  + (* commutative case *)
    dichot_elt_app_exec H2 ; subst ;
    comm_case tens_r Hl2 Hr2 IHsize.
- (* parr_r *)
  goto_key_case (parr A0 B) parr_r Hl Hr Hl1 Hr1 Hl2 Hr2 HP1
                X l l' l0 l1 l2 l3 l4 H H0 H1 f1 IHsize Hax P_cutfree.
  + (* key case tens/parr bis *)
    change (A0 :: B :: l3) with ((A0 :: nil) ++ B :: l3) in Hl2.
    eapply IHcut in Hl2...
    destruct Hl2 as [s' Hl2].
    simpl in Hl2.
    rewrite <- (app_nil_l (A0 :: _)) in Hl2.
    eapply IHcut in Hl2...
    destruct Hl2 as [s'' Hl2].
    rewrite <- app_assoc.
    eexists...
- (* top_r *)
  goto_key_case top top_r Hl Hr Hl1 Hr1 Hl2 Hr2 HP1
                X l l' l0 l1 l2 l3 l4 H H0 H1 f1 IHsize Hax P_cutfree.
- (* plus_r1 *)
  goto_key_case (aplus A0 B) plus_r1 Hl Hr Hl1 Hr1 Hl2 Hr2 HP1
                X l l' l0 l1 l2 l3 l4 H H0 H1 f1 IHsize Hax P_cutfree.
  + (* key case *)
    eapply IHcut in Hl1...
- (* plus_r2 *)
  goto_key_case (aplus B A0) plus_r2 Hl Hr Hl1 Hr1 Hl2 Hr2 HP1
                X l l' l0 l1 l2 l3 l4 H H0 H1 f1 IHsize Hax P_cutfree.
  + (* key case *)
    eapply IHcut in Hr1...
- (* with_r *)
  goto_key_case (awith A0 B) with_r Hl Hr Hl1 Hr1 Hl2 Hr2 HP1
                X l l' l0 l1 l2 l3 l4 H H0 H1 f1 IHsize Hax P_cutfree.
  + (* key case plus_r1/with_r bis *)
    eapply IHcut in Hl1...
  + (* key case plus_r2/with_r bis *)
    eapply IHcut in Hl1...
- (* oc_r *)
  goto_key_case (oc A0) oc_r Hl Hr Hl1 Hr1 Hl2 Hr2 HP1
                X l l' l0 l1 l2 l3 l4 H H0 H1 f1 IHsize Hax P_cutfree.
  + (* mix2_r / _ *)
    mix2_r_comm (oc A0) Hr Hl1 Hr1 l l0 l1 l2 l3 l4 H0 H1 f1 IHsize.
    * ex_apply_mix2 f1 Hl1 Hr1.
    * eapply ex_r in Hl1...
  + (* key case de_r/oc_r *)
    eapply IHcut in Hl1...
  + (* key case wk_r/oc_r *)
    eapply (wk_list_r l) in Hl1.
    destruct Hl1 as [s' Hl1].
    eexists.
    eapply ex_r ; [ apply Hl1 | ]...
  + (* key case co_r/oc_r *)
    eapply (key_case_oc_subst A0 l (map wn lw :: l0 :: nil)) in Hl1...
    * destruct Hl1 as [s' Hl1].
      simpl in Hl1.
      rewrite <- ? app_assoc in Hl1.
      apply co_list_r in Hl1.
      destruct Hl1 as [s'' Hl1].
      eexists.
      eapply ex_r ; [ apply Hl1 | ]...
    * intros.
      rewrite <- (bidual A0) in Hl2.
      eapply IHcut...
  + (* commutative case *)
    symmetry in H2.
    decomp_map H2 ; subst.
    rewrite <- (app_nil_r (map wn l6)).
    rewrite <- app_comm_cons.
    eapply comm_oc_wn...
    * replace (map wn l4 ++ wn x :: map wn l6)
         with (map wn (l4 ++ x :: l6))...
      rewrite map_app...
    * intros s' lw' Hhyp.
      rewrite app_nil_r.
      rewrite app_nil_r in Hhyp.
      apply oc_r...
    * rewrite app_nil_r...
- (* de_r *)
  goto_key_case (wn A0) de_r Hl Hr Hl1 Hr1 Hl2 Hr2 HP1
                X l l' l0 l1 l2 l3 l4 H H0 H1 f1 IHsize Hax P_cutfree.
  + (* key case *)
    eapply IHcut in Hl1...
- (* wk_r *)
  goto_key_case (wn A0) wk_r Hl Hr Hl1 Hr1 Hl2 Hr2 HP1
                X l l' l0 l1 l2 l3 l4 H H0 H1 f1 IHsize Hax P_cutfree.
  + (* key case *)
    eapply (wk_list_r l) in Hl2.
    destruct Hl2 as [s' Hl2].
    eexists.
    eapply ex_r ; [ apply Hl2 | ]...
- (* co_r *)
  goto_key_case (wn A0) co_r Hl Hr Hl1 Hr1 Hl2 Hr2 HP1
                X l l' l0 l1 l2 l3 l4 H H0 H1 f1 IHsize Hax P_cutfree.
  + mix2_r_comm (wn A0) Hr Hl1 Hr1 l l0 l1 l2 l3 l4 H0 H1 f1 IHsize.
    * ex_apply_mix2 f1 Hl1 Hr1.
    * clear Hr1.
      eapply (ex_r )...
  + (* key case oc_r/co_r bis *)
    eapply (key_case_oc_subst (dual A0) l0 (map wn lw :: l :: nil)) in Hl2 ;
      try rewrite bidual...
    * destruct Hl2 as [s' Hl2].
      simpl in Hl2.
      rewrite <- ? app_assoc in Hl2.
      apply co_list_r in Hl2.
      destruct Hl2 as [s'' Hl2].
      eexists.
      eapply ex_r ; [ apply Hl2 | ]...
    * intros.
      eapply (IHcut A0)...
  + symmetry in H2.
    dichot_elt_app_exec H2 ; subst.
    * decomp_map H0 ; subst.
      rewrite <- app_comm_cons.
      eapply comm_oc_wn...
      -- replace (map wn l4 ++ wn x :: map wn l6)
           with (map wn (l4 ++ x :: l6))...
         rewrite map_app...
      -- intros s' lw' Hhyp.
         apply co_r...
    * subst.
      rewrite ? app_comm_cons in Hl2.
      rewrite app_assoc in Hl2.
      eapply (IHsize _ _ _ _ _ _ Hl) in Hl2...
      destruct Hl2 as [s' Hl2].
      eexists.
      rewrite <- app_assoc in Hl2.
      rewrite <- ? app_comm_cons in Hl2.
      rewrite <- ? app_comm_cons.
      rewrite <- ? app_assoc.
      apply co_r in Hl2...
- (* cut_r *)
  rewrite P_cutfree in f'.
  inversion f'.
- (* gax_r *)
  inversion_ll Hl f1 X l' Hl1 Hr1 HP1 Hax2 ;
    try (
      destruct A ; inversion H ;
      apply P_gax_atomic in Hax ; apply Forall_app_inv in Hax ; destruct Hax as [_ Hax] ;
      inversion Hax as [ lax | hax tax Hax2 ] ; inversion Hax2 ; fail).
  + (* ax_r / _ *)
    destruct A ; inversion H ; subst.
    eexists.
    apply gax_r...
  + (* ex_r / _ *)
    assert (ll P (A :: l3 ++ l2) 1) as Hr'.
    { eapply gax_r.
      apply (P_gax_ex _ _ Hax)... }
    rewrite <- (bidual A) in Hr'.
    hyps_PCperm_unfold ; remember (pperm P) as pp eqn:Hpp ; destruct pp.
    * assert (Heq := HP1).
      apply Permutation_vs_cons_inv in Heq.
      destruct Heq as (l'1 & l'2 & Heq) ; subst.
      symmetry in HP1.
      apply Permutation_cons_app_inv in HP1.
      eapply IHsize in Hr'...
      destruct Hr' as [s' Hr'].
      eexists.
      eapply ex_r...
      unfold PCperm ; rewrite <- Hpp...
    * apply cperm_vs_cons_inv in HP1.
      destruct HP1 as (l'1 & l'2 & Heq1 & Heq2) ; subst.
      eapply IHsize in Hr'...
      destruct Hr' as [s' Hr'].
      eexists.
      eapply ex_r...
  + (* mix2_r / _ *)
    destruct l4.
    * simpl in H ; subst.
      clear Hl ; eapply IHsize...
    * inversion H ; subst.
      eapply IHsize in Hr1...
      destruct Hr1 as [s' Hr1].
      eexists.
      apply (ex_r _ _ (l3 ++ l2 ++ l4)) in Hr1...
      eapply ex_r ; [ eapply (@mix2_r _ f1 _ _ _ _ Hr1 Hl1) | ]...
  + (* cut_r / _ *)
    rewrite P_cutfree in f1.
    inversion f1.
  + (* gax_r / _ *)
    eexists.
    apply gax_r.
    eapply P_gax_cutted...
Qed.

End Cut_Elim.

(** If axioms are atomic and closed under cut and exchange, then the cut rule is valid. *)
Lemma cut_r_gaxat {P} :
  (forall l, pgax P l -> Forall atomic l) ->
  (forall l1 l2, pgax P l1 -> PCperm (pperm P) l1 l2 -> pgax P l2) ->
  (forall x l1 l2 l3, pgax P (dual x :: l1) -> pgax P (l2 ++ x :: l3) ->
     pgax P (l2 ++ l1 ++ l3)) ->
  forall A l1 l2 s1 s2,
    ll P (dual A :: l1) s1 -> ll P (A :: l2) s2 -> exists s', ll P (l2 ++ l1) s'.
Proof with myeeasy.
intros Hgax_at Hgax_ex Hgax_cut A l1 l2 s1 s2 pi1 pi2.
eapply cut_elim in pi1...
- destruct pi1 as [s' pi1].
  assert (exists s', ll P (nil ++ l1 ++ l2) s') as Hex.
  + eexists...
  + destruct Hex as [s0 Hex].
    eexists.
    eapply (ex_r _ (nil ++ l1 ++ l2))...
    simpl.
    apply PCperm_app_comm.
- eassumption.
Qed.

(** If axioms are atomic and closed under cut and exchange, then the cut rule is admissible:
provability is preserved if we remove the cut rule. *)
Lemma cut_admissible {P} :
  (forall l, pgax P l -> Forall atomic l) ->
  (forall l1 l2, pgax P l1 -> PCperm (pperm P) l1 l2 -> pgax P l2) ->
  (forall x l1 l2 l3, pgax P (dual x :: l1) -> pgax P (l2 ++ x :: l3) ->
     pgax P (l2 ++ l1 ++ l3)) ->
  forall l s, ll P l s -> exists s', ll (cutrm_pfrag P) l s'.
Proof with myeeasy.
intros Hgax_at Hgax_ex Hgax_cut l s H.
induction H ;
  try (eexists ; constructor ; myeeasy ; fail) ;
  try (destruct IHll as [s' IHll] ; eexists ; constructor ; myeeasy ; fail) ;
  try (destruct IHll1 as [s'1 IHll1] ;
       destruct IHll2 as [s'2 IHll2] ; eexists ; constructor ; myeeasy ; fail).
- destruct IHll as [s' IHll].
  eexists.
  apply (ex_r _ l1)...
- destruct IHll1 as [s'1 IHll1].
  destruct IHll2 as [s'2 IHll2].
  eapply cut_r_gaxat...
Qed.

(** If there are no axioms (except the identity rule), then the cut rule is valid. *)
Lemma cut_r_axfree {P} : (forall l, ~ pgax P l) -> forall A l1 l2 s1 s2, 
  ll P (dual A :: l1) s1 -> ll P (A :: l2) s2 -> exists s,
    ll P (l2 ++ l1) s.
Proof with myeeasy.
intros P_axfree A l1 l2 s1 s2 pi1 pi2.
case_eq (pcut P) ; intros Hcut.
- eexists.
  eapply (@cut_r _ Hcut)...
- eapply cut_r_gaxat ;
    try (now (intros ; apply P_axfree in H ; inversion H))...
Qed.

(** If there are no axioms (except the identity rule), then the cut rule is admissible:
provability is preserved if we remove the cut rule. *)
Lemma cut_admissible_axfree {P} : (forall l, ~ pgax P l) -> forall l s,
  ll P l s -> exists s', ll (cutrm_pfrag P) l s'.
Proof.
intros P_axfree l s H.
eapply cut_admissible ;
  try (intros ; exfalso ; eapply P_axfree ; myeeasy ; fail) ;
  eassumption.
Qed.


(** ** Subformula Property *)

(** version of ll with predicate parameter for constraining sequents *)
Inductive ll_ps P (PS : list formula -> Prop) : list formula -> Prop :=
| ax_ps_r : forall X, PS (covar X :: var X :: nil) -> ll_ps P PS (covar X :: var X :: nil)
| ex_ps_r : forall l1 l2, PS l2 -> ll_ps P PS l1 -> PCperm (pperm P) l1 l2 -> ll_ps P PS l2
| mix0_ps_r {f : pmix0 P = true} : PS nil -> ll_ps P PS nil
| mix2_ps_r {f : pmix2 P = true} : forall l1 l2, PS (l2 ++ l1) -> 
                                     ll_ps P PS l1 -> ll_ps P PS l2 -> ll_ps P PS (l2 ++ l1)
| one_ps_r : PS (one :: nil) -> ll_ps P PS (one :: nil)
| bot_ps_r : forall l, PS (bot :: l) -> ll_ps P PS l -> ll_ps P PS (bot :: l)
| tens_ps_r : forall A B l1 l2, PS (tens A B :: l2 ++ l1) ->
                               ll_ps P PS (A :: l1) -> ll_ps P PS (B :: l2) ->
                               ll_ps P PS (tens A B :: l2 ++ l1)
| parr_ps_r : forall A B l, PS (parr A B :: l) -> 
                               ll_ps P PS (A :: B :: l) -> ll_ps P PS (parr A B :: l)
| top_ps_r : forall l, PS (top :: l) -> ll_ps P PS (top :: l)
| plus_ps_r1 : forall A B l, PS (aplus A B :: l) ->
                               ll_ps P PS (A :: l)-> ll_ps P PS (aplus A B :: l)
| plus_ps_r2 : forall A B l, PS (aplus B A :: l) ->
                               ll_ps P PS (A :: l) -> ll_ps P PS (aplus B A :: l)
| with_ps_r : forall A B l, PS (awith A B :: l) ->
                               ll_ps P PS (A :: l) -> ll_ps P PS (B :: l) ->
                               ll_ps P PS (awith A B :: l)
| oc_ps_r : forall A l, PS (oc A :: map wn l) ->
                                ll_ps P PS (A :: map wn l) -> ll_ps P PS (oc A :: map wn l)
| de_ps_r : forall A l, PS (wn A :: l) -> ll_ps P PS (A :: l) -> ll_ps P PS (wn A :: l)
| wk_ps_r : forall A l, PS (wn A :: l) -> ll_ps P PS l -> ll_ps P PS (wn A :: l)
| co_ps_r : forall A lw l, PS (wn A :: map wn lw ++ l) ->
                               ll_ps P PS (wn A :: map wn lw ++ wn A :: l) ->
                               ll_ps P PS (wn A :: map wn lw ++ l)
| cut_ps_r {f : pcut P = true} : forall A l1 l2, PS (l2 ++ l1) ->
                               ll_ps P PS (dual A :: l1) -> ll_ps P PS (A :: l2) ->
                               ll_ps P PS (l2 ++ l1)
| gax_ps_r : forall l, PS l -> pgax P l -> ll_ps P PS l.

Lemma stronger_ps_pfrag P Q : le_pfrag P Q -> forall PS l,
  ll_ps P PS l -> ll_ps Q PS l.
Proof with myeeasy.
intros Hle PS l H.
induction H ; try (constructor ; myeasy ; fail).
- apply (ex_ps_r _ _ l1)...
  inversion Hle.
  destruct H3 as (_ & _ & _ & Hp).
  unfold PCperm in H0.
  unfold PCperm.
  destruct (pperm P) ; destruct (pperm Q) ;
    simpl in Hp ; try inversion Hp...
  apply cperm_perm...
- unfold le_pfrag in Hle.
  rewrite f in Hle.
  destruct Hle as (_ & _ & Hmix0 & _).
  simpl in Hmix0...
  apply (@mix0_ps_r _ _ Hmix0)...
- unfold le_pfrag in Hle.
  rewrite f in Hle.
  destruct Hle as (_ & _ & _ & Hmix2 & _).
  simpl in Hmix2...
  apply (@mix2_ps_r _ _ Hmix2)...
- inversion Hle.
  rewrite f in H2.
  simpl in H2.
  eapply (@cut_ps_r _ _ H2)...
- apply gax_ps_r...
  apply Hle...
Qed.

Lemma ll_ps_stronger {P} : forall (PS QS : list formula -> Prop) l,
  ll_ps P PS l -> (forall x, PS x -> QS x) -> ll_ps P QS l.
Proof with try eassumption.
intros PS QS l pi Hs.
induction pi ;
  try (constructor ; try apply Hs ; eassumption ; fail).
- eapply ex_ps_r...
  apply Hs...
- eapply (@cut_ps_r _ _ f)...
  apply Hs...
Qed.

Lemma ll_ps_is_ps {P} : forall l PS, ll_ps P PS l -> PS l.
Proof.
intros l PS Hll.
inversion Hll ; assumption.
Qed.

Lemma ll_ps_is_ll {P} : forall l PS, ll_ps P PS l -> exists s, ll P l s.
Proof with try eassumption.
intros l PS pi.
induction pi ;
  try (destruct IHpi as [s IHpi]) ;
  try (destruct IHpi1 as [s1 IHpi1]) ;
  try (destruct IHpi2 as [s2 IHpi2]) ;
  eexists ;
  try (constructor ; eassumption ; fail).
- eapply ex_r...
- eapply (@cut_r _ f)...
Qed.

Lemma ll_is_ll_ps {P} : forall l s, ll P l s -> ll_ps P (fun _ => True) l.
Proof with myeeasy.
intros l s pi.
induction pi ;
  try (constructor ; myeasy ; fail).
- eapply ex_ps_r...
- eapply (@cut_ps_r _ _ f)...
Qed.

(** A fragment is a subset of formulas closed under subformula. *)
Definition fragment (FS : formula -> Prop) :=
  forall A, FS A -> forall B, subform B A -> FS B.

(** Linear logic is conservative over its fragments (in the absence of cut). *)
Lemma conservativity {P} : pcut P = false -> forall FS, fragment FS ->
  forall l, ll_ps P (fun _ => True) l -> Forall FS l -> ll_ps P (Forall FS) l.
Proof with try eassumption ; try reflexivity.
intros P_cutfree FS HFS l pi.
induction pi ; intros HFrag.
- apply ax_ps_r...
- apply (ex_ps_r _ _ l1)...
  apply IHpi.
  apply PCperm_sym in H0.
  eapply PCperm_Forall...
- apply (@mix0_ps_r _ _ f)...
- assert (HFrag2 := Forall_app_inv _ _ _ HFrag).
  destruct HFrag2.
  apply (@mix2_ps_r _ _ f)...
  + apply IHpi1...
  + apply IHpi2...
- apply one_ps_r...
- inversion HFrag.
  apply bot_ps_r...
  apply IHpi...
- inversion HFrag ; subst.
  apply Forall_app_inv in H3.
  destruct H3.
  apply tens_ps_r...
  + apply IHpi1...
    constructor...
    eapply HFS...
    apply sub_tens_l...
  + apply IHpi2...
    constructor...
    eapply HFS...
    apply sub_tens_r...
- inversion HFrag ; subst.
  apply parr_ps_r...
  apply IHpi.
  constructor ; [ | constructor ]...
  + eapply HFS...
    apply sub_parr_l...
  + eapply HFS...
    apply sub_parr_r...
- apply top_ps_r...
- inversion HFrag ; subst.
  apply plus_ps_r1...
  apply IHpi.
  constructor...
  eapply HFS...
  apply sub_plus_l...
- inversion HFrag ; subst.
  apply plus_ps_r2...
  apply IHpi.
  constructor...
  eapply HFS...
  apply sub_plus_r...
- inversion HFrag ; subst.
  apply with_ps_r...
  + apply IHpi1...
    constructor...
    eapply HFS...
    apply sub_with_l...
  + apply IHpi2...
    constructor...
    eapply HFS...
    apply sub_with_r...
- inversion HFrag ; subst.
  apply oc_ps_r...
  apply IHpi.
  constructor...
  eapply HFS...
  apply sub_oc...
- inversion HFrag ; subst.
  apply de_ps_r...
  apply IHpi.
  constructor...
  eapply HFS...
  apply sub_wn...
- inversion HFrag ; subst.
  apply wk_ps_r...
  apply IHpi...
- inversion HFrag ; subst.
  apply Forall_app_inv in H3.
  destruct H3.
  apply co_ps_r...
  apply IHpi.
  constructor...
  apply Forall_app...
  constructor...
- rewrite P_cutfree in f.
  inversion f.
- apply gax_ps_r...
Qed.

(** Subformula property:
any provable sequent is provable by a proof containing only subformulas of this sequent. *)
Proposition subformula {P} : pcut P = false -> forall l s,
  ll P l s -> ll_ps P (fun x => subform_list x l) l.
Proof with try eassumption ; try reflexivity.
intros P_cutfree l s pi.
apply ll_is_ll_ps in pi.
apply conservativity...
- intros A Hf B Hs.
  revert Hf ; clear - Hs ; induction l ; intro Hf ; inversion Hf ; subst.
  + apply Exists_cons_hd.
    etransitivity...
  + apply Exists_cons_tl.
    apply IHl...
- apply (sub_id_list l nil).
Qed.

(* Cut is admissible in any fragment with no axioms. *)
Lemma cut_admissible_fragment {P} : (forall l, ~ pgax P l) ->
 forall FS, fragment FS -> forall l,
   ll_ps P (Forall FS) l -> ll_ps (cutrm_pfrag P) (Forall FS) l.
Proof with myeeasy.
intros P_axfree FS HFS l pi.
assert (Forall FS l) as HFSl by (destruct pi ; myeeasy).
apply ll_ps_is_ll in pi.
destruct pi as [s pi].
apply cut_admissible_axfree in pi...
clear s ; destruct pi as [s pi].
apply ll_is_ll_ps in pi.
apply conservativity...
Qed.

(** Linear logic (with no axioms) is conservative over its fragments. *)
Lemma conservativity_cut_axfree {P} : (forall l, ~ pgax P l) ->
  forall FS, fragment FS -> forall l s,
    ll P l s -> Forall FS l -> ll_ps P (Forall FS) l.
Proof with try eassumption ; try reflexivity.
intros P_axfree FS Hf l s pi HFS.
apply cut_admissible_axfree in pi...
clear s ; destruct pi as [s pi].
apply ll_is_ll_ps in pi.
eapply conservativity in pi...
clear - pi ; induction pi ;
  try (constructor ; assumption ; fail).
- eapply ex_ps_r...
- eapply @cut_ps_r...
  destruct P.
  inversion f.
Qed.


(** ** Deduction Theorem *)

Lemma ext_wn_param P Q (Q_perm : pperm Q = true) : forall l l0 s,
  ll P l s ->
  (pcut P = true -> pcut Q = true) ->
  (forall l', pgax P l' -> exists s0, ll Q (l' ++ map wn l0) s0) ->
  (pmix0 P = true -> pmix0 Q = false -> exists s0, ll Q (map wn l0) s0) ->
  (pmix2 P = true -> pmix2 Q = false ->
     forall l1 l2 s1 s2, ll Q (l1 ++ map wn l0) s1 -> ll Q (l2 ++ map wn l0) s2 ->
       exists s0, ll Q (l2 ++ l1 ++ map wn l0) s0) ->
  exists s', ll Q (l ++ map wn l0) s'.
Proof with myeeasy.
intros l l0 s pi Hpcut Hpgax Hpmix0 Hpmix2.
induction pi.
- assert (ll Q (covar X :: var X :: nil) 1) as Hax by (apply ax_r).
  apply (wk_list_r l0) in Hax.
  destruct Hax as [s Hax].
  eexists.
  eapply ex_r...
  apply PCperm_app_comm.
- destruct IHpi as [s' IHpi].
  eexists.
  eapply ex_r...
  apply PCperm_perm in H.
  rewrite Q_perm.
  apply Permutation_app_tail...
- case_eq (pmix0 Q) ; intros Q_mix0.
  + assert (ll Q nil 1) as Hmix0 by (apply (@mix0_r Q Q_mix0)).
    apply (wk_list_r l0) in Hmix0.
    destruct Hmix0 as [s' Hmix0].
    eexists.
    rewrite app_nil_r in Hmix0...
  + apply Hpmix0 in Q_mix0...
- case_eq (pmix2 Q) ; intros Q_mix2.
  + destruct IHpi1 as [s'1 IHpi1].
    destruct IHpi2 as [s'2 IHpi2].
    assert
      (exists s0, ll Q (map wn l0 ++ map wn l0 ++ l2 ++ l1) s0)
      as Hmix.
    * eexists.
      eapply ex_r.
      -- eapply (@mix2_r _ Q_mix2) ; [apply IHpi1 | apply IHpi2].
      -- subst ; unfold PCperm ; simpl ; rewrite Q_perm ; perm_solve.
    * destruct Hmix as [s0 Hmix].
      change (map wn l0 ++ map wn l0 ++ l2 ++ l1)
        with (map wn l0 ++ map wn nil ++ map wn l0 ++ l2 ++ l1)
        in Hmix.
      apply co_list_r in Hmix.
      destruct Hmix as [s'0 Hmix].
      eexists.
      eapply ex_r...
      PCperm_solve.
  + destruct IHpi1 as [s1' IHpi1].
    destruct IHpi2 as [s2' IHpi2].
    rewrite <- app_assoc.
    eapply Hpmix2 in Q_mix2...
- assert (ll Q (one :: nil) 1) as Hone by (apply one_r).
  apply (wk_list_r l0) in Hone.
  destruct Hone as [s Hone].
  eexists.
  eapply ex_r...
  apply PCperm_app_comm.
- destruct IHpi as [s' IHpi].
  eexists.
  apply bot_r...
- destruct IHpi1 as [s'1 IHpi1].
  destruct IHpi2 as [s'2 IHpi2].
  assert (exists s0,
    ll Q (map wn l0 ++ map wn l0 ++ (tens A B) :: l2 ++ l1) s0)
    as Htens.
  + eexists.
    eapply ex_r.
    * eapply tens_r ; [apply IHpi1 | apply IHpi2].
    * subst ; unfold PCperm ; simpl ; rewrite Q_perm ; perm_solve.
  + destruct Htens as [s0 Htens].
    change (map wn l0 ++ map wn l0 ++ tens A B :: l2 ++ l1)
      with (map wn l0 ++ map wn nil ++ map wn l0 ++ tens A B :: l2 ++ l1)
      in Htens.
    apply co_list_r in Htens.
    destruct Htens as [s'0 Htens].
    eexists.
    eapply ex_r...
    PCperm_solve.
- destruct IHpi as [s' IHpi].
  eexists.
  apply parr_r...
- eexists.
  apply top_r.
- destruct IHpi as [s' IHpi].
  eexists.
  apply plus_r1...
- destruct IHpi as [s' IHpi].
  eexists.
  apply plus_r2...
- destruct IHpi1 as [s'1 IHpi1].
  destruct IHpi2 as [s'2 IHpi2].
  eexists.
  apply with_r...
- destruct IHpi as [s' IHpi].
  eexists.
  rewrite <- app_comm_cons in IHpi.
  rewrite <- map_app in IHpi.
  rewrite <- app_comm_cons.
  rewrite <- map_app.
  apply oc_r...
- destruct IHpi as [s' IHpi].
  eexists.
  apply de_r...
- destruct IHpi as [s' IHpi].
  eexists.
  apply wk_r...
- destruct IHpi as [s' IHpi].
  eexists.
  rewrite <- app_comm_cons.
  rewrite <- app_assoc.
  rewrite <- app_comm_cons in IHpi.
  rewrite <- app_assoc in IHpi.
  apply co_r...
- destruct IHpi1 as [s'1 IHpi1].
  destruct IHpi2 as [s'2 IHpi2].
  assert (exists s0,
    ll Q (map wn l0 ++ map wn l0 ++ l2 ++ l1) s0)
    as Hcut.
  + eexists.
    eapply ex_r.
    * assert (pcut Q = true) as Q_cut by (now apply Hpcut).
      eapply (@cut_r _ Q_cut) ; [apply IHpi1 | apply IHpi2].
    * subst ; unfold PCperm ; simpl ; rewrite Q_perm ; perm_solve.
  + destruct Hcut as [s0 Hcut].
    change (map wn l0 ++ map wn l0 ++ l2 ++ l1)
      with (map wn l0 ++ map wn nil ++ map wn l0 ++ l2 ++ l1)
      in Hcut.
    apply co_list_r in Hcut.
    destruct Hcut as [s'0 Hcut].
    eexists.
    eapply ex_r...
    PCperm_solve.
- apply Hpgax...
Qed.

(** By extending axioms of [P] with [map wn l0],
one can turn any proof of [l] in [P] into a proof of [l ++ map wn l0]. *)
Lemma ext_wn {P} {P_perm : pperm P = true} : forall l l0 s,
  ll P l s -> exists s',
    ll (axupd_pfrag P (fun l => exists l', pgax P l' /\ l = l' ++ map wn l0))
       (l ++ map wn l0) s'.
Proof with myeeasy.
intros l l0 s pi.
remember
  (axupd_pfrag P (fun l => exists l', pgax P l' /\ l = l' ++ map wn l0))
  as Q.
eapply (ext_wn_param P Q) in pi...
- rewrite HeqQ...
- intros P_cut.
  rewrite HeqQ ; simpl...
- intros l' Hgax.
  eexists.
  eapply gax_r.
  rewrite HeqQ ; simpl.
  eexists ; split...
- intros P_mix0 Q_mix0.
  rewrite HeqQ in Q_mix0 ; simpl in Q_mix0.
  rewrite P_mix0 in Q_mix0.
  inversion Q_mix0.
- intros P_mix2 Q_mix2.
  rewrite HeqQ in Q_mix2 ; simpl in Q_mix2.
  rewrite P_mix2 in Q_mix2.
  inversion Q_mix2.
Qed.

Lemma weaker_hyp {P} : forall G : list formula -> Prop,
  (forall l, pgax P l -> exists s, ll (axupd_pfrag P G) l s) ->
    forall l s, ll P l s -> exists s', ll (axupd_pfrag P G) l s'.
Proof with myeeasy.
intros G Hhyps l s H.
induction H ;
  try (eexists ; constructor ; myeeasy ; fail) ;
  try (destruct IHll as [s' IHll] ; eexists ; constructor ; myeeasy ; fail) ;
  try (destruct IHll1 as [s'1 IHll1] ;
       destruct IHll2 as [s'2 IHll2] ; eexists ; constructor ; myeeasy ; fail).
- destruct IHll as [s' IHll].
  eexists.
  apply (ex_r _ l1)...
- destruct IHll1 as [s'1 IHll1].
  destruct IHll2 as [s'2 IHll2].
  eexists.
  assert (pcut (axupd_pfrag P G) = true) as G_cut by now simpl.
  eapply (@cut_r _ G_cut)...
- apply Hhyps...
Qed.

(** Deduction lemma for linear logic. *)
Lemma deduction {P} : pperm P = true -> (forall l, ~ pgax P l) -> pcut P = true ->
  forall A l, 
      (exists s, ll (axupd_pfrag P (fun x => x = A :: nil)) l s)
   <->
      (exists s, ll (cutrm_pfrag P) (l ++ (wn (dual A) :: nil)) s).
Proof with myeeasy.
intros P_perm P_axfree P_cut A l ; split ; intros [s H].
- cut (exists s, ll P (l ++ (wn (dual A) :: nil)) s) ;
    [ intros [s' Hc] ; eapply cut_admissible_axfree ; myeeasy | ].
  assert (pperm (axupd_pfrag P (fun x => x = A :: nil)) = true)
    as fp by now simpl.
  eapply (@ext_wn _ fp _ (dual A :: nil)) in H.
  destruct H as [s' H].
  apply (weaker_hyp (fun _ => False)) in H...
  + destruct H as [s0 H].
    eexists.
    apply (stronger_pfrag _ P) in H...
    nsplit 5 ; try apply leb_refl ; simpl.
    intros l0 HF ; destruct HF.
  + simpl.
    intros l0 Hl0.
    destruct Hl0 as (l'0 & Hone & Hl0).
    inversion Hone ; subst.
    assert (HaxA := @ax_exp (axupd_pfrag P (fun _ => False)) (dual A)).
    destruct HaxA as [s0 HaxA].
    eexists.
    eapply ex_r.
    * eapply de_r...
    * rewrite bidual.
      apply PCperm_swap.
- assert
    (exists s, ll (axupd_pfrag P (fun x => x = A :: nil))
                  ((oc A :: nil) ++ map wn nil) s)
    as Hoc.
  + eexists.
    apply oc_r.
    apply gax_r...
  + destruct Hoc as [s1 Hoc].
    eexists.
    replace (oc A) with (dual (wn (dual A))) in Hoc
      by (simpl ; rewrite bidual ; myeasy).
    apply (stronger_pfrag _ (axupd_pfrag P (fun x => x = A :: nil))) in H.
    * rewrite <- (app_nil_r l).
      assert (pcut (axupd_pfrag P (fun x => x = A :: nil)) = true)
        as f2 by now simpl.
      eapply (@cut_r _ f2)...
      eapply ex_r ; [ apply H | PCperm_solve ].
    * nsplit 5 ; try apply leb_refl...
      intros l0 Hax.
      apply P_axfree in Hax...
Qed.





