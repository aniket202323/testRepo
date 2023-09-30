CREATE procedure [dbo].[spASP_wrTestConformanceByShift]
@ReportId int,
@RunId int = NULL
AS
--************************************************************/
/****************
set nocount on
Declare @ReportId int, @RunId int
select @reportid = 828
--*************/
--TODO: What About Retests?
Declare @ReportName varchar(255)
Declare @CriteriaString varchar(1000)
Declare @Unit int
Declare @Variables varchar(7000)
Declare @StartTime datetime  
Declare @EndTime datetime  
Declare @NonProductiveTimeFilter int
Declare @NPTLabel varchar(255)
Declare @NPTLabelDefault varchar(255)
Declare @TargetTimeZone varchar(200)
Select @TargetTimeZone=NULL
  	 EXEC spRS_GetReportParamValue 'TargetTimeZone',@ReportId,@TargetTimeZone output
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
exec spRS_GetReportParamValue 'NonProductiveTimeFilter', @ReportId, @ReturnValue output
Select @NonProductiveTimeFilter = ABS(Coalesce(convert(int,@ReturnValue), 0))
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'MasterUnit', @ReportId, @ReturnValue output
Select @Unit = convert(int,@ReturnValue)
exec spRS_GetReportParamValue 'Variables', @ReportId, @Variables output
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
 	 SELECT @StartTime = dbo.fnServer_CmnConvertToDBTime(@StartTime,@TargetTimeZone)
 	 SELECT @EndTime 	   = dbo.fnServer_CmnConvertToDBTime(@EndTime,@TargetTimeZone)
--**********************************************/
--**********************************************
-- Check For Required Parameters And Set Defaults
--**********************************************
If @ReportName Is Null 
  Select @ReportName = dbo.fnRS_TranslateString_New(@LangId, 36146, 'Test Conformance By Shift')
If @Unit Is Null
  Begin
    exec spRS_AddEngineActivity @ReportName, 0, 'Required [MasterUnit] Parameter Is Missing', 2, @ReportId, @RunId
    Raiserror('Required [MasterUnit] Parameter Is Missing',16,1)
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
    Raiserror('Required [StartTime] Parameter Is Missing',16,1)
    return
  End
If @EndTime Is Null
  Begin
    exec spRS_AddEngineActivity @ReportName, 0, 'Required [EndTime] Parameter Is Missing', 2, @ReportId, @RunId
    Raiserror('Required [EndTime] Parameter Is Missing',16,1)
    return
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
Select @CriteriaString = dbo.fnRS_TranslateString_New(@LangId, 36232, 'Testing Conformance By Crew-Shift') 
Select @CriteriaString = @CriteriaString + 
 	 Case 
 	  	 When @NonProductiveTimeFilter=0 Then '<br><i>' + @NPTLabel + ' ' + dbo.fnRS_TranslateString_New(@LangId, 36026, 'Contains') + ' ' + dbo.fnRS_TranslateString_New(@LangId, 42120, 'Non-Productive Time') + '</i>' Else '<br><i>' + dbo.fnRS_TranslateString_New(@LangId, 35193, 'Non-Productive Time Removed') + '</i>' 
 	 End
Insert into #Prompts (PromptName, PromptValue) Values ('Criteria', @CriteriaString)
Insert into #Prompts (PromptName, PromptValue) Values ('GenerateTime', dbo.fnRS_TranslateString_New(@LangId, 36178, 'Created') + ': ' + convert(varchar(25), dbo.fnServer_CmnConvertFromDbTime(dbo.fnServer_CmnGetDate(getutcdate()),@TargetTimeZone),120))
Insert into #Prompts (PromptName, PromptValue) Values ('Variable', dbo.fnRS_TranslateString_New(@LangId, 36163, 'Variable'))
Insert into #Prompts (PromptName, PromptValue) Values ('Scheduled', dbo.fnRS_TranslateString_New(@LangId, 36230, 'Scheduled'))
Insert into #Prompts (PromptName, PromptValue) Values ('Tested', dbo.fnRS_TranslateString_New(@LangId, 36231, 'Tested'))
Insert into #Prompts (PromptName, PromptValue) Values ('Conformance', dbo.fnRS_TranslateString_New(@LangId, 36195, 'Conformance'))
Insert into #Prompts (PromptName, PromptValue) Values ('ConformanceWarning', '90.0')
Insert into #Prompts (PromptName, PromptValue) Values ('ConformanceReject', '80.0')
Insert into #Prompts (PromptName, PromptValue) Values ('StartTime', Convert(varchar(30),dbo.fnServer_CmnConvertFromDBTime(@StartTime,@TargetTimeZone), 20))
Insert into #Prompts (PromptName, PromptValue) Values ('EndTime', Convert(varchar(30),dbo.fnServer_CmnConvertFromDBTime(@EndTime,@TargetTimeZone), 20))
select * From #Prompts
Drop Table #Prompts
--**********************************************
-- Return Data For Report
--**********************************************
-- 2 Pages Per Product 
-- 1st Page Is Header Information
-- 2nd Page Is Specifications Order By Group
Create Table #Variables (
  ItemOrder int,
  Item int
)
Insert Into #Variables (Item, ItemOrder)
  execute ('Select Var_Id, ItemOrder = CharIndex(convert(varchar(10),Var_Id),' + '''' + @Variables + ''''+ ',1)  From Variables Where Var_Id in (' + @Variables + ')')
