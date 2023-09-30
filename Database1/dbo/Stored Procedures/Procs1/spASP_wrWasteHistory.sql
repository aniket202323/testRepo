﻿CREATE PROCEDURE [dbo].[spASP_wrWasteHistory]
@EventId int,
@InTimeZone nvarchar(200)=NULL
AS
/*********************************************
-- For Testing
--*********************************************
Select @EventId = 3515
--**********************************************/
Declare @ReportName nvarchar(255)
Declare @CriteriaString nVarChar(1000)
Declare @Unit int
Declare @UnitName nVarChar(100)
Declare @Timestamp datetime
Declare @LocationId int
Declare @ProductionEventId int
Declare @ProductionEventName nVarChar(50)
Declare @DimensionXUnits nvarchar(25)
Declare @TreeId int
Declare @CauseLevel1Name nvarchar(25)
Declare @CauseLevel2Name nvarchar(25)
Declare @CauseLevel3Name nvarchar(25)
Declare @CauseLevel4Name nvarchar(25)
Declare @ActionLevel1Name nvarchar(25)
Declare @ActionLevel2Name nvarchar(25)
Declare @ActionLevel3Name nvarchar(25)
Declare @ActionLevel4Name nvarchar(25)
Declare @EventType nvarchar(255)
--**********************************************
-- Translations Setup & Common Prompt Lookup
--**********************************************
-- Retreive the Language Id of the current user
Declare @LangId INT
EXEC spWA_GetCurrentUserInfo @LangId = @LangId OUTPUT
Select @EventType = dbo.fnTranslate(@LangId, 34779, 'Waste')
-- Get Common Prompts
DECLARE @sUnspecified nVarChar(100)
SET @sUnspecified = dbo.fnTranslate(@LangId, 34519, '<Unspecified>')
--**********************************************
If @EventId Is Null
  Begin
    Raiserror('SP: Event ID Is A Required Parameter',16,1)
    Return
  End
Select @Unit = PU_Id, @Timestamp = Timestamp, @ProductionEventId = Event_Id, @LocationId = source_pu_id
  From Waste_Event_Details
  Where WED_id = @EventId
Select @UnitName = PU_Desc
 From Prod_Units 
 Where PU_Id = @Unit
If @LocationId Is Not Null
  Begin
 	  	 Select @TreeId = Name_Id
 	  	   From Prod_Events
 	  	   Where PU_Id = @LocationId and
            Event_Type = 3
    If @TreeId Is Not Null  
      Begin
 	  	  	  	 Select @CauseLevel1Name = level_name
 	  	  	  	   From event_reason_level_headers 
 	  	  	  	   Where Tree_Name_id = @TreeId and
 	  	  	  	         Reason_Level = 1
 	  	  	  	 
 	  	  	  	 If @CauseLevel1Name Is Not Null 
 	  	  	  	  	 Select @CauseLevel2Name = level_name
 	  	  	  	  	   From event_reason_level_headers 
 	  	  	  	  	   Where Tree_Name_id = @TreeId and
 	  	  	  	  	         Reason_Level = 2
 	  	  	  	 
 	  	  	  	 If @CauseLevel2Name Is Not Null 
 	  	  	  	  	 Select @CauseLevel3Name = level_name
 	  	  	  	  	   From event_reason_level_headers 
 	  	  	  	  	   Where Tree_Name_id = @TreeId and
 	  	  	  	  	         Reason_Level = 3
 	  	  	  	 
 	  	  	  	 If @CauseLevel3Name Is Not Null 
 	  	  	  	  	 Select @CauseLevel4Name = level_name
 	  	  	  	  	   From event_reason_level_headers 
 	  	  	  	  	   Where Tree_Name_id = @TreeId and
 	  	  	  	  	         Reason_Level = 4
 	  	  	 End
 	  	 Select @TreeId = NULL
 	  	 Select @TreeId = Action_Tree_Id
 	  	   From Prod_Events
 	  	   Where PU_Id = @LocationId and
 	  	         Event_Type = 3
 	  	 
 	  	 If @TreeId Is Not Null
 	  	   Begin
 	  	 
 	  	  	  	 Select @ActionLevel1Name = level_name
 	  	  	  	   From event_reason_level_headers 
 	  	  	  	   Where Tree_Name_id = @TreeId and
 	  	  	  	         Reason_Level = 1
 	  	  	  	 
 	  	  	  	 If @ActionLevel1Name Is Not Null 
 	  	  	  	  	 Select @ActionLevel2Name = level_name
 	  	  	  	  	   From event_reason_level_headers 
 	  	  	  	  	   Where Tree_Name_id = @TreeId and
 	  	  	  	  	         Reason_Level = 2
 	  	  	  	 
 	  	  	  	 If @ActionLevel2Name Is Not Null 
 	  	  	  	  	 Select @ActionLevel3Name = level_name
 	  	  	  	  	   From event_reason_level_headers 
 	  	  	  	  	   Where Tree_Name_id = @TreeId and
 	  	  	  	  	         Reason_Level = 3
 	  	  	  	 
 	  	  	  	 If @ActionLevel3Name Is Not Null 
 	  	  	  	  	 Select @ActionLevel4Name = level_name
 	  	  	  	  	   From event_reason_level_headers 
 	  	  	  	  	   Where Tree_Name_id = @TreeId and
 	  	  	  	  	         Reason_Level = 4
 	 
 	  	 End 	  	  	       
  End
