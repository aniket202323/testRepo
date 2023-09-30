-- spNP_GetReasonInfo() Based on Tree_Name_Id and Event_Reason_Name, retrieves event reason information (esp, Event_Reason_Id & Event_Reason_Level)
-- Assumption: Plant Apps stipulates that Event_Reason_Name must be unique in a given Plant Apps server.
--
CREATE PROCEDURE dbo.spNP_GetReasonInfo
 	   @Event_Reason_Name nVarchar(50)
 	 , @Tree_Name_Id 	 Int
AS
DECLARE @Return_Status Int
SELECT  @Return_Status = -1  	 --Initialize
SELECT d.Event_Reason_Id
     , r.Event_Reason_Name
     , [Event_Reason_Level] = d.Event_Reason_Level
  FROM Event_Reason_Tree_Data d 
  JOIN Event_Reasons r ON r.Event_Reason_Id = d.Event_Reason_Id AND r.Event_Reason_Name = @Event_Reason_Name 
 WHERE d.Tree_Name_Id = @Tree_Name_Id
SELECT @Return_Status = @@Error
SELECT [Return_Status] = @Return_Status
