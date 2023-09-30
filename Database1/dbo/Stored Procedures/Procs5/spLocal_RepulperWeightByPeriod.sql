 /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-10  
Version  : 1.0.2  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_RepulperWeightByPeriod  
Author:   Matthew Wells (MSI)  
Date Created:  12/18/02  
  
Description:  
=========  
Ratioes the repulper weight by time to match TAY calculation.  
  
Change Date Who What  
=========== ==== =====  
01/06/02 MKW Added Product Change times.  
02/20/03 MKW Fixed problem with False Sheetbreaks  
*/  
  
CREATE PROCEDURE spLocal_RepulperWeightByPeriod  
@Output_Value  varchar(25) OUTPUT, --1  
@Value_Str  varchar(25),  --2  
@TimeStamp  datetime,  --3  
@Var_Id  int,   --4  
@Day_Interval  int,   --5  
@Day_Offset  int,   --6  
@Shift_Interval  int,   --7  
@Shift_Offset  int,   --8  
@Invalid_Status_Desc varchar(25),  --9  
@Product_PU_Id int   --10  
As  
  
SET NOCOUNT ON  
--Insert Into Local_Calculation_Inputs (Entry_On, A, B, C)  
--Values (getdate(), @Value_Str, convert(varchar(50), @TimeStamp, 120), @Var_Id)  
  
/*   
Select  @Value_Str  = '2.5',  
 @TimeStamp  = '2003-01-03 08:03:12',  
 @Var_Id   = 24434,  
 @Day_Interval  = 1440,  
 @Day_Offset  = 0,  
 @Shift_Interval  = 720,  
 @Shift_Offset  = 420  
*/  
  
Declare @PU_Id    int,  
 @Precision   int,  
 @Day_Start_Time   datetime,  
 @Shift_Start_Time  datetime,  
 @Last_End_Time   datetime,  
 @Start_Time   datetime,  
 @End_Time   datetime,  
 @Result_On   datetime,  
 @Intervals   int,  
 @Value    real,  
 @Sample_Time   real,  
 @Sample_Value   real,  
 @Downtime   real,  
 @Sheetbreak_Time  real,  
 @Invalid_Downtime_Id  int,  
 @TEStatus_Id   int,  
 @Sample_Count   int,  
 @False_Turnover_Desc varchar(25),  
 @False_Turnover_Id int,  
 @Event_Status   int,  
 @User_id     int,  
 @AppVersion    varchar(30)  
   
  
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
  
DECLARE @TimeStamps TABLE (TimeStamp datetime)  
  
--Initialize data  
Select  @Value_Str   = nullif(ltrim(rtrim(@Value_Str)), ''),  
 @Output_Value  = 'DONOTHING', --@Value_Str,  
 @Value    = Null,  
 @Downtime  = 0.0,  
 @Sheetbreak_Time = 0.0,  
 @Sample_Count  = 0  
  
Select  @PU_Id  = PU_Id,  
 @Precision = Var_Precision  
From [dbo].Variables  
Where Var_Id = @Var_Id  
  
Select  @Start_Time = Start_Time,  
 @End_Time = End_Time,  
 @TEStatus_Id = coalesce(TEStatus_Id, 0)  
From [dbo].Timed_Event_Details  
Where PU_Id = @PU_Id And Start_Time = @TimeStamp  
  
