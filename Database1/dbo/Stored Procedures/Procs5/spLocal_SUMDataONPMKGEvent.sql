 /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Stephane Turner, System Technologies for Industry  
Date   : 2005-11-16  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_SUMDataONPMKGEvent  
Author:   Fran Osorno  
Date Created:  03/03/2004  
  
Description:  
=========  
This sp will sum data for a given turnover.  This is need ed for Perfect Parent roll to get data into the database for the last value comparision  
  
  
Change Date  Who What  
=========== ==== =====  
10/17/05  FGO Created  
*/  
  
CREATE PROCEDURE dbo.spLocal_SUMDataONPMKGEvent  
   @Output_Value  VARCHAR(25) OUTPUT,  
   @Event_Time  DATETIME,  
   @PU_ID   INT,  
   @VarId   INT  
  
AS  
  
SET NOCOUNT ON  
  
/* Declare other variables */  
 DECLARE  
   @LastEventTime  DATETIME,  
   @VarTotal  FLOAT  
  
  
  
/* Set the variables For Testing */  
/*  
 SELECT  @Event_Time = '10/17/05 14:19:25',  
  @PU_ID = 505,  
  @VarID = 4742  
*/  
     
  
/* Set @LastEventTime */  
 SELECT TOP 1 @LastEventTime= timestamp  
  FROM [dbo].events  
  WHERE timestamp < @Event_Time AND  pu_id = @PU_ID ORDER BY timestamp DESC  
  
  
/* Get the Sum of the result of @VarID */  
 SELECT  @VarTotal = SUM(CONVERT(FLOAT,Result))  
  FROM [dbo].tests  
  WHERE var_id = @VarID AND (result_on >= @LastEventTime AND result_on <= @Event_Time)  
     
  
  
  
/* Output the Result */  
  
 SELECT @Output_Value =  
   CASE  
    WHEN @VarTotal IS NULL THEN 0  
    ELSE @VarTotal  
   END  
  
  
SET NOCOUNT OFF  
  