Select @CauseLevel1Name = coalesce(@CauseLevel1Name, dbo.fnTranslate(@LangId, 34626, 'Cause 1'))
Select @CauseLevel2Name = coalesce(@CauseLevel2Name, dbo.fnTranslate(@LangId, 34627, 'Cause 2'))
Select @CauseLevel3Name = coalesce(@CauseLevel3Name, dbo.fnTranslate(@LangId, 34628, 'Cause 3'))
Select @CauseLevel4Name = coalesce(@CauseLevel4Name, dbo.fnTranslate(@LangId, 34629, 'Cause 4'))
Select @ActionLevel1Name = coalesce(@ActionLevel1Name, dbo.fnTranslate(@LangId, 34630, 'Action 1'))
Select @ActionLevel2Name = coalesce(@ActionLevel2Name, dbo.fnTranslate(@LangId, 34631, 'Action 2'))
Select @ActionLevel3Name = coalesce(@ActionLevel3Name, dbo.fnTranslate(@LangId, 34632, 'Action 3'))
Select @ActionLevel4Name = coalesce(@ActionLevel4Name, dbo.fnTranslate(@LangId, 34633, 'Action 4'))
Select @ProductionEventName = s.event_subtype_desc,
       @DimensionXUnits = s.Dimension_X_Eng_Units
  from event_configuration e 
  join event_subtypes s on s.Event_Subtype_Id = e.Event_Subtype_Id
  where e.pu_id = @Unit and 
        e.et_id = 1
Select @ReportName = dbo.fnTranslate(@LangId, 34901, 'Waste Event History')
--**********************************************
-- Return Header Information
--**********************************************
-- Line1: Report Name
-- Line2: Criteria
-- Line3: Generate Time
-- Line4 - n: Column Names
Declare @Prompts Table(
  PromptId int null,
  PromptName nvarchar(20),
  PromptValue nvarchar(1000),
  PromptValue_Parameter SQL_Variant,
  PromptValue_Parameter2 SQL_Variant,
  PromptValue_Parameter3 SQL_Variant
)
Insert into @Prompts (PromptName, PromptValue) Values ('ReportName', @ReportName)
If @ProductionEventId Is Null
  Insert into @Prompts (PromptName, PromptValue, PromptValue_Parameter, PromptValue_Parameter2, PromptValue_Parameter3)
    Values('Criteria', dbo.fnTranslate(@LangId, 34895, 'Event At [{0}] On {2}'), @Timestamp, NULL, @UnitName)
Else
  Insert into @Prompts (PromptName, PromptValue, PromptValue_Parameter, PromptValue_Parameter2, PromptValue_Parameter3)
    Values('Criteria', dbo.fnTranslate(@LangId, 34896, 'Event At [{0}] For {1} On {2}'), @Timestamp, @ProductionEventId, @UnitName)
