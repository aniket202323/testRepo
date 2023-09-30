/*
Get Downtime data for a set of production units.
@EquipmentList           - Comma separated list of production unit equipment ids
@UnitList                - Comma separated list of production units
@StartTime               - Start time
@EndTime                 - End time
@InTimeZone              - Ex: 'India Standard Time','Central Stardard Time'
@IncludeSummary          - Request a second result set with a summary of the data by unit
*/
CREATE Procedure [dbo].[spBF_DowntimeGetData]
@EquipmentList           nvarchar(max),
@UnitList                nvarchar(max),
@StartTime               datetime = NULL,
@EndTime                 datetime = NULL,
@InTimeZone              nVarChar(200) = NULL,
@IncludeSummary          bit = 0,
@MinDurationFilter       float = null,
@EventId 	  	  	  	  int = null,
@TrimReportRange 	  	  Int = 1
,@OEEParameter nvarchar(50) = NULL--Time based OEE : Availability/Performance/Quality. NULL in case of Classic OEE
AS
/* ##### spBF_DowntimeGetData #####
Description 	 : Returns data for Gaant chart (Summary/Line level) for Availability donut in case of classic OEE and for Availability, Performance & Quality donuts in case of Time based OEE
Creation Date 	 : if any
Created By 	 : if any
#### Update History ####
DATE 	  	  	  	 Modified By 	  	 UserStory/Defect No 	  	 Comments 	  	 
---- 	  	  	  	 ----------- 	  	  	 ------------------- 	  	  	  	 --------
2018-02-20 	 Prasad 	  	  	  	 7.0 SP3 	 F28159 	  	  	  	 Modified procedure to handle time based downtime calculation.
*/
set nocount on
If @OEEParameter IS NOT NULL AND @OEEParameter NOT LIKE '%loss%'
Begin
 	 If (@OEEParameter = 'Quality')
 	 Begin
 	  	 Set @OEEParameter = 'Quality losses'
 	 End
 	 Else
 	 Begin
 	  	 Set @OEEParameter = @OEEParameter + ' loss'
 	 End
End
IF @TrimReportRange is null Set @TrimReportRange = 1
SELECT @StartTime = dbo.fnServer_CmnConvertToDBTime(@StartTime,@InTimeZone)
SELECT @Endtime = dbo.fnServer_CmnConvertToDBTime(@Endtime,@InTimeZone)
Declare @IsCalledFromMESProc BIT
 	 SET @IsCalledFromMESProc = 0
IF @EquipmentList = 'MES'
 	 BEGIN
 	  	 SET @IsCalledFromMESProc = 1
 	  	 SET @EquipmentList = NULL
 	 END
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
Declare @Units Table (UnitId int, EquipId uniqueidentifier, OEEMode nvarchar(20))
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
--<Update OEE Mode for All units>
;WITH S As 
(
Select 
       TFV.KeyID UnitId, EDFTV.Field_desc
From 
       Table_Fields TF
       JOIN Table_Fields_Values TFV on TFV.Table_Field_Id = TF.Table_Field_Id and TFV.TableId = TF.TableId
       Join ED_FieldTypes EDFT On EDFT.ED_Field_Type_Id = TF.ED_Field_Type_Id
       LEFT OUTER Join ED_FieldType_ValidValues EDFTV on EDFTV.ED_Field_Type_Id = TF.ED_Field_Type_Id AND EDFTV.Field_Id = TFV.Value
Where 
       TF.Table_Field_Desc = 'OEE Calculation Type'
)
Update u
SET
 	 u.OEEMode = Isnull(S.Field_desc,'Classic')
From 
 	 @Units u
 	 Left Outer Join S on S.UnitId = u.UnitId
