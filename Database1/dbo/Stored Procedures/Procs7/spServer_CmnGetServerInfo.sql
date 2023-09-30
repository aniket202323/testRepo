CREATE PROCEDURE dbo.spServer_CmnGetServerInfo
@ServiceName nVarChar(50),
@ServiceId int OUTPUT,
@ServerName nvarchar(50) OUTPUT,
@ServerIPAddress nvarchar(50) OUTPUT,
@ServerPort int OUTPUT,
@LookupServerName nvarchar(50) = NULL
 AS
Select @ServerName = Node_Name,
       @ServerIPAddress = Listener_Address,
       @ServerPort = Listener_Port
  From CXS_Service 
  Where Service_Id = 9
if @LookupServerName is null or @LookupServerName = ''
begin
 	 Select @ServiceId = NULL
 	 Select @ServiceId = Service_Id From CXS_Service Where Service_Desc = @ServiceName
 	 If (@ServiceId Is NULL)
 	   Select @ServiceId = 0
end
else
begin
 	 Select @ServiceId = NULL
 	 Select @ServiceId = Service_Id From CXS_Service Where Service_Desc = @ServiceName and Node_Name = @LookupServerName
 	 If (@ServiceId Is NULL)
 	   Select @ServiceId = 0
end
