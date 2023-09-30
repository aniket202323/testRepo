Create Procedure dbo.spXLAGetProductCode
 	 @ProdID int  AS
select prod_code from products  where prod_id = @ProdId
