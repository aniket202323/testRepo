CREATE procedure [dbo].[spASP_wrTestDetail]
--Declare 
@TestId BigInt,
@InTimeZone nvarchar(200)=NULL
AS
Declare @SpecificationSetting int  -- For Specification Comparisons
Select @SpecificationSetting = convert(int,value) From Site_Parameters Where Parm_id = 13
If @SpecificationSetting is Null Select @SpecificationSetting = 1
/*********************************************
-- For Testing
--*********************************************
Select @TestId = 143523
--**********************************************/
Declare @ReportName nvarchar(255)
Declare @CriteriaString nVarChar(1000)
Declare @Timestamp datetime
Declare @Value nvarchar(25)
Declare @Status nvarchar(20)
Declare @EnteredOn datetime
Declare @EnteredBy nVarChar(100)
Declare @VariableId int
Declare @CommentId int
Declare @Unit int
Declare @IsEventBased int
Declare @IsNumeric int
Declare @SpecificationId int
Declare @VariableName nVarChar(100)
Declare @EngineeringUnits nvarchar(25)
DEclare @Alias nVarChar(100)
Declare @UnitName nVarChar(100)
Declare @SpecificationName nVarChar(100)
Declare @EventId int
Declare @EventName nVarChar(50)
Declare @EventType nVarChar(50)
Declare @ProductId int
Declare @ProductCode nVarChar(50)
Declare @ProductDescription nVarChar(100)
Declare @HasSpecification int
Declare @UpperEntry nvarchar(25)
Declare @UpperReject nvarchar(25)
Declare @UpperWarning nvarchar(25)
Declare @UpperUser nvarchar(25)
Declare @Target nvarchar(25)
Declare @LowerUser nvarchar(25)
Declare @LowerWarning nvarchar(25)
Declare @LowerReject nvarchar(25)
Declare @LowerEntry nvarchar(25)
Declare @TrendStart datetime
Declare @TrendEnd datetime
Declare @Validation nvarchar(25)
Declare @VirtDir nvarchar(255)
--**********************************************
-- Translations Setup & Common Prompt Lookup
--**********************************************
-- Retreive the Language Id of the current user
Declare @LangId INT
EXEC spWA_GetCurrentUserInfo @LangId = @LangId OUTPUT
-- Get Common Prompts
DECLARE @sUpperEntry nVarChar(100)
DECLARE @sLowerEntry nVarChar(100)
DECLARE @sUpperReject nVarChar(100)
DECLARE @sLowerReject nVarChar(100)
DECLARE @sUpperWarning nVarChar(100)
DECLARE @sLowerWarning nVarChar(100)
DECLARE @sUpperUser nVarChar(100)
DECLARE @sLowerUser nVarChar(100)
DECLARE @sTarget nVarChar(100)
DECLARE @sUnspecified nVarChar(100)
Declare @sReady nVarChar(100)
Declare @sScheduled nVarChar(100)
Declare @sCanceled nVarChar(100)
SET @sUpperEntry = dbo.fnTranslate(@LangId, 34825, 'Upper Entry')
SET @sLowerEntry = dbo.fnTranslate(@LangId, 34826, 'Lower Entry')
SET @sUpperReject = dbo.fnTranslate(@LangId, 34671, 'Upper Reject')
SET @sLowerReject = dbo.fnTranslate(@LangId, 34667, 'Lower Reject')
SET @sUpperWarning = dbo.fnTranslate(@LangId, 34670, 'Upper Warning')
SET @sLowerWarning = dbo.fnTranslate(@LangId, 34668, 'Lower Warning')
SET @sUpperUser = dbo.fnTranslate(@LangId, 34827, 'Upper User')
SET @sLowerUser = dbo.fnTranslate(@LangId, 34828, 'Lower User')
SET @sTarget = dbo.fnTranslate(@LangId, 34669, 'Target')
SET @sUnspecified = dbo.fnTranslate(@LangId, 34519, '<Unspecified>')
SET @sReady = dbo.fnTranslate(@LangId, 34829, 'Ready')
SET @sScheduled = dbo.fnTranslate(@LangId, 34830, 'Unscheduled')
SET @sCanceled = dbo.fnTranslate(@LangId, 34831, 'Canceled')
--**********************************************
SELECT @VirtDir = Value
FROM Site_Parameters
WHERE Parm_id = 30
If @TestId Is Null
  Begin
    Raiserror('Command Did Not Find Test To Return',16,1)
    Return
  End
