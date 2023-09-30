Create Procedure dbo.spFF_GetProductDesc 
@Prod_Id int,
@Prod_Desc nvarchar(50) OUTPUT
AS
Select @Prod_Desc = Null
Select @Prod_Desc = Prod_Desc From Products Where Prod_Id = @Prod_Id
Return(100)
