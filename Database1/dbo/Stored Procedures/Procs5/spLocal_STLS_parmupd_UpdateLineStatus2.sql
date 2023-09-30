/*
Name: spLocal_STLS_parmupd_UpdateLineStatus2
OldName: spLocal_STLS_parmupd_UpdateLineStatus1
Purpose: Given time, unit, schedule ID, and status, updates the line status of the schedule.
---------------------------------------------------------------------------------------------------------------------------------------  
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
--------------------------------------------------------------------------------------------------------------------------------------
*/
CREATE        PROCEDURE [dbo].[spLocal_STLS_parmupd_UpdateLineStatus2]
	--parameters
	 @StartDate DateTime,
	 @UnitDesc VARCHAR(50),
	 @ScheduleID INT,		--Line status_schedule_ID
	 @StatusPhrase VARCHAR(50),
 	@UserName VARCHAR(50),		--vinayak added
 	@Comment NVARCHAR(500)		--vinayak added

AS

DECLARE @LineStatusID INT
DECLARE @MasterUnitID INT

DECLARE @OrigStartDate DATETIME 

DECLARE @OrigEndDate DATETIME 		--vinayak added
DECLARE @OrigLineStatusID INT		--vinayak added

DECLARE @UserID INT			--vinayak added
DECLARE @EnteredOn DateTime		--vinayak added
DECLARE @EndDateTime DateTime		--vinayak added
DECLARE @MinDateTime DateTime		--vinayak added
DECLARE @MaxDateTime DateTime		--vinayak added
DECLARE @OldStartDate DateTime		--vinayak added
DECLARE @OldEndDate DateTime		--vinayak added
DECLARE @PriorLineStatusID INT		--vinayak added
DECLARE @NextLineStatusID INT		--vinayak added

DECLARE @Follower_ScheduleID INT	--vinayak added

	-- Get Master Unit ID 
	SET @MasterUnitID = (SELECT Unit_Id
		FROM Local_PG_Line_Status
		WHERE Status_Schedule_Id = @ScheduleID)

	-- get start date of the line status row being modified
	SET @OldStartDate = (SELECT Start_DateTime
		FROM Local_PG_Line_Status
		WHERE Unit_Id = @MasterUnitID
		AND Status_Schedule_Id = @ScheduleID)

	-- if line status not there that means it must have been deleted by another user
	IF (@OldStartDate Is Null) BEGIN
	SELECT @ScheduleID as Status_Schedule_Id , NULL as Min_DateTime, NULL as Max_DateTime
	RETURN 1
	END

	-- get end date of the line status row being modified
	SET @OldEndDate = (SELECT Local_PG_Line_Status.End_DateTime
		FROM Local_PG_Line_Status
		WHERE Unit_Id = @MasterUnitID
		AND Status_Schedule_Id = @ScheduleID)

	-- select end datetime of current record as upper limit for new start datetime
	SET @MaxDateTime = (SELECT End_DateTime
		FROM Local_PG_Line_Status
		WHERE Unit_Id = @MasterUnitID
		AND Status_Schedule_Id = @ScheduleID)

	-- select start datetime date of previous record as lower limit for new start datetime
	SET @MinDateTime = (SELECT Start_DateTime
		FROM 	Local_PG_Line_Status
		WHERE 	Unit_Id = @MasterUnitID
		AND 	End_DateTime = @OldStartDate)

	-- select status of previous record as not allowed for new status
	SET @PriorLineStatusID = (SELECT Local_PG_Line_Status.Line_Status_Id
		FROM 	Local_PG_Line_Status
		WHERE 	Unit_Id = @MasterUnitID
		AND 	End_DateTime = @OldStartDate)
 
	-- select status of next record as not allowed for new status
	SET @NextLineStatusID = (SELECT Local_PG_Line_Status.Line_Status_Id
		FROM 	Local_PG_Line_Status
		WHERE 	Unit_Id = @MasterUnitID
		AND 	Start_DateTime = @OldEndDate)


--Get Line Status ID 
	SET @LineStatusID = (SELECT Phrase.Phrase_Id
		FROM Phrase
		JOIN Data_Type ON Phrase.Data_Type_Id = Data_Type.Data_Type_Id
		WHERE	Phrase_Value = @StatusPhrase	
		AND	Data_Type.Data_Type_Desc = 'Line Status')


	-- cancel edit operation if modified start datetime is out of the min,max validation range
	-- cancel edit operation if line status same as of prior or next row
	IF	(	((@MinDateTime IS NOT NULL)  AND (@StartDate <= @MinDateTime))
			OR
			((@MaxDateTime IS NOT NULL)  AND (@StartDate >= @MaxDateTime))
			OR
			((@PriorLineStatusID IS NOT NULL)  AND ( @LineStatusID = @PriorLineStatusID ))
			OR
			((@NextLineStatusID IS NOT NULL)  AND ( @LineStatusID = @NextLineStatusID ))
		)

		BEGIN

		SELECT @ScheduleID as Status_Schedule_Id, @MinDateTime as Min_DateTime, @MaxDateTime as Max_DateTime, @PriorLineStatusID as Prior_LineStatusID,  @NextLineStatusID as Next_LineStatusID

		RETURN 1
		END


	-- capture original start date of record being edited
        SET @OrigStartDate = (SELECT Start_DateTime
			FROM Local_PG_Line_Status
			WHERE Status_Schedule_Id = @ScheduleID)

	-- capture original end date of record being edited
        SET @OrigEndDate = (SELECT End_DateTime
			FROM Local_PG_Line_Status
			WHERE Status_Schedule_Id = @ScheduleID)

	-- capture original line status id of record being edited
        SET @OrigLineStatusID = (SELECT Line_Status_ID
			FROM Local_PG_Line_Status
			WHERE Status_Schedule_Id = @ScheduleID)


