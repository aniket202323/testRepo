CREATE PROCEDURE [dbo].[spASP_wrAlarmHistory]
@EventId int,
@InTimeZone nvarchar(200)=NULL
AS
/*********************************************
-- For Testing
--*********************************************
Select @EventId = 5 --5 --8 
--**********************************************/
Declare @ReportName nvarchar(255)
Declare @CriteriaString nVarChar(1000)
Declare @Unit int
Declare @Key int
Declare @AlarmName nVarChar(100)
Declare @AlarmType int
Declare @AlarmTemplate int
Declare @StartTime datetime
Declare @EndTime datetime
Declare @CauseTree int
Declare @ActionTree int
Declare @CauseLevel1Name nvarchar(25)
Declare @CauseLevel2Name nvarchar(25)
Declare @CauseLevel3Name nvarchar(25)
Declare @CauseLevel4Name nvarchar(25)
Declare @ActionLevel1Name nvarchar(25)
Declare @ActionLevel2Name nvarchar(25)
Declare @ActionLevel3Name nvarchar(25)
Declare @ActionLevel4Name nvarchar(25)
Declare @EventType nvarchar(255)
-- Look up the language Id
Declare @LangId INT
EXEC spWA_GetCurrentUserInfo @LangId = @LangId OUTPUT
Select @EventType = dbo.fnTranslate(@LangId, 34902, 'Alarm')
--**********************************************
-- Loookup Initial Information For This Event
--**********************************************
If @EventId Is Null
  Begin
    Raiserror('Event ID Is A Required Parameter',16,1)
    Return
  End
-- Get Event Information
Select @Key = d.Key_Id, @AlarmType = d.Alarm_Type_Id, 
       @StartTime = d.start_time, @EndTime = d.end_time
  From Alarms d
  Where d.Alarm_id = @EventId
If @AlarmType = 1
  Select @AlarmName = Var_Desc + ' ' + dbo.fnTranslate(@LangId, 34643, 'Limit Alarm')
   From Variables
   Where Var_Id = @Key
Else If @AlarmType = 2
  Select @AlarmName = Var_Desc + ' ' + dbo.fnTranslate(@LangId, 34644, 'SPC Alarm')
   From Variables
   Where Var_Id = @Key
Else
  Select @AlarmName = PU_Desc + ' ' + dbo.fnTranslate(@LangId, 34645, 'Production Alarm')
   From Prod_Units
   Where PU_Id = @Key
If @AlarmType in (1,2)
  Select @Unit = coalesce(pu.Master_Unit, pu.PU_id)
    From Variables v
    Join prod_units pu on pu.pu_id = v.pu_id
    Where v.Var_Id = @Key
Else
  Select @Unit = @Key
If @AlarmType in (1,2)
  Begin
 	  	 Select @AlarmTemplate = AT_Id
 	  	   From Alarm_Template_Var_Data
      Where ATD_Id = @AlarmTemplate
    Select @CauseTree = Cause_Tree_id,
           @ActionTree = Action_Tree_Id 
      From Alarm_Templates
      Where AT_Id = @AlarmTemplate
  End
If @CauseTree Is Not Null  
  Begin
 	  	 Select @CauseLevel1Name = level_name
 	  	   From event_reason_level_headers 
 	  	   Where Tree_Name_id = @CauseTree and
 	  	         Reason_Level = 1
 	  	 
 	  	 If @CauseLevel1Name Is Not Null 
 	  	  	 Select @CauseLevel2Name = level_name
 	  	  	   From event_reason_level_headers 
 	  	  	   Where Tree_Name_id = @CauseTree and
 	  	  	         Reason_Level = 2
 	  	 
 	  	 If @CauseLevel2Name Is Not Null 
 	  	  	 Select @CauseLevel3Name = level_name
 	  	  	   From event_reason_level_headers 
 	  	  	   Where Tree_Name_id = @CauseTree and
 	  	  	         Reason_Level = 3
 	  	 
 	  	 If @CauseLevel3Name Is Not Null 
 	  	  	 Select @CauseLevel4Name = level_name
 	  	  	   From event_reason_level_headers 
 	  	  	   Where Tree_Name_id = @CauseTree and
 	  	  	         Reason_Level = 4
 	 End
