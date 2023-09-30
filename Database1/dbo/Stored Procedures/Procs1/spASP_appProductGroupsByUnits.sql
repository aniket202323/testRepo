CREATE procedure [dbo].[spASP_appProductGroupsByUnits]
@Units nVarChar(1000)
AS
/***************************
--For Testing
--***************************
Select @Units = '2'
--***************************/
Create Table #Units (
  ItemOrder int,
  Item int 
)
Insert Into #Units (Item, ItemOrder)
  execute ('Select Distinct PU_Id, ItemOrder = CharIndex(convert(nvarchar(10),PU_Id),' + '''' + @Units + ''''+ ',1)  From Prod_Units Where PU_Id in (' + @Units + ')' + ' and pu_id <> 0')
Select Distinct Id = pg.Product_Grp_Id, Description = pg.Product_Grp_Desc
  From Product_Groups pg
  Join Product_Group_Data pgd on pgd.Product_Grp_id = pg.Product_Grp_Id
  Join pu_products pup on pup.prod_id = pgd.prod_id 
  Join #Units u on u.Item = pup.pu_id
  Order By pg.Product_Grp_Desc
Drop Table #Units
