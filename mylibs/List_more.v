(* List_more Library *)
(* Coq 8.6 *)
(* v 0.3  2017/07/18   Olivier Laurent *)


(* Release Notes
     v0.2: change in decomp_map, etc up to symmetry
             and better implementation
     v0.3: change in cons2app and cons2app_hyp
             dealing with existentials
*)


(** * Add-ons for List library
Usefull properties apparently missing in the List library. *)

Require Export List.
Require Import Lt Le.


(** ** Simplification in lists *)

Ltac list_simpl :=
  repeat (
    repeat simpl ;
    repeat rewrite <- app_assoc ;
    repeat rewrite <- app_comm_cons ;
    repeat rewrite app_nil_r ;
    repeat rewrite <- map_rev ;
    repeat rewrite rev_involutive ;
    repeat rewrite rev_app_distr ;
    repeat rewrite rev_unit ;
    repeat rewrite map_app ).
Ltac list_simpl_hyp H :=
  repeat (
    repeat simpl in H ;
    repeat rewrite <- app_assoc in H ;
    repeat rewrite <- app_comm_cons in H ;
    repeat rewrite app_nil_r in H ;
    repeat rewrite <- map_rev in H ;
    repeat rewrite rev_involutive in H ;
    repeat rewrite rev_app_distr in H ;
    repeat rewrite rev_unit in H ;
    repeat rewrite map_app in H ).
Tactic Notation "list_simpl" "in" hyp(H) := list_simpl_hyp H.
Ltac list_simpl_hyps :=
  repeat (
    match goal with
    | H : _ |- _ => progress list_simpl in H
    end ).


(** ** Removal of [cons] constructions *)

Lemma cons_is_app {A} : forall (x:A) l, x :: l = (x :: nil) ++ l.
Proof.
reflexivity.
Qed.

Ltac cons2app :=
  repeat
  match goal with
  | |- context [ cons ?x ?l ] =>
         lazymatch l with
         | nil => fail
         | _ => rewrite (cons_is_app x l)
           (* one could prefer
                 change (cons x l) with (app (cons x nil) l)
              which leads to simpler generated term
              but does work not with existential variables *)
         end
  end.
Ltac cons2app_hyp H :=
  repeat
  match type of H with
  | context [ cons ?x ?l ]  =>
      lazymatch l with
      | nil => fail
      | _ =>  rewrite (cons_is_app x l) in H
           (* one could prefer
                 change (cons x l) with (app (cons x nil) l) in 
              which leads to simpler generated term
              but does work not with existential variables *)
      end
  end.
Tactic Notation "cons2app" "in" hyp(H) := cons2app_hyp H.
Ltac cons2app_hyps :=
  repeat (
    match goal with
    | H : _ |- _ => progress cons2app in H
    end ).
Ltac cons2app_all := cons2app_hyps ; cons2app.


(** ** Decomposition of [app] *)

