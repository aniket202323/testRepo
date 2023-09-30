   /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-23  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
     Replace temp table for table variable   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_CreateArray  
Author:   Matthew Wells (MSI)  
Date Created:  08/13/02  
  
Description:  
=========  
Creates an array based off any manually entered tests for variables that are defined as dependencies for the calling calculation.  
There can be a maximum of 100 elements in the profile.  
  
Change Date Who What  
=========== ==== =====  
05/13/03 MKW Write a null value to the source var id if there are no elements defined.  
*/  
  
CREATE procedure dbo.spLocal_CreateArray  
@Output_Value  varchar(25) OUTPUT,  
@Source_Var_Id int,  
@TimeStamp  datetime  
AS  
SET NOCOUNT ON  
/* Testing  
Select  @Source_Var_Id = 18436,  
 @TimeStamp = '2002-08-11 23:03:37'  
*/  
  
Declare @PU_Id   int,  
 @User_Id   int,  
 @Transaction_Type  int,  
 @Test_Id   int,  
 @Test_Array_Id   int,  
 @Array_Id   int,  
 @Value_Str   varchar(25),  
 @Value    float,  
 @Total    float,  
 @Precision   int,  
 @Data_Type_Id   int,  
 @Result   varchar(25),  
 @Data    binary(8),  
 @Data_Array   varbinary(800),  
 @Data_Size   int,  
 @PctGood   binary(4),  
 @PctGood_Size   int,  
 @PctGood_Array  varbinary(400),  
 @Count    int,  
 @Byte    binary,  
 @Byte_Count   int,  
 @Output   binary(8),  
 @Sign    int,  
 @Byte0    binary,  
 @Byte1    binary,  
 @Byte2    binary,  
 @Byte3    binary,  
 @Byte4    binary,  
 @Byte5    binary,  
 @Byte6    binary,  
 @Byte7    binary,  
 @Byte_Bit   int,  
 @Exponent   int,  
 @Exponent_Bit   int ,  
 @Base    float,  
 @Mantissa   decimal(16,0),  
 @Mantissa_Bit   decimal(16,0),  
 @Mantissa_Size   int,  
 @Bias    int,  
 @Mantissa_Shift  int,  
 @AppVersion   varchar(30)  
   
  
 -- Get the Proficy database version  
 SELECT @AppVersion = App_Version FROM [dbo].[AppVersions] WHERE App_Name = 'Database'   
  
  
DECLARE @Profile TABLE(  
 Profile_Id  int Identity,  
 Result   varchar(25)  
)  
DECLARE @VariableRS TABLE(  
 Var_Id    int,  
 PU_Id     int,  
 User_Id       int,  
 Canceled    int,  
 Result    varchar(25),  
 Result_On   datetime,  
 Trans_Type   int,  
 Post_Update   int,  
 SecondUserId  int Null,  
 TransNum    int Null,  
 EventId    int Null,  
 ArrayId    int Null,  
 CommentId   int Null  
)  
/* Initialize */  
Select  @Array_Id  = Null,  
 @Test_Id  = Null,  
 @Test_Array_Id  = Null,  
 @Data_Size  = 8,  
 @Data_Array  = Null,  
 @PctGood   = 0x0000C842,  
 @PctGood_Size  = 4,  
 @PctGood_Array = Null,  
 @Count   = 0,  
 @Precision  = 2,  
 @Base   = 2.0,  
 @Mantissa_Size  = 52,  
 @Bias   = 1023,  
 @Exponent_Bit  = 2048,   -- 2^11 = Largest Exponent + 1  
 @Mantissa_Bit  = 4503599627370496 -- 2^52 = Largest Mantissa + 1  
  
-- user id for the resulset  
SELECT @User_id = User_id   
FROM [dbo].Users  
WHERE username = 'Reliability System'  
  
/* Get variable configuration */  
Select  @PU_Id  = PU_Id,  
 @Precision  = Var_Precision,  
 @Data_Type_Id  = Data_Type_Id  
From [dbo].Variables  
Where Var_Id = @Source_Var_Id  
  
/* Get existing array Id */  
Select  @Test_Id = Test_Id,   
 @Test_Array_Id = Array_Id  
From [dbo].tests  
Where Var_Id = @Source_Var_Id And Result_On = @TimeStamp  
  
