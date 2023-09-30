CREATE PROCEDURE dbo.spSDK_GetReasonById
 	 @ReasonId  	  	  	 INT
AS
SELECT 	 ReasonId = Event_Reason_Id, 
 	  	  	 ReasonName = Event_Reason_Name, 
 	  	  	 ReasonCode = Event_Reason_Code
 	 FROM 	 Event_Reasons
 	 WHERE 	 Event_Reason_Id = @ReasonId
