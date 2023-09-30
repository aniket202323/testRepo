CREATE PROCEDURE dbo.spServer_PMgrGetServerInfo
@ServerPort int OUTPUT
 AS
Select @ServerPort = listener_port from cxs_service where service_id=15