-- Get Test Information
Select @Timestamp = t.result_on,
       @Value = t.Result,
 	  	  	  @Status = Case 
                   When t.Result Is Not Null Then 'Ready'
                   When t.Result Is Null and t.Canceled = 0 Then 'Scheduled'
                   Else 'Canceled'   
 	  	  	  	  	  	  	  	  End,
       @EnteredOn =  t.Entry_On,
       @EnteredBy = u.username,
       @VariableId = t.var_id,
       @CommentId = t.comment_id 
  From Tests t
  Join Users u on u.user_id = t.entry_by       
  Where t.test_id = @TestId
Select @VariableName = v.var_desc,
       @EngineeringUnits = v.eng_units,
       @Alias = v.Test_Name,
       @Unit = case when pu.master_unit is null then pu.pu_id else pu.master_unit End,
       @UnitName = pu.pu_desc,
       @IsEventBased = Case
                          When v.Event_Type = 1 Then 1
                          Else 0
                       End,  
       @IsNumeric = Case
                          When v.Data_Type_Id in (1,2,6,7) Then 1
                          Else 0
                       End,
       @SpecificationId = v.spec_id  
  From Variables v 
  Join Prod_Units pu on pu.pu_id = v.pu_id
  Where v.var_id = @VariableId
If @SpecificationId Is Not Null
  Select @SpecificationName = spec_desc
    From Specifications
    Where spec_id = @SpecificationId
If @IsEventBased = 1 
  Begin
    Select @EventId = event_id, 
           @EventName = event_num,
           @ProductId = applied_product
      From events 
      Where pu_id = @Unit and
            timestamp = @Timestamp
 	  	 Select @EventType = s.event_subtype_desc
 	  	   from event_configuration e 
 	  	   join event_subtypes s on s.Event_Subtype_Id = e.Event_Subtype_Id
 	  	   where e.pu_id = @Unit and 
 	  	         e.et_id = 1
  End
If @ProductId Is Null
  Begin
    Select @ProductId = prod_id
      From Production_Starts
      Where pu_id = @Unit and
            start_time <= @Timestamp and
            ((end_Time > @Timestamp) or (end_time is null))
  End
Select @ProductCode = prod_code,
       @ProductDescription = prod_desc
  From Products
  Where prod_Id = @ProductId
Select @HasSpecification = vs_id,
 	  	  	  @UpperEntry = l_entry,
 	  	  	  @UpperReject = u_reject,
 	  	  	  @UpperWarning = u_warning,
 	  	  	  @UpperUser = u_user,
 	  	  	  @Target = target,
 	  	  	  @LowerUser = l_user,
 	  	  	  @LowerWarning = l_warning,
 	  	  	  @LowerReject = l_reject,
 	  	  	  @LowerEntry = l_entry
  From Var_Specs 
  Where Var_id = @VariableId and
        Prod_Id = @ProductId and
        Effective_Date <= @Timestamp and
        ((Expiration_Date > @Timestamp) or (Expiration_Date Is Null))  
