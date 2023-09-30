Create Procedure dbo.spEMEV_GetLocations
@ECId int,
@User_Id int = 1
AS
Declare @Insert_Id int
Select PU_Desc as Location from Prod_Units p
  Join Event_Configuration c on c.pu_Id = p.pu_Id and c.EC_Id = @ECId
