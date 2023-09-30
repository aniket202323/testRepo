Create Procedure dbo.spDBR_Mark_Report_Start_Time
@ReportID int,
@StartTime datetime,
@InTimeZone 	  	 varchar(200) = NULL  ---23/08/2010 - Ex: 'India Standard Time','Central Stardard Time' 
AS
declare @StatID int
 	 ---24/08/2010 - Conversion of datetime into UTC e.g. India Standard Time','Central Stardard Time'
 	  
 	  	 SELECT @StartTime = dbo.fnServer_CmnConvertToDBTime(@StartTime,@InTimeZone)
 	  
insert Dashboard_Content_Generator_Statistics (Dashboard_Report_ID, Dashboard_Report_Start_Time) values(@ReportID, @StartTime)
set @StatID = (select scope_identity())
select @StatID as id
