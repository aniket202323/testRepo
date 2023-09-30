/*
-- Dan Oct-21-2004
  1) Changed Query around Aggregate types to include the following sampling types:
  20,21,24,25,26,27
  2) Some downtime values were returning negative values.  
  Modified query around Timed_Event_Details by adding an external set of ()
  3) Downtime & runtime were passed to the report as minutes when they should be seconds
-- Dan Aug-17-2004
  Changed selection criteria so that joins are inclusive in regards to Start_Time
--Dan Aug-9-2004
Changed Timestamps to be converted to 120
Altered selection criteria from Production_Starts, Production_Plan_Starts and Crew_Schedule.  See code below
*/
CREATE procedure [dbo].[spASP_wrProductionList]
@ReportId int,
@RunId int = NULL
AS
--TODO: Add Other Process Order Attributes To Summary Page 
--TODO: When Default Aggregates Available For Variables, Change From Sampling Type
--TODO: When Default Aggregates For Dimensions, Get From Database
--TODO: ?? Color Code Variable Values Based On Specifications ??
--TODO: Work On Downtime Query
--TODO: Add Index(es) - EndTime and EventId To Temporary Table
set arithignore on
set ansi_warnings off
Declare @ReportName varchar(255)
Declare @CriteriaString varchar(1000)
Declare @Unit int
Declare @StartTime datetime
Declare @EndTime datetime
Declare @Variables varchar(1000)
Declare @DisplayGenealogyCounts int
Declare @DisplayDowntime int
Declare @DisplayWaste int
Declare @SummarizeDay int 
Declare @SummarizeProduct int 
Declare @SummarizeOrder int 
Declare @SummarizeShift int 
Declare @SummarizeCrew int 
Declare @SummarizeStatus int 
Declare @EventName varchar(50)
Declare @DimensionXName varchar(50)
Declare @DimensionYName varchar(50)
Declare @DimensionZName varchar(50)
Declare @DimensionAName varchar(50)
Declare @DimensionXAggregate int
Declare @DimensionYAggregate int
Declare @DimensionZAggregate int
Declare @DimensionAAggregate int
Declare @DimensionXAggregateName varchar(50)
Declare @DimensionYAggregateName varchar(50)
Declare @DimensionZAggregateName varchar(50)
Declare @DimensionAAggregateName varchar(50)
Declare @NoCrew int
Declare @NoOrder int
/*********************************************
-- For Testing
--*********************************************
declare @ReportId int
declare @RunId int
Select @Unit = 2
Select @StartTime = dateadd(day,-7,getdate())
Select @EndTime =  getdate()
Select @Variables = '11,12,13'
--**********************************************/
--/**********************************************
-- Loookup Parameters For This Report Id
--**********************************************
Declare @ReturnValue varchar(7000)
Select @ReportName = Report_Name From Report_Definitions Where Report_Id = @ReportId
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'MasterUnit', @ReportId, @ReturnValue output
Select @Unit = convert(int,@ReturnValue)
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'StartTime', @ReportId, @ReturnValue output
Select @StartTime = convert(datetime,@ReturnValue)
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'EndTime', @ReportId, @ReturnValue output
Select @EndTime = convert(datetime,@ReturnValue)
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'DisplayGenealogy', @ReportId, @ReturnValue output
Select @DisplayGenealogyCounts = convert(int, @ReturnValue)
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'DisplayDowntime', @ReportId, @ReturnValue output
Select @DisplayDowntime = convert(int, @ReturnValue)
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'DisplayWaste', @ReportId, @ReturnValue output
Select @DisplayWaste = convert(int, @ReturnValue)
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'SummarizeByDay', @ReportId, @ReturnValue output
Select @SummarizeDay = convert(int, @ReturnValue)
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'SummarizeByProduct', @ReportId, @ReturnValue output
Select @SummarizeProduct = convert(int, @ReturnValue)
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'SummarizeByOrder', @ReportId, @ReturnValue output
Select @SummarizeOrder = convert(int, @ReturnValue)
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'SummarizeByShift', @ReportId, @ReturnValue output
Select @SummarizeShift = convert(int, @ReturnValue)
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'SummarizeByCrew', @ReportId, @ReturnValue output
Select @SummarizeCrew = convert(int, @ReturnValue)
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'SummarizeByStatus', @ReportId, @ReturnValue output
Select @SummarizeStatus = convert(int, @ReturnValue)
exec spRS_GetReportParamValue 'Variables', @ReportId, @Variables output
--**********************************************/
--**********************************************
-- Check For Required Parameters And Set Defaults
--**********************************************
If @ReportName Is Null 
 	 Select @ReportName = dbo.fnRS_Translate(@ReportId, 36203, 'Production Listing')
If @Unit Is Null
  Begin
    exec spRS_AddEngineActivity @ReportName, 0, 'Required [MasterUnit] Parameter Is Missing', 2, @ReportId, @RunId
    Raiserror('Required [MasterUnit] Parameter Is Missing',16,1)
    return
  End
If @StartTime Is Null
  Begin
    exec spRS_AddEngineActivity @ReportName, 0, 'Required [StartTime] Parameter Is Missing', 2, @ReportId, @RunId
    Raiserror('Required [StartTime] Parameter Is Missing',16,1)
    return
  End
If @EndTime Is Null
  Begin
    exec spRS_AddEngineActivity @ReportName, 0, 'Required [EndTime] Parameter Is Missing', 2, @ReportId, @RunId
    Raiserror('Required [EndTime] Parameter Is Missing',16,1)
    return
  End
If @DisplayGenealogyCounts Is Null 
  Select @DisplayGenealogyCounts = 1
If @DisplayDowntime Is Null 
  Select @DisplayDowntime = 1
If @DisplayWaste Is Null 
  Select @DisplayWaste = 1
If @SummarizeDay Is Null
  Select @SummarizeDay = 1
If @SummarizeProduct Is Null
  Select @SummarizeProduct = 1
