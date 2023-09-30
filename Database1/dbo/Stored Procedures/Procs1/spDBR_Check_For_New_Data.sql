Create Procedure dbo.spDBR_Check_For_New_Data
@reportid int,
@oldtime datetime,
@InTimeZone 	  	 varchar(200) = NULL  ---23/08/2010 - Ex: 'India Standard Time','Central Stardard Time' 
AS
 	 declare @newtime datetime
 	 set @newtime = (select dashboard_Time_Stamp from dashboard_Report_Data where dashboard_report_id = @reportid)
 	 select @oldtime = dateadd(second, 1, @oldtime)
 	 ---23/08/2010 - Conversion of datetime into UTC e.g. India Standard Time','Central Stardard Time'
 	  
 	  	 SELECT @oldtime = dbo.fnServer_CmnConvertToDBTime(@oldtime,@InTimeZone)
if (@newtime > @oldtime)
begin
 	 select 'true' as NewData
end
else
begin
 	 select 'false' as NewData
end
