CREATE PROCEDURE dbo.spServer_CmnGetArrayStatOnly
@VarId int,
@ArrayStatOnly int OUTPUT
 AS
Select @ArrayStatOnly = NULL
Select @ArrayStatOnly = ArrayStatOnly From Variables_Base Where Var_Id = @VarId
If (@ArrayStatOnly Is NULL)
  Select @ArrayStatOnly = 0
