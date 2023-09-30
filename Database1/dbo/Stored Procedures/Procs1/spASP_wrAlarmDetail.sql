CREATE PROCEDURE [dbo].[spASP_wrAlarmDetail]
  @EventId int,
  @Command int  = NULL,
  @InTimeZone nvarchar(200) =NULL
AS
--TODO: Get n and m in SPC Rule formula
--TODO: ?? Display Categories ??
set arithignore on
set arithabort off
set ansi_warnings off
set nocount on
/*********************************************
spASP_wrAlarmDetail 3
-- For Testing
--*********************************************
Select @EventId = 5 --5 --8 
Select @Command =  NULL --3
--**********************************************/
Declare @ReportName nvarchar(255)
Declare @CriteriaString nVarChar(1000)
Declare @Unit int
Declare @AlarmName nVarChar(100)
Declare @AlarmType int
Declare @AlarmTemplate int
Declare @AlarmRule int
Declare @AlarmRuleText nvarchar(255)
Declare @Key int
Declare @CauseTree int
Declare @ActionTree int
Declare @EventDescription nVarChar(1000)
Declare @StartTime datetime
Declare @EndTime datetime
Declare @TrendStart datetime
Declare @TrendEnd datetime
Declare @Duration int
Declare @Uptime real
Declare @Acked int
Declare @AckedBy nVarChar(100)
Declare @AckedOn datetime
Declare @Cause1 nVarChar(100)
Declare @Cause2 nVarChar(100)
Declare @Cause3 nVarChar(100)
Declare @Cause4 nVarChar(100)
Declare @CauseCommentId int
Declare @Action1 nVarChar(100)
Declare @Action2 nVarChar(100)
Declare @Action3 nVarChar(100)
Declare @Action4 nVarChar(100)
Declare @ActionCommentId int
Declare @ResearchStatus nvarchar(25)
Declare @ResearchOpen datetime
Declare @ResearchClosed datetime
Declare @ResearchUser nVarChar(100)
Declare @ResearchCommentId int
Declare @UpdatedBy nVarChar(100)
Declare @UpdatedTime datetime
Declare @StartResult nvarchar(25)
Declare @MinResult nvarchar(25)
Declare @MaxResult nvarchar(25)
Declare @EndResult nvarchar(25)
Declare @NumberOfUpdates int
Declare @ProductId int
Declare @ProductCode nVarChar(50)
Declare @LastTime datetime
Declare @Level1Name nvarchar(25)
Declare @Level2Name nvarchar(25)
Declare @Level3Name nvarchar(25)
Declare @Level4Name nvarchar(25)
--**********************************************
-- Translations Setup & Common Prompt Lookup
--**********************************************
-- Retreive the Language Id of the current user
Declare @LangId INT
EXEC spWA_GetCurrentUserInfo @LangId = @LangId OUTPUT
-- Get Common Prompts
DECLARE @sUnspecified nVarChar(100)
SET @sUnspecified = dbo.fnTranslate(@LangId, 34519, '<Unspecified>')
--**********************************************
--**********************************************
-- Loookup Initial Information For This Event
--**********************************************
If @EventId Is Null
  Begin
    Raiserror('A Base EventId Must Be Supplied',16,1)
    Return
  End
If @Command Is Not Null
  Begin
 	  	 Select @Key = Key_Id, @StartTime = Start_Time, @AlarmType = Alarm_Type_Id
 	  	   From Alarms 
 	  	   Where Alarm_Id = @EventId 
   	 Select @EventId = NULL
  End
If @Command = 1
  Begin
    -- Scroll Next Event
    Select @EventId = Alarm_Id 
      From Alarms
      Where Key_Id = @Key and 
            Alarm_Type_id = @AlarmType and
            Start_Time = (Select Min(Start_Time) From Alarms Where Key_Id = @Key and Alarm_Type_Id = @AlarmType and Start_Time > @StartTime)
  End
Else If @Command = 2
  Begin
    -- Scroll Previous Event
    Select @EventId = Alarm_Id 
      From Alarms
      Where Key_Id = @Key and 
            Alarm_Type_Id = @AlarmType and
            Start_Time = (Select Max(Start_Time) From Alarms Where Key_Id = @Key and Alarm_Type_Id = @AlarmType and Start_Time < @StartTime)
  End
