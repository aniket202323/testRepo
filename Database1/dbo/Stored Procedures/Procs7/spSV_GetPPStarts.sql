CREATE Procedure dbo.spSV_GetPPStarts
@PathId int,
@StartTime datetime,
@EndTime datetime,
@ProductionVariable int = 0,
@RegionalServer 	  	  	 Int = 0
AS
If @RegionalServer is null
 	 Set @RegionalServer = 0
Declare @maxStart DateTime,@minPPId int,@minStartPPId DateTime,@MyCounter Int
Declare @OutputTable Table (myOrder Int,pu_Desc nvarchar(100),Actual_Start DateTime,Actual_End DateTime,Process_Order nvarchar(100),PP_Id Int,PP_Status_Desc nvarchar(100),PP_Start_Id Int)
INsert Into @OutputTable(myOrder,pu_Desc,Actual_Start ,Actual_End ,Process_Order,PP_Id,PP_Status_Desc,PP_Start_Id)
select 0,pu_Desc,pps.Start_Time ,pps.End_Time,pp.Process_Order,  pps.PP_Id,ppt.PP_Status_Desc, pps.PP_Start_Id
from Production_Plan_Starts pps
join Production_Plan pp on pp.PP_Id = pps.PP_Id
join Production_Plan_Statuses ppt on pp.pp_Status_Id = ppt.pp_status_Id
Join Prod_Units pu on pu.PU_Id = pps.PU_Id
where pp.Path_Id = @PathId and pps.Start_Time > = @StartTime and (pps.End_Time <= @EndTime or pps.End_Time is NULL)
Select @MyCounter = 1
While (Select count(*) From @OutputTable Where myOrder = 0) > 0
BEGIN
 	 Select @maxStart = max(Actual_Start) From @OutputTable Where myOrder = 0
 	 SELECT @minPPId = MIN(PP_Id) FROM  @OutputTable Where myOrder = 0 and Actual_Start = @maxStart
 	 While (Select count(*) From @OutputTable Where myOrder = 0 and PP_Id = @minPPId) > 0
 	 BEGIN
 	  	 Select @minStartPPId =  Min(Actual_Start) From @OutputTable Where myOrder = 0  and PP_Id = @minPPId
 	  	 UPDATE @OutputTable Set myOrder = @MyCounter Where myOrder = 0  and PP_Id = @minPPId and Actual_Start = @minStartPPId
 	  	 Select @MyCounter = @MyCounter + 1
 	 END
END
IF @RegionalServer = 1
BEGIN
 	 DECLARE @T Table  (TimeColumns nvarchar(100))
 	 DECLARE @CHT Table  (HeaderTag Int,Idx Int)
 	 Insert into @T(TimeColumns) Values ('Start Time')
 	 Insert into @T(TimeColumns) Values ('End Time')
 	 Insert into @CHT(HeaderTag,Idx) Values (20072,1) -- Process Order
 	 Insert into @CHT(HeaderTag,Idx) Values (20498,2) -- Unit
 	 Insert into @CHT(HeaderTag,Idx) Values (20055,3) -- Start Time
 	 Insert into @CHT(HeaderTag,Idx) Values (20054,4) -- End Time
 	 Insert into @CHT(HeaderTag,Idx) Values (20180,5) -- PP_Status_Desc
 	 Insert into @CHT(HeaderTag,Idx) Values (20500,6) -- PP_Start_Id
 	 Select TimeColumns From @T
 	 Select HeaderTag From @CHT Order by Idx
 	 Select  	 [Process Order] = Process_Order,
 	  	  	 [Unit] = pu_Desc,
 	  	  	 [Start Time] = Actual_Start,
 	  	  	 [End Time] =Actual_End,
 	  	  	 [Status] = PP_Status_Desc,
 	  	  	 [PP Start Id ] = PP_Start_Id 
 	 FROM @OutputTable 
 	 order by myOrder,pu_Desc
END
ELSE
BEGIN
 	 select pu_Desc,Actual_Start ,Actual_End ,Process_Order,PP_Id,PP_Status_Desc,PP_Start_Id 
 	 from @OutputTable order by myOrder,pu_Desc
END
