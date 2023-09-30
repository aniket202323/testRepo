CREATE Procedure dbo.spDBR_TopNWaste
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
--*********************************************************/
SET ANSI_WARNINGS off
set arithignore on
set arithabort off
set ansi_warnings off
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
Declare @DimXUnits varchar(25)
Declare @iActualProduction real,
@iActualQualityLoss real,
@iActualYieldLoss real,
@iIdealYield real,
@iIdealRate real, 
@iIdealProduction real,  
@iWarningProduction real,  
@iRejectProduction real,  
@iTargetQualityLoss real,
@iWarningQualityLoss real,
@iRejectQualityLoss real,
@iActualTotalItems int,
@iActualGoodItems int,
@iActualBadItems int,
@iActualConformanceItems int
Declare @AmountEngineeringUnits varchar(25),
@ItemEngineeringUnits varchar(25),
@TimeEngineeringUnits int
Create Table #Summary (
  Timestamp  	  	  	  	  	 datetime,
 	 ProductId 	  	  	  	  	  	 int NULL,
  ItemId  	             int NULL,
 	 Amount  	  	  	  	  	  	  	 real NULL,
  Fault  	  	  	  	  	  	  	 varchar(100) NULL,
 	 Crew 	  	  	  	  	  	  	  	 varchar(10) NULL
) 
create table #ProductiveTimes
(
  PU_Id     int null,
  StartTime datetime,
  EndTime   datetime
)
Declare @TotalProduction real
Declare @TotalWaste real
Select @TotalProduction = 0
Select @TotalWaste = 0.0
Declare @@StartTime datetime
Declare @@EndTime datetime
Declare @ProductProduction real
--*****************************************************/
--Build List Of Units
--*****************************************************/
create table #Units
(
  LineName varchar(100) NULL, 
  LineId int NULL,
 	 UnitName varchar(100) NULL,
 	 Item int
)
---23/08/2010 - Conversion of datetime into UTC e.g. India Standard Time','Central Stardard Time'
 	 SELECT @StartTime = dbo.fnServer_CmnConvertToDBTime(@StartTime,@InTimeZone)
 	 SELECT @EndTime = dbo.fnServer_CmnConvertToDBTime(@EndTime,@InTimeZone)
if (not @UnitList like '%<Root></Root>%' and not @UnitList is NULL)
  begin
    if (not @UnitList like '%<Root>%')
    begin
      declare @Text nvarchar(4000)
      select @Text = N'Item;' + Convert(nvarchar(4000), @UnitList)
      Insert Into #Units (Item) EXECUTE spDBR_Prepare_Table @Text
    end
    else
    begin
      insert into #Units (LineName, LineId, UnitName, Item) EXECUTE spDBR_Prepare_Table @UnitList
    end
  end
Else
  Begin
    Insert Into #Units (Item) 
      Select distinct pu_id From prod_events where event_type = 3     
  End
--*****************************************************/
declare @curPU_Id int
Declare PRODUCTIVETIME_CURSOR INSENSITIVE CURSOR
 	 For (
 	 Select item From #Units
 	 )
 	  For Read Only
if (@FilterNonProductiveTime = 1)
begin
   	 Open PRODUCTIVETIME_CURSOR
 	 BEGIN_PRODUCTIVETIME_CURSOR1:
 	 Fetch Next From PRODUCTIVETIME_CURSOR Into @curPU_Id
 	 While @@Fetch_Status = 0
 	 Begin    
 	  	 insert into #ProductiveTimes (StartTime, EndTime)  execute spDBR_GetProductiveTimes @curPU_Id, @StartTime, @EndTime
 	  	 update #ProductiveTimes set PU_Id = @curPU_Id where PU_Id is null
      	  	 GOTO BEGIN_PRODUCTIVETIME_CURSOR1
 	 End
 	 Close PRODUCTIVETIME_CURSOR
 	 Deallocate PRODUCTIVETIME_CURSOR
end
else
begin
   	 Open PRODUCTIVETIME_CURSOR
 	 BEGIN_PRODUCTIVETIME_CURSOR2:
 	 Fetch Next From PRODUCTIVETIME_CURSOR Into @curPU_Id
 	 While @@Fetch_Status = 0
 	 Begin    
 	  	 insert into #ProductiveTimes (PU_Id, StartTime, EndTime) select @curPU_Id, @StartTime, @EndTime
      	  	 GOTO BEGIN_PRODUCTIVETIME_CURSOR2
 	 End
 	 Close PRODUCTIVETIME_CURSOR
 	 Deallocate PRODUCTIVETIME_CURSOR
end
/*if (@FilterNonProductiveTime = 1)
begin
insert into #ProductiveTimes (StartTime, EndTime, PU_Id) select Productive_Start_Time, Productive_End_Time, PU_Id from events_npt where PU_Id in (select item from #units) 
and coalesce(Start_Time, Actual_Start_Time) >= @StartTime and timestamp <= @EndTime
insert into #ProductiveTimes (StartTime, EndTime, PU_Id) select Productive_Start_Time, Productive_End_Time, PU_Id from events_npt where PU_Id in (select item from #units) 
and coalesce(Start_Time, Actual_Start_Time) < @StartTime and @EndTime between coalesce(Start_Time, Actual_Start_Time) and timestamp
insert into #ProductiveTimes (StartTime, EndTime, PU_Id) select Productive_Start_Time, Productive_End_Time, PU_Id from events_npt where PU_Id in (select item from #units) 
and timestamp > @EndTime and @StartTime between coalesce(Start_Time, Actual_Start_Time) and timestamp
insert into #ProductiveTimes (StartTime, EndTime, PU_Id) select Productive_Start_Time, Productive_End_Time, PU_Id from events_npt where PU_Id in (select item from #units) 
and timestamp > @EndTime and @StartTime > coalesce(Start_Time, Actual_Start_Time)
end
else
begin
 	  	 insert into #ProductiveTimes (PU_Id, StartTime, EndTime) select item, @StartTime, @EndTime from #units
end
delete from #ProductiveTimes where starttime is null
delete from #ProductiveTimes where starttime = endtime
*/
declare @LastEndTime datetime, @NextStartTime datetime, @NextEndTime datetime, @MaxEndTime datetime
select @MaxEndTime = max(Endtime) from #ProductiveTimes
select @LastEndTime = min(EndTime) from #ProductiveTimes
select @NextStartTime = min(StartTime) from #ProductiveTimes where StartTime >= @LastEndTime
select @NextEndTime = min(EndTime) from #ProductiveTimes where StartTime = @NextStartTime
while (@LastEndTime < @MaxEndTime)
begin
 	 while @LastEndTime = @NextStartTime
 	 begin
 	  	 update #ProductiveTimes set EndTime = @NextEndTime where endtime = @LastEndTime
 	   delete from #ProductiveTimes where starttime = @NextStartTime and endtime = @NextEndTime
 	 
 	 select @LastEndTime = @NextEndTime
 	 select @NextStartTime = min(StartTime) from #ProductiveTimes where StartTime >= @LastEndTime
 	 select @NextEndTime = min(EndTime) from #ProductiveTimes where StartTime = @NextStartTime 	 
 	 end
 	 select @LastEndTime = @NextEndTime
 	 select @NextStartTime = min(StartTime) from #ProductiveTimes where StartTime >= @LastEndTime
 	 select @NextEndTime = min(EndTime) from #ProductiveTimes where StartTime = @NextStartTime 	 