--Else This is Just A Straight Query
If @EventId Is Null
  Begin
    Raiserror('Command Did Not Find Event To Return',16,1)
    Return
  End
-- Get Event Information
Select @EventDescription = d.Alarm_Desc,
       @Key = d.Key_Id, @AlarmType = d.Alarm_Type_Id, @AlarmTemplate = d.ATD_Id, @AlarmRule = d.ATSRD_Id,
       @StartTime = d.start_time, 
 	    @EndTime = d.end_time, 
       @Duration = datediff(second,d.start_time, coalesce(d.end_time, dbo.fnServer_CmnGetDate(getutcdate()))) / 60.0,
       @Cause1 = coalesce(r1.event_reason_name, @sUnspecified),
       @Cause2 = r2.event_reason_name,
       @Cause3 = r3.event_reason_name,
       @Cause4 = r3.event_reason_name,
       @CauseCommentId = d.Cause_Comment_Id,
       @Action1 = coalesce(a1.event_reason_name, @sUnspecified),
       @Action2 = a2.event_reason_name,
       @Action3 = a3.event_reason_name,
       @Action4 = a4.event_reason_name,
       @ActionCommentId = d.action_Comment_Id,
       @ResearchStatus = rs.research_status_desc,
       @ResearchOpen = d.Research_Open_Date,
       @ResearchClosed = d.Research_Close_Date,
       @ResearchUser = u1.Username,
       @ResearchCommentId = d.Research_Comment_Id,
       @Acked = d.Ack,
       @AckedBy = u2.Username,
       @AckedOn = d.Ack_On,
       @UpdatedBy = u3.Username,
       @UpdatedTime = d.Modified_on,
       @StartResult = d.Start_Result,
       @MinResult = convert(nvarchar(25),d.Min_Result),
       @MaxResult = convert(nvarchar(25),d.Max_Result),
       @EndResult = convert(nvarchar(25),d.End_Result)
  From Alarms d
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
  Where d.Alarm_id = @EventId
If @AlarmType = 1
  Select @AlarmName = Var_Desc + ' ' + dbo.fnTranslate(@LangId, 34596, 'Limit Alarm')
   From Variables
   Where Var_Id = @Key
Else If @AlarmType = 2
  Select @AlarmName = Var_Desc + ' ' + dbo.fnTranslate(@LangId, 34597, 'SPC Alarm')
   From Variables
   Where Var_Id = @Key
Else If @AlarmType = 4
  Select @AlarmName = Var_Desc + ' ' + dbo.fnTranslate(@LangId, 35128, 'SPC Group Alarm')
   From Variables
   Where Var_Id = @Key
Else
  Select @AlarmName = PU_Desc + ' ' + dbo.fnTranslate(@LangId, 34598, 'Production Alarm')
   From Prod_Units
   Where PU_Id = @Key
If @AlarmType in (1,2,4)
  Select @Unit = coalesce(pu.Master_Unit, pu.PU_id)
    From Variables v
    Join prod_units pu on pu.pu_id = v.pu_id
    Where v.Var_Id = @Key
Else
  Select @Unit = @Key
Select @ReportName = dbo.fnTranslate(@LangId, 34642, 'Alarm Detail')
Select @TrendStart = dateadd(minute,-3 * @Duration, @StartTime)
If @EndTime is Null
  Select @TrendEnd = dbo.fnServer_CmnGetDate(getutcdate())
Else
  Select @TrendEnd = dateadd(minute,1 * @Duration, @EndTime)
