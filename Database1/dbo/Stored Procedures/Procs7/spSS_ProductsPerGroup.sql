Create Procedure dbo.spSS_ProductsPerGroup
 @GroupId Int
AS
 Declare @TimeStamp datetime
 Declare @PUId int
 If (@GroupId Is Null) or (@GroupId = 0)
  Select p.prod_id, p.prod_code , p.Prod_Desc
   From Products  p 
    Order By p.Prod_Code
 Else
  Select p.prod_id, p.prod_code , p.Prod_Desc
   From Product_Groups N Inner Join Product_Group_data G on N.Product_Grp_Id = G.Product_Grp_Id
                         Inner Join Products  p on p.Prod_Id = G.Prod_Id
    Where N.Product_Grp_Desc = @GroupId
     Order By p.Prod_Code
