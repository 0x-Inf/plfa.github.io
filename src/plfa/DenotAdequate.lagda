---
title     : "DenotAdequacy: Adequacy of denotational semantics with respect to operational semantics"
layout    : page
prev      : /DenotSound/
permalink : /DenotAdequate/
next      : /Acknowledgements/
---

\begin{code}
module plfa.DenotAdequate where
\end{code}

## Imports

\begin{code}
open import plfa.Untyped
open import plfa.Denot

open import Relation.Binary.PropositionalEquality
  using (_≡_; _≢_; refl; sym; trans; cong; cong₂; cong-app)
open import Data.Product using (_×_; Σ; Σ-syntax; ∃; ∃-syntax; proj₁; proj₂)
  renaming (_,_ to ⟨_,_⟩)
open import Data.Sum
open import Relation.Nullary using (¬_)
open import Relation.Nullary.Negation using (contradiction)
open import Data.Empty using (⊥-elim) renaming (⊥ to Bot)
open import Data.Unit
open import Relation.Nullary using (Dec; yes; no)
\end{code}


In this chapter we prove that the denotational semantics is adequate,
that is, if a term M is denotationally equal to another term in normal
form, then M reduces to normal form. For the lambda calculus there are
may choices of normal forms: normal form, head normal form, and weak
head normal form. We shall focus on reduction to weak-head normal form
(WHNF), that is, to lambda abstraction.  It is well known that if a
term can reduce to WHNF using full β reduction, then it can also
reduce to WHNF using the call-by-name reduction strategy.  So in this
chapter we shallow narrow our focus to call-by-name.

Recall that we have defined denotational equality by means of the
semantic judgement γ ⊢ M ↓ v. Suppose M is denotationally equal to
some lambda abstraction, that is, ℰ M ≃ ℰ (ƛ N).  For any γ, we have γ
⊢ ƛ N ↓ ⊥ ↦ ⊥, so then we must also have γ ⊢ M ↓ (⊥ ↦ ⊥). We will show
that γ ⊢ M ↓ (⊥ ↦ ⊥) implies that M reduces to WHNF.  In other words,
whenever the semantic judgement says M results in a function, then M
is a terminating program, i.e., it reduces to a lambda via
call-by-name.

The proof will relate the semantic judgment γ ⊢ M ↓ v to a
call-by-name big-step semantics, written γ' ⊢ M ⇓ c, where c is a
closure (a term paired with an environment) and γ' is an environment
that maps variables to closures. The proof will be an induction on the
derivation of γ ⊢ M ↓ v, and to strengthen the induction hypothesis,
we will relate semantic values to closures using a _logical relation_
𝕍.

The rest of this chapter is organized as follows.

* We loosen the requirement that M result in a function value to
  instead require that M result in a value that is greater than or
  equal to a function value. We establish several properties about
  being ``greater than a function''.

* We define the call-by-name big-step semantics of the lambda calculus
  and prove that it is deterministic.

* We define the logical relation 𝕍 that relates values and closures,
  and extend it to a relation on terms 𝔼 and environments 𝔾.

* We prove the main lemma,
  that if 𝔾 γ γ' and γ ⊢ M ↓ v, then 𝔼 v (clos M γ').

* We prove adequacy as a corollary to the main lemma.


## The property of being greater or equal to a function

We define the following short-hand for saying that a value is
greather-than or equal to a function value.

\begin{code}
AboveFun : Value → Set
AboveFun v = Σ[ v₁ ∈ Value ] Σ[ v₂ ∈ Value ] v₁ ↦ v₂ ⊑ v
\end{code}

If a value v is greater than a function, then an even greater value v'
is too.

