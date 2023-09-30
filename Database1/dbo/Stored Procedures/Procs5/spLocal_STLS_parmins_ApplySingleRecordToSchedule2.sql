/*
Name: spLocal_STLS_parmins_ApplySingleRecordToSchedule2
Old Name: spLocal_STLS_parmins_ApplySingleRecordToSchedule1
---------------------------------------------------------------------------------------------------------------------------------------  
Modified by Allen Duncan
Date: 31 Jan 2012
Change: Changed follower code to use joins to work with new Proficy V5.X db 
change for Table_Fields Table requierment of table_id for UDPs
Version: 1.2
-----------------------------------------------------------
Build#8
Modified by : Vinayak Pate on Jan 31, 2008
Follower units to have schedule as Master
maintain proficy standards be removing t ransactions and l ocks
-----------------------------------------------------------
Modified by : Vinayak Pate on June 9, 2006
1) To allow new shift addition if shift number 4 exists
2) To get CS_ID of overlap by shift number on the same day because every Start Day their shall be unique shift numbers
---------------------------------------------------------
Modified By : Kapadia.r on 19-Dec-2005
Purpose: To allow user to enter shift number.(STLS change UID-2)
---------------------------------------------------------
Purpose: Apply a single record to the crew schedule.
Date: 11/12/2001
---------------------------------------------------------------
*/


CREATE  PROCEDURE [dbo].[spLocal_STLS_parmins_ApplySingleRecordToSchedule2]

	--Parameters
	 @Team VARCHAR(10),
	 @UnitDesc VARCHAR(50),
	 @StartTime DATETIME,
	 @EndTime DATETIME,
	 @Shift VARCHAR(2)
---------------------------
--Test
--SET @Team = 'D'
--SET @UnitDesc = 'DICB004 Converter'
--SET @StartTime = 'Dec 24 2007 06:00'
--SET @EndTime = 'Dec 24 2007 15:00'
--SET Shift = '3'
---------------------------
AS

--Local Variables
DECLARE	 @MasterUnitId INT	-- Vinayak Follower Logic


--Get Master Unit ID
	SET @MasterUnitId = (SELECT Distinct PU_Id FROM Prod_Units WHERE PU_Desc = @UnitDesc)

--Test for Overlapping Records of Master Unit Only
	SELECT Distinct CS_Id
	FROM Crew_Schedule
	WHERE 	
(		((Crew_Schedule.Start_Time >= @StartTime
			AND Crew_Schedule.Start_Time <  @EndTime)
		OR
		(Crew_Schedule.End_Time >  @StartTime
			AND Crew_Schedule.End_Time <=  @EndTime)
		OR
		(Crew_Schedule.End_Time >=  @EndTime
			AND Crew_Schedule.Start_Time <= @StartTime)
		)
		AND
		PU_Id = @MasterUnitId 
)
OR
(		DAY(Crew_Schedule.Start_Time) = DAY(@StartTime)
			AND	MONTH(Crew_Schedule.Start_Time) = MONTH(@StartTime)
			AND	YEAR(Crew_Schedule.Start_Time) = YEAR(@StartTime)
			AND	Crew_Schedule.Shift_Desc = @Shift
			AND	Crew_Schedule.PU_Id = @MasterUnitId 
)


--If Rowcount > 0, overlapping records exist with Master.  Return 1 and exit.
	IF @@ROWCOUNT > 0
		BEGIN
		RETURN 1
		END

-- Get Followers List
DECLARE @MyTableVar TABLE (FU_ID integer)	-- This stores the unit id's of follower units
	INSERT INTO @MyTableVar 
		 SELECT PU.PU_Id
         FROM Tables AS T INNER JOIN Table_Fields_Values AS TFV ON T.TableId = TFV.TableId 
              INNER JOIN Table_Fields AS TF ON TFV.Table_Field_Id = TF.Table_Field_Id INNER JOIN
              Prod_Units AS PU ON TFV.KeyId = PU.PU_Id INNER JOIN Prod_Units AS PU_1 ON TFV.Value
               = CAST(PU_1.PU_Id as varchar)
         WHERE (T.TableName = 'Prod_Units') AND (TF.Table_Field_Desc = 'STLS_ST_MASTER_UNIT_ID') 
                AND (PU_1.PU_Id = @MasterUnitId)
-- Follower List available


--Delete Overlapping Records of follower units only (because master does not have overlapping records)
-- Follower module 
	DELETE	FROM Crew_Schedule
	WHERE
	(		(
				(Crew_Schedule.Start_Time >= @StartTime
					AND Crew_Schedule.Start_Time <  @EndTime)
				OR
				(Crew_Schedule.End_Time >  @StartTime
					AND Crew_Schedule.End_Time <=  @EndTime)
				OR
				(Crew_Schedule.End_Time >=  @EndTime
					AND Crew_Schedule.Start_Time <= @StartTime)
			)
			AND	Crew_Schedule.PU_Id IN (select FU_ID from @MyTableVar)
	)
	OR
	(		DAY(Crew_Schedule.Start_Time) = DAY(@StartTime)
				AND	MONTH(Crew_Schedule.Start_Time) = MONTH(@StartTime)
				AND	YEAR(Crew_Schedule.Start_Time) = YEAR(@StartTime)
				AND	Crew_Schedule.Shift_Desc = @Shift
				AND	Crew_Schedule.PU_Id IN (select FU_ID from @MyTableVar)
	)
-- module end

	IF @@ERROR > 0
			BEGIN
			RAISERROR('Insert Record to Shedule failed (1).', 16, 1)
			RETURN 99
			END

-- Added below Follower module for follower units by vinayak 
	INSERT INTO Crew_Schedule (Start_Time, End_Time, PU_Id, Crew_Desc, Shift_Desc)
	SELECT @StartTime, @EndTime, FU_Id, @Team, @Shift
	FROM @MyTableVar

	IF @@ERROR > 0
			BEGIN
			RAISERROR('Insert Record to Shedule failed (2).', 16, 1)
			RETURN 99
			END
	

RETURN 0


