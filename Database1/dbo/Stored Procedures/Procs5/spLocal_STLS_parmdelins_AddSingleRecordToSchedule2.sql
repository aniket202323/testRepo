/*
Name: spLocal_STLS_parmdelins_AddSingleRecordToSchedule2
Old Name: spLocal_STLS_parmdelins_AddSingleRecordToSchedule1
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
--------------------------------------------------------------------
Modified by Vinayak Pate on June 8, 2006
1) Allow new shift to added if shift number 4 exists.
---------------------------------------------------------------------
Modified By : Kapadia.r on 19-Dec-2005
Purpose: To allow user to enter shift number.(STLS change UID-2)
-----------------------------------------------------------
Purpose: Delete overlapping records within the schedule and add a single record.
Date: 11/12/2001
---------------------------------------------------------
*/

CREATE         PROCEDURE [dbo].[spLocal_STLS_parmdelins_AddSingleRecordToSchedule2]

	--Parameters
	 @StartTime DATETIME,
	 @EndTime DATETIME,
	 @Team VARCHAR(10),
	 @UnitDesc VARCHAR(50),
	 @Shift VARCHAR(2),
	 @vcDeletions VARCHAR(8000)

---------------------------
--Test
--SET @Team = 'TeamJoe2'
--SET @UnitDesc = 'CR15AW Converter'
--SET @StartTime = 'Jan 1 2001 04:00'
--SET @EndTime = 'Jan 1 2001 04:10'
---------------------------
AS
SET NOCOUNT ON  

DECLARE	 @MasterUnitId INT	-- Vinayak Follower Logic

-- Get Followers List
SET @MasterUnitId = (Select DISTINCT pu_id From PROD_UNITS Where PU_DESC = @UnitDesc )

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


--Delete Overlapping Records
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