If @SummarizeOrder Is Null
  Select @SummarizeOrder = 1
If @SummarizeShift Is Null
  Select @SummarizeShift = 1
If @SummarizeCrew Is Null
  Select @SummarizeCrew = 1
If @SummarizeStatus Is Null
  Select @SummarizeStatus = 1
Select @NoCrew = 0
Select @NoOrder = 0
select @EventName = s.event_subtype_desc,
       @DimensionXName = case when LTrim(RTrim(s.dimension_x_name)) = '' then null else s.dimension_x_name end,
       @DimensionYName = case when LTrim(RTrim(s.dimension_y_name)) = '' then null else s.dimension_y_name end,
       @DimensionZName = case when LTrim(RTrim(s.dimension_z_name)) = '' then null else s.dimension_z_name end,
       @DimensionAName = case when LTrim(RTrim(s.dimension_a_name)) = '' then null else s.dimension_a_name end
  from event_configuration e 
  join event_subtypes s on s.Event_Subtype_Id = e.Event_Subtype_Id
  where e.pu_id = @Unit and 
        e.et_id = 1
Select @DimensionXAggregate = 7 --Total
Select @DimensionYAggregate = 7 --Total
Select @DimensionZAggregate = 4 --Min
Select @DimensionAAggregate = 4 --Min
--**********************************************
-- Return Header and Column Information
--**********************************************
-- Line1: Report Name
-- Line2: Criteria
-- Line3: Generate Time
-- Line4 - n: Column Names
Create Table #Prompts (
  PromptId int identity(1,1),
  PromptName varchar(20),
  PromptValue varchar(1000)
)
Declare @CountColumnName varchar(15)
Declare @DayColumnName varchar(15)
Declare @ShiftColumnName varchar(15)
Declare @CrewColumnName varchar(15)
Declare @ProcessOrderColumnName varchar(15)
Declare @StatusColumnName varchar(15)
Declare @StartColumnName varchar(15)
Declare @EndColumnName varchar(15)
Declare @ProductColumnName varchar(25)
Declare @ProductDescriptionColumnName varchar(25)
Declare @RemainingColumnName varchar(15)
Declare @RuntimeColumnName varchar(15)
Declare @DowntimeColumnName varchar(15)
Declare @DowntimeCountColumnName varchar(15)
Declare @DowntimePercentColumnName varchar(15)
Declare @WasteColumnName varchar(15)
Declare @WastePercentColumnName varchar(15)
Declare @ParentCountColumnName varchar(15)
Declare @ChildCountColumnName varchar(15)
Select @CountColumnName = '#Items'
Select @DayColumnName = 'Production Day'
Select @ShiftColumnName = 'Shift'
Select @CrewColumnName = 'Crew'
Select @ProcessOrderColumnName = 'Process Order'
Select @StatusColumnName = 'Status'
Select @StartColumnName = 'Input'
Select @EndColumnName = 'Initial'
Select @RemainingColumnName = 'Remaining'
Select @ProductColumnName = 'Product'
Select @ProductDescriptionColumnName = 'Description'
Select @RuntimeColumnName = 'Run Time'
Select @DowntimeColumnName = 'Down Time'
Select @DowntimeCountColumnName = '#Events'
Select @DowntimePercentColumnName = 'Down%'
Select @WasteColumnName = 'Waste'
Select @WastePercentColumnName = 'Waste%'
Select @ParentCountColumnName = 'Parent Count'
Select @ChildCountColumnName = 'Child Count'
Insert into #Prompts (PromptName, PromptValue) Values ('ReportName', @ReportName)
Select @CriteriaString = dbo.fnRS_Translate(@ReportId, 36204, 'Production For') + ' ' + (Select PU_Desc From Prod_Units Where PU_Id = @Unit)
Select @CriteriaString = @CriteriaString + ' ' + dbo.fnRS_Translate(@ReportId, 36176, 'From') + ' [' + convert(varchar(25), @StartTime,120) + '] ' + dbo.fnRS_Translate(@ReportId, 36177, 'To') + ' [' + convert(varchar(25), @EndTime,120) + ']'
Insert into #Prompts (PromptName, PromptValue) Values ('Criteria', @CriteriaString)
Insert into #Prompts (PromptName, PromptValue) Values ('GenerateTime', dbo.fnRS_Translate(@ReportId, 36178, 'Created') + ': ' + convert(varchar(25), getdate(),120))
Insert into #Prompts (PromptName, PromptValue) Values ('TotalSummary', dbo.fnRS_Translate(@ReportId, 36205, 'Grand Totals'))
Insert into #Prompts (PromptName, PromptValue) Values ('StatusSummary', dbo.fnRS_Translate(@ReportId, 36206, 'Status Summary'))
Insert into #Prompts (PromptName, PromptValue) Values ('ShiftSummary', dbo.fnRS_Translate(@ReportId, 36207, 'Shift Summary'))
Insert into #Prompts (PromptName, PromptValue) Values ('CrewSummary', dbo.fnRS_Translate(@ReportId, 36208, 'Crew Summary'))
Insert into #Prompts (PromptName, PromptValue) Values ('ProductSummary', dbo.fnRS_Translate(@ReportId, 36209, 'Product Summary'))
Insert into #Prompts (PromptName, PromptValue) Values ('OrderSummary', dbo.fnRS_Translate(@ReportId, 36210, 'Process Order Summary'))
Insert into #Prompts (PromptName, PromptValue) Values ('DaySummary', dbo.fnRS_Translate(@ReportId, 36211, 'Production Day Summary'))
Insert into #Prompts (PromptName, PromptValue) Values ('InputsVisible', convert(varchar(5),@DisplayGenealogyCounts))
Insert into #Prompts (PromptName, PromptValue) Values ('DimensionCount', Case When @DimensionAName Is Not Null Then '4' When @DimensionZName Is Not Null Then '3' When @DimensionYName Is Not Null Then '2' Else '1' End)
select * From #Prompts
Drop Table #Prompts
--**********************************************
-- Return Data For Report
--**********************************************
Create Table #Report (
  EventId int,
  EventNumber varchar(25),
  EventStatus varchar(25) NULL,
  ProductId int NULL,
  StartTime datetime NULL,
  EndTime datetime,
  ProcessOrderId int NULL,
  ProductionDay varchar(10),
  ShiftName varchar(10) NULL, 
  CrewName varchar(10) NULL, 
  DowntimeMinutes real NULL,
  DowntimeCount int NULL,
  WasteAmount real NULL,
  StartX real NULL,
  StartY real NULL,
  StartZ real NULL,
  StartA real NULL,
  EndX real NULL,
  EndY real NULL,
  EndZ real NULL,
  EndA real NULL,
  RemainingX real NULL,
  RemainingY real NULL,
  RemainingZ real NULL,
  RemainingA real NULL,
  ParentCount int NULL,
  ChildCount int NULL,
  Color int NULL,
  Hyperlink varchar(255) NULL
)
--*******************************************************************
--*******************************************************************
--*******************************************************************
--  Get Event List
--*******************************************************************
Insert Into #Report(EventId, EventNumber, EventStatus, StartTime, EndTime, ProductId, EndX, EndY, EndZ, EndA, RemainingX, RemainingY, RemainingZ, RemainingA, ProcessOrderId, Color, Hyperlink)
  Select e.event_id, e.event_num, s.ProdStatus_Desc, e.Start_Time, e.Timestamp, 
         Case When e.Applied_Product Is Null Then ps.Prod_Id Else e.Applied_Product End,
         d.initial_dimension_x, d.initial_dimension_y, d.initial_dimension_z, d.initial_dimension_a, 
         d.final_dimension_x, d.final_dimension_y, d.final_dimension_z, d.final_dimension_a,
         d.pp_id,
 	  Color = Case  
 	        When s.Status_Valid_For_Input <> 1 Then 1 --Red
 	        When s.Count_For_Production <> 1 Then 2 -- Blue
 	        Else -1 --Black
 	      End, 
         Hyperlink =  'EventDetail.aspx?Id=' + convert(varchar(15),e.event_id)
    From Events e
    Join Production_Starts ps on ps.PU_id = @Unit and 
                                 ps.Start_Time <= e.Timestamp and 
                                ((ps.End_Time > e.Timestamp) or (ps.End_Time Is Null))
    Join Production_Status s on s.ProdStatus_id = e.Event_Status and s.count_for_production = 1
    Left Outer Join Event_Details d on d.event_id = e.event_id
    Where e.PU_id = @Unit and
          e.Timestamp > @StartTime and 
          e.Timestamp <= @EndTime 
 	 -- Changed
