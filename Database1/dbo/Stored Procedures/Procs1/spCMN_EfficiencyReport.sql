Create Procedure dbo.spCMN_EfficiencyReport
@Unit int,
@StartTime datetime = NULL,
@EndTime datetime = NULL,
@LanguageNumber int = 0,
@DecimalSeparator nvarchar(1) = NULL
AS
Declare @SQL nvarchar(2000)
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
Declare @ResultsetNameStatusPareto nvarchar(50)
Declare @ResultsetNameDowntimeLocationPareto nvarchar(50)
Declare @ResultsetNameDowntimeFaultPareto nvarchar(50)
Declare @ResultsetNameDowntimeReason1Pareto nvarchar(50)
Declare @ResultsetNameDowntimeReason2Pareto nvarchar(50)
Declare @ResultsetNameWasteLocationPareto nvarchar(50)
Declare @ResultsetNameWasteReason1Pareto nvarchar(50)
Declare @ResultsetNameWasteReason2Pareto nvarchar(50)
Declare @ColumnNameStatus nvarchar(50)
Declare @ColumnNameLocation nvarchar(50)
Declare @ColumnNameDowntimeFault nvarchar(50)
Declare @ColumnNameDowntimeReason1 nvarchar(50)
Declare @ColumnNameDowntimeReason2 nvarchar(50)
Declare @ColumnNameWasteReason1 nvarchar(50)
Declare @ColumnNameWasteReason2 nvarchar(50)
Declare @ColumnNameTotalProduction nvarchar(50)
Declare @ColumnNameNumberProduction nvarchar(50)
Declare @ColumnNameTotalWaste nvarchar(50)
Declare @ColumnNameNumberWaste nvarchar(50)
Declare @ColumnNamePercentWaste nvarchar(50)
Declare @ColumnNamePercentProduction nvarchar(50)
Declare @ColumnNameTotalDown nvarchar(50)
Declare @ColumnNameNumberDown nvarchar(50)
Declare @ColumnNamePercentDown nvarchar(50)
Declare @ColumnNamePercentTime nvarchar(50)
Declare @DowntimeText nvarchar(50)
Declare @WasteText nvarchar(50)
Select @ResultsetNameStatusPareto = 'Status Pareto'
Select @ResultsetNameDowntimeLocationPareto = 'Downtime Location Pareto'
Select @ResultsetNameDowntimeFaultPareto = 'Downtime Fault Pareto'
Select @ResultsetNameWasteLocationPareto = 'Waste Location Pareto'
Select @ColumnNameStatus = 'Status'
Select @ColumnNameLocation = 'Location'
Select @ColumnNameDowntimeFault= 'Fault'
Select @ColumnNameTotalProduction = 'Total Production'
Select @ColumnNameNumberProduction = '#'
Select @ColumnNameTotalWaste = 'Total Waste'
Select @ColumnNameNumberWaste = 'Events'
Select @ColumnNamePercentWaste = '% Waste'
Select @ColumnNamePercentProduction = '% Production'
Select @ColumnNameTotalDown = 'Total Down'
Select @ColumnNameNumberDown = 'Events'
Select @ColumnNamePercentDown = '% Downtime'
Select @ColumnNamePercentTime = '% Total'
Select @DowntimeText = 'Downtime' 
Select @WasteText = 'Waste' 
Select @TempString = NULL
select @TempString = s.event_subtype_desc
  from event_configuration e 
  join event_subtypes s on s.Event_Subtype_Id = e.Event_Subtype_Id
  where e.pu_id = @Unit and 
        e.et_id = 1
Select @ColumnNameNumberProduction = @ColumnNameNumberProduction + coalesce(@TempString,'Events')     
Select @ColumnNameWasteReason1 = NULL
Select @ColumnNameWasteReason1 = h.Level_Name
  From Prod_Events pe
  Join Event_Reason_Level_Headers h on h.tree_name_id = pe.name_id and h.Reason_Level = 1
  Where pe.PU_Id = @Unit and
        pe.Event_Type = 3
Select @TempString = NULL
Select @TempString = Prompt_String 
  From Language_Data
  Where Language_Id = @LanguageNumber and Prompt_Number = 24273
