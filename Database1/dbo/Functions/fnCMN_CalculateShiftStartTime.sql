CREATE FUNCTION dbo.fnCMN_CalculateShiftStartTime(
@PUId Int
) 
     RETURNS DateTime
AS 
BEGIN
 	 DECLARE @ShiftInt 	 INT,
 	  	 @ShiftOffset 	  	 INT,
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
 	 SELECT @TempTime = Start_Time From Crew_Schedule where pu_Id = @PUId and Start_Time <= @DbNow and End_Time > @DbNow 
 	 IF @TempTime Is null
 	 BEGIN
 	  	 SELECT @ShiftInt = convert(Int,Value) from Dept_Parameters  where parm_Id = 16 and Dept_Id = @Deptid
 	  	 IF @ShiftInt Is Null
 	  	  	 SELECT @ShiftInt = convert(Int,Value) from site_parameters where parm_Id = 16   --Site Parameter EndOfDayHour
 	  	 If @ShiftInt Is Null Set @ShiftInt = 0
 	  	 SELECT @ShiftOffset = convert(Int,Value) from Dept_Parameters  where parm_Id = 17 and Dept_Id = @Deptid
 	  	 IF @ShiftOffset Is Null
 	  	  	 SELECT @ShiftOffset = convert(Int,Value) from site_parameters where parm_Id = 17   --Site Parameter EndOfDayMinute
 	  	 If @ShiftOffset Is Null Set @ShiftOffset = 0
 	  	 SELECT @TempTime = DateAdd(hour,-DatePart(Hour,@LocalNow),@LocalNow)
 	  	 SELECT @TempTime = DateAdd(Minute,-DatePart(Minute,@TempTime),@TempTime)
 	  	 SELECT @TempTime = DateAdd(Second,-DatePart(Second,@TempTime),@TempTime)
 	  	 SELECT @TempTime = DateAdd(Millisecond,-DatePart(Millisecond,@TempTime),@TempTime)
 	  	 If @ShiftInt < 0 Select @ShiftInt = 0
 	  	 If @ShiftInt > 1440 Select @ShiftInt = 0
 	  	 If @ShiftOffset < 0 Select @ShiftOffset = 0
 	  	 If @ShiftOffset > 1440 Select @ShiftOffset = 0
 	  	 IF @ShiftOffset > @ShiftInt
 	  	  	 SELECT @ShiftOffset = @ShiftInt
 	  	 Select @TempTime = DateAdd(Minute,Convert(int,@ShiftOffset),@TempTime)
 	  	 IF @TempTime > @LocalNow
 	  	  	 SELECT @TempTime = DateAdd(Day,-1,@TempTime)
 	  	 IF @ShiftInt > 0
 	  	 Begin
 	  	  	 While Dateadd(minute,@ShiftInt,@TempTime) < @LocalNow
 	  	  	 Begin
 	  	  	  	 Select @TempTime = Dateadd(minute,@ShiftInt,@TempTime)
 	  	  	 End
 	  	 End
 	  	 SELECT @TempTime = dbo.fnServer_CmnConvertTime ( @TempTime ,@LocalTimeZoneName,@DbTZ)
 	 END
 	 RETURN @TempTime
END
