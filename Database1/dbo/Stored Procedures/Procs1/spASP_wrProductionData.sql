--exec [dbo].[spASP_wrProductionData] 1
CREATE procedure [dbo].[spASP_wrProductionData]
@ReportId int,
@RunId int = NULL
AS
--**************************************************/
/*
--spASP_wrProductionData 1081
--select * from report_definitions where report_type_id = -11
Declare @ReportId int, @RunId int
set nocount on
Select @ReportId=33009 --1080
--Select @ReportId=1080
-- downtime amount
--66 = 45 min
--67 = 40 min
--*/
set ansi_warnings off
Create Table #Prompts (
  PromptId int identity(1,1),
  PromptName varchar(20),
  PromptValue varchar(1000)
)
Create Table #PivotReportProductionDay(
 	  IS_NPT int,
     Production_Day datetime,
     Event_Count int,
     Initial_Dimension_X decimal(19,2),
     Final_Dimension_X decimal(19,2),
     Waste_Amount decimal(19,2),
     Waste_Percent decimal(19,2),
     Downtime_Events int,
     Downtime_Minutes int,
     Runtime_Minutes int,
     Percent_DownTime decimal(19,2)
)
Create Table #PivotReportShift(
 	  IS_NPT int,
     Shift_Desc varchar(10),
     Event_Count int,
     Initial_Dimension_X decimal(19,2),
     Final_Dimension_X decimal(19,2),
     Waste_Amount decimal(19,2),
     Waste_Percent decimal(19,2),
     Downtime_Events int,
     Downtime_Minutes int,
     Runtime_Minutes int,
     Percent_DownTime decimal(19,2)
)
Create Table #PivotReportCrew(
 	  IS_NPT int,
     Crew_Desc varchar(10),
     Event_Count int,
     Initial_Dimension_X decimal(19,2),
     Final_Dimension_X decimal(19,2),
     Waste_Amount decimal(19,2),
     Waste_Percent decimal(19,2),
     Downtime_Events int,
     Downtime_Minutes int,
     Runtime_Minutes int,
     Percent_DownTime decimal(19,2)
)
Create Table #PivotReportProcessOrder(
 	  IS_NPT int,
     Process_Order_Id int,
 	  Process_Order_Number varchar(50),
     Event_Count int,
     Initial_Dimension_X decimal(19,2),
     Final_Dimension_X decimal(19,2),
     Waste_Amount decimal(19,2),
     Waste_Percent decimal(19,2),
     Downtime_Events int,
     Downtime_Minutes int,
     Runtime_Minutes int,
     Percent_DownTime decimal(19,2)
)
Create Table #PivotReportProduct(
 	  IS_NPT int,
     Prod_Id int,
     Event_Count int,
     Initial_Dimension_X decimal(19,2),
     Final_Dimension_X decimal(19,2),
     Waste_Amount decimal(19,2),
     Waste_Percent decimal(19,2),
     Downtime_Events int,
     Downtime_Minutes int,
     Runtime_Minutes int,
     Percent_DownTime decimal(19,2)
)
Create Table #PivotReportStatus(
 	  IS_NPT int,
     Event_Status varchar(25),
     Event_Count int,
     Initial_Dimension_X decimal(19,2),
     Final_Dimension_X decimal(19,2),
     Waste_Amount decimal(19,2),
     Waste_Percent decimal(19,2),
     Downtime_Events int,
     Downtime_Minutes int,
     Runtime_Minutes int,
     Percent_DownTime decimal(19,2)
)
--==============================================
-- Return Data For Report
--==============================================
Create Table #Report (
 	 Row_Id int NOT NULL IDENTITY (1, 1),
 	 Event_Id int,
 	 Event_Number varchar(25),
 	 Event_Status varchar(25) NULL,
 	 Prod_Id int NULL,
 	 Start_Time datetime NULL,
 	 End_Time datetime,
 	 Process_Order_Id int NULL,
 	 Production_Day datetime,
 	 Shift_Name varchar(10) NULL, 
 	 Crew_Name varchar(10) NULL, 
 	 Waste_Amount real NULL,
 	 Initial_Dimension_X real NULL,
 	 Final_Dimension_X real NULL,
 	 Color int NULL,
 	 Event_Downtime_Minutes real NULL,
 	 Event_Downtime_Count int NULL,
 	 Event_Duration int,
 	 Productive_Start_Time datetime,
 	 Productive_End_Time datetime,
 	 Non_Productive_Seconds int,
 	 Perform_User_Id int,
 	 Verify_User_Id int,
 	 Perform_Username varchar(30),
 	 Verify_Username varchar(30),
 	 Process_Order_Number varchar(50)
)
Create Table #ReportGrandTotal(
     Event_Count int,
     Initial_Dimension_X real,
     Waste_Events int,
     Waste_Amount real,
     Waste_Percent  decimal(19, 2),
     Downtime_Events int,
     Runtime_Amount int,
     Downtime_Amount int,
     Downtime_Percent decimal(19, 2)
)
Create Table #CrewSchedule(
     Start_Time datetime,
     End_Time datetime,
     Shift_Desc varchar(10),
     Crew_Desc varchar(10),
     Shift_Duration int
)
Create Table #PivotProductionVariableData(
     Result_On datetime,
     Var_Desc varchar(50),
     Result varchar(25)
)
Create Table #ProductionVariableData(
     Result_On datetime,
     Event_Id int,
     Var_id int,
     Result Varchar(25),
     Var_Desc Varchar(50),
     Production_Day datetime,
     Shift varchar(10),
     Crew varchar(10),
     Process_Order_Id int,
     Prod_Id int,
     Event_Status varchar(25)
)
Declare @ReturnValue varchar(7000)
Declare @TargetTimeZone varchar(200)  
Declare @ReportName varchar(255)
Declare @DisplayGenealogyCounts int
Declare @DisplayDowntime int
Declare @DisplayWaste int
Declare @SummarizeDay int
Declare @SummarizeProduct int
Declare @SummarizeOrder int
Declare @SummarizeShift int
Declare @SummarizeCrew int
Declare @SummarizeStatus int
Declare @Variables varchar(1000)
Declare @CriteriaString varchar(1000)
Declare @StartTime datetime
Declare @EndTime datetime
Declare @Unit int
Declare @VariableDataPresent int
Declare @TimeOption int
Declare @DimensionXName varchar(50)
Declare @DimensionYName varchar(50)
Declare @DimensionZName varchar(50)
Declare @DimensionAName varchar(50)
Declare @CountColumnName varchar(20)
Declare @DayColumnName varchar(20)
Declare @ShiftColumnName varchar(20)
Declare @CrewColumnName varchar(20)
Declare @ProcessOrderColumnName varchar(20)
Declare @StatusColumnName varchar(20)
Declare @StartColumnName varchar(20)
Declare @EndColumnName varchar(20)
Declare @RemainingColumnName varchar(20)
Declare @ProductColumnName varchar(20)
Declare @ProductDescriptionColumnName varchar(20)
Declare @RuntimeColumnName varchar(20)
Declare @DowntimeColumnName varchar(20)
Declare @DowntimeCountColumnName varchar(20)
Declare @DowntimePercentColumnName varchar(20)
Declare @WasteColumnName varchar(20)
Declare @WastePercentColumnName varchar(20)
Declare @ParentCountColumnName varchar(20)
Declare @ChildCountColumnName varchar(20)
Declare @DisplayESignature int
Declare @ProductionVariable int
Declare @DisplayProdCodeOverDesc int
Declare @LocaleId int
Declare @LangId int
Select @CountColumnName = '#Items'
Select @DayColumnName = 'Production Day'
Select @ShiftColumnName = 'Shift'
Select @CrewColumnName = 'Crew'
Select @ProcessOrderColumnName = 'Process Order'
Select @StatusColumnName = 'Status'
Select @StartColumnName = 'Input'
Select @EndColumnName = 'Initial '
Select @RemainingColumnName = 'Remaining '
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
-------------------------------------------------------
-- Get Report Definition Parameter Values
-------------------------------------------------------
Declare @NonProductiveTimeFilter int
Declare @NPTLabel varchar(255)
Declare @NPTLabelDefault varchar(255)
SELECT 	 @ReturnValue = NULL
EXEC 	 spRS_GetReportParamValue 'LocaleId', @ReportId, @ReturnValue output
SELECT 	 @LocaleId = CASE @ReturnValue WHEN NULL THEN 0 ELSE abs(convert(INT, @ReturnValue)) END
SELECT @LangId = Language_id From Language_Locale_Conversion Where LocaleId=@LocaleId
If @LangId is Null SET @LangId = 0
select @NPTLabelDefault = '(npt)'
if (Select Count(*) from Site_Parameters where parm_id = 316) = 0
  Select @NPTLabel=@NPTLabelDefault
