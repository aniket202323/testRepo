CREATE procedure [dbo].[spASP_wrProcessOrderHistory]
@EventId int,
@InTimeZone nvarchar(200)=NULL
AS
/*
alter procedure spASP_wrProcessOrderHistory
@EventId int
AS
--*/
--/*********************************************
-- For Testing
--*********************************************
--Declare @EventId int
--Select @EventId = 9363 --2572 --327
--**********************************************/
--**********************************************
-- Translations Setup & Common Prompt Lookup
--**********************************************
-- Retreive the Language Id of the current user
Declare @LangId INT
EXEC spWA_GetCurrentUserInfo @LangId = @LangId OUTPUT
-- Get Common Prompts
DECLARE @Quantity nVarChar(100)
DECLARE @Time nVarChar(100)
DECLARE @None nVarChar(100)
SET @Quantity = dbo.fnTranslate(@LangId, 34781, 'Quantity')
SET @Time = dbo.fnTranslate(@LangId, 34782, 'Time')
SET @None = dbo.fnTranslate(@LangId, 34783, 'None')
Declare @ReportName nvarchar(255)
Declare @CriteriaString nVarChar(1000)
Declare @Path int
Declare @ProcessOrder nVarChar(100)
Declare @PathName nVarChar(100)
Declare @EventType nvarchar(255)
Select @EventType = dbo.fnTranslate(@LangId, 34763, 'Process Order')
If @EventId Is Null
  Begin
    Raiserror('Event ID Is A Required Parameter',16,1)
    Return
  End
Select @Path = Path_Id, @ProcessOrder = Process_Order 
  From Production_Plan
  Where PP_Id = @EventId 
Select @PathName = Path_Code
 From Prdexec_Paths 
 Where Path_Id = @Path
