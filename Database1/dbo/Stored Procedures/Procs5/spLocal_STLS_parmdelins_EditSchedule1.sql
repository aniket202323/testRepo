/*
Name: spLocal_STLS_parmdelins_EditSchedule1
---------------------------------------------------------------------------------------------------------------------------------------  
Modified by Allen Duncan
Date: 31 Jan 2012
Change: Changed follower code to use joins to work with new Proficy V5.X db 
change for Table_Fields Table requierment of table_id for UDPs
Version: 1.2
--------------------------------------------------------------------------------------------------------------------------------------
Build #8
Modified by Vinayak Pate
Date 05-FEB-2008
Change: Replace schedules of follower units also along with Master
maintain proficy standards be removing t ransactions and l ocks
--------------------------------------------------------------------------------------------------------------------------------------
Date: 11/12/2001
---------------------------------------------------------------------------------------------------------------------------------------
*/

CREATE    PROCEDURE [dbo].[spLocal_STLS_parmdelins_EditSchedule1]

	--Parameters
	 @EditAll VARCHAR(8000),
	 @UnitDesc VARCHAR(50)
---------------------------
--Test
--SET @EditAll = '5486,Jan 2 2001 04:00,Jan 2 2001 08:00,TeamJoe6;5487,Jan 2 2001 08:00,Jan 2 2001 12:00,TeamJoe5;'
--SET @UnitDesc = 'CR15AW Converter'
---------------------------
AS
SET NOCOUNT ON
--Local Variables
--DECLARE @nUnitID INT
DECLARE @nDelimitRecord INT
DECLARE @nDelimitField INT
DECLARE @vcRemainingRecord VARCHAR(8000)
DECLARE @vcCurrentRecord VARCHAR(100)
DECLARE @vcRemainingFields VARCHAR(100)
DECLARE @vcCurrentID VARCHAR(20)
DECLARE @nCurrentID INT

DECLARE @vcCurrentStartTime VARCHAR(35)
DECLARE @vcCurrentEndTime VARCHAR(35)
DECLARE @vcCurrentTeam VARCHAR(10)
DECLARE @vcCurrentShift VARCHAR(5)

DECLARE @nScheduleID1 INT
DECLARE @nScheduleID2 INT
DECLARE @nScheduleID3 INT
DECLARE @nScheduleID4 INT
DECLARE @vcShiftCount VARCHAR(10)
DECLARE @dtCompareStartTime DATETIME
DECLARE @nPreviousShiftFlag INT

DECLARE  @nCSId AS INTEGER	-- Vinayak Follower Logic
DECLARE	 @StartTime DATETIME	-- Vinayak Follower Logic
DECLARE	 @LastStartTime DATETIME	-- Vinayak Follower Logic
DECLARE	 @EndTime DATETIME	-- Vinayak Follower Logic
DECLARE	 @MasterUnitId INT	-- Vinayak Follower Logic
DECLARE	 @Shift VARCHAR(2)	-- Vinayak Follower Logic

-- Get Follower List
SET @MasterUnitId = (Select pu_id From PROD_UNITS Where PU_DESC = @UnitDesc )

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

-- Get Schedule Id List (Master only)
	DECLARE @MyCSIDTableVar TABLE (CS_ID integer)	-- This stores the unit id's of follower units

	SET @vcRemainingRecord = @EditAll

	WHILE LEN(@vcRemainingRecord) > 0
	BEGIN
		SET @nDelimitRecord = CHARINDEX(";",@vcRemainingRecord,1)
		SET @vcCurrentRecord = LEFT(@vcRemainingRecord,(@nDelimitRecord - 1))
		SET @vcRemainingRecord = RIGHT(@vcRemainingRecord,(LEN(@vcRemainingRecord) - @nDelimitRecord))
		
		SET @nDelimitField = CHARINDEX(",",@vcCurrentRecord,1)
		SET @vcCurrentID = LEFT(@vcCurrentRecord,(@nDelimitField - 1))

		SET @nCSId = CAST(@vcCurrentID AS INT)	

		INSERT INTO @MyCSIDTableVar (CS_ID)
		VALUES (@nCSId)
	END -- Loop
-- Schedule Id list available


