{-# LANGUAGE OverloadedStrings #-}

-- | Random GTK utils
module Yi.Frontend.Pango.Utils where

import Control.Exception (catch, throw)

import Data.Text (append)
import Paths_yine
import System.FilePath
import Graphics.UI.Gtk
import System.Glib.GError

loadIcon :: FilePath -> IO Pixbuf
loadIcon fpath = do
  let iconfile = "/Users/wdey/yi/yi-frontend-pango/art" </> fpath
  icoProject <-
    catch (pixbufNewFromFile iconfile)
    (\(GError dom code msg) ->
      throw $ GError dom code $
        msg `append` " -- use the yi_datadir environment variable to"
            `append` " specify an alternate location")
  pixbufAddAlpha icoProject (Just (0,255,0))