--</Update OEE Mode for All units>
-------------------------------------------------------------------------------------------------
-- Get the downtime data
-------------------------------------------------------------------------------------------------
Declare @DowntimeData table (
 	 EventId int,
 	 UnitEquipmentId uniqueidentifier,
 	 UnitId int,
 	 Unit nVarChar(100),
 	 StartTime datetime null,
 	 EndTime datetime null,
 	 Duration decimal(10,2) null,
 	 Uptime float null,
 	 LocationEquipmentId uniqueidentifier null,
 	 LocationId int null,
 	 Location nVarChar(100) null,
 	 FaultId int null,
 	 Fault nVarChar(100) null,
 	 StatusId int null,
 	 Status nVarChar(100) null,
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
 	 Operator nVarChar(255) null
)
if (@EventId is not null)
 	 Begin
 	  	 insert into @DowntimeData ( EventId, UnitEquipmentId, UnitId, Unit, StartTime, EndTime, Duration, Uptime, LocationEquipmentId, LocationId,
 	  	  	  	  	  	  	  	  	 Location, FaultId, Fault, StatusId, Status, Reason1Id, Reason1, Reason2Id, Reason2, Reason3Id, Reason3,
 	  	  	  	  	  	  	  	  	 Reason4Id, Reason4, Action1Id, Action1, Action2Id, Action2, Action3Id, Action3, Action4Id, Action4,
 	  	  	  	  	  	  	  	  	 ReasonComment, ActionComment, ReasonsCompleted)
 	  	 select 	 d.DowntimeEventId, a1.Origin1EquipmentId, d.ProductionUnitId, d.ProductionUnit, d.StartTime, d.EndTime, d.Duration, ted.Uptime,
 	  	  	  	 Coalesce(a2.Origin1EquipmentId, a1.Origin1EquipmentId), Coalesce(d.SourceProductionUnitId, d.ProductionUnitId),
 	  	  	  	 Coalesce(d.SourceProductionUnit, d.ProductionUnit), d.DowntimeFaultId, d.DowntimeFault, d.DowntimeStatusId, d.DowntimeStatus,
 	  	  	  	 d.Cause1Id, d.Cause1, d.Cause2Id, d.Cause2, d.Cause3Id, d.Cause3, d.Cause4Id, d.Cause4, d.Action1Id, d.Action1,
 	  	  	  	 d.Action2Id, d.Action2, d.Action3Id, d.Action3, d.Action4Id, d.Action4, d.CauseCommentText, d.ActionCommentText,
 	  	  	  	 Coalesce(ertd.Bottom_Of_Tree, 0)
 	  	   from 	 [dbo].[SDK_V_PADowntimeEvent] d
 	  	   join 	 [dbo].Timed_Event_Details ted on ted.TEDet_Id = d.DowntimeEventId
 	  	   Join @Units U on U.UnitId = ted.PU_Id
 	  	   Left join 	 [dbo].[PAEquipment_Aspect_SOAEquipment] a1 on a1.PU_Id = d.ProductionUnitId
 	  	   left join 	 [dbo].[PAEquipment_Aspect_SOAEquipment] a2 on a2.PU_Id = d.SourceProductionUnitId
 	  	   left join [dbo].[Event_Reason_Tree_Data] ertd on ertd.Event_Reason_Tree_Data_Id = d.ReasonTreeDataId  
 	  	   where d.DowntimeEventId = @EventId 
 	  	   select 	 EventId, UnitEquipmentId, UnitId, Unit,
 	  	 dbo.fnServer_CmnConvertFromDbTime(StartTime, @InTimeZone) 	 as 'StartTime',
 	  	 dbo.fnServer_CmnConvertFromDbTime(EndTime, @InTimeZone) 	  	 as 'EndTime',
 	  	 Duration, LocationEquipmentId, LocationId, Location, FaultId, Fault, StatusId, Status,
 	  	 Reason1Id, Reason1, Reason2Id, Reason2, Reason3Id, Reason3, Reason4Id, Reason4,
 	  	 Action1Id, Action1, Action2Id, Action2, Action3Id, Action3, Action4Id, Action4,
 	  	 ReasonComment, ActionComment, ReasonsCompleted, Operator
 	  	 from 	 @DowntimeData
 	 End