Else
  select @NPTLabel = Coalesce(case Value when '' then @NPTLabelDefault else value end, @NPTLabelDefault) from Site_Parameters where parm_Id = 316
Create Table  #TimeOptions (Option_Id int, Date_Type_Id int, Description varchar(50), Start_Time datetime, End_Time datetime)
Select @ReportName = Report_Name From Report_Definitions Where Report_Id = @ReportId
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'DisplayProdCodeOverDesc', @ReportId, @ReturnValue output 
Select @DisplayProdCodeOverDesc = ABS(Coalesce(convert(int,@ReturnValue), 0))
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'NonProductiveTimeFilter', @ReportId, @ReturnValue output 
Select @NonProductiveTimeFilter = ABS(Coalesce(convert(int,@ReturnValue), 0))
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'DisplayESignature', @ReportId, @ReturnValue output 
Select @DisplayESignature = ABS(Coalesce(convert(int,@ReturnValue), 0))
--Print 'Non-Productive Filter is ' + Case when @NonProductiveTimeFilter = 0 then 'OFF' Else 'ON' End
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'MasterUnit', @ReportId, @ReturnValue output 
Select @Unit = convert(int,@ReturnValue)
Select @TargetTimeZone = NULL 
Exec spRS_GetReportParamValue 'TargetTimeZone', @ReportId,@TargetTimeZone output 
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'TimeOption', @ReportId, @ReturnValue output 
Select @TimeOption = convert(int,@ReturnValue)
If @TimeOption = 0
     Begin
          Select @ReturnValue = NULL
          exec spRS_GetReportParamValue 'StartTime', @ReportId, @ReturnValue output 
          Select @StartTime = convert(datetime,@ReturnValue)
          Select @ReturnValue = NULL
          exec spRS_GetReportParamValue 'EndTime', @ReportId,@ReturnValue output 
          Select @EndTime = convert(datetime,@ReturnValue)
     End
Else
     Begin
          Insert Into #TimeOptions 
          exec spRS_GetTimeOptions @TimeOption,@TargetTimeZone
          Select @StartTime = Start_Time, @EndTime = End_Time From #TimeOptions
     End
 	 SELECT @StartTime= [dbo].[fnServer_CmnConvertToDbTime] (@StartTime,@TargetTimeZone)
 	 SELECT @EndTime= [dbo].[fnServer_CmnConvertToDbTime] (@EndTime,@TargetTimeZone)
 Drop Table #TimeOptions
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'DisplayGenealogy', @ReportId, @ReturnValue output 
Select @DisplayGenealogyCounts = (Coalesce(convert(int,@ReturnValue), -1))
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'DisplayDowntime', @ReportId, @ReturnValue output 
Select @DisplayDowntime = (Coalesce(convert(int,@ReturnValue), -1))
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'DisplayWaste', @ReportId, @ReturnValue output 
Select @DisplayWaste = (Coalesce(convert(int,@ReturnValue), -1))
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'SummarizeByDay', @ReportId, @ReturnValue output 
Select @SummarizeDay = (Coalesce(convert(int,@ReturnValue), -1))
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'SummarizeByProduct', @ReportId, @ReturnValue output 
Select @SummarizeProduct = (Coalesce(convert(int,@ReturnValue), -1))
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'SummarizeByOrder', @ReportId, @ReturnValue output 
Select @SummarizeOrder = (Coalesce(convert(int,@ReturnValue), -1))
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'SummarizeByShift', @ReportId, @ReturnValue output 
Select @SummarizeShift = (Coalesce(convert(int,@ReturnValue), -1))
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'SummarizeByCrew', @ReportId, @ReturnValue output 
Select @SummarizeCrew = (Coalesce(convert(int,@ReturnValue), -1))
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'SummarizeByStatus', @ReportId, @ReturnValue output 
Select @SummarizeStatus = (Coalesce(convert(int,@ReturnValue), -1))
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'Variables', @ReportId, @ReturnValue output 
Select @Variables = @ReturnValue
----------------------------------------------------
-- Check For Required Parameters And Set Defaults
----------------------------------------------------
If @ReportName Is Null 
 	 Select @ReportName = dbo.fnRS_TranslateString_New(@LangId, 36203, 'Production Listing')
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
-------------------------------------------------------
-- Get Column Label Information
-------------------------------------------------------
Declare @TimeUnitDesc varchar(20), @AmountEngineeringUnits varchar(20), @ItemEngineeringUnits varchar(20), @UnitPerTime varchar(50)
select @AmountEngineeringUnits=coalesce(AmountEngineeringUnits, 'Units'),
       @ItemEngineeringUnits=Coalesce(ItemEngineeringUnits, 'Units'),
       @TimeUnitDesc=Coalesce(TimeUnitDesc, 'Minute')
from dbo.fnCMN_GetEngineeringUnitsByUnit(@Unit)
Select @UnitPerTime = ' ' + @AmountEngineeringUnits --+ '/' + @TimeUnitDesc
Declare @InitialDimensionX varchar(50), @FinalDimensionX varchar(50)
select 
  @InitialDimensionX = case when LTrim(RTrim(s.dimension_x_name)) = '' then 'Initial Dimension X' else 'Initial ' + s.dimension_x_name end,
  @FinalDimensionX = case when LTrim(RTrim(s.dimension_x_name)) = '' then 'Initial Dimension X' else 'Final ' + s.dimension_x_name end
  from event_configuration e 
  join event_subtypes s on s.Event_Subtype_Id = e.Event_Subtype_Id
  where e.pu_id = @Unit 
 	  	 and e.et_id = 1
-------------------------------------------------------
-- Setup Prompts Table
-------------------------------------------------------
Insert into #Prompts (PromptName, PromptValue) Values ('ReportName', @ReportName)
Select @CriteriaString = dbo.fnRS_TranslateString_New(@LangId, 36204, 'Production For') + ' ' + (Select PU_Desc From Prod_Units Where PU_Id = @Unit)
Select @CriteriaString = @CriteriaString + 
 	 Case 
 	  	 When @NonProductiveTimeFilter=0 Then '<br><i>' + @NPTLabel + ' ' + dbo.fnRS_TranslateString_New(@LangId, 36026, 'Contains') +  ' ' + dbo.fnRS_TranslateString_New(@LangId, 35132, 'Non-Productive Time') + '</i>' Else '<br><i>' + dbo.fnRS_TranslateString_New(@LangId, 35132,'Non-Productive Time') + ' ' + dbo.fnRS_TranslateString_New(@LangId, 34651,'Removed') + '</i>' 
 	 End