If @ActionTree Is Not Null
  Begin
 	  	 Select @ActionLevel1Name = level_name
 	  	   From event_reason_level_headers 
 	  	   Where Tree_Name_id = @ActionTree and
 	  	         Reason_Level = 1
 	  	 
 	  	 If @ActionLevel1Name Is Not Null 
 	  	  	 Select @ActionLevel2Name = level_name
 	  	  	   From event_reason_level_headers 
 	  	  	   Where Tree_Name_id = @ActionTree and
 	  	  	         Reason_Level = 2
 	  	 
 	  	 If @ActionLevel2Name Is Not Null 
 	  	  	 Select @ActionLevel3Name = level_name
 	  	  	   From event_reason_level_headers 
 	  	  	   Where Tree_Name_id = @ActionTree and
 	  	  	         Reason_Level = 3
 	  	 
 	  	 If @ActionLevel3Name Is Not Null 
 	  	  	 Select @ActionLevel4Name = level_name
 	  	  	   From event_reason_level_headers 
 	  	  	   Where Tree_Name_id = @ActionTree and
 	  	  	         Reason_Level = 4
 	 End 	  	  	       
Select @CauseLevel1Name = coalesce(@CauseLevel1Name, dbo.fnTranslate(@LangId, 34626, 'Cause 1'))
Select @CauseLevel2Name = coalesce(@CauseLevel2Name, dbo.fnTranslate(@LangId, 34627, 'Cause 2'))
Select @CauseLevel3Name = coalesce(@CauseLevel3Name, dbo.fnTranslate(@LangId, 34628, 'Cause 3'))
Select @CauseLevel4Name = coalesce(@CauseLevel4Name, dbo.fnTranslate(@LangId, 34629, 'Cause 4'))
Select @ActionLevel1Name = coalesce(@ActionLevel1Name, dbo.fnTranslate(@LangId, 34630, 'Action 1'))
Select @ActionLevel2Name = coalesce(@ActionLevel2Name, dbo.fnTranslate(@LangId, 34631, 'Action 2'))
Select @ActionLevel3Name = coalesce(@ActionLevel3Name, dbo.fnTranslate(@LangId, 34632, 'Action 3'))
Select @ActionLevel4Name = coalesce(@ActionLevel4Name, dbo.fnTranslate(@LangId, 34633, 'Action 4'))
--**********************************************
-- Return Header Information
--**********************************************
-- Line1: Report Name
-- Line2: Criteria
-- Line3: Generate Time
-- Line4 - n: Column Names
Declare @Prompts Table (
  PromptId int,
  PromptName nvarchar(20),
  PromptValue nvarchar(1000),
  PromptValue_Parameter SQL_Variant,
  PromptValue_Parameter2 SQL_Variant,
  PromptValue_Parameter3 SQL_Variant  
)
Select @ReportName = dbo.fnTranslate(@LangId, 34646, 'Alarm Event History')
Insert into @Prompts (PromptName, PromptValue) Values ('ReportName', @ReportName)
SET @CriteriaString = dbo.fnTranslate(@LangId, 34647, 'For {0} From [{1}] To [{2}]')
IF @EndTime IS NULL
  Insert into @Prompts (PromptName, PromptValue, PromptValue_Parameter, PromptValue_Parameter2, PromptValue_Parameter3)
    Values ('Criteria', @CriteriaString, @AlarmName, @StartTime, dbo.fnTranslate(@LangId, 34616, 'OPEN'))
ELSE
  Insert into @Prompts (PromptName, PromptValue, PromptValue_Parameter, PromptValue_Parameter2, PromptValue_Parameter3)
    Values('Criteria', @CriteriaString, @AlarmName, @StartTime, @EndTime)
Insert into @Prompts (PromptName, PromptValue, PromptValue_Parameter)
  Values('GenerateTime', dbo.fnTranslate(@LangId, 34521, 'Created: {0}'), dbo.fnServer_CmnGetDate(getutcdate()))
