CREATE PROCEDURE dbo.spCSS_GetAddInConnections 
@HostName nvarchar(25)
AS
Select Count(cc.Client_Connection_Id) from Client_Connections cc
  Join Client_Connection_App_Data ccad on ccad.Client_Connection_Id = cc.Client_Connection_Id
  where cc.end_time is Null and cc.HostName = @HostName and App_Id = 4