Insert into #Prompts (PromptName, PromptValue) Values ('Criteria', @CriteriaString)
Insert into #Prompts (PromptName, PromptValue) Values ('StartTime', convert(varchar(25), [dbo].[fnServer_CmnConvertFromDbTime] (@StartTime,@TargetTimeZone),120))  
Insert into #Prompts (PromptName, PromptValue) Values ('EndTime', convert(varchar(25), [dbo].[fnServer_CmnConvertFromDbTime] (@EndTime,@TargetTimeZone),120)) 
Insert into #Prompts (PromptName, PromptValue) Values ('GenerateTime',convert(varchar(25), dbo.fnServer_CmnConvertFromDbTime(dbo.fnServer_CmnGetDate(getUTCdate()),@TargetTimeZone),120))  
Insert into #Prompts (PromptName, PromptValue) Values ('TotalSummary', dbo.fnRS_TranslateString_New(@LangId, 36205, 'Grand Totals'))
Insert into #Prompts (PromptName, PromptValue) Values ('StatusSummary', dbo.fnRS_TranslateString_New(@LangId, 36206, 'Status Summary'))
Insert into #Prompts (PromptName, PromptValue) Values ('ShiftSummary', dbo.fnRS_TranslateString_New(@LangId, 36207, 'Shift Summary'))
Insert into #Prompts (PromptName, PromptValue) Values ('CrewSummary', dbo.fnRS_TranslateString_New(@LangId, 36208, 'Crew Summary'))
Insert into #Prompts (PromptName, PromptValue) Values ('ProductSummary', dbo.fnRS_TranslateString_New(@LangId, 36209, 'Product Summary'))
Insert into #Prompts (PromptName, PromptValue) Values ('OrderSummary', dbo.fnRS_TranslateString_New(@LangId, 36210, 'Process Order Summary'))
Insert into #Prompts (PromptName, PromptValue) Values ('DaySummary', dbo.fnRS_TranslateString_New(@LangId, 36211, 'Production Day Summary'))
Insert into #Prompts (PromptName, PromptValue) Values ('DisplayWaste',Convert(varchar(2), @DisplayWaste))
Insert into #Prompts (PromptName, PromptValue) Values ('DisplayDowntime', Convert(varchar(2), @DisplayDowntime))
Insert into #Prompts (PromptName, PromptValue) Values ('SummarizeDay',Convert(varchar(5), @SummarizeDay))
Insert into #Prompts (PromptName, PromptValue) Values ('SummarizeOrder', Convert(varchar(5), @SummarizeOrder))
Insert into #Prompts (PromptName, PromptValue) Values ('SummarizeShift',Convert(varchar(5), @SummarizeShift))
Insert into #Prompts (PromptName, PromptValue) Values ('SummarizeCrew', Convert(varchar(5), @SummarizeCrew))
Insert into #Prompts (PromptName, PromptValue) Values ('SummarizeStatus',Convert(varchar(5), @SummarizeStatus))
Insert into #Prompts (PromptName, PromptValue) Values ('SummarizeProduct',Convert(varchar(5), @SummarizeProduct))
Insert into #Prompts (PromptName, PromptValue) Values ('Initial_Dimension_X', @InitialDimensionX)
Insert into #Prompts (PromptName, PromptValue) Values ('Final_Dimension_X', @FinalDimensionX)
Insert into #Prompts (PromptName, PromptValue) Values ('DisplayESignature', @DisplayESignature)
Insert into #Prompts (PromptName, PromptValue) Values ('TargetTimeZone',@TargetTimeZone)
Select * from #Prompts
-- This table holds the names of the variable Columns
Create Table #PivotFieldNames(ColName varchar(50))
-- Mill Start Time (i.e. 7:00:00)
Declare @MillStartTime varchar(8)
-- Dynamic SQL Strings
Declare @SQL varchar(8000), @SQL2 varchar(8000)
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
-- Get Production Variable Data
------------------------------------------------------
Insert Into #ProductionVariableData
     Exec spRS_GetProductionVariableData @StartTime,@EndTime, @Unit, @Variables 
------------------------------------------------------
-- Get Event Listing Details
------------------------------------------------------
Insert Into #Report(Event_Id, Event_Number, Event_Status, Start_Time, End_Time, Prod_Id, Initial_Dimension_X, Final_Dimension_X, Process_Order_Id, Color,
Productive_Start_Time, Productive_End_Time, Non_Productive_Seconds, perform_User_Id, verify_user_Id
)
  Select e.event_id, e.event_num, s.ProdStatus_Desc, e.Start_Time, e.Timestamp, 
         Case When e.Applied_Product Is Null Then ps.Prod_Id Else e.Applied_Product End,
          d.initial_dimension_x, 
          d.final_dimension_x, 
          d.pp_id, 	  
          Color = Case  
 	        When s.Status_Valid_For_Input <> 1 Then 1 --Red
 	        When s.Count_For_Production <> 1 Then 2 -- Blue
 	        Else -1 --Black
 	      End,
 	  	 Productive_Start_Time,
 	  	 Productive_End_Time,
 	  	 Non_Productive_Seconds, 
 	  	 es.perform_User_Id, es.verify_user_Id
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
 	 Order By e.Timestamp
------------------------------------------------------------------
-- Check For Variable Based Production
------------------------------------------------------------------
declare @EventData TABLE(Event_Id int, Initial_Dimension_X int)
select @ProductionVariable=Production_Variable from Prod_Units where PU_ID = @Unit
If @ProductionVariable Is Not NULL
Begin
 	 --Print 'Getting Production Data From Variable ' + convert(varchar(5), @ProductionVariable)
 	 -- Sum Production Amount From Tests Table Variable
 	 insert into @EventData
 	 select r.event_Id, SUM(CAST(CASE WHEN ISNUMERIC(t.result) = 1 THEN t.result ELSE '0' END AS float)) --sum(convert(float, t.result))
 	 from #Report r
 	 Join Tests t
 	 on t.event_Id = r.event_Id
 	 group by r.event_Id
 	 
 	 -- Update Local #Report Table
 	 Update O 
 	  	  Set o.Initial_Dimension_X = p.Initial_Dimension_X
 	  	  From @EventData p 
 	  	  Join #Report O on O.event_Id = P.event_Id
End
-----------------------------
-- Update Signoff Users
-----------------------------
Update O 
     Set Perform_Username = Username
     From Users u
     Join #Report O on O.perform_User_Id = U.User_Id
Update O 
     Set Verify_Username = Username
     From Users u
     Join #Report O on O.verify_user_Id = U.User_Id
