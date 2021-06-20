{-----------------------------------------------------------------------}
{ PROJECT		NON-PROFIT HIGH QUALITY PROFESSIONAL SOFTWARE,  }
{			AVAILABLE FOR ALL WORLD				}
{ LIBRARY		SYSTEM UTILITIES                                }
{ MODULE		MULTIPLE-OPERATING-SYSTEMS-LOADER               }
{ FILE NAME		OS-BOOT.PAS					}
{ PURPOSE		OS-loader from the fixed disk                   }
{ VERSION		1.30						}
{ DATE			18-Oct-93					}
{ DESIGN		Dmitry Stefankov				}
{ IMPLEMENTATION	Dmitry Stefankov 				}
{ COMPANY		Freelance Software Engineer			}
{ ADDRESS		Isakowskogo str, 4-2-30				}
{			Moscow, 123181					}
{			USSR						}
{			Tel. 007 (095) 944-6304				}
{ COPYRIGHT NOTICE	Copyright (C) 1987-1993, Dmitry Stefankov	}
{ RESTRICTED RIGHTS	AVAILABLE ONLY FOR FREE DISTRIBUTION,           }
{			NOT FOR COMMERCIAL PURPOSE			}
{ COMPUTER		IBM PC or compatible				}
{ OPERATING SYSTEM	MS/PC-DOS Version 3.30 or higher		}
{ COMPILER		Turbo Pascal Version 6.0			}
{                       (Borland International Inc.)  or compatible     }
{ ASSEMBLY LANGUAGE	Microsoft MASM 5.10 or compatible               }
{ LINKER		Turbo Pascal internal                           }
{ ARGUMENTS		None                                            }
{ RETURN		See error return codes definitions		}
{ REQUIRES		Source Code Files                               }
{                       NONE                                            }
{                       External Object Files                           }
{                       NONE                                            }
{			Maintence Project Files				}
{			NONE						}
{ NATURAL LANGUAGE      English Language                             	}
{ SPECIAL		None						}
{ DESCRIPTION		1. Read Master Boot Record.                     }
{			1a. If our loader present then copy some info	}
{			    by user confirming				} 
{			2. Extract the Partition Table from it and	}
{			   link with new loader code. 			}
{			3. Install a new Master Boot Record if user     }
{			    wants it					}
{ REVISION HISTORY	Dima Stefankov (DS)				}
{   			1.00   13-Sep-92  DS  initial release		}
{			1.01   14-Sep-92  DS  add saving old MBR to file}
{                       1.02   21-Sep-92  DS  some corrections          }
{                       1.10   08-Oct-92  DS  some style corrections    }
{                       1.11   27-Oct-92  DS  some corrections          }
{                       1.12   04-Nov-92  DS  some updates              }
{			1.20   23-Mar-93  DS  some corrections		}
{                       1.21   14-May-93  DS  some style updates        }
{			1.30   18-Oct-93  DS  added a checking of copy  }
{                                             already installed on disk }
{-----------------------------------------------------------------------}


{*======================= PROGRAM HEADER PART ==========================*}

PROGRAM   OS_LOADER_FROM_FIXED_DISK;


{*** other modules ***}
{*USES;*}


{** switches for compilation **}
{$S-}		{*  stack checking   *}
{$R-}           {*  range checking   *}

{* generate version for loader code debugging *}
{***$DEFINE  DebugVersion}


{*========================== CONSTANTS PART ============================*}

