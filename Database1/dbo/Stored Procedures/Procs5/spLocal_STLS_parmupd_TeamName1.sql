











/*
--------------------------------------------------------------------------------------------------------------------------------------
Name: spLocal_STLS_parmupd_TeamName
Purpose: Update the team name.
--------------------------------------------------------------------------------------------------------------------------------------
Build #8
Modified by Vinayak Pate
Date 11-Feb-2008
Change: Maintain Proficy Standards by Removing T ransactions, l ocks
--------------------------------------------------------------------------------------------------------------------------------------
Date: 11/12/2001
*/
CREATE  PROCEDURE spLocal_STLS_parmupd_TeamName1
	--parameters
	@ReplaceAllFlag VARCHAR(20),
	@ReplaceTeam	VARCHAR(10),
	@WithReplacementTeam VARCHAR(10),
	@EffectiveDate DATETIME,
	@InScheduleFlag VARCHAR(20)
AS

/*
This procedure is used when updating a team name.  If the name already has been applied in the
schedule, the team name must be updated in the schedule (all instances, or based on
an effective date) and in patterns.  Otherwise, the team name only needs to be updated in
patterns.
*/


--Make sure that the new name has not been already used
SELECT * 
FROM Local_PG_Teams
WHERE TeamName = @WithReplacementTeam

IF @@ROWCOUNT > 0 
	BEGIN
	RETURN 1
	END
ELSE
	BEGIN
	IF @InScheduleFlag = "NotInSchedule"
		BEGIN
		--Update Teams
		UPDATE Local_PG_Teams
			SET TeamName = @WithReplacementTeam
			WHERE TeamName = @ReplaceTeam
		END
	
	ELSE
  		BEGIN
		--If used in schedule


		IF @ReplaceAllFlag = 'ReplaceAll'
			BEGIN	
		--Update all records with this team in the schedule
			UPDATE Crew_Schedule
			SET Crew_Desc = @WithReplacementTeam
			WHERE Crew_Desc = @ReplaceTeam

		--Update Teams
			UPDATE Local_PG_Teams
			SET TeamName = @WithReplacementTeam
			WHERE TeamName = @ReplaceTeam
			END

		ELSE
			BEGIN
			UPDATE Crew_Schedule
			SET Crew_Desc = @WithReplacementTeam
			WHERE Crew_Desc = @ReplaceTeam
			AND Start_Time >= @EffectiveDate
		--Update Teams
			UPDATE Local_PG_Teams
			SET TeamName = @WithReplacementTeam
			WHERE TeamName = @ReplaceTeam
			END
  		END
	End
--Error Check
IF @@ERROR > 0
	BEGIN
	RAISERROR('Update Team Name Failed.', 16, 1)
	RETURN 99
	END


RETURN 0



