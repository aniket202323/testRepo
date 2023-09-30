CREATE PROCEDURE dbo.spSDK_GetConnectionId
 	 @HostName nvarchar(50),
 	 @ClientConnectionId INT OUTPUT
AS
SELECT @ClientConnectionId = MAX(Client_Connection_Id) 
 	 FROM CLIENT_CONNECTIONS 
 	 WHERE END_TIME IS NULL 
 	 AND HOSTNAME = @HostName
