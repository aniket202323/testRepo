/*
Function: 	  	  	 fnGEPSAvailability
Author: 	  	  	  	 Matthew Wells (GE)
Date Created: 	  	 2007/07/25
Editor Tab Spacing: 	 4
Description:
============
Calculates availability
Change Date 	 Who 	 What
=========== 	 ==== 	 =====
*/
CREATE FUNCTION [dbo].[fnGEPSAvailability] (@LoadingTime 	 real,
 	  	  	  	  	  	  	  	  	  	  	 @RunTime 	 real,
 	  	  	  	  	  	  	  	  	  	  	 @CapValue 	 tinyint)
RETURNS real AS
BEGIN
DECLARE @Availability real
SELECT @Availability = CASE WHEN @LoadingTime > 0
 	  	  	  	  	  	  	  	 THEN @RunTime/@LoadingTime*100
 	  	  	  	  	  	  	 ELSE 0
 	  	  	  	  	  	  	 END
RETURN CASE WHEN 	 @Availability > 100
 	  	  	  	  	 AND @CapValue = 1
 	  	  	  	 THEN 100
 	  	  	 ELSE @Availability
 	  	  	 END
END
