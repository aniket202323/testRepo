
/*
Name: spLocal_STLS_LineStatusNew2
Old Name: spLocal_STLS_LineStatusNew1
Purpose: Adds a new record to the line status schedule.
--------------------------------------------------------------------------------------------------------------------------------------
Modified by Allen Duncan
Date: 31 Jan 2012
Change: Changed follower code to use joins to work with new Proficy V5.X db 
change for Table_Fields Table requierment of table_id for UDPs
Version: 1.4
--------------------------------------------------------------------------------------------------------------------------------------
Modified by Allen Duncan
Date 28-Apr-2010
Change: Removed the update for endtime for added record and combined with insert operation.
Version: 1.3
--------------------------------------------------------------------------------------------------------------------------------------
Build #8
Modified by Vinayak Pate
Date 05-Feb-2008
Change: Added follower unit Functionality
maintain proficy standards be removing t ransactions and l ocks
--------------------------------------------------------------------------------------------------------------------------------------
Modified by Vinayak Pate
Date 17-Jul-06
Added Comment Functionality
--------------------------------------------------------------------------------------------------------------------------------------
Modified by Rajnikant Kapadia
on 10-Nov-05		Version 2.0.1
Change  	removed  WITH upd l ock  from update end time query
---------------------------------------------------------------------------------------------------------------------------------------
Modified by Debbie Linville
On 16-Jan-03			Version 2.0.0
Change : 	Add End_DateTime to insert for line status
---------------------------------------------------------------------------------------------------------------------------------------
Date: 11/12/2001
------------------------------------------------------------------------------------------------------------------------------------
*/

Create PROCEDURE spLocal_STLS_parmins_LineStatusNew2
	--parameters
 	@StartDate DateTime,
 	@UnitDesc VARCHAR(50),
 	@StatusPhrase VARCHAR(50),
 	@UserName VARCHAR(50),		--vinayak added
 	@Comment NVARCHAR(500)		--vinayak added

AS

DECLARE @LineStatusID INT
DECLARE @UnitID INT
DECLARE @UserID INT			--vinayak added
DECLARE @StatusScheduleID INT			--vinayak added
DECLARE @EnteredOn DateTime			--vinayak added
DECLARE @EndDateTime DateTime			--vinayak added
DECLARE @PriorLineStatusID INT		--vinayak added
DECLARE @NextLineStatusID INT		--vinayak added
DECLARE	 @MasterUnitId INT	-- Vinayak Follower Logic

SET @MasterUnitId = (Select pu_id From PROD_UNITS Where PU_DESC = @UnitDesc )


--2.  Get Line Status ID for Insert
	SET @LineStatusID = (SELECT Phrase.Phrase_Id
		FROM Phrase
		JOIN Data_Type ON Phrase.Data_Type_Id = Data_Type.Data_Type_Id
		WHERE	Phrase_Value = @StatusPhrase	
		AND	Data_Type.Data_Type_Desc = 'Line Status')

--3.  Get UnitID
	SET @MasterUnitId = (SELECT PU_Id 
		FROM Prod_Units
		WHERE PU_Desc = @UnitDesc)			

	-- Make sure same start time record doesn't already exist for this unit
	SET @StatusScheduleID = (SELECT Status_Schedule_ID 	--vinayak added
		FROM Local_PG_Line_Status			--vinayak added
		WHERE Unit_Id = @MasterUnitId			--vinayak added
		AND Start_DateTime = @StartDate)		--vinayak added

	-- select status of previous record as not allowed for new status
	SET @PriorLineStatusID = (SELECT Local_PG_Line_Status.Line_Status_Id
		FROM 	Local_PG_Line_Status
		WHERE 	Unit_Id = @MasterUnitId
		AND	Start_DateTime =	(SELECT	Max(Start_DateTime)
						FROM 	Local_PG_Line_Status
						WHERE 	Unit_Id = @MasterUnitId
						AND 	Start_DateTime < @StartDate)
				) 

	-- select status of next record as not allowed for new status
	SET @NextLineStatusID = (SELECT Local_PG_Line_Status.Line_Status_Id
		FROM 	Local_PG_Line_Status
		WHERE 	Unit_Id = @MasterUnitId
		AND	Start_DateTime = 	(SELECT	Min(Start_DateTime)
						FROM 	Local_PG_Line_Status
						WHERE 	Unit_Id = @MasterUnitId
						AND 	Start_DateTime > @StartDate)
				)	



	-- cancel insert operation if new start datetime already exist
	-- cancel insert operation if line status same as of prior or next row
	IF	(	(@StatusScheduleID IS NOT NULL) 
			OR
			((@PriorLineStatusID IS NOT NULL)  AND (@LineStatusID = @PriorLineStatusID ))
			OR
			((@NextLineStatusID IS NOT NULL)  AND ( @LineStatusID = @NextLineStatusID ))
		)
		BEGIN
		Select 1 as Status_Schedule_Id			RETURN 1
		END


