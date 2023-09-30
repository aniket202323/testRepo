
/*
--------------------------------------------------------------------------------------------------------------------------------------
Name: spLocal_STLS_parmupd_LineScheduleDelete2
--------------------------------------------------------------------------------------------------------------------------------------
OldName: spLocal_STLS_parmupd_LineScheduleDelete1
Purpose: Delete a record from the Line Schedule
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
Build #7
Modified by Vinayak Pate
On 7/17/2006	
Added update to Comment Table
--------------------------------------------------------------------------------------------------------------------------------------
Modified by Rajnikant Kapadia 
On 1/10/2005 	Versin 2.0.1
Change :	Added user parameter in stored procedure to log deleted record in history table
		STLS change UID - 5 and 6
---------------------------------------------------------------------------------------------------------------------------------------
Modified by Debbie Linville
On 16-Jan-03	Version 2.0.0
Change : 	Update End_DateTime of prior record after delete
---------------------------------------------------------------------------------------------------------------------------------------
Date: 11/12/2001
--------------------------------------------------------------------------------------------------------------------------------------
*/

CREATE      PROCEDURE [dbo].[spLocal_STLS_parmupd_LineScheduleDelete2]
	--parameters
	@StatusScheduleID INT,
	@User varchar(50)

AS

DECLARE @MasterUnitId INT
DECLARE @StartDate DATETIME 
DECLARE @PriorStartDate DATETIME
DECLARE @UserID int
DECLARE @LineStatusID INT
DECLARE @DeletedOn DATETIME 

DECLARE @PriorLineStatusID INT		--vinayak added
DECLARE @NextLineStatusID INT		--vinayak added

--1. Get information 
	SET @MasterUnitId = (SELECT Unit_Id
		FROM Local_PG_Line_Status
		WHERE Status_Schedule_Id = @StatusScheduleID)
       
	SET @LineStatusID = (SELECT Line_Status_Id
		FROM Local_PG_Line_Status
		WHERE Status_Schedule_Id = @StatusScheduleID)

	SET @StartDate = (SELECT Start_DateTime
		FROM Local_PG_Line_Status
		WHERE Status_Schedule_Id = @StatusScheduleID)

	SET @UserID = (SELECT [User_ID] from users where Upper(LTrim(RTrim(UserName))) = Upper(LTrim(RTrim(@User))))

	SET @DeletedOn = (Select getdate())

--2. Mark delete row
--	UPDATE Local_PG_Line_Status
--	SET Update_Status = 'DELETE'
--	WHERE Status_Schedule_Id = @StatusScheduleID
	
	--insert deleted record in history table
	INSERT INTO Local_PG_Line_Status_History 
	(Status_Schedule_Id,Start_DateTime,Line_Status_Id,Update_Status,Unit_Id,End_DateTime,[User_ID],Modified_DateTime)
	SELECT Status_Schedule_Id,Start_DateTime,Line_Status_Id,Update_Status,Unit_Id,End_DateTime,
	@UserID,@DeletedOn FROM Local_PG_Line_Status WHERE Status_Schedule_Id = @StatusScheduleID

	-- insert row in comments table
	INSERT INTO Local_PG_Line_Status_Comments
	(Status_Schedule_Id, [User_Id], Entered_On, Start_DateTime, End_DateTime, Line_Status_Id, Unit_Id, Comment_Text) --vinayak added
	VALUES	(@StatusScheduleID, @UserID, @DeletedOn, NULL, NULL, @LineStatusID, @MasterUnitId, NULL)	--vinayak added

-- Added below Follower module for follower units by vinayak
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

-- Delete Follower line status for the given start if present
	DELETE	FROM 	Local_PG_Line_Status		
		WHERE	Local_PG_Line_Status.Start_DateTime = @StartDate
		AND 	Local_PG_Line_Status.Unit_Id IN (select Distinct FU_ID from @MyTableVar)

-- Update end time of previous record of the deleted record (LOOP)
	DECLARE @Vincount INT, @VinUnitId INT
	SET @VinCount = CAST((Select Count(FU_Id) from @MyTableVar) as INT)
	SET @VinUnitId = CAST((Select Max(FU_Id) from @MyTableVar) as INT)

	WHILE @VinCount > 0
	BEGIN

	-- select status of previous record as not allowed for new status
	SET @PriorLineStatusID = (SELECT Local_PG_Line_Status.Line_Status_Id
		FROM 	Local_PG_Line_Status
		WHERE 	Unit_Id = @VinUnitId
		AND	Start_DateTime =	(SELECT	Max(Start_DateTime)
						FROM 	Local_PG_Line_Status
						WHERE 	Unit_Id = @VinUnitId
						AND 	Start_DateTime < @StartDate)
				) 

	-- select status of next record as not allowed for new status
	SET @NextLineStatusID = (SELECT Local_PG_Line_Status.Line_Status_Id
		FROM 	Local_PG_Line_Status
		WHERE 	Unit_Id = @VinUnitId
		AND	Start_DateTime = 	(SELECT	Min(Start_DateTime)
						FROM 	Local_PG_Line_Status
						WHERE 	Unit_Id = @VinUnitId
						AND 	Start_DateTime > @StartDate)
				)	

	-- Delete next record too if it has same line status as of previous record
	IF		(	@PriorLineStatusID IS NOT NULL
			AND	@NextLineStatusID IS NOT NULL
			AND 	@PriorLineStatusID = @NextLineStatusID
			)
		BEGIN
			DELETE	FROM 	Local_PG_Line_Status	
				WHERE 	Unit_Id = @VinUnitId
				AND	Start_DateTime = (SELECT Min(Start_DateTime)
							FROM 	Local_PG_Line_Status
							WHERE 	Unit_Id = @VinUnitId
							AND 	Start_DateTime > @StartDate)
		END	

		SET @PriorStartDate  = (SELECT MAX(Start_DateTIme)
			FROM Local_PG_Line_Status 
			WHERE Unit_Id = @VinUnitId 
			AND Start_DateTime < @StartDate
--			AND Master_Status_Schedule_Id <> @StatusScheduleID
			AND Update_Status <> 'DELETE')

	--Change end time of prior row
		UPDATE Local_PG_Line_Status
			SET End_DateTime = (SELECT MIN(Start_DateTime) 
					FROM Local_PG_Line_Status 
					WHERE Unit_Id = @VinUnitId 
					AND Start_DateTime > @PriorStartDate
					AND Update_Status <> 'DELETE')
			WHERE Unit_Id = @VinUnitId 
			AND Start_DateTime = @PriorStartDate

		SET @VinUnitId = CAST((Select Max(FU_Id) from @MyTableVar Where FU_Id < @VinUnitId) as INT)
		SET @VinCount = @VinCount - 1
	END
-- Follower module ends


--Error Check
IF @@ERROR > 0
	BEGIN
	RAISERROR('Delete of Line Schedule failed.', 16, 1)
	RETURN 99
	END


RETURN 0