end
Create Table #Production (
  ProductId int,
  TotalProduction real 
) 
  	  	 --Prepare Details Table
    Create Table #Details (
 	  	   Timestamp  	  	  	  	  	 datetime,
 	  	  	 ItemId 	  	  	  	  	     int NULL,
 	  	  	 ProductId 	  	  	  	  	   int NULL,
 	  	  	 Amount  	  	  	  	  	  	  	 real NULL,
      FaultId  	  	  	  	  	  	 int NULL,
 	  	  	 Crew 	  	  	  	  	  	  	  	 varchar(10) NULL,
    ) 
    Create Table #ProductChanges (
      ProductId int,
      StartTime datetime,
      EndTime datetime,
      Production real NULL
    ) 
Declare Unit_Cursor Insensitive Cursor 
  For Select Item From #Units 
  For Read Only
Open Unit_Cursor
Fetch Next From Unit_Cursor Into @@UnitId
While @@Fetch_Status = 0
  Begin
    --Get Reason Level Header Names
    If @Level1Name Is Null
      Begin
     	  	 Select @TreeId = Name_Id
 	  	       From Prod_Events
 	  	       Where PU_Id = @@UnitId and
            Event_Type = 3
     	  	 Select @Level1Name = level_name
 	  	       From event_reason_level_headers 
 	  	       Where Tree_Name_id = @TreeId and
 	  	             Reason_Level = 1
 	  	 
      	  	 If @Level1Name Is Not Null 
 	  	   	     Select @Level2Name = level_name
 	  	  	       From event_reason_level_headers 
 	  	  	       Where Tree_Name_id = @TreeId and
 	  	  	             Reason_Level = 2
 	  	 
 	  	     If @Level2Name Is Not Null 
 	  	  	     Select @Level3Name = level_name
 	  	  	       From event_reason_level_headers 
 	  	  	       Where Tree_Name_id = @TreeId and
 	  	  	             Reason_Level = 3
 	  	 
 	  	     If @Level3Name Is Not Null 
 	  	  	     Select @Level4Name = level_name
 	  	  	       From event_reason_level_headers 
 	  	  	       Where Tree_Name_id = @TreeId and
 	  	  	             Reason_Level = 4
      End
    If @DimXUnits Is Null  
 	  	  	  	 Select @DimXUnits = s.dimension_x_eng_units
 	  	  	  	   from event_configuration e 
 	  	  	  	   join event_subtypes s on s.Event_Subtype_Id = e.Event_Subtype_Id
 	  	  	  	   where e.pu_id = @@UnitId and 
 	  	  	  	         e.et_id = 1
declare @curStartTime datetime, @curEndTime datetime
Declare TIME_CURSOR INSENSITIVE CURSOR
  For (
     Select PU_Id, StartTime, EndTime From #ProductiveTimes Where PU_ID = @@UnitId
      )
  For Read Only
  Open TIME_CURSOR  
