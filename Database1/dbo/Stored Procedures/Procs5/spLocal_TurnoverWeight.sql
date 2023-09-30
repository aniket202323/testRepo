   /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Stephane Turner, System Technologies for Industry  
Date   : 2005-11-16  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_TurnoverWeight  
Author:   Matthew Wells (MSI)  
Date Created:  06/04/02  
  
Description:  
=========  
Calculates the turnover weight by calculating the reel time and then multiplying it by the production rate.  
  
Change Date Who What  
=========== ==== =====  
06/04/02 MKW Created.  
07/02/02 MKW Added conversion factor.  
03/10/03 MKW Added error messages.  
05/28/03 MKW Added Additive_Rate  
*/  
  
CREATE PROCEDURE dbo.spLocal_TurnoverWeight  
@Output_Value   varchar(25) OUTPUT,  
@Reel_Start_Time  datetime,  
@Reel_End_Time   datetime,  
@Sheetbreak_PU_Id   int,  
@Downtime_PU_Id   int,  
@Invalid_Status_Name  varchar(50),  
@Production_Rate_Str  varchar(25),  
@Conversion_Factor_Str  varchar(25),  
@Additive_Rate_Str  varchar(25)  
AS  
  
SET NOCOUNT ON  
  
/* Testing   
SELECT  @Reel_Start_Time  = '2002-06-03 12:00:00',  
 @Reel_End_Time  = '2002-06-03 13:00:00',  
 @Sheetbreak_PU_Id = 510,  
 @Downtime_PU_Id  = 508,  
 @Production_Rate_Str = '0.102'  
*/  
  
DECLARE @Stored_Procedure_Name   varchar(50),  
 @Message    varchar(255),  
 @Sheetbreak_Invalid_Status_Id  int,  
 @Sheetbreak_Time   real,  
 @Downtime_Invalid_Status_Id  int,  
 @Turnover_Weight   real,  
 @Downtime    real,  
 @Production_Rate   real,  
 @Conversion_Factor   real,  
 @Additive_Rate    real  
  
-- Initialization   
SELECT  @Output_Value    = Null,  
 @Conversion_Factor  = 1.0,  
 @Stored_Procedure_Name  = 'spLocal_TurnoverWeight',  
 @Additive_Rate   = 0.0  
  
IF isnumeric(@Conversion_Factor_Str) = 1  
     SELECT @Conversion_Factor = convert(real, @Conversion_Factor_Str)  
ELSE  
     EXEC [dbo].spLocal_WriteMessage @Stored_Procedure_Name,  
    'Warning: Invalid conversion factor.'  
  
-- Check argument  
IF isnumeric(@Production_Rate_Str) = 1  
     BEGIN  
     -- Argument conversion   
     SELECT @Production_Rate = convert(real, @Production_Rate_Str)  
  
     IF isnumeric(@Additive_Rate_Str) = 1  
          BEGIN  
          SELECT @Additive_Rate = convert(real, @Additive_Rate_Str)  
          END  
  
     -- Get the invalid status id so can exclude those records  
     SELECT @Sheetbreak_Invalid_Status_Id = TEStatus_Id  
     FROM [dbo].Timed_Event_Status  
     WHERE PU_Id = @Sheetbreak_PU_Id  
  AND TEStatus_Name = @Invalid_Status_Name  
  
     SELECT @Downtime_Invalid_Status_Id = TEStatus_Id  
     FROM [dbo].Timed_Event_Status  
     WHERE PU_Id = @Downtime_PU_Id  
  AND TEStatus_Name = @Invalid_Status_Name  
  
     -- Get the downtime for the turnover period  
     SELECT @Downtime = convert(real, Sum(Datediff(s,  CASE   
       WHEN Start_Time < @Reel_Start_Time Then @Reel_Start_Time  
              ELSE Start_Time   
       END,  
           CASE   
       WHEN End_Time > @Reel_End_Time Or End_Time Is Null Then @Reel_End_Time  
        ELSE End_Time   
       END)))/60  
     FROM [dbo].Timed_Event_Details  
     WHERE PU_Id = @Downtime_PU_Id  
  AND (TEStatus_Id <> @Downtime_Invalid_Status_Id OR TEStatus_Id IS NULL)  
  AND Start_Time < @Reel_End_Time  
  AND (End_Time > @Reel_Start_Time OR End_Time IS NULL)  
  
     -- Get the sheetbreak time for the turnover period   
     SELECT @Sheetbreak_Time = convert(real, sum(datediff(s, CASE   
       WHEN Start_Time < @Reel_Start_Time Then @Reel_Start_Time  
              ELSE Start_Time   
       END,  
           CASE   
       WHEN End_Time > @Reel_End_Time Or End_Time Is Null Then @Reel_End_Time  
        ELSE End_Time   
       END)))/60  
     FROM [dbo].Timed_Event_Details  
     WHERE PU_Id = @Sheetbreak_PU_Id  
  AND (TEStatus_Id <> @Sheetbreak_Invalid_Status_Id OR TEStatus_Id IS NULL)  
  AND Start_Time < @Reel_End_Time  
  AND (End_Time > @Reel_Start_Time OR End_Time IS NULL)  
  
     -- Multiply reel time by the production rate  
     SELECT @Turnover_Weight = (convert(real, datediff(s, @Reel_Start_Time, @Reel_End_Time))/60-isnull(@Sheetbreak_Time, 0)-isnull(@Downtime, 0))*(@Production_Rate+@Additive_Rate)*@Conversion_Factor  
     IF @Turnover_Weight <= 0  
          BEGIN  
          SELECT @Message = 'Warning: Invalid Turnover Weight;  Inputs:' + convert(varchar(25), @Reel_Start_Time, 120) + ',' + convert(varchar(25), @Reel_End_Time, 120) +  ',' + ltrim(str(@Downtime, 25, 3)) +  ',' + ltrim(str(@Sheetbreak_Time, 25, 3))  
          EXEC [dbo].spCmn_AddMessage @Message,  
    @Stored_Procedure_Name  
          END  
  
     -- Return results  
     SELECT @Output_Value = ltrim(str(@Turnover_Weight, 25, 3))  
     END  
  
SET NOCOUNT OFF  
  