--**********************************************
-- Return Header Information
--**********************************************
-- Line1: Report Name
-- Line2: Criteria
-- Line3: Generate Time
-- Line4 - n: Column Names
Create Table #Prompts (
  PromptId int identity(1,1),
  PromptName nvarchar(20),
  PromptValue nvarchar(1000),
  PromptValue_Parameter SQL_Variant
)
Insert into #Prompts (PromptName, PromptValue) Values ('ReportName', @ReportName)
Insert into #Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('Criteria', dbo.fnTranslate(@LangId, 34599, 'For {0}'), @AlarmName)
Insert into #Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('GenerateTime', dbo.fnTranslate(@LangId, 34521, 'Created: {0}'), [dbo].[fnServer_CmnConvertFromDbTime](dbo.fnServer_CmnGetDate(getutcdate()), @InTimeZone))
Insert into #Prompts (PromptName, PromptValue) Values ('EventInformation', dbo.fnTranslate(@LangId, 34600, 'Event Information'))
Insert into #Prompts (PromptName, PromptValue) Values ('ElectronicSignature', dbo.fnTranslate(@LangId, 34695, 'Electronic Signature'))
Insert into #Prompts (PromptName, PromptValue) Values ('CauseInformation', dbo.fnTranslate(@LangId, 34601, 'Cause Information'))
Insert into #Prompts (PromptName, PromptValue) Values ('CauseComments', dbo.fnTranslate(@LangId, 34602, 'Cause Comments'))
Insert into #Prompts (PromptName, PromptValue) Values ('ActionInformation', dbo.fnTranslate(@LangId, 34603, 'Action Information'))
Insert into #Prompts (PromptName, PromptValue) Values ('Action Comments', dbo.fnTranslate(@LangId, 34604, 'ActionComments'))
Insert into #Prompts (PromptName, PromptValue) Values ('AlarmStatistics', dbo.fnTranslate(@LangId, 34605, 'Alarm Statistics'))
Insert into #Prompts (PromptName, PromptValue) Values ('ResearchInformation', dbo.fnTranslate(@LangId, 34606, 'NCR Research'))
Insert into #Prompts (PromptName, PromptValue) Values ('ResearchComments', dbo.fnTranslate(@LangId, 34607, 'Research Comments'))
Insert into #Prompts (PromptName, PromptValue) Values ('GotoPrevious', dbo.fnTranslate(@LangId, 34608, 'Goto Previous Alarm'))
Insert into #Prompts (PromptName, PromptValue) Values ('GotoNext', dbo.fnTranslate(@LangId, 34609, 'Goto Next Alarm'))
Insert into #Prompts (PromptName, PromptValue) Values ('ViewAudit', dbo.fnTranslate(@LangId, 34610, 'View Audit Trail'))
Insert into #Prompts (PromptName, PromptValue) Values ('ViewTimeline', dbo.fnTranslate(@LangId, 34611, 'View Timeline'))
Insert into #Prompts (PromptName, PromptValue) Values ('TrendLong', dbo.fnTranslate(@LangId, 34612, 'Trend Long Term'))
Insert into #Prompts (PromptName, PromptValue) Values ('TrendShort', dbo.fnTranslate(@LangId, 34613, 'Trend Short Term'))
Insert into #Prompts (PromptName, PromptValue) Values ('EventId', convert(nvarchar(15), @EventId))
Insert into #Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('StartTime', '{0}',[dbo].[fnServer_CmnConvertFromDbTime] (@StartTime, @InTimeZone))
Insert into #Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('EndTime', '{0}', coalesce([dbo].[fnServer_CmnConvertFromDbTime](@EndTime,@InTimeZone),[dbo].[fnServer_CmnConvertFromDbTime](dbo.fnServer_CmnGetDate(getutcdate()),@InTimeZone)))
Insert into #Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('TrendStart', '{0}', [dbo].[fnServer_CmnConvertFromDbTime](@TrendStart,@InTimeZone))
Insert into #Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('TrendEnd', '{0}', [dbo].[fnServer_CmnConvertFromDbTime](@TrendEnd,@InTimeZone))
Insert into #Prompts (PromptName, PromptValue) Values ('VariableId', convert(nvarchar(30), @Key))
Insert into #Prompts (PromptName, PromptValue) Values ('UnitId', convert(nvarchar(30), @Unit))
--select PromptId,PromptName,PromptValue,'PromptValue_Parameter'= case when (ISDATE(Convert(varchar,PromptValue_Parameter))=1)
-- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
-- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,PromptValue_Parameter),@InTimeZone)
-- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
-- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 PromptValue_Parameter
-- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end
--From #Prompts
Select * from #Prompts
Drop Table #Prompts
--**********************************************
-- Return Data For Report
--**********************************************
-- Get Product
Select @ProductId = Prod_Id 
  From Production_Starts 
  Where PU_Id = @Unit and 
          Start_Time <= @StartTime and
          ((End_Time > @StartTime) or (End_Time Is Null)) 
Select @ProductCode = Prod_Code From Products Where Prod_Id = @ProductId 
-- Check History
Select @NumberOfUpdates = count(modified_on) - 1 
  From Alarm_history 
  where Alarm_Id = @EventId
