CREATE PROCEDURE dbo.spServer_OPCGetRawForward
@Var_Type int,
@Var_Key int,
@Property int,
@StartTime datetime,
@NumValues int
AS
-- Variables
if (@Var_Type = 1)
begin
  if (@Property = 2) -- Value Property
  begin
    Set RowCount @NumValues
    select     Result_On, Result, 'Good' as Quality
      from     Tests
      where    Var_Id = @Var_Key and Canceled = 0 and Result is not null and Result_On > @StartTime
      order by Result_On
    Set RowCount 0
  end
end
