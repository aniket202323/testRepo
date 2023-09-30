/*
Get Waste data for a set of production units.
@EquipmentList           - Comma separated list of production unit equipment ids
@UnitList                - Comma separated list of production units
@StartTime               - Start time
@EndTime                 - End time
@InTimeZone              - Ex: 'India Standard Time','Central Stardard Time'
@IncludeSummary          - Request a second result set with a summary of the data by unit
*/
CREATE Procedure [dbo].[spBF_WasteGetData]
@EquipmentList           nvarchar(max),
@UnitList                nvarchar(max),
@StartTime               datetime = NULL,
@EndTime                 datetime = NULL,
@InTimeZone              nVarChar(200) = NULL,
@IncludeSummary          bit = 0
AS
set nocount on
SELECT @StartTime = dbo.fnServer_CmnConvertToDBTime(@StartTime,@InTimeZone)
SELECT @Endtime = dbo.fnServer_CmnConvertToDBTime(@Endtime,@InTimeZone)
-------------------------------------------------------------------------------------------------
-- Equipment/Unit translation
-------------------------------------------------------------------------------------------------
If (@EquipmentList is Not Null)
 	 Set @EquipmentList = REPLACE(@EquipmentList, ' ', '')
If (@UnitList is Not Null)
 	 Set @UnitList = REPLACE(@UnitList, ' ', '')
if ((@EquipmentList is Not Null) and (LEN(@EquipmentList) = 0))
 	 Set @EquipmentList = Null
if ((@UnitList is Not Null) and (LEN(@UnitList) = 0))
 	 Set @UnitList = Null
Declare @Units Table (UnitId int, EquipId uniqueidentifier)
if (@UnitList is not null)
 	 begin
 	  	 insert into @Units (UnitId)
 	  	 select Id from [dbo].[fnCmn_IdListToTable]('Prod_Units',@UnitList,',')
 	  	 UPDATE u
 	  	   SET  EquipId 	 = a.Origin1EquipmentId
 	  	   FROM @Units u
 	  	   join [dbo].[PAEquipment_Aspect_SOAEquipment] a on a.PU_Id = u.UnitId
 	 end
else if (@EquipmentList is not null)
 	 begin
 	  	 Declare @mytable table (id int identity(1,1), value nVarChar(100))
 	  	 insert into @mytable(value)
 	  	 select value from [dbo].[fnLocal_CmnParseList](@EquipmentList,',')
 	  	 insert into @Units (UnitId, EquipId)
 	  	 Select a.PU_Id, a.Origin1EquipmentId
 	  	   From [dbo].[PAEquipment_Aspect_SOAEquipment] a
 	  	   Join @mytable e on e.value = a.Origin1EquipmentId
 	  	   where a.PU_Id is not null
 	 end
Set @EquipmentList = ''
Set @UnitList = ''
SELECT @EquipmentList = @EquipmentList + COALESCE(convert(nVarChar(50), EquipId) + ',' ,''),
       @UnitList = @UnitList + COALESCE(convert(nVarChar(50), UnitId) + ',' ,'')
  FROM @Units
  order by UnitId
if (LEN(@EquipmentList) > 0)
 	 Set @EquipmentList = Left(@EquipmentList, LEN(@EquipmentList) - 1)
if (LEN(@UnitList) > 0)
 	 Set @UnitList = Left(@UnitList, LEN(@UnitList) - 1)
