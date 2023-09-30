CREATE   PROCEDURE [dbo].[spDBR_GetTimeOptions] 
@Option_Id int = Null,
@InTimeZone varchar(200) = ''
AS
---LMA:  Added to Trap for Missing TimeZone 
Declare @CatchTimeZone varchar(200)
Select @CatchTimeZone = Default_Value from Report_Parameters where rp_id = -47
If @InTimeZone is NULL or @InTimezone = '' SET @InTimeZone = @CatchTimeZone
-------------------------------------
-- LOCAL VARIABLES
-------------------------------------
DECLARE @h VARCHAR(3)
DECLARE @m VARCHAR(3)
DECLARE @t VARCHAR(7)
DECLARE @optionName VARCHAR(10)
DECLARE @Description VARCHAR(20)
DECLARE @Start_Time DATETIME
DECLARE @End_Time DATETIME
DECLARE @s VARCHAR(1000)
DECLARE @e VARCHAR(1000)
DECLARE @x VARCHAR(1000)
DECLARE @Now DATETIME
Declare @MyId int
----VC----
DECLARE  	  @TimeOffset  	    	    	  VARCHAR(50) --formerly @t
DECLARE  	  @StartOfDaySeconds  	  VARCHAR(25)
DECLARE  	  @AccountingDate  	    	  VARCHAR(25)
DECLARE  	  @WeekStartDate  	    	  VARCHAR(25)
DECLARE  	  @WeekEndDate  	    	  VARCHAR(25)
DECLARE  	  @TempString  	    	    	  VARCHAR(255)
DECLARE  	  @BaseDate  	    	    	  VARCHAR(25)
DECLARE  	  @SQLString  	    	    	  VARCHAR(7000)
DECLARE  	  @ShiftInterval  	    	  VARCHAR(25)
DECLARE  	  @ShiftOffset  	    	  VARCHAR(25)
DECLARE  	  @EndOfWeekDay  	    	  INT
DECLARE  	  @StartOfWeekDay  	  INT
DECLARE  	  @OldStartOfWeekDay  	  INT
DECLARE  	  @EndOfDayHour  	    	  INT
DECLARE  	  @EndOfDayMin  	    	  INT
DECLARE @Date_Type_Id  	    	  INT
Declare @DBTimeZone 	 varchar(200)
DECLARE @MillStartDate datetime
----VC----
----------------------------------------------------------
-- Initialize Mill Start Time from Site_Parameters Table
----------------------------------------------------------
SELECT @DBTimeZone = Value from dbo.Site_Parameters where Parm_Id=192
Select @Now = dbo.fnServer_CmnConvertTime(dbo.fnServer_CmnGetDate(GETUTCDATE()),@DBTimeZone,@InTimeZone)
 	 
select @h = convert(varchar(3),Value) from site_parameters where parm_Id = 14   --Site Parameter EndOfDayHour
select @m = convert(varchar(3),Value) from site_parameters where parm_Id = 15   --Site Parameter EndOfDayMinute
SELECT @MillStartDate = dateadd(dd,0, datediff(dd,0,dbo.fnServer_CmnGetDate(GETUTCDATE())))
SELECT @MillStartDate = DateAdd(hh,convert(int,@h),@MillStartDate)
SELECT @MillStartDate = DateAdd(mm,convert(int,@m),@MillStartDate)
If @h < 0 Select @h = 24 + @h
If @h < 0 Select @H = 0
If @h > 23 Select @h = 0
If @m < 0 Select @m = 60 + @m
If @m < 0 Select @m = 0
If @m > 59 Select @m = 0
if Len(@M) = 1 Select @m = '0' + @m
select @t = @h + ':' +  @m  + ':00'
Create table #t(
  Option_id int,
  Date_Type_Id int,
  Description varchar(100),
  Start_Time varchar(30),
  End_Time varchar(30),
  Time_Difference int
)
-- Insert types 1 and 2
insert into #t(Option_Id, Date_Type_Id, Description)
select RRD_Id, Date_Type_Id, Default_Prompt_Desc from report_Relative_Dates where Date_Type_Id in (1,2) order by rrd_Id
----------
----VC----
-------------------------------------------------------------------------------
-- Get Site StartOfDay in seconds.
-------------------------------------------------------------------------------
SELECT  	  @EndOfDayHour = 0, @EndOfDayMin = 0, @StartOfDaySeconds = 0, @TempString = NULL
-- EndOfDayHour.
SELECT  	  @TempString = Value  	  FROM dbo.Site_Parameters WHERE Parm_Id = 14
IF IsNumeric(@TempString) = 1 
  	  SELECT @EndOfDayHour = Convert(Int, @TempString)
