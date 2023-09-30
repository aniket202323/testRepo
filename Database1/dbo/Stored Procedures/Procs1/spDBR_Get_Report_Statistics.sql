Create Procedure dbo.spDBR_Get_Report_Statistics
@reportid int
AS
 	 declare @number_hits integer
 	 declare @number_executions integer
 	 declare @ave_run_time integer 	 
 	 
 	 set @number_hits = (select dashboard_report_number_hits from dashboard_reports where dashboard_report_id = @reportid)
 	 set @number_executions = (select count(dashboard_content_generator_statistic_id) from dashboard_content_generator_statistics where dashboard_report_id = @reportid) 
 	 set @ave_run_time = (select AVG(DATEDIFF(Millisecond, dashboard_report_start_time, dashboard_report_end_time)) from dashboard_content_generator_statistics where dashboard_report_id = @reportid and not dashboard_report_end_time is null)
 	 declare @ave_time varchar(100)
 	 if (@ave_run_time is null)
 	 begin
 	  	 set @ave_time = '0 ms'
 	 end
 	 else
 	 begin
 	  	 set @ave_time = convert(varchar(100), @ave_run_time)
 	  	 set @ave_time = (@ave_time + ' ms')
 	 end
 	 select @number_hits as number_hits, @number_executions as number_executions, @ave_time as average_exec_time