-------------------------------------------------------------------------------------------------
-- Get the Waste data
-------------------------------------------------------------------------------------------------
Declare @WasteData table (
 	 EventId int,
 	 UnitEquipmentId uniqueidentifier,
 	 UnitId int,
 	 Unit nVarChar(100),
 	 StartTime datetime null,
 	 EndTime datetime null,
 	 Duration decimal(10,2) null,
 	 LocationEquipmentId uniqueidentifier null,
 	 LocationId int null,
 	 Location nVarChar(100) null,
 	 FaultId int null,
 	 Fault nVarChar(100) null,
 	 Reason1Id int null, Reason1 nVarChar(100) null,
 	 Reason2Id int null, Reason2 nVarChar(100) null,
 	 Reason3Id int null, Reason3 nVarChar(100) null,
 	 Reason4Id int null, Reason4 nVarChar(100) null,
 	 Action1Id int null, Action1 nVarChar(100) null,
 	 Action2Id int null, Action2 nVarChar(100) null,
 	 Action3Id int null, Action3 nVarChar(100) null,
 	 Action4Id int null, Action4 nVarChar(100) null,
 	 ReasonComment text null,
 	 ActionComment text null,
 	 ReasonsCompleted tinyint null,
 	 Operator nVarChar(255) null,
 	 Amount float Null,
 	 Waste_Measure_Id Int Null,
 	 WasteMeasure nVarChar(100) Null,
 	 Waste_Type_id 	 Int Null,
 	 WasteType nVarChar(100) Null
)
insert into @WasteData ( EventId, UnitEquipmentId, UnitId, Unit, StartTime, 
 	  	  	  	  	  	 EndTime, LocationEquipmentId, LocationId,Location, FaultId, 
 	  	  	  	  	  	 Fault, Reason1Id, Reason1,Reason2Id, Reason2, 
 	  	  	  	  	  	 Reason3Id, Reason3,Reason4Id,Reason4, Action1Id, 
 	  	  	  	  	  	 Action1, Action2Id, Action2,Action3Id, Action3, 
 	  	  	  	  	  	 Action4Id, Action4, 	 ReasonComment,ActionComment, ReasonsCompleted,
 	  	  	  	  	  	 Amount,Waste_Measure_Id,WasteMeasure,Waste_Type_id,WasteType)
select 	 d.WasteEventId, a1.Origin1EquipmentId, d.ProductionUnitId, d.ProductionUnit, d.Timestamp, 
 	  	 d.Timestamp, Coalesce(a2.Origin1EquipmentId, a1.Origin1EquipmentId), Coalesce(d.SourceProductionUnitId, d.ProductionUnitId),Coalesce(d.SourceProductionUnit, d.ProductionUnit), d.WasteFaultId,
 	  	  d.WasteFault,d.Cause1Id, d.Cause1, d.Cause2Id, d.Cause2, 
 	  	  d.Cause3Id, d.Cause3, d.Cause4Id, d.Cause4, d.Action1Id, 
 	  	  d.Action1, 	 d.Action2Id, d.Action2, d.Action3Id, d.Action3, 
 	  	  d.Action4Id, d.Action4, d.CauseCommentText, d.ActionCommentText,Coalesce(ertd.Bottom_Of_Tree, 0),
 	  	  d.Amount,d.WasteMeasurementId,d.WasteMeasurement,d.WasteTypeId,d.WasteType 
  from 	 [dbo].[SDK_V_PAWasteEvent]  d
  join 	 [dbo].[PAEquipment_Aspect_SOAEquipment] a1 on a1.PU_Id = d.ProductionUnitId
  left join 	 [dbo].[PAEquipment_Aspect_SOAEquipment] a2 on a2.PU_Id = d.SourceProductionUnitId
  left join [dbo].[Event_Reason_Tree_Data] ertd on ertd.Event_Reason_Tree_Data_Id = d.ReasonTreeDataId  
  where d.ProductionUnitId in (select UnitId from @Units) and
 	  	  d.Timestamp > @StartTime and d.Timestamp <= @EndTime  and d.ProductionEventId is null
insert into @WasteData ( EventId, UnitEquipmentId, UnitId, Unit, StartTime, EndTime, LocationEquipmentId, LocationId,
 	  	  	  	  	  	  	 Location, FaultId, Fault,  Reason1Id, Reason1, Reason2Id, Reason2, Reason3Id, Reason3,
 	  	  	  	  	  	  	 Reason4Id, Reason4, Action1Id, Action1, Action2Id, Action2, Action3Id, Action3, Action4Id, Action4,
 	  	  	  	  	  	  	 ReasonComment, ActionComment, ReasonsCompleted,Amount,Waste_Measure_Id,WasteMeasure,Waste_Type_id,WasteType)
