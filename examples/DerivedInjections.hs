{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE UndecidableInstances #-}

-- Run independently of the application:
--   runghc -XUnicodeSyntax examples/DerivedInjections.hs
--
-- The trusted input is the meaning of each construction and the target's
-- algebraic operations. No instance contains a map into a particular target.
--
-- Differences and fractions are representatives of equivalence classes.
-- A Cauchy approximation at precision n must have error at most 2^(-n).
-- Equality of reals is deliberately not an operation of this example.
-- These finite programs represent computable reals, not every classical real.
module Main (main) where

import Control.Monad (unless)
import Data.Kind (Constraint)
import Data.Ratio ((%), denominator, numerator)
import qualified Prelude as P
import Prelude

-- Algebraic structure, with the usual laws trusted rather than proved.
class Semiring a where
  zero, one ∷ a
  plus, times ∷ a → a → a

class Semiring a ⇒ Ring a where
  negative ∷ a → a

-- Inverse requires a nonzero argument. For a real, finding evidence of
-- nonzeroness may take arbitrarily long; it diverges when given zero.
class Ring a ⇒ Field a where
  inverse ∷ a → a

type Precision = P.Integer

-- The input sequence must approach its limit with error at most 2^(-n).
-- All instances here use the ordinary absolute-value / coordinate metric.
class Field a ⇒ Complete a where
  limit ∷ (Precision → a) → a

minus ∷ Ring a ⇒ a → a → a
minus x y = plus x (negative y)

divide ∷ Field a ⇒ a → a → a
divide x y = times x (inverse y)

-- Construction syntax. Names avoid clashes with Nat's Z constructor.
data Nat = Z | S Nat deriving (Eq, Ord)
data Difference a = Difference a a
data Fraction a = Fraction a a
newtype Completion a = Cauchy (Precision → a)
data Complex a = Complex a a

type Ints = Difference Nat
type Rats = Fraction Ints
type Reals = Completion Rats
type Complexes = Complex Reals

-- The reusable interpreter: the source construction determines which
-- operations a target must support. This is the only tower conversion.
-- It is injective for the tower below; canonical maps to arbitrary other
-- models (for example a field of positive characteristic) need not be.
class Construction a where
  type Needs a b ∷ Constraint
  inject ∷ Needs a b ⇒ a → b

-- Nat is initial among unital semirings.
instance Construction Nat where
  type Needs Nat b = Semiring b
  inject Z = zero
  inject (S n) = plus one (inject n)

-- Interpret a formal difference using the target's subtraction.
instance Construction a ⇒ Construction (Difference a) where
  type Needs (Difference a) b = (Needs a b, Ring b)
  inject (Difference p n) = minus (inject p) (inject n)

-- Interpret a fraction using the target's division. For this tower the
-- source is Z, and targets have characteristic zero, so denominators survive.
instance Construction a ⇒ Construction (Fraction a) where
  type Needs (Fraction a) b = (Needs a b, Field b)
  inject (Fraction p q) = divide (inject p) (inject q)

-- Extend the interpretation of a dense subfield by taking limits.
-- The underlying interpretation must preserve the chosen metric.
instance Construction a ⇒ Construction (Completion a) where
  type Needs (Completion a) b = (Needs a b, Complete b)
  inject (Cauchy approximations) = limit (inject . approximations)

-- The target constructions supply arithmetic, not conversion functions.
instance Semiring Nat where
  zero = Z
  one = S Z
  plus Z b = b
  plus (S a) b = S (plus a b)
  times Z _ = Z
  times (S a) b = plus b (times a b)

instance Semiring a ⇒ Semiring (Difference a) where
  zero = Difference zero zero
  one = Difference one zero
  plus (Difference a b) (Difference c d) =
    Difference (plus a c) (plus b d)
  times (Difference a b) (Difference c d) =
    Difference (plus (times a c) (times b d))
               (plus (times a d) (times b c))

instance Semiring a ⇒ Ring (Difference a) where
  negative (Difference a b) = Difference b a

-- For differences over Nat, this is exactly the group-completion relation.
instance (Semiring a, Eq a) ⇒ Eq (Difference a) where
  Difference a b == Difference c d = plus a d == plus c b

instance Semiring a ⇒ Semiring (Fraction a) where
  zero = Fraction zero one
  one = Fraction one one
  plus (Fraction a b) (Fraction c d) =
    Fraction (plus (times a d) (times c b)) (times b d)
  times (Fraction a b) (Fraction c d) =
    Fraction (times a c) (times b d)

instance Ring a ⇒ Ring (Fraction a) where
  negative (Fraction a b) = Fraction (negative a) b

instance Field Rats where
  inverse (Fraction a b)
    | a == zero = error "inverse: zero fraction"
    | otherwise = Fraction b a

instance (Semiring a, Eq a) ⇒ Eq (Fraction a) where
  Fraction a b == Fraction c d = times a d == times c b

-- Host integers/rationals are used only for finite bookkeeping, display,
-- error bounds, and reducing representatives. The tower's carriers remain
-- the types built above from Nat, and inject does not use these helpers.
nat ∷ P.Integer → Nat
nat n
  | n < 0 = error "nat: negative input"
  | n == 0 = Z
  | otherwise = S (nat (n - 1))

natValue ∷ Nat → P.Integer
natValue = go 0
  where
    go n Z = n
    go n (S rest) = let next = n + 1 in next `seq` go next rest

integer ∷ P.Integer → Ints
integer n
  | n >= 0 = Difference (nat n) Z
  | otherwise = Difference Z (nat (-n))

integerValue ∷ Ints → P.Integer
integerValue (Difference p n) = natValue p - natValue n

rational ∷ P.Integer → P.Integer → Rats
rational _ 0 = error "rational: zero denominator"
rational p q = fromHostRational (p % q)

fromHostRational ∷ P.Rational → Rats
fromHostRational q = Fraction (integer (numerator q))
                             (integer (denominator q))

rationalValue ∷ Rats → P.Rational
rationalValue (Fraction p q) = integerValue p % integerValue q

-- Reducing a representative changes neither its quotient class nor its
-- interpretation. It keeps this deliberately unary example reasonably small.
reduce ∷ Rats → Rats
reduce = fromHostRational . rationalValue

epsilon ∷ Precision → P.Rational
epsilon n
  | n < 0 = error "precision must be nonnegative"
  | otherwise = 1 % (2 ^ n)

precisionFor ∷ P.Rational → Precision
precisionFor tolerance
  | tolerance <= 0 = error "precisionFor: nonpositive tolerance"
  | otherwise = search 0
  where
    search n
      | epsilon n <= tolerance = n
      | otherwise = search (n + 1)

approximate ∷ Reals → Precision → Rats
approximate (Cauchy approximations) n
  | n < 0 = error "precision must be nonnegative"
  | otherwise = reduce (approximations n)

instance Semiring Reals where
  zero = Cauchy (const zero)
  one = Cauchy (const one)
  plus x y = Cauchy $ \n →
    reduce (plus (approximate x (n + 1)) (approximate y (n + 1)))
  times x y =
    let bx = abs (rationalValue (approximate x 0)) + 1
        by = abs (rationalValue (approximate y 0)) + 1
        extra = precisionFor (1 / (bx + by + 1))
    in Cauchy $ \n →
      reduce (times (approximate x (n + extra))
                    (approximate y (n + extra)))

instance Ring Reals where
  negative x = Cauchy $ \n → negative (approximate x n)

instance Field Reals where
  inverse x =
    -- Find a strictly positive lower bound for |x|.
    let search k =
          let b = abs (rationalValue (approximate x k)) - epsilon k
          in if b > 0 then b else search (k + 1)
        lower = search 0
    in Cauchy $ \n →
      let tolerance = min (lower / 2) (epsilon n * lower * lower / 2)
          k = precisionFor tolerance
      in reduce (inverse (approximate x k))

instance Complete Reals where
  limit xs = Cauchy $ \n → approximate (xs (n + 1)) (n + 1)

instance Ring a ⇒ Semiring (Complex a) where
  zero = Complex zero zero
  one = Complex one zero
  plus (Complex a b) (Complex c d) = Complex (plus a c) (plus b d)
  times (Complex a b) (Complex c d) =
    Complex (minus (times a c) (times b d))
            (plus (times a d) (times b c))

instance Ring a ⇒ Ring (Complex a) where
  negative (Complex a b) = Complex (negative a) (negative b)

instance Field Complexes where
  inverse (Complex a b) =
    let normSquared = plus (times a a) (times b b)
    in Complex (divide a normSquared) (negative (divide b normSquared))

instance Complete Complexes where
  limit xs = Complex
    (limit (\n → case xs n of Complex a _ → a))
    (limit (\n → case xs n of Complex _ b → b))

-- An irrational input, using floor(sqrt(2) * 2^n) / 2^n.
-- Its error is strictly less than 2^(-n).
sqrtTwo ∷ Reals
sqrtTwo = Cauchy $ \n →
  let d = 2 ^ n
  in rational (integerSquareRoot (2 * d * d)) d

integerSquareRoot ∷ P.Integer → P.Integer
integerSquareRoot n = search 0 (n + 1)
  where
    search lo hi
      | hi - lo <= 1 = lo
      | mid * mid <= n = search mid hi
      | otherwise = search lo mid
      where mid = (lo + hi) `div` 2

complexApproximation ∷ Complexes → Precision → (P.Rational, P.Rational)
complexApproximation (Complex x y) n =
  (rationalValue (approximate x n), rationalValue (approximate y n))

check ∷ String → Bool → IO ()
check name ok = unless ok (error ("failed: " ++ name))

main ∷ IO ()
main = do
  -- These are all the same inject. Only the inferred source/target changes.
  let n = S (S (S Z))
      z = inject n ∷ Ints
      q = inject z ∷ Rats
      r = inject q ∷ Reals
      c = inject r ∷ Complexes
  print (integerValue z, rationalValue q, complexApproximation c 3)

  let half = rational 1 2
      halfReal = inject half ∷ Reals
      halfComplex = inject halfReal ∷ Complexes
  print (complexApproximation halfComplex 3)
  print (complexApproximation (inject sqrtTwo ∷ Complexes) 3)

  check "Nat -> Z" (integerValue z == 3)
  check "Z -> Q" (rationalValue q == 3)
  check "Q -> R -> C" (complexApproximation c 3 == (3, 0))
  check "fraction -> C" (complexApproximation halfComplex 3 == (1 % 2, 0))
  check "direct and composed Nat -> C"
    (complexApproximation (inject n ∷ Complexes) 3 == complexApproximation c 3)
  check "equivalent integer representatives"
    ((inject (Difference (nat 5) (nat 2)) ∷ Rats) == q)
  check "equivalent fraction representatives"
    (rationalValue (approximate (inject (Fraction (integer 2) (integer 4))) 3)
      == rationalValue (approximate halfReal 3))
  let (sqrtApprox, imaginaryApprox) =
        complexApproximation (inject sqrtTwo ∷ Complexes) 3
  check "sqrt(2) injection error bound"
    (sqrtApprox * sqrtApprox <= 2
      && (sqrtApprox + epsilon 3) ^ (2 ∷ Int) >= 2
      && imaginaryApprox == 0)
  let squareApprox = rationalValue (approximate (times sqrtTwo sqrtTwo) 3)
      reciprocalApprox = rationalValue (approximate (inverse sqrtTwo) 3)
      imaginaryUnit = Complex zero one ∷ Complexes
  check "real multiplication error bound" (abs (squareApprox - 2) <= epsilon 3)
  check "real reciprocal error bound"
    ((reciprocalApprox - epsilon 3) ^ (2 ∷ Int) <= 1 % 2
      && (reciprocalApprox + epsilon 3) ^ (2 ∷ Int) >= 1 % 2)
  check "i squared" (complexApproximation (times imaginaryUnit imaginaryUnit) 3
    == (-1, 0))
  check "inverse i" (complexApproximation (inverse imaginaryUnit) 3 == (0, -1))
  putStrLn "All construction-derived injection checks passed."