Update #Report Set Perform_Username = '-' where Perform_Username Is Null
Update #Report Set Verify_Username = '-' where Verify_Username Is Null
Update #Report Set Initial_Dimension_X = 0 Where Initial_Dimension_X Is Null
Update #Report Set Final_Dimension_X = 0 Where Final_Dimension_X Is Null
------------------------------------------------------
-- Update Event Listing Details
------------------------------------------------------
Update #Report 
  Set Start_Time = (Select max(e.Timestamp) From Events e where e.pu_id = @Unit and e.timestamp < #Report.End_Time and e.timestamp > @StartTime)
  Where Start_Time Is Null
Update #Report 
  Set Start_Time = @StartTime
  Where Start_Time Is Null
Update #Report Set Production_Day = dbo.fnCMN_GetProductionDayByTimeStamp(End_time)
--------------------------------
-- Process Order
--------------------------------
Update #Report 
  Set Process_Order_Id = (Select min(ps.pp_id) From production_plan_starts ps where ps.pu_id = @Unit and ps.Start_Time <= #Report.End_Time and ((ps.End_Time > #Report.End_Time) or (ps.End_Time is Null)))
  Where Process_Order_Id Is Null
Update O 
     Set Process_Order_Number = Process_Order
     From Production_Plan u
     Join #Report O on O.Process_Order_Id = U.PP_Id
--------------------------------
-- Shift and Crew
--------------------------------
Update #Report Set
     Shift_Name = CS.Shift_Desc,
     Crew_Name = CS.Crew_Desc
     From #CrewSchedule CS
 	  Where #Report.End_Time > CS.Start_Time 
 	  	  	 and #Report.End_Time <= CS.End_Time
--------------------------------
-- Waste By Event
--------------------------------
UPDATE #Report
   SET Waste_Amount = (select sum(Waste_Event_Details.Amount)
      FROM Waste_Event_Details
         WHERE Waste_Event_Details.Event_Id = #Report.Event_Id)
--------------------------------
-- Downtime By Unit
--------------------------------
Declare @Row_Id int, @ST datetime, @ET datetime, @DTSec real, @DTCount int
Declare @NPSecondsForEvent int
Declare MyCursor INSENSITIVE CURSOR
  For ( Select Row_Id, Start_Time, End_Time From #Report )
  For Read Only
  Open MyCursor  
MyLoop1:
  Fetch Next From MyCursor Into @Row_Id, @ST, @ET
  If (@@Fetch_Status = 0)
    Begin
 	  	 Select @DTSec = TotalDowntimeSeconds, @DTCount=TotalCount From dbo.fnCMN_GetTotalDowntimeByUnit(@ST, @ET, @Unit, NULL)
 	  	 Update #Report Set 
 	  	   Event_Downtime_Minutes = @DTSec / 60.0,
 	  	   Event_Downtime_Count = @DTCount
 	  	 Where Row_Id = @Row_Id
      Goto MyLoop1
    End -- End Loop Here
Close MyCursor
Deallocate MyCursor
Update #Report Set Event_DownTime_Minutes = 0 Where Event_DownTime_Minutes Is Null
/*
-------------------------------------------------------
-- Filter Out Non-Productive Time
-------------------------------------------------------
 	 According to function dbo.fnCmn_ModifyNPTimeRange, 
 	 when Productive_Start_Time and Productive_End_Time are both null
 	 this means that the event is totally encompased by np time
 	 When the NP Filter is on do the following:
 	 - Remove all events that are totally within np time
 	 - for any events that have np time that are left
 	  	 - Prorate the production, waste & downtime
 	  	 - reset the event start & end times
*/
If @NonProductiveTimeFilter = 1
 	 Begin
 	  	 --Print 'Removing NP Events From #Report...'
 	  	 Delete From #Report Where (Productive_Start_Time Is Null) and (Productive_End_Time Is Null)
 	  	 --Print 'Pro-Rating Remaining NP Events In #Report...'
 	  	 Update #Report Set 
 	  	  	 -- ECR #33293
 	  	  	 --/*
 	  	  	 Initial_Dimension_X = Round(((Initial_Dimension_X / DateDiff(s, Start_Time, End_Time)) * DateDiff(s, Productive_Start_Time, Productive_End_Time)), 0),
 	  	  	 Waste_Amount = Round(((Waste_Amount / DateDiff(s, Start_Time, End_Time)) * DateDiff(s, Productive_Start_Time, Productive_End_Time)), 0),
 	  	  	 Event_Downtime_Minutes = Round(((Event_Downtime_Minutes / DateDiff(s, Start_Time, End_Time)) * DateDiff(s, Productive_Start_Time, Productive_End_Time)), 0)
 	  	  	 --********/
 	  	  	 /*
 	  	  	 Initial_Dimension_X = Round(dbo.fnCMN_GetProRatedProduction(Start_Time, End_Time, Productive_Start_Time, Productive_End_Time, Initial_Dimension_X),0),
 	  	  	 Waste_Amount = Round(dbo.fnCMN_GetProRatedProduction(Start_Time, End_Time, Productive_Start_Time, Productive_End_Time, Waste_Amount),0),
 	  	  	 Event_Downtime_Minutes = Round(dbo.fnCMN_GetProRatedProduction(Start_Time, End_Time, Productive_Start_Time, Productive_End_Time, Event_Downtime_Minutes),0)
 	  	  	 --******/
 	  	 Where Non_Productive_Seconds > 0
 	  	 --Print 'Resetting Start & End Time For NP Events In #Report...'
 	  	 Update #Report Set 
 	  	  	 Start_Time=Productive_Start_Time,
 	  	  	 End_Time=Productive_End_Time,
 	  	  	 Non_Productive_Seconds=0
 	  	 where Non_Productive_Seconds > 0
 	  	 -- I need to keep the value of NP seconds around so that I can flag the rows
 	  	 -- in the summary tables
 	 End
Update #Report Set Event_Duration = DateDiff(mi, Start_Time, End_Time)
/*
-------------------------------------------------------
-- Break up Events By Time Boundary
-------------------------------------------------------
Executing this procedure performs the following tasks:
-Parse all of the rows in #Report and look where and event start/end time crosses
 any of the following borders
 - Production Day
 - Shift or Crew change
When a boundry is crossed, that event will be split as follows:
Start_Time -> Boundry
Boundry -> End_Time
Waste, Downtime & Production will be prorated
*/
--exec spRS_SplitInsertProRateProductionData
Select @VariableDataPresent = Count(var_desc) From #ProductionVariableData
-------------------------------------------------------
-- Declare Pivot Tables For Variable Data
-------------------------------------------------------
Create Table #RawVariableDataByProductionDay(Production_Day datetime)
Create Table #RawVariableDataByShift(Shift_Desc varchar(10))
Create Table #RawVariableDataByCrew(Crew_Desc varchar(10))
Create Table #RawVariableDataByDescription(Result_On datetime)
Create Table #RawVariableDataByProcessOrder(Process_Order_Id int)
Create Table #RawVariableDataByProduct(Prod_Id int)
Create Table #RawVariableDataByEventStatus(Event_Status varchar(25))
If (@VariableDataPresent = 0)
     Print 'No Variable Data Present'
Else
     Begin          
          Insert Into #PivotFieldNames Select Distinct var_desc From #ProductionVariableData
          Select @SQL='', @SQL2=''
          Select @SQL2 = @SQL2 + ',[' + ColName + '] decimal(19,2)'  FROM #PivotFieldNames
          Select @SQL = 'Alter Table #ReportGrandTotal Add ' + Right(@SQL2, Len(@SQL2) -1) 
          EXEC (@SQL)
          ----------------------------------------------------------
          -- Build Variable By Production Day Table
          ----------------------------------------------------------
               -----------------------------------
          Select @SQL='', @SQL2=''
          Select @SQL2 = @SQL2 + ',[' + ColName + '] decimal(19,2)'  FROM #PivotFieldNames
          Select @SQL = 'Alter Table #RawVariableDataByProductionDay Add ' + Right(@SQL2, Len(@SQL2) -1) 
          EXEC (@SQL)
               -----------------------------------
          Insert Into #RawVariableDataByProductionDay
          exec spRS_CrossTab 
               'Select Production_Day From #ProductionVariableData Group By Production_Day', 
               'sum(convert(decimal(19,2), Result))', 
               'var_desc', 
               '#ProductionVariableData'
          ----------------------------------------------------------
          -- Build Variable By Shift Table
          ----------------------------------------------------------
               -----------------------------------
          Select @SQL='', @SQL2=''
          Select @SQL2 = @SQL2 + ',[' + ColName + '] decimal(19,2)'  FROM #PivotFieldNames
          Select @SQL = 'Alter Table #RawVariableDataByShift Add ' + Right(@SQL2, Len(@SQL2) -1) 
          EXEC (@SQL)
               -----------------------------------
          Insert Into #RawVariableDataByShift
          exec spRS_CrossTab 
               'Select Shift From #ProductionVariableData Group By Shift', 
               'sum(convert(decimal(19,2), Result))', 
               'var_desc', 
               '#ProductionVariableData'
          ----------------------------------------------------------
          -- Build Variable By Crew Table
          ----------------------------------------------------------
               -----------------------------------
          Select @SQL='', @SQL2=''
          Select @SQL2 = @SQL2 + ',[' + ColName + '] decimal(19,2)'  FROM #PivotFieldNames
          Select @SQL = 'Alter Table #RawVariableDataByCrew Add ' + Right(@SQL2, Len(@SQL2) -1) 
          EXEC (@SQL)
               -----------------------------------
          Insert Into #RawVariableDataByCrew
          exec spRS_CrossTab 
               'Select Crew From #ProductionVariableData Group By Crew', 
               'sum(convert(decimal(19,2), Result))', 
               'var_desc', 
               '#ProductionVariableData'
          ----------------------------------------------------------
          -- Build Variable By Event Table
          ----------------------------------------------------------
               -----------------------------------
          Select @SQL='', @SQL2=''
          Select @SQL2 = @SQL2 + ',[' + ColName + '] decimal(19,2)'  FROM #PivotFieldNames
          Select @SQL = 'Alter Table #RawVariableDataByDescription Add ' + Right(@SQL2, Len(@SQL2) -1) 
          EXEC (@SQL)
               -----------------------------------
          Insert Into #RawVariableDataByDescription
          exec spRS_CrossTab 
               'Select Result_On From #ProductionVariableData Group By Result_On', 
               'sum(convert(decimal(19,2), Result))', 
               'var_desc', 
               '#ProductionVariableData'
          ----------------------------------------------------------
          -- Build Variable By Process Order Table
          ----------------------------------------------------------
               -----------------------------------
          Select @SQL='', @SQL2=''
          Select @SQL2 = @SQL2 + ',[' + ColName + '] decimal(19,2)'  FROM #PivotFieldNames
          Select @SQL = 'Alter Table #RawVariableDataByProcessOrder Add ' + Right(@SQL2, Len(@SQL2) -1) 
          EXEC (@SQL)
               -----------------------------------
          Insert Into #RawVariableDataByProcessOrder
          exec spRS_CrossTab 
               'Select Process_Order_Id From #ProductionVariableData Group By Process_Order_Id', 
               'sum(convert(decimal(19,2), Result))', 
               'var_desc', 
               '#ProductionVariableData'
          ----------------------------------------------------------
          -- Build Variable By Process Order Table
          ----------------------------------------------------------
               -----------------------------------
          Select @SQL='', @SQL2=''
          Select @SQL2 = @SQL2 + ',[' + ColName + '] decimal(19,2)'  FROM #PivotFieldNames
          Select @SQL = 'Alter Table #RawVariableDataByProduct Add ' + Right(@SQL2, Len(@SQL2) -1) 
          EXEC (@SQL)
               -----------------------------------
          Insert Into #RawVariableDataByProduct
          exec spRS_CrossTab 
               'Select Prod_Id From #ProductionVariableData Group By Prod_Id', 
               'sum(convert(decimal(19,2), Result))', 
               'var_desc', 
               '#ProductionVariableData'
          ----------------------------------------------------------
          -- Build Variable By Status Table
          ----------------------------------------------------------
               -----------------------------------
          Select @SQL='', @SQL2=''
          Select @SQL2 = @SQL2 + ',[' + ColName + '] decimal(19,2)'  FROM #PivotFieldNames
          Select @SQL = 'Alter Table #RawVariableDataByEventStatus Add ' + Right(@SQL2, Len(@SQL2) -1) 
          EXEC (@SQL)
               -----------------------------------
          Insert Into #RawVariableDataByEventStatus
          exec spRS_CrossTab 
               'Select Event_Status From #ProductionVariableData Group By Event_Status', 
               'sum(convert(decimal(19,2), Result))', 
               'var_desc', 
               '#ProductionVariableData'
End -- If @Variable Data Present
----------------------------------------------------------
-- Get Downtime Information
----------------------------------------------------------
Create Table #PivotDownTimeByProductionDay(
     Production_Day datetime,
     Downtime_Events int,
     Downtime_Minutes int,
     Runtime_Minutes int,
     Percent_DownTime decimal(19,2)
)
Create Table #PivotDownTimeByShift(
     Shift_Desc varchar(10),
     Downtime_Events int,
     Downtime_Minutes int,
     Runtime_Minutes int,
     Percent_DownTime decimal(19,2)
)
Create Table #PivotDownTimeByCrew(
     Crew_Desc varchar(10),
     Downtime_Events int,
     Downtime_Minutes int,
     Runtime_Minutes int,
     Percent_DownTime decimal(19,2)
)
Create Table #PivotDownTimeProcessOrder(
     Process_Order_id int,
     Downtime_Events int,
     Downtime_Minutes int,
     Runtime_Minutes int,
     Percent_DownTime decimal(19,2)
)
Create Table #PivotDownTimeByProduct(
     Prod_Id int,
     Downtime_Events int,
     Downtime_Minutes int,
     Runtime_Minutes int,
     Percent_DownTime decimal(19,2)
)
Create Table #PivotDownTimeByStatus(
 	  IS_NPT int,
     Event_Status varchar(25),
     Downtime_Events int,
     Downtime_Minutes int,
     Runtime_Minutes int,
     Percent_DownTime decimal(19,2)
)
--------------------------------------------------------------------------------------
-- This call will populate the 6 tables above with downtime grouped accordingly
--------------------------------------------------------------------------------------
/*
Exec spRS_GetProductionDownTimeData @StartTime, @EndTime, @Unit, @NonProductiveTimeFilter
-- Not sure why this isn't taken care of with the above sp call
Insert Into #PivotDownTimeByStatus(IS_NPT, Event_Status, Downtime_Events, Downtime_Minutes, Runtime_Minutes, Percent_DownTime)
     Select Case When Sum(r.Non_Productive_Seconds) > 0 Then 1 Else 0 End,
 	  	   Event_Status,
          Count(*) AS DownTimeEvents,
          SUM(Event_Downtime_Minutes) AS DownTimeMinutes,
          Sum(Event_Duration) - Sum(Event_Downtime_Minutes) AS RunTimeMinutes,
         100 - ((SUM(Event_Duration) - Sum(Event_Downtime_Minutes)) * 100) / SUM(Event_Duration)  AS PercentUpTime
     From #Report r
     Group By Event_Status
     Order By Event_Status
*/
-------------------------------------------------------
-- Update Local Pivot Tables From #Report
-------------------------------------------------------
insert into #PivotReportProductionDay(IS_NPT, Production_Day, Event_Count, Initial_Dimension_X, Final_Dimension_X, Waste_Amount, Waste_Percent, Downtime_Events, Downtime_Minutes, Runtime_Minutes, Percent_Downtime)
     Select 
 	  	   Sum (r.Non_Productive_Seconds),
 	  	   Production_Day,
 	  	   sum(Case When r.End_Time > r.Production_Day Then 1 else 0 end) as [Event_Count],
          Convert(decimal(19, 2),Sum(Initial_Dimension_X)) as [Initial_Dimension_X],
          Convert(decimal(19, 2),Sum(Final_Dimension_X)) as [Final_Dimension_X],
          Convert(decimal(19, 2),Sum(Waste_Amount)) as [Waste],
 	  	   Case 
 	  	  	 When Sum(Initial_Dimension_X) > 0 Then
 	  	  	  	 Convert(decimal(19, 2), Convert(decimal(19, 2),Sum(Waste_Amount)) / Convert(decimal(19,2),Sum(Initial_Dimension_X)) * 100)
 	  	  	 Else
 	  	  	  	 0
 	  	  	 End  AS [Waste_Percent],
 	  	 Sum(Event_Downtime_Count),
 	  	 Sum(Event_Downtime_Minutes),
 	  	 Sum(Event_Duration) - Sum(Event_Downtime_Minutes),
 	  	 --(100 * Sum(Event_Downtime_Minutes)) / (Sum(Event_Duration) - Sum(Event_Downtime_Minutes))
 	  	 (Sum(Event_Downtime_Minutes) / Sum(Event_Duration)) * 100
 	  From #Report r
     Group By Production_Day
     Order By Production_Day
