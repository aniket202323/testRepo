Create Procedure dbo.spGE_GetDefectTypes
 AS
Select Defect_Name,Defect_Type_Id 
  From Defect_Types
  Order By Defect_Name