-- Get StartTime, LastStartTime, EndTime, FirstDayShifts, LastDayShifts of revised schedule (Master only)
	DECLARE @MyFirstDayShiftsTableVar TABLE (Shift varchar(2))	-- This stores new shifts requested on start day
	DECLARE @MyLastDayShiftsTableVar TABLE (Shift varchar(2))	-- This stores new shifts requested on end day

	SET @vcRemainingRecord = @EditAll

	WHILE LEN(@vcRemainingRecord) > 0
	BEGIN
		SET @nDelimitRecord = CHARINDEX(";",@vcRemainingRecord,1)
		SET @vcCurrentRecord = LEFT(@vcRemainingRecord,(@nDelimitRecord - 1))
		SET @vcRemainingRecord = RIGHT(@vcRemainingRecord,(LEN(@vcRemainingRecord) - @nDelimitRecord))
		
		SET  @vcRemainingFields = @vcCurrentRecord 
		
		--Get ID
		SET @nDelimitField = CHARINDEX(",",@vcRemainingFields,1)
		SET @vcCurrentID = LEFT(@vcRemainingFields,(@nDelimitField - 1))
		SET @vcRemainingFields = RIGHT(@vcRemainingFields,(LEN(@vcRemainingFields) - @nDelimitField))
		SET @nCurrentID = CAST(@vcCurrentID AS INT)

		--Get Start Time
		SET @nDelimitField = CHARINDEX(",",@vcRemainingFields,1)
		SET @vcCurrentStartTime = LEFT(@vcRemainingFields,(@nDelimitField - 1))
		SET @vcRemainingFields = RIGHT(@vcRemainingFields,(LEN(@vcRemainingFields) - @nDelimitField))

			-- positioned V1
		If @StartTime IS NULL		-- record first start time of revised schedule
			BEGIN
			SET @StartTime = CAST(@vcCurrentStartTime as DATETIME)  
			SET @LastStartTime = CAST(@vcCurrentStartTime as DATETIME)  
			END

			-- positioned V2
		IF DAY(@LastStartTime) != DAY(CAST(@vcCurrentStartTime as DATETIME))
			BEGIN
			DELETE FROM @MyLastDayShiftsTableVar	-- delete stored shifts of days before last day
			END

			-- positioned V3
		SET @LastStartTime = CAST(@vcCurrentStartTime as DATETIME)  -- record last start time of revised schedule

		
		--Get End Time
		SET @nDelimitField = CHARINDEX(",",@vcRemainingFields,1)
		SET @vcCurrentEndTime = LEFT(@vcRemainingFields,(@nDelimitField - 1))
		SET @vcRemainingFields = RIGHT(@vcRemainingFields,(LEN(@vcRemainingFields) - @nDelimitField))

		SET @EndTime = CAST(@vcCurrentEndTime as DATETIME)  -- record last end time of revised schedule


		--Get Teams
		SET @nDelimitField = CHARINDEX(",",@vcRemainingFields,1)
		SET @vcCurrentTeam = LEFT(@vcRemainingFields,(@nDelimitField - 1))
		SET @vcRemainingFields = RIGHT(@vcRemainingFields,(LEN(@vcRemainingFields) - @nDelimitField))

		--Get Shifts
		SET @vcCurrentShift = @vcRemainingFields
		SET @vcRemainingFields =''

			-- positioned V4
		IF DAY(@StartTime) = DAY(CAST(@vcCurrentStartTime as DATETIME))
			BEGIN
			INSERT INTO @MyFirstDayShiftsTableVar(Shift)	-- Store shifts of first day 
			VALUES (@vcCurrentShift)
			END

			-- positioned V5
		INSERT INTO @MyLastDayShiftsTableVar(Shift)		-- Store shifts of last day (positioned V2 deletes previous days shifts)
		VALUES (@vcCurrentShift)

	END -- Loop

--Test for Overlapping Records (New records shall not overlapp with existing records, other than those being edited)
		SELECT CS_Id
		FROM Crew_Schedule
		WHERE 	
		(	(Crew_Schedule.Start_Time >= @StartTime
				AND Crew_Schedule.Start_Time < @EndTime)
			AND PU_Id = @MasterUnitId
			AND CS_Id NOT IN (Select Distinct CS_ID from @MyCSIDTableVar)
		)
		OR
		(	(Crew_Schedule.End_Time >  @StartTime
				AND Crew_Schedule.End_Time <= @EndTime)
			AND PU_Id = @MasterUnitId
			AND CS_Id NOT IN (Select Distinct CS_ID from @MyCSIDTableVar)
		)
		OR
		(
			(Crew_Schedule.End_Time >=  @EndTime
				AND Crew_Schedule.Start_Time <= @StartTime)
			AND PU_Id = @MasterUnitId
			AND CS_Id NOT IN (Select Distinct CS_ID from @MyCSIDTableVar)
		)
		OR
		(	DAY(Crew_Schedule.Start_Time) = DAY(@StartTime)
			AND	MONTH(Crew_Schedule.Start_Time) = MONTH(@StartTime)
			AND	YEAR(Crew_Schedule.Start_Time) = YEAR(@StartTime)
			AND	Crew_Schedule.Shift_Desc IN (Select Distinct Shift from @MyFirstDayShiftsTableVar)
			AND PU_Id = @MasterUnitId
			AND CS_Id NOT IN (Select Distinct CS_ID from @MyCSIDTableVar)
		)
		OR
		(	DAY(Crew_Schedule.Start_Time) = DAY(@LastStartTime)
			AND	MONTH(Crew_Schedule.Start_Time) = MONTH(@LastStartTime)
			AND	YEAR(Crew_Schedule.Start_Time) = YEAR(@LastStartTime)
			AND	Crew_Schedule.Shift_Desc IN (Select Distinct Shift from @MyLastDayShiftsTableVar)
			AND PU_Id = @MasterUnitId
			AND CS_Id NOT IN (Select Distinct CS_ID from @MyCSIDTableVar)
		)

