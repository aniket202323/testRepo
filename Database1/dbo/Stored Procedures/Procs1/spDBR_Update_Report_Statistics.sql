Create Procedure dbo.spDBR_Update_Report_Statistics
@reportid int
AS
 	 declare @numhits int
 	 set @numhits =  (select dashboard_report_number_hits from dashboard_reports where dashboard_report_id = @reportid)
 	 set @numhits = @numhits + 1
 	 update dashboard_reports set dashboard_report_number_hits = @numhits where dashboard_report_id = @reportid
