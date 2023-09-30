CREATE Procedure dbo.spDBR_AvailabilityDistribution
@UnitList text = null,
@StartTime datetime = null,
@EndTime datetime = null,
@FilterNonProductiveTime int = 0,
@ProductFilter int = null,
@CrewFilter varchar(20) = null,
@ShiftFilter varchar(20) = null,
@LocationFilter int = NULL,
@FaultFilter varchar(100) = NULL,
@ReasonFilter1 int = NULL,
@ReasonFilter2 int = NULL,
@ReasonFilter3 int = NULL,
@ReasonFilter4 int = NULL,
@ShowTopNBars int = 20,
@InTimeZone varchar(200) = NULL,  ---23/08/2010 - Ex: 'India Standard Time','Central Stardard Time'
@TimeOption 	 int=NULL
AS
--*********************************************************/
/*
"Availability Downtime" is Total downtime (Downtime Distribution) with Performance DT, Outside Area DT and Unavailable DT filtered out 
     OR it is only Unplanned DT which is (Calendar time ? (Performance DT +  Outside Area + Unavailable DT) 
*/
set arithignore on
set arithabort off
set ansi_warnings off
if (@LocationFilter = -1)
begin
 select @LocationFilter = NULL
end
Declare @@UnitId int, @@UnitDesc varchar(50)
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
Declare @PerformanceCategory int, @OutsideAreaCategory int, @UnavailableCategory int
Declare @PreviousDowntimeEnd Datetime
Declare @StoredTimePreviousFailure REAL, @ERC_ID int, @TimePreviousFailure REAL
Declare @OldDowntimeEnd datetime, @NewDowntimeStart Datetime, @NewDowntimeEnd datetime, @Id int
Declare @curStartTime datetime, @curEndTime datetime
Declare @curPU_Id int
Declare @RowCount int
Declare @TotalOperatingTime int
Declare @TotalDownTime real
Select @TotalOperatingTime = 0
Select @TotalDownTime = 0.0
Declare @Summary Table 
(
 	 Timestamp 	  	  	 datetime,
 	 EndTime 	  	  	  	 datetime,
 	 ProductId 	  	  	 int NULL,
 	 LocationId 	  	  	 int NULL,
 	 Reason1 	  	  	  	 int NULL,
 	 Reason2 	  	  	  	 int NULL,
 	 Reason3 	  	  	  	 int NULL,
 	 Reason4 	  	  	  	 int NULL,
 	 Duration 	  	  	 real NULL,
 	 TimeToRepair 	  	 real NULL,
 	 TimePreviousFailure 	 real NULL,
 	 Fault 	  	  	  	 varchar(100) NULL,
 	 Crew 	  	  	  	 varchar(20) NULL,
 	 Shift 	  	  	  	 varchar(20) NULL
) 
Declare @ProductChanges Table
(
 	 ProductId 	  	  	 int,
 	 StartTime 	  	  	 datetime,
 	 EndTime 	  	  	  	 datetime
) 
Declare @OperatingTime Table
(
 	 ProductId 	  	  	 int,
 	 TotalTime 	  	  	 int 
) 
create table #Units
(
 	 LineName 	  	  	 varchar(100) NULL, 
 	 LineId 	  	  	  	 int NULL,
 	 UnitName 	  	  	 varchar(100) NULL,
 	 Item 	  	  	  	 int
)
create table #ProductiveTimes
(
 	 PU_Id 	  	  	  	 int null,
 	 StartTime 	  	  	 datetime,
 	 EndTime 	  	  	  	 datetime
)
Create Table #Details 
(
 	 Id 	  	  	  	  	 int identity(1,1),
 	 TEdet_id 	  	  	 int,
 	 ERC_ID 	  	  	  	 int,
 	 Flag 	  	  	  	 int,
 	 Parent 	  	  	  	 int,
 	 Timestamp  	  	  	 datetime,
 	 Endtime 	  	  	  	 datetime,
 	 LocationId 	  	  	 int NULL,
 	 ProductId 	  	  	 int NULL,
 	 Reason1  	  	  	 int NULL,
 	 Reason2  	  	  	 int NULL,
 	 Reason3  	  	  	 int NULL,
 	 Reason4  	  	  	 int NULL,
 	 Duration  	  	  	 real NULL,
 	 TimeToRepair  	  	 real NULL,
 	 TimePreviousFailure 	 real NULL,
 	 FaultId  	  	  	 int NULL,
 	 Crew 	  	  	  	 varchar(20) null,
 	 Shift 	  	  	  	 varchar(20) NULL
) 
Declare @Data2 Table(id int identity, id_start int, id_finish int)
Declare @Data3 Table(id int, amount int)
Create Table #PreviousDowntimeEnd(End_Time datetime)
---23/08/2010 - Conversion of datetime into UTC e.g. India Standard Time','Central Stardard Time'
 /*Time Options are also need to consider */
Create Table  #TimeOptions (Option_Id int, Date_Type_Id int, Description varchar(50), Start_Time datetime, End_Time datetime)
---23/08/2010 - Conversion of datetime into UTC e.g. India Standard Time','Central Stardard Time'
 	 --SELECT @StartTime = dbo.fnServer_CmnConvertToDBTime(@StartTime,@InTimeZone)
 	 --SELECT @EndTime = dbo.fnServer_CmnConvertToDBTime(@EndTime,@InTimeZone)
 IF(@StartTime) IS NOT NULL AND (@EndTime) IS NOT NULL
BEGIN
 	 SELECT @StartTime = [dbo].[fnServer_CmnConvertToDbTime](@StartTime,@InTimeZone),
 	 @EndTime = [dbo].[fnServer_CmnConvertToDbTime](@EndTime,@InTimeZone)
END
ELSE IF (@TimeOption) IS NOT NULL
BEGIN
 	 Insert Into #TimeOptions exec spRS_GetTimeOptions @TimeOption,@InTimeZone
 	 Select @StartTime = Start_Time, @EndTime = End_Time From #TimeOptions
 	 SELECT @StartTime = [dbo].[fnServer_CmnConvertToDbTime](@StartTime,@InTimeZone),
 	  	 @EndTime = [dbo].[fnServer_CmnConvertToDbTime](@EndTime,@InTimeZone)
END
ELSE
BEGIN
 	 Insert Into #TimeOptions exec spRS_GetTimeOptions 30,@InTimeZone -- Default to Today if no start time and end time is provided
 	 Select @StartTime = Start_Time, @EndTime = End_Time From #TimeOptions 	 
 	 SELECT @StartTime = [dbo].[fnServer_CmnConvertToDbTime](@StartTime,@InTimeZone),
 	 @EndTime = [dbo].[fnServer_CmnConvertToDbTime](@EndTime,@InTimeZone)
END 
----------------------------------------------------------------------
-- Build Unit List
----------------------------------------------------------------------
if (not @UnitList like '%<Root></Root>%' and not @UnitList is NULL)
  begin
    if (not @UnitList like '%<Root>%')
    begin
      declare @UnitText nvarchar(4000)
      select @UnitText = N'Item;' + Convert(nvarchar(4000), @UnitList)
      Insert Into #Units (Item) EXECUTE spDBR_Prepare_Table @UnitText
    end
    else
    begin
      Insert Into #Units EXECUTE spDBR_Prepare_Table @UnitList
    end
  end
Else
  Begin
    Insert Into #Units (Item) 
      Select distinct pu_id From prod_events where event_type = 2     
  End