-- Figure Out Uptime
Select @LastTime = coalesce(End_Time, dbo.fnServer_CmnGetDate(getutcdate()))
  From Alarms 
  Where Key_Id = @Key and 
        Alarm_Type_id = @AlarmType and
        Start_Time = (Select Max(Start_Time) From Alarms Where Key_Id = @Key and Alarm_Type_Id = @AlarmType and Start_Time < @StartTime)
Select @Uptime = datediff(second,@LastTime, @StartTime) / 60.0
-- Get Cause and Action Trees
If @AlarmType in (1,2,4)
  Begin
 	  	 Select @AlarmTemplate = AT_Id
 	  	   From Alarm_Template_Var_Data
      Where ATD_Id = @AlarmTemplate
    Select @CauseTree = Cause_Tree_id,
           @ActionTree = Action_Tree_Id 
      From Alarm_Templates
      Where AT_Id = @AlarmTemplate
  End
If @AlarmRule Is Not Null
  Select @AlarmRuleText = r.Alarm_SPC_Rule_Desc
    From alarm_template_spc_rule_data rd
    Join alarm_spc_rules r on r.Alarm_SPC_Rule_Id = rd.Alarm_SPC_Rule_Id
    Where rd.ATSRD_Id = @AlarmRule 
-- Create Simple Return Table
Create Table #Report (
  Id int identity(1,1),
  Name nvarchar(50),
  Value nvarchar(255) NULL,
  Value_Parameter SQL_Variant,
  Value_Parameter2 SQL_Variant,
  Hyperlink nvarchar(255) NULL,
 	 Tag Int NULL
)
--********************************************************************************
-- Return Basic Event Information
--********************************************************************************
Truncate Table #Report
Insert Into #Report (Name, Value) Values (dbo.fnTranslate(@LangId, 34614, 'Description'), @EventDescription)
If @AlarmRuleText is Not Null
  Insert Into #Report (Name, Value) Values (dbo.fnTranslate(@LangId, 34615, 'Rule'), @AlarmRuleText)
Insert Into #Report (Name, Value, Value_Parameter) Values (dbo.fnTranslate(@LangId, 34011, 'Start Time'), '{0}', [dbo].[fnServer_CmnConvertFromDbTime](@StartTime,@InTimeZone))
IF @EndTime IS NULL
 	 Insert Into #Report (Name, Value) Values (dbo.fnTranslate(@LangId, 34012, 'End Time'), dbo.fnTranslate(@LangId, 34616, 'OPEN'))
ELSE
 	 Insert Into #Report (Name, Value, Value_Parameter) Values (dbo.fnTranslate(@LangId, 34012, 'End Time'), '{0}', [dbo].[fnServer_CmnConvertFromDbTime](@EndTime,@InTimeZone))
Insert Into #Report (Name, Value, Value_Parameter)
  Values(dbo.fnTranslate(@LangId, 34617, 'Alarm Duration'), dbo.fnTranslate(@LangId, 34618, '{0} Minutes'), @Duration)
If @Uptime is Not Null
  Insert Into #Report (Name, Value, Value_Parameter)
    Values(dbo.fnTranslate(@LangId, 34619, 'Time From Last Alarm'), dbo.fnTranslate(@LangId, 34618, '{0} Minutes'), @Uptime)
Insert Into #Report (Name, Value) Values (dbo.fnTranslate(@LangId, 34620, 'Initial Product'), @ProductCode)
If @Acked = 1
  Insert Into #Report (Name, Value, Value_Parameter) Values (dbo.fnTranslate(@LangId, 34621, 'Acknowledgement'), @AckedBy + ' {0}', @AckedOn)
Else
  Insert Into #Report (Name, Value) Values (dbo.fnTranslate(@LangId, 34621, 'Acknowledgement'), dbo.fnTranslate(@LangId, 34622, 'NONE'))
If @NumberOfUpdates > 0 
  Begin
 	   Insert Into #Report ([Name], Value, Value_Parameter, Value_Parameter2)
            Values(dbo.fnTranslate(@LangId, 34623, 'Updated By'), '{0} ({1})', @UpdatedBy, [dbo].[fnServer_CmnConvertFromDbTime](@UpdatedTime,@InTimeZone)  )
 	   Insert Into #Report ([Name], Value, Hyperlink)
            Values(dbo.fnTranslate(@LangId, 34625, 'Number Of Updates'), convert(nvarchar(15),@NumberOfUpdates) , 'Javascript:ShowWindow("AuditTrail/AlarmAuditTrail.aspx?Id=' + convert(nvarchar(15),@EventId) + '&TargetTimeZone=' + replace(@InTimeZone,' ','+') + '" ,400,750);')
  End
