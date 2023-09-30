CREATE PROCEDURE dbo.spRS_GetProperties 
AS
Select PropertyId = Prop_Id, PropertyDesc = Prop_Desc
  From Product_Properties 
  Order By Prop_Desc
