CREATE procedure [dbo].[spASP_appProductsByUnits]
--declare 
@Units nvarchar(1000),
@GroupId int,
@SearchString nVarChar(50)
AS
/***************************
--For Testing
--***************************
Select @Units = '2'
Select @GroupId = null 
Select @SearchString = null
--***************************/
Create Table #Units (
  ItemOrder int,
  Item int 
)
Insert Into #Units (Item, ItemOrder)
  execute ('Select Distinct PU_Id, ItemOrder = CharIndex(convert(nvarchar(10),PU_Id),' + '''' + @Units + ''''+ ',1)  From Prod_Units Where PU_Id in (' + @Units + ')' + ' and pu_id <> 0')
If @GroupId Is Not Null
  Begin
    If @SearchString Is Null
      Begin
 	  	  	  	 Select Distinct Id = p.Prod_Id, Description = p.Prod_Code + ' - ' + p.Prod_Desc
 	  	  	  	   From Product_Group_Data pgd  
 	  	  	  	   Join Product_Groups pg on pg.Product_Grp_id = pgd.Product_Grp_Id 
 	  	  	  	   Join pu_products pup on pup.prod_id = pgd.prod_id 
 	  	  	  	   Join #Units u on u.Item = pup.pu_id
 	  	  	  	   Join Products p on p.prod_id = pgd.prod_id
 	  	  	  	   Where pgd.Product_Grp_Id = @GroupId
 	  	  	  	   Order By Description
      End
    Else
      Begin
 	  	  	  	 Select Distinct Id = p.Prod_Id, Description = p.Prod_Code + ' - ' + p.Prod_Desc
 	  	  	  	   From Product_Group_Data pgd  
 	  	  	  	   Join Product_Groups pg on pg.Product_Grp_id = pgd.Product_Grp_Id 
 	  	  	  	   Join pu_products pup on pup.prod_id = pgd.prod_id 
 	  	  	  	   Join #Units u on u.Item = pup.pu_id
 	  	  	  	   Join Products p on p.prod_id = pgd.prod_id and ((p.Prod_Code like '%' + @SearchString + '%') or (p.Prod_Desc like '%' + @SearchString + '%'))  
 	  	  	  	   Where pgd.Product_Grp_Id = @GroupId
 	  	  	  	   Order By Description
      End
  End
Else
  Begin
    If @SearchString Is Null
      Begin
 	  	  	  	 Select Distinct Id = p.Prod_Id, Description = p.Prod_Code + ' - ' + p.Prod_Desc
 	  	       From Products p 
 	  	  	  	   Join pu_products pup on pup.prod_id = p.prod_id 
 	  	  	  	   Join #Units u on u.Item = pup.pu_id
 	  	  	  	   Order By Description
      End
    Else
      Begin
 	  	  	  	 Select Distinct Id = p.Prod_Id, Description = p.Prod_Code + ' - ' + p.Prod_Desc
 	  	       From Products p 
 	  	  	  	   Join pu_products pup on pup.prod_id = p.prod_id 
 	  	  	  	   Join #Units u on u.Item = pup.pu_id
          Where ((p.Prod_Code like '%' + @SearchString + '%') or (p.Prod_Desc like '%' + @SearchString + '%'))  
 	  	  	  	   Order By Description
      End
  End
Drop Table #Units
