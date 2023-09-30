/*
-- Dan Aug-17-2004
  Changed selection criteria so that joins are inclusive in regards to Start_Time
  Previous changes undone
--Dan Aug-10-2004
Changed Timestamps to be converted to 120
Altered selection criteria:
        Where vs.Prod_Id = @@ProductId and
              vs.Effective_Date < @RelativeTime and
              ((vs.Expiration_Date >= @RelativeTime) or (vs.Expiration_Date Is Null))
See code below
*/
CREATE procedure [dbo].[spASP_wrSpecificationsByVariable]
@ReportId int,
@RunId int = NULL
 AS 
/***********************************************************/
/******** Copyright 2004 GE Fanuc International Inc.********/
/****************** All Rights Reserved ********************/
/***********************************************************/
Declare @ReportName varchar(255)
Declare @CriteriaString varchar(1000)
Declare @Unit int
Declare @Variables varchar(7000)
Declare @Products varchar(7000)
Declare @RelativeTime datetime  
Declare @LocaleId int, @LangId int
Declare @TargetTimeZone varchar(200)
Declare @NumberOfPoints 	 int
Declare @MaxRecords int
Set @MaxRecords = 0
/*********************************************
-- For Testing
--*********************************************
Select @ReportId = 5
Select @Variables = '1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27'
Select @Products = '6,7,5' 
Select @RelativeTime = getdate()
--**********************************************/
--/**********************************************
-- Loookup Parameters For This Report Id
--**********************************************
Declare @ReturnValue varchar(7000)
Select @ReportName = Report_Name From Report_Definitions Where Report_Id = @ReportId
exec spRS_GetReportParamValue 'Variables', @ReportId, @Variables output
exec spRS_GetReportParamValue 'Products', @ReportId, @Products output
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'StartTime', @ReportId, @ReturnValue output
Select @RelativeTime = convert(datetime,@ReturnValue)
SELECT 	 @ReturnValue = NULL
EXEC 	 spRS_GetReportParamValue 'LocaleId', @ReportId, @ReturnValue output
SELECT 	 @LocaleId = CASE @ReturnValue WHEN NULL THEN 0 ELSE abs(convert(INT, @ReturnValue)) END
SELECT @LangId = Language_id From Language_Locale_Conversion Where LocaleId=@LocaleId
If @LangId is Null SET @LangId = 0
SELECT @TargetTimeZone = NULL
  	 EXEC spRS_GetReportParamValue 'TargetTimeZone',@ReportId,@TargetTimeZone output
 	 SELECT @RelativeTime = dbo.fnServer_CmnConvertToDBTime(@RelativeTime,@TargetTimeZone)
SELECT @NumberOfPoints = 0
EXEC spRS_GetReportParamValue 'No_Of_DataPoints',@ReportId,@NumberOfPoints output
 --**********************************************/
--**********************************************
-- Check For Required Parameters And Set Defaults
--**********************************************
If @ReportName Is Null 
  Select @ReportName = dbo.fnRS_TranslateString_New(@LangId, 36227, 'Specifications By Variable'
)
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
If @RelativeTime is Null
  Select @RelativeTime = dbo.fnServer_CmnGetDate(getutcdate())
--**********************************************
-- Return Header Information
--**********************************************
--Declare @MaxRecordCount Table(RecordCount bit)
declare @RecordsExceeded bit
Set @RecordsExceeded = 0
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
Select @CriteriaString = dbo.fnRS_TranslateString_New(@LangId, 36228, 'Specifications For Selected Variables At') + ' [' + convert(varchar(25), dbo.fnServer_CmnConvertFromDBTime(coalesce(@RelativeTime, dbo.fnServer_CmnGetDate(getutcdate())),@TargetTimeZone),120) + ']' 
Insert into #Prompts (PromptName, PromptValue) Values ('Criteria', @CriteriaString)
  	 Insert into #Prompts (PromptName, PromptValue) Values ('GenerateTime', dbo.fnRS_TranslateString_New(@LangId, 36178, 'Created') + ': ' + convert(varchar(25),dbo.fnServer_CmnConvertFromDBTime(dbo.fnServer_CmnGetDate(getutcdate()),@TargetTimeZone),120))
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
Insert into #Prompts (PromptName, PromptValue) Values ('TargetTimeZone',@TargetTimeZone)
Insert into #Prompts(PromptName, PromptValue) Values ('NumberOfPoints',@NumberOfPoints)
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
  execute ('Select Distinct Prod_Id, ItemOrder = CharIndex('',''+ convert(varchar(10),Prod_Id) + '','',' + ''',' + @Products + ','''+ ',1)  From Products Where Prod_Id in (' + @Products + ')')
Create Table #Variables (
  ItemOrder int,
  Item int
)
Insert Into #Variables (Item, ItemOrder)
  execute ('Select Distinct Var_Id, ItemOrder = CharIndex('',''+ convert(varchar(10),Var_Id) + '','',' + ''',' + @Variables + ','''+ ',1)  From Variables Where Var_Id in (' + @Variables + ')')
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
             LRL = vs.l_reject, LWL = vs.l_warning, TGT = vs.Target, UWL = vs.U_Warning, URL = vs.U_Reject, TFY = vs.Test_Freq,  ---Added
             Effective =   dbo.fnServer_CmnConvertFromDBTime(vs.Effective_Date,@TargetTimeZone)  ,
 	  	  	  Expiration =  dbo.fnServer_CmnConvertFromDBTime(vs.Expiration_Date,@TargetTimeZone)  ,
             Comment = c.Comment_Text, Var_Id = v.var_id, Prod_Id = @@ProductId,
  	    	    	   Var_Precision = coalesce(v.Var_Precision, 0)
        From Var_Specs vs
        Join #Variables l on l.Item = vs.var_id
        Join Variables v on v.var_id = vs.var_id
        Join PU_Groups pug on pug.pug_id = v.pug_id
        Left Outer Join Comments c on c.Comment_Id = vs.Comment_Id
        Where vs.Prod_Id = @@ProductId and
 	  	  	  	 vs.Effective_Date <= @RelativeTime and
              ((vs.Expiration_Date > @RelativeTime) or (vs.Expiration_Date Is Null))
        Order by l.ItemOrder
  	     -- Changed
  	     Set @MaxRecords = @MaxRecords + @@ROWCOUNT -- Fix for the bug 36433 
    Fetch Next From Product_Cursor Into @@ProductId
  End
EndProcedure:
Close Product_Cursor
Deallocate Product_Cursor  
-- Fix for the bug 36433 - Variable Conformance & Spec By Variable Reports have bad formatting
-- Returning this boolean value true if the number of records exceeds 500 records.
SELECT @RecordsExceeded as RecordsExceeded
Drop Table #Products
Drop Table #Variables