If @HasSpecification is Not Null
  Begin
    If @SpecificationSetting = 1 and @IsNumeric = 1 
     	  	 Select @Validation = Case
 	  	  	  	  	  	  	  	  	              When convert(real, @Value) > convert(real,coalesce(@UpperEntry,@Value)) Then @sUpperEntry
 	  	  	  	  	  	  	  	  	              When convert(real, @Value) < convert(real,coalesce(@LowerEntry,@Value)) Then @sLowerEntry
 	  	  	  	  	  	  	  	  	              When convert(real, @Value) > convert(real,coalesce(@UpperReject,@Value)) Then @sUpperReject
 	  	  	  	  	  	  	  	  	              When convert(real, @Value) < convert(real,coalesce(@LowerReject,@Value)) Then @sLowerReject
 	  	  	  	  	  	  	  	  	              When convert(real, @Value) > convert(real,coalesce(@UpperWarning,@Value)) Then @sUpperWarning
 	  	  	  	  	  	  	  	  	              When convert(real, @Value) < convert(real,coalesce(@LowerWarning,@Value)) Then @sLowerWarning 
 	  	  	  	  	  	  	  	  	              When convert(real, @Value) > convert(real,coalesce(@UpperUser,@Value)) Then @sUpperUser
 	  	  	  	  	  	  	  	  	              When convert(real, @Value) < convert(real,coalesce(@LowerUser,@Value)) Then @sLowerUser
 	  	  	  	  	  	  	  	  	              Else @sTarget
                          	  	  end
    Else If @SpecificationSetting = 2 and @IsNumeric = 1
     	  	 Select @Validation = Case
 	  	  	  	  	  	  	  	  	              When convert(real, @Value) >= convert(real,coalesce(@UpperEntry,@Value)) Then @sUpperEntry
 	  	  	  	  	  	  	  	  	              When convert(real, @Value) <= convert(real,coalesce(@LowerEntry,@Value)) Then @sLowerEntry
 	  	  	  	  	  	  	  	  	              When convert(real, @Value) >= convert(real,coalesce(@UpperReject,@Value)) Then @sUpperReject
 	  	  	  	  	  	  	  	  	              When convert(real, @Value) <= convert(real,coalesce(@LowerReject,@Value)) Then @sLowerReject
 	  	  	  	  	  	  	  	  	              When convert(real, @Value) >= convert(real,coalesce(@UpperWarning,@Value)) Then @sUpperWarning
 	  	  	  	  	  	  	  	  	              When convert(real, @Value) <= convert(real,coalesce(@LowerWarning,@Value)) Then @sLowerWarning
 	  	  	  	  	  	  	  	  	              When convert(real, @Value) >= convert(real,coalesce(@UpperUser,@Value)) Then @sUpperUser 
 	  	  	  	  	  	  	  	  	              When convert(real, @Value) <= convert(real,coalesce(@LowerUser,@Value)) Then @sLowerUser
 	  	  	  	  	  	  	  	  	              Else @sTarget
                          	  	  end
    Else
     	  	 Select @Validation = Case
 	  	  	  	  	  	  	  	  	              When @Value = @UpperEntry Then @UpperEntry 
 	  	  	  	  	  	  	  	  	              When @Value = @UpperReject Then @sUpperReject
 	  	  	  	  	  	  	  	  	              When @Value = @UpperWarning Then @sUpperWarning
 	  	  	  	  	  	  	  	  	              When @Value = @UpperUser Then @sUpperUser 
 	  	  	  	  	  	  	  	  	              When @Value = @LowerEntry Then @sLowerEntry
 	  	  	  	  	  	  	  	  	              When @Value = @LowerReject Then @sLowerReject
 	  	  	  	  	  	  	  	  	              When @Value = @LowerWarning Then @sLowerWarning
 	  	  	  	  	  	  	  	  	              When @Value = @LowerUser Then @sLowerUser
 	  	  	  	  	  	  	  	  	              Else @sTarget 
                          	  	  end
  End
Else
  Begin
 	  	 Select @Validation = dbo.fnTranslate(@LangId, 34832, 'No Specification')
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
  PromptName nvarchar(30),
  PromptValue nvarchar(1000),
  PromptValue_Parameter SQL_Variant, 
  PromptValue_Parameter2 SQL_Variant
)
Select @ReportName = dbo.fnTranslate(@LangId, 34833, 'Test Detail')
Insert into #Prompts (PromptName, PromptValue) Values('ReportName', @ReportName)
Insert into #Prompts (PromptName, PromptValue, PromptValue_Parameter, PromptValue_Parameter2) 
  Values('Criteria', dbo.fnTranslate(@LangId, 34834, '{0} At {1}'), @VariableName, @TimeStamp)
