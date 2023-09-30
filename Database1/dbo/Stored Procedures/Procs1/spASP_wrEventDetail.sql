CREATE PROCEDURE [dbo].[spASP_wrEventDetail]
@EventId int,
@Command int = NULL,
@SearchEvent nVarChar(50) = NULL,
@InTimeZone nvarchar(200)=NULL
AS
set arithignore on
set arithabort off
set ansi_warnings off
/*********************************************
-- For Testing
--*********************************************
spASP_wrEventDetail 36540
Declare @EventId int,
@Command int,
@SearchEvent nVarChar(50)
Select @EventId = 327 --2572 --327
Select @Command =  null --3
Select @SearchEvent = null --'218514'
--select * from events where pu_id = 52
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
Declare @DimXName nvarchar(25)
Declare @DimXUnits nvarchar(25)
Declare @DimYName nvarchar(25)
Declare @DimYUnits nvarchar(25)
Declare @DimZName nvarchar(25)
Declare @DimZUnits nvarchar(25)
Declare @DimAName nvarchar(25)
Declare @DimAUnits nvarchar(25)
Declare @ProcessOrderId int
Declare @Initial_Dimension_X real
Declare @Final_Dimension_X real
Declare @Initial_Dimension_Y real
Declare @Final_Dimension_Y real
Declare @Initial_Dimension_Z real
Declare @Final_Dimension_Z real
Declare @Initial_Dimension_A real
Declare @Final_Dimension_A real
Declare @OrderId int
Declare @ShipmentId int
Declare @Shipment nVarChar(100)
Declare @CustomerId int
Declare @CustomerOrder nVarChar(100)
Declare @CustomerCode nVarChar(100)
Declare @CustomerName nvarchar(255)
Declare @ConsigneeId int
Declare @ConsigneeCode nVarChar(100)
Declare @ConsigneeName nvarchar(255)
Declare @ProcessOrder nVarChar(100)
Declare @ProcessOrderStatus nVarChar(50)
Declare @TrendStart datetime
Declare @TrendEnd datetime
Declare @DefaultDisplayId int
Declare @UnitNameNP nvarchar(200)
Declare @IsConfiguredNPTime bit
-- Retreive the Language Id of the current user
Declare @LangId INT
EXEC spWA_GetCurrentUserInfo @LangId = @LangId OUTPUT
Declare @sInitial nVarChar(100)
Declare @sFinal nVarChar(100)
Set @sInitial = dbo.fnTranslate(@LangId, 34721, 'Initial {0}')
Set @sFinal = dbo.fnTranslate(@LangId, 34722, 'Final {0}')
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
 	  	 Select @Unit = PU_Id, @EndTime = Timestamp
 	  	   From Events e
 	  	   Where Event_Id = @EventId 
   	 Select @EventId = NULL
  End
If @Command = 1
  Begin
    -- Scroll Next Event
    Select @EventId = Event_Id 
      From Events 
      Where PU_Id = @Unit and 
            Timestamp = (Select Min(Timestamp) From Events Where PU_Id = @Unit and Timestamp > @EndTime)
  End
Else If @Command = 2
  Begin
    -- Scroll Previous Event
    Select @EventId = Event_Id 
      From Events 
      Where PU_Id = @Unit and
            Timestamp = (Select Max(Timestamp) From Events Where PU_Id = @Unit and Timestamp < @EndTime)
  End
Else If @Command = 3
  Begin
    -- Find Event
 	  	 If @SearchEvent Is Null
 	  	   Begin
 	  	     Raiserror('A Search Event Must Be Supplied To Search',16,1)
 	  	     Return
 	  	   End
    Select @EventId = Event_Id 
      From Events 
      Where PU_Id = @Unit and
            Event_Num = @SearchEvent
  End
--Else This is Just A Straight Query
Declare @Test int
SELECT @Test = Event_Id
FROM EVENTS
WHERE Event_Id = @EventId
If @Test is null 
  BEGIN
    Raiserror('Event Does Not Exist',16,1)
    Return
  END
If @EventId Is Null
  Begin
    Raiserror('Command Did Not Find Event To Return',16,1)
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
       @CommentId = comment_id,
 	    @IsConfiguredNPTime = dbo.fnCmn_IsUnitConfiguredForNPtime(pu_id)  
  From Events e
  Join Production_Status ps on ps.prodstatus_id =  e.event_status
  Where Event_Id = @EventId 
Select @EventType = s.event_subtype_desc,
       @DimXName = s.dimension_x_name,
       @DimYName = s.dimension_y_name,
       @DimZName = s.dimension_z_name,
       @DimAName = s.dimension_a_name,
       @DimXUnits = s.dimension_x_eng_units,
       @DimYUnits = s.dimension_y_eng_units,
       @DimZUnits = s.dimension_z_eng_units,
       @DimAUnits = s.dimension_a_eng_units
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
--TODO: Get Default Display Id
Select @UnitName = PU_Desc,
       @DefaultDisplayId = NULL
 From Prod_Units 
 Where PU_Id = @Unit
Select @ReportName = @EventType + ' ' + @EventName 
If @IsConfiguredNPTime = 1
 	 Set @UnitNameNP = @UnitName + ' (' + dbo.fnTranslate(@LangId, 35130, 'Configured for Non-Productive Time') + ')'
Else
 	 Set @UnitNameNP = @UnitName
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
Insert into #Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('Criteria', dbo.fnTranslate(@LangId, 34665, 'On {0}'), @UnitNameNP)
Insert into #Prompts (PromptName, PromptValue, PromptValue_Parameter) Values('GenerateTime', dbo.fnTranslate(@LangId, 34521, 'Created: {0}'),[dbo].[fnServer_CmnConvertFromDbTime] (dbo.fnServer_CmnGetDate(getutcdate()),@InTimeZone))
Insert into #Prompts (PromptName, PromptValue) Values ('EventInformation', dbo.fnTranslate(@LangId, 34693, 'Event Information'))
Insert into #Prompts (PromptName, PromptValue) Values ('AlarmInformation', dbo.fnTranslate(@LangId, 34694, 'Alarm Information'))
Insert into #Prompts (PromptName, PromptValue) Values ('ElectronicSignature', dbo.fnTranslate(@LangId, 34695, 'Electronic Signature'))
Insert into #Prompts (PromptName, PromptValue) Values ('CustomerInformation', dbo.fnTranslate(@LangId, 34696, 'Customer Information'))
Insert into #Prompts (PromptName, PromptValue) Values ('Comments', dbo.fnTranslate(@LangId, 34697, 'Comments'))
Insert into #Prompts (PromptName, PromptValue) Values ('WasteSummary', dbo.fnTranslate(@LangId, 34698, 'Waste Summary'))
Insert into #Prompts (PromptName, PromptValue) Values ('DowntimeSummary', dbo.fnTranslate(@LangId, 34699, 'Downtime Summary'))
Insert into #Prompts (PromptName, PromptValue) Values ('InputComponents', dbo.fnTranslate(@LangId, 34700, 'Input Components'))
Insert into #Prompts (PromptName, PromptValue) Values ('OutputComponents', dbo.fnTranslate(@LangId, 34701, 'Output Components'))
Insert into #Prompts (PromptName, PromptValue) Values ('ParameterSummary', dbo.fnTranslate(@LangId, 34702, 'Parameter Summary'))
Insert into #Prompts (PromptName, PromptValue) Values ('NPTime', dbo.fnTranslate(@LangId, 35132, 'Non-Productive Time'))
Insert into #Prompts (PromptName, PromptValue) Values ('DataSecurity', dbo.fnTranslate(@LangId, 35258, 'Data Security'))
Insert into #Prompts (PromptName, PromptValue) Values ('Username', dbo.fnTranslate(@LangId, 34703, 'User'))
Insert into #Prompts (PromptName, PromptValue) Values ('Timestamp', dbo.fnTranslate(@LangId, 34704, 'Time'))
Insert into #Prompts (PromptName, PromptValue) Values ('Comment', dbo.fnTranslate(@LangId, 34705, 'Comment'))
Insert into #Prompts (PromptName, PromptValue) Values ('Fault', dbo.fnTranslate(@LangId, 34706, 'Fault'))
Insert into #Prompts (PromptName, PromptValue) Values ('Location', dbo.fnTranslate(@LangId, 34707, 'Location'))
Insert into #Prompts (PromptName, PromptValue) Values ('Reasons', dbo.fnTranslate(@LangId, 34708, 'Reasons'))
Insert into #Prompts (PromptName, PromptValue) Values ('Actions', dbo.fnTranslate(@LangId, 34709, 'Actions'))
Insert into #Prompts (PromptName, PromptValue) Values ('StartTime', dbo.fnTranslate(@LangId, 34710, 'Start'))
Insert into #Prompts (PromptName, PromptValue) Values ('EndTime', dbo.fnTranslate(@LangId, 34711, 'End'))
Insert into #Prompts (PromptName, PromptValue) Values ('Product', dbo.fnTranslate(@LangId, 34712, 'Product'))
Insert into #Prompts (PromptName, PromptValue) Values ('Unit', dbo.fnTranslate(@LangId, 34713, 'Unit'))
Insert into #Prompts (PromptName, PromptValue) Values ('Amount', dbo.fnTranslate(@LangId, 34714, 'Amount'))
Insert into #Prompts (PromptName, PromptValue) Values ('Variable', dbo.fnTranslate(@LangId, 34715, 'Variable'))
Insert into #Prompts (PromptName, PromptValue) Values ('LRL', dbo.fnTranslate(@LangId, 34667, 'Lower Reject'))
Insert into #Prompts (PromptName, PromptValue) Values ('LWL', dbo.fnTranslate(@LangId, 34668, 'Lower Warning'))
Insert into #Prompts (PromptName, PromptValue) Values ('TGT', dbo.fnTranslate(@LangId, 34669, 'Target'))
Insert into #Prompts (PromptName, PromptValue) Values ('UWL', dbo.fnTranslate(@LangId, 34670, 'Upper Warning'))
Insert into #Prompts (PromptName, PromptValue) Values ('URL', dbo.fnTranslate(@LangId, 34671, 'Upper Reject'))
Insert into #Prompts (PromptName, PromptValue) Values ('Value', dbo.fnTranslate(@LangId, 34672, 'Value'))
Insert into #Prompts (PromptName, PromptValue) Values ('EnteredOn', dbo.fnTranslate(@LangId, 34673, 'Entered On'))
Insert into #Prompts (PromptName, PromptValue) Values ('EnteredBy', dbo.fnTranslate(@LangId, 34674, 'Entered By'))
Insert into #Prompts (PromptName, PromptValue) Values ('Status', dbo.fnTranslate(@LangId, 34019, 'Status'))
Insert into #Prompts (PromptName, PromptValue) Values ('Product', dbo.fnTranslate(@LangId, 34017, 'Product'))
Insert into #Prompts (PromptName, PromptValue) Values ('Item', dbo.fnTranslate(@LangId, 34797, 'Item'))
Insert into #Prompts (PromptName, PromptValue) Values ('User', dbo.fnTranslate(@LangId, 34688, 'User'))
Insert into #Prompts (PromptName, PromptValue) Values ('UserReason', dbo.fnTranslate(@LangId, 35154, 'Reason'))
Insert into #Prompts (PromptName, PromptValue) Values ('UserComment', dbo.fnTranslate(@LangId, 34244, 'Comment'))
Insert into #Prompts (PromptName, PromptValue) Values ('Approver', dbo.fnTranslate(@LangId, 35138, 'Approver'))
Insert into #Prompts (PromptName, PromptValue) Values ('ApproverReason', dbo.fnTranslate(@LangId, 35154, 'Reason'))
Insert into #Prompts (PromptName, PromptValue) Values ('ApproverComment', dbo.fnTranslate(@LangId, 34244, 'Comment'))
Insert into #Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('GotoPrevious', dbo.fnTranslate(@LangId, 34716, 'Goto Previous {0}'), @EventType)
Insert into #Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('GotoNext', dbo.fnTranslate(@LangId, 34717, 'Goto Next {0}'), @EventType)
Insert into #Prompts (PromptName, PromptValue) Values ('ViewAudit', dbo.fnTranslate(@LangId, 34610, 'View Audit Trail'))
Insert into #Prompts (PromptName, PromptValue) Values ('ViewGenealogy', dbo.fnTranslate(@LangId, 34718, 'View Genealogy'))
Insert into #Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('ViewTimeline', dbo.fnTranslate(@LangId, 34719, 'View {0} Timeline'), @EventType)
Insert into #Prompts (PromptName, PromptValue) Values ('ViewFlow', dbo.fnTranslate(@LangId, 34720, 'View Flow Timeline'))
Insert into #Prompts (PromptName, PromptValue) Values ('TrendLong', dbo.fnTranslate(@LangId, 34612, 'Trend Long Term'))
Insert into #Prompts (PromptName, PromptValue) Values ('TrendShort', dbo.fnTranslate(@LangId, 34613, 'Trend Short Term'))
Insert into #Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('EventId', '{0}', @EventId)
Insert into #Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('TrendStart', '{0}', [dbo].[fnServer_CmnConvertFromDbTime] (@TrendStart,@InTimeZone))
Insert into #Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('TrendEnd', '{0}', [dbo].[fnServer_CmnConvertFromDbTime] (@TrendEnd,@InTimeZone) )
Insert into #Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('StartTime', '{0}',[dbo].[fnServer_CmnConvertFromDbTime] (@StartTime,@InTimeZone) )
Insert into #Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('EndTime', '{0}', [dbo].[fnServer_CmnConvertFromDbTime] (@EndTime,@InTimeZone))
Insert into #Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('UnitId', '{0}', @Unit)
 	 --select PromptId,PromptName,PromptValue,'PromptValue_Parameter'= case when (ISDATE(Convert(varchar,PromptValue_Parameter))=1)
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,PromptValue_Parameter),@InTimeZone)
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 PromptValue_Parameter
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end
 	  	  	  	  	  	  	  	  	  	  	 
 	 --From #Prompts
 SELECT * FROM #Prompts
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
-- Get Event Detail Information
Select @ShipmentId = Shipment_Item_id, @OrderId = coalesce(Order_Id, -1 * Order_Line_Id), @ProcessOrderId = PP_Id, 
       @Initial_Dimension_X = Initial_Dimension_X, @Final_Dimension_X = Final_Dimension_X,   
       @Initial_Dimension_Y = Initial_Dimension_Y, @Final_Dimension_Y = Final_Dimension_Y, 
       @Initial_Dimension_Z = Initial_Dimension_Z, @Final_Dimension_Z = Final_Dimension_Z, 
       @Initial_Dimension_A = Initial_Dimension_A, @Final_Dimension_A = Final_Dimension_A
   From Event_Details
  Where Event_Id = @EventId
If @OrderId < 0 
  Begin
    Select @OrderId = -1 * @OrderId
    Select @OrderId = Order_Id From customer_order_line_items Where Order_Line_Id = @OrderId 
  End
-- Get Process Order 
If @ProcessOrderId Is Null
  Select @ProcessOrderId = PP_Id 
    From Production_Plan_Starts
    Where PU_Id = @Unit and 
          Start_Time <= @EndTime and 
          ((End_Time > @EndTime) or (End_Time Is Null)) 
If @ProcessOrderId Is Not Null
  Begin
    Select @ProcessOrder = pp.Process_Order, @ProcessOrderStatus = ps.pp_status_desc 
      From Production_Plan pp
      Join production_plan_statuses ps on ps.pp_status_id = pp.pp_status_id 
      Where pp_id = @ProcessOrderId
  End
If @ShipmentId Is Not Null
  Select @Shipment = shipment_number from shipment where shipment_id = @ShipmentId
If @OrderId Is Not Null
  Begin
 	   Select @CustomerId = co.Customer_Id,
           @CustomerOrder = co.Plant_Order_Number,
 	          @CustomerCode = c.Customer_Code,
 	          @CustomerName = c.Customer_Name
 	     From Customer_Orders co 
 	     Join Customer c on c.Customer_Id = co.Customer_Id
 	     Where co.Order_Id = @OrderId
 	   Select @ConsigneeId = co.Consignee_Id,
 	          @ConsigneeCode = c.Customer_Code,
 	          @ConsigneeName = c.Customer_Name
 	     From Customer_Orders co 
 	     Join Customer c on c.Customer_Id = co.Consignee_Id
 	     Where co.Order_Id = @OrderId
 	 End
-- Create Simple Return Table
Create Table #Report (
  [Id] int identity(1,1),
  [Name] nvarchar(50),
  Name_Parameter nvarchar(25),
  Value nvarchar(255) NULL,
  Value_Parameter SQL_Variant,
  Value_Parameter2 SQL_Variant,
  Value_Parameter3 SQL_Variant,
  Hyperlink nvarchar(255) NULL,
 	 Tag int NULL
)
--********************************************************************************
-- Return Basic Event Information
--********************************************************************************
Truncate Table #Report
Insert Into #Report ([Name], Value) Values (dbo.fnTranslate(@LangId, 34019, 'Status'), @Status)
Insert Into #Report ([Name], Value) Values (dbo.fnTranslate(@LangId, 34017, 'Product'), @ProductCode)
Insert Into #Report([Name],Value) Values ('TargetTimeZone',@InTimeZone)
If @ProcessOrderId Is Not Null
  Insert Into #Report ([Name], Value, Value_Parameter, Value_Parameter2, Hyperlink)
    Values (dbo.fnTranslate(@LangId, 35085, 'Process Order'), '{0} ({1})', @ProcessOrder, @ProcessOrderStatus, 'ProcessOrderDetail.aspx?Id=' + convert(nvarchar(15),@ProcessOrderId) + '&TargetTimeZone=' + replace(ISNULL(@InTimeZone,''),' ','+'))
Insert Into #Report ([Name], Value, Value_Parameter) Values (dbo.fnTranslate(@LangId, 34011, 'Start Time'), '{0}', [dbo].[fnServer_CmnConvertFromDbTime] (@StartTime,@InTimeZone))
Insert Into #Report ([Name], Value, Value_Parameter) Values (dbo.fnTranslate(@LangId, 34012, 'End Time'), '{0}', [dbo].[fnServer_CmnConvertFromDbTime] (@EndTime,@InTimeZone))
If @DimXName is not null and @DimXName <> ''
  Insert Into #Report ([Name], Name_Parameter, Value, Value_Parameter, Value_Parameter2)
    Values (REPLACE(@sInitial,'{0}',@DimXName), @DimXName, '{0} {1}', coalesce(@Initial_Dimension_X, 0.0), @DimXUnits)
If @DimYName is not null and @DimYName <> ''
  Insert Into #Report ([Name], Name_Parameter, Value, Value_Parameter, Value_Parameter2)
    Values (REPLACE(@sInitial,'{0}',@DimYName), @DimYName, '{0} {1}', coalesce(@Initial_Dimension_Y, 0.0), @DimYUnits)
If @DimZName is not null and @DimZName <> ''
  Insert Into #Report ([Name], Name_Parameter, Value, Value_Parameter, Value_Parameter2)
    Values (REPLACE(@sInitial,'{0}',@DimZName), @DimZName, '{0} {1}', coalesce(@Initial_Dimension_Z, 0.0), @DimZUnits)
If @DimAName is not null and @DimAName <> ''
  Insert Into #Report ([Name], Name_Parameter, Value, Value_Parameter, Value_Parameter2)
    Values (REPLACE(@sInitial,'{0}',@DimAName), @DimAName, '{0} {1}', coalesce(@Initial_Dimension_A, 0.0), @DimAUnits)
If @DimXName is not null and @DimXName <> ''
  Insert Into #Report ([Name], Name_Parameter, Value, Value_Parameter, Value_Parameter2)
    Values (REPLACE(@sFinal,'{0}',@DimXName), @DimXName, '{0} {1}', coalesce(@Final_Dimension_X, 0.0), @DimXUnits)
If @DimYName is not null and @DimYName <> ''
  Insert Into #Report ([Name], Name_Parameter, Value, Value_Parameter, Value_Parameter2)
    Values (REPLACE(@sFinal,'{0}',@DimYName), @DimYName, '{0} {1}', coalesce(@Final_Dimension_Y, 0.0), @DimYUnits)
If @DimZName is not null and @DimZName <> ''
  Insert Into #Report ([Name], Name_Parameter, Value, Value_Parameter, Value_Parameter2)
    Values (REPLACE(@sFinal,'{0}',@DimZName), @DimZName, '{0} {1}', coalesce(@Final_Dimension_Z, 0.0), @DimZUnits)
If @DimAName is not null and @DimAName <> ''
  Insert Into #Report ([Name], Name_Parameter, Value, Value_Parameter, Value_Parameter2)
    Values (REPLACE(@sFinal,'{0}',@DimAName), @DimAName, '{0} {1}', coalesce(@Final_Dimension_A, 0.0), @DimAUnits)
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
 	 -- 	  	  	  	  	  	  	 'Value_Parameter3 '= case when (ISDATE(Convert(varchar,Value_Parameter3 ))=1)
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,Value_Parameter3),@InTimeZone)
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Value_Parameter3
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end,
 	 -- 	  	  	  	  	  	  	  Hyperlink ,Tag  from #Report Order By Id
SELECT * FROM #Report Order By Id
--********************************************************************************
--********************************************************************************
-- Return Alarm Status
--********************************************************************************
Truncate Table #Report
Declare @HostName nvarchar(255)
Declare @VirtualDirectory nvarchar(255)
Declare @Hyperlink nvarchar(2000)
Select @HostName = value from site_parameters where parm_id = 27
Select @VirtualDirectory = value from site_parameters where parm_id = 160
Insert Into #Report ([Name], Value) Values (dbo.fnTranslate(@LangId, 34723, 'Conformance'), @Conformance)
If @TestingPercent is Not Null
  Insert Into #Report ([Name], Value, Value_Parameter)
    Values(dbo.fnTranslate(@LangId, 34724, 'Testing Percent'), '{0}', @TestingPercent)
Else
  Insert Into #Report ([Name], Value)
    Values(dbo.fnTranslate(@LangId, 34724, 'Testing Percent'), dbo.fnTranslate(@LangId, 34725, 'N/A'))
Declare @HighCount int
Declare @MediumCount int
Declare @LowCount int
execute spASP_appGetUnitAlarmCounts
 	 @Unit,
 	 @StartTime, 
 	 @EndTime,
 	 @HighCount OUTPUT,
 	 @MediumCount OUTPUT,
 	 @LowCount OUTPUT
 	 
 	 
declare @USEHttps nvarchar(255)
declare @protocol nvarchar(10)
set @protocol='http://'
SELECT @USEHttps = Value FROM Site_Parameters WHERE Parm_Id = 90
if (@USEHttps='1')
begin
 set @protocol='https://'
end
-- Todo: This is bad if the link ever changes (or if we start using ssl)!!!!!!
Select @Hyperlink = @protocol + @Hostname  + @VirtualDirectory + 'MSWebPart.aspx?TemplateName=38036&TemplateVersion=1'
Select @Hyperlink = @Hyperlink + '&Unit=' + convert(nvarchar(25),@Unit)
Select @Hyperlink = @Hyperlink + '&StartTime=' + replace(convert(nvarchar(30),  dbo.fnServer_CmnConvertFromDBTime(@StartTime,@InTimeZone) ,109),' ', '+')
Select @Hyperlink = @Hyperlink + '&EndTime=' + replace(convert(nvarchar(30),  dbo.fnServer_CmnConvertFromDBTime(@EndTime,@InTimeZone)  , 109),' ', '+')
Select @Hyperlink = @Hyperlink + '&TargetTimeZone=' + replace(ISNULL(@InTimeZone,''),' ','+')
Insert Into #Report (Name, Value, Value_Parameter, HyperLink) Values (dbo.fnTranslate(@LangId, 34726, 'High Alarm'), '{0}', @HighCount, @Hyperlink + '&PriorityFilter=3')
Insert Into #Report (Name, Value, Value_Parameter, HyperLink) Values (dbo.fnTranslate(@LangId, 34727, 'Medium Alarm'), '{0}', @MediumCount,  @Hyperlink + '&PriorityFilter=2')
Insert Into #Report (Name, Value, Value_Parameter, HyperLink) Values (dbo.fnTranslate(@LangId, 34728, 'Low Alarm'), '{0}', @LowCount,  @Hyperlink + '&PriorityFilter=1')
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
 	 -- 	  	  	  	  	  	  	 'Value_Parameter3 '= case when (ISDATE(Convert(varchar,Value_Parameter3 ))=1)
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,Value_Parameter3),@InTimeZone)
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Value_Parameter3
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end,
 	 -- 	  	  	  	  	  	  	  Hyperlink ,Tag  from #Report Order By Id
 	 
 	 SELECT * FROM #Report Order by Id
--********************************************************************************
--********************************************************************************
-- Return Electronic Signature Information
--********************************************************************************
Truncate Table #Report
Declare @ESigId Int
Select @ESigId = Signature_Id
From Events
Where Event_Id = @EventId
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
 	 -- 	  	  	  	  	  	  	 'Value_Parameter3 '= case when (ISDATE(Convert(varchar,Value_Parameter3 ))=1)
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,Value_Parameter3),@InTimeZone)
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Value_Parameter3
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end,
 	 -- 	  	  	  	  	  	  	  Hyperlink ,Tag  from #Report Order By Id
SELECT * FROM #Report Order By Id
--select top 10 * from events
--spASP_wrEventDetail 327, null, null
--********************************************************************************
--********************************************************************************
-- Return Order and Shipment Information
--********************************************************************************
Truncate Table #Report
If @OrderId Is Not Null
  Begin
    Insert Into #Report ([Name], Value, HyperLink) Values ('Order Number', @CustomerOrder, 'Applications/EventViewer/CustomerOrderDetail.aspx?OrderId=' + convert(nvarchar(10),@OrderId))
    If @ConsigneeId is Not Null
      Insert Into #Report ([Name], Value, Value_Parameter, HyperLink)
        Values(dbo.fnTranslate(@LangId, 34733, 'Ship To'), @ConsigneeName + ' ({0})', @ConsigneeCode, 'Applications/EventViewer/CustomerDetail.aspx?CustomerId=' + convert(nvarchar(10),@ConsigneeId))
    Insert Into #Report ([Name], Value, Value_Parameter, HyperLink)
      Values(dbo.fnTranslate(@LangId, 34734, 'Bill To'), @CustomerName + ' ({0})', @CustomerCode, 'Applications/EventViewer/CustomerDetail.aspx?CustomerId=' + convert(nvarchar(10),@CustomerId))
--    Insert Into #Report ([Name], Value) Values ('Order Number', @CustomerOrder)
--    If @ConsigneeId is Not Null
--      Insert Into #Report ([Name], Value, Value_Parameter)
--        Values(dbo.fnTranslate(@LangId, 34733, 'Ship To'), @ConsigneeName + ' ({0})', @ConsigneeCode)
--    Insert Into #Report ([Name], Value, Value_Parameter)
--      Values(dbo.fnTranslate(@LangId, 34734, 'Bill To'), @CustomerName + ' ({0})', @CustomerCode)
  End
If @ShipmentId Is Not Null
  Begin
 	 /*
    Insert Into #Report (Name, Value, HyperLink)
      Values(dbo.fnTranslate(@LangId, 34735, 'Shipment'), @Shipment, 'ShipmentDetail.aspx?Id=' + convert(nvarchar(10), @ShipmentId))
 	 */
    Insert Into #Report (Name, Value)
      Values(dbo.fnTranslate(@LangId, 34735, 'Shipment'), @Shipment)
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
 	 -- 	  	  	  	  	  	  	 'Value_Parameter3 '= case when (ISDATE(Convert(varchar,Value_Parameter3 ))=1)
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,Value_Parameter3),@InTimeZone)
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Value_Parameter3
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end,
 	 -- 	  	  	  	  	  	  	  Hyperlink ,Tag  from #Report Order By Id
 SELECT * FROM  #Report Order By Id
