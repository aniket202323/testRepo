Create Procedure dbo.spCMN_ProductionReport
@Unit int,
@StartTime datetime = NULL,
@EndTime datetime = NULL,
@LanguageNumber int = 0,
@DecimalSeparator nvarchar(1) = NULL
AS
Declare @SQL nvarchar(2000)
Declare @MaxNumberOfRows int
Select @MaxNumberOfRows = 1000
If @DecimalSeparator Is Null
  Select @DecimalSeparator = '.'
--*********************************************************************************
-- Prepare Start and End Times
--*********************************************************************************
Declare @Now datetime
Select @Now =  dbo.fnServer_CmnGetDate(getUTCdate())
If @StartTime is Null
   Begin
 	 DECLARE @timeTable table (RRDId Int,PDesc nvarchar(100),PromptId Int,StartTime Datetime,EndTime DateTime)
 	 DECLARE @TZ nvarchar(200)
 	 SELECT @TZ = dbo.fnServer_GetTimeZone(@Unit)
 	 Insert Into @timeTable(RRDId ,PDesc ,PromptId ,StartTime ,EndTime)
 	  	 EXECUTE dbo.spGE_GetRelativeDates @TZ
    	 SELECT @StartTime =StartTime FROM @timeTable Where RRDId = 30
   End
If @EndTime Is Null
  Select @EndTime = @Now
--*********************************************************************************
-- Translate Column Names and Other Strings (By Language)
--*********************************************************************************
Declare @TempString nvarchar(50)
Declare @ResultsetNameGoodProductionList nvarchar(50)
Declare @ResultsetNameBadProductionList nvarchar(50)
Declare @ResultsetNameStatusPareto nvarchar(50)
Declare @ResultsetNameProductPareto nvarchar(50)
Declare @ColumnNameEvent nvarchar(50)
Declare @ColumnNameStatus nvarchar(50)
Declare @ColumnNameStartTime nvarchar(50)
Declare @ColumnNameEndTime nvarchar(50)
Declare @ColumnNameProduct nvarchar(50)
Declare @ColumnNameProductOriginal nvarchar(50)
Declare @ColumnNameProductApplied nvarchar(50)
Declare @ColumnNameDimensionXInitial nvarchar(50)
Declare @ColumnNameDimensionXFinal nvarchar(50)
Declare @ColumnNameDimensionYInitial nvarchar(50)
Declare @ColumnNameDimensionYFinal nvarchar(50)
Declare @ColumnNameDimensionZInitial nvarchar(50)
Declare @ColumnNameDimensionZFinal nvarchar(50)
Declare @ColumnNameDimensionAInitial nvarchar(50)
Declare @ColumnNameDimensionAFinal nvarchar(50)
Declare @ColumnNameTotalProduction nvarchar(50)
Declare @ColumnNameNumberProduction nvarchar(50)
Declare @ColumnNamePercentProduction nvarchar(50)
Select @ResultsetNameGoodProductionList = 'Good Production'
Select @ResultsetNameBadProductionList = 'Bad Production'
Select @ResultsetNameStatusPareto = 'Status Pareto'
Select @ResultsetNameProductPareto = 'Product Pareto'
Select @ColumnNameEvent = 'Event'
Select @ColumnNameStatus = 'Status'
Select @ColumnNameStartTime = 'Start Time'
Select @ColumnNameEndTime = 'End Time'
Select @ColumnNameProduct = 'Product'
Select @ColumnNameProductOriginal = 'Original Product'
Select @ColumnNameProductApplied = 'Applied Product'
Select @ColumnNameDimensionXInitial = 'Initial'
Select @ColumnNameDimensionXFinal = 'Final'
Select @ColumnNameDimensionYInitial = @ColumnNameDimensionXInitial
Select @ColumnNameDimensionYFinal = @ColumnNameDimensionXFinal
Select @ColumnNameDimensionZInitial = @ColumnNameDimensionXInitial
Select @ColumnNameDimensionZFinal = @ColumnNameDimensionXFinal
Select @ColumnNameDimensionAInitial = @ColumnNameDimensionXInitial
Select @ColumnNameDimensionAFinal = @ColumnNameDimensionXFinal
Select @ColumnNameTotalProduction = 'Total Production'
Select @ColumnNameNumberProduction = '#'
Select @ColumnNamePercentProduction = '% Production'
If (Select count(Uses_Start_Time) From Prod_Units Where PU_Id = @Unit and Uses_Start_Time Is Not NULL) = 0
  Select @ColumnNameStartTime = NULL
