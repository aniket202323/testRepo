CREATE procedure [dbo].[spASP_wrEventHistoryColor]
@ReportId int,
@RunId int = NULL
AS
--******************************************************************************************************************************************/
/*
set nocount on
Declare @ReportId int, @Runid int
Select @ReportId= 697
--*/
/*
SET NOCOUNT ON
EXEC spASP_wrEventHistoryColor 697
-- Dan Feb-1-2005
 	 Proficy 4.3 Added support for Non-Productive Time
-- Dan Aug-17-2004
  Changed selection criteria so that joins are inclusive in regards to Start_Time
--Dan Aug-9-2004
Changed Timestamps to be converted to 120
Altered selection criteria from production starts.  See code below
--TODO: Filter Variables By Event Sub-type Too
--TODO: Get Production Plan Status Color From New Tables
--TODO: Add Comment Id's To Waste, Downtime, Uptime With New Database Changes
--TODO: Recognize Requested Regional Settings
--TODO: Create Index On Timestamp
--TODO: Try To Order Product Resultsets By First Time Run
--??TODO: Change To Get Variables By "Sheet"??
*/
set arithignore on
set arithabort off
set ansi_warnings off
Declare @SpecificationSetting int  -- For Specification Comparisons
Select @SpecificationSetting = convert(int,value) From Site_Parameters Where Parm_id = 13
If @SpecificationSetting is Null Select @SpecificationSetting = 1
Declare @ReportName varchar(255)
Declare @CriteriaString varchar(1000)
Declare @Unit int
Declare @StartTime datetime
Declare @EndTime datetime
Declare @Variables varchar(4000)
Declare @Products varchar(4000)
Declare @EventType int
Declare @EventSubtype int
Declare @MaxVariableCount int
Declare @IgnoreNoData int 
Declare @TargetTimeZone varchar(200)
Declare @NumberOfPoints int
Declare @SQL varchar(3000)
Declare @EventName varchar(100)
Declare @UDEType int
Declare @DisplayESignature int
Declare @NonProductiveTimeFilter int
Declare @NPTLabel varchar(255)
Declare @NPTLabelDefault varchar(255)
Declare @@NumberOfDigits int
select @NPTLabelDefault = '(npt)'
if (Select Count(*) from Site_Parameters where parm_id = 316) = 0
  Select @NPTLabel=@NPTLabelDefault
Else
  select @NPTLabel = Coalesce(case Value when '' then @NPTLabelDefault else value end, @NPTLabelDefault) from Site_Parameters where parm_Id = 316
