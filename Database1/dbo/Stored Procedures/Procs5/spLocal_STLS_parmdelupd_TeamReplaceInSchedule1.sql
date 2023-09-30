











/*
--------------------------------------------------------------
Name: spLocal_STLS_parmdelupd_TeamReplaceInSchedule1
Purpose: This procedure is called when deleting a team that is already used within the schedule.
The user can opt to Replace the Team throughout the Schedule ("ReplaceAllFlag = "ReplaceAll"),
or to Replace the Team only after a selected effective date ("ReplaceAllFlag = "EffectiveDate")
The schedule is updated, then the team is deleted.
--------------------------------------------------------------
Build #8
Modified by Vinayak Pate
Date 12-Feb-2008
Change: maintain proficy standards be removing t ransactions and l ocks
--------------------------------------------------------------
Date: 11/12/2001
--------------------------------------------------------------
*/

CREATE  PROCEDURE spLocal_STLS_parmdelupd_TeamReplaceInSchedule1
	--parameters
	@ReplaceAllFlag VARCHAR(20),
	@ReplaceTeam	VARCHAR(10),
	@WithReplacementTeam VARCHAR(10),
	@EffectiveDate DATETIME
AS



IF @ReplaceAllFlag = 'ReplaceAll'
	BEGIN	
	--Update all records with this team in the schedule
	UPDATE Crew_Schedule
		SET Crew_Desc = @WithReplacementTeam
		WHERE Crew_Desc = @ReplaceTeam

	DELETE FROM Local_PG_Teams
	WHERE TeamName = @ReplaceTeam
	END

ELSE
	BEGIN
	UPDATE Crew_Schedule
		SET Crew_Desc = @WithReplacementTeam
		WHERE Crew_Desc = @ReplaceTeam
		AND Start_Time >= @EffectiveDate

	DELETE FROM Local_PG_Teams
	WHERE TeamName = @ReplaceTeam
	END


--Error Check
IF @@ERROR > 0
	BEGIN
	RAISERROR('Replace And Delete Team Failed.', 16, 1)
	RETURN 99
	END


RETURN 0














