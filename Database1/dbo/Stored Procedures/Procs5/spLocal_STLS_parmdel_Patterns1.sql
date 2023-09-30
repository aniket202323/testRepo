











/*
--------------------------------------------------------------
Name: spLocal_STLS_parmdel_Patterns1
Purpose: Delete a pattern
--------------------------------------------------------------
Build #8
Modified by Vinayak Pate
Date 05-Feb-2008
Change: maintain proficy standards be removing t ransactions and l ocks
--------------------------------------------------------------
Date: 11/12/2001
--------------------------------------------------------------
*/

CREATE  PROCEDURE spLocal_STLS_parmdel_Patterns1
	--parameter
	@PatternID INT
AS


DELETE FROM Local_PG_Patterns
WHERE PatternID = @PatternID

DELETE FROM Local_PG_Pattern_Schedule
WHERE PatternID = @PatternID

--Error Check
IF @@ERROR > 0
	BEGIN
	RAISERROR('Delete of Pattern failed.', 16, 1)
	RETURN 99
	END


RETURN 0












