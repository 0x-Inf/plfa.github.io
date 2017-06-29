---
title     : "Stlc: The Simply Typed Lambda-Calculus"
layout    : page
permalink : /Stlc
---

This chapter defines the simply-typed lambda calculus.

## Imports
\begin{code}
open import Maps using (Id; id; _≟_; PartialMap; module PartialMap)
open PartialMap using (∅) renaming (_,_↦_ to _,_∶_)
open import Data.String using (String)
open import Data.Maybe using (Maybe; just; nothing)
open import Relation.Nullary using (Dec; yes; no)
open import Relation.Binary.PropositionalEquality using (_≡_; _≢_; refl)
\end{code}


## Syntax

Syntax of types and terms.

\begin{code}
infixr 20 _⇒_

data Type : Set where
  𝔹 : Type
  _⇒_ : Type → Type → Type

infixl 20 _·_
infix  15 λ[_∶_]_
infix  15 if_then_else_

data Term : Set where
  var : Id → Term
  λ[_∶_]_ : Id → Type → Term → Term
  _·_ : Term → Term → Term
  true : Term
  false : Term
  if_then_else_ : Term → Term → Term → Term
\end{code}

Example terms.
\begin{code}
f x : Id
f  =  id "f"
x  =  id "x"

not two : Term 
not =  λ[ x ∶ 𝔹 ] (if var x then false else true)
two =  λ[ f ∶ 𝔹 ⇒ 𝔹 ] λ[ x ∶ 𝔹 ] var f · (var f · var x)
\end{code}

## Values

\begin{code}
data Value : Term → Set where
  value-λ     : ∀ {x A N} → Value (λ[ x ∶ A ] N)
  value-true  : Value true
  value-false : Value false
\end{code}

## Substitution

\begin{code}
_[_∶=_] : Term → Id → Term → Term
(var x′) [ x ∶= V ] with x ≟ x′
... | yes _ = V
... | no  _ = var x′
(λ[ x′ ∶ A′ ] N′) [ x ∶= V ] with x ≟ x′
... | yes _ = λ[ x′ ∶ A′ ] N′
... | no  _ = λ[ x′ ∶ A′ ] (N′ [ x ∶= V ])
(L′ · M′) [ x ∶= V ] =  (L′ [ x ∶= V ]) · (M′ [ x ∶= V ])
(true) [ x ∶= V ] = true
(false) [ x ∶= V ] = false
(if L′ then M′ else N′) [ x ∶= V ] = if (L′ [ x ∶= V ]) then (M′ [ x ∶= V ]) else (N′ [ x ∶= V ])
\end{code}

## Reduction rules

\begin{code}
infix 10 _⟹_ 

