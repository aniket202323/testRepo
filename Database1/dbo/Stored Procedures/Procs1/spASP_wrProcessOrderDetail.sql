CREATE procedure [dbo].[spASP_wrProcessOrderDetail]
@PPId int,
@Command int = NULL,
@SearchOrder nVarChar(50) = NULL,
@InTimeZone nvarchar(200)=NULL
AS
/*
alter procedure spASP_wrProcessOrderDetail
@PPId int,
@Command int = NULL,
@SearchOrder nVarChar(50) = NULL
AS
--*/
set arithignore on
set arithabort off
set ansi_warnings off
--/*********************************************
-- For Testing
--*********************************************
/*Declare @PPId int,
@Command int,
@SearchOrder nVarChar(50)
Select @PPId = 9275 
Select @Command =  NULL --3
Select @SearchOrder = NULL --''
--select * from production_plan where actual_end_time is not null
--**********************************************/
Declare @ReportName nvarchar(255)
Declare @CriteriaString nVarChar(1000)
Declare @ImpliedSequence int
Declare @Path int
Declare @PathName nVarChar(100)
Declare @Unit int
Declare @ProcessOrder  	  	  	 nVarChar(100)
Declare @StatusId  	  	  	  	  	 int
Declare @Status  	  	  	  	  	  	 nVarChar(50)
Declare @StatusColor  	  	  	  	 int
Declare @ControlType  	  	  	  	 nVarChar(50)
Declare @OrderType  	  	  	  	  	 nVarChar(50)
Declare @ProductId  	  	  	  	  	 int
Declare @ProductCode  	  	  	  	 nVarChar(50)
Declare @ForecastQuantity  	 real
Declare @ActualGoodQuantity real
Declare @ActualBadQuantity  	 real
Declare @ForecastStartTime  	 datetime
Declare @ActualStartTime  	  	 datetime
Declare @ForecastEndTime  	  	 datetime
Declare @ActualEndTime  	  	  	 datetime
Declare @RemainingTime  	  	  	 real
Declare @ActualDowntime  	  	 real
Declare @ActualRuntime  	  	  	 real
Declare @ActualGoodItems  	  	 int
Declare @ActualBadItems  	  	 int
Declare @UpdatedBy  	  	  	  	  	 int 
Declare @UpdatedTime  	  	  	  	 datetime
Declare @CommentId  	  	  	  	  	 int
Declare @DimXUnits nvarchar(25)
Declare @DimYUnits nvarchar(25)
Declare @DimZUnits nvarchar(25)
Declare @DimAUnits nvarchar(25)
Declare @DimXName nvarchar(25)
Declare @DimYName nvarchar(25)
Declare @DimZName nvarchar(25)
Declare @DimAName nvarchar(25)
Declare @EventName nvarchar(25)
--**********************************************
-- Translations Setup & Common Prompt Lookup
--**********************************************
-- Retreive the Language Id of the current user
Declare @LangId INT
EXEC spWA_GetCurrentUserInfo @LangId = @LangId OUTPUT
--**********************************************
-- Loookup Initial Information For This Order
--**********************************************
If @PPId is Null
  Begin
    Raiserror('A Base PPId Must Be Supplied',16,1)
    Return
  End
If @Command Is Not Null
  Begin
 	  	 Select @Path = Path_Id, @ImpliedSequence = implied_sequence
 	  	   From Production_Plan
 	  	   Where PP_Id = @PPId 
   	 Select @PPId = NULL
  End
If @Command = 1
  Begin
    -- Scroll Next Event
    Select @PPId = PP_Id 
      From Production_Plan 
      Where Path_Id = @Path and 
            implied_sequence = (Select Min(implied_sequence) From Production_Plan Where Path_Id = @Path and implied_sequence > @ImpliedSequence)
  End
Else If @Command = 2
  Begin
    -- Scroll Previous Event
    Select @PPId = PP_Id 
      From Production_Plan 
      Where Path_Id = @Path and 
            implied_sequence = (Select Max(implied_sequence) From Production_Plan Where Path_Id = @Path and implied_sequence < @ImpliedSequence)
  End
