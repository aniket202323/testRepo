Create Procedure dbo.spEMEC_GetWasteTypes
@User_Id int
AS
SELECT *
FROM Waste_Event_Type
order by WET_Name
