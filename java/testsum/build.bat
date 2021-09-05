@echo off
rem Compile all of JAVA
rem
javac.exe -version 1>NUL 2>NUL
if ERRORLEVEL 1 path "c:\Program Files\Java\jdk1.8.0_05\bin";%path%
@rem if ERRORLEVEL 1 path "c:\Program Files\Java\jdk-13.0.1\bin";%path%
@rem if ERRORLEVEL 1 path "c:\Program Files\Java\jdk-11.0.11\bin";%path%
javac.exe -verson 1>NUL 2>NUL
if ERRORLEVEL 1 echo "JAVA Environment Unavailable"
javac.exe %1
@rem javac.exe hello_world.java
@rem java -cp . Arguments
