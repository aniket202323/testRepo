Create Procedure dbo.spRSQ_GetProductsByGroup 
@GroupId int,
@PU_Id int = NULL
AS
--We Are Ignoring The Unit ID For Now.
If @GroupId Is Not Null
  Begin
    Select a.prod_id, a.prod_code 
      from Product_Group_Data B WITH (index(Product_Group_Data_By_Group))
      Join Products a On a.Prod_Id = B.Prod_Id
      Where B.product_grp_id = @GroupId  
      Order By a.Prod_Code
  End
Else
  Begin
    Select prod_id, prod_code 
      from Products 
      Where prod_id > 1
      Order By Prod_Code
  End
