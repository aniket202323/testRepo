Create Procedure dbo.spFF_GetProductName 
@Prod_Id int,
@Prod_Code nvarchar(50) OUTPUT
AS
Select @Prod_Code = Null
Select @Prod_Code = Prod_Code From Products Where Prod_Id = @Prod_Id
Return(100)
