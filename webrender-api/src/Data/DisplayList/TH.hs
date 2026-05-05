{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE CPP #-}
module Data.DisplayList.TH 
  ( generateFFIBindings ) where

import Language.Haskell.TH
import Language.Haskell.TH.Syntax
import Language.Haskell.TH.Lib
import Language.C.System.GCC
import qualified Language.C as C
import qualified Language.C.Data.Ident as CI
import qualified Language.C.Syntax.AST as CAST
import Control.Monad (forM)
import Data.List (isPrefixOf, isInfixOf)
import Data.Maybe (mapMaybe, catMaybes, fromMaybe)
import System.FilePath (takeDirectory, (</>))
import System.Process (readProcess)
import Foreign.Ptr (Ptr)
import Foreign.C.Types
import Data.Word
import Data.Int

-- | Generate both types and FFI bindings
generateFFIBindings :: String -> Q [Dec]
generateFFIBindings header = do
  loc <- location
  let packageRoot = takeDirectory $ takeDirectory $ takeDirectory $ loc_filename loc
  let headerPath = packageRoot </> header
  Right translUnit <- runIO $ C.parseCFile (newGCC "gcc") Nothing [] headerPath
  -- LLM code from here below
  types <- generateTypesFromTU translUnit
  let funDecls = extractFunctionDecls translUnit
  bindings <- mapM generateFFIBinding funDecls
  return $ types ++ concat bindings

-- | Generate type declarations from translation unit
generateTypesFromTU :: C.CTranslUnit -> Q [Dec]
generateTypesFromTU (C.CTranslUnit extDecls _) = do
  let structDefs = extractStructDefs extDecls
      typedefs = extractTypedefs extDecls
      enumDefs = extractEnumDefs extDecls
  
  structDecls <- mapM genStructDecl structDefs
  typeAliases <- mapM genTypeAlias typedefs
  enumDecls <- mapM genEnumDecl enumDefs
  
  return $ concat structDecls ++ catMaybes typeAliases ++ concat enumDecls

-- | Extract struct definitions
extractStructDefs :: [C.CExtDecl] -> [(String, [StructField])]
extractStructDefs = mapMaybe extractStruct
  where
    extractStruct (C.CDeclExt (C.CDecl specs [] _)) =
      case [su | C.CTypeSpec (C.CSUType su _) <- specs] of
        [C.CStruct _ (Just ident) (Just decls) _ _] ->
          let name = identToString ident
              fields = extractFields decls
          in Just (name, fields)
        _ -> Nothing
    extractStruct _ = Nothing

-- | Struct field info
data StructField = StructField
  { fieldName :: String
  , fieldType :: C.CTypeSpec
  , fieldIsPtr :: Bool
  , fieldIsArray :: Maybe Int
  }

-- | Extract fields from struct declarations
extractFields :: [C.CDecl] -> [StructField]
extractFields = mapMaybe extractField
  where
    extractField (C.CDecl specs declarators _) =
      case declarators of
        [(Just (C.CDeclr (Just ident) derivedDecls _ _ _), _, _)] ->
          let fieldName = identToString ident
              fieldType = extractTypeSpec specs
              fieldIsPtr = any isPtr derivedDecls
              fieldIsArray = findArraySize derivedDecls
          in Just StructField{..}
        _ -> Nothing
    
    isPtr (C.CPtrDeclr _ _) = True
    isPtr _ = False
    
    findArraySize [] = Nothing
    findArraySize (C.CArrDeclr _ (C.CArrSize _ (C.CConst (C.CIntConst n _))) _ : _) = 
      Just (fromIntegral $ C.getCInteger n)
    findArraySize (_ : xs) = findArraySize xs

-- | Generate Haskell struct declaration
genStructDecl :: (String, [StructField]) -> Q [Dec]
genStructDecl (name, fields) = do
  let dataName = mkName name
      conName = mkName name
  
  fieldDecls <- mapM genFieldDecl fields
  
  let dataDec = DataD [] dataName [] Nothing 
        [RecC conName fieldDecls] 
        [DerivClause Nothing [ConT ''Show, ConT ''Eq]]
  
  return [dataDec]
  where
    genFieldDecl StructField{..} = do
      fieldType' <- cTypeSpecToHaskellType fieldType fieldIsPtr
      let fieldNameHs = mkName $ toLowerFirst name ++ capitalizeFirst fieldName
      return (fieldNameHs, Bang NoSourceUnpackedness NoSourceStrictness, fieldType')

-- | Extract typedef declarations
extractTypedefs :: [C.CExtDecl] -> [(String, C.CTypeSpec)]
extractTypedefs = mapMaybe extractTypedef
  where
    extractTypedef (C.CDeclExt (C.CDecl specs declarators _)) =
      case (specs, declarators) of
        ([C.CStorageSpec (C.CTypedef _), C.CTypeSpec typeSpec], 
         [(Just (C.CDeclr (Just ident) _ _ _ _), _, _)]) ->
          Just (identToString ident, typeSpec)
        _ -> Nothing
    extractTypedef _ = Nothing

-- | Generate type alias
genTypeAlias :: (String, C.CTypeSpec) -> Q (Maybe Dec)
genTypeAlias (name, typeSpec) = do
  if shouldSkipType name
    then return Nothing
    else do
      haskellType <- cTypeSpecToHaskellType typeSpec False
      return $ Just $ TySynD (mkName name) [] haskellType

-- | Check if we should skip a type
shouldSkipType :: String -> Bool
shouldSkipType name = any (`isPrefixOf` name) 
  ["__", "pthread_", "FILE", "va_list"]

-- | Extract enum definitions
extractEnumDefs :: [C.CExtDecl] -> [(String, [(String, Maybe Integer)])]
extractEnumDefs = mapMaybe extractEnum
  where
    extractEnum (C.CDeclExt (C.CDecl specs [] _)) =
      case [e | C.CTypeSpec (C.CEnumType e _) <- specs] of
        [C.CEnum (Just ident) (Just enumerators) _ _] ->
          let name = identToString ident
              values = map extractEnumerator enumerators
          in Just (name, values)
        _ -> Nothing
    extractEnum _ = Nothing
    
    extractEnumerator (ident, maybeExpr) =
      (identToString ident, extractConstValue maybeExpr)
    
    extractConstValue Nothing = Nothing
    extractConstValue (Just (C.CConst (C.CIntConst n _))) = 
      Just (C.getCInteger n)
    extractConstValue _ = Nothing

-- | Generate enum declaration
genEnumDecl :: (String, [(String, Maybe Integer)]) -> Q [Dec]
genEnumDecl (enumName, values) = do
  let typeName = mkName enumName
  
  let newtypeDec = NewtypeD [] typeName [] Nothing
        (RecC typeName [(mkName $ "un" ++ enumName, Bang NoSourceUnpackedness NoSourceStrictness, ConT ''Word32)])
        [DerivClause Nothing [ConT ''Show, ConT ''Eq]]
  
  constants <- forM (zip [0..] values) $ \(idx, (valName, maybeVal)) -> do
    let constName = mkName $ toLowerFirst valName
        value = fromMaybe idx maybeVal
    return $ ValD (VarP constName) 
      (NormalB $ AppE (ConE typeName) (LitE $ IntegerL value)) []
  
  return $ newtypeDec : constants

-- | Convert C type spec to Haskell type
cTypeSpecToHaskellType :: C.CTypeSpec -> Bool -> Q Type
cTypeSpecToHaskellType typeSpec isPtr = do
  let baseType = case typeSpec of
        C.CVoidType _ -> 
          if isPtr then ConT ''()
          else TupleT 0
        
        C.CCharType _ -> ConT ''CChar
        C.CShortType _ -> ConT ''CShort  
        C.CIntType _ -> ConT ''CInt
        C.CLongType _ -> ConT ''CLong
        C.CFloatType _ -> ConT ''CFloat
        C.CDoubleType _ -> ConT ''CDouble
        C.CBoolType _ -> ConT ''CBool
        
        C.CSUType (C.CStruct _ (Just ident) _ _ _) _ ->
          ConT $ mkName $ identToString ident
        
        C.CEnumType (C.CEnum (Just ident) _ _ _) _ ->
          ConT $ mkName $ identToString ident
        
        C.CTypeDef ident _ ->
          let name = identToString ident
          in case name of
            "uint8_t" -> ConT ''Word8
            "uint16_t" -> ConT ''Word16
            "uint32_t" -> ConT ''Word32
            "uint64_t" -> ConT ''Word64
            "int8_t" -> ConT ''Int8
            "int16_t" -> ConT ''Int16
            "int32_t" -> ConT ''Int32
            "int64_t" -> ConT ''Int64
            "uintptr_t" -> ConT ''CSize
            "size_t" -> ConT ''CSize
            "bool" -> ConT ''CBool
            _ -> ConT $ mkName name
        
        _ -> ConT ''Word32  -- Default
  
  return $ if isPtr 
    then AppT (ConT ''Ptr) baseType
    else baseType

-- | Function declaration info
data FunDeclInfo = FunDeclInfo
  { funName :: String
  , funReturnType :: C.CTypeSpec
  , funParams :: [(Maybe String, C.CDecl)]
  , funIsPtr :: Bool
  }

-- | Extract function declarations from translation unit
extractFunctionDecls :: C.CTranslUnit -> [FunDeclInfo]
extractFunctionDecls (C.CTranslUnit extDecls _) = 
  mapMaybe extractFunDecl extDecls
  where
    extractFunDecl :: C.CExtDecl -> Maybe FunDeclInfo
    extractFunDecl (C.CDeclExt (C.CDecl specs [(Just declr, _, _)] _)) =
      case declr of
        C.CDeclr (Just ident) [C.CFunDeclr (Right (params, _)) _ _] _ _ _ ->
          let funName = identToString ident
              funReturnType = extractTypeSpec specs
              funIsPtr = hasPointerDecl specs declr
              funParams = extractParams params
          in if shouldBindFunction funName
             then Just FunDeclInfo{..}
             else Nothing
        _ -> Nothing
    extractFunDecl _ = Nothing

-- | Extract type specifier from declaration specifiers
extractTypeSpec :: [C.CDeclSpec] -> C.CTypeSpec
extractTypeSpec specs = 
  case [ts | C.CTypeSpec ts <- specs] of
    (t:_) -> t
    [] -> C.CVoidType C.undefNode

-- | Check if declaration has pointer
hasPointerDecl :: [C.CDeclSpec] -> C.CDeclr -> Bool
hasPointerDecl _ (C.CDeclr _ derivedDecls _ _ _) =
  any isPtr derivedDecls
  where
    isPtr (C.CPtrDeclr _ _) = True
    isPtr _ = False

-- | Extract parameters from function declarator
extractParams :: [C.CDecl] -> [(Maybe String, C.CDecl)]
extractParams = map extractParam
  where
    extractParam decl@(C.CDecl _ declarators _) =
      case declarators of
        [(Just (C.CDeclr (Just ident) _ _ _ _), _, _)] ->
          (Just (identToString ident), decl)
        _ -> (Nothing, decl)

-- | Check if we should generate binding for this function
shouldBindFunction :: String -> Bool
shouldBindFunction name =
  not $ any (`isPrefixOf` name)
    [ "__android_log_"
    , "is_in_compositor_thread"
    , "is_in_render_thread"
    , "is_in_main_thread"
    , "is_glcontext_"
    , "gecko_profiler_"
    ]

-- | Convert C identifier to string
identToString :: CI.Ident -> String
identToString (CI.Ident str _ _) = str

-- | Generate FFI binding for a function
generateFFIBinding :: FunDeclInfo -> Q [Dec]
generateFFIBinding FunDeclInfo{..} = do
  let haskellName = mkName $ "c_" ++ funName
  
  maybeType <- cTypeToHaskell funReturnType funIsPtr funParams
  
  case maybeType of
    Just haskellType -> return
      [ForeignD $ ImportF CCall Safe funName haskellName haskellType]
    Nothing -> return []

-- | Convert C type to Haskell type
cTypeToHaskell :: C.CTypeSpec -> Bool -> [(Maybe String, C.CDecl)] -> Q (Maybe Type)
cTypeToHaskell returnTypeSpec isPtr params = do
  returnType <- cTypeSpecToHaskellType returnTypeSpec isPtr
  paramTypes <- mapM (paramToHaskellType . snd) params
  
  let ioReturnType = AppT (ConT ''IO) returnType
      functionType = foldr (\param acc -> AppT (AppT ArrowT param) acc)
                          ioReturnType paramTypes
  
  return $ Just functionType

-- | Convert parameter declaration to Haskell type
paramToHaskellType :: C.CDecl -> Q Type
paramToHaskellType (C.CDecl specs declarators _) = do
  let typeSpec = extractTypeSpec specs
      isPtr = case declarators of
                [(Just declr, _, _)] -> hasPointerDecl specs declr
                _ -> False
  
  cTypeSpecToHaskellType typeSpec isPtr

-- | Helper to convert first letter to lowercase
toLowerFirst :: String -> String
toLowerFirst [] = []
toLowerFirst (c:cs) = toLower c : cs
  where
    toLower ch = if ch >= 'A' && ch <= 'Z' 
                 then toEnum (fromEnum ch + 32)
                 else ch

-- | Helper to capitalize first letter
capitalizeFirst :: String -> String  
capitalizeFirst [] = []
capitalizeFirst (c:cs) = toUpper c : cs
  where
    toUpper ch = if ch >= 'a' && ch <= 'z'
                 then toEnum (fromEnum ch - 32)
                 else ch
