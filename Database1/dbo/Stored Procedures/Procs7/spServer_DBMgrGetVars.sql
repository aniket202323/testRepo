CREATE PROCEDURE dbo.spServer_DBMgrGetVars
AS
select var_id from Variables_Base order by var_id
