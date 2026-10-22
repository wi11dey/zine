-- Run: runghc -XUnicodeSyntax examples/NonArchimedean.hs
--
-- Three distinct things:
-- 1. A specification of an ultrapower, conditional on an ultrafilter oracle.
-- 2. Executable Conway cuts for short (finite) surreal numbers.
-- 3. The exact ordered field Q(t), with t positive infinite. This is an
--    executable subfield of both a hyperreal field and the surreal numbers.
--    It is not a representation of either entire field.
module Main where

import Control.Monad (unless)
import Numeric.Natural (Natural)

-- The full hyperreal construction: sequences modulo a chosen ultrafilter.
-- The caller must supply a genuine nonprincipal ultrafilter. There is no
-- general computable implementation of this oracle on arbitrary predicates.
newtype Ultrafilter = Ultrafilter
  { almostEverywhere ∷ (Natural → Bool) → Bool }

newtype HyperRepresentative a = HyperRepresentative (Natural → a)

-- The diagonal into the product, followed conceptually by quotienting.
standard ∷ a → HyperRepresentative a
standard x = HyperRepresentative (const x)

equivalentModulo ∷ Eq a ⇒ Ultrafilter → HyperRepresentative a
                → HyperRepresentative a → Bool
equivalentModulo u (HyperRepresentative x) (HyperRepresentative y) =
  almostEverywhere u (\n → x n == y n)

lessModulo ∷ Ord a ⇒ Ultrafilter → HyperRepresentative a
           → HyperRepresentative a → Bool
lessModulo u (HyperRepresentative x) (HyperRepresentative y) =
  almostEverywhere u (\n → x n < y n)

pointwise ∷ (a → a → a) → HyperRepresentative a
          → HyperRepresentative a → HyperRepresentative a
pointwise operation (HyperRepresentative x) (HyperRepresentative y) =
  HyperRepresentative (\n → operation (x n) (y n))

-- Short surreal forms. Finite, acyclic lists/trees and valid cuts are the
-- representation invariant. These represent exactly the dyadic rationals.
data ShortSurreal = Cut [ShortSurreal] [ShortSurreal]

leq ∷ ShortSurreal → ShortSurreal → Bool
leq x@(Cut xl _) y@(Cut _ yr) =
  all (\l → not (leq y l)) xl && all (\r → not (leq r x)) yr

sameSurreal ∷ ShortSurreal → ShortSurreal → Bool
sameSurreal x y = leq x y && leq y x

valid ∷ ShortSurreal → Bool
valid (Cut ls rs) = all valid ls && all valid rs
  && all (\l → all (\r → not (leq r l)) rs) ls

cut ∷ [ShortSurreal] → [ShortSurreal] → Maybe ShortSurreal
cut ls rs
  | valid result = Just result
  | otherwise = Nothing
  where result = Cut ls rs

negateShort ∷ ShortSurreal → ShortSurreal
negateShort (Cut ls rs) = Cut (map negateShort rs) (map negateShort ls)

addShort ∷ ShortSurreal → ShortSurreal → ShortSurreal
addShort x@(Cut xl xr) y@(Cut yl yr) = Cut
  (map (`addShort` y) xl ++ map (addShort x) yl)
  (map (`addShort` y) xr ++ map (addShort x) yr)

zeroShort, oneShort, twoShort, halfShort ∷ ShortSurreal
zeroShort = Cut [] []
oneShort = Cut [zeroShort] []
twoShort = Cut [oneShort] []
halfShort = Cut [zeroShort] [oneShort]

-- Executable infinite/infinitesimal arithmetic: rational functions in t.
-- Coefficients are in ascending order. Trailing zeros are removed.
newtype Polynomial = Polynomial [Rational] deriving (Eq, Show)

polynomial ∷ [Rational] → Polynomial
polynomial = Polynomial . reverse . dropWhile (== 0) . reverse

addCoefficients ∷ [Rational] → [Rational] → [Rational]
addCoefficients [] ys = ys
addCoefficients xs [] = xs
addCoefficients (x:xs) (y:ys) = (x+y) : addCoefficients xs ys

addPolynomial ∷ Polynomial → Polynomial → Polynomial
addPolynomial (Polynomial xs) (Polynomial ys) =
  polynomial (addCoefficients xs ys)

negatePolynomial ∷ Polynomial → Polynomial
negatePolynomial (Polynomial xs) = polynomial (map negate xs)