Insert into #Prompts (PromptName, PromptValue, PromptValue_Parameter) Values('GenerateTime', dbo.fnTranslate(@LangId, 34521, 'Created: {0}'), dbo.fnServer_CmnGetDate(getutcdate()))
Insert into #Prompts (PromptName, PromptValue) Values('TestInformation', dbo.fnTranslate(@LangId, 34835, 'Test Information'))
Insert into #Prompts (PromptName, PromptValue) Values ('ElectronicSignature', dbo.fnTranslate(@LangId, 34695, 'Electronic Signature'))
Insert into #Prompts (PromptName, PromptValue) Values('VariableInformation', dbo.fnTranslate(@LangId, 34836, 'Variable Information'))
Insert into #Prompts (PromptName, PromptValue) Values('SpecificationInformation', dbo.fnTranslate(@LangId, 34837, 'Specification Information'))
Insert into #Prompts (PromptName, PromptValue) Values('Comments', dbo.fnTranslate(@LangId, 34838, 'Comments'))
Insert into #Prompts (PromptName, PromptValue) Values('Alarms', dbo.fnTranslate(@LangId, 34839, 'Alarms'))
Insert into #Prompts (PromptName, PromptValue) Values('AuditTrail', dbo.fnTranslate(@LangId, 34840, 'Audit Trail'))
Insert into #Prompts (PromptName, PromptValue) Values('ESigPerformer', dbo.fnTranslate(@LangId, 35145, 'E-Signature Performer'))
Insert into #Prompts (PromptName, PromptValue) Values('ESigPerformedTime', dbo.fnTranslate(@LangId, 35146, 'E-Signature Performed Time'))
Insert into #Prompts (PromptName, PromptValue) Values('ESigPerformerReason', dbo.fnTranslate(@LangId, 35147, 'E-Signature Performer Reason'))
Insert into #Prompts (PromptName, PromptValue) Values('ESigPerformerComment', dbo.fnTranslate(@LangId, 35148, 'E-Signature Performer Comment'))
Insert into #Prompts (PromptName, PromptValue) Values('ESigApprover', dbo.fnTranslate(@LangId, 35149, 'E-Signature Approver'))
Insert into #Prompts (PromptName, PromptValue) Values('ESigApprovedTime', dbo.fnTranslate(@LangId, 35150, 'E-Signature Approved Time'))
Insert into #Prompts (PromptName, PromptValue) Values('ESigApproverReason', dbo.fnTranslate(@LangId, 35151, 'E-Signature Approver Reason'))
Insert into #Prompts (PromptName, PromptValue) Values('ESigApproverComment', dbo.fnTranslate(@LangId, 35152, 'E-Signature Approver Comment'))
Insert into #Prompts (PromptName, PromptValue) Values ('TestId', convert(nvarchar(15), @TestId))
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
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end  
From #Prompts
Drop Table #Prompts
--**********************************************
-- Return Data For Report
--**********************************************
-- Create Simple Return Table
Create Table #Report (
  [Id] int identity(1,1),
  [Name] nvarchar(50),
  [Value] nvarchar(255) NULL,
  Value_Parameter SQL_Variant,
  Hyperlink nvarchar(255) NULL,
  Hyperlink_Encode SQL_Variant,
  Hyperlink_Encode2 SQL_Variant,
  Hyperlink_Encode3 SQL_Variant,
  Hyperlink_Encode4 SQL_Variant,
 	 Tag int NULL
)
--********************************************************************************
-- Return Basic Test Information
--********************************************************************************
Truncate Table #Report
If @IsEventBased = 1
  Insert Into #Report ([Name], Value, Hyperlink) Values (@EventType, @EventName, '<Link>EventDetail.aspx?Id=' + convert(nvarchar(15),@EventId) +'&TargetTimeZone='+ @InTimeZone + '</Link>')
