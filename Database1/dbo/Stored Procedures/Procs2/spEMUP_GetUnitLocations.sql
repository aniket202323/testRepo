CREATE Procedure dbo.spEMUP_GetUnitLocations
@PU_Id int,
@User_Id int
AS
Select UL.Location_Id, PU.PL_Id, UL.PU_Id, PL.PL_Desc, PU.PU_Desc, UL.Location_Code, UL.Location_Desc, UL.Prod_Id, P.Prod_Code, P.Prod_Desc,
       UL.Maximum_Items, UL.Maximum_Dimension_X, UL.Maximum_Dimension_Y, UL.Maximum_Dimension_Z, UL.Maximum_Dimension_A, UL.Maximum_Alarm_Enabled,
       UL.Minimum_Items, UL.Minimum_Dimension_X, UL.Minimum_Dimension_Y, UL.Minimum_Dimension_Z, UL.Minimum_Dimension_A, UL.Minimum_Alarm_Enabled,
       Comment = Case When UL.Comment_Id is NULL or UL.Comment_Id = 0 Then 0 Else 1 End
From Unit_Locations UL
Join Prod_Units PU On PU.PU_Id = UL.PU_Id
Join Prod_Lines PL On PL. PL_Id = PU.PL_Id
Left Outer Join Products P On P.Prod_Id = UL.Prod_Id
Where UL.PU_Id = @PU_Id
Order By UL.Location_Id ASC
