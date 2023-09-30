  /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : David Lemire, System Technologies for Industry  
Date   : 2005-11-02  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
     Replace temp table for table variable   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
-- Stored Procedure: spLocal_ProcessOrderTimeStatus  
-- Created By:  Dan Hinchey (GE Fanuc - Mountain Systems)  
-- Created Date: December 23, 2003  
--  
-- This SP calculates the time remaining for the 'Active' Process Order.  
-- If there is no 'Active' Process Order then the value is set to the DefaultTime  
-- input parameter.  When configuring the calc the the DefaultTime should be set  
-- to a value greater than the value of the low priority alarm configured for the  
-- variable that this SP/calc is assigned to.  
--  
*/  
  
CREATE PROCEDURE dbo.spLocal_ProcessOrderTimeStatus  
 @OutPut_Value VarChar(25) OUTPUT,  
 @MaterPU_Id Int,  
 @TimeStamp DateTime,  
 @DefaultTime Float  
AS  
  
SET NOCOUNT ON  
  
-- Declare Local Variables.  
DECLARE @PP_Id   Int,  
 @Forecast_End_Date DateTime,  
 @Remaining_Time  Float  
-- Get the Active Production Plan ID and Schedule End Time.  
SELECT @PP_Id = pps.PP_Id, @Forecast_End_Date = Forecast_End_Date  
 FROM [dbo].Production_Plan_Starts pps  
 JOIN [dbo].Production_Plan pp ON pps.PP_Id = pp.PP_Id  
 WHERE pps.PU_Id = @MaterPU_Id  
 AND Start_Time < @TimeStamp  
 AND (End_Time >= @TimeStamp OR End_Time IS NULL)  
-- If there is no active Production Plan use the default remaining time,  
-- otherwise calculate the remaining time.  
IF @PP_Id IS NOT NULL  
BEGIN  
 SELECT @Remaining_Time = DATEDIFF(n,@TimeStamp,@Forecast_End_Date)  
END  
ELSE  
BEGIN  
 SELECT @Remaining_Time = @DefaultTime  
END  
SELECT @OutPut_Value = @Remaining_Time  
  
SET NOCOUNT OFF  
  
