CREATE Procedure dbo.spCMN_DowntimeReport
@Unit int,
@StartTime datetime = NULL,
@EndTime datetime = NULL,
@LanguageNumber int = 0,
@DecimalSeparator nvarchar(1) = NULL
AS
--***********************
set nocount on
--Declare @StartTime datetime
--Declare @EndTime datetime
--Declare @LanguageNumber int
--Select @Unit = 2
--Select @StartTime = dateadd(day,-50,getutcdate())
--Select @LanguageNumber = 1
--***************************
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
Declare @ResultsetNameDowntimeList nvarchar(50)
Declare @ResultsetNameLocationPareto nvarchar(50)
Declare @ResultsetNameFaultPareto nvarchar(50)
Declare @ResultsetNameReason1Pareto nvarchar(50)
Declare @ResultsetNameReason2Pareto nvarchar(50)
Declare @ColumnNameStartTime nvarchar(50)
Declare @ColumnNameEndTime nvarchar(50)
Declare @ColumnNameDuration nvarchar(50)
Declare @ColumnNameLocation nvarchar(50)
Declare @ColumnNameFault nvarchar(50)
Declare @ColumnNameReason1 nvarchar(50)
Declare @ColumnNameReason2 nvarchar(50)
Declare @ColumnNameReason3 nvarchar(50)
Declare @ColumnNameReason4 nvarchar(50)
Declare @ColumnNameAction1 nvarchar(50)
Declare @ColumnNameAction2 nvarchar(50)
Declare @ColumnNameTotalDown nvarchar(50)
Declare @ColumnNameNumberDown nvarchar(50)
Declare @ColumnNamePercentDown nvarchar(50)
Declare @ColumnNamePercentTime nvarchar(50)
Select @ResultsetNameDowntimeList = 'Downtime Details'
Select @ResultsetNameLocationPareto = 'Location Pareto'
Select @ResultsetNameFaultPareto = 'Fault Pareto'
Select @ColumnNameStartTime = 'Start Time'
Select @ColumnNameEndTime = 'End Time'
Select @ColumnNameDuration = 'Duration'
Select @ColumnNameLocation = 'Location'
Select @ColumnNameFault = 'Fault Name'
Select @ColumnNameTotalDown = 'Time Down'
Select @ColumnNameNumberDown = 'Events'
Select @ColumnNamePercentDown = '% Downtime'
Select @ColumnNamePercentTime = '% Total'
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
        pe.Event_Type = 2
If @ColumnNameReason1 Is Not Null
  Select @ResultsetNameReason1Pareto = @ColumnNameReason1 + ' ' + @TempString
Else
  Select @ResultsetNameReason1Pareto = Null
Select @ColumnNameReason2 = NULL
Select @ColumnNameReason2 = h.Level_Name
  From Prod_Events pe
  Join Event_Reason_Level_Headers h on h.tree_name_id = pe.name_id and h.Reason_Level = 2
  Where pe.PU_Id = @Unit and
        pe.Event_Type = 2
If @ColumnNameReason2 Is Not Null
  Select @ResultsetNameReason2Pareto = @ColumnNameReason2  + ' ' + @TempString
Else
  Select @ResultsetNameReason2Pareto = Null
Select @ColumnNameReason3 = NULL
Select @ColumnNameReason3 = h.Level_Name
  From Prod_Events pe
  Join Event_Reason_Level_Headers h on h.tree_name_id = pe.name_id and h.Reason_Level = 3
  Where pe.PU_Id = @Unit and
        pe.Event_Type = 2
Select @ColumnNameReason4 = NULL
Select @ColumnNameReason4 = h.Level_Name
  From Prod_Events pe
  Join Event_Reason_Level_Headers h on h.tree_name_id = pe.name_id and h.Reason_Level = 4
  Where pe.PU_Id = @Unit and
        pe.Event_Type = 2
