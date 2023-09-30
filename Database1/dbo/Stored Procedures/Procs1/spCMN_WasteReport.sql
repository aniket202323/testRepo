Create Procedure dbo.spCMN_WasteReport
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
Declare @Hour int
Declare @Minute int
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
Declare @ResultsetNameWasteList nvarchar(50)
Declare @ResultsetNameLocationPareto nvarchar(50)
Declare @ResultsetNameReason1Pareto nvarchar(50)
Declare @ResultsetNameReason2Pareto nvarchar(50)
Declare @ColumnNameEvent nvarchar(50)
Declare @ColumnNameTime nvarchar(50)
Declare @ColumnNameAmount nvarchar(50)
Declare @ColumnNameLocation nvarchar(50)
Declare @ColumnNameReason1 nvarchar(50)
Declare @ColumnNameReason2 nvarchar(50)
Declare @ColumnNameReason3 nvarchar(50)
Declare @ColumnNameReason4 nvarchar(50)
Declare @ColumnNameAction1 nvarchar(50)
Declare @ColumnNameAction2 nvarchar(50)
Declare @ColumnNameTotalWaste nvarchar(50)
Declare @ColumnNameNumberWaste nvarchar(50)
Declare @ColumnNamePercentWaste nvarchar(50)
Declare @ColumnNamePercentProduction nvarchar(50)
Select @ResultsetNameWasteList = 'Waste Details'
Select @ResultsetNameLocationPareto = 'Location Pareto'
Select @ColumnNameEvent = 'Event'
Select @ColumnNameTime = 'Time'
Select @ColumnNameAmount = 'Amount'
Select @ColumnNameLocation = 'Location'
Select @ColumnNameTotalWaste = 'Total Waste'
Select @ColumnNameNumberWaste = 'Events'
Select @ColumnNamePercentWaste = '% Waste'
Select @ColumnNamePercentProduction = '% Production'
Select @TempString = NULL
Select @TempString = Prompt_String 
  From Language_Data
  Where Language_Id = @LanguageNumber and Prompt_Number = 24273
Select @TempString = coalesce(@TempString,'Pareto')     
Select @ColumnNameReason1 = NULL
Select @ColumnNameReason1 = h.Level_Name
  From Prod_Events pe
  Join Event_Reason_Level_Headers h on h.tree_name_id = pe.name_id and h.Reason_Level = 1
  Where pe.PU_Id = @Unit and
        pe.Event_Type = 3
If @ColumnNameReason1 Is Not Null
  Select @ResultsetNameReason1Pareto = @ColumnNameReason1 + ' ' + @TempString
Else
  Select @ResultsetNameReason1Pareto = Null
Select @ColumnNameReason2 = NULL
Select @ColumnNameReason2 = h.Level_Name
  From Prod_Events pe
  Join Event_Reason_Level_Headers h on h.tree_name_id = pe.name_id and h.Reason_Level = 2
  Where pe.PU_Id = @Unit and
        pe.Event_Type = 3
If @ColumnNameReason2 Is Not Null
  Select @ResultsetNameReason2Pareto = @ColumnNameReason2 + ' ' + @TempString
Else
  Select @ResultsetNameReason2Pareto = Null
Select @ColumnNameReason3 = NULL
Select @ColumnNameReason3 = h.Level_Name
  From Prod_Events pe
  Join Event_Reason_Level_Headers h on h.tree_name_id = pe.name_id and h.Reason_Level = 3
  Where pe.PU_Id = @Unit and
        pe.Event_Type = 3
Select @ColumnNameReason4 = NULL
Select @ColumnNameReason4 = h.Level_Name
  From Prod_Events pe
  Join Event_Reason_Level_Headers h on h.tree_name_id = pe.name_id and h.Reason_Level = 4
  Where pe.PU_Id = @Unit and
        pe.Event_Type = 3
