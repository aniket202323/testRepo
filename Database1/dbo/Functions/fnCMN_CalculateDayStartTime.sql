CREATE FUNCTION dbo.fnCMN_CalculateDayStartTime(
@PUId Int
) 
     RETURNS DateTime
AS 
BEGIN
 	 DECLARE @Hour 	 INT,
 	  	 @Minute 	  	 INT,
 	  	 @DbTZ 	  	 nvarchar(200),
 	  	 @DbNow 	  	 DateTime,
 	  	 @LocalNow 	 DateTime,
 	  	 @UTCNow 	  	 DateTime,
 	  	 @TempTime 	 DateTime,
 	  	 @LocalTimeZoneName nvarchar(200),
 	  	 @Deptid 	  	 Int
 	 
 	 SELECT @Deptid = dbo.fnServer_GetDepartment(@PUId)
 	 SELECT @LocalTimeZoneName = dbo.fnServer_GetTimeZone(@PUId)
 	 SELECT @DbTZ=value from site_parameters where parm_id=192
 	 IF @LocalTimeZoneName Is Null
 	  	 SELECT @LocalTimeZoneName = @DbTZ
 	 SELECT @UTCNow = Getutcdate()
 	 SELECT @DbNow = dbo.fnServer_CmnGetdate(@UTCNow)
 	 SELECT @LocalNow =  dbo.fnServer_CmnConvertTime (@DbNow,@DbTZ,@LocalTimeZoneName)
 	 SELECT @Hour = convert(Int,Value) from Dept_Parameters  where parm_Id = 14 and Dept_Id = @Deptid
 	 IF @Hour Is Null
 	  	 SELECT @Hour = convert(Int,Value) from site_parameters where parm_Id = 14   --Site Parameter EndOfDayHour
 	 If @Hour Is Null Set @Hour = 0
 	 SELECT @Minute = convert(Int,Value) from Dept_Parameters  where parm_Id = 15 and Dept_Id = @Deptid
 	 IF @Minute Is Null
 	  	 SELECT @Minute = convert(Int,Value) from site_parameters where parm_Id = 15   --Site Parameter EndOfDayMinute
 	 If @Minute Is Null Set @Minute = 0
 	 SELECT @TempTime = DateAdd(hour,-DatePart(Hour,@LocalNow),@LocalNow)
 	 SELECT @TempTime = DateAdd(Minute,-DatePart(Minute,@TempTime),@TempTime)
 	 SELECT @TempTime = DateAdd(Second,-DatePart(Second,@TempTime),@TempTime)
 	 SELECT @TempTime = DateAdd(Millisecond,-DatePart(Millisecond,@TempTime),@TempTime)
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
 	 SELECT @TempTime = dbo.fnServer_CmnConvertTime ( @TempTime , @LocalTimeZoneName,@DbTZ) 	 
 	 RETURN @TempTime
END