Select @ColumnNameAction1 = NULL
Select @ColumnNameAction1 = h.Level_Name
  From Prod_Events pe
  Join Event_Reason_Level_Headers h on h.tree_name_id = pe.Action_Tree_Id and h.Reason_Level = 1
  Where pe.PU_Id = @Unit and
        pe.Event_Type = 2
Select @ColumnNameAction2 = NULL
Select @ColumnNameAction2 = h.Level_Name
  From Prod_Events pe
  Join Event_Reason_Level_Headers h on h.tree_name_id = pe.Action_Tree_Id and h.Reason_Level = 2
  Where pe.PU_Id = @Unit and
        pe.Event_Type = 2
If @LanguageNumber <> 0
  Begin
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24054
    Select @ResultsetNameDowntimeList = coalesce(@TempString,@ResultsetNameDowntimeList)     
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24271
    Select @ResultsetNameLocationPareto = coalesce(@TempString,@ResultsetNameLocationPareto)     
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24272
    Select @ResultsetNameFaultPareto = coalesce(@TempString,@ResultsetNameFaultPareto)     
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24116
    Select @ColumnNameStartTime = coalesce(@TempString,@ColumnNameStartTime)     
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24117
    Select @ColumnNameEndTime = coalesce(@TempString,@ColumnNameEndTime)     
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24115
    Select @ColumnNameDuration = coalesce(@TempString,@ColumnNameDuration)     
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24223
    Select @ColumnNameLocation = coalesce(@TempString,@ColumnNameLocation)     
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24118
    Select @ColumnNameFault = coalesce(@TempString,@ColumnNameFault)     
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24274
    Select @ColumnNameTotalDown = coalesce(@TempString,@ColumnNameTotalDown)     
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24275
    Select @ColumnNameNumberDown = coalesce(@TempString,@ColumnNameNumberDown)     
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24276
    Select @ColumnNamePercentDown= coalesce(@TempString,@ColumnNamePercentDown)     
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24277
    Select @ColumnNamePercentTime= coalesce(@TempString,@ColumnNamePercentTime)     
  End
--*********************************************************************************
-- Define Time Columns
--*********************************************************************************
Create Table #ColumnFormats (
  TimeColumns nvarchar(50)
)
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
--Do Downtime List After Counting Records In Return
Insert Into #Resultsets (ResultOrder, ResultName)
  Values (2, @ResultsetNameLocationPareto)
Insert Into #Resultsets (ResultOrder, ResultName)
  Values (3, @ResultsetNameFaultPareto)
If @ResultsetNameReason1Pareto Is Not Null
  Insert Into #Resultsets (ResultOrder, ResultName)
    Values (4, @ResultsetNameReason1Pareto)
If @ResultsetNameReason2Pareto Is Not Null
  Insert Into #Resultsets (ResultOrder, ResultName)
    Values (5, @ResultsetNameReason2Pareto)
--*********************************************************************************
-- Get Data Into Temporary Table
--*********************************************************************************
Create Table #Details (
  StartTime datetime,
  EndTime datetime NULL,
  Duration int NULL,
  Location nvarchar(50) NULL,
  Fault nvarchar(100) NULL,
  Reason1 nvarchar(50) NULL,
  Reason2 nvarchar(50) NULL,
  Reason3 nvarchar(50) NULL,
  Reason4 nvarchar(50) NULL,
  Action1 nvarchar(50) NULL,
  Action2 nvarchar(50) NULL
)
Declare @TotalDown int
Declare @TotalOperating int
DEclare @NumberOfRows int
Insert Into #Details
  Select d.Start_Time, d.End_Time, 0, pu.PU_Desc,tef.TEFault_Name, 
         r1.Event_Reason_Name, r2.Event_Reason_Name, r3.Event_Reason_Name, r4.Event_Reason_Name,
         a1.Event_Reason_Name, a2.Event_Reason_Name
    From Timed_Event_Details d
    Left Outer Join Prod_Units pu on pu.pu_id = d.source_pu_id
    Left Outer Join Timed_Event_Fault tef on tef.TEFault_id = d.TEFault_id
    Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.reason_level1  
    Left Outer Join Event_Reasons r2 on r2.event_reason_id = d.reason_level2  
    Left Outer Join Event_Reasons r3 on r3.event_reason_id = d.reason_level3  
    Left Outer Join Event_Reasons r4 on r4.event_reason_id = d.reason_level4  
    Left Outer Join Event_Reasons a1 on a1.event_reason_id = d.action_level1  
    Left Outer Join Event_Reasons a2 on a2.event_reason_id = d.action_level2  
    Where d.PU_Id = @Unit and 
          d.Start_Time <= @EndTime and 
          ((d.End_Time  > @StartTime) or (d.End_Time Is Null))
