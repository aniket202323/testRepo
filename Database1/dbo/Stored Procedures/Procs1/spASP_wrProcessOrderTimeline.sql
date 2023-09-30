CREATE procedure [dbo].[spASP_wrProcessOrderTimeline]
  @Line int = NULL,
  @Path int = NULL, 
  @Units nVarChar(1000) = NULL,
  @StartTime datetime, 
  @EndTime datetime,
  @InTimeZone nvarchar(200)=NULL
AS
/*
alter procedure spASP_wrProcessOrderTimeline
@Line int,
@Path int, 
@Units nvarchar(1000),
@StartTime datetime, 
@EndTime datetime
AS
--
*/
-- TODO: Get Status Color Working
Declare @ReportName nvarchar(255)
Declare @CriteriaString nVarChar(1000)
Declare @LineName nVarChar(100)
Declare @UnitName nVarChar(100)
Declare @SQL nvarchar(3000)
SELECT @StartTime=[dbo].[fnServer_CmnConvertToDbTime] (@StartTime,@InTimeZone)  
SELECT @EndTime=[dbo].[fnServer_CmnConvertToDbTime] (@EndTime,@InTimeZone) 
--/*********************************************
-- For Testing
--*********************************************
/*
Declare @Line int,
@Path int, 
@Units nvarchar(1000),
@StartTime datetime, 
@EndTime datetime
Select @Line = NULL
Select @Path = NULL
Select @Units = '2,3'
Select @StartTime = '10-jan-01'
Select @EndTime = dateadd(day,10,dbo.fnServer_CmnGetDate(getutcdate()))*/
--**********************************************/
--**********************************************
-- Translations Setup & Common Prompt Lookup
--**********************************************
-- Retreive the Language Id of the current user
Declare @LangId INT
EXEC spWA_GetCurrentUserInfo @LangId = @LangId OUTPUT
-- Get Common Prompts
DECLARE @Planned nVarChar(100)
SET @Planned = dbo.fnTranslate(@LangId, 34822, 'Planned')
--**********************************************
-- Loookup Parameters For This Report
--**********************************************
Select @ReportName = dbo.fnTranslate(@LangId, 34823, 'Schedule Timeline')
Create Table #Units (
  Item int,
  ItemOrder int
)
If @Line Is Not Null
  Begin
    Select @LineName = pl_desc from prod_lines where pl_id = @Line
    Insert Into #Units (Item, ItemOrder)
      Select PU_Id, PU_Order
        From Prod_Units 
        Where PL_Id = @Line and
              Master_Unit Is Null
  End
Else If @Path is not null
  Begin
  --TODO: Change To Path
  Select @LineName = pl_desc from prod_lines where pl_id = @Line
  End
Else
  Begin
    Select @LineName = 'Unit'
 	  	 Select @SQL = 'Select PU_Id, ItemOrder = CharIndex(convert(nvarchar(10),PU_Id),' + '''' + @Units + '''' + ',1)  From Prod_Units Where PU_Id in ('  + @Units +  ')'
 	  	 Insert Into #Units
 	  	   Exec (@SQL)
  End
--**********************************************
-- Return Header Information
--**********************************************
-- Line1: Report Name
-- Line2: Criteria
-- Line3: Generate Time
-- Line4 - n: Column Names
DECLARE @Prompts TABLE
(
  PromptId int identity(1,1),
  PromptName nvarchar(20),
  PromptValue nvarchar(1000),
  PromptValue_Parameter SQL_Variant,
  PromptValue_Parameter2 SQL_Variant,
  PromptValue_Parameter3 SQL_Variant
)
/*
Create Table #Prompts (
  PromptId int identity(1,1),
  PromptName nvarchar(20),
  PromptValue nvarchar(1000),
  PromptValue_Parameter SQL_Variant,
  PromptValue_Parameter2 SQL_Variant,
  PromptValue_Parameter3 SQL_Variant
)
*/
Insert into @Prompts (PromptName, PromptValue) Values ('ReportName', @ReportName)
Insert into @Prompts (PromptName, PromptValue, PromptValue_Parameter, PromptValue_Parameter2, PromptValue_Parameter3)
  Values('Criteria', dbo.fnTranslate(@LangId, 34824, '{0} Process Orders From [{1}] To [{2}]'), @LineName, [dbo].[fnServer_CmnConvertFromDbTime] (@StartTime,@InTimeZone)  ,   [dbo].[fnServer_CmnConvertFromDbTime] (@EndTime,@InTimeZone) ) 