multiplyPolynomial ∷ Polynomial → Polynomial → Polynomial
multiplyPolynomial (Polynomial xs) (Polynomial ys) = polynomial $
  foldl' addCoefficients []
    [replicate i 0 ++ map (x *) ys | (i,x) <- zip [0..] xs]

leadingCoefficient ∷ Polynomial → Rational
leadingCoefficient (Polynomial xs) = case reverse xs of
  [] → 0
  x:_ → x

degree ∷ Polynomial → Int
degree (Polynomial xs) = length xs - 1

constantPolynomial ∷ Rational → Polynomial
constantPolynomial q = polynomial [q]

-- The denominator must be nonzero. Equality is quotient equality, rather
-- than equality of numerator/denominator representatives.
data InfiniteRational = RF Polynomial Polynomial deriving Show

instance Eq InfiniteRational where
  RF p q == RF r s = multiplyPolynomial p s == multiplyPolynomial r q

instance Ord InfiniteRational where
  compare (RF p q) (RF r s) =
    let numeratorDifference = addPolynomial (multiplyPolynomial p s)
          (negatePolynomial (multiplyPolynomial r q))
        denominatorProduct = multiplyPolynomial q s
    in compare (leadingCoefficient numeratorDifference
                * leadingCoefficient denominatorProduct) 0

instance Num InfiniteRational where
  RF p q + RF r s = RF
    (addPolynomial (multiplyPolynomial p s) (multiplyPolynomial r q))
    (multiplyPolynomial q s)
  RF p q * RF r s = RF (multiplyPolynomial p r) (multiplyPolynomial q s)
  negate (RF p q) = RF (negatePolynomial p) q
  fromInteger n = RF (constantPolynomial (fromInteger n)) (constantPolynomial 1)
  abs x = if x < 0 then negate x else x
  signum x = case compare x 0 of
    LT → -1
    EQ → 0
    GT → 1

instance Fractional InfiniteRational where
  fromRational q = RF (constantPolynomial q) (constantPolynomial 1)
  recip (RF p q)
    | leadingCoefficient p == 0 = error "reciprocal of zero"
    | otherwise = RF q p

infinite, infinitesimal ∷ InfiniteRational
infinite = RF (polynomial [0,1]) (constantPolynomial 1)
infinitesimal = recip infinite

-- In this particular subfield, every finite element has rational standard
-- part. Nothing means the element is infinite in magnitude.
standardPart ∷ InfiniteRational → Maybe Rational
standardPart (RF p q) = case compare (degree p) (degree q) of
  LT → Just 0
  EQ → Just (leadingCoefficient p / leadingCoefficient q)
  GT → Nothing

-- Start from the same Peano naturals; this universal fold works in any
-- lawful unital numeric target, including InfiniteRational.
data Nat = Z | S Nat

injectNat ∷ Num a ⇒ Nat → a
injectNat Z = 0
injectNat (S n) = 1 + injectNat n

check ∷ String → Bool → IO ()
check label success = unless success (error ("failed: " ++ label))

main ∷ IO ()
main = do
  let three = injectNat (S (S (S Z))) ∷ InfiniteRational
      huge = fromInteger (10 ^ (1000 ∷ Int)) ∷ InfiniteRational
      x = infinite
      e = infinitesimal
  check "Nat embedding" (three == 3)
  check "positive infinite" (x > huge)
  check "positive infinitesimal" (0 < e && e < recip huge)
  check "inverse" (x * e == 1)
  check "quotient representatives" ((x*x-1)/(x-1) == x+1)
  check "negative denominator order" (1/(1-x) < 0)
  check "standard part" (standardPart ((3*x+2)/(x-5)) == Just 3)
  check "infinite has no standard part" (standardPart x == Nothing)
  check "surreal cut validity" (valid halfShort)
  check "surreal simplest number" (sameSurreal (Cut [zeroShort] [twoShort]) oneShort)
  check "surreal addition" (sameSurreal (addShort halfShort halfShort) oneShort)
  check "surreal negation" (sameSurreal (addShort oneShort (negateShort oneShort)) zeroShort)
  check "invalid cut rejected" (case cut [oneShort] [zeroShort] of
    Nothing → True
    Just _ → False)
  print (x > huge, 0 < e && e < recip huge, x * e == 1)
  print (standardPart ((3*x+2)/(x-5)))
  putStrLn "All executable hyperreal/surreal fragment checks passed."