Insert Into #Report ([Name], Value, Value_Parameter) Values(dbo.fnTranslate(@LangId, 34841, 'Timestamp'), '{0}', @Timestamp)
Insert Into #Report ([Name], Value) Values(dbo.fnTranslate(@LangId, 34842, 'Value'), @Value)
Insert Into #Report ([Name], Value) Values(dbo.fnTranslate(@LangId, 34843, 'Validation'), @Validation)
Insert Into #Report ([Name], Value) Values(dbo.fnTranslate(@LangId, 34844, 'Status'), @Status)
Insert Into #Report ([Name], Value, Value_Parameter) Values(dbo.fnTranslate(@LangId, 34845, 'Entered On'), '{0}', @EnteredOn)
Insert Into #Report ([Name], Value) Values(dbo.fnTranslate(@LangId, 34846, 'Entered By'), @EnteredBy)
 select [Id],
  [Name],
  [Value],
 	  	 'Value_Parameter'= case when (ISDATE(Convert(varchar,Value_Parameter))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,Value_Parameter),@InTimeZone)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Value_Parameter
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end, 
  Hyperlink, 
 	  	 'Hyperlink_Encode'= case when (ISDATE(Convert(varchar,Hyperlink_Encode))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,Hyperlink_Encode),@InTimeZone)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Hyperlink_Encode
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end,
 	  	 'Hyperlink_Encode2'= case when (ISDATE(Convert(varchar,Hyperlink_Encode2))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,Hyperlink_Encode2),@InTimeZone)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Hyperlink_Encode2
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end,
 	  	 'Hyperlink_Encode3'= case when (ISDATE(Convert(varchar,Hyperlink_Encode3))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,Hyperlink_Encode3),@InTimeZone)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Hyperlink_Encode3
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end,
 	  	 'Hyperlink_Encode4'= case when (ISDATE(Convert(varchar,Hyperlink_Encode4))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,Hyperlink_Encode4),@InTimeZone)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Hyperlink_Encode4
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end,
 	 Tag
From  #Report Order By Id
--********************************************************************************
--********************************************************************************
-- Return Variable Information
--********************************************************************************
Truncate Table #Report
--TODO: Make this time calculation better
Select @TrendEnd = @Timestamp
Select @TrendStart = dateadd(minute, -1440, @Timestamp)
Insert Into #Report ([Name], Value, Hyperlink, Hyperlink_Encode, Hyperlink_Encode2, Hyperlink_Encode3, Hyperlink_Encode4) Values
  (dbo.fnTranslate(@LangId, 34847, 'Variable'), @VariableName,
   '<Link>MainFrame.aspx?Control=Applications/Interactive Chart/InteractiveChart.ascx&Title={0}&StartTime={1}&EndTime={2}&ContextName={3}&ContextType=2&Variables=' + convert(nvarchar(20),@VariableId) + '&TargetTimeZone='+ @InTimeZone +'</Link>',
   @VariableName, @TrendStart, @TrendEnd, @Unit)
Insert Into #Report ([Name], Value) Values (dbo.fnTranslate(@LangId, 34848, 'Eng Units'), @EngineeringUnits)
If @Alias Is Not Null
  Insert Into #Report ([Name], Value) Values (dbo.fnTranslate(@LangId, 34849, 'Alias'), @Alias)
Insert Into #Report ([Name], Value) Values (dbo.fnTranslate(@LangId, 34850, 'Unit'), @UnitName)
If @SpecificationName is Not Null
  Insert Into #Report ([Name], Value) Values (dbo.fnTranslate(@LangId, 34851, 'Specification'), @SpecificationName)
 select [Id],
  [Name],
  [Value],
 	  	 'Value_Parameter'= case when (ISDATE(Convert(varchar,Value_Parameter))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,Value_Parameter),@InTimeZone)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Value_Parameter
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end, 
  Hyperlink, 
 	  	 'Hyperlink_Encode'= case when (ISDATE(Convert(varchar,Hyperlink_Encode))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,Hyperlink_Encode),@InTimeZone)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Hyperlink_Encode
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end,
 	  	 'Hyperlink_Encode2'= case when (ISDATE(Convert(varchar,Hyperlink_Encode2))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,Hyperlink_Encode2),@InTimeZone)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Hyperlink_Encode2
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end,
 	  	 'Hyperlink_Encode3'= case when (ISDATE(Convert(varchar,Hyperlink_Encode3))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,Hyperlink_Encode3),@InTimeZone)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Hyperlink_Encode3
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end,
 	  	 'Hyperlink_Encode4'= case when (ISDATE(Convert(varchar,Hyperlink_Encode4))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,Hyperlink_Encode4),@InTimeZone)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Hyperlink_Encode4
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end,
 	 Tag
