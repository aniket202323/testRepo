CREATE Procedure dbo.spDBR_TopNDowntime
@UnitList text = NULL,
@StartTime datetime = NULL,
@EndTime datetime = NULL,
@ProductFilter int = null,
@CrewFilter varchar(10) = null,
@LocationFilter int = NULL,
@FaultFilter varchar(100) = NULL,
@ReasonFilter1 int = NULL,
@ReasonFilter2 int = NULL,
@ReasonFilter3 int = NULL,
@ReasonFilter4 int = NULL,
@ReportLevel int = 0,
@TopNumber int = 10,
@FilterNonProductiveTime int = 0,
@InTimeZone 	  	 varchar(200) = NULL  ---23/08/2010 - Ex: 'India Standard Time','Central Stardard Time' 
AS
--******************************************************/
SET ANSI_WARNINGS off
set arithignore on
set arithabort off
Declare @@UnitId int
Declare @SQL1 varchar(3000)
Declare @SQL2 varchar(3000)
Declare @SQL3 varchar(3000)
Declare @SQL4 varchar(3000)
Declare @FaultId int
Declare @TreeId int
Declare @Level1Name varchar(100)
Declare @Level2Name varchar(100)
Declare @Level3Name varchar(100)
Declare @Level4Name varchar(100)
Declare @Summary Table (
 	 Timestamp 	  	  	 datetime,
 	 ProductId 	  	  	 int NULL,
 	 ItemId 	  	  	  	 int NULL,
 	 Duration 	  	  	 real NULL,
 	 TimeToRepair 	  	 real NULL,
 	 TimePreviousFailure 	 real NULL,
 	 Fault 	  	  	  	 varchar(100) NULL,
 	 Crew 	  	  	  	 varchar(10) NULL
) 
Declare @TotalOperatingTime bigint
Declare @TotalDownTime real
Select @TotalOperatingTime = 0
Select @TotalDownTime = 0.0
--*****************************************************/
--Build List Of Units
--*****************************************************/
create table #Units
(
 	 LineName 	 varchar(100) NULL, 
 	 LineId 	  	 int NULL,
 	 UnitName 	 varchar(100) NULL,
 	 Item 	  	 int
)
Declare @Units Table
(
 	 LineName 	 varchar(100) NULL, 
 	 LineId 	 int NULL,
 	 UnitName 	 varchar(100) NULL,
 	 Item 	  	 int
)
create table #ProductiveTimes
(
 	 PU_Id     int null,
 	 StartTime datetime,
 	 EndTime   datetime
)
Declare @ProductiveTimes Table
(
 	 PU_Id     int null,
 	 StartTime datetime,
 	 EndTime   datetime
)
---23/08/2010 - Conversion of datetime into UTC e.g. India Standard Time','Central Stardard Time'
 	 SELECT @StartTime = dbo.fnServer_CmnConvertToDBTime(@StartTime,@InTimeZone)
 	 SELECT @EndTime = dbo.fnServer_CmnConvertToDBTime(@EndTime,@InTimeZone)
if (not @UnitList like '%<Root></Root>%' and not @UnitList is NULL)
 	 begin
 	  	 if (not @UnitList like '%<Root>%')
 	  	  	 begin
 	  	  	  	 declare @InputString varchar(8000)
 	  	  	  	 Select @InputString = @UnitList
 	  	  	  	 Declare @INstr VarChar(7999), @I int, @Id int,@Divider varchar(1)
 	  	  	  	 Select @Divider = ';'
 	  	  	  	 Declare @T TABLE (Id_Value Int)
 	  	  	  	 Select @I = 1
 	  	  	  	 Select @INstr = @InputString + @Divider
 	  	  	  	 While (Datalength(LTRIM(RTRIM(@INstr))) > 1) 
 	  	  	  	   Begin
 	  	  	  	  	 Select @Id = SubString(@INstr,1,CharIndex(@Divider,@INstr)-1)
 	  	  	  	  	 insert into @T (Id_Value) Values (@Id)
 	  	  	  	  	 Select @INstr = SubString(@INstr,CharIndex(@Divider,@INstr),Datalength(@INstr))
 	  	  	  	  	 Select @INstr = Right(@INstr,Datalength(@INstr)-1)
 	  	  	  	   End
 	  	  	  	    -- copy to the result of the function the required columns
 	  	  	  	    INSERT @Units(Item)
 	  	  	  	  	  Select Id_Value From @T
 	  	  	 end
 	  	 else
 	  	  	 begin
 	  	  	   insert into #Units (LineName, LineId, UnitName, Item) 
 	  	  	  	 EXECUTE spDBR_Prepare_Table @UnitList
 	  	  	   Insert Into @Units (LineName, LineId, UnitName, Item) 
 	  	  	  	 Select LineName, LineId, UnitName, Item
 	  	  	  	  	 From #Units
 	  	  	 end
 	 end
Else
  Begin
    Insert Into @Units (Item) 
      Select distinct pu_id From prod_events where event_type = 2     
  End
--*****************************************************/
declare @curPU_Id int
if (@FilterNonProductiveTime = 1)
 	 begin
 	  	 Declare PRODUCTIVETIME_CURSOR INSENSITIVE CURSOR
   	  	 For (
      	  	 Select Item From @Units
       	  	 )
  	  	  For Read Only
   	  	 Open PRODUCTIVETIME_CURSOR
 	  	 BEGIN_PRODUCTIVETIME_CURSOR1:
 	  	 Fetch Next From PRODUCTIVETIME_CURSOR Into @curPU_Id
 	  	 While @@Fetch_Status = 0
 	  	 Begin    
 	  	  	 insert into #ProductiveTimes (StartTime, EndTime) execute spDBR_GetProductiveTimes @curPU_Id, @StartTime, @EndTime
 	  	  	 update #ProductiveTimes set PU_Id = @curPU_Id where PU_Id is null
      	  	  	 GOTO BEGIN_PRODUCTIVETIME_CURSOR1
 	  	 End
 	  	 Close PRODUCTIVETIME_CURSOR
 	  	 Deallocate PRODUCTIVETIME_CURSOR
 	  	 Insert Into @ProductiveTimes(PU_ID, StartTime, EndTime)
 	  	 Select PU_ID, StartTime, EndTime From #ProductiveTimes
 	 end
else
 	 begin
 	  	 Insert Into @ProductiveTimes(PU_ID, StartTime, EndTime)
 	  	  	 Select Item, @StartTime, @EndTime From @Units
 	 end
-- Local Crew_Schedule table for faster access
Declare @Crew_Schedule Table(
 	 Start_Time datetime,
 	 End_Time datetime,
 	 PU_ID int,
 	 Crew_desc varchar(10),
 	 Shift_Desc varchar(10)
)
Insert Into @Crew_Schedule(Start_Time, End_Time, PU_ID, Crew_Desc, Shift_Desc)
 	 Select Start_Time, End_Time, PU_ID, Crew_Desc, Shift_Desc
 	 From Crew_Schedule cs
 	 Join @Units u on cs.PU_ID = u.Item
    Where cs.Start_Time <= @EndTime
    and cs.End_Time >= @StartTime
Declare @OperatingTime Table(
 	 ProductId int,
 	 TotalTime int 
) 
--Prepare Details Table
Declare @Details Table (
 	 Timestamp  	  	  	  	 datetime,
 	 ItemId 	  	  	  	  	 int NULL,
 	 ProductId 	  	  	  	 int NULL,
 	 Duration  	  	  	  	 real NULL,
 	 TimeToRepair  	  	  	 real NULL,
 	 TimePreviousFailure 	  	 real NULL,
 	 FaultId  	  	  	  	 int NULL,
 	 Crew 	  	  	  	  	 varchar(10) NULL
) 
Declare @ProductChanges Table (
 	 ProductId 	 int,
 	 StartTime 	 datetime,
 	 EndTime 	  	 datetime
) 
declare @curStartTime datetime, @curEndTime datetime
Declare Unit_Cursor Insensitive Cursor 
  For Select Item From @Units 
  For Read Only
