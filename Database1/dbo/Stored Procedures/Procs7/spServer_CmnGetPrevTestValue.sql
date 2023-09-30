CREATE PROCEDURE dbo.spServer_CmnGetPrevTestValue
@Var_Id int,
@RefTimeStamp nVarChar(30),
@MUId int,
@Value nvarchar(50) OUTPUT,
@ValueTimeStamp nVarChar(30) OUTPUT
 AS
Select @valueTimeStamp = max(Result_On) From Tests Where (Var_Id = @Var_Id) And (Result_On < @RefTimeStamp)
Select @Value = Result From Tests Where (Var_Id = @Var_Id) And (Result_On < @ValueTimeStamp)
If @Value Is Null
begin
  Select @Value = ''
  select @ValueTimeStamp = ''
end
