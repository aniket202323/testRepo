CREATE PROCEDURE dbo.spServer_CmnGetVarReloadFlags   
AS
select var_id from variables_Base where Reload_Flag is not NULL and Reload_Flag <> 0