--********************************************************************************
--********************************************************************************
-- Return Comments
--********************************************************************************
Select Username = u.Username, Timestamp =   [dbo].[fnServer_CmnConvertFromDbTime] (c.Modified_On,@InTimeZone)  , Comment = c.Comment_Text 
  From Comments c
  Join Users u on u.user_id = c.User_id 
  Where c.TopOfChain_Id = @CommentId Or c.Comment_Id = @CommentId
--********************************************************************************
--********************************************************************************
-- Return Waste Information
--********************************************************************************
DECLARE @sUnspecified nVarChar(100)
SET @sUnspecified = dbo.fnTranslate(@LangId, 34519, '*Unspecified*')
Select 'Timestamp'=  [dbo].[fnServer_CmnConvertFromDbTime] ([Timestamp],@InTimeZone)  ,
       Fault = case When wef.WEFault_Name Is Null Then @sUnspecified Else wef.WEFault_Name End, 
       Amount = ISNULL(d.Amount, 0),
       Location = case When pu.PU_Desc Is Null Then @sUnspecified Else pu.PU_Desc End,
       Reasons = coalesce(r1.event_reason_name, @sUnspecified)  + coalesce(',' + r2.event_reason_name,'') + coalesce(',' + r3.event_reason_name,'') + coalesce(',' + r4.event_reason_name,''),
       Actions = coalesce(a1.event_reason_name, @sUnspecified)  + coalesce(',' + a2.event_reason_name,'') + coalesce(',' + a3.event_reason_name,'') + coalesce(',' + a4.event_reason_name,''),
       Hyperlink = 'WasteDetail.aspx?Id=' + convert(nvarchar(10),d.WED_Id) + '&TargetTimeZone=' + replace(ISNULL(@InTimeZone,''),' ','+')
       --Comment = c.Comment_Text
  From Waste_Event_Details d
  Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.reason_level1
  Left Outer Join Event_Reasons r2 on r2.event_reason_id = d.reason_level2
  Left Outer Join Event_Reasons r3 on r3.event_reason_id = d.reason_level3
  Left Outer Join Event_Reasons r4 on r4.event_reason_id = d.reason_level4
  Left Outer Join Event_Reasons a1 on a1.event_reason_id = d.action_level1
  Left Outer Join Event_Reasons a2 on a2.event_reason_id = d.action_level2
  Left Outer Join Event_Reasons a3 on a3.event_reason_id = d.action_level3
  Left Outer Join Event_Reasons a4 on a4.event_reason_id = d.action_level4
  Left Outer Join Waste_Event_Fault wef on wef.wefault_id = d.wefault_id
  Left Outer Join Prod_Units pu on pu.pu_id = d.source_pu_id
  --Left Outer Join Comments c on c.Comment_id = d.comment_id
  Where d.Event_Id = @EventId
