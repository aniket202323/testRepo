CREATE PROCEDURE dbo.spServer_EMgrUpdEventFinalDims
@EventId int,
@DoDimX int,
@DoDimY int,
@DoDimZ int,
@DoDimA int,
@WETId_DimX int,
@WETId_DimY int,
@WETId_DimZ int,
@WETId_DimA int,
@DimXPEIIds nvarchar (100),
@DimYPEIIds nvarchar (100),
@DimZPEIIds nvarchar (100),
@DimAPEIIds nvarchar (100)
 AS
DECLARE 	 
 	 @EventInitialDimX 	 Float,
 	 @EventInitialDimY 	 Float,
 	 @EventInitialDimZ 	 Float,
 	 @EventInitialDimA 	 Float,
 	 @EventFinalDimX 	  	 Float,
 	 @EventFinalDimY 	  	 Float,
 	 @EventFinalDimZ 	  	 Float,
 	 @EventFinalDimA 	  	 Float,
 	 @ConsumedX 	  	 Float,
 	 @ConsumedY 	  	 Float,
 	 @ConsumedZ 	  	 Float,
 	 @ConsumedA 	  	 Float,
 	 @EventStartTime DateTime,
 	 @EventEndTime DateTime,
 	 @EventTimeStamp DateTime,
 	 @WastedX 	  	 Float,
 	 @WastedY 	  	 Float,
 	 @WastedZ 	  	 Float,
 	 @WastedA 	  	 Float,
 	 @EventPUId 	 int,
 	 @PUId 	  	  	  	 int
DECLARE @WasteTimes TABLE(EventId int null, WastedX int, WastedY int, WastedZ int, WastedA int, WETId int)
SELECT 	 @EventInitialDimX 	 = NULL, 	 @EventInitialDimY 	 = NULL, 	 @EventInitialDimZ 	 = NULL, 	 @EventInitialDimA 	 = NULL
SELECT 	 @ConsumedX 	  	  	  	 = 0, 	  	 @ConsumedY 	  	  	  	 = 0, 	  	 @ConsumedZ 	  	  	  	 = 0, 	  	 @ConsumedA 	  	  	  	 = 0
SELECT 	 @EventFinalDimX 	  	 = 0, 	  	 @EventFinalDimY 	  	 = 0, 	  	 @EventFinalDimZ 	  	 = 0, 	  	 @EventFinalDimA 	  	 = 0
SELECT 	 @WastedX 	  	  	  	  	 = 0, 	  	 @WastedY 	  	  	  	  	 = 0, 	  	 @WastedZ 	  	  	  	  	 = 0, 	  	 @WastedA 	  	  	  	  	 = 0
-- Get Event Data
SELECT 	 @EventTimeStamp   = null, @EventPUId = NULL
SELECT 	 @EventTimeStamp = TimeStamp, @EventPUId = PU_Id 	 FROM 	 Events WHERE Event_Id = @EventId
if @EventTimeStamp is NULL
 	 return
SELECT 	 @EventInitialDimX 	 = Coalesce(Initial_Dimension_X, 0), 	 @EventInitialDimY 	 = Coalesce(Initial_Dimension_Y, 0),
 	  	  	  	 @EventInitialDimZ 	 = Coalesce(Initial_Dimension_Z, 0), 	 @EventInitialDimA 	 = Coalesce(Initial_Dimension_A, 0)
 	 FROM 	 Event_Details WHERE Event_Id = @EventId
if @EventInitialDimX is NULL
 	 return
-------- Count Consumed -----------
create table #TempConsumed(DimX real, DimY real, DimZ real, DimA real, PEI_Id int)
insert into #TempConsumed (DimX, DimY, DimZ, DimA, PEI_Id) 
 	  	  	 SELECT Coalesce(Dimension_X,0), Coalesce(Dimension_Y,0), Coalesce(Dimension_Z,0), Coalesce(Dimension_A,0), Coalesce(PEI_Id,0) FROM 	 Event_Components  	 WHERE 	 Source_Event_Id 	 = @EventId
if (@DoDimX <> 0 and @DimXPEIIds is not null and len(@DimXPEIIds) > 0)
 	 exec ('update #TempConsumed set DimX = 0 WHERE PEI_Id not in (' + @DimXPEIIds + ')')
