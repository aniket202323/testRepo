/*
Function: 	  	  	 fnGEPSMaxDate
Author: 	  	  	  	 Matthew Wells (GE)
Date Created: 	  	 2007/08/17
Editor Tab Spacing: 	 4
Description:
============
Calculates maximum date
Change Date 	 Who 	 What
=========== 	 ==== 	 =====
*/
CREATE FUNCTION [dbo].[fnGEPSMaxDate] ( 	 @Date1 	 datetime,
 	  	  	  	  	  	  	  	  	  	 @Date2 	 datetime,
 	  	  	  	  	  	  	  	  	  	 @Date3 	 datetime)
RETURNS datetime AS
BEGIN
IF 	 @Date1 >= isnull(@Date2, @Date1)
 	 AND @Date1 >= isnull(@Date3, @Date1)
 	 RETURN @Date1
ELSE IF 	 @Date2 >= isnull(@Date3, @Date2)
 	 RETURN @Date2
RETURN @Date3
END
