Create Procedure [dbo].[spASP_wrTransactionDetail]
@TransactionId int,
@ReportId int = 0
AS
--TODO: Add prompts for later resultset columns
--TODO: Determine Who the language of the client user.
--      Other report stored procedures pass the report id in as a parameter
--      but this report is not used this way
/*********************************************
-- For Testing
--*********************************************
DECLARE @TransactionId int
Select @TransactionId = 36
SET NOCOUNT ON
--**********************************************/
Declare @ReportName varchar(255)
Declare @CriteriaString varchar(1000)
Declare @CreateDate datetime
Declare @EffectiveDate datetime
Declare @ApprovedDate datetime
Declare @ApprovedUser varchar(100)
Declare @TransactionDescription varchar(255)
Declare @TransactionGroup varchar(100)
Declare @CorporateDescription varchar(255)
Declare @CorporateServer varchar(100)
Declare @TargetTimeZone varchar(200)
declare @LocaleId int, @LangId int
Declare @ReturnValue int
Declare @QueryDate datetime
If @TransactionId Is Null
  Begin
    Raiserror('Command Did Not Find Transaction To Return',16,1)
    Return
  End
SELECT 	 @ReturnValue = NULL
EXEC 	 spRS_GetReportParamValue 'LocaleId', @ReportId, @ReturnValue output
SELECT 	 @LocaleId = CASE @ReturnValue WHEN NULL THEN 0 ELSE abs(convert(INT, @ReturnValue)) END
SELECT @LangId = Language_id From Language_Locale_Conversion Where LocaleId=@LocaleId
If @LangId is Null SET @LangId = 0
SELECT @TargetTimeZone = NULL
exec spRS_GetReportParamValue 'TargetTimeZone', @ReportId,@TargetTimeZone output 
-- Get Tranaction Information
Select @CreateDate = trans_create_date, 
 	  	  	  @EffectiveDate = effective_date,
 	  	  	  @ApprovedDate = approved_on,
 	  	  	  @ApprovedUser = u1.username,
 	  	  	  @TransactionDescription = trans_desc,
 	  	  	  @TransactionGroup = tg.transaction_grp_desc,
 	  	  	  @CorporateDescription = corp_trans_desc,
 	  	  	  @CorporateServer = s.linked_server_desc
  From Transactions t
  left outer Join users u1 on u1.user_id = t.approved_by
  left outer join transaction_groups tg on tg.transaction_grp_id = t.transaction_grp_id
  left outer join linkable_remote_servers s on s.linked_server_id = t.linked_server_id
  Where Trans_Id = @TransactionId
If @EffectiveDate Is Null
  Select @QueryDate = getdate()
Else
  Select @QueryDate = dateadd(second,-30,@EffectiveDate)
