-- spEMAC_SearchRules '',1
Create Procedure dbo.spEMAC_SearchRules 
@SearchString nvarchar(50),
@User_Id int
AS
declare @ATId int
declare @AlarmTypeId int
declare @APId int
declare @NumVariables int
declare @DescSearch nvarchar(50)
select @DescSearch = @SearchString
declare @RuleText nvarchar(255)
if @DescSearch = ''
  select @DescSearch = '%%'
else
  select @DescSearch = '%' + @DescSearch + '%'
select @RuleText = ''
DECLARE  @AlarmsSearchRules table(
  AT_Id int,
  AT_Desc nvarchar(50),
  AP_Id int,
  Lower_Entry bit, 
  Lower_Reject bit, 
  Lower_Warning bit, 
  Lower_User bit, 
  Target bit,
  Upper_User bit, 
  Upper_Warning bit, 
  Upper_Reject bit, 
  Upper_Entry bit, 
  Custom_Text nvarchar(255),
  Rule_Text nvarchar(255),
  Use_Var_Desc bit,
  Use_Trigger_Desc bit,
  Use_AT_Desc bit,
  Cause_Required bit,
  Action_Required bit,
  Comment_Id int,
  Alarm_Type_Desc nvarchar(50),
  Num_Variables int,
  DQ_Tag nVarChar(100),
  DQ_Var_Id int,
  DQ_Criteria tinyint,
  DQ_Value nVarChar(25),
  Alarm_Type_Id int,
  ESignature_Level int,
  sp_Name 	  	 nvarchar(50),
  String_Specification_Setting TinyInt,
  UseLineDesc Int,
  UseUnitDesc Int,
  Email_Table_Id    Int
)
insert into @AlarmsSearchRules(AT_Id,AT_Desc,AP_Id,Lower_Entry,Lower_Reject, 
  Lower_Warning,Lower_User,Target,Upper_User,Upper_Warning, 
  Upper_Reject,Upper_Entry,Custom_Text,Rule_Text,Use_Var_Desc,
  Use_Trigger_Desc,Use_AT_Desc,Cause_Required,Action_Required,Comment_Id,
  Alarm_Type_Desc,Num_Variables,DQ_Tag,DQ_Var_Id,DQ_Criteria,
  DQ_Value,Alarm_Type_Id,ESignature_Level,sp_Name,String_Specification_Setting,
  UseLineDesc,UseUnitDesc,Email_Table_Id)
select AT_Id, AT_Desc, AP_Id, Lower_Entry, Lower_Reject,
 	  	  	  Lower_Warning, Lower_User, Target,Upper_User, Upper_Warning,
 	  	  	  Upper_Reject, Upper_Entry, Custom_Text, NULL, Use_Var_Desc,
       Use_Trigger_Desc, Use_AT_Desc, Cause_Required, Action_Required, Comment_Id,
 	  	 Alarm_Type_Desc = CASE WHEN t.Alarm_Type_Id <> 1 THEN T.Alarm_Type_Desc
 	  	  	  	  	  	  	  	 WHEN a.String_Specification_Setting = 0 THEN 'String - ' + T.Alarm_Type_Desc + '(Equal Spec)'
 	  	  	  	  	  	  	  	 WHEN a.String_Specification_Setting = 1 THEN 'String - ' + T.Alarm_Type_Desc + '(Not Equal Spec)'
 	  	  	  	  	  	  	  	 WHEN a.String_Specification_Setting = 2 THEN 'String - ' + T.Alarm_Type_Desc + '(Use Phrase Order)'
 	  	  	  	  	  	  	  	 ELSE T.Alarm_Type_Desc
 	  	  	  	  	  	  	 END 	 , 
       NULL, DQ_Tag, DQ_Var_Id, DQ_Criteria,
       DQ_Value, T.Alarm_Type_Id, A.ESignature_Level,isnull(a.sp_Name,''),A.String_Specification_Setting,
       ISNULL(Use_Line_desc,0),ISNULL(Use_Unit_desc,0),ISNULL(a.Email_Table_Id,-1)
