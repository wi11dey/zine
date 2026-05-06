{-# LANGUAGE OverloadedStrings #-}

import Data.Prototype (override)
import Lens.Micro.Platform ((.=))
import Yi.Boot (configMain)
import Yi.Config.Default.Emacs
import Yi.Config.Default.HaskellMode
import Yi.Config.Default.JavaScriptMode
import Yi.Config.Default.MiscModes
import Yi.Config.Default.Vty
import Yi.Config.Simple
import qualified Yi.IncrementalParse as IncrParser (scanner)
import Yi.Keymap.Emacs as Emacs
import qualified Yi.Lexer.Zine as Zine (pText)
import Yi.Mode.Common
import Yi.Mode.Latex
import qualified Yi.Rope as R
import Yi.String (mapLines)
import Yi.Style (StyleName)
import Yi.Syntax (ExtHL (ExtHL), Scanner, mkHighlighter)
import Yi.Syntax.OnlineTree (Tree, manyToks)

zineMode =
    fundamentalMode
        { modeName = "zine",
          modeApplies = anyExtension ["z"],
          modeHL = ExtHL $ mkHighlighter (IncrParser.scanner Zine.pText)
        }

main :: IO ()
main = configMain defaultConfig $ do
    configureVty
    myEmacsConfig
    configureHaskellMode
    configureJavaScriptMode
    configureMiscModes
    addMode latexMode2
    addMode zineMode

myEmacsConfig :: ConfigM ()
myEmacsConfig = do
    configureEmacs
    defaultKmA .= myKeymapSet

myKeymapSet :: KeymapSet
myKeymapSet =
    Emacs.mkKeymapSet
        $ Emacs.defKeymap `override` \parent _self ->
            parent
                { -- bind M-> to increaseIndent and mix with default Emacs keymap.
                  _eKeymap = (_eKeymap parent) ||> (metaCh '>' ?>>! increaseIndent)
                }

increaseIndent :: BufferM ()
increaseIndent = do
    r <- getSelectRegionB
    r' <- unitWiseRegion Line r -- extend the region to full lines.
    modifyRegionB (mapLines (R.cons ' ')) r'