Open Unit_Cursor
Fetch Next From Unit_Cursor Into @@UnitId
While @@Fetch_Status = 0
  Begin
    --Get Reason Level Header Names
    If @Level1Name Is Null
      Begin
     	  	 Select @TreeId = Name_Id From Prod_Events Where PU_Id = @@UnitId and Event_Type = 2
     	  	 Select @Level1Name = level_name From event_reason_level_headers Where Tree_Name_id = @TreeId and Reason_Level = 1
 	  	 
      	  	 If @Level1Name Is Not Null 
 	  	  	  	 Select @Level2Name = level_name From event_reason_level_headers Where Tree_Name_id = @TreeId and Reason_Level = 2
 	  	 
 	  	     If @Level2Name Is Not Null 
 	  	  	     Select @Level3Name = level_name From event_reason_level_headers Where Tree_Name_id = @TreeId and Reason_Level = 3
 	  	 
 	  	     If @Level3Name Is Not Null 
 	  	  	     Select @Level4Name = level_name From event_reason_level_headers Where Tree_Name_id = @TreeId and Reason_Level = 4
      End
 	 --*****************************************************
 	 -- DOWNTIME EVENTS
 	 --*****************************************************
 	 Declare TIME_CURSOR INSENSITIVE CURSOR
 	   For (
 	  	  Select StartTime, EndTime From @ProductiveTimes where PU_Id = @@UnitId
 	  	   )
 	   For Read Only
 	   Open TIME_CURSOR  
 	 BEGIN_TIME_CURSOR:
 	 Fetch Next From TIME_CURSOR Into @curStartTime, @curEndTime
 	 While @@Fetch_Status = 0
 	  	 Begin    
 	  	  	 If @FaultFilter Is Not Null
 	  	  	  	 Begin
 	  	  	  	  	 Select @FaultId = NULL
 	  	  	  	  	 Select @FaultId = TEFault_Id From Timed_Event_Fault Where PU_Id = @@UnitId and TEFault_Name = @FaultFilter
 	  	  	  	 End
 	  	  	 If @ReportLevel = 0  --Location
 	  	  	  	 begin
 	  	  	  	  	 Insert Into @Details(Timestamp, ItemId, Duration, TimeToRepair, TimePreviousFailure, FaultId) 
 	  	  	  	  	  	 Select d.Start_Time, d.Source_PU_ID, 
 	  	  	  	  	  	  	 DateDiff(second, Case When d.Start_Time < @curStartTime Then @curStartTime ELSE d.Start_Time END, Case When d.End_Time > @curEndTime Then @curEndTime ELSE ISNULL(d.End_Time, @curEndTime) END) / 60.0,
 	  	  	  	  	  	  	 DateDiff(second, d.Start_Time, IsNull(d.End_Time, dbo.fnServer_CmnGetDate(getutcdate()))) / 60.0,
 	  	  	  	  	  	  	 Case When d.Start_Time < @curStartTime Then NULL
 	  	  	  	  	  	  	  	 When d.Uptime <= 0 Then NULL ELSE d.Uptime End,
 	  	  	  	  	  	  	 d.TEFault_Id
 	  	  	  	  	  	 From Timed_Event_Details d 
 	  	  	  	  	  	 Where d.PU_ID =  @@UnitID
 	  	  	  	  	  	 AND d.Start_Time >= @curStartTime 
 	  	  	  	  	  	 AND d.Start_Time < @curEndTime
 	  	  	  	  	  	 AND (@LocationFilter IS NULL or d.Source_PU_Id  = @LocationFilter)
 	  	  	  	  	  	 AND (@ReasonFilter1 IS NULL or d.Reason_Level1 = @ReasonFilter1)
 	  	  	  	  	  	 AND (@ReasonFilter2 IS NULL or d.Reason_Level2 = @ReasonFilter2)
 	  	  	  	  	  	 AND (@ReasonFilter3 IS NULL or d.Reason_Level3 = @ReasonFilter3)
 	  	  	  	  	  	 AND (@ReasonFilter4 IS NULL or d.Reason_Level4 = @ReasonFilter4)
 	  	  	  	  	  	 AND (@FaultId IS NULL or d.TEFault_Id = @FaultId)
 	  	  	  	  	  	 
 	  	  	  	  	 Insert Into @Details(Timestamp, ItemId, Duration, TimeToRepair, TimePreviousFailure, FaultId) 
 	  	  	  	  	  	 Select d.Start_Time, d.Source_PU_ID, 
 	  	  	  	  	  	  	 DateDiff(second, Case When d.Start_Time < @curStartTime Then @curStartTime ELSE d.Start_Time END, Case When d.End_Time > @curEndTime Then @curEndTime ELSE ISNULL(d.End_Time, @curEndTime) END) / 60.0,
 	  	  	  	  	  	  	 DateDiff(second, d.Start_Time, IsNull(d.End_Time, dbo.fnServer_CmnGetDate(getutcdate()))) / 60.0,
 	  	  	  	  	  	  	 Case When d.Start_Time < @curStartTime Then NULL
 	  	  	  	  	  	  	  	 When d.Uptime <= 0 Then NULL ELSE d.Uptime End,
 	  	  	  	  	  	  	 d.TEFault_Id
 	  	  	  	  	  	 From Timed_Event_Details d 
 	  	  	  	  	  	 Where d.PU_ID = @@UnitID
 	  	  	  	  	  	 
 	  	  	  	  	  	 AND d.Start_time = (Select Max(t.Start_Time) from Timed_Event_Details t where t.pu_Id = @@UnitID AND t.Start_Time < @curStartTime)
 	  	  	  	  	  	 AND ((d.End_Time > @curStartTime) or (d.End_Time IS NULL))
 	  	  	  	  	  	 AND (@LocationFilter IS NULL or d.Source_PU_Id  = @LocationFilter)
 	  	  	  	  	  	 AND (@ReasonFilter1 IS NULL or d.Reason_Level1 = @ReasonFilter1)
 	  	  	  	  	  	 AND (@ReasonFilter2 IS NULL or d.Reason_Level2 = @ReasonFilter2)
 	  	  	  	  	  	 AND (@ReasonFilter3 IS NULL or d.Reason_Level3 = @ReasonFilter3)
 	  	  	  	  	  	 AND (@ReasonFilter4 IS NULL or d.Reason_Level4 = @ReasonFilter4)
 	  	  	  	  	  	 AND (@FaultId IS NULL or d.TEFault_Id = @FaultId)
 	  	  	  	 end
 	  	  	 Else If @ReportLevel = 1
 	  	  	  	 begin
 	  	  	  	  	 Insert Into @Details(Timestamp, ItemId, Duration, TimeToRepair, TimePreviousFailure, FaultId) 
 	  	  	  	  	  	 Select d.Start_Time, d.Reason_Level1, 
 	  	  	  	  	  	  	 DateDiff(second, Case When d.Start_Time < @curStartTime Then @curStartTime ELSE d.Start_Time END, Case When d.End_Time > @curEndTime Then @curEndTime ELSE ISNULL(d.End_Time, @curEndTime) END) / 60.0,
 	  	  	  	  	  	  	 DateDiff(second, d.Start_Time, IsNull(d.End_Time, dbo.fnServer_CmnGetDate(getutcdate()))) / 60.0,
 	  	  	  	  	  	  	 Case When d.Start_Time < @curStartTime Then NULL
 	  	  	  	  	  	  	  	 When d.Uptime <= 0 Then NULL ELSE d.Uptime End,
 	  	  	  	  	  	  	 d.TEFault_Id
 	  	  	  	  	  	 From Timed_Event_Details d 
 	  	  	  	  	  	 Where d.PU_ID = @@UnitID
 	  	  	  	  	  	 AND d.Start_Time >= @curStartTime 
 	  	  	  	  	  	 AND d.Start_Time < @curEndTime
 	  	  	  	  	  	 AND (@LocationFilter IS NULL or d.Source_PU_Id  = @LocationFilter)
 	  	  	  	  	  	 AND (@ReasonFilter1 IS NULL or d.Reason_Level1 = @ReasonFilter1)
 	  	  	  	  	  	 AND (@ReasonFilter2 IS NULL or d.Reason_Level2 = @ReasonFilter2)
 	  	  	  	  	  	 AND (@ReasonFilter3 IS NULL or d.Reason_Level3 = @ReasonFilter3)
 	  	  	  	  	  	 AND (@ReasonFilter4 IS NULL or d.Reason_Level4 = @ReasonFilter4)
 	  	  	  	  	  	 AND (@FaultId IS NULL or d.TEFault_Id = @FaultId)
 	  	  	  	  	  	 
 	  	  	  	  	 Insert Into @Details(Timestamp, ItemId, Duration, TimeToRepair, TimePreviousFailure, FaultId) 
 	  	  	  	  	  	 Select d.Start_Time, d.Reason_Level1, 
 	  	  	  	  	  	  	 DateDiff(second, Case When d.Start_Time < @curStartTime Then @curStartTime ELSE d.Start_Time END, Case When d.End_Time > @curEndTime Then @curEndTime ELSE ISNULL(d.End_Time, @curEndTime) END) / 60.0,
 	  	  	  	  	  	  	 DateDiff(second, d.Start_Time, IsNull(d.End_Time, dbo.fnServer_CmnGetDate(getutcdate()))) / 60.0,
 	  	  	  	  	  	  	 Case When d.Start_Time < @curStartTime Then NULL
 	  	  	  	  	  	  	  	 When d.Uptime <= 0 Then NULL ELSE d.Uptime End,
 	  	  	  	  	  	  	 d.TEFault_Id
 	  	  	  	  	  	 From Timed_Event_Details d 
 	  	  	  	  	  	 Where d.PU_ID = @@UnitID
 	  	  	  	  	  	 
 	  	  	  	  	  	 AND d.Start_time = (Select Max(t.Start_Time) from Timed_Event_Details t where t.pu_Id = @@UnitID AND t.Start_Time < @curStartTime)
 	  	  	  	  	  	 AND ((d.End_Time > @curStartTime) or (d.End_Time IS NULL))
 	  	  	  	  	  	 AND (@LocationFilter IS NULL or d.Source_PU_Id  = @LocationFilter)
 	  	  	  	  	  	 AND (@ReasonFilter1 IS NULL or d.Reason_Level1 = @ReasonFilter1)
 	  	  	  	  	  	 AND (@ReasonFilter2 IS NULL or d.Reason_Level2 = @ReasonFilter2)
 	  	  	  	  	  	 AND (@ReasonFilter3 IS NULL or d.Reason_Level3 = @ReasonFilter3)
 	  	  	  	  	  	 AND (@ReasonFilter4 IS NULL or d.Reason_Level4 = @ReasonFilter4)
 	  	  	  	  	  	 AND (@FaultId IS NULL or d.TEFault_Id = @FaultId)
 	  	  	  	 end
 	  	  	 Else If @ReportLevel = 2
 	  	  	  	 begin
 	  	  	  	  	 Insert Into @Details(Timestamp, ItemId, Duration, TimeToRepair, TimePreviousFailure, FaultId) 
 	  	  	  	  	  	 Select d.Start_Time, d.Reason_Level2, 
 	  	  	  	  	  	  	 DateDiff(second, Case When d.Start_Time < @curStartTime Then @curStartTime ELSE d.Start_Time END, Case When d.End_Time > @curEndTime Then @curEndTime ELSE ISNULL(d.End_Time, @curEndTime) END) / 60.0,
 	  	  	  	  	  	  	 DateDiff(second, d.Start_Time, IsNull(d.End_Time, dbo.fnServer_CmnGetDate(getutcdate()))) / 60.0,
 	  	  	  	  	  	  	 Case When d.Start_Time < @curStartTime Then NULL
 	  	  	  	  	  	  	  	 When d.Uptime <= 0 Then NULL ELSE d.Uptime End,
 	  	  	  	  	  	  	 d.TEFault_Id
 	  	  	  	  	  	 From Timed_Event_Details d 
 	  	  	  	  	  	 Where d.PU_ID = @@UnitID
 	  	  	  	  	  	 AND d.Start_Time >= @curStartTime 
 	  	  	  	  	  	 AND d.Start_Time < @curEndTime
 	  	  	  	  	  	 AND (@LocationFilter IS NULL or d.Source_PU_Id  = @LocationFilter)
 	  	  	  	  	  	 AND (@ReasonFilter1 IS NULL or d.Reason_Level1 = @ReasonFilter1)
 	  	  	  	  	  	 AND (@ReasonFilter2 IS NULL or d.Reason_Level2 = @ReasonFilter2)
 	  	  	  	  	  	 AND (@ReasonFilter3 IS NULL or d.Reason_Level3 = @ReasonFilter3)
 	  	  	  	  	  	 AND (@ReasonFilter4 IS NULL or d.Reason_Level4 = @ReasonFilter4)
 	  	  	  	  	  	 AND (@FaultId IS NULL or d.TEFault_Id = @FaultId)
 	  	  	  	  	  	 
 	  	  	  	  	 Insert Into @Details(Timestamp, ItemId, Duration, TimeToRepair, TimePreviousFailure, FaultId) 
 	  	  	  	  	  	 Select d.Start_Time, d.Reason_Level2, 
 	  	  	  	  	  	  	 DateDiff(second, Case When d.Start_Time < @curStartTime Then @curStartTime ELSE d.Start_Time END, Case When d.End_Time > @curEndTime Then @curEndTime ELSE ISNULL(d.End_Time, @curEndTime) END) / 60.0,
 	  	  	  	  	  	  	 DateDiff(second, d.Start_Time, IsNull(d.End_Time, dbo.fnServer_CmnGetDate(getutcdate()))) / 60.0,
 	  	  	  	  	  	  	 Case When d.Start_Time < @curStartTime Then NULL
 	  	  	  	  	  	  	  	 When d.Uptime <= 0 Then NULL ELSE d.Uptime End,
 	  	  	  	  	  	  	 d.TEFault_Id
 	  	  	  	  	  	 From Timed_Event_Details d 
 	  	  	  	  	  	 Where d.PU_ID = @@UnitID
 	  	  	  	  	  	 
 	  	  	  	  	  	 AND d.Start_time = (Select Max(t.Start_Time) from Timed_Event_Details t where t.pu_Id = @@UnitID AND t.Start_Time < @curStartTime)
 	  	  	  	  	  	 AND ((d.End_Time > @curStartTime) or (d.End_Time IS NULL))
 	  	  	  	  	  	 AND (@LocationFilter IS NULL or d.Source_PU_Id  = @LocationFilter)
 	  	  	  	  	  	 AND (@ReasonFilter1 IS NULL or d.Reason_Level1 = @ReasonFilter1)
 	  	  	  	  	  	 AND (@ReasonFilter2 IS NULL or d.Reason_Level2 = @ReasonFilter2)
 	  	  	  	  	  	 AND (@ReasonFilter3 IS NULL or d.Reason_Level3 = @ReasonFilter3)
 	  	  	  	  	  	 AND (@ReasonFilter4 IS NULL or d.Reason_Level4 = @ReasonFilter4)
 	  	  	  	  	  	 AND (@FaultId IS NULL or d.TEFault_Id = @FaultId)
 	  	  	  	 end
 	  	  	 Else If @ReportLevel = 3
 	  	  	  	 begin
 	  	  	  	  	 Insert Into @Details(Timestamp, ItemId, Duration, TimeToRepair, TimePreviousFailure, FaultId) 
 	  	  	  	  	  	 Select d.Start_Time, d.Reason_Level3, 
 	  	  	  	  	  	  	 DateDiff(second, Case When d.Start_Time < @curStartTime Then @curStartTime ELSE d.Start_Time END, Case When d.End_Time > @curEndTime Then @curEndTime ELSE ISNULL(d.End_Time, @curEndTime) END) / 60.0,
 	  	  	  	  	  	  	 DateDiff(second, d.Start_Time, IsNull(d.End_Time, dbo.fnServer_CmnGetDate(getutcdate()))) / 60.0,
 	  	  	  	  	  	  	 Case When d.Start_Time < @curStartTime Then NULL
 	  	  	  	  	  	  	  	 When d.Uptime <= 0 Then NULL ELSE d.Uptime End,
 	  	  	  	  	  	  	 d.TEFault_Id
 	  	  	  	  	  	 From Timed_Event_Details d 
 	  	  	  	  	  	 Where d.PU_ID = @@UnitID
 	  	  	  	  	  	 AND d.Start_Time >= @curStartTime 
 	  	  	  	  	  	 AND d.Start_Time < @curEndTime
 	  	  	  	  	  	 AND (@LocationFilter IS NULL or d.Source_PU_Id  = @LocationFilter)
 	  	  	  	  	  	 AND (@ReasonFilter1 IS NULL or d.Reason_Level1 = @ReasonFilter1)
 	  	  	  	  	  	 AND (@ReasonFilter2 IS NULL or d.Reason_Level2 = @ReasonFilter2)
 	  	  	  	  	  	 AND (@ReasonFilter3 IS NULL or d.Reason_Level3 = @ReasonFilter3)
 	  	  	  	  	  	 AND (@ReasonFilter4 IS NULL or d.Reason_Level4 = @ReasonFilter4)
 	  	  	  	  	  	 AND (@FaultId IS NULL or d.TEFault_Id = @FaultId)
 	  	  	  	  	  	 
 	  	  	  	  	 Insert Into @Details(Timestamp, ItemId, Duration, TimeToRepair, TimePreviousFailure, FaultId) 
 	  	  	  	  	  	 Select d.Start_Time, d.Reason_Level3, 
 	  	  	  	  	  	  	 DateDiff(second, Case When d.Start_Time < @curStartTime Then @curStartTime ELSE d.Start_Time END, Case When d.End_Time > @curEndTime Then @curEndTime ELSE ISNULL(d.End_Time, @curEndTime) END) / 60.0,
 	  	  	  	  	  	  	 DateDiff(second, d.Start_Time, IsNull(d.End_Time, dbo.fnServer_CmnGetDate(getutcdate()))) / 60.0,
 	  	  	  	  	  	  	 Case When d.Start_Time < @curStartTime Then NULL
 	  	  	  	  	  	  	  	 When d.Uptime <= 0 Then NULL ELSE d.Uptime End,
 	  	  	  	  	  	  	 d.TEFault_Id
 	  	  	  	  	  	 From Timed_Event_Details d 
 	  	  	  	  	  	 Where d.PU_ID = @@UnitID
 	  	  	  	  	  	 
 	  	  	  	  	  	 AND d.Start_time = (Select Max(t.Start_Time) from Timed_Event_Details t where t.pu_Id = @@UnitID AND t.Start_Time < @curStartTime)
 	  	  	  	  	  	 AND ((d.End_Time > @curStartTime) or (d.End_Time IS NULL))
 	  	  	  	  	  	 AND (@LocationFilter IS NULL or d.Source_PU_Id  = @LocationFilter)
 	  	  	  	  	  	 AND (@ReasonFilter1 IS NULL or d.Reason_Level1 = @ReasonFilter1)
 	  	  	  	  	  	 AND (@ReasonFilter2 IS NULL or d.Reason_Level2 = @ReasonFilter2)
 	  	  	  	  	  	 AND (@ReasonFilter3 IS NULL or d.Reason_Level3 = @ReasonFilter3)
 	  	  	  	  	  	 AND (@ReasonFilter4 IS NULL or d.Reason_Level4 = @ReasonFilter4)
 	  	  	  	  	  	 AND (@FaultId IS NULL or d.TEFault_Id = @FaultId)
 	  	  	  	 end
 	  	  	 Else If @ReportLevel = 4
 	  	  	  	 begin
 	  	  	  	  	 Insert Into @Details(Timestamp, ItemId, Duration, TimeToRepair, TimePreviousFailure, FaultId) 
 	  	  	  	  	  	 Select d.Start_Time, d.Reason_Level4, 
 	  	  	  	  	  	  	 DateDiff(second, Case When d.Start_Time < @curStartTime Then @curStartTime ELSE d.Start_Time END, Case When d.End_Time > @curEndTime Then @curEndTime ELSE ISNULL(d.End_Time, @curEndTime) END) / 60.0,
 	  	  	  	  	  	  	 DateDiff(second, d.Start_Time, IsNull(d.End_Time, dbo.fnServer_CmnGetDate(getutcdate()))) / 60.0,
 	  	  	  	  	  	  	 Case When d.Start_Time < @curStartTime Then NULL
 	  	  	  	  	  	  	  	 When d.Uptime <= 0 Then NULL ELSE d.Uptime End,
 	  	  	  	  	  	  	 d.TEFault_Id
 	  	  	  	  	  	 From Timed_Event_Details d 
 	  	  	  	  	  	 Where d.PU_ID = @@UnitID
 	  	  	  	  	  	 AND d.Start_Time >= @curStartTime 
 	  	  	  	  	  	 AND d.Start_Time < @curEndTime
 	  	  	  	  	  	 AND (@LocationFilter IS NULL or d.Source_PU_Id  = @LocationFilter)
 	  	  	  	  	  	 AND (@ReasonFilter1 IS NULL or d.Reason_Level1 = @ReasonFilter1)
 	  	  	  	  	  	 AND (@ReasonFilter2 IS NULL or d.Reason_Level2 = @ReasonFilter2)
 	  	  	  	  	  	 AND (@ReasonFilter3 IS NULL or d.Reason_Level3 = @ReasonFilter3)
 	  	  	  	  	  	 AND (@ReasonFilter4 IS NULL or d.Reason_Level4 = @ReasonFilter4)
 	  	  	  	  	  	 AND (@FaultId IS NULL or d.TEFault_Id = @FaultId)
 	  	  	  	  	  	 
 	  	  	  	  	 Insert Into @Details(Timestamp, ItemId, Duration, TimeToRepair, TimePreviousFailure, FaultId) 
 	  	  	  	  	  	 Select d.Start_Time, d.Reason_Level4, 
 	  	  	  	  	  	  	 DateDiff(second, Case When d.Start_Time < @curStartTime Then @curStartTime ELSE d.Start_Time END, Case When d.End_Time > @curEndTime Then @curEndTime ELSE ISNULL(d.End_Time, @curEndTime) END) / 60.0,
 	  	  	  	  	  	  	 DateDiff(second, d.Start_Time, IsNull(d.End_Time, dbo.fnServer_CmnGetDate(getutcdate()))) / 60.0,
 	  	  	  	  	  	  	 Case When d.Start_Time < @curStartTime Then NULL
 	  	  	  	  	  	  	  	 When d.Uptime <= 0 Then NULL ELSE d.Uptime End,
 	  	  	  	  	  	  	 d.TEFault_Id
 	  	  	  	  	  	 From Timed_Event_Details d 
 	  	  	  	  	  	 Where d.PU_ID = @@UnitID
 	  	  	  	  	  	 
 	  	  	  	  	  	 AND d.Start_time = (Select Max(t.Start_Time) from Timed_Event_Details t where t.pu_Id = @@UnitID AND t.Start_Time < @curStartTime)
 	  	  	  	  	  	 AND ((d.End_Time > @curStartTime) or (d.End_Time IS NULL))
 	  	  	  	  	  	 AND (@LocationFilter IS NULL or d.Source_PU_Id  = @LocationFilter)
 	  	  	  	  	  	 AND (@ReasonFilter1 IS NULL or d.Reason_Level1 = @ReasonFilter1)
 	  	  	  	  	  	 AND (@ReasonFilter2 IS NULL or d.Reason_Level2 = @ReasonFilter2)
 	  	  	  	  	  	 AND (@ReasonFilter3 IS NULL or d.Reason_Level3 = @ReasonFilter3)
 	  	  	  	  	  	 AND (@ReasonFilter4 IS NULL or d.Reason_Level4 = @ReasonFilter4)
 	  	  	  	  	  	 AND (@FaultId IS NULL or d.TEFault_Id = @FaultId)
 	  	  	  	 end
 	  	  	 Else If @ReportLevel = 5  -- Fault
 	  	  	  	 begin
 	  	  	  	  	 Insert Into @Details(Timestamp, ItemId, Duration, TimeToRepair, TimePreviousFailure, FaultId) 
 	  	  	  	  	  	 Select d.Start_Time, d.Source_PU_Id, 
 	  	  	  	  	  	  	 DateDiff(second, Case When d.Start_Time < @curStartTime Then @curStartTime ELSE d.Start_Time END, Case When d.End_Time > @curEndTime Then @curEndTime ELSE ISNULL(d.End_Time, @curEndTime) END) / 60.0,
 	  	  	  	  	  	  	 DateDiff(second, d.Start_Time, IsNull(d.End_Time, dbo.fnServer_CmnGetDate(getutcdate()))) / 60.0,
 	  	  	  	  	  	  	 Case When d.Start_Time < @curStartTime Then NULL
 	  	  	  	  	  	  	  	 When d.Uptime <= 0 Then NULL ELSE d.Uptime End,
 	  	  	  	  	  	  	 d.TEFault_Id
 	  	  	  	  	  	 From Timed_Event_Details d 
 	  	  	  	  	  	 Where d.PU_ID = @@UnitID
 	  	  	  	  	  	 AND d.Start_Time >= @curStartTime 
 	  	  	  	  	  	 AND d.Start_Time < @curEndTime
 	  	  	  	  	  	 AND (@LocationFilter IS NULL or d.Source_PU_Id  = @LocationFilter)
 	  	  	  	  	  	 AND (@ReasonFilter1 IS NULL or d.Reason_Level1 = @ReasonFilter1)
 	  	  	  	  	  	 AND (@ReasonFilter2 IS NULL or d.Reason_Level2 = @ReasonFilter2)
 	  	  	  	  	  	 AND (@ReasonFilter3 IS NULL or d.Reason_Level3 = @ReasonFilter3)
 	  	  	  	  	  	 AND (@ReasonFilter4 IS NULL or d.Reason_Level4 = @ReasonFilter4)
 	  	  	  	  	  	 AND (@FaultId IS NULL or d.TEFault_Id = @FaultId)
 	  	  	  	  	  	 
 	  	  	  	  	 Insert Into @Details(Timestamp, ItemId, Duration, TimeToRepair, TimePreviousFailure, FaultId) 
 	  	  	  	  	  	 Select d.Start_Time, d.Source_PU_Id, 
 	  	  	  	  	  	  	 DateDiff(second, Case When d.Start_Time < @curStartTime Then @curStartTime ELSE d.Start_Time END, Case When d.End_Time > @curEndTime Then @curEndTime ELSE ISNULL(d.End_Time, @curEndTime) END) / 60.0,
 	  	  	  	  	  	  	 DateDiff(second, d.Start_Time, IsNull(d.End_Time, dbo.fnServer_CmnGetDate(getutcdate()))) / 60.0,
 	  	  	  	  	  	  	 Case When d.Start_Time < @curStartTime Then NULL
 	  	  	  	  	  	  	  	 When d.Uptime <= 0 Then NULL ELSE d.Uptime End,
 	  	  	  	  	  	  	 d.TEFault_Id
 	  	  	  	  	  	 From Timed_Event_Details d 
 	  	  	  	  	  	 Where d.PU_ID = @@UnitID
 	  	  	  	  	  	 
 	  	  	  	  	  	 AND d.Start_time = (Select Max(t.Start_Time) from Timed_Event_Details t where t.pu_Id = @@UnitID AND t.Start_Time < @curStartTime)
 	  	  	  	  	  	 AND ((d.End_Time > @curStartTime) or (d.End_Time IS NULL))
 	  	  	  	  	  	 AND (@LocationFilter IS NULL or d.Source_PU_Id  = @LocationFilter)
 	  	  	  	  	  	 AND (@ReasonFilter1 IS NULL or d.Reason_Level1 = @ReasonFilter1)
 	  	  	  	  	  	 AND (@ReasonFilter2 IS NULL or d.Reason_Level2 = @ReasonFilter2)
 	  	  	  	  	  	 AND (@ReasonFilter3 IS NULL or d.Reason_Level3 = @ReasonFilter3)
 	  	  	  	  	  	 AND (@ReasonFilter4 IS NULL or d.Reason_Level4 = @ReasonFilter4)
 	  	  	  	  	  	 AND (@FaultId IS NULL or d.TEFault_Id = @FaultId)
 	  	  	  	 end
 	  	  	 Else If @ReportLevel = 6  -- Crew
 	  	  	  	 begin
 	  	  	  	  	 Insert Into @Details(Timestamp, ItemId, Duration, TimeToRepair, TimePreviousFailure, FaultId) 
 	  	  	  	  	  	 Select d.Start_Time, d.Source_PU_Id, 
 	  	  	  	  	  	  	 DateDiff(second, Case When d.Start_Time < @curStartTime Then @curStartTime ELSE d.Start_Time END, Case When d.End_Time > @curEndTime Then @curEndTime ELSE ISNULL(d.End_Time, @curEndTime) END) / 60.0,
 	  	  	  	  	  	  	 DateDiff(second, d.Start_Time, IsNull(d.End_Time, dbo.fnServer_CmnGetDate(getutcdate()))) / 60.0,
 	  	  	  	  	  	  	 Case When d.Start_Time < @curStartTime Then NULL
 	  	  	  	  	  	  	  	 When d.Uptime <= 0 Then NULL ELSE d.Uptime End,
 	  	  	  	  	  	  	 d.TEFault_Id
 	  	  	  	  	  	 From Timed_Event_Details d 
 	  	  	  	  	  	 Where d.PU_ID = @@UnitID
 	  	  	  	  	  	 AND d.Start_Time >= @curStartTime 
 	  	  	  	  	  	 AND d.Start_Time < @curEndTime
 	  	  	  	  	  	 AND (@LocationFilter IS NULL or d.Source_PU_Id  = @LocationFilter)
 	  	  	  	  	  	 AND (@ReasonFilter1 IS NULL or d.Reason_Level1 = @ReasonFilter1)
 	  	  	  	  	  	 AND (@ReasonFilter2 IS NULL or d.Reason_Level2 = @ReasonFilter2)
 	  	  	  	  	  	 AND (@ReasonFilter3 IS NULL or d.Reason_Level3 = @ReasonFilter3)
 	  	  	  	  	  	 AND (@ReasonFilter4 IS NULL or d.Reason_Level4 = @ReasonFilter4)
 	  	  	  	  	  	 AND (@FaultId IS NULL or d.TEFault_Id = @FaultId)
 	  	  	  	  	  	 
 	  	  	  	  	 Insert Into @Details(Timestamp, ItemId, Duration, TimeToRepair, TimePreviousFailure, FaultId) 
 	  	  	  	  	  	 Select d.Start_Time, d.Source_PU_Id, 
 	  	  	  	  	  	  	 DateDiff(second, Case When d.Start_Time < @curStartTime Then @curStartTime ELSE d.Start_Time END, Case When d.End_Time > @curEndTime Then @curEndTime ELSE ISNULL(d.End_Time, @curEndTime) END) / 60.0,
 	  	  	  	  	  	  	 DateDiff(second, d.Start_Time, IsNull(d.End_Time, dbo.fnServer_CmnGetDate(getutcdate()))) / 60.0,
 	  	  	  	  	  	  	 Case When d.Start_Time < @curStartTime Then NULL
 	  	  	  	  	  	  	  	 When d.Uptime <= 0 Then NULL ELSE d.Uptime End,
 	  	  	  	  	  	  	 d.TEFault_Id
 	  	  	  	  	  	 From Timed_Event_Details d 
 	  	  	  	  	  	 Where d.PU_ID = @@UnitID
 	  	  	  	  	  	 
 	  	  	  	  	  	 AND d.Start_time = (Select Max(t.Start_Time) from Timed_Event_Details t where t.pu_Id = @@UnitID AND t.Start_Time < @curStartTime)
 	  	  	  	  	  	 AND ((d.End_Time > @curStartTime) or (d.End_Time IS NULL))
 	  	  	  	  	  	 AND (@LocationFilter IS NULL or d.Source_PU_Id  = @LocationFilter)
 	  	  	  	  	  	 AND (@ReasonFilter1 IS NULL or d.Reason_Level1 = @ReasonFilter1)
 	  	  	  	  	  	 AND (@ReasonFilter2 IS NULL or d.Reason_Level2 = @ReasonFilter2)
 	  	  	  	  	  	 AND (@ReasonFilter3 IS NULL or d.Reason_Level3 = @ReasonFilter3)
 	  	  	  	  	  	 AND (@ReasonFilter4 IS NULL or d.Reason_Level4 = @ReasonFilter4)
 	  	  	  	  	  	 AND (@FaultId IS NULL or d.TEFault_Id = @FaultId)
 	  	  	  	 end
 	  	  	 Else If @ReportLevel = 7  -- Product
 	  	  	  	 begin
 	  	  	  	  	 Insert Into @Details(Timestamp, ItemId, Duration, TimeToRepair, TimePreviousFailure, FaultId) 
 	  	  	  	  	  	 Select d.Start_Time, d.Source_PU_Id, 
 	  	  	  	  	  	  	 DateDiff(second, Case When d.Start_Time < @curStartTime Then @curStartTime ELSE d.Start_Time END, Case When d.End_Time > @curEndTime Then @curEndTime ELSE ISNULL(d.End_Time, @curEndTime) END) / 60.0,
 	  	  	  	  	  	  	 DateDiff(second, d.Start_Time, IsNull(d.End_Time, dbo.fnServer_CmnGetDate(getutcdate()))) / 60.0,
 	  	  	  	  	  	  	 Case When d.Start_Time < @curStartTime Then NULL
 	  	  	  	  	  	  	  	 When d.Uptime <= 0 Then NULL ELSE d.Uptime End,
 	  	  	  	  	  	  	 d.TEFault_Id
 	  	  	  	  	  	 From Timed_Event_Details d 
 	  	  	  	  	  	 Where d.PU_ID = @@UnitID
 	  	  	  	  	  	 AND d.Start_Time >= @curStartTime 
 	  	  	  	  	  	 AND d.Start_Time < @curEndTime
 	  	  	  	  	  	 AND (@LocationFilter IS NULL or d.Source_PU_Id  = @LocationFilter)
 	  	  	  	  	  	 AND (@ReasonFilter1 IS NULL or d.Reason_Level1 = @ReasonFilter1)
 	  	  	  	  	  	 AND (@ReasonFilter2 IS NULL or d.Reason_Level2 = @ReasonFilter2)
 	  	  	  	  	  	 AND (@ReasonFilter3 IS NULL or d.Reason_Level3 = @ReasonFilter3)
 	  	  	  	  	  	 AND (@ReasonFilter4 IS NULL or d.Reason_Level4 = @ReasonFilter4)
 	  	  	  	  	  	 AND (@FaultId IS NULL or d.TEFault_Id = @FaultId)
 	  	  	  	  	  	 
 	  	  	  	  	 Insert Into @Details(Timestamp, ItemId, Duration, TimeToRepair, TimePreviousFailure, FaultId) 
 	  	  	  	  	  	 Select d.Start_Time, d.Source_PU_Id, 
 	  	  	  	  	  	  	 DateDiff(second, Case When d.Start_Time < @curStartTime Then @curStartTime ELSE d.Start_Time END, Case When d.End_Time > @curEndTime Then @curEndTime ELSE ISNULL(d.End_Time, @curEndTime) END) / 60.0,
 	  	  	  	  	  	  	 DateDiff(second, d.Start_Time, IsNull(d.End_Time, dbo.fnServer_CmnGetDate(getutcdate()))) / 60.0,
 	  	  	  	  	  	  	 Case When d.Start_Time < @curStartTime Then NULL
 	  	  	  	  	  	  	  	 When d.Uptime <= 0 Then NULL ELSE d.Uptime End,
 	  	  	  	  	  	  	 d.TEFault_Id
 	  	  	  	  	  	 From Timed_Event_Details d 
 	  	  	  	  	  	 Where d.PU_ID = @@UnitID
 	  	  	  	  	  	 
 	  	  	  	  	  	 AND d.Start_time = (Select Max(t.Start_Time) from Timed_Event_Details t where t.pu_Id = @@UnitID AND t.Start_Time < @curStartTime)
 	  	  	  	  	  	 AND ((d.End_Time > @curStartTime) or (d.End_Time IS NULL))
 	  	  	  	  	  	 AND (@LocationFilter IS NULL or d.Source_PU_Id  = @LocationFilter)
 	  	  	  	  	  	 AND (@ReasonFilter1 IS NULL or d.Reason_Level1 = @ReasonFilter1)
 	  	  	  	  	  	 AND (@ReasonFilter2 IS NULL or d.Reason_Level2 = @ReasonFilter2)
 	  	  	  	  	  	 AND (@ReasonFilter3 IS NULL or d.Reason_Level3 = @ReasonFilter3)
 	  	  	  	  	  	 AND (@ReasonFilter4 IS NULL or d.Reason_Level4 = @ReasonFilter4)
 	  	  	  	  	  	 AND (@FaultId IS NULL or d.TEFault_Id = @FaultId)
 	  	  	  	 end
 	  	  	 -- Join In Product Information  
 	  	  	 Update D
 	  	  	  	 Set D.ProductId = PS.Prod_Id
 	  	  	  	 From Production_Starts PS
 	  	  	  	 Join @Details D on
 	  	  	  	  	 PS.Start_Time <= D.Timestamp
 	  	  	  	  	 and ((PS.End_Time > D.Timestamp) or (PS.End_Time Is Null) )
 	  	  	  	 Where PS.PU_ID = @@UnitId
 	  	  	 Insert Into @ProductChanges (ProductId, StartTime, EndTime)
 	  	  	   Select Prod_Id, 
 	  	  	  	  	  Case When Start_Time < @curStartTime Then @curStartTime Else Start_Time End,
 	  	  	  	  	  Case When coalesce(End_Time, dbo.fnServer_CmnGetDate(getutcdate())) > @curEndTime Then @curEndTime Else coalesce(End_Time, dbo.fnServer_CmnGetDate(getutcdate())) End
 	  	  	  	 From Production_Starts d
    	  	  	  	   Where d.PU_id = @@UnitId and
 	  	   	  	  	  	  	   d.Start_Time = (Select Max(t.Start_Time) From Production_Starts t Where t.PU_Id = @@UnitId and t.start_time < @curStartTime) and
 	  	   	  	  	  	   ((d.End_Time > @curStartTime) or (d.End_Time is Null))
 	  	  	    Union
 	  	  	  	 Select Prod_Id, 
 	  	  	  	  	  Case When Start_Time < @curStartTime Then @curStartTime Else Start_Time End,
 	  	  	  	  	  Case When coalesce(End_Time, dbo.fnServer_CmnGetDate(getutcdate())) > @curEndTime Then @curEndTime Else coalesce(End_Time, dbo.fnServer_CmnGetDate(getutcdate())) End
 	  	  	  	 From Production_Starts d
 	  	  	  	  	 Where d.PU_id = @@UnitId and
 	  	  	  	  	  	   d.Start_Time >= @curStartTime and 
 	  	          	  	  	 d.Start_Time < @curEndTime 
 	  	  	 If @ProductFilter Is Not Null
 	  	  	   Begin                    	  	  	  	  	 
 	  	  	  	 Delete From @ProductChanges Where ProductId <> @ProductFilter
 	  	  	  	 Delete From @Details Where ProductId <> @ProductFilter
 	  	  	   End
 	  	     -- Update Operating Time From Trimmed Production Starts
  	  	  	 Select @TotalOperatingTime = @TotalOperatingTime + coalesce((Select sum(datediff(second, StartTime, EndTime))From @ProductChanges),0)
    	  	  	 Insert Into @OperatingTime (ProductId, TotalTime)
 	  	  	   Select ProductId, sum(datediff(second, StartTime, EndTime))
 	  	  	  	 From @ProductChanges
 	  	  	  	 Group By ProductId
 	  	  	 delete from @ProductChanges       
 	  	  	 --Update Crew
 	  	  	 Update D
 	  	  	  	 Set D.Crew = C.Crew_Desc
 	  	  	  	 From @Crew_Schedule C
 	  	  	  	 Join @Details D on
 	  	  	  	  	 C.Start_Time <= D.Timestamp
 	  	  	  	  	 and C.End_Time > D.Timestamp
 	  	  	  	 Where C.PU_ID = @@UnitId
 	  	  	 If @CrewFilter Is Not Null
 	  	  	   Delete From @Details Where Crew <> @CrewFilter 
 	  	  	 Select @TotalDownTime = @TotalDownTime + coalesce((Select sum(Duration) From @Details),0)
 	  	  	   
 	  	  	 -- Add Rows To Summary Resultset
 	  	  	 Insert Into  @Summary (Timestamp,ProductId,ItemId, Duration, TimeToRepair, TimePreviousFailure, Crew, Fault) 
 	  	  	   Select Timestamp,ProductId,ItemId,Duration, TimeToRepair, TimePreviousFailure, Crew, case when tef.TEFault_Id Is Null then + dbo.fnDBTranslate(N'0', 38333, 'Unspecified') Else tef.TEFault_Name End 
 	  	  	  	 From @Details D
 	  	  	  	 Left Outer Join Timed_Event_Fault tef on tef.TEFault_Id = D.FaultId 
 	  	   delete from @Details  
 	      GOTO BEGIN_TIME_CURSOR
 	 End
 	 Close TIME_CURSOR
 	 Deallocate TIME_CURSOR
    Fetch Next From Unit_Cursor Into @@UnitId
  End