Update #Details
  Set StartTime = Case When StartTime < @StartTime Then @StartTime Else StartTime End,
      EndTime = Case When EndTime Is Null Then @EndTime When EndTime > @EndTime Then @EndTime Else EndTime End
Update #Details
  Set Duration = Datediff(second, StartTime, EndTime) 
Select @NumberOfRows = @@RowCount
If @NumberOfRows <= @MaxNumberOfRows
  Insert Into #Resultsets (ResultOrder, ResultName)
    Values (1, @ResultsetNameDowntimeList)
Select @TotalDown = sum(Duration)
  From #Details
Select @TotalOperating = datediff(second,@StartTime, @EndTime)
select  @TotalDown = Coalesce(@TotalDown,0)
select  @TotalOperating = Coalesce(@TotalOperating,0)
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
    Select @SQL = 'Select StartTime as [' + @ColumnNameStartTime + '], EndTime as [' + @ColumnNameEndTime + '] ' 
    Select @SQL = @SQL + ',convert(nvarchar(25),convert(int,Duration / 3600)) + ' + '''' + ':' + '''' +  ' + right(' + '''' + '0' + '''' + ' + convert(nvarchar(25),convert(int,(Duration - convert(int,Duration / 3600) * 3600)/60)),2) as [' + @ColumnNameDuration + '] '
    Select @SQL = @SQL + ',Location as [' + @ColumnNameLocation + '], Fault as [' + @ColumnNameFault + '] '
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
    Select @SQL = @SQL + 'From #Details Order By StartTime DESC'
    --print @SQL 
    Execute (@SQL)
  End
