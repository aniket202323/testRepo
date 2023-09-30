CREATE PROCEDURE dbo.spServer_CmnGetLastTestValue
@Var_Id int,
@MU_Id int,
@Value nvarchar(50) OUTPUT,
@ResultOn nVarChar(30) OUTPUT
 AS
select @Value=Result, @ResultOn=Result_On from tests where var_id=@var_id and (result_on = (select max(result_on) from tests where (var_id = @var_id) and (result is not null)))
If @Value Is Null
  Select @Value = ''