If @Value_Str Is Not Null And @End_Time Is Not Null  
     Begin  
     Select TOP 1 @Last_End_Time = End_Time  
     From [dbo].Timed_Event_Details  
     Where PU_Id = @PU_Id And End_Time <= @Start_Time  
    Order By End_Time Desc  
  
     -- Delete any data between this turnover and the last turnover (next TO will be automatically retriggered)  
     Insert Into @Tests ( Var_Id,  
    PU_Id,  
    Result,  
    Result_On,  
    Transaction_Type,User_id)  
     Select @Var_Id,  
  @PU_Id,  
  '',  
  Result_On,  
  2,@User_id  
     From [dbo].tests  
     Where Var_Id = @Var_Id And Result_On > @Last_End_Time And Result_On <= @End_Time  
  
     -- Check for a false downtime  
   Select @Invalid_Downtime_Id = TEStatus_Id  
     From [dbo].Timed_Event_Status  
     Where PU_Id = @PU_Id And TEStatus_Name = @Invalid_Status_Desc  
  
     -- Convert value and if valid then process  
     If isnumeric(@Value_Str) = 1  
          Select @Value = convert(real, @Value_Str)  
  
     If @Value Is Not Null And @TEStatus_Id <> @Invalid_Downtime_Id  
          Begin  
  
          -- Determine day interval time periods  
          Select @Result_On = dateadd(mi, @Day_Offset, convert(datetime, floor(convert(float, @Start_Time))))  
          While @Result_On < @End_Time  
               Begin  
               If @Result_On > @Start_Time  
                    Begin  
                    Insert Into @TimeStamps  
                    Values (@Result_On)  
                    Select @Sample_Count = @Sample_Count + 1  
                    End  
               Select @Result_On = dateadd(mi, @Day_Interval, @Result_On)  
               End  
  
          -- Determine shift interval time periods  
          Select @Result_On = dateadd(mi, @Shift_Offset, convert(datetime, floor(convert(float, @Start_Time))))  
          While @Result_On < @End_Time  
               Begin  
               If @Result_On > @Start_Time  
                    Begin  
                    Insert Into @TimeStamps  
                    Values (@Result_On)  
                    Select @Sample_Count = @Sample_Count + 1  
                    End  
               Select @Result_On = dateadd(mi, @Shift_Interval, @Result_On)  
               End  
  
          -- Determine product change time periods  
          Insert Into @TimeStamps  
          Select dateadd(s, -1, Start_Time)  
          From [dbo].Production_Starts  
          Where PU_Id = @Product_PU_Id And Start_Time > @Start_Time And Start_Time < @End_Time  
          Select @Sample_Count = @Sample_Count + @@ROWCOUNT  
  
          Select @Sheetbreak_Time = datediff(s, @Start_Time, @End_Time)  
  
          If @Sample_Count > 0  
               Begin  
               -- Open cursor for other time periods  
               Declare TimeStamps Cursor For  
               Select Distinct TimeStamp  
               From @TimeStamps  
               Order By TimeStamp Asc  
               For Read Only  
  
               Open TimeStamps  
               Fetch Next From TimeStamps Into @Result_On  
               While @@FETCH_STATUS = 0  
                    Begin  
                    Select @Sample_Value = @Value*(convert(real, datediff(s, @Start_Time, @Result_On))/@Sheetbreak_Time)  
  
                    -- Return results for sample  
                    Insert Into @Tests( Var_Id,  
     PU_Id,  
     Result,  
     Result_On,User_id)  
                    Values ( @Var_Id,  
    @PU_Id,  
    ltrim(str(@Sample_Value, 25, @Precision)),  
    @Result_On,@User_id)  
  
                    --Increment to next sample  
                    Select @Start_Time = @Result_On  
                    Fetch Next From TimeStamps Into @Result_On  
                    End  
  
               Close TimeStamps  
               Deallocate TimeStamps  
  
               End  
          Else  
               Select @Result_On = @Start_Time  
  
          -- Get downtime for remaining period  
          Select @Sample_Value = @Value*(convert(real, datediff(s,@Result_On,@End_Time)))/@Sheetbreak_Time  
  
          Insert Into @Tests( Var_Id,  
    PU_Id,  
    Result,  
    Result_On,User_id)  
          Values ( @Var_Id,  
   @PU_Id,  
   ltrim(str(@Sample_Value, 25, @Precision)),  
   @End_Time,@User_id)  
  
--          Select @Output_Value = ltrim(str(@Sample_Value, 25, @Precision))  
        
          End  
     End  
  
IF @AppVersion LIKE '4%'  
 BEGIN  
  Select 2,Var_Id, PU_Id, User_Id, Canceled, Result, Result_On, Transaction_Type, Post_Update, SecondUserId, TransNum, EventId, ArrayId, CommentId  
  From @Tests  
 END  
ELSE  
 BEGIN  
  Select 2,Var_Id, PU_Id, User_Id, Canceled, Result, Result_On, Transaction_Type, Post_Update  
  From @Tests  
 END  
  
  
SET NOCOUNT OFF  
  
