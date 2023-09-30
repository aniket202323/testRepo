CREATE PROCEDURE dbo.spServer_CmnClearVarReloadFlag   
@VarId int
AS
update Variables_Base set Reload_Flag=0 where var_id=@VarId
