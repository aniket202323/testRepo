Create Procedure dbo.spEMAC_GetVariableTypes
@User_Id int
AS
Select SPC_Group_Variable_Type_Id, SPC_Group_Variable_Type_Desc 
  From SPC_Group_Variable_Types
  order by SPC_Group_Variable_Type_Desc
