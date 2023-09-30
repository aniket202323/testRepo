/*
Function: 	  	  	 fnGEPSPerformance
Author: 	  	  	  	 Matthew Wells (GE)
Date Created: 	  	 2007/07/25
Editor Tab Spacing: 	 4
Description:
============
Calculates performance term.
Change Date 	 Who 	 What
=========== 	 ==== 	 =====
2007/08/17 	 MKW 	 Fixed cap condition
*/
CREATE FUNCTION [dbo].[fnGEPSPerformance] ( 	 @ActualProd 	 real,
 	  	  	  	  	  	  	  	  	  	  	 @IdealProd 	 real,
 	  	  	  	  	  	  	  	  	  	  	 @CapValue 	 tinyint)
RETURNS real AS
BEGIN
DECLARE @Performance real
SELECT @Performance = CASE 	 WHEN 	 @IdealProd > 0
 	  	  	  	  	  	  	  	 THEN @ActualProd/@IdealProd*100
 	  	  	  	  	  	  	 ELSE 0
 	  	  	  	  	  	  	 END
RETURN CASE 	 WHEN 	 @Performance > 100
 	  	  	  	  	 AND @CapValue = 1
 	  	  	  	 THEN 100
 	  	  	 ELSE @Performance
 	  	  	 END
END