Else
 	 Begin
 	 
insert into @DowntimeData ( EventId, UnitEquipmentId, UnitId, Unit, StartTime, EndTime, Duration, Uptime, LocationEquipmentId, LocationId,
 	  	  	  	  	  	  	 Location, FaultId, Fault, StatusId, Status, Reason1Id, Reason1, Reason2Id, Reason2, Reason3Id, Reason3,
 	  	  	  	  	  	  	 Reason4Id, Reason4, Action1Id, Action1, Action2Id, Action2, Action3Id, Action3, Action4Id, Action4,
 	  	  	  	  	  	  	 ReasonComment, ActionComment, ReasonsCompleted)
select 	 d.DowntimeEventId, a1.Origin1EquipmentId, d.ProductionUnitId, d.ProductionUnit, d.StartTime, d.EndTime, d.Duration, ted.Uptime,
 	  	 Coalesce(a2.Origin1EquipmentId, a1.Origin1EquipmentId), Coalesce(d.SourceProductionUnitId, d.ProductionUnitId),
 	  	 Coalesce(d.SourceProductionUnit, d.ProductionUnit), d.DowntimeFaultId, d.DowntimeFault, d.DowntimeStatusId, d.DowntimeStatus,
 	  	 d.Cause1Id, d.Cause1, d.Cause2Id, d.Cause2, d.Cause3Id, d.Cause3, d.Cause4Id, d.Cause4, d.Action1Id, d.Action1,
 	  	 d.Action2Id, d.Action2, d.Action3Id, d.Action3, d.Action4Id, d.Action4, d.CauseCommentText, d.ActionCommentText,
 	  	 Coalesce(ertd.Bottom_Of_Tree, 0)
  from 	 [dbo].[SDK_V_PADowntimeEvent] d
  join 	 [dbo].Timed_Event_Details ted on ted.TEDet_Id = d.DowntimeEventId
  Join @Units U on U.UnitId = d.ProductionUnitId
  Left join 	 [dbo].[PAEquipment_Aspect_SOAEquipment] a1 on a1.PU_Id = d.ProductionUnitId
  left join 	 [dbo].[PAEquipment_Aspect_SOAEquipment] a2 on a2.PU_Id = d.SourceProductionUnitId
  left join [dbo].[Event_Reason_Tree_Data] ertd on ertd.Event_Reason_Tree_Data_Id = d.ReasonTreeDataId  
  where 
 	  	 d.ProductionUnitId in (select UnitId from @Units) and
 	  	 d.StartTime < @EndTime AND ( d.EndTime > @StartTime OR d.EndTime Is NULL ) 
 	  	 and  
 	  	  	  	 ( 
 	  	  	  	  	 (d.Cause1 = @OEEParameter And @OEEParameter IS NOT NULL)
 	  	  	  	  	 OR
 	  	  	  	  	 (@OEEParameter IS NULL AND U.OEEMode <> 'Time Based')
 	  	  	  	  	 OR
 	  	  	  	  	 (@OEEParameter IS NULL AND U.OEEMode = 'Time Based' AND d.Cause1 = 'Availability Loss')
 	  	  	  	  	 OR
 	  	  	  	  	 (@IsCalledFromMESProc = 1)
 	  	  	  	 )
-- Lookup Equipment Operators if the table is available
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[User_Equipment_Assignment]') and OBJECTPROPERTY(id, N'IsTable') = 1)
 	 Begin
 	  	 UPDATE d
 	  	 SET Operator 	 = Coalesce(U.Username, 'Unknown')
 	  	 FROM @DowntimeData d
 	  	 Left Join [dbo].[User_Equipment_Assignment] ea on ea.EquipmentId = d.UnitId
 	  	  	  	   and d.EndTime >= ea.StartTime and (d.EndTime < ea.EndTime or ea.EndTime IS NULL)
 	  	 Left Join [dbo].[Users] U on U.User_Id = ea.UserId
 	 End