Else
  Begin
 	   Insert Into #Report ([Name], Value, Value_Parameter, Value_Parameter2)
            Values(dbo.fnTranslate(@LangId, 34624, 'Added By'), '{0} ({1})', @UpdatedBy,  [dbo].[fnServer_CmnConvertFromDbTime](@UpdatedTime,@InTimeZone))
  End
 --Select Id,  [Name], [Value], 'Value_Parameter'= case when (ISDATE(Convert(varchar,Value_Parameter))=1)
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,Value_Parameter),@InTimeZone)
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Value_Parameter
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end,
 	 -- 	  	  	  	  	  	  	 'Value_Parameter2 '= case when (ISDATE(Convert(varchar,Value_Parameter2 ))=1)
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,Value_Parameter2),@InTimeZone)
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Value_Parameter2
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end,
 	 -- 	  	  	  	  	  	  	  Hyperlink , 	 Tag  from #Report Order By Id
 	 
SELECT * FROM #Report Order By Id
 --********************************************************************************
--********************************************************************************
-- Return Cause Information
--********************************************************************************
Truncate Table #Report
If @CauseTree Is Not Null
  Begin
 	  	 Select @Level1Name = level_name
 	  	   From event_reason_level_headers 
 	  	   Where Tree_Name_id = @CauseTree and
 	  	         Reason_Level = 1
 	  	 
 	  	 If @Level1Name Is Not Null 
 	  	  	 Select @Level2Name = level_name
 	  	  	   From event_reason_level_headers 
 	  	  	   Where Tree_Name_id = @CauseTree and
 	  	  	         Reason_Level = 2
 	  	 
 	  	 If @Level2Name Is Not Null 
 	  	  	 Select @Level3Name = level_name
 	  	  	   From event_reason_level_headers 
 	  	  	   Where Tree_Name_id = @CauseTree and
 	  	  	         Reason_Level = 3
 	  	 
 	  	 If @Level3Name Is Not Null 
 	  	  	 Select @Level4Name = level_name
 	  	  	   From event_reason_level_headers 
 	  	  	   Where Tree_Name_id = @CauseTree and
 	  	  	         Reason_Level = 4
  End
Insert Into #Report (Name, Value) Values (coalesce(@Level1Name, dbo.fnTranslate(@LangId, 34626, 'Cause 1')), @Cause1)
If @Cause2 Is Not Null
  Insert Into #Report (Name, Value) Values (coalesce(@Level2Name, dbo.fnTranslate(@LangId, 34627, 'Cause 2')), @Cause2)
If @Cause3 Is Not Null
  Insert Into #Report (Name, Value) Values (coalesce(@Level3Name, dbo.fnTranslate(@LangId, 34628, 'Cause 3')), @Cause3)
If @Cause4 Is Not Null
  Insert Into #Report (Name, Value) Values (coalesce(@Level4Name, dbo.fnTranslate(@LangId, 34629, 'Cause 4')), @Cause4)
 --Select Id,  [Name], [Value], 'Value_Parameter'= case when (ISDATE(Convert(varchar,Value_Parameter))=1)
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,Value_Parameter),@InTimeZone)
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Value_Parameter
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end,
 	 -- 	  	  	  	  	  	  	 'Value_Parameter2 '= case when (ISDATE(Convert(varchar,Value_Parameter2 ))=1)
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,Value_Parameter2),@InTimeZone)
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Value_Parameter2
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end,
 	 -- 	  	  	  	  	  	  	  Hyperlink , 	 Tag  from #Report Order By Id
 SELECT * FROM #Report order by Id
--********************************************************************************
--********************************************************************************
-- Return Cause Comments
--********************************************************************************
Select Username = u.Username, Timestamp = c.Modified_On, Comment = c.Comment_Text
  From Comments c
  Join Users u on u.user_id = c.User_id 
  Where c.Comment_Id = @CauseCommentId
