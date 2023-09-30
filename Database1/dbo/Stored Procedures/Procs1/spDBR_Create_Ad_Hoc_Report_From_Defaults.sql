Create Procedure dbo.spDBR_Create_Ad_Hoc_Report_From_Defaults
@templateid int
AS
 	 declare @reportid int
 	 declare @reportname varchar(100)
 	 declare @server varchar(100), @galleryserver varchar(100)
 	 declare @templatedesc varchar(4000)
 	 declare @column int
 	 declare @columnposition int
 	 declare @hasframe int
 	 declare @expanded int
 	 declare @allowremove int
 	 declare @allowminimize int
 	 declare @cachecode int
 	 declare @cachetimeout int
 	 declare @detaillink varchar(500)
 	 declare @helplink varchar(500)
 	 
 	 set @reportname = (select case when isnumeric(dashboard_template_name) = 1 then (dbo.fnDBTranslate(N'0', dashboard_template_name, dashboard_template_name)) 
 	  	  	  	  	 else (dashboard_template_name)
 	  	  	  	  	 end as dashboard_template_name
 	  	   	  	 from dashboard_templates where dashboard_template_id = @templateid)
 	 set @server =(select dashboard_report_server from dashboard_Reports where dashboard_Report_id = (select min(dashboard_report_id) from dashboard_reports))
 	 set @galleryserver = (select min (server) from dashboard_gallery_Generator_servers)
 	 set @server =IsNULL(@server, @galleryserver)
 	 set @server = IsNULL(@server, (select @@servername))
 	 set @column = (select dashboard_template_column from dashboard_templates where dashboard_template_id = @templateid)
 	 set @columnposition = (select dashboard_template_column_position from dashboard_templates where dashboard_template_id = @templateid)
 	 set @hasframe = (select dashboard_template_has_frame from dashboard_templates where dashboard_template_id = @templateid)
 	 set @expanded = (select dashboard_template_expanded from dashboard_templates where dashboard_template_id = @templateid)
 	 set @allowremove = (select dashboard_template_allow_remove from dashboard_templates where dashboard_template_id = @templateid)
 	 set @allowminimize = (select dashboard_template_allow_minimize from dashboard_templates where dashboard_template_id = @templateid)
 	 set @cachecode = (select dashboard_template_cache_code from dashboard_templates where dashboard_template_id = @templateid)
 	 set @cachetimeout = (select dashboard_template_cache_timeout from dashboard_templates where dashboard_template_id = @templateid)
 	 set @detaillink = (select dashboard_template_detail_link from dashboard_templates where dashboard_template_id = @templateid)
 	 set @helplink = (select dashboard_template_help_link from dashboard_templates where dashboard_template_id = @templateid)
 	 set @templatedesc = (select dashboard_template_description from dashboard_Templates where dashboard_template_id = @templateid)
 	 insert into Dashboard_Reports (Dashboard_Report_Name, Dashboard_Template_ID, Dashboard_Report_Version_Count, Dashboard_Report_Ad_Hoc_Flag, Dashboard_Report_Server, Dashboard_Report_Number_Hits, Dashboard_Report_Create_Date, Dashboard_Report_Description, dashboard_report_column, dashboard_report_column_position, dashboard_report_has_frame, dashboard_report_expanded, dashboard_report_allow_remove, dashboard_report_allow_minimize, dashboard_report_cache_code, dashboard_report_cache_timeout, dashboard_report_detail_link, dashboard_report_help_link) 
 	 values (@reportname,@templateid, 1, 1, @server, 0, dbo.fnServer_CmnGetDate(getutcdate()),@templatedesc, @column, @columnposition, @hasframe, @expanded, @allowremove, @allowminimize, @cachecode, @cachetimeout, @detaillink, @helplink )
 	 
 	 
 	 set @reportid =  (select scope_identity())
 	  	 
 	  	 
 	 insert into dashboard_parameter_values (dashboard_report_id, dashboard_template_parameter_id, dashboard_parameter_value, dashboard_parameter_column, dashboard_parameter_row)
 	 select @reportid, dv.dashboard_template_parameter_id, dv.dashboard_parameter_value, dv.dashboard_parameter_column, dv.dashboard_parameter_row
 	 from Dashboard_Parameter_Default_Values dv, dashboard_template_parameters tp
 	 where dv.dashboard_template_parameter_id = tp.dashboard_template_parameter_id
 	 and tp.dashboard_template_id = @templateid
 	 and tp.dashboard_template_parameter_id not in (select pv.dashboard_template_parameter_id from dashboard_parameter_values pv where pv.dashboard_report_id = @reportid)
 	 
 	 insert into dashboard_report_links (dashboard_template_link_id, dashboard_report_from_id)
 	 select dtl.dashboard_template_link_id, @reportID from dashboard_template_links dtl where dashboard_template_link_from = @templateid
 	 
 	 /*create table ##Report_ID
 	 (
 	  	 reportid int
 	 ) 	 
 	 insert into ##Report_ID values (@reportid)
 	 */
return @reportid
