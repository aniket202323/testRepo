  /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : David Lemire, System Technologies for Industry  
Date   : 2005-11-02  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_PmkgUptimeDuration  
Author:   Matthew Wells (MSI)  
Date Created:  03/16/04  
  
Description:  
=========  
Calculates the uptime for a given downtime event.  
  
*/  
  
CREATE procedure [dbo].spLocal_PmkgUptimeDuration  
@OutputValue  varchar(25) OUTPUT,  
@VarId   int,   
@StartTime  datetime,  
@ExcludedStatusName varchar(25), --Invalid  
@Conversion  float  
AS  
  
SET NOCOUNT ON  
  
DECLARE @TEStatusId  int,  
 @PUId   int,  
 @VarPrecision  int  
  
SELECT @PUId  = PU_Id,  
 @VarPrecision = Var_Precision  
FROM [dbo].Variables  
WHERE Var_Id = @VarId  
  
SELECT @TEStatusId = TEStatus_Id  
FROM [dbo].Timed_Event_Status  
WHERE PU_Id = @PUId  
 AND TEStatus_Name = @ExcludedStatusName  
  
SELECT TOP 1 @OutputValue = ltrim(str(datediff(s, End_Time, @StartTime)/@Conversion, 25, @VarPrecision))  
FROM [dbo].Timed_Event_Details  
WHERE PU_Id = @PUId  
 AND End_Time <= @StartTime  
 AND ( TEStatus_Id <> @TEStatusId  
  OR TEStatus_Id IS NULL  
  OR @TEStatusId IS NULL)  
ORDER BY Start_Time DESC  
  
SET NOCOUNT OFF  
  
