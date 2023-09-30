-- spNP_GetReasonName() Based on Tree_Name_Id and Event_Reason_Name, retrieves event reason information (esp, Event_Reason_Id & Event_Reason_Level)
-- Assumption: Plant Apps stipulates that Event_Reason_Name must be unique in a given Plant Apps server.
--
CREATE PROCEDURE dbo.spNP_GetReasonName
 	   @Event_Reason_Id Int
AS
DECLARE @Return_Status Int
SELECT  @Return_Status = -1  	 --Initialize
SELECT * FROM Event_Reasons WHERE Event_Reason_Id = @Event_Reason_Id 
SELECT @Return_Status = @@Error
SELECT [Return_Status] = @Return_Status
