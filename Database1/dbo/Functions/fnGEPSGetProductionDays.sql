/*
Function: 	  	  	 fnGEPSGetProductionDays
Author: 	  	  	  	 Matthew Wells (GE)
Date Created: 	  	 2007/07/25
Editor Tab Spacing: 	 4
Description:
============
Calculates the production days for the period passed.
Change Date 	 Who 	 What
=========== 	 ==== 	 =====
*/
CREATE FUNCTION [dbo].[fnGEPSGetProductionDays] ( 	 @ReportStartTime 	 datetime,
 	  	  	  	  	  	  	  	  	  	  	  	  	 @ReportEndTime 	  	 datetime)
RETURNS @Days TABLE ( 	 StartTime 	  	 datetime,
 	  	  	  	  	  	 EndTime 	  	  	 datetime,
 	  	  	  	  	  	 ProductionDay 	 datetime)
AS
BEGIN 
 	 -- Declarations
 	 DECLARE 	 @ParmEndHourId 	  	 int,
 	  	  	 @ParmEndMinuteId 	 int,
 	  	  	 @ParmEndHour 	  	 int,
 	  	  	 @ParmEndMinute 	  	 int,
 	  	  	 @ProductionDay 	  	 datetime
 	 -- Initialization
 	 SELECT 	 @ParmEndHourId 	  	 = 14,
 	  	  	 @ParmEndMinuteId 	 = 15
 	 -- Configuration
 	 SELECT 	 @ParmEndHour = convert(int, Value)
 	 FROM dbo.Site_Parameters
 	 WHERE 	 Parm_Id = @ParmEndHourId
 	 SELECT 	 @ParmEndMinute = convert(int, Value)
 	 FROM dbo.Site_Parameters
 	 WHERE 	 Parm_Id = @ParmEndMinuteId
 	  	 -- Generate list of production days
 	 SELECT @ProductionDay = convert(datetime, convert(int, @ReportStartTime))
 	 SELECT @ProductionDay = dateadd(hh, @ParmEndHour, @ProductionDay)
 	 SELECT @ProductionDay = dateadd(mi, @ParmEndMinute, @ProductionDay)
 	 IF @ProductionDay > @ReportStartTime
 	  	 BEGIN
 	  	 SELECT @ProductionDay = dateadd(d, -1, @ProductionDay)
 	  	 END
 	 WHILE @ProductionDay < @ReportEndTime
 	  	 BEGIN
 	  	 INSERT INTO @Days ( 	 StartTime,
 	  	  	  	  	  	  	 EndTime,
 	  	  	  	  	  	  	 ProductionDay)
 	  	 VALUES (CASE 	 WHEN @ProductionDay < @ReportStartTime THEN @ReportStartTime
 	  	  	  	  	  	 ELSE @ProductionDay
 	  	  	  	  	  	 END,
 	  	  	  	 CASE 	 WHEN dateadd(d, 1, @ProductionDay) > @ReportEndTime THEN @ReportEndTime
 	  	  	  	  	  	 ELSE dateadd(d, 1, @ProductionDay)
 	  	  	  	  	  	 END,
 	  	  	  	 convert(nvarchar(25), @ProductionDay, 1))
 	  	 SELECT @ProductionDay = dateadd(d, 1, @ProductionDay)
 	  	 END
    RETURN
END
