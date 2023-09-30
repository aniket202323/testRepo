CREATE PROCEDURE dbo.spSDK_QueryReasons
 	 @ReasonName  	  	  	 nvarchar(100) = NULL,
 	 @ReasonCode  	  	  	 nvarchar(50) = NULL
AS
SET 	 @ReasonName = REPLACE(COALESCE(@ReasonName, '*'), '*', '%')
SET 	 @ReasonName = REPLACE(REPLACE(@ReasonName, '?', '_'), '[', '[[]')
SET 	 @ReasonCode = REPLACE(COALESCE(@ReasonCode, '*'), '*', '%')
SET 	 @ReasonCode = REPLACE(REPLACE(@ReasonCode, '?', '_'), '[', '[[]')
SELECT 	 ReasonId = Event_Reason_Id, 
 	  	  	 ReasonName = Event_Reason_Name, 
 	  	  	 ReasonCode = Event_Reason_Code
 	 FROM 	 Event_Reasons
 	 WHERE 	 Event_Reason_Name LIKE @ReasonName AND
 	  	  	 Event_Reason_Code LIKE @ReasonCode