--********************************************************************************
--********************************************************************************
-- Return Action Information
--********************************************************************************
Truncate Table #Report
Select @Level1Name = NULL
Select @Level2Name = NULL
Select @Level3Name = NULL
Select @Level4Name = NULL
If @ActionTree Is Not Null
  Begin
 	  	 Select @Level1Name = level_name
 	  	   From event_reason_level_headers 
 	  	   Where Tree_Name_id = @ActionTree and
 	  	         Reason_Level = 1
 	  	 
 	  	 If @Level1Name Is Not Null 
 	  	  	 Select @Level2Name = level_name
 	  	  	   From event_reason_level_headers 
 	  	  	   Where Tree_Name_id = @ActionTree and
 	  	  	         Reason_Level = 2
 	  	 
 	  	 If @Level2Name Is Not Null 
 	  	  	 Select @Level3Name = level_name
 	  	  	   From event_reason_level_headers 
 	  	  	   Where Tree_Name_id = @ActionTree and
 	  	  	         Reason_Level = 3
 	  	 
 	  	 If @Level3Name Is Not Null 
 	  	  	 Select @Level4Name = level_name
 	  	  	   From event_reason_level_headers 
 	  	  	   Where Tree_Name_id = @ActionTree and
 	  	  	         Reason_Level = 4
 	 End
Insert Into #Report (Name, Value) Values (coalesce(@Level1Name, dbo.fnTranslate(@LangId, 34630, 'Action 1')), @Action1)
If @Action2 Is Not Null
  Insert Into #Report (Name, Value) Values (coalesce(@Level2Name, dbo.fnTranslate(@LangId, 34631, 'Action 2')), @Action2)
If @Action3 Is Not Null
  Insert Into #Report (Name, Value) Values (coalesce(@Level3Name, dbo.fnTranslate(@LangId, 34632, 'Action 3')), @Action3)
If @Action4 Is Not Null
  Insert Into #Report (Name, Value) Values (coalesce(@Level4Name, dbo.fnTranslate(@LangId, 34633, 'Action 4')), @Action4)
 --Select Id,  [Name], [Value], 'Value_Parameter'= case when (ISDATE(Convert(varchar,Value_Parameter))=1)
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,Value_Parameter),@InTimeZone)
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Value_Parameter
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end,
 	 -- 	  	  	  	  	  	  	 'Value_Parameter2 '= case when (ISDATE(Convert(varchar,Value_Parameter2 ))=1)
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,Value_Parameter2),@InTimeZone)
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Value_Parameter2
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end,
 	 -- 	  	  	  	  	  	  	  Hyperlink , 	 Tag  from #Report Order By Id
SELECT * FROM #Report Order By Id
--********************************************************************************
--********************************************************************************
-- Return Action Comments
--********************************************************************************
Select Username = u.Username, Timestamp =   [dbo].[fnServer_CmnConvertFromDbTime] (c.Modified_On,@InTimeZone) , Comment = c.Comment_Text
  From Comments c
  Join Users u on u.user_id = c.User_id 
  Where c.Comment_Id = @ActionCommentId
--********************************************************************************
--********************************************************************************
-- Return Research Information
--********************************************************************************
Truncate Table #Report
If @ResearchOpen Is Not Null
  Begin
 	  	 Insert Into #Report (Name, Value) Values (dbo.fnTranslate(@LangId, 34634, 'Assigned To'), @ResearchUser)
 	  	 Insert Into #Report (Name, Value) Values (dbo.fnTranslate(@LangId, 34635, 'Status'), @ResearchStatus)
 	  	 Insert Into #Report (Name, Value, Value_Parameter) Values (dbo.fnTranslate(@LangId, 34636, 'Opened On'), '{0}',[dbo].[fnServer_CmnConvertFromDbTime](@ResearchOpen,@InTimeZone))
    If @ResearchClosed Is Not Null
   	  	 Insert Into #Report (Name, Value, Value_Parameter) Values (dbo.fnTranslate(@LangId, 34636, 'Closed On'), '{0}', [dbo].[fnServer_CmnConvertFromDbTime](@ResearchClosed,@InTimeZone) )
    Else
   	  	 Insert Into #Report (Name, Value) Values (dbo.fnTranslate(@LangId, 34637, 'Closed On'), dbo.fnTranslate(@LangId, 34616, 'OPEN'))
  End
 --Select Id,  [Name], [Value], 'Value_Parameter'= case when (ISDATE(Convert(varchar,Value_Parameter))=1)
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,Value_Parameter),@InTimeZone)
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Value_Parameter
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end,
 	 -- 	  	  	  	  	  	  	 'Value_Parameter2 '= case when (ISDATE(Convert(varchar,Value_Parameter2 ))=1)
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,Value_Parameter2),@InTimeZone)
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Value_Parameter2
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end,
 	 -- 	  	  	  	  	  	  	  Hyperlink , 	 Tag  from #Report Order By Id
 SELECT * FROM #Report Order By Id