data _⟹_ : Term → Term → Set where
  β⇒ : ∀ {x A N V} → Value V →
    (λ[ x ∶ A ] N) · V ⟹ N [ x ∶= V ]
  γ⇒₀ : ∀ {L L' M} →
    L ⟹ L' →
    L · M ⟹ L' · M
  γ⇒₁ : ∀ {V M M'} →
    Value V →
    M ⟹ M' →
    V · M ⟹ V · M'
  β𝔹₀ : ∀ {M N} →
    if true then M else N ⟹ M
  β𝔹₁ : ∀ {M N} →
    if false then M else N ⟹ N
  γ𝔹 : ∀ {L L' M N} →
    L ⟹ L' →    
    if L then M else N ⟹ if L' then M else N
\end{code}

## Reflexive and transitive closure

\begin{code}
Rel : Set → Set₁
Rel A = A → A → Set

infixl 10 _>>_

data _* {A : Set} (R : Rel A) : Rel A where
  ⟨⟩ : ∀ {x : A} → (R *) x x
  ⟨_⟩ : ∀ {x y : A} → R x y → (R *) x y
  _>>_ : ∀ {x y z : A} → (R *) x y → (R *) y z → (R *) x z

infix 10 _⟹*_

_⟹*_ : Rel Term
_⟹*_ = (_⟹_) *
\end{code}

## Notation for setting out reductions

\begin{code}
infixr 2 _⟹⟨_⟩_
infix  3 _∎

_⟹⟨_⟩_ : ∀ L {M N} → L ⟹ M → M ⟹* N → L ⟹* N
L ⟹⟨ L⟹M ⟩ M⟹*N  =  ⟨ L⟹M ⟩ >> M⟹*N

_∎ : ∀ M → M ⟹* M
M ∎  =  ⟨⟩
\end{code}

## Example reductions

\begin{code}
example₀ : not · true ⟹* false
example₀ =
    not · true
  ⟹⟨ β⇒ value-true ⟩
    if true then false else true
  ⟹⟨ β𝔹₀ ⟩
    false
  ∎

example₁ : two · not · true ⟹* true
example₁ =
    two · not · true
  ⟹⟨ γ⇒₀ (β⇒ value-λ) ⟩
    (λ[ x ∶ 𝔹 ] not · (not · var x)) · true
  ⟹⟨ β⇒ value-true ⟩
    not · (not · true)
  ⟹⟨ γ⇒₁ value-λ (β⇒ value-true) ⟩
    not · (if true then false else true)
  ⟹⟨ γ⇒₁ value-λ β𝔹₀ ⟩
    not · false
  ⟹⟨ β⇒ value-false ⟩
    if false then false else true
  ⟹⟨ β𝔹₁ ⟩
    true
  ∎
\end{code}

## Type rules

\begin{code}
Context : Set
Context = PartialMap Type

infix 10 _⊢_∶_

data _⊢_∶_ : Context → Term → Type → Set where
  Ax : ∀ {Γ x A} →
    Γ x ≡ just A →
    Γ ⊢ var x ∶ A
  ⇒-I : ∀ {Γ x N A B} →
    Γ , x ∶ A ⊢ N ∶ B →
    Γ ⊢ λ[ x ∶ A ] N ∶ A ⇒ B
  ⇒-E : ∀ {Γ L M A B} →
    Γ ⊢ L ∶ A ⇒ B →
    Γ ⊢ M ∶ A →
    Γ ⊢ L · M ∶ B
  𝔹-I₀ : ∀ {Γ} →
    Γ ⊢ true ∶ 𝔹
  𝔹-I₁ : ∀ {Γ} →
    Γ ⊢ false ∶ 𝔹
  𝔹-E : ∀ {Γ L M N A} →
    Γ ⊢ L ∶ 𝔹 →
    Γ ⊢ M ∶ A →
    Γ ⊢ N ∶ A →
    Γ ⊢ if L then M else N ∶ A    
\end{code}

## Example type derivations

\begin{code}
example₂ : ∅ ⊢ not ∶ 𝔹 ⇒ 𝔹
example₂ = ⇒-I (𝔹-E (Ax refl) 𝔹-I₁ 𝔹-I₀)

example₃ : ∅ ⊢ two ∶ (𝔹 ⇒ 𝔹) ⇒ 𝔹 ⇒ 𝔹
example₃ = ⇒-I (⇒-I (⇒-E (Ax refl) (⇒-E (Ax refl) (Ax refl))))
\end{code}

Construction of a type derivation is best done interactively.
We start with the declaration:

  `example₂ : ∅ ⊢ not ∶ 𝔹 ⇒ 𝔹`
  `example₂ = ?`

Typing control-L causes Agda to create a hole and tell us its expected type.

  `example₂ = { }0`
  `?0 : ∅ ⊢ not ∶ 𝔹 ⇒ 𝔹`

Now we fill in the hole, observing that the outermost term in `not` in a `λ`,
which is typed using `⇒-I`. The `⇒-I` rule in turn takes one argument, which
we again specify with a hole.

  `example₂ = ⇒-I { }0`
  `?0 : ∅ , x ∶ 𝔹 ⊢ if var x then false else true ∶ 𝔹`

Again we fill in the hole, observing that the outermost term is now
`if_then_else_`, which is typed using `𝔹-E`. The `𝔹-E` rule in turn takes
three arguments, which we again specify with holes.

  `example₂ = ⇒-I (𝔹-E { }0 { }1 { }2)`
  `?0 : ∅ , x ∶ 𝔹 ⊢ var x ∶ 𝔹`
  `?1 : ∅ , x ∶ 𝔹 ⊢ false ∶ 𝔹`
  `?2 : ∅ , x ∶ 𝔹 ⊢ true ∶ 𝔹`

Filling in the three holes gives the derivation above.



