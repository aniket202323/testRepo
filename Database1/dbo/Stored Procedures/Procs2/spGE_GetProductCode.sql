CREATE Procedure dbo.spGE_GetProductCode
 	  	  	 @Prod_Id 	  	 Int,
 	  	  	 @ProdCode 	  	 nvarchar(25) 	 Output
AS
Select @ProdCode = Prod_Code From Products where Prod_Id = @Prod_Id