Update #Report 
  Set StartTime = (Select max(e.Timestamp) From Events e where e.pu_id = @Unit and e.timestamp < #Report.EndTime and e.timestamp > @StartTime)
  Where StartTime Is Null
Update #Report 
  Set StartTime = @StartTime
  Where StartTime Is Null
Update #Report 
  Set ProcessOrderId = (Select min(ps.pp_id) From production_plan_starts ps where ps.pu_id = @Unit and ps.Start_Time <= #Report.EndTime and ((ps.End_Time > #Report.EndTime) or (ps.End_Time is Null)))
  Where ProcessOrderId Is Null
-- Changed
If (Select count(ProcessOrderId) From #Report) = 0 
  Select @NoOrder = 1
--*******************************************************************
--*******************************************************************
--*******************************************************************
--  Join Day, Shift Information
--*******************************************************************
Declare @ReferenceTime datetime
Declare @FirstShiftTime datetime
Declare @ProductionDayStart int
Declare @ShiftLength int
-- Changed
If (Select count(Start_Time) From Crew_Schedule Where PU_Id = @Unit and Start_Time <= @StartTime and End_Time > @StartTime) > 0
  Begin
    -- We DO Have A Crew Schedule For This Unit
    -- Get The Start Time At Midnight, Figure Out Production Day Start
    Select @ReferenceTime = convert(datetime, convert(varchar(10), @StartTime,102))
    Select @FirstShiftTime = min(Start_Time)
      From Crew_Schedule
      Where PU_Id = @Unit and
            Start_Time > @ReferenceTime and Start_Time <= @EndTime
    Select @ProductionDayStart = datediff(minute, @ReferenceTime, @FirstShiftTime)
    -- Join in the crew schedule and adjust the production day if necessary    
    Update #Report
      Set ProductionDay = Case
            When datediff(minute, convert(datetime, convert(varchar(10), r.EndTime,102)) ,r.EndTime) >= @ProductionDayStart Then convert(varchar(6), r.EndTime,109)
            Else convert(varchar(6), dateadd(day,-1,r.EndTime),109)
          End,
          ShiftName = s.shift_desc,
          CrewName = s.Crew_Desc
        From #Report r, Crew_Schedule s
        Where s.pu_id = @Unit and
              s.start_time <= r.EndTime and
              s.end_time > r.EndTime 
        -- Changed
        -- r.EndTime comes from the Events table
  End
Else
  Begin
    -- We DO NOT have a crew schedule for this unit, use The Default Crew Schedule
    Select @ProductionDayStart = (select convert(int,Value) from site_parameters where parm_id = 14) * 60 +  (select convert(int,Value) from site_parameters where parm_id = 15)
    Select @ShiftLength = (select convert(int,Value) from site_parameters where parm_id = 16)
    Update #Report 
      Set ProductionDay = Case
            When datediff(minute, convert(datetime, convert(varchar(10), #Report.EndTime,102)) ,#Report.EndTime) >= @ProductionDayStart Then convert(varchar(6), #Report.EndTime,109)
            Else convert(varchar(6), dateadd(day,-1,#Report.EndTime),109)
          End,
          ShiftName = Case
            When datediff(minute, convert(datetime, convert(varchar(10), #Report.EndTime,102)) ,#Report.EndTime) >= @ProductionDayStart Then convert(varchar(10),convert(int, (datediff(minute, convert(datetime, convert(varchar(10), #Report.EndTime,102)) ,#Report.EndTime) - @ProductionDayStart) / @ShiftLength) + 1)
            Else convert(varchar(10),convert(int, (datediff(minute, convert(datetime, convert(varchar(10), dateadd(day,-1,#Report.EndTime),102)) ,#Report.EndTime) - @ProductionDayStart) / @ShiftLength) + 1)
          End
     Select @NoCrew = 1
  End
--*******************************************************************
--*******************************************************************
--*******************************************************************
--  Join In Variable Data 
--*******************************************************************
Declare @VariableColumnNames varchar(3000)
Declare @VariableSummaryNames varchar(3000)
Declare @ThisColumnName varchar(100)
Declare @SQL varchar(7000)
Declare @SQL2 varchar(7000)
Declare @@VariableId int
Declare @@VariableName varchar(50)
DEclare @@Aggregate int
Declare @@NumberOfDigits int
Create Table #Variables (
  VarId int, 
  VarOrder int,
  VarDesc varchar(50),
  Aggregate int NULL,
  NumberOfDigits int NULL,
  UnitDesc varchar(50)
)
Declare @@MyUnitDesc varchar(50)
If @Variables Is not null and @Variables <> ''
  Insert Into #Variables 
    execute ('Select Distinct Var_Id, VarOrder = CharIndex(convert(varchar(10),Var_Id),' + '''' + @Variables + ''''+ ',1),  Coalesce(Test_Name, Var_Desc), Sampling_Type, var_precision, pu.pu_desc From Variables v Join prod_Units pu on v.pu_Id = pu.pu_Id Where Var_Id in (' + @Variables + ')' + ' and v.pu_id <> 0')
Select @VariableColumnNames = NULL
Declare Variable_Cursor Insensitive Cursor 
  For Select Top 10 VarId, VarDesc, Aggregate, NumberOfDigits, UnitDesc From #Variables Order By VarOrder
  For Read Only
Open Variable_Cursor
Fetch Next From Variable_Cursor Into @@VariableId, @@VariableName, @@Aggregate, @@NumberOfDigits, @@MyUnitDesc
While @@Fetch_Status = 0
  Begin
     --Select @ThisColumnName = @@VariableName
     --Select @ThisColumnName = @@VariableName + '_' + convert(varchar(3), @@VariableId)
 	 Select @ThisColumnName = @@MyUnitDesc + '_' + @@VariableName
 	 Select @ThisColumnName = Replace(@ThisColumnName, '[', '(')
 	 Select @ThisColumnName = Replace(@ThisColumnName, ']', ')')
     Select @SQL = 'Alter Table #Report Add [' + @ThisColumnName + '] varchar(25) NULL'
     Execute (@SQL)
     Select @SQL = 'Update #Report Set [' + @ThisColumnName + '] = t.Result ' 
     Select @SQL = @SQL + 'From #Report r ' 
     Select @SQL = @SQL + 'Join Tests t on t.Var_id = ' + Convert(varchar(20),@@VariableId) + ' ' 
     Select @SQL = @SQL + 'and t.Result_On = r.EndTime and t.Result_On Between ' + '''' + convert(varchar(30),@StartTime,109) + '''' + ' and ' + '''' + convert(varchar(30),@EndTime,109) + '''' + ' '  
     Execute (@SQL)
     If @VariableColumnNames Is Not Null
        Begin
          Select @VariableColumnNames = @VariableColumnNames + ','
          Select @VariableSummaryNames = @VariableSummaryNames + ','
        End
      Else
        Begin
          Select @VariableColumnNames = ''
          Select @VariableSummaryNames = ''
        End
      Select @VariableColumnNames = @VariableColumnNames + '[' + @ThisColumnName + '] AS [' +
           case 
             when @@NumberOfDigits Is Null Then 'A' 
             Else convert(varchar(5), @@NumberOfDigits) 
           End + 
           '_' +  @ThisColumnName + ']'
      Select @VariableSummaryNames = @VariableSummaryNames + 
           Case 
             when @@Aggregate in (1,24) Then 'Avg(convert(real,'
             when @@Aggregate in (4,25) Then 'Min(convert(real,'
             when @@Aggregate in (5,26) Then 'Max(convert(real,'
             when @@Aggregate in (6,27) Then 'Stdev(convert(real,'
             when @@Aggregate in (7,20) Then 'Sum(convert(real,'
             when @@Aggregate in (13,21) Then 'Count(convert(real,'
             Else 'Count(convert(real,'
           End +
           '[' + @ThisColumnName + '])) AS [' +
           case 
             when @@NumberOfDigits Is Null Then 'A' 
             Else 
 	            Case 
 	              when @@Aggregate in (1,24) Then convert(varchar(5), @@NumberOfDigits + 1)
 	              when @@Aggregate in (4,25) Then convert(varchar(5), @@NumberOfDigits + 1)
 	              when @@Aggregate in (5,26) Then convert(varchar(5), @@NumberOfDigits + 1)
 	              when @@Aggregate in (6,27) Then convert(varchar(5), @@NumberOfDigits + 2)
 	              when @@Aggregate in (7,20) Then convert(varchar(5), @@NumberOfDigits + 1)
 	              when @@Aggregate in (13,21) Then convert(varchar(5), 0)
 	              Else convert(varchar(5), 0)
 	            End 
           End + 
           '_' + @ThisColumnName + ']' 
 	 Fetch Next From Variable_Cursor Into @@VariableId, @@VariableName, @@Aggregate, @@NumberOfDigits, @@MyUnitDesc
  End --@@Fetch_Status = 0
Close Variable_Cursor
Deallocate Variable_Cursor  
Drop Table #Variables
--*******************************************************************
--*******************************************************************
-- Set Up Aggregate Strings For Dimensions
Select @DimensionXAggregateName = Case
     when @DimensionXAggregate = 1 Then 'Avg('
     when @DimensionXAggregate = 4 Then 'Min('
     when @DimensionXAggregate = 5 Then 'Max('
     when @DimensionXAggregate = 6 Then 'Stdev('
     when @DimensionXAggregate = 7 Then 'Sum('
     when @DimensionXAggregate = 13 Then 'Count('
     Else 'Sum('
End
Select @DimensionYAggregateName = Case
     when @DimensionYAggregate = 1 Then 'Avg('
     when @DimensionYAggregate = 4 Then 'Min('
     when @DimensionYAggregate = 5 Then 'Max('
     when @DimensionYAggregate = 6 Then 'Stdev('
     when @DimensionYAggregate = 7 Then 'Sum('
     when @DimensionYAggregate = 13 Then 'Count('
     Else 'Sum('
End
Select @DimensionZAggregateName = Case
     when @DimensionZAggregate = 1 Then 'Avg('
     when @DimensionZAggregate = 4 Then 'Min('
     when @DimensionZAggregate = 5 Then 'Max('
     when @DimensionZAggregate = 6 Then 'Stdev('
     when @DimensionZAggregate = 7 Then 'Sum('
     when @DimensionZAggregate = 13 Then 'Count('
     Else 'Sum('
End
Select @DimensionAAggregateName = Case
     when @DimensionAAggregate = 1 Then 'Avg('
     when @DimensionAAggregate = 4 Then 'Min('
     when @DimensionAAggregate = 5 Then 'Max('
     when @DimensionAAggregate = 6 Then 'Stdev('
     when @DimensionAAggregate = 7 Then 'Sum('
     when @DimensionAAggregate = 13 Then 'Count('
     Else 'Sum('
End
--*******************************************************************
--  Cursor Through Events To Get Event Specific Information
--*******************************************************************
Declare @EventWaste real
Declare @EventDowntime real
Declare @EventDowntimeCount int
Declare @EventParentCount int
Declare @EventChildCount int
Declare @EventParentX real
Declare @EventParentY real
Declare @EventParentZ real
Declare @EventParentA real
Declare @@EventId int
Declare @@StartTime datetime
Declare @@EndTime datetime
If @DisplayDowntime <> 0 or @DisplayWaste <> 0 or @DisplayGenealogyCounts <> 0 
 	 Begin
 	  	 Create Table #Downtime (
 	  	   StartTime datetime,
 	  	   EndTime datetime NULL,
 	  	   Uptime int NULL
 	  	 )
 	  	  	 
 	  	 Create Table #GenealogyData (
 	  	   EventParentCount int NULL,
 	  	   EventChildCount int NULL,
 	  	   EventParentX real NULL,
 	  	   EventParentY real NULL,
 	  	   EventParentZ real NULL,
 	  	   EventParentA real NULL
 	  	 )
 	 
 	  	 
 	  	 Declare Event_Cursor Insensitive Cursor 
 	  	   For Select EventId, StartTime, EndTime From #Report
 	  	   For Read Only
 	  	 
 	  	 Open Event_Cursor
 	 
 	  	 Fetch Next From Event_Cursor Into @@EventId, @@StartTime, @@EndTime
 	 
 	  	 While @@Fetch_Status = 0
 	  	  	 Begin 	 
 	  	  	  	 Select @EventWaste = 0
 	  	  	  	 Select @EventDowntime = 0
 	  	  	  	 Select @EventParentCount = 0
 	  	  	  	 Select @EventChildCount = 0
 	  	  	  	 Select @EventParentX = NULL
 	  	  	  	 Select @EventParentY = NULL
 	  	  	  	 Select @EventParentZ = NULL
 	  	  	  	 Select @EventParentA = NULL
 	    
 	  	  	  	 -- Get The Basic Parent Data For the "Start" Columns, 
 	  	  	  	 If @DisplayGenealogyCounts <> 0
 	  	  	  	 Begin
 	  	  	  	  	 Truncate Table #GenealogyData
 	  	  	  	  	 Select @SQL = 'Insert Into #GenealogyData (EventParentCount, EventParentX, EventParentY, EventParentZ, EventParentA) '
 	  	  	  	  	 Select @SQL = @SQL + 'Select EventParentCount = count(event_id), '
 	  	  	  	  	 Select @SQL = @SQL + 'EventParentX = ' + @DimensionXAggregateName + 'coalesce(Dimension_X, 0.0)), '
 	  	  	  	  	 Select @SQL = @SQL + 'EventParentY = ' + @DimensionYAggregateName + 'coalesce(Dimension_Y, 0.0)), '
 	  	  	  	  	 Select @SQL = @SQL + 'EventParentZ = ' + @DimensionZAggregateName + 'coalesce(Dimension_Z, 0.0)), '
 	  	  	  	  	 Select @SQL = @SQL + 'EventParentA = ' + @DimensionAAggregateName + 'coalesce(Dimension_A, 0.0)) '
 	  	  	  	  	 Select @SQL = @SQL + 'From Event_Components Where Event_id = ' + convert(varchar(15),@@EventId)          
 	  	  	  	  	 Execute (@SQL) 
 	  	  	  	  	 
 	  	  	  	  	 Select @EventParentCount = EventParentCount, 
 	  	  	  	  	 @EventParentX = EventParentX,
 	  	  	  	  	 @EventParentY = EventParentY,
 	  	  	  	  	 @EventParentZ = EventParentZ,
 	  	  	  	  	 @EventParentA = EventParentA
 	  	  	  	  	 From #GenealogyData
 	  	  	  	  	 
 	  	  	  	  	 Select @EventChildCount = count(event_id)
 	  	  	  	  	 From Event_Components 
 	  	  	  	  	 Where Source_Event_id = @@EventId 	  	 
 	  	  	  	 End 
 	  	 
 	  	  	     -- Get The Total Waste Amount
 	  	  	     If @DisplayWaste <> 0
 	  	  	         Select @EventWaste = sum(amount)
 	  	  	         From Waste_Event_Details
 	  	  	         Where Event_Id = @@EventId     
 	  	 
 	  	  	     -- Get The Total Downtime Minutes
 	  	  	  	 If @DisplayDowntime <> 0
 	  	  	  	  	 Begin
 	  	  	  	         Truncate Table #Downtime
 	  	  	  	         
 	  	  	  	         Insert Into #Downtime 
 	  	  	  	           Select Start_Time, End_Time, Case When Uptime Is Null Then Null Else 1 End
 	  	  	  	           From Timed_Event_Details
 	  	  	  	             Where PU_Id = @Unit and 
 	  	  	  	  	  	  	  	   ((Start_Time < @@EndTime) and 
 	  	  	  	                   (End_Time > @@StartTime or End_Time Is Null))
 	  	  	  	  	  	  	  	 /*
 	  	  	  	                   ((Start_Time >= @@StartTime and Start_Time < @@EndTime) or 
 	  	  	  	                   (End_Time > @@StartTime and End_Time <= @@EndTime) or 
 	  	  	  	                   (Start_Time < @@StartTime and (End_Time > @@EndTime or End_Time Is Null)))
 	  	  	  	  	  	  	  	 */
 	  	  	  	  	  	 -- Changed
 	  	  	  	  	  	 -- @@StartTime and @@EndTime were derived from the Events table
 	  	  	  	         Update #Downtime 
 	  	  	  	           Set StartTime = Case when StartTime < @@StartTime Then @@StartTime Else StartTime End,
 	  	  	  	               EndTime = Case When EndTime > @@EndTime Then @@EndTime When EndTime Is Null Then @@EndTime Else EndTime End
 	  	  	  	 
 	  	  	  	         Select @EventDowntime = sum(datediff(second,StartTime, EndTime) / 60.0),
 	  	                    @EventDowntimeCount = count(Uptime)
 	  	  	  	            From #Downtime   	 
 	  	  	  	       End
 	  	  	  	  	  	 
 	  	  	     Update #Report
 	  	  	       Set DowntimeMinutes = @EventDowntime, DowntimeCount = @EventDowntimeCount, WasteAmount = @EventWaste, 
 	  	  	           StartX = @EventParentX, StartY = @EventParentY, StartZ = @EventParentZ, StartA = @EventParentA, 
 	  	  	           ParentCount = @EventParentCount, ChildCount = @EventChildCount
 	  	  	       Where EventId = @@EventId
 	  	  	  	 
 	  	  	     Fetch Next From Event_Cursor Into @@EventId, @@StartTime, @@EndTime
 	  	  	 End --@@Fetch_Status = 0
 	  	 
 	  	  	 Close Event_Cursor
 	  	  	 Deallocate Event_Cursor   	  	 
 	  	  	 Drop Table #Downtime
 	  	  	 Drop Table #GenealogyData
 	   End --@DisplayDowntime <> 0 or @DisplayWaste <> 0 or @DisplayGenealogyCounts <> 0 
--*******************************************************************
--  Get Total Downtime, Waste, And Amount Statistics
--*******************************************************************
Declare @TotalProduction real
Declare @TotalWaste real
Declare @TotalDowntime real
Select @TotalProduction = sum(EndX), 
       @TotalWaste = sum(WasteAmount),
       @TotalDowntime = sum(DowntimeMinutes)
  From #Report
-- Total Production Could Be Null
If @TotalProduction Is Null 
  Select @TotalProduction = 1
--*******************************************************************
--*******************************************************************
--*******************************************************************
--  Return Summary Data  
--*******************************************************************
Select @SQL = ',Count(EventNumber) As [0_' + @CountColumnName + '] '
If @DisplayGenealogyCounts <> 0 
 	 Begin
 	  	 If @DimensionXName Is Not Null
 	  	   Select @SQL = @SQL + ',' + @DimensionXAggregateName + 'StartX) as [2_' + @StartColumnName + ' ' + @DimensionXName + '] '
 	  	 If @DimensionYName Is Not Null
 	  	   Select @SQL = @SQL + ',' + @DimensionYAggregateName + 'StartY) as [2_' + @StartColumnName + ' ' + @DimensionYName + '] '
 	  	 If @DimensionZName Is Not Null
 	  	   Select @SQL = @SQL + ',' + @DimensionZAggregateName + 'StartZ) as [2_' + @StartColumnName + ' ' + @DimensionZName + '] '
 	  	 If @DimensionAName Is Not Null
 	  	   Select @SQL = @SQL + ',' + @DimensionAAggregateName + 'StartA) as [2_' + @StartColumnName + ' ' + @DimensionAName + '] '
 	 End
If @DimensionXName Is Not Null
 	 Select @SQL = @SQL + ',' + @DimensionXAggregateName + 'EndX) as [2_' + @EndColumnName + ' ' + @DimensionXName + '] '
If @DimensionYName Is Not Null
 	 Select @SQL = @SQL + ',' + @DimensionYAggregateName + 'EndY) as [2_' + @EndColumnName + ' ' + @DimensionYName + '] '
If @DimensionZName Is Not Null
 	 Select @SQL = @SQL + ',' + @DimensionZAggregateName + 'EndZ) as [2_' + @EndColumnName + ' ' + @DimensionZName + '] '
If @DimensionAName Is Not Null
 	 Select @SQL = @SQL + ',' + @DimensionAAggregateName + 'EndA) as [2_' + @EndColumnName + ' ' + @DimensionAName + '] '
If @DimensionXName Is Not Null
 	 Select @SQL = @SQL + ',' + @DimensionXAggregateName + 'RemainingX) as [2_' + @RemainingColumnName + ' ' + @DimensionXName + '] '
If @DimensionYName Is Not Null
 	 Select @SQL = @SQL + ',' + @DimensionYAggregateName + 'RemainingY) as [2_' + @RemainingColumnName + ' ' + @DimensionYName + '] '
If @DimensionZName Is Not Null
 	 Select @SQL = @SQL + ',' + @DimensionZAggregateName + 'RemainingZ) as [2_' + @RemainingColumnName + ' ' + @DimensionZName + '] '
If @DimensionAName Is Not Null
 	 Select @SQL = @SQL + ',' + @DimensionAAggregateName + 'RemainingA) as [2_' + @RemainingColumnName + ' ' + @DimensionAName + '] '
If @VariableSummaryNames Is Not Null
 	 Select @SQL = @SQL + ',' + @VariableSummaryNames + ' '
If @DisplayWaste <> 0 
 	 Begin
 	  	 Select @SQL = @SQL + ',sum(WasteAmount) as [2_' + @WasteColumnName + '] '
 	  	 Select @SQL = @SQL + ',' + 'sum(WasteAmount) / ' + convert(varchar(30), @TotalProduction) + '* 100.0 as [P_' + @WastePercentColumnName + '] '   
 	 End
If @DisplayDowntime <> 0
 	 Begin
 	  	 Select @SQL = @SQL + ',' + 'sum(Datediff(second, StartTime, EndTime) / 60.0 - coalesce(DowntimeMinutes,0.0)) * 60' + ' as [H_' + @RuntimeColumnName + '] '
 	  	 Select @SQL = @SQL + ',sum(DowntimeMinutes) * 60' + ' as [H_' + @DowntimeColumnName + '] '
 	  	 Select @SQL = @SQL + ',sum(DowntimeCount)' + ' as [0_' + @DowntimeCountColumnName + '] '
 	  	 Select @SQL = @SQL + ',' + '(sum(DowntimeMinutes) / sum(Datediff(second, StartTime, EndTime) / 60.0)) * 100.0  as [P_' + @DowntimePercentColumnName + '] '   
 	 End
If @DisplayGenealogyCounts <> 0
 	 Begin
 	  	 Select @SQL = @SQL + ',sum(ParentCount) as [0_' + @ParentCountColumnName  + '] '
 	  	 Select @SQL = @SQL + ',sum(ChildCount) as [0_' + @ChildCountColumnName  + '] '
 	 End
-- Return Totals and Summary Resultsets
-- Grand Total Resultset
Select @SQL2 = 'Select ' + '''' + 'Total' + '''' + 'as [SummaryType], null as [HyperLink] '
Select @SQL2 = @SQL2 + @SQL 
Select @SQL2 = @SQL2 + ' From #Report' 
Exec (@SQL2)
If @SummarizeDay <> 0
 	 Begin
 	  	 Print '@SummarizeDay'
 	  	 Select @SQL2 = 'Select ' + '''' + 'Day' + '''' + 'as [SummaryType], null as [HyperLink] '
 	  	 Select @SQL2 = @SQL2 + ',ProductionDay as [T_' + @DayColumnName + '] '
 	  	 Select @SQL2 = @SQL2 + @SQL 
 	  	 Select @SQL2 = @SQL2 + ' From #Report Group By ProductionDay Order By min(StartTime) ASC' 
 	  	 Exec (@SQL2)
 	 End
If @SummarizeShift <> 0
 	 Begin
 	  	 Print '@SummarizeShift'
 	  	 Select @SQL2 = 'Select ' + '''' + 'Shift' + '''' + 'as [SummaryType], null as [HyperLink] '
 	  	 Select @SQL2 = @SQL2 + ',ShiftName as [T_' + @ShiftColumnName + '] '
 	  	 Select @SQL2 = @SQL2 + @SQL 
 	  	 Select @SQL2 = @SQL2 + ' From #Report Group By ShiftName Order By ShiftName ASC' 
 	  	 Exec (@SQL2)
 	 End
If @SummarizeCrew <> 0 and @NoCrew = 0
 	 Begin
 	  	 Print '@SummarizeCrew'
 	  	 Select @SQL2 = 'Select ' + '''' + 'Crew' + '''' + 'as [SummaryType], null as [HyperLink] '
 	  	 Select @SQL2 = @SQL2 + ',CrewName as [T_' + @CrewColumnName + '] '
 	  	 Select @SQL2 = @SQL2 + @SQL 
 	  	 Select @SQL2 = @SQL2 + ' From #Report Group By CrewName Order By CrewName ASC' 
 	  	 Exec (@SQL2)
 	 End
If @SummarizeOrder <> 0 and @NoOrder = 0
 	 Begin
 	  	 Print '@SummarizeOrder'
 	  	 Select @SQL2 = 'Select ' + '''' + 'Order' + '''' + 'as [SummaryType], ' + '''' + 'ProcessOrderDetail.aspx?Id=' + '''' + '+ convert(varchar(15),ProcessOrderId)' + ' as [HyperLink] '
 	  	 Select @SQL2 = @SQL2 + ',Min(pp.Process_Order) as [T_' + @ProcessOrderColumnName + '] '
 	  	 Select @SQL2 = @SQL2 + @SQL 
 	  	 Select @SQL2 = @SQL2 + ' From #Report Join Production_Plan pp on pp.pp_id = #Report.ProcessOrderId Group By ProcessOrderId Order By min(StartTime) ASC' 
 	  	 Exec (@SQL2)
 	 End
If @SummarizeProduct <> 0
 	 Begin
 	  	 Print '@SummarizeProduct'
 	  	 Select @SQL2 = 'Select ' + '''' + 'Product' + '''' + 'as [SummaryType], null as [HyperLink] '
 	  	 Select @SQL2 = @SQL2 + ',Min(p.Prod_Code) as [T_' + @ProductColumnName + '] '
 	  	 Select @SQL2 = @SQL2 + ',Min(p.Prod_Desc) as [T_' + @ProductDescriptionColumnName + '] '
 	  	 Select @SQL2 = @SQL2 + @SQL 
 	  	 Select @SQL2 = @SQL2 + ' From #Report Join Products p on p.prod_id = #Report.ProductId Group By ProductId Order By min(StartTime) ASC' 
 	  	 Exec (@SQL2)
 	 End
If @SummarizeStatus <> 0
 	 Begin
 	  	 Print '@SummarizeStatus'
 	  	 Select @SQL2 = 'Select ' + '''' + 'Status' + '''' + 'as [SummaryType], null as [HyperLink] '
 	  	 Select @SQL2 = @SQL2 + ',EventStatus as [T_' + @StatusColumnName + '] '
 	  	 Select @SQL2 = @SQL2 + @SQL 
 	  	 Select @SQL2 = @SQL2 + ' From #Report Group By EventStatus Order By EventStatus ASC' 
 	  	 Exec (@SQL2)
 	 End
--*******************************************************************
--  Return Detailed Data  
--*******************************************************************
Select @SQL = 'Select '
Select @SQL = @SQL + 'Color, Hyperlink '
Select @SQL = @SQL + ',ProductionDay as [T_' + @DayColumnName + '] '
Select @SQL = @SQL + ',ShiftName as [T_' + @ShiftColumnName + '] '
If @NoCrew = 0 
  Select @SQL = @SQL + ',CrewName as [T_' + @CrewColumnName + '] '
Else 
  Select @SQL = @SQL + ',X_Crew = NULL '
If @NoOrder = 0
  Select @SQL = @SQL + ',pp.Process_Order as [T_' + @ProcessOrderColumnName + '] '
Else
  Select @SQL = @SQL + ',X_ProcessOrder = NULL'
Select @SQL = @SQL + ',p.Prod_Code as [T_' + @ProductColumnName + '] '
Select @SQL = @SQL + ',EventNumber as [T_' + @EventName + '] '
Select @SQL = @SQL + ',EventStatus as [T_' + @StatusColumnName + '] '
Select @SQL = @SQL + ',StartTime as [D_' + 'Start Time' + '] '
Select @SQL = @SQL + ',EndTime as [D_' + 'End Time' + '] '
If @DisplayGenealogyCounts <> 0 
  Begin
 	  	 If @DimensionXName Is Not Null
 	  	   Select @SQL = @SQL + ',StartX as [2_' + @StartColumnName + ' ' + @DimensionXName + '] '
 	  	 If @DimensionYName Is Not Null
 	  	   Select @SQL = @SQL + ',StartY as [2_' + @StartColumnName + ' ' + @DimensionYName + '] '
 	  	 If @DimensionZName Is Not Null
 	  	   Select @SQL = @SQL + ',StartZ as [2_' + @StartColumnName + ' ' + @DimensionZName + '] '
 	  	 If @DimensionAName Is Not Null
 	  	   Select @SQL = @SQL + ',StartA as [2_' + @StartColumnName + ' ' + @DimensionAName + '] '
  End
If @DimensionXName Is Not Null
  Select @SQL = @SQL + ',EndX as [2_' + @EndColumnName + ' ' + @DimensionXName + '] '
If @DimensionYName Is Not Null
  Select @SQL = @SQL + ',EndY as [2_' + @EndColumnName + ' ' + @DimensionYName + '] '
If @DimensionZName Is Not Null
  Select @SQL = @SQL + ',EndZ as [2_' + @EndColumnName + ' ' + @DimensionZName + '] '
If @DimensionAName Is Not Null
  Select @SQL = @SQL + ',EndA as [2_' + @EndColumnName + ' ' + @DimensionAName + '] '
If @DimensionXName Is Not Null
  Select @SQL = @SQL + ',RemainingX as [2_' + @RemainingColumnName + ' ' + @DimensionXName + '] '
If @DimensionYName Is Not Null
  Select @SQL = @SQL + ',RemainingY as [2_' + @RemainingColumnName + ' ' + @DimensionYName + '] '
If @DimensionZName Is Not Null
  Select @SQL = @SQL + ',RemainingZ as [2_' + @RemainingColumnName + ' ' + @DimensionZName + '] '
If @DimensionAName Is Not Null
  Select @SQL = @SQL + ',RemainingA as [2_' + @RemainingColumnName + ' ' + @DimensionAName + '] '
Select @SQL = @SQL + coalesce(',' + @VariableColumnNames, '') + ' '
If @DisplayWaste <> 0 
  Begin
    Select @SQL = @SQL + ',WasteAmount as [2_' + @WasteColumnName + '] '
    Select @SQL = @SQL + ',' + 'WasteAmount / ' + convert(varchar(30), @TotalProduction) + '* 100.0 as [P_' + @WastePercentColumnName + '] '   
  End
If @DisplayDowntime <> 0
  Begin
    Select @SQL = @SQL + ',' + '(Datediff(second, StartTime, EndTime) / 60.0 - coalesce(DowntimeMinutes,0.0)) * 60' + ' as [H_' + @RuntimeColumnName + '] '
    Select @SQL = @SQL + ',DowntimeMinutes * 60' + ' as [H_' + @DowntimeColumnName + '] '
    Select @SQL = @SQL + ',DowntimeCount' + ' as [0_' + @DowntimeCountColumnName + '] '
    Select @SQL = @SQL + ',' + 'DowntimeMinutes / ' + convert(varchar(30), @TotalDowntime) + '* 100.0  as [P_' + @DowntimePercentColumnName + '] '   
  End
If @DisplayGenealogyCounts <> 0
  Begin
    Select @SQL = @SQL + ',ParentCount as [0_' + @ParentCountColumnName  + '] '
    Select @SQL = @SQL + ',ChildCount as [0_' + @ChildCountColumnName  + '] '
  End
If @NoOrder = 0 
  Select @SQL = @SQL + 'From #Report Join Products p on p.Prod_id = #Report.ProductId Left Outer Join Production_Plan pp on pp.pp_id = #Report.ProcessOrderId Order By EndTime ASC, ShiftName ASC, ProcessOrderId ASC'
Else
  Select @SQL = @SQL + 'From #Report Join Products p on p.Prod_id = #Report.ProductId Order By EndTime ASC, ShiftName ASC, ProcessOrderId ASC'
Execute (@SQL)
Drop Table #Report
