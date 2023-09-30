/*
Function: 	  	  	 fnGEPSIdealProduction
Author: 	  	  	  	 Matthew Wells (GE)
Date Created: 	  	 2007/07/25
Editor Tab Spacing: 	 4
Description:
============
Calculates ideal production.
Change Date 	 Who 	 What
=========== 	 ==== 	 =====
2007/08/17 	 MKW 	 Fixed ratefactor condition
*/
CREATE FUNCTION [dbo].[fnGEPSIdealProduction] ( 	 @Runtime 	  	  	 real,
 	  	  	  	  	  	  	  	  	  	  	  	 @IdealRate 	  	  	 real,
 	  	  	  	  	  	  	  	  	  	  	  	 @RateFactor 	  	  	 real,
 	  	  	  	  	  	  	  	  	  	  	  	 @TotalProduction 	 real)
RETURNS real AS
BEGIN
RETURN CASE WHEN 	 @IdealRate IS NULL
 	  	  	  	  	 THEN @TotalProduction
 	  	  	 WHEN 	 isnull(@RateFactor,0) > 0
 	  	  	  	  	 AND @RunTime >= 0
 	  	  	  	  	 THEN (@RunTime)*(@IdealRate/@RateFactor)
 	  	  	 ELSE 0
 	  	  	 END
END