/* Get profile data and sort by profile var desc */  
Insert Into @Profile (Result)  
Select TOP 100 t.Result  
From [dbo].Variables v  
     Inner Join [dbo].Calculation_Instance_Dependencies cid On cid.Var_Id = v.Var_Id  
     Inner Join [dbo].tests t On t.Var_Id = v.Var_Id   
Where cid.Result_Var_Id = @Source_Var_Id And t.Result_On = @TimeStamp And t.Result Is Not Null  
Order By v.Var_Desc Asc  
  
If @@ROWCOUNT > 0 And @Data_Type_Id = 7  
     Begin  
     -- Create binary arrays for data and percent good  
     Declare DataProfile Cursor For  
     Select Result  
     From @Profile  
     Order By Profile_Id Asc  
     For Read Only  
  
     Open DataProfile  
     Fetch Next From DataProfile Into @Value_Str  
     While @@FETCH_STATUS = 0 And isnumeric(@Value_Str) = 1  
          Begin  
          Select @Value = convert(float, @Value_Str)  
  
          /*****************************************************************************************  
          *                                Convert float to binary                                  *  
          *****************************************************************************************/  
          /* Reinitialize */  
          Select @Sign  = 0,  
      @Byte0  = 0,  
      @Byte1  = 0,  
      @Byte2  = 0,  
      @Byte3  = 0,  
      @Byte4  = 0,  
      @Byte5  = 0,  
      @Byte6  = 0,  
      @Byte7  = 0,  
      @Output_Value = 0  
  
          /* Set sign bit and then drop the sign */  
          If @Value < 0  
               Select @Sign = 128  
          Select @Value = abs(@Value)  
  
          /* Determine the Mantissa and Exponent */  
          Select  @Exponent   = floor(log(@Value)/log(2))+@Bias,  
  @Mantissa   = (@Value/power(@Base, @Exponent-@Bias)-1)*@Mantissa_Bit -- 2^52  
  
          /*  Rebuild in IEEE 754 binary format   */  
          Select  @Byte0   = convert(int, floor(@Exponent/power(2, 4))) | @Sign,  
  @Mantissa_Shift = convert(int, floor(@Mantissa/power(@Base, 48))),  
  @Byte1   = convert(int, floor(@Exponent*power(2, 4))) | @Mantissa_Shift,  
  @Mantissa  = @Mantissa - @Mantissa_Shift*power(@Base, 48),  
  @Mantissa_Shift = convert(int, floor(@Mantissa/power(@Base, 40))),  
          @Byte2   = @Mantissa_Shift % 256,  
  @Mantissa  = @Mantissa - @Mantissa_Shift*power(@Base, 40),  
  @Mantissa_Shift = convert(int, floor(@Mantissa/power(@Base, 32))),  
          @Byte3   = @Mantissa_Shift % 256,  
  @Mantissa  = @Mantissa - @Mantissa_Shift*power(@Base, 32),  
  @Mantissa_Shift = convert(int, floor(@Mantissa/power(@Base, 24))),  
          @Byte4   = @Mantissa_Shift % 256,  
  @Mantissa  = @Mantissa - @Mantissa_Shift*power(@Base, 24),  
  @Mantissa_Shift = convert(int, floor(@Mantissa/power(@Base, 16))),  
          @Byte5   = @Mantissa_Shift % 256,  
  @Mantissa  = @Mantissa - @Mantissa_Shift*power(@Base, 16),  
  @Mantissa_Shift = convert(int, floor(@Mantissa/power(@Base, 8))),  
          @Byte6   = @Mantissa_Shift % 256,  
  @Mantissa  = @Mantissa - @Mantissa_Shift*power(@Base, 8),  
  @Mantissa_Shift = convert(int, floor(@Mantissa/power(@Base, 0))),  
          @Byte7   = @Mantissa_Shift % 256,  
  @Data   = @Byte7 + @Byte6 + @Byte5 + @Byte4 + @Byte3 + @Byte2 + @Byte1 + @Byte0  
  
          /*****************************************************************************************  
          *                           Create arrays and total for average                               *  
          *****************************************************************************************/  
          If @Count = 0  
               Select @Data_Array   = @Data,  
  @PctGood_Array = @PctGood,  
  @Total   = @Value  
          Else  
               Select  @Data_Array   = @Data_Array + @Data,  
  @PctGood_Array = @PctGood_Array + @PctGood,  
  @Total   = @Total + @Value  
  
          Select @Count = @Count + 1  
          Fetch Next From DataProfile Into @Value_Str  
          End  
  
     Close DataProfile  
     Deallocate DataProfile  
  
     /*****************************************************************************************  
     *                                    Insert/update data                                  *  
     *****************************************************************************************/  
     If @Data_Array Is Not Null And @Count > 0  
          Begin  
          If @Test_Array_Id Is Null  
               Begin  
               Insert Into [dbo].Array_Data (Data, PctGood, Element_Size, Num_Elements, ShouldDelete)  
               Values (@Data_Array, @PctGood_Array, 8, @Count, Null)  
               Select @Array_Id = @@IDENTITY  
               End  
          Else  
               Begin  
               Update [dbo].Array_Data  
               Set  Element_Size = 8,   
       Num_Elements = @Count,  
       Data  = @Data_Array,  
       PctGood = @PctGood_Array  
               Where Array_Id = @Test_Array_Id  
  
               If @@ROWCOUNT > 0  
                    Select @Array_Id = @Test_Array_Id  
               End  
          
          If @Array_Id Is Not Null  
               Begin  
               /* Determine result for tests table */  
               Select @Result = ltrim(str(@Total/@Count, 24-@Precision, @Precision))  
  
               /* Ensure there is a test entry so don't lose array reference */  
               If @Test_Id Is Null  
                    Begin  
                    Insert Into [dbo].tests (Var_Id, Result_On, Entry_On, Entry_By, Result, Array_Id)  
                    Values (@Source_Var_Id, @TimeStamp, getdate(), @User_Id, @Result, @Array_Id)  
                    Select @Test_Id = @@IDENTITY  
                    Select @Transaction_Type = 1  
                    End  
               Else  
                    Begin  
                    If @Test_Array_Id Is Null  
                         Begin  
                         Update [dbo].tests  
                         Set Array_Id = @Array_Id  
                         Where Test_Id = @Test_Id  
                         End  
  
                    Select @Transaction_Type = 2  
                    End  
  
               /* Normally would issue a post-update but it erases the Array_id from the client cache*/  
               If @Test_Id Is Not Null  
      INSERT INTO @VariableRS (Var_Id, PU_Id, User_Id, Canceled, Result, Result_On, Trans_Type, Post_Update)  
                    Select  @Source_Var_Id,     -- @Var_Id  
          @PU_Id,       -- @PU_Id  
          @User_id,       -- @User_Id      
          0,        -- @Canceled  
          @Result,       -- @Result         
          convert(varchar(25), @TimeStamp, 120),    -- @Result_On                     
          @Transaction_Type,      -- @Transaction_Type  
          0       -- @Post_Update  
               End  
          End  
     End  
