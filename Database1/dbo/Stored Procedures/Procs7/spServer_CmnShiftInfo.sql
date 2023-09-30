CREATE PROCEDURE dbo.spServer_CmnShiftInfo
@ShiftInterval int output,
@ShiftOffset int output,
@DepartmentId int = NULL
AS
declare @Value nvarchar(500)
exec spServer_CmnGetParameter 16, NULL, NULL, @value output, @DepartmentId
Select @ShiftInterval = Convert(int,@Value)
exec spServer_CmnGetParameter 17, NULL, NULL, @value output, @DepartmentId
Select @ShiftOffset = Convert(int,@Value)