Insert into @Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('GenerateTime',   dbo.fnTranslate(@LangId, 34521, 'Created: {0}'), dbo.fnServer_CmnGetDate(getutcdate()))
Insert into @Prompts (PromptName, PromptValue) Values ('TabTitle', @LineName)
Insert into @Prompts (PromptName, PromptValue) Values ('Comments', dbo.fnTranslate(@LangId, 34743, 'Comments'))
  select PromptId,
  PromptName ,
  PromptValue ,
  'PromptValue_Parameter'= case when (ISDATE(Convert(varchar,PromptValue_Parameter))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,PromptValue_Parameter),@InTimeZone)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 PromptValue_Parameter
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end ,
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
--Drop Table @Prompts
--**********************************************
-- Return Data For Report
--**********************************************
Create Table #Events (
  Category nvarchar(255),
  Subcategory nvarchar(255) NULL,
  StartTime datetime NULL, 
  EndTime datetime,
  ShortLabel nvarchar(255) NULL,
  LongLabel nvarchar(255) NULL,
  Color int, 
  Hovertext nVarChar(1000) NULL,
  Hyperlink nvarchar(255) NULL,
  SortKey int NULL,
  ItemOrder int NULL,
)
Declare @@Unit int
Declare @@Path int
Declare @ItemOrder int
Select @ItemOrder = 0
Declare Unit_Cursor Insensitive Cursor 
  For Select Item From #Units Order By ItemOrder
  For Read Only
