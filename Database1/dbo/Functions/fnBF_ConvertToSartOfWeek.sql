CREATE FUNCTION dbo.fnBF_ConvertToSartOfWeek(@InTime DateTime,@MoveToMonday Int,@TZ VarChar(255))
 RETURNS DATETIME AS
BEGIN
DECLARE @Hour Int,@Minute Int,@StartOfWeek Int,@DayOfWeek Int
SET @InTime = DATEADD(millisecond,-DatePART(millisecond,@InTime),@InTime)
SET @InTime = DATEADD(Second,-DatePART(Second,@InTime),@InTime)
SET @InTime = DATEADD(Minute,-DatePART(Minute,@InTime),@InTime)
SET @InTime = DATEADD(Hour,-DatePART(Hour,@InTime),@InTime)
SELECT @Hour = convert(Int,Value) FROM site_parameters where parm_Id = 14   --Site Parameter EndOfDayHour
If @Hour Is Null Set @Hour = 0
SELECT @Minute = convert(Int,Value) FROM site_parameters where parm_Id = 15   --Site Parameter EndOfDayMinute
If @Minute Is Null Set @Minute = 0
IF @MoveToMonday = 1
BEGIN
 	 SET @StartOfWeek = 1
 	 SET @DayOfWeek = datepart(WEEKDAY ,@InTime)
 	 WHILE @StartOfWeek <> @DayOfWeek
 	 BEGIN
 	  	 SET  @InTime = DateAdd(day,-1 ,@InTime)
 	  	 SET @DayOfWeek = datepart(WEEKDAY,@InTime)
 	 END
END
SET @InTime = DATEADD(Hour,@Hour,@InTime)
SET @InTime = DATEADD(MINUTE,@minute,@InTime)
SELECT @InTime = dbo.fnServer_CmnConvertToDbTime(@InTime,@TZ)
return @InTime 
END