from Alarm_Templates A
join Alarm_Types T on T.Alarm_Type_Id = A.Alarm_Type_Id
where AT_Desc like @DescSearch
Declare AlarmSearchRulesCursor Cursor For
  Select AT_Id, Alarm_Type_Id from @AlarmsSearchRules for read only
Open AlarmSearchRulesCursor
While (0=0) Begin
  Fetch Next
    From AlarmSearchRulesCursor
    Into @ATId, @AlarmTypeId
  If (@@Fetch_Status <> 0) Break
    If @AlarmTypeId = 1
      Begin
 	  	     select @NumVariables = (select count(*) from Alarm_Template_Var_Data
 	  	     where Alarm_Template_Var_Data.AT_Id = @ATId and Alarm_Template_Var_Data.ATVRD_Id is NULL)
      End
    Else
      Begin
 	  	     select @NumVariables = (select count(*) from Alarm_Template_Var_Data
 	  	     where Alarm_Template_Var_Data.AT_Id = @ATId and Alarm_Template_Var_Data.ATSRD_Id is NULL)
      End
    update @AlarmsSearchRules set Num_Variables = @NumVariables where AT_Id = @ATId
    select @RuleText = ''
    if (select UseLineDesc from @AlarmsSearchRules where AT_Id = @ATId) = 1
      select @RuleText = @RuleText + '[Line]'
    if (select UseUnitDesc from @AlarmsSearchRules where AT_Id = @ATId) = 1
      select @RuleText = @RuleText + '[Unit]'
    if (select Use_Var_Desc from @AlarmsSearchRules where AT_Id = @ATId) = 1
      select @RuleText = @RuleText + '[Var]'
    if (select Use_AT_Desc from @AlarmsSearchRules where AT_Id = @ATId) = 1
      select @RuleText = @RuleText + '[Template]'
    if (select Use_Trigger_Desc from @AlarmsSearchRules where AT_Id = @ATId) = 1
      select @RuleText = @RuleText + '[Trigger]'
    if (select Custom_Text from @AlarmsSearchRules where AT_Id = @ATId) <> ''
 	  	  	  	 select @RuleText = @RuleText + '[' + Custom_Text + ']' from @AlarmsSearchRules where AT_Id = @ATId
    update @AlarmsSearchRules set Rule_Text = @RuleText where AT_Id = @ATId
 	  	 --Update the AP_Id appropriately for each Template (Variable Templates)
    --Use the Max AP_Id as the priority can change by Rule
    if @AlarmTypeId = 1
      Begin
        Select @APId = max(AP_Id) from Alarm_Template_Variable_Rule_Data Where AT_Id = @ATId
 	  	  	  	 Update @AlarmsSearchRules set AP_Id = @APId Where AT_Id = @ATId
      End
    else
      Begin
   	  	 --Update the AP_Id appropriately for each Template (SPC Templates)
      --Use the Max AP_Id as the priority can change by Rule
 	  	  	  	 Select @APId = max(AP_Id) from Alarm_Template_SPC_Rule_Data where AT_Id = @ATId        
 	  	     Update @AlarmsSearchRules set AP_Id = @APId Where AT_Id = @ATId
      End
End
Close AlarmSearchRulesCursor
Deallocate AlarmSearchRulesCursor
select value from site_parameters where parm_id = 25
select * from @AlarmsSearchRules
DECLARE @Tables Table (TableId Int,TableName nVarChar(100))
INSERT INTO @Tables(TableId,TableName) VALUES (17,'Department')
INSERT INTO @Tables(TableId,TableName) VALUES (18,'Production Line')
INSERT INTO @Tables(TableId,TableName) VALUES (19,'Production Group')
INSERT INTO @Tables(TableId,TableName) VALUES (21,'Product Family')
INSERT INTO @Tables(TableId,TableName) VALUES (22,'Product Group')
INSERT INTO @Tables(TableId,TableName) VALUES (23,'Product')
INSERT INTO @Tables(TableId,TableName) VALUES (43,'Production Unit')
Select TableId,TableName from @Tables  order by TableName
