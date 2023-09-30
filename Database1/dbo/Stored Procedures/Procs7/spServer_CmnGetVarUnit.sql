CREATE PROCEDURE dbo.spServer_CmnGetVarUnit
@VarId int,
@PUId int OUTPUT
AS
Select @PUId = PU_Id From Variables_Base Where (Var_Id = @VarId)
