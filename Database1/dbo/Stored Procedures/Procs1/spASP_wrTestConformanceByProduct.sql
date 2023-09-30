CREATE procedure [dbo].[spASP_wrTestConformanceByProduct]
@ReportId int,
@RunId int = NULL
AS
/*
set nocount on
Declare @ReportId int, @RunId int
Select @reportId=709
*/
--TODO: What About Retests?
Declare @ReportName varchar(255)
Declare @CriteriaString varchar(1000)
Declare @Unit int
Declare @Variables varchar(7000)
Declare @Products varchar(7000)
Declare @StartTime datetime  
Declare @EndTime datetime  
Declare @TargetTimeZone varchar(200)
Select @TargetTimeZone=NULL
  	 EXEC spRS_GetReportParamValue 'TargetTimeZone',@ReportId,@TargetTimeZone output
Declare @NonProductiveTimeFilter int
Declare @NPTLabel varchar(255)
Declare @NPTLabelDefault varchar(255)
select @NPTLabelDefault = '(npt)'
if (Select Count(*) from Site_Parameters where parm_id = 316) = 0
  Select @NPTLabel=@NPTLabelDefault
Else
  select @NPTLabel = Coalesce(case Value when '' then @NPTLabelDefault else value end, @NPTLabelDefault) from Site_Parameters where parm_Id = 316
--/**********************************************
-- Loookup Parameters For This Report Id
--**********************************************
Declare @ReturnValue varchar(7000)
Declare @LocaleId int, @LangId int
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
exec spRS_GetReportParamValue 'Products', @ReportId, @Products output
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
  Select @ReportName = dbo.fnRS_TranslateString_New(@LangId, 36145, 'Test Conformance By Product')
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
If @Products Is Null
  Begin
    exec spRS_AddEngineActivity @ReportName, 0, 'Required [Products] Parameter Is Missing', 2, @ReportId, @RunId
    Raiserror('Required [Products] Parameter Is Missing',16,1)
    return
  End
If @Products = '0'
  Begin
    exec spRS_AddEngineActivity @ReportName, 0, 'A Specific Set Of Products Must Be Selected', 2, @ReportId, @RunId
    Raiserror('A Specific Set Of Products Must Be Selected',16,1)
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
Select @CriteriaString = dbo.fnRS_TranslateString_New(@LangId, 36229, 'Testing Conformance For Selected Variables') 
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
Declare @@ProductId int
Create Table #Products (
  ItemOrder int,
  Item int
)
Insert Into #Products (Item, ItemOrder)
  execute ('Select Prod_Id, ItemOrder = CharIndex(convert(varchar(10),Prod_Id),' + '''' + @Products + ''''+ ',1)  From Products Where Prod_Id in (' + @Products + ')')
Create Table #Variables (
  ItemOrder int,
  Item int
)
Insert Into #Variables (Item, ItemOrder)
  execute ('Select Var_Id, ItemOrder = CharIndex(convert(varchar(10),Var_Id),' + '''' + @Variables + ''''+ ',1)  From Variables Where Var_Id in (' + @Variables + ')')
Create Table #RawTests (
  ItemOrder int,
  VariableId int,
  ProductId int,
  Scheduled tinyint,
  Tested tinyint,
  IS_NPT int
)
-- Get All the Tests
Insert Into #RawTests
  Select ItemOrder = v.ItemOrder,
         VariableId = t.Var_id,
         ProductId = ps.Prod_id,
         Scheduled = 1,
         Tested = Case when t.result is null then 0 else 1 end,
 	  	  t.Is_Non_Productive
    From Tests_NPT t
 	  	 Join #variables v on v.Item = t.var_id
 	  	 Join production_starts ps on ps.pu_id = @Unit 
 	  	  	 and ps.start_time <= t.result_on 
 	  	  	 and ((ps.end_time > t.result_on) or (ps.end_time is null))
 	  	 Join #Products p on p.Item = ps.prod_id
    Where t.result_on > @StartTime 
 	  	 and t.result_on <= @EndTime
 	  	 and (@NonProductiveTimeFilter = 0 or t.Is_Non_Productive = 0) 
--Changed
--Print 'Select * from #RawTests'
--Select * from #RawTests
-- Return The Total Grid
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
Select Product = 'Total', Description = dbo.fnRS_TranslateString_New(@LangId, 35280, 'Totals'), Comment = NULL
Select Variable = Case 
 	  	  	 When ItemOrder > 0 
 	  	  	 Then v.Var_Desc  + Case When IS_NPT > 0 Then @NPTLabel Else '' End
 	  	  	 Else 'Total' 
 	  	 End,
       Scheduled = r.Scheduled,
       Tested = r.Tested,
       Conformance = Case When r.Scheduled > 0 Then convert(decimal(10,2), convert(real, r.Tested) / convert(real,r.Scheduled)) * 100 else 100.0 End
   From #Totals r
   Join variables v on v.var_id = r.VariableId
   Order by ItemOrder ASC 
Drop Table #Totals
-----------------------------------------------------
-- Loop Through Products
-----------------------------------------------------
Declare Product_Cursor Insensitive Cursor 
  For Select Item From #Products Order By ItemOrder
  For Read Only
Open Product_Cursor
Fetch Next From Product_Cursor Into @@ProductId
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
        Where ProductId = @@ProductId
 	     Group By VariableId
 	        
 	 Insert Into #Report(ItemOrder, VariableId, Scheduled, Tested)
 	   Select ItemOrder = 0,
 	          VariableId = 0,
 	          Scheduled = sum(Scheduled),
 	          Tested = sum(Tested)
 	     From #Report 	  	 
 	 Select Product = Prod_Code, Description = Prod_Desc, Comment = NULL
 	  	 From Products 
 	  	 where Prod_Id = @@ProductId      
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
 	 
 	 Fetch Next From Product_Cursor Into @@ProductId
  End
Close Product_Cursor
Deallocate Product_Cursor  
Drop Table #RawTests
Drop Table #Products
Drop Table #Variables
