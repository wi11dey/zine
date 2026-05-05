{-# LANGUAGE BlockArguments #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE NamedFieldPuns #-}

module Data.DisplayList where

import Control.Monad.Reader
import Foreign.Ptr (Ptr)

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

rect :: CommonItemProperties -> LayoutRect -> ColorF -> DisplayListM ()
rect props layout color = do
  ptr <- ask
  liftIO (cDlbPushRect ptr props layout color)

stackingContext :: LayoutPoint -> DisplayListM a -> DisplayListM a
stackingContext origin context = do
  ptr <- ask
  liftIO (cDlbPushStackingContext ptr origin)
  returnValue <- context
  liftIO (cDlbPopStackingContext ptr)
  return $ returnValue
