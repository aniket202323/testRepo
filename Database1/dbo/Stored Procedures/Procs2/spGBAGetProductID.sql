Create Procedure dbo.spGBAGetProductID
 	 @ProdCode nvarchar(20)   AS
select prod_id from products WITH (index(Products_By_Code)) where prod_code = @ProdCode