--********************************************************************************
--********************************************************************************
-- Return Research Comments
--********************************************************************************
Select Username = u.Username, Timestamp =   [dbo].[fnServer_CmnConvertFromDbTime] (c.Modified_On,@InTimeZone)  , Comment = c.Comment_Text
  From Comments c
  Join Users u on u.user_id = c.User_id 
  Where c.Comment_Id = @ResearchCommentId
--********************************************************************************
--********************************************************************************
-- Return Alarm Statistics
--********************************************************************************
Truncate Table #Report
IF IsNumeric(@StartResult) = 1
 	 Insert Into #Report([Name], Value, Value_Parameter) Values(dbo.fnTranslate(@LangId, 34638, 'Start Value'), '{0}', CAST(@StartResult AS Float))
ELSE If @StartResult Is Not Null
 	 Insert Into #Report ([Name], Value) Values (dbo.fnTranslate(@LangId, 34638, 'Start Value'), @StartResult)
IF IsNumeric(@MinResult) = 1
 	 Insert Into #Report ([Name], Value, Value_Parameter) Values (dbo.fnTranslate(@LangId, 34639, 'Min Value'), '{0}', CAST(@MinResult AS Float))
ELSE If @MinResult Is Not Null
 	 Insert Into #Report ([Name], Value) Values (dbo.fnTranslate(@LangId, 34639, 'Min Value'), @MinResult)
IF IsNumeric(@MaxResult) = 1
 	 Insert Into #Report ([Name], Value, Value_Parameter) Values (dbo.fnTranslate(@LangId, 34640, 'Max Value'), '{0}', CAST(@MaxResult AS Float))
ELSE If @MaxResult Is Not Null
 	 Insert Into #Report ([Name], Value) Values (dbo.fnTranslate(@LangId, 34640, 'Max Value'), @MaxResult)
IF IsNumeric(@EndResult) = 1
 	 Insert Into #Report ([Name], Value, Value_Parameter) Values (dbo.fnTranslate(@LangId, 34641, 'End Value'), '{0}', CAST(@EndResult AS Float))
ELSE If @EndResult Is Not Null
 	 Insert Into #Report ([Name], Value) Values (dbo.fnTranslate(@LangId, 34641, 'End Value'), @EndResult)
 --Select Id,  [Name], [Value], 'Value_Parameter'= case when (ISDATE(Convert(varchar,Value_Parameter))=1)
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,Value_Parameter),@InTimeZone)
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Value_Parameter
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end,
 	 -- 	  	  	  	  	  	  	 'Value_Parameter2 '= case when (ISDATE(Convert(varchar,Value_Parameter2 ))=1)
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,Value_Parameter2),@InTimeZone)
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Value_Parameter2
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end,
 	 -- 	  	  	  	  	  	  	  Hyperlink , 	 Tag  from #Report Order By Id
 SELECT * FROM #Report Order By Id
--********************************************************************************
--********************************************************************************
-- Return Trend
--********************************************************************************
Declare @AlarmTrendData Table(
 	 [Timestamp] DateTime,
 	 Value SQL_Variant,
 	 LRL SQL_Variant,
 	 LWL SQL_Variant,
 	 TGT SQL_Variant,
 	 UWL SQL_Variant,
 	 URL SQL_Variant )
If @AlarmType in (1,2,4)
  Begin
 	  	 Insert Into @AlarmTrendData
 	  	  	 Select [Timestamp] = t.Result_On,
           Value = dbo.fnDisplayVarcharValue(Null, t.Result),
           LRL = dbo.fnDisplayVarcharValue(Null, vs.L_Reject),
           LWL = dbo.fnDisplayVarcharValue(Null, vs.L_Warning),
           TGT = dbo.fnDisplayVarcharValue(Null, vs.Target),
           UWL = dbo.fnDisplayVarcharValue(Null, vs.U_Warning),
           URL = dbo.fnDisplayVarcharValue(Null, vs.U_Reject)
      From Tests t
      Join Production_Starts ps on ps.PU_id = @Unit and ps.Start_Time <= t.Result_On and ((ps.End_Time > t.Result_On) or (ps.End_Time Is Null))
      left outer Join var_specs vs on vs.Var_id = @key and vs.prod_id = ps.prod_id and vs.effective_date <= t.Result_On and ((vs.expiration_date > t.Result_On) or (vs.expiration_date Is Null))
      Where t.var_id = @Key and 
            t.Result_On Between @TrendStart and @TrendEnd
      Order by Timestamp
  End
