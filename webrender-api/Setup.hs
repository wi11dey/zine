import Distribution.Simple
import Distribution.Simple.Setup
import Distribution.PackageDescription
import Distribution.Simple.LocalBuildInfo
import System.Process
import System.Exit
import qualified Data.Set as Set
import Data.Maybe
import Control.Monad
import Text.Regex.TDFA
import System.IO

main = defaultMainWithHooks simpleUserHooks
  { preBuild = \args buildFlags -> do
      putStrLn "Running cbindgen..."
      (ExitSuccess, stdout, stderr) <- readProcessWithExitCode 
        "cbindgen" 
        [
          "webrender_bindings_cbindgen",
          "--config", "webrender_bindings_cbindgen.toml",
          "--output", "webrender_bindings_cbindgen.h"]
        ""
      writeFile "cbindgen_stubs.h"
        $ unlines
        $ map (\missingType -> "typedef void " ++ missingType ++ ";")
        $ Set.toList
        $ Set.fromList
        $ do
          log <- lines stderr
          [_, missingType] <- pure $ getAllTextSubmatches
            $ log =~ "WARN: Can't find (.*). This usually means that this type was incompatible or not found."
          return missingType
      preBuild simpleUserHooks args buildFlags
  }
