/*
Name: spLocal_STLS_parmupd_UpdateLineStatus2Test
OldName: spLocal_STLS_parmupd_UpdateLineStatus1
Purpose: Given time, unit, schedule ID, and status, updates the line status of the schedule.
---------------------------------------------------------------------------------------------------------------------------------------  
Modified by:	Max Jacob
Date:			2019-05-17
Change:			End time can now be specified instead of calculated automatically
				Returning different error codes depending on what check fais
				Refactoring
Version:		1.3
--------------------------------------------------------------------------------------------------------------------------------------
Modified by Allen Duncan
Date: 31 Jan 2012
Change: Changed follower code to use joins to work with new Proficy V5.X db 
change for Table_Fields Table requierment of table_id for UDPs
Version: 1.2
--------------------------------------------------------------------------------------------------------------------------------------
Build #8
Modified by Vinayak Pate
Date 11-Feb-2008
Change: Added follower Unit Functionality
--------------------------------------------------------------------------------------------------------------------------------------
Modified by Vinayak Pate
On 28-Jun-06			
Change : 	Added Comment to Store
On 17-Jul-06			
Change : 	Added OldStartDate to avoid overwriting beyond range
---------------------------------------------------------------------------------------------------------------------------------------
Modified by Debbie Linville
On 16-Jan-03			Version 2.0.0
Change : 	Add End_DateTime to update
---------------------------------------------------------------------------------------------------------------------------------------
Date: 11/12/2001
---------------------------------------------------------------------------------------------------------------------------------------
*/
CREATE PROCEDURE [dbo].[spLocal_STLS_parmupd_UpdateLineStatus2Test]
	@StartDate		DATETIME,
	@UnitDesc		VARCHAR(50),
	@ScheduleID		INT,
	@StatusPhrase	VARCHAR(50),
 	@UserName		VARCHAR(50),
 	@Comment		NVARCHAR(500),
	@EndTime		DATETIME
AS
---------------------------------------------------------------------------------------------------------------------------------------
-- Declare variables
---------------------------------------------------------------------------------------------------------------------------------------
DECLARE
@LineStatusDescID			INT,
@MasterUnitID				INT,
@OrigStartDate				DATETIME,
@OrigEndDate				DATETIME,
@OrigLineStatusID			INT,
@OrigLineStatusIsPrOut		BIT,
@UserID						INT,
@EnteredOn					DATETIME,
@EndDateTime				DATETIME,
@MinDateTime				DATETIME,
@MaxDateTime				DATETIME,
@OldStartDate				DATETIME,
@OldEndDate					DATETIME,
@PriorLineStatusID			INT,
@PriorLineStatusIsPrOut		BIT,
@PriorLineStatusEndTime		DATETIME,
@NextLineStatusID			INT,
@NextLineStatusIdPrOut		BIT,
@NextLineStatusStartTime	DATETIME,
@Follower_ScheduleID		INT,
@Vincount					INT,
@VinUnitId					INT

DECLARE
@PR_OUT_PHRASE	VARCHAR(20) = 'pr out:'

DECLARE	@ProductionUnits TABLE
(
	PuId	INTEGER
)

SET @MasterUnitID	= NULL
SET @OldStartDate	= NULL

SELECT	@MasterUnitID	= Unit_Id,
		@OldStartDate	= Start_DateTime
FROM	dbo.Local_PG_Line_Status
WHERE	Status_Schedule_Id = @ScheduleID

-- if line status not there that means it must have been deleted by another user
IF @OldStartDate Is Null
BEGIN
	SELECT	@ScheduleID	[Status_Schedule_Id],
			NULL		[Min_DateTime],
			NULL		[Max_DateTime]

	RETURN 1 -- Line status doesn’t exist
END
--	Get old line status info
SET @OldEndDate		= NULL
SET @MaxDateTime	= NULL

SELECT	@OldEndDate		= End_DateTime,
		@MaxDateTime	= End_DateTime
FROM	dbo.Local_PG_Line_Status
WHERE	Unit_Id				= @MasterUnitID
AND		Status_Schedule_Id	= @ScheduleID
-- Get previous line status info
SET @MinDateTime			= NULL
SET @PriorLineStatusID		= NULL
SET	@PriorLineStatusEndTime	= NULL
SET	@PriorLineStatusIsPrOut	= NULL

SELECT	TOP 1
		@MinDateTime			=	lsn.Start_DateTime,
		@PriorLineStatusEndTime =	lsn.End_DateTime,
		@PriorLineStatusID		=	lsn.Line_Status_Id,
		@PriorLineStatusIsPrOut =	CASE
										WHEN CHARINDEX(@PR_OUT_PHRASE, p.Phrase_Value) > 0
											THEN	1
										ELSE
											0
									END
FROM	dbo.Local_PG_Line_Status	lsn
														
