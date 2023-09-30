CREATE PROCEDURE dbo.spServer_GWayGetInfo
@ServerName nvarchar(50) OUTPUT,
@ServerIPAddress nvarchar(50) OUTPUT,
@ServerPort int OUTPUT
 AS
--
-- WARNING: This SP is used by PA OPC Server, any changes must also be reflected there. (MP 7/7/08)
--
Select @ServerName = node_name,  @ServerIPAddress = listener_address,  @ServerPort = listener_port from cxs_service where service_id=14
