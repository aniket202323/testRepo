











/*
--------------------------------------------------------------
Name: spLocal_STLS_parmdelupd_PatternName1
Purpose: Update the name of a pattern by deleting then updating it.
--------------------------------------------------------------
Build #8
Modified by Vinayak Pate
Date 12-Feb-2008
Change: maintain proficy standards be removing t ransactions and l ocks
--------------------------------------------------------------
Date: 11/12/2001
--------------------------------------------------------------
*/

CREATE  PROCEDURE spLocal_STLS_parmdelupd_PatternName1
	--Parameters
	@PatternID INT,
	@PatternName VARCHAR(32),
	@PatternDays INT

AS
	DECLARE @nPatternDaysExisting INT



	--1. Evaluate if the new number of days exceeds the existing number of days
	SET @nPatternDaysExisting = 	(SELECT PatternDays 
				  	 FROM Local_PG_Patterns
					 WHERE PatternID = @PatternID)
	
	IF @PatternDays <= @nPatternDaysExisting
		BEGIN

		--check for overlapping records
		SELECT PatternID 
		FROM Local_PG_Patterns
		WHERE PatternName = @PatternName
		AND  PatternID <> @PatternID

		IF @@ROWCOUNT > 0
		BEGIN
			RETURN 1
		END


		
		--2.  Update the name of the pattern in Local_PG_Patterns and Local_PG_Pattern_Schedule
		UPDATE Local_PG_Patterns
		SET PatternName = @PatternName ,
		PatternDays = @PatternDays
		WHERE PatternID = @PatternID
		
		--3.  Delete Excess records
		DELETE FROM Local_PG_Pattern_Schedule
		WHERE PatternID = @PatternID
			AND PatternDayID > @PatternDays
		END
	
	


	ELSE
		BEGIN
		RAISERROR('Update Pattern Failed.', 16, 1)
		RETURN 99
		END

--Error Check
IF @@ERROR > 0
	BEGIN
	RAISERROR('Update Pattern Failed.', 16, 1)
	RETURN 99
	END

	
RETURN 0












