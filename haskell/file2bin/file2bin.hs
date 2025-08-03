--
-- Extract binary portion from file, version 1.0
-- Copyright (C) 2025 Dmitry Stefankov. All Rights Reserved.
--

module Main (main) where

import Control.Monad
import Control.Monad.Except
import System.Console.GetOpt
import System.Environment(getArgs, getProgName)
import System.IO
import System.Exit
import Data.Char (isSpace)
import Data.Word
import Data.Binary.Get
import Data.Binary.Put
import Data.ByteString(readFile)
import qualified Data.ByteString as B
import Data.Char (isSpace)

data Options = Options {
    optVerbose :: Bool
  , optShowVersion :: Bool
  , optInputFilename :: String
  , optOutputFilename :: String
  , optOffset :: Int
  , optBytes :: Int
  } deriving Show

defaultOptions = Options {
    optShowVersion = False 
  , optVerbose = False
  , optInputFilename = ""
  , optOutputFilename = ""
  , optOffset = 0
  , optBytes = 0
  }

options :: [OptDescr (Options -> Either String Options)]
options =
  [ Option ['i'] ["infile"]
        (ReqArg (\arg opts -> Right opts { optInputFilename = return arg !! 0 } -- really dirty, sorry but could not make it work another way
        ) "INFILE")
        "input filename"
  , Option ['o'] ["outfile"]
        (ReqArg (\arg opts -> Right opts { optOutputFilename = return arg !! 0 } -- really dirty, sorry but could not make it work another way
        ) "OUTFILE")
        "output filename"
  , Option ['l'] ["offset"]
      (ReqArg (\l opts ->
        case reads l of
          [(offset, "")] | offset >= 0 -> Right opts { optOffset = offset }
          _ -> Left "--input offset value must be a number zero or greater"
        ) "OFFSET")
      "byte offset on input stream"
  , Option ['s'] ["bytes"]
      (ReqArg (\s opts ->
        case reads s of
          [(bytes, "")] | bytes >= 0 -> Right opts { optBytes = bytes }
          _ -> Left "--copy bytes value must be a number zero or greater"
        ) "BYTES")
      "copy N bytes from input stream"
  , Option ['V','?'] ["version"]
        (NoArg (\ opts -> Right opts { optShowVersion = True }))  -- here no need for a value for this option because of `NoArg`
        "show version number"
  , Option ['v'] ["verbose"]
      (NoArg (\opts -> Right opts { optVerbose = True }))
      "verbose output"
  ]

parseArgs :: IO Options
parseArgs = do
  argv <- getArgs
  progName <- getProgName
  putStrLn progName
  -- putStrLn show (length progName)
  let header = "Usage: " ++ progName ++ " [OPTION...]"
  let helpMessage = usageInfo header options
  case getOpt RequireOrder options argv of
    (opts, [], []) ->
      case foldM (flip id) defaultOptions opts of
        Right opts -> return opts
        Left errorMessage -> ioError (userError (errorMessage ++ "\n" ++ helpMessage))
    (_, _, errs) -> ioError (userError (concat errs ++ helpMessage))


main :: IO ()
main = do

  putStrLn "Extract binary portion from file, version 1.0"
  putStrLn "Copyright (C) 2025 Dmitry Stefankov. All Rights Reserved."

  options <- parseArgs
  putStrLn $ show options

  let infile  = optInputFilename options
  let outfile = optOutputFilename options
  ---putStrLn $ "outfile: " ++ outfile
  let inoffset = optOffset options
  let inbytes = optBytes options
  let in_big_ofs = toInteger inoffset :: Integer

  let b1 = null (dropWhile isSpace infile)
  let b2 = null (dropWhile isSpace outfile)
  if b1 == True
    then exitWith ExitSuccess else putStrLn $ "infile: " ++ infile
  if b2 == True
    then exitWith ExitSuccess else putStrLn $ "outfile: " ++ outfile

  ihandle <- openBinaryFile infile ReadMode
  hSeek ihandle AbsoluteSeek in_big_ofs
  inputBytes <- B.hGetContents ihandle
  hClose ihandle

  B.writeFile outfile inputBytes
  let out_big_ofs = toInteger inbytes :: Integer
  ohandle <- openBinaryFile outfile ReadWriteMode
  ---hSeek ohandle AbsoluteSeek out_big_ofs
  hSetFileSize ohandle (toInteger out_big_ofs)
  hClose ohandle

  ---putStrLn $ "Successfully wrote " ++ show (B.length inputBytes) ++ " bytes to " ++ outfile

  putStrLn "All done."
