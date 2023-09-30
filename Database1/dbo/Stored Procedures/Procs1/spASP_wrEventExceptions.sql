CREATE procedure [dbo].[spASP_wrEventExceptions]
@EventId int,
@InTimeZone nvarchar(200)=NULL
AS
/*
alter procedure spASP_wrEventExceptions
@EventId int
AS
--*/
set arithignore on
set arithabort off
set ansi_warnings off
--/*********************************************
-- For Testing
--*********************************************
/*Declare @EventId int
Select @EventId = 327 */
--**********************************************/
Declare @SpecificationSetting int  -- For Specification Comparisons
Select @SpecificationSetting = convert(int,value) From Site_Parameters Where Parm_id = 13
If @SpecificationSetting is Null Select @SpecificationSetting = 1
Declare @ReportName nvarchar(255)
Declare @CriteriaString nVarChar(1000)
Declare @Unit int
Declare @UnitName nVarChar(100)
Declare @EventType nVarChar(50)
Declare @EventName nVarChar(50)
Declare @Status nVarChar(50)
Declare @StatusColor int
Declare @StartTime datetime
Declare @EndTime datetime
Declare @ProductId int
Declare @TestingPercent int
Declare @Conformance nvarchar(25)
Declare @SignedBy int
Declare @ApprovedBy int
Declare @UpdatedBy int
Declare @UpdatedTime datetime
Declare @CommentId int
Declare @ProductCode nVarChar(50)
Declare @TrendStart datetime
Declare @TrendEnd datetime
--**********************************************
-- Translations Setup & Common Prompt Lookup
--**********************************************
-- Retreive the Language Id of the current user
Declare @LangId INT
EXEC spWA_GetCurrentUserInfo @LangId = @LangId OUTPUT
-- Get Common Prompts
DECLARE @High nVarChar(100)
DECLARE @Medium nVarChar(100)
DECLARE @Low nVarChar(100)
SET @High = dbo.fnTranslate(@LangId, 34736, 'High')
SET @Medium = dbo.fnTranslate(@LangId, 34737, 'Medium')
SET @Low = dbo.fnTranslate(@LangId, 34738, 'Low')
--**********************************************
-- Loookup Initial Information For This Event
--**********************************************
If @EventId Is Null
  Begin
    Raiserror('A Base EventId Must Be Supplied',16,1)
    Return
  End
Select @Unit = PU_Id, @EventName = Event_Num, @Status = ps.ProdStatus_Desc,
       @StatusColor = Case when ps.Status_Valid_For_Input = 1 Then 0 Else 2 End,
       @StartTime = Start_Time, @EndTime = Timestamp, @ProductId = Applied_Product,
       @TestingPercent = Testing_Prct_Complete, 
       @Conformance = Case 
                        When Conformance = 1 Then dbo.fnTranslate(@LangId, 34688, 'User')
                        When Conformance = 2 Then dbo.fnTranslate(@LangId, 34689, 'Warning') 
                        When Conformance = 3 Then dbo.fnTranslate(@LangId, 34690, 'Reject') 
                        When Conformance = 3 Then dbo.fnTranslate(@LangId, 34691, 'Entry')
                        Else dbo.fnTranslate(@LangId, 34692, 'Good')
                      End,
       @SignedBy = null, @ApprovedBy = NULL,
       @UpdatedBy = user_id, @UpdatedTime = entry_on,
       @CommentId = comment_id       
  From Events e
  Join Production_Status ps on ps.prodstatus_id =  e.event_status
  Where Event_Id = @EventId 
Select @EventType = s.event_subtype_desc
  from event_configuration e 
  join event_subtypes s on s.Event_Subtype_Id = e.Event_Subtype_Id
  where e.pu_id = @Unit and 
        e.et_id = 1
-- Get Start Time If Missing
If @StartTime Is Null
  Select @StartTime = max(Timestamp) From Events Where PU_Id = @Unit and Timestamp < @EndTime