CONST

    { program definitions }
     asPurpose                  =       'OS-MultBoot';
     asVersion                  =       '1.30';
     asAuthor                   =       'Dima Stefankov';
     asCopyright                =       'Copyright (c) 1987, 1993';
     asProgram                  =       'OS-Boot';
     asProgramPrompt            =       asProgram+': ';

     { exit codes }
       errTerminateOK           =     0;
       errBootStrapDebug        =     1;
       errBadReadFixedDisk      =     2;
       errBadWriteFixedDisk     =     3;
       errUserInstallAbort      =     4;
       errUserWriteAbort        =     5;
       errMismatchLoaderCode    =     6;

    { miscellaneous }
      aMaxTpStrLen              =     255;
      asBlank                   =     '';
      achHexPrefix              =     '$';
      asFreeSlot                =     ' <*** free slot ***>';
      asNonFreeSlot             =     ' <*** disk slot ***>';
      aSectorSize               =     512;
      aSecSizeInWords           =     aSectorSize DIV 2;
      aQuit                     =     'Q';
      achYes                    =     'Y';
      achNo                     =     'N';
      aDefExt                   =     'BIN';
      aDosExtMark               =     '.';

    { ASCII codes }
      achNULL                   =     00;
      achLF                     =     10;
      achCR                     =     13;
      achOne                    =     '1';
      achFour                   =     '4';

      {***** ATTENTION!!! Hard-coded values below. *****}
      {***** Please modify carefully!              *****}
{$IFDEF  DebugVersion}
      adwBootSeg                =     $8000;     { segment at 512K }
{$ELSE}
      adwBootSeg                =     $0000;     { segment at 0K }
{$ENDIF}
     adwBootOfs                 =     $7C00;
     adwRelBootOfs              =     adwBootOfs + aSectorSize;
     adwPartitionTable		=     $1BE;
     aPartitonEntrySize         =     $10;
     aMaxAvailLogicalPartition	=     4;
     adwBootMarkOfs             =     adwPartitionTable + (aPartitonEntrySize*aMaxAvailLogicalPartition);
     adwBootSecID               =     $AA55;

     aOS_Desc_Str_Len           =     $16;      { these values found }
     aOS_Desc_Ofs               =     $04;	{ after assembly of  }
     aOS_Desc_Start             =     $40-1;	{ IPL procedure.     } 	 
     aOS_Desc_Str_Len_Ext       =     aOS_Desc_Str_Len + 2;

     aDebugOff                  =     0;
     aDebugOn                   =     1;

     aFarJumpOpCode             =     $EA;      { iAPX86 opcode }

     aRomKbdDriver              =     $16;      { IBM PC BIOS functions }
     aRomDiskDriver             =     $13;
     aRomVideoDriver            =     $10;

  { use for to check of installed version }
     asCopyrightNotice          =     'OS-MultBoot (C) 1992 D.Stefankov';


{*====================== TYPED CONSTANTS PART ==========================*}

TYPE

  {* strings *}
       STR2                     =     STRING[2];
       STR4                     =     STRING[4];
       STR8                     =     STRING[8];

    {* Information about logical disk *}
    recLogicalPartition  =  RECORD
                 dbBootDriveMark              :       System.Byte;      {00}
                 dbStartingHead               :       System.Byte;      {01}
                 dwStartingCylSec             :       System.Word;      {02}
                 dbOperatingSystemID          :       System.Byte;      {04}
                 dbEndingHead                 :       System.Byte;      {05}
                 dwEndingCylSec               :       System.Word;      {06}
                 ddPrecedingSecs              :       System.Longint;   {08}
                 ddSecsPerPartition           :       System.Longint;   {0C}
                           END;
    {* recLogicalPartition *}

    {* Master Boot Sector *}
    recMasterBoot  =  RECORD
         dbReservedCode           :  ARRAY[0..adwPartitionTable-1] OF System.Byte;      	    {000}
         recDiskPartitionsTable   :  ARRAY[0..aMaxAvailLogicalPartition-1] OF recLogicalPartition;  {1BE}
         dwValidBootRecID         :  System.Word;                        		   	    {1FE}
                           END;
    {* recMasterBoot *}


{*=========================== VARIABLES PART ===========================*}

VAR

   grecFixedDiskBoot    :   recMasterBoot;
   gfOutStream          :   FILE  OF  recMasterBoot;
   gsTempInput          :   STRING;
   gdwOurBootRecLen	:   System.Word;
   gdwMemOfs            :   System.Word;
   gbStatusOk           :   System.Boolean;
   gdbIndex             :   System.Byte;
   gchIn                :   System.Char;



{*=========================== PROCEDURAL PART ==========================*}

