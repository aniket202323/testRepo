Create Procedure dbo.spDBR_Add_Calendar_Custom_Date
@CalendarID int,
@CustomDate datetime,
@InTimeZone 	  	 varchar(200) = NULL  ---23/08/2010 - Ex: 'India Standard Time','Central Stardard Time' 
AS
 	 ---23/08/2010 - Conversion of datetime into UTC e.g. India Standard Time','Central Stardard Time'
 	 SELECT @CustomDate = dbo.fnServer_CmnConvertToDBTime(@CustomDate,@InTimeZone)
 	 insert into dashboard_custom_dates (Dashboard_Calendar_ID , Dashboard_Day_To_Run,Dashboard_Completed ) values (@calendarid, @customdate, 0)