else if (@DoDimX <> 0)
 	 exec ('update #TempConsumed set DimX = 0')
if (@DoDimY <> 0 and @DimYPEIIds is not null and len(@DimYPEIIds) > 0)
 	 exec ('update #TempConsumed set DimY = 0 WHERE PEI_Id not in (' + @DimYPEIIds + ')')
else if (@DoDimY <> 0)
 	 exec ('update #TempConsumed set DimY = 0')
if (@DoDimZ <> 0 and @DimZPEIIds is not null and len(@DimZPEIIds) > 0)
 	 exec ('update #TempConsumed set DimZ = 0 WHERE PEI_Id not in (' + @DimZPEIIds + ')')
else if (@DoDimZ <> 0)
 	 exec ('update #TempConsumed set DimZ = 0')
if (@DoDimA <> 0 and @DimAPEIIds is not null and len(@DimAPEIIds) > 0)
 	 exec ('update #TempConsumed set DimA = 0 WHERE PEI_Id not in (' + @DimAPEIIds + ')')
else if (@DoDimA <> 0)
 	 exec ('update #TempConsumed set DimA = 0')
select @ConsumedX = sum(DimX), @ConsumedY = sum(DimY), @ConsumedZ = sum(DimZ), @ConsumedA = sum(DimA)  from #TempConsumed
-- Count waste
if (@WETId_DimX <> 0 or @WETId_DimY <> 0 or @WETId_DimZ <> 0 or @WETId_DimA <> 0) 
begin
 	 SELECT 	 @EventStartTime = Start_Time, @EventEndTime = Timestamp, @PUId = PU_Id FROM 	 Events WHERE Event_Id=@EventId
 	 if (@EventStartTime is null)
 	  	 SELECT 	 @EventStartTime = max(Timestamp) FROM 	 Events WHERE PU_Id = @PUId and Timestamp < @EventEndTime
 	 insert into @WasteTimes(EventId, WastedX, WastedY, WastedZ, WastedA, WETId) 	 SELECT 	 Event_Id, Coalesce(Dimension_X, Amount), Dimension_Y, Dimension_Z, Dimension_A, WET_Id 
 	  	  	  	  	 FROM 	 Waste_Event_Details 	  
 	  	  	  	  	 WHERE 	 Event_Id 	 = @EventId
 	 if (@EventStartTime is not null)
 	 begin
 	  	 insert into @WasteTimes(EventId, WastedX, WastedY, WastedZ, WastedA, WETId) 	 SELECT 	 NULL, Coalesce(Dimension_X, Amount), Dimension_Y, Dimension_Z, Dimension_A, WET_Id 
 	  	  	  	  	  	 FROM 	 Waste_Event_Details 	  with (index (WEvent_details_idx_EventIdTime)) 
 	  	  	  	  	  	 WHERE 	 (Event_Id 	 is null and (Timestamp > @EventStartTime and TimeStamp <= @EventEndTime)) 
 	 end
 	 IF 	 @DoDimX <> 0 and @WETId_DimX <> 0
 	  	 SELECT 	 @WastedX 	 = Sum(WastedX) 	 FROM 	 @WasteTimes 	  WHERE 	 WETId 	 = @WETId_DimX 
 	 IF 	 @DoDimY <> 0 and @WETId_DimY <> 0
 	  	 SELECT 	 @WastedY 	 = Sum(WastedY) 	 FROM 	 @WasteTimes 	  WHERE 	 WETId 	 = @WETId_DimY
 	 IF 	 @DoDimZ <> 0 and @WETId_DimZ <> 0
 	  	 SELECT 	 @WastedZ 	 = Sum(WastedZ) 	 FROM 	 @WasteTimes 	  WHERE 	 WETId 	 = @WETId_DimZ
 	 IF 	 @DoDimA <> 0 and @WETId_DimA <> 0
 	  	 SELECT 	 @WastedA 	 = Sum(WastedA) 	 FROM 	 @WasteTimes 	  WHERE 	 WETId 	 = @WETId_DimA 