Select @TempString = coalesce(@TempString,'Pareto')     
If @ColumnNameWasteReason1 Is Not Null
  Select @ResultsetNameWasteReason1Pareto = @ColumnNameWasteReason1 + ' ' + @TempString
Else
  Select @ResultsetNameWasteReason1Pareto = Null
Select @ColumnNameWasteReason2 = NULL
Select @ColumnNameWasteReason2 = h.Level_Name
  From Prod_Events pe
  Join Event_Reason_Level_Headers h on h.tree_name_id = pe.name_id and h.Reason_Level = 2
  Where pe.PU_Id = @Unit and
        pe.Event_Type = 3
If @ColumnNameWasteReason2 Is Not Null
  Select @ResultsetNameWasteReason2Pareto = @ColumnNameWasteReason2 + ' ' + @TempString
Else
  Select @ResultsetNameWasteReason2Pareto = Null
Select @ColumnNameDowntimeReason1 = h.Level_Name
  From Prod_Events pe
  Join Event_Reason_Level_Headers h on h.tree_name_id = pe.name_id and h.Reason_Level = 1
  Where pe.PU_Id = @Unit and
        pe.Event_Type = 2
If @ColumnNameDowntimeReason1 Is Not Null
  Select @ResultsetNameDowntimeReason1Pareto = @ColumnNameDowntimeReason1 + ' ' + @TempString
Else
  Select @ResultsetNameDowntimeReason1Pareto = Null
Select @ColumnNameDowntimeReason2 = NULL
Select @ColumnNameDowntimeReason2 = h.Level_Name
  From Prod_Events pe
  Join Event_Reason_Level_Headers h on h.tree_name_id = pe.name_id and h.Reason_Level = 2
  Where pe.PU_Id = @Unit and
        pe.Event_Type = 2
If @ColumnNameDowntimeReason2 Is Not Null
  Select @ResultsetNameDowntimeReason2Pareto = @ColumnNameDowntimeReason2 + ' ' + @TempString
Else
  Select @ResultsetNameDowntimeReason2Pareto = Null
If @LanguageNumber <> 0
  Begin
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24252
    Select @ResultsetNameStatusPareto = coalesce(@TempString, @ResultsetNameStatusPareto)     
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24280
    Select @ResultsetNameDowntimeLocationPareto = coalesce(@TempString, @ResultsetNameDowntimeLocationPareto)     
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24281
    Select @ResultsetNameDowntimeFaultPareto = coalesce(@TempString, @ResultsetNameDowntimeFaultPareto)     
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24282
    Select @ResultsetNameWasteLocationPareto = coalesce(@TempString,@ResultsetNameWasteLocationPareto)     
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24061
    Select @ColumnNameStatus = coalesce(@TempString,@ColumnNameStatus)     
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24223
    Select @ColumnNameLocation = coalesce(@TempString,@ColumnNameLocation)     
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24283
    Select @ColumnNameDowntimeFault = coalesce(@TempString,@ColumnNameDowntimeFault)     
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24269
    Select @ColumnNameTotalProduction = coalesce(@TempString,@ColumnNameTotalProduction)     
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
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24284
    Select @ColumnNameTotalDown = coalesce(@TempString,@ColumnNameTotalDown)     
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24275
    Select @ColumnNameNumberDown = coalesce(@TempString,@ColumnNameNumberDown)     
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24275
    Select @ColumnNamePercentDown = coalesce(@TempString,@ColumnNamePercentDown)     
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24277
    Select @ColumnNamePercentTime = coalesce(@TempString,@ColumnNamePercentTime)     
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24285
    Select @DowntimeText = coalesce(@TempString,@DowntimeText)     
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24286
    Select @WasteText = coalesce(@TempString,@WasteText)     
  End
Select @ResultsetNameDowntimeReason1Pareto = @DowntimeText + ' ' + @ResultsetNameDowntimeReason1Pareto  
Select @ResultsetNameDowntimeReason2Pareto = @DowntimeText + ' ' + @ResultsetNameDowntimeReason2Pareto  
Select @ResultsetNameWasteReason1Pareto = @WasteText + ' ' + @ResultsetNameWasteReason1Pareto  
Select @ResultsetNameWasteReason2Pareto = @WasteText + ' ' + @ResultsetNameWasteReason2Pareto  
--*********************************************************************************
-- Define Time Columns
--*********************************************************************************
Create Table #ColumnFormats (
  TimeColumns nvarchar(50)
)
-- No Time Columns
--*********************************************************************************
-- Define Resultset Names To Be Returned
--*********************************************************************************
Create Table #Resultsets (
  ResultOrder int,
  ResultName nvarchar(50)  
)
Insert Into #Resultsets (ResultOrder, ResultName)
  Values (3, @ResultsetNameStatusPareto)
