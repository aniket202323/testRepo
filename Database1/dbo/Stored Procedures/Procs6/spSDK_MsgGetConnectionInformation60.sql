Create procedure [dbo].[spSDK_MsgGetConnectionInformation60]
AS
Declare @ServiceName Varchar(1000)
/*
Select @ServiceName = [Value] From Site_Parameters Where Parm_Id = 3
If Len(@ServiceName) = 0 Or @ServiceName Is Null
 	 Select @ServiceName = NODE_NAME From cxs_Service Where Proficy_Service_Name = 'PRGateway'
Select 'PORT' As [Name], [Value] From Site_Parameters where Parm_Id = 6
Union Select 'SERVERNAME' As [Name], @ServiceName
*/
Select listener_address, Listener_port From cxs_Service Where Proficy_Service_Name = 'PRGateway'
