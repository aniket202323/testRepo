  /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-09  
Version  : 1.0.2  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_SetTimedEventStatusByReason  
Author:   Matthew Wells (MSI)  
Date Created:  11/23/01  
  
Description:  
=========  
This procedure checks the reasons assigned to this event and if one of the reasons matches the defined 'status change' reason then it  
sets the status of the event to the passed status.  This is used to flag 'false' downtime records for reporting purposes.  
  
Change Date Who What  
=========== ==== =====  
11/23/01 MKW Created  
01/15/04 MKW Increased @Reason_Name size to 100 and @Status to 50  
*/  
CREATE PROCEDURE dbo.spLocal_SetTimedEventStatusByReason  
@Output_Value  varchar(25) OUTPUT,  
@TEDet_Id   int,  
@Reason_Name  varchar(100),  
@Status    varchar(100)  
AS  
SET NOCOUNT ON  
  
DECLARE @PU_Id   int,  
 @New_TEStatus_Id int,  
 @Current_TEStatus_Id int,  
 @Reason_Name1  varchar(100),  
 @Reason_Name2  varchar(100),  
 @Reason_Name3  varchar(100),  
 @Reason_Name4  varchar(100)  
  
/* Initialization */  
SELECT  @Current_TEStatus_Id  = NULL,  
 @Reason_Name1  = NULL,  
 @Reason_Name2  = NULL,  
 @Reason_Name3  = NULL,  
 @Reason_Name4  = NULL  
  
/* Get event details */  
SELECT  @PU_Id   = PU_Id,  
 @Current_TEStatus_Id  = TEStatus_Id,  
 @Reason_Name1   = r1.Event_Reason_Name,  
 @Reason_Name2   = r2.Event_Reason_Name,  
 @Reason_Name3   = r3.Event_Reason_Name,  
 @Reason_Name4   = r4.Event_Reason_Name  
FROM [dbo].Timed_Event_Details ted  
     LEFT JOIN [dbo].Event_Reasons r1 ON ted.Reason_Level1 = r1.Event_Reason_Id  
     LEFT JOIN [dbo].Event_Reasons r2 ON ted.Reason_Level2 = r2.Event_Reason_Id  
     LEFT JOIN [dbo].Event_Reasons r3 ON ted.Reason_Level3 = r3.Event_Reason_Id  
     LEFT JOIN [dbo].Event_Reasons r4 ON ted.Reason_Level4 = r4.Event_Reason_Id       
WHERE TEDet_Id = @TEDet_Id  
  
-- Check to see if any of the reasons match the 'status change' reason   
IF (@Reason_Name1 = @Reason_Name AND @Reason_Name1 IS NOT NULL) OR  
   (@Reason_Name2 = @Reason_Name AND @Reason_Name2 IS NOT NULL) OR  
   (@Reason_Name3 = @Reason_Name AND @Reason_Name3 IS NOT NULL) OR  
   (@Reason_Name4 = @Reason_Name AND @Reason_Name4 IS NOT NULL)  
     BEGIN  
     SELECT @New_TEStatus_Id = TEStatus_Id  
     FROM [dbo].Timed_Event_Status  
     WHERE PU_Id = @PU_Id  
  AND TEStatus_Name = @Status  
  
     IF @TEDet_Id Is Not NULL And @New_TEStatus_Id Is Not NULL And (@New_TEStatus_Id <> @Current_TEStatus_Id Or @Current_TEStatus_Id Is NULL)  
          BEGIN  
           UPDATE [dbo].Timed_Event_Details  
           SET TEStatus_Id = @New_TEStatus_Id  
           WHERE TEDet_Id = @TEDet_Id  
          END  
     END  
-- Make sure if no 'status change' reason that the status is NULL  
ELSE  
     BEGIN  
     IF @Current_TEStatus_Id IS NOT NULL  
          BEGIN  
         UPDATE [dbo].Timed_Event_Details  
           SET TEStatus_Id = NULL  
           WHERE TEDet_Id = @TEDet_Id  
          END  
     END  
     
SELECT @Output_Value = @TEDet_Id  
  
SET NOCOUNT OFF  