Create Table #RawTests (
  ItemOrder int,
  VariableId int,
  Crew varchar(25),
  Shift varchar(25),
  Scheduled tinyint,
  Tested tinyint,
  IS_NPT int
)
-- Get All the Tests
Insert Into #RawTests
  Select ItemOrder = v.ItemOrder,
         VariableId = t.Var_id,
         Crew = cs.Crew_Desc,
         Shift = cs.Shift_Desc,
         Scheduled = 1,
         Tested = Case when t.result is null then 0 else 1 end,
 	  	  t.Is_Non_Productive
    From Tests_NPT t
    Join #variables v on v.Item = t.var_id
    Join Crew_Schedule cs  With(index(Crew_UC_PUStartTime)) on cs.pu_id = @Unit and 
 	  	  	  	  	    cs.Start_Time <= t.result_on and cs.End_Time >= t.result_on and
                       --cs.start_time between dateadd(day,-1,t.result_on) and dateadd(day,1,t.result_on) and
                       cs.start_time <= t.result_on and cs.end_time > t.result_on
    Where t.result_on > @StartTime 
 	  	 and t.result_on <= @EndTime
 	  	 and (@NonProductiveTimeFilter = 0 or t.Is_Non_Productive = 0) 
 	 --Changed        
-------------------------------------------------
-- If there are no shifts or crews configured
-- get raw variable data
-------------------------------------------------
If (Select Count(*) From #RawTests) = 0
  Begin
 	 Insert Into #RawTests
 	   Select ItemOrder = v.ItemOrder,
 	  	  	  VariableId = t.Var_id,
 	  	  	  Crew = dbo.fnRS_TranslateString_New(@LangId,36411,'Unknown Crew'),
 	  	  	  Shift = dbo.fnRS_TranslateString_New(@LangId,36412,'Unknown Shift'),
 	  	  	  Scheduled = 1,
 	  	  	  Tested = Case when t.result is null then 0 else 1 end,
 	  	  	  t.Is_Non_Productive
 	  	 From Tests_NPT t
 	  	 Join #variables v on v.Item = t.var_id
 	  	 Where t.result_on > @StartTime 
 	  	  	 and t.result_on <= @EndTime
 	  	  	 and (@NonProductiveTimeFilter = 0 or t.Is_Non_Productive = 0) 
  End
-------------------------------------------------
-- Return The Total Grid
-------------------------------------------------
Create Table #Totals (
  ItemOrder int,
  VariableId int,
  Scheduled int,
  Tested int,
  IS_NPT int
)    
Insert Into #Totals
  Select ItemOrder = min(ItemOrder),
         VariableId = min(VariableId),
         Scheduled = sum(Scheduled),
         Tested = sum(Tested),
 	  	 IS_NPT = Case When Sum(IS_NPT) > 0 Then 1 else 0 End
    From #RawTests
    Group By VariableId
Insert Into #Totals(ItemOrder, VariableId, Scheduled, Tested)
  Select ItemOrder = 0,
         VariableId = 0,
         Scheduled = sum(Scheduled),
         Tested = sum(Tested)
    From #Totals
Select Description = dbo.fnRS_TranslateString_New(@LangId, 35280, 'Totals')
Select Variable = Case When ItemOrder > 0 Then v.Var_Desc Else 'Total' End,
       Scheduled = r.Scheduled,
       Tested = r.Tested,
       Conformance = Case When r.Scheduled > 0 Then convert(decimal(10,2), convert(real, r.Tested) / convert(real,r.Scheduled)) * 100 else 100.0 End
   From #Totals r
   Join variables v on v.var_id = r.VariableId
   Order by ItemOrder ASC 
