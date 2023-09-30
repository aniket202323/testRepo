CREATE procedure [dbo].[spASP_wrTimeHistoryColor]
@ReportId int,
@RunId int = NULL
AS
--**********/
/************
set nocount on
Declare @ReportId int, @Runid int
Select @reportId=110
--*********/
set arithignore on
set arithabort off
set ansi_warnings off
Declare @SpecificationSetting int  -- For Specification Comparisons
Select @SpecificationSetting = convert(int,value) From Site_Parameters Where Parm_id = 13
If @SpecificationSetting is Null Select @SpecificationSetting = 1
Declare @ReportName varchar(255)
Declare @CriteriaString varchar(1000)
Declare @Unit int
Declare @SheetId int
Declare @StartTime datetime
Declare @EndTime datetime
Declare @Products varchar(4000)
Declare @MaxVariableCount int
Declare @IgnoreNoData int 
Declare @FirstVariable int
Declare @DisplayESignature int
Declare @NonProductiveTimeFilter int
Declare @NPTLabel varchar(255)
Declare @NPTLabelDefault varchar(255)
select @NPTLabelDefault = '(npt)'
if (Select Count(*) from Site_Parameters where parm_id = 316) = 0
  Select @NPTLabel=@NPTLabelDefault
Else
  select @NPTLabel = Coalesce(case Value when '' then @NPTLabelDefault else value end, @NPTLabelDefault) from Site_Parameters where parm_Id = 316
/*********************************************
-- For Testing
--*********************************************
Select @SheetId = 33
Select @StartTime = '1-may-01'
Select @EndTime = '10-jun-03'
Select @Products = null
--**********************************************/
Declare @SQL varchar(3000)
--/**********************************************
-- Loookup Parameters For This Report Id
--**********************************************
Declare @ReturnValue varchar(7000)
declare @LocaleId int, @LangId int
declare @TargetTimeZone varchar(200)
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
exec spRS_GetReportParamValue 'Display', @ReportId, @ReturnValue output
Select @SheetId = convert(int, @ReturnValue)
exec spRS_GetReportParamValue 'Products', @ReportId, @Products output
Select @TargetTimeZone = NULL 
exec spRS_GetReportParamValue 'TargetTimeZone', @ReportId,@TargetTimeZone output
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
exec spRS_GetReportParamValue 'MaximumColumns', @ReportId, @ReturnValue output
Select @MaxVariableCount = convert(int,@ReturnValue)
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'IgnoreNoData', @ReportId, @ReturnValue output
Select @IgnoreNoData = convert(int,@ReturnValue)
--**********************************************/
--**********************************************
-- Check For Required Parameters And Set Defaults
--**********************************************
If @ReportName Is Null 
  Select @ReportName = dbo.fnRS_TranslateString_New(@LangId, 36150, 'Time History Color') 
If @SheetId Is Null
  Begin
    exec spRS_AddEngineActivity @ReportName, 0, 'Required [Display] Parameter Is Missing', 2, @ReportId, @RunId
    Raiserror('Required [Display] Parameter Is Missing',16,1)
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
If @MaxVariableCount Is Null
  Select @MaxVariableCount = 25
If @IgnoreNoData Is Null
  Select @IgnoreNoData = 0
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
Select @CriteriaString = dbo.fnRS_TranslateString_New(@LangId, 36175, 'Time History For') + ' ' + (select Sheet_Desc From Sheets Where Sheet_Id = @SheetId)
Select @CriteriaString = @CriteriaString + 
 	 Case 
 	  	 When @NonProductiveTimeFilter=0 Then '<br><i>' + @NPTLabel + ' ' + dbo.fnRS_TranslateString_New(@LangId, 36026, 'Contains') + ' ' + dbo.fnRS_TranslateString_New(@LangId, 42120, 'Non-Productive Time') + '</i>' Else '<br><i>' + dbo.fnRS_TranslateString_New(@LangId, 35193, 'Non-Productive Time Removed') + '</i>' 
 	 End
Insert into #Prompts (PromptName, PromptValue) Values ('Criteria', @CriteriaString)
  	 Insert into #Prompts (PromptName, PromptValue) Values ('GenerateTime', dbo.fnRS_TranslateString_New(@LangId, 36178, 'Created') + ': ' + convert(varchar(25), dbo.fnServer_CmnConvertFromDbTime(dbo.fnServer_CmnGetDate(getutcdate()),@TargetTimeZone),120))