Lemma dichot_app {A} : forall (l1 : list A) l2 l3 l4,
  l1 ++ l2 = l3 ++ l4 ->
     (exists l2', l1 ++ l2' = l3 /\ l2 = l2' ++ l4)
  \/ (exists l4', l1 = l3 ++ l4' /\ l4' ++ l2 = l4).
Proof with try assumption ; try reflexivity.
induction l1 ; induction l3 ; intros ;
  simpl in H ; inversion H ; subst.
- right.
  exists (@nil A).
  split ; simpl...
- left.
  exists (a::l3).
  split...
- right.
  exists (a::l1).
  split ; simpl...
- inversion H.
  apply IHl1 in H1.
  destruct H1 as [(l2' & H2'1 & H2'2) | (l4' & H4'1 & H4'2)] ;
    [left | right].
  + exists l2'.
    split...
    simpl.
    rewrite H2'1...
  + exists l4'.
    split...
    simpl.
    rewrite H4'1...
Qed.

Ltac dichot_app_exec H :=
  lazymatch type of H with
  | _ ++ _ = _ ++ _ => apply dichot_app in H ;
                         let l2 := fresh "l" in
                         let l4 := fresh "l" in
                         let H1 := fresh H in
                         let H2 := fresh H in
                         destruct H as [(l2 & H1 & H2) | (l4 & H1 & H2)]
  | _ => fail
  end.

Lemma dichot_elt_app {A} : forall l1 (a : A) l2 l3 l4,
  l1 ++ a :: l2 = l3 ++ l4 ->
     (exists l2', l1 ++ a :: l2' = l3 /\ l2 = l2' ++ l4)
  \/ (exists l4', l1 = l3 ++ l4' /\ l4' ++ a :: l2 = l4).
Proof with try reflexivity.
induction l1 ; induction l3 ; intros ;
  simpl in H ; inversion H ; subst.
- right.
  exists (@nil A).
  split ; simpl...
- left.
  exists l3.
  split...
- right.
  exists (a::l1).
  split ; simpl...
- inversion H.
  apply IHl1 in H1.
  destruct H1 as [(l' & H'1 & H'2) | (l' & H'1 & H'2)] ;
    [left | right] ;
    exists l' ;
    (split ; try assumption) ;
    simpl ;
    rewrite H'1...
Qed.

Ltac dichot_elt_app_exec H :=
  lazymatch type of H with
  | _ ++ _ :: _ = _ ++ _ => apply dichot_elt_app in H ;
                              let l2 := fresh "l" in
                              let l4 := fresh "l" in
                              let H1 := fresh H in
                              let H2 := fresh H in
                              destruct H as [(l2 & H1 & H2) | (l4 & H1 & H2)]
  | _ ++ _ = _ ++ _ :: _ => simple apply eq_sym in H ;
                            apply dichot_elt_app in H ;
                              let l2 := fresh "l" in
                              let l4 := fresh "l" in
                              let H1 := fresh H in
                              let H2 := fresh H in
                              destruct H as [(l2 & H1 & H2) | (l4 & H1 & H2)]
  | _ => fail
  end.


(** ** [In] *)

Lemma in_elt {A} : forall (a:A) l1 l2, In a (l1 ++ a :: l2).
Proof.
induction l1.
- apply in_eq.
- intros.
  apply in_cons.
  apply IHl1.
Qed.

Lemma in_elt_inv {A} : forall (a b : A) l1 l2,
  In a (l1 ++ b :: l2) -> a = b \/ In a (l1 ++ l2).
Proof with try reflexivity ; try assumption.
induction l1 ; intros l2 Hin ; inversion Hin ; subst.
- left...
- right...
- right.
  apply in_eq.
- apply IHl1 in H.
  destruct H ; [ left | right ]...
  apply in_cons...
Qed.

(** ** [last] *)

Lemma last_last {A} : forall l (a b : A), last (l ++ (a :: nil)) b = a.
Proof with try reflexivity.
induction l ; intros ; simpl...
rewrite IHl.
destruct l ; simpl...
Qed.

Lemma removelast_last {A} : forall l (a : A), removelast (l ++ (a :: nil)) = l.
Proof with try reflexivity.
induction l ; intros ; simpl...
rewrite IHl.
destruct l ; simpl...
Qed.

Lemma map_last : forall A B (f : A -> B) l a,
  map f (l ++ a :: nil) = (map f l) ++ (f a) :: nil.
Proof with try reflexivity.
induction l ; intros ; simpl...
rewrite IHl...
Qed.


(** ** [rev] *)

Lemma app_eq_rev {A} : forall l1 l2 l3 : list A,
  l1 ++ l2 = rev l3 ->
    exists l1' l2', l3 = l2' ++ l1' /\ l1 = rev l1' /\ l2 = rev l2'.
Proof with try assumption ; try reflexivity.
intros l1 l2 ; revert l1.
induction l2 using rev_ind ; intros.
- exists l3 ; exists (@nil A).
  split ; [ | split]...
  rewrite app_nil_r in H...
- destruct l3.
  + destruct l1 ; destruct l2 ; inversion H.
  + simpl in H.
    assert (l1 ++ l2 = rev l3) as Hrev.
    { rewrite app_assoc in H.
      remember (l1 ++ l2) as l4.
      remember (rev l3) as l5.
      clear - H.
      revert l4 H ; induction l5 ; intros l4 H.
      - destruct l4 ; inversion H...
        destruct l4 ; inversion H2.
      - destruct l4 ; inversion H.
        + destruct l5 ; inversion H2.
        + apply IHl5 in H2 ; subst... }
    apply IHl2 in Hrev.
    destruct Hrev as (l1' & l2' & Heq1 & Heq2 & Heq3) ; subst.
    exists l1' ; exists (x :: l2') ; split ; [ | split ]...
    rewrite rev_app_distr in H.
    rewrite <- app_assoc in H.
    apply app_inv_head in H.
    apply app_inv_head in H.
    inversion H ; subst...
Qed.


(** ** Decomposition of [map] *)

Lemma app_eq_map {A B} : forall (f : A -> B) l1 l2 l3,
  l1 ++ l2 = map f l3 ->
    exists l1' l2', l3 = l1' ++ l2' /\ l1 = map f l1' /\ l2 = map f l2'.
Proof with try assumption ; try reflexivity.
intros f.
induction l1 ; intros.
- exists (@nil A) ; exists l3.
  split ; [ | split]...
- destruct l3 ; inversion H.
  apply IHl1 in H2.
  destruct H2 as (? & ? & ? & ? & ?) ; subst.
  exists (a0::x) ; exists x0.
  split ; [ | split]...
Qed.

Lemma cons_eq_map {A B} : forall (f : A -> B) a l2 l3,
  a :: l2 = map f l3 ->
    exists b l2', l3 = b :: l2' /\ a = f b /\ l2 = map f l2'.
Proof.
intros f a l2 l3 H.
destruct l3 ; inversion H ; subst.
eexists ; eexists ; split ; [ | split] ;
  try reflexivity ; try eassumption.
Qed.

Ltac decomp_map_eq H Heq :=
  lazymatch type of H with
  | _ ++ _ = map _ _ => apply app_eq_map in H ;
                          let l1 := fresh "l" in
                          let l2 := fresh "l" in
                          let H1 := fresh H in
                          let H2 := fresh H in
                          let Heq1 := fresh Heq in
                          destruct H as (l1 & l2 & Heq1 & H1 & H2) ;
                          rewrite Heq1 in Heq ; clear Heq1 ;
                          decomp_map_eq H1 Heq ; decomp_map_eq H2 Heq
  | _ :: _ = map _ _ => apply cons_eq_map in H ;
                          let x := fresh "x" in
                          let l2 := fresh "l" in
                          let H1 := fresh H in
                          let H2 := fresh H in
                          let Heq1 := fresh Heq in
                          destruct H as (x & l2 & Heq1 & H1 & H2) ;
                          rewrite Heq1 in Heq ; clear Heq1 ;
                          decomp_map_eq H2 Heq
  | _ => idtac
  end.

Ltac decomp_map H :=
  match type of H with
  | _ = map _ ?l => let l' := fresh "l" in
                    let Heq := fresh H in
                    remember l as l' eqn:Heq in H ;
                    decomp_map_eq H Heq ;
                    let H' := fresh H in
                    clear l' ;
                    rename Heq into H'
  end.


(** ** [flat_map] *)

Lemma flat_map_app {A B} : forall (f : A -> list B) l1 l2,
  flat_map f (l1 ++ l2) = flat_map f l1 ++ flat_map f l2.
Proof with try reflexivity.
intros f l1 l2.
induction l1...
simpl.
rewrite IHl1.
rewrite app_assoc...
Qed.

Lemma flat_map_ext : forall (A B : Type) (f g : A -> list B),
  (forall a, f a = g a) -> forall l, flat_map f l = flat_map g l.
Proof with try reflexivity.
intros A B f g Hext.
induction l...
simpl.
rewrite Hext.
rewrite IHl...
Qed.


(** ** [Forall] and [Exists] *)

Lemma Forall_app_inv {A} : forall P (l1 : list A) l2,
  Forall P (l1 ++ l2) -> Forall P l1 /\ Forall P l2.
Proof with try assumption.
induction l1 ; intros.
- split...
  constructor.
- inversion H ; subst.
  apply IHl1 in H3.
  destruct H3.
  split...
  constructor...
Qed.

Lemma Forall_app {A} : forall P (l1 : list A) l2,
  Forall P l1 -> Forall P l2 -> Forall P (l1 ++ l2).
Proof with try assumption.
induction l1 ; intros...
inversion H ; subst.
apply IHl1 in H0...
constructor...
Qed.

Lemma Forall_In {A} : forall P l (a : A), Forall P l -> In a l -> P a.
Proof.
intros.
eapply (proj1 (Forall_forall _ _)) in H ; eassumption.
Qed.

Lemma Forall_elt {A} : forall P l1 l2 (a : A), Forall P (l1 ++ a :: l2) -> P a.
Proof.
intros P l1 l2 a HF.
eapply Forall_In ; try eassumption.
apply in_elt.
Qed.

Lemma Forall_wedge {A} : forall P Q (l : list A),
  (Forall (fun x => P x /\ Q x) l) -> Forall P l /\ Forall Q l.
Proof with try assumption.
induction l ; intro Hl ; split ; constructor ; inversion Hl ; subst.
- destruct H1...
- apply IHl...
- destruct H1...
- apply IHl...
Qed.

Lemma Forall_nth {A} : forall P l,
  Forall P l -> forall i (a : A), i < length l -> P (nth i l a).
Proof with try assumption.
induction l ; intros.
- inversion H0.
- destruct i ; inversion H...
  simpl in H0.
  apply IHl...
  apply lt_S_n...
Qed.

Lemma exists_Forall {A B} : forall (P : A -> B -> Prop) l,
  (exists k, Forall (P k) l) -> Forall (fun x => exists k, P k x) l .
Proof with try eassumption ; try reflexivity.
induction l ; intros ; constructor ;
  destruct H as [k H] ; inversion H ; subst.
- eexists...
- apply IHl...
  eexists...
Qed.

Lemma Forall_map {A B} : forall (f : A -> B) l,
  Forall (fun x => exists y, x = f y) l <-> exists l0, l = map f l0.
Proof with try reflexivity.
induction l ; split ; intro H.
- exists (@nil A)...
- constructor.
- inversion H ; subst.
  destruct H2 as [y Hy] ; subst.
  apply IHl in H3.
  destruct H3 as [l0 Hl0] ; subst.
  exists (y :: l0)...
- destruct H as [l0 Heq].
  destruct l0 ; inversion Heq ; subst.
  constructor.
  + exists a0...
  + apply IHl.
    exists l0...
Qed.

Lemma Forall_rev {A} : forall P (l : list A), Forall P l -> Forall P (rev l).
Proof with try assumption.
induction l ; intros HP.
- constructor.
- inversion HP ; subst.
  apply IHl in H2.
  apply Forall_app...
  constructor...
  constructor.
Qed.

Lemma inc_Forall {A} : forall (P : nat -> A -> Prop) l i j,
  (forall i j a, P i a -> i <= j -> P j a) ->
    Forall (P i) l -> i <= j -> Forall (P j) l.
Proof with try eassumption.
intros P l i j Hinc.
induction l ; intros H Hl ; constructor ; inversion H.
- eapply Hinc...
- apply IHl...
Qed.

Lemma Exists_app_inv {A} : forall (P : A -> Prop) l1 l2,
  Exists P (l1 ++ l2) -> Exists P l1 \/ Exists P l2.
Proof with try assumption.
induction l1 ; intros.
- right...
- inversion H ; subst.
  + left.
    apply Exists_cons_hd...
  + apply IHl1 in H1.
    destruct H1.
    * left.
      apply Exists_cons_tl...
    * right...
Qed.

Lemma Exists_app {A} : forall (P : A -> Prop) l1 l2,
  (Exists P l1 \/ Exists P l2) -> Exists P (l1 ++ l2).
Proof with try assumption.
induction l1 ; intros...
- destruct H...
  inversion H.
- destruct H.
  + inversion H ; subst.
    * apply Exists_cons_hd...
    * apply Exists_cons_tl.
      apply IHl1.
      left...
  + apply Exists_cons_tl.
    apply IHl1.
    right...
Qed.

Lemma Exists_rev {A} : forall P (l : list A), Exists P l -> Exists P (rev l).
Proof with try assumption.
induction l ; intros HP ; inversion HP ; subst ;
  apply Exists_app.
- right ; constructor...
- left.
  apply IHl...
Qed.


(** ** Map for functions with two arguments : [map2] *)

Fixpoint map2 {A B C} (f : A -> B -> C) l1 l2 :=
  match l1 , l2 with
  | nil , _ => nil
  | _ , nil => nil
  | a1::r1 , a2::r2 => (f a1 a2)::(map2 f r1 r2)
  end.

Lemma map2_length {A B C} : forall (f : A -> B -> C) l1 l2,
  length l1 = length l2 -> length (map2 f l1 l2) = length l2.
Proof with try assumption ; try reflexivity.
induction l1 ; intros...
destruct l2.
+ inversion H.
+ simpl in H.
  injection H ; intro H'.
  apply IHl1 in H'.
  simpl...
  rewrite H'...
Qed.

Lemma length_map2 {A B C} : forall (f : A -> B -> C) l1 l2,
  length (map2 f l1 l2) <= length l1 /\ length (map2 f l1 l2) <= length l2.
Proof.
induction l1 ; intros.
- split ; apply le_0_n.
- destruct l2.
  + split ; apply le_0_n.
  + destruct (IHl1 l2) as [H1 H2].
    split ; simpl ; apply le_n_S ; assumption.
Qed.

Lemma nth_map2 {A B C} : forall (f : A -> B -> C) l1 l2 i a b c,
  i < length (map2 f l1 l2) ->
    nth i (map2 f l1 l2) c = f (nth i l1 a) (nth i l2 b).
Proof with try assumption ; try reflexivity.
induction l1 ; intros.
- inversion H.
- destruct l2.
  + inversion H.
  + destruct i...
    simpl.
    apply IHl1.
    simpl in H.
    apply lt_S_n...
Qed.