Close Unit_Cursor
Deallocate Unit_Cursor  
--*********************************************************************************
-- Return Resultset #1 - Resultset Name List
--*********************************************************************************
Declare @Message varchar(100)
Declare @ResultSets Table (
 	 ResultSetName 	  	 varchar(50),
 	 ResultSetTabName 	 varchar(50),
 	 ParameterName 	  	 varchar(50)  NULL,
 	 ParameterUnits 	  	 varchar(50) NULL,
 	 DataColumns 	  	  	 varchar(50) NULL,
 	 LabelColumns 	  	 varchar(50) NULL,
 	 IconDesc 	  	  	 varchar(1000) NULL,
 	 RS_ID 	  	  	  	 int  NULL
)
If @ReportLevel = 0
  Select @Message = dbo.fnDBTranslate(N'0', 38352,'Top') + ' ' + convert(varchar(10),@TopNumber) + ' ' + dbo.fnDBTranslate(N'0', 38347, 'Downtime By Location')
Else If @ReportLevel = 1
  Select @Message = dbo.fnDBTranslate(N'0', 38352,'Top') + ' ' + convert(varchar(10),@TopNumber) + ' ' + dbo.fnDBTranslate(N'0', 38348, 'Downtime By') + ' '    + @Level1Name
Else If @ReportLevel = 2
  Select @Message = dbo.fnDBTranslate(N'0', 38352,'Top') + ' ' + convert(varchar(10),@TopNumber) +  ' ' + dbo.fnDBTranslate(N'0', 38348, 'Downtime By') + ' '  + @Level2Name
