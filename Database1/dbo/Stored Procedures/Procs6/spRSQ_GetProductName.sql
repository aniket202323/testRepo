Create Procedure dbo.spRSQ_GetProductName 
@Prod_Id int,
@Prod_Code nVarChar(50) OUTPUT
 AS
Select @Prod_Code = Null
select @Prod_Code = prod_code from products where prod_id = @Prod_Id
