{-# LANGUAGE GADTs #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE StandaloneKindSignatures #-}

module Main where

-- import Data.Kind (Type)  -- Not needed for this version
import Unsafe.Coerce (unsafeCoerce)

-- Two households, both alike in dignity
data House = Montague | Capulet

-- An involution: apply it twice and you're back
type family Opposite (h :: House) :: House where
    Opposite Montague = Capulet
    Opposite Capulet  = Montague

-- Verify involution property
-- Opposite (Opposite Montague) = Opposite Capulet = Montague ✓
-- Opposite (Opposite Capulet) = Opposite Montague = Capulet ✓

-- People carry their allegiance as type-level branding
data Person (h :: House) where
    Romeo    :: Person Montague
    Juliet   :: Person Capulet
    Tybalt   :: Person Capulet
    Mercutio :: Person Montague

-- The ancient grudge as a type-level constraint
class Grudge (a :: House) (b :: House)
instance Grudge Montague Capulet
instance Grudge Capulet Montague
-- No instance for Grudge Montague Montague - you cannot feud with yourself

-- Violence is a well-typed interaction between opposing houses
data Conflict = Conflict deriving (Eq, Show)

quarrel :: (Grudge h1 h2) => Person h1 -> Person h2 -> Conflict
quarrel _ _ = Conflict

-- Example: Tybalt quarrels with Mercutio
tybaltMercutio :: Conflict
tybaltMercutio = quarrel Tybalt Mercutio

-- What Verona permits: marriage within the same house
data Marriage (h :: House) = Marriage

marry :: Person h -> Person h -> Marriage h
marry _ _ = Marriage

-- This would be a type error (uncomment to see):
-- romeo_and_juliet = marry Romeo Juliet
-- ERROR: Couldn't match Montague with Capulet

-- The Friar performs unsafeCoerce
-- Returns a Marriage in the first person's house, achieved via unsafeCoerce
friarLawrence :: Person h1 -> Person (Opposite h1) -> Marriage h1
friarLawrence p1 p2 = unsafeCoerce (marry p1 (unsafeCoerce p2 :: Person h1))

-- Fate as phantom type
data Star = Crossed | Uncrossed

data Lover (s :: Star) (h :: House) where
    StarCrossedLover :: Person h -> Lover Crossed h
-- No constructor for Uncrossed

-- Death erases the type parameter
data Death = Death deriving (Eq, Show)

die :: Person h -> Death
die _ = Death

-- In death, all are equal
romeoDies :: Death
romeoDies = die Romeo

julietDies :: Death
julietDies = die Juliet

-- The play's acts
data Act where
    Prologue    :: Star -> Act
    Rising      :: Person h1 -> Person (Opposite h1) -> Act
    Catastrophe :: Person h -> Death -> Act
    Resolution  :: House -> House -> Act

-- The tragedy as a program
play :: [Act]
play = [ Prologue Crossed
       , Rising Romeo Juliet
       , Catastrophe Romeo Death
       , Catastrophe Juliet Death
       , Resolution Montague Capulet ]

-- Verify the rising action requires Grudge constraint
risingAction :: Act
risingAction = Rising Romeo Juliet

-- Main function for testing
main :: IO ()
main = do
    putStrLn "Romeo and Juliet Type System Test"
    putStrLn $ "Tybalt vs Mercutio: " ++ show (tybaltMercutio == Conflict)
    putStrLn $ "Romeo dies: " ++ show (romeoDies == Death)
    putStrLn $ "Juliet dies: " ++ show (julietDies == Death)
    putStrLn $ "Play has " ++ show (length play) ++ " acts"
    putStrLn "All type checks pass!"