Else If @ReportLevel = 3
  Select @Message = dbo.fnDBTranslate(N'0', 38352,'Top') + ' ' + convert(varchar(10),@TopNumber) + ' ' + dbo.fnDBTranslate(N'0', 38348, 'Downtime By') + ' ' + @Level3Name
Else If @ReportLevel = 4
  Select @Message = dbo.fnDBTranslate(N'0', 38352,'Top') + ' ' + convert(varchar(10),@TopNumber) + ' ' + dbo.fnDBTranslate(N'0', 38348, 'Downtime By') + ' ' + @Level4Name
Else If @ReportLevel = 5
  Select @Message = dbo.fnDBTranslate(N'0', 38352,'Top') + ' ' + convert(varchar(10),@TopNumber) + ' ' + dbo.fnDBTranslate(N'0', 38349, 'Downtime By Fault')
Else If @ReportLevel = 6
  Select @Message = dbo.fnDBTranslate(N'0', 38352,'Top') + ' ' + convert(varchar(10),@TopNumber) + ' ' + dbo.fnDBTranslate(N'0', 38350, 'Downtime By Crew') 
Else If @ReportLevel = 7
  Select @Message = dbo.fnDBTranslate(N'0', 38352,'Top') + ' ' + convert(varchar(10),@TopNumber) + ' ' + dbo.fnDBTranslate(N'0', 38351, 'Downtime By Product') 