Declare @TempDimensionX nvarchar(50)
Declare @TempDimensionY nvarchar(50)
Declare @TempDimensionZ nvarchar(50)
Declare @TempDimensionA nvarchar(50)
Select @TempString = NULL
Select @TempDimensionX = NULL
Select @TempDimensionY = NULL
Select @TempDimensionZ = NULL
Select @TempDimensionA = NULL
select @TempString = s.event_subtype_desc, @TempDimensionX = s.dimension_x_name, @TempDimensionY = s.dimension_y_name, @TempDimensionZ = s.dimension_z_name, @TempDimensionA = s.dimension_a_name
  from event_configuration e 
  join event_subtypes s on s.Event_Subtype_Id = e.Event_Subtype_Id
  where e.pu_id = @Unit and 
        e.et_id = 1
Select @ColumnNameEvent = coalesce(@TempString,@ColumnNameEvent)     
Select @ColumnNameNumberProduction = @ColumnNameNumberProduction + coalesce(@TempString,'Events')     
If @LanguageNumber <> 0
  Begin
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24267
    Select @ResultsetNameGoodProductionList = coalesce(@TempString, @ResultsetNameGoodProductionList)     
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24268
    Select @ResultsetNameBadProductionList = coalesce(@TempString, @ResultsetNameBadProductionList)     
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24252
    Select @ResultsetNameStatusPareto = coalesce(@TempString,@ResultsetNameStatusPareto)     
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24253
    Select @ResultsetNameProductPareto = coalesce(@TempString,@ResultsetNameProductPareto)     
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24061
    Select @ColumnNameStatus = coalesce(@TempString,@ColumnNameStatus)     
    if @ColumnNameStartTime Is Not NULL
      Begin
        Select @TempString = NULL
        Select @TempString = Prompt_String 
          From Language_Data
          Where Language_Id = @LanguageNumber and Prompt_Number = 24116
        Select @ColumnNameStartTime = coalesce(@TempString,@ColumnNameStartTime)     
      End
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24117
    Select @ColumnNameEndTime = coalesce(@TempString,@ColumnNameEndTime)     
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24108
    Select @ColumnNameProduct = coalesce(@TempString,@ColumnNameProduct)     
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24254
    Select @ColumnNameProductOriginal = coalesce(@TempString,@ColumnNameProductOriginal)     
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24255
    Select @ColumnNameProductApplied = coalesce(@TempString,@ColumnNameProductApplied)     
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24256
    Select @ColumnNameDimensionXInitial = coalesce(@TempString,@ColumnNameDimensionXInitial)     
    Select @ColumnNameDimensionYInitial = @ColumnNameDimensionXInitial + ' ' + @TempDimensionY
    Select @ColumnNameDimensionZInitial = @ColumnNameDimensionXInitial + ' ' + @TempDimensionZ
    Select @ColumnNameDimensionAInitial = @ColumnNameDimensionXInitial + ' ' + @TempDimensionA
    Select @ColumnNameDimensionXInitial = @ColumnNameDimensionXInitial + ' ' + @TempDimensionX
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24257
    Select @ColumnNameDimensionXFinal = coalesce(@TempString,@ColumnNameDimensionXFinal)     
    Select @ColumnNameDimensionYFinal = @ColumnNameDimensionXFinal + ' ' + @TempDimensionY
    Select @ColumnNameDimensionZFinal = @ColumnNameDimensionXFinal + ' ' + @TempDimensionZ
    Select @ColumnNameDimensionAFinal = @ColumnNameDimensionXFinal + ' ' + @TempDimensionA
    Select @ColumnNameDimensionXFinal = @ColumnNameDimensionXFinal + ' ' + @TempDimensionX
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24269
    Select @ColumnNameTotalProduction = coalesce(@TempString,@ColumnNameTotalProduction)     
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24259
    Select @ColumnNameNumberProduction = coalesce(@TempString,@ColumnNameNumberProduction)     
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24270
    Select @ColumnNamePercentProduction = coalesce(@TempString,@ColumnNamePercentProduction)     
  End
