Create Procedure dbo.spDBR_Get_Product_Description
@product_id int,
@product_display_code int
as
 	 
 	 if (@product_id = -1)
 	 begin
 	  	 insert into #sp_name_results select '[any product]'
 	 end
 	 else
 	 begin
 	  	 if(@product_display_code=0)
 	  	 begin
 	  	  	 insert into #sp_name_results select Prod_desc from products where prod_id = @product_id
 	  	 end
 	  	 else
 	  	 begin
 	  	  	 insert into #sp_name_results select Prod_code from products where prod_id = @product_id
 	  	 end
 	 end
 	 