PROCEDURE _IPL_Code; far; assembler;
{* Initial program loader. *}
{* Note 1: This procedure must be always first. *}
{* Note 2: The length of code must be <= $1BE for non-debugging version. *}
asm
{$IFDEF  DebugVersion}
        cmp      ax, aDebugOff        { Test for relocated code marker }
        je       @InitCode

        mov      bx, cs               { Our Procedure in TP code segment }
        mov      ds, bx               { We move it to new segment for debugging }
        mov      ax, adwBootSeg
        mov      es, ax
        mov      cx, aSecSizeInWords
        mov      si, 0
        mov      di, adwBootOfs
        push     es                   { Jump Segment into Stack }
        push     di                   { Jump Offset  into Stack }
        cld
        rep      movsw

        mov      ax, aDebugOff        { we had relocated code }
        retf                          { jump to relocated code }

  @InitCode:
{$ENDIF}

        cli                           { disable ints during regs setup }
{$IFDEF DebugVersion}
        mov      ax, adwBootSeg
{$ELSE}
	sub	 ax, ax
{$ENDIF}
        mov      ds, ax               { set seg registers to zero = ABS0 seg }
        mov      es, ax
        mov      ss, ax               { stack at $0000:$7C00 }
        mov      sp, adwBootOfs

        sti                           { re-enable intrs }
        cld                           { go forward }
        mov      si, sp               { DS:SI -> 0:$7C00 }
        mov      di, adwRelBootOfs    { ES:DI -> 0:$7E00 }
        mov      cx, aSecSizeInWords  { words count }
        rep      movsw                { relocate code to safe place }
				      { jump to continue from new place }
        db       aFarJumpOpCode       { Direct FAR Jump }
	dw	 adwRelBootOfs + (OFFSET @NewStart)
	dw	 adwBootSeg

                                      { messages for user }
				      { offset to ref        =>  $1D }
  @dbUserMenu_MSG:
        db       "OS-MultBoot (C) 1992 D.Stefankov"
        db       achCR,achLF
                                      {** Hard-coded values, be carefully! **}
				      { offset to ref        =>  $41 }
				      { length of each entry =>  $16 }
				      { offset of <None>     =>  $04 }
        db       "[1] None OS           "
	db	 achCR, achLF

        db       "[2] None OS           "
	db	 achCR, achLF

        db       "[3] None OS           "
	db	 achCR, achLF

        db       "[4] None OS           "
	db	 achCR, achLF

        db       "Select:"
        db       achNULL

  @LoadOS_MSG:
        db       achCR,achLF
        db       '.. Load OS ..'
        db       achCR,achLF
        db       achNULL

  @BadPartition_MSG:
        db       achCR,achLF
        db       '.. Bad Partition ..'
        db       achNULL

  @ErrLoadOS_MSG:
        db       achCR,achLF
        db       '.. Error loading OS ..'
        db       achNULL

  @BadOS_MSG:
        db       achCR,achLF
        db       '.. Missing OS ..'
        db       achNULL

  @BadUserSelect_MSG:
        db       achCR,achLF
        db       '.. Invalid select ..'
        db       achNULL


  @AnyKey_MSG:
        db       achCR,achLF
        db       '.. Strike any key ..'
        db       achNULL


  @NewStart:
        mov      ah, 0Fh              { get video mode }
        int      aRomVideoDriver      { call ROM BIOS video driver }
        mov      ah, 00h              { set video mode }
        int      aRomVideoDriver      { call ROM BIOS video driver }

        mov      si, OFFSET  @dbUserMenu_MSG
        call     @AsciizOutput        { Display string in format <ASCII+zero> }

        mov      ah, 00h              { get user char }
        int      aRomKbdDriver        { call ROM BIOS keyboard driver }

        cmp      al, achOne           { test for match value }
        jb       @BadEntry
        cmp      al, achFour
        ja       @BadEntry

        and      ax, $0007            { must in range 1..4 }
        mov      cl, 4                { each entry in PT occupies }
        shl      al, cl               { exactly 16 bytes }
        mov      si, adwRelBootOfs + adwPartitionTable - aPartitonEntrySize
        add      si, ax               { DS:SI -> Partition Table entry }

        mov      dx, [si]             { DH = head, DL = drive }
        mov      cx, [si+2]           { CX = cyl/sec }
        mov      ax, cx               { test valid info }
        or       ax, dx
        jz       @BadPartition        { jump if unable to load this }

        or       dl, 080h             { turn on a bit for fixed disk }
        mov      bx, adwBootOfs       { ES:BX -> buffer }
        mov      bp, 7                { retry count }

  @TryLoad:
       mov      ax, 0201h             { read one sector from disk to memory }
       int      aRomDiskDriver        { call ROM BIOS disk driver }
       jnc      @LoadOk               { jump if driver says OK }
       xor	ah, ah		      { reset controller }
       int	aRomDiskDriver	      { call ROM BIOS disk driver }
       dec      bp                    { decrement a retries counter }
       jnz      @TryLoad
                                      { may be disk bad? }
       mov      si, OFFSET  @ErrLoadOS_MSG

  @UserWarning:
        call     @AsciizOutput        { Display string in format <ASCII+zero> }

        mov      si, OFFSET  @AnyKey_MSG
        call     @AsciizOutput        { Display string in format <ASCII+zero> }

        mov      ah, 00h              { get user char }
        int      aRomKbdDriver        { call ROM BIOS keyboard driver }
        jmp      @NewStart

  @LoadOk:                            { check boot ID }
        cmp     word ptr [bx+adwBootMarkOfs], adwBootSecID
        jne    @BadOS

        mov      si, OFFSET  @LoadOS_MSG
        call     @AsciizOutput        { Display string in format <ASCII+zero> }
        db     aFarJumpOpCode         { Direct Far Jump }
        dw     adwBootOfs, adwBootSeg { address }

  @BadEntry:                          { invalid user option }
        mov    si, OFFSET  @BadUserSelect_MSG
        jmp    @UserWarning

  @BadOS:                             { non-bootable sector }
        mov    si, OFFSET  @BadOS_MSG
        jmp    @UserWarning

  @BadPartition:                      { bad partition table }
        mov    si, OFFSET  @BadPartition_MSG
        jmp    @UserWarning


 {** _AsciizOutput  PROC NEAR **}
  @AsciizOutput:                      
        add    si, adwRelBootOfs      { fix problem with relocation }

  @NextChar:
        lodsb                         { get char }
        or       al, al               { AL is zero? }
        jz       @Done                { exit if match }
        push     si                   { preserve SI (may be destroyed for older BIOS versions!) }
        mov      bx, 0007h            { white-on-black }
        mov      ah, 0Eh              { TTY function }
        int      aRomVideoDriver      { call ROM BIOS video driver }
        pop      si                   { recover SI }
        jmp      @NextChar

  @Done:
        retn                          { return to caller }
 {** _AsciizOutput  ENDP  **}

