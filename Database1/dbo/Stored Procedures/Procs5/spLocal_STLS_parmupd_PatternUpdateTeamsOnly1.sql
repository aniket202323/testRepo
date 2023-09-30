











/*
--------------------------------------------------------------------------------------------------------------------------------------
Name: spLocal_STLS_parmupd_PatternUpdateTeamsOnly1
Purpose: Update the teams within a pattern.
--------------------------------------------------------------------------------------------------------------------------------------
Build #8
Modified by Vinayak Pate
Date 11-Feb-2008
Change: Maintain Proficy Standards by Removing T ransactions, l ocks
--------------------------------------------------------------------------------------------------------------------------------------
Date: 11/12/2001
--------------------------------------------------------------------------------------------------------------------------------------
*/

CREATE  PROCEDURE spLocal_STLS_parmupd_PatternUpdateTeamsOnly1
	--Parameters
	@PatternTeamNames VARCHAR(6000),	--a string structure (TeamName,Day,Shift)
	@PatternID INT
AS
	DECLARE @nTeamID INT
	DECLARE @vcTeamName VARCHAR(10)
	DECLARE @strShift CHAR(1)
	DECLARE @nShift	INT
	DECLARE @strDay VARCHAR(4)
	DECLARE @nDay INT

	--position flags 
	DECLARE @nPosition INT
	DECLARE @strRemainingTeams VARCHAR(6000) 
	DECLARE @strTeamRecord VARCHAR(16)
	DECLARE @strRemainingRecord VARCHAR(16)
	


	SET @strRemainingTeams = @PatternTeamNames


WHILE LEN(@strRemainingTeams) > 0
	BEGIN
	
	--Loop
	--  Get Team Record
	SET @nPosition = CHARINDEX(';', @strRemainingTeams, 1)
	SET @strTeamRecord = LEFT(@strRemainingTeams, @nPosition)

	--  Remove Remaining Records
	SET @strRemainingTeams = RIGHT(@strRemainingTeams, ((LEN(@strRemainingTeams)) - @nPosition))

	-- Get Team Name
	SET @nPosition = CHARINDEX(',', @strTeamRecord, 1)
	SET @vcTeamName = LEFT(@strTeamRecord,(@nPosition - 1))
	SET @strRemainingRecord = RIGHT(@strTeamRecord, ((LEN(@strTeamRecord)) - @nPosition))

	
	-- Get Team ID

	SET @nTeamID = (SELECT TeamID
			FROM Local_PG_Teams
			WHERE TeamName = @vcTeamName)


	-- Get Day
	SET @nPosition = CHARINDEX(',', @strRemainingRecord, 1)
	SET @strDay = LEFT(@strRemainingRecord,(@nPosition - 1))
	SET @strRemainingRecord = RIGHT(@strRemainingRecord, ((LEN(@strRemainingRecord)) - @nPosition))
	SET @nDay = CAST(@strDay AS INT)
	


	-- Get Shift
	SET @strShift = LEFT(@strRemainingRecord,1)
	SET @nShift = CAST(@strShift AS INT)

	
	UPDATE Local_PG_Pattern_Schedule
		SET TeamID = @nTeamID
		WHERE PatternDayID = @nDay
			AND ShiftID = @nShift
			AND PatternID = @PatternID

	END


--Error Check
IF @@ERROR > 0
	BEGIN
	RAISERROR('Update Pattern Teams Failed.', 16, 1)
	RETURN 99
	END

	
RETURN 0















