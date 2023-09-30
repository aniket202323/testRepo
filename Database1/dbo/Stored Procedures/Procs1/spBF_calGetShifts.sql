CREATE PROCEDURE dbo.spBF_calGetShifts
@ClientUTCOffset int = 0
AS
BEGIN
 	 -- SET NOCOUNT ON added to prevent extra result sets from
 	 -- interfering with SELECT statements.
 	 SET NOCOUNT ON;
 	 declare @CurrentTime datetime
 	 declare @DepartmentTimeZone nvarchar(255)
 	 declare @CurrentOffset int
 	 select @CurrentTime = GETUTCDATE()
 	 SET @CurrentTime = DATEADD(millisecond,-DatePART(millisecond,@CurrentTime),@CurrentTime)
 	 SET @CurrentTime = DATEADD(Second,-DatePART(Second,@CurrentTime),@CurrentTime)
 	 SET @CurrentTime = DATEADD(Minute,-DatePART(Minute,@CurrentTime),@CurrentTime)
 	 SET @CurrentTime = DATEADD(Hour,-DatePART(Hour,@CurrentTime),@CurrentTime)
 	 Select @DepartmentTimeZone = min(Time_Zone) from Departments
 	 Select @DepartmentTimeZone = isnull(@DepartmentTimeZone,'UTC')
 	 select @CurrentOffset = UTCBias from TimeZoneTranslations where TimeZone = @DepartmentTimeZone and (@CurrentTime between UTCStartTime and UTCEndTime)
 	 SELECT id,name,description, DateAdd(minute, @CurrentOffset - Coalesce(UTCOffset,0),DateAdd(minute, DatePart(hour, Start_Time) * 60, @CurrentTime))  as 'start_time', 
 	  	 DateAdd(minute, @CurrentOffset - Coalesce(UTCOffset,0),DateAdd(minute, DatePart(hour, End_Time) * 60, @CurrentTime))  as 'end_time',duration from Shifts where IsDeleted = 0 order by name ;
END
