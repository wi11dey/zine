{-# OPTIONS_GHC -Wno-x-partial -Wunused-imports #-}
-- ^It is fine to have build panic in unexpected scenarios

{-# LANGUAGE BlockArguments #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE UnicodeSyntax #-}
{-# LANGUAGE ViewPatterns #-}

import Control.Monad
import Distribution.Simple hiding (classifyExtension)
import Distribution.Simple.Setup
import Distribution.Types.HookedBuildInfo
import System.Process
import Data.List
import Data.Maybe
import Distribution.Simple.PreProcess
import Distribution.Simple.PreProcess.Unlit
import Distribution.Simple.SrcDist
import Distribution.Simple.Utils
import Distribution.Types.BuildInfo
import Distribution.Types.PackageDescription
import Distribution.Verbosity
import Language.Haskell.Extension as Cabal hiding (classifyExtension)
import Language.Haskell.Exts.Extension
import Language.Haskell.Exts.Lexer
import Language.Haskell.Exts.Parser
import Language.Haskell.Exts.SrcLoc
import Data.Text (Text)
import qualified Data.Text as Text
import qualified Data.Text.IO as Text

main = defaultMainWithHooks simpleUserHooks
  { preBuild = buildUDPipe
  , buildHook = \package localBuildInfo hooks flags → do
      unicodeify package
      buildHook simpleUserHooks package localBuildInfo hooks flags
  }

unicodeSyntax ∷ Token → Maybe Text
unicodeSyntax KW_Forall   = Just "∀"
unicodeSyntax DoubleColon = Just "∷"
unicodeSyntax RightArrow  = Just "→"
unicodeSyntax LeftArrow   = Just "←"
unicodeSyntax DoubleArrow = Just "⇒"
unicodeSyntax _           = Nothing

unicodeify ∷ PackageDescription → IO ()
unicodeify package = do
  let extensions = do
        BuildInfo {..} ← allBuildInfo package
        Cabal.EnableExtension extension ← defaultExtensions ++ otherExtensions
        return $ classifyExtension $ show extension
  packageFiles ← listPackageSources normal "." package knownSuffixHandlers
  (concat → replacements) ← forM packageFiles \file → do
    tokens ← lex extensions file
    return do
      Loc {..} ← tokens
      replacement ← maybeToList $ unicodeSyntax $ unLoc
      return (loc, replacement)
  sequence_ $ reverse $ map replace replacements
    where
      lex extensions parseFilename
        | ".lhs" `isSuffixOf` parseFilename = do
            source ← readFile parseFilename
            preprocessed ← either return (dieWithException normal) $ unlit parseFilename source
            return $
              fromParseResult $
              lexTokenStreamWithMode defaultParseMode { parseFilename, extensions } preprocessed
        | ".hs" `isSuffixOf` parseFilename = do
            source ← readFile parseFilename
            return $
              fromParseResult $
              lexTokenStreamWithMode defaultParseMode { parseFilename, extensions } source
        | otherwise = return []

      replace ∷ (SrcSpan, Text) → IO ()
      replace (SrcSpan { srcSpanFilename = filename
                       , srcSpanStartLine   = (subtract 1 → startLine)
                       , srcSpanStartColumn = (subtract 1 → startCol)
                       , srcSpanEndLine     = (subtract 1 → endLine)
                       , srcSpanEndColumn   = (subtract 1 → endCol)
                       },
                replacement) = do
        source ← Text.readFile filename
        let (prevLines, splitAt (endLine - startLine + 1) → (spanLines, nextLines)) =
              splitAt startLine $ Text.lines source
        Text.writeFile filename $
          Text.unlines $
          prevLines ++
            [ Text.take startCol (head spanLines) <>
              replacement <>
              Text.drop endCol (last spanLines)] ++
            nextLines

buildUDPipe ∷ Args → BuildFlags → IO HookedBuildInfo
buildUDPipe _ _ = do
  callProcess
    "make"
    [ "-C",
      "udpipe/src_lib_only",
      "-o",
      "force", -- disable forcing
      "udpipe.cpp",
      "CXX=/usr/bin/clang++"
    ]
  pure emptyHookedBuildInfo