JOIN	dbo.Phrase					p	WITH(NOLOCK)	ON	lsn.Line_Status_Id			=	p.Phrase_Id
WHERE	UPPER(lsn.Update_Status)	!=	'DELETE'
AND		lsn.Unit_Id				=	@MasterUnitID
AND		lsn.Start_DateTime		<	@OldStartDate
AND		lsn.Status_Schedule_Id	!=	@ScheduleID
ORDER
BY		lsn.Start_DateTime	DESC

-- Get next line status info
SET @NextLineStatusIdPrOut		= NULL
SET	@NextLineStatusID			= NULL
SET @NextLineStatusStartTime	= NULL

SELECT	TOP 1
		@NextLineStatusStartTime	=	lsn.Start_DateTime,
		@NextLineStatusID			=	lsn.Line_Status_Id,
		@NextLineStatusIdPrOut		=	CASE
											WHEN CHARINDEX(@PR_OUT_PHRASE, p.Phrase_Value) > 0
												THEN	1
											ELSE
												0
										END
FROM	dbo.Local_PG_Line_Status	lsn
JOIN	dbo.Phrase					p	WITH(NOLOCK)	ON	lsn.Line_Status_Id			=	p.Phrase_Id
WHERE	lsn.Unit_Id					=	@MasterUnitID
AND		UPPER(lsn.Update_Status)	!=	'DELETE'
AND		lsn.Start_DateTime			>	@OldStartDate
ORDER
BY		lsn.Start_DateTime	ASC

-- Get new line status desc ID
SET @LineStatusDescID =	(
							SELECT	p.Phrase_Id
							FROM	Phrase		p	WITH(NOLOCK)
							JOIN	Data_Type	dt	WITH(NOLOCK)	ON p.Data_Type_Id = dt.Data_Type_Id
							WHERE	p.Phrase_Value = @StatusPhrase	
							AND		dt.Data_Type_Desc = 'Line Status'
						)
-- cancel edit operation if modified start datetime is out of the min,max validation range
-- cancel edit operation if line status same as of prior or next row
IF	(	
		@MinDateTime	IS	NOT NULL
	AND	@StartDate		<=	@MinDateTime
	)
OR	(	
		@MaxDateTime	IS	NOT NULL
	AND	@StartDate		>= @MaxDateTime
	)
BEGIN
	SELECT	@ScheduleID			[Status_Schedule_Id],
			@MinDateTime		[Min_DateTime],
			@MaxDateTime		[Max_DateTime],
			@PriorLineStatusID	[Prior_LineStatusID],
			@NextLineStatusID	[Next_LineStatusID]

	RETURN 2 -- Line status must be between ${Min_DateTime} and ${Max_DateTime}
END

IF	(
		@PriorLineStatusID	IS	NOT NULL
	AND	@LineStatusDescID	=	@PriorLineStatusID
	)
OR	(
		@NextLineStatusID	IS	NOT NULL
	AND @LineStatusDescID	=	@NextLineStatusID
	)
BEGIN
	SELECT	@ScheduleID			[Status_Schedule_Id],
			@MinDateTime		[Min_DateTime],
			@MaxDateTime		[Max_DateTime],
			@PriorLineStatusID	[Prior_LineStatusID],
			@NextLineStatusID	[Next_LineStatusID]

	RETURN 3 -- Line status schedule can’t have the same status as the previous or next schedule
END

SET @OrigStartDate		= NULL
SET	@OrigEndDate		= NULL
SET @OrigLineStatusID	= NULL

SELECT	@OrigStartDate		= Start_DateTime,
		@OrigEndDate		= End_DateTime,
		@OrigLineStatusID	= Line_Status_ID
FROM	dbo.Local_PG_Line_Status
WHERE	Status_Schedule_Id = @ScheduleID

-- Added below Follower module for follower units 
	-- Get Follower List
INSERT INTO @ProductionUnits
(
	PuId
)
SELECT	PU.PU_Id
FROM	[Tables]			t
JOIN	Table_Fields_Values tfv	WITH(NOLOCK)	ON t.TableId			= tfv.TableId 
JOIN	Table_Fields		tf	WITH(NOLOCK)	ON tfv.Table_Field_Id	= tf.Table_Field_Id
JOIN	Prod_Units_Base		pu	WITH(NOLOCK)	ON tfv.KeyId			= pu.PU_Id
JOIN	Prod_Units_Base		pu1 WITH(NOLOCK)	ON tfv.[Value]			= CAST(pu1.PU_Id AS VARCHAR)
WHERE	t.TableName			= 'Prod_Units'
AND		tf.Table_Field_Desc = 'STLS_LS_MASTER_UNIT_ID'
AND		pu1.PU_Id			= @MasterUnitId

SET @VinCount	=	(
						SELECT	COUNT(1)
						FROM	@ProductionUnits
					)
SET @VinUnitId	=	(
						SELECT	MAX(PuId)
						FROM	@ProductionUnits
					)