--********************************************************************************
--********************************************************************************
-- Return Downtime Information
--********************************************************************************
/*
 	 select * from Timed_Event_Details
spASP_wrEventDetail 327
*/
Select StartTime =   [dbo].[fnServer_CmnConvertFromDbTime] ((Case When Start_Time < @StartTime Then @StartTime Else Start_Time End),@InTimeZone)  ,
       EndTime =   [dbo].[fnServer_CmnConvertFromDbTime] ((Case When End_Time < @EndTime Then End_Time Else @EndTime End),@InTimeZone)  , 
       Fault = case When tef.tEFault_Name Is Null Then @sUnspecified Else tef.tEFault_Name End, 
       Location = case When pu.PU_Desc Is Null Then @sUnspecified Else pu.PU_Desc End,
       Reasons = coalesce(r1.event_reason_name, @sUnspecified)  + coalesce(',' + r2.event_reason_name,'') + coalesce(',' + r3.event_reason_name,'') + coalesce(',' + r4.event_reason_name,''),
       Actions = coalesce(a1.event_reason_name, @sUnspecified)  + coalesce(',' + a2.event_reason_name,'') + coalesce(',' + a3.event_reason_name,'') + coalesce(',' + a4.event_reason_name,''),
       Hyperlink = 'DowntimeDetail.aspx?Id=' + CONVERT(nvarchar(10),d.TEDET_Id)+ '&TargetTimeZone=' + replace(ISNULL(@InTimeZone,''),' ','+')
       --Comment = c.Comment_Text
  From Timed_Event_Details d
  Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.reason_level1
  Left Outer Join Event_Reasons r2 on r2.event_reason_id = d.reason_level2
  Left Outer Join Event_Reasons r3 on r3.event_reason_id = d.reason_level3
  Left Outer Join Event_Reasons r4 on r4.event_reason_id = d.reason_level4
  Left Outer Join Event_Reasons a1 on a1.event_reason_id = d.action_level1
  Left Outer Join Event_Reasons a2 on a2.event_reason_id = d.action_level2
  Left Outer Join Event_Reasons a3 on a3.event_reason_id = d.action_level3
  Left Outer Join Event_Reasons a4 on a4.event_reason_id = d.action_level4
  Left Outer Join Timed_Event_Fault tef on tef.tefault_id = d.tefault_id
  Left Outer Join Prod_Units pu on pu.pu_id = d.source_pu_id
  --Left Outer Join Comments c on c.Comment_id = d.comment_id
  Where d.PU_Id = @Unit and 
 	       d.Start_Time = (Select Max(Start_Time) From Timed_Event_Details t Where t.PU_Id = @Unit and t.start_time < @StartTime) and
      ((d.End_Time > @StartTime) or (d.End_Time is Null))