insert into @ResultSets values (NULL, @Message, 'blue', NULL, NULL, NULL, NULL, NULL)
insert into @ResultSets values (dbo.fnDBTranslate(N'0', 38353,'Summary'), dbo.fnDBTranslate(N'0', 38353,'Summary'), NULL, NULL, NULL, NULL, NULL, 1)
insert into @ResultSets values (dbo.fnDBTranslate(N'0', 38354,'Total Time'), dbo.fnDBTranslate(N'0', 38354,'Total Time'), NULL, dbo.fnDBTranslate(N'0', 38339, 'Minutes'), 2, 1, NULL, 2)
If @ReportLevel = 7 and @CrewFilter is Null
  insert into @ResultSets values (dbo.fnDBTranslate(N'0', 38355,'Fault Time'), dbo.fnDBTranslate(N'0', 38355,'Fault Time'),NULL, dbo.fnDBTranslate(N'0', 38339, 'Minutes'),2, 1, NULL, 3)
insert into @ResultSets values (dbo.fnDBTranslate(N'0', 38339, 'Minutes'), dbo.fnDBTranslate(N'0', 38341, 'MTTR'),NULL, dbo.fnDBTranslate(N'0', 38339, 'Minutes'),2, 1, NULL, 4)
If @CrewFilter Is Null
  insert into @ResultSets values (dbo.fnDBTranslate(N'0', 38339, 'Minutes'), dbo.fnDBTranslate(N'0', 38342,'MTBF'),NULL,  dbo.fnDBTranslate(N'0', 38339, 'Minutes'),2, 1, NULL, 5)