Else If @Command = 3
  Begin
    -- Find Event
 	  	 If @SearchOrder Is Null
 	  	   Begin
 	  	     Raiserror('An Order Number Must Be Supplied To Search',16,1)
 	  	     Return
 	  	   End
    Select @PPId = PP_Id 
      From production_plan 
      Where Path_Id = @Path and
            Process_Order = @SearchOrder
  End
--Else This is Just A Straight Query
If @PPId Is Null
  Begin
    Raiserror('Command Did Not Find Order To Return',16,1)
    Return
  End
Select @ProcessOrder = pp.process_order,
       @Path = pp.path_id,
       @StatusId = pp.pp_status_id,
       @Status = s.pp_status_desc,
       @StatusColor = case pp.pp_status_id 
                        when 1 then 1
                        else 2 
                      End,
       @ControlType = case pp.control_type
                        When 2 Then dbo.fnTranslate(@LangId, 34781, 'Quantity')
                        When 1 Then dbo.fnTranslate(@LangId, 34782, 'Time')
                        Else dbo.fnTranslate(@LangId, 34783, 'None')
                      End,
       @OrderType = t.pp_type_name,
       @ProductId = pp.prod_id,
       @ProductCode = p.prod_code,
       @ForecastQuantity = pp.forecast_quantity,
       @ActualGoodQuantity = pp.actual_good_quantity,
       @ActualBadQuantity = pp.actual_bad_quantity,
       @ForecastStartTime = pp.forecast_start_date,
       @ActualStartTime = pp.actual_start_time,
       @ForecastEndTime = pp.forecast_end_date,
       @ActualEndTime = pp.actual_end_time,
       @RemainingTime = pp.predicted_remaining_duration,
       @ActualDowntime = pp.actual_down_time,
       @ActualRuntime = pp.actual_running_time,
       @ActualGoodItems = pp.actual_good_items,
       @ActualBadItems = pp.actual_bad_items,
       @UpdatedBy = pp.user_id, 
       @UpdatedTime = pp.entry_on,
       @CommentId = pp.comment_id
  From Production_Plan pp
  Join production_plan_statuses s on s.pp_status_id = pp.pp_status_id
  join production_plan_types t on t.pp_type_id = pp.pp_type_id
  join products p on p.prod_id = pp.prod_id
  Where pp.pp_id = @PPId
Select @PathName = path_desc + ' (' + path_code + ')'
  From prdexec_paths 
  where path_id = @Path
-- get dimension name
Select @Unit = min(pu_id)
  From prdexec_path_units
  Where path_id = @path and
        is_schedule_point = 1
Select @EventName = s.Event_Subtype_Desc,
       @DimXUnits = s.dimension_x_eng_units,
       @DimYUnits = s.dimension_y_eng_units,
       @DimZUnits = s.dimension_z_eng_units,
       @DimAUnits = s.dimension_a_eng_units,
       @DimXName = s.dimension_x_name,
       @DimYName = s.dimension_y_name,
       @DimZName = s.dimension_z_name,
       @DimAName = s.dimension_a_name
  from event_configuration e 
  join event_subtypes s on s.Event_Subtype_Id = e.Event_Subtype_Id
  where e.pu_id = @Unit and 
        e.et_id = 1
