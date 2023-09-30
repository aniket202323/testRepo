	

/*
Name: spLocal_STLS_Follower_Get_Master_Data
---------------------------------------------------------------------------------------------------------------------------------------  
Modified by Allen Duncan
Date: 31 Jan 2012
Change: Changed follower code to use joins to work with new Proficy V5.X db 
change for Table_Fields Table requierment of table_id for UDPs
Version 1.1
--------------------------------------------------------------------------------------------------------------------------------------
Build #8
Created by Vinayak Pate
Date 14-May-2008
Make schedules of follower units similar to their master units.
---------------------------------------------------------------------------------------------------------------------------------------
*/
CREATE        PROCEDURE [dbo].[spLocal_STLS_Follower_Get_Master_Data]
	--Parameters
	@vcFollowerIDs VARCHAR(8000) = 0,
	@dtStartDate DATETIME = '1901-01-01',
	@dtEndDate DATETIME = '2901-01-01'

AS

--Local Variables
DECLARE @charDelimiter CHAR(1)
DECLARE @nPosition INT
DECLARE @strRecord VARCHAR(20)
DECLARE @strRemainingRecord VARCHAR(8000)

DECLARE	 @nFollowerUnitId INT	
DECLARE	 @nST_MasterUnitId INT	
DECLARE	 @nLS_MasterUnitId INT	

DECLARE @txtStartDate VARCHAR(30)
DECLARE @txtEndDate VARCHAR(30)

SET NOCOUNT ON

SET @strRemainingRecord = @vcFollowerIDs
SET @charDelimiter = ','

	SET @txtStartDate = cast(@dtStartDate as varchar)
	IF @dtStartDate = '1901-01-01'
	BEGIN
		SET @txtStartDate 	= ' beginning '
	END

	SET @txtEndDate = cast(@dtEndDate as varchar)
	IF @dtEndDate = '2901-01-01'
	BEGIN
		SET @txtEndDate 	= ' end '
	END

WHILE LEN(@strRemainingRecord) > 0