Else If @Test_Id Is Not Null  
     Begin  
  INSERT INTO @VariableRS (Var_Id, PU_Id, User_Id, Canceled, Result, Result_On, Trans_Type, Post_Update)  
      Select @Source_Var_Id,     -- @Var_Id  
    @PU_Id,       -- @PU_Id  
    Null,       -- @User_Id      
    0,        -- @Canceled  
    Null,        -- @Result         
    convert(varchar(25), @TimeStamp, 120),    -- @Result_On                     
    2,        -- @Transaction_Type  
    0       -- @Post_Update  
     End  
  
IF (SELECT COUNT(*) FROM @VariableRS) > 0  
 BEGIN  
  IF @AppVersion LIKE '4%'  
   BEGIN  
    SELECT 2,  
      Var_Id,   
      PU_Id,   
      User_Id,   
      Canceled,   
      Result,   
      Result_On,   
      Trans_Type,   
      Post_Update,   
      SecondUserId,   
      TransNum,   
      EventId,   
      ArrayId,   
      CommentId  
    FROM @VariableRS  
   END  
  ELSE  
   BEGIN  
    SELECT 2,  
      Var_Id,   
      PU_Id,   
      User_Id,   
      Canceled,   
      Result,   
      Result_On,   
      Trans_Type,   
      Post_Update  
    FROM @VariableRS  
   END  
 END  
  
/* Return data */  
Select @Output_Value = 'DONOTHING'  
  
SET NOCOUNT OFF  
  