insert into #PivotReportShift(IS_NPT, Shift_Desc, Event_Count, Initial_Dimension_X, Final_Dimension_X, Waste_Amount, Waste_Percent, Downtime_Events, Downtime_Minutes, Runtime_Minutes, Percent_Downtime)
     Select  
 	  	   Sum (r.Non_Productive_Seconds),
 	  	   Shift_Name,
 	  	   sum(Case When r.End_Time > r.Production_Day Then 1 else 0 end) as [Event_Count],
          Convert(decimal(19, 2),Sum(Initial_Dimension_X)) as [Initial_Dimension_X],
          Convert(decimal(19, 2),Sum(Final_Dimension_X)) as [Final_Dimension_X],
          Convert(decimal(19, 2),Sum(Waste_Amount)) as [Waste],
 	  	   Case 
 	  	  	 When Sum(Initial_Dimension_X) > 0 Then
 	  	  	  	 Convert(decimal(19, 2), Convert(decimal(19, 2),Sum(Waste_Amount)) / Convert(decimal(19,2),Sum(Initial_Dimension_X)) * 100)
 	  	  	 Else
 	  	  	  	 0
 	  	  	 End AS [Waste_Percent],
 	  	 Sum(Event_Downtime_Count),
 	  	 Sum(Event_Downtime_Minutes),
 	  	 Sum(Event_Duration) - Sum(Event_Downtime_Minutes),
 	  	 --(100 * Sum(Event_Downtime_Minutes)) / (Sum(Event_Duration) - Sum(Event_Downtime_Minutes))
 	  	 (Sum(Event_Downtime_Minutes) / Sum(Event_Duration)) * 100
     From #Report r
     Group By Shift_Name
     Order By Shift_Name
insert into #PivotReportCrew(IS_NPT, Crew_Desc, Event_Count, Initial_Dimension_X, Final_Dimension_X, Waste_Amount, Waste_Percent, Downtime_Events, Downtime_Minutes, Runtime_Minutes, Percent_Downtime)
     Select  
 	  	   Sum (r.Non_Productive_Seconds),
 	  	   Crew_Name,
 	  	   sum(Case When r.End_Time > r.Production_Day Then 1 else 0 end) as [Event_Count],
          Convert(decimal(19, 2),Sum(Initial_Dimension_X)) as [Initial_Dimension_X],
          Convert(decimal(19, 2),Sum(Final_Dimension_X)) as [Final_Dimension_X],
          Convert(decimal(19, 2),Sum(Waste_Amount)) as [Waste],
 	  	   Case 
 	  	  	 When Sum(Initial_Dimension_X) > 0 Then
 	  	  	  	 Convert(decimal(19, 2), Convert(decimal(19, 2),Sum(Waste_Amount)) / Convert(decimal(19,2),Sum(Initial_Dimension_X)) * 100)
 	  	  	 Else
 	  	  	  	 0
 	  	  	 End AS [Waste_Percent],
 	  	 Sum(Event_Downtime_Count),
 	  	 Sum(Event_Downtime_Minutes),
 	  	 Sum(Event_Duration) - Sum(Event_Downtime_Minutes),
 	  	 --(100 * Sum(Event_Downtime_Minutes)) / (Sum(Event_Duration) - Sum(Event_Downtime_Minutes))
 	  	 (Sum(Event_Downtime_Minutes) / Sum(Event_Duration)) * 100
     From #Report r
     Group By Crew_Name
     Order By Crew_Name
