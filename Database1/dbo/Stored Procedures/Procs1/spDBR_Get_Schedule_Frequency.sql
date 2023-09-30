Create Procedure dbo.spDBR_Get_Schedule_Frequency
@scheduleid int,
@InTimeZone varchar(200)=''
AS
 	 select dashboard_frequency_base_time = dbo.fnServer_CmnConvertFromDBTime(dashboard_frequency_base_time,@InTimeZone), dashboard_frequency, dashboard_frequency_type_id from dashboard_schedule_frequency where dashboard_schedule_id = @scheduleid
