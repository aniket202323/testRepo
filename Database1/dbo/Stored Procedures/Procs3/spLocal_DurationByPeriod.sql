  /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Peron, System technologies for industry  
Date   : 2005-10-27  
Version  : 1.0.2  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
Stored Procedure: spLocal_DurationByPeriod  
Author:   Matthew Wells (MSI)  
Date Created:  08/27/01  
  
Description:  
=========  
Calculates the duration for a given time period for a product/time variable  
  
Change Date Who What  
=========== ==== =====  
11/05/01 MKW Added comment.  
12/10/02 MKW Updated for build 215.40  
*/  
CREATE PROCEDURE dbo.spLocal_DurationByPeriod  
@Output_Value varchar(25) OUTPUT,  
@PU_Id  int,  
@Var_Id  int,  
@End_Time datetime,  
@Conversion float  
As  
  
SET NOCOUNT ON  
  
Declare @Start_Time   datetime,  
 @Production_Start_Time  datetime,  
 @Intervals   int,  
 @Interval   int,  
 @Offset    int,  
 @Var_PU_Id   int,  
 @Precision   int,  
 @User_Id    int  
  
-- user id for the resulset  
SELECT @User_id = User_id   
FROM [dbo].Users  
WHERE username = 'Reliability System'  
   
/* Initialization */  
Select   @Output_Value = '0.0'  
  
/* Get the sampling window from the variable configuration */  
Select  @Var_PU_Id = PU_Id,  
 @Offset  = Sampling_Offset,  
 @Interval = Sampling_Interval,  
 @Precision = isnull(Var_Precision, 0)  
From [dbo].Variables  
Where Var_Id = @Var_Id  
  
If @Interval > 0  
     Begin  
     Select @Start_Time = dateadd(mi, @Offset, convert(datetime, floor(convert(float, @End_Time))))  
     Select @Intervals = floor(convert(float, Datediff(s, @Start_Time, dateadd(s, -1, @End_Time)))/60/@Interval)  
     Select @Start_Time = dateadd(mi, @Intervals*@Interval, @Start_Time)  
  
     -- Get all product changes in the Sampling Window  
     Declare ProductionStarts Cursor For  
     Select dateAdd(s, -1, Start_Time)  
     From [dbo].Production_Starts  
     Where PU_Id = @PU_Id And Start_Time > @Start_Time And Start_Time < @End_Time  
     Order By Start_Time Asc  
     Open ProductionStarts  
  
     Fetch Next From ProductionStarts INTO @Production_Start_Time  
     While @@FETCH_STATUS = 0  
          Begin  
          -- Summarize the downtime data   
          Select @Output_Value = ltrim(str(convert(float, datediff(s, @Start_Time, @Production_Start_Time)) * @Conversion, 25, @Precision))  
            
          -- Return test result set for Product Change   
          Select 2, @Var_Id, @Var_PU_Id, @User_id, 0, @Output_Value, @Production_Start_Time, 1, 0  
  
          -- Reassign Start Time   
          Select @Start_Time = @Production_Start_Time  
  
          -- Fetch next record   
          Fetch Next From ProductionStarts INTO @Production_Start_Time  
          End  
  
     -- Cleanup   
     Close ProductionStarts  
     Deallocate ProductionStarts  
  
     -- Return value for the end of the window   
     Select @Output_Value = ltrim(str(convert(float, datediff(s, @Start_Time, @End_Time))*@Conversion, 25, @Precision))  
     End  
  
  
SET NOCOUNT OFF  
  
