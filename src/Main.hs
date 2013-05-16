module Main where

import Network.HTTP
import Network.HTTP.Webhooq
import Network.HTTP.Webhooq.HttpServer (withServer)

import Test.HUnit

import Control.Concurrent (threadDelay) 
import Control.Concurrent.STM (TMVar, readTMVar, atomically)

import Data.Maybe (fromJust, isJust)

import Data.UUID (UUID)

import Data.HashMap.Strict (HashMap)
import qualified Data.HashMap.Strict as HashMap

import Network.URI (parseAbsoluteURI)

import qualified Data.Text as Text

import qualified Codec.MIME.Type as Mime

import qualified Data.ByteString as ByteString
import qualified Data.ByteString.Char8 as Char8 

import Data.UUID.V4 (nextRandom)

type RequestsMap = TMVar (HashMap UUID String)

webhooqServer = WebhooqServer (fromJust (parseAbsoluteURI "http://localhost:8080"))

main  = do
  withServer (\ requests -> runTestTT (TestList [direct_exchange_round_trip requests]))

direct_exchange_round_trip :: RequestsMap -> Test 
direct_exchange_round_trip requests = TestLabel "direct_exchange_round_trip" $ TestCase $ do
   let queue_name = "test-queue"
   let exchange_name = "test-exchange"
   let routing_key = "t.e.s.t"
   uuid <- nextRandom 
   let url =  "http://localhost:3000/"++(show uuid)
   let body = Char8.pack "test-body"
   -- putStrLn url
   declareExchange webhooqServer [] Direct exchange_name []
   declareQueue webhooqServer [] queue_name []
   bindQueue webhooqServer [] exchange_name routing_key queue_name 
     (Link [LinkValue (fromJust (parseAbsoluteURI url)) [(Text.pack "rel", Text.pack "wq")]])
   publish 
     webhooqServer 
     [ mkMessageIdHeader (show uuid), Header HdrContentLength (show $ ByteString.length body) ]
     exchange_name
     routing_key
     Mime.nullType
     body 
   
   threadDelay (1 * 1000 * 1000)
   
   requestsMap <- atomically (readTMVar requests)
   assertEqual  "requests map has one entry" 1 (HashMap.size requestsMap) 
   
   let found  = HashMap.lookup uuid requestsMap 
   assertBool   "requests map contains sent UUID" (isJust found) 

   
