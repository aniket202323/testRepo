CREATE PROCEDURE  dbo.spASP_wrOEESummary
     @ReportId int = NULL,
     @RunId int = NULL 	  	  	  	  	  	 
AS
--***************************************************************************************************************************************/
/*****************************************************
set nocount on
Declare @ReportId int, @RunId int
Select @ReportId=734 --696
exec spASP_wrOEESummary 734
--*****************************************************/
Create Table #Prompts (
 	 PromptId int identity(1,1),
 	 PromptName varchar(20),
 	 PromptValue varchar(1000)
)
Declare @ReturnValue varchar(7000)
Declare @ReportName varchar(255)
Declare @CriteriaString varchar(1000)
Declare @StartTime datetime
Declare @EndTime datetime
Declare @Unit int
Declare @SummarizeDay int
Declare @SummarizeProduct int
Declare @SummarizeOrder int
Declare @SummarizeShift int
Declare @SummarizeCrew int
Declare @ProficyDashBoardPath varchar(50)
Declare @HideEventTimeSummary int
Declare @DisplayESignature int
Select @ProficyDashBoardPath = Value From Site_Parameters Where Parm_Id = 160
Declare @NonProductiveTimeFilter int
Declare @NPTLabel varchar(255)
Declare @NPTLabelDefault varchar(255)
select @NPTLabelDefault = '(npt)'
if (Select Count(*) from Site_Parameters where parm_id = 316) = 0
  Select @NPTLabel=@NPTLabelDefault
Else
  select @NPTLabel = Coalesce(case Value when '' then @NPTLabelDefault else value end, @NPTLabelDefault) from Site_Parameters where parm_Id = 316
-----------------------------------------------------------------------------
-- These Parameters Must Be Present For The Report To Function Correctly
-----------------------------------------------------------------------------
--------------
-- Display E-Signature
--------------
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'DisplayESignature', @ReportId, @ReturnValue output
Select @DisplayESignature = ABS(Coalesce(convert(int,@ReturnValue), 0))
--------------
-- Non-Productive Filter
--------------
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'NonProductiveTimeFilter', @ReportId, @ReturnValue output
Select @NonProductiveTimeFilter = ABS(Coalesce(convert(int,@ReturnValue), 0))
Print 'Non-Productive Filter is ' + Case when @NonProductiveTimeFilter = 0 then 'OFF' Else 'ON' End
--------------
-- StartTime
--------------
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'StartTime', @ReportId, @ReturnValue output
If (@ReturnValue Is Null) or (LTrim(RTrim(@ReturnValue)) = '')
  Begin
    exec spRS_AddEngineActivity @ReportName, 0, 'Required [StartTime] Parameter Is Missing', 2, @ReportId, @RunId
    Raiserror('Required [StartTime] Parameter Is Missing',16,1)
    return
  End
Select @StartTime = Convert(DateTime, @ReturnValue)
--------------
-- EndTime
--------------
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'EndTime', @ReportId, @ReturnValue output
If (@ReturnValue Is Null) or (LTrim(RTrim(@ReturnValue)) = '')
  Begin
    exec spRS_AddEngineActivity @ReportName, 0, 'Required [EndTime] Parameter Is Missing', 2, @ReportId, @RunId
    Raiserror('Required [EndTime] Parameter Is Missing',16,1)
    return
  End
Select @EndTime = Convert(DateTime, @ReturnValue)
--------------
-- Master Unit / Unit
--------------
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'MasterUnit', @ReportId, @ReturnValue output
If (@ReturnValue Is Null) or (LTrim(RTrim(@ReturnValue)) = '')
  Begin
     exec spRS_GetReportParamValue 'Unit', @ReportId, @ReturnValue output
     If (@ReturnValue Is Null) or (LTrim(RTrim(@ReturnValue)) = '')
       Begin
         exec spRS_AddEngineActivity @ReportName, 0, 'Required [MasterUnit or Unit] Parameter Is Missing', 2, @ReportId, @RunId
         Raiserror('Required [MasterUnit or Unit] Parameter Is Missing',16,1)
         return
       End
  End
Select @Unit = Convert(Int, @ReturnValue)
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'HideEventTimestampSummary', @ReportId, @ReturnValue output
Select @HideEventTimeSummary = Case @ReturnValue When NULL then 0 Else abs(Convert(INT, @ReturnValue)) End
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'ReportName', @ReportId, @ReturnValue output
Select @ReportName = Case @ReturnValue When NULL then 'OEE Summary' Else @ReturnValue End
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'SummarizeByDay', @ReportId, @ReturnValue output
Select @SummarizeDay = Case @ReturnValue When NULL then -1 Else Convert(INT, @ReturnValue) End
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'SummarizeByProduct', @ReportId, @ReturnValue output
Select @SummarizeProduct = Case @ReturnValue When NULL then -1 Else Convert(INT, @ReturnValue) End
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'SummarizeByOrder', @ReportId, @ReturnValue output
Select @SummarizeOrder = Case @ReturnValue When NULL then -1 Else Convert(INT, @ReturnValue) End
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'SummarizeByShift', @ReportId, @ReturnValue output
Select @SummarizeShift = Case @ReturnValue When NULL then -1 Else Convert(INT, @ReturnValue) End
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'SummarizeByCrew', @ReportId, @ReturnValue output
Select @SummarizeCrew = Case @ReturnValue When NULL then -1 Else Convert(INT, @ReturnValue) End
Declare @Production_Variable int
Select @Production_Variable = Production_Variable from prod_Units where pu_Id = @Unit
Select @CriteriaString = dbo.fnRS_Translate(@ReportId, 36204, 'Production For') + ' ' + (Select PU_Desc From Prod_Units Where PU_Id = @Unit)
Select @CriteriaString = @CriteriaString + 
 	 Case 
 	  	 When @NonProductiveTimeFilter=0 Then '<br><i>' + @NPTLabel + ' ' + dbo.fnRS_Translate(@ReportId, 36026, 'Contains') + ' ' + dbo.fnRS_Translate(@ReportId, 42120, 'Non-Productive Time') + '</i>' Else '<br><i>' + dbo.fnRS_Translate(@ReportId, 35193, 'Non-Productive Time Removed') + '</i>' 
 	 End
Insert into #Prompts (PromptName, PromptValue) Values ('ReportName', @ReportName)
Insert into #Prompts (PromptName, PromptValue) Values ('Criteria', @CriteriaString)
Insert into #Prompts (PromptName, PromptValue) Values ('GenerateTime',convert(varchar(25), getdate(),120))
Insert into #Prompts (PromptName, PromptValue) Values ('StartTime', convert(varchar(25), @StartTime,120))
Insert into #Prompts (PromptName, PromptValue) Values ('EndTime', convert(varchar(25), @EndTime,120))
Insert into #Prompts (PromptName, PromptValue) Values ('DisplayESignature', @DisplayESignature)
Insert into #Prompts (PromptName, PromptValue) Values ('RSID_2', 'OEE Summary')
If @SummarizeDay = -1
Insert into #Prompts (PromptName, PromptValue) Values ('RSID_3', 'Production Day Summary')
If @SummarizeShift = -1
Insert into #Prompts (PromptName, PromptValue) Values ('RSID_4', 'Shift Summary')
If @SummarizeCrew = -1
Insert into #Prompts (PromptName, PromptValue) Values ('RSID_5', 'Crew Summary')
If @SummarizeProduct = -1
Insert into #Prompts (PromptName, PromptValue) Values ('RSID_6', 'Product Summary')
If @SummarizeOrder = -1
Insert into #Prompts (PromptName, PromptValue) Values ('RSID_7', 'Process Order Summary')
If @HideEventTimeSummary = 0
  Begin
 	 If @Production_Variable Is Null
 	   Insert into #Prompts (PromptName, PromptValue) Values ('RSID_8', 'Event Summary')
 	 Else
 	   Insert into #Prompts (PromptName, PromptValue) Values ('RSID_8', 'Test Summary')
  End