Union
Select StartTime =  [dbo].[fnServer_CmnConvertFromDbTime] ((Case When Start_Time < @StartTime Then @StartTime Else Start_Time End),@InTimeZone)  ,
       EndTime =   [dbo].[fnServer_CmnConvertFromDbTime] ((Case When End_Time < @EndTime Then End_Time Else @EndTime End),@InTimeZone)   ,
       Fault = case When tef.tEFault_Name Is Null Then @sUnspecified Else tef.tEFault_Name End, 
       Location = case When pu.PU_Desc Is Null Then @sUnspecified Else pu.PU_Desc End,
       Reasons = coalesce(r1.event_reason_name, @sUnspecified)  + coalesce(',' + r2.event_reason_name,'') + coalesce(',' + r3.event_reason_name,'') + coalesce(',' + r4.event_reason_name,''),
       Actions = coalesce(a1.event_reason_name, @sUnspecified)  + coalesce(',' + a2.event_reason_name,'') + coalesce(',' + a3.event_reason_name,'') + coalesce(',' + a4.event_reason_name,''),
       Hyperlink = 'DowntimeDetail.aspx?Id=' + CONVERT(nvarchar(10),d.TEDET_Id)+ '&TargetTimeZone=' + replace(ISNULL(@InTimeZone,''),' ','+')
       --Comment = c.Comment_Text
  From Timed_Event_Details d
  Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.reason_level1
  Left Outer Join Event_Reasons r2 on r2.event_reason_id = d.reason_level2
  Left Outer Join Event_Reasons r3 on r3.event_reason_id = d.reason_level3
  Left Outer Join Event_Reasons r4 on r4.event_reason_id = d.reason_level4
  Left Outer Join Event_Reasons a1 on a1.event_reason_id = d.action_level1
  Left Outer Join Event_Reasons a2 on a2.event_reason_id = d.action_level2
  Left Outer Join Event_Reasons a3 on a3.event_reason_id = d.action_level3
  Left Outer Join Event_Reasons a4 on a4.event_reason_id = d.action_level4
  Left Outer Join Timed_Event_Fault tef on tef.tefault_id = d.tefault_id
  Left Outer Join Prod_Units pu on pu.pu_id = d.source_pu_id
  --Left Outer Join Comments c on c.Comment_id = d.comment_id
  Where d.PU_Id = @Unit and 
        d.Start_Time > @StartTime and 
 	  	     d.Start_Time <= @EndTime 
