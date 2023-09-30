
/*
Name: spLocal_STLS_parmdel_CrewSchedule1
---------------------------------------------------------------------------------------------------------------------------------------  
Modified by Bala Murugan (TCS)
Date:  15 March 2012
Change: Set QUOTED_IDENTIFIER  to off
Version: 1.3
----------------------------------------------------------------------------------------------------------------------------
Modified by Allen Duncan
Date: 31 Jan 2012
Change: Changed follower code to use joins to work with new Proficy V5.X db 
change for Table_Fields Table requierment of table_id for UDPs
Version: 1.2
--------------------------------------------------------------------------------------------------------------------------------------
Build #8
Modified by Vinayak Pate
Date 31-Jan-2008
Change: Delete schedules of follower units, maintain proficy standards be removing t ransactions and l ocks
--------------------------------------------------------------------------------------------------------------------------------------
Modified by Debbie Linville
On 12-Apr-04			Version 1.0.1
Change : 	changed @strRecord to VARCHAR(6)
---------------------------------------------------------------------------------------------------------------------------------------
Date: 11/12/2001
---------------------------------------------------------------------------------------------------------------------------------------
*/

CREATE      PROCEDURE [dbo].[spLocal_STLS_parmdel_CrewSchedule1]
	--Parameters
	@vcDeletions VARCHAR(8000)
AS

--Local Variables
DECLARE @charDelimiter CHAR(1)
DECLARE @nPosition INT
DECLARE @strRecord VARCHAR(20)
DECLARE @strRemainingRecord VARCHAR(8000)

DECLARE @nCSId AS INTEGER	-- Vinayak Follower Logic
DECLARE	 @StartTime DATETIME	-- Vinayak Follower Logic
DECLARE	 @EndTime DATETIME	-- Vinayak Follower Logic
DECLARE	 @MasterUnitId INT	-- Vinayak Follower Logic
DECLARE	 @Shift VARCHAR(2)	-- Vinayak Follower Logic


SET @strRemainingRecord = @vcDeletions
SET @charDelimiter = ','

-- Get Followers List
SET @nPosition = CHARINDEX(@charDelimiter,@strRemainingRecord, 1)
SET @strRecord = LEFT(@strRemainingRecord, (@nPosition - 1))
SET @strRemainingRecord = RIGHT(@strRemainingRecord, ((LEN(@strRemainingRecord)) - @nPosition))

SET @nCSId = CAST(@strRecord AS INT)		
SET @MasterUnitId = (Select pu_id From Crew_Schedule Where CS_ID = @nCSId)

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



SET @strRemainingRecord = @vcDeletions
WHILE LEN(@strRemainingRecord) > 0
	BEGIN

	SET @nPosition = CHARINDEX(@charDelimiter,@strRemainingRecord, 1)
	SET @strRecord = LEFT(@strRemainingRecord, (@nPosition - 1))
	SET @strRemainingRecord = RIGHT(@strRemainingRecord, ((LEN(@strRemainingRecord)) - @nPosition))

-- Follower module 
	SET @nCSId = CAST(@strRecord AS INT)		
	SET @StartTime = (Select Start_Time From Crew_Schedule Where CS_ID = @nCSId)
	SET @EndTime = (Select End_Time From Crew_Schedule Where CS_ID = @nCSId)
	SET @Shift = (Select Shift_Desc From Crew_Schedule Where CS_ID = @nCSId)

-- Delete Follower crew scheduele for the given period 
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

	END


--Error Check
IF @@ERROR > 0
	BEGIN
	RAISERROR('SQL error - spLocal_STLS_parmdel_CrewSchedule1.', 16, 1)
	RETURN 99
	END


RETURN 0