--Sarla
--Select * From @AlarmTrendData
Select   [dbo].[fnServer_CmnConvertFromDbTime] ([Timestamp],@InTimeZone) [Timestamp] ,
 	 [Value],
 	 LRL,
 	 LWL, 
 	 TGT, 
 	 UWL,
 	 URL 
From @AlarmTrendData
--Sarla
--********************************************************************************
--********************************************************************************
-- Return Electronic Signature Information
--********************************************************************************
Print 'Electronic Signature Information'
Truncate Table #Report
Declare @ESigId Int
Select @ESigId = Signature_Id
From Alarms
Where Alarm_Id = @EventId
If @ESigId Is Not Null
Begin
 	 Insert Into #Report (Name, Value, Value_Parameter) 
 	  	 Select dbo.fnTranslate(@LangId, 34688, 'User'), Value = u.Username + ' ({0})', Value_Parameter = esig.Perform_Time
 	  	 From ESignature esig
 	  	 Join Users u On esig.Perform_User_Id = u.User_Id
 	  	 Where esig.Signature_Id = @ESigId
 	 Insert Into #Report (Name, Value) 
 	  	 Select dbo.fnTranslate(@LangId, 35136, 'User Reason'), Value = r.Event_Reason_Name 
 	  	 From ESignature esig
 	  	 Join Event_Reasons r On esig.Perform_Reason_Id = r.Event_Reason_Id
 	  	 Where esig.Signature_Id = @ESigId
 	 Insert Into #Report (Name, Value, Tag) 
 	  	 Select dbo.fnTranslate(@LangId, 35137, 'User Comment'), Value = c.Comment_Text, c.Comment_Id
 	  	 From ESignature esig
 	  	 Join Comments c On esig.Perform_Comment_Id = c.Comment_Id
 	  	 Where esig.Signature_Id = @ESigId
 	 Insert Into #Report (Name, Value, Value_Parameter) 
 	  	 Select dbo.fnTranslate(@LangId, 35138, 'Approver'), Value = u.Username + ' ({0})', Value_Parameter = esig.Verify_Time 
 	  	 From ESignature esig
 	  	 Join Users u On esig.Verify_User_Id = u.User_Id
 	  	 Where esig.Signature_Id = @ESigId
 	 Insert Into #Report (Name, Value) 
 	  	 Select dbo.fnTranslate(@LangId, 35139, 'Approver Reason'), Value = r.Event_Reason_Name 
 	  	 From ESignature esig
 	  	 Join Event_Reasons r On esig.Verify_Reason_Id = r.Event_Reason_Id
 	  	 Where esig.Signature_Id = @ESigId
 	 Insert Into #Report (Name, Value, Tag) 
 	  	 Select dbo.fnTranslate(@LangId, 35140, 'Approver Comment'), Value = c.Comment_Text, c.Comment_Id
 	  	 From ESignature esig
 	  	 Join Comments c On esig.Verify_Comment_Id = c.Comment_Id
 	  	 Where esig.Signature_Id = @ESigId
End
  --Select Id,  [Name], [Value], 'Value_Parameter'= case when (ISDATE(Convert(varchar,Value_Parameter))=1)
 	  	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,Value_Parameter),@InTimeZone)
 	  	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Value_Parameter
 	  	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	 end,
 	  	 -- 	  	  	  	  	  	 'Value_Parameter2 '= case when (ISDATE(Convert(varchar,Value_Parameter2 ))=1)
 	  	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,Value_Parameter2),@InTimeZone)
 	  	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Value_Parameter2
 	  	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	 end,
 	  	 -- 	  	  	  	  	  	  Hyperlink , 	 Tag  from #Report Order By Id
 	  	 
  SELECT * FROM #Report Order By Id
--********************************************************************************
Drop Table #Report
set nocount off
