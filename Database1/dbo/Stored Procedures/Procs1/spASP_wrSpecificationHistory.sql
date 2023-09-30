Create procedure [dbo].[spASP_wrSpecificationHistory]
@VariableId int,
@ProductId int,
@RelativeTime datetime = NULL,
@ChangesSince datetime = NULL,
@LocaleId int = 1033,
@TargetTimeZone varchar(200) =NULL
AS
--*********************************************/
/**********************************************
set nocount on
Declare @VariableId int, @ProductId int, @RelativeTime datetime, @ChangesSince datetime 
-- sample values
select @VariableId=10, @ProductId=3, @RelativeTime='2001-06-13 23:21:00'
--********************************************/
Declare @ReportName varchar(255)
Declare @CriteriaString varchar(1000)
Declare @VariableName varchar(255)
Declare @ProductCode varchar(50)
Declare @ReportId int
Declare @LangId int
 Declare @RelativeTimeDB datetime
Declare @ChangesSinceDB datetime
 SELECT @LangId = Language_id From Language_Locale_Conversion Where LocaleId=@LocaleId
If @LangId is Null SET @LangId = 0
  	 SELECT @RelativeTimeDB = dbo.fnServer_CmnConvertToDBTime(@RelativeTime,@TargetTimeZone)
 	 SELECT @ChangesSinceDB = dbo.fnServer_CmnConvertToDBTime(@ChangesSince,@TargetTimeZone)
/*********************************************
-- For Testing
--*********************************************
Select @VariableId = 6
Select @ProductId = 5 
Select @RelativeTime = getdate()
Select @ChangesSince = NULL
--**********************************************/
--**********************************************
-- Loookup Parameters For This Report Id
--**********************************************
Select @ReportName = dbo.fnRS_TranslateString_New(@LangId, 36212, 'Specification History')
Select @VariableName = var_desc from Variables Where Var_id = @VariableId
Select @ProductCode = prod_Code From Products Where Prod_id = @ProductId
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
If @ChangesSince Is Null
  Select @CriteriaString = dbo.fnRS_TranslateString_New(@LangId, 36213, 'All Specification Changes') 
Else
  Select @CriteriaString = dbo.fnRS_TranslateString_New(@LangId, 36214, 'Changes Since') + ' : ' + convert(varchar(25), @ChangesSince, 120)
Insert into #Prompts (PromptName, PromptValue) Values ('Criteria', @CriteriaString)
Insert into #Prompts (PromptName, PromptValue) Values ('GenerateTime', dbo.fnRS_TranslateString_New(@LangId, 36178, 'Created') + ': ' + convert(varchar(25), dbo.fnServer_CmnConvertFromDbTime(dbo.fnServer_CmnGetDate(getutcdate()),@TargetTimeZone),120))
Insert into #Prompts (PromptName, PromptValue) Values ('TabTitle', @VariableName + ' ' + dbo.fnRS_TranslateString_New(@LangId, 36215, 'on') + ' ' + @ProductCode)
Insert into #Prompts (PromptName, PromptValue) Values ('TransactionName', dbo.fnRS_TranslateString_New(@LangId, 36216, 'Transaction'))
Insert into #Prompts (PromptName, PromptValue) Values ('ApprovedBy', dbo.fnRS_TranslateString_New(@LangId, 36200, 'Approved By'))
Insert into #Prompts (PromptName, PromptValue) Values ('Target', dbo.fnRS_TranslateString_New(@LangId, 36144, 'Target'))
Insert into #Prompts (PromptName, PromptValue) Values ('LowerReject', dbo.fnRS_TranslateString_New(@LangId, 36217, 'Lower Reject'))
Insert into #Prompts (PromptName, PromptValue) Values ('LowerWarning', dbo.fnRS_TranslateString_New(@LangId, 36218, 'Lower Warning'))
Insert into #Prompts (PromptName, PromptValue) Values ('UpperWarning', dbo.fnRS_TranslateString_New(@LangId, 36219, 'Upper Warning'))
Insert into #Prompts (PromptName, PromptValue) Values ('UpperReject', dbo.fnRS_TranslateString_New(@LangId, 36220, 'Upper Reject'))
Insert into #Prompts (PromptName, PromptValue) Values ('TestFrequency', dbo.fnRS_TranslateString_New(@LangId, 36221, 'Test Frequency'))
Insert into #Prompts (PromptName, PromptValue) Values ('EffectiveDate', dbo.fnRS_TranslateString_New(@LangId, 36222, 'Effective Date'))
Insert into #Prompts (PromptName, PromptValue) Values ('ExpirationDate', dbo.fnRS_TranslateString_New(@LangId, 36223, 'Expiration Date'))
select * From #Prompts
Drop Table #Prompts
--**********************************************
-- Return Data For Report
--**********************************************
If @ChangesSinceDB Is Null
  Select TransactionName = t.trans_desc, ApprovedBy = u.Username, ApprovedOn = t.Approved_On, 
         Target = vs.Target, LowerReject = vs.l_reject, LowerWarning = vs.l_warning, UpperWarning = vs.u_warning, UpperReject = vs.u_reject, 
         TestFrequency = vs.Test_Freq, EffectiveDate = dbo.fnServer_CmnConvertFromDBTime(vs.Effective_Date,@TargetTimeZone), ExpirationDate = dbo.fnServer_CmnConvertFromDBTime(vs.Expiration_Date,@TargetTimeZone), 
         Comment = c.Comment_Text,  
         Highlight = Case When vs.Effective_Date < dateadd(minute, 1, @RelativeTimeDB) and vs.Effective_Date > dateadd(minute, -1, @RelativeTimeDB) then 1 Else 0 End, 
         Id = t.Trans_Id,
 	  	  v.var_Precision
    From Var_Specs vs
 	 Join Variables v on v.var_Id = @VariableId
    Join Transactions t on t.Effective_Date = vs.Effective_Date
    Join users u on u.user_id = t.approved_by
    left outer Join comments c on c.comment_id = t.comment_id  
    Where vs.Var_id = @VariableId and
          vs.Prod_Id = @ProductId 
    Order by vs.Effective_Date ASC
Else
  Select TransactionName = t.trans_desc, ApprovedBy = u.Username, ApprovedOn = t.Approved_On, 
         Target = vs.Target, LowerReject = vs.l_reject, LowerWarning = vs.l_warning, UpperWarning = vs.u_warning, UpperReject = vs.u_reject, 
         TestFrequency = vs.Test_Freq, EffectiveDate = vs.Effective_Date, ExpirationDate = vs.Expiration_Date,   
         Comment = c.Comment_Text,  
         Highlight = 0, Id = t.Trans_Id,
 	  	  v.var_Precision
    From Var_Specs vs
 	 Join Variables v on v.var_Id = @VariableId
    Join Transactions t on t.Effective_Date = vs.Effective_Date  
    Join users u on u.user_id = t.approved_by  
    left outer Join comments c on c.comment_id = t.comment_id  
    Where vs.Var_id = @VariableId and
          vs.Prod_Id = @ProductId and
          vs.effective_date >= @RelativeTimeDB 
    Order by vs.Effective_Date ASC