BEGIN_TIME_CURSOR:
Fetch Next From TIME_CURSOR Into @curPU_Id, @curStartTime, @curEndTime
While @@Fetch_Status = 0
Begin   
 	  	 --*****************************************************
 	  	 -- WASTE EVENTS
 	  	 --*****************************************************
    If @ReportLevel = 0  --Location
 	  	   Select @SQL1 = 'Select d.Timestamp, d.Source_PU_Id' 	  
    Else If @ReportLevel = 1
 	  	   Select @SQL1 = 'Select d.Timestamp, d.Reason_Level1' 	  
    Else If @ReportLevel = 2
 	  	   Select @SQL1 = 'Select d.Timestamp, d.Reason_Level2' 	  
    Else If @ReportLevel = 3
 	  	   Select @SQL1 = 'Select d.Timestamp, d.Reason_Level3' 	  
    Else If @ReportLevel = 4
 	  	   Select @SQL1 = 'Select d.Timestamp, d.Reason_Level4' 	  
    Else If @ReportLevel = 5  -- Fault
 	  	   Select @SQL1 = 'Select d.Timestamp, d.Source_PU_Id' 	  
    Else If @ReportLevel = 6  -- Crew
 	  	   Select @SQL1 = 'Select d.Timestamp, d.Source_PU_Id' 	  
    Else If @ReportLevel = 7  -- Product
 	  	   Select @SQL1 = 'Select d.Timestamp, d.Source_PU_Id' 	  
 	  	 Select @SQL1 = @SQL1 + ', d.Amount'
 	  	 Select @SQL1 = @SQL1 + ', d.WEFault_Id'         
 	  	 Select @SQL2 = ' From Waste_Event_Details d Where d.PU_Id = ' + convert(varchar(10),@@UnitId)
 	  	 Select @SQL2 = @SQL2 + ' and d.Timestamp > ' + '''' + convert(varchar(30),@curStartTime) + '''' + ' and d.Timestamp <= ' + '''' + convert(varchar(30),@curEndTime) + ''''
 	  	 Select @SQL2 = @SQL2 + ' and d.Event_Id Is Null'
    Select @SQL3 = ' '
 	  	 If @LocationFilter Is Not Null Select @SQL3 = @SQL3 + ' and d.Source_PU_Id = ' + convert(varchar(10), @LocationFilter)
 	  	 If @ReasonFilter1 Is Not Null Select @SQL3 = @SQL3 + ' and d.Reason_Level1 = ' + convert(varchar(10), @ReasonFilter1)
 	  	 If @ReasonFilter2 Is Not Null Select @SQL3 = @SQL3 + ' and d.Reason_Level2 = ' + convert(varchar(10), @ReasonFilter2)
 	  	 If @ReasonFilter3 Is Not Null Select @SQL3 = @SQL3 + ' and d.Reason_Level3 = ' + convert(varchar(10), @ReasonFilter3)
 	  	 If @ReasonFilter4 Is Not Null Select @SQL3 = @SQL3 + ' and d.Reason_Level4 = ' + convert(varchar(10), @ReasonFilter4)
 	  	 If @FaultFilter Is Not Null
      Begin
 	  	  	  	 Select @FaultId = NULL
 	  	  	  	 Select @FaultId = WEFault_Id From Waste_Event_Fault Where PU_Id = @@UnitId and WEFault_Name = @FaultFilter
        If @FaultId Is Not Null
 	  	  	  	  	 Select @SQL3 = @SQL3 + ' and d.WEFault_Id = ' + convert(varchar(10), @FaultId)              
      End
    Select @SQL4 = @SQL1 + @SQL2 + @SQL3
    --For Testing 
    --Select @SQL4 
    Insert Into #Details (Timestamp, ItemId, Amount, FaultId)
      Exec (@SQL4)        
    Select @SQL1 = replace(@SQL1, 'd.Timestamp', 'e.Timestamp')
 	   Select @SQL2 = ' From Events e Join Waste_Event_Details d on d.Event_Id = e.Event_Id Where e.PU_Id = ' + convert(varchar(10),@@UnitId) 
    Select @SQL2 = @SQL2 + ' and e.Timestamp > ' + '''' + convert(varchar(30),@curStartTime) + '''' + ' and e.Timestamp <= ' + '''' + convert(varchar(30),@curEndTime) + ''''
    Select @SQL4 = @SQL1 + @SQL2 + @SQL3
    --For Testing 
    --Select @SQL4 
    Insert Into #Details (Timestamp, ItemId, Amount, FaultId)
      Exec (@SQL4)        
 	 
    -- Join In Product Information    
    Update #Details 
      Set ProductId = (Select Prod_Id From Production_Starts ps Where ps.PU_Id = @@UnitId and ps.Start_Time <= #Details.Timestamp and ((ps.End_Time > #Details.Timestamp) or (ps.End_Time Is Null)))      	 
    Insert Into #ProductChanges (ProductId, StartTime, EndTime)
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
                    	  	  	  	  	 
        Delete From #ProductChanges Where ProductId <> @ProductFilter
        Delete From #Details Where ProductId <> @ProductFilter
      End
    -- Get Production Amounts Per Product Change
 	  	 Declare Production_Cursor Insensitive Cursor 
 	  	   For Select StartTime,EndTime From #ProductChanges 
 	  	   For Read Only
 	  	 
 	  	 Open Production_Cursor
 	  	 
 	  	 Fetch Next From Production_Cursor Into @@StartTime, @@EndTime
 	  	 
 	  	 While @@Fetch_Status = 0
 	  	   Begin
        Select @ProductProduction = 0.0
 	  	  	  	 execute spCMN_GetUnitProduction
 	  	  	  	  	  	 @@UnitId,
 	  	  	  	  	  	 @@StartTime, 
 	  	  	  	  	  	 @@EndTime,
 	  	  	  	  	  	 0,
 	  	  	  	  	  	 @iActualProduction OUTPUT,
 	  	  	  	  	  	 @iActualQualityLoss OUTPUT,
 	  	  	  	  	  	 @iActualYieldLoss OUTPUT,
 	  	  	  	  	  	 @iActualTotalItems OUTPUT,
 	  	  	  	  	  	 @iActualGoodItems OUTPUT,
 	  	  	  	  	  	 @iActualBadItems OUTPUT,
 	  	  	  	  	  	 @iActualConformanceItems OUTPUT,
 	  	  	  	  	  	 @iIdealYield OUTPUT,  
 	  	  	  	  	  	 @iIdealRate OUTPUT,  
 	  	  	  	  	  	 @iIdealProduction OUTPUT,  
 	  	  	  	  	  	 @iWarningProduction OUTPUT,  
 	  	  	  	  	  	 @iRejectProduction OUTPUT,  
 	  	  	  	  	  	 @iTargetQualityLoss OUTPUT,
 	  	  	  	  	  	 @iWarningQualityLoss OUTPUT,
 	  	  	  	  	  	 @iRejectQualityLoss OUTPUT,
 	  	  	  	  	  	 @AmountEngineeringUnits OUTPUT,
 	  	  	  	  	  	 @ItemEngineeringUnits OUTPUT,
 	  	  	  	  	  	 @TimeEngineeringUnits OUTPUT
        Select @ProductProduction = coalesce(@iActualProduction, @ProductProduction)
        Update #ProductChanges set Production = @ProductProduction Where StartTime = @@StartTime
 	  	  	  	 Fetch Next From Production_Cursor Into @@StartTime, @@EndTime
      End     
    close Production_Cursor
    deallocate Production_Cursor
    -- Update Operating Time From Trimmed Production Starts
  	  	 Select @TotalProduction = @TotalProduction + coalesce((Select sum(Production)From #ProductChanges),0)
    	 Insert Into #Production (ProductId, TotalProduction)
      Select ProductId, sum(Production)
        From #ProductChanges
        Group By ProductId
    truncate Table #ProductChanges    
    --Update Crew
    Update #Details 
      Set #Details.Crew = (Select c.Crew_Desc From Crew_Schedule c Where c.PU_Id = @@UnitId and c.Start_Time <= #Details.Timestamp and C.End_Time > #Details.Timestamp)
    If @CrewFilter Is Not Null
      Delete From #Details Where Crew <> @CrewFilter 
  	  	 Select @TotalWaste = @TotalWaste + coalesce((Select sum(Amount) From #Details),0)
 	   
    -- Add Rows To Summary Resultset
    Insert Into  #Summary (Timestamp,ProductId,ItemId, Amount, Crew, Fault) 
      Select Timestamp,ProductId,ItemId,Amount, Crew, case when wef.WEFault_Id Is Null then '<Unspecified>' Else wef.WEFault_Name End 
        From #Details
        Left Outer Join Waste_Event_Fault wef on wef.WEFault_Id = #Details.FaultId 
    --For Testing
    --Select * From #Details
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
-- Return Resultset #1 - Resultset Name List
--*********************************************************************************
Declare @Message varchar(100)
Create Table #Resultsets (
  ResultSetName varchar(50),
  ResultSetTabName varchar(50),
  ParameterName varchar(50)  NULL,
  ParameterUnits varchar(50) NULL,
  DataColumns    varchar(50) NULL,
  LabelColumns   varchar(50) NULL,
  IconDesc 	  varchar(1000) NULL,
  RS_ID 	  	 int  NULL
)
if (@level1name is null)
select @level1name = 'Level1'
if (@level2name is null)
select @level2name = 'Level2'
if (@level3name is null)
select @level3name = 'Level3'
if (@level4name is null)
select @level4name = 'Level4'
If @ReportLevel = 0
  Select @Message = dbo.fnDBTranslate(N'0', 38352,'Top') + ' ' + + convert(varchar(10),@TopNumber) + ' ' + dbo.fnDBTranslate(N'0', 38452, 'Waste By Location')
Else If @ReportLevel = 1
  Select @Message = dbo.fnDBTranslate(N'0', 38352,'Top')  + ' ' + + convert(varchar(10),@TopNumber) + ' ' + dbo.fnDBTranslate(N'0', 38453, 'Waste By') + ' ' + @Level1Name
Else If @ReportLevel = 2
  Select @Message = dbo.fnDBTranslate(N'0', 38352,'Top') + ' ' + + convert(varchar(10),@TopNumber) + ' ' + dbo.fnDBTranslate(N'0', 38453, 'Waste By') + ' ' + @Level2Name
Else If @ReportLevel = 3
  Select @Message = dbo.fnDBTranslate(N'0', 38352,'Top') + ' ' + + convert(varchar(10),@TopNumber) + ' ' + dbo.fnDBTranslate(N'0', 38453, 'Waste By') + ' ' + @Level3Name
Else If @ReportLevel = 4
  Select @Message = dbo.fnDBTranslate(N'0', 38352,'Top') + ' ' + + convert(varchar(10),@TopNumber) + ' ' + dbo.fnDBTranslate(N'0', 38453, 'Waste By') + ' ' + @Level4Name
Else If @ReportLevel = 5
  Select @Message = dbo.fnDBTranslate(N'0', 38352,'Top') + ' ' + + convert(varchar(10),@TopNumber) + ' ' + dbo.fnDBTranslate(N'0', 38454, 'Waste By Fault')
Else If @ReportLevel = 6
  Select @Message = dbo.fnDBTranslate(N'0', 38352,'Top') + ' ' + + convert(varchar(10),@TopNumber) + ' ' + dbo.fnDBTranslate(N'0', 38455, 'Waste By Crew')
Else If @ReportLevel = 7
  Select @Message = dbo.fnDBTranslate(N'0', 38352,'Top') + ' ' + + convert(varchar(10),@TopNumber) + ' ' + dbo.fnDBTranslate(N'0', 38456, 'Waste By Product')
insert into #Resultsets values (NULL, @Message, 'blue', NULL, NULL, NULL, NULL, NULL)
insert into #Resultsets values (dbo.fnDBTranslate(N'0', 38353,'Summary'), dbo.fnDBTranslate(N'0', 38353,'Summary'), NULL,NULL, NULL, NULL, NULL, 1)
insert into #Resultsets values (dbo.fnDBTranslate(N'0', 38457, 'Total Amount'), dbo.fnDBTranslate(N'0', 38457, 'Total Amount'),  NULL,coalesce(@DimXUnits,dbo.fnDBTranslate(N'0', 38129, 'Units')),2, 1, NULL,  2)
If @ReportLevel = 7 and @CrewFilter is Null
  insert into #Resultsets values (dbo.fnDBTranslate(N'0', 38458, 'Fault Amount'), dbo.fnDBTranslate(N'0', 38458, 'Fault Amount'),  NULL,coalesce(@DimXUnits,dbo.fnDBTranslate(N'0', 38129, 'Units')),2, 1, NULL,  3)
insert into #Resultsets values (dbo.fnDBTranslate(N'0', 38488, 'MAPE'), dbo.fnDBTranslate(N'0', 38488, 'MAPE'), NULL, coalesce(@DimXUnits,dbo.fnDBTranslate(N'0', 38129, 'Units')),2, 1, NULL,  4)
If @CrewFilter Is Null
  insert into #Resultsets values (dbo.fnDBTranslate(N'0', 38489, 'MABE'), dbo.fnDBTranslate(N'0', 38489, 'MABE'),  NULL,coalesce(@DimXUnits,dbo.fnDBTranslate(N'0', 38129, 'Units')),2, 1, NULL,  5)
insert into #Resultsets values (dbo.fnDBTranslate(N'0', 38356, 'Occur'), dbo.fnDBTranslate(N'0', 38356, 'Occur'), NULL, '#', 2, 1, NULL, 6)
Select * From #Resultsets
Drop Table #Resultsets
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
--*********************************************************************************
-- Return Resultsets For Location
--*********************************************************************************
If @ReportLevel = 0
  Begin
    Truncate Table #Results
    --Resultset #1, Summary
    Insert Into #Results (Id, Total, MTTR, MTBF, PercentTotal, NumberOfEvents)
      Select ItemId, sum(Amount), Avg(Amount), (@TotalProduction) / Count(Amount),sum(Amount) / convert(real,@TotalWaste), Count(Amount)
        From #Summary
        Group By ItemId
    Truncate Table #TmpResults
 	 insert into #TmpResults select Top (@TopNumber) * from #Results order by Total desc
 	 
 	 Select @SQL1 = 'Select Format = 0, coalesce(u.pu_desc,' + '''' + dbo.fnDBTranslate(N'0', 38333, 'Unspecified') + '''' + ') as [\@' + dbo.fnDBTranslate(N'0', 38345, 'Location') + '], convert(decimal(10,2),Total) as [' + dbo.fnDBTranslate(N'0', 38340, 'Total') +'], convert(decimal(10,2),r.MTTR) as [\@' + dbo.fnDBTranslate(N'0', 38488, 'MAPE') + '],'
    If @CrewFilter Is Null
      Select @SQL1 = @SQL1 + 'convert(decimal(10,2),r.MTBF) as [\@' + dbo.fnDBTranslate(N'0', 38489, 'MABE') + '],' 
    Select @SQL1 = @SQL1 + 'convert(varchar(25),convert(decimal(10,1),r.PercentTotal*100.0)) + ' + '''' + '%' + '''' + ' as [\@' + dbo.fnDBTranslate(N'0', 38343, '% Total') + '], r.NumberOfEvents as [' + dbo.fnDBTranslate(N'0', 38344, '# Events') + '], 1 as RS_ID From #TmpResults r left outer join Prod_Units u on u.pu_id = r.Id Order By Total ASC'
    Exec (@SQL1)
    --Resultset #2, Total Time
 	 Select @SQL1 = 'Select Format = 0, coalesce(u.pu_desc,' + '''' + dbo.fnDBTranslate(N'0', 38333, 'Unspecified') + '''' + ') as [\@' + dbo.fnDBTranslate(N'0', 38345, 'Location') + '], convert(decimal(10,2),Total) as [' + dbo.fnDBTranslate(N'0', 38340, 'Total') +'], 2 as RS_ID From #TmpResults r left outer join Prod_Units u on u.pu_id = r.Id Order By Total ASC' 
    Exec (@SQL1)
    --Resultset #4, MTTR
    Truncate Table #Statistics
    Insert Into #Statistics (Id, Value, Minimum, Maximum, StandardDeviation)
      Select ItemId, avg(Amount), min(Amount), max(Amount), stdev(Amount)
        From #Summary
        Group By ItemId
    Truncate Table #TmpStatistics
 	 insert into #TmpStatistics select Top (@TopNumber) * from #Statistics order by Value desc
    Select @SQL1 = 'Select Format = 0, coalesce(u.pu_desc,' + '''' + dbo.fnDBTranslate(N'0', 38333, 'Unspecified') + '''' + ') as [\@' + dbo.fnDBTranslate(N'0', 38345, 'Location') + '], convert(decimal(10,2),Value) as [\@' + dbo.fnDBTranslate(N'0', 38488, 'MAPE') +'], convert(decimal(10,2),Minimum) as [' + dbo.fnDBTranslate(N'0', 38360, 'Minimum') + '], convert(decimal(10,2),Maximum) as [' + dbo.fnDBTranslate(N'0', 38357, 'Maximum') + '], convert(decimal(10,2),StandardDeviation) as [' + dbo.fnDBTranslate(N'0', 38358, 'StDev') + '], 4 as RS_ID From #TmpStatistics r left outer join Prod_Units u on u.pu_id = r.Id Order By Value ASC' 
    Exec (@SQL1)
    If @CrewFilter Is Null
      Begin
        --Resultset #5, MTBF
        Truncate Table #Statistics
        Insert Into #Statistics (Id, Value, Minimum, Maximum, StandardDeviation)
          Select ItemId, (@TotalProduction - sum(Amount)) / convert(real,count(Amount)), null, null, null
            From #Summary
            Group By ItemId
 	     Truncate Table #TmpStatistics
 	  	 insert into #TmpStatistics select Top (@TopNumber) * from #Statistics order by Value desc
        Select @SQL1 = 'Select Format = 0, coalesce(u.pu_desc,' + '''' + dbo.fnDBTranslate(N'0', 38333, 'Unspecified') + '''' + ') as [\@' + dbo.fnDBTranslate(N'0', 38345, 'Location') + '], convert(decimal(10,2),Value) as [\@' + dbo.fnDBTranslate(N'0', 38489, 'MABE') +'], 5 as RS_ID From #TmpStatistics r left outer join Prod_Units u on u.pu_id = r.Id Order By Value ASC' 
        Exec (@SQL1)
      End
    --Resultset #6, Ocuurences
    Truncate Table #Statistics
    Insert Into #Statistics (Id, Value, Minimum, Maximum, StandardDeviation)
      Select ItemId, count(Amount), null, null, null
        From #Summary
        Group By ItemId
    Truncate Table #TmpStatistics
 	 insert into #TmpStatistics select Top (@TopNumber) * from #Statistics order by Value desc
    Select @SQL1 = 'Select Format = 0, coalesce(u.pu_desc,' + '''' + dbo.fnDBTranslate(N'0', 38333, 'Unspecified') + '''' + ') as [\@' + dbo.fnDBTranslate(N'0', 38345, 'Location') + '], convert(decimal(10,0),Value) as [' + dbo.fnDBTranslate(N'0', 38356, 'Occur') +'], 6 as RS_ID From #TmpStatistics r left outer join Prod_Units u on u.pu_id = r.Id Order By Value ASC' 
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
      Select ItemId, sum(Amount), Avg(Amount), (@TotalProduction) / Count(Amount),sum(Amount) / convert(real,@TotalWaste), Count(Amount)
        From #Summary
        Group By ItemId
    Truncate Table #TmpResults
 	 insert into #TmpResults select Top (@TopNumber) * from #Results order by Total desc
 	 
    Select @SQL1 = 'Select Format = 0, coalesce(n.event_reason_name,' + '''' + dbo.fnDBTranslate(N'0', 38333, 'Unspecified') + '''' + ') as [\@' + Case @ReportLevel When 1 Then @Level1Name When 2 Then @Level2Name When 3 Then @Level3Name Else @Level4Name End + '], convert(decimal(10,2),Total) as [' + dbo.fnDBTranslate(N'0', 38340, 'Total') +'], convert(decimal(10,2),r.MTTR) as [\@' + dbo.fnDBTranslate(N'0', 38488, 'MAPE') + '],'
    If @CrewFilter Is Null
      Select @SQL1 = @SQL1 + 'convert(decimal(10,2),r.MTBF) as [\@' + dbo.fnDBTranslate(N'0', 38489, 'MABE')  + '],' 
    Select @SQL1 = @SQL1 + 'convert(varchar(25),convert(decimal(10,1),r.PercentTotal*100.0)) + ' + '''' + '%' + '''' + ' as [\@' + dbo.fnDBTranslate(N'0', 38343, '% Total') + '], r.NumberOfEvents as [' + dbo.fnDBTranslate(N'0', 38344, '# Events') + '], 1 as RS_ID From #TmpResults r left outer join Event_Reasons n on n.event_reason_id = r.Id Order By Total ASC'
    Exec (@SQL1)
    --Resultset #2, Total Time
    Select @SQL1 = 'Select Format = 0, coalesce(n.event_reason_name,' + '''' + dbo.fnDBTranslate(N'0', 38333, 'Unspecified') + '''' + ') as [\@' + Case @ReportLevel When 1 Then @Level1Name When 2 Then @Level2Name When 3 Then @Level3Name Else @Level4Name End + '], convert(decimal(10,2),Total) as [' + dbo.fnDBTranslate(N'0', 38340, 'Total') +'], 2 as RS_ID From #TmpResults r left outer join Event_Reasons n on n.event_reason_id = r.Id Order By Total ASC'   
    Exec (@SQL1)
    --Resultset #4, MTTR
    Truncate Table #Statistics
    Insert Into #Statistics (Id, Value, Minimum, Maximum, StandardDeviation)
      Select ItemId, avg(Amount), min(Amount), max(Amount), stdev(Amount)
        From #Summary
        Group By ItemId
    Truncate Table #TmpStatistics
 	 insert into #TmpStatistics select Top (@TopNumber) * from #Statistics order by Value desc
    Select @SQL1 = 'Select Format = 0, coalesce(n.event_reason_name,' + '''' + dbo.fnDBTranslate(N'0', 38333, 'Unspecified') + '''' + ') as [\@' + Case @ReportLevel When 1 Then @Level1Name When 2 Then @Level2Name When 3 Then @Level3Name Else @Level4Name End + '], convert(decimal(10,2),Value) as [\@' + dbo.fnDBTranslate(N'0', 38488, 'MAPE') +'], convert(decimal(10,2),Minimum) as [' + dbo.fnDBTranslate(N'0', 38360, 'Minimum') + '], convert(decimal(10,2),Maximum) as [' + dbo.fnDBTranslate(N'0', 38357, 'Maximum') + '], convert(decimal(10,2),StandardDeviation) as [' + dbo.fnDBTranslate(N'0', 38358, 'StDev') + '], 4 as RS_ID From #TmpStatistics r left outer join Event_Reasons n on n.event_reason_id = r.Id Order By Value ASC' 
    Exec (@SQL1)
    If @CrewFilter Is Null
      Begin
        --Resultset #5, MTBF
        Truncate Table #Statistics
        Insert Into #Statistics (Id, Value, Minimum, Maximum, StandardDeviation)
          Select ItemId, (@TotalProduction - sum(Amount)) / convert(real,count(Amount)), null, null, null
            From #Summary
            Group By ItemId
 	     Truncate Table #TmpStatistics
 	  	 insert into #TmpStatistics select Top (@TopNumber) * from #Statistics order by Value desc
        Select @SQL1 = 'Select Format = 0, coalesce(n.event_reason_name,' + '''' + dbo.fnDBTranslate(N'0', 38333, 'Unspecified') + '''' + ') as [\@' + Case @ReportLevel When 1 Then @Level1Name When 2 Then @Level2Name When 3 Then @Level3Name Else @Level4Name End + '], convert(decimal(10,2),Value) as [\@' + dbo.fnDBTranslate(N'0', 38489, 'MABE') +'], 5 as RS_ID From #TmpStatistics r left outer join Event_Reasons n on n.event_reason_id = r.Id Order By Value ASC' 
        Exec (@SQL1)
      End
    --Resultset #6, Ocuurences
    Truncate Table #Statistics
    Insert Into #Statistics (Id, Value, Minimum, Maximum, StandardDeviation)
      Select ItemId, count(Amount), null, null, null
        From #Summary
        Group By ItemId
    Truncate Table #TmpStatistics
 	 insert into #TmpStatistics select Top (@TopNumber) * from #Statistics order by Value desc
    Select @SQL1 = 'Select Format = 0, coalesce(n.event_reason_name,' + '''' + dbo.fnDBTranslate(N'0', 38333, 'Unspecified') + '''' + ') as [\@' + Case @ReportLevel When 1 Then @Level1Name When 2 Then @Level2Name When 3 Then @Level3Name Else @Level4Name End + '], convert(decimal(10,0),Value) as [' + dbo.fnDBTranslate(N'0', 38356, 'Occur') +'], 6 as RS_ID From #TmpStatistics r left outer join Event_Reasons n on n.event_reason_id = r.Id Order By Value ASC' 
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
      Select Fault, sum(Amount), Avg(Amount), (@TotalProduction) / Count(Amount),sum(Amount) / convert(real,@TotalWaste), Count(Amount)
        From #Summary
        Group By Fault
    Truncate Table #TmpResults
 	 insert into #TmpResults select Top (@TopNumber) * from #Results order by Total desc
 	 
    Select @SQL1 = 'Select Format = 0, r.Name as [' + dbo.fnDBTranslate(N'0', 38336, 'Fault') + '], convert(decimal(10,2),Total) as [\@' + dbo.fnDBTranslate(N'0', 38340, 'Total') +'], convert(decimal(10,2),r.MTTR) as [\@' + dbo.fnDBTranslate(N'0', 38488, 'MAPE') + '],'
    If @CrewFilter Is Null
      Select @SQL1 = @SQL1 + 'convert(decimal(10,2),r.MTBF) as [\@' + dbo.fnDBTranslate(N'0', 38489, 'MABE')  + '],' 
    Select @SQL1 = @SQL1 + 'convert(varchar(25),convert(decimal(10,1),r.PercentTotal*100.0)) + ' + '''' + '%' + '''' + ' as [\@' + dbo.fnDBTranslate(N'0', 38343, '% Total') + '], r.NumberOfEvents as [' + dbo.fnDBTranslate(N'0', 38344, '# Events') + '], 1 as RS_ID From #TmpResults r Order By Total ASC'
    Exec (@SQL1)
    --Resultset #2, Total Time
    Select @SQL1 = 'Select Top ' + convert(varchar(10), @TopNumber) + ' Format = 0, r.Name as [\@' + dbo.fnDBTranslate(N'0', 38336, 'Fault') + '], convert(decimal(10,2),Total) as [' + dbo.fnDBTranslate(N'0', 38340, 'Total') +'], 2 as RS_ID From #TmpResults r Order By Total ASC' 
    Exec (@SQL1)
    --Resultset #4, MTTR
    Truncate Table #Statistics
    Insert Into #Statistics (Name, Value, Minimum, Maximum, StandardDeviation)
      Select Fault, avg(Amount), min(Amount), max(Amount), stdev(Amount)
        From #Summary
        Group By Fault
    Truncate Table #TmpStatistics
 	 insert into #TmpStatistics select Top (@TopNumber) * from #Statistics order by Value desc
    Select @SQL1 = 'Select Format = 0, r.Name as [' + dbo.fnDBTranslate(N'0', 38336, 'Fault') + '], convert(decimal(10,2),Value) as [\@' + dbo.fnDBTranslate(N'0', 38488, 'MAPE') +'], convert(decimal(10,2),Minimum) as [' + dbo.fnDBTranslate(N'0', 38360, 'Minimum') + '], convert(decimal(10,2),Maximum) as [' + dbo.fnDBTranslate(N'0', 38357, 'Maximum') + '], convert(decimal(10,2),StandardDeviation) as [' + dbo.fnDBTranslate(N'0', 38358, 'StDev') + '], 4 as RS_ID From #TmpStatistics r Order By Value ASC' 
    Exec (@SQL1)
    If @CrewFilter Is Null
      Begin
        --Resultset #5, MTBF
        Truncate Table #Statistics
        Insert Into #Statistics (Name, Value, Minimum, Maximum, StandardDeviation)
          Select Fault, (@TotalProduction - sum(Amount)) / convert(real,count(Amount)), null, null, null
            From #Summary
            Group By Fault
 	     Truncate Table #TmpStatistics
 	  	 insert into #TmpStatistics select Top (@TopNumber) * from #Statistics order by Value desc
        Select @SQL1 = 'Select Format = 0, r.Name as [' + dbo.fnDBTranslate(N'0', 38336, 'Fault') + '], convert(decimal(10,2),Value) as [\@' + dbo.fnDBTranslate(N'0', 38489, 'MABE') +'], 5 as RS_ID From #TmpStatistics r Order By Value ASC' 
        Exec (@SQL1)
      End
    --Resultset #6, Ocuurences
    Truncate Table #Statistics
    Insert Into #Statistics (Name, Value, Minimum, Maximum, StandardDeviation)
      Select Fault, count(Amount), null, null, null
        From #Summary
        Group By Fault
    Truncate Table #TmpStatistics
 	 insert into #TmpStatistics select Top (@TopNumber) * from #Statistics order by Value desc
    Select @SQL1 = 'Select Format = 0, r.Name as [' + dbo.fnDBTranslate(N'0', 38336, 'Fault') + '], convert(decimal(10,0),Value) as [\@' + dbo.fnDBTranslate(N'0', 38356, 'Occur') +'], 6 as RS_ID From #TmpStatistics r Order By Value ASC' 
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
      Select Crew, sum(Amount), Avg(Amount), (@TotalProduction) / Count(Amount),sum(Amount) / convert(real,@TotalWaste), Count(Amount)
        From #Summary
        Group By Crew
    Truncate Table #TmpResults
 	 insert into #TmpResults select Top (@TopNumber) * from #Results order by Total desc
 	 
    Select @SQL1 = 'Select Format = 0, coalesce( r.Name ,' + '''' + dbo.fnDBTranslate(N'0', 38333, 'Unspecified') + '''' + ') as [\@' + dbo.fnDBTranslate(N'0', 38338, 'Crew') + '], convert(decimal(10,2),Total) as [' + dbo.fnDBTranslate(N'0', 38340, 'Total') +'], convert(decimal(10,2),r.MTTR) as [\@' + dbo.fnDBTranslate(N'0', 38488, 'MAPE') + '],'
    If @CrewFilter Is Null
      Select @SQL1 = @SQL1 + 'convert(decimal(10,2),r.MTBF) as [\@' + dbo.fnDBTranslate(N'0', 38489, 'MABE')  + '],' 
    Select @SQL1 = @SQL1 + 'convert(varchar(25),convert(decimal(10,1),r.PercentTotal*100.0)) + ' + '''' + '%' + '''' + ' as [\@' + dbo.fnDBTranslate(N'0', 38343, '% Total') + '], r.NumberOfEvents as [' + dbo.fnDBTranslate(N'0', 38344, '# Events') + '], 1 as RS_ID From #TmpResults r Order By Total ASC'
    Exec (@SQL1)
    --Resultset #2, Total Time
    Select @SQL1 = 'Select Format = 0, coalesce( r.Name ,' + '''' + dbo.fnDBTranslate(N'0', 38333, 'Unspecified') + '''' + ') as [\@' + dbo.fnDBTranslate(N'0', 38338, 'Crew') + '], convert(decimal(10,2),Total) as [' + dbo.fnDBTranslate(N'0', 38340, 'Total') +'], 2 as RS_ID From #TmpResults r Order By Total ASC'
    Exec (@SQL1)
    --Resultset #4, MTTR
    Truncate Table #Statistics
    Insert Into #Statistics (Name, Value, Minimum, Maximum, StandardDeviation)
      Select Crew, avg(Amount), min(Amount), max(Amount), stdev(Amount)
        From #Summary
        Group By Crew
    Truncate Table #TmpStatistics
 	 insert into #TmpStatistics select Top (@TopNumber) * from #Statistics order by Value desc
    Select @SQL1 = 'Select Format = 0, coalesce( r.Name ,' + '''' + dbo.fnDBTranslate(N'0', 38333, 'Unspecified') + '''' + ') as [\@' + dbo.fnDBTranslate(N'0', 38338, 'Crew') + '], convert(decimal(10,2),Value) as [\@' + dbo.fnDBTranslate(N'0', 38488, 'MAPE') +'], convert(decimal(10,2),Minimum) as [' + dbo.fnDBTranslate(N'0', 38360, 'Minimum') + '], convert(decimal(10,2),Maximum) as [' + dbo.fnDBTranslate(N'0', 38357, 'Maximum') + '], convert(decimal(10,2),StandardDeviation) as [' + dbo.fnDBTranslate(N'0', 38358, 'StDev') + '], 4 as RS_ID From #TmpStatistics r Order By Value ASC' 
    Exec (@SQL1)
    If @CrewFilter Is Null
      Begin
        --Resultset #5, MTBF
        Truncate Table #Statistics
        Insert Into #Statistics (Name, Value, Minimum, Maximum, StandardDeviation)
          Select Crew, (@TotalProduction - sum(Amount)) / convert(real,count(Amount)), null, null, null
            From #Summary
            Group By Crew
 	     Truncate Table #TmpStatistics
 	  	 insert into #TmpStatistics select Top (@TopNumber) * from #Statistics order by Value desc
        Select @SQL1 = 'Select Format = 0, coalesce( r.Name ,' + '''' + dbo.fnDBTranslate(N'0', 38333, 'Unspecified') + '''' + ') as [\@' + dbo.fnDBTranslate(N'0', 38338, 'Crew') + '], convert(decimal(10,2),Value) as [\@' + dbo.fnDBTranslate(N'0', 38489, 'MABE') +'], 5 as RS_ID From #TmpStatistics r Order By Value ASC' 
        Exec (@SQL1)
      End
    --Resultset #6, Ocuurences
    Truncate Table #Statistics
    Insert Into #Statistics (Name, Value, Minimum, Maximum, StandardDeviation)
      Select Crew, count(Amount), null, null, null
        From #Summary
        Group By Crew
    Truncate Table #TmpStatistics
 	 insert into #TmpStatistics select Top (@TopNumber) * from #Statistics order by Value desc
    Select @SQL1 = 'Select Format = 0, coalesce( r.Name ,' + '''' + dbo.fnDBTranslate(N'0', 38333, 'Unspecified') + '''' + ') as [\@' + dbo.fnDBTranslate(N'0', 38338, 'Crew') + '], convert(decimal(10,0),Value) as [' + dbo.fnDBTranslate(N'0', 38356, 'Occur') +'], 6 as RS_ID From #TmpStatistics r Order By Value ASC' 
    Exec (@SQL1)
  End
