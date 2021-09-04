/* 
  Search and replace pattern per file
  2021 (c) Dmitry Stefankov 
*/

using System;
using System.IO;
using System.Text;
//using CommandLine;


class Program {

   public static int GetHexVal(char hex) {
        int val = (int)hex;
        //For uppercase A-F letters:
        //return val - (val < 58 ? 48 : 55);
        //For lowercase a-f letters:
        //return val - (val < 58 ? 48 : 87);
        //Or the two combined, but a bit slower:
        return val - (val < 58 ? 48 : (val < 97 ? 55 : 87));
    }

    public static byte[] StringToByteArrayFastest(string hex) {
        if (hex.Length % 2 == 1)
            throw new Exception("The binary key cannot have an odd number of digits");

        byte[] arr = new byte[hex.Length >> 1];

        for (int i = 0; i < hex.Length >> 1; ++i)
        {
            arr[i] = (byte)((GetHexVal(hex[i << 1]) << 4) + (GetHexVal(hex[(i << 1) + 1])));
        }

        return arr;
    }

    private static int NewFindBytes(byte[] src, byte[] find)
    {
        int index = -1;
        int matchIndex = 0;
        // handle the complete source array
        for (int i = 0; i < src.Length; i++)
        {
            if (src[i] == find[matchIndex])
            {
                if (matchIndex == (find.Length - 1))
                {
                    index = i - matchIndex;
                    break;
                }
                matchIndex++;
            }
            else
            {
                matchIndex = 0;
            }

        }
        return index;
    }

    public static byte[] NewReplaceBytes(byte[] src, byte[] search, byte[] repl)
    {
        byte[] dst = null;
        byte[] temp = null;
        int index = NewFindBytes(src, search);
        while (index >= 0)
        {
            if (temp == null)
                temp = src;
            else
                temp = dst;

            dst = new byte[temp.Length - search.Length + repl.Length];

            // before found array
            Buffer.BlockCopy(temp, 0, dst, 0, index);
            // repl copy
            Buffer.BlockCopy(repl, 0, dst, index, repl.Length);
            // rest of src array
            Buffer.BlockCopy(
                temp,
                index + search.Length,
                dst,
                index + repl.Length,
                temp.Length - (index + search.Length));


            index = NewFindBytes(dst, search);
        }
        return dst;
    }

    static int Main(string[] args)
    {
        // Display the number of command line arguments:
        // String ProgramFilename = args[0];
        Console.WriteLine();
        // Invoke this program with an arbitrary set of command line arguments.
        string[] arguments = Environment.GetCommandLineArgs();
        Console.WriteLine("GetCommandLineArgs: {0}", string.Join(", ", arguments));

        System.Console.WriteLine(args.Length);
        if (args.Length < 4) {
           Console.WriteLine("Search and replace hexdec. pattern per file, version 1.0");
           Console.WriteLine("Copyright (C) 2021 Dmitry Stefankov. All Rights Reserved.");
           Console.WriteLine("Usage : findrep <InFileName> <OutFileName> <SrchPat> <RplPat> <ask>");
           return 1;
        }

        String InFilename = args[0];
        String OutFilename = args[1];
        string HexSearchPattern = args[2];
        string HexReplacePattern = args[3];
        byte[] SearchPatternData = StringToByteArrayFastest(HexSearchPattern);
        byte[] ReplacePatternData = StringToByteArrayFastest(HexReplacePattern);
        bool ask = false;
        if (args.Length > 4) ask = true;

        Console.WriteLine("InFileName: {0}, OutFileName: {1}, SrchPat={2}, ReplPat={3}, Ask={4}", 
                          InFilename, OutFilename, HexSearchPattern, HexReplacePattern, ask );

        byte[] ByteReadBuffer = File.ReadAllBytes(InFilename);
        byte[] resultWriteBytes = NewReplaceBytes(ByteReadBuffer, SearchPatternData, ReplacePatternData);
        File.WriteAllBytes(OutFilename, resultWriteBytes);

        return 0;
    }

}