Select @TrendStart = dateadd(second, -6 * datediff(second,@StartTime, @EndTime), @StartTime)
Select @TrendEnd = dateadd(second, 3 * datediff(second,@StartTime, @EndTime), @EndTime)
If @TrendEnd > dbo.fnServer_CmnGetDate(getutcdate()) 
  Select @TrendEnd = dbo.fnServer_CmnGetDate(getutcdate())
Select @UnitName = PU_Desc
 From Prod_Units 
 Where PU_Id = @Unit
Select @ReportName = @EventType + ' ' + @EventName + ' ' + dbo.fnTranslate(@LangId, 34739, 'Exceptions')
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
Select @CriteriaString = 'On ' Select @CriteriaString = @CriteriaString + @UnitName
Insert into #Prompts (PromptName, PromptValue, PromptValue_Parameter) Values('Criteria', dbo.fnTranslate(@LangId, 34665, 'On {0}'), @UnitName)
Insert into #Prompts (PromptName, PromptValue, PromptValue_Parameter) Values('GenerateTime', dbo.fnTranslate(@LangId, 34521, 'Created: {0}'),[dbo].[fnServer_CmnConvertFromDbTime](dbo.fnServer_CmnGetDate(getutcdate()),@InTimeZone))
Insert into #Prompts (PromptName, PromptValue) Values ('EventInformation', dbo.fnTranslate(@LangId, 34740, 'Event Information'))
Insert into #Prompts (PromptName, PromptValue) Values ('ExceptionSummary', dbo.fnTranslate(@LangId, 34741, 'Exception Summary'))
Insert into #Prompts (PromptName, PromptValue) Values ('AlarmSummary', dbo.fnTranslate(@LangId, 34742, 'Alarm Summary'))
Insert into #Prompts (PromptName, PromptValue) Values ('Comments', dbo.fnTranslate(@LangId, 34743, 'Comments'))
Insert into #Prompts (PromptName, PromptValue) Values ('Username', dbo.fnTranslate(@LangId, 34703, 'User'))
Insert into #Prompts (PromptName, PromptValue) Values ('Timestamp', dbo.fnTranslate(@LangId, 34704, 'Time'))
Insert into #Prompts (PromptName, PromptValue) Values ('Comment', dbo.fnTranslate(@LangId, 34705, 'Comment'))
Insert into #Prompts (PromptName, PromptValue) Values ('StartTime', dbo.fnTranslate(@LangId, 34710, 'Start'))
Insert into #Prompts (PromptName, PromptValue) Values ('EndTime', dbo.fnTranslate(@LangId, 34711, 'End'))
Insert into #Prompts (PromptName, PromptValue) Values ('Product', dbo.fnTranslate(@LangId, 34712, 'Product'))
Insert into #Prompts (PromptName, PromptValue) Values ('Unit', dbo.fnTranslate(@LangId, 34713, 'Unit'))
Insert into #Prompts (PromptName, PromptValue) Values ('Variable', dbo.fnTranslate(@LangId, 34715, 'Variable'))
Insert into #Prompts (PromptName, PromptValue) Values ('LRL', dbo.fnTranslate(@LangId, 34667, 'Lower Reject'))
Insert into #Prompts (PromptName, PromptValue) Values ('LWL', dbo.fnTranslate(@LangId, 34668, 'Lower Warning'))
Insert into #Prompts (PromptName, PromptValue) Values ('TGT', dbo.fnTranslate(@LangId, 34669, 'Target'))
Insert into #Prompts (PromptName, PromptValue) Values ('UWL', dbo.fnTranslate(@LangId, 34670, 'Upper Warning'))
Insert into #Prompts (PromptName, PromptValue) Values ('URL', dbo.fnTranslate(@LangId, 34671, 'Upper Reject'))
Insert into #Prompts (PromptName, PromptValue) Values ('Value', dbo.fnTranslate(@LangId, 34672, 'Value'))
Insert into #Prompts (PromptName, PromptValue) Values ('EnteredOn', dbo.fnTranslate(@LangId, 34673, 'Entered On'))
Insert into #Prompts (PromptName, PromptValue) Values ('EnteredBy', dbo.fnTranslate(@LangId, 34674, 'Entered By'))
Insert into #Prompts (PromptName, PromptValue) Values ('Priority', dbo.fnTranslate(@LangId, 34744, 'Priority'))
Insert into #Prompts (PromptName, PromptValue) Values ('Description', dbo.fnTranslate(@LangId, 34745, 'Description'))
Insert into #Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('EventId', '{0}', @EventId)
Insert into #Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('TrendStart', '{0}',[dbo].[fnServer_CmnConvertFromDbTime](@TrendStart,@InTimeZone))
Insert into #Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('TrendEnd', '{0}', [dbo].[fnServer_CmnConvertFromDbTime](@TrendEnd,@InTimeZone))
Insert into #Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('StartTime', '{0}',[dbo].[fnServer_CmnConvertFromDbTime]( @StartTime,@InTimeZone))
Insert into #Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('EndTime', '{0}', [dbo].[fnServer_CmnConvertFromDbTime]( @EndTime,@InTimeZone))
Insert into #Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('UnitId', '{0}', @Unit)
Insert into #Prompts (PromptName, PromptValue) Values ('Id', dbo.fnTranslate(@LangId, 34984, 'Id'))
--select PromptId,PromptName,PromptValue,'PromptValue_Parameter'= case when (ISDATE(Convert(varchar,PromptValue_Parameter))=1)
-- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
-- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,PromptValue_Parameter),@InTimeZone)
-- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
-- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 PromptValue_Parameter
-- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end
SELECT *
From #Prompts
Drop Table #Prompts
--**********************************************
-- Return Data For Report
--**********************************************
-- Get Product
If @ProductId Is Null
  Select @ProductId = Prod_Id 
    From Production_Starts 
    Where PU_Id = @Unit and 
          Start_Time <= @EndTime and
          ((End_Time > @EndTime) or (End_Time Is Null)) 
