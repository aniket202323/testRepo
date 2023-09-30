Create Procedure dbo.spDBR_Finish_Import
AS
 	 /********************
 	 Clean up templates table--[UNPROCESSED TEMPLATE IMPORT]'s set to 'None'
 	 **********************/
 	 update Dashboard_Templates set dashboard_template_preview_filename = 'None' 
 	 where dashboard_template_preview_filename like '%UNPROCESSED TEMPLATE IMPORT%'
