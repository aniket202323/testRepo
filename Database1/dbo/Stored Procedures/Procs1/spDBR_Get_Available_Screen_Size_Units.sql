Create Procedure dbo.spDBR_Get_Available_Screen_Size_Units
AS
 	 select dashboard_template_size_unit_id, dashboard_template_size_unit_description from dashboard_template_size_units
 	  
