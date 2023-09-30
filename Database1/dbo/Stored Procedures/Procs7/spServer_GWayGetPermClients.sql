CREATE PROCEDURE dbo.spServer_GWayGetPermClients 
AS
select name from GWay_Permanent_Clients where is_active = 1