Select @ReportName = dbo.fnRS_TranslateString_New(@LangId, 36233, 'Transaction Detail')
Select @CriteriaString = @TransactionDescription
--**********************************************
-- Return Header Information
--**********************************************
-- Line1: Report Name
-- Line2: Criteria
-- Line3: Generate Time
-- Line4 - n: Column Names
Create Table #Prompts (
  PromptId int identity(1,1),
  PromptName varchar(30),
  PromptValue varchar(1000)
)
Insert into #Prompts (PromptName, PromptValue) Values ('ReportName', @ReportName)
Insert into #Prompts (PromptName, PromptValue) Values ('Criteria', @CriteriaString)
Insert into #Prompts (PromptName, PromptValue) Values ('GenerateTime', dbo.fnRS_TranslateString_New(@LangId, 36178, 'Created') + ': ' + convert(varchar(17), dbo.fnServer_CmnGetDate(getutcdate()),109))
Insert into #Prompts (PromptName, PromptValue) Values ('General', dbo.fnRS_TranslateString_New(@LangId, 36234, 'General'))
Insert into #Prompts (PromptName, PromptValue) Values ('Approval', dbo.fnRS_TranslateString_New(@LangId, 36235, 'Approval'))
Insert into #Prompts (PromptName, PromptValue) Values ('CorporateSpecifications', dbo.fnRS_TranslateString_New(@LangId, 36236, 'Corporate Specifications'))
Insert into #Prompts (PromptName, PromptValue) Values ('ProductionCapability', dbo.fnRS_TranslateString_New(@LangId, 36237, 'Production Capability'))
Insert into #Prompts (PromptName, PromptValue) Values ('ProductionCharacteristics', dbo.fnRS_TranslateString_New(@LangId, 36238, 'Production Characteristics'))
Insert into #Prompts (PromptName, PromptValue) Values ('PlantSpecifications', dbo.fnRS_TranslateString_New(@LangId, 36239, 'Plant Level Specifications'))
Insert into #Prompts (PromptName, PromptValue) Values ('VariableSpecifications', dbo.fnRS_TranslateString_New(@LangId, 36240, 'Variable Level Specifications'))
Insert into #Prompts (PromptName, PromptValue) Values ('Operation', dbo.fnRS_TranslateString_New(@LangId, 36075, 'Operation'))
Insert into #Prompts (PromptName, PromptValue) Values ('Product', dbo.fnRS_TranslateString_New(@LangId, 36085, 'Product'))
Insert into #Prompts (PromptName, PromptValue) Values ('Line', dbo.fnRS_TranslateString_New(@LangId, 36241, 'Line'))
Insert into #Prompts (PromptName, PromptValue) Values ('Unit', dbo.fnRS_TranslateString_New(@LangId, 36196, 'Unit'))
Insert into #Prompts (PromptName, PromptValue) Values ('Variable', dbo.fnRS_TranslateString_New(@LangId, 36163, 'Variable'))
Insert into #Prompts (PromptName, PromptValue) Values ('Property', dbo.fnRS_TranslateString_New(@LangId, 36242, 'Property'))
Insert into #Prompts (PromptName, PromptValue) Values ('Characteristic', dbo.fnRS_TranslateString_New(@LangId, 36243, 'Characteristic'))
Insert into #Prompts (PromptName, PromptValue) Values ('TGT', dbo.fnRS_TranslateString_New(@LangId, 36144, 'Target'))
Insert into #Prompts (PromptName, PromptValue) Values ('LEL', dbo.fnRS_TranslateString_New(@LangId, 36244, 'Lower Entry'))
Insert into #Prompts (PromptName, PromptValue) Values ('LRL', dbo.fnRS_TranslateString_New(@LangId, 36217, 'Lower Reject'))
Insert into #Prompts (PromptName, PromptValue) Values ('LWL', dbo.fnRS_TranslateString_New(@LangId, 36218, 'Lower Warning'))
Insert into #Prompts (PromptName, PromptValue) Values ('LUL', dbo.fnRS_TranslateString_New(@LangId, 36245, 'Lower User'))
Insert into #Prompts (PromptName, PromptValue) Values ('UUL', dbo.fnRS_TranslateString_New(@LangId, 36246, 'Upper User'))
Insert into #Prompts (PromptName, PromptValue) Values ('UWL', dbo.fnRS_TranslateString_New(@LangId, 36219, 'Upper Warning'))
Insert into #Prompts (PromptName, PromptValue) Values ('URL', dbo.fnRS_TranslateString_New(@LangId, 36220, 'Upper Reject'))
Insert into #Prompts (PromptName, PromptValue) Values ('UEL', dbo.fnRS_TranslateString_New(@LangId, 36247, 'Upper Entry'))
Insert into #Prompts (PromptName, PromptValue) Values ('TF', dbo.fnRS_TranslateString_New(@LangId, 36221, 'Test Frequency'))
Insert into #Prompts (PromptName, PromptValue) Values ('TransactionId', convert(varchar(15), @TransactionId))
Insert into #Prompts (PromptName,PromptValue)  Values('Created',dbo.fnRS_TranslateString_New(@LangId, 36178, 'Created On'))
Insert into #Prompts (PromptName,PromptValue) Values('ApprovedOn',dbo.fnRS_TranslateString_New(@LangId, 36298, 'Approved On'))
Insert into #Prompts (PromptName,PromptValue) Values ('EffectiveDate',dbo.fnRS_TranslateString_New(@LangId, 36222, 'Effective Date'))
select * From #Prompts
Drop Table #Prompts
--**********************************************
-- Return Data For Report
--**********************************************
-- Create Simple Return Table
Create Table #Report (
  Id int identity(1,1),
  Name varchar(50),
  Value varchar(255) NULL,
  Hyperlink varchar(255) NULL
)
--********************************************************************************
-- Return Basic Transaction Information
--********************************************************************************
Truncate Table #Report
Insert Into #Report (Name, Value) Values ( 'CreatedOn', convert(varchar(17),dbo.fnServer_CmnConvertFromDBTime(@CreateDate,@TargetTimeZone)))
Insert Into #Report (Name, Value) Values (dbo.fnRS_TranslateString_New(@LangId, 34168, 'Group'), @TransactionGroup)
Insert Into #Report (Name, Value) Values (dbo.fnRS_TranslateString_New(@LangId, 36032, 'Description'), @TransactionDescription)
Select * From #Report Order By Id
--********************************************************************************
--********************************************************************************
-- Return Approval
--********************************************************************************
Truncate Table #Report
Insert Into #Report (Name, Value) Values ( 'CreatedOn', convert(varchar(17),dbo.fnServer_CmnConvertFromDBTime(@CreateDate,@TargetTimeZone)))
If @ApprovedDate Is Not Null
  Begin
 	  	 Insert Into #Report (Name, Value) Values ('ApprovedOn', convert(varchar(17),dbo.fnServer_CmnConvertFromDBTime(@ApprovedDate,@TargetTimeZone)))
 	  	 Insert Into #Report (Name, Value) Values (dbo.fnRS_TranslateString_New(@LangId, 34730, 'Approved By'), @ApprovedUser)
 	  	 Insert Into #Report (Name, Value) Values ( 'EffectiveDate', convert(varchar(17),dbo.fnServer_CmnConvertFromDBTime(@EffectiveDate,@TargetTimeZone)))
  End