-- EndOfDayMin.
SELECT  	  @TempString = NULL
SELECT  	  @TempString = Value FROM dbo.Site_Parameters WHERE Parm_Id = 15
IF IsNumeric(@TempString) = 1
  	  SELECT  	  @EndOfDayMin = Convert(Int, @TempString)
SELECT  	  @StartOfDaySeconds = Convert(VARCHAR(25), @EndOfDayHour * 3600 + @EndOfDayMin * 60)
-------------------------------------------------------------------------------
-- Get ShiftInterval in seconds
-------------------------------------------------------------------------------
SELECT  	  @ShiftInterval = ''
SELECT  	  @TempString = NULL
SELECT  	  @TempString = Value FROM dbo.Site_Parameters WHERE  	  Parm_Id = 16
IF  	  IsNumeric(@TempString) = 1
  	  SELECT  	  @ShiftInterval = Convert(VARCHAR(25), Convert(Int, @TempString) * 60)
ELSE
  	  SELECT  	  @ShiftInterval = Convert(VARCHAR(25), 480 * 60)
-------------------------------------------------------------------------------
-- Get ShiftOffset in seconds AM MSI 04-Apr-2003
-------------------------------------------------------------------------------
SELECT  	  @ShiftOffset = ''
SELECT  	  @TempString = NULL
SELECT  	  @TempString = Value FROM dbo.Site_Parameters WHERE Parm_Id = 17
IF  	  IsNumeric(@TempString) = 1 -- NUMERIC SHIFT OFFSET
  	  BEGIN
  	    	  IF Convert(Int, @TempString)=0 --Shift Offset is 0
  	    	    	  BEGIN
  	    	    	    	  SELECT  	  @ShiftOffset = @StartOfDaySeconds -- ASSUME THAT SHIFT 1 STARTS WHEN MILL DAY STARTS
  	    	    	  END
  	    	  ELSE
  	    	    	  BEGIN -- SHIFT OFFSET IS NOT 0
  	    	    	    	  SELECT  	  @ShiftOffset = Convert(VARCHAR(25), Convert(Int, @TempString) * 60)
  	    	    	  END
  	  END
ELSE -- NON-NUMERIC SHIFT OFFSET OR NULL
  	  BEGIN
  	    	  SELECT  	  @ShiftOffset = @StartOfDaySeconds -- ASSUME THAT SHIFT 1 STARTS WHEN MILL DAY STARTS
  	  END
-------------------------------------------------------------------------------
-- Get time offset
-------------------------------------------------------------------------------
SELECT  	  @TimeOffset = ''
SELECT  	  @TimeOffset = Convert(VARCHAR(50), @StartOfDaySeconds, 118) 
-------------------------------------------------------------------------------
-- Get Site EndOfWeek in days.
-------------------------------------------------------------------------------
SELECT  	  @EndOfWeekDay = 6, @TempString = NULL
SELECT  	  @TempString = Value FROM dbo.Site_Parameters WHERE Parm_Id = 301
IF  	  IsNumeric(@TempString) = 1
  	  SELECT  	  @EndOfWeekDay = Convert(Int, @TempString)
IF  	  @EndOfWeekDay = 7
  	  SELECT  	  @StartOfWeekDay = 1
ELSE
  	  SELECT  	  @StartOfWeekDay = @EndOfWeekDay + 1
SELECT  	  @OldStartOfWeekDay = @@DateFirst
SET   	  DATEFIRST @StartOfWeekDay
-------------------------------------------------------------------------------
-- Get temporary dates.
-------------------------------------------------------------------------------
SELECT  	  @AccountingDate = Convert(DateTime, Floor(Convert(Float, DateAdd(Second, -Convert(Int, @StartOfDaySeconds), dbo.fnServer_CmnGetDate(getutcdate())))))
-- Week Start date.
SELECT  	  @WeekStartDate = @AccountingDate
WHILE  	  DatePart(WeekDay, @WeekStartDate) <> 1
  	  BEGIN
  	    	  SELECT  	  @WeekStartDate = DateAdd(Day, -1, @WeekStartDate)
  	    	  CONTINUE
  	  END
-- Week End date.
SELECT  	  @WeekEndDate = @AccountingDate
WHILE  	  DatePart(WeekDay, @WeekEndDate) <> 7
  	  BEGIN
  	    	  SELECT  	  @WeekEndDate = DateAdd(Day, 1, @WeekEndDate)
  	    	  CONTINUE
  	  END
Declare Cursor1 Insensitive Cursor
  For (
       Select option_Id, Date_Type_Id
       From #t
      )
  For Read Only
  Open Cursor1  
