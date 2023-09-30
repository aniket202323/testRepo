Create Procedure dbo.spGBAGetProductCode
 	 @ProdID int   AS
select prod_code from products WITH (index(PK___7__12)) where prod_id = @ProdId
