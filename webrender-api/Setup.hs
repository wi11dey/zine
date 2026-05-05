import Distribution.Simple
import Distribution.Simple.Setup
import Distribution.PackageDescription
import Distribution.Simple.LocalBuildInfo
import System.Process
import System.Exit
import Control.Monad

main = defaultMainWithHooks simpleUserHooks
  { preBuild = \args buildFlags -> do
      putStrLn "Running cbindgen..."
      exitCode <- system "cbindgen webrender_bindings_cbindgen -c webrender_bindings_cbindgen.toml -o webrender_bindings_cbindgen.h"
      case exitCode of
        ExitSuccess -> putStrLn "cbindgen completed successfully"
        ExitFailure code -> error $ "cbindgen failed with exit code: " ++ show code
      preBuild simpleUserHooks args buildFlags
  }
