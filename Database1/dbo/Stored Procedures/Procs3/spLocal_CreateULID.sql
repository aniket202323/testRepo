   /*  
  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Peron, System technologies for industry  
Date   : 2005-10-27  
Version  : 1.0.1  
Purpose  : Nocount + version  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
Stored Procedure: spLocal_CreateULID  
Author:   Matthew Wells (MSI)  
Date Created:  10/23/01  
  
Description:  
=========  
Calculates the ULID + check bit.  
  
Change Date Who What  
=========== ==== =====  
10/23/01 MKW Created procedure  
*/  
CREATE Procedure dbo.spLocal_CreateULID  
@Output_Value  varchar(25) OUTPUT, -- ULID  
@Header  varchar(25),  -- ULID Header  
@SN   int   -- Serial Number  
As  
  
SET NOCOUNT ON  
  
Declare @ULID   varchar(25),  
 @ULID_Length  int,  
 @SN_Length  int,  
 @Check  int,  
 @SN_String  varchar(25),  
 @ULID_01  int,  
 @ULID_02  int,  
 @ULID_03  int,  
 @ULID_04  int,  
 @ULID_05  int,  
 @ULID_06  int,  
 @ULID_07  int,  
 @ULID_08  int,  
 @ULID_09  int,  
 @ULID_10  int,  
 @ULID_11  int,  
 @ULID_12  int,  
 @ULID_13  int,  
 @ULID_14  int,  
 @ULID_15  int,  
 @ULID_16  int,  
 @ULID_17  int,  
 @ULID_18  int,  
 @ULID_19  int  
  
/* Initialization */  
Select  @ULID_Length = 19,  
 @SN_Length = @ULID_Length - Len(@Header)  
  
/* Put together base ULID */  
Select @SN_String = convert(varchar(25), @SN)  
Select @ULID = @Header + Replicate('0', @SN_Length - Len(@SN_String)) + @SN_String  
       
/* Calculate and append check bit */  
If Len(@ULID) = @ULID_Length And IsNumeric(@ULID) = 1  
     Begin  
     Select @ULID_01 = Convert(int, Substring(@ULID, 1, 1)),  
  @ULID_02 = Convert(int, Substring(@ULID, 2, 1)),  
  @ULID_03 = Convert(int, Substring(@ULID, 3, 1)),  
  @ULID_04 = Convert(int, Substring(@ULID, 4, 1)),  
  @ULID_05 = Convert(int, Substring(@ULID, 5, 1)),  
  @ULID_06 = Convert(int, Substring(@ULID, 6, 1)),  
  @ULID_07 = Convert(int, Substring(@ULID, 7, 1)),  
  @ULID_08 = Convert(int, Substring(@ULID, 8, 1)),  
  @ULID_09 = Convert(int, Substring(@ULID, 9, 1)),  
  @ULID_10 = Convert(int, Substring(@ULID, 10, 1)),  
  @ULID_11 = Convert(int, Substring(@ULID, 11, 1)),  
  @ULID_12 = Convert(int, Substring(@ULID, 12, 1)),  
  @ULID_13 = Convert(int, Substring(@ULID, 13, 1)),  
  @ULID_14 = Convert(int, Substring(@ULID, 14, 1)),  
  @ULID_15 = Convert(int, Substring(@ULID, 15, 1)),  
  @ULID_16 = Convert(int, Substring(@ULID, 16, 1)),  
  @ULID_17 = Convert(int, Substring(@ULID, 17, 1)),  
  @ULID_18 = Convert(int, Substring(@ULID, 18, 1)),  
  @ULID_19 = Convert(int, Substring(@ULID, 19, 1))  
  
     Select @Check = @ULID_01+@ULID_03 +@ULID_05+@ULID_07+@ULID_09+@ULID_11+@ULID_13+@ULID_15+@ULID_17+@ULID_19  
     Select @Check = @Check * 3  
     Select @Check = @Check+@ULID_02+@ULID_04 +@ULID_06+@ULID_08+@ULID_10+@ULID_12+@ULID_14+@ULID_16+@ULID_18  
     Select @Check = 10 - (@Check % 10)  
     Select @Output_Value = @ULID + right(convert(varchar(10), @Check), 1)  
     End  
Else  
     Select @Output_Value = @ULID + 'X'  
  
SET NOCOUNT OFF  
  
