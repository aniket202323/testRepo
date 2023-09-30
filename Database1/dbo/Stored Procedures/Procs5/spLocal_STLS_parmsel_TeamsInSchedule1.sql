










/*
---------------------------------------------------------------------------
Name:	spLocal_STLS_parmsel_Local_PG_TeamsInSchedule1
Purpose: Given Team ID, find out if team was used in the crew schedule
Date: 11/12/2001
---------------------------------------------------------------------------
Build #8 No Change
---------------------------------------------------------------------------
*/

CREATE PROCEDURE spLocal_STLS_parmsel_TeamsInSchedule1
	--parameters
	@TeamID INT
AS


SELECT  DISTINCT *
FROM Crew_Schedule

Join Local_PG_Teams ON Crew_Schedule.Crew_Desc = Local_PG_Teams.TeamName 
Where Local_PG_Teams.TeamID = @TeamID 

--Error Check
IF @@ERROR > 0
	BEGIN
	RAISERROR('Selection of Local_PG_Teams in Schedule failed.', 16, 1)
	RETURN 99
	END

RETURN 0











