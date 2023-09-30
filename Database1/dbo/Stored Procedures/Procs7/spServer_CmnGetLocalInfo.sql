CREATE PROCEDURE dbo.spServer_CmnGetLocalInfo
@ProdDayMinutes int output,
@ShiftInterval int output,
@ShiftOffset int output,
@DepartmentId int = NULL
 AS
Declare
  @ProdDayHour int,
  @ProdDayMinute int
Execute spServer_CmnEndOfDay @ProdDayHour output, @ProdDayMinute output, @DepartmentId 
Select @ProdDayMinutes = (@ProdDayHour * 60) + @ProdDayMinute
Execute spServer_CmnShiftInfo @ShiftInterval output, @ShiftOffset output, @DepartmentId 