Insert into @Prompts (PromptName, PromptValue) Values('History', dbo.fnTranslate(@LangId, 34648, 'History'))
Insert into @Prompts (PromptName, PromptValue) Values('Updated', dbo.fnTranslate(@LangId, 34649, 'Updated'))
Insert into @Prompts (PromptName, PromptValue) Values('Added', dbo.fnTranslate(@LangId, 34650, 'Added'))
Insert into @Prompts (PromptName, PromptValue) Values('Removed', dbo.fnTranslate(@LangId, 34651, 'Removed'))
Insert into @Prompts (PromptName, PromptValue) Values('FromValue', dbo.fnTranslate(@LangId, 34652, 'From Value'))
Insert into @Prompts (PromptName, PromptValue) Values('ToValue', dbo.fnTranslate(@LangId, 34653, 'To Value'))
Insert into @Prompts (PromptName, PromptValue) Values('UpdateTime', dbo.fnTranslate(@LangId, 34654, 'Update Time'))
Insert into @Prompts (PromptName, PromptValue) Values('UpdateUser', dbo.fnTranslate(@LangId, 34655, 'Update User'))
Insert into @Prompts (PromptName, PromptValue) Values('StartTime', dbo.fnTranslate(@LangId, 34011, 'Start Time'))
Insert into @Prompts (PromptName, PromptValue) Values('EndTime', dbo.fnTranslate(@LangId, 34012, 'End Time'))
Insert into @Prompts (PromptName, PromptValue) Values('Duration', dbo.fnTranslate(@LangId, 34656, 'Duration'))
Insert into @Prompts (PromptName, PromptValue) Values('AlarmDescription', dbo.fnTranslate(@LangId, 34614, 'Description'))
Insert into @Prompts (PromptName, PromptValue) Values('AlarmRule', dbo.fnTranslate(@LangId, 34615, 'Rule'))
Insert into @Prompts (PromptName, PromptValue) Values('Acked', dbo.fnTranslate(@LangId, 34657, 'Acked'))
Insert into @Prompts (PromptName, PromptValue) Values('AckedBy', dbo.fnTranslate(@LangId, 34658, 'Acked By'))
Insert into @Prompts (PromptName, PromptValue) Values('AckedOn', dbo.fnTranslate(@LangId, 34659, 'Acked On'))
Insert into @Prompts (PromptName, PromptValue) Values('StartResult', dbo.fnTranslate(@LangId, 34638, 'Start Value'))
Insert into @Prompts (PromptName, PromptValue) Values('MinResult', dbo.fnTranslate(@LangId, 34639, 'Min Value'))
Insert into @Prompts (PromptName, PromptValue) Values('MaxResult', dbo.fnTranslate(@LangId, 34640, 'Max Value'))
Insert into @Prompts (PromptName, PromptValue) Values('EndResult', dbo.fnTranslate(@LangId, 34641, 'End Value'))
Insert into @Prompts (PromptName, PromptValue) Values('ESigPerformer', dbo.fnTranslate(@LangId, 35145, 'E-Signature Performer'))
Insert into @Prompts (PromptName, PromptValue) Values('ESigPerformedTime', dbo.fnTranslate(@LangId, 35146, 'E-Signature Performed Time'))
Insert into @Prompts (PromptName, PromptValue) Values('ESigPerformerReason', dbo.fnTranslate(@LangId, 35147, 'E-Signature Performer Reason'))
Insert into @Prompts (PromptName, PromptValue) Values('ESigPerformerComment', dbo.fnTranslate(@LangId, 35148, 'E-Signature Performer Comment'))
Insert into @Prompts (PromptName, PromptValue) Values('ESigApprover', dbo.fnTranslate(@LangId, 35149, 'E-Signature Approver'))
Insert into @Prompts (PromptName, PromptValue) Values('ESigApprovedTime', dbo.fnTranslate(@LangId, 35150, 'E-Signature Approved Time'))
Insert into @Prompts (PromptName, PromptValue) Values('ESigApproverReason', dbo.fnTranslate(@LangId, 35151, 'E-Signature Approver Reason'))
Insert into @Prompts (PromptName, PromptValue) Values('ESigApproverComment', dbo.fnTranslate(@LangId, 35152, 'E-Signature Approver Comment'))
Insert into @Prompts (PromptName, PromptValue) Values('Cause1', @CauseLevel1Name)
Insert into @Prompts (PromptName, PromptValue) Values('Cause2', @CauseLevel2Name)
Insert into @Prompts (PromptName, PromptValue) Values('Cause3', @CauseLevel3Name)
Insert into @Prompts (PromptName, PromptValue) Values('Cause4', @CauseLevel4Name)
Insert into @Prompts (PromptName, PromptValue) Values('Action1', @ActionLevel1Name)
Insert into @Prompts (PromptName, PromptValue) Values('Action2', @ActionLevel2Name)
Insert into @Prompts (PromptName, PromptValue) Values('Action3', @ActionLevel3Name)
Insert into @Prompts (PromptName, PromptValue) Values('Action4', @ActionLevel4Name)
Insert into @Prompts (PromptName, PromptValue) Values('ResearchStatus', dbo.fnTranslate(@LangId, 34660, 'Research Status'))
Insert into @Prompts (PromptName, PromptValue) Values('ResearchOpen', dbo.fnTranslate(@LangId, 34661, 'Research Open Date'))
Insert into @Prompts (PromptName, PromptValue) Values('ResearchClosed', dbo.fnTranslate(@LangId, 34662, 'Research Close Date'))
Insert into @Prompts (PromptName, PromptValue) Values('ResearchUser', dbo.fnTranslate(@LangId, 34663, 'Research User'))
Insert Into @Prompts (PromptId, PromptName, PromptValue) Values(44, 'Item', dbo.fnTranslate(@LangId, 34797, 'Item'))
select PromptId,PromptName,PromptValue,'PromptValue_Parameter'= case when (ISDATE(Convert(varchar,PromptValue_Parameter))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,PromptValue_Parameter),@InTimeZone)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 PromptValue_Parameter
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end,
 	  	  	  	  	  	  	  	  	  	 'PromptValue_Parameter2'= case when (ISDATE(Convert(varchar,PromptValue_Parameter2))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,PromptValue_Parameter2),@InTimeZone)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 PromptValue_Parameter2
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end,
 	  	  	  	  	  	  	  	  	  	 'PromptValue_Parameter3'= case when (ISDATE(Convert(varchar,PromptValue_Parameter3))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,PromptValue_Parameter3),@InTimeZone)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 PromptValue_Parameter3
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end
FROM @Prompts
--**********************************************
-- Return Data For Report
--**********************************************
Select UpdateTime =   [dbo].[fnServer_CmnConvertFromDbTime] (d.Modified_on,@InTimeZone)  ,  
       UpdateUser = u3.Username,
 	  	  	  Item = @EventType,
       AlarmDescription = NULL, --d.Alarm_Desc
       AlarmRule = r.Alarm_SPC_Rule_Desc,
       StartTime =   [dbo].[fnServer_CmnConvertFromDbTime] (d.start_time,@InTimeZone)  ,
       EndTime = [dbo].[fnServer_CmnConvertFromDbTime] (d.end_time,@InTimeZone) ,
       Duration = case when d.end_time Is Null Then NULL Else datediff(second,d.start_time, d.end_time) / 60.0 end,
       Cause1 = r1.event_reason_name,
       Cause2 = r2.event_reason_name,
       Cause3 = r3.event_reason_name,
       Cause4 = r3.event_reason_name,
       Action1 = a1.event_reason_name,
       Action2 = a2.event_reason_name,
       Action3 = a3.event_reason_name,
       Action4 = a4.event_reason_name,
       ResearchStatus = rs.research_status_desc,
       ResearchOpen =  [dbo].[fnServer_CmnConvertFromDbTime] (d.Research_Open_Date,@InTimeZone) ,
       ResearchClosed =   [dbo].[fnServer_CmnConvertFromDbTime] (d.Research_Close_Date,@InTimeZone) ,
       ResearchUser = u1.Username,
       Acked = d.Ack,
       AckedBy = u2.Username,
       AckedOn =  [dbo].[fnServer_CmnConvertFromDbTime] (d.Ack_On,@InTimeZone) ,
       StartResult = d.Start_Result,
       MinResult = d.Min_Result,
       MaxResult = d.Max_Result,
       EndResult = d.End_Result,
 	  	  	  ESigPerformer = esig_pu.Username,
 	  	  	  ESigPerformedTime = esig.Perform_Time,
 	  	  	  ESigPerformerReason = pr.Event_Reason_Name,
 	  	  	  ESigPerformerComment = pc.Comment_Text,
 	  	  	  ESigApprover = esig_vu.Username,
 	  	  	  ESigApprovedTime = esig.Verify_Time,
 	  	  	  ESigApproverReason = vr.Event_Reason_Name,
 	  	  	  ESigApproverComment = vc.Comment_Text
  From Alarm_History d
  Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.cause1
  Left Outer Join Event_Reasons r2 on r2.event_reason_id = d.cause2
  Left Outer Join Event_Reasons r3 on r3.event_reason_id = d.cause3
  Left Outer Join Event_Reasons r4 on r4.event_reason_id = d.cause4
  Left Outer Join Event_Reasons a1 on a1.event_reason_id = d.action1
  Left Outer Join Event_Reasons a2 on a1.event_reason_id = d.action2
  Left Outer Join Event_Reasons a3 on a1.event_reason_id = d.action3
  Left Outer Join Event_Reasons a4 on a1.event_reason_id = d.action4
  Left outer Join Users u1 on u1.user_id = d.research_user_id
  Left outer Join Users u2 on u2.user_id = d.ack_by
  Left outer Join Users u3 on u3.user_id = d.user_id
  left outer join research_status rs on rs.research_status_Id = d.research_status_id
  left outer join alarm_template_spc_rule_data rd on rd.ATSRD_Id = d.ATSRD_Id
  left outer Join alarm_spc_rules r on r.Alarm_SPC_Rule_Id = rd.Alarm_SPC_Rule_Id
 	 left outer join esignature esig on d.Signature_Id = esig.Signature_Id
 	 left outer join users esig_pu on esig.Perform_User_Id = esig_pu.user_id
 	 left outer join users esig_vu on esig.Verify_User_Id = esig_vu.user_id
 	 left outer join event_reasons pr On esig.Perform_Reason_Id = pr.Event_Reason_Id
 	 left outer join event_reasons vr On esig.Verify_Reason_Id = vr.Event_Reason_Id
 	 left outer join Comments pc On esig.Perform_Comment_Id = pc.Comment_Id
 	 left outer join Comments vc On esig.Verify_Comment_Id = vc.Comment_Id
  Where d.Alarm_id = @EventId
  Order By d.Modified_On ASC
