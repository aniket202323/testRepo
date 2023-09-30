Create Procedure dbo.spFF_GetProductInfo 
@Prod_Id int,
@Prod_Desc  	 nvarchar(50) OUTPUT,
@ProdCode 	  	 nvarchar(25) OUTPUT
AS
Select @Prod_Desc = Null
Select @ProdCode = Null
Select @Prod_Desc = Prod_Desc,@ProdCode = Prod_Code From Products Where Prod_Id = @Prod_Id
Return(100)
