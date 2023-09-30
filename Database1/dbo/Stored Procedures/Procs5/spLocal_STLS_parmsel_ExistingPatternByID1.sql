










/*
---------------------------------------------------------
Name: spLocal_STLS_parmsel_ExistingPatternByID1
---------------------------------------------------------
Build #8: No Change
---------------------------------------------------------
Purpose: Select a pattern
Date: 11/12/2001
---------------------------------------------------------
*/

CREATE PROCEDURE spLocal_STLS_parmsel_ExistingPatternByID1
	@PatternID INT
AS

SELECT *
FROM Local_PG_Patterns
WHERE PatternID = @PatternID