Select @ReportName = dbo.fnTranslate(@LangId, 34763, 'Process Order') + ' ' + @ProcessOrder 
--**********************************************
-- Return Header Information
--**********************************************
-- Line1: Report Name
-- Line2: Criteria
-- Line3: Generate Time
-- Line4 - n: Column Names
Declare @Prompts Table(
  PromptId int,
  PromptName nvarchar(20),
  PromptValue nvarchar(1000),
  PromptValue_Parameter SQL_Variant,
  PromptIsDate 	 Int
)
Insert into @Prompts (PromptId, PromptName, PromptValue,PromptIsDate) Values (1, 'ReportName', @ReportName,0)
Insert into @Prompts (PromptId, PromptName, PromptValue, PromptValue_Parameter,PromptIsDate) Values (2, 'Criteria', dbo.fnTranslate(@LangId, 34665, 'On {0}'), Coalesce(@PathName, dbo.fnTranslate(@LangId, 34814, '*Unknown Path Name*')),0)
Insert into @Prompts (PromptId, PromptName, PromptValue, PromptValue_Parameter,PromptIsDate) Values (3, 'GenerateTime', dbo.fnTranslate(@LangId, 34521, 'Created: {0}'), dbo.fnServer_CmnGetDate(getutcdate()),1)
-- Prompts For Section Headers
Insert into @Prompts (PromptId, PromptName, PromptValue,PromptIsDate) Values (4, 'SequenceInformation', dbo.fnTranslate(@LangId, 34784, 'Sequence Statistics'),0)
Insert into @Prompts (PromptId, PromptName, PromptValue,PromptIsDate) Values (5, 'UnitTimeline', dbo.fnTranslate(@LangId, 34785, 'Unit Timeline'),0)
Insert into @Prompts (PromptId, PromptName, PromptValue,PromptIsDate) Values (6, 'BOMDetails', dbo.fnTranslate(@LangId, 34786, 'BOM Details'),0)
Insert into @Prompts (PromptId, PromptName, PromptValue,PromptIsDate) Values (7, 'Comments', dbo.fnTranslate(@LangId, 34743, 'Comments'),0)
Insert into @Prompts (PromptId, PromptName, PromptValue,PromptIsDate) Values (8, 'AlarmInformation', dbo.fnTranslate(@LangId, 34694, 'Alarm Information'),0)
Insert into @Prompts (PromptId, PromptName, PromptValue,PromptIsDate) Values (9, 'Forecast', dbo.fnTranslate(@LangId, 34787, 'Forecast'),1)
Insert into @Prompts (PromptId, PromptName, PromptValue,PromptIsDate) Values (10, 'Actual', dbo.fnTranslate(@LangId, 34788, 'Actual'),1)
-- Prompts For Column Names
-- Setup Resultset
Insert into @Prompts (PromptId, PromptName, PromptValue,PromptIsDate) Values (11, 'Pattern', dbo.fnTranslate(@LangId, 34789, 'Pattern'),0)
Insert into @Prompts (PromptId, PromptName, PromptValue,PromptIsDate) Values (12, 'StartTime', dbo.fnTranslate(@LangId, 34710, 'Start'),0)
Insert into @Prompts (PromptId, PromptName, PromptValue,PromptIsDate) Values (13, 'EndTime', dbo.fnTranslate(@LangId, 34711, 'End'),0)
Insert into @Prompts (PromptId, PromptName, PromptValue,PromptIsDate) Values (14, 'Quantity', dbo.fnTranslate(@LangId, 34781, 'Quantity'),0)
Insert into @Prompts (PromptId, PromptName, PromptValue,PromptIsDate) Values (15, 'QuantityForecast', dbo.fnTranslate(@LangId, 34787, 'Forecast'),0)
Insert into @Prompts (PromptId, PromptName, PromptValue,PromptIsDate) Values (16, 'QuantityGood', dbo.fnTranslate(@LangId, 34790, 'Good'),0)
Insert into @Prompts (PromptId, PromptName, PromptValue,PromptIsDate) Values (17, 'QuantityBad', dbo.fnTranslate(@LangId, 34791, 'Bad'),0)
Insert into @Prompts (PromptId, PromptName, PromptValue,PromptIsDate) Values (18, 'QuantityRemaining', dbo.fnTranslate(@LangId, 34795, 'Remaining'),0)
Insert into @Prompts (PromptId, PromptName, PromptValue,PromptIsDate) Values (19, 'Repetitions', dbo.fnTranslate(@LangId, 34796, 'Repetitions'),0)
Insert into @Prompts (PromptId, PromptName, PromptValue,PromptIsDate) Values (20, 'RepetitionsForecast', dbo.fnTranslate(@LangId, 34787, 'Forecast'),0)
Insert into @Prompts (PromptId, PromptName, PromptValue,PromptIsDate) Values (21, 'RepetitionsActual', dbo.fnTranslate(@LangId, 34788, 'Actual'),0)
Insert into @Prompts (PromptId, PromptName, PromptValue,PromptIsDate) Values (22, 'Items', @EventName,0)
Insert into @Prompts (PromptId, PromptName, PromptValue,PromptIsDate) Values (23, 'ItemsGood', dbo.fnTranslate(@LangId, 34790, 'Good'),0)
Insert into @Prompts (PromptId, PromptName, PromptValue,PromptIsDate) Values (24, 'ItemsBad', dbo.fnTranslate(@LangId, 34791, 'Bad'),0)
Insert into @Prompts (PromptId, PromptName, PromptValue,PromptIsDate) Values (25, 'Time', dbo.fnTranslate(@LangId, 34792, 'Time'),0)
Insert into @Prompts (PromptId, PromptName, PromptValue,PromptIsDate) Values (26, 'TimeRunning', dbo.fnTranslate(@LangId, 34793, 'Running'),0)
Insert into @Prompts (PromptId, PromptName, PromptValue,PromptIsDate) Values (27, 'TimeDown', dbo.fnTranslate(@LangId, 34794, 'Down'),0)
Insert into @Prompts (PromptId, PromptName, PromptValue,PromptIsDate) Values (28, 'TimeRemaining', dbo.fnTranslate(@LangId, 34795, 'Remaining'),0)
If @DimXName Is Not Null
  Insert into @Prompts (PromptId, PromptName, PromptValue,PromptIsDate) Values (29, 'DimensionX', @DimXName + coalesce(' (' + @DimXUnits + ')',''),0)
