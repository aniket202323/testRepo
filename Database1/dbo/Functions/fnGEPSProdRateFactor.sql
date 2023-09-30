/*
Function: 	  	  	 fnGEPSProdRateFactor
Author: 	  	  	  	 Matthew Wells (GE)
Date Created: 	  	 2007/07/25
Editor Tab Spacing: 	 4
Description:
============
Calculates production rate factor.
Change Date 	 Who 	 What
=========== 	 ==== 	 =====
*/
CREATE FUNCTION [dbo].[fnGEPSProdRateFactor] ( 	 @RateUnit 	 int)
RETURNS real AS
BEGIN 
RETURN CASE @RateUnit
 	  	  	 WHEN 0 THEN 3600
 	  	  	 WHEN 1 THEN 60
 	  	  	 WHEN 2 THEN 1
 	  	  	 WHEN 3 THEN 86400
 	  	  	 ELSE 0
 	  	  	 END
END
