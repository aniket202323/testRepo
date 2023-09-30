Create Procedure dbo.spDBR_Get_Product_Name
@product_id int
As
 	 if(@product_id = -1)
 	 begin
 	  	 select '[any product]' as prod_desc, '-1' as prod_id
 	 end
 	 else
 	 begin
 	  	 select Prod_desc, prod_id from products where prod_id = @product_id
 	 end
