Create Procedure dbo.spDBR_Delete_Old_Stats
@daystosave int = -1
AS 	 
 	 declare @cutoffdate datetime
 	 if (@daystosave = -1)
 	 begin
 	  	 execute spServer_CmnGetParameter 169,27, @@SERVERNAME, @daystosave output
 	 end 	 
 	 set @daystosave = (@daystosave * (-1))
 	 set @cutoffdate = DateAdd(day, @daystosave, dbo.fnServer_CmnGetDate(getutcdate()))
 	 
 	 
 	 delete from dashboard_content_Generator_statistics where dashboard_report_end_time < @cutoffdate
 	 delete from dashboard_content_generator_resource_usage where dashboard_resource_log_time < @cutoffdate
 	 
 	 
