Create Procedure dbo.spDBR_Get_Content_Generator_Statistics
@starttime 	  	 datetime,
@endtime 	  	 datetime,
@InTimeZone 	  	 varchar(200) = NULL  ---23/08/2010 - Ex: 'India Standard Time','Central Stardard Time' 
AS
 	 ---24/08/2010 - Conversion of datetime into UTC e.g. India Standard Time','Central Stardard Time'
 	  
 	  	 SELECT @starttime = dbo.fnServer_CmnConvertToDBTime(@starttime,@InTimeZone)
 	  	 SELECT @endtime = dbo.fnServer_CmnConvertToDBTime(@endtime,@InTimeZone)
 	  
 	 declare @count int
 	 set @count = (select count(dashboard_report_start_time) from dashboard_content_generator_statistics where Dashboard_report_start_time >= @starttime and Dashboard_Report_Start_Time <= @endtime)
 	 select @count as NumRows, * from Dashboard_Content_Generator_Statistics where Dashboard_Report_Start_Time >= @starttime and Dashboard_Report_Start_Time <= @endtime order by Dashboard_Report_Start_Time
