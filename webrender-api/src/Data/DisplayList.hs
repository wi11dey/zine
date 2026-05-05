module Data.DisplayList (DisplayListM, runDisplayListM, rect, stackingContext) where

import Control.Monad.Reader
import Foreign.Ptr (Ptr, FunPtr)
import Foreign.ForeignPtr (ForeignPtr, newForeignPtr)

data DisplayListBuilder
data DisplayListPayload

newtype DisplayListM a = DisplayListM {
  buildDisplayList :: ReaderT (Ptr DisplayListBuilder) IO a
  }
  deriving (Functor, Applicative, Monad)

foreign import ccall "dlb_new" cDlbNew :: IO (Ptr DisplayListBuilder)
-- Destroys the DLB too
foreign import ccall "dlb_end" cDlbEnd :: Ptr DisplayListBuilder -> IO (Ptr DisplayListPayload)
foreign import ccall "&dlp_destroy" cDlpDestroy :: FunPtr (Ptr DisplayListPayload -> IO ())

runDisplayListM :: DisplayListM () -> IO (ForeignPtr DisplayListPayload)
runDisplayListM (DisplayListM { buildDisplayList }) = do
  dlb <- cDlbNew
  runReaderT buildDisplayList dlb
  payloadPtr <- cDlbEnd dlb
  newForeignPtr cDlpDestroy payloadPtr

data CommonItemProperties
data LayoutRect
data ColorF
data LayoutPoint

cDlbPushRect :: Ptr DisplayListBuilder -> CommonItemProperties -> LayoutRect -> ColorF -> IO ()
cDlbPushRect = undefined

cDlbPushStackingContext :: Ptr DisplayListBuilder -> LayoutPoint -> IO ()
cDlbPushStackingContext = undefined

cDlbPopStackingContext :: Ptr DisplayListBuilder -> IO ()
cDlbPopStackingContext = undefined

rect :: CommonItemProperties -> LayoutRect -> ColorF -> DisplayListM ()
rect props layout color = DisplayListM do
  ptr <- ask
  liftIO (cDlbPushRect ptr props layout color)

stackingContext :: LayoutPoint -> DisplayListM a -> DisplayListM a
stackingContext origin context = DisplayListM do
  ptr <- ask
  liftIO (cDlbPushStackingContext ptr origin)
  returnValue <- buildDisplayList context
  liftIO (cDlbPopStackingContext ptr)
  return $ returnValue
