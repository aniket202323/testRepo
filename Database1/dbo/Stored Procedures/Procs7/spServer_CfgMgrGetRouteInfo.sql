CREATE PROCEDURE dbo.spServer_CfgMgrGetRouteInfo
 AS
Declare @UseRabbitMQBridgeParm nVarChar(100)
Declare @UseRabbitMQBridge int
select @UseRabbitMQBridgeParm = dbo.fnServer_CmnGetParameter(197, null, null, '0', null)
BEGIN TRY
  set @UseRabbitMQBridge = Convert(int, @UseRabbitMQBridgeParm)
END TRY
BEGIN CATCH
  set @UseRabbitMQBridge = 0
END CATCH
Declare @UseKafkaBridgeParm nVarChar(100)
Declare @UseKafkaBridge int
select @UseKafkaBridgeParm = dbo.fnServer_CmnGetParameter(198, null, null, '0', null)
BEGIN TRY
  set @UseKafkaBridge = Convert(int, @UseKafkaBridgeParm)
END TRY
BEGIN CATCH
  set @UseKafkaBridge = 0
END CATCH
Declare @RouteInfo Table (Service_Id smallint, applicationname nvarchar(100), Domain nvarchar(100), Service_Desc nvarchar(100),
 	  	  	  	  	  	  	 Route_Id smallint, RouteApplicationName nvarchar(100), RouteDomain nvarchar(100), KeyMask nvarchar(500),
 	  	  	  	  	  	  	 RG_Id smallint)
Insert Into @RouteInfo (Service_Id, applicationname, Domain, Service_Desc, Route_Id, RouteApplicationName, RouteDomain, KeyMask, RG_Id)
Select 	  c.RG_Id, e.applicationname, e.Domain, e.Service_Desc, a.Route_Id, a.ApplicationName, a.Domain, a.KeyMask, c.RG_Id
  From   CXS_Route_Data a
  Join   CXS_Route_Group c on c.RG_Id = a.RG_Id
  Join   CXS_Leaf d on d.RG_Id = c.RG_Id
  Join   CXS_Service e on e.Service_Id = d.Service_Id
  Where  e.Is_Active = 1 and d.Buffer_To_Disk = 1
Update ri set ri.Service_Desc = c.RG_Desc From @RouteInfo ri Join CXS_Route_Group c on c.RG_Id = ri.RG_Id where ri.RG_Id in (20,21)
if (@UseRabbitMQBridge <> 1)
Begin
 	 Delete From @RouteInfo Where RG_Id = 20
End
if (@UseKafkaBridge <> 1)
Begin
 	 Delete From @RouteInfo Where RG_Id = 21
End
Select 	  	 Service_Id, applicationname, Domain, Service_Desc, Route_Id,
 	  	  	 RouteApplicationName as ApplicationName, RouteDomain as Domain, KeyMask
  From 	  	 @RouteInfo
  order by 	 RG_Id, Route_Id
