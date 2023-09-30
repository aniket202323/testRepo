CREATE FUNCTION [dbo].[fnBF_calCalculateEndSchedule] (@startTime datetime, @startShift datetime, @duration integer, @ClientUTCOffset int) RETURNS DATETIME AS
BEGIN
       -- Declare the return variable here
 	 DECLARE @Result datetime
 	 DECLARE @start datetime
 	 DECLARE @workDate datetime
 	 Declare @from_Time datetime, @To_Time datetime, @DSTOffset int
 	 declare @DepartmentTimeZone nvarchar(255)
 	 Select @DepartmentTimeZone = min(Time_Zone) from Departments
 	 Select @DepartmentTimeZone = isnull(@DepartmentTimeZone,'UTC')
 	 SELECT @from_Time = dbo.fnBF_ConvertToSartOfWeek(@startShift,0,@DepartmentTimeZone)
 	 SELECT @To_Time = dbo.fnBF_ConvertToSartOfWeek(@starttime,0,@DepartmentTimeZone)
 	 SET @DSTOffset = DATEPart(hour,@To_Time) - DATEPart(hour,@from_Time)
 	 SET @Start =dbo.fnBF_calDateTimeFromParts(DATEPART(year,@startTime),DATEPART(month,@startTime),DATEPART(day,@startTime),DATEPART(hour,@startShift),DATEPART(minute,@startShift),DATEPART(second,@startShift),0)
 	 Select @Start = DateAdd(Hour,@DSTOffset,@Start)
    --if converting the Shift start time to the local time changes the day to be before the day of the shift, add 1 to the day    
 	 select @workDate = dateadd(minute, -@ClientUTCOffset, @Start)
    if (DATEPART(day, @workDate) < DATEPART(day, @Start)) or (DATEPART(month, @workDate) < DATEPART(month, @Start))
      Begin
        select @Start = DATEADD(day, 1, @Start)
      End
 	 SET @Result = dateadd(hour, @duration, @start);
 	 RETURN @Result
END
