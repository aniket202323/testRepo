/*
Function: 	  	  	 fnGEPSRunTime
Author: 	  	  	  	 Matthew Wells (GE)
Date Created: 	  	 2007/07/25
Editor Tab Spacing: 	 4
Description:
============
Calculates actual speed
Change Date 	 Who 	 What
=========== 	 ==== 	 =====
*/
CREATE FUNCTION [dbo].[fnGEPSRunTime] ( 	 @CalendarTime 	  	  	 real,
 	  	  	  	  	  	  	  	  	  	 @TotalDowntime 	  	  	 real,
 	  	  	  	  	  	  	  	  	  	 @PerformanceDowntime 	 real)
RETURNS real AS
BEGIN
RETURN 	 @CalendarTime - @TotalDowntime + @PerformanceDowntime
END
