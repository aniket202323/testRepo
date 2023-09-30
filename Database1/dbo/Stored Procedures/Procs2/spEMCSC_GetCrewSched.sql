Create Procedure dbo.spEMCSC_GetCrewSched 
@PU_Id int,
@Start_Time datetime,
@End_Time datetime,
@User_Id int
AS
Select PU_Desc, Case When CS.Comment_Id Is Not Null Then 1 Else 0 End as Comment, Start_Time, End_Time, PU_Desc, Crew_Desc, Shift_Desc, CS.Comment_Id, CS_Id
From Crew_Schedule CS
Join Prod_Units PU on PU.PU_Id = CS.PU_Id
Where CS.PU_Id = @PU_Id
And Start_Time >= @Start_Time 
And End_Time <= @End_Time
Order By Start_Time DESC
