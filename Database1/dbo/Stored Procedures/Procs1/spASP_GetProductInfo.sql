CREATE PROCEDURE [dbo].[spASP_GetProductInfo]
  @ProductId INT
AS
SELECT Prod_Code, Prod_Desc
FROM Products
WHERE Prod_Id = @ProductId