BEGIN

	SET @nPosition = CHARINDEX(@charDelimiter,@strRemainingRecord, 1)

	If @nPosition > 0
	Begin
		SET @strRecord = LEFT(@strRemainingRecord, (@nPosition - 1))
		SET @strRemainingRecord = RIGHT(@strRemainingRecord, ((LEN(@strRemainingRecord)) - @nPosition))
	End

	If @nPosition = 0
	Begin
		SET @strRecord = @strRemainingRecord
		SET @strRemainingRecord = ''
	End

	SET @nFollowerUnitId = (SELECT Distinct PU_id from prod_Units
				WHERE PU_Id = CAST(@strRecord AS INT)	
				AND Master_Unit IS NULL)	

	IF @nFollowerUnitId  IS NULL
	BEGIN
		print 'No changes made to crew schedule of unit ' + @strRecord + ' because it is INVALID follower unit Id'
	END

	IF @nFollowerUnitId  IS NOT NULL
	BEGIN



				SET @nST_MasterUnitId = (SELECT DISTINCT PU.PU_Id
                        FROM Prod_Units PU (NOLOCK) INNER JOIN Table_Fields_Values TFV( NOLOCK) ON 
                        PU.PU_Id = TFV.Value INNER JOIN Table_Fields TF (NOLOCK) ON TFV.Table_Field_Id 
                        = TF.Table_Field_Id INNER JOIN Tables T (NOLOCK) ON TFV.TableId = T.TableId
                        WHERE     (TF.Table_Field_Desc = 'STLS_ST_MASTER_UNIT_ID') AND (T.TableName = 
                        'Prod_units') AND (TFV.KeyId = @nFollowerUnitId))
			
				SET @nLS_MasterUnitId = (SELECT DISTINCT PU.PU_Id
                        FROM Prod_Units PU (NOLOCK) INNER JOIN Table_Fields_Values TFV( NOLOCK) ON 
                        PU.PU_Id = TFV.Value INNER JOIN Table_Fields TF (NOLOCK) ON TFV.Table_Field_Id 
                        = TF.Table_Field_Id INNER JOIN Tables T (NOLOCK) ON TFV.TableId = T.TableId
                        WHERE     (TF.Table_Field_Desc = 'STLS_LS_MASTER_UNIT_ID') AND (T.TableName = 
                        'Prod_units') AND (TFV.KeyId = @nFollowerUnitId))
					
			
			
				IF @nFollowerUnitId  !=	@nST_MasterUnitId  
				BEGIN	
					-- Delete Folower Crew Schedule for the given period
					DELETE FROM CREW_SCHEDULE
					WHERE	pu_id = @nFollowerUnitId  	
					AND	pu_id != @nST_MasterUnitId  	
					AND	Start_Time >= @dtStartDate
					AND	Start_Time <= @dtEndDate
			
					-- Copy Master Crew Schedule to Follower for the given period
					INSERT INTO Crew_Schedule (Start_Time, End_Time, PU_Id, Crew_Desc, Shift_Desc)
					SELECT 	Start_Time, End_Time, @nFollowerUnitId, Crew_Desc, Shift_Desc
					FROM 	Crew_Schedule
					WHERE	PU_id = @nST_MasterUnitId  	
					AND	Start_Time >= @dtStartDate
					AND	Start_Time <= @dtEndDate
			
					print cast(@@rowcount as varchar) + ' crew schedule records copied from Master Id '  + CAST(@nST_MasterUnitId as varchar)   + ' to Folllower Id ' + cast(@nFollowerUnitId  as varchar) + ' for period from ' + cast(@txtStartDate as varchar) + ' to ' + cast(@txtEndDate as varchar) 
				END
			
				IF @nFollowerUnitId  =	@nST_MasterUnitId  
				BEGIN
					print 'No changes made to crew schedule of unit ' + cast(@nFollowerUnitId  as varchar) + ' because it is master of itself '
				END
			
				IF @nST_MasterUnitId IS NULL
				BEGIN
					print 'No changes made to crew schedule of unit ' + cast(@nFollowerUnitId  as varchar) + ' because it does not have any master '
				END
			
			
			
				IF @nFollowerUnitId  !=	@nLS_MasterUnitId  
				BEGIN	
					-- Delete Follower Line Status for given period
					DELETE FROM Local_PG_Line_Status 
					WHERE	Unit_id = @nFollowerUnitId  	
					AND	Unit_id != @nLS_MasterUnitId  	
					AND	Start_DateTime >= @dtStartDate
					AND	Start_DateTime <= @dtEndDate
			
					-- Copy Master Line Status to Follower for the given period
					INSERT INTO 	Local_PG_Line_Status (Start_DateTime, Line_Status_Id, Update_Status, Unit_Id, End_DateTime)
					SELECT 	Start_DateTime, Line_Status_Id, 'NEW', @nFollowerUnitId, End_DateTime
					FROM 	Local_PG_Line_Status
					WHERE	Unit_id = @nLS_MasterUnitId  	
					AND	Start_DateTime >= @dtStartDate
					AND	Start_DateTime <= @dtEndDate
			
					print cast(@@rowcount as varchar) + ' line status records copied from Master Id '  + cast(@nLS_MasterUnitId as varchar)  + ' to Folllower Id ' + cast(@nFollowerUnitId as varchar)  + ' for period from ' + cast(@txtStartDate as varchar) + ' to ' + cast(@txtEndDate as varchar) 
				END
			
				IF @nFollowerUnitId  =	@nLS_MasterUnitId  
				BEGIN
					print 'No changes made to line status of unit ' + cast(@nFollowerUnitId  as varchar) + ' because it is master of itself '
				END
			
				IF @nLS_MasterUnitId IS NULL
				BEGIN
					print 'No changes made to line status of unit ' + cast(@nFollowerUnitId  as varchar) + ' because it does not have any master '
				END

	END
END

SET NOCOUNT OFF


--Error Check
IF @@ERROR > 0
	BEGIN
	RAISERROR('SQL error - spLocal_STLS_Follower_Get_Master_Data', 16, 1)
	RETURN 99
	END


RETURN 0