\begin{code}
AboveFun-⊑ : ∀{v v' : Value}
      → AboveFun v → v ⊑ v'
        -------------------
      → AboveFun v'
AboveFun-⊑ ⟨ v₁ , ⟨ v₂ , lt' ⟩ ⟩ lt = ⟨ v₁ , ⟨ v₂ , Trans⊑ lt' lt ⟩ ⟩
\end{code}

The bottom value ⊥ is not greater than a function.

\begin{code}
AboveFun⊥ : ¬ AboveFun ⊥
AboveFun⊥ ⟨ v₁ , ⟨ v₂ , lt ⟩ ⟩
    with sub-inv-fun lt
... | ⟨ Γ , ⟨ f , ⟨ Γ⊆⊥ , ⟨ lt1 , lt2 ⟩ ⟩ ⟩ ⟩
    with Funs∈ f
... | ⟨ A , ⟨ B , m ⟩ ⟩
    with Γ⊆⊥ m
... | ()
\end{code}

If the join of two values v₁ and v₂ is greater than a function, then
at least one of them is too.

\begin{code}
AboveFun-⊔ : ∀{v₁ v₂}
           → AboveFun (v₁ ⊔ v₂)
           → AboveFun v₁ ⊎ AboveFun v₂
AboveFun-⊔{v₁}{v₂} ⟨ v , ⟨ v' , v↦v'⊑v₁⊔v₂ ⟩ ⟩ 
    with sub-inv-fun v↦v'⊑v₁⊔v₂
... | ⟨ Γ , ⟨ f , ⟨ Γ⊆v₁⊔v₂ , ⟨ lt1 , lt2 ⟩ ⟩ ⟩ ⟩
    with Funs∈ f
... | ⟨ A , ⟨ B , m ⟩ ⟩
    with Γ⊆v₁⊔v₂ m
... | inj₁ x = inj₁ ⟨ A , ⟨ B , (∈→⊑ x) ⟩ ⟩
... | inj₂ x = inj₂ ⟨ A , ⟨ B , (∈→⊑ x) ⟩ ⟩
\end{code}

On the other hand, if neither of v₁ and v₂ is greater than a function,
then their join is also not greater than a function.

\begin{code}
not-AboveFun-⊔ : ∀{v₁ v₂ : Value}
               → ¬ AboveFun v₁ → ¬ AboveFun v₂
               → ¬ AboveFun (v₁ ⊔ v₂)
not-AboveFun-⊔ af1 af2 af12
    with AboveFun-⊔ af12
... | inj₁ x = contradiction x af1
... | inj₂ x = contradiction x af2
\end{code}

The converse is also true. If the join of two values is not above a
function, then neither of them is individually.

\begin{code}
not-AboveFun-⊔-inv : ∀{v₁ v₂ : Value} → ¬ AboveFun (v₁ ⊔ v₂)
              → ¬ AboveFun v₁ × ¬ AboveFun v₂
not-AboveFun-⊔-inv af = ⟨ f af , g af ⟩
  where
    f : ∀{v₁ v₂ : Value} → ¬ AboveFun (v₁ ⊔ v₂) → ¬ AboveFun v₁
    f{v₁}{v₂} af12 ⟨ v , ⟨ v' , lt ⟩ ⟩ =
        contradiction ⟨ v , ⟨ v' , ConjR1⊑ lt ⟩ ⟩ af12
    g : ∀{v₁ v₂ : Value} → ¬ AboveFun (v₁ ⊔ v₂) → ¬ AboveFun v₂
    g{v₁}{v₂} af12 ⟨ v , ⟨ v' , lt ⟩ ⟩ =
        contradiction ⟨ v , ⟨ v' , ConjR2⊑ lt ⟩ ⟩ af12
\end{code}

The property of being greater than a function value is decidable, as
exhibited by the following function.

\begin{code}
AboveFun? : (v : Value) → Dec (AboveFun v)
AboveFun? ⊥ = no AboveFun⊥
AboveFun? (v ↦ v') = yes ⟨ v , ⟨ v' , Refl⊑ ⟩ ⟩
AboveFun? (v₁ ⊔ v₂)
    with AboveFun? v₁ | AboveFun? v₂
... | yes ⟨ v , ⟨ v' , lt ⟩ ⟩ | _ = yes ⟨ v , ⟨ v' , (ConjR1⊑ lt) ⟩ ⟩
... | no _ | yes ⟨ v , ⟨ v' , lt ⟩ ⟩ = yes ⟨ v , ⟨ v' , (ConjR2⊑ lt) ⟩ ⟩
... | no x | no y = no (not-AboveFun-⊔ x y)
\end{code}


## Big-step semantics for call-by-name lambda calculus

To better align with the denotational semantics, we shall use an
environment-passing big-step semantics. Because this is call-by-name,
an environment maps each variable to a closure, that is, to a term
paired with its environment. (Environments and closures are mutually
recursive.) We define environments and closures as follows.

\begin{code}
ClosEnv : Context → Set

data Clos : Set where
  clos : ∀{Γ} → (M : Γ ⊢ ★) → ClosEnv Γ → Clos

ClosEnv Γ = ∀ (x : Γ ∋ ★) → Clos
\end{code}

As usual, we have the empty environment, and we can extend an
environment.
\begin{code}
∅' : ClosEnv ∅
∅' ()

_,'_ : ∀ {Γ} → ClosEnv Γ → Clos → ClosEnv (Γ , ★)
(γ ,' c) Z = c
(γ ,' c) (S x) = γ x
\end{code}

The following is the big-step semantics for call-by-name evaluation,
which we describe below.

\begin{code}
data _⊢_⇓_ : ∀{Γ} → ClosEnv Γ → (Γ ⊢ ★) → Clos → Set where

  ⇓-var : ∀{Γ}{γ : ClosEnv Γ}{x : Γ ∋ ★}{Δ}{δ : ClosEnv Δ}{M : Δ ⊢ ★}{c}
        → γ x ≡ clos M δ
        → δ ⊢ M ⇓ c
          -----------
        → γ ⊢ ` x ⇓ c

  ⇓-lam : ∀{Γ}{γ : ClosEnv Γ}{M : Γ , ★ ⊢ ★}
        → γ ⊢ ƛ M ⇓ clos (ƛ M) γ

  ⇓-app : ∀{Γ}{γ : ClosEnv Γ}{L M : Γ ⊢ ★}{Δ}{δ : ClosEnv Δ}{L' : Δ , ★ ⊢ ★}{c}
       → γ ⊢ L ⇓ clos (ƛ L') δ   →   (δ ,' clos M γ) ⊢ L' ⇓ c
         ----------------------------------------------------
       → γ ⊢ L · M ⇓ c
\end{code}

* The (⇓-var) rule evaluates a variable by finding the associated
  closure in the environment and then evaluating the closure.

* The (⇓-lam) rule turns a lambda abstraction into a closure
  by packaging it up with its environment.

* The (⇓-app) rule performs function application by first evaluating
  the term L in operator position. If that produces a closure containing
  a lambda abstraction (ƛ L'), then we evaluate the body L' in an
  environment extended with the argument M. Note that M is not
  evaluated in rule (⇓-app) because this is call-by-name and not
  call-by-value.

If the big-step semantics says that a term M evaluates to both c and
c', then c and c' are identical. In other words, the big-step relation
is a partial function.

\begin{code}
⇓-determ : ∀{Γ}{γ : ClosEnv Γ}{M : Γ ⊢ ★}{c c' : Clos}
         → γ ⊢ M ⇓ c → γ ⊢ M ⇓ c'
         → c ≡ c'
⇓-determ (⇓-var eq1 mc) (⇓-var eq2 mc')
      with trans (sym eq1) eq2
... | refl = ⇓-determ mc mc'
⇓-determ ⇓-lam ⇓-lam = refl
⇓-determ (⇓-app mc mc₁) (⇓-app mc' mc'') 
    with ⇓-determ mc mc'
... | refl = ⇓-determ mc₁ mc''
\end{code}


## Relating values to closures

Next we relate semantic values to closures.  The relation 𝕍 is for
closures whose term is a lambda abstraction (i.e. in WHNF), whereas
the relation 𝔼 is for any closure. Roughly speaking, 𝔼 v c will hold
if, when v is greater than a function value, c evaluates to a closure
c' in WHNF and 𝕍 v c'. Regarding 𝕍 v c, it will hold when c is in
WHNF, and if v is a function, the body of c evaluates according to v.

\begin{code}
𝕍 : Value → Clos → Set
𝔼 : Value → Clos → Set
\end{code}

We define 𝕍 as a function from values and closures to Set and not as a
data type because it is mutually recursive with 𝔼 in a negative
position (to the left of an implication).  We first perform case
analysis on the term in the closure. If the term is a variable or
application, then 𝕍 is false (Bot). If the term is a lambda
abstraction, we define 𝕍 by recursion on the value, which we
describe below.

\begin{code}
𝕍 v (clos (` x₁) γ) = Bot
𝕍 v (clos (M · M₁) γ) = Bot
𝕍 ⊥ (clos (ƛ M) γ) = ⊤
𝕍 (v ↦ v') (clos (ƛ M) γ) =
    (∀{c : Clos} → 𝔼 v c → AboveFun v' → Σ[ c' ∈ Clos ]
        (γ ,' c) ⊢ M ⇓ c'  ×  𝕍 v' c')
𝕍 (v₁ ⊔ v₂) (clos (ƛ M) γ) = 𝕍 v₁ (clos (ƛ M) γ) × 𝕍 v₂ (clos (ƛ M) γ)
\end{code}

* If the value is ⊥, then the result is true (⊤).

* If the value is a join (v₁ ⊔ v₂), then the result is the pair
  (conjunction) of 𝕍 is true for both v₁ and v₂.

* The important case is for a function value (v ↦ v') and closure
  (clos (ƛ M) γ). Given any closure c such that 𝔼 v c, if v' is
  greater than a function, then M evaluates (with γ extended with c)
  to some closure c' and we have 𝕍 v' c'.


The definition of 𝔼 is straightforward. If v is a greater than a
function, then M evaluates to a closure related to v.

\begin{code}
𝔼 v (clos M γ') = AboveFun v → Σ[ c ∈ Clos ] γ' ⊢ M ⇓ c × 𝕍 v c
\end{code}

The proof of the main lemma is by induction on γ ⊢ M ↓ v, so it goes
underneath lambda abstractions and must therefore reason about open
terms (terms with variables). Thus, we also need to relate
environments of semantic values to environments of closures.
In the following, 𝔾 relates γ to γ' if the corresponding
values and closures are related by 𝔼.

\begin{code}
𝔾 : ∀{Γ} → Env Γ → ClosEnv Γ → Set
𝔾 {Γ} γ γ' = ∀{x : Γ ∋ ★} → 𝔼 (γ x) (γ' x)

𝔾-∅ : 𝔾 `∅ ∅'
𝔾-∅ {()}

𝔾-ext : ∀{Γ}{γ : Env Γ}{γ' : ClosEnv Γ}{v c}
      → 𝔾 γ γ' → 𝔼 v c → 𝔾 (γ `, v) (γ' ,' c)
𝔾-ext {Γ} {γ} {γ'} g e {Z} = e
𝔾-ext {Γ} {γ} {γ'} g e {S x} = g
\end{code}


We shall need a few properties of the 𝕍 and 𝔼 relations.  The first is
that a closure in the 𝕍 relation must be in weak-head normal form.  We
define WHNF has follows.

\begin{code}
data WHNF : ∀ {Γ A} → Γ ⊢ A → Set where
  ƛ_ : ∀ {Γ} {N : Γ , ★ ⊢ ★}
     → WHNF (ƛ N)
\end{code}

The proof goes by cases on the term in the closure.

\begin{code}
𝕍→WHNF : ∀{Γ}{γ : ClosEnv Γ}{M : Γ ⊢ ★}{v}
       → 𝕍 v (clos M γ) → WHNF M
𝕍→WHNF {M = ` x} {v} ()
𝕍→WHNF {M = ƛ M} {v} vc = ƛ_
𝕍→WHNF {M = M · M₁} {v} ()
\end{code}

Next we have an introduction rule for 𝕍 that mimics the (⊔-intro)
rule. If both v₁ and v₂ are related to a closure c, then their join is
too.

\begin{code}
𝕍⊔-intro : ∀{c v₁ v₂}
         → 𝕍 v₁ c → 𝕍 v₂ c
           ---------------
         → 𝕍 (v₁ ⊔ v₂) c
𝕍⊔-intro {clos (` x₁) x} () v2c
𝕍⊔-intro {clos (ƛ M) x} v1c v2c = ⟨ v1c , v2c ⟩
𝕍⊔-intro {clos (M · M₁) x} () v2c
\end{code}

\begin{code}
not-AboveFun-𝕍 : ∀{v : Value}{Γ}{γ' : ClosEnv Γ}{M : Γ , ★ ⊢ ★ }
               → ¬ AboveFun v
                 -------------------
               → 𝕍 v (clos (ƛ M) γ')
not-AboveFun-𝕍 {⊥} af = tt
not-AboveFun-𝕍 {v ↦ v'} af = ⊥-elim (contradiction ⟨ v , ⟨ v' , Refl⊑ ⟩ ⟩ af)
not-AboveFun-𝕍 {v₁ ⊔ v₂} af
    with not-AboveFun-⊔-inv af
... | ⟨ af1 , af2 ⟩ =
    ⟨ not-AboveFun-𝕍 af1 , not-AboveFun-𝕍 af2 ⟩
\end{code}


\begin{code}
sub-𝕍 : ∀{c : Clos}{v v'} → 𝕍 v c → v' ⊑ v → 𝕍 v' c
sub-𝔼 : ∀{c : Clos}{v v'} → 𝔼 v c → v' ⊑ v → 𝔼 v' c
\end{code}

\begin{code}
sub-𝕍 {clos (` x) γ} {v} () lt
sub-𝕍 {clos (M₁ · M₂) γ} () lt
sub-𝕍 {clos (ƛ M) γ} vc Bot⊑ = tt
sub-𝕍 {clos (ƛ M) γ} vc (ConjL⊑ lt1 lt2) = ⟨ (sub-𝕍 vc lt1) , sub-𝕍 vc lt2 ⟩
sub-𝕍 {clos (ƛ M) γ} ⟨ vv1 , vv2 ⟩ (ConjR1⊑ lt) = sub-𝕍 vv1 lt
sub-𝕍 {clos (ƛ M) γ} ⟨ vv1 , vv2 ⟩ (ConjR2⊑ lt) = sub-𝕍 vv2 lt
sub-𝕍 {clos (ƛ M) γ} vc (Trans⊑{v₂ = v₂} lt1 lt2) = sub-𝕍 (sub-𝕍 vc lt2) lt1
sub-𝕍 {clos (ƛ M) γ} vc (Fun⊑ lt1 lt2) ev1 sf
    with vc (sub-𝔼 ev1 lt1) (AboveFun-⊑ sf lt2)
... | ⟨ c , ⟨ Mc , v4 ⟩ ⟩ = ⟨ c , ⟨ Mc , sub-𝕍 v4 lt2 ⟩ ⟩
sub-𝕍 {clos (ƛ M) γ} {v₁ ↦ v₂ ⊔ v₁ ↦ v₃} ⟨ vc12 , vc13 ⟩ Dist⊑ ev1c sf
    with AboveFun? v₂ | AboveFun? v₃
... | yes af2 | no naf3
    with vc12 ev1c af2
... | ⟨ clos {Γ'} N γ₁ , ⟨ M⇓c2 , 𝕍2c ⟩ ⟩
    with 𝕍→WHNF 𝕍2c
... | ƛ_ {N = N'} =
      let 𝕍3c = not-AboveFun-𝕍{v₃}{Γ'}{γ₁}{N'} naf3 in
      ⟨ clos (ƛ N') γ₁ , ⟨ M⇓c2 , 𝕍⊔-intro 𝕍2c 𝕍3c ⟩ ⟩
sub-𝕍 {c} {v₁ ↦ v₂ ⊔ v₁ ↦ v₃} ⟨ vc12 , vc13 ⟩ Dist⊑ ev1c sf
    | no naf2 | yes af3
    with vc13 ev1c af3
... | ⟨ clos {Γ'} N γ₁ , ⟨ M⇓c3 , 𝕍3c ⟩ ⟩ 
    with 𝕍→WHNF 𝕍3c
... | ƛ_ {N = N'} =
      let 𝕍2c = not-AboveFun-𝕍{v₂}{Γ'}{γ₁}{N'} naf2 in
      ⟨ clos (ƛ N') γ₁ , ⟨ M⇓c3 , 𝕍⊔-intro 𝕍2c 𝕍3c ⟩ ⟩
sub-𝕍 {c} {v₁ ↦ v₂ ⊔ v₁ ↦ v₃} ⟨ vc12 , vc13 ⟩  Dist⊑ ev1c ⟨ v , ⟨ v' , lt ⟩ ⟩
    | no naf2 | no naf3
    with AboveFun-⊔ ⟨ v , ⟨ v' , lt ⟩ ⟩
... | inj₁ af2 = ⊥-elim (contradiction af2 naf2)
... | inj₂ af3 = ⊥-elim (contradiction af3 naf3)
sub-𝕍 {c} {v₁ ↦ v₂ ⊔ v₁ ↦ v₃} ⟨ vc12 , vc13 ⟩  Dist⊑ ev1c sf
    | yes af2 | yes af3
    with vc12 ev1c af2 | vc13 ev1c af3
... | ⟨ clos N δ , ⟨ Mc1 , v4 ⟩ ⟩
    | ⟨ c2 , ⟨ Mc2 , v5 ⟩ ⟩ rewrite ⇓-determ Mc2 Mc1 with 𝕍→WHNF v4
... | ƛ_ =
      ⟨ clos N δ , ⟨ Mc1 , ⟨ v4 , v5 ⟩ ⟩ ⟩
\end{code}

\begin{code}
sub-𝔼 {clos M x} {v} {v'} evc lt fv
    with evc (AboveFun-⊑ fv lt)
... | ⟨ c , ⟨ Mc , vvc ⟩ ⟩ =
      ⟨ c , ⟨ Mc , sub-𝕍 vvc lt ⟩ ⟩
\end{code}

\begin{code}
kth-x : ∀{Γ}{γ' : ClosEnv Γ}{x : Γ ∋ ★}
     → Σ[ Δ ∈ Context ] Σ[ δ ∈ ClosEnv Δ ] Σ[ M ∈ Δ ⊢ ★ ]
                 γ' x ≡ clos M δ
kth-x{γ' = γ'}{x = x} with γ' x
... | clos{Γ = Δ} M δ = ⟨ Δ , ⟨ δ , ⟨ M , refl ⟩ ⟩ ⟩
\end{code}


## Programs with function denotation terminate via call-by-name


\begin{code}
↓→𝔼 : ∀{Γ}{γ : Env Γ}{γ' : ClosEnv Γ}{M : Γ ⊢ ★ }{v}
            → 𝔾 γ γ' → γ ⊢ M ↓ v → 𝔼 v (clos M γ')
↓→𝔼 {Γ} {γ} {γ'} {`_ x} {v} g var sf 
    with kth-x{Γ}{γ'}{x} | g{x = x}
... | ⟨ Δ , ⟨ δ , ⟨ M , eq ⟩ ⟩ ⟩ | g' rewrite eq
    with g' sf
... | ⟨ c , ⟨ L⇓c , Vnc ⟩ ⟩ =
      ⟨ c , ⟨ (⇓-var eq L⇓c) , Vnc ⟩ ⟩
↓→𝔼 {Γ} {γ} {γ'} {L · M} {v} g (↦-elim{v₁ = v₁} d₁ d₂) sf
    with ↓→𝔼 g d₁ ⟨ v₁ , ⟨ v , Refl⊑ ⟩ ⟩
... | ⟨ clos (` x) δ , ⟨ L⇓c , () ⟩ ⟩
... | ⟨ clos (L' · M') δ , ⟨ L⇓c , () ⟩ ⟩ 
... | ⟨ clos (ƛ L') δ , ⟨ L⇓c , Vc ⟩ ⟩
    with Vc {clos M γ'} (↓→𝔼 g d₂) sf
... | ⟨ c' , ⟨ L'⇓c' , Vc' ⟩ ⟩ =
    ⟨ c' , ⟨ ⇓-app L⇓c L'⇓c' , Vc' ⟩ ⟩
↓→𝔼 {Γ} {γ} {γ'} {ƛ M} {v ↦ v'} g (↦-intro d) sf =
  ⟨ (clos (ƛ M) γ') , ⟨ ⇓-lam , G ⟩ ⟩
  where G : {c : Clos} → 𝔼 v c → AboveFun v'
          → Σ-syntax Clos (λ c' → ((γ' ,' c) ⊢ M ⇓ c') × 𝕍 v' c')
        G {c} evc sfv' = ↓→𝔼 (λ {x} → 𝔾-ext{Γ}{γ}{γ'} g evc {x}) d sfv'
↓→𝔼 {Γ} {γ} {γ'} {M} {⊥} g ⊥-intro sf = ⊥-elim (AboveFun⊥ sf)
↓→𝔼 {Γ} {γ} {γ'} {M} {v₁ ⊔ v₂} g (⊔-intro d₁ d₂) af12
    with AboveFun? v₁ | AboveFun? v₂
↓→𝔼 g (⊔-intro{v₁ = v₁}{v₂ = v₂} d₁ d₂) af12 | yes af1 | no naf2
    with ↓→𝔼 g d₁ af1 
... | ⟨ clos {Γ'} M' γ₁ , ⟨ M⇓c1 , 𝕍1c ⟩ ⟩
    with 𝕍→WHNF 𝕍1c
... | ƛ_ {N = M} =
    let 𝕍2c = not-AboveFun-𝕍{v₂}{Γ'}{γ₁}{M} naf2 in
    ⟨ clos (ƛ M) γ₁ , ⟨ M⇓c1 , 𝕍⊔-intro 𝕍1c 𝕍2c ⟩ ⟩
↓→𝔼 g (⊔-intro{v₁ = v₁}{v₂ = v₂} d₁ d₂) af12 | no naf1  | yes af2
    with ↓→𝔼 g d₂ af2
... | ⟨ clos {Γ'} M' γ₁ , ⟨ M⇓c2 , 𝕍2c ⟩ ⟩
    with 𝕍→WHNF 𝕍2c
... | ƛ_ {N = M} =
    let 𝕍1c = not-AboveFun-𝕍{v₁}{Γ'}{γ₁}{M} naf1 in
    ⟨ clos (ƛ M) γ₁ , ⟨ M⇓c2 , 𝕍⊔-intro 𝕍1c 𝕍2c ⟩ ⟩
↓→𝔼 g (⊔-intro d₁ d₂) af12 | no naf1  | no naf2
    with AboveFun-⊔ af12
... | inj₁ af1 = ⊥-elim (contradiction af1 naf1)
... | inj₂ af2 = ⊥-elim (contradiction af2 naf2)
↓→𝔼 g (⊔-intro d₁ d₂) af12 | yes af1 | yes af2
    with ↓→𝔼 g d₁ af1 | ↓→𝔼 g d₂ af2 
... | ⟨ c1 , ⟨ M⇓c1 , 𝕍1c ⟩ ⟩ | ⟨ c2 , ⟨ M⇓c2 , 𝕍2c ⟩ ⟩
    rewrite ⇓-determ M⇓c2 M⇓c1 =
      ⟨ c1 , ⟨ M⇓c1 , 𝕍⊔-intro 𝕍1c 𝕍2c ⟩ ⟩
↓→𝔼 {Γ} {γ} {γ'} {M} {v} g (sub d lt) sf 
    with ↓→𝔼 {Γ} {γ} {γ'} {M} g d (AboveFun-⊑ sf lt)
... | ⟨ c , ⟨ M⇓c , 𝕍c ⟩ ⟩ =
      ⟨ c , ⟨ M⇓c , sub-𝕍 𝕍c lt ⟩ ⟩
\end{code}


## Proof of denotational adequacy


\begin{code}
adequacy : ∀{M : ∅ ⊢ ★}{N : ∅ , ★ ⊢ ★}  →  ℰ M ≃ ℰ (ƛ N)
         →  Σ[ c ∈ Clos ] ∅' ⊢ M ⇓ c
adequacy{M}{N} eq 
    with ↓→𝔼 𝔾-∅ ((proj₂ eq) (↦-intro ⊥-intro)) ⟨ ⊥ , ⟨ ⊥ , Refl⊑ ⟩ ⟩
... | ⟨ c , ⟨ M⇓c , Vc ⟩ ⟩ = ⟨ c , M⇓c ⟩
\end{code}
