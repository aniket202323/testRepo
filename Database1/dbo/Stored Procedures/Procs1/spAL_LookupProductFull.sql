Create Procedure dbo.spAL_LookupProductFull
@Id int
AS
  Select start_id = 1, pu_id = null, start_time = '1/1/1970', end_time = null, prod_id, prod_code, prod_desc, comment_id,  external_link, Event_Esignature_Level = Coalesce(Event_Esignature_Level, 0), Product_Change_Esignature_Level = Coalesce(Product_Change_Esignature_Level, 0)
    from products 
    where (prod_id = @ID)