Else  
  Begin
    -- Language = English
    Select @ColumnNameDimensionYInitial = @ColumnNameDimensionXInitial + ' ' + @TempDimensionY
    Select @ColumnNameDimensionZInitial = @ColumnNameDimensionXInitial + ' ' + @TempDimensionZ
    Select @ColumnNameDimensionAInitial = @ColumnNameDimensionXInitial + ' ' + @TempDimensionA
    Select @ColumnNameDimensionXInitial = @ColumnNameDimensionXInitial + ' ' + @TempDimensionX
    Select @ColumnNameDimensionYFinal = @ColumnNameDimensionXFinal + ' ' + @TempDimensionY
    Select @ColumnNameDimensionZFinal = @ColumnNameDimensionXFinal + ' ' + @TempDimensionZ
    Select @ColumnNameDimensionAFinal = @ColumnNameDimensionXFinal + ' ' + @TempDimensionA
    Select @ColumnNameDimensionXFinal = @ColumnNameDimensionXFinal + ' ' + @TempDimensionX
  End
--*********************************************************************************
-- Define Time Columns
--*********************************************************************************
Create Table #ColumnFormats (
  TimeColumns nvarchar(50)
)
If @ColumnNameStartTime Is Not NULL
  Insert Into #ColumnFormats (TimeColumns) 
    Values (@ColumnNameStartTime)
Insert Into #ColumnFormats (TimeColumns) 
  Values (@ColumnNameEndTime)
--*********************************************************************************
-- Define Resultset Names To Be Returned
--*********************************************************************************
Create Table #Resultsets (
  ResultOrder int,
  ResultName nvarchar(50)  
)
--Do Good And Bad Production List After Counting Records In Return
Insert Into #Resultsets (ResultOrder, ResultName)
  Values (3, @ResultsetNameStatusPareto)
Insert Into #Resultsets (ResultOrder, ResultName)
  Values (4, @ResultsetNameProductPareto)
--*********************************************************************************
-- Get Data Into Temporary Table
--*********************************************************************************
Create Table #Details (
  Icon int NULL,
  Event nvarchar(50),
  Status nvarchar(50) NULL,
  Good int NULL,   
  StartTime datetime NULL,
  EndTime datetime,
  oProduct nvarchar(50) NULL,
  aProduct nvarchar(50) NULL,
  rProduct nvarchar(50) NULL,
  iDimensionX float(32) NULL,
  iDimensionY float(32) NULL,
  iDimensionZ float(32) NULL,
  iDimensionA float(32) NULL,
  fDimensionX float(32) NULL,
  fDimensionY float(32) NULL,
  fDimensionZ float(32) NULL,
  fDimensionA float(32) NULL
)
Declare @TotalProduction float(32)
Declare @NumberOfRows int
Insert Into #Details
  Select s.icon_id, e.event_num, s.prodstatus_desc, s.status_valid_for_input, e.start_time, e.timestamp,
         p1.prod_code, p2.prod_code, null, 
         d.initial_dimension_x, d.initial_dimension_y, d.initial_dimension_z, d.initial_dimension_a,  
         d.final_dimension_x, d.final_dimension_y, d.final_dimension_z, d.final_dimension_a  
    From events e
    Left outer Join event_details d on d.event_id = e.event_id 
    Join production_status s on s.prodstatus_id = e.event_status 
    Join production_starts ps on ps.PU_Id = @Unit and ps.Start_Time <= e.timestamp and ((ps.end_time > e.timestamp) or (ps.end_time Is NULL))
    Join products p1 on p1.prod_id = ps.prod_id
    left outer join products p2 on p2.prod_id = e.applied_product
    Where e.PU_Id = @Unit and 
          e.Timestamp  >= @StartTime and
          e.Timestamp < @EndTime
Select @NumberOfRows = count(EndTime), @TotalProduction = sum(coalesce(iDimensionX,0))
  From #Details
Update #Details Set rProduct = coalesce(aProduct, oProduct)
If @NumberOfRows <= @MaxNumberOfRows
  Begin
    Insert Into #Resultsets (ResultOrder, ResultName)
      Values (1, @ResultsetNameGoodProductionList)
    Insert Into #Resultsets (ResultOrder, ResultName)
      Values (2, @ResultsetNameBadProductionList)
  End  