Insert Into #PivotReportProcessOrder(IS_NPT, Process_Order_Id, Process_Order_Number, Event_Count, Initial_Dimension_X, Final_Dimension_X, Waste_Amount, Waste_Percent, Downtime_Events, Downtime_Minutes, Runtime_Minutes, Percent_Downtime)
     Select  
 	  	   Sum (r.Non_Productive_Seconds),
 	  	   Process_Order_Id,
 	  	   Process_Order_Number,
 	  	   sum(Case When r.End_Time > r.Production_Day Then 1 else 0 end) as [Event_Count],
          Convert(decimal(19, 2),Sum(Initial_Dimension_X)) as [Initial_Dimension_X],
          Convert(decimal(19, 2),Sum(Final_Dimension_X)) as [Final_Dimension_X],
          Convert(decimal(19, 2),Sum(Waste_Amount)) as [Waste],
 	  	   Case 
 	  	  	 When Sum(Initial_Dimension_X) > 0 Then
 	  	  	  	 Convert(decimal(19, 2), Convert(decimal(19, 2),Sum(Waste_Amount)) / Convert(decimal(19,2),Sum(Initial_Dimension_X)) * 100)
 	  	  	 Else
 	  	  	  	 0
 	  	  	 End  AS [Waste_Percent],
 	  	 Sum(Event_Downtime_Count),
 	  	 Sum(Event_Downtime_Minutes),
 	  	 Sum(Event_Duration) - Sum(Event_Downtime_Minutes),
 	  	 --(100 * Sum(Event_Downtime_Minutes)) / (Sum(Event_Duration) - Sum(Event_Downtime_Minutes))
 	  	 (Sum(Event_Downtime_Minutes) / Sum(Event_Duration)) * 100
     From #Report r
     Group By Process_Order_Number, Process_Order_Id
     Order By Process_Order_Number, Process_Order_Id
Insert Into #PivotReportProduct(IS_NPT, Prod_Id, Event_Count, Initial_Dimension_X, Final_Dimension_X, Waste_Amount, Waste_Percent, Downtime_Events, Downtime_Minutes, Runtime_Minutes, Percent_Downtime)
     Select  
 	  	   Sum (r.Non_Productive_Seconds),
 	  	   Prod_Id,
 	  	   sum(Case When r.End_Time > r.Production_Day Then 1 else 0 end) as [Event_Count],
          Convert(decimal(19, 2),Sum(Initial_Dimension_X)) as [Initial_Dimension_X],
          Convert(decimal(19, 2),Sum(Final_Dimension_X)) as [Final_Dimension_X],
          Convert(decimal(19, 2),Sum(Waste_Amount)) as [Waste],
 	  	   Case 
 	  	  	 When Sum(Initial_Dimension_X) > 0 Then
 	  	  	  	 Convert(decimal(19, 2), Convert(decimal(19, 2),Sum(Waste_Amount)) / Convert(decimal(19,2),Sum(Initial_Dimension_X)) * 100) 
 	  	  	 Else
 	  	  	  	 0
 	  	  	 End AS [Waste_Percent],
 	  	 Sum(Event_Downtime_Count),
 	  	 Sum(Event_Downtime_Minutes),
 	  	 Sum(Event_Duration) - Sum(Event_Downtime_Minutes),
 	  	 --(100 * Sum(Event_Downtime_Minutes)) / (Sum(Event_Duration) - Sum(Event_Downtime_Minutes))
 	  	 (Sum(Event_Downtime_Minutes) / Sum(Event_Duration)) * 100
     From #Report r
     Group By Prod_Id
     Order By Prod_Id
Insert Into #PivotReportStatus(IS_NPT, Event_Status, Event_Count, Initial_Dimension_X, Final_Dimension_X, Waste_Amount, Waste_Percent, Downtime_Events, Downtime_Minutes, Runtime_Minutes, Percent_Downtime)
     Select  
 	  	   Sum (r.Non_Productive_Seconds),
 	  	   Event_Status,
 	  	   sum(Case When r.End_Time > r.Production_Day Then 1 else 0 end) as [Event_Count],
          Convert(decimal(19, 2),Sum(Initial_Dimension_X)) as [Initial_Dimension_X],
          Convert(decimal(19, 2),Sum(Final_Dimension_X)) as [Final_Dimension_X],
          Convert(decimal(19, 2),Sum(Waste_Amount)) as [Waste],
 	  	   Case 
 	  	  	 When Sum(Initial_Dimension_X) > 0 Then
 	  	  	  	 Convert(decimal(19, 2), Convert(decimal(19, 2),Sum(Waste_Amount)) / Convert(decimal(19,2),Sum(Initial_Dimension_X)) * 100)
 	  	  	 Else
 	  	  	  	 0
 	  	  	 End AS [Waste_Percent],
 	  	 Sum(Event_Downtime_Count),
 	  	 Sum(Event_Downtime_Minutes),
 	  	 Sum(Event_Duration) - Sum(Event_Downtime_Minutes),
 	  	 --(100 * Sum(Event_Downtime_Minutes)) / (Sum(Event_Duration) - Sum(Event_Downtime_Minutes))
 	  	 (Sum(Event_Downtime_Minutes) / Sum(Event_Duration)) * 100
     From #Report r
     Group By Event_Status
     Order By Event_Status
-------------------------------------------------------
-- Begin Returning Data
-------------------------------------------------------
--Print '--========================================='
--Print '-- GRAND TOTAL'
--Print '--========================================='
Declare @TotalEvents int
Declare @TotalDimensionX real
Declare @TotalWaste real
Declare @WasteEvents int
Declare @DowntimeEvents int
Declare @DowntimeMinutes int
Declare @RunTimeMinutes int
Declare @SQL3 varchar(8000)
Declare @SQL4 varchar(8000)
Select @TotalEvents = Count(Distinct Event_Id) From #Report
Select @WasteEvents = Count(Distinct Event_Id) From #Report where Waste_Amount > 0
Select @DowntimeEvents = Sum(Event_Downtime_Count) From #Report
Select @TotalDimensionX = Sum(Initial_Dimension_X) From #Report
Select @TotalWaste = Sum(Waste_Amount) From #Report
Select @DowntimeMinutes = Sum(Event_Downtime_Minutes) From #Report
Select @RunTimeMinutes = sum(Datediff(mi, Start_Time, End_Time) - coalesce(Event_Downtime_Minutes,0.0)) From #Report
If (@VariableDataPresent <> 0)
     Begin
          Select @SQL='', @SQL2='', @SQL3='', @SQL4=''
          Select @SQL2 = @SQL2 + ',Sum([' + ColName + '])'  FROM #PivotFieldNames
          Select @SQL3 = @SQL3 + ',[' + ColName + ']' From #PivotFieldNames
          Select @SQL = 'Insert Into #ReportGrandTotal(' + Right(@SQL3, Len(@SQL3) -1) + ')'
          --Print @SQL
          Select @SQL4 = @SQL + '  Select ' + Right(@SQL2, Len(@SQL2) -1) + ' From #RawVariableDataByDescription' 
          --Print @SQL4
          exec (@SQL4)
     End
Else
     Insert Into #ReportGrandTotal(Event_Count) values(0)
 	 Update #ReportGrandTotal Set
 	  	 Event_Count = @TotalEvents, 
 	  	 Initial_Dimension_X = @TotalDimensionX, 
 	  	 Waste_Amount = @TotalWaste, 
 	  	 Waste_Events = @WasteEvents, 
 	  	 Waste_Percent = 0, 
 	  	 Downtime_Events = @DowntimeEvents, 
 	  	 Downtime_Amount = @DowntimeMinutes, 
 	  	 Runtime_Amount = @RunTimeMinutes, 
 	  	 Downtime_Percent = convert(decimal(19, 2), (convert(float, @DowntimeMinutes)/ convert(float,(@DowntimeMinutes + @RunTimeMinutes))) * 100)
IF @TotalDimensionX >0
 	 Update #ReportGrandTotal Set
 	  	 Waste_Percent = (@TotalWaste / @TotalDimensionX) * 100
 	 --Downtime_Percent = @DowntimeMinutes * 100 / @RunTimeMinutes
/*
select @DowntimeMinutes, @RunTimeMinutes, @DowntimeMinutes + @RunTimeMinutes, 
convert(decimal(19, 2), (convert(float, @DowntimeMinutes)/ convert(float,(@DowntimeMinutes + @RunTimeMinutes))) * 100)
*/
Select Event_Count, 
ltrim(Str(Initial_Dimension_X, 19, 2) + @UnitPerTime) [Initial_Dimension_X], 
Waste_Events, 
ltrim(Str(Waste_Amount, 19, 2) + @UnitPerTime) [Waste_Amount], 
Waste_Percent, Downtime_Events, 
dbo.fnRS_MakeTimeDurationString(Runtime_Amount) AS [Runtime_Amount],
dbo.fnRS_MakeTimeDurationString(Downtime_Amount) AS [Downtime_Amount],
Downtime_Percent 
from #ReportGrandTotal
----------------------------------------------------------------
-- Begin Joining Tables
----------------------------------------------------------------
-- Return Grand Totals Table
-- Drop R.Final_Dimension_X
Print '--========================================='
Print '-- Production Day Summary'
Print '--========================================='
Select Convert(varchar(10),   [dbo].[fnServer_CmnConvertFromDbTime] (R.Production_Day,@TargetTimeZone)   , 120)AS [Production_Day],
R.Event_Count, 
ltrim(Str(R.Initial_Dimension_X, 19, 2) + @UnitPerTime) [Initial_Dimension_X], 
ltrim(Str(R.Waste_Amount, 19, 2) + @UnitPerTime) [Waste_Amount], 
R.Waste_Percent,
dbo.fnRS_MakeTimeDurationString(R.IS_NPT / 60) AS [NP_Time],
dbo.fnRS_MakeTimeDurationString(R.Runtime_Minutes) AS [Runtime_Minutes],
dbo.fnRS_MakeTimeDurationString(R.Downtime_Minutes) AS [Downtime_Minutes],
R.Downtime_Events, 
R.Percent_DownTime,
     V.*