--/**********************************************
-- Loookup Parameters For This Report Id
--**********************************************
Declare @ReturnValue varchar(7000)
Declare @LocaleId int,@LangId int
DECLARE @TimeOption int
Create Table  #TimeOptions (Option_Id int, Date_Type_Id int, Description varchar(50), Start_Time datetime, End_Time datetime)
SELECT 	 @ReturnValue = NULL
EXEC 	 spRS_GetReportParamValue 'LocaleId', @ReportId, @ReturnValue output
SELECT 	 @LocaleId = CASE @ReturnValue WHEN NULL THEN 0 ELSE abs(convert(INT, @ReturnValue)) END
SELECT @LangId = Language_id From Language_Locale_Conversion Where LocaleId=@LocaleId
If @LangId is Null SET @LangId = 0
Select @ReportName = Report_Name From Report_Definitions Where Report_Id = @ReportId
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'DisplayESignature', @ReportId, @ReturnValue output
Select @DisplayESignature = ABS(Coalesce(convert(int,@ReturnValue), 0))
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'NonProductiveTimeFilter', @ReportId, @ReturnValue output
Select @NonProductiveTimeFilter = ABS(Coalesce(convert(int,@ReturnValue), 0))
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'MasterUnit', @ReportId, @ReturnValue output
Select @Unit = convert(int,@ReturnValue)
exec spRS_GetReportParamValue 'Products', @ReportId, @Products output
exec spRS_GetReportParamValue 'Variables', @ReportId, @Variables output
Select @TargetTimeZone = NULL 
exec spRS_GetReportParamValue 'TargetTimeZone', @ReportId,@TargetTimeZone output
select @NumberOfPoints = 0
exec spRS_GetReportParamValue 'No_Of_DataPoints',@ReportId,@NumberOfPoints output
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'TimeOption', @ReportId, @ReturnValue output 
Select @TimeOption = convert(int,@ReturnValue)
If @TimeOption = 0
     Begin
 	  	 Select @ReturnValue = NULL
 	  	 exec spRS_GetReportParamValue 'StartTime', @ReportId, @ReturnValue output
 	  	 Select @StartTime = convert(datetime, @ReturnValue)
 	  	 Select @ReturnValue = NULL
 	  	 exec spRS_GetReportParamValue 'EndTime', @ReportId, @ReturnValue output
 	  	 Select @EndTime = convert(datetime, @ReturnValue)
 	  END
 	  ELSE
 	  BEGIN
 	  	  Insert Into #TimeOptions 
          exec spRS_GetTimeOptions @TimeOption,@TargetTimeZone
          Select @StartTime = Start_Time, @EndTime = End_Time From #TimeOptions
 	  END
 Drop Table #TimeOptions
SELECT @StartTime= [dbo].[fnServer_CmnConvertToDbTime] (@StartTime,@TargetTimeZone)--Ramesh
SELECT @EndTime= [dbo].[fnServer_CmnConvertToDbTime] (@EndTime,@TargetTimeZone)--Ramesh
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'EventType', @ReportId, @ReturnValue output
Select @EventType = convert(int,@ReturnValue)
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'EventSubType', @ReportId, @ReturnValue output
Select @EventSubType = convert(int,@ReturnValue)
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'MaximumColumns', @ReportId, @ReturnValue output
Select @MaxVariableCount = convert(int,@ReturnValue)
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'IgnoreNoData', @ReportId, @ReturnValue output
Select @IgnoreNoData = convert(int,@ReturnValue)
Select @TargetTimeZone = NULL
exec spRS_GetReportParamValue 'TargetTimeZone', @ReportId, @TargetTimeZone output
--**********************************************
-- Check For Required Parameters And Set Defaults
--**********************************************
If @ReportName Is Null 
  Select @ReportName = dbo.fnRS_TranslateString_New(@LangId, 36187, 'Event History Color')
If @Unit Is Null
  Begin
    exec spRS_AddEngineActivity @ReportName, 0, 'Required [Unit] Parameter Is Missing', 2, @ReportId, @RunId
    Raiserror('Required [Unit] Parameter Is Missing',16,1)
    return
  End
If @Variables Is Null
  Begin
    exec spRS_AddEngineActivity @ReportName, 0, 'Required [Variables] Parameter Is Missing', 2, @ReportId, @RunId
    Raiserror('Required [Variables] Parameter Is Missing',16,1)
    return
  End
If @StartTime Is Null
  Begin
    exec spRS_AddEngineActivity @ReportName, 0, 'Required [StartTime] Parameter Is Missing', 2, @ReportId, @RunId
    Raiserror('Required [StartTime] Parameter Is Missing',1,1)
    return
  End
If @EndTime Is Null
  Begin
    exec spRS_AddEngineActivity @ReportName, 0, 'Required [EndTime] Parameter Is Missing', 2, @ReportId, @RunId
    Raiserror('Required [EndTime] Parameter Is Missing',1,1)
    return
  End
If @EventType is Null 
  Select @EventType = 1
If @MaxVariableCount Is Null
  Select @MaxVariableCount = 25
If @IgnoreNoData Is Null
  Select @IgnoreNoData = 0
--**********************************************
-- Look Up Event Information
--**********************************************
If @EventType = 11
 	 Begin
    -- alarms
    Select @EventName = var_desc from variables where var_id = @EventSubType
    Select @EventName = @EventName + ' Alarm'
 	 End
Else If @EventType = 14
 	 Begin
    -- user defined events
 	  	 Select @EventName = event_subtype_desc, @UDEType = duration_required From Event_Subtypes Where event_subtype_id = @EventSubtype
 	 End
Else
 	 Begin
    -- all other types of events
    Select @EventName = ET_Desc From Event_Types Where ET_Id = @EventType
 	 End
--**********************************************
-- Return Header Information
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
Insert into #Prompts (PromptName, PromptValue) Values ('ReportName', @ReportName)
Insert into #Prompts (PromptName, PromptValue) Values ('GenerateTime', convert(varchar(25), dbo.fnServer_CmnConvertFromDbTime(dbo.fnServer_CmnGetDate(getutcdate()),@TargetTimeZone),120))
Insert into #Prompts (PromptName, PromptValue) Values ('EventName', @EventName)
 Update #Prompts Set PromptValue=
 	 Case 
 	  	 When PromptValue = 'Production Event'         Then dbo.fnRS_TranslateString_New(@LangId,36321,'Production Event')
 	  	 When PromptValue = 'Downtime Event'           Then dbo.fnRS_TranslateString_New(@LangId,36322,'Downtime Event')
 	  	 When PromptValue = 'Waste Event'              Then dbo.fnRS_TranslateString_New(@LangId,36323,'Waste Event')
 	  	 When PromptValue = 'Product Change Event'     Then dbo.fnRS_TranslateString_New(@LangId,36324,'Product Change Event')
 	  	 When PromptValue = 'Alarm Event'              Then dbo.fnRS_TranslateString_New(@LangId,36325,'Alarm Event')
 	  	 When PromptValue = 'Process Order Event'      Then dbo.fnRS_TranslateString_New(@LangId,36326,'Process Order Event')
 	  	 When PromptValue = 'User Defined Event'       Then dbo.fnRS_TranslateString_New(@LangId,36327,'User Defined Event')
 	 End
Select @CriteriaString = (Select PromptValue From #Prompts Where PromptName = 'EventName') + ' '+  dbo.fnRS_TranslateString_New(@LangId,36188,'History For Unit')+ ': ' + (Select PU_Desc From Prod_Units Where PU_Id = @Unit)
Select @CriteriaString = @CriteriaString + 
 	 Case 
 	  	 When @NonProductiveTimeFilter=0 Then '<br><i>' + @NPTLabel + ' ' + dbo.fnRS_TranslateString_New(@LangId,36026,'Contains') + ' ' + dbo.fnRS_TranslateString_New(@LangId,35132,'Non-Productive Time') + '</i>' Else '<br><i>' + dbo.fnRS_TranslateString_New(@LangId,35193,'Non-Productive Time Removed') + '</i>' 
 	 End
Insert into #Prompts (PromptName, PromptValue) Values ('Criteria', @CriteriaString)
Insert into #Prompts (PromptName, PromptValue) Values ('GenerateTime', dbo.fnRS_TranslateString_New(@LangId, 36178, 'Created') + ': ' + convert(varchar(25), dbo.fnServer_CmnGetDate(getutcdate()),120))
Insert into #Prompts (PromptName, PromptValue) Values ('Comment',dbo.fnRS_TranslateString_New(@LangId, 36179, 'Comment') )
Insert into #Prompts (PromptName, PromptValue) Values ('StartTime', convert(varchar(30), dbo.fnServer_CmnConvertFromDBTime(@StartTime,@TargetTimeZone), 120))
Insert into #Prompts (PromptName, PromptValue) Values ('EndTime', convert(varchar(30), dbo.fnServer_CmnConvertFromDBTime(@EndTime,@TargetTimeZone), 120))
Insert into #Prompts (PromptName, PromptValue) Values ('Variable',dbo.fnRS_TranslateString_New(@LangId, 36163, 'Variable'))
Insert into #Prompts (PromptName, PromptValue) Values ('Limits',dbo.fnRS_TranslateString_New(@LangId, 36180, 'Limits'))
Insert into #Prompts (PromptName, PromptValue) Values ('Time',dbo.fnRS_TranslateString_New(@LangId, 36181, 'Time'))
Insert into #Prompts (PromptName, PromptValue) Values ('Target',dbo.fnRS_TranslateString_New(@LangId, 36144, 'Target'))
Insert into #Prompts (PromptName, PromptValue) Values ('Warning',dbo.fnRS_TranslateString_New(@LangId, 36170, 'Warning'))
Insert into #Prompts (PromptName, PromptValue) Values ('Reject',dbo.fnRS_TranslateString_New(@LangId, 36093, 'Reject'))
Insert into #Prompts (PromptName, PromptValue) Values ('DisplayESignature', @DisplayESignature)
Insert into #Prompts (PromptName,PromptValue) Values('NumberOfPoints',@NumberOfPoints)
Insert into #Prompts (PromptName,PromptValue) Values('TargetTimeZone',@TargetTimeZone)
select * From #Prompts
Drop Table #Prompts
--**********************************************
-- Return Data For Report
--**********************************************
Create Table #Events (
 	 EventLabel varchar(200) NULL,
 	 EventColor int NULL,
 	 StartTime datetime NULL, 
 	 Timestamp datetime,
 	 RunId int,
 	 ProductId int, 
 	 CommentId int NULL,
 	 Hyperlink varchar(255) NULL,
 	 Actual_Start_Time datetime,
 	 Productive_Start_Time datetime,
 	 Productive_End_Time datetime,
 	 Non_Productive_Seconds float,
 	 Perform_User_Id int,
 	 Verify_User_Id int,
 	 Perform_Username varchar(30),
 	 Verify_Username varchar(30)
)
Create Table #Variables (
  ItemOrder int,
  Item int,
  DataTypeId int,
  NumberOfDigits int NULL
)
If @EventType <> 14 -- Alarms
  Select @SQL = 'Select Distinct Var_Id, ItemOrder = CharIndex(convert(varchar(10),Var_Id),' + '''' + @Variables + ''''+ ',1), Data_Type_Id,Var_Precision  From Variables Where Var_Id in (' + @Variables + ')' + ' and data_type_id in (1,2,6,7) and Event_Type = ' + convert(varchar(10), @EventType) + ' and pu_id <> 0'
Else
  Select @SQL = 'Select Distinct Var_Id, ItemOrder = CharIndex(convert(varchar(10),Var_Id),' + '''' + @Variables + ''''+ ',1), Data_Type_Id,Var_Precision  From Variables Where Var_Id in (' + @Variables + ')' + ' and data_type_id in (1,2,6,7) and pu_id <> 0'
Insert Into #Variables (Item, ItemOrder, DataTypeId,NumberOfDigits)
  execute (@SQL)
--**********************************************
-- Get All The Events We Care About
--**********************************************
 	 
If @EventType = 1 
  Begin
    -- Production Events
    Insert Into #Events (EventLabel, EventColor, StartTime, Timestamp, RunId, ProductId, CommentId, Hyperlink, Perform_User_Id, Verify_User_Id)
 	  	 Select EventLabel = e.event_num + ' (' + s.ProdStatus_Desc + ')'
 	  	  	  	 + Case When e.Non_Productive_Seconds > 0 then @NPTLabel Else '' End, 
 	  	  	 Case  
               When s.Status_Valid_For_Input <> 1 Then 2
               When s.Count_For_Production <> 1 Then 1
               Else 0
            End, 
 	  	  	 e.Start_Time, 
 	  	  	 e.Timestamp, 
 	        Case When e.Applied_Product Is Null Then ps.Start_id Else e.Applied_Product End,
 	        Case When e.Applied_Product Is Null Then ps.Prod_Id Else e.Applied_Product End,
 	        e.Comment_Id,
 	        Hyperlink = 'EventDetail.aspx?Id=' + convert(varchar(20),e.Event_Id) + '&TargetTimeZone=' + @TargetTimeZone,
 	  	    es.Perform_User_Id, es.Verify_User_Id
 	   From Events_NPT e
 	   Join Production_Starts ps on ps.PU_id = @Unit 
 	  	 and ps.Start_Time <= e.Timestamp 
 	  	 and ((ps.End_Time > e.Timestamp) or (ps.End_Time Is Null))
 	   Join Production_Status s on s.ProdStatus_id = e.Event_Status
      Left Join ESignature es on es.Signature_Id = e.Signature_Id
 	   Where e.PU_id = @Unit 
 	  	 and e.Timestamp > @StartTime 
 	  	 and e.Timestamp <= @EndTime 
 	  	 and (@NonProductiveTimeFilter = 0 or e.Non_Productive_Seconds = 0) 
 	   -- Changed
  End
Else If @EventType = 2 
  Begin
    -- Downtime Events
    Insert Into #Events (EventLabel, EventColor, StartTime, Timestamp, RunId, ProductId, CommentId, Hyperlink, Perform_User_Id, Verify_User_Id)
 	  	 Select EventLabel = coalesce(r1.event_reason_name,'<Unspecified>')  
 	  	  	  	 + coalesce(',' + r2.event_reason_name,'') 
 	  	  	  	 + coalesce(' (' + tef.tefault_name + ') - ',' - ') 
 	  	  	  	 + convert(varchar(20),convert(decimal(10,2), datediff(second,d.start_time, d.end_time) / 60.0))
 	  	  	     + Case When d.Non_Productive_Seconds > 0 then @NPTLabel Else '' End, 
             Case when d.reason_level1 Is Null Then 2 Else 0 End, 
 	  	  	 d.start_time, 
 	  	  	 d.end_time, 
 	  	  	 ps.Start_id, 
 	  	  	 ps.Prod_Id, 
 	  	  	 NULL,
 	  	  	 Hyperlink = 'DowntimeDetail.aspx?Id=' + convert(varchar(20),d.tedet_Id) + '&TargetTimeZone=' + @TargetTimeZone, 
 	  	     es.Perform_User_Id, es.Verify_User_Id
 	  	 From Timed_Event_Details_NPT d
        Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.reason_level1
        Left Outer Join Event_Reasons r2 on r2.event_reason_id = d.reason_level2
        Left Outer Join Timed_Event_Fault tef on tef.tefault_id = d.tefault_id
 	  	 Join Production_Starts ps on ps.PU_id = @Unit and 
 	                                ps.Start_Time <= d.End_Time and 
 	                               ((ps.End_Time > d.End_Time) or (ps.End_Time Is Null))
 	  	 Left Join ESignature es on es.Signature_Id = d.Signature_Id
 	  	 Where d.PU_id = @Unit and
 	         d.End_Time > @StartTime and 
 	         d.End_Time <= @EndTime 
 	  	  	 and (@NonProductiveTimeFilter = 0 or d.Non_Productive_Seconds = 0) 
 	  	 -- Changed
  End
Else If @EventType = 3
  Begin
    -- Waste Events
    -- Data will be stored by timestamp - regardless of event based versus time based...
    Insert Into #Events (EventLabel, EventColor, StartTime, Timestamp, RunId, ProductId, CommentId, Hyperlink, Perform_User_Id, Verify_User_Id)
 	  	 Select EventLabel = coalesce(r1.event_reason_name,'<Unspecified>')  
 	  	  	  	 + coalesce(',' + r2.event_reason_name,'') 
 	  	  	  	 + coalesce(' (' + coalesce(e.event_Num,wef.wefault_name) + ') - ',' - ') 
 	  	  	  	 + convert(varchar(20),convert(decimal(10,2), d.Amount))
                + Case When d.Is_Non_Productive > 0 then @NPTLabel Else '' End, 
            Case when d.reason_level1 Is Null Then 2 Else 0 End, 
 	  	  	 null, 
 	  	  	 d.timestamp, 
 	  	  	 ps.Start_id, 
 	  	  	 ps.Prod_Id, 
 	  	  	 NULL,
 	  	  	 Hyperlink = 'WasteDetail.aspx?Id=' + convert(varchar(20),d.wed_Id) + '&TargetTimeZone=' + @TargetTimeZone, 
 	  	  	 es.Perform_User_Id, es.Verify_User_Id
 	  	 From Waste_Event_Details_NPT d
        Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.reason_level1
        Left Outer Join Event_Reasons r2 on r2.event_reason_id = d.reason_level2
        Left Outer Join Events e on e.event_id = d.event_id
        Left Outer Join Waste_Event_Fault wef on wef.wefault_id = d.wefault_id
 	  	 Join Production_Starts ps on ps.PU_id = @Unit 
 	  	  	 and ps.Start_Time <= d.Timestamp 
 	  	  	 and ((ps.End_Time > d.Timestamp) or (ps.End_Time Is Null))
 	  	 Left Join ESignature es on es.Signature_Id = d.Signature_Id
 	  	 Where d.PU_id = @Unit 
 	  	  	 and d.Timestamp > @StartTime 
 	  	  	 and d.Timestamp <= @EndTime 
 	  	  	 and (@NonProductiveTimeFilter = 0 or d.Is_Non_Productive = 0) 
 	  	 -- Changed
  End
Else If @EventType = 4 
  Begin
    -- Product Change Events
    Insert Into #Events (EventLabel, EventColor, StartTime, Timestamp, RunId, ProductId, CommentId, Hyperlink, Perform_User_Id, Verify_User_Id)
 	  	 Select EventLabel = p.Prod_Code 
 	  	  	  	 + Case When ps.Non_Productive_Seconds > 0 then @NPTLabel Else '' End,  	 
 	  	  	 0, 
 	  	  	 ps.Start_Time, dateadd(second, -1, ps.End_Time), 
 	  	  	 ps.Start_id, 
 	  	  	 ps.Prod_Id, 
 	  	  	 ps.Comment_Id,
 	  	  	 Hyperlink = '', es.Perform_User_Id, es.Verify_User_Id
 	  	  	  	 --Hyperlink = 'ProductChangeDetail.aspx?Id=' + convert(varchar(20),ps.Start_Id) 
 	  	 From Production_Starts_NPT ps
 	  	 Join Products p on p.prod_id = ps.prod_id
 	  	 Left Join ESignature es on es.Signature_Id = ps.Signature_Id
 	  	 Where ps.PU_id = @Unit 
 	  	  	 and ps.End_Time > @StartTime 
 	  	  	 and ps.End_Time <= @EndTime 
            and (@NonProductiveTimeFilter = 0 or ps.Non_Productive_Seconds = 0) 
 	 -- Changed
  End
Else If @EventType = 5
  Begin
    -- Product Change / Time Events
    -- This "Event" Is Implemented In "Time" Version Of This Report
    Return
  End
Else If @EventType = 11
  Begin
    -- Alarm Events - Need Subtype
 	 Insert Into #Events (EventLabel, EventColor, StartTime, Timestamp, RunId, ProductId, CommentId, Hyperlink, Perform_User_Id, Verify_User_Id)
   	  	 Select EventLabel = d.alarm_desc
 	  	  	  	  	 + Case When d.Non_Productive_Seconds > 0 then @NPTLabel Else '' End, 
 	  	  	 EventColor = Case when d.ack Is Null or d.ack = 0 Then 2 Else 0 End,
 	  	  	 StartTime = NULL,
 	  	  	 Timestamp = d.End_Time,
   	  	   	 ps.Start_id, 
 	  	  	 ps.Prod_Id, 
 	  	  	 ps.Comment_Id,
 	         Hyperlink = 'AlarmDetail.aspx?Id=' + convert(varchar(20),d.Alarm_Id)+ '&TargetTimeZone=' + @TargetTimeZone, 
 	  	  	 es.Perform_User_Id, es.Verify_User_Id
 	  	 From Alarms_NPT d
 	  	 Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.cause1
 	  	 Left Outer Join Comments c On c.Comment_id = d.Cause_Comment_Id
   	  	 Join Production_Starts ps on ps.PU_id = @Unit 
 	  	  	 and ps.Start_Time <= d.end_time 
 	  	  	 and ((ps.End_Time > d.end_time) or (ps.End_Time Is Null))
 	  	 Left Join ESignature es on es.Signature_Id = d.Signature_Id
 	  	 Where d.Key_Id = @EventSubType 
 	  	  	 and d.Alarm_Type_Id in (1,2) 
 	  	  	 and d.End_Time > @StartTime 
 	  	  	 and d.End_Time <= @EndTime 
 	  	     and (@NonProductiveTimeFilter = 0 or d.Non_Productive_Seconds = 0) 
 	  	 -- Changed
  End
Else If @EventType = 14
  Begin
    -- UDE Events - Need Subtype
 	  	 If @UDEType = 1 
 	  	  	 Begin
 	  	  	  	 -- Both Start and End Times Apply
     	  	 Insert Into #Events (EventLabel, EventColor, StartTime, Timestamp, RunId, ProductId, CommentId, Hyperlink, Perform_User_Id, Verify_User_Id)
 	  	    	  	 Select EventLabel = coalesce(r1.event_reason_name,'<Unspecified>')  
 	  	  	  	  	  	 + coalesce(',' + r2.event_reason_name,'') + ' - ' 
 	  	  	  	  	  	 + convert(varchar(20),convert(decimal(10,2), datediff(second,d.start_time, d.end_time) / 60.0))
 	  	  	  	  	  	 + Case When d.Non_Productive_Seconds > 0 then @NPTLabel Else '' End, 
 	  	             EventColor = Case when d.cause1 Is Null or d.ack = 0 Then 2 Else 0 End,
 	  	             StartTime = NULL,
 	  	             Timestamp = d.end_time,
 	        	  	   	 ps.Start_id, 
 	  	  	  	  	 ps.Prod_Id, 
 	  	  	  	  	 ps.Comment_Id,
 	  	  	  	     Hyperlink = 'UserDefinedEventDetail.aspx?Id=' + convert(varchar(20),d.UDE_Id)+ '&TargetTimeZone=' + @TargetTimeZone, 
 	  	  	  	  	 es.Perform_User_Id, es.Verify_User_Id
 	  	  	  	 From User_Defined_Events_NPT d
 	  	    	  	 Join Production_Starts ps on ps.PU_id = @Unit 
 	  	  	  	  	 and ps.Start_Time <= d.end_time 
 	  	  	  	  	 and ((ps.End_Time > d.end_time) or (ps.End_Time Is Null))
 	  	  	  	 Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.cause1
 	  	  	  	 Left Outer Join Event_Reasons r2 on r1.event_reason_id = d.cause2
 	  	  	  	 Left Outer Join Comments c On c.Comment_id = d.Cause_Comment_Id
 	  	  	  	 Left Join ESignature es on es.Signature_Id = d.Signature_Id
 	  	  	  	 Where d.PU_Id = @Unit 
 	  	  	  	  	 and d.Event_Subtype_id = @EventSubtype 
 	  	  	  	  	 and d.End_Time >  @StartTime 
 	  	  	  	  	 and d.End_Time <= @EndTime 
 	  	  	  	  	 and (@NonProductiveTimeFilter = 0 or d.Non_Productive_Seconds = 0) 
 	  	  	 -- Changed
      End
 	  	 Else
 	  	  	 Begin
 	  	  	  	 -- Only Start Time Applies
 	  	      	  	 Insert Into #Events (EventLabel, EventColor, StartTime, Timestamp, RunId, ProductId, CommentId, Hyperlink, Perform_User_Id, Verify_User_Id)
 	  	  	  	    	  	 Select EventLabel = coalesce(r1.event_reason_name,'<Unspecified>')  
 	  	  	  	  	  	  	  	 + coalesce(',' + r2.event_reason_name,'')
 	  	  	  	  	  	  	  	 + Case When d.Non_Productive_Seconds > 0 then @NPTLabel Else '' End, 
 	  	  	  	             EventColor = Case when d.cause1 Is Null or d.ack = 0 Then 2 Else 0 End,
 	  	  	  	             StartTime = NULL,
 	  	  	  	             Timestamp = d.start_time,
 	  	  	        	  	   	 ps.Start_id, 
 	  	  	  	  	  	  	 ps.Prod_Id, 
 	  	  	  	  	  	  	 ps.Comment_Id,
 	  	  	  	  	  	     Hyperlink = 'UserDefinedEventDetail.aspx?Id=' + convert(varchar(20),d.UDE_Id) + '&TargetTimeZone=' + @TargetTimeZone, 
 	  	  	  	  	  	  	 es.Perform_User_Id, es.Verify_User_Id
 	  	  	  	  	  	 From User_Defined_Events_NPT d
 	  	  	  	    	  	 Join Production_Starts ps on ps.PU_id = @Unit 
 	  	  	  	  	  	  	 and ps.Start_Time <= d.start_time 
 	  	  	  	  	  	  	 and ((ps.End_Time > d.start_time) or (ps.End_Time Is Null))
 	  	  	  	  	  	 Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.cause1
 	  	  	  	  	  	 Left Outer Join Event_Reasons r2 on r1.event_reason_id = d.cause2
 	  	  	  	  	  	 Left Outer Join Comments c On c.Comment_id = d.Cause_Comment_Id
 	  	  	  	  	  	 Left Join ESignature es on es.Signature_Id = d.Signature_Id
 	  	  	  	  	  	 Where d.PU_Id = @Unit 
 	  	  	  	  	  	  	 and d.Event_Subtype_id = @EventSubtype 
 	  	  	  	  	  	  	 and d.start_Time >  @StartTime 
 	  	  	  	  	  	  	 and d.start_Time <= @EndTime 
 	  	  	  	  	  	  	 and (@NonProductiveTimeFilter = 0 or d.Non_Productive_Seconds = 0) 
 	  	  	  	  	 -- Changed
 	  	  	 End
  End
-- NO E-SIGNATURE HERE
Else If @EventType = 19
  Begin
    Insert Into #Events (EventLabel, EventColor, StartTime, Timestamp, RunId, ProductId, CommentId, Hyperlink)
 	  	 Select EventLabel = pp.Process_Order + '(' +  s.pp_status_desc + ')' 
 	  	  	  	  	 + Case When ps.Non_Productive_Seconds > 0 then @NPTLabel Else '' End, 
 	  	  	 0, 
 	  	  	 ps.Start_Time, 
 	  	  	 ps.End_Time, 
 	  	  	 ps.pp_id, 
 	  	  	 pp.Prod_Id, 
 	  	  	 ps.Comment_Id,
 	  	  	 Hyperlink = 'ProcessOrderDetail.aspx?Id=' + convert(varchar(20),ps.pp_Id) + '&TargetTimeZone=' + @TargetTimeZone
 	  	 From Production_Plan_Starts_NPT ps
        Join Production_Plan pp on pp.pp_id = ps.pp_id
        Join production_plan_statuses s on s.pp_status_id = pp.pp_status_id
        Where ps.PU_id = @Unit 
 	  	  	 and ps.End_Time > @StartTime 
 	  	  	 and ps.End_Time <= @EndTime 
 	  	  	 and (@NonProductiveTimeFilter = 0 or ps.Non_Productive_Seconds = 0) 
 	 -- Changed
  End
Else If @EventType = 22
  Begin
    -- Uptime
    Insert Into #Events (EventLabel, EventColor, StartTime, Timestamp, RunId, ProductId, CommentId, Hyperlink, Perform_User_Id, Verify_User_Id)
 	  	 Select EventLabel = coalesce(r1.event_reason_name,'<Unspecified>')  
 	  	  	  	 + coalesce(',' + r2.event_reason_name,'') 
 	  	  	  	 + coalesce(' (' + tef.tefault_name + ')','')
 	  	  	     + Case When d.Non_Productive_Seconds > 0 then @NPTLabel Else '' End, 
 	  	  	 Case when d.reason_level1 Is Null Then 2 Else 0 End, d.Start_Time, d.end_time, 
 	  	  	 ps.Start_id, 
 	  	  	 ps.Prod_Id, 
 	  	  	 NULL,
 	  	  	 Hyperlink = 'DowntimeDetail.aspx?Id=' + convert(varchar(20),d.tedet_Id), ES.Perform_User_Id, ES.Verify_User_Id
 	  	 From Timed_Event_Details_NPT d
 	  	 Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.reason_level1
 	  	 Left Outer Join Event_Reasons r2 on r2.event_reason_id = d.reason_level2
 	  	 Left Outer Join Timed_Event_Fault tef on tef.tefault_id = d.tefault_id
 	  	 Join Production_Starts ps on ps.PU_id = @Unit 
 	  	  	 and ps.Start_Time <= d.End_Time 
 	  	  	 and ((ps.End_Time > d.End_Time) or (ps.End_Time Is Null))
 	  	 Left Join ESignature es on es.Signature_Id = d.Signature_Id
 	  	 Where d.PU_id = @Unit 
 	  	  	 and d.Start_Time >  @StartTime 
 	  	  	 and d.Start_Time <= @EndTime 
 	  	  	 and (@NonProductiveTimeFilter = 0 or d.Non_Productive_Seconds = 0) 
 	 -- Changed
    -- Purge "Chained Events" (ie With No Uptime)
    Create Table #BadTimes (
      StartTime datetime
    )
    Insert Into #BadTimes
      Select StartTime
      From #Events e1      
      Where (Select Count(e2.Timestamp) 
               From #Events e2 
               Where e2.Timestamp = e1.StartTime
             ) > 0
    Delete From #Events
      Where StartTime In (Select StartTime From #BadTimes)
    Drop Table #BadTimes  
    Update #Events Set TimeStamp = StartTime, StartTime = NULL
  End
-----------------------------
-- Update Signoff Users
-----------------------------
--Print 'Adding default user signoff values'
--Update #Events Set Perform_User_Id = 53, Verify_User_Id = 59
/*
Update O 
     Set Perform_Username = Username
     From Users u
     Join #Events O on O.perform_User_Id = U.User_Id
Update O 
     Set Verify_Username = Username
     From Users u
     Join #Events O on O.verify_user_Id = U.User_Id
Update #Events Set Perform_Username = 'None' where Perform_Username Is Null
Print convert(varchar(5), @@RowCount) + ' Perform_Username rows updated'
Update #Events Set Verify_Username = 'None' where Verify_Username Is Null
Print convert(varchar(5), @@RowCount) + ' Verify_Username rows updated'
*/
-- Purge Products We Don't Want
If ltrim(rtrim(@Products)) = '0' 
  Select @Products = NULL 