--********************************************************************************
--********************************************************************************
-- Return Genealogy Input Information
--********************************************************************************
--TODO: Use Timestamp of event component when available
Select Item = e.Event_Num, 
       [Timestamp] =   [dbo].[fnServer_CmnConvertFromDbTime] (e.[timestamp],@InTimeZone)  ,
       Product = Case When e.Applied_Product Is Null Then p1.Prod_Code Else p2.Prod_Code End,
       Unit = pu.PU_Desc,
       Amount = '{0} ' + coalesce(es.Dimension_X_eng_units, ''),
       Amount_Parameter = coalesce(d.Dimension_X,0),
       Hyperlink = 'EventDetail.aspx?Id=' + convert(nvarchar(25),e.Event_id) + '&TargetTimeZone=' + replace(ISNULL(@InTimeZone,''),' ','+')
  From event_components d
  Join events e on e.event_id = d.source_event_id
  Join prod_units pu on pu.pu_id = e.pu_id
  Join production_starts ps on ps.pu_id = e.pu_id and ps.Start_Time <= e.Timestamp and ((ps.End_Time > e.Timestamp) or (ps.End_Time is Null))
  join products p1 on p1.prod_id = ps.Prod_Id
  Left Outer join products p2 on p2.prod_id = e.applied_product 
  Left outer Join event_configuration ec on ec.pu_id = e.pu_id and ec.et_id = 1
  Left outer join event_subtypes es on es.Event_Subtype_Id = ec.Event_Subtype_Id
  Where d.Event_Id = @EventId
  Order by e.Timestamp DESC
