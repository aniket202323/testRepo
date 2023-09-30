CREATE procedure [dbo].[spASP_wrInventoryList]
@ReportId int,
@RunId int = NULL
AS
--*********************************************************************************/
/*************************
Set nocount on
Declare @Reportid int, @Runid int
Select @ReportId = 1808
--************************/
declare @TargetTimeZone varchar(200)
Declare @ReportName varchar(255)
Declare @CriteriaString varchar(1000)
Declare @Units varchar(7000)
Declare @Products varchar(7000)
Declare @NonProductiveTimeFilter int
Declare @NPTLabel varchar(255)
Declare @NPTLabelDefault varchar(255)
Declare @NumberOfUnitsReportedOn int
Declare @MaxRowCount int
Declare @RowCount int
Declare @SQLTop varchar(255)
Declare @LocaleId int, @LangId int
select @MaxRowCount = 10000
select @RowCount = 0
select @NPTLabelDefault = '(npt)'
if (Select Count(*) from Site_Parameters where parm_id = 316) = 0
  Select @NPTLabel=@NPTLabelDefault
Else
  select @NPTLabel = Coalesce(case Value when '' then @NPTLabelDefault else value end, @NPTLabelDefault) from Site_Parameters where parm_Id = 316
--/**********************************************
-- Loookup Parameters For This Report Id
--**********************************************
Declare @ReturnValue varchar(7000)
Select @ReportName = Report_Name From Report_Definitions Where Report_Id = @ReportId
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'NonProductiveTimeFilter', @ReportId, @ReturnValue output
Select @NonProductiveTimeFilter = ABS(Coalesce(convert(int,@ReturnValue), 0))
exec spRS_GetReportParamValue 'Units', @ReportId, @Units output
exec spRS_GetReportParamValue 'Products', @ReportId, @Products output
SELECT 	 @ReturnValue = NULL
EXEC 	 spRS_GetReportParamValue 'LocaleId', @ReportId, @ReturnValue output
SELECT 	 @LocaleId = CASE @ReturnValue WHEN NULL THEN 0 ELSE abs(convert(INT, @ReturnValue)) END
SELECT @LangId = Language_id From Language_Locale_Conversion Where LocaleId=@LocaleId
If @LangId is Null SET @LangId = 0
Select @TargetTimeZone = NULL
exec spRS_GetReportParamValue 'TargetTimeZone', @ReportId,@TargetTimeZone output
--**********************************************
-- Check For Required Parameters And Set Defaults
--**********************************************
If @ReportName Is Null 
  Select @ReportName = dbo.fnRS_TranslateString_New(@LangId, 36190, 'Inventory Listing')
If @Units Is Null
  Begin
    exec spRS_AddEngineActivity @ReportName, 0, 'Required [Units] Parameter Is Missing', 2, @ReportId, @RunId
    Raiserror('Required [Units] Parameter Is Missing',16,1)
    return
  End
If @Products = '0' 
  Select @Products = NULL
--**********************************************
-- Return Header Information
--**********************************************
-- Line1: Report Name
-- Line2: Criteria
-- Line3: Generate Time
-- Line4 - n: Column Names
Create Table #Prompts (
 	 PromptId int identity(1,1),
 	 PromptName varchar(20),
 	 PromptValue varchar(1000)
)
Insert into #Prompts (PromptName, PromptValue) Values ('ReportName', @ReportName)
Select @ReportName = dbo.fnRS_TranslateString_New(@LangId, 36190, 'Inventory Listing')
Select @CriteriaString = dbo.fnRS_TranslateString_New(@LangId, 36191, 'Inventory For ')
If @Products Is Null
 	 Select @CriteriaString =  @CriteriaString + ' ' + dbo.fnRS_TranslateString_New(@LangId, 36192, 'All Products') 
Else
 	 Select @CriteriaString =  @CriteriaString + ' ' + dbo.fnRS_TranslateString_New(@LangId, 36130, 'Selected Products')
Select @CriteriaString = @CriteriaString + 
 	 Case 
 	  	 When @NonProductiveTimeFilter=0 Then '<br><i>' + @NPTLabel + ' ' + dbo.fnRS_TranslateString_New(@LangId, 36026, 'Contains') + ' ' + dbo.fnRS_TranslateString_New(@LangId, 42120, 'Non-Productive Time') + '</i>' Else '<br><i>' + dbo.fnRS_TranslateString_New(@LangId, 35193, 'Non-Productive Time Removed') + '</i>' 
 	 End
Insert into #Prompts (PromptName, PromptValue) Values ('Criteria', @CriteriaString)
Insert into #Prompts (PromptName, PromptValue) Values ('GenerateTime', dbo.fnRS_TranslateString_New(@LangId, 36178, 'Created') + ': ' + convert(varchar(25), dbo.fnServer_CmnConvertFromDbTime(dbo.fnServer_CmnGetDate(getutcdate()),@TargetTimeZone),120))
Insert into #Prompts (PromptName, PromptValue) Values ('EventName', dbo.fnRS_TranslateString_New(@LangId, 36193, 'Item'))
Insert into #Prompts (PromptName, PromptValue) Values ('Status', dbo.fnRS_TranslateString_New(@LangId, 36194, 'Status'))
Insert into #Prompts (PromptName, PromptValue) Values ('Conformance', dbo.fnRS_TranslateString_New(@LangId, 36195, 'Conformance'))
Insert into #Prompts (PromptName, PromptValue) Values ('Unit', dbo.fnRS_TranslateString_New(@LangId, 36196, 'Unit'))
Insert into #Prompts (PromptName, PromptValue) Values ('Product', dbo.fnRS_TranslateString_New(@LangId, 36085, 'Product'))
Insert into #Prompts (PromptName, PromptValue) Values ('Dimensions', dbo.fnRS_TranslateString_New(@LangId, 36197, 'Dimensions'))
Insert into #Prompts (PromptName, PromptValue) Values ('Age', dbo.fnRS_TranslateString_New(@LangId, 36198, 'Age'))
Insert into #Prompts (PromptName, PromptValue) Values ('SignedBy', dbo.fnRS_TranslateString_New(@LangId, 36199, 'Signed By'))
Insert into #Prompts (PromptName, PromptValue) Values ('ApprovedBy', dbo.fnRS_TranslateString_New(@LangId, 36200, 'Approved By'))
Insert into #Prompts (PromptName, PromptValue) Values ('Count', dbo.fnRS_TranslateString_New(@LangId, 36201, 'Total Count'))
Insert into #Prompts (PromptName, PromptValue) Values ('Amount', dbo.fnRS_TranslateString_New(@LangId, 36202, 'Total Amount'))
Insert into #Prompts (PromptName, PromptValue) Values ('TargetTimeZone',@TargetTimeZone)
--**********************************************
-- Return Data For Report
--**********************************************
Declare @@UnitId int
Declare @UnitName varchar(100)
Declare @EventName varchar(100)
Declare @DimXName varchar(25)
Declare @DimXUnits varchar(25)
Declare @DimYName varchar(25)
Declare @DimYUnits varchar(25)
Declare @DimZName varchar(25)
Declare @DimZUnits varchar(25)
Declare @DimAName varchar(25)
Declare @DimAUnits varchar(25)
Create Table #Units (
 	 ItemOrder int,
 	 Item int
)
Insert Into #Units (Item, ItemOrder)
 	 execute ('Select PU_Id, ItemOrder = CharIndex(convert(varchar(10),PU_Id),' + '''' + @Units + ''''+ ',1)  From Prod_Units Where PU_Id in (' + @Units + ')')
-- Get An Event Name For Prompts 
Select @@UnitId = min(Item) from #Units
Select @EventName = NULL
select @EventName = s.event_subtype_desc
  from event_configuration e 
  join event_subtypes s on s.Event_Subtype_Id = e.Event_Subtype_Id
  where e.pu_id = @@UnitId and 
        e.et_id = 1
If @EventName Is Not Null
  Update #Prompts Set PromptValue = @EventName 
    Where PromptName = 'EventName' 
-- Now Return Prompts
select * From #Prompts
Drop Table #Prompts
Create Table #Products (
 	 ItemOrder int,
 	 Item int
)
If @Products Is Not Null
  Begin 	  	 
 	 Insert Into #Products (Item, ItemOrder)
 	  	 execute ('Select Prod_Id, ItemOrder = CharIndex(convert(varchar(10),Prod_Id),' + '''' + @Products + ''''+ ',1)  From Products Where Prod_Id in (' + @Products + ')')
  End
Create Table #UnitTotals (
  ItemId int,
  ItemCount int,
  ItemAmount real
)
Create Table #ProductTotals (
  ItemId int,
  ItemCount int,
  ItemAmount real
)
Create Table #StatusTotals (
  ItemId int,
  ItemCount int,
  ItemAmount real
)
-- Loop Through Each Unit's Data
Declare Unit_Cursor Insensitive Cursor 
  For Select Item From #Units Order By ItemOrder
  For Read Only
Open Unit_Cursor
Fetch Next From Unit_Cursor Into @@UnitId
While @@Fetch_Status = 0 and @RowCount < @MaxRowCount
 	 Begin    
 	  	 Create Table #Report (
 	  	  	 EventId  	  	 int,
 	  	  	 EventNumber  	 varchar(100),
 	  	  	 Status  	  	  	 varchar(50),
      	  	 StatusId       	 int, 
 	  	  	 Conformance 	  	 varchar(50) NULL,
 	  	  	 PercentTested 	 int NULL,
 	  	  	 Color 	  	  	 int,
 	  	  	 Unit 	  	  	 varchar(100), 	  	  	  	  	 
 	  	  	 Location 	  	 varchar(100) NULL, 	  	  	  	  	 
 	  	  	 Product 	  	  	 varchar(50) NULL,
       	  	 ProductId      	 int NULL,
 	  	  	 Amount   	  	 real NULL,
 	  	  	 Dimensions 	  	 varchar(255) NULL,
 	  	  	 DimensionText 	 varchar(255) NULL,
 	  	  	 Age 	  	  	  	 int, 
 	  	  	 SignedBy 	  	 varchar(100) NULL, 	  	  	  	  	 
 	  	  	 ApprovedBy     	 varchar(100) NULL,
 	  	  	 Comment 	  	  	 varchar(1000) NULL
 	  	 )
 	  	 Select @UnitName = PU_Desc From Prod_Units Where PU_Id = @@UnitId 
 	  	 
 	  	 select @EventName = s.event_subtype_desc,
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
 	  	   where e.pu_id = @@UnitId and 
 	  	         e.et_id = 1
 	     If @Products Is Not Null
 	  	  	 Begin
 	  	  	  	 Print '@Products Is Not Null'
 	  	  	  	 Insert Into #Report (EventId,EventNumber,Status, StatusId, Conformance,PercentTested,Color,Unit,Location,Product,ProductId, Amount,Dimensions, DimensionText,Age, SignedBy, ApprovedBy,Comment)
 	  	  	  	  	 Select  	 EventId = e.event_id,
 	  	  	  	  	  	  	 EventNumber = e.event_num  + Case When e.Non_Productive_Seconds > 0 Then @NPTLabel Else '' End,
 	  	  	  	  	  	  	 Status = s.prodstatus_desc,
 	  	  	  	  	  	  	 StatusId = e.event_status,                  
 	  	  	  	  	  	  	 Conformance = Case  
 	  	  	  	  	               When e.Conformance = 4 Then 'Entry'
 	  	  	  	  	               When e.Conformance = 3 Then 'Reject'
 	  	  	  	  	               When e.Conformance = 2 Then 'Warning'
 	  	  	  	  	               When e.Conformance = 1 Then 'User'
 	  	  	  	  	               Else 'Good'
 	  	  	  	  	              End, 
 	  	  	  	  	  	  	 PercentTested 	 = e.Testing_Prct_Complete,
 	  	  	  	  	  	  	 Color = Case  
 	  	  	  	  	               When s.Status_Valid_For_Input <> 1 Then 1 --Red
 	  	  	  	  	               When s.Count_For_Production <> 1 Then 2 -- Blue
 	  	  	  	  	               Else -1 --Black
 	  	  	  	  	              End, 
 	  	  	  	  	  	  	 Unit 	 = @UnitName,
 	  	  	  	  	  	  	 Location = ul.location_code,
 	  	  	  	  	  	  	 Product = Case When e.Applied_Product Is Null Then p1.Prod_Code Else p2.Prod_Code End,
 	  	  	  	  	  	  	 ProductId = Case When e.Applied_Product Is Null Then ps.Prod_Id Else e.Applied_Product End,
 	  	  	  	  	  	  	 Amount = d.Initial_Dimension_X,
 	  	  	  	  	  	  	 Dimensions = convert(varchar(20),convert(decimal(18,2),d.Initial_Dimension_X)) + coalesce(' ' + @DimXUnits,''), 
 	  	  	  	  	  	  	 DimensionText = coalesce(@DimXName + ' = ' + convert(varchar(20),convert(decimal(18,2),d.Initial_Dimension_X)) + coalesce(' ' + @DimXUnits,''), '') + 
 	  	  	  	  	  	  	  	 coalesce(', ' + @DimYName + ' = ' + convert(varchar(20),convert(decimal(18,2),d.Initial_Dimension_Y)) + coalesce(' ' + @DimYUnits,''), '') + 
 	  	  	  	  	  	  	  	 coalesce(', ' + @DimZName + ' = ' + convert(varchar(20),convert(decimal(18,2),d.Initial_Dimension_Z)) + coalesce(' ' + @DimZUnits,''), '') + 
 	  	  	  	  	  	  	  	 coalesce(', ' + @DimAName + ' = ' + convert(varchar(20),convert(decimal(18,2),d.Initial_Dimension_A)) + coalesce(' ' + @DimAUnits,''), ''),
 	  	  	  	  	  	  	 Age = datediff(second,e.Timestamp,dbo.fnServer_CmnGetDate(getutcdate())),
 	  	  	  	  	  	  	 SignedBy = u1.Username,
 	  	  	  	  	  	  	 ApprovedBy = u2.Username,
 	  	  	  	  	  	  	 Comment = c.Comment_Text
   	  	  	  	  	 From Events_NPT e
 	  	  	  	  	  	 Join Production_Status s on s.ProdStatus_Id = e.Event_Status and s.Count_For_Inventory = 1
 	  	  	  	  	  	 Join Production_Starts ps on ps.PU_Id = @@UnitId and ps.Start_Time <= e.Timestamp and ((ps.End_Time > e.Timestamp) or (ps.End_Time Is Null))
 	  	  	  	  	  	 Join Products p1 on p1.Prod_Id = ps.Prod_id
 	  	  	  	  	  	 Join #Products pf on pf.Item = coalesce(e.Applied_Product, ps.Prod_Id)
 	  	  	  	  	  	 Left Outer Join Products p2 on p2.Prod_Id = e.Applied_Product
 	  	  	  	  	  	 Left Outer Join Event_Details d on d.Event_Id = e.Event_Id
 	  	  	  	  	  	 Left outer join unit_locations ul on ul.location_id = d.location_id
 	  	  	  	  	  	 Left Outer Join Users u1 on u1.user_id = e.User_Signoff_Id
 	  	  	  	  	  	 Left Outer Join Users u2 on u2.user_id = e.Approver_User_Id
 	  	  	  	  	  	 Left Outer Join Comments c on c.Comment_id = e.Comment_Id
   	  	  	  	  	 Where e.PU_Id = @@UnitId
 	  	  	  	  	  	 and (@NonProductiveTimeFilter = 0 or e.Non_Productive_Seconds = 0) 
 	  	  	  	  	 -- Changed
 	  	  	  	  	 -- + Case When e.Non_Productive_Seconds > 0 then @NPTLabel Else '' End,
 	  	  	 End
 	  	 Else
 	  	  	 Begin
 	  	  	  	 Print '@Products Is Null'
 	  	  	  	 Insert Into #Report (EventId,EventNumber,Status, StatusId, Conformance,PercentTested,Color,Unit,Location,Product,ProductId, Amount,Dimensions, DimensionText,Age, SignedBy, ApprovedBy,Comment)
 	  	  	  	  	 Select EventId = e.event_id,
 	  	  	  	  	  	 EventNumber = e.event_num  + Case When e.Non_Productive_Seconds > 0 Then @NPTLabel Else '' End,
 	  	  	  	  	  	 Status = s.prodstatus_desc,
 	  	  	  	  	  	 StatusId = e.event_status,                  
 	  	  	  	  	  	 Conformance = Case  
 	  	  	  	               When e.Conformance = 4 Then 'Entry'
 	  	  	  	               When e.Conformance = 3 Then 'Reject'
 	  	  	  	               When e.Conformance = 2 Then 'Warning'
 	  	  	  	               When e.Conformance = 1 Then 'User'
 	  	  	  	               Else 'Good'
 	  	  	  	              End, 
 	  	  	  	  	  	 PercentTested = e.Testing_Prct_Complete,
 	  	  	  	  	  	 Color = Case  
 	  	  	  	               When s.Status_Valid_For_Input <> 1 Then 2
 	  	  	  	               When s.Count_For_Production <> 1 Then 1
 	  	  	  	               Else 0
 	  	  	  	              End, 
 	  	  	  	  	  	 Unit 	 = @UnitName,
 	  	  	  	  	  	 Location = ul.location_code,
 	  	  	  	  	  	 Product = Case When e.Applied_Product Is Null Then p1.Prod_Code Else p2.Prod_Code End,
 	  	  	  	  	  	 ProductId 	 = Case When e.Applied_Product Is Null Then ps.Prod_Id Else e.Applied_Product End,
 	  	  	  	  	  	 Amount = d.Initial_Dimension_X,
 	  	  	  	  	  	 Dimensions = convert(varchar(20),convert(decimal(18,2),d.Initial_Dimension_X)) + coalesce(' ' + @DimXUnits,''), 
 	  	  	  	  	  	 DimensionText = coalesce(@DimXName + ' = ' + convert(varchar(20),convert(decimal(18,2),d.Initial_Dimension_X)) + coalesce(' ' + @DimXUnits,''), '') + 
                                  coalesce(', ' + @DimYName + ' = ' + convert(varchar(20),convert(decimal(18,2),d.Initial_Dimension_Y)) + coalesce(' ' + @DimYUnits,''), '') + 
                                  coalesce(', ' + @DimZName + ' = ' + convert(varchar(20),convert(decimal(18,2),d.Initial_Dimension_Z)) + coalesce(' ' + @DimZUnits,''), '') + 
                                  coalesce(', ' + @DimAName + ' = ' + convert(varchar(20),convert(decimal(18,2),d.Initial_Dimension_A)) + coalesce(' ' + @DimAUnits,''), ''),
 	  	  	  	  	  	 /*
 	  	  	  	  	  	 Amount = d.Final_Dimension_X,
 	  	  	  	  	  	 Dimensions = convert(varchar(20),convert(decimal(18,2),d.Final_Dimension_X)) + coalesce(' ' + @DimXUnits,''), 
 	  	  	  	  	  	 DimensionText = coalesce(@DimXName + ' = ' + convert(varchar(20),convert(decimal(18,2),d.Final_Dimension_X)) + coalesce(' ' + @DimXUnits,''), '') + 
                                  coalesce(', ' + @DimYName + ' = ' + convert(varchar(20),convert(decimal(18,2),d.Final_Dimension_Y)) + coalesce(' ' + @DimYUnits,''), '') + 
                                  coalesce(', ' + @DimZName + ' = ' + convert(varchar(20),convert(decimal(18,2),d.Final_Dimension_Z)) + coalesce(' ' + @DimZUnits,''), '') + 
                                  coalesce(', ' + @DimAName + ' = ' + convert(varchar(20),convert(decimal(18,2),d.Final_Dimension_A)) + coalesce(' ' + @DimAUnits,''), ''),
 	  	  	  	  	  	 */
 	  	  	  	  	  	 Age = datediff(second,e.Timestamp,dbo.fnServer_CmnGetDate(getutcdate())),
 	  	  	  	  	  	 SignedBy = u1.Username,
 	  	  	  	  	  	 ApprovedBy = u2.Username,
 	  	  	  	  	  	 Comment = c.Comment_Text
   	  	  	  	  	 From Events_NPT e
 	  	  	  	  	  	 Join Production_Status s on s.ProdStatus_Id = e.Event_Status and s.Count_For_Inventory = 1
 	  	  	  	  	  	 Join Production_Starts ps on ps.PU_Id = @@UnitId and ps.Start_Time <= e.Timestamp and ((ps.End_Time > e.Timestamp) or (ps.End_Time Is Null))
 	  	  	  	  	  	 Join Products p1 on p1.Prod_Id = ps.Prod_id
 	  	  	  	  	  	 Left Outer Join Products p2 on p2.Prod_Id = e.Applied_Product
 	  	  	  	  	  	 Left Outer Join Event_Details d on d.Event_Id = e.Event_Id
 	  	  	  	  	  	 Left outer join unit_locations ul on ul.location_id = d.location_id
 	  	  	  	  	  	 Left Outer Join Users u1 on u1.user_id = e.User_Signoff_Id
 	  	  	  	  	  	 Left Outer Join Users u2 on u2.user_id = e.Approver_User_Id
 	  	  	  	  	  	 Left Outer Join Comments c on c.Comment_id = e.Comment_Id
   	  	  	  	  	 Where e.PU_Id = @@UnitId    
 	  	  	  	  	  	 and (@NonProductiveTimeFilter = 0 or e.Non_Productive_Seconds = 0) 
 	  	  	  	  	 -- Changed
 	  	  	 End
 	  	  	 Insert Into #UnitTotals (ItemId, ItemCount, ItemAmount)
 	  	  	  	 Select @@UnitId, count(EventId), Sum(Amount)
 	  	  	  	  	 From #Report
 	  	  	  	 
 	  	  	 Insert Into #ProductTotals (ItemId, ItemCount, ItemAmount)
 	  	  	  	 Select ProductId, count(EventId), Sum(Amount)
 	  	  	  	  	 From #Report
 	  	  	  	  	 Group By ProductId
 	  	  	  	 
 	  	  	 Insert Into #StatusTotals (ItemId, ItemCount, ItemAmount)
 	  	  	  	 Select StatusId, count(EventId), Sum(Amount)
 	  	  	  	  	 From #Report
 	  	  	  	  	 Group By StatusId
 	  	  	 Select @RowCount = @RowCount + (Select Count(*) From #Report)
 	  	  	 If @RowCount <= @MaxRowCount
 	  	  	  	 Begin 	  	     
 	  	  	  	  	 Select Topic = 'Production Event', TabType = 'Detail', TabTitle = @UnitName
 	  	  	  	  	 Select * From #Report Order By Age DESC
 	  	  	  	 End
 	  	  	 Else
 	  	  	  	 Begin
 	  	  	  	  	 Select Topic = 'Production Event', TabType = 'Detail', TabTitle = @UnitName + ' ' + dbo.fnRS_TranslateString_New(@LangId, 36026,'Contains') + convert(varchar(10), (Select Count(*) From #Report)) + ' ' + dbo.fnRS_TranslateString_New(@LangId, 30011,'Rows') + '. ' + dbo.fnRS_TranslateString_New(@LangId, 12127,'Maximum') + ' ' + dbo.fnRS_TranslateString_New(@LangId, 16310,'Number') + ' ' + dbo.fnRS_TranslateString_New(@LangId, 16259,'of') + ' ' + dbo.fnRS_TranslateString_New(@LangId, 30011,'Rows') + ' [' + convert(varchar(10), @MaxRowCount) + '] ' + dbo.fnRS_TranslateString_New(@LangId, 36400,'Exceeded') + '.  ' + dbo.fnRS_TranslateString_New(@LangId, 38352,'Top') +  convert(varchar(20), @RowCount - @MaxRowCount) + ' '+ dbo.fnRS_TranslateString_New(@LangId, 36401,'Displayed')
 	  	  	  	  	 Select @SQLTop = 'Select Top ' + convert(varchar(20), @RowCount - @MaxRowCount) + ' * From #Report Order By Age DESC'
 	  	  	  	  	 Exec (@SQLTop)
 	  	  	  	 End
 	     Drop Table #Report    
    Fetch Next From Unit_Cursor Into @@UnitId
  End
Close Unit_Cursor
Deallocate Unit_Cursor  
-- Return Summary Resultsets
Declare @ColumnName varchar(50)
Declare @SQL varchar(1000)
Select @ColumnName = 'Unit'
Select Topic = 'Unit', TabType = 'Summary', TabTitle = dbo.fnRS_TranslateString_New(@LangId, 34909,'Unit Summary')
Select @SQL = 'Select min(pu.PU_Desc) as ' + @ColumnName + ', TotalCount = Sum(ItemCount), TotalAmount = sum(ItemAmount) 
 	  	  	 From #UnitTotals
 	  	  	 Join Prod_Units pu on pu.PU_Id = #UnitTotals.ItemId
 	  	  	 Group By ItemId'
Exec (@SQL)
Select @ColumnName = 'Product'
Select Topic = 'Product', TabType = 'Summary', TabTitle = dbo.fnRS_TranslateString_New(@LangId, 36209,'Product Summary')
Select @SQL = 'Select min(p.Prod_Code + ' + '''' + ' - ' + '''' + ' + p.Prod_Desc) as ' + @ColumnName + ', TotalCount = Sum(ItemCount), TotalAmount = sum(ItemAmount) 
 	  	  	 From #ProductTotals
 	  	  	 Join Products p on p.Prod_Id = #ProductTotals.ItemId
 	  	  	 Group By ItemId'
Exec (@SQL)
Select @ColumnName = 'Status'
Select Topic = 'Production Status', TabType = 'Summary', TabTitle = dbo.fnRS_TranslateString_New(@LangId, 36206,'Status Summary')
Select @SQL = 'Select min(s.ProdStatus_Desc) as ' + @ColumnName + ', TotalCount = Sum(ItemCount), TotalAmount = sum(ItemAmount) 
 	  	  	 From #StatusTotals
 	  	  	 Join Production_Status s on s.ProdStatus_Id = #StatusTotals.ItemId
 	  	  	 Group By ItemId'
Exec (@SQL)
Drop Table #Units
Drop Table #Products
Drop Table #UnitTotals
Drop Table #ProductTotals
Drop Table #StatusTotals
