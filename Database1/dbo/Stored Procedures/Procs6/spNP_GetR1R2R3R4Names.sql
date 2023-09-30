-- spNP_GetR1R2R3R4Names() Based on Tree_Name_Id and Event_Reason_Name, retrieves event reason information (esp, Event_Reason_Id & Event_Reason_Level)
-- Assumption: Plant Apps stipulates that Event_Reason_Name must be unique in a given Plant Apps server.
--
CREATE PROCEDURE dbo.spNP_GetR1R2R3R4Names
 	   @R1_Id Int
 	 , @R2_Id Int
 	 , @R3_Id Int
 	 , @R4_Id Int
AS
DECLARE @R1Name nVarchar(50), @R2Name nVarchar(50), @R3Name nVarchar(50), @R4Name nVarchar(50) 
DECLARE @Return_Status Int
SELECT  @Return_Status = -1  	 --Initialize
SELECT @R1Name = Event_Reason_Name FROM Event_Reasons WHERE Event_Reason_Id = @R1_Id
SELECT @R2Name = Event_Reason_Name FROM Event_Reasons WHERE Event_Reason_Id = @R2_Id
SELECT @R3Name = Event_Reason_Name FROM Event_Reasons WHERE Event_Reason_Id = @R3_Id
SELECT @R4Name = Event_Reason_Name FROM Event_Reasons WHERE Event_Reason_Id = @R4_Id
SELECT [R1Name] = @R1Name, [R2Name] = @R2Name, [R3Name] = @R3Name, [R4Name] = @R4Name
SELECT @Return_Status = @@Error
SELECT [Return_Status] = @Return_Status
