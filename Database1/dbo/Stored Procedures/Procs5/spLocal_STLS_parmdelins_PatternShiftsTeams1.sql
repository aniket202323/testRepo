











/*
--------------------------------------------------------------
Name: spLocal_STLS_parmdelins_PatternShiftsTeams1
Purpose: delete the shifts and teams info on a pattern and replace.
--------------------------------------------------------------
Build #8
Modified by Vinayak Pate
Date 12-Feb-2008
Change: maintain proficy standards be removing t ransactions and l ocks
--------------------------------------------------------------
Date: 11/12/2001
--------------------------------------------------------------
*/

CREATE  PROCEDURE spLocal_STLS_parmdelins_PatternShiftsTeams1

--Parameters
 @PatternName		VARCHAR(32),
 @PatternTotalDays	INT,
 @PatternShiftTimes 	VARCHAR(600),
 @PatternTeams		VARCHAR(8000), --Format:    'Team1,Team2,Team1,Team3'
 @ExistingPatternID 		INT

AS

--Local Variables
DECLARE @PatternShiftTimesLocal VARCHAR(600)
DECLARE @vcTeamRecord		VARCHAR(10)

DECLARE @charFieldDelimiter 	CHAR(1)
DECLARE @charRecordDelimiter	CHAR(1)
DECLARE @charTeamDelimiter	CHAR(1)
DECLARE @nFieldPosition		INT
DECLARE @nRecordPosition	INT
DECLARE @nTeamRecordPosition	INT
DECLARE @vcCurrentRecord	VARCHAR(18)	--'Day\Shift\StartTime\EndTime\DayChange;
						--'1\2\02:00\12:00\1; [repeat]
DECLARE @nDayCounter		INT
DECLARE @nWeekDay		INT		--1 of 7 days in the 7-day cycle

DECLARE @PatternID		INT
DECLARE @nDay			INT
DECLARE @nShift			INT
DECLARE @charStartTime		CHAR(5)
DECLARE @charEndTime		CHAR(5)
DECLARE @nDayChange		INT
DECLARE @nTeamID		INT



SET @charFieldDelimiter = '\'
SET @charRecordDelimiter = ';'
SET @charTeamDelimiter = ','


	--Delete Existing Pattern
	DELETE FROM Local_PG_Pattern_Schedule
	WHERE PatternID = @ExistingPatternID

	DELETE FROM Local_PG_Patterns
	WHERE PatternID = @ExistingPatternID

	--0.  Insert Pattern Name and Number Days into Local_PG_Patterns
	Insert Into Local_PG_Patterns(PatternName,PatternDays)
	Values(@PatternName,@PatternTotalDays)	

	--1.  Loop through total number of days
	SET @nDayCounter = 1
	WHILE(@nDayCounter <= @PatternTotalDays)
	BEGIN

		--2.  Get Day of Week (1-7)
		IF @nDayCounter > 7
		BEGIN
			
			SET @nWeekDay = @nDayCounter % 7
			IF @nWeekDay = 0
				SET @nWeekDay = 7			
		END
		ELSE
		BEGIN
			SET @nWeekDay = @nDayCounter
		END
		
		--3.  Get 1 Record from @PatternShiftTimes
		Set @PatternShiftTimesLocal = @PatternShiftTimes


		WHILE(LEN(@PatternShiftTimesLocal)>0)
		BEGIN

			SET @nRecordPosition = CHARINDEX(@charRecordDelimiter,@PatternShiftTimesLocal,1)
			SET @vcCurrentRecord = LEFT(@PatternShiftTimesLocal,@nRecordPosition)

			--4.  Get Day of Week From Current Record; Compare
			SET @nDay = LEFT(@vcCurrentRecord,1)
			IF @nDay = CAST(@nWeekDay AS INT)
			
			BEGIN
				
				SET @nTeamRecordPosition = CHARINDEX(@charTeamDelimiter,@PatternTeams,1)

				SET @vcTeamRecord = Left(@PatternTeams, (@nTeamRecordPosition - 1))
				SET @PatternTeams = RIGHT(@PatternTeams, ((Len(@PatternTeams)) - @nTeamRecordPosition))
				
				--Get TeamID
				SELECT @nTeamID = TeamID
				FROM Local_PG_Teams
				WHERE TeamName = @vcTeamRecord

				--Get PatternID
				SELECT @PatternID = PatternID
				FROM Local_PG_Patterns
				WHERE PatternName = @PatternName
				
				--Get Shift Info
				SET @nShift = CAST((SubString(@vcCurrentRecord,3,1)) AS INT)
				
				--GET StartTime & EndTime & DayChange
				SET @charStartTime = SubString(@vcCurrentRecord,5,5)
				SET @charEndTime = SubString(@vcCurrentRecord,11,5)
				SET @nDayChange = SubString(@vcCurrentRecord,17,1)

				--Test 
				--SELECT @PatternID as "PatternID", @nDayCounter as "Day", @nShift as "Shift", @charStartTime as "StartTime", @charEndTime as "EndTime", @nDayChange as "DayChange", @nTeamID as "TeamID"
				
				--Insert into table Local_PG_Pattern_Schedule
				INSERT INTO Local_PG_Pattern_Schedule
				(PatternID,PatternDayID,ShiftID,StartTime,EndTime,DayChangeFlag,TeamID)
				VALUES(@PatternID,@nDayCounter,@nShift,@charStartTime,@charEndTime,@nDayChange,@nTeamID)
			END

			SET @PatternShiftTimesLocal = RIGHT(@PatternShiftTimesLocal,((LEN(@PatternShiftTimesLocal))-@nRecordPosition))
		END
		SET @nDayCounter = @nDayCounter + 1
	END

--Error Check
IF @@ERROR > 0
	BEGIN
	RAISERROR('Update Pattern failed.', 16, 1)
	RETURN 99
	END


RETURN 0