Insert into #Prompts (PromptName, PromptValue) Values ('Comment', dbo.fnRS_TranslateString_New(@LangId, 36179, 'Comment'))
Insert into #Prompts (PromptName, PromptValue) Values ('StartTime', convert(varchar(30), dbo.fnServer_CmnConvertFromDBTime(@StartTime,@TargetTimeZone), 120))
Insert into #Prompts (PromptName, PromptValue) Values ('EndTime', convert(varchar(30),dbo.fnServer_CmnConvertFromDBTime(@EndTime,@TargetTimeZone), 120))
Insert into #Prompts (PromptName, PromptValue) Values ('Variable', dbo.fnRS_TranslateString_New(@LangId, 36163, 'Variable'))
Insert into #Prompts (PromptName, PromptValue) Values ('Limits', dbo.fnRS_TranslateString_New(@LangId, 36180, 'Limits'))
Insert into #Prompts (PromptName, PromptValue) Values ('Time', dbo.fnRS_TranslateString_New(@LangId, 36181, 'Time'))
Insert into #Prompts (PromptName, PromptValue) Values ('Target', dbo.fnRS_TranslateString_New(@LangId, 36144, 'Target'))
Insert into #Prompts (PromptName, PromptValue) Values ('Warning', dbo.fnRS_TranslateString_New(@LangId, 36170, 'Warning'))
Insert into #Prompts (PromptName, PromptValue) Values ('Reject', dbo.fnRS_TranslateString_New(@LangId, 36093, 'Reject'))
Insert into #Prompts (PromptName, PromptValue) Values ('DisplayESignature', @DisplayESignature)
Insert into #Prompts (PromptName, PromptValue) Values ('TargetTimeZone',@TargetTimeZone)
select * From #Prompts
Drop Table #Prompts
--**********************************************
-- Return Data For Report
--**********************************************
Create Table #Events (
 	 Timestamp datetime,
 	 RunId int,
 	 ProductId int, 
 	 CommentId int NULL,
 	 Perform_User_Id int,
 	 Verify_User_Id int,
 	 Perform_Username varchar(30),
 	 Verify_Username varchar(30)
)
Create Table #Variables (
  ItemOrder int,
  Item int,
  DataTypeId int,
  PU_ID int
)
Insert Into #Variables (Item, ItemOrder, DataTypeId, PU_ID)
  Select sv.Var_Id, sv.Var_Order, v.Data_Type_id, PU_ID
    From sheet_variables sv 
    Join variables v on v.var_id = sv.var_id
    Where sv.sheet_id = @SheetId and
          sv.var_id is not null 
 	  	 and v.data_type_id in (1,2,6,7)
-- Get The Master Unit Based On The Sheet, Or The First Variable
Select @Unit = NULL
Select @Unit = Master_Unit 
  From Sheets 
  Where Sheet_Id = @SheetId
If @Unit is Null
  Begin
    Select @FirstVariable = min(ItemOrder) From #Variables
    Select @FirstVariable = Item From #Variables Where ItemOrder = @FirstVariable
    Select @Unit = Coalesce(master_unit, pu_id) 
      From Prod_Units
      Where PU_Id = (Select PU_Id From Variables Where Var_Id = @FirstVariable)
  End
--**********************************************
-- Get All The Times We Care About
--**********************************************
Insert Into #Events (Timestamp, RunId, ProductId, CommentId, Perform_User_Id, Verify_User_Id)
 	 Select sc.Result_On,
 	  	 ps.Start_id,
 	  	 ps.Prod_Id, 
 	  	 sc.Comment_Id,
 	  	 es.Perform_User_Id, es.Verify_User_Id
    From Sheet_Columns sc 
    Join Production_Starts ps on ps.PU_id = @Unit 
 	  	 and ps.Start_Time <= sc.Result_On 
 	  	 and ((ps.End_Time > sc.Result_On) or (ps.End_Time Is Null))
 	 Left Join ESignature es on es.Signature_Id = sc.Signature_Id
    Where sc.Sheet_Id = @SheetId and
 	  	 sc.Result_On > @StartTime and 
 	  	 sc.Result_On <= @EndTime 
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
Declare @PU_ID int
Select @NumberOfVariables = count(Item) From #Variables
If @NumberOfVariables = 0 
  Return