Drop Table #Totals
Declare @@SearchItem varchar(25)
Declare Crew_Cursor Insensitive Cursor 
  For Select Distinct Crew From #RawTests Order By Crew
  For Read Only
Open Crew_Cursor
Fetch Next From Crew_Cursor Into @@SearchItem
While @@Fetch_Status = 0
  Begin
    Create Table #Report (
      ItemOrder int,
      VariableId int,
      Scheduled int,
      Tested int,
 	   IS_NPT int
    )    
 	  	 Insert Into #Report
 	  	   Select ItemOrder = min(ItemOrder),
 	  	          VariableId = min(VariableId),
 	  	          Scheduled = sum(Scheduled),
 	  	          Tested = sum(Tested),
 	  	  	  	  IS_NPT = Case When Sum(IS_NPT) > 0 Then 1 Else 0 End
 	  	     From #RawTests
        Where Crew = @@SearchItem
 	  	     Group By VariableId
 	  	        
 	  	 Insert Into #Report(ItemOrder, VariableId, Scheduled, Tested)
 	  	   Select ItemOrder = 0,
 	  	          VariableId = 0,
 	  	          Scheduled = sum(Scheduled),
 	  	          Tested = sum(Tested)
 	  	     From #Report 	  	 
    Select Description = dbo.fnRS_TranslateString_New(@LangId, 16039,'Crew:')+ ' ' + @@SearchItem
    Select Variable = 
 	  	  	 Case 
 	  	  	  	 When ItemOrder > 0 Then v.Var_Desc + Case When IS_NPT > 0 Then @NPTLabel Else '' End
 	  	  	  	 Else 'Total' 
 	  	  	 End,
           Scheduled = r.Scheduled,
           Tested = r.Tested,
           Conformance = Case When r.Scheduled > 0 Then convert(decimal(10,2), convert(real, r.Tested) / convert(real,r.Scheduled)) * 100 else 100.0 End
       From #Report r
    	  	  Join variables v on v.var_id = r.VariableId
       Order by ItemOrder ASC
    Drop Table #Report
    Fetch Next From Crew_Cursor Into @@SearchItem
  End
Close Crew_Cursor
Deallocate Crew_Cursor  
Declare Shift_Cursor Insensitive Cursor 
  For Select Distinct Shift From #RawTests Order By Shift
  For Read Only
Open Shift_Cursor
Fetch Next From Shift_Cursor Into @@SearchItem
While @@Fetch_Status = 0
  Begin
    Create Table #Report2 (
      ItemOrder int,
      VariableId int,
      Scheduled int,
      Tested int,
      IS_NPT int
    )    
 	  	 Insert Into #Report2
 	  	   Select ItemOrder = min(ItemOrder),
 	  	          VariableId = min(VariableId),
 	  	          Scheduled = sum(Scheduled),
 	  	          Tested = sum(Tested),
                 IS_NPT = Case When Sum(IS_NPT) > 0 Then 1 Else 0 End
 	  	     From #RawTests
        Where Shift = @@SearchItem
 	  	     Group By VariableId
 	  	        
 	  	 Insert Into #Report2(ItemOrder, VariableId, Scheduled, Tested)
 	  	   Select ItemOrder = 0,
 	  	          VariableId = 0,
 	  	          Scheduled = sum(Scheduled),
 	  	          Tested = sum(Tested)
 	  	     From #Report2 	  	 
    Select Description = dbo.fnRS_TranslateString_New(@LangId, 16040,'Shift:')+ ' ' + @@SearchItem
    Select Variable = 
 	  	  	  	 Case 
 	  	  	  	  	 When ItemOrder > 0 Then v.Var_Desc + Case When IS_NPT > 0 Then @NPTLabel Else '' End 
 	  	  	  	  	 Else 'Total' 
 	  	  	  	 End,
           Scheduled = r.Scheduled,
           Tested = r.Tested,
           Conformance = Case When r.Scheduled > 0 Then convert(decimal(10,2), convert(real, r.Tested) / convert(real,r.Scheduled)) * 100 else 100.0 End
       From #Report2 r
    	  	  Join variables v on v.var_id = r.VariableId
       Order by ItemOrder ASC
    Drop Table #Report2
    Fetch Next From Shift_Cursor Into @@SearchItem
  End
Close Shift_Cursor
Deallocate Shift_Cursor  
Drop Table #RawTests
Drop Table #Variables
