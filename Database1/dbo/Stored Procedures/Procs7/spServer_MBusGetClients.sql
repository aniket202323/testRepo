CREATE PROCEDURE dbo.spServer_MBusGetClients
 AS
Select a.Service_Id,b.Buffer_To_Disk,a.Service_Desc
  From CXS_Service a
  Join CXS_Leaf b on b.Service_Id = a.Service_Id
  Where a.Is_Active = 1
  Order By a.Service_Id