--********************************************************************************
 	  	  	   	  	  	  	 
--********************************************************************************
-- Return Genealogy Output Information
--********************************************************************************
--TODO: Use Timestamp of event component when available
Select * from (
  Select Item = UDE.UDE_Desc, 
       [Timestamp] =   [dbo].[fnServer_CmnConvertFromDbTime] (UDE.End_Time,@InTimeZone)  ,
       Product = null,
       Unit = pu.PU_Desc,
       Amount = '0',
       Amount_Parameter = null,
       Hyperlink = 'UDEDetail.aspx?Id=' + convert(nvarchar(25),UDE.UDE_id)+ '&TargetTimeZone=' + replace(ISNULL(@InTimeZone,''),' ','+')
  From User_Defined_Events UDE
  Join prod_units pu on pu.pu_id = UDE.pu_id
  Where UDE.Event_Id = @EventId
UNION
  Select Item = e.Event_Num, 
       [Timestamp] =   [dbo].[fnServer_CmnConvertFromDbTime] ( e.[timestamp],@InTimeZone)  ,
       Product = Case When e.Applied_Product Is Null Then p1.Prod_Code Else p2.Prod_Code End,
       Unit = pu.PU_Desc,
       Amount = '{0} ' + coalesce(es.Dimension_X_eng_units, ''),
       Amount_Parameter = coalesce(d.Dimension_X, 0),
       Hyperlink = 'EventDetail.aspx?Id=' + convert(nvarchar(25),e.Event_id)+ '&TargetTimeZone=' + replace(ISNULL(@InTimeZone,''),' ','+')
  From event_components d
  Join events e on e.event_id = d.event_id
  Join prod_units pu on pu.pu_id = e.pu_id
  Join production_starts ps on ps.pu_id = e.pu_id and ps.Start_Time <= e.Timestamp and ((ps.End_Time > e.Timestamp) or (ps.End_Time is Null))
  join products p1 on p1.prod_id = ps.Prod_Id
  Left Outer join products p2 on p2.prod_id = e.applied_product 
  Left outer Join event_configuration ec on ec.pu_id = e.pu_id and ec.et_id = 1
  Left outer join event_subtypes es on es.Event_Subtype_Id = ec.Event_Subtype_Id
  Where d.Source_Event_Id = @EventId
) OutputEvents order by OutputEvents.[Timestamp] DESC
--********************************************************************************
--********************************************************************************
-- Return Parameter Information
--********************************************************************************
If @DefaultDisplayId Is Null
  Begin
    Select GroupOrder = pug.pug_order,
           ItemOrder = v.pug_order,
           IsTitle = 0,
           Unit = case when pu.Master_Unit Is Null then pu.pu_id else pu.Master_Unit End,
           [Id] = v.var_id,
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
           Interpolated = 0,
           Variable = v.var_desc,
           EngineeringUnits = v.eng_units,
           LRL = dbo.fnDisplayVarcharValue(v.Data_Type_Id, vs.L_Reject),
           LWL = dbo.fnDisplayVarcharValue(v.Data_Type_Id, vs.L_Warning),
           TGT = dbo.fnDisplayVarcharValue(v.Data_Type_Id, vs.Target),
           UWL = dbo.fnDisplayVarcharValue(v.Data_Type_Id, vs.U_Warning),
           URL = dbo.fnDisplayVarcharValue(v.Data_Type_Id, vs.U_Reject),
           Value = dbo.fnDisplayVarcharValue(v.Data_Type_Id, t.Result), 
           EnteredOn = [dbo].[fnServer_CmnConvertFromDbTime] (t.Entry_On,@InTimeZone), --Sarla
           EnteredBy = u.Username,
 	  	  	  	  	  [User] = esig_pu.Username + ' ({0})',
 	  	  	  	  	  User_Parameter =   [dbo].[fnServer_CmnConvertFromDbTime] (esig.Perform_Time,@InTimeZone)  , 
 	  	  	  	  	  UserReason = pr.Event_Reason_Name,
 	  	  	  	  	  UserComment = esig.Perform_Comment_Id,
 	  	  	  	  	  Approver = esig_vu.Username + ' ({0})',
 	  	  	  	  	  Approver_Parameter =   [dbo].[fnServer_CmnConvertFromDbTime] (esig.Verify_Time,@InTimeZone)  , 
 	  	  	  	  	  ApproverReason = vr.Event_Reason_Name,
 	  	  	  	  	  ApproverComment = esig.Verify_Comment_Id
      From Variables v
      Join prod_units pu on pu.pu_id = v.pu_id and pu.pu_id = @Unit or pu.master_Unit = @Unit
      Join pu_groups pug on pug.pu_id = pu.pu_id and pug.pug_id = v.pug_id
      left outer join tests t on t.var_id = v.var_id and t.result_on = @EndTime
      left outer join var_specs vs on vs.prod_id = @ProductId and vs.var_id = v.var_id and vs.effective_date <= @EndTime and ((vs.expiration_date > @EndTime) or (vs.expiration_date is null))
      left outer join users u on u.user_id = t.entry_by
 	  	  	 left outer join esignature esig on esig.signature_id = t.signature_id
 	  	  	 left outer join users esig_pu on esig.Perform_User_Id = esig_pu.user_id
 	  	  	 left outer join users esig_vu on esig.Verify_User_Id = esig_vu.user_id
 	  	  	 left outer join event_reasons pr On esig.Perform_Reason_Id = pr.Event_Reason_Id
 	  	  	 left outer join event_reasons vr On esig.Verify_Reason_Id = vr.Event_Reason_Id
