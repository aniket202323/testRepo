Create Procedure dbo.spDBR_Update_Template_Dashboard_Detail_Link
@dashboard_template_id int,
@dashboard_template_detail_link varchar(500)
AS
 	 if (@dashboard_template_detail_link = '')
 	 begin
 	  	 update dashboard_templates set dashboard_template_detail_link = null
 	  	  	  	  	  	  	  	  	 where dashboard_template_id = @dashboard_template_id
 	 end
 	 else
 	 begin
 	  	 update dashboard_templates set dashboard_template_detail_link = @dashboard_template_detail_link
 	  	  	  	  	  	  	  	  	 where dashboard_template_id = @dashboard_template_id
 	 end
 	 
 	   