If @DimYName Is Not Null
  Insert into @Prompts (PromptId, PromptName, PromptValue,PromptIsDate) Values (30, 'DimensionY', @DimYName + coalesce(' (' + @DimYUnits + ')',''),0)
If @DimZName Is Not Null
  Insert into @Prompts (PromptId, PromptName, PromptValue,PromptIsDate) Values (31, 'DimensionZ', @DimZName + coalesce(' (' + @DimZUnits + ')',''),0)
If @DimAName Is Not Null
  Insert into @Prompts (PromptId, PromptName, PromptValue,PromptIsDate) Values (32, 'DimensionA', @DimAName + coalesce(' (' + @DimAUnits + ')',''),0)
-- BOM
Insert into @Prompts (PromptId, PromptName, PromptValue,PromptIsDate) Values (33, 'ItemOrder', dbo.fnTranslate(@LangId, 35241, 'Item Order'),0)
Insert into @Prompts (PromptId, PromptName, PromptValue,PromptIsDate) Values (34, 'ProdCode', dbo.fnTranslate(@LangId, 34461, 'Product Code'),0)
Insert into @Prompts (PromptId, PromptName, PromptValue,PromptIsDate) Values (34, 'ProdDesc', dbo.fnTranslate(@LangId, 34974, 'Product Description'),0)
Insert into @Prompts (PromptId, PromptName, PromptValue,PromptIsDate) Values (35, 'LotNumber', dbo.fnTranslate(@LangId, 35242, 'Lot Number'),0)
Insert into @Prompts (PromptId, PromptName, PromptValue,PromptIsDate) Values (36, 'Location', dbo.fnTranslate(@LangId, 34569, 'Location'),0)
Insert into @Prompts (PromptId, PromptName, PromptValue,PromptIsDate) Values (37, 'QuantityPer', dbo.fnTranslate(@LangId, 34799, 'Qty Per'),0)
Insert into @Prompts (PromptId, PromptName, PromptValue,PromptIsDate) Values (38, 'EngineeringUnits', dbo.fnTranslate(@LangId, 34848, 'Eng Units'),0)
Insert into @Prompts (PromptId, PromptName, PromptValue,PromptIsDate) Values (39, 'RequiredQuantity', dbo.fnTranslate(@LangId, 35243, 'Req Qty'),0)
Insert into @Prompts (PromptId, PromptName, PromptValue,PromptIsDate) Values (40, 'ActualQuantity', dbo.fnTranslate(@LangId, 35244, 'Act Qty'),0)
Insert into @Prompts (PromptId, PromptName, PromptValue,PromptIsDate) Values (41, 'RemainingQuantity', dbo.fnTranslate(@LangId, 35245, 'Rem Qty'),0)
Insert into @Prompts (PromptId, PromptName, PromptValue,PromptIsDate) Values (42, 'ScrapFactor', dbo.fnTranslate(@LangId, 35246, 'Scrap Factor'),0)
Insert into @Prompts (PromptId, PromptName, PromptValue,PromptIsDate) Values (43, 'LowerReject', dbo.fnTranslate(@LangId, 34667, 'Lower Reject'),0)
Insert into @Prompts (PromptId, PromptName, PromptValue,PromptIsDate) Values (44, 'UpperReject', dbo.fnTranslate(@LangId, 34671, 'Upper Reject'),0)
Insert into @Prompts (PromptId, PromptName, PromptValue,PromptIsDate) Values (45, 'Substitutions', dbo.fnTranslate(@LangId, 35247, 'Substitutions'),0)
-- Alarms, Comments
Insert into @Prompts (PromptId, PromptName, PromptValue,PromptIsDate) Values (46, 'Username', dbo.fnTranslate(@LangId, 34703, 'User'),0)
Insert into @Prompts (PromptId, PromptName, PromptValue,PromptIsDate) Values (47, 'Timestamp', dbo.fnTranslate(@LangId, 34704, 'Time'),0)
Insert into @Prompts (PromptId, PromptName, PromptValue,PromptIsDate) Values (48, 'AckedBy', dbo.fnTranslate(@LangId, 34803, 'Ack'),0)
Insert into @Prompts (PromptId, PromptName, PromptValue,PromptIsDate) Values (49, 'Comment', dbo.fnTranslate(@LangId, 34705, 'Comment'),0)
Insert into @Prompts (PromptId, PromptName, PromptValue,PromptIsDate) Values (50, 'Message', dbo.fnTranslate(@LangId, 34804, 'Message'),0)
-- Prompts For Menu Items
Insert into @Prompts (PromptId, PromptName, PromptValue,PromptIsDate) Values (51, 'GotoPrevious', dbo.fnTranslate(@LangId, 34805, 'Goto Previous Order'),0)
Insert into @Prompts (PromptId, PromptName, PromptValue,PromptIsDate) Values (52, 'GotoNext', dbo.fnTranslate(@LangId, 34806, 'Goto Next Order'),0)
Insert into @Prompts (PromptId, PromptName, PromptValue,PromptIsDate) Values (53, 'ViewAudit', dbo.fnTranslate(@LangId, 34677, 'View Audit Trail'),0)
Insert into @Prompts (PromptId, PromptName, PromptValue,PromptIsDate) Values (54, 'ViewTimeline', dbo.fnTranslate(@LangId, 34678, 'View Timeline'),0)
Insert into @Prompts (PromptId, PromptName, PromptValue,PromptIsDate) Values (55, 'OrderId', convert(nvarchar(15), @PPId),0)
Insert into @Prompts (PromptId, PromptName, PromptValue,PromptIsDate) Values (56, 'PathId', convert(nvarchar(15), @Path),0)
select PromptId,PromptName,PromptValue,'PromptValue_Parameter'= case when PromptIsDate = 1 AND (ISDATE(Convert(varchar,PromptValue_Parameter))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,PromptValue_Parameter),@InTimeZone)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 PromptValue_Parameter
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end 
From @Prompts
--**********************************************
-- Return Data For Report
--**********************************************
-- Create Simple Return Table
Declare @Report Table(
  [Id] int identity(1,1),
  [Name] nvarchar(50),
  Value nvarchar(255) NULL,
  Value_Parameter nvarchar(1000),
  Hyperlink nvarchar(255) NULL
)
--********************************************************************************
-- Return Basic Order Information
--********************************************************************************
Delete From @Report
Insert Into @Report (Name, Value) Values (dbo.fnTranslate(@LangId, 34809, 'Path'), @PathName)
Insert Into @Report (Name, Value) Values (dbo.fnTranslate(@LangId, 34810, 'Status'), @Status)  --TODO: Color
Insert Into @Report (Name, Value) Values (dbo.fnTranslate(@LangId, 34811, 'Control Type'), @ControlType)
Insert Into @Report (Name, Value) Values (dbo.fnTranslate(@LangId, 34812, 'Order Type'), @OrderType)
Insert Into @Report (Name, Value) Values (dbo.fnTranslate(@LangId, 34813, 'Product'), @ProductCode)
select [Id],
  [Name],
  [Value],
  'Value_Parameter'= case when (ISDATE(Convert(varchar,Value_Parameter))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Convert(varchar,[dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,Value_Parameter),@InTimeZone))
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Value_Parameter
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end, Hyperlink
From  @Report Order By Id
--********************************************************************************
--********************************************************************************
-- Return Statistics Table
--********************************************************************************
-- Create Simple Return Table
Declare @Statistics Table(
  [Id] int identity(1,1),
  [Name] nvarchar(50),
  Forecast nvarchar(255) NULL,
  Forecast_Parameter nvarchar(1000),
  Actual nvarchar(255) NULL,
  Actual_Color nvarchar(50),
  Actual_Parameter nvarchar(1000),
  Actual_Parameter2 nvarchar(1000),
  PromptIsDate 	 Int
)
/*
spASP_wrProcessOrderDetail 10002
*/
Insert Into @Statistics ([Name], Forecast, Forecast_Parameter, Actual, Actual_Color, Actual_Parameter,PromptIsDate) 
  Select [Name] = dbo.fnTranslate(@LangId, 35039, 'Total Quantity'),
         Forecast = '{0} ' + Coalesce(@DimXUnits, ''),
         Forecast_Parameter = Coalesce(@ForecastQuantity, 0),
         Actual =  '{0}  ' + Coalesce(@DimXUnits, ''),
         Actual_Color = 'Red',
         Actual_Parameter = Coalesce(@ActualGoodQuantity + @ActualBadQuantity, 0)
 	  	  ,0