end
Select @WastedX = 0.0 where @WastedX is null
Select @WastedY = 0.0 where @WastedY is null
Select @WastedZ = 0.0 where @WastedZ is null
Select @WastedA = 0.0 where @WastedA is null
-------------------------------------------------------------------------------
-- Calculate the updated Final dimension
------------------------------------------------------------------------------- 	 
SELECT 	 @EventFinalDimX 	 = @EventInitialDimX - @ConsumedX - @WastedX
SELECT 	 @EventFinalDimY 	 = @EventInitialDimY - @ConsumedY - @WastedY
SELECT 	 @EventFinalDimZ 	 = @EventInitialDimZ - @ConsumedZ - @WastedZ
SELECT 	 @EventFinalDimA 	 = @EventInitialDimA - @ConsumedA - @WastedA
/*
-- Debugging
SELECT 	 @EventInitialDimX 	 , 	 @EventInitialDimY 	 , 	 @EventInitialDimZ 	 , 	 @EventInitialDimA 	 
SELECT 	 @ConsumedX 	  	  	  	 , 	  	 @ConsumedY 	  	  	  	 , 	  	 @ConsumedZ 	  	  	  	 , 	  	 @ConsumedA 	  	  	  	 
SELECT 	 @WastedX 	  	  	  	  	 , 	  	 @WastedY 	  	  	  	  	 , 	  	 @WastedZ 	  	  	  	  	 , 	  	 @WastedA 	  	  	  	  	 
SELECT 	 @EventFinalDimX 	  	 , 	  	 @EventFinalDimY 	  	 , 	  	 @EventFinalDimZ 	  	 , 	  	 @EventFinalDimA 	  	 
*/
/*
Trans Nums
104  Final Dim X Has Changed  EventId and Dimension is all that is looked at.
105  Final Dim Y Has Changed  EventId and Dimension is all that is looked at.
106  Final Dim Z Has Changed  EventId and Dimension is all that is looked at.
107  Final Dim A Has Changed  EventId and Dimension is all that is looked at.
*/
if (@DoDimX <> 0)
 	 select 10, 1, 0, 1, 104, @EventId, @EventPUId, NULL, NULL, NULL, NULL, NULL, NULL, NULL, @EventTimeStamp, NULL, NULL, 
 	  	  	  	  	  	  	 NULL, NULL, NULL, NULL, InitX=@EventInitialDimX, @EventInitialDimY, @EventInitialDimZ, @EventInitialDimA, @EventFinalDimX, @EventFinalDimY, @EventFinalDimZ, @EventFinalDimA, NULL, NULL, NULL, NULL
if (@DoDimY <> 0)
 	 select 10, 1, 0, 1, 105, @EventId, @EventPUId, NULL, NULL, NULL, NULL, NULL, NULL, NULL, @EventTimeStamp, NULL, NULL, 
 	  	  	  	  	  	  	 NULL, NULL, NULL, NULL, InitX=@EventInitialDimX, @EventInitialDimY, @EventInitialDimZ, @EventInitialDimA, @EventFinalDimX, @EventFinalDimY, @EventFinalDimZ, @EventFinalDimA, NULL, NULL, NULL, NULL
if (@DoDimZ <> 0)
 	 select 10, 1, 0, 1, 106, @EventId, @EventPUId, NULL, NULL, NULL, NULL, NULL, NULL, NULL, @EventTimeStamp, NULL, NULL, 
 	  	  	  	  	  	  	 NULL, NULL, NULL, NULL, InitX=@EventInitialDimX, @EventInitialDimY, @EventInitialDimZ, @EventInitialDimA, @EventFinalDimX, @EventFinalDimY, @EventFinalDimZ, @EventFinalDimA, NULL, NULL, NULL, NULL
if (@DoDimA <> 0)
 	 select 10, 1, 0, 1, 107, @EventId, @EventPUId, NULL, NULL, NULL, NULL, NULL, NULL, NULL, @EventTimeStamp, NULL, NULL, 
 	  	  	  	  	  	  	 NULL, NULL, NULL, NULL, InitX=@EventInitialDimX, @EventInitialDimY, @EventInitialDimZ, @EventInitialDimA, @EventFinalDimX, @EventFinalDimY, @EventFinalDimZ, @EventFinalDimA, NULL, NULL, NULL, NULL