Insert Into #Resultsets (ResultOrder, ResultName)
  Values (4, @ResultsetNameDowntimeLocationPareto)
Insert Into #Resultsets (ResultOrder, ResultName)
  Values (5, @ResultsetNameDowntimeFaultPareto)
If @ResultsetNameDowntimeReason1Pareto Is Not Null
  Insert Into #Resultsets (ResultOrder, ResultName)
    Values (6, @ResultsetNameDowntimeReason1Pareto)
If @ResultsetNameDowntimeReason2Pareto Is Not Null
  Insert Into #Resultsets (ResultOrder, ResultName)
    Values (7, @ResultsetNameDowntimeReason2Pareto)
Insert Into #Resultsets (ResultOrder, ResultName)
  Values (8, @ResultsetNameWasteLocationPareto)
If @ResultsetNameWasteReason1Pareto Is Not Null
  Insert Into #Resultsets (ResultOrder, ResultName)
    Values (9, @ResultsetNameWasteReason1Pareto)
If @ResultsetNameWasteReason2Pareto Is Not Null
  Insert Into #Resultsets (ResultOrder, ResultName)
    Values (10, @ResultsetNameWasteReason2Pareto)
--*********************************************************************************
-- Get Data Into Temporary Table
--*********************************************************************************
Create Table #ProductionDetails (
  Status nvarchar(50) NULL,
  iDimensionX float(32) NULL
)
Declare @TotalProduction float(32)
Insert Into #ProductionDetails
  Select s.prodstatus_desc, d.initial_dimension_x
    From events e
    Left outer Join event_details d on d.event_id = e.event_id 
    Join production_status s on s.prodstatus_id = e.event_status and s.count_for_production = 1
    Where e.PU_Id = @Unit and 
          e.Timestamp  >= @StartTime and
          e.Timestamp < @EndTime
Select @TotalProduction = sum(coalesce(iDimensionX,0))
  From #ProductionDetails  
select  @TotalProduction = Coalesce(@TotalProduction,0)
Create Table #WasteDetails (
  Amount float(32) NULL,
  Location nvarchar(50) NULL,
  Reason1 nvarchar(50) NULL,
  Reason2 nvarchar(50) NULL,
)
Declare @TotalWaste float(32)
Insert Into #WasteDetails (Amount,Location,Reason1,Reason2)
  Select d.amount, pu.PU_Desc, r1.Event_Reason_Name, r2.Event_Reason_Name
    From events e
    Join Waste_Event_Details d on d.event_id = e.event_id and d.amount is not null
    Left Join Prod_Units pu on pu.pu_id = d.source_pu_id
    Left Join Event_Reasons r1 on r1.event_reason_id = d.reason_level1  
    Left Join Event_Reasons r2 on r2.event_reason_id = d.reason_level2  
    Where e.PU_Id = @Unit and 
          e.Timestamp  >= @StartTime and
          e.Timestamp < @EndTime
Insert Into #WasteDetails (Amount,Location,Reason1,Reason2)
  Select d.amount, pu.PU_Desc, r1.Event_Reason_Name, r2.Event_Reason_Name
    From Waste_Event_Details d
    Left Join Prod_Units pu on pu.pu_id = d.source_pu_id
    Left Join Event_Reasons r1 on r1.event_reason_id = d.reason_level1  
    Left Join Event_Reasons r2 on r2.event_reason_id = d.reason_level2  
    Where d.PU_Id = @Unit and   d.Timestamp  >= @StartTime and
          d.Timestamp < @EndTime and d.event_id Is NULL and  d.amount is not null
Select @TotalWaste = sum(Amount)
  From #WasteDetails  