select 	 d.WasteEventId, a1.Origin1EquipmentId, d.ProductionUnitId, d.ProductionUnit, d.Timestamp, d.Timestamp, 
 	  	 Coalesce(a2.Origin1EquipmentId, a1.Origin1EquipmentId), Coalesce(d.SourceProductionUnitId, d.ProductionUnitId),
 	  	 Coalesce(d.SourceProductionUnit, d.ProductionUnit), d.WasteFaultId, d.WasteFault, 
 	  	 d.Cause1Id, d.Cause1, d.Cause2Id, d.Cause2, d.Cause3Id, d.Cause3, d.Cause4Id, d.Cause4, d.Action1Id, d.Action1,
 	  	 d.Action2Id, d.Action2, d.Action3Id, d.Action3, d.Action4Id, d.Action4, d.CauseCommentText, d.ActionCommentText,
 	  	 Coalesce(ertd.Bottom_Of_Tree, 0),d.Amount,d.WasteMeasurementId,d.WasteMeasurement,d.WasteTypeId,d.WasteType 
  from 	 events a
  Join [dbo].[SDK_V_PAWasteEvent]  d on d.ProductionEventId = a.Event_Id 
  join 	 [dbo].[PAEquipment_Aspect_SOAEquipment] a1 on a1.PU_Id = d.ProductionUnitId
  left join 	 [dbo].[PAEquipment_Aspect_SOAEquipment] a2 on a2.PU_Id = d.SourceProductionUnitId
  left join [dbo].[Event_Reason_Tree_Data] ertd on ertd.Event_Reason_Tree_Data_Id = d.ReasonTreeDataId 
  where d.ProductionUnitId in (select UnitId from @Units) and
 	  	    a.Start_Time <= @Endtime AND ( a.TimeStamp > @StartTime )
-- Lookup Equipment Operators if the table is available
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[User_Equipment_Assignment]') and OBJECTPROPERTY(id, N'IsTable') = 1)
 	 Begin
 	  	 UPDATE d
 	  	 SET Operator 	 = Coalesce(U.Username, 'Unknown')
 	  	 FROM @WasteData d
 	  	 Left Join [dbo].[User_Equipment_Assignment] ea on ea.EquipmentId = d.UnitId
 	  	  	  	   and d.EndTime >= ea.StartTime and (d.EndTime < ea.EndTime or ea.EndTime IS NULL)
 	  	 Left Join [dbo].[Users] U on U.User_Id = ea.UserId
 	 End
Else
 	 Begin
 	  	 UPDATE @WasteData SET Operator = 'Unknown' Where Operator is null
 	 End
update @WasteData set StartTime = @StartTime where StartTime < @StartTime
update @WasteData set EndTime = @EndTime where EndTime > @EndTime
update @WasteData set Duration = (DATEDIFF(Second, StartTime, EndTime) / 60.0) 
select 	 EventId, UnitEquipmentId, UnitId, Unit,
 	  	 StartTime = dbo.fnServer_CmnConvertFromDbTime(StartTime, @InTimeZone),
 	  	 EndTime = dbo.fnServer_CmnConvertFromDbTime(EndTime, @InTimeZone),
 	  	 Duration, LocationEquipmentId, LocationId, Location, FaultId, Fault, 
 	  	 Reason1Id, Reason1, Reason2Id, Reason2, Reason3Id, Reason3, Reason4Id, Reason4,
 	  	 Action1Id, Action1, Action2Id, Action2, Action3Id, Action3, Action4Id, Action4,
 	  	 ReasonComment, ActionComment, ReasonsCompleted, Operator,Amount,Waste_Measure_Id,WasteMeasure,Waste_Type_id,WasteType
  from 	 @WasteData
-------------------------------------------------------------------------------------------------
-- Include a summary if requested
-------------------------------------------------------------------------------------------------
Declare @TotalWaste Float
Select @TotalWaste = 0.0
Select @TotalWaste = @TotalWaste + coalesce((SELECT sum(Amount) From @WasteData),0)
if @TotalWaste <= 0.01 set @TotalWaste = 0.01
Declare @TotalQryTime Float
Select @TotalQryTime = DATEDIFF(Second, @StartTime, @EndTime) / 60.0
if @TotalQryTime <= 0.01 set @TotalQryTime = 0.01
if (@IncludeSummary = 1)
Begin
  -- Force all units to appear in the summary
  insert into @WasteData (EventId, UnitEquipmentId, UnitId, Unit, StartTime, EndTime, Duration)
  (select 	 null, EquipId, UnitId, e.S95Id, @StartTime, @StartTime, 0.0
  from 	 @Units u
  join  Equipment e on e.EquipmentId = u.EquipId)
  Select 	 UnitId, UnitEquipmentId, Unit,
 	  	  	 TotalWaste = sum(Amount),
 	  	  	 AverageWaste = avg(Amount),
 	  	  	 Events = count(distinct(EventId))
  from @WasteData
  group by UnitId, UnitEquipmentId, Unit
End