--3a.  Get UserID				--vinayak added
	SET @UserID = (SELECT User_Id 		--vinayak added
		FROM Users			--vinayak added
		WHERE UserName = @UserName)	--vinayak added


-- Added below Follower module for follower units by vinayak Feb 05, 2008

-- Get Follower List
DECLARE @MyTableVar TABLE (FU_ID integer)	-- This stores the unit id's of follower units
	INSERT INTO @MyTableVar 
	SELECT PU.PU_Id FROM Tables T (NOLOCK) INNER JOIN Table_Fields_Values TFV (NOLOCK) 
                ON T.TableId = TFV.TableId INNER JOIN Table_Fields TF (NOLOCK) ON 
                TFV.Table_Field_Id = TF.Table_Field_Id INNER JOIN Prod_Units PU (NOLOCK) ON 
                TFV.KeyId = PU.PU_Id INNER JOIN Prod_Units PU_1 (NOLOCK) ON TFV.Value = 
                CAST(PU_1.PU_Id as varchar)
         WHERE (T.TableName = 'Prod_Units') AND (TF.Table_Field_Desc = 'STLS_LS_MASTER_UNIT_ID') 
                AND (PU_1.PU_Id = @MasterUnitId)
                
-- Follower List available

-- Delete Follower line status for the given start if present
	DELETE	FROM 	Local_PG_Line_Status		
		WHERE	Local_PG_Line_Status.Start_DateTime = @StartDate
		AND 	Local_PG_Line_Status.Unit_Id IN (select Distinct FU_ID from @MyTableVar)

--Get Startdate of next record for enddate of new record inserted will return null if no next record
   set @EndDateTime = (SELECT MIN(Start_DateTime) 
						FROM Local_PG_Line_Status 
						WHERE Unit_Id = @MasterUnitId
						AND Start_DateTime > @StartDate
						AND Update_Status <> 'DELETE')



-- Insert NEW Line Status to Master and Follower units
	INSERT INTO Local_PG_Line_Status(Start_DateTime, Line_Status_Id, Update_Status, Unit_Id, End_DateTime)
	SELECT @StartDate, @LineStatusID, 'NEW', FU_ID, @EndDateTime
	FROM @MyTableVar

-- Update previous and next records of new record entered (LOOP)
	DECLARE @Vincount INT, @VinUnitId INT
	SET @VinCount = CAST((Select Count(FU_Id) from @MyTableVar) as INT)
	SET @VinUnitId = CAST((Select Max(FU_Id) from @MyTableVar) as INT)

	WHILE @VinCount > 0
	BEGIN
		UPDATE Local_PG_Line_Status
			SET End_DateTime = @StartDate
			WHERE Unit_Id = @VinUnitId
			AND Start_DateTime = (SELECT MAX(Start_DateTime) 
						FROM Local_PG_Line_Status 
						WHERE Unit_Id = @VinUnitId
						AND Start_DateTime < @StartDate
						AND Update_Status <> 'DELETE')

--removed and added as part of insert of new record 4/28/10
		--UPDATE Local_PG_Line_Status
			--SET End_DateTime = (SELECT MIN(Start_DateTime) 
					--	FROM Local_PG_Line_Status 
					--	WHERE Unit_Id = @VinUnitId
					--	AND Start_DateTime > @StartDate
						--AND Update_Status <> 'DELETE')
			--WHERE Unit_Id = @VinUnitId
			--AND Start_DateTime = @StartDate

		SET @VinUnitId = CAST((Select Max(FU_Id) from @MyTableVar Where FU_Id < @VinUnitId) as INT)
		SET @VinCount = @VinCount - 1
	END
-- Follower module ends


-- Insert Comment
	SET @StatusScheduleID = (SELECT Status_Schedule_ID 	
		FROM Local_PG_Line_Status			
		WHERE Unit_Id = @MasterUnitId			
		AND Start_DateTime = @StartDate)		

	SET @EndDateTime = (SELECT End_DateTime 		
		FROM Local_PG_Line_Status			
		WHERE Status_Schedule_ID = @StatusScheduleID)	

INSERT INTO Local_PG_Line_Status_Comments
	(Status_Schedule_Id, [User_Id], Entered_On, Start_DateTime, End_DateTime, Line_Status_Id, Unit_Id, Comment_Text) --vinayak added
VALUES	(@StatusScheduleID, @UserID, getdate(), @StartDate, @EndDateTime, @LineStatusID, @MasterUnitId, @Comment)	--vinayak added



--Error Check
IF @@ERROR > 0
	BEGIN
	RAISERROR('Insert of Line Shedule failed.', 16, 1)
	RETURN 99
	END

select null as Status_Schedule_Id	-- to avoid error message on web page


RETURN 0