Select  @TotalWaste = Coalesce(@TotalWaste,0)
Create Table #DowntimeDetails (
  StartTime datetime,
  EndTime datetime NULL,
  Duration int NULL,
  Location nvarchar(50) NULL,
  Fault nvarchar(100) NULL,
  Reason1 nvarchar(50) NULL,
  Reason2 nvarchar(50) NULL,
)
Declare @TotalDown int
Declare @TotalOperating int
Insert Into #DowntimeDetails
  Select d.Start_Time, d.End_Time, 0, pu.PU_Desc,tef.TEFault_Name, 
         r1.Event_Reason_Name, r2.Event_Reason_Name
    From Timed_Event_Details d
    Left Outer Join Prod_Units pu on pu.pu_id = d.source_pu_id
    Left Outer Join Timed_Event_Fault tef on tef.TEFault_id = d.TEFault_id
    Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.reason_level1  
    Left Outer Join Event_Reasons r2 on r2.event_reason_id = d.reason_level2  
    Where d.PU_Id = @Unit and 
          d.Start_Time <= @EndTime and 
          ((d.End_Time  > @StartTime) or (d.End_Time Is Null))
Update #DowntimeDetails
  Set StartTime = Case When StartTime < @StartTime Then @StartTime Else StartTime End,
      EndTime = Case When EndTime Is Null Then @EndTime When EndTime > @EndTime Then @EndTime Else EndTime End
Update #DowntimeDetails
  Set Duration = Datediff(second, StartTime, EndTime) 
Select @TotalDown = sum(Duration)
  From #DowntimeDetails
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
-- Return Resultset #3 - Production Status Pareto
--*********************************************************************************
Select @SQL = 'Select Status as [' + @ColumnNameStatus + '] ' 
Select @SQL = @SQL + ',replace(convert(nvarchar(25),convert(decimal(15,2),Sum(coalesce(iDimensionX,0.0)))),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ') as [' + @ColumnNameTotalProduction + '] '
Select @SQL = @SQL + ',Count(Status) as [' + @ColumnNameNumberProduction + '] '
If @TotalProduction > 0 
  Select @SQL = @SQL + ',replace(convert(nvarchar(25),convert(decimal(15,2),Sum(coalesce(iDimensionX,0.0)) / convert(real,' + convert(nvarchar(25),@TotalProduction) + ') * 100.0)),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ') as [' + @ColumnNamePercentProduction + '] '
Select @SQL = @SQL + 'From #ProductionDetails Group By Status Order By [' + @ColumnNameTotalProduction + '] DESC' 
--print @SQL 
Execute (@SQL)
Drop Table #ProductionDetails
--*********************************************************************************
-- Return Resultset #4 - Location Pareto
--*********************************************************************************
Select @SQL = 'Select Location as [' + @ColumnNameLocation + '] ' 
Select @SQL = @SQL + ',convert(nvarchar(25),convert(int,Sum(Duration) / 3600)) + ' + '''' + ':' + '''' +  ' + right(' + '''' + '0' + '''' + ' + convert(nvarchar(25),convert(int,(sum(Duration) - convert(int,sum(Duration) / 3600) * 3600)/60)),2) as [' + @ColumnNameTotalDown + '] '
Select @SQL = @SQL + ',Count(Duration) as [' + @ColumnNameNumberDown + '] '
If @TotalDown > 0
  Select @SQL = @SQL + ',replace(convert(nvarchar(25),convert(decimal(10,2),Sum(Duration) / convert(real,' + convert(nvarchar(25),@TotalDown) + ') * 100.0)),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ') as [' + @ColumnNamePercentDown + '] '
If @TotalOperating > 0 
  Select @SQL = @SQL + ',replace(convert(nvarchar(25),convert(decimal(10,2),Sum(Duration) / convert(real,' + convert(nvarchar(25),@TotalOperating) + ') * 100.0)),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ') as [' + @ColumnNamePercentTime + '] '