Insert Into @Statistics ([Name], Forecast, Forecast_Parameter, Actual, Actual_Color, Actual_Parameter,PromptIsDate) 
  Select [Name] =  dbo.fnTranslate(@LangId, 35040, 'Good Quantity'),
         Forecast = '-' ,
         Forecast_Parameter = '',
         Actual =  '{0}  ' + Coalesce(@DimXUnits, ''),
         Actual_Color = 'Red',
         Actual_Parameter = Coalesce(@ActualGoodQuantity, 0)
 	  	  ,0
Insert Into @Statistics ([Name], Forecast, Forecast_Parameter, Actual, Actual_Color, Actual_Parameter,PromptIsDate) 
  Select [Name] =  dbo.fnTranslate(@LangId, 35041, 'Bad Quantity'),
         Forecast = '-',
         Forecast_Parameter =  '',
         Actual =  '{0}  ' + Coalesce(@DimXUnits, ''),
         Actual_Color = 'Red',
         Actual_Parameter = Coalesce(@ActualBadQuantity, 0)
 	  	  ,0
Insert Into @Statistics ([Name], Forecast, Forecast_Parameter, Actual, Actual_Parameter,PromptIsDate)
  Select [Name] = dbo.fnTranslate(@LangId, 34011, 'Start Time'),
         Forecast = '{0}',
         Forecast_Parameter = @ForecastStartTime,
         Actual = '{0}',
         Actual_Parameter = Coalesce(@ActualStartTime, '-')
 	  	  ,1
