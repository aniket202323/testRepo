CREATE  procedure [dbo].[spWO_SearchProducts]
@VariableId int = null,
@GroupId int = null,
@NameMask nVarChar(50) = null
AS
Declare @UnitId int
If @VariableId Is Not Null
 	 Select @UnitId = Case When Master_Unit Is Null Then PU_Id Else Master_Unit End
  From Prod_Units 
  Where PU_Id = (Select PU_Id From Variables Where Var_Id = @VariableId)
Select Distinct ProductId = p.Prod_Id, LongName = p.Prod_Desc, ShortName = p.Prod_Code
From products p
Left Outer Join Product_Group_Data pg On pg.Prod_Id = p.Prod_Id
Left Outer Join pu_products pup on pup.prod_id = pg.prod_id
Where (@UnitId Is Null Or pup.PU_Id = @UnitId)
And (@NameMask Is Null Or p.prod_code like '%' + @NameMask + '%')
And (@GroupId Is Null Or pg.Product_Grp_Id = @GroupId)
