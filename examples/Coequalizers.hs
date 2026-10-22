-- Run independently of the application:
--   runghc -XUnicodeSyntax examples/Coequalizers.hs
--
-- The interface is categorical; the implementation below is for finite sets.
-- Objects and arrows are values, so their endpoints are checked at runtime.
-- Finite sets use integer labels, and maps use tables. Constructors are kept
-- private: use finiteSet and finiteMap to maintain the representation laws.
-- All supplied lists must be finite. As usual in Haskell, termination and
-- the laws of arbitrary category implementations are not enforced by types.
module Main
  ( main
  , Category(..)
  , HasCoequalizers(..)
  , Coequalizer(..)
  , throughQuotient
  , FiniteSet
  , FiniteMap
  , finiteSet
  , finiteMap
  , apply
  , finiteSets
  ) where

import Control.Monad (forM, unless)
import Data.List (nub, partition, sort, sortOn)
import Data.Either (isLeft)

-- compose cat g f means g after f. Each implementation must satisfy the
-- category laws on valid objects and arrows.
data Category object morphism = Category
  { source ∷ morphism → object
  , target ∷ morphism → object
  , identity ∷ object → morphism
  , compose ∷ morphism → morphism → Either String morphism
  }

-- The construction returns the quotient object, its projection, and the
-- operation for factoring a compatible arrow through that projection.
-- For f,g : E → X, with q = projectionOntoCoequalizer result:
--   q . f = q . g
-- For h : X → Y with h . f = h . g, the last field returns the unique
-- hbar : Q → Y satisfying hbar . q = h.
data Coequalizer object morphism = Coequalizer
  { quotientObject ∷ object
  , projectionOntoCoequalizer ∷ morphism
  , universalMorphismFromCoequalizer ∷ morphism → Either String morphism
  }

data HasCoequalizers object morphism = HasCoequalizers
  { category ∷ Category object morphism
  , coequalizer ∷ morphism → morphism
                → Either String (Coequalizer object morphism)
  }

-- This reasoning is independent of sets, rings, matrices, etc. Given an
-- entry c : A → X and a quotient q : X → Q, construct q . c : A → Q.
-- It is a canonical composite of the given maps, not necessarily injective.
throughQuotient ∷ Category object morphism → Coequalizer object morphism
                → morphism → Either String morphism
throughQuotient cat result = compose cat (projectionOntoCoequalizer result)

-- A concrete category implementation starts here.
newtype FiniteSet = FiniteSet [Int] deriving (Eq, Show)

data FiniteMap = FiniteMap FiniteSet FiniteSet [(Int, Int)]
  deriving (Eq, Show)

finiteSet ∷ [Int] → FiniteSet
finiteSet = FiniteSet . sort . nub

finiteMap ∷ FiniteSet → FiniteSet → [(Int, Int)]
          → Either String FiniteMap
finiteMap from@(FiniteSet xs) to@(FiniteSet ys) table
  | map fst ordered /= xs =
      Left "A map must have exactly one image for each source element."
  | any (\(_, y) → y `notElem` ys) ordered =
      Left "A map image is outside the target object."
  | otherwise = Right (FiniteMap from to ordered)
  where ordered = sortOn fst table

apply ∷ FiniteMap → Int → Either String Int
apply (FiniteMap _ _ table) x = case lookup x table of
  Nothing → Left "The element is outside the map's source object."
  Just y → Right y