Insert Into @Statistics ([Name], Forecast, Forecast_Parameter, Actual, Actual_Color, Actual_Parameter,PromptIsDate)
  Select [Name] = dbo.fnTranslate(@LangId, 34012, 'End Time'),
         Forecast = '{0}',
         Forecast_Parameter = @ForecastEndTime,
         Actual = '{0}',
         Actual_Color =  Case @StatusId
                    When 3 Then 'Blue'
                  Else
                    Null
                  End,
         Actual_Parameter = Case @StatusId
           When 3 then
             coalesce(dateadd(minute, @RemainingTime, dbo.fnServer_CmnGetDate(getutcdate())), @ActualEndTime)
           Else
             coalesce(@ActualEndTime,'-')
           End
 	  	    ,1
Insert Into @Statistics ([Name], Forecast, Forecast_Parameter, Actual, Actual_Color, Actual_Parameter,PromptIsDate) 
  Select [Name] = dbo.fnTranslate(@LangId, 34656, 'Duration'),
         Forecast = '{0}',
         Forecast_Parameter = DateDiff(Minute, @ForecastStartTime, @ForecastEndTime),
         Actual = '{0}',
         Actual_Color = 'Red',
         Actual_Parameter = Convert(Int,coalesce(@ActualRuntime, 0))
 	  	  ,0