insert into @ResultSets values (dbo.fnDBTranslate(N'0', 38356, 'Occur'), dbo.fnDBTranslate(N'0', 38356, 'Occur'),NULL, '#',2, 1, NULL, 6)
Select * From @ResultSets
Create Table #Results (
 	 Id 	  	  	  	 int NULL,
 	 Name 	  	  	 varchar(100) NULL,
 	 Total 	  	  	 real NULL,
 	 MTTR 	  	  	 real NULL,
 	 MTBF 	  	  	 real NULL,
 	 PercentTotal 	 real NULL,
 	 NumberOfEvents 	 int NULL 
)
Create Table #TmpResults (
 	 Id 	  	  	  	 int NULL,
 	 Name 	  	  	 varchar(100) NULL,
 	 Total 	  	  	 real NULL,
 	 MTTR 	  	  	 real NULL,
 	 MTBF 	  	  	 real NULL,
 	 PercentTotal 	 real NULL,
 	 NumberOfEvents 	 int NULL 
)
Create Table #Statistics (
 	 Id 	  	  	  	  	 int NULL,
 	 Name 	  	  	  	 varchar(100) NULL,
 	 Value 	  	  	  	 real NULL,
 	 Minimum 	  	  	  	 real NULL,
 	 Maximum 	  	  	  	 real NULL,
 	 StandardDeviation 	 real NULL
)
Create Table #TmpStatistics (
 	 Id 	  	  	  	  	 int NULL,
 	 Name 	  	  	  	 varchar(100) NULL,
 	 Value 	  	  	  	 real NULL,
 	 Minimum 	  	  	  	 real NULL,
 	 Maximum 	  	  	  	 real NULL,
 	 StandardDeviation 	 real NULL
)
Declare @SQL0 varchar(8000)
Select @SQL0=''
--*********************************************************************************
-- Return Resultsets For Location
--*********************************************************************************
If @ReportLevel = 0
  Begin
    Truncate Table #Results
    --Resultset #1, Summary
    Insert Into #Results (Id, Total, MTTR, MTBF, PercentTotal, NumberOfEvents)
      Select ItemId, sum(Duration), Avg(TimeToRepair), avg(TimePreviousFailure),sum(Duration) / convert(real,@TotalDowntime), Count(Duration)
        From @Summary
        Group By ItemId
    Truncate Table #TmpResults
 	 insert into #TmpResults select Top (@TopNumber) * from #Results order by Total desc
 	 
    Select @SQL1 = 'Select Format = 0, coalesce(u.pu_desc,' + '''' + dbo.fnDBTranslate(N'0', 38333, 'Unspecified') + ''') as [\@' + dbo.fnDBTranslate(N'0', 38335, 'Location') + '], convert(decimal(10,2),Total) as [' + dbo.fnDBTranslate(N'0', 38340, 'Total') +'],'
    Select @SQL1 = @SQL1 + 'dbo.fnRS_MakeTimeDurationString(r.MTTR) as ' + dbo.fnDBTranslate(N'0', 38341, 'MTTR') + ','
    Select @SQL1 = @SQL1 + 'dbo.fnRS_MakeTimeDurationString(r.MTBF) as ' + dbo.fnDBTranslate(N'0', 38342, 'MTBF')  +','  
    Select @SQL1 = @SQL1 + 'convert(decimal(10,1),r.PercentTotal*100.0) as [\@' + dbo.fnDBTranslate(N'0', 38343, '% Total') + '], r.NumberOfEvents as [' + dbo.fnDBTranslate(N'0', 38344, '# Events') + '], 1 as RS_ID From #TmpResults r Left join Prod_Units u on u.pu_id = r.Id Order By Total ASC'
    Exec (@SQL1)
    --Resultset #2, Total Time
    Select @SQL1 = 'Select Format = 0, coalesce(u.pu_desc,' + '''' + dbo.fnDBTranslate(N'0', 38333, 'Unspecified') + ''') as [\@' + dbo.fnDBTranslate(N'0', 38335, 'Location') + '], convert(decimal(10,2),Total) as [' + dbo.fnDBTranslate(N'0', 38340, 'Total') +'], 2 as RS_ID From #TmpResults r Left join Prod_Units u on u.pu_id = r.Id Order By Total ASC' 
    Exec (@SQL1)
    --Resultset #4, MTTR
    Truncate Table #Statistics
    Insert Into #Statistics (Id, Value, Minimum, Maximum, StandardDeviation)
      Select ItemId, avg(TimeToRepair), min(TimeToRepair), max(TimeToRepair), stdev(TimeToRepair)
        From @Summary
        Group By ItemId
    Truncate Table #TmpStatistics
 	 insert into #TmpStatistics select Top (@TopNumber) * from #Statistics order by Value desc
    Select @SQL1 = 'Select Format = 0, coalesce(u.pu_desc,' + '''' + dbo.fnDBTranslate(N'0', 38333, 'Unspecified') + ''') as [\@' + dbo.fnDBTranslate(N'0', 38335, 'Location') + '], '
    Select @SQL1 = @SQL1 + 'convert(decimal(10,2),Value) as [' + dbo.fnDBTranslate(N'0', 38361, 'Minutes') +']' + ','
    Select @SQL1 = @SQL1 + 'dbo.fnRS_MakeTimeDurationString(Value) as ' + dbo.fnDBTranslate(N'0', 38341, 'MTTR') + ','
    Select @SQL1 = @SQL1 + 'dbo.fnRS_MakeTimeDurationString(Minimum) as ' + dbo.fnDBTranslate(N'0', 38360, 'Minimum') + ','
    Select @SQL1 = @SQL1 + 'dbo.fnRS_MakeTimeDurationString(Maximum) as ' + dbo.fnDBTranslate(N'0', 38357, 'Maximum') + ','
    Select @SQL1 = @SQL1 + 'dbo.fnRS_MakeTimeDurationString(StandardDeviation) as ''' + dbo.fnDBTranslate(N'0', 38358, 'StDev') + ''','
    Select @SQL1 = @SQL1 + ' 4 as RS_ID From #TmpStatistics r Left join Prod_Units u on u.pu_id = r.Id Order By Value ASC' 
 	 Exec (@SQL1)
    --Resultset #5, MTBF
    Truncate Table #Statistics
    Insert Into #Statistics (Id, Value, Minimum, Maximum, StandardDeviation)
      Select ItemId, avg(TimePreviousFailure), min(TimePreviousFailure), max(TimePreviousFailure), stdev(TimePreviousFailure)
        From @Summary
        Group By ItemId
    Truncate Table #TmpStatistics
 	 insert into #TmpStatistics select Top (@TopNumber) * from #Statistics order by Value desc
    Select @SQL1 = 'Select Format = 0, coalesce(u.pu_desc,' + '''' + dbo.fnDBTranslate(N'0', 38333, 'Unspecified') + ''') as [\@' + dbo.fnDBTranslate(N'0', 38335, 'Location') + '], '
    Select @SQL1 = @SQL1 + 'convert(decimal(10,2),Value) as [' + dbo.fnDBTranslate(N'0', 38342, 'MTBF') + '-' + dbo.fnDBTranslate(N'0', 38339, 'Minutes') +']' + ','
    Select @SQL1 = @SQL1 + 'dbo.fnRS_MakeTimeDurationString(Value) as ' + dbo.fnDBTranslate(N'0', 38342, 'MTBF') + ','
    Select @SQL1 = @SQL1 + '5 as RS_ID From #TmpStatistics r Left join Prod_Units u on u.pu_id = r.Id Order By Value ASC' 
    Exec (@SQL1)
    --Resultset #6, Ocuurences
    Truncate Table #Statistics
    Insert Into #Statistics (Id, Value, Minimum, Maximum, StandardDeviation)
      Select ItemId, count(Duration), null, null, null
        From @Summary
        Group By ItemId
    Truncate Table #TmpStatistics
 	 insert into #TmpStatistics select Top (@TopNumber) * from #Statistics order by Value desc
    Select @SQL1 = 'Select Format = 0, coalesce(u.pu_desc,' + '''' + dbo.fnDBTranslate(N'0', 38333, 'Unspecified') + ''') as [\@' + dbo.fnDBTranslate(N'0', 38335, 'Location') + '], convert(decimal(10,0),Value) as [' + dbo.fnDBTranslate(N'0', 38356, 'Occur') +'], 6 as RS_ID From #TmpStatistics r Left join Prod_Units u on u.pu_id = r.Id Order By Value ASC' 
    Exec (@SQL1)
  End
--*********************************************************************************
-- Return Resultsets For Causes
--*********************************************************************************
If @ReportLevel > 0 and @ReportLevel < 5
  Begin
    Truncate Table #Results
   --Resultset #1, Summary
    Insert Into #Results (Id, Total, MTTR, MTBF, PercentTotal, NumberOfEvents)
      Select ItemId, 
 	  	 sum(Duration), Avg(TimeToRepair), avg(TimePreviousFailure),sum(Duration) / convert(real,@TotalDowntime), Count(Duration)
        From @Summary
        Group By ItemId
    Truncate Table #TmpResults
 	 insert into #TmpResults select Top (@TopNumber) * from #Results order by Total desc
    Select @SQL1 = 'Select Format = 0, coalesce(n.Event_Reason_Name,' + '''' + dbo.fnDBTranslate(N'0', 38333, 'Unspecified') + ''') as [\@' + Case @ReportLevel When 1 Then @Level1Name When 2 Then @Level2Name When 3 Then @Level3Name Else @Level4Name End + '], convert(decimal(10,2),Total) as [' + dbo.fnDBTranslate(N'0', 38340, 'Total') +'], '
    Select @SQL1 = @SQL1 + 'dbo.fnRS_MakeTimeDurationString(r.MTTR) as ' + dbo.fnDBTranslate(N'0', 38341, 'MTTR') + ','
    Select @SQL1 = @SQL1 + 'dbo.fnRS_MakeTimeDurationString(r.MTBF) as ' + dbo.fnDBTranslate(N'0', 38342, 'MTBF')  +',' 
    Select @SQL1 = @SQL1 + 'convert(decimal(10,1),r.PercentTotal*100.0) as [\@' + dbo.fnDBTranslate(N'0', 38343, '% Total') + '], r.NumberOfEvents as [' + dbo.fnDBTranslate(N'0', 38344, '# Events') + '], 1 as RS_ID From #TmpResults r Left join Event_Reasons n on n.event_reason_id = r.Id Order By Total ASC'
    Exec (@SQL1)
    --Resultset #2, Total Time
    Select @SQL1 = 'Select Format = 0, coalesce(n.Event_Reason_Name,' + '''' + dbo.fnDBTranslate(N'0', 38333, 'Unspecified') + ''') as [\@' + Case @ReportLevel When 1 Then @Level1Name When 2 Then @Level2Name When 3 Then @Level3Name Else @Level4Name End + '], convert(decimal(10,2),Total) as [' + dbo.fnDBTranslate(N'0', 38340, 'Total') +'], 2 as RS_ID From #TmpResults r Left join Event_Reasons n on n.event_reason_id = r.Id Order By Total ASC' 
    Exec (@SQL1)
    --Resultset #4, MTTR
    Truncate Table #Statistics
    Insert Into #Statistics (Id, Value, Minimum, Maximum, StandardDeviation)
      Select ItemId, avg(TimeToRepair), min(TimeToRepair), max(TimeToRepair), stdev(TimeToRepair)
        From @Summary
        Group By ItemId
    Truncate Table #TmpStatistics
 	 insert into #TmpStatistics select Top (@TopNumber) * from #Statistics order by Value desc
    Select @SQL1 = 'Select Format = 0, coalesce(n.Event_Reason_Name,' + '''' + dbo.fnDBTranslate(N'0', 38333, 'Unspecified') + ''') as [\@' + Case @ReportLevel When 1 Then @Level1Name When 2 Then @Level2Name When 3 Then @Level3Name Else @Level4Name End + '], '
    Select @SQL1 = @SQL1 + 'convert(decimal(10,2),Value) as [' + dbo.fnDBTranslate(N'0', 38361, 'Minutes') +']' + ','
    Select @SQL1 = @SQL1 + 'dbo.fnRS_MakeTimeDurationString(Value) as ' + dbo.fnDBTranslate(N'0', 38341, 'MTTR') + ','
    Select @SQL1 = @SQL1 + 'dbo.fnRS_MakeTimeDurationString(Minimum) as ' + dbo.fnDBTranslate(N'0', 38360, 'Minimum') + ','
    Select @SQL1 = @SQL1 + 'dbo.fnRS_MakeTimeDurationString(Maximum) as ' + dbo.fnDBTranslate(N'0', 38357, 'Maximum') + ','
    Select @SQL1 = @SQL1 + 'dbo.fnRS_MakeTimeDurationString(StandardDeviation) as ''' + dbo.fnDBTranslate(N'0', 38358, 'StDev') + ''','
    Select @SQL1 = @SQL1 + '4 as RS_ID From #TmpStatistics r Left join Event_Reasons n on n.event_reason_id = r.Id Order By Value ASC' 
    Exec (@SQL1)
    --Resultset #5, MTBF
    Truncate Table #Statistics
    Insert Into #Statistics (Id, Value, Minimum, Maximum, StandardDeviation)
      Select ItemId, avg(TimePreviousFailure), min(TimePreviousFailure), max(TimePreviousFailure), stdev(TimePreviousFailure)
        From @Summary
        Group By ItemId
    Truncate Table #TmpStatistics
 	 insert into #TmpStatistics select Top (@TopNumber) * from #Statistics order by Value desc
    Select @SQL1 = 'Select Format = 0, coalesce(n.Event_Reason_Name,' + '''' + dbo.fnDBTranslate(N'0', 38333, 'Unspecified') + ''') as [\@' + Case @ReportLevel When 1 Then @Level1Name When 2 Then @Level2Name When 3 Then @Level3Name Else @Level4Name End + '], '
    Select @SQL1 = @SQL1 + 'convert(decimal(10,2),Value) as [' + dbo.fnDBTranslate(N'0', 38342, 'MTBF') + '-' + dbo.fnDBTranslate(N'0', 38339, 'Minutes') +']' + ','
    Select @SQL1 = @SQL1 + 'dbo.fnRS_MakeTimeDurationString(Value) as ' + dbo.fnDBTranslate(N'0', 38342, 'MTBF') + ','
    Select @SQL1 = @SQL1 + '5 as RS_ID From #TmpStatistics r Left join Event_Reasons n on n.event_reason_id = r.Id Order By Value ASC' 
    Exec (@SQL1)
    --Resultset #6, Ocuurences
    Truncate Table #Statistics
    Insert Into #Statistics (Id, Value, Minimum, Maximum, StandardDeviation)
      Select ItemId, count(Duration), null, null, null
        From @Summary
        Group By ItemId
    Truncate Table #TmpStatistics
 	 insert into #TmpStatistics select Top (@TopNumber) * from #Statistics order by Value desc
    Select @SQL1 = 'Select Top ' + convert(varchar(10), @TopNumber) + ' Format = 0, coalesce(n.Event_Reason_Name,' + '''' + dbo.fnDBTranslate(N'0', 38333, 'Unspecified') + ''') as [\@' + Case @ReportLevel When 1 Then @Level1Name When 2 Then @Level2Name When 3 Then @Level3Name Else @Level4Name End + '], convert(decimal(10,0),Value) as [' + dbo.fnDBTranslate(N'0', 38356, 'Occur') +'], 6 as RS_ID From #TmpStatistics r Left join Event_Reasons n on n.event_reason_id = r.Id Order By Value ASC' 
    Exec (@SQL1)
  End