Select * from #Prompts
DROP TABLE #Prompts
------------
Create Table #OEEStatistics(
 	 Actual_Speed real,
 	 Ideal_Speed real,
 	 Performance_Rate real,
 	 Ideal_Production real,
 	 Net_Production real,
 	 Waste real,
 	 Quality_Rate real,
 	 Run_Time real,
 	 Loading_Time real,
 	 Available_Rate real,
 	 OEE real
)
Create Table #OEESummary_ShiftCrew(
 	 Row_Id int NOT NULL IDENTITY (1, 1),
 	 Shift_Desc varchar(10),
 	 Crew_Desc varchar(10),
 	 Process_Order_Id int,
 	 Event_Id int,
 	 Event_Number varchar(25),
 	 Start_Time datetime,
 	 End_Time datetime,
 	 Product_Id int,
 	 Product_Desc varchar(50),
 	 Actual_Speed real,
 	 Ideal_Speed real,
 	 Performance_Rate real,
 	 Ideal_Production real,
 	 Net_Production real,
 	 Waste real,
 	 Quality_Rate real,
 	 Run_Time real,
 	 Loading_Time real,
 	 Available_Rate real,
 	 OEE real,
 	 Non_Productive_Seconds int
)
Create Table #OEESummary_ProductionDay(
 	 Row_Id int NOT NULL IDENTITY (1, 1),
 	 Production_Day datetime, 
 	 Process_Order_Id int,
 	 Event_Id int,
 	 Event_Number varchar(25),
 	 Start_Time datetime,
 	 End_Time datetime,
 	 Product_Id int,
 	 Product_Desc varchar(50),
 	 Actual_Speed real,
 	 Ideal_Speed real,
 	 Performance_Rate real,
 	 Ideal_Production real, 
 	 Net_Production real,
 	 Waste real,
 	 Quality_Rate real,
 	 Run_Time real,
 	 Loading_Time real,
 	 Available_Rate real,
 	 OEE real,
 	 Non_Productive_Seconds int
)
Create Table #OEESummary_Raw(
 	 Row_Id int NOT NULL IDENTITY (1, 1),
 	 Process_Order_Id int,
 	 Event_Id int,
 	 Event_Number varchar(25),
 	 Start_Time datetime,
 	 End_Time datetime,
 	 Product_Id int,
 	 Product_Desc varchar(50),
 	 Actual_Speed real,
 	 Ideal_Speed real,
 	 Performance_Rate real,
 	 Ideal_Production real,
 	 Net_Production real,
 	 Waste real,
 	 Quality_Rate real,
 	 Run_Time real,
 	 Loading_Time real,
 	 Available_Rate real,
 	 OEE real,
 	 TEST_Id BigInt,
 	 Non_Productive_Seconds int,
 	 Perform_User_Id int,
 	 Verify_User_Id int,
 	 Perform_Username varchar(30),
 	 Verify_Username varchar(30)
)
Create Table #EventTimes (
 	 Start_Time datetime,
 	 End_Time datetime,
 	 Product_Id int,
 	 Product_Desc varchar(50),
 	 Event_Id int,
 	 Event_Number varchar(25),
 	 Process_Order_Id int,
 	 TEST_Id BigInt,
 	 Productive_Start_Time datetime,
 	 Productive_End_Time datetime,
 	 Non_Productive_Seconds int,
 	 Perform_User_Id int,
 	 Verify_User_Id int
)
Create Table #CrewSchedule(
     Start_Time datetime,
     End_Time datetime,
     Shift_Desc varchar(10),
     Crew_Desc varchar(10),
     Shift_Duration int
)
-- Mill Start Time (i.e. 7:00:00)
Declare @MillStartTime varchar(8)
------------------------------------------------------
-- Get Mill Start Time
------------------------------------------------------
Select @MillStartTime = dbo.fnRS_GetMillStartTime()
------------------------------------------------------
-- Get Crew Schedule For Time Frame
------------------------------------------------------
Insert Into #CrewSchedule(Start_Time, End_Time, Shift_Desc, Crew_Desc) select * from dbo.fnRS_wrGetCrewSchedule(@StartTime, @EndTime, @Unit)
Update #CrewSchedule Set Shift_Duration = DateDiff(mi, Start_Time, End_Time)
------------------------------------------------------
-- Check for variable based production
------------------------------------------------------
If @Production_Variable Is Not Null
 	 Begin
 	  	 --Print '** Variable Based Production **'
 	  	 Insert into #EventTimes(Start_Time, End_Time, Product_Id, TEST_Id, perform_User_Id, verify_user_Id)
 	  	 select @StartTime, t.Result_On, ps.Prod_Id, t.test_Id , es.perform_User_Id, es.verify_user_Id
 	  	 from tests_NPT T
 	  	 Join Production_Starts ps on ps.PU_id = @Unit 
 	  	  	 and ps.Start_Time <= t.Result_On
 	  	  	 and ((ps.End_Time > t.Result_On) or (ps.End_Time Is Null))
 	  	 Left Join ESignature es on es.Signature_Id = t.Signature_Id
 	  	 
 	  	 where var_id = @Production_Variable
 	  	  	 and t.Result_On > @StartTime 
 	  	  	 and t.Result_On <= @EndTime
 	  	  	 and (@NonProductiveTimeFilter = 0 or T.Is_Non_Productive = 0) 
 	  	  	 order by t.Result_On
 	  	  	 -- no NP-time gets into the #EventTimes table
 	  	 
 	  	 Declare @ST1 datetime, @ET1 datetime, @OldTS1 DateTime
 	  	 Select @OldTS1 = @StartTime
 	  	 Declare MyCursor INSENSITIVE CURSOR
 	  	 For ( Select Start_Time, End_Time From #EventTimes )
 	  	 For Read Only
 	  	 Open MyCursor  
 	  	 
 	  	 MyLoop1:
 	  	 Fetch Next From MyCursor Into @ST1, @ET1
 	  	 If (@@Fetch_Status = 0)
 	  	  	 Begin -- Begin Loop Here
 	  	  	 Update #EventTimes Set Start_Time = @OldTS1 where End_Time = @ET1
 	  	 
 	  	  	 Select @OldTS1 = @ET1
 	  	 
 	  	  	 Goto MyLoop1
 	  	  	 End -- End Loop Here
 	  	 
 	  	 
 	  	 Close MyCursor
 	  	 Deallocate MyCursor
 	 End
Else
 	 Begin
 	  	 --Print '** Event Based Production **'
 	  	 ------------------------------------------------------
 	  	 -- Populate the Event Times table
 	  	 ------------------------------------------------------
 	  	 -- The timestamp of the first event outside the range of this report
 	  	 Declare @NextEventTimestamp datetime
 	  	 Select @NextEventTimestamp = (select Min(e.Timestamp) 
 	  	 From Events e
 	  	 Where e.PU_Id = @Unit 
 	  	  	 and e.Timestamp >= @EndTime)
 	  	 If @NextEventTimeStamp Is Null
 	  	  	 Begin
 	  	  	  	 Insert into #EventTimes(Start_Time, End_Time, Product_Id, Event_Id, Event_Number, Productive_Start_Time, Productive_End_Time, Non_Productive_Seconds, perform_User_Id, verify_user_Id)
 	  	  	  	 Select e.Start_Time, e.Timestamp, ps.Prod_Id, e.Event_Id, e.Event_Num, Productive_Start_Time, Productive_End_Time, Non_Productive_Seconds, es.perform_User_Id, es.verify_user_Id
 	  	  	  	 From Events_NPT e
 	  	  	  	  	 Join Production_Starts ps on ps.PU_id = @Unit 
 	  	  	  	  	  	 and ps.Start_Time <= e.Timestamp
 	  	  	  	  	  	 and ((ps.End_Time > e.Timestamp) or (ps.End_Time Is Null))
 	  	  	  	  	 
 	  	  	  	  	 Join Production_Status s on s.ProdStatus_id = e.Event_Status 
 	  	  	  	  	  	 and s.count_for_production = 1
 	  	  	  	  	 
 	  	  	  	  	 Left Outer Join Event_Details d on d.event_id = e.event_id
 	  	  	  	  	 Left Join ESignature es on es.Signature_Id = e.Signature_Id
 	  	  	  	 Where e.PU_id = @Unit 
 	  	  	  	  	 and e.Timestamp > @StartTime 
 	  	  	  	  	 and e.Timestamp <= @EndTime 
 	  	  	 End
 	  	 Else
 	  	  	 Begin
 	  	  	  	 Insert into #EventTimes(Start_Time, End_Time, Product_Id, Event_Id, Event_Number, Productive_Start_Time, Productive_End_Time, Non_Productive_Seconds, perform_User_Id, verify_user_Id)
 	  	  	  	 Select e.Start_Time, e.Timestamp, ps.Prod_Id, e.Event_Id, e.Event_Num, Productive_Start_Time, Productive_End_Time, Non_Productive_Seconds, es.perform_User_Id, es.verify_user_Id
 	  	  	  	 From Events_NPT e
 	  	  	  	 Join Production_Starts ps on ps.PU_id = @Unit 
 	  	  	  	  	 and ps.Start_Time <= e.Timestamp
 	  	  	  	  	 and ((ps.End_Time > e.Timestamp) or (ps.End_Time Is Null))
 	  	  	  	 
 	  	  	  	 Join Production_Status s on s.ProdStatus_id = e.Event_Status 
 	  	  	  	  	 and s.count_for_production = 1
 	  	  	  	 
 	  	  	  	 Left Outer Join Event_Details d on d.event_id = e.event_id
 	  	  	  	 Left Join ESignature es on es.Signature_Id = e.Signature_Id
 	  	  	  	 Where e.PU_id = @Unit and
 	  	  	  	  	 (
 	  	  	  	  	  	 (e.Timestamp > @StartTime and e.Timestamp <= @EndTime)
 	  	  	  	  	 or
 	  	  	  	  	  	 (e.Timestamp = @NextEventTimestamp)
 	  	  	  	  	 ) 	 
 	  	  	  	 update #EventTimes
 	  	  	  	  	 Set End_Time = @EndTime where End_Time > @EndTime
 	  	  	 End
 	 End -- If Event Based Production
 	 
 	 
update #EventTimes
 	 Set End_Time = @EndTime where End_Time > @EndTime
update #EventTimes
 	 Set Start_Time = @StartTime where Start_Time < @StartTime
-- Get Process Order Id
Update #EventTimes 
  Set Process_Order_Id = (Select min(ps.pp_id) 
                         From production_plan_starts ps 
                         where ps.pu_id = @Unit 
                         and ps.Start_Time <= #EventTimes.End_Time 
                         and ((ps.End_Time > #EventTimes.Start_Time) or (ps.End_Time is Null)))
-- Get Product Description
Update E 
     Set Product_Desc = Prod_Desc
     From Products p 
     Join #EventTimes E on E.Product_Id = P.Prod_Id
-- Update Starttime where null
Update #EventTimes 
  Set Start_Time = (Select max(e.Timestamp) From Events e where e.pu_id = @Unit and e.timestamp < #EventTimes.End_Time and e.timestamp > @StartTime)
  Where Start_Time Is Null
Update #EventTimes 
  Set Start_Time = @StartTime
  Where Start_Time Is Null
-- Get Process Order Id
Update #EventTimes 
  Set Process_Order_Id = (
          Select min(ps.pp_id) 
          From production_plan_starts ps 
          where ps.pu_id = @Unit 
               and ps.Start_Time <= #EventTimes.End_Time 
               and ((ps.End_Time > #EventTimes.End_Time) or (ps.End_Time is Null)))
  Where Process_Order_Id Is Null
-- Filter out events that are totally within NP time
If @NonProductiveTimeFilter = 1
 	 Begin
 	  	 Print 'Removing NP Events From #Report...'
 	  	 Delete From #EventTimes Where (Productive_Start_Time Is Null) and (Productive_End_Time Is Null)
 	  	 Print 'Resetting Start & End Time For NP Events In #Report...'
 	  	 Update #EventTimes Set 
 	  	  	 Start_Time=Productive_Start_Time,
 	  	  	 End_Time=Productive_End_Time
 	  	  	 --Non_Productive_Seconds=0
 	  	 where Non_Productive_Seconds > 0
 	  	 -- I need to keep the value of NP seconds around so that I can flag the rows
 	  	 -- in the summary tables
 	 End
--------------------------------------------
-- Cursor Variables
--------------------------------------------
Declare @curStartTime datetime
Declare @curEndTime datetime
Declare @curProductId int
Declare @curEventId int
Declare @curEventNum varchar(25)
Declare @curProcessOrderId int
Declare @curProductDesc varchar(25)
Declare @curProductionDay1 datetime
Declare @curProductionDay2 datetime
Declare @curShiftDesc1 varchar(25)
Declare @curShiftDesc2 varchar(25)
Declare @curCrewDesc1 varchar(25)
Declare @curCrewDesc2 varchar(25)
Declare @curShiftStartTime1 datetime
Declare @curShiftStartTime2 datetime
Declare @curShiftEndTime1 datetime
Declare @curShiftEndTime2 datetime
Declare @Test_Id BigInt
Declare @Productive_Start_Time datetime
Declare @Productive_End_Time datetime
Declare @Non_Productive_Seconds int
Declare @perform_User_Id int, @verify_user_Id int
-----------------------------------------------------------------
-- Cursor Through All Event Times And Populate Summary Tables
-----------------------------------------------------------------
Declare EVENT_TIME_CURSOR INSENSITIVE CURSOR
  For (
     Select Start_Time, End_Time, Product_Id, Event_Id, Event_Number, Process_Order_Id, Product_Desc, Test_Id, Non_Productive_Seconds, perform_User_Id, verify_user_Id
 	  From #EventTimes
      )
  For Read Only
  Open EVENT_TIME_CURSOR  
BEGIN_EVENT_TIME_CURSOR:
Fetch Next From EVENT_TIME_CURSOR Into @curStartTime, @curEndTime, @curProductId, @curEventId, @curEventNum, @curProcessOrderId, @curProductDesc, @Test_Id, @Non_Productive_Seconds, @perform_User_Id, @verify_user_Id
While @@Fetch_Status = 0
Begin    
     Select @curProductionDay1=Production_Day, @curShiftDesc1=Shift_Desc, @curCrewDesc1=Crew_Desc, @curShiftStartTime1=Start_Time, @curShiftEndTime1=End_Time
     from dbo.fnCMN_GetProductionDayShiftCrewByTimeStamp(@curStartTime, @Unit)
     Select @curProductionDay2=Production_Day, @curShiftDesc2=Shift_Desc, @curCrewDesc2=Crew_Desc, @curShiftStartTime2=Start_Time, @curShiftEndTime2=End_Time
     from dbo.fnCMN_GetProductionDayShiftCrewByTimeStamp(@curEndTime, @Unit)
     -------------------------------------------------
     -- Did the event cross production day boundary ?
     -------------------------------------------------
     if @curProductionDay1 <> @curProductionDay2 
          Begin
 	  	 -- this is so I don't add an event row with no time span
               if DateDiff(Second, @curStartTime, @curShiftEndTime1) > 0
               Begin
 	  	  	  	  	 -- From EventStartTime to Beginning of ProductionDay2
                    insert Into #OEESummary_ProductionDay(Process_Order_Id, Event_Id, Event_Number, Product_Id, Production_Day, Start_Time, End_Time, Product_Desc, Non_Productive_Seconds)
                    Values(@curProcessOrderId, @curEventId, @curEventNum, @curProductId, @curProductionDay1, @curStartTime, @curProductionDay2, @curProductDesc,
 	  	  	  	  	  	 dbo.fnCMN_GetProRatedProduction(@curStartTime, @curEndTime, @curStartTime, @curProductionDay2, @Non_Productive_Seconds)
 	  	  	  	  	 ) 	  	  	  	 
               End
               -- From Beginning of ProductionDay2 to EventEndTime
               insert Into #OEESummary_ProductionDay(Process_Order_Id, Event_Id, Event_Number, Product_Id, Production_Day, Start_Time, End_Time, Product_Desc, Non_Productive_Seconds)
               Values(@curProcessOrderId, @curEventId, @curEventNum, @curProductId, @curProductionDay2, @curProductionDay2, @curEndTime, @curProductDesc,
 	  	  	  	  	 dbo.fnCMN_GetProRatedProduction(@curStartTime, @curEndTime, @curProductionDay2, @curEndTime, @Non_Productive_Seconds)
 	  	  	  	 )
 	  	  	  	 
          End
     Else
          Begin
               insert Into #OEESummary_ProductionDay(Process_Order_Id, Event_Id, Event_Number, Product_Id, Production_Day, Start_Time, End_Time, Product_Desc, Non_Productive_Seconds)
               Values(@curProcessOrderId, @curEventId, @curEventNum, @curProductId, @curProductionDay1, @curStartTime, @curEndTime, @curProductDesc, @Non_Productive_Seconds)
          End
     -------------------------------------------------
     -- Did the event cross shift or crew boundary ?
     -------------------------------------------------
     if (@curShiftDesc1 <> @curShiftDesc2) OR (@curCrewDesc1 <> @curCrewDesc2)
          Begin
               if DateDiff(Second, @curStartTime, @curShiftEndTime1) > 0
               Begin
                    -- Split Before and After Boundary
                    insert Into #OEESummary_ShiftCrew(Process_Order_Id, Event_Id, Event_Number, Product_Id, Crew_Desc, Shift_Desc, Start_Time, End_Time, Product_Desc, Non_Productive_Seconds)
                    Values(@curProcessOrderId, @curEventId, @curEventNum, @curProductId, @curCrewDesc1, @curShiftDesc1, @curStartTime, @curShiftEndTime1, @curProductDesc,
 	  	  	  	  	  	 dbo.fnCMN_GetProRatedProduction(@curStartTime, @curEndTime, @curStartTime, @curShiftEndTime1, @Non_Productive_Seconds)
 	  	  	  	  	 ) 	  	  	  	  	 
               End
               insert Into #OEESummary_ShiftCrew(Process_Order_Id, Event_Id, Event_Number, Product_Id, Crew_Desc, Shift_Desc, Start_Time, End_Time, Product_Desc, Non_Productive_Seconds)
               Values(@curProcessOrderId, @curEventId, @curEventNum, @curProductId, @curCrewDesc2, @curShiftDesc2, @curShiftStartTime2, @curEndTime, @curProductDesc,
 	  	  	  	  	 dbo.fnCMN_GetProRatedProduction(@curStartTime, @curEndTime, @curShiftStartTime2, @curEndTime, @Non_Productive_Seconds)
 	  	  	  	 )
 	  	  	  	 
          End
     Else
          Begin
               insert Into #OEESummary_ShiftCrew(Process_Order_Id, Event_Id, Event_Number, Product_Id, Crew_Desc, Shift_Desc, Start_Time, End_Time, Product_Desc, Non_Productive_Seconds)
               Values(@curProcessOrderId, @curEventId, @curEventNum, @curProductId, @curCrewDesc1, @curShiftDesc1, @curStartTime, @curEndTime, @curProductDesc, @Non_Productive_Seconds)
          End
     -------------------------------------------------
     -- Record Raw Event Data     
     -------------------------------------------------    
 	 
     insert Into #OEESummary_Raw(Process_Order_Id, Event_Id, Event_Number, Product_Id, Start_Time, End_Time, Product_Desc, Test_Id, Non_Productive_Seconds, perform_User_Id, verify_user_Id)
     Values(@curProcessOrderId, @curEventId, @curEventNum, @curProductId, @curStartTime, @curEndTime, @curProductDesc, @Test_Id, @Non_Productive_Seconds, @perform_User_Id, @verify_user_Id)
     GOTO BEGIN_EVENT_TIME_CURSOR
End
Close EVENT_TIME_CURSOR
Deallocate EVENT_TIME_CURSOR
-----------------------------
-- Update Signoff Users
-----------------------------
Update O 
     Set Perform_Username = Username
     From Users u
     Join #OEESummary_Raw O on O.perform_User_Id = U.User_Id
Update O 
     Set Verify_Username = Username
     From Users u
     Join #OEESummary_Raw O on O.verify_user_Id = U.User_Id
Update #OEESummary_Raw Set Perform_Username = '-' where Perform_Username Is Null
Print convert(varchar(5), @@RowCount) + ' Perform_Username rows updated'
Update #OEESummary_Raw Set Verify_Username = '-' where Verify_Username Is Null
Print convert(varchar(5), @@RowCount) + ' Verify_Username rows updated'
---------------------------------------------------------
-- Declare Output Variables For Unit Statistics
---------------------------------------------------------
Declare @IdealProduction real,@IdealYield real,  
@ActualProduction real,@ActualQualityLoss real,@ActualYieldLoss real,@ActualSpeedLoss real,@ActualDowntimeLoss real,@ActualDowntimeMinutes real,
@ActualRuntimeMinutes real,@ActualUnavailableMinutes real,@ActualSpeed real,@ActualPercentOEE real,@ActualTotalItems int,@ActualGoodItems int,
@ActualBadItems int,@ActualConformanceItems int,@TargetProduction real,@WarningProduction real,@RejectProduction real, @TargetQualityLoss real,
@WarningQualityLoss real,@RejectQualityLoss real,@TargetDowntimeLoss real,@WarningDowntimeLoss real,@RejectDowntimeLoss real,@TargetSpeed real,
@TargetDowntimeMinutes real,@WarningDowntimeMinutes real,@RejectDowntimeMinutes real,@TargetPercentOEE real,@WarningPercentOEE real,@RejectPercentOEE real,
@AmountEngineeringUnits varchar(25),@ItemEngineeringUnits varchar(25),@TimeEngineeringUnits int,@Status int,@ActualDowntimeCount int
------------------------------------------------------
-- Get Engineering Units
------------------------------------------------------
select @AmountEngineeringUnits=coalesce(AmountEngineeringUnits, 'Units'),
       @ItemEngineeringUnits=Coalesce(ItemEngineeringUnits, 'Units'),
       @TimeEngineeringUnits=Coalesce(TimeEngineeringUnits, 4)
from dbo.fnCMN_GetEngineeringUnitsByUnit(@Unit)
Declare @Event_Id int
Declare @Event_Number varchar(25)
Declare @Row_Id int
Declare @ST datetime
Declare @ET datetime
Declare @ProductId int
-----------------------
-- OEE Variables
-----------------------
Declare @PerformanceCategory int
Declare @PerformanceDT real
Declare @SpeedLossTime real
Declare @NetOperatingTime real
Declare @PerformanceRate real
Declare @Downtime_Scheduled_Category int
Declare @Downtime_External_Category int
Declare @TotalUnavailableTimeMinutes real
Declare @TotalOutsideAreaMinutes real
Declare @ActualLoadingTimeMinutes real
Declare @AvailableRate real
Declare @QualityRate real
Declare @OEE real
-------------------------------------------------------
-- Loop through Crew Shift Times 
-- and call spCMN_GetOeeStatistics
-------------------------------------------------------
Declare UNIT_CREW_CURSOR INSENSITIVE CURSOR
  For (
     Select Row_Id, Start_Time, End_Time, Product_Id, Event_Id, Event_Number From #OEESummary_ShiftCrew
      )
  For Read Only
  Open UNIT_CREW_CURSOR  
If (@SummarizeCrew = -1) OR (@SummarizeShift = -1)
Begin
     BEGIN_UNIT_CREW_CURSOR:
     Fetch Next From UNIT_CREW_CURSOR Into @Row_Id, @ST, @ET, @ProductId, @Event_Id, @Event_Number
     While @@Fetch_Status = 0
     Begin
          Truncate Table #OEEStatistics
          insert into #OEEStatistics(Actual_Speed, Ideal_Speed, Performance_Rate, Ideal_Production, Net_Production, Waste, Quality_Rate, Run_Time, Loading_Time, Available_Rate, OEE)
          exec spCMN_GetOeeStatistics @Unit, @ST, @ET, @NonProductiveTimeFilter
          Update o Set
               o.Actual_Speed     =   oe.Actual_Speed,          
               o.Ideal_Speed      =   oe.Ideal_Speed,
               o.Performance_Rate =   oe.Performance_Rate,
               o.Ideal_Production =   oe.Ideal_Production,
               o.Net_Production   =   oe.Net_Production,
               o.Waste            =   oe.Waste, 
               o.Quality_Rate     =   oe.Quality_Rate,
               o.Run_Time         =   oe.Run_Time,
               o.Loading_Time     =   oe.Loading_Time, 
               o.Available_Rate   =   oe.Available_Rate,      
               o.OEE              =   oe.OEE
          From #OEEStatistics oe
          Join #OEESummary_ShiftCrew o on o.Row_Id = @Row_Id 
          GOTO BEGIN_UNIT_CREW_CURSOR
     End
End -- If (@SummarizeCrew = -1) OR (@SummarizeShift = -1)
---------------------------------
-- Cleanup Cursor
---------------------------------
Close UNIT_CREW_CURSOR
Deallocate UNIT_CREW_CURSOR
-------------------------------------------------------
-- Loop through Production Day Times 
-- and call spCMN_GetOeeStatistics
-------------------------------------------------------
Declare UNIT_PRODUCTION_DAY_CURSOR INSENSITIVE CURSOR
  For (
     Select Row_Id, Start_Time, End_Time, Product_Id, Event_Id, Event_Number From #OEESummary_ProductionDay
      )
  For Read Only
  Open UNIT_PRODUCTION_DAY_CURSOR  
If (@SummarizeDay = -1)
Begin
     BEGIN_UNIT_PRODUCTION_DAY_CURSOR:
     Fetch Next From UNIT_PRODUCTION_DAY_CURSOR Into @Row_Id, @ST, @ET, @ProductId, @Event_Id, @Event_Number
     While @@Fetch_Status = 0
     Begin
          Truncate Table #OEEStatistics
          insert into #OEEStatistics(Actual_Speed, Ideal_Speed, Performance_Rate, Ideal_Production, Net_Production, Waste, Quality_Rate, Run_Time, Loading_Time, Available_Rate, OEE)
          exec spCMN_GetOeeStatistics @Unit, @ST, @ET, @NonProductiveTimeFilter
          Update o Set
               o.Actual_Speed     =   oe.Actual_Speed,          
               o.Ideal_Speed      =   oe.Ideal_Speed,
               o.Performance_Rate =   oe.Performance_Rate,
               o.Ideal_Production =   oe.Ideal_Production,
               o.Net_Production   =   oe.Net_Production,
               o.Waste            =   oe.Waste, 
               o.Quality_Rate     =   oe.Quality_Rate,
               o.Run_Time         =   oe.Run_Time,
               o.Loading_Time     =   oe.Loading_Time, 
               o.Available_Rate   =   oe.Available_Rate,      
               o.OEE              =   oe.OEE
          From #OEEStatistics oe
          Join #OEESummary_ProductionDay o on o.Row_Id = @Row_Id 
          GOTO BEGIN_UNIT_PRODUCTION_DAY_CURSOR
     End
End -- If (@SummarizeDay = -1)
---------------------------------
-- Cleanup Cursor
---------------------------------
Close UNIT_PRODUCTION_DAY_CURSOR
Deallocate UNIT_PRODUCTION_DAY_CURSOR
-------------------------------------------------------
-- Loop through Indivisual Event Times 
-- and call spCMN_GetOeeStatistics
-------------------------------------------------------
Declare UNIT_RAW_CURSOR INSENSITIVE CURSOR
  For (
     Select Row_Id, Start_Time, End_Time, Product_Id, Event_Id, Event_Number From #OEESummary_Raw
      )
  For Read Only
  Open UNIT_RAW_CURSOR  
BEGIN_UNIT_RAW_CURSOR:
Fetch Next From UNIT_RAW_CURSOR Into @Row_Id, @ST, @ET, @ProductId, @Event_Id, @Event_Number
While @@Fetch_Status = 0
Begin
     Truncate Table #OEEStatistics
     insert into #OEEStatistics(Actual_Speed, Ideal_Speed, Performance_Rate, Ideal_Production, Net_Production, Waste, Quality_Rate, Run_Time, Loading_Time, Available_Rate, OEE)
     exec spCMN_GetOeeStatistics @Unit, @ST, @ET, @NonProductiveTimeFilter
     Update o Set
          o.Actual_Speed     =   oe.Actual_Speed,          
          o.Ideal_Speed      =   oe.Ideal_Speed,
          o.Performance_Rate =   oe.Performance_Rate,
          o.Ideal_Production =   oe.Ideal_Production,
          o.Net_Production   =   oe.Net_Production,
          o.Waste            =   oe.Waste, 
          o.Quality_Rate     =   oe.Quality_Rate,
          o.Run_Time         =   oe.Run_Time,
          o.Loading_Time     =   oe.Loading_Time, 
          o.Available_Rate   =   oe.Available_Rate,      
          o.OEE              =   oe.OEE
     From #OEEStatistics oe
     Join #OEESummary_Raw o on o.Row_Id = @Row_Id 
     GOTO BEGIN_UNIT_RAW_CURSOR
End
---------------------------------
-- Cleanup Cursor
---------------------------------
Close UNIT_RAW_CURSOR
Deallocate UNIT_RAW_CURSOR
Update #OEESummary_ProductionDay Set Run_Time = 0 Where Run_Time < 0
Update #OEESummary_ProductionDay Set Loading_Time = 0 Where Loading_Time < 0
Update #OEESummary_ShiftCrew Set Run_Time = 0 Where Run_Time < 0
Update #OEESummary_ShiftCrew Set Loading_Time = 0 Where Loading_Time < 0
Update #OEESummary_Raw Set Run_Time = 0 Where Run_Time < 0
Update #OEESummary_Raw Set Loading_Time = 0 Where Loading_Time < 0
Create Table #GrandTotals(
     Actual_Speed real,
     Ideal_Speed real, 
     Performance_Rate real,
     Ideal_Production real,
     Net_Production real,
     Waste real,
     Quality_Rate real,
     Run_Time real,
     Loading_Time real,
     Available_Rate real,
     OEE real
)
---------------------------------------------
-- Summarize Grand Totals
---------------------------------------------
-- CALC ACTUAL RATE    = NETPRODUCTION / RUNTIME
-- CALC IDEAL RATE     = IDEALPRODUCTION / LOADINGTIME
-- PERFORMANCE RATE    = (((NETPRODUCTION) / (LOADINGTIME)) / (IDEALRATE))
-- QUALITY RATE        = ((GOOD) / (GOOD + WASTE))
-- AVAILIBILITY RATE   = (RUNNINGTIME) / (LOADINGTIME)
-- OEE                 = (((NETPRODUCTION) / (LOADINGTIME)) / (IDEALRATE)) * ((GOOD) / (GOOD + WASTE)) * ((RUNNINGTIME) / (LOADINGTIME))
/*
 Calculating The Ideal Rate
 Ideal Rate is calculated in spCMN_GetUnitProduction as follows
 IdealRate comes from a product spec.  When no spec is given then the actual rate is used in place of it
 IdealProduction = IdealRate * LoadingTime
  LoadingTime will always be known, IdealProduction amount gets cumulated from all the calls to spCMN_GetUnitStatistics
  When we want to back calculate what the IdealRate is we use the following formula:
    IdealProduction / LoadingTime = IdealRate
*/
/*
print 'Summarize Grand Totals'
*/
/*
insert into #GrandTotals(Actual_Speed, Ideal_Speed, Performance_Rate, Ideal_Production, Net_Production, Waste, Quality_Rate, Run_Time, Loading_Time, Available_Rate, OEE)
exec spCMN_GetOeeStatistics @Unit, @StartTime, @EndTime
select 
-- 	 @ProficyDashBoardPath + 'MSWebPart.aspx?TemplateName=38481&TemplateVersion=1' 
--          + '&38239=' + convert(varchar(25), @StartTime, 120) 
--          + '&38240=' + convert(varchar(25), @EndTime, 120) 
--          + '&38130=' + convert(varchar(25), @Unit, 120) 
--          AS [Hyperlink],
     Convert(VarChar(25), convert(decimal(10,2), Actual_Speed))  + ' ' + @AmountEngineeringUnits + '/min' AS [Actual_Speed], 
     Convert(VarChar(25), convert(decimal(10,2), Ideal_Speed))  + ' ' + @AmountEngineeringUnits + '/min' AS [Ideal_Speed], 
     Convert(VarChar(25), convert(decimal(10,2), Performance_Rate)) + ' %'  AS [Performance_Rate],
     Convert(VarChar(25), convert(decimal(10,2), Net_Production)) + ' ' + @AmountEngineeringUnits AS [Total_Net_Production], 
     Convert(Decimal(10,2), Ideal_Production) as [Ideal_Production], 
     Convert(VarChar(25), convert(decimal(10,2), Waste)) + ' ' + @AmountEngineeringUnits AS [Total_Waste], 
     Convert(VarChar(25), convert(decimal(10,2), Quality_Rate)) + ' %' AS [Quality_Rate],
--     Convert(VarChar(25), dbo.fnRS_MakeTimeDurationString(Run_Time)) as Run_Time,
--   Convert(VarChar(25), dbo.fnRS_MakeTimeDurationString(Loading_Time)) as Loading_Time,
  Convert(VarChar(25), Run_Time) as [Run_Time],
  Convert(VarChar(25), Loading_Time) as [Loading_Time],
     Convert(VarChar(25), str(Run_Time, 10 , 2)) as Run_Time,
     Convert(VarChar(25), str(Loading_Time, 10, 2)) as Loading_Time,
     Convert(VarChar(25), convert(decimal(10,2), Available_Rate)) + ' %' AS [Available_Rate],      
     Convert(VarChar(25), convert(decimal(10,2), OEE)) + ' %' AS [OEE]
from #GrandTotals
*/
-- This is another way to do the grand summary
--Print 'TEST Grand Summary'
-- 
Declare @Actual_Speed Real,@Ideal_Speed real, @Performance_Rate real, @Available_Rate real, @Quality_Rate real, @OEE_Rate real
Declare @Net_Production real, @Ideal_Production real, @Waste real, @Run_Time real, @Loading_time real
Select @Net_Production = Sum(Net_Production), @Ideal_Production = Sum(Ideal_Production), @Waste = Sum(Waste), @Run_Time = Sum(Run_Time), @Loading_time = Sum(Loading_Time) 
from #OEESummary_Raw
Select @Actual_Speed=Actual_Rate,@Ideal_Speed=Ideal_Rate,@Performance_Rate=Performance_Rate,@Available_Rate=Available_Rate,@Quality_Rate=Quality_Rate,@OEE_Rate=OEE
from dbo.fnCMN_OEERates(@Run_Time, @Loading_Time,0, @Net_Production, @Ideal_Production, @Waste)
Select 
 	 Convert(Decimal(10,2), @Actual_Speed) as [Actual_Speed],
 	 Convert(Decimal(10,2), @Ideal_Speed) as [Ideal_Speed],
 	 Convert(Decimal(10,2), @Net_Production) as [Net_Production], 
 	 Convert(Decimal(10,2), @Ideal_Production) as [Ideal_Production], 
 	 Convert(Decimal(10,2), @Waste) as [Waste], 
 	 Convert(Decimal(10,2), @Run_Time) as [Run_Time], 
 	 Convert(Decimal(10,2), @Loading_time) as [Loading_Time],
 	 Convert(Decimal(10,2), @Available_Rate) as [Available_Rate],
 	 Convert(Decimal(10,2), @Performance_Rate) as [Performance_Rate],
 	 Convert(Decimal(10,2), @Quality_Rate) as [Quality_Rate],
 	 Convert(Decimal(10,2), @OEE_Rate) as [OEE]
Into #S1
Select 
 	 @ProficyDashBoardPath + 'MSWebPart.aspx?TemplateName=38481&TemplateVersion=1' 
          + '&38239=' + convert(varchar(25), @StartTime, 120) 
          + '&38240=' + convert(varchar(25), @EndTime, 120) 
          + '&38130=' + convert(varchar(25), @Unit, 120) 
          + '&38491=' + convert(varchar(1), @NonProductiveTimeFilter) 
          AS [Hyperlink],
  Convert(VarChar(25), Actual_Speed) + ' ' + @AmountEngineeringUnits + '/min' AS [Actual_Speed],
  Convert(VarChar(25), Ideal_Speed) + ' ' + @AmountEngineeringUnits + '/min' AS [Ideal_Speed],
  Convert(VarChar(25), Performance_Rate) + ' %' as [Performance_Rate],
  Convert(VarChar(25), Net_Production) + ' ' + @AmountEngineeringUnits AS [Net_Production],
  Convert(VarChar(25), Waste) + ' ' + @AmountEngineeringUnits AS [Waste],
  Convert(VarChar(25), Quality_Rate) + ' %' as [Quality_Rate],
  Convert(VarChar(25), dbo.fnRS_MakeTimeDurationString(Run_Time) ) as [Run_Time],
  Convert(VarChar(25), dbo.fnRS_MakeTimeDurationString(Loading_Time) ) as [Loading_Time],
  Convert(VarChar(25), Available_Rate) + ' %' as [Available_Rate],
  Convert(VarChar(25), OEE) + ' %' as [OEE]
From #S1
Drop Table #S1
----------------------------------------------------------------------
-- By Production Day 
----------------------------------------------------------------------
Create Table #S2(
Row_Id int NOT NULL IDENTITY (1, 1),
Production_Day VarChar(10),
Product_Desc varchar(50),
Actual_Speed Decimal(10,2),
Ideal_Speed Decimal(10,2),
Net_Production Decimal(10,2),
Ideal_Production Decimal(10,2),
Waste Decimal(10,2),
Run_Time Decimal(10,2),
Loading_Time Decimal(10,2),
Available_Rate Decimal(10,2),
Performance_Rate Decimal(10,2),
Quality_Rate Decimal(10,2),
OEE Decimal(10,2)
)
Insert Into #S2(Production_Day, Product_Desc, Net_Production, Ideal_Production, Waste, Run_Time, Loading_Time)
Select 
 	 Convert(varchar(10), Production_Day, 120) AS [Production_Day],
 	 Product_Desc,
 	 Convert(Decimal(10,2), Sum(Net_Production)) as [Net_Production], 
 	 Convert(Decimal(10,2), Sum(Ideal_Production)) as [Ideal_Production], 
 	 Convert(Decimal(10,2), Sum(Waste)) as [Waste], 
 	 Convert(Decimal(10,2), Sum(Run_Time)) as [Run_Time], 
 	 Convert(Decimal(10,2), Sum(Loading_Time)) as [Loading_Time]
From #OEESummary_ProductionDay
Group By Production_Day, Product_Desc
Order By Production_Day
Declare S2_CURSOR INSENSITIVE CURSOR
  For ( Select Row_Id, Net_Production, Ideal_Production, Waste, Run_Time, Loading_Time From #S2 )
  For Read Only
  Open S2_CURSOR  
BEGIN_S2_CURSOR:
Fetch Next From S2_CURSOR Into @Row_id, @net_Production, @Ideal_Production, @Waste, @Run_Time, @Loading_Time
While @@Fetch_Status = 0
     Begin    
          Select @Actual_Speed=Actual_Rate,@Ideal_Speed=Ideal_Rate,@Performance_Rate=Performance_Rate,@Available_Rate=Available_Rate,@Quality_Rate=Quality_Rate,@OEE_Rate=OEE
          from dbo.fnCMN_OEERates(@Run_Time, @Loading_Time,0, @Net_Production, @Ideal_Production, @Waste)
          Update #S2 Set Actual_Speed=@Actual_Speed,Ideal_Speed=@Ideal_Speed,Performance_Rate=@Performance_Rate,Available_Rate=@Available_Rate,Quality_Rate=@Quality_Rate,OEE=@OEE_Rate
 	   Where Row_Id=@Row_Id
          GOTO BEGIN_S2_CURSOR
     End 
Close S2_CURSOR
Deallocate S2_CURSOR
Select 
  Production_Day, Product_Desc,
  Convert(VarChar(25), Actual_Speed) + ' ' + @AmountEngineeringUnits + '/min' AS [Actual_Speed],
  Convert(VarChar(25), Ideal_Speed) + ' ' + @AmountEngineeringUnits + '/min' AS [Ideal_Speed],
  Convert(VarChar(25), Performance_Rate) + ' %' as [Performance_Rate],
  Convert(VarChar(25), Net_Production) + ' ' + @AmountEngineeringUnits AS [Net_Production],
  Convert(VarChar(25), Waste) + ' ' + @AmountEngineeringUnits AS [Waste],
  Convert(VarChar(25), Quality_Rate) + ' %' as [Quality_Rate],
  Convert(VarChar(25), dbo.fnRS_MakeTimeDurationString(Run_Time) ) as [Run_Time],
  Convert(VarChar(25), dbo.fnRS_MakeTimeDurationString(Loading_Time) ) as [Loading_Time],
  Convert(VarChar(25), Available_Rate ) + ' %' as [Available_Rate],
  Convert(VarChar(25), OEE) + ' %' as [OEE]
From #S2
Drop Table #S2
----------------------------------------------------------------------
-- By Shift
----------------------------------------------------------------------
Create Table #S3(
Row_Id int NOT NULL IDENTITY (1, 1),
Shift_Desc VarChar(10),
Product_Desc varchar(50),
Actual_Speed Decimal(10,2),
Ideal_Speed Decimal(10,2),
Net_Production Decimal(10,2),
Ideal_Production Decimal(10,2),
Waste Decimal(10,2),
Run_Time Decimal(10,2),
Loading_Time Decimal(10,2),
Available_Rate Decimal(10,2),
Performance_Rate Decimal(10,2),
Quality_Rate Decimal(10,2),
OEE Decimal(10,2)
)
Insert Into #S3(Shift_Desc, Product_Desc, Net_Production, Ideal_Production, Waste, Run_Time, Loading_Time)
Select 
 	 Shift_Desc,Product_Desc,
 	 Convert(Decimal(10,2), Sum(Net_Production)) as [Net_Production], 
 	 Convert(Decimal(10,2), Sum(Ideal_Production)) as [Ideal_Production], 
 	 Convert(Decimal(10,2), Sum(Waste)) as [Waste], 
 	 Convert(Decimal(10,2), Sum(Run_Time)) as [Run_Time], 
 	 Convert(Decimal(10,2), Sum(Loading_Time)) as [Loading_Time]
From #OEESummary_ShiftCrew
Group By Shift_Desc, Product_Desc
Order by Shift_Desc
Declare S3_CURSOR INSENSITIVE CURSOR
  For ( Select Row_Id, Net_Production, Ideal_Production, Waste, Run_Time, Loading_Time From #S3 )
  For Read Only
  Open S3_CURSOR  
BEGIN_S3_CURSOR:
Fetch Next From S3_CURSOR Into @Row_id, @net_Production, @Ideal_Production, @Waste, @Run_Time, @Loading_Time
While @@Fetch_Status = 0
     Begin    
          Select @Actual_Speed=Actual_Rate,@Ideal_Speed=Ideal_Rate,@Performance_Rate=Performance_Rate,@Available_Rate=Available_Rate,@Quality_Rate=Quality_Rate,@OEE_Rate=OEE
          from dbo.fnCMN_OEERates(@Run_Time, @Loading_Time,0, @Net_Production, @Ideal_Production, @Waste)
          Update #S3 Set Actual_Speed=@Actual_Speed,Ideal_Speed=@Ideal_Speed,Performance_Rate=@Performance_Rate,Available_Rate=@Available_Rate,Quality_Rate=@Quality_Rate,OEE=@OEE_Rate
 	   Where Row_Id=@Row_Id
          GOTO BEGIN_S3_CURSOR
     End 
Close S3_CURSOR
Deallocate S3_CURSOR
Select 
  Shift_Desc, Product_Desc,
  Convert(VarChar(25), Actual_Speed) + ' ' + @AmountEngineeringUnits + '/min' AS [Actual_Speed],
  Convert(VarChar(25), Ideal_Speed) + ' ' + @AmountEngineeringUnits + '/min' AS [Ideal_Speed],
  Convert(VarChar(25), Performance_Rate) + ' %' as [Performance_Rate],
  Convert(VarChar(25), Net_Production) + ' ' + @AmountEngineeringUnits AS [Net_Production],
  Convert(VarChar(25), Waste) + ' ' + @AmountEngineeringUnits AS [Waste],
  Convert(VarChar(25), Quality_Rate) + ' %' as [Quality_Rate],
  Convert(VarChar(25), dbo.fnRS_MakeTimeDurationString(Run_Time) ) as [Run_Time],
  Convert(VarChar(25), dbo.fnRS_MakeTimeDurationString(Loading_Time) ) as [Loading_Time],
  Convert(VarChar(25), Available_Rate) + ' %' as [Available_Rate],
  Convert(VarChar(25), OEE) + ' %' as [OEE]
From #S3
Drop Table #S3
----------------------------------------------------------------------
-- By Crew
----------------------------------------------------------------------
Create Table #S4(
Row_Id int NOT NULL IDENTITY (1, 1),
Crew_Desc VarChar(10),
Product_Desc varchar(50),
Actual_Speed Decimal(10,2),
Ideal_Speed Decimal(10,2),
Net_Production Decimal(10,2),
Ideal_Production Decimal(10,2),
Waste Decimal(10,2),
Run_Time Decimal(10,2),
Loading_Time Decimal(10,2),
Available_Rate Decimal(10,2),
Performance_Rate Decimal(10,2),
Quality_Rate Decimal(10,2),
OEE Decimal(10,2)
)
Insert Into #S4(Crew_Desc, Product_Desc, Net_Production, Ideal_Production, Waste, Run_Time, Loading_Time)
Select 
 	 Crew_Desc,Product_Desc,
 	 Convert(Decimal(10,2), Sum(Net_Production)) as [Net_Production], 
 	 Convert(Decimal(10,2), Sum(Ideal_Production)) as [Ideal_Production], 
 	 Convert(Decimal(10,2), Sum(Waste)) as [Waste], 
 	 Convert(Decimal(10,2), Sum(Run_Time)) as [Run_Time], 
 	 Convert(Decimal(10,2), Sum(Loading_Time)) as [Loading_Time]
From #OEESummary_ShiftCrew
Group By Crew_Desc, Product_Desc
Order By Crew_Desc
Declare S4_CURSOR INSENSITIVE CURSOR
  For ( Select Row_Id, Net_Production, Ideal_Production, Waste, Run_Time, Loading_Time From #S4 )
  For Read Only
  Open S4_CURSOR  
BEGIN_S4_CURSOR:
Fetch Next From S4_CURSOR Into @Row_id, @net_Production, @Ideal_Production, @Waste, @Run_Time, @Loading_Time
While @@Fetch_Status = 0
     Begin    
          Select @Actual_Speed=Actual_Rate,@Ideal_Speed=Ideal_Rate,@Performance_Rate=Performance_Rate,@Available_Rate=Available_Rate,@Quality_Rate=Quality_Rate,@OEE_Rate=OEE
          from dbo.fnCMN_OEERates(@Run_Time, @Loading_Time, 0,@Net_Production, @Ideal_Production, @Waste)
          Update #S4 Set Actual_Speed=@Actual_Speed,Ideal_Speed=@Ideal_Speed,Performance_Rate=@Performance_Rate,Available_Rate=@Available_Rate,Quality_Rate=@Quality_Rate,OEE=@OEE_Rate
 	   Where Row_Id=@Row_Id
          GOTO BEGIN_S4_CURSOR
     End 
Close S4_CURSOR
Deallocate S4_CURSOR
Select 
     Crew_Desc, Product_Desc,
  Convert(VarChar(25), Actual_Speed) + ' ' + @AmountEngineeringUnits + '/min' AS [Actual_Speed],
  Convert(VarChar(25), Ideal_Speed) + ' ' + @AmountEngineeringUnits + '/min' AS [Ideal_Speed],
  Convert(VarChar(25), Performance_Rate) + ' %' as [Performance_Rate],
  Convert(VarChar(25), Net_Production) + ' ' + @AmountEngineeringUnits AS [Net_Production],
  Convert(VarChar(25), Waste) + ' ' + @AmountEngineeringUnits AS [Waste],
  Convert(VarChar(25), Quality_Rate) + ' %' as [Quality_Rate],
  Convert(VarChar(25), dbo.fnRS_MakeTimeDurationString(Run_Time) ) as [Run_Time],
  Convert(VarChar(25), dbo.fnRS_MakeTimeDurationString(Loading_Time) ) as [Loading_Time],
  Convert(VarChar(25), Available_Rate) + ' %' as [Available_Rate],
  Convert(VarChar(25), OEE) + ' %' as [OEE]
From #S4
Drop Table #S4
----------------------------------------------------------------------
-- By Product
----------------------------------------------------------------------
Create Table #S5(
Row_Id int NOT NULL IDENTITY (1, 1),
Product_Desc varchar(50),
Actual_Speed Decimal(10,2),
Ideal_Speed Decimal(10,2),
Net_Production Decimal(10,2),
Ideal_Production Decimal(10,2),
Waste Decimal(10,2),
Run_Time Decimal(10,2),
Loading_Time Decimal(10,2),
Available_Rate Decimal(10,2),
Performance_Rate Decimal(10,2),
Quality_Rate Decimal(10,2),
OEE Decimal(10,2)
)
Insert Into #S5(Product_Desc, Net_Production, Ideal_Production, Waste, Run_Time, Loading_Time)
Select 
 	 Product_Desc,
 	 Convert(Decimal(10,2), Sum(Net_Production)) as [Net_Production], 
 	 Convert(Decimal(10,2), Sum(Ideal_Production)) as [Ideal_Production], 
 	 Convert(Decimal(10,2), Sum(Waste)) as [Waste], 
 	 Convert(Decimal(10,2), Sum(Run_Time)) as [Run_Time], 
 	 Convert(Decimal(10,2), Sum(Loading_Time)) as [Loading_Time]
From #OEESummary_Raw
Group By Product_Desc
Declare S5_CURSOR INSENSITIVE CURSOR
  For ( Select Row_Id, Net_Production, Ideal_Production, Waste, Run_Time, Loading_Time From #S5 )
  For Read Only
  Open S5_CURSOR  
BEGIN_S5_CURSOR:
Fetch Next From S5_CURSOR Into @Row_id, @net_Production, @Ideal_Production, @Waste, @Run_Time, @Loading_Time
While @@Fetch_Status = 0
     Begin    
          Select @Actual_Speed=Actual_Rate,@Ideal_Speed=Ideal_Rate,@Performance_Rate=Performance_Rate,@Available_Rate=Available_Rate,@Quality_Rate=Quality_Rate,@OEE_Rate=OEE
          from dbo.fnCMN_OEERates(@Run_Time, @Loading_Time,0, @Net_Production, @Ideal_Production, @Waste)
          Update #S5 Set Actual_Speed=@Actual_Speed,Ideal_Speed=@Ideal_Speed,Performance_Rate=@Performance_Rate,Available_Rate=@Available_Rate,Quality_Rate=@Quality_Rate,OEE=@OEE_Rate
 	   Where Row_Id=@Row_Id
          GOTO BEGIN_S5_CURSOR
     End 
Close S5_CURSOR
Deallocate S5_CURSOR
Select 
     Product_Desc,
  Convert(VarChar(25), Actual_Speed) + ' ' + @AmountEngineeringUnits + '/min' AS [Actual_Speed],
  Convert(VarChar(25), Ideal_Speed) + ' ' + @AmountEngineeringUnits + '/min' AS [Ideal_Speed],
  Convert(VarChar(25), Performance_Rate) + ' %' as [Performance_Rate],
  Convert(VarChar(25), Net_Production) + ' ' + @AmountEngineeringUnits AS [Net_Production],
  Convert(VarChar(25), Waste) + ' ' + @AmountEngineeringUnits AS [Waste],
  Convert(VarChar(25), Quality_Rate) + ' %' as [Quality_Rate],
  Convert(VarChar(25), dbo.fnRS_MakeTimeDurationString(Run_Time) ) as [Run_Time],
  Convert(VarChar(25), dbo.fnRS_MakeTimeDurationString(Loading_Time) ) as [Loading_Time],
  Convert(VarChar(25), Available_Rate ) + ' %' as [Available_Rate],
  Convert(VarChar(25), OEE) + ' %' as [OEE]
From #S5
Drop Table #S5
----------------------------------------------------------------------
-- By Process Order
----------------------------------------------------------------------
Create Table #S6(
Row_Id int NOT NULL IDENTITY (1, 1),
Process_Order_Id int,
Product_Desc varchar(50),
Actual_Speed Decimal(10,2),
Ideal_Speed Decimal(10,2),
Net_Production Decimal(10,2),
Ideal_Production Decimal(10,2),
Waste Decimal(10,2),
Run_Time Decimal(10,2),
Loading_Time Decimal(10,2),
Available_Rate Decimal(10,2),
Performance_Rate Decimal(10,2),
Quality_Rate Decimal(10,2),
OEE Decimal(10,2)
)
Insert Into #S6(Process_Order_Id, Product_Desc, Net_Production, Ideal_Production, Waste, Run_Time, Loading_Time)
Select 
 	 Process_Order_Id, Product_Desc,
 	 Convert(Decimal(10,2), Sum(Net_Production)) as [Net_Production], 
 	 Convert(Decimal(10,2), Sum(Ideal_Production)) as [Ideal_Production], 
 	 Convert(Decimal(10,2), Sum(Waste)) as [Waste], 
 	 Convert(Decimal(10,2), Sum(Run_Time)) as [Run_Time], 
 	 Convert(Decimal(10,2), Sum(Loading_Time)) as [Loading_Time]
From #OEESummary_Raw
Group By Process_Order_Id, Product_Desc
Declare S6_CURSOR INSENSITIVE CURSOR
  For ( Select Row_Id, Net_Production, Ideal_Production, Waste, Run_Time, Loading_Time From #S6 )
  For Read Only
  Open S6_CURSOR  
BEGIN_S6_CURSOR:
Fetch Next From S6_CURSOR Into @Row_id, @net_Production, @Ideal_Production, @Waste, @Run_Time, @Loading_Time
While @@Fetch_Status = 0
     Begin    
          Select @Actual_Speed=Actual_Rate,@Ideal_Speed=Ideal_Rate,@Performance_Rate=Performance_Rate,@Available_Rate=Available_Rate,@Quality_Rate=Quality_Rate,@OEE_Rate=OEE
          from dbo.fnCMN_OEERates(@Run_Time, @Loading_Time, 0, @Net_Production, @Ideal_Production, @Waste)
          Update #S6 Set Actual_Speed=@Actual_Speed,Ideal_Speed=@Ideal_Speed,Performance_Rate=@Performance_Rate,Available_Rate=@Available_Rate,Quality_Rate=@Quality_Rate,OEE=@OEE_Rate
 	   Where Row_Id=@Row_Id
          GOTO BEGIN_S6_CURSOR
     End 
Close S6_CURSOR
Deallocate S6_CURSOR
Select 
     Process_Order_Id, Product_Desc,
  Convert(VarChar(25), Actual_Speed) + ' ' + @AmountEngineeringUnits + '/min' AS [Actual_Speed],
  Convert(VarChar(25), Ideal_Speed) + ' ' + @AmountEngineeringUnits + '/min' AS [Ideal_Speed],
  Convert(VarChar(25), Performance_Rate) + ' %' as [Performance_Rate],
  Convert(VarChar(25), Net_Production) + ' ' + @AmountEngineeringUnits AS [Net_Production],
  Convert(VarChar(25), Waste) + ' ' + @AmountEngineeringUnits AS [Waste],
  Convert(VarChar(25), Quality_Rate) + ' %' as [Quality_Rate],
  Convert(VarChar(25), dbo.fnRS_MakeTimeDurationString(Run_Time) ) as [Run_Time],
  Convert(VarChar(25), dbo.fnRS_MakeTimeDurationString(Loading_Time) ) as [Loading_Time],
  Convert(VarChar(25), Available_Rate) + ' %' as [Available_Rate],
  Convert(VarChar(25), OEE) + ' %' as [OEE]
From #S6
Drop Table #S6
-- exec spASP_wrOEESummary 81
If @Production_Variable Is Null
 	 -- By Event
 	 If @DisplayESignature = 0
 	  	 Select Event_Number + Case When Non_Productive_Seconds > 0 Then @NPTLabel Else '' End AS Event_Number,  
 	  	  	 Product_Desc, 
 	  	  	 Convert(VarChar(25), Convert(Decimal(10,2),Actual_Speed))  + ' ' + @AmountEngineeringUnits + '/min' AS Actual_Speed,
 	  	  	 Convert(VarChar(25), Convert(Decimal(10,2),Ideal_Speed))  + ' ' + @AmountEngineeringUnits + '/min' AS Ideal_Speed,
 	  	  	 Convert(VarChar(25), Convert(Decimal(10,2),Performance_Rate))  + ' %'  AS Performance_Rate,
 	  	  	 Convert(VarChar(25), Convert(Decimal(10,2),Net_Production))  + ' ' + @AmountEngineeringUnits  AS Net_Production,
 	  	  	 Convert(VarChar(25), Convert(Decimal(10,2),Waste))  + ' ' + @AmountEngineeringUnits  AS Waste,
 	  	  	 Convert(VarChar(25), Convert(Decimal(10,2),Quality_Rate))  + ' %'  AS Quality_Rate,
 	  	  	 Convert(VarChar(25), dbo.fnRS_MakeTimeDurationString(Run_Time)) as Run_Time,
      	  	 Convert(VarChar(25), dbo.fnRS_MakeTimeDurationString(Loading_Time)) as Loading_Time,
 	  	  	 Convert(VarChar(25), Convert(Decimal(10,2),Available_Rate))  + ' %'  AS Available_Rate,
 	  	  	 Convert(VarChar(25), Convert(Decimal(10,2),OEE))  + ' %'  AS OEE
 	  	 From #OEESummary_Raw o
 	 Else
 	  	 Select Event_Number + Case When Non_Productive_Seconds > 0 Then @NPTLabel Else '' End AS Event_Number,   
 	  	  	 Perform_Username AS [User],
 	  	  	 Verify_Username AS [Approver],
 	  	  	 Product_Desc, 
 	  	  	 Convert(VarChar(25), Convert(Decimal(10,2),Actual_Speed))  + ' ' + @AmountEngineeringUnits + '/min' AS Actual_Speed,
 	  	  	 Convert(VarChar(25), Convert(Decimal(10,2),Ideal_Speed))  + ' ' + @AmountEngineeringUnits + '/min' AS Ideal_Speed,
 	  	  	 Convert(VarChar(25), Convert(Decimal(10,2),Performance_Rate))  + ' %'  AS Performance_Rate,
 	  	  	 Convert(VarChar(25), Convert(Decimal(10,2),Net_Production))  + ' ' + @AmountEngineeringUnits  AS Net_Production,
 	  	  	 Convert(VarChar(25), Convert(Decimal(10,2),Waste))  + ' ' + @AmountEngineeringUnits  AS Waste,
 	  	  	 Convert(VarChar(25), Convert(Decimal(10,2),Quality_Rate))  + ' %'  AS Quality_Rate,
 	  	  	 Convert(VarChar(25), dbo.fnRS_MakeTimeDurationString(Run_Time)) as Run_Time,
      	  	 Convert(VarChar(25), dbo.fnRS_MakeTimeDurationString(Loading_Time)) as Loading_Time,
 	  	  	 Convert(VarChar(25), Convert(Decimal(10,2),Available_Rate))  + ' %'  AS Available_Rate,
 	  	  	 Convert(VarChar(25), Convert(Decimal(10,2),OEE))  + ' %'  AS OEE
 	  	 From #OEESummary_Raw o
Else
 	 If @DisplayESignature = 0
 	  	 Select Test_Id + Case When Non_Productive_Seconds > 0 Then @NPTLabel Else '' End AS Test_ID, 
 	  	  	 Product_Desc, 
 	  	  	 Convert(VarChar(25), Convert(Decimal(10,2),Actual_Speed))  + ' ' + @AmountEngineeringUnits + '/min' AS Actual_Speed,
 	  	  	 Convert(VarChar(25), Convert(Decimal(10,2),Ideal_Speed))  + ' ' + @AmountEngineeringUnits + '/min' AS Ideal_Speed,
 	  	  	 Convert(VarChar(25), Convert(Decimal(10,2),Performance_Rate))  + ' %'  AS Performance_Rate,
 	  	  	 Convert(VarChar(25), Convert(Decimal(10,2),Net_Production))  + ' ' + @AmountEngineeringUnits  AS Net_Production,
 	  	  	 Convert(VarChar(25), Convert(Decimal(10,2),Waste))  + ' ' + @AmountEngineeringUnits  AS Waste,
 	  	  	 Convert(VarChar(25), Convert(Decimal(10,2),Quality_Rate))  + ' %'  AS Quality_Rate,
 	  	  	 Convert(VarChar(25), dbo.fnRS_MakeTimeDurationString(Run_Time)) as Run_Time,
      	  	 Convert(VarChar(25), dbo.fnRS_MakeTimeDurationString(Loading_Time)) as Loading_Time,
 	  	  	 Convert(VarChar(25), Convert(Decimal(10,2),Available_Rate))  + ' %'  AS Available_Rate,
 	  	  	 Convert(VarChar(25), Convert(Decimal(10,2),OEE))  + ' %'  AS OEE
 	  	 From #OEESummary_Raw
 	 Else
 	  	 Select Test_Id + Case When Non_Productive_Seconds > 0 Then @NPTLabel Else '' End AS Test_ID,  
 	  	  	 Perform_Username AS [User],
 	  	  	 Verify_Username AS [Approver],
 	  	  	 Product_Desc, 
 	  	  	 Convert(VarChar(25), Convert(Decimal(10,2),Actual_Speed))  + ' ' + @AmountEngineeringUnits + '/min' AS Actual_Speed,
 	  	  	 Convert(VarChar(25), Convert(Decimal(10,2),Ideal_Speed))  + ' ' + @AmountEngineeringUnits + '/min' AS Ideal_Speed,
 	  	  	 Convert(VarChar(25), Convert(Decimal(10,2),Performance_Rate))  + ' %'  AS Performance_Rate,
 	  	  	 Convert(VarChar(25), Convert(Decimal(10,2),Net_Production))  + ' ' + @AmountEngineeringUnits  AS Net_Production,
 	  	  	 Convert(VarChar(25), Convert(Decimal(10,2),Waste))  + ' ' + @AmountEngineeringUnits  AS Waste,
 	  	  	 Convert(VarChar(25), Convert(Decimal(10,2),Quality_Rate))  + ' %'  AS Quality_Rate,
 	  	  	 Convert(VarChar(25), dbo.fnRS_MakeTimeDurationString(Run_Time)) as Run_Time,
      	  	 Convert(VarChar(25), dbo.fnRS_MakeTimeDurationString(Loading_Time)) as Loading_Time,
 	  	  	 Convert(VarChar(25), Convert(Decimal(10,2),Available_Rate))  + ' %'  AS Available_Rate,
 	  	  	 Convert(VarChar(25), Convert(Decimal(10,2),OEE))  + ' %'  AS OEE
 	  	 From #OEESummary_Raw
Drop Table #OEEStatistics
Drop Table #GrandTotals
Drop Table #CrewSchedule
Drop Table #EventTimes
Drop Table #OEESummary_Raw
Drop Table #OEESummary_ProductionDay
Drop Table #OEESummary_ShiftCrew
--/*****************************************************