Declare @SD nvarchar(255)
Declare @SDColor nVarChar(50)
If @StatusId = 3
  If DateAdd(minute,coalesce(@RemainingTime, 0),dbo.fnServer_CmnGetDate(getutcdate())) > @ForecastEndTime
    Begin
      Set @SD = '{0}'
      Set @SDColor = 'Red'
    End
  Else
    Begin
      Set @SD = '+{0}'
      Set @SDColor = 'Blue'
    End
Else
  If @ActualStartTime Is Not Null
    If @RemainingTime > 0.0
      Begin
        Set @SD = '({0})'
        Set @SDColor = 'Blue'
      End
    Else
      Begin
        Set @SD = '{0}'
        Set @SDColor = 'Red'
      End
  Else
      Set @SD = '-'
Insert Into @Statistics ([Name], Forecast, Actual, Actual_Color, Actual_Parameter,PromptIsDate) 
  Select [Name] = dbo.fnTranslate(@LangId, 34807, 'Schedule Deviation'),
         Forecast =  '-',
         Actual = @SD,
         Actual_Color = @SDColor,
         Actual_Parameter = Convert(Int,coalesce(@RemainingTime, 0) - datediff(minute, dbo.fnServer_CmnGetDate(getutcdate()), @ForecastEndTime))
 	  	  ,0
select [Id],[Name] ,Forecast,'Forecast_Parameter'= case when PromptIsDate = 1 AND (ISDATE(Convert(varchar,Forecast_Parameter))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Convert(varchar,[dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,Forecast_Parameter),@InTimeZone))
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Forecast_Parameter
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end, Actual , Actual_Color , 
  	    	    	    	    	    	    	  'Actual_Parameter'=case when PromptIsDate = 1 AND (ISDATE(Convert(varchar,Actual_Parameter))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Convert(varchar,[dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,Actual_Parameter),@InTimeZone))
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Actual_Parameter
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end,
  	    	    	    	    	    	    	  'Actual_Parameter2'=case when PromptIsDate = 1 AND (ISDATE(Convert(varchar,Actual_Parameter2))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Convert(varchar,[dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,Actual_Parameter2),@InTimeZone))
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Actual_Parameter2
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end
From  @Statistics Order By Id
--********************************************************************************
-- Return Sequence Information
--********************************************************************************
select Pattern = Pattern_Code,
       StartTime =   [dbo].[fnServer_CmnConvertFromDbTime] (Actual_Start_Time,@InTimeZone)  ,
       EndTime =   [dbo].[fnServer_CmnConvertFromDbTime] (Actual_End_Time,@InTimeZone)   ,
       QuantityForecast = Forecast_Quantity,
       QuantityGood = Actual_Good_Quantity,
       QuantityBad = Actual_Bad_Quantity,
       QuantityRemaining = Predicted_Remaining_Quantity,
       RepetitionsForecast = Pattern_Repititions,
       RepetitionsActual = Actual_Repetitions,
       ItemsGood = Actual_Good_Items, 
       ItemsBad = Actual_Bad_Items,
       TimeRunning = Actual_Running_Time,
       TimeDown = Actual_Down_Time,
       TimeRemaining = Predicted_Remaining_Duration,
       DimensionX = Base_Dimension_X, 
       DimensionY = Base_Dimension_Y, 
       DimensionZ = Base_Dimension_Z, 
       DimensionA = Base_Dimension_A 
  from production_setup
  Where PP_Id = @PPId
  Order By Implied_Sequence
