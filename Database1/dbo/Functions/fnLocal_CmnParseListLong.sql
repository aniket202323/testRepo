﻿/*
Stored Procedure: 	 fnLocal_CmnParseListLong
Author: 	  	  	 Matthew Wells (GE)
Date Created: 	  	 2005/03/04
Description:
=========
This function parses out a list in a string separated by defined character
Change Date 	 Who 	 What
=========== 	 ==== 	 =====
*/
CREATE FUNCTION [dbo].[fnLocal_CmnParseListLong] ( 	 @String 	  	 varchar(MAX),
 	  	  	  	  	  	  	  	  	  	  	 @Separator 	 char(1))
RETURNS @List TABLE (Value varchar(MAX))
AS
BEGIN
DECLARE 	 @Start 	 int,
 	  	 @End 	 int
SELECT 	 @Start 	 = 1,
 	  	 @String 	 = @String + @Separator,
 	  	 @End 	 = charindex(@Separator, @String, @Start)
WHILE @End > 0
 	 BEGIN
 	 IF @Start < @End
 	  	 BEGIN
 	  	 INSERT INTO @List (Value)
 	  	 SELECT substring(@String, @Start, @End - @Start)
 	  	 END
 	 SELECT 	 @Start 	 = @End + 1,
 	  	  	 @End 	 = charindex(@Separator, @String, @Start)
 	 END
RETURN
END