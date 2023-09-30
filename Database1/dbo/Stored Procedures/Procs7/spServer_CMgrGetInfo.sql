CREATE PROCEDURE dbo.spServer_CMgrGetInfo
@ServerName nvarchar(50) OUTPUT,
@ServerIPAddress nvarchar(50) OUTPUT,
@ServerPort int OUTPUT
 AS
Select @ServerName = Node_Name,
       @ServerIPAddress = Listener_Address,
       @ServerPort = Listener_Port
  From CXS_Service
  Where Service_Id = 3
