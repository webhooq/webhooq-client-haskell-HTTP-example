{-# LANGUAGE OverloadedStrings, FlexibleInstances #-}
module Network.HTTP.Webhooq.HttpServer where 

import Web.Scotty

import Data.Monoid (mconcat)

import Control.Concurrent.STM
import Control.Concurrent
import Control.Monad.IO.Class (liftIO)

import Data.UUID
import Data.UUID.Aeson
import Data.UUID.Hashable

import qualified Data.ByteString.Char8 as B8
import qualified Data.ByteString.Lazy  as LBS

import qualified Data.Text as Text 
import Data.Text.Lazy(unpack)
import Data.Text.Lazy.Encoding(encodeUtf8)
import Data.UUID (fromString,fromByteString)

import Network.HTTP.Types.Status
import Network.HTTP.Webhooq
import Data.Aeson.Types

import Data.HashMap.Strict (HashMap)
import qualified Data.HashMap.Strict as HashMap

import Control.Exception (bracket)

instance ToJSON (HashMap UUID String) where 
  toJSON m = Object (HashMap.foldrWithKey foldMap HashMap.empty m)
    where
    foldMap key val acc = HashMap.insert (Text.pack (show key)) (String (Text.pack val)) acc 

server :: IO ()
server = do
  requests <- atomically (newTMVar HashMap.empty) :: IO (TMVar (HashMap UUID String))
  server' requests

server' :: TMVar (HashMap UUID String) -> IO ()
server' requests = 
   scotty 3000 $ do
    get "/requests" $ do
      requestsMap <- liftIO $ atomically (readTMVar requests)
      json requestsMap 
    get "/:uuid" $ do
      uuidTxt <- param "uuid"
      liftIO $ putStrLn (show uuidTxt)
      case fromString $ unpack uuidTxt of 
        Nothing   -> do
          status $ Status 400 (B8.pack "Failed to parse UUID from path")
        Just uuid -> do
          addRequest requests uuid
          status status204
    notFound $ do
      status $ Status 404 (B8.pack "not found. requests should be /uuid only.")
  where
  addRequest requests requestId = do
    liftIO $ atomically $ do
      m <- readTMVar requests
      _ <- swapTMVar requests (HashMap.insert requestId "" m)
      return ()

withServer :: (TMVar (HashMap UUID String) -> IO a) -> IO a
withServer callback  = do
  requests <- atomically (newTMVar HashMap.empty) :: IO (TMVar (HashMap UUID String))
  bracket 
   (forkIO $ server' requests)
   (killThread)
   (\ _ -> threadDelay (1000000) >> callback requests) 

  