--select * from esignature
--spASP_wrEventDetail 327, null, null
      where v.event_type = 1 and v.pu_id <> 0
    Union All
    Select GroupOrder = pug.pug_order,
           ItemOrder = -1000,
           IsTitle = 1,
           Unit = case when pu.Master_Unit Is Null then pu.pu_id else pu.Master_Unit End,
           Id = 0,
           Color = 0,
           Interpolated = 0,
           Variable = pug.pug_desc,
           EngineeringUnits = null,
           LRL = null,
           LWL = null,
           TGT = null,
           UWL = null,
           URL = null,
           Value = null,
           EnteredOn = null,
           EnteredBy = null,
 	  	  	  	  	  [User] = null,
 	  	  	  	  	  User_Parameter = null,
 	  	  	  	  	  UserReason = null,
 	  	  	  	  	  UserComment = null,
 	  	  	  	  	  Approver = null,
 	  	  	  	  	  Approver_Parameter = null,
 	  	  	  	  	  ApproverReason = null,
 	  	  	  	  	  ApproverComment = null
      From pu_groups pug
      Join prod_units pu on pu.pu_id = pug.pu_id and (pu.pu_id = @Unit or pu.master_Unit = @Unit) 
      Order By Unit, GroupOrder, ItemOrder 
  End
