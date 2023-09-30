Create Procedure dbo.spDBR_Get_Sample_XML
@templateid int
AS
 	 declare @reportid int
 	 declare @reportname varchar(100)
 	 declare @server varchar(100)
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
 	 
 	 
 	 set @reportname = (select Dashboard_Template_Name from dashboard_templates where dashboard_template_id = @templateid)
 	 set @server =(select @@SERVERNAME)
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
 	 
 	 insert into dashboard_report_links (dashboard_template_link_id, dashboard_report_from_id)
 	 select dtl.dashboard_template_link_id, @reportID from dashboard_template_links dtl where dashboard_template_link_from = @templateid
 	 
 	 select @reportid as Dashboard_Report_ID