END; {end-asm}
{ _IPL_Code }


PROCEDURE    _DummyProc;
{* It is used for reference only. Don't remove this code!!! *}
BEGIN
  {** nothing!!! *}
END;
{ _DummyProc }



{*=========================== FUNCTIONAL PART ==========================*}

FUNCTION  _fnsForceFileExtension(sFileName, sDefExt : STRING) : STRING;
{* Add extension for filename if not present. *}
BEGIN
   IF (System.Pos(aDosExtMark,sFileName) = 0)
     THEN sFileName := sFileName + aDosExtMark + sDefExt;
   {if-then}
  _fnsForceFileExtension := sFileName;
END;
{ _fnsForceFileExtension }


FUNCTION   _fnchGetFirstChar(sInput : STRING) : System.Char;
{* Returns a first char from string. *}
VAR
  chTemp  :  System.Char;

BEGIN
   IF (System.Length(sInput) <> 0)
     THEN  chTemp := sInput[1]
     ELSE  chTemp := System.Char(achNULL);
   {if-then-else}
  _fnchGetFirstChar := chTemp;
END;
{ _fnchGetFirstChar }



{*=========================== PROCEDURAL PART ==========================*}

PROCEDURE    _CopyrightDisplay;
{* Outputs the copyright notice. *}
BEGIN
     System.WriteLn(asPurpose+
                    '  Version '+
                    asVersion+
                    ',  '+
                    asCopyright+
                    '  '+
                    asAuthor);
END;  { _CopyrightDisplay }


{*============================== MAIN PART =============================*}

BEGIN

  {* copyright message *}
    _CopyrightDisplay;


  {* set a length of boot code, don't count TP RETF instruction *}
     gdwOurBootRecLen := System.Ofs(_DummyProc) - System.Ofs(_IPL_Code) - 1;


  {* test bootstrap procedure *}
{$IFDEF  DebugVersion}
    System.WriteLn(asProgramPrompt+'Debugging of boostrap procedure.');
    asm
      mov        ax,  aDebugOn        { no relocated code }
    END;
    {asm-end}

    _IPL_Code;

   System.Halt(errBootStrapDebug);
{$ENDIF}

  {* test for match length of IPL *}
     IF  (gdwOurBootRecLen > adwPartitionTable)
       THEN  BEGIN
         System.WriteLn(asProgramPrompt+'Bad size of loader code please re-code.');
         System.Halt(errMismatchLoaderCode);
             END;
     {if-then}

  {* Read original master boot record *}
    System.WriteLn(asProgramPrompt+'Reading of MBR.');
    gbStatusOk := System.True;
    asm
        mov     dx, 0080h             { drive 0, head 0 }
        mov     cx, 0001h             { cyl 0, sec 1 }
        mov     ax, ds
        mov     es, ax                { ES = Turbo DS }
        mov     bx, OFFSET grecFixedDiskBoot
        mov     ax, 0201h             { read 1 sector }
        int     aRomDiskDriver        { ROM BIOS disk driver }
        jnc     @Done
                                      { at this point reading failed }
        mov     gbStatusOk, System.False

     @Done:
    END;
    {ams-end}

  IF NOT(gbStatusOk)
    THEN  BEGIN
       System.WriteLn(asProgramPrompt+'Unable to read MBR from fixed disk.');
       System.Halt(errBadReadFixedDisk);
          END;
  {if-then}


  {* check for presence of installed loader *}
     System.Move(grecFixedDiskBoot,gsTempInput[1],aMaxTpStrLen);
     gsTempInput[0] := System.Char(aMaxTpStrLen);
     IF  (System.Pos(asCopyrightNotice,gsTempInput) <> 0)
       THEN  BEGIN
          System.WriteLn(asProgramPrompt+asProgram+' loader found on fixed disk 0.');
          System.Write(asProgramPrompt+'Copy description strings from installed copy (Y/N): ');
          System.ReadLn(gsTempInput);

          IF  (System.UpCase(_fnchGetFirstChar(gsTempInput)) <> achNo)
             THEN  BEGIN
                System.WriteLn(asProgramPrompt+'Copy description strings.');
                System.Move(System.Mem[System.Seg(grecFixedDiskBoot.dbReservedCode):
                            (System.Ofs(grecFixedDiskBoot.dbReservedCode)+aOS_Desc_Start)],
                            System.Mem[System.Seg(System.Addr(_IPL_Code)^):aOS_Desc_Start],
                            aOS_Desc_Str_Len_Ext*aMaxAvailLogicalPartition);
                   END;
          {if-then}
             END
       ELSE
          System.WriteLn(asProgramPrompt+asProgram+' loader not present.');
     {if-then}


  {* save original boot record *}
     System.Write(asProgramPrompt+'Save original MBR (Y/N): ');
     System.ReadLn(gsTempInput);
     IF  ((System.UpCase(gsTempInput[1]) <> achNo) OR (gsTempInput = asBlank))
       THEN  BEGIN
         System.Write(asProgramPrompt+'Enter filename (def.ext.='+aDefExt+'): ');
         System.ReadLn(gsTempInput);
         IF (gsTempInput <> asBlank)
           THEN  BEGIN
              gsTempInput := _fnsForceFileExtension(gsTempInput,aDefExt);
              System.WriteLn(asProgramPrompt+'Copy original MBR to file.');
            {** no check for errors **}
              System.Assign(gfOutStream,gsTempInput);
              System.Rewrite(gfOutStream);
              System.Write(gfOutStream,grecFixedDiskBoot);
              System.Close(gfOutStream);
                 END;
         {if-then}
             END;
     {if-then}


  {* make a new boot record *}
    System.WriteLn(asProgramPrompt+'Copy loader code.');
    System.Move(System.Mem[System.Seg(System.Addr(_IPL_Code)^):0],
                           grecFixedDiskBoot,
                           gdwOurBootRecLen);

  {* Ask user about installation. *}
     System.Write(asProgramPrompt+'Install OS-MBoot. Are you sure (N/Y): ');
     System.ReadLn(gsTempInput);
     IF  (System.UpCase(_fnchGetFirstChar(gsTempInput)) <> achYes)
       THEN  BEGIN
         System.WriteLn(asProgramPrompt+'Aborted by user.');
         System.Halt(errUserInstallAbort);
             END;
     {if-then}


  {* Ask user about OS select. *}
     gbStatusOk := System.False;

     REPEAT
      {* display current settings *}
       System.WriteLn(asProgramPrompt+'Operating System (OS)  Define Menu: ');
       FOR  gdbIndex  := 0  TO  aMaxAvailLogicalPartition-1  DO
       BEGIN
         System.Move(grecFixedDiskBoot.dbReservedCode[aOS_Desc_Start+(aOS_Desc_Str_Len_Ext*gdbIndex)],
                     gsTempInput[1],
                     aOS_Desc_Str_Len);
         gsTempInput[0] := System.Char(aOS_Desc_Str_Len);
         {* Check for free slot *}
         IF  (grecFixedDiskBoot.recDiskPartitionsTable[gdbIndex].dwStartingCylSec = 0)
           THEN  gsTempInput := gsTempInput + asFreeSlot
           ELSE  gsTempInput := gsTempInput + asNonFreeSlot;
         {if-then-else}
         System.WriteLn(gsTempInput);
       END;
       {for-to-do}
       System.WriteLn('[Q] Quit');
       System.Write('Select your option(1,2,3,4,Q): ');

     {* get user input *}
       System.ReadLn(gsTempInput);
       gchIn := System.UpCase(_fnchGetFirstChar(gsTempInput));

       IF (gsTempInput <> asBlank)
         THEN  CASE  gchIn  OF
                        achOne..achFour  :  BEGIN
       {* only 4 logical partitions enabled *}
         gdbIndex := System.Byte(gchIn) - System.Byte(achOne);
         System.Write(asProgramPrompt+'Enter OS/ID string (up ',(aOS_Desc_Str_Len-aOS_Desc_Ofs),' chars): ');
         System.ReadLn(gsTempInput);

         IF  (gsTempInput <> asBlank)
           THEN  BEGIN
       {* cut string if need *}
         WHILE  (System.Length(gsTempInput) > (aOS_Desc_Str_Len-aOS_Desc_Ofs)) DO
           System.Delete(gsTempInput,System.Length(gsTempInput),1);
         {while-do}
       {* copy ID string *}
         System.Move(gsTempInput[1],
                     grecFixedDiskBoot.dbReservedCode[aOS_Desc_Start+((aOS_Desc_Str_Len+2)*gdbIndex)+aOS_Desc_Ofs],
                     System.Length(gsTempInput));
                 END
         {if-then}
                                     END;
                        aQuit       :  gbStatusOk := System.True;
                 ELSE
                     System.WriteLn(asProgramPrompt+'Bad selection.');
               END;
               {case-of}
       {if-then}
     UNTIL (gbStatusOk);
     {repeat-until}


  {* Ask user about writing. *}
     System.Write(asProgramPrompt+'Write a new IPL. Are you sure (N/Y): ');
     System.ReadLn(gsTempInput);
     IF  (System.UpCase(_fnchGetFirstChar(gsTempInput)) <> achYes)
       THEN  BEGIN
         System.WriteLn(asProgramPrompt+'Aborted by user.');
         System.Halt(errUserWriteAbort);
             END;
     {if-then}


  {* Write a new master boot record *}
    System.WriteLn(asProgramPrompt+'Writing of MBR.');
    gbStatusOk := System.True;
    asm
        mov     dx, 0080h             { drive 0, head 0 }
        mov     cx, 0001h             { cyl 0, sec 1 }
        mov     ax, ds
        mov     es, ax                { ES = Turbo DS }
        mov     bx, OFFSET grecFixedDiskBoot
        mov     ax, 0301h             { write 1 sector }
        int     aRomDiskDriver        { ROM BIOS disk driver }
        jnc     @Done
                                      { we know that writing failed here }
        mov     gbStatusOk, System.False

     @Done:
    END;
    {asm-end}

  IF NOT(gbStatusOk)
    THEN  BEGIN
       System.WriteLn(asProgramPrompt+'Unable to write MBR to fixed disk.');
       System.Halt(errBadWriteFixedDisk);
          END;
  {if-then}


  {* final report *}
    System.WriteLn(asProgramPrompt+'Done.');

  {* System.Halt(errTerminateOk); *}
END.