Select @VariableCount = -1
----------------------------------
-- PRODUCT CURSER (OUTER)
----------------------------------
Declare Product_Cursor Insensitive Cursor 
  For (Select Distinct ProductId From #Events)
  For Read Only
Open Product_Cursor
Fetch Next From Product_Cursor Into @@ProductId
While @@Fetch_Status = 0
  Begin
    ----------------------------------
    -- VARIABLE CURSER (INNER)
    ----------------------------------
    Declare Variable_Cursor Insensitive Cursor 
      For Select Item, DataTypeId, PU_ID From #Variables Order By ItemOrder
      For Read Only
    Open Variable_Cursor
    Fetch Next From Variable_Cursor Into @@VariableId, @@DataTypeId, @PU_ID
    While @@Fetch_Status = 0
      Begin
        If @VariableCount = -1
          Begin
 	  	  	 -- Create Header Table
            Create Table #Header (
              Attribute varchar(25)
            )
            Insert Into #Header (Attribute) Values ('Units')
            Insert Into #Header (Attribute) Values ('Description')
            Insert Into #Header (Attribute) Values ('LReject')
            Insert Into #Header (Attribute) Values ('LWarning')
            Insert Into #Header (Attribute) Values ('Target')
            Insert Into #Header (Attribute) Values ('UWarning')
            Insert Into #Header (Attribute) Values ('UReject')
 	  	  	 -- Create Report Table
           Create Table #Report (
              --Timestamp datetime,
 	  	  	   Timestamp varchar(30),
              RunId int,
              ProductId int, 
              CommentId int NULL,
 	  	  	   IS_NPT int,
 	  	  	   Perform_User_Id int,
 	  	  	   Verify_User_Id int,
 	  	  	   Perform_Username varchar(30),
 	  	  	   Verify_Username varchar(30)
            )
           -- Fill In Report Events
            Insert Into #Report (Timestamp, RunId, ProductId, CommentId, IS_NPT, Perform_User_Id, Verify_User_Id)
 	  	  	  	 Select convert(varchar(25), Timestamp, 120), RunId, ProductId, CommentId, dbo.fnWA_IsNonProductiveTime(@PU_ID, e.Timestamp, NULL), Perform_User_Id, Verify_User_Id 
 	  	  	  	 From #Events e
 	  	  	  	 Where ProductId = @@ProductId
 	  	  	  	  	 and (@NonProductiveTimeFilter = 0 or (dbo.fnWA_IsNonProductiveTime(@PU_ID, e.Timestamp, NULL) = 0))
            -- Get Min and Max Times
            Select @MinTime = min(timestamp),
                   @MaxTime = max(timestamp)  
              From #Report
 	  	  	 -----------------------------
 	  	  	 -- Update Signoff Users
 	  	  	 -----------------------------
 	  	  	 --Update #Report Set Perform_User_Id=1, Verify_User_Id=1
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
        Fetch Next From Variable_Cursor Into @@VariableId, @@DataTypeId, @PU_ID
        If @VariableCount = @MaxVariableCount or @@Fetch_Status <> 0
          Begin
            Select Product = p.Prod_Code, Description = p.Prod_Desc, Comment = c.Comment_Text
              From Products p 
              Left Outer Join Comments c on c.Comment_id = p.Comment_id
              Where p.Prod_id = @@ProductId
 	  	  	 
 	  	  	 update #Report Set Timestamp = dbo.fnServer_CmnConvertFromDBTime(Timestamp,@TargetTimeZone)
 	  	  	 Update #Report Set Timestamp= Timestamp + @NPTLabelDefault where IS_NPT > 0
 	  	  	 Select * into #Report2 from #Report
 	  	  	 alter table #Report2 drop column IS_NPT
 	  	  	 alter table #Report2 drop column Perform_User_Id
 	  	  	 alter table #Report2 drop column Verify_User_Id
 	  	  	 
 	  	  	 
            Select * From #Header
            Select * From #Report2
              Order By Timestamp DESC
 	  	  	 Drop Table #Report2
            Drop Table #Header
            Drop Table #Report
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
--/**********
