CREATE procedure [dbo].[spASP_wrSpecificationsByUnit]
@ReportId int,
@RunId int = NULL
AS
--**************************************************/
/*********************************************
set nocount on
Declare @ReportId int, @RunId int
Select @ReportId = 655
--**********************************************/
Declare @ReportName varchar(255)
Declare @CriteriaString varchar(1000)
Declare @Unit int
Declare @Products varchar(2000)
Declare @RelativeTime datetime  
Declare @LocaleId int, @LangId int
Declare @TargetTimeZone varchar(200)
Declare @NumberOfPoints int
Declare @MaxRecords int
Declare @RecordsExceeded bit
Set @MaxRecords = 0
Set @RecordsExceeded = 0
--/**********************************************
-- Loookup Parameters For This Report Id
--**********************************************
Declare @ReturnValue varchar(7000)
Select @ReportName = Report_Name From Report_Definitions Where Report_Id = @ReportId
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'MasterUnit', @ReportId, @ReturnValue output
Select @Unit = convert(int,@ReturnValue)
exec spRS_GetReportParamValue 'Products', @ReportId, @Products output
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'StartTime', @ReportId, @ReturnValue output
Select @RelativeTime = convert(datetime,@ReturnValue)
SELECT 	 @ReturnValue = NULL
EXEC 	 spRS_GetReportParamValue 'LocaleId', @ReportId, @ReturnValue output
SELECT 	 @LocaleId = CASE @ReturnValue WHEN NULL THEN 0 ELSE abs(convert(INT, @ReturnValue)) END
SELECT @LangId = Language_id From Language_Locale_Conversion Where LocaleId=@LocaleId
If @LangId is Null SET @LangId = 0
Select @TargetTimeZone=NULL
  	 EXEC spRS_GetReportParamValue 'TargetTimeZone',@ReportId,@TargetTimeZone output
 	 SELECT @RelativeTime = dbo.fnServer_CmnConvertToDBTime(@RelativeTime,@TargetTimeZone)
SELECT @NumberOfPoints = 0
EXEC spRS_GetReportParamValue 'No_Of_DataPoints',@ReportId,@NumberOfPoints output
 --**********************************************/
--**********************************************
-- Check For Required Parameters And Set Defaults
--**********************************************
If @ReportName Is Null 
  Select @ReportName = dbo.fnRS_TranslateString_New(@LangId, 36224, 'Specifications By Unit')