select  @TotalProduction = Coalesce(@TotalProduction,0)
--*********************************************************************************
-- Return Resultset #1 - Resultset Name List
--*********************************************************************************
Select * From #Resultsets
  Order By ResultOrder ASC
Drop Table #Resultsets
--*********************************************************************************
-- Return Resultset #2 - Time Format Column List
--*********************************************************************************
Select * From #ColumnFormats
Drop Table #ColumnFormats
--*********************************************************************************
-- Return Resultset #3 - Good Production List
--*********************************************************************************
If @NumberOfRows <= @MaxNumberOfRows
  Begin
    Select @SQL = 'Select Icon, Event as [' + @ColumnNameEvent + '], Status as [' + @ColumnNameStatus + '] ' 
    If @ColumnNameStartTime Is Not Null 
      Select @SQL = @SQL + ',StartTime as [' + @ColumnNameStartTime + '] '
    Select @SQL = @SQL + ',EndTime as [' + @ColumnNameEndTime + '] '
    Select @SQL = @SQL + ',oProduct as [' + @ColumnNameProductOriginal + '], aProduct as [' + @ColumnNameProductApplied + '] '
    If @ColumnNameDimensionXInitial Is Not Null 
      Select @SQL = @SQL + ',replace(convert(nvarchar(25),convert(decimal(10,2),iDimensionX)),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ') as [' + @ColumnNameDimensionXInitial + '] '
    If @ColumnNameDimensionYInitial Is Not Null 
      Select @SQL = @SQL + ',replace(convert(nvarchar(25),convert(decimal(10,2),iDimensionY)),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ') as [' + @ColumnNameDimensionYInitial + '] '
    If @ColumnNameDimensionZInitial Is Not Null 
      Select @SQL = @SQL + ',replace(convert(nvarchar(25),convert(decimal(10,2),iDimensionZ)),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ') as [' + @ColumnNameDimensionZInitial + '] '
    If @ColumnNameDimensionAInitial Is Not Null 
      Select @SQL = @SQL + ',replace(convert(nvarchar(25),convert(decimal(10,2),iDimensionA)),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ') as [' + @ColumnNameDimensionAInitial + '] '
    If @ColumnNameDimensionXFinal Is Not Null 
      Select @SQL = @SQL + ',replace(convert(nvarchar(25),convert(decimal(10,2),fDimensionX)),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ') as [' + @ColumnNameDimensionXFinal + '] '
    If @ColumnNameDimensionYFinal Is Not Null 
      Select @SQL = @SQL + ',replace(convert(nvarchar(25),convert(decimal(10,2),fDimensionY)),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ') as [' + @ColumnNameDimensionYFinal + '] '
    If @ColumnNameDimensionZFinal Is Not Null 
      Select @SQL = @SQL + ',replace(convert(nvarchar(25),convert(decimal(10,2),fDimensionZ)),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ') as [' + @ColumnNameDimensionZFinal + '] '
    If @ColumnNameDimensionAFinal Is Not Null 
      Select @SQL = @SQL + ',replace(convert(nvarchar(25),convert(decimal(10,2),fDimensionA)),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ') as [' + @ColumnNameDimensionAFinal + '] '
    Select @SQL = @SQL + 'From #Details Where Good > 0 Order By EndTime DESC'
    --print @SQL 
    Execute (@SQL)
  End
