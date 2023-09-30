











/*
--------------------------------------------------------------------------------------------------------------------------------------
Name: spLocal_STLS_parmsel_TeamInPatterns1
Purpose: Given a team, find out if that team was used in which pattern.
--------------------------------------------------------------------------------------------------------------------------------------
Build #8
Modified by Vinayak Pate
Date 11-Feb-2008
Change: maintain proficy standards be removing t ransactions and l ocks
--------------------------------------------------------------------------------------------------------------------------------------
Date: 11/12/2001
--------------------------------------------------------------------------------------------------------------------------------------
*/

CREATE  PROCEDURE spLocal_STLS_parmsel_TeamInPatterns1
	--parameter
	@TeamID INT
AS


SELECT  DISTINCT Local_PG_Patterns.PatternName, Local_PG_Patterns.PatternID, 
	Local_PG_Pattern_Schedule.PatternID, Local_PG_Pattern_Schedule.TeamID
FROM Local_PG_Patterns

JOIN Local_PG_Pattern_Schedule 
	ON Local_PG_Patterns.PatternID = Local_PG_Pattern_Schedule.PatternID

WHERE Local_PG_Pattern_Schedule.TeamID = @TeamID
ORDER BY Local_PG_Patterns.PatternName


--Error Check
IF @@ERROR > 0
	BEGIN
	RAISERROR('Selection failed.', 16, 1)
	RETURN 99
	END


RETURN 0














