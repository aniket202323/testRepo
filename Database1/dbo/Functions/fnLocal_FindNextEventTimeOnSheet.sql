-------------------------------------------------------------------------------------------------

-------------------------------------[Creation Of Function]--------------------------------------
CREATE FUNCTION [dbo].[fnLocal_FindNextEventTimeOnSheet] (@Sheet_Id int, @TimeStamp datetime)
/*
-------------------------------------------------------------------------------------------------
Created by	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2006-03-02
Version		:	1.0.0
Purpose		:	Searches for a non-existing event timestamp within given sheet ID.
					Will search after @TimeStamp time, incrementing 1 second until found. 
					Returns a sheet column timestamp.
-------------------------------------------------------------------------------------------------
*/

RETURNS datetime

AS
BEGIN

	DECLARE 
	@EventTime	datetime,
	@Step			int,
	@TimeFound	bit

	SET @TimeFound = 0
	SET @Step = 0
	
	WHILE @TimeFound = 0
		BEGIN
			SET @EventTime = dateadd(ss, @Step, @TimeStamp)
			IF NOT Exists(SELECT Result_On FROM dbo.Sheet_Columns WHERE (Sheet_Id = @Sheet_Id) AND (Result_On = @EventTime))
				BEGIN
					SET @TimeFound = 1
				END 
				
			SET @Step = @Step + 1
		END

	RETURN @EventTime

END

