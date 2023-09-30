CREATE PROCEDURE dbo.spServer_MBusGetBufRouteIds
 AS
SELECT Route_Id from cxs_route where Should_Buffer = 1 or Should_Buffer is NULL