Select @ColumnNameAction1 = NULL
Select @ColumnNameAction1 = h.Level_Name
  From Prod_Events pe
  Join Event_Reason_Level_Headers h on h.tree_name_id = pe.Action_Tree_Id and h.Reason_Level = 1
  Where pe.PU_Id = @Unit and
        pe.Event_Type = 3
Select @ColumnNameAction2 = NULL
Select @ColumnNameAction2 = h.Level_Name
  From Prod_Events pe
  Join Event_Reason_Level_Headers h on h.tree_name_id = pe.Action_Tree_Id and h.Reason_Level = 2
  Where pe.PU_Id = @Unit and
        pe.Event_Type = 3
Select @TempString = NULL
select @TempString = s.event_subtype_desc
  from event_configuration e 
  join event_subtypes s on s.Event_Subtype_Id = e.Event_Subtype_Id
  where e.pu_id = @Unit and 
        e.et_id = 1
Select @ColumnNameEvent = coalesce(@TempString,@ColumnNameEvent)     
If @LanguageNumber <> 0
  Begin
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24053
    Select @ResultsetNameWasteList = coalesce(@TempString,@ResultsetNameWasteList)     
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24271
    Select @ResultsetNameLocationPareto = coalesce(@TempString,@ResultsetNameLocationPareto)     
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24105
    Select @ColumnNameTime = coalesce(@TempString,@ColumnNameTime)     
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24125
    Select @ColumnNameAmount = coalesce(@TempString,@ColumnNameAmount)     
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24223
    Select @ColumnNameLocation = coalesce(@TempString,@ColumnNameLocation)     
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24278
    Select @ColumnNameTotalWaste = coalesce(@TempString,@ColumnNameTotalWaste)     
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24275
    Select @ColumnNameNumberWaste = coalesce(@TempString,@ColumnNameNumberWaste)     
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24279
    Select @ColumnNamePercentWaste = coalesce(@TempString,@ColumnNamePercentWaste)     
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24270
    Select @ColumnNamePercentProduction = coalesce(@TempString,@ColumnNamePercentProduction)     
  End
--*********************************************************************************
-- Define Time Columns
--*********************************************************************************
Create Table #ColumnFormats (
  TimeColumns nvarchar(50)
)
Insert Into #ColumnFormats (TimeColumns) 
  Values (@ColumnNameTime)
--*********************************************************************************
-- Define Resultset Names To Be Returned
--*********************************************************************************
Create Table #Resultsets (
  ResultOrder int,
  ResultName nvarchar(50)  
)
--Do Waste List After Counting Records In Return
Insert Into #Resultsets (ResultOrder, ResultName)
  Values (2, @ResultsetNameLocationPareto)
If @ResultsetNameReason1Pareto Is Not Null
  Insert Into #Resultsets (ResultOrder, ResultName)
    Values (3, @ResultsetNameReason1Pareto)
If @ResultsetNameReason2Pareto Is Not Null
  Insert Into #Resultsets (ResultOrder, ResultName)
    Values (4, @ResultsetNameReason2Pareto)