Select * From #Report Order By Id
--********************************************************************************
--********************************************************************************
-- Return Corporate Specification Information
--********************************************************************************
Truncate Table #Report
If @CorporateServer Is Not Null
  Begin
 	  	 Insert Into #Report (Name, Value) Values (dbo.fnRS_TranslateString_New(@LangId, 36299, 'Remote Source'), @CorporateServer)
 	  	 Insert Into #Report (Name, Value) Values (dbo.fnRS_TranslateString_New(@LangId, 36032, 'Description'), @CorporateDescription)
  End
Select * From #Report Order By Id
--********************************************************************************
--********************************************************************************
-- Return Addition Of Products
--********************************************************************************
select Operation = Case When tp.Is_Delete = 1 then dbo.fnRS_TranslateString_New(@LangId, 36261, 'Remove') Else dbo.fnRS_TranslateString_New(@LangId, 36259, 'Add') End, 
       Product = p.prod_desc + ' (' + p.Prod_Code + ')',
       Line = pl.pl_desc,
       Unit = pu.pu_desc
  from trans_products tp
  Join Products p on p.prod_id = tp.prod_id
  Join prod_units pu on pu.pu_id = tp.pu_id
  Join prod_lines pl on pl.pl_id = pu.pl_id
  Where tp.trans_id = @TransactionId
  order by product
--********************************************************************************
--********************************************************************************
-- Return Characteristic Linkages
--********************************************************************************
--Make #product# #property#: #characteristic# on #unit#
select Product = p.prod_desc + ' (' + p.Prod_Code + ')', 
       Property = pp.prop_desc,
       Characteristic = c.char_desc,
       Line = pl.pl_desc,
       Unit = pu.pu_desc
  from trans_characteristics tc
  Join Products p on p.prod_id = tc.prod_id
  Join prod_units pu on pu.pu_id = tc.pu_id
  Join prod_lines pl on pl.pl_id = pu.pl_id
  Join product_properties pp on pp.prop_id = tc.prop_id
  Join characteristics c on c.char_id = tc.char_id
  Where tc.trans_id = @TransactionId
  order by product
