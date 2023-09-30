










/*
-----------------------------------------------------
Name: spLocal_STLS_parmsel_ExistingPatterns1
-----------------------------------------------------
Build #8 No Change
-----------------------------------------------------
Purpose: Get Patterns Count
Date: 11/12/2001
-----------------------------------------------------
*/

CREATE PROCEDURE spLocal_STLS_parmsel_ExistingPatterns1 

--Parameters
@PatternName VARCHAR(32)

AS
	SELECT *
	FROM Local_PG_Patterns
	WHERE UPPER(PatternName) = UPPER(@PatternName)











