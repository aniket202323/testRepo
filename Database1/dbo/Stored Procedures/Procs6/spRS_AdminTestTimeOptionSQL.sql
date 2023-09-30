CREATE   PROCEDURE [dbo].[spRS_AdminTestTimeOptionSQL] 
@TimeOptionSQL varchar(1000)
AS
-------------------------------------
-- LOCAL VARIABLES
-------------------------------------
Declare @h varchar(3)
declare @m varchar(3)
Declare @t varchar(7)
Declare @s varchar(1000)
Declare @Now DateTime
DECLARE 	 @TimeOffset 	  	  	 VARCHAR(50) --formerly @t
DECLARE 	 @StartOfDaySeconds 	 VARCHAR(25)
DECLARE 	 @AccountingDate 	  	 VARCHAR(25)
DECLARE 	 @WeekStartDate 	  	 VARCHAR(25)
DECLARE 	 @WeekEndDate 	  	 VARCHAR(25)
DECLARE 	 @TempString 	  	  	 VARCHAR(255)
DECLARE 	 @BaseDate 	  	  	 VARCHAR(25)
DECLARE 	 @SQLString 	  	  	 VARCHAR(7000)
DECLARE 	 @ShiftInterval 	  	 VARCHAR(25)
DECLARE 	 @ShiftOffset 	  	 VARCHAR(25)
DECLARE 	 @EndOfWeekDay 	  	 INT
DECLARE 	 @StartOfWeekDay 	 INT
DECLARE 	 @OldStartOfWeekDay 	 INT
DECLARE 	 @EndOfDayHour 	  	 INT
DECLARE 	 @EndOfDayMin 	  	 INT
DECLARE   @Date_Type_Id 	  	 INT
Declare   @MyId int
-------------------------------------------------------------------------------
-- Get Site StartOfDay in seconds.
-------------------------------------------------------------------------------
SELECT 	 @EndOfDayHour = 0, @EndOfDayMin = 0, @StartOfDaySeconds = 0, @TempString = NULL
-- EndOfDayHour.
SELECT 	 @TempString = Value 	 FROM dbo.Site_Parameters WHERE Parm_Id = 14
IF IsNumeric(@TempString) = 1 
 	 SELECT @EndOfDayHour = Convert(Int, @TempString)
-- EndOfDayMin.
SELECT 	 @TempString = NULL
SELECT 	 @TempString = Value FROM dbo.Site_Parameters WHERE Parm_Id = 15
IF IsNumeric(@TempString) = 1
 	 SELECT 	 @EndOfDayMin = Convert(Int, @TempString)
SELECT 	 @StartOfDaySeconds = Convert(VARCHAR(25), @EndOfDayHour * 3600 + @EndOfDayMin * 60)
-------------------------------------------------------------------------------
-- Get ShiftInterval in seconds
-------------------------------------------------------------------------------
SELECT 	 @ShiftInterval = ''
SELECT 	 @TempString = NULL
SELECT 	 @TempString = Value FROM dbo.Site_Parameters WHERE 	 Parm_Id = 16
IF 	 IsNumeric(@TempString) = 1
 	 SELECT 	 @ShiftInterval = Convert(VARCHAR(25), Convert(Int, @TempString) * 60)
ELSE
 	 SELECT 	 @ShiftInterval = Convert(VARCHAR(25), 480 * 60)
-------------------------------------------------------------------------------
-- Get ShiftOffset in seconds AM MSI 04-Apr-2003
-------------------------------------------------------------------------------
SELECT 	 @ShiftOffset = ''
SELECT 	 @TempString = NULL
SELECT 	 @TempString = Value FROM dbo.Site_Parameters WHERE Parm_Id = 17
IF 	 IsNumeric(@TempString) = 1 -- NUMERIC SHIFT OFFSET
 	 BEGIN
 	  	 IF Convert(Int, @TempString)=0 --Shift Offset is 0
 	  	  	 BEGIN
 	  	  	  	 SELECT 	 @ShiftOffset = @StartOfDaySeconds -- ASSUME THAT SHIFT 1 STARTS WHEN MILL DAY STARTS
 	  	  	 END
 	  	 ELSE
 	  	  	 BEGIN -- SHIFT OFFSET IS NOT 0
 	  	  	  	 SELECT 	 @ShiftOffset = Convert(VARCHAR(25), Convert(Int, @TempString) * 60)
 	  	  	 END
 	 END