--*********************************************************************************
-- Get Data Into Temporary Table
--*********************************************************************************
Create Table #Details (
  Time datetime,
  Event nvarchar(50) NULL,
  Amount float(32) NULL,
  Location nvarchar(50) NULL,
  Reason1 nvarchar(100) NULL,
  Reason2 nvarchar(100) NULL,
  Reason3 nvarchar(100) NULL,
  Reason4 nvarchar(100) NULL,
  Action1 nvarchar(100) NULL,
  Action2 nvarchar(100) NULL
)
Declare @TotalWaste float(32)
Declare @TotalProduction float(32)
DEclare @NumberOfRows int
Insert Into #Details
  Select e.Timestamp, e.event_num, d.amount, pu.PU_Desc,
         r1.Event_Reason_Name, r2.Event_Reason_Name, r3.Event_Reason_Name, r4.Event_Reason_Name,
         a1.Event_Reason_Name, a2.Event_Reason_Name
    From events e
    Join Waste_Event_Details d on d.event_id = e.event_id and d.amount is not null
    Left Outer Join Prod_Units pu on pu.pu_id = d.source_pu_id
    Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.reason_level1  
    Left Outer Join Event_Reasons r2 on r2.event_reason_id = d.reason_level2  
    Left Outer Join Event_Reasons r3 on r3.event_reason_id = d.reason_level3  
    Left Outer Join Event_Reasons r4 on r4.event_reason_id = d.reason_level4  
    Left Outer Join Event_Reasons a1 on a1.event_reason_id = d.action_level1  
    Left Outer Join Event_Reasons a2 on a2.event_reason_id = d.action_level2  
    Where e.PU_Id = @Unit and 
          e.Timestamp  >= @StartTime and
          e.Timestamp < @EndTime
  Union
  Select d.Timestamp, null, d.amount, pu.PU_Desc,
         r1.Event_Reason_Name, r2.Event_Reason_Name, r3.Event_Reason_Name, r4.Event_Reason_Name,
         a1.Event_Reason_Name, a2.Event_Reason_Name
    From Waste_Event_Details d
    Left Outer Join Prod_Units pu on pu.pu_id = d.source_pu_id
    Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.reason_level1  
    Left Outer Join Event_Reasons r2 on r2.event_reason_id = d.reason_level2  
    Left Outer Join Event_Reasons r3 on r3.event_reason_id = d.reason_level3  
    Left Outer Join Event_Reasons r4 on r4.event_reason_id = d.reason_level4  
    Left Outer Join Event_Reasons a1 on a1.event_reason_id = d.action_level1  
    Left Outer Join Event_Reasons a2 on a2.event_reason_id = d.action_level2  
    Where d.PU_Id = @Unit and 
          d.Timestamp  >= @StartTime and
          d.Timestamp < @EndTime and
          d.event_id Is NULL and 
          d.amount is not null
Select @NumberOfRows = count(time), @TotalWaste = sum(Amount)
  From #Details
If @NumberOfRows <= @MaxNumberOfRows
  Insert Into #Resultsets (ResultOrder, ResultName)
    Values (1, @ResultsetNameWasteList)
select  @TotalWaste = Coalesce(@TotalWaste,0)
select @TotalProduction = sum(ed.Initial_Dimension_X)
  From Events e
  Join Event_Details ed on ed.event_id = e.event_id and ed.Initial_Dimension_X Is Not NULL
  Where e.PU_Id = @Unit and 
        e.Timestamp  >= @StartTime and
        e.Timestamp < @EndTime
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
-- Return Resultset #3 - Detail List
--*********************************************************************************
If @NumberOfRows <= @MaxNumberOfRows
  Begin
    Select @SQL = 'Select Event as [' + @ColumnNameEvent + '], Time as [' + @ColumnNameTime + '] ' 
    Select @SQL = @SQL + ',replace(convert(nvarchar(25),convert(decimal(10,2),Amount)),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ') as [' + @ColumnNameAmount + '] '
    Select @SQL = @SQL + ',Location as [' + @ColumnNameLocation + '] '
    If @ColumnNameReason1 Is Not Null 
      Select @SQL = @SQL + ',Reason1 as [' + @ColumnNameReason1 + '] '
    If @ColumnNameReason2 Is Not Null 
      Select @SQL = @SQL + ',Reason2 as [' + @ColumnNameReason2 + '] '
    If @ColumnNameReason3 Is Not Null 
      Select @SQL = @SQL + ',Reason3 as [' + @ColumnNameReason3 + '] '
    If @ColumnNameReason4 Is Not Null 
      Select @SQL = @SQL + ',Reason4 as [' + @ColumnNameReason4 + '] '
    If @ColumnNameAction1 Is Not Null 
      Select @SQL = @SQL + ',Action1 as [' + @ColumnNameAction1 + '] '
    If @ColumnNameAction2 Is Not Null 
      Select @SQL = @SQL + ',Action2 as [' + @ColumnNameAction2 + '] '
    Select @SQL = @SQL + 'From #Details Order By Time DESC'
    --print @SQL 
    Execute (@SQL)
  End
