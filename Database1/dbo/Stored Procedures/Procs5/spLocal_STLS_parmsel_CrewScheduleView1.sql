











/*
--------------------------------------------------------------
Name: spLocal_STLS_parmsel_CrewScheduleView1
Purpose: View the crew schedule given a line and timeframe.
--------------------------------------------------------------
Build #8
Modified by Vinayak Pate
Date 05-Feb-2008
Change: maintain proficy standards be removing t ransactions and l ocks
--------------------------------------------------------------
Date: 11/12/2001
--------------------------------------------------------------
*/

CREATE  PROCEDURE spLocal_STLS_parmsel_CrewScheduleView1
	--parameters
	 @StartDate DateTime,
	 @EndDate DateTime,
	 @UnitDesc VARCHAR(50)
AS

DECLARE @UnitID INT


	
	--1.  Get Unit ID
	SET @UnitID = (SELECT Prod_Units.PU_Id
		FROM Prod_Units
		WHERE PU_Desc = @UnitDesc)

	--2.  Select Records from Schedule
	SELECT  Convert(VARCHAR,Crew_Schedule.Start_Time, 113) as StartTime,
		Convert(VARCHAR,Crew_Schedule.End_Time, 113) as EndTime,
		Crew_Schedule.Crew_Desc, Crew_Schedule.Shift_Desc, Crew_Schedule.CS_Id
	FROM Crew_Schedule
	WHERE 	((Crew_Schedule.Start_Time >= @StartDate
			AND Crew_Schedule.Start_Time <= @EndDate)
		OR
		(Crew_Schedule.End_Time >= @StartDate 
			AND Crew_Schedule.End_Time <= @EndDate)
		OR
		(Crew_Schedule.End_Time >= @EndDate 
			AND Crew_Schedule.Start_Time <= @StartDate)
		)
		AND
		PU_Id = @UnitID

	ORDER BY Crew_Schedule.Start_Time
	
--Error Check
IF @@ERROR > 0
	BEGIN
	RAISERROR('View Shedule failed.', 16, 1)
	RETURN 99
	END




RETURN 0	

