Select @ReportName = dbo.fnTranslate(@LangId, 34815, 'Process Order History')
--**********************************************
-- Return Header Information
--**********************************************
-- Line1: Report Name
-- Line2: Criteria
-- Line3: Generate Time
-- Line4 - n: Column Names
Declare @Prompts Table (
  PromptId int null,
  PromptName nvarchar(20),
  PromptValue nvarchar(1000),
  PromptValue_Parameter SQL_Variant,
  PromptValue_Parameter2 SQL_Variant
)
Insert into @Prompts (PromptName, PromptValue) Values ('ReportName', @ReportName)
Insert into @Prompts (PromptName, PromptValue, PromptValue_Parameter, PromptValue_Parameter2) Values('Criteria', dbo.fnTranslate(@LangId, 34749, 'For {0} On {1}'), @ProcessOrder, @PathName)
Insert into @Prompts (PromptName, PromptValue, PromptValue_Parameter) Values('GenerateTime', dbo.fnTranslate(@LangId, 34521, 'Created: {0}'), dbo.fnServer_CmnGetDate(getutcdate()))
Insert into @Prompts (PromptName, PromptValue) Values ('History', dbo.fnTranslate(@LangId, 34648, 'History'))
Insert into @Prompts (PromptName, PromptValue) Values ('Updated', dbo.fnTranslate(@LangId, 34649, 'Updated'))
Insert into @Prompts (PromptName, PromptValue) Values ('Added', dbo.fnTranslate(@LangId, 34650, 'Added'))
Insert into @Prompts (PromptName, PromptValue) Values ('Removed', dbo.fnTranslate(@LangId, 34651, 'Removed'))
Insert into @Prompts (PromptName, PromptValue) Values ('Operation', dbo.fnTranslate(@LangId, 34754, 'Operation'))
Insert into @Prompts (PromptName, PromptValue) Values ('Field', dbo.fnTranslate(@LangId, 34755, 'Field'))
Insert into @Prompts (PromptName, PromptValue) Values ('FromValue', dbo.fnTranslate(@LangId, 34756, 'From Value'))
Insert into @Prompts (PromptName, PromptValue) Values ('ToValue', dbo.fnTranslate(@LangId, 34757, 'To Value'))
Insert into @Prompts (PromptName, PromptValue) Values ('UpdateTime', dbo.fnTranslate(@LangId, 34654, 'Update Time'))
Insert into @Prompts (PromptName, PromptValue) Values ('UpdateUser', dbo.fnTranslate(@LangId, 34655, 'Update User'))
Insert into @Prompts (PromptName, PromptValue) Values ('ProcessOrder', dbo.fnTranslate(@LangId, 34816, 'Process Order'))
Insert into @Prompts (PromptName, PromptValue) Values ('Path', dbo.fnTranslate(@LangId, 34809, 'Path'))
Insert into @Prompts (PromptName, PromptValue) Values ('QuantityForecast', dbo.fnTranslate(@LangId, 34817, 'Quantity'))
Insert into @Prompts (PromptName, PromptValue) Values ('Product', dbo.fnTranslate(@LangId, 34017, 'Product'))
Insert into @Prompts (PromptName, PromptValue) Values ('TimeForecastStart', dbo.fnTranslate(@LangId, 34011, 'Start Time'))
Insert into @Prompts (PromptName, PromptValue) Values ('TimeForecastEnd', dbo.fnTranslate(@LangId, 34012, 'End Time'))
Insert into @Prompts (PromptName, PromptValue) Values ('ImpliedSequence', dbo.fnTranslate(@LangId, 34818, 'Sequence'))
Insert into @Prompts (PromptName, PromptValue) Values ('BlockNumber', dbo.fnTranslate(@LangId, 34819, 'Block'))
Insert into @Prompts (PromptName, PromptValue) Values ('Status', dbo.fnTranslate(@LangId, 34810, 'Status'))
Insert into @Prompts (PromptName, PromptValue) Values ('ControlType', dbo.fnTranslate(@LangId, 34811, 'Control Type'))
Insert into @Prompts (PromptName, PromptValue) Values ('OrderType', dbo.fnTranslate(@LangId, 34812, 'Order Type'))
Insert into @Prompts (PromptName, PromptValue) Values ('Source', dbo.fnTranslate(@LangId, 34820, 'Source Order'))
Insert into @Prompts (PromptName, PromptValue) Values ('Parent', dbo.fnTranslate(@LangId, 34821, 'Parent Order'))
Insert Into @Prompts (PromptName, PromptValue) Values('Item', dbo.fnTranslate(@LangId, 34797, 'Item'))
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
From @Prompts
--**********************************************
-- Return Data For Report
--**********************************************
Select UpdateTime =   [dbo].[fnServer_CmnConvertFromDbTime] (pp.Entry_On,@InTimeZone) ,
       UpdateUser = u.Username,
 	  	  	  Item = @EventType,
       ProcessOrder = pp.Process_Order,
       Path = e.path_code,
       QuantityForecast = pp.forecast_quantity,
       Product = p.prod_code,
       TimeForecastStart =   [dbo].[fnServer_CmnConvertFromDbTime] (pp.Forecast_Start_Date,@InTimeZone)  ,  
       TimeForecastEnd =  [dbo].[fnServer_CmnConvertFromDbTime] (pp.Forecast_End_Date,@InTimeZone) , 
       ImpliedSequence = pp.implied_sequence,
       BlockNumber = pp.Block_Number,
       Status = s.pp_status_desc,
       ControlType = case pp.control_type
                        When 2 Then @Quantity
                        When 1 Then @Time
                        Else @None
                      End,
       OrderType = t.pp_type_name,
       Source = pp2.process_order,
       Parent = pp3.process_order
  From Production_Plan_History pp
  Join production_plan_statuses s on s.pp_status_id = pp.pp_status_id
  join production_plan_types t on t.pp_type_id = pp.pp_type_id
  join products p on p.prod_id = pp.prod_id
  join users u on u.user_id = pp.user_id
  left outer Join prdexec_paths e on e.path_id = pp.path_id
  left outer join production_plan pp2 on pp2.pp_id = pp.source_pp_id
  left outer join production_plan pp3 on pp3.pp_id = pp.parent_pp_id
  Where pp.pp_id = @EventId
  Order By pp.entry_on ASC