Open Unit_Cursor
Fetch Next From Unit_Cursor Into @@Unit
While @@Fetch_Status = 0
  Begin
    Select @UnitName = PU_Desc From Prod_Units Where PU_Id = @@Unit
    Select @ItemOrder = @ItemOrder + 1
    --*******************************************************************  
    -- Planned Process Orders
    --*******************************************************************  
 	  	 Declare Path_Cursor Insensitive Cursor 
 	  	   For Select Path_id From prdexec_path_units Where PU_Id = @@Unit and is_schedule_point = 1 
 	  	   For Read Only
 	  	 Open Path_Cursor
 	  	 
 	  	 
 	  	 Fetch Next From Path_Cursor Into @@Path
 	  	 
 	  	 While @@Fetch_Status = 0
 	  	   Begin        
 	  	  	     Insert Into #Events (Category, Subcategory, StartTime, EndTime, ShortLabel, LongLabel, Color, HoverText, Hyperlink, SortKey, ItemOrder)
 	  	  	    	   Select Category = @UnitName, 
 	  	  	              Subcategory = @Planned,
 	  	  	              StartTime = Case When pp.Forecast_Start_Date < @StartTime Then @StartTime Else pp.Forecast_Start_Date End,
 	  	  	              EndTime = Case When pp.Forecast_End_Date > @EndTime Then @EndTime Else pp.Forecast_End_Date End,
 	  	  	              ShortLabel = pp.Process_Order,
 	  	  	              LongLabel = pp.Process_Order + ' (' +  s.pp_status_desc + ')' + ' - ' + p.prod_code,
 	  	  	              Color = (Select Color From Colors Where Color_Id = 2),
 	  	  	              HoverText = CONVERT(nvarchar(1000),c.Comment_Text),
 	  	  	  	  	          Hyperlink = 'ProcessOrderDetail.aspx?Id=' + convert(nvarchar(20),pp.pp_Id),
 	  	  	              SortKey = 0,
                   ItemOrder = @ItemOrder
 	  	  	         From Production_Plan pp
 	  	  	         Join production_plan_statuses s on s.pp_status_id = pp.pp_status_id
 	  	  	         Join Products p on p.prod_id = pp.prod_id
 	  	  	         Left Outer Join Comments c On c.Comment_id = pp.Comment_Id
 	  	  	  	  	  	   Where pp.Path_id = @@Path and
 	  	  	  	    	  	       pp.Forecast_Start_date = (Select Max(Forecast_Start_date) From Production_Plan t Where t.Path_Id = @@Path and t.Forecast_Start_date <= @StartTime) and
 	  	  	  	     	         pp.Forecast_end_date > @StartTime
 	  	  	  	  	 Union
 	  	  	    	   Select Category = @UnitName, 
 	  	  	              Subcategory = 'Planned',
 	  	  	              StartTime = Case When pp.Forecast_Start_Date < @StartTime Then @StartTime Else pp.Forecast_Start_Date End,
 	  	  	              EndTime = Case When pp.Forecast_End_Date > @EndTime Then @EndTime Else pp.Forecast_End_Date End,
 	  	  	              ShortLabel = pp.Process_Order,
 	  	  	              LongLabel = pp.Process_Order + ' (' +  s.pp_status_desc + ')' + ' - ' + p.prod_code,
 	  	  	              Color = (Select Color From Colors Where Color_Id = 2),
 	  	  	              HoverText = CONVERT(nvarchar(1000),c.Comment_Text),
 	  	  	  	  	          Hyperlink = 'ProcessOrderDetail.aspx?Id=' + convert(nvarchar(20),pp.pp_Id),
 	  	  	              SortKey = 0,
                   ItemOrder = @ItemOrder
 	  	  	         From Production_Plan pp
 	  	  	         Join production_plan_statuses s on s.pp_status_id = pp.pp_status_id
 	  	  	         Join Products p on p.prod_id = pp.prod_id
 	  	  	         Left Outer Join Comments c On c.Comment_id = pp.Comment_Id
 	  	  	  	  	  	   Where pp.Path_id = @@Path and
 	  	  	  	             pp.Forecast_Start_date > @StartTime and 
 	  	  	  	  	          	 pp.Forecast_Start_date <= @EndTime 
 	  	  	  	    Order by StartTime 
     	  	     
 	  	  	  	 Fetch Next From Path_Cursor Into @@Path
      End
    Close Path_Cursor
    Deallocate Path_Cursor
    --*******************************************************************  
    --*******************************************************************  
    -- Actual Process Orders
    --*******************************************************************  
    Insert Into #Events (Category, Subcategory, StartTime, EndTime, ShortLabel, LongLabel, Color, HoverText, Hyperlink, SortKey, ItemOrder)
   	   Select Category = @UnitName, 
             Subcategory = 'Actual',
             StartTime = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
             EndTime = coalesce(d.End_Time, @EndTime),
             ShortLabel = pp.Process_Order,
             LongLabel = pp.Process_Order + ' (' +  s.pp_status_desc + ')' + ' - ' + p.prod_code,
             Color = (Select Color From Colors Where Color_Id = 1),
             HoverText = CONVERT(nvarchar(1000),c.Comment_Text),
 	  	          Hyperlink = 'ProcessOrderDetail.aspx?Id=' + convert(nvarchar(20),pp.pp_Id),
             SortKey = 1,
             ItemOrder = @ItemOrder
 	  	  	   From Production_Plan_Starts d
        Join Production_Plan pp on pp.pp_id = d.pp_id
        Join production_plan_statuses s on s.pp_status_id = pp.pp_status_id
        Join Products p on p.prod_id = pp.prod_id
        Left Outer Join Comments c On c.Comment_id = d.Comment_Id
 	  	  	   Where d.PU_id = @@Unit and
 	    	  	       d.Start_Time = (Select Max(Start_Time) From Production_Plan_Starts t Where t.PU_Id = @@Unit and t.start_time <= @StartTime) and
 	     	       ((d.End_Time > @StartTime) or (d.End_Time is Null))
 	  	 Union
   	   Select Category = @UnitName, 
             Subcategory = 'Actual',
             StartTime = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
             EndTime = coalesce(d.End_Time, @EndTime),
             ShortLabel = pp.Process_Order,
             LongLabel = pp.Process_Order + ' (' +  s.pp_status_desc + ')' + ' - ' + p.prod_code,
             Color = (Select Color From Colors Where Color_Id = 1),
             HoverText = CONVERT(nvarchar(1000),c.Comment_Text),
 	  	          Hyperlink = 'ProcessOrderDetail.aspx?Id=' + convert(nvarchar(20),pp.pp_Id),
             SortKey = 1,
             ItemOrder = @ItemOrder
 	  	  	   From Production_Plan_Starts d
        Join Production_Plan pp on pp.pp_id = d.pp_id
        Join production_plan_statuses s on s.pp_status_id = pp.pp_status_id
        Join Products p on p.prod_id = pp.prod_id
        Left Outer Join Comments c On c.Comment_id = d.Comment_Id
 	       Where d.PU_id = @@Unit and
 	             d.Start_Time > @StartTime and 
 	  	          	 d.Start_Time <= @EndTime 
 	    Order by StartTime 
    --*******************************************************************  
 	  	 
    Fetch Next From Unit_Cursor Into @@Unit
  End
Close Unit_Cursor
Deallocate Unit_Cursor
Select Category, Subcategory,  [dbo].[fnServer_CmnConvertFromDbTime] (StartTime,@InTimeZone)  , [dbo].[fnServer_CmnConvertFromDbTime](EndTime,@InTimeZone),ShortLabel, LongLabel, Color, Hovertext, Hyperlink
  From #Events
  Order by ItemOrder, SortKey, StartTime ASC 
Drop Table #Events
Drop Table #Units