finiteCategory ∷ Category FiniteSet FiniteMap
finiteCategory = Category
  { source = \(FiniteMap from _ _) → from
  , target = \(FiniteMap _ to _) → to
  , identity = \obj@(FiniteSet xs) →
      FiniteMap obj obj [(x, x) | x ← xs]
  , compose = \g@(FiniteMap middle to _) (FiniteMap from middle' table) →
      if middle /= middle'
      then Left "Composition requires matching intermediate objects."
      else do
        images ← traverse (\(x, y) → do z ← apply g y; pure (x, z)) table
        finiteMap from to images
  }

finiteSets ∷ HasCoequalizers FiniteSet FiniteMap
finiteSets = HasCoequalizers finiteCategory finiteCoequalizer

finiteCoequalizer ∷ FiniteMap → FiniteMap
                  → Either String (Coequalizer FiniteSet FiniteMap)
finiteCoequalizer f@(FiniteMap e x@(FiniteSet xs) fs)
                  g@(FiniteMap e' x' gs)
  | e /= e' || x /= x' =
      Left "A coequalizer requires parallel arrows with the same endpoints."
  | otherwise = do
      -- Initially each element is its own class. Merge the classes of f(e)
      -- and g(e) for every e. Merging whole classes supplies transitivity.
      let classes = foldl merge (map (:[]) xs) (zip (map snd fs) (map snd gs))
          -- A class is represented by its least label. A coequalizer is only
          -- specified up to unique compatible isomorphism; these labels are
          -- an implementation choice, not extra mathematical structure.
          quotient = finiteSet [r | r:_ ← classes]
          table = [(a, r) | cls@(r:_) ← classes, a ← cls]
      q ← finiteMap x quotient table
      pure Coequalizer
        { quotientObject = quotient
        , projectionOntoCoequalizer = q
        , universalMorphismFromCoequalizer = \h → do
            hf ← compose finiteCategory h f
            hg ← compose finiteCategory h g
            if hf /= hg
              then Left "The map does not respect the identifications."
              else do
                let FiniteSet representatives = quotient
                images ← traverse (\r → do y ← apply h r; pure (r, y))
                                  representatives
                finiteMap quotient (target finiteCategory h) images
        }
  where
    merge classes (a, b) =
      let (joined, rest) = partition (\cls → a `elem` cls || b `elem` cls)
                                     classes
      in sort (concat joined) : rest

-- Exhaustive checks of the universal property on small finite objects.
-- In particular, compare the constructed factor with *all* maps Q → Y;
-- satisfying the commutative square alone would not establish uniqueness.
allMaps ∷ FiniteSet → FiniteSet → [FiniteMap]
allMaps from@(FiniteSet xs) to@(FiniteSet ys) =
  [FiniteMap from to (zip xs images) | images ← sequence (map (const ys) xs)]

smallObject ∷ Int → FiniteSet
smallObject n = finiteSet [0 .. n - 1]

assert ∷ String → Bool → Either String ()
assert label ok = unless ok (Left ("Check failed: " ++ label))

checkUniversalProperties ∷ Either String Int
checkUniversalProperties = do
  counts ← forM diagrams $ \(f, g) → do
    result ← coequalizer finiteSets f g
    let cat = category finiteSets
        x = target cat f
        q = projectionOntoCoequalizer result
        quotient = quotientObject result
    qf ← compose cat q f
    qg ← compose cat q g
    assert "q coequalizes f and g" (qf == qg)
    assert "projection endpoints" (source cat q == x && target cat q == quotient)
    let testMaps = [h | n ← [0 .. 2], h ← allMaps x (smallObject n)]
    mapM_ (checkFactor cat result f g) testMaps
    pure (length testMaps)
  pure (sum counts)
  where
    diagrams =
      [(f, g) | n ← [0 .. 2], m ← [0 .. 3]
              , f ← allMaps (smallObject n) (smallObject m)
              , g ← allMaps (smallObject n) (smallObject m)]
    checkFactor cat result f g h = do
      hf ← compose cat h f
      hg ← compose cat h g
      let q = projectionOntoCoequalizer result
          factors =
            [u | u ← allMaps (quotientObject result) (target cat h)
               , compose cat u q == Right h]
      case universalMorphismFromCoequalizer result h of
        Right u → do
          assert "compatible input" (hf == hg)
          assert "unique factor" (factors == [u])
        Left _ → do
          assert "incompatible input rejected" (hf /= hg)
          assert "no possible factor" (null factors)

checkInvalidInputs ∷ Either String ()
checkInvalidInputs = do
  let x = finiteSet [0, 1]
      y = finiteSet [0]
      cat = category finiteSets
      ix = identity cat x
      iy = identity cat y
  assert "missing map image" (isLeft (finiteMap x x [(0, 0)]))
  assert "duplicate map image"
    (isLeft (finiteMap x x [(0, 0), (0, 1), (1, 1)]))
  assert "image outside target" (isLeft (finiteMap x y [(0, 0), (1, 1)]))
  assert "nonparallel arrows" (isLeft (coequalizer finiteSets ix iy))
  assert "mismatched composition" (isLeft (compose cat ix iy))
  assert "element outside source" (isLeft (apply ix 2))
  result ← coequalizer finiteSets ix ix
  assert "factor with wrong source"
    (isLeft (universalMorphismFromCoequalizer result iy))
  assert "entry with wrong target" (isLeft (throughQuotient cat result iy))

demo ∷ Either String [String]
demo = do
  -- Relations 0 ~ 1 and 1 ~ 2 give classes {0,1,2} and {3}.
  let e = finiteSet [0, 1]
      x = finiteSet [0, 1, 2, 3]
      y = finiteSet [10, 20]
      a = finiteSet [100, 200]
  f ← finiteMap e x [(0, 0), (1, 1)]
  g ← finiteMap e x [(0, 1), (1, 2)]
  result ← coequalizer finiteSets f g
  h ← finiteMap x y [(0, 10), (1, 10), (2, 10), (3, 20)]
  hbar ← universalMorphismFromCoequalizer result h
  c ← finiteMap a x [(100, 2), (200, 3)]
  j ← throughQuotient (category finiteSets) result c
  pure
    [ "Q (class representatives): " ++ show (quotientObject result)
    , "q : X -> Q: " ++ show (projectionOntoCoequalizer result)
    , "hbar : Q -> Y: " ++ show hbar
    , "q . c : A -> Q: " ++ show j
    ]

main ∷ IO ()
main = case do
  checkInvalidInputs
  count ← checkUniversalProperties
  output ← demo
  pure (count, output) of
    Left problem → ioError (userError problem)
    Right (count, output) → do
      mapM_ putStrLn output
      putStrLn ("Passed " ++ show count ++ " exhaustive factorization checks.")
