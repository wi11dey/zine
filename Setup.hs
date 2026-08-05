{-# LANGUAGE UnicodeSyntax #-}

import Distribution.Simple
import Distribution.Simple.Setup (BuildFlags)
import Distribution.Types.HookedBuildInfo (HookedBuildInfo, emptyHookedBuildInfo)
import System.Process (callProcess)

main ∷ IO ()
main = defaultMainWithHooks simpleUserHooks {preBuild = buildUDPipe}

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
