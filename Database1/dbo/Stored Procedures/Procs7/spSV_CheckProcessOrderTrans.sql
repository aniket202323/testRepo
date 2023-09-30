Create Procedure dbo.spSV_CheckProcessOrderTrans
@PPId int,
@Language_Id int,
@Message varchar(7000) OUTPUT,
@VBMsgBoxStyle int OUTPUT
AS
Declare @PathId int
--VBMsgBoxStyle
--vbYesNo = 4
--vbInformation = 64
Select @Message = '', @VBMsgBoxStyle = 64
/*
When activating a process order we need to do a unit "binding" check.  
In other words, we need to check if all units that are required in the execution path of the order are either already running on that same path, 
or are not running another order.  I think the logic would go something like this:
Before going active:
*/
--1. What is the path of this order?
select @PathId = Path_Id
 	 from Production_Plan
 	 where PP_Id = @PPId
--2. What units are in this path?
CREATE TABLE #PathUnits (PU_Id int, ThisPath_PPStartId int NULL, OtherPath_PPStartId int NULL)
INSERT INTO #PathUnits
  Select PU_Id, NULL, NULL
    From PrdExec_Path_Units 
 	  	 Where Path_Id = @PathId
--3. Are all units already on this path?
Update #PathUnits
 	 Set ThisPath_PPStartId = (Select PP_Start_Id From Production_Plan_Starts Where PP_Id = @PPId and PU_Id = #PathUnits.PU_Id and End_Time is NULL)
--4. If not; are the units that are not on this path running an active order now? (according to pp_starts)
Update #PathUnits
 	 Set OtherPath_PPStartId = (Select PP_Start_Id From Production_Plan_Starts Where PP_Id <> @PPId and PU_Id = #PathUnits.PU_Id and End_Time is NULL)
 	 Where ThisPath_PPStartId is NULL
--Schedule Control Types
-- 0 = All Units Run Same Schedule Simultaneously
-- 1 = Schedule Flows By Event
-- 2 = Schedule Flows Independently
--5. If units are running active order on another path AND schedule control type for this path = "all units simultaneous" then 
-- 	 give message and REJECT status change.
If (Select Count(*) From #PathUnits Where OtherPath_PPStartId is NOT NULL) > 0 and (Select Schedule_Control_Type From PrdExec_Paths Where Path_Id = @PathId) = 0
 	 Select @Message = coalesce(ld2.Prompt_String, ld.Prompt_String), @VBMsgBoxStyle = 64 from Language_Data ld 
 	               Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
 	               where ld.Language_Id = 0 and ld.Prompt_Number = 20377
--6. If units are running active order on another path AND schedule control type for this path <> "all units simultaneous" then 
-- 	 give warning message "Not all units required for this order are currently available."  and ask if they still want to proceed?
If (Select Count(*) From #PathUnits Where OtherPath_PPStartId is NOT NULL) > 0 and (Select Schedule_Control_Type From PrdExec_Paths Where Path_Id = @PathId) <> 0
 	 Select @Message = coalesce(ld2.Prompt_String, ld.Prompt_String), @VBMsgBoxStyle = 4 from Language_Data ld 
 	               Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
 	               where ld.Language_Id = 0 and ld.Prompt_Number = 20378
DROP TABLE #PathUnits