From  #Report Order By Id
--********************************************************************************
--********************************************************************************
-- Return Specification Information
--********************************************************************************
Truncate Table #Report
If @HasSpecification Is Not Null
  Begin
 	  	 Insert Into #Report ([Name], Value) Values (@sUpperEntry, @UpperEntry)
 	  	 Insert Into #Report ([Name], Value) Values (@sUpperReject, @UpperReject)
 	  	 Insert Into #Report ([Name], Value) Values (@sUpperWarning, @UpperWarning)
 	  	 Insert Into #Report ([Name], Value) Values (@sUpperUser, @UpperUser)
 	  	 Insert Into #Report ([Name], Value) Values (@sTarget, @Target)
 	  	 Insert Into #Report ([Name], Value) Values (@sLowerUser, @LowerUser)
 	  	 Insert Into #Report ([Name], Value) Values (@sLowerWarning, @LowerWarning)
 	  	 Insert Into #Report ([Name], Value) Values (@sLowerReject, @LowerReject)
 	  	 Insert Into #Report ([Name], Value) Values (@sLowerEntry, @LowerEntry)
  End
Else
  Begin
    Insert Into #Report ([Name], Value) Values (dbo.fnTranslate(@LangId, 34852, 'Specifications'), dbo.fnTranslate(@LangId, 34783, 'None'))
  End
 select [Id],
  [Name],
  [Value],
 	  	 'Value_Parameter'= case when (ISDATE(Convert(varchar,Value_Parameter))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,Value_Parameter),@InTimeZone)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Value_Parameter
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end, 
  Hyperlink, 
 	  	 'Hyperlink_Encode'= case when (ISDATE(Convert(varchar,Hyperlink_Encode))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,Hyperlink_Encode),@InTimeZone)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Hyperlink_Encode
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end,
 	  	 'Hyperlink_Encode2'= case when (ISDATE(Convert(varchar,Hyperlink_Encode2))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,Hyperlink_Encode2),@InTimeZone)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Hyperlink_Encode2
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end,
 	  	 'Hyperlink_Encode3'= case when (ISDATE(Convert(varchar,Hyperlink_Encode3))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,Hyperlink_Encode3),@InTimeZone)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Hyperlink_Encode3
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end,
 	  	 'Hyperlink_Encode4'= case when (ISDATE(Convert(varchar,Hyperlink_Encode4))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,Hyperlink_Encode4),@InTimeZone)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Hyperlink_Encode4
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end,
 	 Tag
From  #Report Order By Id
--********************************************************************************
--********************************************************************************
-- Return Comments
--********************************************************************************
--TODO: Return Chained Comments
Select Username = u.Username, 
 	 Timestamp =  [dbo].[fnServer_CmnConvertFromDbTime] ( c.Modified_On,@InTimeZone) ,
  Comment = c.Comment_Text
  From Comments c
  Join Users u on u.user_id = c.User_id 
  Where c.Comment_Id = @CommentId
--********************************************************************************
--********************************************************************************
-- Return Alarms
--********************************************************************************
--TODO: Link Comments?
Select Description = d.Alarm_Desc, 
       StartTime =  [dbo].[fnServer_CmnConvertFromDbTime] (Start_Time,@InTimeZone) ,
       EndTime =  (coalesce([dbo].[fnServer_CmnConvertFromDbTime](End_Time,@InTimeZone), dbo.fnServer_CmnGetDate(getutcdate()))) , 
       Reasons = coalesce(r1.event_reason_name, @sUnspecified)  + coalesce(',' + r2.event_reason_name,'') + coalesce(',' + r3.event_reason_name,'') + coalesce(',' + r4.event_reason_name,''),
       Actions = coalesce(a1.event_reason_name, @sUnspecified)  + coalesce(',' + a2.event_reason_name,'') + coalesce(',' + a3.event_reason_name,'') + coalesce(',' + a4.event_reason_name,''),
       Hyperlink = '<Link>AlarmDetail.aspx?Id=' + convert(nvarchar(15),Alarm_Id) + '&TargetTimeZone='+ @InTimeZone + '</Link>'
  From Alarms d
  Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.Cause1
  Left Outer Join Event_Reasons r2 on r2.event_reason_id = d.Cause2
  Left Outer Join Event_Reasons r3 on r3.event_reason_id = d.Cause3
  Left Outer Join Event_Reasons r4 on r4.event_reason_id = d.Cause4
  Left Outer Join Event_Reasons a1 on a1.event_reason_id = d.action1
  Left Outer Join Event_Reasons a2 on a2.event_reason_id = d.action2
  Left Outer Join Event_Reasons a3 on a3.event_reason_id = d.action3
  Left Outer Join Event_Reasons a4 on a4.event_reason_id = d.action4
  Where d.Key_Id = @VariableId and
        d.Alarm_Type_Id in (1,2) and  
 	       d.Start_Time <= @Timestamp and 
        ((d.End_Time > @Timestamp) or (d.End_Time Is Null))
  order by start_time asc
