CREATE PROCEDURE dbo.spServer_CmnGetTestValue
@Var_Id int,
@TimeStamp nVarChar(30),
@MU_Id int,
@Value nvarchar(50) OUTPUT
 AS
Select @Value = Result From Tests Where (Var_Id = @Var_Id) And (Result_On = @TimeStamp)
If @Value Is Null
  Select @Value = ''