Else
 	 Begin
 	  	 UPDATE @DowntimeData SET Operator = 'Unknown' Where Operator is null
 	 End
 	  
IF @TrimReportRange = 1
BEGIN
 	 update @DowntimeData set StartTime = @StartTime where StartTime < @StartTime
 	 update @DowntimeData set EndTime = @EndTime where EndTime > @EndTime
 	 update @DowntimeData set Duration = (DATEDIFF(Second, StartTime, EndTime) / 60.0) where StartTime = @StartTime or EndTime = @EndTime
 	 update @DowntimeData set Duration = (DATEDIFF(Second, StartTime, @EndTime) / 60.0) where EndTime is null
END
if (@MinDurationFilter is not null)
 	 delete @DowntimeData where Duration < @MinDurationFilter
select 	 EventId, UnitEquipmentId, UnitId, Unit,
 	  	 dbo.fnServer_CmnConvertFromDbTime(StartTime, @InTimeZone) 	 as 'StartTime',
 	  	 dbo.fnServer_CmnConvertFromDbTime(EndTime, @InTimeZone) 	  	 as 'EndTime',
 	  	 Duration, LocationEquipmentId, LocationId, Location, FaultId, Fault, StatusId, Status,
 	  	 Reason1Id, Reason1, Reason2Id, Reason2, Reason3Id, Reason3, Reason4Id, Reason4,
 	  	 Action1Id, Action1, Action2Id, Action2, Action3Id, Action3, Action4Id, Action4,
 	  	 ReasonComment, ActionComment, ReasonsCompleted, Operator
  from 	 @DowntimeData
-------------------------------------------------------------------------------------------------
-- Include a summary if requested
-------------------------------------------------------------------------------------------------
Declare @TotalDownTime Float
Select @TotalDownTime = 0.0
Select @TotalDownTime = @TotalDownTime + coalesce((SELECT sum(Duration) From @DowntimeData),0)
if @TotalDownTime <= 0.01 set @TotalDownTime = 0.01
Declare @TotalQryTime Float
Select @TotalQryTime = DATEDIFF(Second, @StartTime, @EndTime) / 60.0
if @TotalQryTime <= 0.01 set @TotalQryTime = 0.01
if (@IncludeSummary = 1)
Begin
  -- Force all units to appear in the summary
  insert into @DowntimeData (EventId, UnitEquipmentId, UnitId, Unit, StartTime, EndTime, Duration, Uptime)
  (select 	 null, EquipId, UnitId, e.S95Id, @StartTime, @StartTime, 0.0, 0.0
  from 	 @Units u
  join  Equipment e on e.EquipmentId = u.EquipId)
  Select 	 UnitId, UnitEquipmentId, Unit,
 	  	  	 sum(Duration) 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 as 'TotalDowntime',
 	  	  	 convert(decimal(10,2),@TotalQryTime - sum(Duration)) 	  	  	  	  	  	  	 as 'TotalUptime',
 	  	  	 avg(Duration) 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 as 'MTTR',
 	  	  	 avg(Uptime) 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 as 'MTBF',
 	  	  	 convert(decimal(10,2),sum(Duration) / @TotalDowntime * 100.0) 	  	  	  	  	 as 'PctTotal',
 	  	  	 convert(decimal(10,2),sum(Duration) / @TotalQryTime * 100.0) 	  	  	  	  	 as 'PctDowntime',
 	  	  	 convert(decimal(10,2),(@TotalQryTime - sum(Duration)) / @TotalQryTime * 100.0) 	 as 'PctUptime',
 	  	  	 count(distinct(EventId)) 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 as 'Events'
 	  	  	 
  from @DowntimeData
  group by UnitId, UnitEquipmentId, Unit
End
End
