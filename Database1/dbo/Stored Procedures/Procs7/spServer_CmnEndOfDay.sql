CREATE PROCEDURE dbo.spServer_CmnEndOfDay
@EndOfDayHour int output,
@EndOfDayMinute int output,
@DepartmentId int = NULL
AS
declare @Value nvarchar(500)
exec spServer_CmnGetParameter 14, NULL, NULL, @value output, @DepartmentId
Select @EndOfDayHour = Convert(int,@Value)
exec spServer_CmnGetParameter 15, NULL, NULL, @value output, @DepartmentId
Select @EndOfDayMinute = Convert(int,@Value)
