








/*
---------------------------------------------------------
Modified by Vinayak Pate
Date 05-Feb-2008
Change: maintain proficy standards be removing t ransactions and l ocks
Change: length of ID varchar
---------------------------------------------------------
Modified By : Kapadia.r on 19-Dec-2005
Purpose: To allow user to enter shift number.(STLS change UID-2)
---------------------------------------------------------
Name: spLocal_STLS_parmsel_CrewScheduleConflictView1
Purpose: View the crew schedule overlapping records given a line and timeframe.
Date: 11/12/2001
-----------------------------------------------------------
*/

CREATE      PROCEDURE spLocal_STLS_parmsel_CrewScheduleConflictView1
	--parameters
	 @StartDate DateTime,
	 @EndDate DateTime,
	 @UnitDesc VARCHAR(50),
	 @vcDeletions VARCHAR(8000)
AS

DECLARE @UnitID INT
DECLARE @nDelimitRecord INT
DECLARE @nDelimitField INT
DECLARE @vcRemainingRecord VARCHAR(8000)
DECLARE @vcCurrentRecord VARCHAR(100)
DECLARE @vcRemainingFields VARCHAR(100)
DECLARE @vcCurrentID VARCHAR(20)
DECLARE @nCurrentID INT


--temp table is created to store all comma separated vcDeletions as integer
CREATE TABLE #Temp_Array(CSID int)
SET NOCOUNT ON

IF LEN(@vcDeletions) > 0
	BEGIN
		SET @vcRemainingRecord = LTrim(RTrim(@vcDeletions))
		
		WHILE LEN(@vcRemainingRecord) > 0
		BEGIN
			SET @nDelimitRecord = CHARINDEX(",",@vcRemainingRecord,1)
			SET @vcCurrentRecord = LEFT(@vcRemainingRecord,(@nDelimitRecord - 1))
			SET @vcRemainingRecord = RIGHT(@vcRemainingRecord,(LEN(@vcRemainingRecord) - @nDelimitRecord))
			INSERT INTO #Temp_Array VALUES (@vcCurrentRecord)		
		END
	END
ELSE
	BEGIN
	SET @vcDeletions = '0'
	END



	
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
			AND Crew_Schedule.Start_Time <  @EndDate)
		OR
		(Crew_Schedule.End_Time >  @StartDate
			AND Crew_Schedule.End_Time <=  @EndDate)
		OR
		(Crew_Schedule.End_Time >=  @EndDate
			AND Crew_Schedule.Start_Time <= @StartDate)
		OR
		(CS_ID in (SELECT CSID from #Temp_Array))
		)
		AND
		PU_Id = @UnitID
	
--Error Check
IF @@ERROR > 0
	BEGIN
	RAISERROR('View Shedule failed.', 16, 1)
	RETURN 99
	END


DROP TABLE #temp_Array

RETURN 0	





















