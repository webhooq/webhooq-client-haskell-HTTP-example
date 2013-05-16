module Main where --RounTripSpec where

import Network.HTTP.Webhooq
import Network.HTTP.Webhooq.HttpServer (withServer)

import Test.HUnit
--import Test.QuickCheck
import Test.Hspec
import Test.Hspec.HUnit

import Control.Applicative
import Control.Concurrent (threadDelay) 
import Control.Concurrent.STM (TMVar, readTMVar, swapTMVar, atomically)

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
import Network.HTTP.Headers(Header(..), HeaderName( HdrContentLength ) )

type RequestsMap = TMVar (HashMap UUID String)

webhooqServer = WebhooqServer (fromJust (parseAbsoluteURI "http://localhost:8080"))

main = withServer test --hspec (withServer topic_exchange_round_trip_spec)
 where
 test requests = do
   testData <- setUp    
   hspec $ topic_exchange_round_trip_spec testData requests

topic_exchange_round_trip_spec :: TestData -> RequestsMap -> Spec 
topic_exchange_round_trip_spec testData requests = describe "A Topic Exchange" $ do 
  it "routes a message with key 'a.b.c.d' into every queue" $ do
      -- reset the requests map
      atomically (swapTMVar requests HashMap.empty)
      -- generate a new random message id for this test, use it in text form as a random message body
      message_id <- nextRandom
      let message_body = Char8.pack (show message_id)
      -- publish a message to the Webhooq broker
      publish 
        webhooqServer 
        [ mkMessageIdHeader (show message_id), Header HdrContentLength (show $ ByteString.length message_body) ]
        (show $ exchange_A testData)
        "a.b.c.d" 
        Mime.nullType
        message_body 
      -- wait for the broker to deliver to the message to our queues
      threadDelay(2*1000000)
      -- get the map of request call backs made
      requestsMap <- atomically (readTMVar requests)
      -- ensure we got the correct number of requests 
      assertEqual  "requests map has seven entries" 7 (HashMap.size requestsMap) 
      -- verify we got the requests we expected 
      let label   = (\ u q -> "requests map contains request for " ++ q ++ " UUID (" ++ (show u) ++ ")") 
      ((assertBool (label (queue_1 testData) "queue_1")) . isJust . (HashMap.lookup (queue_1 testData))) requestsMap  
      ((assertBool (label (queue_2 testData) "queue_2")) . isJust . (HashMap.lookup (queue_2 testData))) requestsMap 
      ((assertBool (label (queue_3 testData) "queue_3")) . isJust . (HashMap.lookup (queue_3 testData))) requestsMap
      ((assertBool (label (queue_4 testData) "queue_4")) . isJust . (HashMap.lookup (queue_4 testData))) requestsMap
      ((assertBool (label (queue_5 testData) "queue_5")) . isJust . (HashMap.lookup (queue_5 testData))) requestsMap
      ((assertBool (label (queue_6 testData) "queue_6")) . isJust . (HashMap.lookup (queue_6 testData))) requestsMap
      ((assertBool (label (queue_7 testData) "queue_7")) . isJust . (HashMap.lookup (queue_7 testData))) requestsMap
  
  -- + -- + -- + -- + -- + -- 
 
  it "route a message with key 'b.c.d.a' only into queue_1" $ do
      -- reset the requests map
      atomically (swapTMVar requests HashMap.empty)
      -- generate a new random message id for this test, use it in text form as a random message body
      message_id <- nextRandom
      let message_body = Char8.pack (show message_id)
      -- publish a message to the Webhooq broker
      publish 
        webhooqServer 
        [ mkMessageIdHeader (show message_id), Header HdrContentLength (show $ ByteString.length message_body) ]
        (show $ exchange_A testData)
        "b.c.d.a" 
        Mime.nullType
        message_body 
      -- wait for the broker to deliver to the message to our queues
      threadDelay(2*1000000)
      -- get the map of request call backs made
      requestsMap <- atomically (readTMVar requests)
      -- ensure we got the correct number of requests 
      assertEqual  "requests map has seven entries" 1 (HashMap.size requestsMap) 
      -- verify we got the requests we expected 
      let label   = (\ u q -> "requests map contains request for " ++ q ++ " UUID (" ++ (show u) ++ ")") 
      ((assertBool (label (queue_1 testData) "queue_1")) . isJust . (HashMap.lookup (queue_1 testData))) requestsMap  

  -- + -- + -- + -- + -- + -- 

  it "route a message with key 'a.b' only into queues 1, 3, and 5" $ do
      -- reset the requests map
      atomically (swapTMVar requests HashMap.empty)
      -- generate a new random message id for this test, use it in text form as a random message body
      message_id <- nextRandom
      let message_body = Char8.pack (show message_id)
      -- publish a message to the Webhooq broker
      publish 
        webhooqServer 
        [ mkMessageIdHeader (show message_id), Header HdrContentLength (show $ ByteString.length message_body) ]
        (show $ exchange_A testData)
        "a.b" 
        Mime.nullType
        message_body 
      -- wait for the broker to deliver to the message to our queues
      threadDelay(2*1000000)
      -- get the map of request call backs made
      requestsMap <- atomically (readTMVar requests)
      -- ensure we got the correct number of requests 
      assertEqual  "requests map has seven entries" 3 (HashMap.size requestsMap) 
      -- verify we got the requests we expected 
      let label   = (\ u q -> "requests map contains request for " ++ q ++ " UUID (" ++ (show u) ++ ")") 
      ((assertBool (label (queue_1 testData) "queue_1")) . isJust . (HashMap.lookup (queue_1 testData))) requestsMap  
      ((assertBool (label (queue_3 testData) "queue_3")) . isJust . (HashMap.lookup (queue_3 testData))) requestsMap
      ((assertBool (label (queue_5 testData) "queue_5")) . isJust . (HashMap.lookup (queue_5 testData))) requestsMap
  
  -- + -- + -- + -- + -- + -- 

  it "route a message with key 'a.c.b.d' only into queues 1, 3, 5 and 6" $ do
      -- reset the requests map
      atomically (swapTMVar requests HashMap.empty)
      -- generate a new random message id for this test, use it in text form as a random message body
      message_id <- nextRandom
      let message_body = Char8.pack (show message_id)
      -- publish a message to the Webhooq broker
      publish 
        webhooqServer 
        [ mkMessageIdHeader (show message_id), Header HdrContentLength (show $ ByteString.length message_body) ]
        (show $ exchange_A testData)
        "a.c.b.d" 
        Mime.nullType
        message_body 
      -- wait for the broker to deliver to the message to our queues
      threadDelay(2*1000000)
      -- get the map of request call backs made
      requestsMap <- atomically (readTMVar requests)
      -- ensure we got the correct number of requests 
      assertEqual  "requests map has seven entries" 4 (HashMap.size requestsMap) 
      -- verify we got the requests we expected 
      let label   = (\ u q -> "requests map contains request for " ++ q ++ " UUID (" ++ (show u) ++ ")") 
      ((assertBool (label (queue_1 testData) "queue_1")) . isJust . (HashMap.lookup (queue_1 testData))) requestsMap  
      ((assertBool (label (queue_3 testData) "queue_3")) . isJust . (HashMap.lookup (queue_3 testData))) requestsMap
      ((assertBool (label (queue_5 testData) "queue_5")) . isJust . (HashMap.lookup (queue_5 testData))) requestsMap
      ((assertBool (label (queue_6 testData) "queue_6")) . isJust . (HashMap.lookup (queue_6 testData))) requestsMap
  
  -- + -- + -- + -- + -- + -- 
 
  it "route a message with key 'a.z.c.d' only into queues 1, 2, 3, 5 and 6" $ do
      -- reset the requests map
      atomically (swapTMVar requests HashMap.empty)
      -- generate a new random message id for this test, use it in text form as a random message body
      message_id <- nextRandom
      let message_body = Char8.pack (show message_id)
      -- publish a message to the Webhooq broker
      publish 
        webhooqServer 
        [ mkMessageIdHeader (show message_id), Header HdrContentLength (show $ ByteString.length message_body) ]
        (show $ exchange_A testData)
        "a.z.c.d" 
        Mime.nullType
        message_body 
      -- wait for the broker to deliver to the message to our queues
      threadDelay(2*1000000)
      -- get the map of request call backs made
      requestsMap <- atomically (readTMVar requests)
      -- ensure we got the correct number of requests 
      assertEqual  "requests map has seven entries" 5 (HashMap.size requestsMap) 
      -- verify we got the requests we expected 
      let label   = (\ u q -> "requests map contains request for " ++ q ++ " UUID (" ++ (show u) ++ ")") 
      ((assertBool (label (queue_1 testData) "queue_1")) . isJust . (HashMap.lookup (queue_1 testData))) requestsMap  
      ((assertBool (label (queue_2 testData) "queue_2")) . isJust . (HashMap.lookup (queue_2 testData))) requestsMap 
      ((assertBool (label (queue_3 testData) "queue_3")) . isJust . (HashMap.lookup (queue_3 testData))) requestsMap
      ((assertBool (label (queue_5 testData) "queue_5")) . isJust . (HashMap.lookup (queue_5 testData))) requestsMap
      ((assertBool (label (queue_6 testData) "queue_6")) . isJust . (HashMap.lookup (queue_6 testData))) requestsMap
  
  -- + -- + -- + -- + -- + -- 
   
  it "route a message with key 'a.b.z.d' only into queues 1, 3, 5, 6 and 7" $ do
      -- reset the requests map
      atomically (swapTMVar requests HashMap.empty)
      -- generate a new random message id for this test, use it in text form as a random message body
      message_id <- nextRandom
      let message_body = Char8.pack (show message_id)
      -- publish a message to the Webhooq broker
      publish 
        webhooqServer 
        [ mkMessageIdHeader (show message_id), Header HdrContentLength (show $ ByteString.length message_body) ]
        (show $ exchange_A testData)
        "a.b.z.d" 
        Mime.nullType
        message_body 
      -- wait for the broker to deliver to the message to our queues
      threadDelay(2*1000000)
      -- get the map of request call backs made
      requestsMap <- atomically (readTMVar requests)
      -- ensure we got the correct number of requests 
      assertEqual  "requests map has seven entries" 5 (HashMap.size requestsMap) 
      -- verify we got the requests we expected 
      let label   = (\ u q -> "requests map contains request for " ++ q ++ " UUID (" ++ (show u) ++ ")") 
      ((assertBool (label (queue_1 testData) "queue_1")) . isJust . (HashMap.lookup (queue_1 testData))) requestsMap  
      ((assertBool (label (queue_3 testData) "queue_3")) . isJust . (HashMap.lookup (queue_3 testData))) requestsMap
      ((assertBool (label (queue_5 testData) "queue_5")) . isJust . (HashMap.lookup (queue_5 testData))) requestsMap
      ((assertBool (label (queue_6 testData) "queue_6")) . isJust . (HashMap.lookup (queue_6 testData))) requestsMap
      ((assertBool (label (queue_7 testData) "queue_7")) . isJust . (HashMap.lookup (queue_7 testData))) requestsMap
  
  -- + -- + -- + -- + -- + -- 
  
    
    
     