from #PivotReportProductionDay R
--Left Outer Join #PivotDownTimeByProductionDay D on D.Production_Day = R.Production_Day
Left Outer Join #RawVariableDataByProductionDay V on V.Production_Day = R.Production_Day
Order By R.Production_Day
Print '--========================================='
Print '-- Shift Summary'
Print '--========================================='
Select R.Shift_Desc, 
R.Event_Count, 
ltrim(Str(R.Initial_Dimension_X, 19, 2) + @UnitPerTime) [Initial_Dimension_X], 
ltrim(Str(R.Waste_Amount, 19, 2) + @UnitPerTime) [Waste_Amount], 
R.Waste_Percent,
dbo.fnRS_MakeTimeDurationString(R.IS_NPT / 60) AS [NP_Time],
dbo.fnRS_MakeTimeDurationString(R.Runtime_Minutes) AS [Runtime_Minutes],
dbo.fnRS_MakeTimeDurationString(R.Downtime_Minutes) AS [Downtime_Minutes],
R.Downtime_Events, R.Percent_DownTime,
     V.*
from #PivotReportShift R
--Left Outer Join #PivotDownTimeByShift D on D.Shift_Desc = R.Shift_Desc
Left Outer Join #RawVariableDataByShift V on V.Shift_Desc = R.Shift_Desc
Order By R.Shift_Desc
Print '--========================================='
Print '-- Crew Summary'
Print '--========================================='
Select R.Crew_Desc, 
R.Event_Count, 
ltrim(Str(R.Initial_Dimension_X, 19, 2) + @UnitPerTime) [Initial_Dimension_X], 
ltrim(Str(R.Waste_Amount, 19, 2) + @UnitPerTime) [Waste_Amount], 
R.Waste_Percent,
dbo.fnRS_MakeTimeDurationString(R.IS_NPT / 60) AS [NP_Time],
dbo.fnRS_MakeTimeDurationString(R.Runtime_Minutes) AS [Runtime_Minutes],
dbo.fnRS_MakeTimeDurationString(R.Downtime_Minutes) AS [Downtime_Minutes],
R.Downtime_Events, R.Percent_DownTime,
     V.*