--*********************************************************************************
-- Return Resultsets For Product
--*********************************************************************************
If @ReportLevel = 7
  Begin
    Truncate Table #Results
 	  	 -- Return % Operating Time By Product
    Create Table #RealResults (
      ID    int NULL,
      Value real NULL
    )
 	  	 
 	  	 Insert Into #RealResults (Id, Value)
 	  	   Select ProductId, sum(TotalProduction)
        From #Production
 	  	     Group By ProductId 
 	  	 
    --Resultset #1, Summary
    Insert Into #Results (Id, Total, MTTR, MTBF, PercentTotal, NumberOfEvents)
      Select ProductId, sum(Amount), Avg(Amount), (@TotalProduction) / Count(Amount),sum(Amount) / convert(real,@TotalWaste), Count(Amount)
        From #Summary
        Group By ProductId
    Truncate Table #TmpResults
 	 insert into #TmpResults select Top (@TopNumber) * from #Results order by Total desc
 	 
    Select @SQL1 = 'Select Format = 0, p.prod_code as [\@' + dbo.fnDBTranslate(N'0', 38337, 'Product') + '], convert(decimal(10,2),Total) as [' + dbo.fnDBTranslate(N'0', 38340, 'Total') +'], convert(decimal(10,2),r.MTTR) as [\@' + dbo.fnDBTranslate(N'0', 38488, 'MAPE') + '],'
    If @CrewFilter Is Null
      Select @SQL1 = @SQL1 + 'convert(decimal(10,2),r.MTBF) as [\@' + dbo.fnDBTranslate(N'0', 38489, 'MABE')  + '],' 
    Select @SQL1 = @SQL1 + 'convert(varchar(25),convert(decimal(10,1),r.PercentTotal*100.0)) + ' + '''' + '%' + '''' + ' as [\@' + dbo.fnDBTranslate(N'0', 38343, '% Total') + '], r.NumberOfEvents as [' + dbo.fnDBTranslate(N'0', 38344, '# Events') + '], 1 as RS_ID From #TmpResults r left outer join Products p on p.prod_id = r.Id Order By Total ASC'
    Exec (@SQL1)
    --Resultset #2, Total Time
    Select @SQL1 = 'Select Format = 0, p.prod_code as [\@' + dbo.fnDBTranslate(N'0', 38337, 'Product') + '], convert(decimal(10,2),Total) as [' + dbo.fnDBTranslate(N'0', 38340, 'Total') +'], 2 as RS_ID From #TmpResults r left outer join Products p on p.prod_id = r.Id Order By Total ASC' 
    Exec (@SQL1)
    If @CrewFilter Is Null
      Begin
 	     Truncate Table #TmpResults
 	  	 insert into #TmpResults select Top (@TopNumber) r.* From #Results r left outer join #RealResults i on i.Id = r.Id Order By (r.Total / (i.value) * 100.0) desc 
 	 
        Select @SQL1 = 'Select Format = 0, p.prod_code as [\@' + dbo.fnDBTranslate(N'0', 38337, 'Product') + '], convert(decimal(10,2),(r.Total / (i.value) * 100.0)) as [' + dbo.fnDBTranslate(N'0', 38460, '% Fault') + '],3 as RS_ID From #TmpResults r join Products p on p.prod_id = r.Id left outer join #RealResults i on i.Id = r.Id Order By (r.Total / (i.value) * 100.0) ASC' 
        Exec (@SQL1)
      End
    --Resultset #4, MTTR
    Truncate Table #Statistics
    Insert Into #Statistics (Id, Value, Minimum, Maximum, StandardDeviation)
      Select ProductId, avg(Amount), min(Amount), max(Amount), stdev(Amount)
        From #Summary
        Group By ProductId
    Truncate Table #TmpStatistics
 	 insert into #TmpStatistics select Top (@TopNumber) * from #Statistics order by Value desc
    Select @SQL1 = 'Select Format = 0, p.prod_code as [\@' + dbo.fnDBTranslate(N'0', 38337, 'Product') + '], convert(decimal(10,2),Value) as [\@' + dbo.fnDBTranslate(N'0', 38488, 'MAPE') +'], convert(decimal(10,2),Minimum) as [' + dbo.fnDBTranslate(N'0', 38360, 'Minimum') + '], convert(decimal(10,2),Maximum) as [' + dbo.fnDBTranslate(N'0', 38357, 'Maximum') + '], convert(decimal(10,2),StandardDeviation) as [' + dbo.fnDBTranslate(N'0', 38358, 'StDev') + '],4 as RS_ID From #TmpStatistics r left outer join Products p on p.prod_id = r.Id Order By Value ASC' 
    Exec (@SQL1)
    If @CrewFilter Is Null
      Begin
        --Resultset #5, MTBF
        Truncate Table #Statistics
        Insert Into #Statistics (Id, Value, Minimum, Maximum, StandardDeviation)
          Select ProductId, (@TotalProduction - sum(Amount)) / convert(real,count(Amount)), null, null, null
            From #Summary
            Group By ProductId
 	     Truncate Table #TmpStatistics
 	  	 insert into #TmpStatistics select Top (@TopNumber) * from #Statistics order by Value desc
        Select @SQL1 = 'Select Format = 0, p.prod_code as [\@' + dbo.fnDBTranslate(N'0', 38337, 'Product') + '], convert(decimal(10,2),Value) as [\@' + dbo.fnDBTranslate(N'0', 38489, 'MABE') +'], 5 as RS_ID From #TmpStatistics r left outer join Products p on p.prod_id = r.Id Order By Value ASC' 
        Exec (@SQL1)
      End
    --Resultset #6, Ocuurences
    Truncate Table #Statistics
    Insert Into #Statistics (Id, Value, Minimum, Maximum, StandardDeviation)
      Select ProductId, count(Amount), null, null, null
        From #Summary
        Group By ProductId
    Truncate Table #TmpStatistics
 	 insert into #TmpStatistics select Top (@TopNumber) * from #Statistics order by Value desc
    Select @SQL1 = 'Select Format = 0, p.prod_code as [\@' + dbo.fnDBTranslate(N'0', 38337, 'Product') + '], convert(decimal(10,0),Value) as [' + dbo.fnDBTranslate(N'0', 38356, 'Occur') +'], 6 as RS_ID From #TmpStatistics r left outer join Products p on p.prod_id = r.Id Order By Value ASC' 
    Exec (@SQL1)
    Drop Table #RealResults
  End
Drop Table #Results
Drop Table #TmpResults
Drop Table #Statistics
Drop Table #TmpStatistics
Drop Table #Summary
Drop Table #Units
Drop Table #Production
Drop Table #ProductiveTimes
Drop Table #Details
Drop Table #ProductChanges
