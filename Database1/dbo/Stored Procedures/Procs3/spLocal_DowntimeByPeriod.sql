  /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Peron, System technologies for industry  
Date   : 2005-10-27  
Version  : 1.0.4  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
     Replace temp table for table variable   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
Stored Procedure: spLocal_DowntimeByPeriod  
Author:   Matthew Wells (MSI)  
Date Created:  08/27/01  
  
Description:  
=========  
This procedure summarizes downtime duration by a defined period.  It gets and formats the inputs and then calls  
the standard downtime summary routine.  
  
Change Date Who What  
=========== ==== =====  
11/05/01 MKW Added comment  
02/02/02 MKW Added check for invalid status (excludes that downtime)  
08/22/02 MKW Replace call to spLocal_DowntimeSummary with single query  
10/21/02 MKW Changed timestamp of product change value for 215.40  
*/  
  
CREATE PROCEDURE dbo.spLocal_DowntimeByPeriod  
@Output_Value  varchar(25) OUTPUT,  
@PU_Id  int,  
@Var_Id  int,  
@End_Time  datetime,  
@Fault_Desc  varchar(50),  
@Conversion  float,  
@Invalid_Status_Name varchar(50)  
As  
  
SET NOCOUNT ON  
  
Declare @Start_Time  datetime,  
 @Production_Start_Time datetime,  
 @Var_PU_Id  int,  
 @Invalid_Status_Id int,  
 @Var_Precision  int,  
 @Downtime  real,  
 @Intervals  int,  
 @Interval  int,  
 @Offset   int,  
 @User_id   int  
  
-- user id for the resulset  
SELECT @User_id = User_id   
FROM Users  
WHERE username = 'Reliability System'  
  
/* Initialization */  
Select @Output_Value = '0.00'  
  
/* Get invalid status id */  
Select @Invalid_Status_Id = TEStatus_Id  
From [dbo].Timed_Event_Status  
Where PU_Id = @PU_Id And TEStatus_Name = @Invalid_Status_Name  
  
/* Get the sampling window from the variable configuration */  
Select  @Interval = Sampling_Interval,  
 @Offset  = Sampling_Offset,  
 @Var_PU_Id = PU_Id,  
 @Var_Precision = isnull(Var_Precision, 0)  
From [dbo].Variables  
Where Var_Id = @Var_Id  
  
If @Interval > 0  
     Begin  
     Select @Start_Time = dateadd(mi, @Offset, convert(datetime, floor(convert(float, @End_Time))))  
     Select @Intervals = floor(convert(float, Datediff(s, @Start_Time, dateadd(s, -1, @End_Time)))/60/@Interval)  
     Select @Start_Time = dateadd(mi, @Intervals*@Interval, @Start_Time)  
  
     /* Get all product changes in the Sampling Window; NOTE - revert to -1 min 59 sec to match Proficy internal records */  
     Declare ProductionStarts Cursor For  
     Select dateAdd(s, -1, Start_Time)  
     From [dbo].Production_Starts  
     Where PU_Id = @PU_Id And Start_Time > @Start_Time And Start_Time < @End_Time  
     Order By Start_Time Asc  
     Open ProductionStarts  
  
     Fetch Next From ProductionStarts INTO @Production_Start_Time  
     While @@FETCH_STATUS = 0  
          Begin  
  
          If @Start_Time < @Production_Start_Time  
               Begin  
               Select @Downtime = 0.0  
               Select @Downtime = isnull(convert(real, Sum(Datediff(s,  Case   
       When Start_Time < @Start_Time Then @Start_Time  
              Else Start_Time   
       End,  
           Case   
       When End_Time > @Production_Start_Time Or End_Time Is Null Then @Production_Start_Time  
        Else End_Time   
       End)))/@Conversion, 0.0)  
               From [dbo].Timed_Event_Details  
               Where PU_Id = @PU_Id And (TEStatus_Id <> @Invalid_Status_Id Or TEStatus_Id Is Null) And  
                           Start_Time < @Production_Start_Time And (End_Time > @Start_Time Or End_Time Is Null)  
  
               Select 2,           -- @Result_Set_Type   
        @Var_Id,           -- @Var_Id  
        @Var_PU_Id,           -- @PU_Id  
        @User_id,            -- @User_Id  
        0,            -- @Cancelled  
        ltrim(str(@Downtime, 15, @Var_Precision)),      -- @Result  
        @Production_Start_Time,         -- @Result_On  
        1,            -- @Transaction_Type  
        0           -- @Post_Update  
               End  
            
          /* Reassign Start Time */  
          Select @Start_Time = @Production_Start_Time  
  
          /* Fetch next record */  
          Fetch Next From ProductionStarts INTO @Production_Start_Time  
          End  
  
     /* Cleanup */  
     Close ProductionStarts  
     Deallocate ProductionStarts  
  
     /* Return value for the end of the window */  
     Select @Downtime = 0.0  
     Select @Downtime = isnull(convert(real, Sum(Datediff(s,  Case   
        When Start_Time < @Start_Time Then @Start_Time  
               Else Start_Time   
        End,  
            Case   
        When End_Time > @End_Time Or End_Time Is Null Then @End_Time  
         Else End_Time   
        End)))/@Conversion, 0.0)  
     From [dbo].Timed_Event_Details  
     Where PU_Id = @PU_Id And (TEStatus_Id <> @Invalid_Status_Id Or TEStatus_Id Is Null) And  
                Start_Time < @End_Time And (End_Time > @Start_Time Or End_Time Is Null)  
  
     Select @Output_Value = ltrim(str(@Downtime, 15, @Var_Precision))  
  
     End  
  
SET NOCOUNT OFF  
  
