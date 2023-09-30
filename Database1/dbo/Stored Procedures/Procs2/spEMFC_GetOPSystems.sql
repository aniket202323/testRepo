Create Procedure dbo.spEMFC_GetOPSystems
@User_Id int
AS
select * from Operating_Systems
order by OS_Id