Cursor1LoopBegin:
Fetch Next From Cursor1 Into @MyId, @Date_Type_Id
  If (@@Fetch_Status = 0)
    Begin
  	    	  -------------------------------------------------------------------------------
  	    	  -- Get @SQLString based upon the Relative Date Id. (Start_Date_SQL)
  	    	  -------------------------------------------------------------------------------
  	    	  SELECT  	  @SQLString = ''
  	    	  -------------------------------------------------------------------------------
  	    	  -- Get @SQLString based upon the Relative Date Id. (Start_Date_SQL)
  	    	  -------------------------------------------------------------------------------
  	    	  SELECT  	  @SQLString = ''
  	    	  SELECT  	  @SQLString = Start_Date_SQL FROM dbo.Report_Relative_Dates WHERE RRD_Id = @MyId
  	    	  
  	    	  SELECT  	  @SQLString = Replace(@SQLString, '@StartOfDaySeconds', @StartOfDaySeconds)
  	    	  SELECT  	  @SQLString = Replace(@SQLString, '@AccountingDate', '''' + @AccountingDate + '''')
  	    	  SELECT  	  @SQLString = Replace(@SQLString, '@WeekStartDate', '''' + @WeekStartDate + '''')
  	    	  SELECT  	  @SQLString = Replace(@SQLString, '@WeekEndDate', '''' + @WeekEndDate + '''')
  	    	  SELECT  	  @SQLString = Replace(@SQLString, '@ShiftInterval', @ShiftInterval)
  	    	  SELECT  	  @SQLString = Replace(@SQLString, '@t', @TimeOffset)
  	    	  If (@Date_Type_Id = 1) 
  	    	    	  SELECT  	  @SQLString = Replace(@SQLString, 'SELECT', 'Update #t Set Start_Time = Convert(VarChar(20), ')  	  
  	    	  Else
  	    	    	  SELECT  	  @SQLString = Replace(@SQLString, 'SELECT', 'Update #t Set End_Time = Convert(VarChar(20), ')  	  
  	    	  Select @SQLString = @SQLString + ', 120) Where Option_Id = ' + convert(varchar(10), @MyId)
  	    	  --IF @DBTimeZone = 'UTC'
  	    	  --  	  	 SELECT @SQLString = replace(@SQLString,'getdate()','dbo.fnServer_CmnConvertTime(dbo.fnServer_CmnGetDate(GETUTCDATE()),''UTC'',' + ''''+ @InTimezone + ''')')
  	    	  --  	  ELSE
  	    	  --  	  	 BEGIN
  	    	    	  	 SELECT @SQLString = REPLACE(@SQLString,'getdate()','dbo.fnServer_CmnConvertTime(GETUTCDATE(),''UTC'',' + ''''+ @InTimezone + ''')')
  	    	    	  	 --END
  	    	  --SELECT @SQLString = REPLACE(@SQLString,'getdate()','dbo.fnServer_CmnGetDate(getutcdate())')
  	    	  Exec(@SQLString)
      Goto Cursor1LoopBegin
    End
  Else
    Goto Cursor1End
Cursor1End:
Close Cursor1
Deallocate Cursor1
----VC----
----------
------------------------------------------------
-- Date_Type_Id = 3 are Start->End Time Ranges
------------------------------------------------
insert into #t(Option_Id, Date_Type_Id, Description)
select RRD_Id, Date_Type_Id, Default_Prompt_Desc from report_Relative_Dates where Date_Type_Id = 3 order by rrd_Id
Declare MyCursor INSENSITIVE CURSOR
  For (
       Select option_Id
       From #t
       Where Date_Type_Id = 3
      )
  For Read Only
  Open MyCursor  
MyLoop1:
  Fetch Next From MyCursor Into @MyId 
  If (@@Fetch_Status = 0)
    Begin -- Begin Loop Here
      Select @s = Start_Date_SQL, @e = End_Date_SQL from Report_Relative_Dates where RRD_id = @MyId
  	    If @s is not null
        Begin
  	    	    	  --------------------------
  	    	    	  -- Character Replacement
  	    	    	  --------------------------
  	    	    	  --IF @DBTimeZone = 'UTC'
  	    	    	  	 --SELECT @s = replace(@s,'getdate()','dbo.fnServer_CmnConvertTime(dbo.fnServer_CmnGetDate(GETUTCDATE()),''UTC'',' + ''''+ @InTimezone + ''')')
  	    	    	  --ELSE
  	    	    	  	 --BEGIN
  	    	    	  	 SELECT @s = REPLACE(@s,'getdate()','dbo.fnServer_CmnConvertTime(GETUTCDATE(),''UTC'',' + ''''+ @InTimezone + ''')')
  	    	    	  	  
  	    	    	  	 --END
  	    	    	  --IF @DBTimeZone = 'UTC'
  	    	    	  	 --SELECT @e = replace(@e,'getdate()','dbo.fnServer_CmnConvertTime(dbo.fnServer_CmnGetDate(GETUTCDATE()),''UTC'',' + ''''+ @InTimezone + ''')')
  	    	    	  --ELSE
  	    	    	  	 --BEGIN
  	    	    	  	 SELECT @e = REPLACE(@e,'getdate()','dbo.fnServer_CmnConvertTime(GETUTCDATE(),''UTC'',' + ''''+ @InTimezone + ''')')
  	    	    	  	 --END
  	    	    	  SELECT @s = Replace(@s, '@t', '''' + @t + '''')
  	    	    	  SELECT @e = Replace(@e, '@t', '''' + @t + '''')
  	    	    	  
  	    	    	  SELECT @e = Replace(@e, '@H01', '''' + '-01 ' + '''')
  	    	    	  SELECT @s = Replace(@s, '@H01', '''' + '-01 ' + '''')
  	    	    	  
  	    	    	  SELECT @e = Replace(@e, '@H', '''' + '-' + '''')
  	    	    	  SELECT @s = Replace(@s, '@H', '''' + '-' + '''')
  	    	    	  
  	    	    	  SELECT @e = Replace(@e, '@WeekStartDate', '''' + @WeekStartDate + '''')
  	    	    	  SELECT @s = Replace(@s, '@WeekStartDate', '''' + @WeekStartDate + '''')
  	    	    	  
  	    	    	  SELECT @e = Replace(@e, '@WeekEndDate', '''' + @WeekEndDate + '''')
  	    	    	  SELECT @s = Replace(@s, '@WeekEndDate', '''' + @WeekEndDate + '''')
  	    	    	  SELECT @s = Replace(@s, '@StartOfDaySeconds', @StartOfDaySeconds)
  	    	    	  SELECT @e = Replace(@e, '@StartOfDaySeconds', @StartOfDaySeconds)
  	    	    	  
  	    	    	  SELECT @s = Replace(@s, '@AccountingDate', '''' + @AccountingDate + '''')
  	    	    	  SELECT @e = Replace(@e, '@AccountingDate', '''' + @AccountingDate + '''')
  	    	    	  
  	    	    	  SELECT @s = Replace(@s, '@ShiftInterval', @ShiftInterval)
  	    	    	  SELECT @e = Replace(@e, '@ShiftInterval', @ShiftInterval)
  	    	    	  SELECT @s = 'update #t set Start_Time = Convert(VarChar(20), ' + @s + ', 120) where Option_Id = ' + convert(varchar(5), @MyId)
  	    	    	  SELECT @e = 'update #t set End_Time = Convert(VarChar(20), ' + @e + ', 120) where Option_Id = ' + convert(varchar(5), @MyId)
  	    	    	  -----------------------------------------
  	    	    	  -- Fill #t with the start and end times
  	    	    	  -----------------------------------------
  	    	    	  exec(@s)
  	    	    	  exec(@e)
  	    	  End
      Goto MyLoop1
    End -- End Loop Here
  Else -- Nothing Left To Loop Through
    goto myEnd
myEnd:
Close MyCursor
Deallocate MyCursor
If  (Select Start_Time From #t Where Option_Id = 30) > @Now 
  Begin
 	 DECLARE @tempstart datetime, @tempend datetime
 	 SELECT @tempstart = Start_Time From #t where Option_Id = 31
 	  
  	  Update #t set 
       Start_Time = Convert(Varchar(30),Dateadd(day,-1,Start_time),120),
       End_Time = Convert(Varchar(30),Dateadd(day,-1,End_Time),120)
  	    Where Option_Id in (26,27,28,31)
     /*
     -- ECR #29399
     -- Problem occurs when you ask for today and current time is between
  	   -- midnight and mill start time     
     */
     -- Today
 	 SELECT @tempstart = Start_Time,@tempend=End_Time From #t where Option_Id = 30
 	 
 	 If @tempstart > @tempend
 	  	  Update #t set 
 	  	   Start_Time = Convert(Varchar(30),Dateadd(day,-1,Start_time),120)
 	  	 Where Option_Id = 30
  End
------------------------------------------
-- Select From #t the appropriate values
------------------------------------------
update #t set Time_Difference = DateDiff(n, Start_Time, End_Time)
If @Option_Id is null
  Select Option_Id, Description, Start_Time, End_Time 
  From #t
  Order By Time_Difference asc, Start_Time Desc, Description
Else
  Select Option_Id, Description, Start_Time, End_Time 
  From #t
  Where Option_Id = @Option_Id
drop table #t