--*********************************************************************************
-- Return Resultsets For Fault
--*********************************************************************************
If @ReportLevel = 5
  Begin
    Truncate Table #Results
    --Resultset #1, Summary
    Insert Into #Results (Name, Total, MTTR, MTBF, PercentTotal, NumberOfEvents)
      Select Fault, sum(Duration), Avg(TimeToRepair), avg(TimePreviousFailure),sum(Duration) / convert(real,@TotalDowntime), Count(Duration)
        From @Summary
        Group By Fault
    Truncate Table #TmpResults
 	 insert into #TmpResults select Top (@TopNumber) * from #Results order by Total desc
    Select @SQL1 = 'Select Format = 0, coalesce(r.Name,' + '''' + dbo.fnDBTranslate(N'0', 38333, 'Unspecified') + ''') as [\@' + dbo.fnDBTranslate(N'0', 38336, 'Fault') + '], convert(decimal(10,2),Total) as [' + dbo.fnDBTranslate(N'0', 38340, 'Total') +'], '
    Select @SQL1 = @SQL1 + 'dbo.fnRS_MakeTimeDurationString(r.MTTR) as ' + dbo.fnDBTranslate(N'0', 38341, 'MTTR') + ','
    If @CrewFilter Is Null
      Select @SQL1 = @SQL1 + 'dbo.fnRS_MakeTimeDurationString(r.MTBF) as ' + dbo.fnDBTranslate(N'0', 38342, 'MTBF')  +',' 
    Select @SQL1 = @SQL1 + 'convert(decimal(10,1),r.PercentTotal*100.0) as [\@' + dbo.fnDBTranslate(N'0', 38343, '% Total') + '], r.NumberOfEvents as [' + dbo.fnDBTranslate(N'0', 38344, '# Events') + '], 1 as RS_ID From #TmpResults r Order By Total ASC'
    Exec (@SQL1)
    --Resultset #2, Total Time
    Select @SQL1 = 'Select Format = 0, coalesce(r.Name,' + '''' + dbo.fnDBTranslate(N'0', 38333, 'Unspecified') + ''') as [\@' + dbo.fnDBTranslate(N'0', 38336, 'Fault') + '], convert(decimal(10,2),Total) as [' + dbo.fnDBTranslate(N'0', 38340, 'Total') +'], 2 as RS_ID From #TmpResults r Order By Total ASC' 
    Exec (@SQL1)
    --Resultset #4, MTTR
    Truncate Table #Statistics
    Insert Into #Statistics (Name, Value, Minimum, Maximum, StandardDeviation)
      Select Fault, avg(TimeToRepair), min(TimeToRepair), max(TimeToRepair), stdev(TimeToRepair)
        From @Summary
        Group By Fault
    Truncate Table #TmpStatistics
 	 insert into #TmpStatistics select Top (@TopNumber) * from #Statistics order by Value desc
    Select @SQL1 = 'Select Format = 0, coalesce(r.Name,' + '''' + dbo.fnDBTranslate(N'0', 38333, 'Unspecified') + ''') as [\@' + dbo.fnDBTranslate(N'0', 38336, 'Fault') + '], '
    Select @SQL1 = @SQL1 + 'convert(decimal(10,2),Value) as [' + dbo.fnDBTranslate(N'0', 38361, 'Minutes') +']' + ','
    Select @SQL1 = @SQL1 + 'dbo.fnRS_MakeTimeDurationString(Value) as ' + dbo.fnDBTranslate(N'0', 38341, 'MTTR') + ','
    Select @SQL1 = @SQL1 + 'dbo.fnRS_MakeTimeDurationString(Minimum) as ' + dbo.fnDBTranslate(N'0', 38360, 'Minimum') + ','
    Select @SQL1 = @SQL1 + 'dbo.fnRS_MakeTimeDurationString(Maximum) as ' + dbo.fnDBTranslate(N'0', 38357, 'Maximum') + ','
    Select @SQL1 = @SQL1 + 'dbo.fnRS_MakeTimeDurationString(StandardDeviation) as ''' + dbo.fnDBTranslate(N'0', 38358, 'StDev') + ''','
    Select @SQL1 = @SQL1 + '4 as RS_ID From #TmpStatistics r Order By Value ASC'
    Exec (@SQL1)
    --Resultset #5, MTBF
    Truncate Table #Statistics
    Insert Into #Statistics (Name, Value, Minimum, Maximum, StandardDeviation)
      Select Fault, avg(TimePreviousFailure),min(TimePreviousFailure), max(TimePreviousFailure), stdev(TimePreviousFailure)
        From @Summary
        Group By Fault
    Truncate Table #TmpStatistics
 	 insert into #TmpStatistics select Top (@TopNumber) * from #Statistics order by Value desc
    Select @SQL1 = 'Select Format = 0, coalesce(r.Name,' + '''' + dbo.fnDBTranslate(N'0', 38333, 'Unspecified') + ''') as [\@' + dbo.fnDBTranslate(N'0', 38336, 'Fault') + '], '
    Select @SQL1 = @SQL1 + 'convert(decimal(10,2),Value) as [' + dbo.fnDBTranslate(N'0', 38342, 'MTBF') + '-' + dbo.fnDBTranslate(N'0', 38339, 'Minutes') +']' + ','
    Select @SQL1 = @SQL1 + 'dbo.fnRS_MakeTimeDurationString(Value) as ' + dbo.fnDBTranslate(N'0', 38342, 'MTBF') + ','
    Select @SQL1 = @SQL1 + '5 as RS_ID From #TmpStatistics r Order By Value ASC' 
    Exec (@SQL1)
    --Resultset #6, Ocuurences
    Truncate Table #Statistics
    Insert Into #Statistics (Name, Value, Minimum, Maximum, StandardDeviation)
      Select Fault, count(Duration), null, null, null
        From @Summary
        Group By Fault
    Truncate Table #TmpStatistics
 	 insert into #TmpStatistics select Top (@TopNumber) * from #Statistics order by Value desc
    Select @SQL1 = 'Select Format = 0, coalesce(r.Name,' + '''' + dbo.fnDBTranslate(N'0', 38333, 'Unspecified') + ''') as [\@' + dbo.fnDBTranslate(N'0', 38336, 'Fault') + '], convert(decimal(10,0),Value) as [' + dbo.fnDBTranslate(N'0', 38356, 'Occur') +'], 6 as RS_ID From #TmpStatistics r Order By Value ASC' 
    Exec (@SQL1)
  End
--*********************************************************************************
-- Return Resultsets For Crew
--*********************************************************************************
If @ReportLevel = 6
  Begin
    Truncate Table #Results
    --Resultset #1, Summary
    Insert Into #Results (Name, Total, MTTR, MTBF, PercentTotal, NumberOfEvents)
      Select Crew, sum(Duration), Avg(TimeToRepair), avg(TimePreviousFailure),sum(Duration) / convert(real,@TotalDowntime), Count(Duration)
        From @Summary
        Group By Crew
    Truncate Table #TmpResults
 	 insert into #TmpResults select Top (@TopNumber) * from #Results order by Total desc
    Select @SQL1 = 'Select Format = 0, coalesce(r.Name,' + '''' + dbo.fnDBTranslate(N'0', 38333, 'Unspecified') + ''') as [\@' + dbo.fnDBTranslate(N'0', 38338, 'Crew') + '], convert(decimal(10,2),Total) as [' + dbo.fnDBTranslate(N'0', 38340, 'Total') +'], '
    Select @SQL1 = @SQL1 + 'dbo.fnRS_MakeTimeDurationString(r.MTTR) as ' + dbo.fnDBTranslate(N'0', 38341, 'MTTR') + ','
    If @CrewFilter Is Null
      Select @SQL1 = @SQL1 + 'dbo.fnRS_MakeTimeDurationString(r.MTBF) as ' + dbo.fnDBTranslate(N'0', 38342, 'MTBF')  +',' 
    Select @SQL1 = @SQL1 + 'convert(decimal(10,1),r.PercentTotal*100.0) as [\@' + dbo.fnDBTranslate(N'0', 38343, '% Total') + '], r.NumberOfEvents as [' + dbo.fnDBTranslate(N'0', 38344, '# Events') + '], 1 as RS_ID From #TmpResults r Order By Total ASC'
    Exec (@SQL1)
    --Resultset #2, Total Time
    Select @SQL1 = 'Select Format = 0, coalesce(r.Name,' + '''' + dbo.fnDBTranslate(N'0', 38333, 'Unspecified') + ''') as [\@' + dbo.fnDBTranslate(N'0', 38338, 'Crew') + '], convert(decimal(10,2),Total) as [' + dbo.fnDBTranslate(N'0', 38340, 'Total') +'], 2 as RS_ID From #TmpResults r Order By Total ASC' 
    Exec (@SQL1)
    --Resultset #4, MTTR
    Truncate Table #Statistics
    Insert Into #Statistics (Name, Value, Minimum, Maximum, StandardDeviation)
      Select Crew, avg(TimeToRepair), min(TimeToRepair), max(TimeToRepair), stdev(TimeToRepair)
        From @Summary
        Group By Crew
    Truncate Table #TmpStatistics
 	 insert into #TmpStatistics select Top (@TopNumber) * from #Statistics order by Value desc
    Select @SQL1 = 'Select Format = 0, coalesce(r.Name,' + '''' + dbo.fnDBTranslate(N'0', 38333, 'Unspecified') + ''') as [\@' + dbo.fnDBTranslate(N'0', 38338, 'Crew') + '], '
    Select @SQL1 = @SQL1 + 'convert(decimal(10,2),Value) as [' + dbo.fnDBTranslate(N'0', 38361, 'Minutes') +']' + ','
    Select @SQL1 = @SQL1 + 'dbo.fnRS_MakeTimeDurationString(Value) as ' + dbo.fnDBTranslate(N'0', 38341, 'MTTR') + ','
    Select @SQL1 = @SQL1 + 'dbo.fnRS_MakeTimeDurationString(Minimum) as ' + dbo.fnDBTranslate(N'0', 38360, 'Minimum') + ','
    Select @SQL1 = @SQL1 + 'dbo.fnRS_MakeTimeDurationString(Maximum) as ' + dbo.fnDBTranslate(N'0', 38357, 'Maximum') + ','
    Select @SQL1 = @SQL1 + 'dbo.fnRS_MakeTimeDurationString(StandardDeviation) as ''' + dbo.fnDBTranslate(N'0', 38358, 'StDev') + ''','
    Select @SQL1 = @SQL1 + '4 as RS_ID From #TmpStatistics r Order By Value ASC' 
    Exec (@SQL1)
    --Resultset #5, MTBF
    Truncate Table #Statistics
    Insert Into #Statistics (Name, Value, Minimum, Maximum, StandardDeviation)
      Select Crew, avg(TimePreviousFailure), min(TimePreviousFailure), max(TimePreviousFailure), stdev(TimePreviousFailure)
        From @Summary
        Group By Crew
    Truncate Table #TmpStatistics
 	 insert into #TmpStatistics select Top (@TopNumber) * from #Statistics order by Value desc
    Select @SQL1 = 'Select Format = 0, coalesce(r.Name,' + '''' + dbo.fnDBTranslate(N'0', 38333, 'Unspecified') + ''') as [\@' + dbo.fnDBTranslate(N'0', 38338, 'Crew') + '], '
    Select @SQL1 = @SQL1 + 'convert(decimal(10,2),Value) as [' + dbo.fnDBTranslate(N'0', 38342, 'MTBF') + '-' + dbo.fnDBTranslate(N'0', 38339, 'Minutes') +']' + ','
    Select @SQL1 = @SQL1 + 'dbo.fnRS_MakeTimeDurationString(Value) as ' + dbo.fnDBTranslate(N'0', 38342, 'MTBF') + ','
    Select @SQL1 = @SQL1 + '5 as RS_ID From #TmpStatistics r Order By Value ASC' 
    Exec (@SQL1)
    --Resultset #6, Ocuurences
    Truncate Table #Statistics
    Insert Into #Statistics (Name, Value, Minimum, Maximum, StandardDeviation)
      Select Crew, count(Duration), null, null, null
        From @Summary
        Group By Crew
    Truncate Table #TmpStatistics
 	 insert into #TmpStatistics select Top (@TopNumber) * from #Statistics order by Value desc
    Select @SQL1 = 'Select Format = 0, coalesce(r.Name,' + '''' + dbo.fnDBTranslate(N'0', 38333, 'Unspecified') + ''') as [\@' + dbo.fnDBTranslate(N'0', 38338, 'Crew') + '], convert(decimal(10,0),Value) as [' + dbo.fnDBTranslate(N'0', 38356, 'Occur') +'], 6 as RS_ID From #TmpStatistics r Order By Value ASC'  
    Exec (@SQL1)
  End