If @Products Is Not Null and Len(@Products) > 0 
  Execute ('Delete From #Events Where ProductId Not In (' + @Products + ')')
--**********************************************
-- Start Going After The Data A Product At A Time
--**********************************************
Declare @VariableCount int
Declare @NumberOfVariables int
Declare @MinTime datetime
Declare @MaxTime datetime
Declare @ColumnName varchar(25)
Declare @VariableString varchar(25)
Declare @ProductString varchar(25)
Declare @Target varchar(25)
Declare @LWL varchar(25)
Declare @LRL varchar(25)
Declare @UWL varchar(25)
Declare @URL varchar(25)
Declare @@ProductId int
Declare @@VariableId int
Declare @@DataTypeId int
Select @NumberOfVariables = count(Item) From #Variables
If @NumberOfVariables = 0 
  Return
Select @VariableCount = -1
Declare Product_Cursor Insensitive Cursor 
  For (Select Distinct ProductId From #Events)
  For Read Only
Open Product_Cursor
Fetch Next From Product_Cursor Into @@ProductId
While @@Fetch_Status = 0
  Begin
    Declare Variable_Cursor Insensitive Cursor 
      For Select Item, DataTypeId,NumberOfDigits From #Variables Order By ItemOrder
      For Read Only
    Open Variable_Cursor
    Fetch Next From Variable_Cursor Into @@VariableId, @@DataTypeId, @@NumberOfDigits
    While @@Fetch_Status = 0
      Begin
        If @VariableCount = -1
          Begin
           Create Table #Report (
              EventLabel varchar(200) NULL,
              EventColor int NULL,
              Timestamp datetime,
              RunId int,
              ProductId int, 
              CommentId int NULL,
              Hyperlink varchar(255) NULL,
 	  	  	   Perform_User_Id int,
 	  	  	   Verify_User_Id int,
 	  	  	   Perform_Username varchar(30),
 	  	  	   Verify_Username varchar(30)
            )
            Create Table #Header (
              Attribute varchar(25)
            )
 	     -- Extra Rows Added To Separate Data
 	  	  	 Insert Into #Header (Attribute) Values ('Precision')
            Insert Into #Header (Attribute) Values ('Units')
            Insert Into #Header (Attribute) Values ('Description')
            Insert Into #Header (Attribute) Values ('LReject')
            Insert Into #Header (Attribute) Values ('LWarning')
            Insert Into #Header (Attribute) Values ('Target')
            Insert Into #Header (Attribute) Values ('UWarning')
            Insert Into #Header (Attribute) Values ('UReject')
            -- Fill In Report Events
            Insert Into #Report (EventLabel, EventColor, Timestamp, RunId, ProductId, CommentId, Hyperlink, Perform_User_Id, Verify_User_Id)
              Select EventLabel, EventColor, Timestamp, RunId, ProductId, CommentId, Hyperlink, Perform_User_Id, Verify_User_Id From #Events Where ProductId = @@ProductId
            -- Get Min and Max Times
            Select @MinTime = min(timestamp),
                   @MaxTime = max(timestamp)  
              From #Report
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
 	  	  	 Print convert(varchar(5), @@RowCount) + ' Perform_Username rows updated'
 	  	  	 Update #Report Set Verify_Username = '-' where Verify_Username Is Null
 	  	  	 Print convert(varchar(5), @@RowCount) + ' Verify_Username rows updated'
          End      
        If @VariableCount = -1 
          Select @VariableCount = 1
        Else
          Select @VariableCount = @VariableCount + 1        
        Select @ColumnName = '_' + convert(varchar(25),@@VariableId)
        Select @VariableString = convert(varchar(25),@@VariableId)
        Select @ProductString = convert(varchar(25),@@ProductId)
        -- Create Column In Header Table And Column(s) In Report Table
        Select @SQL = 'Alter Table #Header Add ' + @ColumnName + ' varchar(50) NULL'
        Execute (@SQL)
        Select @SQL = 'Alter Table #Report Add ' + @ColumnName + '_InSpec int NULL'
        Execute (@SQL)
        Select @SQL = 'Alter Table #Report Add ' + @ColumnName + '_Comment varchar(200) NULL'
        Execute (@SQL)
        -- Fill In Header Data Based On Min Time
        Select @SQL = 'Update #Header Set ' + @ColumnName + ' = ' + coalesce(convert(varchar(10), @@NumberOfDigits),'0')  + ' Where Attribute = ' + '''' + 'Precision' + ''''
        Execute (@SQL)
        Select @SQL = 'Update #Header Set ' + @ColumnName + ' = (Select Var_Desc From Variables Where Var_Id = ' + @VariableString + ') Where Attribute = ' + '''' + 'Description' + ''''
        Execute (@SQL)
        Select @SQL = 'Update #Header Set ' + @ColumnName + ' = (Select Eng_Units From Variables Where Var_Id = ' + @VariableString + ') Where Attribute = ' + '''' + 'Units' + ''''
        Execute (@SQL)
        Select @Target = NULL
        Select @LWL = NULL
        Select @LRL = NULL
        Select @UWL = NULL
        Select @URL = NULL
        Select @Target = Target, @LWL = l_Warning, @LRL = L_Reject, @UWL = u_warning, @URL = u_reject
          From var_specs
          Where var_id = @@VariableId and
                prod_id = @@ProductId and
                effective_date <= @MinTime and
                ((expiration_date > @MinTime) or (expiration_date is null))
 	 -- Update Lower Reject 
        Select @SQL = 'Update #Header Set ' + @ColumnName + ' = ' +  @LRL  + ' Where Attribute = ' + '''' + 'LReject' + ''''
        Execute (@SQL)
 	 -- Update Lower Warning
        Select @SQL = 'Update #Header Set ' + @ColumnName + ' = ' + @LWL + ' Where Attribute = ' + '''' + 'LWarning' + ''''
        Execute (@SQL)
 	 --Update Target Value
        Select @SQL = 'Update #Header Set ' + @ColumnName + ' = ' + @Target + ' Where Attribute = ' + '''' + 'Target' + ''''
        Execute (@SQL)
 	 -- Update Upper Warning
        Select @SQL = 'Update #Header Set ' + @ColumnName + ' = ' + @UWL + ' Where Attribute = ' + '''' + 'UWarning' + ''''
        Execute (@SQL)
 	 -- Update Upper Reject 
        Select @SQL = 'Update #Header Set ' + @ColumnName + ' = ' + @URL + ' Where Attribute = ' + '''' + 'UReject' + ''''
        Execute (@SQL)
        -- Fill In Report Data (Value, InSpec, Comment) Based On Min/Max Time
        Select @SQL = 'Update #Report Set '
        If (@@DataTypeId = 1 or @@DataTypeId = 2 or @@DataTypeId = 6 or @@DataTypeId = 7) and @SpecificationSetting = 1
          Select @SQL = @SQL + @ColumnName + '_InSpec = Case 
                     When convert(real, t.result) > convert(real,coalesce(vs.u_reject,t.result)) Then 2 
                     When convert(real, t.result) < convert(real,coalesce(vs.l_reject,t.result)) Then -2 
                     When convert(real, t.result) > convert(real,coalesce(vs.u_warning,t.result)) Then 1 
                     When convert(real, t.result) < convert(real,coalesce(vs.l_warning,t.result)) Then -1 
                     Else 0 End, ' 
        Else If (@@DataTypeId = 1 or @@DataTypeId = 2 or @@DataTypeId = 6 or @@DataTypeId = 7) and @SpecificationSetting = 2
          Select @SQL = @SQL + @ColumnName + '_InSpec = Case 
                     When convert(real, t.result) >= convert(real,coalesce(vs.u_reject,convert(real, t.result)-1)) Then 2 
                     When convert(real, t.result) <= convert(real,coalesce(vs.l_reject,convert(real, t.result)+1)) Then -2 
                     When convert(real, t.result) >= convert(real,coalesce(vs.u_warning,convert(real, t.result)-1)) Then 1 
                     When convert(real, t.result) <= convert(real,coalesce(vs.l_warning,convert(real, t.result)+1)) Then -1 
                     Else 0 End, ' 
        Else
          Select @SQL = @SQL + @ColumnName + '_InSpec = Case 
                     When t.result = coalesce(vs.u_reject,' + '''' + 'vs.u_reject' + '''' + ') Then 2 
                     When t.result = coalesce(vs.l_reject,' + '''' + 'vs.l_reject' + '''' + ') Then -2 
                     When t.result = coalesce(vs.u_warning,' + '''' + 'vs.u_warning' + '''' + ') Then 1 
                     When t.result = coalesce(vs.l_warning,' + '''' + 'vs.l_warning' + '''' + ') Then -1 
                     Else 0 End, ' 
        Select @SQL = @SQL + @ColumnName + '_Comment = c.Comment_Text From #Report r ' 
        Select @SQL = @SQL + 'Join Tests t on t.Var_id = ' + @VariableString + ' and t.Result_On = r.Timestamp and t.Result_On Between ' + '''' + convert(varchar(30),@MinTime,109) + '''' + ' and ' + '''' + convert(varchar(30),@MaxTime,109) + '''' + ' '  
        Select @SQL = @SQL + 'Left Outer Join Var_Specs vs on vs.Var_Id = ' + @VariableString + ' and vs.Prod_Id = ' + @ProductString + ' and vs.effective_date <= r.Timestamp and ((vs.expiration_date > r.Timestamp) or (vs.expiration_date Is Null)) ' 
        Select @SQL = @SQL + 'Left Outer Join Comments c on c.Comment_Id = t.Comment_Id' 
        Execute (@SQL)
        If @@Rowcount = 0 
          Begin
  	  	  	 If @IgnoreNoData <> 0 
              Begin
 	  	         Select @SQL = 'Alter Table #Header Drop Column ' + @ColumnName 
 	  	         Execute (@SQL)
 	  	 
 	  	         Select @SQL = 'Alter Table #Report Drop Column ' + @ColumnName + '_InSpec'
 	  	         Execute (@SQL)
 	  	 
 	  	         Select @SQL = 'Alter Table #Report Drop Column ' + @ColumnName + '_Comment'
 	  	         Execute (@SQL)                
 	  	  	  	 Select @VariableCount = @VariableCount - 1        
              End
          End
        Fetch Next From Variable_Cursor Into @@VariableId, @@DataTypeId, @@NumberOfDigits
        If @VariableCount = @MaxVariableCount or @@Fetch_Status <> 0
          Begin
            Select Product = p.Prod_Code, Description = Case p.Prod_Desc  When 'no product' Then dbo.fnRS_TranslateString_New(@LangId,35288,'No Product') Else p.Prod_Desc End, Comment = c.Comment_Text
              From Products p 
              Left Outer Join Comments c on c.Comment_id = p.Comment_id
              Where p.Prod_id = @@ProductId
 	  	  	 Select * into #Report2  from #Report 
 	  	  	 execute ('alter table #Report2 Drop Column Perform_User_Id') 
 	  	  	 execute ('alter table #Report2 Drop Column Verify_User_Id')
 	  	  	 
            Select * From #Header
 	  	  	 update #Report2 Set Timestamp = [dbo].[fnServer_CmnConvertFromDbTime] ([Timestamp],@TargetTimeZone)  
 	  	  	 Select * from #Report2
            --Select * From #Report
              Order By Timestamp DESC
            Drop Table #Header
            Drop Table #Report
 	  	  	 Drop Table #Report2
            Select @VariableCount = -1
          End
      End     
    Close Variable_Cursor
    Deallocate Variable_Cursor  
    Fetch Next From Product_Cursor Into @@ProductId
  End
Close Product_Cursor
Deallocate Product_Cursor  
Drop Table #Events
Drop Table #Variables
--/**************************************************************************
