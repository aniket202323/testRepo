











/*
-----------------------------------------------------------
Name: spLocal_STLS_parmsel_PatternEditAllNameExists1
Purpose: Check if pattern exists per name and id.
-----------------------------------------------------------
Modified: Vinayak Pate
Date: 11 Feb 2008
Build #8
Change: maintain proficy standards be removing t ransactions and l ocks
-----------------------------------------------------------
Date: 11/12/2001
*/

CREATE  PROCEDURE spLocal_STLS_parmsel_PatternEditAllNameExists1

--Parameters
 @PatternName		VARCHAR(32),
 @PatternID		INT
 
AS



SELECT * 
FROM Local_PG_Patterns
WHERE PatternID <>  @PatternID
AND PatternName = @PatternName


--Error Check
IF @@ERROR > 0
	BEGIN
	RAISERROR('Update Pattern failed.', 16, 1)
	RETURN 99
	END


RETURN 0























