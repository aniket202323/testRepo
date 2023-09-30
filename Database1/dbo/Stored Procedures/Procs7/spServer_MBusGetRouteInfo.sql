CREATE PROCEDURE dbo.spServer_MBusGetRouteInfo
 AS
Select ServiceId = e.Service_Id, RouteId = a.Route_Id, RouteDesc = b.Route_Desc
  From CXS_Route_Data a
  Join CXS_Route b on b.Route_Id = a.Route_Id
  Join CXS_Route_Group c on c.RG_Id = a.RG_Id
  Join CXS_Leaf d on d.RG_Id = c.RG_Id
  Join CXS_Service e on e.Service_Id = d.Service_Id