--********************************************************************************
-- Return Unit Timeline Information
--********************************************************************************
Declare @Events Table(
  Category nvarchar(255),
  Subcategory nvarchar(255) NULL,
  StartTime datetime NULL, 
  EndTime datetime,
  ShortLabel nvarchar(255) NULL,
  LongLabel nvarchar(255) NULL,
  Color int, 
  Hovertext nVarChar(1000) NULL,
  Hyperlink nvarchar(255) NULL
)
Insert Into @Events (Category, Subcategory, StartTime, EndTime, ShortLabel, LongLabel, Color, HoverText, Hyperlink)
  Select Category = pu.pu_desc, 
         Subcategory = NULL,
         StartTime = d.Start_Time,
         EndTime = coalesce(d.End_Time, dbo.fnServer_CmnGetDate(getutcdate())),
         ShortLabel = coalesce(ps.pattern_code,''),
         LongLabel = coalesce(ps.pattern_code,''),
         Color = case when d.end_time is null then (Select Color From Colors WHERE Color_Id = 2) else (Select Color From Colors WHERE Color_Id = 1) end,
         HoverText = c.Comment_Text,
         Hyperlink = NULL
 	   From Production_Plan_Starts d
    Join Prod_Units pu on pu.pu_id = d.pu_id
    left outer join production_setup ps on ps.pp_setup_id = d.pp_setup_id 
    Left Outer Join Comments c On c.Comment_id = d.Comment_Id
 	   Where d.PP_id = @PPId
 Order by d.Start_Time 
Select MinTime = min(StartTime), MaxTime = max(EndTime) From @Events
--Sarla
--Select * From @Events   Order By Category, StartTime
select Category,Subcategory,
 	  	 'StartTime'=   [dbo].[fnServer_CmnConvertFromDbTime] (StartTime,@InTimeZone)  ,
 	  	 'EndTime'=  [dbo].[fnServer_CmnConvertFromDbTime] (EndTime,@InTimeZone) ,
 	  	 ShortLabel,LongLabel,Color,Hovertext,Hyperlink 
From @Events  Order By Category, StartTime
--Sarla
--********************************************************************************
-- Return BOM Details
--********************************************************************************
Declare @Value int
execute spASP_wrProcessOrderBOMStatistics
  @Value OUTPUT,
  @PPId,
  201
--********************************************************************************
-- Return Comments
--********************************************************************************
--TODO: Return Chained Comments
Select Username = u.Username, Timestamp =   [dbo].[fnServer_CmnConvertFromDbTime] (c.Modified_On,@InTimeZone) ,  
 	  Comment = c.Comment_Text
  From Comments c
  Join Users u on u.user_id = c.User_id 
  Where c.Comment_Id = @CommentId
--********************************************************************************
--********************************************************************************
-- Return Alarms
--********************************************************************************
--TODO: Is Key = PP_Id?
select [Id] = Alarm_Id,
 	 Timestamp =   [dbo].[fnServer_CmnConvertFromDbTime] (a.Start_Time,@InTimeZone) ,
       AckedBy = Case when a.Ack_on is null then dbo.fnTranslate(@LangId, 34808, '*Unacknowledged*') Else u.username + ' ({0})' end,
       AckedBy_Parameter = a.ack_on,
       Message = a.Alarm_Desc,
       HyperLink = 'Applications/EventViewer/AlarmDetail.aspx?Id=' + CAST(Alarm_Id as nvarchar(10))+'&TargetTimeZone=' + @InTimeZone
  from alarms a
  left outer join users u on u.user_id = a.ack_by
  Where Key_id = @PPId and
        Alarm_Type_Id = 3
  Order By Start_Time
/*
spASP_wrProcessOrderDetail 2
select * from Alarms
*/
--********************************************************************************
-- Return Update / Audit Information
--********************************************************************************
Delete From @Report
Insert Into @Report ([Name], Value, Value_Parameter) 
  Select [Name] = dbo.fnTranslate(@LangId, 34731, 'Last Updated By'), Value = Username + ' ({0})',
    Value_Parameter = @UpdatedTime
    From Users 
    Where User_id = @UpdatedBy
Select * From @Report Order By Id
--********************************************************************************
