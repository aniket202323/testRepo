Create Procedure dbo.spEMCSC_GetCrewDescs 
@User_Id int
AS
Select Distinct Crew_Desc
From Crew_Schedule
Order By Crew_Desc ASC
Select Distinct Shift_Desc
From Crew_Schedule
Order By Shift_Desc ASC
