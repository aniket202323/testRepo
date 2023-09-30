Create Procedure dbo.spCMN_ScheduleReport
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
Declare @ResultsetNameSchedule nvarchar(50)
Declare @ColumnNameProcessOrder nvarchar(50)
Declare @ColumnNameStatus nvarchar(50)
Declare @ColumnNameProductCode nvarchar(50)
Declare @ColumnNameProductDescription nvarchar(50)
Declare @ColumnNameAmount nvarchar(50)
Declare @ColumnNameStartTime nvarchar(50)
Declare @ColumnNameEndTime nvarchar(50)
Declare @ColumnNameActualStart nvarchar(50)
Declare @ColumnNameActualEnd nvarchar(50)
Select @ResultsetNameSchedule = 'Schedule'
Select @ColumnNameProcessOrder = 'Process Order'
Select @ColumnNameStatus = 'Status'
Select @ColumnNameProductCode = 'Product Code'
Select @ColumnNameProductDescription = 'Product'
Select @ColumnNameAmount = 'Amount'
Select @ColumnNameStartTime = 'Forecast Start'
Select @ColumnNameEndTime = 'Forecast End'
Select @ColumnNameActualStart = 'Actual Start'
Select @ColumnNameActualEnd = 'Actual End'
If @LanguageNumber <> 0
  Begin
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24262
    Select @ResultsetNameSchedule = coalesce(@TempString,@ResultsetNameSchedule)     
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24148
    Select @ColumnNameProcessOrder = coalesce(@TempString,@ColumnNameProcessOrder)     
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24061
    Select @ColumnNameStatus = coalesce(@TempString,@ColumnNameStatus)     
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24038
    Select @ColumnNameProductCode = coalesce(@TempString,@ColumnNameProductCode)     
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24108
    Select @ColumnNameProductDescription = coalesce(@TempString,@ColumnNameProductDescription)     
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24125
    Select @ColumnNameAmount = coalesce(@TempString,@ColumnNameAmount)     
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24263
    Select @ColumnNameStartTime = coalesce(@TempString,@ColumnNameStartTime)     
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24264
    Select @ColumnNameEndTime = coalesce(@TempString,@ColumnNameEndTime)     
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24265
    Select @ColumnNameActualStart = coalesce(@TempString,@ColumnNameActualStart)     
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24266
    Select @ColumnNameActualEnd = coalesce(@TempString,@ColumnNameActualEnd)     
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
Insert Into #ColumnFormats (TimeColumns) 
  Values (@ColumnNameActualStart)
Insert Into #ColumnFormats (TimeColumns) 
  Values (@ColumnNameActualEnd)
--*********************************************************************************
-- Define Resultset Names To Be Returned
--*********************************************************************************
Create Table #Resultsets (
  ResultOrder int,
  ResultName nvarchar(50)  
)
Insert Into #Resultsets (ResultOrder, ResultName)
  Values (1, @ResultsetNameSchedule)
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
-- Return Resultset #3 - Schedule Data
--*********************************************************************************
Select @SQL = 'Select Case When pp.PP_Status_Id = 3 Then 1 Else 0 End as [Bold], ' + 
       'pp.Process_Order as [' + @ColumnNameProcessOrder + '], ' + 
       's.PP_Status_Desc as [' + @ColumnNameStatus + '], ' +  
       'p.Prod_Code as ['  + @ColumnNameProductCode + '], ' +  
       'p.Prod_Desc as [' + @ColumnNameProductDescription+ '], ' + 
       'replace(convert(nvarchar(25),convert(decimal(10,2),pp.Forecast_Quantity)),' + '''' + '.' + '''' + ',' + '''' + @DecimalSeparator + '''' + ') as [' + @ColumnNameAmount + '], ' + 
       'pp.Forecast_Start_Date as [' + @ColumnNameStartTime + '], ' + 
       'pp.Forecast_End_Date as [' + @ColumnNameEndTime + '], ' + 
       '(Select min(Start_Time) From Production_Plan_Starts pps Where pps.PP_Id = pp.PP_Id) as [' + @ColumnNameActualStart + '], ' + 
       '(Select max(End_Time) From Production_Plan_Starts pps Where pps.PP_Id = pp.PP_Id and pps.End_Time Is Not NULL) as [' + @ColumnNameActualEnd + '] ' + 
 	    ' From Prdexec_path_Units pu ' + 
 	    ' Join  Production_Plan pp  On pp.Path_Id = pu.Path_Id  and ' + 
         	 'pp.Forecast_Start_Date < ' + '''' + convert(nVarChar(30), @EndTime,109) + '''' + ' and ' + 
         	 'pp.Forecast_Start_Date >= ' + '''' + convert(nVarChar(30), @StartTime,109) + '''' +
   	    ' Join Production_Plan_Statuses s on s.PP_Status_Id = pp.PP_Status_Id ' + 
   	    ' Join Products p on p.Prod_Id = pp.Prod_Id ' + 
 	  	 'Where pu.PU_Id = ' + convert(nvarchar(10) ,@Unit) + ' Order By pp.Implied_Sequence DESC'
/*
  'From Production_Plan pp ' + 
  'Join Production_Plan_Statuses s on s.PP_Status_Id = pp.PP_Status_Id ' + 
  'Join Products p on p.Prod_Id = pp.Prod_Id ' + 
  'Where pp.PU_Id = ' + convert(nvarchar(10) ,@Unit) + ' and ' + 
        'pp.Forecast_Start_Date < ' + '''' + convert(nVarChar(30), @EndTime,109) + '''' + ' and ' + 
        'pp.Forecast_Start_Date >= ' + '''' + convert(nVarChar(30), @StartTime,109) + '''' + ' ' +
  'Order By pp.Implied_Sequence DESC'
*/
--print @SQL
Execute (@SQL)