Select @SQL = @SQL + 'From #DowntimeDetails Group By Location Order By [' + @ColumnNameTotalDown + '] DESC' 
--print @SQL 
Execute (@SQL)
--*********************************************************************************
-- Return Resultset #5 - Fault Pareto
--*********************************************************************************
Select @SQL = 'Select Fault as [' + @ColumnNameDowntimeFault + '] ' 
Select @SQL = @SQL + ',convert(nvarchar(25),convert(int,Sum(Duration) / 3600)) + ' + '''' + ':' + '''' +  ' + right(' + '''' + '0' + '''' + ' + convert(nvarchar(25),convert(int,(sum(Duration) - convert(int,sum(Duration) / 3600) * 3600)/60)),2) as [' + @ColumnNameTotalDown + '] '
Select @SQL = @SQL + ',Count(Duration) as [' + @ColumnNameNumberDown + '] '
If @TotalDown > 0
  Select @SQL = @SQL + ',replace(convert(nvarchar(25),convert(decimal(10,2),Sum(Duration) / convert(real,' + convert(nvarchar(25),@TotalDown) + ') * 100.0)),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ') as [' + @ColumnNamePercentDown + '] '
If @TotalOperating > 0 
  Select @SQL = @SQL + ',replace(convert(nvarchar(25),convert(decimal(10,2),Sum(Duration) / convert(real,' + convert(nvarchar(25),@TotalOperating) + ') * 100.0)),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ') as [' + @ColumnNamePercentTime + '] '
Select @SQL = @SQL + 'From #DowntimeDetails Group By Fault Order By [' + @ColumnNameTotalDown + '] DESC' 
--print @SQL 
Execute (@SQL)
--*********************************************************************************
-- Return Resultset #6 - Reason 1 Pareto
--*********************************************************************************
If @ColumnNameDowntimeReason1 Is Not Null
  Begin
    Select @SQL = 'Select Reason1 as [' + @ColumnNameDowntimeReason1 + '] ' 
    Select @SQL = @SQL + ',convert(nvarchar(25),convert(int,Sum(Duration) / 3600)) + ' + '''' + ':' + '''' +  ' + right(' + '''' + '0' + '''' + ' + convert(nvarchar(25),convert(int,(sum(Duration) - convert(int,sum(Duration) / 3600) * 3600)/60)),2) as [' + @ColumnNameTotalDown + '] '
    Select @SQL = @SQL + ',Count(Duration) as [' + @ColumnNameNumberDown + '] '
    If @TotalDown > 0
      Select @SQL = @SQL + ',replace(convert(nvarchar(25),convert(decimal(10,2),Sum(Duration) / convert(real,' + convert(nvarchar(25),@TotalDown) + ') * 100.0)),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ') as [' + @ColumnNamePercentDown + '] '
    Select @SQL = @SQL + ',replace(convert(nvarchar(25),convert(decimal(10,2),Sum(Duration) / convert(real,' + convert(nvarchar(25),@TotalOperating) + ') * 100.0)),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ') as [' + @ColumnNamePercentTime + '] '
    If @TotalOperating > 0 
      Select @SQL = @SQL + 'From #DowntimeDetails Group By Reason1 Order By [' + @ColumnNameTotalDown + '] DESC' 
    --print @SQL 
    Execute (@SQL)
  End
--*********************************************************************************
-- Return Resultset #7 - Reason 2 Pareto
--*********************************************************************************
If @ColumnNameDowntimeReason2 Is Not Null
  Begin
    Select @SQL = 'Select Reason2 as [' + @ColumnNameDowntimeReason2 + '] ' 
    Select @SQL = @SQL + ',convert(nvarchar(25),convert(int,Sum(Duration) / 3600)) + ' + '''' + ':' + '''' +  ' + right(' + '''' + '0' + '''' + ' + convert(nvarchar(25),convert(int,(sum(Duration) - convert(int,sum(Duration) / 3600) * 3600)/60)),2) as [' + @ColumnNameTotalDown + '] '
    Select @SQL = @SQL + ',Count(Duration) as [' + @ColumnNameNumberDown + '] '
    If @TotalDown > 0
      Select @SQL = @SQL + ',replace(convert(nvarchar(25),convert(decimal(10,2),Sum(Duration) / convert(real,' + convert(nvarchar(25),@TotalDown) + ') * 100.0)),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ') as [' + @ColumnNamePercentDown + '] '
    Select @SQL = @SQL + ',replace(convert(nvarchar(25),convert(decimal(10,2),Sum(Duration) / convert(real,' + convert(nvarchar(25),@TotalOperating) + ') * 100.0)),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ') as [' + @ColumnNamePercentTime + '] '
    If @TotalOperating > 0 
      Select @SQL = @SQL + 'From #DowntimeDetails Group By Reason2 Order By [' + @ColumnNameTotalDown + '] DESC' 
    --print @SQL 
    Execute (@SQL)
  End