If @Unit Is Null
  Begin
    exec spRS_AddEngineActivity @ReportName, 0, 'Required [MasterUnit] Parameter Is Missing', 2, @ReportId, @RunId
    Raiserror('Required [MasterUnit] Parameter Is Missing',16,1)
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
If @RelativeTime is Null
  Select @RelativeTime = dbo.fnServer_CmnGetDate(GETUTCDATE())
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
Select @CriteriaString = dbo.fnRS_TranslateString_New(@LangId, 36225, 'Specifications For Unit') + ': ' + (Select PU_Desc From Prod_Units Where PU_Id = @Unit) + ' ' + dbo.fnRS_TranslateString_New(@LangId, 36226, 'At') + ' [' + convert(varchar(25),dbo.fnServer_CmnConvertFromDBTime(coalesce(@RelativeTime, dbo.fnServer_CmnGetDate(getutcdate())),@TargetTimeZone),120) + ']'
Insert into #Prompts (PromptName, PromptValue) Values ('Criteria', @CriteriaString)
Insert into #Prompts (PromptName, PromptValue) Values ('GenerateTime', dbo.fnRS_TranslateString_New(@LangId, 36178, 'Created') + ': ' + convert(varchar(25), dbo.fnServer_CmnConvertFromDBTime(dbo.fnServer_CmnGetDate(getutcdate()),@TargetTimeZone),120))
Insert into #Prompts (PromptName, PromptValue) Values ('Variable', dbo.fnRS_TranslateString_New(@LangId, 36163, 'Variable'))
Insert into #Prompts (PromptName, PromptValue) Values ('Target', dbo.fnRS_TranslateString_New(@LangId, 36144, 'Target'))
Insert into #Prompts (PromptName, PromptValue) Values ('LowerReject', dbo.fnRS_TranslateString_New(@LangId, 36217, 'Lower Reject'))
Insert into #Prompts (PromptName, PromptValue) Values ('LowerWarning', dbo.fnRS_TranslateString_New(@LangId, 36218, 'Lower Warning'))
Insert into #Prompts (PromptName, PromptValue) Values ('UpperWarning', dbo.fnRS_TranslateString_New(@LangId, 36219, 'Upper Warning'))
Insert into #Prompts (PromptName, PromptValue) Values ('UpperReject', dbo.fnRS_TranslateString_New(@LangId, 36220, 'Upper Reject'))
Insert into #Prompts (PromptName, PromptValue) Values ('TestFrequency', dbo.fnRS_TranslateString_New(@LangId, 36221, 'Test Frequency'))
Insert into #Prompts (PromptName, PromptValue) Values ('EffectiveDate', dbo.fnRS_TranslateString_New(@LangId, 36222, 'Effective Date'))
Insert into #Prompts (PromptName, PromptValue) Values ('ExpirationDate', dbo.fnRS_TranslateString_New(@LangId, 36223, 'Expiration Date'))
Insert into #Prompts (PromptName, PromptValue) Values ('Comment', dbo.fnRS_TranslateString_New(@LangId, 36179, 'Comment'))
Insert into #Prompts (PromptName, PromptValue) Values ('TargetTimeZone', @TargetTimeZone)
Insert into #Prompts (PromptName, PromptValue) Values ('ByUnit', 1)
Insert into #Prompts  (PromptName, PromptValue) Values ('NumberOfPoints', @NumberOfPoints)
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
Declare Product_Cursor Insensitive Cursor 
  For Select Item From #Products Order By ItemOrder
  For Read Only
Open Product_Cursor
Fetch Next From Product_Cursor Into @@ProductId
While @@Fetch_Status = 0
  Begin
    -- Fix for the bug 36433 
 	 If @MaxRecords > 500
  BEGIn
 	 Set @RecordsExceeded = 1
 	 Goto EndProcedure 	 
  END
    Select Product = p.Prod_Code, Description = p.Prod_Desc, Comment = c.Comment_Text
      From Products p
      Left Outer Join Comments c on c.Comment_Id = p.Comment_Id
      Where p.prod_id = @@ProductId  
      Select Area = pug.pug_desc, Variable = v.var_desc, Units = v.eng_units,
             LRL = vs.l_reject, LWL = vs.l_warning, TGT = vs.Target, UWL = vs.U_Warning, URL = vs.U_Reject,
             Effective = dbo.fnServer_CmnConvertFromDBTime(vs.Effective_Date,@TargetTimeZone), Expiration = dbo.fnServer_CmnConvertFromDBTime(vs.Expiration_Date,@TargetTimeZone ),
             Comment = c.Comment_Text, Var_Id = v.var_id, Prod_Id = @@ProductId, 
 	  	  	  Var_Precision = coalesce(v.Var_Precision, 0)
        From Var_Specs vs
        Join Prod_Units pu on pu.pu_id = @Unit or pu.Master_Unit = @Unit
        Join Variables v on v.var_id = vs.var_id and v.pu_id = pu.pu_id
        Join PU_Groups pug on pug.pug_id = v.pug_id
        Left Outer Join Comments c on c.Comment_Id = vs.Comment_Id
        Where vs.Prod_Id = @@ProductId and
              vs.Effective_Date <= @RelativeTime and
              ((vs.Expiration_Date > @RelativeTime) or (vs.Expiration_Date Is Null))
        Order by pug.pug_order, v.pug_order
    -- Changed
    Set @MaxRecords = @MaxRecords + @@ROWCOUNT -- Fix for the bug 36433 
    Fetch Next From Product_Cursor Into @@ProductId
  End
Close Product_Cursor
Deallocate Product_Cursor  
EndProcedure:
-- Fix for the bug 36433 - Variable Conformance & Spec By Variable Reports have bad formatting
-- Returning this boolean value true if the number of records exceeds 500 records.
SELECT @RecordsExceeded as RecordsExceeded
Drop Table #Products
