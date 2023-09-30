Create Procedure dbo.spDBR_Get_Report_Size
@reportid int
AS 	 
 	 declare @templateid int
 	 declare @fixed_height bit
 	 declare @fixed_width bit
 	 declare @height int, @width int
 	 declare @unit varchar(50)
 	 
 	 set @height=0
 	 set @width=0
 	 set @templateid = (select dashboard_template_id from dashboard_reports where dashboard_report_id = @reportid)
 	 set @fixed_height = (select dashboard_template_fixed_height from dashboard_templates where  dashboard_template_id = @templateid)
 	 set @fixed_width = (select dashboard_template_fixed_width from dashboard_templates where  dashboard_template_id = @templateid)
 	 
 	 if (@fixed_height = 1)
 	 begin 	 
 	  	 set @height = (select height 	 from dashboard_templates 
 	  	  	  	  	  	 where  dashboard_template_id = @templateid)
 	  	 set @unit =  (select dashboard_template_size_unit_description 	 from dashboard_templates t, dashboard_template_size_units s
 	  	  	  	  	  	 where  t.dashboard_template_id = @templateid and t.dashboard_template_size_unit = s.dashboard_template_size_unit_id)
 	 end
 	 if (@fixed_width = 1)
 	 begin 	 
 	  	 set @width = (select width 	 from dashboard_templates 
 	  	  	  	  	  	 where  dashboard_template_id = @templateid) 
 	  	 set @unit =  (select dashboard_template_size_unit_description 	 from dashboard_templates t, dashboard_template_size_units s
 	  	  	  	  	  	 where  t.dashboard_template_id = @templateid and t.dashboard_template_size_unit = s.dashboard_template_size_unit_id)
 	 end
 	 
 	 select @fixed_height as fixed_height, @fixed_width as fixed_width, @height as height, @width as width, @unit as unit
