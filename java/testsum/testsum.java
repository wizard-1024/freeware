//
// Build checksums per file
// Copyright (C) 2021 Dmitry Stefankov
//

import java.io.*;
import java.util.List;
import java.util.Date;
import java.nio.charset.Charset;
import java.nio.file.*;
import java.util.zip.*;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import javax.xml.bind.DatatypeConverter;
import java.math.BigInteger;

public class testsum {

  public static byte[] MyReadAllBytes(String filename) throws IOException {
	Path file = Paths.get(filename);
	return Files.readAllBytes(file);
  }

  public static String sha256(final byte[] base) {
    try{
        final MessageDigest digest = MessageDigest.getInstance("SHA-256");
        final byte[] hash = digest.digest(base);
        final StringBuilder hexString = new StringBuilder();
        for (int i = 0; i < hash.length; i++) {
            final String hex = Integer.toHexString(0xff & hash[i]);
            if(hex.length() == 1) 
              hexString.append('0');
            hexString.append(hex);
        }
        return hexString.toString();
    } catch(Exception ex){
       throw new RuntimeException(ex);
    }
  }

  public static String bytesToHex(byte[] bytes) {
    StringBuffer result = new StringBuffer();
    for (byte b : bytes) result.append(Integer.toString((b & 0xff) + 0x100, 16).substring(1));
    return result.toString();
  }

  public static void ListDir (String dirname, int hashsize) throws IOException {

    File dir=new File(dirname);
    File files[]=dir.listFiles();//files array stores the list of files

    for(int i=0;i<files.length;i++)
    {
        if(files[i].isFile()) //check whether files[i] is file or directory
        {
            String FullFileName = dirname+"\\"+files[i].getName();
            File file = new File(FullFileName);
            long file_size = file.length();
            long t = file.lastModified();
            Date d = new Date(t);
            System.out.print("filename=\""+FullFileName+"\"");
            if (file_size < 1024*1024*512) {
              byte[] ReadBuffer = MyReadAllBytes(FullFileName);
              CRC32 myCRC = new CRC32( );
              myCRC.update( ReadBuffer );
              //System.out.println("  datetime=\""+d.toString()+"\""+"  size=\""+file_size+"\""+"  filename=\""+files[i].getName()+"\"");
              System.out.print("  crc32=\"0x"+Long.toHexString(myCRC.getValue())+"\"");
              try {
                  MessageDigest md = MessageDigest.getInstance("MD5");
                  //md.update(Files.readAllBytes(FullFileName));
                  md.update(ReadBuffer);
                  byte[] digest = md.digest();
                  String myChecksum = DatatypeConverter.printHexBinary(digest).toUpperCase();
                  System.out.print("  md5=\"0x"+myChecksum+"\"");
              } catch (NoSuchAlgorithmException e) {
                  throw new IllegalStateException(e);
              }
              try {
                  MessageDigest md = MessageDigest.getInstance("SHA1");
                  md.update(ReadBuffer);
                  byte[] digest = md.digest();
                  String myChecksum = DatatypeConverter.printHexBinary(digest).toUpperCase();
                  System.out.print("  sha1=\"0x"+myChecksum+"\"");
              } catch (NoSuchAlgorithmException e) {
                  throw new IllegalStateException(e);
              }
              if (hashsize == 224) {
                try {
                  // getInstance() method is called with algorithm SHA-224
                  MessageDigest md = MessageDigest.getInstance("SHA-224");
                  // digest() method is called
                  // to calculate message digest of the input string
                  // returned as array of byte
                  byte[] messageDigest = md.digest(ReadBuffer);
                  // Convert byte array into signum representation
                  BigInteger no = new BigInteger(1, messageDigest);
                  // Convert message digest into hex value
                  String hashtext = no.toString(16);
                  // Add preceding 0s to make it 32 bit
                  while (hashtext.length() < 32) { hashtext = "0" + hashtext; }
                  System.out.print("  sha2(224)=\"0x"+hashtext+"\"");
                }
                // For specifying wrong message digest algorithms
                catch (NoSuchAlgorithmException e) {
                   throw new RuntimeException(e);
                }
              }
              if (hashsize == 256) {
                String myChecksum = sha256(ReadBuffer);
                System.out.print("  sha2(256)=\"0x"+myChecksum+"\"");
              }
              if (hashsize == 384) {
                try {
                  // getInstance() method is called with algorithm SHA-384
                  MessageDigest md = MessageDigest.getInstance("SHA-384");
                  // digest() method is called
                  // to calculate message digest of the input string
                  // returned as array of byte
                  byte[] messageDigest = md.digest(ReadBuffer);
                  // Convert byte array into signum representation
                  BigInteger no = new BigInteger(1, messageDigest);
                  // Convert message digest into hex value
                  String hashtext = no.toString(16);
                  // Add preceding 0s to make it 32 bit
                  while (hashtext.length() < 32) { hashtext = "0" + hashtext; }
                  System.out.print("  sha2(384)=\"0x"+hashtext+"\"");
                }
                // For specifying wrong message digest algorithms
                catch (NoSuchAlgorithmException e) {
                   throw new RuntimeException(e);
                }
              }
              if (hashsize == 512) {
                try {
                  // getInstance() method is called with algorithm SHA-512
                  MessageDigest md = MessageDigest.getInstance("SHA-512");
                  // digest() method is called
                  // to calculate message digest of the input string
                  // returned as array of byte
                  byte[] messageDigest = md.digest(ReadBuffer);
                  // Convert byte array into signum representation
                  BigInteger no = new BigInteger(1, messageDigest);
                  // Convert message digest into hex value
                  String hashtext = no.toString(16);
                  // Add preceding 0s to make it 32 bit
                  while (hashtext.length() < 32) { hashtext = "0" + hashtext; }
                  System.out.print("  sha2(512)=\"0x"+hashtext+"\"");
                }
                // For specifying wrong message digest algorithms
                catch (NoSuchAlgorithmException e) {
                   throw new RuntimeException(e);
                }
              }
            }
            System.out.println();
            //System.out.println();

        }
        else if(files[i].isDirectory())
        {
            //System.out.println("Directory::"+files[i].getName());
            //System.out.println(dirname+"\\"+files[i].getName());
            //System.out.println();
            ListDir(files[i].getAbsolutePath(),hashsize);
        }
    }
  }

  public static void main(String[] args) throws IOException {
     //System.out.println("There are " + args.length + " arguments given.");
     //for(int i = 0; i < args.length; i++) 
    //    System.out.println("The argument #" + (i+1) + " is " + args[i] + " and is at index " + i);
     if (args.length < 2) {
       System.out.println("Build checksums per file, version 1.0");
       System.out.println("Copyright (c) 2021, Dmitry Stefankov");
       System.out.println("Usage: testsum.exe dirname hashsize");
       return;
     }
 
     String MainDir = args[0];
     int hashsize = 224;
     try {
       hashsize = Integer.parseInt(args[1]);
       System.out.println("HashSize: "+hashsize);
     }
     catch (NumberFormatException ex){
        ex.printStackTrace();
     }

     ListDir(MainDir,hashsize);
  }

}