--********************************************************************************
--********************************************************************************
-- Return History
--********************************************************************************
Select UpdateTime =   [dbo].[fnServer_CmnConvertFromDbTime] (d.Entry_On,@InTimeZone)  , 
       UpdateUser = u.Username,
       Value = d.result,
 	  	  	  Status = Case 
                   When d.Result Is Not Null Then @sReady
                   When d.Result Is Null and d.Canceled = 0 Then @sScheduled
                   Else @sCanceled
 	  	  	  	  	  	  	  	  End,
 	  	  	  ESigPerformer = esig_pu.Username,
 	  	  	  ESigPerformedTime = esig.Perform_Time,
 	  	  	  ESigPerformerReason = pr.Event_Reason_Name,
 	  	  	  ESigPerformerComment = pc.Comment_Text,
 	  	  	  ESigApprover = esig_vu.Username,
 	  	  	  ESigApprovedTime = [dbo].[fnServer_CmnConvertFromDbTime] ( esig.Verify_Time,@InTimeZone)   , 
 	  	  	  ESigApproverReason = vr.Event_Reason_Name,
 	  	  	  ESigApproverComment = vc.Comment_Text  
  From Test_History d
  Join users u on u.user_id = d.entry_by
 	 left outer join esignature esig on d.Signature_Id = esig.Signature_Id
 	 left outer join users esig_pu on esig.Perform_User_Id = esig_pu.user_id
 	 left outer join users esig_vu on esig.Verify_User_Id = esig_vu.user_id
 	 left outer join event_reasons pr On esig.Perform_Reason_Id = pr.Event_Reason_Id
 	 left outer join event_reasons vr On esig.Verify_Reason_Id = vr.Event_Reason_Id
 	 left outer join Comments pc On esig.Perform_Comment_Id = pc.Comment_Id
 	 left outer join Comments vc On esig.Verify_Comment_Id = vc.Comment_Id
  Where d.test_id = @Testid
--********************************************************************************
--********************************************************************************
-- Return Electronic Signature Information
--********************************************************************************
Print 'Electronic Signature Information'
Truncate Table #Report
Declare @ESigId Int
Select @ESigId = Signature_Id
From Tests
Where Test_Id = @TestId
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
 	  	 Select dbo.fnTranslate(@LangId, 35137, 'User Comment'), Value = c.Comment_Text, Tag = c.Comment_Id
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
 	  	 Select dbo.fnTranslate(@LangId, 35140, 'Approver Comment'), Value = c.Comment_Text, Tag = c.Comment_Id
 	  	 From ESignature esig
 	  	 Join Comments c On esig.Verify_Comment_Id = c.Comment_Id
 	  	 Where esig.Signature_Id = @ESigId
End
select [Id],
  [Name],
  [Value],
 	  	 'Value_Parameter'= case when (ISDATE(Convert(varchar,Value_Parameter))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,Value_Parameter),@InTimeZone)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Value_Parameter
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end, 
  Hyperlink, 
 	  	 'Hyperlink_Encode'= case when (ISDATE(Convert(varchar,Hyperlink_Encode))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,Hyperlink_Encode),@InTimeZone)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Hyperlink_Encode
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end,
 	  	 'Hyperlink_Encode2'= case when (ISDATE(Convert(varchar,Hyperlink_Encode2))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,Hyperlink_Encode2),@InTimeZone)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Hyperlink_Encode2
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end,
 	  	 'Hyperlink_Encode3'= case when (ISDATE(Convert(varchar,Hyperlink_Encode3))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,Hyperlink_Encode3),@InTimeZone)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Hyperlink_Encode3
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end,
 	  	 'Hyperlink_Encode4'= case when (ISDATE(Convert(varchar,Hyperlink_Encode4))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,Hyperlink_Encode4),@InTimeZone)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Hyperlink_Encode4
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end,
 	 Tag
From  #Report Order By Id
--********************************************************************************
Drop Table #Report