--*********************************************************************************
-- Return Resultset #4 - Bad Production List
--*********************************************************************************
If @NumberOfRows <= @MaxNumberOfRows
  Begin
    Select @SQL = 'Select Icon, Event as [' + @ColumnNameEvent + '], Status as [' + @ColumnNameStatus + '] ' 
    If @ColumnNameStartTime Is Not Null 
      Select @SQL = @SQL + ',StartTime as [' + @ColumnNameStartTime + '] '
    Select @SQL = @SQL + ',EndTime as [' + @ColumnNameEndTime + '] '
    Select @SQL = @SQL + ',oProduct as [' + @ColumnNameProductOriginal + '], aProduct as [' + @ColumnNameProductApplied + '] '
    If @ColumnNameDimensionXInitial Is Not Null 
      Select @SQL = @SQL + ',replace(convert(nvarchar(25),convert(decimal(10,2),iDimensionX)),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ') as [' + @ColumnNameDimensionXInitial + '] '
    If @ColumnNameDimensionYInitial Is Not Null 
      Select @SQL = @SQL + ',replace(convert(nvarchar(25),convert(decimal(10,2),iDimensionY)),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ') as [' + @ColumnNameDimensionYInitial + '] '
    If @ColumnNameDimensionZInitial Is Not Null 
      Select @SQL = @SQL + ',replace(convert(nvarchar(25),convert(decimal(10,2),iDimensionZ)),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ') as [' + @ColumnNameDimensionZInitial + '] '
    If @ColumnNameDimensionAInitial Is Not Null 
      Select @SQL = @SQL + ',replace(convert(nvarchar(25),convert(decimal(10,2),iDimensionA)),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ') as [' + @ColumnNameDimensionAInitial + '] '
    If @ColumnNameDimensionXFinal Is Not Null 
      Select @SQL = @SQL + ',replace(convert(nvarchar(25),convert(decimal(10,2),fDimensionX)),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ') as [' + @ColumnNameDimensionXFinal + '] '
    If @ColumnNameDimensionYFinal Is Not Null 
      Select @SQL = @SQL + ',replace(convert(nvarchar(25),convert(decimal(10,2),fDimensionY)),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ') as [' + @ColumnNameDimensionYFinal + '] '
    If @ColumnNameDimensionZFinal Is Not Null 
      Select @SQL = @SQL + ',replace(convert(nvarchar(25),convert(decimal(10,2),fDimensionZ)),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ') as [' + @ColumnNameDimensionZFinal + '] '
    If @ColumnNameDimensionAFinal Is Not Null 
      Select @SQL = @SQL + ',replace(convert(nvarchar(25),convert(decimal(10,2),fDimensionA)),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ') as [' + @ColumnNameDimensionAFinal + '] '
    Select @SQL = @SQL + 'From #Details Where Good = 0 Order By EndTime DESC'
    --print @SQL 
    Execute (@SQL)
  End
--*********************************************************************************
-- Return Resultset #5 - Status Pareto
--*********************************************************************************
Select @SQL = 'Select Status as [' + @ColumnNameStatus + '] ' 
Select @SQL = @SQL + ',replace(convert(nvarchar(25),convert(decimal(15,2),Sum(coalesce(iDimensionX,0.0)))),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ') as [' + @ColumnNameTotalProduction + '] '
Select @SQL = @SQL + ',Count(EndTime) as [' + @ColumnNameNumberProduction + '] '
If @TotalProduction > 0 
  Select @SQL = @SQL + ',replace(convert(nvarchar(25),convert(decimal(15,2),Sum(coalesce(iDimensionX,0.0)) / convert(real,' + convert(nvarchar(25),@TotalProduction) + ') * 100.0)),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ') as [' + @ColumnNamePercentProduction + '] '
Select @SQL = @SQL + 'From #Details Group By Status Order By [' + @ColumnNameTotalProduction + '] DESC' 
--print @SQL 
Execute (@SQL)
--*********************************************************************************
-- Return Resultset #6 - Product Pareto
--*********************************************************************************
Select @SQL = 'Select rProduct as [' + @ColumnNameProduct + '] ' 
Select @SQL = @SQL + ',replace(convert(nvarchar(25),convert(decimal(15,2),Sum(coalesce(iDimensionX,0.0)))),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ') as [' + @ColumnNameTotalProduction + '] '
Select @SQL = @SQL + ',Count(EndTime) as [' + @ColumnNameNumberProduction + '] '
If @TotalProduction > 0 
  Select @SQL = @SQL + ',replace(convert(nvarchar(25),convert(decimal(15,2),Sum(coalesce(iDimensionX,0.0)) / convert(real,' + convert(nvarchar(25),@TotalProduction) + ') * 100.0)),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ') as [' + @ColumnNamePercentProduction + '] '
Select @SQL = @SQL + 'From #Details Group By rProduct Order By [' + @ColumnNameTotalProduction + '] DESC' 
--print @SQL 
Execute (@SQL)
Drop Table #Details
