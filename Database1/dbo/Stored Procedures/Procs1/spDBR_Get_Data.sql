Create Procedure dbo.spDBR_Get_Data
@StartTime 	  	 datetime,
@EndTime 	  	 datetime,
@varlist 	  	 text,
@InTimeZone 	  	 varchar(200) = NULL  ---23/08/2010 - Ex: 'India Standard Time','Central Stardard Time' 
AS
 	 ---24/08/2010 - Conversion of datetime into UTC e.g. India Standard Time','Central Stardard Time'
 	  
 	  	 SELECT @StartTime = dbo.fnServer_CmnConvertToDBTime(@StartTime,@InTimeZone)
 	  	 SELECT @EndTime = dbo.fnServer_CmnConvertToDBTime(@EndTime,@InTimeZone)
 	  
 	 create table #MyReports([Report ID] varchar(50), [Template ID] varchar(50), [Report Name] varchar(50)) 	 
 	 insert into #MyReports EXECUTE spDBR_Prepare_Table @VarList
EXECUTE spDBR_Prepare_Table '##MyReports', @varlist
select * from #MyReports