Select @ProductCode = Prod_Code From Products Where Prod_Id = @ProductId 
-- Create Simple Return Table
Create Table #Report (
  [Id] int identity(1,1),
  [Name] nvarchar(50),
  Value nvarchar(255) NULL,
  Value_Parameter SQL_Variant,
  Hyperlink nvarchar(255) NULL
)
--********************************************************************************
-- Return Basic Event Information
--********************************************************************************
Truncate Table #Report
Insert Into #Report ([Name], Value) Values(dbo.fnTranslate(@LangId, 34746, 'Status'), @Status)
Insert Into #Report ([Name], Value) Values(dbo.fnTranslate(@LangId, 34747, 'Product'), @ProductCode)
Insert Into #Report ([Name], Value, Value_Parameter) Values(dbo.fnTranslate(@LangId, 34011, 'Start Time'), '{0}',[dbo].[fnServer_CmnConvertFromDbTime]( @StartTime,@InTimeZone))
Insert Into #Report ([Name], Value, Value_Parameter) Values(dbo.fnTranslate(@LangId, 34012, 'End Time'), '{0}', [dbo].[fnServer_CmnConvertFromDbTime](@EndTime,@InTimeZone))
Insert Into #Report (Name, Value) Values (dbo.fnTranslate(@LangId, 34723, 'Conformance'), @Conformance)
If @TestingPercent is Not Null
  Insert Into #Report (Name, Value, Value_Parameter) Values (dbo.fnTranslate(@LangId, 34724, 'Testing Percent'), '{0}', @TestingPercent)
Else
  Insert Into #Report (Name, Value) Values (dbo.fnTranslate(@LangId, 34724, 'Testing Percent'), dbo.fnTranslate(@LangId, 34725, 'N/A'))
If @SignedBy Is Not Null
  Insert Into #Report (Name, Value) 
    Select Name = dbo.fnTranslate(@LangId, 34729, 'Signed By'), Value = Username
      From Users 
      Where User_id = @SignedBy
If @SignedBy Is Not Null
  Insert Into #Report (Name, Value) 
    Select Name = dbo.fnTranslate(@LangId, 34730, 'Approved By'), Value = Username
      From Users 
      Where User_id = @ApprovedBy