ELSE -- NON-NUMERIC SHIFT OFFSET OR NULL
 	 BEGIN
 	  	 SELECT 	 @ShiftOffset = @StartOfDaySeconds -- ASSUME THAT SHIFT 1 STARTS WHEN MILL DAY STARTS
 	 END
-------------------------------------------------------------------------------
-- Get time offset
-------------------------------------------------------------------------------
SELECT 	 @TimeOffset = ''
SELECT 	 @TimeOffset = Convert(VARCHAR(50), @StartOfDaySeconds, 118) 
-------------------------------------------------------------------------------
-- Get Site EndOfWeek in days.
-------------------------------------------------------------------------------
SELECT 	 @EndOfWeekDay = 6, @TempString = NULL
SELECT 	 @TempString = Value FROM dbo.Site_Parameters WHERE Parm_Id = 301
IF 	 IsNumeric(@TempString) = 1
 	 SELECT 	 @EndOfWeekDay = Convert(Int, @TempString)
IF 	 @EndOfWeekDay = 7
 	 SELECT 	 @StartOfWeekDay = 1
ELSE
 	 SELECT 	 @StartOfWeekDay = @EndOfWeekDay + 1
SELECT 	 @OldStartOfWeekDay = @@DateFirst
SET  	 DATEFIRST @StartOfWeekDay
-------------------------------------------------------------------------------
-- Get temporary dates.
-------------------------------------------------------------------------------
SELECT 	 @AccountingDate = Convert(DateTime, Floor(Convert(Float, DateAdd(Second, -Convert(Int, @StartOfDaySeconds), GetDate()))))
-- Week Start date.
SELECT 	 @WeekStartDate = @AccountingDate
WHILE 	 DatePart(WeekDay, @WeekStartDate) <> 1
 	 BEGIN
 	  	 SELECT 	 @WeekStartDate = DateAdd(Day, -1, @WeekStartDate)
 	  	 CONTINUE
 	 END
-- Week End date.
SELECT 	 @WeekEndDate = @AccountingDate
WHILE 	 DatePart(WeekDay, @WeekEndDate) <> 7
 	 BEGIN
 	  	 SELECT 	 @WeekEndDate = DateAdd(Day, 1, @WeekEndDate)
 	  	 CONTINUE
 	 END
----------------------------------------------------------
-- Initialize Mill Start Time from Site_Parameters Table
----------------------------------------------------------
Select @Now = GetDate()
select @h = convert(varchar(3),Value) from site_parameters where parm_Id = 14
select @m = convert(varchar(3),Value) from site_parameters where parm_Id = 15
If @h < 0 Select @h = 24 + @h
If @h < 0 Select @H = 0
If @h > 23 Select @h = 0
If @m < 0 Select @m = 60 + @m
If @m < 0 Select @m = 0
If @m > 59 Select @m = 0
if Len(@M) = 1 Select @m = '0' + @m
select @t = @h + ':' +  @m  + ':00'
Select @s = @TimeOptionSQL
Select @s = Replace(@s, '@t', '''' + @t + '''')
Select @s = Replace(@s, '@H01', '''' + '-01 ' + '''')
Select @s = Replace(@s, '@H', '''' + '-' + '''')
SELECT @s = Replace(@s, '@WeekStartDate', '''' + @WeekStartDate + '''')
SELECT @s = Replace(@s, '@WeekEndDate', '''' + @WeekEndDate + '''')
SELECT @s = Replace(@s, '@StartOfDaySeconds', @StartOfDaySeconds)
SELECT @s = Replace(@s, '@AccountingDate', '''' + @AccountingDate + '''')
SELECT @s = Replace(@s, '@ShiftInterval', @ShiftInterval)
Exec('Select ' + @S + '''' + 'TimeStamp' + '''')