-- Added below Follower module for follower units 
	-- Get Follower List
	DECLARE @MyTableVar TABLE (FU_ID integer)	-- This stores the unit id's of follower units
	INSERT INTO @MyTableVar 
	     SELECT PU.PU_Id
         FROM Tables AS T INNER JOIN Table_Fields_Values AS TFV ON T.TableId = TFV.TableId 
              INNER JOIN Table_Fields AS TF ON TFV.Table_Field_Id = TF.Table_Field_Id INNER JOIN
              Prod_Units AS PU ON TFV.KeyId = PU.PU_Id INNER JOIN Prod_Units AS PU_1 ON TFV.Value
               = CAST(PU_1.PU_Id as varchar)
         WHERE (T.TableName = 'Prod_Units') AND (TF.Table_Field_Desc = 'STLS_LS_MASTER_UNIT_ID') 
                AND (PU_1.PU_Id = @MasterUnitId)
	-- Follower List available

	-- Update edited row (LOOP)
	DECLARE @Vincount INT, @VinUnitId INT
	SET @VinCount = CAST((Select Count(FU_Id) from @MyTableVar) as INT)
	SET @VinUnitId = CAST((Select Max(FU_Id) from @MyTableVar) as INT)

	WHILE @VinCount > 0
	BEGIN

	-- Get Follower Status_Schedule_Id to EDIT
	SET @Follower_ScheduleID = (Select Status_Schedule_ID 
				FROM Local_PG_Line_Status
				WHERE 	Start_DateTime = @OrigStartDate
				AND	( (End_DateTime = @OrigEndDate) OR (End_DateTime + @OrigEndDate IS NULL) )
				AND	Line_Status_ID = @OrigLineStatusID
				AND 	UNIT_ID = @VinUnitId )

	IF @Follower_ScheduleID > 0	-- If Follower unit record matches with record to be edited, then only edit it
	BEGIN
		-- update edited record with new start 
		UPDATE Local_PG_Line_Status
		SET Start_DateTime = @StartDate,
		Line_Status_Id = @LineStatusID,
		Update_Status = 'UPDATE'
		WHERE Status_Schedule_ID = @Follower_ScheduleID

		-- update edited record with new end
		UPDATE Local_PG_Line_Status
		SET End_DateTime = (SELECT MIN(Start_DateTime) 
				FROM Local_PG_Line_Status 
				WHERE Unit_Id = @VinUnitID
				AND Start_DateTime > @StartDate
				AND Update_Status <> 'DELETE')
		WHERE Status_Schedule_ID = @Follower_ScheduleID

		--      update end time on previous row before new start 
		UPDATE Local_PG_Line_Status
		SET End_DateTime = @StartDate
		WHERE Unit_Id = @VinUnitID
		AND Start_DateTime = (SELECT MAX(Start_DateTime) 
				FROM Local_PG_Line_Status 
				WHERE Unit_Id = @VinUnitID
				AND Start_DateTime < @StartDate
				AND Update_Status <> 'DELETE')
	END

	-- loop
	SET @VinUnitId = CAST((Select Max(FU_Id) from @MyTableVar Where FU_Id < @VinUnitId) as INT)
	SET @VinCount = @VinCount - 1
	END
-- Follower module ends

-- Store COMMENT: 	vinayak added Build #7
	--  Get UserID,		
	SET @UserID = (SELECT User_Id 		
		FROM Users			
		WHERE UserName = @UserName)	

	-- Get New End Time, 	
	SET @EndDateTime = (SELECT End_DateTime 		
		FROM Local_PG_Line_Status			
		WHERE Status_Schedule_ID = @ScheduleID)		

	INSERT INTO Local_PG_Line_Status_Comments
	(Status_Schedule_Id, [User_Id], Entered_On, Start_DateTime, End_DateTime, Line_Status_Id, Unit_Id, Comment_Text) 
	VALUES	(@ScheduleID, @UserID, getdate(), @StartDate, @EndDateTime, @LineStatusID, @MasterUnitID, @Comment)	


SELECT Null as Status_Schedule_Id , NULL as Min_DateTime, NULL as Max_DateTime -- return null records to avoid sql exception message in grid

--Error Check
IF @@ERROR > 0
	BEGIN
	RAISERROR('Insert of Line Shedule failed.', 16, 1)
	RETURN 99
	END




RETURN 0	

