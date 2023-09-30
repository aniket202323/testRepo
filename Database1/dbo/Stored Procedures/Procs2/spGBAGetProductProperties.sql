Create Procedure dbo.spGBAGetProductProperties @ID integer = 0
 AS
 if @ID = 0
   select prop_id, prop_desc from product_properties
 else
   select prop_desc from product_properties where prop_id = @ID
