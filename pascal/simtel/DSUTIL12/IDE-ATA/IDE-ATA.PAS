{-----------------------------------------------------------------------}
{ PROJECT		NON-PROFIT HIGH QUALITY PROFESSIONAL SOFTWARE,  }
{			AVAILABLE FOR ALL WORLD				}
{ LIBRARY		SYSTEM UTILITIES                                }
{ MODULE		IDE_ATA_DRIVE_INFO                              }
{ FILE NAME		IDE-ATA.PAS					}
{ PURPOSE		Read IDE/ATA-drive internal information         }
{ VERSION		1.31						}
{ DATE			25-Nov-93					}
{ DESIGN		Dmitry Stefankov				}
{                       (Original idea of Thomas J. Newman, 1991)       }
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
{ ARGUMENTS		<screenlines>  ---  # lines for each screen page}
{			<filewrite>    ---  any string to ask filename  }
{                       <cmos|all|max> ---  find all match CMOS parms   }
{					    (any string except <CMOS>)	}
{					    and/or display HDD ROM table}
{ RETURN		None						}
{ REQUIRES		None                                            }
{ NATURAL LANGUAGE      English Language                             	}
{ SPECIAL		Please note this program can have the problem	}
{			with some 80286 (usually older) mainboards 	}
{			because their manufacturers don't wish to cor-	}
{			rectly implement the ATA/IDE standard interface.}
{ DESCRIPTION		1. Test drive 0 hardware for primary controller }
{                       2. If hardware test successful                  }
{                             then issue IDENTIFY command for IDE-drive }
{                       3. If command not failed                        }
{                            then display lot of info about drive,      }
{                            and ask about write buffer to file,        }
{                            and display possible logical configuration }
{                            for drive through linear translation       }
{                       4.  Repeat steps  1 - 3  for (like above step)  }
{                            drive 1 on primary controller              }
{                            drive 0 on secondary controller            }
{                            drive 1 on secondary controller            }
{                       5. Display ROM BIOS HDD types table             }
{                       6. Get # of hard disks from System BIOS         }
{                       7. Display # of found IDE/ATA-drives            }
{ REVISION HISTORY	Dima Stefankov (DS)				}
{   			1.00   26-Aug-92  DS  initial release		}
{                       1.01   27-Aug-92  DS  some corrections          }
{                       1.02   29-Aug-92  DS  correct some bugs         }
{                       1.10   08-Oct-92  DS  added buffer write to file}
{                       1.11   27-Oct-92  DS  some corrections          }
{                       1.12   02-Nov-92  DS  some style changes        }
{			1.20   24-Feb-93  DS  fixed a bug with hexflags,}
{					      added PLO bytes parameter	}
{			1.21   04-Jul-93  DS  updated documentation	}
{                       1.22   30-Aug-93  DS  added paged screen output }
{			1.23   09-Sep-93  DS  changed parameters order	}
{			1.24   24-Sep-93  DS  added CMOS suggested parms}
{                                             calculations screen, also }
{                                             added display of ROM BIOS }
{                                             HDD types table for CMOS  }
{                                             disk parameters setup, and}
{					      fixed a bug with task file}
{					      loading		        }
{                       1.30   19-Oct-93  DS  added more ATA parameters }
{                                             according ATA draft stand-}
{                                             dard r4a of April 1993    }
{			1.31   25-Nov-93  DS  fixed a timing problem for}
{					      a buffer reading (DRQ bit }
{					      checking)			}
{-----------------------------------------------------------------------}


{*======================= PROGRAM HEADER PART ==========================*}

PROGRAM   READ_IDE_ATA_DRIVE_INFO;



{*** other modules ***}
{*USES;*}

{** switches for compilation **}
{$S-}		{*  stack checking   *}
{$R-}           {*  range checking   *}


{** miscellaneous version **}
{***$DEFINE  DebugVersion}		{* generate a debugging version *}



{*========================== CONSTANTS PART ============================*}

CONST
     asPurpose                  =       'IDE/ATA DRIVE INFO';
     asVersion                  =       '1.31';
     asAuthor                   =       'Dima Stefankov';
     asCopyright                =       'Copyright (c) 1987, 1993';
     asProgram                  =       'IDE/ATA-Info';
     asProgramPrompt            =       asProgram+': ';

     { exit codes }
       errTerminateOK           =     0;
       errUserAbort             =     1;
       errBadNumeric            =     2;
       errBadCPU                =     3;
       errBadSecsNum            =     4;

    { miscellaneous }
      achSpace                  =     ' ';
      asBlank                   =     '';
      achHexPrefix              =     '$';
      achDosDelim               =     '.';
      asDefExt                  =     'bin';
      asPrimary                 =     'primary';
      asSecondary               =     'secondary';
      aPercent100               =     100;

     { screen output }
       aDisableScreenPage       =     0;
       aMinOutLineOnScreen      =     1;
       aDefMaxOutLineForScreen  =     23;
       aBigOutLinesForScreenNum =     2048;

     { Dos equates }
       aBytesPerKByte           =     1024;
       aKBytesPerMbyte          =     1024;
       aBytesPerDosSector       =     512;
       aWordsPerDosSector       =     aBytesPerDosSector DIV 2;
       aPhysDriveNum_0          =     0;
       aPhysDriveNum_1          =     1;

     { Bios equates }
       aMinBiosCylNum           =     0;
       aMaxBiosCylNum           =     1023;
       aMinBiosHeadNum          =     0;
       aMaxBiosHeadNum          =     255;
       aMinBiosSecNum           =     1;
       aMaxBiosSecNum           =     63;
       aDefStdDosBiosSecNum     =     17;
       aStartHeadNum            =     aMinBiosHeadNum + 1;
       aMinHDD_CMOSType         =     1;
       aMaxHDD_CMOSType         =     47;
       aRomBiosSeg              =     $F000;

     { magic words }
       asNoFileToAsk		=    'NOFILE';
       asHddTableDisplayOnly    =    'CMOS';
       asMaxCapacityOnly	=    'MAX';

     { Bit-mapped flags }
       btIdeDrive_00            =     $01;
       btIdeDrive_01            =     $02;
       btIdeDrive_02            =     $04;
       btIdeDrive_03            =     $08;

     { PC hardware ports }
       aDriveCtrlrBaseReg_0     =     $1F0;       { primary controller }
       aDriveCtrlrBaseReg_1     =     $1F0;
       aDriveCtrlrBaseReg_2     =     $170;       { secondary controller }
       aDriveCtrlrBaseReg_3     =     $170;
       aAltDriveStatusReg_0     =     $3F6;
       aAltDriveStatusReg_1     =     $376;

     { controller status register bits }
       btCtlrBusy               =     $80;
       btDriveReady             =     $40;
       btWriteFault             =     $20;
       btSeekComplete           =     $10;
       btDataRequest            =     $08;
       btCmdErr                 =     $01;

     { sector/drive/head info }
       btCRCmode                =     $80;
       btSecSize512             =     $20;

     { sector equates }
        aSectorCountRegVal	=     $01;
        aSectorNumberRegVal	=     $01;

     { controller commands opcodes }
       cmdIDENTIFY              =     $EC;
       cmdDisableInts           =     $04;
       cmdEnableInts            =     $00;

     { IDE info record hard-coded values }
        dbSerialNumberLen                   =      20;
        dbCntlrFirmwareRevisionLen          =      8;
        dbModelNumberLen                    =      40;
        dwReservedPartSize1                 =      $100-$80;
        dbVendorUniqueInfoTextLen           =      $140-$100;
        dwReservedPartSize2                 =      aBytesPerDosSector-$140;

    { bit values }
       btBit_0_ON               =       $0001;
       btBit_1_ON               =       $0002;
       btBit_2_ON               =       $0004;
       btBit_3_ON               =       $0008;
       btBit_4_ON               =       $0010;
       btBit_5_ON               =       $0020;
       btBit_6_ON               =       $0040;
       btBit_7_ON               =       $0080;
       btBit_8_ON               =       $0100;
       btBit_9_ON               =       $0200;
       btBit_A_ON               =       $0400;
       btBit_B_ON               =       $0800;
       btBit_C_ON               =       $1000;
       btBit_D_ON               =       $2000;
       btBit_E_ON               =       $4000;
       btBit_F_ON               =       $8000;

    { bit values }
       aTestPattern_00          =       $00;
       aTestPattern_55          =       $55;
       aTestPattern_AA          =       $AA;
       aTestPattern_FF          =       $FF;


{*==================== TYPE DECLARATIONS PART ==========================*}

TYPE
  {* strings *}
       STR2                     =     STRING[2];
       STR4                     =     STRING[4];
       STR8                     =     STRING[8];

  {* hard drive controller registers read map *}
    recHDISK_READ_REGS          =       RECORD
                 dwDataReg_RD              :     System.Word;
                 dwErrorReg_RD             :     System.Word;
                 dwSectorCountReg_RD       :     System.Word;
                 dwSectorNumberReg_RD      :     System.Word;
                 dwCylinderLowReg_RD       :     System.Word;
                 dwCylinderHighReg_RD      :     System.Word;
                 dwSDH_Reg_RD              :     System.Word;
                 dwStatusReg_RD            :     System.Word;
                                        END;
    {* recHDISK_READ_REGS *}


  {* hard drive controller registers write map *}
    recHDISK_WRITE_REGS          =       RECORD
                 dwDataReg_WR              :     System.Word;
                 dwWRC_Reg_WR              :     System.Word;
                 dwSectorCountReg_WR       :     System.Word;
                 dwSectorNumberReg_WR      :     System.Word;
                 dwCylinderLowReg_WR       :     System.Word;
                 dwCylinderHighReg_WR      :     System.Word;
                 dwSDH_Reg_WR              :     System.Word;
                 dwCommand_Reg_WR          :     System.Word;
                                        END;
    {* recHDISK_WRITE_REGS *}


    {* hard disk drive controller control block *}
      recHDISK_WRITE_CMD_BLOCK    =       RECORD
                 dbData_WR                 :     System.Byte;
                 dbWRC_WR                  :     System.Byte;
                 dbSectorCount_WR          :     System.Byte;
                 dbSectorNumber_WR         :     System.Byte;
                 dbCylinderLow_WR          :     System.Byte;
                 dbCylinderHigh_WR         :     System.Byte;
                 dbSDH_WR                  :     System.Byte;
                 dbCommand_WR              :     System.Byte;
                                          END;
    {* recHDISK_WRITE_CMD_BLOCK *}


    {* Configuration Parameters of IDE disk drive *}
    recIDE_Info_Sector  =  RECORD
                 dwGeneralConfigFlags           :       System.Word;                                              {00}
                 dwFixedCylsNum                 :       System.Word;                                              {02}
                 dwRemovableCylsNum             :       System.Word;                                              {04}
                 dwHeadsNum                     :       System.Word;                                              {06}
                 dwUnfmtdBytesPerPhysTrk        :       System.Word;                                              {08}
                 dwUnfmtdBytesPerSec            :       System.Word;                                              {0A}
                 dwPhysSecsPerTrk               :       System.Word;                                              {0C}
                 dwInterSecGapBytesNumVU        :       System.Word;                                              {0E}
                 dwSyncFieldsBytesNumVU         :       System.Word;                                              {10}
                 dwPLObyteNumVU                 :       System.Word;                                              {12}
                 dbSerialNumber                 :       ARRAY[1..dbSerialNumberLen]  OF System.Char;              {14}
                 dwControllerType               :       System.Word;                                              {28}
                 dwControllerBufSize            :       System.Word;                                              {2A}
                 dwECCbytes                     :       System.Word;                                              {2C}
                 dbCntlrFirmwareRevision        :       ARRAY[1..dbCntlrFirmwareRevisionLen]   OF System.Byte;    {2E}
                 dbModelNumber                  :       ARRAY[1..dbModelNumberLen]   OF System.Char;              {36}
                 dwSecsPerIntr                  :       System.Word;                                              {5E}
                 dwDoubleWordTransferFlag       :       System.Word;                                              {60}
                 dwAssignAlternate              :       System.Word;                                              {62}
                 dwReserved_64                  :       System.Word;                             		  {64}
		 dwPIODataXFRCycleTimingMode	:	System.Word;						  {66}
		 dwDMADataXFRCycleTimingMode	:	System.Word;						  {68}
                 dwCurrentSettingsValidFlag     :       System.Word;                                              {6A}
                 dwCurrentCylsNum               :       System.Word;                                              {6C}
                 dwCurrentHeadsNum              :       System.Word;                                              {6E}
                 dwCurrentSecsPerTrack          :       System.Word;                                              {70}
                 ddCurrentDriveCapacityInSecs   :       System.Longint;                                           {72}
                 dwMultipleSecsModeXfrSettings  :       System.Word;                                              {76}
                 ddTotalUserSecsInLBA_Mode      :       System.Longint;                                           {78}
                 dwSingleWordDMA_XfrMode        :       System.Word;                                              {7C}
                 dwMultiWordDMA_XfrMode         :       System.Word;                                              {7E}
                 dbReserved_80                  :       ARRAY[1..dwReservedPartSize1] OF System.Byte;             {80}
                 dbVendorUniqueInfoText         :       ARRAY[1..dbVendorUniqueInfoTextLen]  OF  System.Char;     {100}
                 dbReserved_140                 :       ARRAY[1..dwReservedPartSize2] OF System.Byte;             {140}
                           END;
    {* recIDE_Info_Sector *}


    {* Hard Disk Parameters Table *}
    recHARD_DISK_PARMS	= RECORD
		dwMAX_CYLS_NUM		     :    System.Word;     {00}
		dbMAX_HEADS_NUM		     :    System.Byte;     {02}
		dwSTART_WRC_XT		     :    System.Word;     {03}
		dwSTART_WRC                  :    System.Word;     {05}
		dbMAX_ECC_DATA_BURST_LEN     :    System.Byte;     {07}
		dbCONTROL_BYTE               :    System.Byte;     {08}
		dbSTD_TIME_OUT_XT            :    System.Byte;     {09}
		dbFMT_TIME_OUT_XT            :    System.Byte;     {0A}
		dbCHECK_TIME_OUT_XT          :    System.Byte;     {0B}
		dwLANDING_ZONE               :    System.Word;     {0C}
		dbSECTORS_PER_TRACK          :    System.Byte;     {0E}
		dbPARM_RESERVED              :    System.Byte;     {0F}
	                  END;
    {* Hard Disk Parameters Table *}


{*====================== TYPED CONSTANTS PART ==========================*}

CONST
    setAscii7_NoCtrl  :    SET OF System.Char  =  [#32..#127];
    setHexChars       :    SET OF System.Char  =  ['0'..'9','A'..'F','a'..'f'];

    gbFileWriteOk     :    System.Boolean      =  System.False;
    gbFindAllOk       :    System.Boolean      =  System.False;
    gbFindCMOSOk      :    System.Boolean      =  System.False;
    gbFindMaxOk	      :    System.Boolean      =  System.False;

    gdwTextLineNum    :    System.Word         =  aMinOutLineOnScreen;
    gdwMaxScreenLines :    System.Word         =  aDefMaxOutLineForScreen;



{*=========================== VARIABLES PART ===========================*}

VAR
   grecDriveInfoBuf      :   recIDE_Info_Sector;
   grecRD_HDISK_Regs     :   recHDISK_READ_REGS;
   grecWRT_HDISK_Regs    :   recHDISK_WRITE_REGS;
   grecWR_CMD_BLOCK      :   recHDISK_WRITE_CMD_BLOCK;
   gliTotalDiskSectors   :   System.Longint;
   giErrorCode           :   System.Integer;
   gdwIndex              :   System.Word;
   gdwAlternateStatus    :   System.Word;
   gdbIDE_Disks_Count    :   System.Byte;
   gdbSDH_TestVal        :   System.Byte;
   gbDiskStatusOK        :   System.Boolean;
   gsTemp                :   STRING;

 { absolute references to memory locations}
   gdbBIOS_Drives_Num    :   System.Byte   ABSOLUTE  $40:$75;
   gdbROM_BIOS_HDD_TYPES_TABLE : ARRAY[aMinHDD_CMOSType..aMaxHDD_CMOSType]
                                 OF  recHARD_DISK_PARMS  ABSOLUTE $F000:$E401;





{*=========================== PROCEDURAL PART ==========================*}

PROCEDURE _IO_DELAY_2;
{* Some i/o bus delay. *}
INLINE($EB/$00/     { jmp short $ + 2 }
       $EB/$00);    { jmp short $ + 2 }
{ _IO_DELAY_2 }


PROCEDURE _IO_DELAY_4;
{* Some i/o bus delay. *}
INLINE($EB/$00/     { jmp short $ + 2 }
       $EB/$00/     { jmp short $ + 2 }
       $EB/$00/     { jmp short $ + 2 }
       $EB/$00);    { jmp short $ + 2 }
{ _IO_DELAY_4 }


PROCEDURE _IO_DELAY_6;
{* Some i/o bus delay. *}
INLINE($EB/$00/     { jmp short $ + 2 }
       $EB/$00/     { jmp short $ + 2 }
       $EB/$00/     { jmp short $ + 2 }
       $EB/$00/     { jmp short $ + 2 }
       $EB/$00/     { jmp short $ + 2 }
       $EB/$00);    { jmp short $ + 2 }
{ _IO_DELAY_6 }


PROCEDURE _IO_DELAY_8;
{* Some i/o bus delay. *}
INLINE($EB/$00/     { jmp short $ + 2 }
       $EB/$00/     { jmp short $ + 2 }
       $EB/$00/     { jmp short $ + 2 }
       $EB/$00/     { jmp short $ + 2 }
       $EB/$00/     { jmp short $ + 2 }
       $EB/$00/     { jmp short $ + 2 }
       $EB/$00/     { jmp short $ + 2 }
       $EB/$00);    { jmp short $ + 2 }
{ _IO_DELAY_8 }


PROCEDURE _ReadDataSector512(VAR dbBuf; dwBaseDataReg, dwTransferCount : System.Word);
{* Transfer 512-bytes sector into memory buffer. *}
INLINE($59/           {  pop     cx           ; CX = # words to xfr }
       $5A/           {  pop     dx           ; DX = base data reg  }
       $5F/           {  pop     di           ; DI = Ofs(dbBuf)     }
       $07/           {  pop     es           ; ES = Seg(dbBuf)     }
       $FA/           {  cli                  ; intrs off           }
       $FC/           {  cld                  ; go forward          }
       $F3/$6D/       {  rep     insw         ; i/o (286+)          }
       $FB);          {  sti                  ; intrs on            }
{ _ReadDataSector512 }



{*=========================== FUNCTIONAL PART ==========================*}

FUNCTION  _fndbReadControllerStatus(dwStatusReg : System.Word) : System.Byte;
{* Read fixed disk drive controller status. *}
VAR
  dbStatus : System.Byte;

BEGIN
  {* assume that status ok *}
   gbDiskStatusOK := System.True;

  {* just read some couple bits *}
   dbStatus  := System.Port[dwStatusReg];
   IF (((dbStatus AND (btDriveReady+btWriteFault+btSeekComplete+btCmdErr))
          XOR (btDriveReady+btSeekComplete)) <> 0)
     THEN  gbDiskStatusOK := System.False;
   {if-then}

  {* return result *}
  _fndbReadControllerStatus := dbStatus;
END; { _fndbReadControllerStatus }


FUNCTION  _fnbControllerIsReady(dwStatusReg : System.Word) : System.Boolean;
{* Test disk controller ready status. *}
VAR
  dwTimeOutCount  :   System.Word;
  dwOuterCount	  :   System.Word;
  dbStatus        :   System.Byte;
  bResVal         :   System.Boolean;

BEGIN
  {* assume that controller ready now *}
    dwTimeOutCount := $FFFF;
    dwOuterCount := $4000;
    gbDiskStatusOK := System.False;
    bResVal        := System.False;

  {* test controller status *}
  WHILE (dwOuterCount <> 0)  DO
  BEGIN
	WHILE (dwTimeOutCount <> 0) DO
	BEGIN
	    {* read status port *}
	    _IO_DELAY_2;
	    dbStatus  := System.Port[dwStatusReg];

	    {* controller busy? *}
	    IF ((dbStatus AND btCtlrBusy) = 0)
	      THEN  BEGIN
		      {* here we found status ok *}
		       dwTimeOutCount := 0;
		       dwOuterCount := 1;
		       gbDiskStatusOK := System.True;
		       bResVal        := System.True;
		    END
	      ELSE
		System.Dec(dwTimeOutCount);
	    {if-then-else}
	END;
	{while-do}
  System.Dec(dwOuterCount);
  END;
  {while-do}

  {* return result *}
    _fnbControllerIsReady := bResVal;
  {$IFDEF  DebugVersion}
	System.WriteLn('Ready state: ',dbStatus);
  {$ENDIF  DebugVersion}
END; { _fnbControllerIsReady }



FUNCTION  _fnbDriveIsReady(dwStatusReg : System.Word) : System.Boolean;
{* Test disk drive ready status. *}
VAR
  dwTimeOutCount  :   System.Word;
  dbStatus        :   System.Byte;
  bResVal         :   System.Boolean;

BEGIN
  {* assume that controller ready now *}
    dwTimeOutCount := $FFFF;
    gbDiskStatusOK := System.False;
    bResVal        := System.False;

  {* test controller status *}
    WHILE (dwTimeOutCount <> 0) DO
    BEGIN
        {* read status port *}
	_IO_DELAY_2;
        dbStatus  := System.Port[dwStatusReg];

        {* drive busy? *}
        IF ((dbStatus AND btDriveReady) <> 0)
          THEN  BEGIN
                  {* drive ready to accept command *}
                   dwTimeOutCount := 0;
                   gbDiskStatusOK := System.True;
                   bResVal        := System.True;
                END
          ELSE
            System.Dec(dwTimeOutCount);
        {if-then-else}
    END;
    {while-do}

  {* return result *}
    _fnbDriveIsReady := bResVal;
END; { _fnbDriveIsReady }


FUNCTION  _fnbWaitDRQ(dwStatusReg : System.Word) : System.Boolean;
{* Wait while sector buffer not full. *}
VAR
  dwTimeOutCount  :   System.Word;
  dwOuterCount	  :   System.Word;
  dbStatus        :   System.Byte;
  bResVal         :   System.Boolean;

PROCEDURE  _SimulateLongDelay(dwWaitCount : System.Word);
{* Fix a time-out problem before a controller will have ready. *}
BEGIN
  WHILE  (dwWaitCount <> 0) DO
  BEGIN
     _IO_DELAY_8;
     System.Dec(dwWaitCount);
  END;
  {while-do}
END;
{ _SimulateLongDelay }

BEGIN
  {* assume that controller ready now *}
    dwTimeOutCount := $FFFF;                {* Hard-coded value!! *}
    dwOuterCount := $FFFF;
    gbDiskStatusOK := System.False;
    bResVal        := System.False;

  {* test controller status *}
    WHILE  (dwOuterCount <> 0)  DO
    BEGIN
	WHILE (dwTimeOutCount <> 0) DO
	BEGIN
	    {* read status port *}
	    _SimulateLongDelay(20);
	    dbStatus  := System.Port[dwStatusReg];

	    {* buffer full? *}
	    IF (((dbStatus AND btCtlrBusy) = 0) AND 
                (((dbStatus AND (btDataRequest+btDriveReady+btSeekComplete)) <> 0)))
	      THEN  BEGIN
		      {* controller reports that buffer ready to read *}
		       dwTimeOutCount := 0;
		       dwOuterCount := 1;
		       gbDiskStatusOK := System.True;
		       bResVal        := System.True;
		    END
	      ELSE
		System.Dec(dwTimeOutCount);
	    {if-then-else}
	END;
	{while-do}
    System.Dec(dwOuterCount);
    END;
    {while-do}

  {* return result *}
    _fnbWaitDRQ := bResVal;
  {$IFDEF  DebugVersion}
	System.WriteLn('DRQ state: ',dbStatus);
  {$ENDIF  DebugVersion}
END; { _fnbWaitDRQ }


FUNCTION   _fnsByteToHexFmt(dbInput : System.Byte) : STR2;
{* Converts a byte to the hex format number representation. *}
CONST
    dbHexCharTable : ARRAY[0..15] OF System.Char = '0123456789ABCDEF';

BEGIN
  _fnsByteToHexFmt := dbHexCharTable[dbInput SHR 4] + dbHexCharTable[dbInput AND $0F];
END;  { _fnsByteToHexFmt }


FUNCTION   _fnsWordToHexFmt(dwInput : System.Word) : STR4;
{* Converts a word to the hex format number representation. *}
BEGIN
  _fnsWordToHexFmt := _fnsByteToHexFmt(System.Hi(dwInput)) +
                      _fnsByteToHexFmt(System.Lo(dwInput));
END;  { _fnsWordToHexFmt }


FUNCTION  _fnsAsciiInfo(pMem : System.Pointer; dwMemLen : System.Word;
                        bSwapBytes : System.Boolean) : STRING;
{* Return string only with match ASCII chars. *}
VAR
  sTemp        :    STRING;
  dwMemOfs     :    System.Word;
  dwChar2      :    System.Word;


PROCEDURE  _AddNewChar(chNew : System.Char);
{* Add match char to string. *}
BEGIN
   IF  (chNew IN setAscii7_NoCtrl)
      THEN  sTemp := sTemp + chNew;
   {if-then}
END; { _AddNewChar }

BEGIN
  {* initialize *}
   sTemp     := asBlank;
   dwMemOfs  := 0;
   dwMemLen  := dwMemLen SHR 1;    { words count }

  {* read all bytes in format HIGH-LOW (Motorola format) *}
   WHILE (dwMemLen <> 0) DO
   BEGIN
      dwChar2   := System.MemW[System.Seg(pMem^):(System.Ofs(pMem^)+dwMemOfs)];

     IF (bSwapBytes)
       THEN  BEGIN
         _AddNewChar(System.Char(System.Hi(dwChar2)));
         _AddNewChar(System.Char(System.Lo(dwChar2)));
             END
       ELSE  BEGIN
         _AddNewChar(System.Char(System.Lo(dwChar2)));
         _AddNewChar(System.Char(System.Hi(dwChar2)));
             END;
     {if-then-else}

      System.Dec(dwMemLen);
      System.Inc(dwMemOfs,2);
   END;
   {while-do}

  {* return string as result *}
   _fnsAsciiInfo := sTemp;
END; { _fnsAsciiInfo }


FUNCTION  _fnsForceFileExtension(sFileName, sDefExt : STRING) : STRING;
{* Add extension for filename if not present. *}
BEGIN
   IF (System.Pos(achDosDelim,sFileName) = 0)
     THEN  sFileName := sFileName + achDosDelim + sDefExt;
   {if-then}
  _fnsForceFileExtension := sFileName;
END;
{ _fnsForceFileExtension }


FUNCTION  _fnsNumToStr(liNum : System.Longint; dwWidth : System.Word) : STRING;
{* Convert a numeric value to its string representation. *}
VAR
  sTemp : STRING;

BEGIN
  IF (dwWidth <> 0)
    THEN  System.Str(liNum:dwWidth,sTemp)
    ELSE  System.Str(liNum,sTemp);
  {if-then-else}

  WHILE (System.Length(sTemp) <> 0) AND (sTemp[1] = achSpace)
  DO  System.Delete(sTemp,1,1);
  {while-do}

  _fnsNumToStr := sTemp;
END;
{ _fnsNumToStr }


FUNCTION  _fnsNumToStrNoAdj(liNum : System.Longint; dwWidth : System.Word) : STRING;
{* Convert a numeric value to its string representation. *}
VAR
  sTemp : STRING;

BEGIN
  IF (dwWidth <> 0)
    THEN  System.Str(liNum:dwWidth,sTemp)
    ELSE  System.Str(liNum,sTemp);
  {if-then-else}

  _fnsNumToStrNoAdj := sTemp;
END;
{ _fnsNumToStrNoAdj }


FUNCTION  _fnsNumToRealStr(rNum : System.Real;dwWidth,dwDecimals : System.Word) : STRING;
{* Convert a real numeric value to its string representation. *}
VAR
  sTemp : STRING;

BEGIN
  System.Str(rNum:dwWidth:dwDecimals,sTemp);

  WHILE (System.Length(sTemp) <> 0) AND (sTemp[1] = achSpace)
  DO  System.Delete(sTemp,1,1);
  {while-do}

  _fnsNumToRealStr := sTemp;
END;
{ _fnsNumToRealStr }


FUNCTION  _fnsNumToRealStrNoAdj(rNum : System.Real;dwWidth,dwDecimals : System.Word) : STRING;
{* Convert a real numeric value to its string representation. *}
VAR
  sTemp : STRING;

BEGIN
  System.Str(rNum:dwWidth:dwDecimals,sTemp);

  _fnsNumToRealStrNoAdj := sTemp;
END;
{ _fnsNumToRealStrNoAdj }


FUNCTION   _fnsUpCase(sInput : STRING) : STRING;
{* Translate characters to upper case. *}
VAR
   dbIndex  :  System.Byte;
   dbCount  :  System.Byte  ABSOLUTE  sInput;

BEGIN
  IF (dbCount <> 0)
    THEN   FOR  dbIndex := 1 TO dbCount DO
               sInput[dbIndex] := System.UpCase(sInput[dbIndex]);
           {for-to-do}
  {if-then}

   _fnsUpCase := sInput;
END;
{  _fnsUpCase }


FUNCTION  _fnsDmaTransferModeInfo(dwBitsInfoMode : System.Word) : STRING;
{* Returns string describing a DMA transfer modes supported by drive. *}
VAR
  dbTempValue  :  System.Byte;
  sTemp        :  STRING;

BEGIN
      IF (dwBitsInfoMode <> 0)
        THEN  BEGIN
             dbTempValue := System.Lo(dwBitsInfoMode);
             sTemp := asBlank;
             IF ((dbTempValue AND btBit_0_ON) <> 0)
               THEN  sTemp := sTemp + '0';
             {if-then}
             IF ((dbTempValue AND btBit_1_ON) <> 0)
               THEN  sTemp := sTemp + ',1';
             {if-then}
             IF ((dbTempValue AND btBit_2_ON) <> 0)
               THEN  sTemp := sTemp + ',2';
             {if-then}
             sTemp := sTemp + '(active is ';
             dbTempValue := System.Hi(dwBitsInfoMode);
             IF ((dbTempValue AND btBit_0_ON) <> 0)
               THEN  sTemp := sTemp + '0';
             {if-then}
             IF ((dbTempValue AND btBit_1_ON) <> 0)
               THEN  sTemp := sTemp + ',1';
             {if-then}
             IF ((dbTempValue AND btBit_2_ON) <> 0)
               THEN  sTemp := sTemp + ',2';
             {if-then}
             sTemp := sTemp + ')';
              END
        ELSE
            sTemp := 'none';
      {if-then}
      _fnsDmaTransferModeInfo := sTemp;
END;
{ _fnsDmaTransferModeInfo }

{*=========================== PROCEDURAL PART ==========================*}

PROCEDURE    _OutputMessageNoLF(sMessage : STRING);
{* Writes a message without the linefeed. *}
BEGIN
  System.Write(sMessage);
END;
{ _OutputMessageNoLF }


PROCEDURE    _OutputMessage(sMessage : STRING);
{* Writes a message through the paged stream output. *}
VAR
  sTemp   :   STRING;

BEGIN
   System.WriteLn(sMessage);
   IF (gdwTextLineNum <> aDisableScreenPage)
     THEN  BEGIN
      System.Inc(gdwTextLineNum);
      IF (gdwTextLineNum > gdwMaxScreenLines)
        THEN  BEGIN
	   gdwTextLineNum := aMinOutLineOnScreen;
           System.Write(asProgramPrompt+' Press <ENTER> to continue or type any string to abort:');
           System.ReadLn(sTemp);
           IF (sTemp <> asBlank)
             THEN  BEGIN
                System.WriteLn(asProgramPrompt+' Aborted by user.');
                System.Halt(errUserAbort);
                   END;
           {if-then}
              END;
      {if-then}
            END;
   {if-then}
END;
{ _OutputMessage }


PROCEDURE    _CopyrightDisplay;
{* Outputs the copyright notice. *}
BEGIN
     _OutputMessage(asPurpose+'  Version '+asVersion+',  '+asCopyright+'  '+asAuthor);
END;  { _CopyrightDisplay }


PROCEDURE  _WriteSDH_Val(dwSDH_Reg : System.Word; dbDiskNum : System.Byte);
{* Write a value to sector/drive/head register. *}
VAR
  dbWriteVal  :  System.Byte;

BEGIN
  {* select default modes *}
    dbWriteVal := ((dbDiskNum SHL 4) OR (btCRCmode+btSecSize512)) OR (gdbSDH_TestVal AND $0F);
    gdbSDH_TestVal := dbWriteVal;

  {* output a value *}
    System.Port[dwSDH_Reg] := dbWriteVal;
END; { _WriteSDH_Val }


PROCEDURE  _TestDiskControllerHardware(recRD_HDISK_Regs  : recHDISK_READ_REGS;
                                       recWRT_HDISK_Regs : recHDISK_WRITE_REGS;
                                       dbDiskNum : System.Byte);
{* Test for disk drive controller present. *}
BEGIN
    {* we assume that unsuccess will occurred *}
     gbDiskStatusOK := System.False;

    {* test 1: write value (non-FF) to SDH and read it back*}
    _WriteSDH_Val(recWRT_HDISK_Regs.dwSDH_Reg_WR,dbDiskNum);
     IF (System.Port[recRD_HDISK_Regs.dwStatusReg_RD] = aTestPattern_FF)
        THEN  System.Exit;
     {if-then}

    {* test 2: controller busy? *}
     IF NOT(_fnbControllerIsReady(recRD_HDISK_Regs.dwStatusReg_RD))
        THEN  System.Exit;
     {if-then}

    {* test 3: write wanted value to SDH and read it back *}
      gbDiskStatusOK := System.False;
      System.Port[recWRT_HDISK_Regs.dwSDH_Reg_WR] := gdbSDH_TestVal;
      _IO_DELAY_2;
      IF (System.Port[recRD_HDISK_Regs.dwSDH_Reg_RD] <> gdbSDH_TestVal)
        THEN  System.Exit;
      {if-then}

    {* test 4: write test pattern to SDH and read it back *}
      System.Port[recWRT_HDISK_Regs.dwCylinderLowReg_WR] := aTestPattern_AA;
      _IO_DELAY_2;
      IF (System.Port[recRD_HDISK_Regs.dwCylinderLowReg_RD] <> aTestPattern_AA)
        THEN  System.Exit;
      {if-then}

    {* test 5: write test pattern to SDH and read it back *}
      System.Port[recWRT_HDISK_Regs.dwCylinderLowReg_WR] := aTestPattern_55;
      _IO_DELAY_2;
      IF (System.Port[recRD_HDISK_Regs.dwCylinderLowReg_RD] <> aTestPattern_55)
        THEN  System.Exit;
      {if-then}

    {* test 6: drive ready? *}
       _IO_DELAY_4;
       IF ((System.Port[recRD_HDISK_Regs.dwStatusReg_RD] AND btDriveReady) <> 0)
          THEN  gbDiskStatusOK := System.True;
       {if-then}

END; { _TestDiskControllerHardware }


PROCEDURE  _OutputCommandBlock(VAR recWR_CMD_BLOCK :  recHDISK_WRITE_CMD_BLOCK;
                               dwBaseReg : System.Word);
{* Write all control bytes to registers. *}
BEGIN
  WITH  recWR_CMD_BLOCK  DO
  BEGIN
     System.Port[dwBaseReg+$01] := dbWRC_WR;
     _IO_DELAY_2;
     System.Port[dwBaseReg+$02] := dbSectorCount_WR;
     _IO_DELAY_2;
     System.Port[dwBaseReg+$03] := dbSectorNumber_WR;
     _IO_DELAY_2;
     System.Port[dwBaseReg+$04] := dbCylinderLow_WR;
     _IO_DELAY_2;
     System.Port[dwBaseReg+$05] := dbCylinderHigh_WR;
     _IO_DELAY_2;
     System.Port[dwBaseReg+$06] := dbSDH_WR;
  END;
  {with-do}
END; { _OutputCommandBlock }


PROCEDURE  _HardResetController(dwStatusPort : System.Word);
{* Do a hard reset of controller. *}

PROCEDURE  _WaitOperation(dwWaitCount :  System.Word);
BEGIN
    WHILE (dwWaitCount <> 0) DO
    BEGIN
       _IO_DELAY_8;
        System.Dec(dwWaitCount);
    END;
    {while-do}
END;
{ _WaitOperation }

BEGIN
    System.Port[dwStatusPort] := cmdDisableInts;
    _WaitOperation($4000);
    System.Port[dwStatusPort] := cmdEnableInts;
    _WaitOperation($4000);
END;
{ _HardResetController }

PROCEDURE  _WriteControllerCommand(recRD_HDISK_Regs    :  recHDISK_READ_REGS;
                                   recWRT_HDISK_Regs   :  recHDISK_WRITE_REGS;
                                   recWR_CMD_BLOCK     :  recHDISK_WRITE_CMD_BLOCK);
{* Write a controller command bytes. *}
BEGIN
  {* controller not buzy? *}
     IF NOT(_fnbControllerIsReady(recRD_HDISK_Regs.dwStatusReg_RD))
        THEN  System.Exit;
     {if-then}

  {* enable/disable the controller operations *}
    _HardResetController(gdwAlternateStatus);

  {* write first 6 command bytes to controller *}
    _OutputCommandBlock(recWR_CMD_BLOCK,recWRT_HDISK_Regs.dwDataReg_WR);

  {* is drive ready? *}
     IF NOT(_fnbDriveIsReady(recRD_HDISK_Regs.dwStatusReg_RD))
        THEN  System.Exit;
     {if-then}

  {* write last command byte into controller stack space *}
    _IO_DELAY_2;
    System.Port[recWRT_HDISK_Regs.dwCommand_Reg_WR] :=  recWR_CMD_BLOCK.dbCommand_WR;

END; { _WriteControllerCommand }


PROCEDURE  _InitCommandBlock(VAR recWR_CMD_BLOCK :  recHDISK_WRITE_CMD_BLOCK);
{* Build command block for controller. *}
BEGIN
  WITH  recWR_CMD_BLOCK  DO
  BEGIN
      dbWRC_WR          := $00;             { see tech. ref. of any IDE/ATA drive }
      dbSectorCount_WR  := $00;
      dbSectorNumber_WR := $00;
      dbCylinderLow_WR  := $00;
      dbCylinderHigh_WR := $00;
      dbSDH_WR          := gdbSDH_TestVal;  { std value }
      dbCommand_WR      := cmdIDENTIFY;
  END;
  {with-do}
END; { _InitCommandBlock }


PROCEDURE  _ReadDriveParameters(VAR  recDriveInfoBuf  :  recIDE_Info_Sector;
                                recRD_HDISK_Regs      :  recHDISK_READ_REGS;
                                recWRT_HDISK_Regs     :  recHDISK_WRITE_REGS;
                                recWR_CMD_BLOCK       :  recHDISK_WRITE_CMD_BLOCK;
                                dbDiskNum : System.Byte);
{* Try to issue an IDENTIFY command for IDE/ATA drive. *}
VAR
  dbTestVal  :  System.Byte;

BEGIN

  {* test message *}
    _OutputMessage(asProgramPrompt+' Issue IDENTIFY command.');

  {* make command block for controller *}
   _InitCommandBlock(recWR_CMD_BLOCK);

  {* try to load this command *}
   _WriteControllerCommand(recRD_HDISK_Regs,recWRT_HDISK_Regs,recWR_CMD_BLOCK);
   IF  NOT(gbDiskStatusOK)
      THEN  System.Exit;
   {if-then}

  {* wait data transfer from disk drive *}
   IF NOT(_fnbWaitDRQ(recRD_HDISK_Regs.dwStatusReg_RD))
        THEN  System.Exit;
   {if-then}

  {* get drive info buffer *}
   _ReadDataSector512(recDriveInfoBuf,recWRT_HDISK_Regs.dwDataReg_WR,aWordsPerDosSector);

  {* Reading of status register must be clear IRQ14 latch!!! *}
   dbTestVal := _fndbReadControllerStatus(recRD_HDISK_Regs.dwStatusReg_RD);

END; { _ReadDriveParameters }




PROCEDURE  _InitDiskDriveRegsReadMap(VAR recRD_HDISK_Regs : recHDISK_READ_REGS;
                                     dwDskCtlrBaseReg : System.Word);
{* Initialize disk drive controller registers read map. *}
BEGIN
  WITH  recRD_HDISK_Regs  DO
   BEGIN
       dwDataReg_RD              := dwDskCtlrBaseReg + $00;
       dwErrorReg_RD             := dwDskCtlrBaseReg + $01;
       dwSectorCountReg_RD       := dwDskCtlrBaseReg + $02;
       dwSectorNumberReg_RD      := dwDskCtlrBaseReg + $03;
       dwCylinderLowReg_RD       := dwDskCtlrBaseReg + $04;
       dwCylinderHighReg_RD      := dwDskCtlrBaseReg + $05;
       dwSDH_Reg_RD              := dwDskCtlrBaseReg + $06;
       dwStatusReg_RD            := dwDskCtlrBaseReg + $07;
   END;
  {with-do}
END; { _InitDiskDriveRegsReadMap }


PROCEDURE  _InitDiskDriveRegsWriteMap(VAR recWRT_HDISK_Regs : recHDISK_WRITE_REGS;
                                     dwDskCtlrBaseReg : System.Word);
{* Initialize disk drive controller registers write map. *}
BEGIN
  WITH  recWRT_HDISK_Regs  DO
   BEGIN
      dwDataReg_WR              := dwDskCtlrBaseReg + $00;
      dwWRC_Reg_WR              := dwDskCtlrBaseReg + $01;
      dwSectorCountReg_WR       := dwDskCtlrBaseReg + $02;
      dwSectorNumberReg_WR      := dwDskCtlrBaseReg + $03;
      dwCylinderLowReg_WR       := dwDskCtlrBaseReg + $04;
      dwCylinderHighReg_WR      := dwDskCtlrBaseReg + $05;
      dwSDH_Reg_WR              := dwDskCtlrBaseReg + $06;
      dwCommand_Reg_WR          := dwDskCtlrBaseReg + $07;
   END;
  {with-do}
END; { _InitDiskDriveRegsWriteMap }


PROCEDURE  _DisplayDriveParameters(VAR  recDriveInfoBuf  :  recIDE_Info_Sector; dbDiskNum : System.Byte);
{* Detail info about IDE-drive parameters. *}
VAR
  sTemp                 :       STRING;
  liCalcTotalSectors    :       System.Longint;
  dwCapacityRatio,
  dwCalcParmsCount,
  dwMaxCalcHeadNum,
  dwCalcHeads,
  dwCalcCylinders,
  dwCalcSectors         :       System.Word;
  dbTempValue           :       System.Byte;
  bUserNoAskExit,
  bDisplayEnable        :       System.Boolean;

BEGIN

  {* header message *}
   _OutputMessage(asBlank);
   _OutputMessage(asProgramPrompt+'Screen 1 of 4 -> Disk Drive '+_fnsNumToStr(dbDiskNum,1)+' Internal Information');

  {* general parameters of drive *}
   WITH  recDriveInfoBuf  DO
   BEGIN
      _OutputMessage('-----> Default Translation Mode Parameters <-----');
      _OutputMessage('Fixed Cylinders ...................... '+_fnsNumToStr(dwFixedCylsNum,4));
      IF (dwRemovableCylsNum <> 0)
        THEN  _OutputMessage('Removable Cylinders .................. '+_fnsNumToStr(dwRemovableCylsNum,4));
      {if-then}
      _OutputMessage('R(ead)/W(rite) Heads ................. '+_fnsNumToStr(dwHeadsNum,3));
      _OutputMessage('Unformatted Bytes Per Physical Track.. '+_fnsNumToStr(dwUnfmtdBytesPerPhysTrk,5));
      _OutputMessage('Unformatted Bytes Per Sector.......... '+_fnsNumToStr(dwUnfmtdBytesPerSec,5));
      _OutputMessage('Physical Sectors Per Track............ '+_fnsNumToStr(dwPhysSecsPerTrk,5));

      gliTotalDiskSectors := System.Longint(dwPhysSecsPerTrk) * dwHeadsNum * dwFixedCylsNum;

      _OutputMessage('-----> Controller/Drive/Firmware Information <-----');
      _OutputMessage('Controller/Buffer Type................ '+'Type '+_fnsNumToStr(dwControllerType,5));
      CASE  dwControllerType OF
              $0000   :   _OutputMessage('    (not specified)');
              $0001   :   _OutputMessage('    (single ported single sector buffer)');
              $0002   :   _OutputMessage('    (dual ported multiple sectors buffer)');
              $0003   :   _OutputMessage('    (dual ported multiple sectors buffer with look-ahead read)');
       ELSE
                          _OutputMessage('    (Reserved)');
      END;
      {case-of}
      _OutputMessage('Controller Buffer Size................ '+_fnsNumToStr((dwControllerBufSize DIV 2),5)+
                                                              '.'+
                                                              +_fnsNumToStr((dwControllerBufSize MOD 2)*5,5)+
                                                              ' KB ('+_fnsNumToStr((dwControllerBufSize),3)+' sectors)');
      _OutputMessage('Controller Firmware Revision ......... '+
                     _fnsAsciiInfo(System.Ptr(Seg(dbCntlrFirmwareRevision),
                                   System.Ofs(dbCntlrFirmwareRevision)),
                                   dbCntlrFirmwareRevisionLen,System.True));
      _OutputMessage('Serial Number ........................ '+
                     _fnsAsciiInfo(System.Ptr(Seg(dbSerialNumber),System.Ofs(dbSerialNumber)),dbSerialNumberLen,System.True));
      _OutputMessage('Model Number ......................... '+
                     _fnsAsciiInfo(System.Ptr(Seg(dbModelNumber),System.Ofs(dbModelNumber)),dbModelNumberLen,System.True));

      _OutputMessage('-----> Miscellaneous Drive Transfer Information <-----');
      _OutputMessage('ECC bytes............................. '+_fnsNumToStr(dwECCbytes,5));
      _OutputMessageNOLF('Max. Secs/Interrupt for R/W MultiMode. ');
      IF (System.Hi(dwSecsPerIntr) <> 0)
        THEN
          _OutputMessage(_fnsNumToStr((System.Lo(dwSecsPerIntr)),3)+' sectors')
        ELSE
          _OutputMessage('not supported');
      {if-then-else}
      _OutputMessageNOLF('Current Secs/Int for R/W MultiMode.... ');
      IF ((dwMultipleSecsModeXfrSettings AND btBit_8_ON) = 0)
        THEN  _OutputMessage('not valid')
        ELSE  _OutputMessage('valid ('+_fnsNumToStr((System.Lo(dwMultipleSecsModeXfrSettings)),3)+' sectors/int)');
      {if-then-else}
      _OutputMessageNoLF('Double Word Transfer Flag............. ');
      CASE dwDoubleWordTransferFlag OF
               0    :    _OutputMessage('not supported');
               1    :    _OutputMessage('supported');
      ELSE
         _OutputMessage(achHexPrefix+_fnsWordToHexFmt(dwDoubleWordTransferFlag)+' = unknown');
      END;
      {case-of}
      _OutputMessageNoLF('Assign Alternate...................... ');
      CASE System.Lo(dwAssignAlternate) OF
               0    :    _OutputMessage('not supported');
               1    :    _OutputMessage('supported');
      ELSE
         _OutputMessage(achHexPrefix+_fnsWordToHexFmt(dwAssignAlternate)+' (unknown, VU)');
      END;
      {case-of}
      _OutputMessageNoLF('D(irect) M(emory) A(ccess) support.... ');
      IF ((System.Hi(dwAssignAlternate) AND btBit_8_ON) = 0)
        THEN  _OutputMessage('no')
        ELSE  _OutputMessage('yes');
      {if-then-else}
      _OutputMessageNoLF('L(ogical) B(lock) A(ddressing) found.. ');
      IF ((System.Hi(dwAssignAlternate) AND btBit_9_ON) = 0)
        THEN  _OutputMessage('no')
        ELSE  _OutputMessage('yes');
      {if-then-else}
      IF (dwPIODataXFRCycleTimingMode <> 0)
        THEN  BEGIN
          _OutputMessageNOLF('PIO Data Transfer Cycle Timing Mode... ');
          dbTempValue := System.Hi(dwPIODataXFRCycleTimingMode);
          sTemp := 'mode 0';
          IF ((240 <= dbTempValue) AND (dbTempValue < 383))
            THEN  sTemp := 'mode 2';
          {if-then}
          IF ((383 <= dbTempValue) AND (dbTempValue < 600))
            THEN  sTemp := 'mode 1';
          {if-then}
          _OutputMessage(sTemp+' ('+_fnsNumToStr(dbTempValue,5)+' ns)');
              END;
      {if-then}
      IF (dwDMADataXFRCycleTimingMode<> 0)
        THEN  BEGIN
          _OutputMessageNOLF('DMA Data Transfer Cycle Timing Mode... ');
          dbTempValue := System.Hi(dwPIODataXFRCycleTimingMode);
          sTemp := 'mode 0';
          IF ((240 <= dbTempValue) AND (dbTempValue < 383))
            THEN  sTemp := 'mode 2';
          {if-then}
          IF ((383 <= dbTempValue) AND (dbTempValue < 600))
            THEN  sTemp := 'mode 1';
          {if-then}
          _OutputMessage(sTemp+' ('+_fnsNumToStr(dbTempValue,5)+' ns)');
              END;
      {if-then}
      _OutputMessage('Total sectors per drive (LBA mode).... '+_fnsNumToStr(ddTotalUserSecsInLBA_Mode,8));
      _OutputMessage('Single Word DMA Data Transfer Modes... '+_fnsDmaTransferModeInfo(dwSingleWordDMA_XfrMode));
      _OutputMessage('Multi-Word DMA Data Transfer Modes.... '+_fnsDmaTransferModeInfo(dwMultiWordDMA_XfrMode));

      _OutputMessage('-----> V(endor) U(nique) Fields for Drive <-----');
      IF (dwInterSecGapBytesNumVU <> 0)
        THEN  _OutputMessage('Inter-Sector Gap Bytes................ '+_fnsNumToStr(dwInterSecGapBytesNumVU,5));
      {if-then}
      IF (dwSyncFieldsBytesNumVU <> 0)
        THEN  _OutputMessage('Bytes in Synch Fields................. '+_fnsNumToStr(dwSyncFieldsBytesNumVU,5));
      {if-then}
      IF (dwPLObyteNumVU <> 0)
        THEN  _OutputMessage('Min. PLO Bytes........................ '+_fnsNumToStr(dwPLObyteNumVU,5));
      {if-then}
      _OutputMessage('Vendor Unique Text Field..............');
      _OutputMessage('  '+
          _fnsAsciiInfo(System.Ptr(Seg(dbVendorUniqueInfoText),System.Ofs(dbVendorUniqueInfoText)),
                        dbVendorUniqueInfoTextLen,System.False));

      _OutputMessage('-----> Current Translation Mode Parameters <-----');
      _OutputMessageNoLF('Settings for this mode................ ');
      IF ((dwCurrentSettingsValidFlag AND btBit_0_ON) = 0)
        THEN  _OutputMessage('may be valid')
        ELSE  _OutputMessage('valid');
      {if-then}
      _OutputMessage('Current Cylinders Number.............. '+_fnsNumToStr(dwCurrentCylsNum,4));
      _OutputMessage('Current Heads Number.................. '+_fnsNumToStr(dwCurrentHeadsNum,3));
      _OutputMessage('Current Sectors Per Track Number...... '+_fnsNumToStr(dwCurrentSecsPerTrack,5));
      _OutputMessage('Current total sectors per drive ...... '+_fnsNumToStr(ddCurrentDriveCapacityInSecs,8));

      _OutputMessage('-----> Calculated Parameters for This Drive <-----');
      _OutputMessage('Total sectors per phys. drive (calc).. '+_fnsNumToStr(gliTotalDiskSectors,8));
      _OutputMessage('Unformatted Drive Capacity (calc)..... '+
                     +_fnsNumToRealStr((System.Longint(dwUnfmtdBytesPerPhysTrk)*dwHeadsNum*dwFixedCylsNum) /
                       (aBytesPerKByte*aKBytesPerMByte),5,2)+
                     ' MBytes');
      _OutputMessage('Expected DOS Drive Capacity (calc).... '+
                     +_fnsNumToRealStr((System.Longint(dwPhysSecsPerTrk)*dwHeadsNum*dwFixedCylsNum*aBytesPerDosSector) /
                       (aBytesPerKByte*aKBytesPerMByte),5,2)+
                     ' MBytes');
     _OutputMessage(asBlank);

   {* configuration info for drive *}
     _OutputMessage(asProgramPrompt+'Screen 2 of 4 -> Internal Configuration Flags Map for Drive '+_fnsNumToStr(dbDiskNum,1));
     _OutputMessage('Configuration Flags................... '+achHexPrefix+_fnsWordToHexFmt(dwGeneralConfigFlags));
     IF ((dwGeneralConfigFlags AND btBit_1_ON) = 0)
       THEN  _OutputMessage('... Non-hard sectored')
       ELSE  _OutputMessage('... Hard sectored');
     {if-then-else}
     IF ((dwGeneralConfigFlags AND btBit_2_ON) = 0)
       THEN  _OutputMessage('... Non-soft sectored')
       ELSE  _OutputMessage('... Soft sectored');
     {if-then-else}
     IF ((dwGeneralConfigFlags AND btBit_3_ON) = 0)
       THEN  _OutputMessage('... MFM encoded')
       ELSE  _OutputMessage('... Non-MFM encoded');
     {if-then-else}
     IF ((dwGeneralConfigFlags AND btBit_4_ON) = 0)
       THEN  _OutputMessage('... Head switch time <= 15 us')
       ELSE  _OutputMessage('... Head switch time > 15 us');
     {if-then-else}
     IF ((dwGeneralConfigFlags AND btBit_5_ON) = 0)
       THEN  _OutputMessage('... Spindle motor control option not implemented')
       ELSE  _OutputMessage('... Spindle motor control option implemented');
     {if-then-else}
     IF ((dwGeneralConfigFlags AND btBit_6_ON) = 0)
       THEN  _OutputMessage('... Non-fixed disk drive')
       ELSE  _OutputMessage('... Fixed disk drive');
     {if-then-else}
     IF ((dwGeneralConfigFlags AND btBit_7_ON) = 0)
       THEN  _OutputMessage('... Non-removable cartridge drive')
       ELSE  _OutputMessage('... Removable cartridge drive');
     {if-then-else}
     IF ((dwGeneralConfigFlags AND btBit_8_ON) = 0)
       THEN  _OutputMessage('... Transfer rate > 5 Mb/sec')
       ELSE  _OutputMessage('... Transfer rate <= 5 Mb/sec');
     {if-then-else}
     IF ((dwGeneralConfigFlags AND btBit_9_ON) = 0)
       THEN  _OutputMessage('... NOT (5 Mb/sec < Transfer rate <= 10 Mb/sec)')
       ELSE  _OutputMessage('... 5 Mb/sec < Transfer rate <= 10 Mb/sec');
     {if-then-else}
     IF ((dwGeneralConfigFlags AND btBit_A_ON) = 0)
       THEN  _OutputMessage('... Transfer rate < 10 Mb/sec')
       ELSE  _OutputMessage('... Transfer rate >= 10 Mb/sec');
     {if-then-else}
     IF ((dwGeneralConfigFlags AND btBit_B_ON) = 0)
       THEN  _OutputMessage('... Rotational speed tolerance <= 0.5%')
       ELSE  _OutputMessage('... Rotational speed tolerance > 0.5%');
     {if-then-else}
     IF ((dwGeneralConfigFlags AND btBit_C_ON) = 0)
       THEN  _OutputMessage('... Data strobe offset option not implemented')
       ELSE  _OutputMessage('... Data strobe offset option implemented');
     {if-then-else}
     IF ((dwGeneralConfigFlags AND btBit_D_ON) = 0)
       THEN  _OutputMessage('... Track offset option not implemented')
       ELSE  _OutputMessage('... Track offset option implemented');
     {if-then-else}
     IF ((dwGeneralConfigFlags AND btBit_E_ON) = 0)
       THEN  _OutputMessage('... Format speed tolerance gap not required')
       ELSE  _OutputMessage('... Format speed tolerance gap required');
     {if-then-else}
     IF ((dwGeneralConfigFlags AND btBit_F_ON) = 0)
       THEN  _OutputMessage('... Magnetic disk drive')
       ELSE  _OutputMessage('... Non-magnetic disk drive');
     {if-then-else}
     _OutputMessage(asBlank);

   {* suggested CMOS parameters for drive *}
     _OutputMessage(asProgramPrompt+'Screen 3 of 4 -> Suggested CMOS parameters for Drive '+_fnsNumToStr(dbDiskNum,1));
     bUserNoAskExit := System.True;
     IF (gbFindAllOk)
       THEN  dwCalcSectors := aMinBiosSecNum
       ELSE  dwCalcSectors := aDefStdDosBiosSecNum;
     {if-then-else}

     WHILE  (bUserNoAskExit) DO
     BEGIN
         dwMaxCalcHeadNum := dwHeadsNum * (dwPhysSecsPerTrk DIV dwCalcSectors);
         dwCalcHeads := aStartHeadNum;
         dwCalcParmsCount := 0;
         _OutputMessage(asProgramPrompt+
                        'Find match drive parameters if number of sectors = '+
                       _fnsNumToStr(dwCalcSectors,5));
         _OutputMessage(' --- Cyls --- Hds --- Secs --- Calc/Actual/Percentage (total secs) ---');

         REPEAT
           {* calculate # of cyls at fixed # of secs/heads *}
            dwCalcCylinders :=  gliTotalDiskSectors DIV (dwCalcSectors*dwCalcHeads);
            liCalcTotalSectors := System.Longint(dwCalcSectors * dwCalcHeads) * dwCalcCylinders;

           {* check if match parameters present before output *}
            IF ((dwCalcCylinders <> 0) AND
               (dwCalcCylinders <= aMaxBiosCylNum) AND
               (dwCalcHeads <= aMaxBiosHeadNum)  AND
               (dwCalcSectors <= aMaxBiosSecNum))
              THEN  BEGIN
		dwCapacityRatio := (liCalcTotalSectors*aPercent100) DIV gliTotalDiskSectors;
		bDisplayEnable := System.True;
		IF ((gbFindMaxOk) AND (dwCapacityRatio <> aPercent100))
		   THEN  BEGIN
		     bDisplayEnable := System.False;
			 END;
		{if-then}

		IF (bDisplayEnable)
		   THEN  BEGIN
               System.Inc(dwCalcParmsCount);
               _OutputMessage('     '+_fnsNumToStrNoAdj(dwCalcCylinders,4)+
                              '     '+_fnsNumToStrNoAdj(dwCalcHeads,3)+
                              '      '+_fnsNumToStrNoAdj(dwCalcSectors,2)+
                              '       '+_fnsNumToStrNoAdj(liCalcTotalSectors,8)+
                              ' / '+_fnsNumToStr(gliTotalDiskSectors,8)+
                              ' / '+_fnsNumToRealStr(((liCalcTotalSectors*aPercent100) / gliTotalDiskSectors),2,2)+
                              '    ('+
                              +_fnsNumToRealStr((System.Longint(dwCalcSectors)*dwCalcHeads*
                                                dwCalcCylinders*aBytesPerDosSector) /
                                                (aBytesPerKByte*aKBytesPerMByte),5,2)+
                                                ' MB)');
			 END;
		{if-then}
                    END;
            {if-then}
            System.Inc(dwCalcHeads);
         UNTIL (dwCalcHeads > dwMaxCalcHeadNum);
         {repeat-until}

         {* display this message if none parameters are matching *}
         IF (dwCalcParmsCount = 0)
           THEN  _OutputMessage(' No match parameters found');
         {if-then}
         _OutputMessage(asBlank);

       {* ask user about other possible disk types based on sector/track *}
         IF (gdwMaxScreenLines <> aDisableScreenPage)
           THEN  BEGIN
             _OutputMessageNoLF(asProgramPrompt+'Enter number of sectors (CR=exit): ');
             System.ReadLn(sTemp);
                 END
           ELSE
             sTemp := asBlank;
         {if-then-else}

         IF (sTemp <> asBlank)
            THEN  BEGIN
              System.Val(sTemp,dwCalcSectors,giErrorCode);
              IF (giErrorCode <> 0) OR (dwCalcSectors = 0)
                THEN  BEGIN
                   System.WriteLn(asProgramPrompt+' Bad value for sectors number.');
                   System.Halt(errBadSecsNum);
                     END;
              {if-then}
                 END
            ELSE
               bUserNoAskExit := System.False;
         {if-then-else}

         IF (gbFindAllOk)
           THEN BEGIN
              System.Inc(dwCalcSectors);
              IF (dwCalcSectors <= aMaxBiosSecNum)
                THEN  bUserNoAskExit := System.True;
              {if-then}
                END;
         {if-then}

     END;
     {while-do}

   END;
   {with-do}

END; { _DisplayDriveParameters }


PROCEDURE  _WriteBufToFile(VAR  recDriveInfoBuf  :  recIDE_Info_Sector);
{* Detail info about IDE-drive parameters. *}
VAR
   recDriveInfOutputStream      :   FILE  OF  recIDE_Info_Sector;
   sFileName                    :   STRING;

BEGIN
   _OutputMessageNoLF(asProgramPrompt+' Enter filename (def.ext.='+asDefExt+'): ');
   System.ReadLn(sFileName);
   IF (sFileName <> asBlank)
   THEN BEGIN
     sFileName := _fnsForceFileExtension(sFileName,asDefExt);
     System.Assign(recDriveInfOutputStream,sFileName);
     System.Rewrite(recDriveInfOutputStream);
     System.Write(recDriveInfOutputStream,recDriveInfoBuf);
     System.Close(recDriveInfOutputStream);
        END;
   {if-then}
END;
{ _WriteBufToFile }


PROCEDURE  _ScanDrive(VAR  recDriveInfoBuf  :  recIDE_Info_Sector;
                      recRD_HDISK_Regs      :  recHDISK_READ_REGS;
                      recWRT_HDISK_Regs     :  recHDISK_WRITE_REGS;
                      recWR_CMD_BLOCK       :  recHDISK_WRITE_CMD_BLOCK;
                      dwDriveCtrlrBaseReg   :  System.Word;
                      dbDiskIncVal          :  System.Byte;
                      dbDiskNum             :  System.Byte;
                      sCtlr                 :  STRING);
{* Test the disk drive. *}
BEGIN

  {* try drive/controller *}
     gdbSDH_TestVal := (btCRCmode+btSecSize512);
    _InitDiskDriveRegsReadMap(grecRD_HDISK_Regs,dwDriveCtrlrBaseReg);
    _InitDiskDriveRegsWriteMap(grecWRT_HDISK_Regs,dwDriveCtrlrBaseReg);
    _TestDiskControllerHardware(grecRD_HDISK_Regs,grecWRT_HDISK_Regs,dbDiskNum);

     IF (gbDiskStatusOK)
       THEN  BEGIN
           _OutputMessage(asProgramPrompt+' IDE/ATA drive '+_fnsNumToStr(dbDiskNum,1)+' found  (primary controller)');
          _ReadDriveParameters(grecDriveInfoBuf, grecRD_HDISK_Regs,
                               grecWRT_HDISK_Regs, grecWR_CMD_BLOCK,
                               dbDiskNum);
          IF  (gbDiskStatusOK)
             THEN  BEGIN
               System.Inc(gdbIDE_Disks_Count,dbDiskIncVal);
               _DisplayDriveParameters(grecDriveInfoBuf,dbDiskNum);
               IF (gbFileWriteOk)
                 THEN  _WriteBufToFile(grecDriveInfoBuf);
               {if-then}
                   END
             ELSE
                _OutputMessage(asProgramPrompt+' IDENTIFY command failed.');
          {if-then-else}
             END
       ELSE
           _OutputMessage(asProgramPrompt+' No hardware for drive '+_fnsNumToStr(dbDiskNum,1)+
                          ' ('+sCtlr+' controller)');
     {if-then-else}

END; { _ScanDrive }


PROCEDURE  _Disp_IDE_disks_Count(dbIDE_Disks_Count : System.Byte);
{* Output # of IDE-disks in the system. *}
CONST
  dbDiskCount  :  System.Byte   =   0;

BEGIN
  {* counts the disks *}
    IF (dbIDE_Disks_Count AND btIdeDrive_00) <> 0
      THEN  System.Inc(dbDiskCount);
    {if-then}
    IF (dbIDE_Disks_Count AND btIdeDrive_01) <> 0
      THEN  System.Inc(dbDiskCount);
    {if-then}
    IF (dbIDE_Disks_Count AND btIdeDrive_02) <> 0
      THEN  System.Inc(dbDiskCount);
    {if-then}
    IF (dbIDE_Disks_Count AND btIdeDrive_03) <> 0
      THEN  System.Inc(dbDiskCount);
    {if-then}

  {* display total *}
    _OutputMessage(asProgramPrompt+' '+_fnsNumToStr(dbDiskCount,1)+' IDE/ATA-drive(s) found for this computer system.');

END; { _Disp_IDE_disks_Count }



{*============================== MAIN PART =============================*}

BEGIN

  {* simple test for CPU type *}
    giErrorCode := 0;
    asm
          push    sp
          pop     ax

          cmp     ax, sp
          je      @CPU186

          mov     giErrorCode, -1
       @CPU186:
    end;
    {asm-end}
    IF (giErrorCode <> 0)
          THEN  BEGIN
             System.WriteLn(asProgramPrompt+' Requires Intel 80186 processor or higher.');
             System.Halt(errBadCPU);
          END;
    {if-then}

  {* init some variables *}
    IF  (System.ParamCount > 1)
      THEN  BEGIN
       IF (_fnsUpCase(System.ParamStr(2)) <> asNoFileToAsk)
         THEN  gbFileWriteOk := System.True;
       {if-then}
            END;
    {if-then}

    IF  (System.ParamCount > 2)
      THEN  BEGIN
	  gsTemp := _fnsUpCase(System.ParamStr(3));
          gbFindCMOSOk := System.True;
          IF  (gsTemp <> asHddTableDisplayOnly)
            THEN  gbFindAllOk  := System.True;
	  {if-then}
          IF  (gsTemp = asMaxCapacityOnly)
            THEN  gbFindMaxOk  := System.True;
          {if-then}
            END;
    {if-then}

    IF  (System.ParamCount <> 0)
      THEN  BEGIN
        System.Val(System.ParamStr(1),gdwMaxScreenLines,giErrorCode);
        IF (giErrorCode <> 0)
          THEN  BEGIN
             System.WriteLn(asProgramPrompt+' Bad value for screen lines.');
             System.Halt(errBadNumeric);
                END
        ELSE  IF (gdwMaxScreenLines = aDisableScreenPage)
                THEN  gdwTextLineNum := aDisableScreenPage;
              {if-then}
        {if-then-else}
            END;
    {if-then}

    gdbIDE_Disks_Count := 0;
    gdwAlternateStatus    := aAltDriveStatusReg_0;


   {* copyright message *}
    _CopyrightDisplay;


  {* try drive 0 hardware/primary controller *}
    _ScanDrive(grecDriveInfoBuf,
               grecRD_HDISK_Regs,
               grecWRT_HDISK_Regs, grecWR_CMD_BLOCK,
               aDriveCtrlrBaseReg_0,
               btIdeDrive_00,
               aPhysDriveNum_0,
               asPrimary);


  {* try drive 1 hardware/primary controller *}
    _ScanDrive(grecDriveInfoBuf,
               grecRD_HDISK_Regs,
               grecWRT_HDISK_Regs, grecWR_CMD_BLOCK,
               aDriveCtrlrBaseReg_1,
               btIdeDrive_01,
               aPhysDriveNum_1,
               asPrimary);


  {* init some vars *}
    gdwAlternateStatus    := aAltDriveStatusReg_1;


  {* try drive 0 hardware/secondary controller *}
      _ScanDrive(grecDriveInfoBuf,
               grecRD_HDISK_Regs,
               grecWRT_HDISK_Regs, grecWR_CMD_BLOCK,
               aDriveCtrlrBaseReg_2,
               btIdeDrive_02,
               aPhysDriveNum_0,
               asSecondary);


  {* try drive 1 hardware/secondary controller *}
      _ScanDrive(grecDriveInfoBuf,
               grecRD_HDISK_Regs,
               grecWRT_HDISK_Regs, grecWR_CMD_BLOCK,
               aDriveCtrlrBaseReg_3,
               btIdeDrive_03,
               aPhysDriveNum_1,
               asSecondary);

  {* display ROM CMOS HDD types table *}
     IF  (NOT(gbFindCMOSOk) AND
          NOT(gbFindAllOk)  AND
          (gdwMaxScreenLines <> aDisableScreenPage))
       THEN BEGIN
         _OutputMessage(asBlank);
         _OutputMessageNoLF(asProgramPrompt+'Display ROM BIOS HDD types table? (N/Y): ');
         System.ReadLn(gsTemp);
         gsTemp := _fnsUpCase(gsTemp);
         IF ((gsTemp <> asBlank) AND (gsTemp[1] = 'Y'))
            THEN gbFindCMOSOk := System.True;
         {if-then}
            END;
     {if-then}

     IF (gbFindCMOSOk)
       THEN BEGIN
         _OutputMessage(asBlank);
         _OutputMessage(asProgramPrompt+'Screen 4 of 4 -> ROM BIOS HDD types table for CMOS drive types');
         _OutputMessage(' -- Type -- Cyls -- Hds -- WRC -- Secs -- Cntrl -- LZone -- TotalSecs -- MB --');
         FOR  gdwIndex := aMinHDD_CMOSType  TO  aMaxHDD_CMOSType  DO
          WITH  recHARD_DISK_PARMS(gdbROM_BIOS_HDD_TYPES_TABLE[gdwIndex])  DO
           BEGIN
               gliTotalDiskSectors := System.Longint(dbSECTORS_PER_TRACK) * dbMAX_HEADS_NUM * dwMAX_CYLS_NUM;
               _OutputMessage('     '+_fnsNumToStrNoAdj(gdwIndex,2)+
                              '    '+_fnsNumToStrNoAdj(dwMAX_CYLS_NUM,4)+
                              '    '+_fnsNumToStrNoAdj(dbMAX_HEADS_NUM,3)+
                              '    '+_fnsNumToStrNoAdj(dwSTART_WRC,5)+
                              '    '+_fnsNumToStrNoAdj(dbSECTORS_PER_TRACK,2)+
                              '     '+_fnsNumToStrNoAdj(dbCONTROL_BYTE,3)+
                              '      '+_fnsNumToStrNoAdj(dwLANDING_ZONE,4)+
                              '    '+_fnsNumToStrNoAdj(gliTotalDiskSectors,8)+
                              '    '+_fnsNumToRealStr(((gliTotalDiskSectors*aBytesPerDosSector) /
                                                       (aBytesPerKByte*aKBytesPerMByte)),5,2));
            END;
           {with-do}
          {for-to-do}
         _OutputMessage(asBlank);
            END;
     {if-then}

  {* find the number of hard disk drives reported by SYSTEM BIOS *}
    _OutputMessage(asProgramPrompt+' '+_fnsNumToStr(gdbBIOS_Drives_Num,1)+
                   ' hard disk drive(s) found by the System BIOS.');

  {** last report  **}
    _Disp_IDE_disks_Count(gdbIDE_Disks_Count);
    _OutputMessage(asProgramPrompt+'Done.');

  {* write a true value for Sector/Drive/Head: this must be reset a micro-code logic to defaults *}
   IF  ((gdbIDE_Disks_Count AND (btIdeDrive_02 OR btIdeDrive_03)) <> 0)
      THEN  System.Port[aDriveCtrlrBaseReg_2+$06] := (btCRCmode+btSecSize512);
   {if-then}
   IF  ((gdbIDE_Disks_Count AND (btIdeDrive_00 OR btIdeDrive_01)) <> 0)
      THEN  System.Port[aDriveCtrlrBaseReg_0+$06] := (btCRCmode+btSecSize512);
   {if-then}

  {* System.Halt(errTerminateOk); *}

END.
