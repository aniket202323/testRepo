/*
Function: 	  	  	 fnGEPSIdealSpeed
Author: 	  	  	  	 Matthew Wells (GE)
Date Created: 	  	 2007/07/25
Editor Tab Spacing: 	 4
Description:
============
Calculates actual speed
Change Date 	 Who 	 What
=========== 	 ==== 	 =====
*/
CREATE FUNCTION [dbo].[fnGEPSIdealSpeed] ( 	 @Time 	  	  	 real,
 	  	  	  	  	  	  	  	  	  	  	 @Production 	  	 real,
 	  	  	  	  	  	  	  	  	  	  	 @RateFactor 	  	 real)
RETURNS real AS
BEGIN
RETURN CASE WHEN 	 @RateFactor > 0
 	  	  	  	  	 AND @Time > 0
 	  	  	  	  	 THEN @Production/(@Time/@RateFactor)
 	  	  	 ELSE 0
 	  	  	 END
END
