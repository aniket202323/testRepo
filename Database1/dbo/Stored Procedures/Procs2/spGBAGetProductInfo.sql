Create Procedure dbo.spGBAGetProductInfo
 	 @ProdID int,
 	 @ProdCode nvarchar(20)   AS
if @ProdCode is Not null 
  select * from products WITH (index(Products_By_Code)) where prod_code = @ProdCode
else if @ProdID is Not null 
  select * from products WITH (index(PK___7__12)) where prod_id = @ProdId 
else
  select * from products where prod_id <> 1 order by prod_code
