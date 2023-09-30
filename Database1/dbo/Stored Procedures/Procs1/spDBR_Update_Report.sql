Create Procedure dbo.spDBR_Update_Report
@reportid int,
@reportname varchar(100),
@templateid int,
@securitygroupid int,
@versioncount int,
@servername varchar(100)
AS
 	 declare @oldtemplate int
 	 
 	 set @oldtemplate = (select dashboard_template_id from dashboard_reports where dashboard_report_id = @reportid)
 	 if (@oldtemplate <> @templateid)
 	 begin
 	  	 delete from dashboard_parameter_values where dashboard_report_id = @reportid
 	  	 delete from dashboard_report_links where dashboard_report_from_id = @reportid
 	  	 update dashboard_report_links set dashboard_report_to_id = null where dashboard_report_to_id = @reportid
 	  	 
 	  	 insert into dashboard_parameter_values (dashboard_report_id, dashboard_template_parameter_id, dashboard_parameter_value, dashboard_parameter_column, dashboard_parameter_row)
 	  	 select @reportid, dv.dashboard_template_parameter_id, dv.dashboard_parameter_value, dv.dashboard_parameter_column, dv.dashboard_parameter_row
 	  	 from Dashboard_Parameter_Default_Values dv, dashboard_template_parameters tp
 	  	 where dv.dashboard_template_parameter_id = tp.dashboard_template_parameter_id
 	  	 and tp.dashboard_template_id = @templateid
 	  	 
 	  	 insert into dashboard_report_links (dashboard_template_link_id, dashboard_report_from_id)
 	  	 select dtl.dashboard_template_link_id, @reportID from dashboard_template_links dtl where dashboard_template_link_from = @templateid
 	  	 
 	  	 /*update dashboard description since it has changed*/
 	  	 declare @desc as varchar(4000)
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
 	  	 
 	  	 
 	  	 set @desc = (select dashboard_template_description from dashboard_Templates where dashboard_template_id = @templateid)
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
 	  	 
 	  	 update dashboard_reports set dashboard_report_description = @desc,
 	  	  	  	  	  	  	  	  	  dashboard_report_column = @column,
 	  	  	  	  	  	  	  	  	  dashboard_report_column_position = @columnposition,
 	  	  	  	  	  	  	  	  	  dashboard_report_has_frame = @hasframe,
 	  	  	  	  	  	  	  	  	  dashboard_report_expanded = @expanded,
 	  	  	  	  	  	  	  	  	  dashboard_report_allow_remove = @allowremove,
 	  	  	  	  	  	  	  	  	  dashboard_report_allow_minimize = @allowminimize,
 	  	  	  	  	  	  	  	  	  dashboard_report_cache_code = @cachecode,
 	  	  	  	  	  	  	  	  	  dashboard_report_cache_timeout = @cachetimeout,
 	  	  	  	  	  	  	  	  	  dashboard_report_detail_link = @detaillink,
 	  	  	  	  	  	  	  	  	  dashboard_report_help_link = @helplink
 	  	  	  	  	  	  	  	  	  where dashboard_report_id = @reportid
 	  	 
 	 end
 	 
 	 declare @@oldReportName varchar(100)
 	 declare @@oldTemplateID int
 	 declare @@maxversion int
 	 
 	 select @@oldReportName = Dashboard_Report_Name, @@oldTemplateID = Dashboard_Template_ID from Dashboard_Reports where Dashboard_Report_ID = @reportid
 	 
 	 if (@@oldReportName = @reportname and @@oldTemplateID = @templateid)
 	 begin
 	  	 select @@maxversion = Version from Dashboard_Reports where Dashboard_Report_ID = @reportid
 	 end
 	 else
 	 begin
 	  	 select @@maxversion = max(Version) + 1 from Dashboard_Reports where Dashboard_Template_ID = @templateid and Dashboard_Report_Name = @reportname 	  	 
 	  	 if (@@maxversion is null)
 	  	 begin
 	  	  	 set @@maxversion = 1
 	  	 end
 	 end
 	 if (@securitygroupid = -1)
 	 begin
 	  	 update dashboard_reports set dashboard_report_name = @reportname, dashboard_template_id = @templateid, dashboard_report_security_group_id = null, dashboard_report_version_count = @versioncount, dashboard_report_server = @servername, version = @@maxversion where dashboard_report_id = @reportid
 	 end
 	 else
 	 begin
 	  	 update dashboard_reports set dashboard_report_name = @reportname, dashboard_template_id = @templateid, dashboard_report_security_group_id = @securitygroupid,dashboard_report_version_count = @versioncount, dashboard_report_server = @servername, version = @@maxversion where dashboard_report_id = @reportid
 	 end
