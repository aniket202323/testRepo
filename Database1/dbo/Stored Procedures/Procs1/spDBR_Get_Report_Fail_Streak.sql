Create Procedure dbo.spDBR_Get_Report_Fail_Streak
@ReportID int,
@FailCount int output
AS
 	 declare @@lastgoodruntime datetime
 	 select @@lastgoodruntime = max(Dashboard_Report_Start_Time) from dashboard_content_Generator_Statistics where not dashboard_report_end_time is null and dashboard_report_id = @reportid
 	 
 	 if (not @@lastgoodruntime is null)
 	 begin 	  	 
 	  	 select @FailCount = count(dashboard_content_generator_statistic_id) from dashboard_content_Generator_Statistics where dashboard_report_start_time > @@lastgoodruntime and dashboard_report_id = @reportid
 	 end
 	 else
 	 begin
 	  	 select @failcount = count(dashboard_content_generator_statistic_id) from dashboard_content_Generator_Statistics where dashboard_report_id = @reportid
 	 end
