Create Procedure dbo.spDBR_Mark_Report_End_Time
@StatisticID int,
@EndTime datetime,
@InTimeZone 	  	 varchar(200) = NULL  ---23/08/2010 - Ex: 'India Standard Time','Central Stardard Time' 
AS
 	 ---24/08/2010 - Conversion of datetime into UTC e.g. India Standard Time','Central Stardard Time'
 	  
 	  	 SELECT @EndTime = dbo.fnServer_CmnConvertToDBTime(@EndTime,@InTimeZone)
 	  
 	 update Dashboard_Content_Generator_Statistics set Dashboard_Report_End_Time = @EndTime where Dashboard_Content_Generator_Statistic_ID = @StatisticID
