Create Procedure dbo.spXLAGetProductGroupID
@Desc varchar(50)
AS 
  Select * From Product_Groups where product_grp_desc = @Desc