Else
  Begin
    Select GroupOrder = 1,
           ItemOrder = sv.var_order,
           IsTitle = case when sv.var_id is null then 1 else 0 End,
           Unit = case when pu.Master_Unit Is Null then pu.pu_id else pu.Master_Unit End,
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
           Interpolated = 0,
           Variable = case when sv.var_id is null then sv.title else v.var_desc end,
           EngineeringUnits = v.eng_units,
           LRL = dbo.fnDisplayVarcharValue(v.Data_Type_Id, vs.L_Reject),
           LWL = dbo.fnDisplayVarcharValue(v.Data_Type_Id, vs.L_Warning),
           TGT = dbo.fnDisplayVarcharValue(v.Data_Type_Id, vs.Target),
           UWL = dbo.fnDisplayVarcharValue(v.Data_Type_Id, vs.U_Warning),
           URL = dbo.fnDisplayVarcharValue(v.Data_Type_Id, vs.U_Reject),
           Value = dbo.fnDisplayVarcharValue(v.Data_Type_Id, t.Result),
           EnteredOn = [dbo].[fnServer_CmnConvertFromDbTime] (t.Entry_On,@InTimeZone),
           EnteredBy = u.Username,
 	  	  	  	  	  [User] = esig_pu.Username + ' ({0})',
 	  	  	  	  	  User_Parameter =   [dbo].[fnServer_CmnConvertFromDbTime] (esig.Perform_Time,@InTimeZone)  ,
 	  	  	  	  	  UserReason = pr.Event_Reason_Name,
 	  	  	  	  	  UserComment = esig.Perform_Comment_Id,
 	  	  	  	  	  Approver = esig_vu.Username + ' ({0})',
 	  	  	  	  	  Approver_Parameter =  [dbo].[fnServer_CmnConvertFromDbTime] (esig.Verify_Time,@InTimeZone)  ,
 	  	  	  	  	  ApproverReason = vr.Event_Reason_Name,
 	  	  	  	  	  ApproverComment = esig.Verify_Comment_Id
      From Sheet_Variables sv
      Left outer join variables v on v.var_id = sv.var_id and v.event_type = 1 and v.pu_id <> 0
      left Join prod_units pu on pu.pu_id = @Unit or pu.master_Unit = @Unit
      left Join pu_groups pug on pug.pu_id = pu.pu_id and pug.pug_id = v.pug_id
      left outer join tests t on t.var_id = v.var_id and t.result_on = @EndTime
      left outer join var_specs vs on vs.prod_id = @ProductId and vs.var_id = v.var_id and vs.effective_date <= @EndTime and ((vs.expiration_date > @EndTime) or (vs.expiration_date is null))
      left outer join users u on u.user_id = t.entry_by
 	  	  	 left outer join esignature esig on esig.signature_id = t.signature_id
 	  	  	 left outer join users esig_pu on esig.Perform_User_Id = esig_pu.user_id
 	  	  	 left outer join users esig_vu on esig.Verify_User_Id = esig_vu.user_id
 	  	  	 left outer join event_reasons pr On esig.Perform_Reason_Id = pr.Event_Reason_Id
 	  	  	 left outer join event_reasons vr On esig.Verify_Reason_Id = vr.Event_Reason_Id
      Where sv.Sheet_Id = @DefaultDisplayId
      Order By ItemOrder 
  End
--select * from var_specs
--sp_columns var_specs
--select * from variables
--********************************************************************************
--********************************************************************************
-- Return Non-Productive Data
--********************************************************************************
Select StartTime=  [dbo].[fnServer_CmnConvertFromDbTime] (npd.Start_Time,@InTimeZone)  , EndTime=  [dbo].[fnServer_CmnConvertFromDbTime] (npd.End_Time,@InTimeZone)  ,
 	 Reasons = coalesce(r1.Event_Reason_Name, @sUnspecified)  + coalesce(',' + r2.Event_Reason_Name,'') + coalesce(',' + r3.Event_Reason_Name,'') + coalesce(',' + r4.Event_Reason_Name,''),
 	 u.Username
From NonProductive_Detail npd
Left Outer Join Users u On npd.User_Id = u.User_Id
Left Outer Join Event_Reasons r1 On npd.Reason_Level1 = r1.Event_Reason_Id
Left Outer Join Event_Reasons r2 On npd.Reason_Level2 = r2.Event_Reason_Id
Left Outer Join Event_Reasons r3 On npd.Reason_Level3 = r3.Event_Reason_Id
Left Outer Join Event_Reasons r4 On npd.Reason_Level4 = r4.Event_Reason_Id
Where npd.PU_Id = @Unit
 	 And ((npd.Start_Time > @StartTime And npd.Start_Time < @EndTime) --NPT starts in the range
 	 Or (npd.End_Time > @StartTime And npd.End_Time < @EndTime) --NPT ends in the range
 	 Or (npd.Start_Time <= @StartTime And npd.End_Time >= @EndTime)) --NPT encompasses the range
--********************************************************************************
--********************************************************************************
-- Data Security Data
--********************************************************************************
Truncate Table #Report
Insert Into #Report (Name, Value) 
 	 Select dbo.fnTranslate(@LangId, 34688, 'User'), Value = u.Username
 	 From Events e
 	 Join Users u On e.User_Signoff_Id = u.User_Id
 	 Where e.Event_Id = @EventId
Insert Into #Report (Name, Value) 
 	 Select dbo.fnTranslate(@LangId, 35136, 'User Reason'), Value = r.Event_Reason_Name
 	 From Events e
 	 Join Event_Reasons r On e.User_Reason_Id = r.Event_Reason_Id
 	 Where e.Event_Id = @EventId
Insert Into #Report (Name, Value) 
 	 Select dbo.fnTranslate(@LangId, 35138, 'Approver'), Value = u.Username
 	 From Events e
 	 Join Users u On e.Approver_User_Id = u.User_Id
 	 Where e.Event_Id = @EventId
Insert Into #Report (Name, Value) 
 	 Select dbo.fnTranslate(@LangId, 35139, 'Approver Reason'), Value = r.Event_Reason_Name
 	 From Events e
 	 Join Event_Reasons r On e.Approver_Reason_Id = r.Event_Reason_Id
 	 Where e.Event_Id = @EventId
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
 	 -- 	  	  	  	  	  	  	 'Value_Parameter3 '= case when (ISDATE(Convert(varchar,Value_Parameter3 ))=1)
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,Value_Parameter3),@InTimeZone)
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Value_Parameter3
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end,
 	 -- 	  	  	  	  	  	  	  Hyperlink ,Tag  from #Report Order By Id
 	 
 	 SELECT * FROM #Report Order By Id
--********************************************************************************
Drop Table #Report
