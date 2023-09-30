Create Procedure dbo.spDBR_Get_Report_Display_Vars
@ReportID int
AS
declare @server varchar(50)
declare @port varchar(50)
declare @node varchar(50)
set @node = (select dashboard_Report_server from dashboard_Reports where dashboard_report_id = @reportid)
execute spServer_CmnGetParameter 161,33 , @node, @port output
execute spServer_CmnGetParameter 165,33 , @node, @server output
if (@server is null or @server = '')
begin
 	 set @server = @node
end
if(@server is null or @server = '')
begin
 	 set @server = (select @@servername)
end 
select r.dashboard_report_id, r.dashboard_report_name, t.dashboard_template_launch_type, r.dashboard_report_has_frame, 
 	  	 t.dashboard_template_fixed_height, t.dashboard_template_fixed_width, t.height, t.width, u.Dashboard_Template_Size_Unit_Code, 
 	  	 t.dashboard_template_help_link, @server as server, @port as port
 	 from dashboard_reports r, dashboard_templates t, dashboard_template_size_units u 
 	 where r.dashboard_report_id = @reportid and r.dashboard_template_id = t.dashboard_template_id and t.dashboard_template_size_unit = u.dashboard_template_size_unit_id
 	  	  	 
