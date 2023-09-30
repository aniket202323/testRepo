CREATE Procedure dbo.spSV_GetPathUnits
@Path_Id int,
@RegionalServer 	  	  	 Int = 0
AS
Declare @PPId int
If @RegionalServer is null
 	 Set @RegionalServer = 0
--Find the open PPiD for this path
Select @PPId = PP_Id
From Production_Plan
Where Path_Id = @Path_Id
And PP_Status_Id = 3
DECLARE 	 @tPathUnits 	 TABLE (
 	 PUDesc nvarchar(50),
 	 ProcessOrder nvarchar(50),
 	 StartTime DATETIME,
 	 EndTime DATETIME,
 	 UnitOrder INT,
 	 PUId INT,
 	 PPId INT,
 	 PPSetupId INT,
 	 CommentId INT,
 	 IsSchedulePoint BIT,
 	 PPStartId INT,
 	 OpenAllowed BIT,
 	 CloseAllowed BIT,
 	 EditAllowed BIT,
 	 DeleteAllowed BIT)
Insert @tPathUnits (PUDesc, ProcessOrder, 	 StartTime, EndTime, UnitOrder, PUId, PPId, PPSetupId, CommentId, IsSchedulePoint, PPStartId, 	 OpenAllowed, CloseAllowed, EditAllowed, DeleteAllowed)
select pu.PU_Desc, pp.Process_Order, pps.Start_Time, pps.End_Time, pepu.Unit_Order, pps.PU_Id, pps.PP_Id, pps.Comment_Id, pps.PP_Setup_Id, pepu.Is_Schedule_Point, pps.PP_Start_Id, NULL, NULL, NULL, NULL
From PrdExec_Path_Units pepu
Join Prod_Units pu on pu.PU_Id = pepu.PU_Id
Join Production_Plan_Starts pps on pps.PU_Id = pepu.PU_Id
Join Production_Plan pp on pp.PP_Id = pps.PP_Id
Where pepu.Path_Id = @Path_Id
And pp.PP_Id = @PPId
Update @tPathUnits
Set OpenAllowed = 
Case 
 	 When tpu.StartTime = (
 	  	 Select Max(StartTime) 
 	  	  	 From @tPathUnits tpu2 
 	  	  	 Where tpu2.PUId = tpu.PUId) 
 	  	  	  	 and StartTime >= (Select StartTime From @tPathUnits Where IsSchedulePoint = 1 and EndTime is NULL) 
 	  	  	  	 and tpu.EndTime is NOT NULL 
 	 Then 1 
 	 Else 0 
End,
CloseAllowed = 
Case 
 	 When tpu.EndTime is NULL and tpu.IsSchedulePoint = 0 
 	 Then 1 
 	 Else 0 
End,
EditAllowed = 
Case 
 	 When tpu.IsSchedulePoint = 0 
 	 Then 1 
 	 Else 0 
End,
DeleteAllowed = 
Case 
 	 When tpu.IsSchedulePoint = 0 
 	 Then 1 
 	 Else 0 
End
From @tPathUnits tpu
/* do not allow open if on another unit */
Update @tPathUnits
Set OpenAllowed = 0
From @tPathUnits a
Join Production_Plan_Starts pps ON pps.End_Time is null and pps.PU_Id = a.puid and pps.is_Production = 1
IF @RegionalServer = 1
BEGIN
 	 DECLARE @T Table  (TimeColumns nvarchar(100))
 	 DECLARE @CHT Table  (HeaderTag Int,Idx Int)
 	 Insert into @T(TimeColumns) Values ('Start Time')
 	 Insert into @T(TimeColumns) Values ('End Time')
 	 Insert into @CHT(HeaderTag,Idx) Values (20498,1) -- Unit
 	 Insert into @CHT(HeaderTag,Idx) Values (20072,2) -- Process Order
 	 Insert into @CHT(HeaderTag,Idx) Values (20055,3) -- Start Time
 	 Insert into @CHT(HeaderTag,Idx) Values (20054,4) -- End Time
 	 Insert into @CHT(HeaderTag,Idx) Values (20500,5) -- PP_Start_Id
 	 Select TimeColumns From @T
 	 Select HeaderTag From @CHT Order by Idx
 	 Select  	 [Unit] = PUDesc,
 	  	  	 [Process Order] = ProcessOrder,
 	  	  	 [Start Time] = StartTime,
 	  	  	 [End Time] =EndTime,
 	  	  	 [PP Start Id ] = PPStartId,
 	  	  	 OpenAllowed, CloseAllowed, EditAllowed, DeleteAllowed, UnitOrder, PUId, PPId, PPSetupId, CommentId 
 	 FROM @tPathUnits 
 	 order by StartTime
END
ELSE
BEGIN
 	 select PUDesc as 'Unit', ProcessOrder as 'Order', StartTime as 'Start Time', EndTime as 'End Time', PPStartId, OpenAllowed, CloseAllowed, EditAllowed, DeleteAllowed, UnitOrder, PUId, PPId, PPSetupId, CommentId
 	 From @tPathUnits
 	 Order By StartTime ASC
END
