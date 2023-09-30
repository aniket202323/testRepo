CREATE  procedure [dbo].[spWO_SearchProductsByVariables]
@VariableIds Varchar(8000) = null,
@GroupId int = null,
@NameMask nVarChar(50) = null
AS 
Create Table #Variables([Order] int, Var_Id int)
Create Table #Units(PU_Id int)
Declare @UnitId int
If @VariableIds Is Not Null
Begin
 	 Insert Into #Variables([Order], Var_Id) Exec spRS_MakeOrderedResultSet @VariableIds
 	 Insert Into #Units
 	 Select 
 	  	 Case When Master_Unit Is Null Then PU_Id Else Master_Unit End
 	 From Prod_Units 
 	 Where PU_Id in (Select PU_Id From Variables Where Var_Id In (Select Var_Id From #Variables))
-- Changed the old query (below) to above matching existing spWO_SearchProducts
-- 	 Select Distinct(v.PU_Id)
-- 	 From Variables v
-- 	 Join Prod_Units pu On pu.PU_Id = v.PU_Id
-- 	 Where v.Var_Id In (Select Var_Id From #Variables)
End
Select Distinct ProductId = p.Prod_Id, LongName = p.Prod_Desc, ShortName = p.Prod_Code
From products p
Left Outer Join Product_Group_Data pg On pg.Prod_Id = p.Prod_Id
Left Outer Join pu_products pup on pup.prod_id = p.prod_id
Where (@VariableIds Is Null Or pup.PU_Id In (Select PU_Id From #Units) )
And (@NameMask Is Null Or p.prod_code like '%' + @NameMask + '%')
And (@GroupId Is Null Or pg.Product_Grp_Id = @GroupId)
--spWO_SearchProductsByVariables '10', NULL, NULL
Drop Table #Variables
Drop Table #Units