Insert Into #Report ([Name], Value, Value_Parameter) 
  Select [Name] = dbo.fnTranslate(@LangId, 34731, 'Last Updated By'), Value = Username + ' ({0})', Value_Parameter = [dbo].[fnServer_CmnConvertFromDbTime](@UpdatedTime,@InTimeZone)
    From Users 
    Where User_id = @UpdatedBy
--select [Id],
--  [Name],
--  [Value],
--  'Value_Parameter'= case when (ISDATE(Convert(varchar,Value_Parameter))=1)
-- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
-- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,Value_Parameter),@InTimeZone)
-- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
-- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Value_Parameter
-- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end, Hyperlink
SELECT * From  #Report Order By Id
--********************************************************************************
--********************************************************************************
-- Return Parameter Exceptions
--********************************************************************************
Create Table #Data (
  Unit int,
  [Id] int,
  Color int NULL,
  Variable nvarchar(100),
  EngineeringUnits nVarChar(50) NULL,
  LRL SQL_Variant NULL,
  LWL SQL_Variant NULL,
  TGT SQL_Variant NULL,
  UWL SQL_Variant NULL,
  URL SQL_Variant NULL,
  Value SQL_Variant NULL,
  EnteredOn datetime NULL,
  EnteredBy nVarChar(50) NULL
)
Insert Into #Data
  Select Unit = case when pu.Master_Unit Is Null then pu.pu_id else pu.Master_Unit End,
       Id = v.var_id,
       Color = Case 
                 When v.Data_Type_Id in (1,2,6,7) and @SpecificationSetting = 1 Then 
 	  	  	  	  	  	  	  	  	  	 Case 
          	  	  	  	  	  	  	 When convert(real, t.result) > convert(real,coalesce(vs.u_reject,t.result)) or convert(real, t.result) < convert(real,coalesce(vs.l_reject,t.result)) Then 2 
          	  	  	  	  	  	  	 When convert(real, t.result) > convert(real,coalesce(vs.u_warning,t.result)) or convert(real, t.result) < convert(real,coalesce(vs.l_warning,t.result)) Then 1 
          	  	  	  	  	  	  	 Else 0 
 	  	  	  	  	  	  	  	  	  	 End
                 When v.Data_Type_Id in (1,2,6,7) and @SpecificationSetting = 2 Then 
 	  	  	  	  	  	  	  	  	  	 Case 
 	  	  	  	               When convert(real, t.result) >= convert(real,coalesce(vs.u_reject,convert(real, t.result)-1)) or convert(real, t.result) <= convert(real,coalesce(vs.l_reject,convert(real, t.result)+1)) Then 2 
 	  	  	  	               When convert(real, t.result) >= convert(real,coalesce(vs.u_warning,convert(real, t.result)-1)) or convert(real, t.result) <= convert(real,coalesce(vs.l_warning,convert(real, t.result)+1)) Then 1 
 	  	  	  	               Else 0 
                    End
                 Else  
 	  	  	  	  	  	  	  	  	  	 Case 
 	  	  	  	  	             When t.result = coalesce(vs.u_reject,'vs.u_reject') or t.result = coalesce(vs.l_reject,'vs.l_reject') Then 2 
 	  	  	  	  	         	  	  	 When t.result = coalesce(vs.u_warning,'vs.u_warning') or t.result = coalesce(vs.l_warning,'vs.l_warning') Then 1 
 	  	  	  	  	             Else 0 
                    End
               End,
       Variable = v.var_desc,
       EngineeringUnits = v.eng_units,
       LRL = dbo.fnDisplayVarcharValue(v.Data_Type_Id, vs.L_Reject),
       LWL = dbo.fnDisplayVarcharValue(v.Data_Type_Id, vs.L_Warning),
       TGT = dbo.fnDisplayVarcharValue(v.Data_Type_Id, vs.Target),
       UWL = dbo.fnDisplayVarcharValue(v.Data_Type_Id, vs.U_Warning),
       URL = dbo.fnDisplayVarcharValue(v.Data_Type_Id, vs.U_Reject),
       Value = dbo.fnDisplayVarcharValue(v.Data_Type_Id, t.Result),
       EnteredOn =   [dbo].[fnServer_CmnConvertFromDbTime] (t.Entry_On,@InTimeZone)  ,  
       EnteredBy = u.Username
  From Variables v
  Join prod_units pu on pu.pu_id = v.pu_id and pu.pu_id = @Unit or pu.master_Unit = @Unit
  left outer join tests t on t.var_id = v.var_id and t.result_on = @EndTime
  left outer join var_specs vs on vs.prod_id = @ProductId and vs.var_id = v.var_id and vs.effective_date <= @EndTime and ((vs.expiration_date > @EndTime) or (vs.expiration_date is null))
  left outer join users u on u.user_id = t.entry_by
  where v.event_type = 1 and v.pu_id <> 0
