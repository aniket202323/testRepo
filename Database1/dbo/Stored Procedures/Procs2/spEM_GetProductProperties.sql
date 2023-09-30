CREATE PROCEDURE dbo.spEM_GetProductProperties
  @Product_Id               int
  AS
Select Event_Esignature_Level = Coalesce(Event_Esignature_Level,0),Product_Change_Esignature_Level = coalesce(Product_Change_Esignature_Level,0)
 	  From products
 	  Where Prod_Id = @Product_Id