Drop Table #DowntimeDetails
--*********************************************************************************
-- Return Resultset #8 - Waste Location Pareto
--*********************************************************************************
Select @SQL = 'Select Location as [' + @ColumnNameLocation + '] ' 
Select @SQL = @SQL + ',replace(convert(nvarchar(25),convert(decimal(10,2),Sum(Amount))),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ') as [' + @ColumnNameTotalWaste + '] '
Select @SQL = @SQL + ',Count(amount) as [' + @ColumnNameNumberWaste + '] '
If @TotalWaste > 0 
  Select @SQL = @SQL + ',replace(convert(nvarchar(25),convert(decimal(10,2),Sum(Amount) / convert(real,' + convert(nvarchar(25),@TotalWaste) + ') * 100.0)),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ') as [' + @ColumnNamePercentWaste + '] '
If @TotalProduction > 0 
  Select @SQL = @SQL + ',replace(convert(nvarchar(25),convert(decimal(10,2),Sum(Amount) / convert(real,' + convert(nvarchar(25),@TotalProduction) + ') * 100.0)),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ') as [' + @ColumnNamePercentProduction + '] '
Select @SQL = @SQL + 'From #WasteDetails Group By Location Order By [' + @ColumnNameTotalWaste + '] DESC' 
--print @SQL 
Execute (@SQL)
--*********************************************************************************
-- Return Resultset #9 - Waste Reason 1 Pareto
--*********************************************************************************
If @ColumnNameWasteReason1 Is Not Null
  Begin
    Select @SQL = 'Select Reason1 as [' + @ColumnNameWasteReason1 + '] ' 
    Select @SQL = @SQL + ',replace(convert(nvarchar(25),convert(decimal(10,2),Sum(Amount))),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ')  as [' + @ColumnNameTotalWaste + '] '
    Select @SQL = @SQL + ',Count(amount) as [' + @ColumnNameNumberWaste + '] '
    If @TotalWaste > 0 
      Select @SQL = @SQL + ',replace(convert(nvarchar(25),convert(decimal(10,2),Sum(Amount) / convert(real,' + convert(nvarchar(25),@TotalWaste) + ') * 100.0)),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ') as [' + @ColumnNamePercentWaste + '] '
    If @TotalProduction > 0 
      Select @SQL = @SQL + ',replace(convert(nvarchar(25),convert(decimal(10,2),Sum(Amount) / convert(real,' + convert(nvarchar(25),@TotalProduction) + ') * 100.0)),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ') as [' + @ColumnNamePercentProduction + '] '
    Select @SQL = @SQL + 'From #WasteDetails Group By Reason1 Order By [' + @ColumnNameTotalWaste + '] DESC' 
    --print @SQL 
    Execute (@SQL)
  End
--*********************************************************************************
-- Return Resultset #10 - Waste Reason 2 Pareto
--*********************************************************************************
If @ColumnNameWasteReason2 Is Not Null
  Begin
    Select @SQL = 'Select Reason2 as [' + @ColumnNameWasteReason2 + '] ' 
    Select @SQL = @SQL + ',replace(convert(nvarchar(25),convert(decimal(10,2),Sum(Amount))),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ') as [' + @ColumnNameTotalWaste + '] '
    Select @SQL = @SQL + ',Count(amount) as [' + @ColumnNameNumberWaste + '] '
    If @TotalWaste > 0 
      Select @SQL = @SQL + ',replace(convert(nvarchar(25),convert(decimal(10,2), Sum(Amount) / convert(real,' + convert(nvarchar(25),@TotalWaste) + ') * 100.0)),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ') as [' + @ColumnNamePercentWaste + '] '
    If @TotalProduction > 0 
      Select @SQL = @SQL + ',replace(convert(nvarchar(25),convert(decimal(10,2), Sum(Amount) / convert(real,' + convert(nvarchar(25),@TotalProduction) + ') * 100.0)),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ') as [' + @ColumnNamePercentProduction + '] '
    Select @SQL = @SQL + 'From #WasteDetails Group By Reason2 Order By [' + @ColumnNameTotalWaste + '] DESC' 
    --print @SQL 
    Execute (@SQL)
  End
Drop Table #WasteDetails