Insert into @Prompts (PromptName, PromptValue, PromptValue_Parameter) Values('GenerateTime', dbo.fnTranslate(@LangId, 34521, 'Created: {0}'), dbo.fnServer_CmnGetDate(getutcdate()))
Insert into @Prompts (PromptName, PromptValue) Values ('History', dbo.fnTranslate(@LangId, 34648, 'History'))
Insert into @Prompts (PromptName, PromptValue) Values ('Updated', dbo.fnTranslate(@LangId, 34649, 'Updated'))
Insert into @Prompts (PromptName, PromptValue) Values ('Added', dbo.fnTranslate(@LangId, 34650, 'Added'))
Insert into @Prompts (PromptName, PromptValue) Values ('Removed', dbo.fnTranslate(@LangId, 34651, 'Removed'))
Insert into @Prompts (PromptName, PromptValue) Values ('FromValue', dbo.fnTranslate(@LangId, 34652, 'From Value'))
Insert into @Prompts (PromptName, PromptValue) Values ('ToValue', dbo.fnTranslate(@LangId, 34653, 'To Value'))
Insert into @Prompts (PromptName, PromptValue) Values ('UpdateTime', dbo.fnTranslate(@LangId, 34654, 'Update Time'))
Insert into @Prompts (PromptName, PromptValue) Values ('UpdateUser', dbo.fnTranslate(@LangId, 34655, 'Update User'))
Insert into @Prompts (PromptName, PromptValue) Values ('Timestamp', dbo.fnTranslate(@LangId, 34897, 'Timestamp'))
Insert into @Prompts (PromptName, PromptValue) Values ('ProductionEvent', @ProductionEventName)
Insert into @Prompts (PromptName, PromptValue) Values ('Type', dbo.fnTranslate(@LangId, 34898, 'Type'))
Insert into @Prompts (PromptName, PromptValue) Values ('Amount', dbo.fnTranslate(@LangId, 34899, 'Amount'))
Insert into @Prompts (PromptName, PromptValue) Values ('EnteredIn', dbo.fnTranslate(@LangId, 34900, 'Entered In'))
Insert into @Prompts (PromptName, PromptValue) Values ('Location', dbo.fnTranslate(@LangId, 34892, 'Location'))
Insert into @Prompts (PromptName, PromptValue) Values ('Fault', dbo.fnTranslate(@LangId, 34893, 'Fault'))
Insert into @Prompts (PromptName, PromptValue) Values ('Cause1', @CauseLevel1Name)
Insert into @Prompts (PromptName, PromptValue) Values ('Cause2', @CauseLevel2Name)
Insert into @Prompts (PromptName, PromptValue) Values ('Cause3', @CauseLevel3Name)
Insert into @Prompts (PromptName, PromptValue) Values ('Cause4', @CauseLevel4Name)
Insert into @Prompts (PromptName, PromptValue) Values ('Action1', @ActionLevel1Name)
Insert into @Prompts (PromptName, PromptValue) Values ('Action2', @ActionLevel2Name)
Insert into @Prompts (PromptName, PromptValue) Values ('Action3', @ActionLevel3Name)
Insert into @Prompts (PromptName, PromptValue) Values ('Action4', @ActionLevel4Name)
Insert into @Prompts (PromptName, PromptValue) Values ('ResearchStatus', dbo.fnTranslate(@LangId, 34660, 'Research Status'))
Insert into @Prompts (PromptName, PromptValue) Values ('ResearchOpen', dbo.fnTranslate(@LangId, 34661, 'Research Open Date'))
Insert into @Prompts (PromptName, PromptValue) Values ('ResearchClosed', dbo.fnTranslate(@LangId, 34662, 'Research Close Date'))
Insert into @Prompts (PromptName, PromptValue) Values ('ResearchUser', dbo.fnTranslate(@LangId, 34663, 'Research User'))
Insert into @Prompts (PromptName, PromptValue) Values('ESigPerformer', dbo.fnTranslate(@LangId, 35145, 'E-Signature Performer'))
Insert into @Prompts (PromptName, PromptValue) Values('ESigPerformedTime', dbo.fnTranslate(@LangId, 35146, 'E-Signature Performed Time'))
Insert into @Prompts (PromptName, PromptValue) Values('ESigPerformerReason', dbo.fnTranslate(@LangId, 35147, 'E-Signature Performer Reason'))
Insert into @Prompts (PromptName, PromptValue) Values('ESigPerformerComment', dbo.fnTranslate(@LangId, 35148, 'E-Signature Performer Comment'))
Insert into @Prompts (PromptName, PromptValue) Values('ESigApprover', dbo.fnTranslate(@LangId, 35149, 'E-Signature Approver'))
Insert into @Prompts (PromptName, PromptValue) Values('ESigApprovedTime', dbo.fnTranslate(@LangId, 35150, 'E-Signature Approved Time'))
Insert into @Prompts (PromptName, PromptValue) Values('ESigApproverReason', dbo.fnTranslate(@LangId, 35151, 'E-Signature Approver Reason'))
Insert into @Prompts (PromptName, PromptValue) Values('ESigApproverComment', dbo.fnTranslate(@LangId, 35152, 'E-Signature Approver Comment'))
Insert Into @Prompts (PromptName, PromptValue) Values('Item', dbo.fnTranslate(@LangId, 34797, 'Item'))
IF @InTimeZone ='' SELECT @InTimeZone = NULL
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
From @Prompts
--**********************************************
-- Return Data For Report
--**********************************************
--Sarla Modifications in Select Clause
Select UpdateTime = case when d.Modified_On Is Null Then NULL Else  [dbo].[fnServer_CmnConvertFromDbTime](d.Modified_On,@InTimeZone) end,  
       UpdateUser = u2.Username,
 	  	  	  Item = @EventType,
       [Timestamp] = case when  d.[Timestamp] Is Null Then NULL Else  [dbo].[fnServer_CmnConvertFromDbTime]( d.[Timestamp],@InTimeZone) end,  
       ProductionEvent = e.Event_Num,
       Type = t.WET_Name,
       Amount = '{0} ' + @DimensionXUnits,
       Amount_Parameter = d.Amount,
       EnteredIn = m.WEMT_Name,
 	  	  	  Location = pu.PU_Desc, 
 	  	  	  Fault = wef.wEFault_Name,
       Cause1 = r1.event_reason_name,
       Cause2 = r2.event_reason_name,
       Cause3 = r3.event_reason_name,
       Cause4 = r3.event_reason_name,
       Action1 = a1.event_reason_name,
       Action2 = a2.event_reason_name,
       Action3 = a3.event_reason_name,
       Action4 = a4.event_reason_name,
       ResearchStatus = rs.research_status_desc,
       ResearchOpen = case when  d.Research_Open_Date Is Null Then NULL Else   [dbo].[fnServer_CmnConvertFromDbTime]( d.Research_Open_Date,@InTimeZone) end,  
       ResearchClosed = case when d.Research_Close_Date Is Null Then NULL Else  [dbo].[fnServer_CmnConvertFromDbTime](d.Research_Close_Date,@InTimeZone)  end,  
       ResearchUser = u1.Username,
 	  	  	  ESigPerformer = esig_pu.Username,
 	  	  	  ESigPerformedTime = esig.Perform_Time,
 	  	  	  ESigPerformerReason = pr.Event_Reason_Name,
 	  	  	  ESigPerformerComment = pc.Comment_Text,
 	  	  	  ESigApprover = esig_vu.Username,
 	  	  	  ESigApprovedTime = [dbo].[fnServer_CmnConvertFromDbTime](esig.Verify_Time,@InTimeZone), 
 	  	  	  ESigApproverReason = vr.Event_Reason_Name,
 	  	  	  ESigApproverComment = vc.Comment_Text
  From Waste_Event_Detail_History d
  Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.reason_level1
  Left Outer Join Event_Reasons r2 on r2.event_reason_id = d.reason_level2
  Left Outer Join Event_Reasons r3 on r3.event_reason_id = d.reason_level3
  Left Outer Join Event_Reasons r4 on r4.event_reason_id = d.reason_level4
  Left Outer Join Event_Reasons a1 on a1.event_reason_id = d.action_level1
  Left Outer Join Event_Reasons a2 on a1.event_reason_id = d.action_level2
  Left Outer Join Event_Reasons a3 on a1.event_reason_id = d.action_level3
  Left Outer Join Event_Reasons a4 on a1.event_reason_id = d.action_level4
  Left Outer Join Waste_Event_Fault wef on wef.wefault_id = d.wefault_id
  Left Outer Join Prod_Units pu on pu.pu_id = d.source_pu_id
  Left outer Join Users u1 on u1.user_id = d.research_user_id
  Left outer Join Users u2 on u2.user_id = d.user_id
  left outer join research_status rs on rs.research_status_Id = d.research_status_id
  Left outer Join events e on e.event_id = d.event_id
  Left outer join waste_event_type t on t.wet_id = d.wet_id
  Left outer join waste_event_meas m on m.wemt_id = d.wemt_id
 	 left outer join esignature esig on d.Signature_Id = esig.Signature_Id
 	 left outer join users esig_pu on esig.Perform_User_Id = esig_pu.user_id
 	 left outer join users esig_vu on esig.Verify_User_Id = esig_vu.user_id
 	 left outer join event_reasons pr On esig.Perform_Reason_Id = pr.Event_Reason_Id
 	 left outer join event_reasons vr On esig.Verify_Reason_Id = vr.Event_Reason_Id
 	 left outer join Comments pc On esig.Perform_Comment_Id = pc.Comment_Id
 	 left outer join Comments vc On esig.Verify_Comment_Id = vc.Comment_Id
  Where WED_Id = @EventId
  Order By d.Modified_On ASC