--*********************************************************************************
-- Return Resultset #4 - Location Pareto
--*********************************************************************************
Select @SQL = 'Select Location as [' + @ColumnNameLocation + '] ' 
Select @SQL = @SQL + ',convert(nvarchar(25),convert(int,Sum(Duration) / 3600)) + ' + '''' + ':' + '''' +  ' + right(' + '''' + '0' + '''' + ' + convert(nvarchar(25),convert(int,(sum(Duration) - convert(int,sum(Duration) / 3600) * 3600)/60)),2) as [' + @ColumnNameTotalDown + '] '
Select @SQL = @SQL + ',Count(StartTime) as [' + @ColumnNameNumberDown + '] '
Select @SQL = @SQL + ',replace(convert(nvarchar(25),convert(decimal(10,2),Sum(Duration) / convert(real,' + convert(nvarchar(25),@TotalDown) + ') * 100.0)),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ') as [' + @ColumnNamePercentDown + '] '
Select @SQL = @SQL + ',replace(convert(nvarchar(25),convert(decimal(10,2),Sum(Duration) / convert(real,' + convert(nvarchar(25),@TotalOperating) + ') * 100.0)),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ') as [' + @ColumnNamePercentTime + '] '
Select @SQL = @SQL + 'From #Details Group By Location Order By [' + @ColumnNameTotalDown + '] DESC' 
--print @SQL 
Execute (@SQL)
--*********************************************************************************
-- Return Resultset #5 - Fault Pareto
--*********************************************************************************
Select @SQL = 'Select Fault as [' + @ColumnNameFault + '] ' 
Select @SQL = @SQL + ',convert(nvarchar(25),convert(int,Sum(Duration) / 3600)) + ' + '''' + ':' + '''' +  ' + right(' + '''' + '0' + '''' + ' + convert(nvarchar(25),convert(int,(sum(Duration) - convert(int,sum(Duration) / 3600) * 3600)/60)),2) as [' + @ColumnNameTotalDown + '] '
Select @SQL = @SQL + ',Count(StartTime) as [' + @ColumnNameNumberDown + '] '
Select @SQL = @SQL + ',replace(convert(nvarchar(25),convert(decimal(10,2),Sum(Duration) / convert(real,' + convert(nvarchar(25),@TotalDown) + ') * 100.0)),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ') as [' + @ColumnNamePercentDown + '] '
Select @SQL = @SQL + ',replace(convert(nvarchar(25),convert(decimal(10,2),Sum(Duration) / convert(real,' + convert(nvarchar(25),@TotalOperating) + ') * 100.0)),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ') as [' + @ColumnNamePercentTime + '] '
Select @SQL = @SQL + 'From #Details Group By Fault Order By [' + @ColumnNameTotalDown + '] DESC' 
--print @SQL 
Execute (@SQL)
--*********************************************************************************
-- Return Resultset #6 - Reason 1 Pareto
--*********************************************************************************
If @ColumnNameReason1 Is Not Null
  Begin
    Select @SQL = 'Select Reason1 as [' + @ColumnNameReason1 + '] ' 
    Select @SQL = @SQL + ',convert(nvarchar(25),convert(int,Sum(Duration) / 3600)) + ' + '''' + ':' + '''' +  ' + right(' + '''' + '0' + '''' + ' + convert(nvarchar(25),convert(int,(sum(Duration) - convert(int,sum(Duration) / 3600) * 3600)/60)),2) as [' + @ColumnNameTotalDown + '] '
    Select @SQL = @SQL + ',Count(StartTime) as [' + @ColumnNameNumberDown + '] '
    Select @SQL = @SQL + ',replace(convert(nvarchar(25),convert(decimal(10,2),Sum(Duration) / convert(real,' + convert(nvarchar(25),@TotalDown) + ') * 100.0)),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ') as [' + @ColumnNamePercentDown + '] '
    Select @SQL = @SQL + ',replace(convert(nvarchar(25),convert(decimal(10,2),Sum(Duration) / convert(real,' + convert(nvarchar(25),@TotalOperating) + ') * 100.0)),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ') as [' + @ColumnNamePercentTime + '] '
    Select @SQL = @SQL + 'From #Details Group By Reason1 Order By [' + @ColumnNameTotalDown + '] DESC' 
    --print @SQL 
    Execute (@SQL)
  End
--*********************************************************************************
-- Return Resultset #7 - Reason 2 Pareto
--*********************************************************************************
If @ColumnNameReason2 Is Not Null
  Begin
    Select @SQL = 'Select Reason2 as [' + @ColumnNameReason2 + '] ' 
    Select @SQL = @SQL + ',convert(nvarchar(25),convert(int,Sum(Duration) / 3600)) + ' + '''' + ':' + '''' +  ' + right(' + '''' + '0' + '''' + ' + convert(nvarchar(25),convert(int,(sum(Duration) - convert(int,sum(Duration) / 3600) * 3600)/60)),2) as [' + @ColumnNameTotalDown + '] '
    Select @SQL = @SQL + ',Count(StartTime) as [' + @ColumnNameNumberDown + '] '
    Select @SQL = @SQL + ',replace(convert(nvarchar(25),convert(decimal(10,2),Sum(Duration) / convert(real,' + convert(nvarchar(25),@TotalDown) + ') * 100.0)),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ') as [' + @ColumnNamePercentDown + '] '
    Select @SQL = @SQL + ',replace(convert(nvarchar(25),convert(decimal(10,2),Sum(Duration) / convert(real,' + convert(nvarchar(25),@TotalOperating) + ') * 100.0)),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ') as [' + @ColumnNamePercentTime + '] '
    Select @SQL = @SQL + 'From #Details Group By Reason2 Order By [' + @ColumnNameTotalDown + '] DESC' 
    --print @SQL 
    Execute (@SQL)
  End
Drop Table #Details
