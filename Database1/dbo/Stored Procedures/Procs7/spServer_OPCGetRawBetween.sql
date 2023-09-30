CREATE PROCEDURE dbo.spServer_OPCGetRawBetween
@Var_Type int,
@Var_Key int,
@Property int,
@StartTime datetime,
@EndTime datetime
AS
-- Variables
if (@Var_Type = 1)
begin
  if (@Property = 2) -- Value Property
  begin
    select     Result_On, Result, 'Good' as Quality
      from     Tests
      where    Var_Id = @Var_Key and Canceled = 0 and Result is not null and Result_On > @StartTime and Result_On < @EndTime
      order by Result_On
  end
end