WHILE @VinCount > 0
BEGIN

	SELECT	Status_Schedule_ID ,
	@OrigStartDate,
	@OrigEndDate
									FROM	dbo.Local_PG_Line_Status
									WHERE 	Start_DateTime	= @OrigStartDate
									AND		( 
												End_DateTime = @OrigEndDate
											OR
												End_DateTime + @OrigEndDate IS NULL
											)
									AND		Line_Status_ID		=	@OrigLineStatusID
									AND 	Unit_Id				=	@VinUnitId

	-- Get Follower Status_Schedule_Id to EDIT
	SET	@Follower_ScheduleID =	(
									SELECT	Status_Schedule_ID 
									FROM	dbo.Local_PG_Line_Status
									WHERE 	Start_DateTime	= @OrigStartDate
									AND		( 
												End_DateTime = @OrigEndDate
											OR
												End_DateTime + @OrigEndDate IS NULL
											)
									AND		Line_Status_ID		=	@OrigLineStatusID
									AND 	Unit_Id				=	@VinUnitId
								)

	SELECT	@Follower_ScheduleID

	IF @Follower_ScheduleID > 0	-- If Follower unit record matches with record to be edited, then only edit it
	BEGIN
		-- update edited record with new start 
		UPDATE	dbo.Local_PG_Line_Status
		SET		Start_DateTime		= @StartDate,
				Line_Status_Id		= @LineStatusDescID,
				Update_Status		= 'UPDATE'
		WHERE	Status_Schedule_ID	= @Follower_ScheduleID

		IF @EndTime IS NULL
		BEGIN
			SET @EndTime =	(
								SELECT	MIN(Start_DateTime) 
								FROM	dbo.Local_PG_Line_Status 
								WHERE	Unit_Id = @VinUnitID
								AND		Start_DateTime > @StartDate
								AND		Update_Status <> 'DELETE'
							)
		END

		SELECT	@StartDate,
				@EndTime

		-- update edited record with new end
		UPDATE	dbo.Local_PG_Line_Status
		SET		End_DateTime =	@EndTime
		WHERE	Status_Schedule_ID = @Follower_ScheduleID


		SELECT	MAX(Start_DateTime)		[StartTime],
				@StartDate				[NewEndTime]
		FROM	dbo.Local_PG_Line_Status 
		WHERE	Unit_Id			=	@VinUnitID
		AND		Start_DateTime	<	@StartDate
		AND		Update_Status	<>	'DELETE'

		--      update end time on previous row before new start 
		UPDATE	dbo.Local_PG_Line_Status
		SET		End_DateTime	=	@StartDate
		WHERE	Unit_Id			=	@VinUnitID
		AND		Start_DateTime	=	(
										SELECT	MAX(Start_DateTime) 
										FROM	dbo.Local_PG_Line_Status 
										WHERE	Unit_Id			=	@VinUnitID
										AND		Start_DateTime	<	@StartDate
										AND		Update_Status	<>	'DELETE'
									)

		SELECT	MIN(Start_DateTime) [StartTime],
				@EndTime [NewStartTime]
		FROM	dbo.Local_PG_Line_Status 
		WHERE	Unit_Id			=	@VinUnitID
		AND		Start_DateTime	>=	@OldEndDate
		AND		Update_Status	<>	'DELETE'

		-- Update start time of following status
		UPDATE	dbo.Local_PG_Line_Status
		SET		Start_DateTime	=	@EndTime
		WHERE	Unit_Id			=	@VinUnitID
		AND		Start_DateTime	=	(
										SELECT	MIN(Start_DateTime) 
										FROM	dbo.Local_PG_Line_Status 
										WHERE	Unit_Id			=	@VinUnitID
										AND		Start_DateTime	>=	@OldEndDate
										AND		Update_Status	<>	'DELETE'
									)
	END

	-- loop
	SET @VinUnitId =	(
							SELECT	MAX(PuId)
							FROM	@ProductionUnits 
							WHERE	PuId < @VinUnitId
						)

	SET @VinCount = @VinCount - 1
END

SET @UserID =	(
					SELECT	[User_Id] 		
					FROM	Users_Base	WITH(NOLOCK)
					WHERE	UserName = @UserName
				)	
	
SET	@EndDateTime =	(
						SELECT	End_DateTime 		
						FROM	dbo.Local_PG_Line_Status			
						WHERE	Status_Schedule_ID = @ScheduleID
					)		

INSERT INTO dbo.Local_PG_Line_Status_Comments
(
	Status_Schedule_Id,
	[User_Id],
	Entered_On,
	Start_DateTime,
	End_DateTime,
	Line_Status_Id,
	Unit_Id,
	Comment_Text
) 
VALUES
(
	@ScheduleID,
	@UserID,
	GETDATE(),
	@StartDate,
	@EndDateTime,
	@LineStatusDescID,
	@MasterUnitID,
	@Comment
)	


SELECT	NULL	[Status_Schedule_Id],
		NULL	[Min_DateTime],
		NULL	[Max_DateTime] -- return null records to avoid sql exception message in grid

--Error Check
IF @@ERROR > 0
BEGIN
	RAISERROR('Insert of Line Shedule failed.', 16, 1)
	RETURN 99 -- Unknown error
END

RETURN 0	

