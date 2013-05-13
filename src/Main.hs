module Main where

import Network.HTTP
import Network.HTTP.Webhooq
import Network.HTTP.Webhooq.HttpServer (withServer)
import Test.HUnit
import Control.Concurrent

import Control.Concurrent.STM

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
  withServer (\ requests -> runTestTT (TestList [testcase requests]))


testcase :: RequestsMap -> Test 
testcase requests = TestLabel "testcase" $ TestCase $ do
   uuid <- nextRandom 
   let url =  "http://localhost:3000/"++(show uuid)
   let body = Char8.pack "test-body"
   -- putStrLn url
   declareExchange webhooqServer [] Direct "test-exchange" []
   declareQueue webhooqServer [] "test-queue" []
   bindQueue webhooqServer [] "test-exchange" "t.e.s.t" "test-queue" 
     (Link [LinkValue (fromJust (parseAbsoluteURI url)) [(Text.pack "rel", Text.pack "wq")]])
   publish 
     webhooqServer 
     [ mkMessageIdHeader (show uuid), Header HdrContentLength (show $ ByteString.length body) ]
     "test-exchange"
     "t.e.s.t"
     Mime.nullType
     body 
   
   threadDelay (1 * 1000 * 1000)
   
   requestsMap <- atomically (readTMVar requests)
   assertEqual  "requests map has one entry" 1 (HashMap.size requestsMap) 
   
   let found  = HashMap.lookup uuid requestsMap 
   assertBool   "requests map contains sent UUID" (isJust found) 
   