--********************************************************************************
--********************************************************************************
-- Return Plant Level Specification Changes
--********************************************************************************
select Property = pp.prop_desc,
       Characteristic = c.char_desc,
       Specification = s.spec_desc,
       EngineeringUnits = s.eng_units,
       OldTGT = as1.Target,
       OldLEL = as1.l_entry,
       OldLRL = as1.l_reject,
       OldLWL = as1.l_warning,
       OldLUL = as1.l_user,
       OldUUL = as1.u_user,
       OldUWL = as1.u_warning,
       OldURL = as1.u_reject,
       OldUEL = as1.u_entry,
       OldTF =  as1.test_freq,
       NewTGT = tp.Target, 
       NewLEL = tp.l_entry, 
       NewLRL = tp.l_reject, 
       NewLWL = tp.l_warning, 
       NewLUL = tp.l_user, 
       NewUUL = tp.u_user, 
       NewUWL = tp.u_warning, 
       NewURL = tp.u_reject, 
       NewUEL = tp.u_entry, 
       NewTF =  tp.test_freq, 
       Comment = t.comment_text
  from trans_properties tp
  Join characteristics c on c.char_id = tp.char_id
  Join product_properties pp on pp.prop_id = c.prop_id
  Join specifications s on s.spec_id = tp.spec_id
  left outer join comments t on t.comment_id = tp.comment_id
  left outer join active_specs as1 on as1.spec_id = tp.spec_id and 
                               as1.char_id = tp.char_id and 
                               as1.effective_date <= @QueryDate and 
                             ((as1.expiration_date > @QueryDate) or (as1.expiration_date is null))
  Where tp.trans_id = @TransactionId
  order by property, characteristic, Specification
--********************************************************************************
--********************************************************************************
-- Return Variable Level Specification Changes
--********************************************************************************
select Product = p.prod_desc + ' (' + p.Prod_Code + ')', 
       Line = pl.pl_desc,
       Unit = pu.pu_desc,
       Variable = v.var_desc,
       EngineeringUnits = v.eng_units,
       OldTGT = vs1.Target,
       OldLEL = vs1.l_entry,
       OldLRL = vs1.l_reject,
       OldLWL = vs1.l_warning,
       OldLUL = vs1.l_user,
       OldUUL = vs1.u_user,
       OldUWL = vs1.u_warning,
       OldURL = vs1.u_reject,
       OldUEL = vs1.u_entry,
       OldTF =  vs1.test_freq,
       NewTGT = tv.Target,
       NewLEL = tv.l_entry,
       NewLRL = tv.l_reject, 
       NewLWL = tv.l_warning,
       NewLUL = tv.l_user,
       NewUUL = tv.u_user, 
       NewUWL = tv.u_warning, 
       NewURL = tv.u_reject, 
       NewUEL = tv.u_entry, 
       NewTF =  tv.test_freq, 
       Comment = t.comment_text
  from trans_variables tv
  join variables v on v.var_id = tv.var_id
  join prod_units pu on pu.pu_id = v.pu_id
  Join prod_lines pl on pl.pl_id = pu.pl_id
  join products p on p.prod_id = tv.prod_id
  left outer join comments t on t.comment_id = tv.comment_id
  left outer join var_specs vs1 on vs1.var_id = tv.var_id and 
                               vs1.prod_id = tv.prod_id and 
                               vs1.effective_date <= @QueryDate and 
                             ((vs1.expiration_date > @QueryDate) or (vs1.expiration_date is null))
  Where tv.trans_id = @TransactionId
  order by product, line, unit, variable
Drop Table #Report