data TestData = TestData
  { exchange_A :: UUID
  , exchange_B :: UUID
  , exchange_C :: UUID
  , exchange_D :: UUID
  , queue_1    :: UUID
  , queue_2    :: UUID
  , queue_3    :: UUID
  , queue_4    :: UUID
  , queue_5    :: UUID
  , queue_6    :: UUID
  , queue_7    :: UUID 

  , exchange_B_route :: String 
  , queue_1_route    :: String
  , queue_2_route    :: String
  , queue_4_route    :: String
  , queue_5_route    :: String
  , queue_6_route    :: String 
  , queue_7_route    :: String
  } deriving (Show)
   
setUp :: IO TestData 
setUp = do
  td <- TestData <$> uuid <*> uuid <*> uuid <*> uuid <*> uuid <*> uuid <*> uuid <*> uuid <*> uuid <*> uuid <*> uuid <*> (pure "a.#") <*> (pure "#") <*> (pure "a.*.c.d") <*> (pure"a.b.c.d") <*> (pure "#") <*> (pure "a.*.*.d") <*> (pure "*.b.*.d")

  declareExchange webhooqServer [] Topic  (show $ exchange_A td) []
  declareExchange webhooqServer [] Fanout (show $ exchange_B td) []
  declareExchange webhooqServer [] Topic  (show $ exchange_C td) []
  declareExchange webhooqServer [] Direct (show $ exchange_D td) []
                      
  declareQueue webhooqServer [] (show $ queue_1 td) []
  declareQueue webhooqServer [] (show $ queue_2 td) []
  declareQueue webhooqServer [] (show $ queue_3 td) []
  declareQueue webhooqServer [] (show $ queue_4 td) []
  declareQueue webhooqServer [] (show $ queue_5 td) []
  declareQueue webhooqServer [] (show $ queue_6 td) []
  declareQueue webhooqServer [] (show $ queue_7 td) []

  bindExchange webhooqServer [] (show $ exchange_A td) (exchange_B_route td) (show $ exchange_B td)
  bindQueue    webhooqServer [] (show $ exchange_A td) (queue_1_route td)    (show $ queue_1 td)    (callbackURL $ queue_1 td)
  bindQueue    webhooqServer [] (show $ exchange_A td) (queue_2_route td)    (show $ queue_2 td)    (callbackURL $ queue_2 td)

  bindExchange webhooqServer [] (show $ exchange_B td) emptyRoute            (show $ exchange_C td)
  bindExchange webhooqServer [] (show $ exchange_B td) emptyRoute            (show $ exchange_D td)
  bindQueue    webhooqServer [] (show $ exchange_B td) emptyRoute            (show $ queue_3 td)    (callbackURL $ queue_3 td)

  bindQueue    webhooqServer [] (show $ exchange_C td) (queue_5_route td)    (show $ queue_5 td)    (callbackURL $ queue_5 td)
  bindQueue    webhooqServer [] (show $ exchange_C td) (queue_6_route td)    (show $ queue_6 td)    (callbackURL $ queue_6 td)
  bindQueue    webhooqServer [] (show $ exchange_C td) (queue_7_route td)    (show $ queue_7 td)    (callbackURL $ queue_7 td)
  
  bindQueue    webhooqServer [] (show $ exchange_D td) (queue_4_route td)    (show $ queue_4 td)    (callbackURL $ queue_4 td)
  return td 
  where 
  callbackURL uuid = link $ "http://localhost:3000/"++(show uuid)
  link url = Link [LinkValue (fromJust (parseAbsoluteURI url)) [(Text.pack "rel", Text.pack "wq")]]
  emptyRoute  = ""
  uuid = nextRandom      
 
{-
 
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
-}
 