--*********************************************************************************
-- Return Resultset #4 - Location Pareto
--*********************************************************************************
Select @SQL = 'Select Location as [' + @ColumnNameLocation + '] ' 
Select @SQL = @SQL + ',replace(convert(nvarchar(25),convert(decimal(10,2),Sum(Amount))),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ') as [' + @ColumnNameTotalWaste + '] '
Select @SQL = @SQL + ',Count(Time) as [' + @ColumnNameNumberWaste + '] '
Select @SQL = @SQL + ',replace(convert(nvarchar(25),convert(decimal(10,2),Sum(Amount) / convert(real,' + convert(nvarchar(25),@TotalWaste) + ') * 100.0)),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ') as [' + @ColumnNamePercentWaste + '] '
If @TotalProduction > 0
  Select @SQL = @SQL + ',replace(convert(nvarchar(25),convert(decimal(10,2),Sum(Amount) / convert(real,' + convert(nvarchar(25),@TotalProduction) + ') * 100.0)),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ') as [' + @ColumnNamePercentProduction + '] '
Select @SQL = @SQL + 'From #Details Group By Location Order By [' + @ColumnNameTotalWaste + '] DESC' 
--print @SQL 
Execute (@SQL)
--*********************************************************************************
-- Return Resultset #5 - Reason 1 Pareto
--*********************************************************************************
If @ColumnNameReason1 Is Not Null
  Begin
    Select @SQL = 'Select Reason1 as [' + @ColumnNameReason1 + '] ' 
    Select @SQL = @SQL + ',replace(convert(nvarchar(25),convert(decimal(10,2),Sum(Amount))),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ')  as [' + @ColumnNameTotalWaste + '] '
    Select @SQL = @SQL + ',Count(Time) as [' + @ColumnNameNumberWaste + '] '
    Select @SQL = @SQL + ',replace(convert(nvarchar(25),convert(decimal(10,2),Sum(Amount) / convert(real,' + convert(nvarchar(25),@TotalWaste) + ') * 100.0)),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ') as [' + @ColumnNamePercentWaste + '] '
    If @TotalProduction > 0
      Select @SQL = @SQL + ',replace(convert(nvarchar(25),convert(decimal(10,2),Sum(Amount) / convert(real,' + convert(nvarchar(25),@TotalProduction) + ') * 100.0)),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ') as [' + @ColumnNamePercentProduction + '] '
    Select @SQL = @SQL + 'From #Details Group By Reason1 Order By [' + @ColumnNameTotalWaste + '] DESC' 
    --print @SQL 
    Execute (@SQL)
  End
--*********************************************************************************
-- Return Resultset #6 - Reason 2 Pareto
--*********************************************************************************
If @ColumnNameReason2 Is Not Null
  Begin
    Select @SQL = 'Select Reason2 as [' + @ColumnNameReason2 + '] ' 
    Select @SQL = @SQL + ',replace(convert(nvarchar(25),convert(decimal(10,2),Sum(Amount))),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ') as [' + @ColumnNameTotalWaste + '] '
    Select @SQL = @SQL + ',Count(Time) as [' + @ColumnNameNumberWaste + '] '
    Select @SQL = @SQL + ',replace(convert(nvarchar(25),convert(decimal(10,2), Sum(Amount) / convert(real,' + convert(nvarchar(25),@TotalWaste) + ') * 100.0)),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ') as [' + @ColumnNamePercentWaste + '] '
    If @TotalProduction > 0
      Select @SQL = @SQL + ',replace(convert(nvarchar(25),convert(decimal(10,2), Sum(Amount) / convert(real,' + convert(nvarchar(25),@TotalProduction) + ') * 100.0)),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ') as [' + @ColumnNamePercentProduction + '] '
    Select @SQL = @SQL + 'From #Details Group By Reason2 Order By [' + @ColumnNameTotalWaste + '] DESC' 
    --print @SQL 
    Execute (@SQL)
  End
Drop Table #Details
