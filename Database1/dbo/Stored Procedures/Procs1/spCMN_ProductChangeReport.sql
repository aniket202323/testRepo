--  spCMN_ProductChangeReport 7
Create Procedure dbo.spCMN_ProductChangeReport
@Unit int,
@StartTime datetime = NULL,
@EndTime datetime = NULL,
@LanguageNumber int = 0,
@DecimalSeparator nvarchar(1) = NULL
AS
Declare @SQL nvarchar(2000)
--*********************************************************************************
-- Prepare Start and End Times
--*********************************************************************************
Declare @Now datetime
Declare @Hour int
Declare @Minute int
Select @Now = dbo.fnServer_CmnGetDate(getUTCdate())
If @StartTime is Null
   Begin
 	 DECLARE @timeTable table (RRDId Int,PDesc nvarchar(100),PromptId Int,StartTime Datetime,EndTime DateTime)
 	 DECLARE @TZ nvarchar(200)
 	 SELECT @TZ = dbo.fnServer_GetTimeZone(@Unit)
 	 Insert Into @timeTable(RRDId ,PDesc ,PromptId ,StartTime ,EndTime)
 	  	 EXECUTE dbo.spGE_GetRelativeDates @TZ
    	 Select @StartTime = StartTime FROM @timeTable Where RRDId = 30
   End
If @EndTime Is Null
  Select @EndTime = @Now
--*********************************************************************************
-- Translate Column Names and Other Strings (By Language)
--*********************************************************************************
Declare @TempString nvarchar(50)
Declare @ResultsetNameProductChange nvarchar(50)
Declare @ColumnNameProductCode nvarchar(50)
Declare @ColumnNameProductDescription nvarchar(50)
Declare @ColumnNameStartTime nvarchar(50)
Declare @ColumnNameEndTime nvarchar(50)
Declare @ColumnNameDuration nvarchar(50)
Declare @TextInProcess nvarchar(50)
Select @ResultsetNameProductChange = 'Product Changes'
Select @ColumnNameProductCode = 'Product Code'
Select @ColumnNameProductDescription = 'Product'
Select @ColumnNameStartTime = 'Start Time'
Select @ColumnNameEndTime = 'End Time'
Select @ColumnNameDuration = 'Duration'
Select @TextInProcess = 'In-Process'
If @LanguageNumber <> 0
  Begin
    Select @TempString = NULL
    Select @TempString = Prompt_String 
      From Language_Data
      Where Language_Id = @LanguageNumber and Prompt_Number = 24098
    Select @ResultsetNameProductChange = coalesce(@TempString,@ResultsetNameProductChange)     
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
      Where Language_Id = @LanguageNumber and Prompt_Number = 24261
    Select @TextInProcess = coalesce(@TempString,@TextInProcess)     
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
Insert Into #Resultsets (ResultOrder, ResultName)
  Values (1, @ResultsetNameProductChange)
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
-- Return Resultset #3 - Product Change Data
--*********************************************************************************
Select @SQL = 'Select p.Prod_Code as ['  + @ColumnNameProductCode + '], ' +  
       'p.Prod_Desc as [' + @ColumnNameProductDescription+ '], ' + 
       'ps.Start_Time as [' + @ColumnNameStartTime + '], ' + 
       'ps.End_Time as [' + @ColumnNameEndTime + '], ' + 
       'Case ' + 
         'When ps.End_Time Is Null Then ' + 
           'convert(nvarchar(10),datediff(Minute,ps.Start_Time, dbo.fnServer_CmnGetDate(getUTCdate()))/60) + ' + ''':''' + ' + right(' + '''0''' + ' + convert(nvarchar(10),datediff(minute,ps.Start_Time, dbo.fnServer_CmnGetDate(getUTCdate())) - datediff(minute,ps.Start_Time, dbo.fnServer_CmnGetDate(getUTCdate()))/60*60),2) + '  + '''' + ' (' + @TextInProcess  + ')' + '''' + ' ' +  
         'Else ' +
           'convert(nvarchar(10),datediff(Minute,ps.Start_Time, ps.End_Time)/60) + ' + ''':''' + ' + right(' + '''0''' + ' + convert(nvarchar(10),datediff(minute,ps.Start_Time, ps.End_Time) - datediff(minute,ps.Start_Time, ps.End_Time)/60*60),2) ' +
       'End as [' + @ColumnNameDuration + '] ' + 
  'From Production_Starts ps ' + 
  'Join Products p on p.Prod_Id = ps.Prod_Id ' + 
  'Where ps.PU_Id = ' + convert(nvarchar(10) ,@Unit) + ' and ' + 
        'ps.Start_Time <= ' + '''' + convert(nVarChar(30), @EndTime,109) + '''' + ' and ' + 
        '((ps.End_Time > ' + '''' + convert(nVarChar(30), @StartTime,109) + '''' + ') or (ps.End_Time Is Null)) ' +
  'Order By ps.Start_Time DESC'
--print @SQL
Execute (@SQL)
