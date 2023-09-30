










/*
--------------------------------------------------------------
Name: spLocal_STLS_parmsel_ExistingPatternScheduleByID1
--------------------------------------------------------------
Build #8 No Change
--------------------------------------------------------------
Purpose:
Date: 11/12/2001
--------------------------------------------------------------
*/


CREATE PROCEDURE spLocal_STLS_parmsel_ExistingPatternScheduleByID1
	--Parameters
	@PatternID INT
AS
	SELECT Local_PG_Pattern_Schedule.ScheduleID, Local_PG_Pattern_Schedule.PatternID, Local_PG_Pattern_Schedule.PatternDayID, Local_PG_Pattern_Schedule.ShiftID, Local_PG_Pattern_Schedule.StartTime,
			Local_PG_Pattern_Schedule.EndTime, Local_PG_Pattern_Schedule.DayChangeFlag, Local_PG_Pattern_Schedule.TeamID, Local_PG_Teams.TeamName 
	FROM Local_PG_Pattern_Schedule
	JOIN Local_PG_Teams ON Local_PG_Pattern_Schedule.TeamID = Local_PG_Teams.TeamID
	WHERE PatternID = @PatternID
	ORDER BY PatternDayID

--Error Check
IF @@ERROR > 0
	BEGIN
	RAISERROR('Select Pattern Failed.', 16, 1)
	RETURN 99
	END

RETURN 0