from #PivotReportCrew R
--Left Outer Join #PivotDownTimeByCrew D on D.Crew_Desc = R.Crew_Desc
Left Outer Join #RawVariableDataByCrew V on V.Crew_Desc = R.Crew_Desc
Order By R.Crew_Desc
Print '--========================================='
Print '-- Process Order Summary'
Print '--========================================='
If (select Count(*) from #PivotReportProcessOrder Where Process_Order_Number Is Not Null) > 0
 	  	 Select R.Process_Order_Number AS [Process_Order_Number], 
 	  	 R.Event_count, 
 	  	 ltrim(Str(R.Initial_Dimension_X, 19, 2) + @UnitPerTime) [Initial_Dimension_X], 
 	  	 ltrim(Str(R.Waste_Amount, 19, 2) + @UnitPerTime) [Waste_Amount], 
 	  	 R.Waste_Percent,
 	  	 dbo.fnRS_MakeTimeDurationString(R.IS_NPT / 60) AS [NP_Time],
 	  	 dbo.fnRS_MakeTimeDurationString(R.Runtime_Minutes) AS [Runtime_Minutes],
 	  	 dbo.fnRS_MakeTimeDurationString(R.Downtime_Minutes) AS [Downtime_Minutes],
 	  	 R.Downtime_Events, R.Percent_DownTime,
 	  	  	  V.*
 	  	 from #PivotReportProcessOrder R
 	  	 --Left Outer Join #PivotDownTimeProcessOrder D on D.Process_Order_Id = R.Process_Order_Id
 	  	 Left Outer Join #RawVariableDataByProcessOrder V on V.Process_Order_Id = R.Process_Order_Id
 	  	 Where R.Process_Order_Number Is Not Null
 	  	 Order By R.Process_Order_Id
Else
 	  	 Select dbo.fnRS_TranslateString_New(@LangId, 36410, 'No Process Orders') AS [Process_Order_Number], 
 	  	 0 AS [Event_Count], 
 	  	 0 AS [Initial_Dimension_X], 
 	  	 0 AS [Waste_Amount], 
 	  	 0 AS [Waste_Percent],
 	  	 0 AS [NP_Time],
 	  	 0 AS [Runtime_Minutes],
 	  	 0 AS [Downtime_Minutes],
 	  	 0 AS [Downtime_Events], 
 	  	 0 AS [Percent_DownTime]
Print '--========================================='
Print '-- Product Summary'
Print '--========================================='
Select 
Case When @DisplayProdCodeOverDesc=0 Then P.Prod_Desc Else P.Prod_Code End [Product],
--P.Prod_Desc, 
R.Event_count, 
ltrim(Str(R.Initial_Dimension_X, 19, 2) + @UnitPerTime) [Initial_Dimension_X], 
ltrim(Str(R.Waste_Amount, 19, 2) + @UnitPerTime) [Waste_Amount], 
R.Waste_Percent,
dbo.fnRS_MakeTimeDurationString(R.IS_NPT / 60) AS [NP_Time],
dbo.fnRS_MakeTimeDurationString(R.Runtime_Minutes) AS [Runtime_Minutes],
dbo.fnRS_MakeTimeDurationString(R.Downtime_Minutes) AS [Downtime_Minutes],
R.Downtime_Events, R.Percent_DownTime,
     V.*
from #PivotReportProduct R
--Left Outer Join #PivotDownTimeByProduct D on D.Prod_Id = R.Prod_Id
Left Outer Join #RawVariableDataByProduct V on V.Prod_Id = R.Prod_Id
Join Products P on P.Prod_Id = R.Prod_Id
Order By R.Prod_Id
Print '--========================================='
Print '-- Status Summary'
Print '--========================================='
Select R.Event_Status, 
R.Event_count, 
ltrim(Str(R.Initial_Dimension_X, 19, 2) + @UnitPerTime) [Initial_Dimension_X], 
ltrim(Str(R.Waste_Amount, 19, 2) + @UnitPerTime) [Waste_Amount], 
R.Waste_Percent,
dbo.fnRS_MakeTimeDurationString(R.IS_NPT / 60) AS [NP_Time],
dbo.fnRS_MakeTimeDurationString(R.Runtime_Minutes) AS [Runtime_Minutes],
dbo.fnRS_MakeTimeDurationString(R.Downtime_Minutes) AS [Downtime_Minutes],
R.Downtime_Events, R.Percent_DownTime,
     V.*
from #PivotReportStatus R
--Left Outer Join #PivotDownTimeByStatus D on D.Event_Status = R.Event_Status
Left Outer Join #RawVariableDataByEventStatus V on V.Event_Status = R.Event_Status
Order By R.Event_Status
/*
Select Event_Number, Start_Time, End_Time, Event_Downtime_Count, Event_Downtime_Minutes --, datediff(mi, Start_Time, End_Time)
from #Report order by start_time --where Event_Downtime_minutes > 0 --and event_downtime_count = 0
*/
Print '--========================================='
Print '-- Event Summary'
Print '--========================================='
If @DisplayESignature = 0
 	 If @NonProductiveTimeFilter = 0
 	  	 
 	  	 Select 
 	  	 Convert(varchar(10),  [dbo].[fnServer_CmnConvertFromDbTime] (Production_Day,@TargetTimeZone)  , 120) AS [Production_Day],
 	  	 Shift_Name, 
 	  	 Crew_Name, 
 	  	 Event_Number [Event_Number], 
 	  	 Event_Id [Event_Id],
 	  	 Process_Order_Number AS [Process_Order_Number],
 	  	 Case When @DisplayProdCodeOverDesc = 1 Then P.Prod_Code Else P.Prod_Desc End AS [Product],
 	  	 --P.Prod_Desc, 
 	  	 R.Event_Status,
 	  	 Convert(varchar(25),  [dbo].[fnServer_CmnConvertFromDbTime] (Start_Time,@TargetTimeZone)  , 120) AS [Start_Time],  
 	  	 Convert(varchar(25),  [dbo].[fnServer_CmnConvertFromDbTime] ( End_Time,@TargetTimeZone)  , 120) AS [End_Time],  
 	  	 ltrim(Str(R.Initial_Dimension_X, 19, 2) + @UnitPerTime) [Initial_Dimension_X], 
 	  	 ltrim(Str(R.Final_Dimension_X, 19, 2) + @UnitPerTime) [Final_Dimension_X], 
 	  	 ltrim(Str(R.Waste_Amount, 19, 2) + @UnitPerTime) [Waste_Amount], 
 	  	 dbo.fnRS_MakeTimeDurationString(Event_Downtime_Minutes) AS [Event_Downtime_Minutes],
 	  	 dbo.fnRS_MakeTimeDurationString(R.Non_Productive_Seconds / 60) AS [NP_Time],
 	  	 Event_Downtime_Count, V.*
 	  	 from #Report R
 	  	 Left outer Join #RawVariableDataByDescription V on V.Result_On = R.End_Time
 	  	 Join Products p on p.Prod_Id = R.Prod_Id
 	  	 Order By R.Production_Day
 	 Else
 	  	 Select 
 	  	 Convert(varchar(10),   [dbo].[fnServer_CmnConvertFromDbTime] (Production_Day,@TargetTimeZone)  , 120) AS [Production_Day],
 	  	 Shift_Name, 
 	  	 Crew_Name, 
 	  	 Event_Number [Event_Number], 
 	  	 Event_Id [Event_Id],
 	  	 Process_Order_Number AS [Process_Order_Number],
 	  	 Case When @DisplayProdCodeOverDesc = 1 Then P.Prod_Code Else P.Prod_Desc End AS [Product],
 	  	 R.Event_Status,
 	  	 Convert(varchar(25),   [dbo].[fnServer_CmnConvertFromDbTime] (Start_Time,@TargetTimeZone)  , 120) AS [Start_Time],  
 	  	 Convert(varchar(25), [dbo].[fnServer_CmnConvertFromDbTime] ( End_Time,@TargetTimeZone)  , 120) AS [End_Time], 
 	  	 ltrim(Str(R.Initial_Dimension_X, 19, 2) + @UnitPerTime) [Initial_Dimension_X], 
 	  	 ltrim(Str(R.Final_Dimension_X, 19, 2) + @UnitPerTime) [Final_Dimension_X], 
 	  	 ltrim(Str(R.Waste_Amount, 19, 2) + @UnitPerTime) [Waste_Amount], 
 	  	 dbo.fnRS_MakeTimeDurationString(Event_Downtime_Minutes) AS [Event_Downtime_Minutes],
 	  	 Event_Downtime_Count, V.*
 	  	 from #Report R
 	  	 Left outer Join #RawVariableDataByDescription V on V.Result_On = R.End_Time
 	  	 Join Products p on p.Prod_Id = R.Prod_Id
 	  	 Order By R.Production_Day
Else
 	 If @NonProductiveTimeFilter = 0
 	  	 Select 
 	  	 Convert(varchar(10),  [dbo].[fnServer_CmnConvertFromDbTime] (Production_Day,@TargetTimeZone)  , 120) AS [Production_Day],
 	  	 Shift_Name, 
 	  	 Crew_Name, 
 	  	 Event_Number [Event_Number], 
 	  	 Event_Id [Event_Id],
 	  	 Perform_Username AS [User],
 	  	 Verify_Username AS [Approver],
 	  	 Process_Order_Number AS [Process_Order_Number],
 	  	 Case When @DisplayProdCodeOverDesc = 1 Then P.Prod_Code Else P.Prod_Desc End AS [Product],
 	  	 R.Event_Status,
 	  	 Convert(varchar(25),  [dbo].[fnServer_CmnConvertFromDbTime] (Start_Time,@TargetTimeZone)  , 120) AS [Start_Time], 
 	  	 Convert(varchar(25), [dbo].[fnServer_CmnConvertFromDbTime] ( End_Time,@TargetTimeZone)  , 120) AS [End_Time],
 	  	 ltrim(Str(R.Initial_Dimension_X, 19, 2) + @UnitPerTime) [Initial_Dimension_X], 
 	  	 ltrim(Str(R.Final_Dimension_X, 19, 2) + @UnitPerTime) [Final_Dimension_X], 
 	  	 ltrim(Str(R.Waste_Amount, 19, 2) + @UnitPerTime) [Waste_Amount], 
 	  	 dbo.fnRS_MakeTimeDurationString(Event_Downtime_Minutes) AS [Event_Downtime_Minutes],
 	  	 dbo.fnRS_MakeTimeDurationString(R.Non_Productive_Seconds / 60) AS [NP_Time],
 	  	 Event_Downtime_Count, V.*
 	  	 from #Report R
 	  	 Left outer Join #RawVariableDataByDescription V on V.Result_On = R.End_Time
 	  	 Join Products p on p.Prod_Id = R.Prod_Id
 	  	 Order By R.Production_Day
 	 Else
 	  	 Select 
 	  	 Convert(varchar(10),   [dbo].[fnServer_CmnConvertFromDbTime] (Production_Day,@TargetTimeZone)  , 120) AS [Production_Day],
 	  	 Shift_Name, 
 	  	 Crew_Name, 
 	  	 Event_Number [Event_Number], 
 	  	 Event_Id [Event_Id],
 	  	 Perform_Username AS [User],
 	  	 Verify_Username AS [Approver],
 	  	 Process_Order_Number AS [Process_Order_Number],
 	  	 Case When @DisplayProdCodeOverDesc = 1 Then P.Prod_Code Else P.Prod_Desc End AS [Product],
 	  	 R.Event_Status,
 	  	 Convert(varchar(25),  [dbo].[fnServer_CmnConvertFromDbTime] (Start_Time,@TargetTimeZone)  , 120) AS [Start_Time], --Sarla
 	  	 Convert(varchar(25),  [dbo].[fnServer_CmnConvertFromDbTime] ( End_Time,@TargetTimeZone)  , 120) AS [End_Time], --Sarla
 	  	 ltrim(Str(R.Initial_Dimension_X, 19, 2) + @UnitPerTime) [Initial_Dimension_X], 
 	  	 ltrim(Str(R.Final_Dimension_X, 19, 2) + @UnitPerTime) [Final_Dimension_X], 
 	  	 ltrim(Str(R.Waste_Amount, 19, 2) + @UnitPerTime) [Waste_Amount], 
 	  	 dbo.fnRS_MakeTimeDurationString(Event_Downtime_Minutes) AS [Event_Downtime_Minutes],
 	  	 Event_Downtime_Count, V.*
 	  	 from #Report R
 	  	 Left outer Join #RawVariableDataByDescription V on V.Result_On = R.End_Time
 	  	 Join Products p on p.Prod_Id = R.Prod_Id
 	  	 Order By R.Production_Day
--Select * from #RawVariableDataByDescription
--Select Count(*) From #Report
--select distinct Count(EventId) from #Report
-------------------------------------------------------------
-- Procedure Cleanup
-------------------------------------------------------------
-- Drop Standard Data Tables 
Drop Table #ReportGrandTotal
Drop Table #Report
Drop Table #CrewSchedule
Drop table #ProductionVariableData
Drop table #PivotFieldNames
-- Drop Event Pivot Tables
Drop Table #PivotReportProductionDay
Drop Table #PivotReportShift
Drop Table #PivotReportCrew
Drop Table #PivotReportProcessOrder
Drop Table #PivotReportProduct
Drop Table #PivotReportStatus
-- Drop Variable Pivot Tables
Drop Table #RawVariableDataByProductionDay
Drop Table #RawVariableDataByShift
Drop Table #RawVariableDataByCrew
Drop Table #RawVariableDataByDescription
Drop Table #RawVariableDataByProcessOrder
Drop Table #RawVariableDataByProduct
Drop Table #RawVariableDataByEventStatus
-- Drop Downtime Pivot Tables
Drop Table #PivotDownTimeByProductionDay
Drop Table #PivotDownTimeByShift
Drop Table #PivotDownTimeByCrew
Drop Table #PivotDownTimeProcessOrder
Drop Table #PivotDownTimeByProduct
Drop Table #PivotDownTimeByStatus
Drop table #PivotProductionVariableData
Drop Table #Prompts
