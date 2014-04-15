{-# OPTIONS_GHC -Wall                      #-}
{-# OPTIONS_GHC -fno-warn-name-shadowing   #-}
{-# OPTIONS_GHC -fno-warn-type-defaults    #-}
{-# OPTIONS_GHC -fno-warn-unused-do-bind   #-}
{-# OPTIONS_GHC -fno-warn-missing-methods  #-}
{-# OPTIONS_GHC -fno-warn-orphans          #-}

module Main (main) where

import Test.HUnit hiding (Test)
import Test.QuickCheck hiding ((.&.))
import Test.Framework ( Test, defaultMain )
import Test.Framework.Providers.QuickCheck2 (testProperty)
import Test.Framework.Providers.HUnit
import Data.LargeWord
import Data.Bits
import Control.Monad
import Data.Binary (encode, decode, Binary)
import qualified Data.ByteString.Lazy as LZ

instance (Arbitrary a, Arbitrary b) => Arbitrary (LargeKey a b) where
   arbitrary = liftM2 LargeKey arbitrary arbitrary

pShiftRightShiftLeft :: Word128 -> Bool
pShiftRightShiftLeft x = shiftR (shiftL x 1) 1 == x .&. (fromInteger ((2^127) - 1))

u1 :: Assertion
u1 = shiftR (18446744073709551616  :: Word128) 64  @?= 1

pQuotRem :: Word256 -> Bool
pQuotRem x = rx == fromInteger ry
  where
    (_qx, rx) = quotRem x 16
    (_qy, ry) = quotRem ((fromIntegral x) :: Integer) 16

encodeDecode :: (Binary a, Binary b, Eq a, Eq b) => LargeKey a b -> Bool
encodeDecode word = decode encoded == word
	where
	encoded = encode word
	{-# NOINLINE encoded #-}

correctEncoding :: Assertion
correctEncoding = (decode . LZ.pack)
	[0,0,0,0,0,0,0,0,50,89,125,125,237,119,73,240
        ,217,12,178,101,235,8,44,221,50,122,244,125,115,181,239,78]
	@?=
	(1234567891234567891234567812345678123456781234567812345678 :: Word256)

u2 :: Assertion
u2 = (2 :: LargeKey Word256 Word128) ^ 254 @?=
     (fromInteger (2 :: Integer) ^ 254)

tests :: [Test]
tests =
    [ testProperty "largeword shift left then right" pShiftRightShiftLeft
    , testProperty "largeword quotRem by 16" pQuotRem
    , testCase "largeword shift 2^64 by 2^64" u1
    , testCase "largeword exponentiation 2^254" u2
    , testCase "big-endian encoding" correctEncoding
    , testProperty "Word96 encode/decode loop" (encodeDecode::Word96 -> Bool)
    , testProperty "Word128 encode/decode loop" (encodeDecode::Word128 -> Bool)
    , testProperty "Word160 encode/decode loop" (encodeDecode::Word160 -> Bool)
    , testProperty "Word192 encode/decode loop" (encodeDecode::Word192 -> Bool)
    , testProperty "Word224 encode/decode loop" (encodeDecode::Word224 -> Bool)
    , testProperty "Word256 encode/decode loop" (encodeDecode::Word256 -> Bool)
      ]

main :: IO ()
main = defaultMain tests