----------------------------------------------------------------------
-- Get Productive Time
----------------------------------------------------------------------
Declare PRODUCTIVETIME_CURSOR INSENSITIVE CURSOR
 	 For ( Select Item From #Units )
 	 For Read Only
Open PRODUCTIVETIME_CURSOR
Fetch Next From PRODUCTIVETIME_CURSOR Into @curPU_Id
While @@Fetch_Status = 0
 	 Begin
 	  	 if (@FilterNonProductiveTime = 1)
 	  	  	 Begin
 	  	  	  	 insert into #ProductiveTimes (StartTime, EndTime)  execute spDBR_GetProductiveTimes @curPU_Id, @StartTime, @EndTime
 	  	  	  	 update #ProductiveTimes set PU_Id = @curPU_Id where PU_Id is null
 	  	  	 End 	  	 
 	  	 Else
 	  	  	 Begin
 	  	  	  	 insert into #ProductiveTimes (PU_Id, StartTime, EndTime) select @curPU_Id, @StartTime, @EndTime
 	  	  	 End 	  	 
 	  	 Fetch Next From PRODUCTIVETIME_CURSOR Into @curPU_Id
 	 End
Close PRODUCTIVETIME_CURSOR
Deallocate PRODUCTIVETIME_CURSOR
-----------------------------------------------
-- Get Crew Schedule
-- Fill in any incomplete Crew Schedule Rows
-----------------------------------------------
Declare @Crew_Schedule TABLE(PU_Id int, Start_Time datetime, End_Time datetime, Crew_Desc varchar(15), Shift_Desc varchar(15))
declare @RowId int
Declare CREW_SCHEDULE_CURSOR Insensitive Cursor
 	 For ( Select PU_ID, StartTime, EndTime From #ProductiveTimes )
 	 For Read Only 	 
 	 Open CREW_SCHEDULE_CURSOR
 	 Fetch Next from CREW_SCHEDULE_CURSOR Into @curPU_Id, @curStartTime, @curEndTime
 	 While (@@Fetch_Status = 0)
 	  	 Begin
 	  	  	 Insert Into @Crew_Schedule(PU_ID, Start_Time, End_Time, Crew_Desc, Shift_Desc)
 	  	  	 select PU_ID, Start_Time, End_Time, Crew_Desc, Shift_Desc From fnCMN_GetUnitCrewSchedule(@curPU_Id, @curStartTime, @curEndTime)
 	  	  	 Fetch Next from CREW_SCHEDULE_CURSOR Into @curPU_Id, @curStartTime, @curEndTime
 	  	 End
Close CREW_SCHEDULE_CURSOR
Deallocate CREW_SCHEDULE_CURSOR
-------------------------------------------------------------------------------------
-- Go through each unit and get all the downtime while the unit was productive
-------------------------------------------------------------------------------------
Declare Unit_Cursor Insensitive Cursor 
  For Select Item From #Units 
  For Read Only
Open Unit_Cursor
Fetch Next From Unit_Cursor Into @@UnitId
While @@Fetch_Status = 0
 	 Begin
 	  	 -- Get Unit Categories
 	  	 Select @PerformanceCategory = Coalesce(Performance_Downtime_Category, 0), 
 	  	  	 @OutsideareaCategory = Coalesce(Downtime_External_Category, 0),
 	  	  	 @UnavailableCategory = Coalesce(Downtime_Scheduled_Category, 0),
 	  	  	 @@UnitDesc = pu_desc 
 	  	 From Prod_Units Where PU_Id = @@UnitId
 	  	 Declare TIME_CURSOR INSENSITIVE CURSOR
 	  	 For (Select StartTime, EndTime From #ProductiveTimes where PU_Id = @@UnitId)
 	  	 For Read Only
 	  	 Open TIME_CURSOR  
 	  	 BEGIN_TIME_CURSOR:
 	  	 Fetch Next From TIME_CURSOR Into @curStartTime, @curEndTime
 	  	 While @@Fetch_Status = 0
 	  	  	 Begin    
 	  	  	  	 -- Get Reason Level Header Names
 	  	  	  	 If @Level1Name Is Null
 	  	  	  	   Begin
     	  	  	  	  	 Select @TreeId = Name_Id From Prod_Events Where PU_Id = @@UnitId and Event_Type = 2
     	  	  	  	  	 Select @Level1Name = level_name From event_reason_level_headers Where Tree_Name_id = @TreeId and Reason_Level = 1
      	  	  	  	  	 If @Level1Name Is Not Null Select @Level2Name = level_name From event_reason_level_headers Where Tree_Name_id = @TreeId and Reason_Level = 2 	 
 	  	  	  	  	  	 If @Level2Name Is Not Null Select @Level3Name = level_name From event_reason_level_headers Where Tree_Name_id = @TreeId and Reason_Level = 3 	  	  	 
 	  	  	  	  	  	 If @Level3Name Is Not Null Select @Level4Name = level_name From event_reason_level_headers Where Tree_Name_id = @TreeId and Reason_Level = 4
 	  	  	  	   End
 	  	  	  	 -- Find Fault Filter
 	  	  	  	 If @FaultFilter Is Not Null
 	  	  	  	  	 Begin
 	  	  	  	  	  	 Select @FaultId = NULL
 	  	  	  	  	  	 Select @FaultId = TEFault_Id From Timed_Event_Fault Where PU_Id = @@UnitId and TEFault_Name = @FaultFilter
 	  	  	  	  	  	 Select @FaultId = IsNull(@FaultId, 0)
 	  	  	  	  	 End
 	  	  	  	 ----------------------------------------------------------------------------------------
 	  	  	  	 -- Get the end_time of the previous failure with the same matching criteria as above
 	  	  	  	 -- We need this to calculate the amount of UpTime when the first Downtime event occurred
 	  	  	  	 ----------------------------------------------------------------------------------------
 	  	  	  	 Select @SQL1 = ''
 	  	  	  	 select @SQL1 = @SQL1 + ' Select max(End_Time)'
 	  	  	  	 select @SQL1 = @SQL1 + ' From   Timed_Event_Details d'
 	  	  	  	 select @SQL1 = @SQL1 + ' Left Outer Join Event_Reason_Category_Data c on c.Event_Reason_Tree_Data_Id = d.Event_Reason_Tree_Data_Id'
 	  	  	  	 select @SQL1 = @SQL1 + ' Where  d.pu_Id = ' + convert(varchar(10), @@UnitId)
 	  	  	  	 select @SQL1 = @SQL1 + ' AND d.End_Time <= ' + '''' + convert(varchar(20), @curStartTime, 120) + '''' + ''
 	  	  	  	 select @SQL1 = @SQL1 + ' AND 	 ((not c.erc_id in (' + Convert(Varchar(10), @PerformanceCategory) + ', ' + Convert(Varchar(10), @OutsideAreaCategory) + ', ' + Convert(Varchar(10), @UnavailableCategory) + ')) OR (c.ERC_ID IS NULL))'
 	  	  	 
 	  	  	  	 If @FaultId Is Not Null
 	  	  	  	  	 Select @SQL1 = @SQL1 + ' AND (d.TEFault_Id = ' + Convert(varchar(10), @FaultId) + ')'
 	  	  	  	 If @ReasonFilter1 Is Not Null
 	  	  	  	  	 Select @SQL1 = @SQL1 + ' AND (d.Reason_Level1 = ' + Convert(varchar(10), @ReasonFilter1) + ')'
 	  	  	  	 If @ReasonFilter2 Is Not Null
 	  	  	  	  	 Select @SQL1 = @SQL1 + ' AND (d.Reason_Level2 = ' + Convert(varchar(10), @ReasonFilter2) + ')'
 	  	  	  	 If @ReasonFilter3 Is Not Null
 	  	  	  	  	 Select @SQL1 = @SQL1 + ' AND (d.Reason_Level3 = ' + Convert(varchar(10), @ReasonFilter3) + ')'
 	  	  	  	 If @ReasonFilter4 Is Not Null
 	  	  	  	  	 Select @SQL1 = @SQL1 + ' AND (d.Reason_Level4 = ' + Convert(varchar(10), @ReasonFilter4) + ')'
 	  	  	  	 delete from #PreviousDowntimeEnd
 	  	  	  	 insert into #PreviousDowntimeEnd(End_Time)
 	  	  	  	 Exec (@SQL1)
 	  	  	 
 	  	  	  	 Select @PreviousDowntimeEnd = End_Time from #PreviousDowntimeEnd
 	  	  	  	 Select @OldDowntimeEnd = IsNull(@PreviousDowntimeEnd, @curStartTime)
 	  	  	  	 Select @SQL1 = '' 	  	 
 	  	  	  	 -- Get Downtime Records
 	  	  	  	 Select @SQL1 = @SQL1 + ' Select tedet_Id, d.Start_Time, d.End_Time, isnull(d.Source_PU_Id, d.pu_Id), d.Reason_Level1, d.Reason_Level2, d.Reason_Level3, d.Reason_Level4, '
 	  	  	  	 Select @SQL1 = @SQL1 + '   DateDiff(Second, case When d.Start_Time < ' + '''' + convert(varchar(20), @curStartTime, 120) + '''' + ' Then ' + '''' + convert(varchar(20), @curStartTime, 120) + '''' + ' Else d.Start_Time End, '
 	  	  	  	 Select @SQL1 = @SQL1 + '       case When IsNull(d.End_Time,' + '''' + convert(varchar(20), @curEndTime, 120) + '''' + ') > ' + '''' + convert(varchar(20), @curEndTime, 120) + '''' + ' Then ' + '''' + convert(varchar(20), @curEndTime, 120) + '''' + ' Else IsNull(d.End_Time, ' + '''' + convert(varchar(20), @curEndTime, 120) + '''' + ') End) / 60.0,'
 	  	  	  	 Select @SQL1 = @SQL1 + ' DateDiff(Second, d.Start_Time, coalesce(d.End_Time,dbo.fnServer_CmnGetDate(getutcdate()))) / 60.0,'
 	  	  	  	 Select @SQL1 = @SQL1 + ' NULL,'
 	  	  	  	 Select @SQL1 = @SQL1 + ' d.TEFault_Id, '
 	  	  	  	 -- Select @SQL1 = @SQL1 + ' c.ERC_ID, '
 	  	  	  	 -- Select @SQL1 = @SQL1 + ' Case When c.ERC_Id In (' + convert(varchar(3), @PerformanceCategory) + ', ' + convert(varchar(3), @OutsideAreaCategory) + ', ' + convert(varchar(3), @UnavailableCategory) + ') Then 1 Else 0 End, '
 	  	  	  	 Select @SQL1 = @SQL1 + ' NULL, NULL, '
 	  	  	  	 Select @SQL1 = @SQL1 + ' ps.Prod_Id,'
 	  	  	  	 Select @SQL1 = @SQL1 + ' cs.Crew_Desc,'
 	  	  	  	 Select @SQL1 = @SQL1 + ' cs.Shift_Desc'
 	  	  	  	 Select @SQL1 = @SQL1 + ' From Timed_Event_Details d'
 	  	  	  	 -- Select @SQL1 = @SQL1 + ' Left Outer Join Event_Reason_Category_Data c on c.Event_Reason_Tree_Data_Id = d.Event_Reason_Tree_Data_Id'
 	  	  	  	 Select @SQL1 = @SQL1 + ' Join Production_Starts ps on ps.pu_id = ' + Convert(varchar(5), @@UnitId) + ' and ps.Start_Time <= d.End_Time and ((ps.End_Time > d.End_Time) or (ps.End_Time Is Null))'
 	  	  	  	 Select @SQL1 = @SQL1 + ' Left Join Crew_Schedule cs on cs.pu_id = d.pu_id and cs.Start_Time <= d.Start_Time and cs.End_Time > d.Start_Time'
 	  	  	  	 Select @SQL1 = @SQL1 + ' Where d.PU_ID = ' + Convert(varchar(5), @@UnitId) 
 	  	  	  	 Select @SQL1 = @SQL1 + ' AND d.Start_Time < ' + '''' + convert(varchar(20), @curEndTime, 120) + '''' + ' and ((d.End_Time > ' + '''' + convert(varchar(20), @OldDowntimeEnd, 120) + '''' + ') or (d.End_Time Is Null))'
 	  	  	  	 
 	  	  	  	 If @LocationFilter Is Not Null
 	  	  	  	  	 Select @SQL1 = @SQL1 + ' AND (d.Source_PU_Id  = ' + Convert(varchar(5), @LocationFilter) + ')'
 	  	  	  	 If @FaultId Is Not Null
 	  	  	  	  	 Select @SQL1 = @SQL1 + ' AND (d.TEFault_Id = ' + Convert(varchar(5), @FaultId) + ')'
 	  	  	  	 If @ReasonFilter1 Is Not Null
 	  	  	  	  	 Select @SQL1 = @SQL1 + ' AND (d.Reason_Level1 = ' + Convert(varchar(5), @ReasonFilter1) + ')'
 	  	  	  	 If @ReasonFilter2 Is Not Null
 	  	  	  	  	 Select @SQL1 = @SQL1 + ' AND (d.Reason_Level2 = ' + Convert(varchar(5), @ReasonFilter2) + ')'
 	  	  	  	 If @ReasonFilter3 Is Not Null
 	  	  	  	  	 Select @SQL1 = @SQL1 + ' AND (d.Reason_Level3 = ' + Convert(varchar(5), @ReasonFilter3) + ')'
 	  	  	  	 If @ReasonFilter4 Is Not Null
 	  	  	  	  	 Select @SQL1 = @SQL1 + ' AND (d.Reason_Level4 = ' + Convert(varchar(5), @ReasonFilter4) + ')'
 	  	  	  	 Select @SQL1 = @SQL1 + ' Order By d.Start_Time'
 	  	  	  	 Insert Into #Details (Tedet_id, Timestamp, EndTime, LocationId, Reason1, Reason2, Reason3, Reason4, Duration, TimeToRepair, TimePreviousFailure, FaultId, ERC_ID, Flag, ProductId, Crew, Shift)
 	  	  	  	 exec (@SQL1)
 	  	  	  	 
 	  	  	  	 -- Possible to get some negative durations because of the records we read before the time period
 	  	  	  	 --update #Details set Duration = 0 where Duration < 0
 	  	  	  	 ----------------------------------------------------------------------------------------
 	  	  	  	 -- I'm going to remove any downtime associated with Performance, Outside Area and Unavailable
 	  	  	  	 -- but I need to retain the amount of Uptime that was associated with those events
 	  	  	  	 -- and add it to the next available downtime event
 	  	  	  	 ----------------------------------------------------------------------------------------
 	  	  	  	 Declare @CleanupTable TABLE(TEDEt_Id int, ERC_Id int, FLAG int)
 	  	  	  	 -- Get Event_Reason_Categories for all downtime events
 	  	  	  	 -- NOTE: Some downtime reasons can belong to multiple categories
 	  	  	  	 Insert into @CleanupTable(TEDEt_Id, ERC_Id, Flag)
 	  	  	  	  	 Select d.TEDET_Id, c.ERC_Id,
 	  	  	  	  	 Case When c.ERC_Id In (@PerformanceCategory, @OutsideAreaCategory, @UnavailableCategory) Then 1 Else 0 End 
 	  	  	  	  	 from #Details d
 	  	  	  	  	 Join Timed_Event_Details ted on ted.tedet_Id = d.tedet_Id
 	  	  	  	  	 Left Outer Join Event_Reason_Category_Data c on c.Event_Reason_Tree_Data_Id = ted.Event_Reason_Tree_Data_Id
 	  	  	  	 Declare @DuplicateTable Table (Tedet_Id int, Row_Count int, ERC_ID int)
 	  	  	  	 -- Find Downtime rows with more than one Category
 	  	  	  	 insert into @DuplicateTable(Tedet_Id, row_count)
 	  	  	  	  	 Select tedet_Id, Count(*) [RowCount]
 	  	  	  	  	 From @CleanupTable
 	  	  	  	  	 group by tedet_Id
 	  	  	  	 update DT
 	  	  	  	  	 Set DT.ERC_Id = CT.ERC_ID
 	  	  	  	  	 From @CleanupTable CT
 	  	  	  	  	 Join @DuplicateTable DT on DT.TEDET_Id = CT.TEDET_Id
 	 
 	  	  	  	 -- update ERC_ID for those downtime events that only have one category
 	  	  	  	 -- NOTE::I might not need to do this...
 	  	  	  	 update D1
 	  	  	  	  	 Set D1.ERC_ID = DT.ERC_ID
 	  	  	  	  	 From @DuplicateTable DT
 	  	  	  	  	 Join #Details D1 on D1.TEDET_Id = DT.TEDET_Id
 	  	  	  	  	 Where DT.Row_Count = 1
 	  	  	  	 Delete from @DuplicateTable where row_count > 1 
 	  	  	  	 Delete From @CleanupTable where tedet_Id in (select Tedet_Id from @DuplicateTable)
 	  	  	  	 -- Find the rows that belong in one of the three categories below.  They are needed later
 	  	  	  	 Delete from @DuplicateTable
 	  	  	  	 Update @CleanupTable Set 
 	  	  	  	  	 Flag = Case When ERC_Id In (@PerformanceCategory, @OutsideAreaCategory, @UnavailableCategory) Then 1 Else 0 End
 	  	  	  	 -- which rows belong to a key category
 	  	  	  	 Insert into @DuplicateTable(Tedet_Id)
 	  	  	  	  	 Select Tedet_Id From @CleanupTable Where Flag = 1
 	  	  	  	 -- Keep the individual downtime rows that belong to the three performance catetories and delete rows with a different category
 	  	  	  	 Delete From @CleanupTable
 	  	  	  	 Where Flag = 0
 	  	  	  	  	 AND Tedet_Id in (select Tedet_Id From @DuplicateTable)
 	  	  	  	 update det
 	  	  	  	  	 Set det.ERC_Id = CT.ERC_ID
 	  	  	  	  	 From @CleanupTable CT
 	  	  	  	  	 Join #Details det on det.tedet_id = ct.tedet_Id
 	  	  	  	 
 	  	  	  	 -- Step 1. Reset the uptime based on all of the downtime events returned from the initial query 	  	  	  	 
 	  	  	  	 Update  d1
 	  	  	  	  	 Set d1.TimePreviousFailure = DateDiff(s, d2.EndTime, d1.timestamp)
 	  	  	  	  	 From #Details d2
 	  	  	  	  	 Join #Details d1 on d1.id = (d2.id + 1)
 	  	  	  	 update #Details
 	  	  	  	  	 set TimePreviousFailure = Datediff(s, @OldDowntimeEnd, Timestamp)
 	  	  	  	  	 where id = 1
 	  	  	  	 -- Step 2. Update the "UpTime" of the events we're going to keep 
 	  	  	  	 -- initialize tables
 	  	  	  	 delete from @data2
 	  	  	  	 delete from @data3
 	  	  	  	 -- Setting the Flag tells me which rows to keep summary information in
 	  	  	  	 Update #Details
 	  	  	  	  	 Set Flag = case when ERC_Id not in (@PerformanceCategory, @OutsideAreaCategory, @UnavailableCategory) Then 0 Else 1 End
 	  	  	  	 -- Identify the rows that will be summary rows
 	  	  	  	 Insert into @data2(id_finish)
 	  	  	  	  	 select id from #Details where flag = 0
 	  	  	  	 -- Get the start and end row ranges for the summary rows
 	  	  	  	 Update  d1
 	  	  	  	  	 Set d1.id_start = d2.id_finish
 	  	  	  	  	 From @data2 d2
 	  	  	  	  	 Join @data2 d1 on d1.id = (d2.id + 1)
 	  	  	  	 update @data2 set id_start = 0 where id_start is null
 	  	  	  	 -- Update the #Details table with parent id.
 	  	  	  	 -- This will help identify which rows to group together under which parent
 	  	  	  	 update d1
 	  	  	  	  	 set parent = d2.id_finish
 	  	  	  	  	 from @data2 d2
 	  	  	  	  	 join #Details d1 on d1.id > d2.id_start and d1.id <= d2.id_finish
 	  	  	 
 	  	  	  	 -- Sum all child and parent rows
 	  	  	  	 insert into @data3(id, amount)
 	  	  	  	  	 select d2.id_finish, Sum(d1.TimePreviousFailure)
 	  	  	  	  	 from #Details d1
 	  	  	  	  	 join @data2 d2 on d1.parent = d2.id_finish
 	  	  	  	  	 Group By parent, d2.id_finish
 	  	  	  	 -- Update #Details with the summary data
 	  	  	  	 update d1
 	  	  	  	  	 set d1.TimePreviousFailure = d3.amount
 	  	  	  	  	 from @data3 d3
 	  	  	  	  	 join #Details d1 on d1.id = d3.id
 	  	  	  	 
 	  	  	  	 -- Step 3. Remove Unwanted Downtime By Category
 	  	  	  	 Delete From #Details Where ERC_id in (@PerformanceCategory, @OutsideAreaCategory, @UnavailableCategory)
 	  	  	  	 
 	  	  	  	 Insert Into @ProductChanges (ProductId, StartTime, EndTime)
 	  	  	  	   Select Prod_Id, 
 	  	  	  	  	  	  Case When Start_Time < @curStartTime Then @curStartTime Else Start_Time End,
 	  	  	  	  	  	  Case When coalesce(End_Time,dbo.fnServer_CmnGetDate(getutcdate())) > @curEndTime Then @curEndTime Else coalesce(End_Time,dbo.fnServer_CmnGetDate(getutcdate())) End
 	  	  	  	  	 From Production_Starts d
    	  	  	  	  	   Where d.PU_id = @@UnitId and
 	  	   	  	  	  	  	  	   d.Start_Time = (Select Max(t.Start_Time) From Production_Starts t Where t.PU_Id = @@UnitId and t.start_time < @curStartTime) and
 	  	   	  	  	  	  	   ((d.End_Time > @curStartTime) or (d.End_Time is Null))
 	  	  	  	    Union
 	  	  	  	  	 Select Prod_Id, 
 	  	  	  	  	  	  Case When Start_Time < @curStartTime Then @curStartTime Else Start_Time End,
 	  	  	  	  	  	  Case When coalesce(End_Time,dbo.fnServer_CmnGetDate(getutcdate())) > @curEndTime Then @curEndTime Else coalesce(End_Time,dbo.fnServer_CmnGetDate(getutcdate())) End
 	  	  	  	  	 From Production_Starts d
 	  	  	  	  	  	 Where d.PU_id = @@UnitId and
 	  	  	  	  	  	  	   d.Start_Time >= @curStartTime and 
 	  	          	  	  	  	 d.Start_Time < @curEndTime 
 	  	  	  	 If @ProductFilter Is Not Null
 	  	  	  	  	 Begin                    	  	  	  	  	 
 	  	  	  	  	  	 Delete From @ProductChanges Where ProductId <> @ProductFilter
 	  	  	  	  	  	 Delete From #Details Where ProductId <> @ProductFilter
 	  	  	  	  	 End
 	  	  	  	 -- Update Operating Time From Trimmed Production Starts
  	  	  	  	 Select @TotalOperatingTime = @TotalOperatingTime + coalesce((Select sum(datediff(second, StartTime, EndTime))From @ProductChanges),0)
    	  	  	  	 Insert Into @OperatingTime (ProductId, TotalTime)
 	  	  	  	  	 Select ProductId, sum(datediff(second, StartTime, EndTime))
 	  	  	  	  	 From @ProductChanges
 	  	  	  	  	 Group By ProductId
 	  	  	  	 delete from @ProductChanges    
 	  	  	  	 If @CrewFilter Is Not Null
 	  	  	  	  	 Delete From #Details Where Crew <> @CrewFilter 
 	 
 	  	  	  	 If @ShiftFilter is not null
 	  	  	  	  	 delete from #Details where Shift <> @ShiftFilter
 	  	  	  	 -- Add Rows To Summary Resultset
 	  	  	  	 Insert Into  @Summary (Timestamp, EndTime,ProductId,LocationId,Reason1,Reason2,Reason3,Reason4, Duration, TimeToRepair, TimePreviousFailure, Crew,Shift, Fault) 
 	  	  	  	  	 Select Timestamp,
 	  	  	  	  	  	 EndTime,
 	  	  	  	  	  	 ProductId,
 	  	  	  	  	  	 LocationId,
 	  	  	  	  	  	 Reason1,
 	  	  	  	  	  	 Reason2,
 	  	  	  	  	  	 Reason3,
 	  	  	  	  	  	 Reason4,
 	  	  	  	  	  	 Duration, 
 	  	  	  	  	  	 TimeToRepair, 
 	  	  	  	  	  	 TimePreviousFailure, 
 	  	  	  	  	  	 Crew, 
 	  	  	  	  	  	 Shift,
 	  	  	  	  	  	 case when tef.TEFault_Id Is Null then dbo.fnDBTranslate(N'0', 38333, 'Unspecified') Else tef.TEFault_Name End 
 	  	  	  	  	 From #Details
 	  	  	  	  	 Left Outer Join Timed_Event_Fault tef on tef.TEFault_Id = #Details.FaultId 
 	  	  	  	 Select @TotalDownTime = @TotalDownTime + coalesce((Select sum(Duration) From #Details),0)
 	  	  	     truncate Table #Details
 	  	  	  	 GOTO BEGIN_TIME_CURSOR
 	  	  	 End
 	  	 Close TIME_CURSOR
 	  	 Deallocate TIME_CURSOR
 	  	 
 	  	 Fetch Next From Unit_Cursor Into @@UnitId
 	 End
Close Unit_Cursor
Deallocate Unit_Cursor  
--*********************************************************************************
-- Return Resultset #0 - Resultset Name List
--*********************************************************************************
Declare @Resultsets Table
(
 	 ResultSetName 	  	 varchar(50),
 	 ResultSetTabName 	 varchar(50),
 	 ParameterName 	  	 varchar(50),
 	 ParameterUnits 	  	 varchar(50) NULL,
 	 DataColumns 	  	  	 varchar(50) NULL,
 	 LabelColumns 	  	 varchar(50) NULL,
 	 IconDesc 	  	  	 varchar(1000) NULL,
 	 Stacked 	  	  	  	 int NULL,
 	 RS_ID 	  	  	  	 int
)
insert into @Resultsets values (null,dbo.fnDBTranslate(N'0', 38480, 'Operating Downtime Distribution'), 'red', NULL, NULL, NULL, NULL, NULL, NULL)
If @LocationFilter Is Null
 	 insert into @Resultsets values ('LocationPareto', dbo.fnDBTranslate(N'0', 38335, 'Location'), '38246', dbo.fnDBTranslate(N'0', 38339, 'Minutes'), '2','1',null,0, 1)
If @FaultFilter Is Null
  insert into @Resultsets values ('FaultPareto', dbo.fnDBTranslate(N'0', 38336, 'Fault'), '38247', dbo.fnDBTranslate(N'0', 38339, 'Minutes'), '2','1', NULL,0, 2)
If @ReasonFilter1 Is Null and @Level1Name Is Not Null
  insert into @Resultsets values ('Reason1Pareto', @Level1Name, '38248', dbo.fnDBTranslate(N'0', 38339, 'Minutes'), '2','1',NULL, 0,3)
If @ReasonFilter2 Is Null and @Level2Name Is Not Null
  insert into @Resultsets values ('Reason2Pareto', @Level2Name, '38249', dbo.fnDBTranslate(N'0', 38339, 'Minutes'), 2,1,NULL,0,4)
If @ReasonFilter3 Is Null and @Level3Name Is Not Null
  insert into @Resultsets values ('Reason3Pareto', @Level3Name, '38250', dbo.fnDBTranslate(N'0', 38339, 'Minutes'), 2,1,NULL,0,5)
If @ReasonFilter4 Is Null and @Level4Name Is Not Null
  insert into @Resultsets values ('Reason4Pareto', @Level4Name, '38251', dbo.fnDBTranslate(N'0', 38339, 'Minutes'), 2,1,NULL,0,6)
If @ProductFilter Is Null
  insert into @Resultsets values ('ProductPareto', dbo.fnDBTranslate(N'0', 38337, 'Product'), '38244', dbo.fnDBTranslate(N'0', 38339, 'Minutes'),'2','1',NULL,0, 7)
If @CrewFilter Is Null
  insert into @Resultsets values ('CrewPareto', dbo.fnDBTranslate(N'0', 38338, 'Crew'), '38245', dbo.fnDBTranslate(N'0', 38339, 'Minutes'), 2,1,NULL,0,8)
IF @ShiftFilter Is NULL
  insert into @Resultsets values ('ShiftPareto', dbo.fnDBTranslate(N'0', 38479, 'Shift'), '38477', dbo.fnDBTranslate(N'0', 38339, 'Minutes'), 2,1,NULL,0,9)
/*********************************************************************************
Results
********************************************************************************/
Create Table #Results 
(
 	 Id 	  	  	  	 int NULL,
 	 Name 	  	  	 varchar(100) NULL,
 	 Total 	  	  	 float NULL,
 	 MTTR 	  	  	 float NULL,
 	 MTBF 	  	  	 float NULL,
 	 PercentTotal 	 float NULL,
 	 NumberOfEvents 	 int NULL 
)
--*********************************************************************************
-- Return Resultset #1 - Location Pareto
--*********************************************************************************
create table #ResultSet1 
(
 	 LocationId 	  	 int NULL,
 	 LocationDesc 	 varchar(50),
 	 Total 	  	  	 real NULL,
 	 MTTR 	  	  	 varchar(50),
 	 MTBF 	  	  	 varchar(50),
 	 [% Total] 	  	 real NULL,
 	 [# Events] 	  	 real NULL,
 	 rs_id 	  	  	 int
) 	  	 
If @LocationFilter Is Null
  Begin
    Truncate Table #Results
    Insert Into #Results (Id, Total,          MTTR,                MTBF, PercentTotal, NumberOfEvents)
      Select LocationId, sum(Duration), Avg(TimeToRepair), avg(TimePreviousFailure) / 60.0, sum(Duration) / convert(real,@TotalDowntime), Count(Duration)
        From @Summary
        Group By LocationId
 	 Insert into #ResultSet1 (LocationId, LocationDesc, Total, MTTR, MTBF, [% Total], [# Events], rs_id) 
 	  	 select r.Id, coalesce(u.pu_desc, dbo.fnDBTranslate(N'0', 38333, 'Unspecified')),
 	  	 Total, dbo.fnMinutesToTime(r.MTTR), dbo.fnMinutesToTime(r.MTBF), r.PercentTotal*100.0, r.NumberOfEvents, 1
 	  	 from #Results r left outer join Prod_Units u on u.pu_id = r.Id
  End
/**********************************************************
ResultSet2
*********************************************************/
create table #ResultSet2 
(
 	 FaultId 	  	  	 int NULL,
 	 FaultDesc 	  	 varchar(50),
 	 Total 	  	  	 real NULL,
 	 MTTR 	  	  	 varchar(50),
 	 MTBF 	  	  	 varchar(50),
 	 [% Total] 	  	 real NULL,
 	 [# Events] 	  	 real NULL,
 	 rs_id 	  	  	 int
)
If @FaultFilter Is Null
 	 Begin
 	     Truncate Table #Results
 	 
 	     Insert Into #Results (Name, Total, MTTR, MTBF, PercentTotal, NumberOfEvents)
 	       Select Fault, sum(Duration), Avg(TimeToRepair), avg(TimePreviousFailure) / 60.0,sum(Duration) / convert(real,@TotalDowntime), Count(Duration)
 	         From @Summary
 	         Group By Fault
 	 
 	 
 	  	 Insert into #ResultSet2 (FaultId, FaultDesc, Total, MTTR, MTBF, [% Total], [# Events], rs_id) 
 	  	  	 select NULL, coalesce(r.Name, dbo.fnDBTranslate(N'0', 38333, 'Unspecified')),
  	  	  	 Total, dbo.fnMinutesToTime(r.MTTR), dbo.fnMinutesToTime(r.MTBF), r.PercentTotal*100.0, r.NumberOfEvents, 2
 	  	  	 from #Results r
 	 End
select @RowCount = (select count(rs_id) from #ResultSet2)
if @RowCount = 0
begin
 	 delete from @Resultsets where ResultSetName = 'FaultPareto'
end
/**********************************************************
ResultSet3
*********************************************************/
create table #ResultSet3
(
 	 Id 	  	  	 int NULL,
 	 Level1Name 	 varchar(50),
 	 Total 	  	 real,
 	 MTTR 	  	 varchar(50),
 	 MTBF 	  	 varchar(50),
 	 [% Total] 	 real,
 	 [# Events] 	 real,    
 	 rs_id 	  	 int
)
If @ReasonFilter1 Is Null and @Level1Name Is Not Null
 	 Begin
 	     Truncate Table #Results
 	 
 	     Insert Into #Results (Id, Total, MTTR, MTBF, PercentTotal, NumberOfEvents)
 	       Select Reason1, sum(Duration), Avg(TimeToRepair), avg(TimePreviousFailure) / 60.0,sum(Duration) / convert(real,@TotalDowntime), Count(Duration)
 	         From @Summary
 	         Group By Reason1
 	 
 	 
 	  	 Insert into #ResultSet3 (Id, Level1Name, Total, MTTR, MTBF, [% Total], [# Events], rs_id) 
 	  	  	 select r.id, coalesce(n.event_reason_name,dbo.fnDBTranslate(N'0', 38333, 'Unspecified')), Total, dbo.fnMinutesToTime(r.MTTR), dbo.fnMinutesToTime(r.MTBF),r.PercentTotal*100.0, r.NumberOfEvents, 3
 	  	  	 From #Results r left outer join Event_Reasons n on n.event_reason_id = r.Id  	  	  	 
 	 End
select @RowCount = (select count(rs_id) from #ResultSet3)
if @RowCount = 0
begin
 	 delete from @Resultsets where ResultSetName = 'Reason1Pareto'
end
/**********************************************************
ResultSet4
*********************************************************/
create table #ResultSet4
(
 	 Id 	  	  	 int NULL,
 	 Level2Name 	 varchar(50),
 	 Total 	  	 real,
 	 MTTR 	  	 varchar(50),
 	 MTBF 	  	 varchar(50),
 	 [% Total] 	 real,
 	 [# Events] 	 real,    
 	 rs_id 	  	 int
)
If @ReasonFilter2 Is Null and @Level2Name Is Not Null
 	 Begin
 	     Truncate Table #Results
 	 
 	     Insert Into #Results (Id, Total, MTTR, MTBF, PercentTotal, NumberOfEvents)
 	       Select Reason2, sum(Duration), Avg(TimeToRepair), avg(TimePreviousFailure) / 60.0 ,sum(Duration) / convert(real,@TotalDowntime), Count(Duration)
 	         From @Summary
 	         Group By Reason2
 	 
 	 
 	  	 Insert into #ResultSet4 (Id, Level2Name, Total, MTTR, MTBF, [% Total], [# Events], rs_id) 
 	  	  	 select r.id, coalesce(n.event_reason_name,dbo.fnDBTranslate(N'0', 38333, 'Unspecified')), Total, dbo.fnMinutesToTime(r.MTTR), dbo.fnMinutesToTime(r.MTBF),r.PercentTotal*100.0, r.NumberOfEvents, 4
 	  	  	 From #Results r left outer join Event_Reasons n on n.event_reason_id = r.Id  	  	  	 
 	 End
select @RowCount = (select count(rs_id) from #ResultSet4)
if @RowCount = 0
begin
 	 delete from @Resultsets where ResultSetName = 'Reason2Pareto'
end
/**********************************************************
ResultSet5
*********************************************************/
create table #ResultSet5
(
 	 Id 	  	  	 int NULL,
 	 Level3Name 	 varchar(50),
 	 Total 	  	 real,
 	 MTTR 	  	 varchar(50),
 	 MTBF 	  	 varchar(50),
 	 [% Total] 	 real,
 	 [# Events] 	 real,    
 	 rs_id 	  	 int
)
If @ReasonFilter3 Is Null and @Level3Name Is Not Null
  Begin
 	     Truncate Table #Results
 	 
 	     Insert Into #Results (Id, Total, MTTR, MTBF, PercentTotal, NumberOfEvents)
 	       Select Reason3, sum(Duration), Avg(TimeToRepair), avg(TimePreviousFailure) / 60.0,sum(Duration) / convert(real,@TotalDowntime), Count(Duration)
 	         From @Summary
 	         Group By Reason3
 	     
 	  	 Insert into #ResultSet5 (Id, Level3Name, Total, MTTR, MTBF, [% Total], [# Events], rs_id) 
 	  	  	 select r.id, coalesce(n.event_reason_name,dbo.fnDBTranslate(N'0', 38333, 'Unspecified')), Total, dbo.fnMinutesToTime(r.MTTR), dbo.fnMinutesToTime(r.MTBF),r.PercentTotal*100.0, r.NumberOfEvents, 5
 	  	  	 From #Results r left outer join Event_Reasons n on n.event_reason_id = r.Id  	  	  	 
  End
select @RowCount = (select count(rs_id) from #ResultSet5)
if @RowCount = 0
begin
 	 delete from @Resultsets where ResultSetName = 'Reason3Pareto'
end
/**********************************************************
ResultSet6
*********************************************************/
create table #ResultSet6
(
 	 Id 	  	  	 int NULL,
 	 Level4Name 	 varchar(50),
 	 Total 	  	 real,
 	 MTTR 	  	 varchar(50),
 	 MTBF 	  	 varchar(50),
 	 [% Total] 	 real,
 	 [# Events] 	 real,    
 	 rs_id 	  	 int
)
If @ReasonFilter4 Is Null and @Level4Name Is Not Null
 	 Begin
 	     Truncate Table #Results
 	 
 	     Insert Into #Results (Id, Total, MTTR, MTBF, PercentTotal, NumberOfEvents)
 	       Select Reason4, sum(Duration), Avg(TimeToRepair), avg(TimePreviousFailure) / 60.0,sum(Duration) / convert(real,@TotalDowntime), Count(Duration)
 	         From @Summary
 	         Group By Reason4
 	 
 	 
 	  	 Insert into #ResultSet6 (Id, Level4Name, Total, MTTR, MTBF, [% Total], [# Events], rs_id) 
 	  	  	 select r.id, coalesce(n.event_reason_name,dbo.fnDBTranslate(N'0', 38333, 'Unspecified')), Total, dbo.fnMinutesToTime(r.MTTR), dbo.fnMinutesToTime(r.MTBF),r.PercentTotal*100.0, r.NumberOfEvents, 6
 	  	  	 From #Results r left outer join Event_Reasons n on n.event_reason_id = r.Id  	  	  	     
 	 End
select @RowCount = (select count(rs_id) from #ResultSet6)
if @RowCount = 0
begin
 	 delete from @Resultsets where ResultSetName = 'Reason4Pareto'
end
/**********************************************************
ResultSet7
*********************************************************/
create table #ResultSet7
(
 	 Id 	  	  	 int,
 	 Product 	  	 varchar(50),
 	 Total 	  	 real,
 	 MTTR 	  	 varchar(50),
 	 MTBF 	  	 varchar(50),
 	 [% Fault] 	 real,
 	 [% Total] 	 real,
 	 [# Events] 	 real,    
 	 rs_id 	  	 int 	  	 
)
-- Return % Operating Time By Product
Create Table #IntegerResults (
 	 ID     	  	 int NULL,
 	 Value  	  	 int NULL
)
If @ProductFilter Is Null
 	 Begin
 	     Truncate Table #Results
 	  	  	  	 
 	  	 Insert Into #IntegerResults (Id, Value)
 	  	  	 Select ProductId, sum(TotalTime)
 	  	  	 From @OperatingTime
 	  	  	 Group By ProductId 
 	  	  	 
 	 
 	     Insert Into #Results (Id, Total, MTTR, MTBF, PercentTotal, NumberOfEvents)
 	       Select ProductId, sum(Duration), Avg(TimeToRepair), avg(TimePreviousFailure) / 60.0,  sum(Duration) / convert(real,@TotalDowntime), Count(Duration)
 	         From @Summary
 	         Group By ProductId
 	 
 	 
 	  	 Insert into #ResultSet7 (Id, Product, Total, MTTR, MTBF, [% Fault], [% Total],[# Events], rs_id) 
 	  	  	 select r.id, p.prod_code, Total, dbo.fnMinutesToTime(r.MTTR),dbo.fnMinutesToTime(((i.value/60.0) - r.Total) / r.NumberOfEvents),r.Total / (i.value/60.0) * 100.0, r.PercentTotal*100.0, r.NumberOfEvents, 7
 	  	  	 From #Results r join Products p on p.prod_id = r.Id left outer join #IntegerResults i on i.Id = r.Id  	  	  	 
 	 End
select @RowCount = (select count(rs_id) from #ResultSet7)
if @RowCount = 0
begin
 	 delete from @Resultsets where ResultSetName = 'ProductPareto'
end
/**********************************************************
ResultSet8 - Crew
*********************************************************/
create table #ResultSet8
(
 	 Id 	  	  	 int,
 	 Crew 	  	 varchar(50),
 	 Total 	  	 real,
 	 MTTR 	  	 varchar(50),
 	 MTBF 	  	 varchar(50),
 	 [% Total] 	 real,
 	 [# Events] 	 real,    
 	 rs_id 	  	 int 	  	 
)
create table #crewtimes
(
 	 Crew  	  	  	  	  	 varchar(50),
 	 Shift 	  	  	  	  	 varchar(50),
 	 duration  	  	  	  	 real,
 	 timetorepair  	  	  	 real,
 	 timepreviousfailure 	  	 real,
 	 CountForEvent 	  	  	 int,
)
Declare @ResultSet9 TABLE
(
 	 Id 	  	  	 int,
 	 [Shift] 	  	 varchar(50),
 	 Total 	  	 real,
 	 MTTR 	  	 varchar(50),
 	 MTBF 	  	 varchar(50),
 	 [% Total] 	 real,
 	 [# Events] 	 real,    
 	 rs_id 	  	 int 	  	 
)
Declare @Local_Crew_Schedule TABLE (PU_ID int, Start_Time datetime, End_Time datetime, Crew_Desc varchar(20), Shift_Desc varchar(20), Duration int, tpf real, ttr real, PercentResponsible real, CountForEvent int)
Declare @LocalTotalCrewDowntime real, @ShiftRowCount int
declare @crewdesc varchar(50), @downtimestart datetime, @downtimeend datetime, @downtimeunitid int, @cduration real, @tpf real, @ttr real
declare @crewstart datetime, @crewend datetime, @duration real, @percent real
If @CrewFilter Is Null
 	 Begin
     	 Truncate Table #Results
 	  	 Declare Crew_CURSOR INSENSITIVE CURSOR
 	  	 For ( Select crew, TimeStamp, EndTime, TimeToRepair, TimePreviousFailure, Duration, LocationId From @Summary )
 	  	 For Read Only
 	  	 Open CREW_CURSOR  
 	  	 BEGIN_CREW_CURSOR:
 	  	 Fetch Next From CREW_CURSOR Into @crewdesc, @downtimestart, @downtimeend, @ttr, @tpf, @cduration, @downtimeunitid
 	  	 While @@Fetch_Status = 0
 	  	  	 Begin
 	  	  	  	 Delete From @Local_Crew_Schedule
 	  	  	  	 -- Determine which crews were involved with this Downtime Event
 	  	  	  	 Insert Into @Local_Crew_Schedule(PU_ID, Start_Time, End_Time, Crew_Desc, Shift_Desc, CountForEvent)
 	  	  	  	  	 Select @DowntimeUnitId, Start_Time, End_Time, Crew_Desc, Shift_Desc, Case When @DowntimeStart <= End_Time and @DowntimeStart > Start_Time Then 1 Else 0 End  
 	  	  	  	  	 From @Crew_Schedule 
 	  	  	  	  	 where PU_ID = @DowntimeUnitId AND @DowntimeStart <= End_Time AND @DowntimeEnd > Start_Time
 	  	  	  	 -- How many Crews were involved
 	  	  	  	 Select @ShiftRowCount = @@RowCount
 	  	  	  	 -- Remove any that are outside the report window
 	  	  	  	 If @ShiftRowCount > 1
 	  	  	  	  	 Begin
 	  	  	  	  	  	 -- Remove any Crews that ended before the report window or started afterward
 	  	  	  	  	  	 Delete From @Local_Crew_Schedule where End_Time <= @StartTime
 	  	  	  	  	  	 Delete From @Local_Crew_Schedule where Start_Time >= @EndTime
 	  	  	  	  	 End
 	  	  	  	 -- How many crews are left?
 	  	  	  	 Select @ShiftRowCount = Count(*) From @Local_Crew_Schedule
 	  	  	  	 -- Trim Start and End Times for the crews
 	  	  	  	 update @Local_Crew_Schedule Set Start_Time = @StartTime where Start_Time < @StartTime
 	  	  	  	 update @Local_Crew_Schedule Set End_Time = @EndTime where End_Time > @EndTime
 	  	  	  	 
 	  	  	  	 If @ShiftRowCount = 1
 	  	  	  	  	 Begin
 	  	  	  	  	  	 -- This Crew/Shift is fully responsible for this downtime event
 	  	  	  	  	  	 update @Local_Crew_Schedule Set Duration=@cduration, ttr=@ttr, tpf=@tpf
 	  	  	  	  	 End
 	  	  	  	 Else
 	  	  	  	  	 Begin
 	  	  	  	  	  	 -- Pro-rate responsibility among various Crew/Shift
 	  	  	  	  	  	 Update @Local_Crew_Schedule SET
 	  	  	  	  	  	  	 Duration = (DateDiff(s, (Case When @DowntimeStart < Start_Time then Start_Time else @DowntimeStart end), (Case When @DowntimeEnd > End_Time then End_Time else @DowntimeEnd End)) / 60.0),
 	  	  	  	  	  	  	 PercentResponsible = (DateDiff(s, (Case When @DowntimeStart < Start_Time then Start_Time else @DowntimeStart end), (Case When @DowntimeEnd < End_Time then @DowntimeEnd else End_Time End)) / 60.0) / (datediff(s, @DowntimeStart, @DowntimeEnd) / 60.0),
 	  	  	  	  	  	  	 tpf = (@tpf * (DateDiff(s, (Case When @DowntimeStart < Start_Time then Start_Time else @DowntimeStart end), (Case When @DowntimeEnd < End_Time then @DowntimeEnd else End_Time End)) / 60.0) / (datediff(s, @DowntimeStart, @DowntimeEnd) / 60.0)),
 	  	  	  	  	  	  	 ttr = (@ttr * (DateDiff(s, (Case When @DowntimeStart < Start_Time then Start_Time else @DowntimeStart end), (Case When @DowntimeEnd < End_Time then @DowntimeEnd else End_Time End)) / 60.0) / (datediff(s, @DowntimeStart, @DowntimeEnd) / 60.0))
 	  	  	  	  	 End
 	  	  	  	 
 	  	  	  	 Insert Into #CrewTimes(Crew, Shift, Duration, TimeToRepair, TimePreviousFailure, CountForEvent) 
 	  	  	  	  	 Select Crew_Desc, Shift_Desc, Duration, ttr, tpf, CountForEvent from @Local_Crew_Schedule
 	  	  	  	 GOTO BEGIN_CREW_CURSOR
 	  	  	 End
 	  	 Close CREW_CURSOR
 	  	 Deallocate CREW_CURSOR
 	  	 delete from #crewtimes where duration = 0
 	  	 -- Get Total Downtime Duration covered by Shifts and Crews
 	  	 select @LocalTotalCrewDowntime = Sum(Duration) from #CrewTimes
 	  	 Insert Into #Results (Name, Total, MTTR, MTBF, PercentTotal, NumberOfEvents)
 	  	  	 Select Crew, sum(Duration), Avg(TimeToRepair), avg(TimePreviousFailure) / 60.0, sum(Duration) / convert(real,@LocalTotalCrewDowntime), sum(CountForEvent)
 	  	  	 From #crewtimes
 	  	  	 Group By Crew
 	  	 Insert into #ResultSet8 (Id, Crew, Total, MTTR, MTBF, [% Total], [# Events], rs_id) 
 	  	  	 select NULL, coalesce(r.name,dbo.fnDBTranslate(N'0', 38333, 'Unspecified')), Total, dbo.fnMinutesToTime(r.MTTR), dbo.fnMinutesToTime(r.MTBF),r.PercentTotal*100.0, r.NumberOfEvents, 8
 	  	  	 From #Results r  	  	  	 
 	  	 Delete From #Results
 	  	 -- Shift data is exactly the same except for the Group By
 	  	 Insert Into #Results (Name, Total, MTTR, MTBF, PercentTotal, NumberOfEvents)
 	  	  	 Select Shift, sum(Duration), Avg(TimeToRepair), avg(TimePreviousFailure) / 60.0, sum(Duration) / convert(real,@LocalTotalCrewDowntime), sum(CountForEvent)
 	  	  	 From #crewtimes
 	  	  	 Group By Shift
 	  	 Insert into @ResultSet9 (Id, Shift, Total, MTTR, MTBF, [% Total], [# Events], rs_id) 
 	  	  	 select NULL, coalesce(r.name,dbo.fnDBTranslate(N'0', 38333, 'Unspecified')), Total, dbo.fnMinutesToTime(r.MTTR), dbo.fnMinutesToTime(r.MTBF),r.PercentTotal*100.0, r.NumberOfEvents, 9
 	  	  	 From #Results r  	  	  	 
  End
select @RowCount = (select count(rs_id) from #ResultSet8)
if @RowCount = 0
begin
 	 delete from @Resultsets where ResultSetName = 'CrewPareto'
end
/**********************************************************
ResultSet9 - Shift
*********************************************************/
create table #ResultSet9
(
 	 Id 	  	  	 int,
 	 [Shift] 	  	 varchar(50),
 	 Total 	  	 real,
 	 MTTR 	  	 varchar(50),
 	 MTBF 	  	 varchar(50),
 	 [% Total] 	 real,
 	 [# Events] 	 real,    
 	 rs_id 	  	 int 	  	 
)
create table #shifttimes
(
 	 Shift  	  	  	  	  	 varchar(50),
 	 duration  	  	  	  	 real,
 	 timetorepair  	  	  	 real,
 	 timepreviousfailure 	  	 real
)
declare @shiftdesc varchar(50)
declare @shiftstart datetime, @shiftend datetime
If @ShiftFilter Is Null
 	 Begin
 	  	 Insert into #ResultSet9
 	  	 Select * from @ResultSet9 
 	  	 Truncate Table #Results
/*
 	  	 Declare SHIFT_CURSOR INSENSITIVE CURSOR
 	  	 For ( Select shift, TimeStamp, EndTime, TimeToRepair, TimePreviousFailure, Duration, LocationId From @Summary )
 	  	 For Read Only
 	  	 Open SHIFT_CURSOR  
 	  	 
 	  	 BEGIN_SHIFT_CURSOR:
 	  	 Fetch Next From SHIFT_CURSOR Into @shiftdesc, @downtimestart, @downtimeend, @ttr, @tpf, @cduration, @downtimeunitid
 	  	 While @@Fetch_Status = 0
 	  	  	 Begin    
 	  	  	  	 Select @shiftstart=@StartTime, @shiftend=@EndTime
 	  	  	  	 Delete From @Local_Crew_Schedule
 	  	  	  	 Insert Into @Local_Crew_Schedule(Start_Time, End_Time, Crew_Desc, Shift_Desc)
 	  	  	  	  	 Select Start_Time, End_Time, Crew_Desc, Shift_Desc From Crew_Schedule where PU_ID = @DowntimeUnitId AND @DowntimeStart <= End_Time AND @DowntimeEnd > Start_Time
 	  	  	  	 Select @ShiftRowCount = @@RowCount
 	  	  	  	 If @ShiftRowCount > 1
 	  	  	  	  	 Begin
 	  	  	  	  	  	 -- Remove any Crews that ended before the report window or started afterward
 	  	  	  	  	  	 Delete From @Local_Crew_Schedule where End_Time <= @StartTime
 	  	  	  	  	  	 Delete From @Local_Crew_Schedule where Start_Time >= @EndTime
 	  	  	  	  	  	 
 	  	  	  	  	  	 -- Exactly how many rows are there?
 	  	  	  	  	 End
 	  	  	  	 select @shiftstart = start_time, @ShiftEnd = end_time, @ShiftDesc = Shift_Desc from @Local_Crew_Schedule 
 	  	  	  	 where @downtimestart between start_time and end_time or @DowntimeEnd Between Start_Time and End_Time
 	  	  	  	 if (@shiftstart < @StartTime) 
 	  	  	  	  	 select @shiftstart = @StartTime
 	  	  	  	 if (@shiftend > @Endtime)
 	  	  	  	  	 select @shiftend = @EndTime
 	  	  	  	 if (@downtimestart < @StartTime) 
 	  	  	  	  	 select @downtimestart = @StartTime
 	  	  	  	 if (@downtimeend > @EndTime)
 	  	  	  	  	 select @downtimeend = @EndTime
 	  	  	  	 if (@shiftstart <= @downtimestart and @shiftend >= @downtimeend)
 	  	  	  	  	 begin
 	  	  	  	  	  	 insert into #shifttimes (shift, duration, timetorepair, timepreviousfailure) values (@shiftdesc, @cduration, @ttr, @tpf)
 	  	  	  	  	 end 	 
 	  	      	 else
 	  	  	  	  	 begin
 	  	  	  	  	  	 select @duration = datediff(second, @downtimestart, @shiftend)
 	  	  	  	  	  	 select @percent = @duration / (@cduration * 60)
 	  	  	  	  	  	 insert into #shifttimes (shift, duration, timetorepair, timepreviousfailure) 
 	  	  	  	  	  	  	 values (@shiftdesc, @cduration * @percent, @ttr * @percent, @tpf * @percent)
 	  	  	  	  	  	 select @cduration = @cduration - (@cduration * @percent)
 	  	  	  	  	  	 select @ttr = @ttr - (@ttr * @percent)
 	  	  	  	  	  	 select @tpf = @tpf - (@tpf * @percent)
 	 
 	  	  	  	  	  	 select @downtimestart = @shiftend
 	  	  	  	  	  	 while (@downtimestart < @downtimeend)
 	  	  	  	  	  	  	 begin
 	  	  	  	  	  	  	  	 Select @ShiftDesc=NULL, @ShiftStart=NULL, @ShiftEnd=NULL
 	  	  	  	  	  	  	  	 select @shiftdesc = shift_desc, @shiftstart = start_time, @shiftend = end_time from crew_schedule 
 	  	  	  	  	  	  	  	 where @DowntimeStart < End_Time And @DowntimeStart >= Start_Time AND PU_ID = @DowntimeUnitId
 	  	  	  	  	  	  	  	 if (@shiftstart <= @downtimestart and @shiftend >= @downtimeend)
 	  	  	  	  	  	  	  	  	 begin
 	  	  	  	  	  	  	  	  	  	 insert into #shifttimes (shift, duration, timetorepair, timepreviousfailure) values (@shiftdesc, @cduration, @ttr, @tpf)
 	  	  	  	  	  	  	  	  	  	 select @downtimestart = @downtimeend
 	  	  	  	  	  	  	  	  	 end 	 
 	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	 begin
 	  	  	  	  	  	  	  	  	  	 select @duration = datediff(second, @downtimestart, @shiftend)
 	  	  	  	  	  	  	  	  	  	 select @percent = @duration / (@cduration * 60)
 	  	  	  	  	  	  	  	  	  	 insert into #shifttimes (shift, duration, timetorepair, timepreviousfailure) values (@shiftdesc, @cduration * @percent, @ttr * @percent, @tpf * @percent)
 	  	  	  	  	  	  	  	  	  	 select @cduration = @cduration - (@cduration * @percent)
 	  	  	  	  	  	  	  	  	  	 select @ttr = @ttr - (@ttr * @percent)
 	  	  	  	  	  	  	  	  	  	 select @tpf = @tpf - (@tpf * @percent)
 	  	  	  	  	 
 	  	  	  	  	  	  	  	  	  	 select @downtimestart = @shiftend
 	  	  	  	  	  	  	  	  	 end
 	  	  	  	  	  	  	 end
 	  	  	  	  	 end
 	  	  	  	 GOTO BEGIN_SHIFT_CURSOR
 	  	  	 End
 	  	 Close SHIFT_CURSOR
 	  	 Deallocate SHIFT_CURSOR
 	 delete from #shifttimes where duration = 0
 	 Insert Into #Results (Name, Total, MTTR, MTBF, PercentTotal, NumberOfEvents)
 	  	 Select Shift, sum(Duration), Avg(TimeToRepair), avg(TimePreviousFailure) / 60.0,sum(Duration) / convert(real,@TotalDowntime), Count(Duration)
 	  	 From #shifttimes
 	  	 Group By shift
 	  	 insert into #ResultSet9 (Id, [Shift], Total, MTTR, MTBF, [% Total], [# Events], rs_id) 
 	  	 select NULL, coalesce(r.name,dbo.fnDBTranslate(N'0', 38333, 'Unspecified')), Total, dbo.fnMinutesToTime(r.MTTR), dbo.fnMinutesToTime(r.MTBF),r.PercentTotal*100.0, r.NumberOfEvents, 9
 	  	 From #Results r  	  	  	     
 	 */
End
select @RowCount = (select count(rs_id) from #ResultSet9)
if @RowCount = 0
begin
 	 delete from @Resultsets where ResultSetName = 'ShiftPareto'
end
declare @total int
select @total = max(total) from #resultset1
if @total > 120
begin
  update #resultset1 set total = total / 60
  update @Resultsets set parameterunits = dbo.fnDBTranslate(N'0', 38388, 'Hours') where rs_id = 1
end
select @total = max(total) from #resultset2
if @total > 120
begin
  update #resultset2 set total = total / 60
  update @Resultsets set parameterunits = dbo.fnDBTranslate(N'0', 38388, 'Hours') where rs_id = 2
end
select @total = max(total) from #resultset3
if @total > 120
begin
  update #resultset3 set total = total / 60
  update @Resultsets set parameterunits = dbo.fnDBTranslate(N'0', 38388, 'Hours') where rs_id = 3
end
select @total = max(total) from #resultset4
if @total > 120
begin
  update #resultset4 set total = total / 60
  update @Resultsets set parameterunits = dbo.fnDBTranslate(N'0', 38388, 'Hours') where rs_id = 4
end
select @total = max(total) from #resultset5
if @total > 120
begin
  update #resultset5 set total = total / 60
  update @Resultsets set parameterunits = dbo.fnDBTranslate(N'0', 38388, 'Hours') where rs_id = 5
end
select @total = max(total) from #resultset6
if @total > 120
begin
  update #resultset6 set total = total / 60
  update @Resultsets set parameterunits = dbo.fnDBTranslate(N'0', 38388, 'Hours') where rs_id = 6
end
select @total = max(total) from #resultset7
if @total > 120
begin
  update #resultset7 set total = total / 60
  update @Resultsets set parameterunits = dbo.fnDBTranslate(N'0', 38388, 'Hours') where rs_id = 7
end
select @total = max(total) from #resultset8
if @total > 120
begin
  update #resultset8 set total = total / 60
  update @Resultsets set parameterunits = dbo.fnDBTranslate(N'0', 38388, 'Hours') where rs_id = 8
end
select @total = max(total) from #resultset9
if @total > 120
begin
  update #resultset9 set total = total / 60
  update @Resultsets set parameterunits = dbo.fnDBTranslate(N'0', 38388, 'Hours') where rs_id = 9
end
Select * From @Resultsets
declare @SQL varchar(7000)
select @SQL = 'select LocationId as Id, LocationDesc as [\@' + dbo.fnDBTranslate(N'0', 38345, 'Location') + '], Total as [' + dbo.fnDBTranslate(N'0', 38340, 'Total') + '], MTTR as [' + dbo.fnDBTranslate(N'0', 38341, 'MTTR') + '], MTBF as [' + dbo.fnDBTranslate(N'0', 38342, 'MTBF') + '], [% Total] as [' + dbo.fnDBTranslate(N'0', 38343, '% Total') + '], [# Events] as [' + dbo.fnDBTranslate(N'0', 38344, '# Events') + '], rs_id as rs_id 	 from #ResultSet1 order by Total asc'
exec (@SQL)
select @SQL = 'select FaultId as Id, FaultDesc as [\@' + dbo.fnDBTranslate(N'0', 38336, 'Fault') + '], Total as [' + dbo.fnDBTranslate(N'0', 38340, 'Total') + '], MTTR as [' + dbo.fnDBTranslate(N'0', 38341, 'MTTR') + '], MTBF as [' + dbo.fnDBTranslate(N'0', 38342, 'MTBF') + '], [% Total] as [' + dbo.fnDBTranslate(N'0', 38343, '% Total') + '], [# Events] as [' + dbo.fnDBTranslate(N'0', 38344, '# Events') + '], rs_id as rs_id 	 from #ResultSet2 order by Total asc'
exec (@SQL)
select @SQL = 'select Id as Id, Level1Name as [\@' +   @Level1Name  + '], Total as [' + dbo.fnDBTranslate(N'0', 38340, 'Total') + '], MTTR as [' + dbo.fnDBTranslate(N'0', 38341, 'MTTR') + '], MTBF as [' + dbo.fnDBTranslate(N'0', 38342, 'MTBF') + '], [% Total] as [' + dbo.fnDBTranslate(N'0', 38343, '% Total') + '], [# Events] as [' + dbo.fnDBTranslate(N'0', 38344, '# Events') + '], rs_id as rs_id 	 from #ResultSet3 order by Total asc'
exec (@SQL)
select @SQL = 'select Id as Id, Level2Name as [\@' +  @Level2Name  + '], Total as [' + dbo.fnDBTranslate(N'0', 38340, 'Total') + '], MTTR as [' + dbo.fnDBTranslate(N'0', 38341, 'MTTR') + '], MTBF as [' + dbo.fnDBTranslate(N'0', 38342, 'MTBF') + '], [% Total] as [' + dbo.fnDBTranslate(N'0', 38343, '% Total') + '], [# Events] as [' + dbo.fnDBTranslate(N'0', 38344, '# Events') + '], rs_id as rs_id 	 from #ResultSet4 order by Total asc'
exec (@SQL)
select @SQL = 'select Id as Id, Level3Name as [\@' +   @Level3Name  + '], Total as [' + dbo.fnDBTranslate(N'0', 38340, 'Total') + '], MTTR as [' + dbo.fnDBTranslate(N'0', 38341, 'MTTR') + '], MTBF as [' + dbo.fnDBTranslate(N'0', 38342, 'MTBF') + '], [% Total] as [' + dbo.fnDBTranslate(N'0', 38343, '% Total') + '], [# Events] as [' + dbo.fnDBTranslate(N'0', 38344, '# Events') + '], rs_id as rs_id 	 from #ResultSet5 order by Total asc'
exec (@SQL)
select @SQL = 'select Id as Id, Level4Name as [\@' +  @Level4Name  + '], Total as [' + dbo.fnDBTranslate(N'0', 38340, 'Total') + '], MTTR as [' + dbo.fnDBTranslate(N'0', 38341, 'MTTR') + '], MTBF as [' + dbo.fnDBTranslate(N'0', 38342, 'MTBF') + '], [% Total] as [' + dbo.fnDBTranslate(N'0', 38343, '% Total') + '], [# Events] as [' + dbo.fnDBTranslate(N'0', 38344, '# Events') + '], rs_id as rs_id 	 from #ResultSet6 order by Total asc'
exec (@SQL)
select @SQL = 'select Id as Id, Product as [\@' + dbo.fnDBTranslate(N'0', 38337, 'Product')  + '], Total as [' + dbo.fnDBTranslate(N'0', 38340, 'Total') + '], MTTR as [' + dbo.fnDBTranslate(N'0', 38341, 'MTTR') + '], MTBF as [' + dbo.fnDBTranslate(N'0', 38342, 'MTBF') + '], [% Fault] as [\@' + dbo.fnDBTranslate(N'0', 38346, '% Fault') + '], [% Total] as [' + dbo.fnDBTranslate(N'0', 38343, '% Total') + '], [# Events] as [' + dbo.fnDBTranslate(N'0', 38344, '# Events') + '], rs_id as rs_id 	 from #ResultSet7 order by Total asc'
exec (@SQL)
select @SQL = 'select Id as Id, Crew as [\@' + dbo.fnDBTranslate(N'0', 38338, 'Crew')  + '], Total as [' + dbo.fnDBTranslate(N'0', 38340, 'Total') + '], MTTR as [' + dbo.fnDBTranslate(N'0', 38341, 'MTTR') + '], MTBF as [' + dbo.fnDBTranslate(N'0', 38342, 'MTBF') + '], [% Total] as [' + dbo.fnDBTranslate(N'0', 38343, '% Total') + '], [# Events] as [' + dbo.fnDBTranslate(N'0', 38344, '# Events') + '], rs_id as rs_id 	 from #ResultSet8 order by Total asc'
exec (@SQL)
select @SQL = 'select Id as Id, Shift as [\@' + dbo.fnDBTranslate(N'0', 38479, 'Shift')  + '], Total as [' + dbo.fnDBTranslate(N'0', 38340, 'Total') + '], MTTR as [' + dbo.fnDBTranslate(N'0', 38341, 'MTTR') + '], MTBF as [' + dbo.fnDBTranslate(N'0', 38342, 'MTBF') + '], [% Total] as [' + dbo.fnDBTranslate(N'0', 38343, '% Total') + '], [# Events] as [' + dbo.fnDBTranslate(N'0', 38344, '# Events') + '], rs_id as rs_id 	 from #ResultSet9 order by Total asc'
exec (@SQL)
Drop Table #Units
Drop Table #ProductiveTimes
Drop Table #Details
Drop Table #Results
Drop Table #ResultSet1
Drop Table #ResultSet2
Drop Table #ResultSet3
Drop Table #ResultSet4
Drop Table #ResultSet5
Drop Table #ResultSet6
Drop Table #ResultSet7
Drop Table #ResultSet8
Drop Table #ResultSet9
Drop Table #IntegerResults
Drop Table #CrewTimes
Drop Table #ShiftTimes
Drop Table #PreviousDowntimeEnd