Select Distinct * From #Data
  Where Color > 0
  Order By Color DESC, Variable ASC
Drop Table #Data
--********************************************************************************
--********************************************************************************
-- Return Alarm List
--********************************************************************************
Select Id = a.Alarm_Id, Priority = Case 
                    When  r.ap_id = 3 or r2.ap_id = 3 Then @High
                    When  r.ap_id = 2 or r2.ap_id = 2 Then @Medium
                    Else @Low
                  End,
       Description = a.Alarm_Desc,
       StartTime =   [dbo].[fnServer_CmnConvertFromDbTime] (a.Start_Time,@InTimeZone)  ,  
       EndTime =  [dbo].[fnServer_CmnConvertFromDbTime] (a.End_Time,@InTimeZone)    
  From Alarms a
  left outer Join Alarm_Template_Var_Data vd on vd.atd_id = a.atd_id
  left outer Join Alarm_Templates t on t.at_id = vd.at_id
  Left Outer Join Alarm_Template_SPC_Rule_Data r on r.atsrd_id = a.atsrd_id and r.at_id = vd.at_id
  Left Outer Join Alarm_Template_Variable_Rule_Data r2 on r2.atvrd_Id = a.atvrd_id and r2.at_id = vd.at_id
  Where a.Start_Time Between @StartTime and @EndTime and
        a.source_pu_id = @Unit
Union
Select Id = a.Alarm_Id, Priority = Case 
                    When  r.ap_id = 3 or r2.ap_id = 3 Then @High
                    When  r.ap_id = 2 or r2.ap_id = 2 Then @Medium
                    Else @Low
                  End,
       Description = a.Alarm_Desc,
       StartTime =   [dbo].[fnServer_CmnConvertFromDbTime] (a.Start_Time,@InTimeZone)  , 
       EndTime =    [dbo].[fnServer_CmnConvertFromDbTime] (a.End_Time,@InTimeZone)  
  From Alarms a
  left outer Join Alarm_Template_Var_Data vd on vd.atd_id = a.atd_id
  left outer Join Alarm_Templates t on t.at_id = vd.at_id
  Left Outer Join Alarm_Template_SPC_Rule_Data r on r.atsrd_id = a.atsrd_id and r.at_id = vd.at_id
  Left Outer Join Alarm_Template_Variable_Rule_Data r2 on r2.atvrd_Id = a.atvrd_id and r2.at_id = vd.at_id
  Where a.Start_Time < @StartTime and ((a.end_time > @StartTime) or (a.end_time is null))  and
        a.source_pu_id = @Unit
Order By Priority Desc         
--********************************************************************************
-- Return Comments
--********************************************************************************
--TODO: Return Chained Comments
Select Username = u.Username, Timestamp =   [dbo].[fnServer_CmnConvertFromDbTime] (c.Modified_On,@InTimeZone) , Comment = c.Comment_Text, Name = u.Username, Value = c.Comment_Text, HyperLink = null 
  From Comments c
  Join Users u on u.user_id = c.User_id 
  Where c.Comment_Id = @CommentId
--********************************************************************************
Drop Table #Report
