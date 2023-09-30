/*
Function: 	  	  	 fnGEPSQuality
Author: 	  	  	  	 Matthew Wells (GE)
Date Created: 	  	 2007/07/25
Editor Tab Spacing: 	 4
Description:
============
Calculates Quality term.
Change Date 	 Who 	 What
=========== 	 ==== 	 =====
*/
CREATE FUNCTION [dbo].[fnGEPSQuality] ( 	 @TotalProduction 	 real,
 	  	  	  	  	  	  	  	  	  	 @Waste 	  	  	  	 real,
 	  	  	  	  	  	  	  	  	  	 @CapValue 	  	  	 tinyint)
RETURNS real AS
BEGIN
DECLARE @Quality real
SELECT @Quality = CASE 	 WHEN 	 @TotalProduction > 0
 	  	  	  	  	  	  	  	 THEN (@TotalProduction-@Waste)/@TotalProduction*100
 	  	  	  	  	  	  	 ELSE 0
 	  	  	  	  	  	  	 END
RETURN CASE 	 WHEN 	 @Quality > 100
 	  	  	  	  	 AND @CapValue = 1
 	  	  	  	 THEN 100
 	  	  	 ELSE @Quality
 	  	  	 END
END
