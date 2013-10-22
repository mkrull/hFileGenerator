module Geckofinger.StringTemplate (
  mergeSourceStrings,
  mergeSourceFiles
) where

import Text.StringTemplate
import Data.Aeson (decode)
import Data.Map as Map (assocs)
import qualified Data.ByteString.Lazy as LBS (ByteString)
import Geckofinger.FileIO (safeReadFile, safeReadFileLBS)

mergeSourceFiles :: [String] -> IO (Maybe String)
-- at least two arguments needed
mergeSourceFiles (tpl:vars:kind:_) = do
  template <- safeReadFile tpl
  values <- safeReadFileLBS vars
  case template of
    Nothing -> return Nothing
    Just t -> case values of
        Nothing -> return Nothing
        Just v -> return $ mergeSourceStrings t v kind
-- wrong number of arguments
mergeSourceFiles _ = return Nothing

-- provide the raw string to create a template and the json values
-- as lazy bytestring
mergeSourceStrings :: String -> LBS.ByteString -> String -> Maybe String
mergeSourceStrings tpl jsonv kind = case decode jsonv of
    Just v -> return $ renderWithValues (assocs v) (newTpl kind tpl)
    Nothing -> Nothing -- TODO log something
  where
    newTpl :: String -> String -> StringTemplate String
    newTpl "angle" = newAngleSTMP
    newTpl _ = newSTMP
    renderWithValues :: [(String, String)] -> StringTemplate String -> String
    renderWithValues vmap = toString . setManyAttrib vmap
