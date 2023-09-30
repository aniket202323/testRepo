CREATE PROCEDURE dbo.spServer_CmnGetLocalInfoByUnit
@MasterUnit int,
@ShiftInterval int OUTPUT,
@ShiftOffset int OUTPUT,
@ProdDayMinutes int OUTPUT
AS
Declare
  @StartTime datetime,
  @EndTime datetime,
  @QueryTime datetime,
  @Value nVarChar(50),
 	 @DeptId int
Select @ShiftInterval = NULL
Select @ShiftOffset = NULL
Select @ProdDayMinutes = NULL
Select @Value = NULL
Select @Value = Value From Site_Parameters Where Parm_Id = 141
If (@Value Is Not NULL)
  If (@Value <> '1')
    Begin
 	  	  	 select @DeptId = dbo.fnServer_GetDepartment(@MasterUnit)
      Execute spServer_CmnGetLocalInfo @ProdDayMinutes output, @ShiftInterval output, @ShiftOffset output, @DeptId
      Return
    End
Select @QueryTime = dbo.fnServer_CmnGetDate(GetUTCDate())
Select @QueryTime = DateAdd(MilliSecond,-DatePart(MilliSecond,@QueryTime),@QueryTime)
Select @QueryTime = DateAdd(Second,-DatePart(Second,@QueryTime),@QueryTime)
Select @QueryTime = DateAdd(Minute,-DatePart(Minute,@QueryTime),@QueryTime)
Select @QueryTime = DateAdd(Hour,-DatePart(Hour,@QueryTime),@QueryTime)
Select @StartTime = NULL
Select @EndTime = NULL
Select @StartTime = Min(Start_Time)
  From Crew_Schedule
  Where (PU_Id = @MasterUnit) And
        (Start_Time > @QueryTime)
If (@StartTime Is not NULL)
begin
 	 Select @EndTime = End_Time
 	   From Crew_Schedule
 	   Where (PU_Id = @MasterUnit) And
 	         (Start_Time = @StartTime)
 	 
 	 If (@EndTime Is not NULL)
 	 begin
 	  	 Select @ShiftInterval = (DatePart(Hour,@EndTime) * 60 + DatePart(Minute,@EndTime)) - (DatePart(Hour,@StartTime) * 60 + DatePart(Minute,@StartTime))
 	  	 Select @ShiftOffset = DatePart(Hour,@StartTime) * 60 + DatePart(Minute,@StartTime)
 	  	 Select @ProdDayMinutes = DatePart(Hour,@StartTime) * 60 + DatePart(Minute,@StartTime)
 	  	 return
 	 end
end
select @DeptId = dbo.fnServer_GetDepartment(@MasterUnit)
Execute spServer_CmnGetLocalInfo @ProdDayMinutes output, @ShiftInterval output, @ShiftOffset output, @DeptId
