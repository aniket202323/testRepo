 /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : David Lemire, System Technologies for Industry  
Date   : 2005-11-02  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_PmkgReelTimeDuration  
Author:   Matthew Wells (MSI)  
Date Created:  03/16/04  
  
Description:  
=========  
Calculates the time on the reel for a given sheetbreak event.  
  
Change Date Who What  
=========== ==== =====  
*/  
  
  
CREATE procedure dbo.spLocal_PmkgReelTimeDuration  
@OutputValue  varchar(25) OUTPUT,  
@VarId   int,  
@StartTime  datetime,  
@DowntimePUId  int,  
@ExcludedStatusName varchar(25), --Invalid  
@Conversion  float  
AS  
  
SET NOCOUNT ON  
  
DECLARE @TEStatusId  int,  
 @SheetbreakPUId  int,  
 @VarPrecision  int,  
 @EndTime  datetime,  
 @DowntimeEndTime datetime,  
 @SheetbreakEndTime datetime  
  
SELECT @SheetbreakPUId = PU_Id,  
 @VarPrecision = Var_Precision  
FROM [dbo].Variables  
WHERE Var_Id = @VarId  
  
-- Downtime Invalid Status  
SELECT @TEStatusId = TEStatus_Id  
FROM [dbo].Timed_Event_Status  
WHERE PU_Id = @DowntimePUId  
 AND TEStatus_Name = @ExcludedStatusName  
  
-- Downtime End Time  
SELECT TOP 1 @DowntimeEndTime = End_Time  
FROM [dbo].Timed_Event_Details  
WHERE PU_Id = @DowntimePUId  
 AND End_Time <= @StartTime  
 AND ( TEStatus_Id <> @TEStatusId  
  OR TEStatus_Id IS NULL  
  OR @TEStatusId IS NULL)  
ORDER BY Start_Time DESC  
  
-- Sheetbreak Invalid Status  
SELECT @TEStatusId = NULL  
SELECT @TEStatusId = TEStatus_Id  
FROM [dbo].Timed_Event_Status  
WHERE PU_Id = @SheetbreakPUId  
 AND TEStatus_Name = @ExcludedStatusName  
  
-- Sheet End Time  
SELECT TOP 1 @SheetbreakEndTime = End_Time  
FROM [dbo].Timed_Event_Details  
WHERE PU_Id = @SheetbreakPUId  
 AND End_Time <= @StartTime  
 AND ( TEStatus_Id <> @TEStatusId  
  OR TEStatus_Id IS NULL  
  OR @TEStatusId IS NULL)  
ORDER BY Start_Time DESC  
  
SELECT @EndTime = CASE WHEN @DowntimeEndTime < @SheetbreakEndTime  
    OR @DowntimeEndTime IS NULL  
   THEN @SheetbreakEndTime  
   ELSE @DowntimeEndTime  
   END  
  
SELECT @OutputValue = ltrim(str(datediff(s,@EndTime,@StartTime)/@Conversion,25,@VarPrecision))  
  
  
SET NOCOUNT OFF  
