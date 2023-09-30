CREATE Procedure dbo.spBF_CalculateOEEReportTime(@LineId Int,@TimeSelection Int,@StartTime DateTime Output,@EndTime DateTime Output,@CappCurrentTime Int = 1)
AS 
BEGIN
  	  DECLARE @Hour  	  INT,
  	    	  @Minute  	    	  INT,
  	    	  @LocalNow  	  DateTime,
  	    	  @UTCNow  	    	  DateTime,
  	    	  @TempTime  	  DateTime,
  	    	  @LocalTimeZoneName nVarChar(200),
  	    	  @Deptid  	    	  Int
 	 /* 
 	 DECLARE  @EndTime DateTime
 	 DECLARE  @StartTime DateTime
 	 EXECUTE 	 dbo.spBF_CalculateOEEReportTime 1,1,@StartTime  Output,@EndTime  Output, 0
 	 SELECT @StartTime,@EndTime,'Current Day'
 	 EXECUTE 	 dbo.spBF_CalculateOEEReportTime 1,2,@StartTime  Output,@EndTime  Output, 0
 	 SELECT @StartTime,@EndTime,'Prev Day'
 	 EXECUTE 	 dbo.spBF_CalculateOEEReportTime 1,3,@StartTime  Output,@EndTime  Output, 0
 	 SELECT @StartTime,@EndTime,'Current Week'
 	 EXECUTE 	 dbo.spBF_CalculateOEEReportTime 1,4,@StartTime  Output,@EndTime  Output, 0
 	 SELECT @StartTime,@EndTime,'Prev Week'
 	 EXECUTE 	 dbo.spBF_CalculateOEEReportTime 1,5,@StartTime  Output,@EndTime  Output, 0
 	 SELECT @StartTime,@EndTime,'Next Week'
 	 EXECUTE 	 dbo.spBF_CalculateOEEReportTime 1,6,@StartTime  Output,@EndTime  Output, 0
 	 SELECT @StartTime,@EndTime,'Next Day'
 	 SELECT @StartTime = '1/1/2012 07:00'  ,@EndTime = '5/4/2012 07:00'
 	 EXECUTE 	 dbo.spBF_CalculateOEEReportTime 1,7,@StartTime  Output,@EndTime  Output, 0
 	 SELECT @StartTime,@EndTime,'User Defined'
 	 EXECUTE 	 dbo.spBF_CalculateOEEReportTime 1,8,@StartTime  Output,@EndTime  Output, 0
 	 SELECT @StartTime,@EndTime,'Current Shift'
 	 EXECUTE 	 dbo.spBF_CalculateOEEReportTime 1,9,@StartTime  Output,@EndTime  Output, 0
 	 SELECT @StartTime,@EndTime,'Previous Shift'
 	 EXECUTE 	 dbo.spBF_CalculateOEEReportTime 1,10,@StartTime  Output,@EndTime  Output, 0
 	 SELECT @StartTime,@EndTime,'Next Shift'
 	 Select Getutcdate()
 	  	 @TimeSelection = 1 /* Current Day  */
 	  	 @TimeSelection = 2 /* Prev Day     */
 	  	 @TimeSelection = 3 /* Current Week */
 	  	 @TimeSelection = 4 /* Prev Week    */
 	  	 @TimeSelection = 5 /* Next Week    */
 	  	 @TimeSelection = 6 /* Next Day     */
 	  	 @TimeSelection = 7 /* User Defined  Max 30 days*/
 	  	 @TimeSelection = 8 /* Current Shift    */
 	  	 @TimeSelection = 9 /* Previous Shift   */
 	  	 @TimeSelection = 10 /* Next Shift      */
 	 */
 	 IF @CappCurrentTime Is Null Set @CappCurrentTime = 1
 	  DECLARE  @EndOfWeekDay Int,@TempString nvarchar(100),@StartOfWeekDay Int, @OldStartOfWeekDay Int
 	  DECLARE @ShiftStartMinutes Int, @ShiftIntervalMinutes Int
 	  DECLARE @AccountingDate DateTime,@WeekStartDate  DateTime 
 	  SELECT @Deptid = Dept_Id FROM Prod_Lines WHERE PL_Id = @LineId
  	  SELECT @LocalTimeZoneName = Time_Zone 
 	  	 FROM Departments
 	  	 WHERE Dept_Id = @DeptId
  	  IF @LocalTimeZoneName Is Null
 	  	  SELECT @LocalTimeZoneName = Value 
 	  	  	 FROM Site_Parameters 
 	  	  	 WHERE Parm_Id = 192
  	  IF @LocalTimeZoneName Is Null  	  SELECT @LocalTimeZoneName = 'UTC'
  	  SELECT @UTCNow = Getutcdate()
  	  SELECT @LocalNow =  dbo.fnServer_CmnConvertTime (@UTCNow,'UTC',@LocalTimeZoneName)
  	  SELECT @TempTime = DateAdd(hour,-DatePart(Hour,@LocalNow),@LocalNow)
  	  SELECT @TempTime = DateAdd(Minute,-DatePart(Minute,@TempTime),@TempTime)
  	  SELECT @TempTime = DateAdd(Second,-DatePart(Second,@TempTime),@TempTime)
  	  SELECT @TempTime = DateAdd(Millisecond,-DatePart(Millisecond,@TempTime),@TempTime)
     IF @TimeSelection in (8,9,10) -- shift math
 	  BEGIN
 	    	  	  SELECT @ShiftStartMinutes = convert(Int,Value) from Dept_Parameters  where parm_Id = 17 and Dept_Id = @Deptid
  	  	  IF @ShiftStartMinutes Is Null
  	    	  	  SELECT @ShiftStartMinutes = convert(Int,Value) from site_parameters where parm_Id = 17   --Site Parameter Shift Offset
  	  	  If @ShiftStartMinutes Is Null Set @ShiftStartMinutes = 0
  	  	  SELECT @ShiftIntervalMinutes = convert(Int,Value) from Dept_Parameters  where parm_Id = 16 and Dept_Id = @Deptid
  	  	  IF @ShiftIntervalMinutes Is Null
  	    	  	  SELECT @ShiftIntervalMinutes = convert(Int,Value) from site_parameters where parm_Id = 16   --Site Parameter Shift Interval
  	  	  If @ShiftIntervalMinutes Is Null Set @ShiftIntervalMinutes = 480
 	  	 --$BeginRegion: New Code
  	  	  IF DATEADD(MINUTE, @ShiftStartMinutes, @TempTime)>@LocalNow
  	  	   	 SET @TempTime=DATEADD(DAY, -1, @TempTime);
  	  	  DECLARE @Shifts TABLE(ShiftRN INT NULL, ShiftStart DATETIME NULL, ShiftEnd DATETIME NULL);
  	  	  DECLARE @Shift_i INT, @Shift_n INT;
  	  	  SELECT @Shift_i=1, @Shift_n=(24 * 60)/ @ShiftIntervalMinutes;
  	  	  WHILE @Shift_i<=@Shift_n 
  	  	  BEGIN
  	  	   	 INSERT INTO @Shifts(ShiftRN, ShiftStart, ShiftEnd)
  	  	   	 SELECT 	 @Shift_i AS "ShiftRN", --Shift RN
  	  	   	  	 DATEADD(MINUTE, ((@Shift_i-1)* @ShiftIntervalMinutes+@ShiftStartMinutes), @TempTime) AS "ShiftStart", --Shift StartTime
  	  	   	  	 DATEADD(MINUTE, (@Shift_i * @ShiftIntervalMinutes)+@ShiftStartMinutes, @TempTime) AS "ShiftEnd"; --Shift EndTime
  	  	   	 SET @Shift_i=@Shift_i+1;
  	  	  END;
  	  	  --
  	  	  DECLARE @CurrentShiftStartTime DATETIME, @CurrentShiftEndTime DATETIME;
  	  	  SELECT 	 @CurrentShiftStartTime=ShiftStart, @CurrentShiftEndTime=ShiftEnd
  	  	  FROM 	 @Shifts
  	  	  WHERE @LocalNow BETWEEN ShiftStart AND ShiftEnd;
  	  	  --
  	  	  IF 	 @TimeSelection=9 
  	  	  BEGIN
  	  	   	 SELECT 	 @StartTime= dbo.fnServer_CmnConvertTime(DATEADD(MINUTE, -@ShiftIntervalMinutes, @CurrentShiftStartTime), @LocalTimeZoneName, 'UTC'),
  	  	   	  	  	 @EndTime = dbo.fnServer_CmnConvertTime(DATEADD(MINUTE, -@ShiftIntervalMinutes, @CurrentShiftEndTime), @LocalTimeZoneName, 'UTC');
  	  	  END;
  	  	  IF @TimeSelection=8 
  	  	  BEGIN
  	  	   	 SELECT 	 @StartTime = dbo.fnServer_CmnConvertTime(@CurrentShiftStartTime, @LocalTimeZoneName, 'UTC'), 
  	  	   	  	  	 @EndTime = dbo.fnServer_CmnConvertTime(@LocalNow, @LocalTimeZoneName, 'UTC');
  	  	  END;
  	  	  IF @TimeSelection=10 
  	  	  BEGIN
  	  	   	 SELECT 	 @StartTime = dbo.fnServer_CmnConvertTime(DATEADD(MINUTE, +@ShiftIntervalMinutes, @CurrentShiftStartTime), @LocalTimeZoneName, 'UTC'), 
  	  	   	  	  	 @EndTime = dbo.fnServer_CmnConvertTime(DATEADD(MINUTE, +@ShiftIntervalMinutes, @CurrentShiftEndTime), @LocalTimeZoneName, 'UTC');
  	  	  END;
 	  	 --$EndRegion: New Code
 	  	 /*
 	  	 --$BeginRegion: Old Code
 	  	  Select @TempTime = DateAdd(Minute,@ShiftStartMinutes,@TempTime)
 	  	  WHILE @TempTime > @LocalNow 
 	  	  BEGIN
 	  	  	 SET  @TempTime = DateAdd(Minute,-@ShiftIntervalMinutes,@TempTime)
 	  	  END
 	  	  WHILE DateAdd(Minute,@ShiftIntervalMinutes,@TempTime) < @LocalNow 
 	  	  BEGIN
 	  	  	 SET  @TempTime = DateAdd(Minute,@ShiftIntervalMinutes,@TempTime)
 	  	  END
 	  	 SELECT @TempTime = dbo.fnServer_CmnConvertTime (@TempTime , @LocalTimeZoneName,'UTC') 
 	  	 IF @TimeSelection = 8  /* Current Shift */
 	  	 BEGIN
 	  	  	 SET @StartTime = @TempTime
 	  	  	 SET @EndTime =   DateAdd(Minute, @ShiftIntervalMinutes, @StartTime)
 	  	  	 IF @CappCurrentTime = 1  and @EndTime > @UTCNow
 	  	  	  	 SET @EndTime =   @UTCNow 
 	  	 END
 	  	 IF @TimeSelection = 9  /* Prev Shift */
 	  	 BEGIN
 	  	  	 SET @EndTime =   @TempTime
 	  	  	 SET @StartTime = DateAdd(Minute,-@ShiftIntervalMinutes, @EndTime) 
 	  	  	 IF @CappCurrentTime = 1  and @EndTime > @UTCNow
 	  	  	  	 SET @EndTime =   @UTCNow 
 	  	 END
 	  	 IF @TimeSelection = 10  /* Next Shift */
 	  	 BEGIN
 	  	  	 SET @StartTime = @TempTime
 	  	  	 SET @StartTime = DateAdd(Minute,@ShiftIntervalMinutes, @StartTime) 
 	  	  	 SET @EndTime =   DateAdd(Minute, @ShiftIntervalMinutes, @StartTime)
 	  	 END
 	  	 --$EndRegion: Old Code
 	  	 */
 	  	 RETURN
  	  END
 	  SELECT @Hour = convert(Int,Value) from Dept_Parameters  where parm_Id = 14 and Dept_Id = @Deptid
  	  IF @Hour Is Null
  	    	  SELECT @Hour = convert(Int,Value) from site_parameters where parm_Id = 14   --Site Parameter EndOfDayHour
  	  If @Hour Is Null Set @Hour = 0
  	  SELECT @Minute = convert(Int,Value) from Dept_Parameters  where parm_Id = 15 and Dept_Id = @Deptid
  	  IF @Minute Is Null
  	    	  SELECT @Minute = convert(Int,Value) from site_parameters where parm_Id = 15   --Site Parameter EndOfDayMinute
  	  If @Minute Is Null Set @Minute = 0
  	  
  	  If @Hour < 0 Select @Hour = 24 + @Hour
  	  If @Hour < 0 Select @Hour = 0
  	  If @Hour > 23 Select @Hour = 0
  	  If @Minute < 0 Select @Minute = 60 + @Minute
  	  If @Minute < 0 Select @Minute = 0
  	  If @Minute > 59 Select @Minute = 0
  	  Select @TempTime = DateAdd(hour,Convert(int,@Hour),@TempTime)
  	  Select @TempTime = DateAdd(Minute,Convert(int,@Minute),@TempTime)
  	  IF @TempTime > @LocalNow
  	    	  SELECT @TempTime = DateAdd(Day,-1,@TempTime)
  	  SELECT @TempTime = dbo.fnServer_CmnConvertTime (@TempTime , @LocalTimeZoneName,'UTC') 
 	 IF @TimeSelection IN (3,4,5)
 	 BEGIN
 	  	 SELECT 	 @EndOfWeekDay = 6, @TempString = NULL
 	  	 SELECT 	 @TempString = Value FROM dbo.Site_Parameters WHERE Parm_Id = 301
 	  	 IF 	 IsNumeric(@TempString) = 1
 	  	  	 SELECT 	 @EndOfWeekDay = Convert(Int, @TempString)
 	  	 IF 	 @EndOfWeekDay = 7
 	  	  	 SELECT 	 @StartOfWeekDay = 1
 	  	 ELSE
 	  	  	 SELECT 	 @StartOfWeekDay = @EndOfWeekDay + 1
 	  	 SELECT 	 @OldStartOfWeekDay = @@DateFirst
 	  	 SET DATEFIRST @StartOfWeekDay
 	  	 WHILE 	 DatePart(WeekDay, @TempTime) <> 1
 	  	 BEGIN
 	  	  	 SELECT 	 @TempTime = DateAdd(Day, -1, @TempTime)
 	  	 END
 	 END
 	  
 	 IF @TimeSelection = 1  /* Current Day */
 	 BEGIN
 	  	 SET @StartTime = @TempTime
 	  	 IF @CappCurrentTime = 1  
 	  	  	 SET @EndTime =   @UTCNow
 	  	 ELSE 
 	  	  	 SET @EndTime =   DateAdd(Day, 1, @StartTime)
 	 END
 	 ELSE IF @TimeSelection = 2 /* Prev Day */
 	 BEGIN
 	  	 SELECT @StartTime = DateAdd(Day,-1,@TempTime),@EndTime = @TempTime
 	 END
 	 ELSE IF @TimeSelection = 3 /* Current Week */
 	 BEGIN
 	  	 SELECT @StartTime = @TempTime
 	  	 IF @CappCurrentTime = 1  
 	  	  	 SET @EndTime =   @UTCNow
 	  	 ELSE 
 	  	  	 SET @EndTime =   DateAdd(Day, 7, @StartTime)
 	 END
 	 ELSE IF @TimeSelection = 4 /* Prev Week */
 	 BEGIN
 	  	 SELECT @StartTime = DateAdd(Day,-7,@TempTime),@EndTime = @TempTime
 	 END
 	 ELSE IF @TimeSelection = 5 /* Next Week */
 	 BEGIN
 	  	 SELECT @StartTime = DateAdd(Day,7,@TempTime),@EndTime = DateAdd(Day,14,@TempTime)
 	 END 	 
 	 ELSE IF @TimeSelection = 6 /* Next Day */
 	 BEGIN
 	  	 SELECT @StartTime = DateAdd(Day,1,@TempTime),@EndTime = DateAdd(Day,2,@TempTime)
 	 END 	  	 
 	 ELSE IF @TimeSelection = 7 /* User Defined */
 	 BEGIN
 	  	 IF DateDiff(Day,@StartTime,@EndTime) > 30
 	  	  	 SET @StartTime = DateAdd(Day,-30,@EndTime)
 	 END 	 
 	 RETURN
END