--If Rowcount > 0, overlapping records exist.  Return 1 and exit.
		IF @@ROWCOUNT > 0
		BEGIN
		RETURN 1
		END


-- Delete Follower and Master crew scheduele for the given period 
	DELETE	FROM Crew_Schedule
		WHERE 	
		(	(Crew_Schedule.Start_Time >= @StartTime
				AND Crew_Schedule.Start_Time < @EndTime)
				AND	Crew_Schedule.PU_Id IN (select FU_ID from @MyTableVar)
		)
		OR
		(	(Crew_Schedule.End_Time >  @StartTime
				AND Crew_Schedule.End_Time <= @EndTime)
				AND	Crew_Schedule.PU_Id IN (select FU_ID from @MyTableVar)
		)
		OR
		(
			(Crew_Schedule.End_Time >=  @EndTime
				AND Crew_Schedule.Start_Time <= @StartTime)
				AND	Crew_Schedule.PU_Id IN (select FU_ID from @MyTableVar)
		)
		OR
		(	DAY(Crew_Schedule.Start_Time) = DAY(@StartTime)
			AND	MONTH(Crew_Schedule.Start_Time) = MONTH(@StartTime)
			AND	YEAR(Crew_Schedule.Start_Time) = YEAR(@StartTime)
			AND	Crew_Schedule.Shift_Desc IN (Select Distinct Shift from @MyFirstDayShiftsTableVar)
			AND	Crew_Schedule.PU_Id IN (select FU_ID from @MyTableVar)
		)
		OR
		(	DAY(Crew_Schedule.Start_Time) = DAY(@LastStartTime)
			AND	MONTH(Crew_Schedule.Start_Time) = MONTH(@LastStartTime)
			AND	YEAR(Crew_Schedule.Start_Time) = YEAR(@LastStartTime)
			AND	Crew_Schedule.Shift_Desc IN (Select Distinct Shift from @MyLastDayShiftsTableVar)
			AND	Crew_Schedule.PU_Id IN (select FU_ID from @MyTableVar)
		)


	--INSERT EDITED RECORDS
	SET @vcRemainingRecord = @EditAll

	WHILE LEN(@vcRemainingRecord) > 0
	BEGIN
		SET @nDelimitRecord = CHARINDEX(";",@vcRemainingRecord,1)
		SET @vcCurrentRecord = LEFT(@vcRemainingRecord,(@nDelimitRecord - 1))
		SET @vcRemainingRecord = RIGHT(@vcRemainingRecord,(LEN(@vcRemainingRecord) - @nDelimitRecord))
		
		SET  @vcRemainingFields = @vcCurrentRecord 
		
		--Get ID
		SET @nDelimitField = CHARINDEX(",",@vcRemainingFields,1)
		SET @vcCurrentID = LEFT(@vcRemainingFields,(@nDelimitField - 1))
		SET @vcRemainingFields = RIGHT(@vcRemainingFields,(LEN(@vcRemainingFields) - @nDelimitField))
		SET @nCurrentID = CAST(@vcCurrentID AS INT)

		--Get Start Time
		SET @nDelimitField = CHARINDEX(",",@vcRemainingFields,1)
		SET @vcCurrentStartTime = LEFT(@vcRemainingFields,(@nDelimitField - 1))
		SET @vcRemainingFields = RIGHT(@vcRemainingFields,(LEN(@vcRemainingFields) - @nDelimitField))
		--Get End Time
		SET @nDelimitField = CHARINDEX(",",@vcRemainingFields,1)
		SET @vcCurrentEndTime = LEFT(@vcRemainingFields,(@nDelimitField - 1))
		SET @vcRemainingFields = RIGHT(@vcRemainingFields,(LEN(@vcRemainingFields) - @nDelimitField))

		--Get Teams
		SET @nDelimitField = CHARINDEX(",",@vcRemainingFields,1)
		SET @vcCurrentTeam = LEFT(@vcRemainingFields,(@nDelimitField - 1))
		SET @vcRemainingFields = RIGHT(@vcRemainingFields,(LEN(@vcRemainingFields) - @nDelimitField))
		--Get Shifts
		SET @vcCurrentShift = @vcRemainingFields
		SET @vcRemainingFields =''
	
	INSERT INTO	Crew_Schedule(Start_Time,End_Time,PU_Id,Crew_Desc,Shift_Desc)
		SELECT	@vcCurrentStartTime,@vcCurrentEndTime,FU_ID,@vcCurrentTeam,@vcCurrentShift
		FROM @MyTableVar

	END -- loop
	
	
	IF @@ERROR > 0
			BEGIN
			RAISERROR('Edit Shedule failed (1).', 16, 1)
			RETURN 99
			END




RETURN 0
	