--*********************************************************************************
-- Return Resultsets For Product
--*********************************************************************************
If @ReportLevel = 7
  Begin
 	  	 Truncate Table #Results
 	  	 -- Return % Operating Time By Product
    Create Table #IntegerResults (
      ID    int NULL,
      Value int NULL
    )
 	  	 
 	  	 Insert Into #IntegerResults (Id, Value)
 	  	   Select ProductId, sum(TotalTime)
        From @OperatingTime
 	  	     Group By ProductId 
 	  	 
    --Resultset #1, Summary
    Insert Into #Results (Id, Total, MTTR, MTBF, PercentTotal, NumberOfEvents)
      Select ProductId, sum(Duration), Avg(TimeToRepair), avg(TimePreviousFailure),sum(Duration) / convert(real,@TotalDowntime), Count(Duration)
        From @Summary
        Group By ProductId
    Truncate Table #TmpResults
 	 insert into #TmpResults select Top (@TopNumber) * from #Results order by Total desc
    Select @SQL1 = 'Select Format = 0, coalesce(p.prod_code,' + '''' + dbo.fnDBTranslate(N'0', 38333, 'Unspecified') + ''') as [\@' + dbo.fnDBTranslate(N'0', 38337, 'Product') + '], '
    Select @SQL1 = @SQL1 + 'convert(decimal(10,2),Total) as [' + dbo.fnDBTranslate(N'0', 38340, 'Total') +'], '
    Select @SQL1 = @SQL1 + 'dbo.fnRS_MakeTimeDurationString(r.MTTR) as ' + dbo.fnDBTranslate(N'0', 38341, 'MTTR') + ','
    If @CrewFilter Is Null
      Select @SQL1 = @SQL1 + 'dbo.fnRS_MakeTimeDurationString(r.MTBF) as ' + dbo.fnDBTranslate(N'0', 38342, 'MTBF')  +',' 
    Select @SQL1 = @SQL1 + 'convert(decimal(10,1),r.PercentTotal*100.0) as [\@' + dbo.fnDBTranslate(N'0', 38343, '% Total') + '], r.NumberOfEvents as [' + dbo.fnDBTranslate(N'0', 38344, '# Events') + '], 1 as RS_ID From #TmpResults r join Products p on p.prod_id = r.Id Order By Total ASC'
 	 
    Exec (@SQL1)
    --Resultset #2, Total Time
    Select @SQL1 = 'Select Format = 0, coalesce(p.prod_code,' + '''' + dbo.fnDBTranslate(N'0', 38333, 'Unspecified') + ''') as [\@' + dbo.fnDBTranslate(N'0', 38337, 'Product') + '], convert(decimal(10,2),Total) as [' + dbo.fnDBTranslate(N'0', 38340, 'Total') +'], 2 as RS_ID From #TmpResults r join Products p on p.prod_id = r.Id Order By Total ASC'
    Exec (@SQL1)
   --Resultset #3, Fault Time
    If @CrewFilter Is Null
      Begin
 	     Truncate Table #TmpResults
 	  	 insert into #TmpResults select Top (@TopNumber) r.* From #Results r left outer join #IntegerResults i on i.Id = r.Id Order By (r.Total / (i.value/60.0) * 100.0) DESC 
        Select @SQL1 = 'Select Format = 0, coalesce(p.prod_code,' + '''' + dbo.fnDBTranslate(N'0', 38333, 'Unspecified') + ''') as [\@' + dbo.fnDBTranslate(N'0', 38337, 'Product') + '], convert(decimal(10,2),(r.Total / (i.value/60.0) * 100.0)) as [' + dbo.fnDBTranslate(N'0', 38346, '% Fault') + '], 3 as RS_ID From #TmpResults r join Products p on p.prod_id = r.Id left outer join #IntegerResults i on i.Id = r.Id Order By (r.Total / (i.value/60.0) * 100.0) ASC' 
        Exec (@SQL1)
      End
    --Resultset #4, MTTR
    Truncate Table #Statistics
    Insert Into #Statistics (Id, Value, Minimum, Maximum, StandardDeviation)
      Select ProductId, avg(TimeToRepair), min(TimeToRepair), max(TimeToRepair), stdev(TimeToRepair)
        From @Summary
        Group By ProductId
    Truncate Table #TmpStatistics
 	 insert into #TmpStatistics select Top (@TopNumber) * from #Statistics order by Value desc
    Select @SQL1 = 'Select Format = 0, coalesce(p.prod_code,' + '''' + dbo.fnDBTranslate(N'0', 38333, 'Unspecified') + ''') as [\@' + dbo.fnDBTranslate(N'0', 38337, 'Product') + '], '
    Select @SQL1 = @SQL1 + 'convert(decimal(10,2),Value) as [' + dbo.fnDBTranslate(N'0', 38361, 'Minutes') +']' + ','
    Select @SQL1 = @SQL1 + 'dbo.fnRS_MakeTimeDurationString(Value) as ' + dbo.fnDBTranslate(N'0', 38341, 'MTTR') + ','
    Select @SQL1 = @SQL1 + 'dbo.fnRS_MakeTimeDurationString(Minimum) as ' + dbo.fnDBTranslate(N'0', 38360, 'Minimum') + ','
    Select @SQL1 = @SQL1 + 'dbo.fnRS_MakeTimeDurationString(Maximum) as ' + dbo.fnDBTranslate(N'0', 38357, 'Maximum') + ','
    Select @SQL1 = @SQL1 + 'dbo.fnRS_MakeTimeDurationString(StandardDeviation) as ''' + dbo.fnDBTranslate(N'0', 38358, 'StDev') + ''','
    Select @SQL1 = @SQL1 + '4 as RS_ID From #TmpStatistics r join Products p on p.prod_id = r.Id Order By Value ASC' 
    Exec (@SQL1)
    --Resultset #5, MTBF
    Truncate Table #Statistics
    Insert Into #Statistics (Id, Value, Minimum, Maximum, StandardDeviation)
      Select ProductId, avg(TimePreviousFailure), min(TimePreviousFailure), max(TimePreviousFailure), stdev(TimePreviousFailure)
        From @Summary
        Group By ProductId
    Truncate Table #TmpStatistics
 	 insert into #TmpStatistics select Top (@TopNumber) * from #Statistics order by Value desc
    Select @SQL1 = 'Select Format = 0, coalesce(p.prod_code,' + '''' + dbo.fnDBTranslate(N'0', 38333, 'Unspecified') + ''') as [\@' + dbo.fnDBTranslate(N'0', 38337, 'Product') + '], '
    Select @SQL1 = @SQL1 + 'convert(decimal(10,2),Value) as [' + dbo.fnDBTranslate(N'0', 38342, 'MTBF') + '-' + dbo.fnDBTranslate(N'0', 38339, 'Minutes') +']' + ','
    Select @SQL1 = @SQL1 + 'dbo.fnRS_MakeTimeDurationString(Value) as ' + dbo.fnDBTranslate(N'0', 38342, 'MTBF') + ','
    Select @SQL1 = @SQL1 + '5 as RS_ID From #TmpStatistics r join Products p on p.prod_id = r.Id Order By Value ASC'
    Exec (@SQL1)
    --Resultset #6, Ocuurences
    Truncate Table #Statistics
    Insert Into #Statistics (Id, Value, Minimum, Maximum, StandardDeviation)
      Select ProductId, count(Duration), null, null, null
        From @Summary
        Group By ProductId
    Truncate Table #TmpStatistics
 	 insert into #TmpStatistics select Top (@TopNumber) * from #Statistics order by Value desc
    Select @SQL1 = 'Select Format = 0, coalesce(p.prod_code,' + '''' + dbo.fnDBTranslate(N'0', 38333, 'Unspecified') + ''') as [\@' + dbo.fnDBTranslate(N'0', 38337, 'Product') + '], convert(decimal(10,0),Value) as [' + dbo.fnDBTranslate(N'0', 38356, 'Occur') +'], 6 as RS_ID From #TmpStatistics r join Products p on p.prod_id = r.Id Order By Value ASC'  
    Exec (@SQL1)
    Drop Table #IntegerResults
  End
--Drop Table #ProductChanges
--Drop Table #Details
Drop Table #Results
Drop Table #TmpResults
Drop Table #Statistics
Drop Table #TmpStatistics
--Drop Table #Summary
Drop Table #Units
--Drop Table #OperatingTime
Drop Table #ProductiveTimes
