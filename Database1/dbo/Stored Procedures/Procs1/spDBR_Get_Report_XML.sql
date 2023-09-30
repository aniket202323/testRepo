Create Procedure dbo.spDBR_Get_Report_XML
@ReportID int,
@Version int
AS
declare @adhoc as bit
declare @onDemand as bit
set @onDemand = 0
declare @scheduleid as int
set @adhoc = (select dashboard_report_ad_hoc_flag from dashboard_reports where dashboard_report_id = @reportid)
set @scheduleid = (select dashboard_schedule_id from dashboard_schedule where dashboard_report_id = @reportid and dashboard_on_demand_based = 1)
if (not @scheduleid is null)
begin
 	 set @adhoc = 1
 	 set @onDemand = 1
end
select @adhoc as ad_hoc, @onDemand as on_demand, dashboard_time_stamp, dashboard_report_xml  from dashboard_report_data where dashboard_report_id = @reportid and dashboard_report_version = @version
