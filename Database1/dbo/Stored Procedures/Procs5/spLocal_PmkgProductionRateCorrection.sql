   /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-04  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
     Replace temp table for table variable   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_PmkgProductionRateCorrection  
Author:   Matthew Wells (MSI)  
Date Created:  02/03/03  
  
Description:  
=========  
Takes a value and divides it over a time period.  
  
Change Date Who What  
=========== ==== =====  
*/  
CREATE PROCEDURE spLocal_PmkgProductionRateCorrection  
@Output_Value  varchar(25) OUTPUT,  
@Var_Id  int,  
@End_Time  datetime,  
@Value_Str  varchar(25),  
@Conversion  float  
AS  
SET NOCOUNT ON  
/*  
Select  @Var_Id  = 24247,  
-- @End_Time = '2003-02-09 09:40:59',  
-- @End_Time = '2003-02-09 00:00:00',  
 @End_Time = '2003-02-10 00:00:00',  
 @Value_Str = '5.0',  
 @Conversion = 1.0  
*/  
  
Declare @Value   float,  
 @PU_Id   int,  
 @Start_Time  datetime,  
 @Product_Start_Time datetime,  
 @Interval_Start_Time datetime,  
 @Result_On  datetime,  
 @Intervals  int,  
 @Duration  float,  
 @Result   float,  
 @i   int,  
 @Precision  int,  
 @Interval  int,  
 @User_id   int,  
 @AppVersion   varchar(30)  
   
  
 -- Get the Proficy database version  
 SELECT @AppVersion = App_Version FROM [dbo].[AppVersions] WHERE App_Name = 'Database'   
-- user id for the resulset  
SELECT @User_id = User_id   
FROM [dbo].Users  
WHERE username = 'Reliability System'  
  
DECLARE @Tests TABLE(  
 Result_Set_Type  int Default 2,  
 Var_Id    int Null,  
 PU_Id   int Null,  
 User_Id   int Null,  
 Canceled  int Default 0,  
 Result   varchar(25) Null,  
 Result_On  datetime Null,  
 Transaction_Type int Default 1,  
 Post_Update  int Default 0,  
 SecondUserId  int Null,  
 TransNum    int Null,  
 EventId    int Null,  
 ArrayId    int Null,  
 CommentId   int Null)  
  
Select  @Product_Start_Time = Null,  
 @i   = 1,  
 @Output_Value  = 'DONOTHING'  
  
If isnumeric(@Value_Str) = 1  
     Begin  
     Select @Value = convert(float, @Value_Str)*@Conversion  
  
     Select  @PU_Id   = PU_Id,  
  @Precision = Var_Precision,  
  @Interval = Sampling_Interval  
     From [dbo].Variables  
     Where Var_Id = @Var_Id  
  
     -- Divide into hourly increments  
     Select @Start_Time = convert(datetime, ceiling(convert(float, @End_Time))-1)  
  
     Select TOP 1 @Product_Start_Time = Start_Time  
     From [dbo].Production_Starts  
     Where PU_Id = @PU_Id And Start_Time > @Start_Time And Start_Time < @End_Time  
     Order By Start_Time Desc  
     Select @Product_Start_Time = coalesce(@Product_Start_Time, @Start_Time)  
  
     Select @Result_On = dateadd(mi, (floor(convert(float, datediff(s, @Start_Time, @Product_Start_Time))/60/@Interval)+1)*@Interval, @Start_Time)  
     Select @Start_Time = @Product_Start_Time  
     Select @Duration = datediff(s, @Start_Time, @End_Time)  
  
     While @Result_On < @End_Time  
          Begin  
          Select @Result = convert(float, datediff(s, @Start_Time, @Result_On))/@Duration*@Value  
          Insert Into @Tests( Var_Id,  
    PU_Id,  
    Result,  
    Result_On,User_id)  
          Values ( @Var_Id,  
   @PU_Id,  
   ltrim(str(@Result, 25, @Precision)),  
   @Result_On,@User_id)  
  
          Select  @Result_On  = dateadd(mi, @Interval, @Result_On),  
   @Start_Time = dateadd(mi, -@Interval, @Result_On)  
          End  
  
  
     Select @Result = convert(float, datediff(s, @Start_Time, @End_Time))/@Duration*@Value  
     Insert Into @Tests(Var_Id,  
   PU_Id,  
   Result,  
   Result_On,User_id)  
     Values ( @Var_Id,  
  @PU_Id,  
  ltrim(str(@Result, 25, @Precision)),  
  @End_Time,@User_id)  
  
    IF @AppVersion LIKE '4%'  
    BEGIN  
            Select 2,   
      Var_Id,   
      PU_Id,   
      User_Id,   
      Canceled,   
      Result,   
      Result_On,   
      Transaction_Type,   
      Post_Update,  
      SecondUserId,   
      TransNum,   
      EventId,   
      ArrayId,   
      CommentId   
     From @Tests  
    END  
   ELSE  
    BEGIN  
            Select 2,   
      Var_Id,   
      PU_Id,   
      User_Id,   
      Canceled,   
      Result,   
      Result_On,   
      Transaction_Type,   
      Post_Update   
     From @Tests  
    END  
     End  
  
  
SET NOCOUNT OFF  
  
