
--------------------------------------------------------------------------------------------------
-- Stored Procedure: spLocal_CTS_Create_Update_Cleaning_Matrix
--------------------------------------------------------------------------------------------------
-- Author				: Francois Bergeron, Symasol
-- Date created			: 2021-08-12
-- Version 				: Version 1.0
-- SP Type				: WEB
-- Caller				: WEB SERVICE
-- Description			: Add update or delete record from [dbo].[Local_CTS_Product_Transition_Cleaning_Methods]
-- Editor tab spacing	: 4
-------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ===========================================================================================
-- 1.0		2021-08-12		F. Bergeron				Initial Release 
--================================================================================================
--
--------------------------------------------------------------------------------------------------
-- TEST CODE:
--------------------------------------------------------------------------------------------------
/*

EXECUTE [spLocal_CTS_Create_Update_Cleaning_Matrix] 2, 11858, 11863,8451,1,'Update'
*/

CREATE   PROCEDURE [dbo].[spLocal_CTS_Create_Update_Cleaning_Matrix]
@Rule_id			INTEGER NULL,
@From_product_id	INTEGER NULL,
@To_product_id		INTEGER NULL,
@Location_id		INTEGER NULL,
@Cleaning_type_id	INTEGER NULL,
@Transaction_type	VARCHAR(10) -- Add, Update, Delete

AS
BEGIN
	SET NOCOUNT ON;
	-- SP Variables
	DECLARE 
	@TransTime				DATETIME,
	@CPTCMId				INTEGER,
	@ParentCPTCMId			INTEGER,
	@UpdateParentCPTCMId	BIT

	DECLARE @Output TABLE
	(
		OutputStatus	INTEGER,
		OutputMessage	VARCHAR(500)
	)
	
	SET @TransTime = GETDATE()
	IF @Transaction_type = 'Add'
	BEGIN

		SET @ParentCPTCMId =	(SELECT	TOP 1 CPTCM_id
								FROM	dbo.Local_CTS_Product_Transition_Cleaning_Methods 
								WHERE	From_Product_id = @From_Product_id 
										AND To_Product_id = @To_Product_id 
										AND Location_id = @Location_id 
										AND End_time IS NULL
								ORDER 
								BY		Start_time DESC 
								)
		-- UPDATE LAST STATE
		IF @ParentCPTCMId IS NOT NULL
		BEGIN
			SET @UpdateParentCPTCMId = 1

		END


		IF @Rule_id IS NOT NULL OR @From_product_id IS NULL OR @To_product_id IS NULL OR @Cleaning_type_id IS NULL
		BEGIN
			INSERT INTO @output
			(
				OutputStatus,
				OutputMessage
			)
			VALUES
			(
				0,
				'Fields received are or incomplete or incorrect '
			)
			GOTO THEEND

		END
		INSERT INTO dbo.Local_CTS_Product_Transition_Cleaning_Methods
		(	From_Product_id,
			To_Product_id,
			Location_id,
			CCM_id,
			Start_Time,
			Parent_CPTCM_id

		)
		VALUES
		(
			@From_Product_id,
			@To_Product_id,
			@Location_id,
			@Cleaning_type_id,
			@TransTime,
			@ParentCPTCMId
		)

		IF @UpdateParentCPTCMId = 1
		BEGIN
			UPDATE	Local_CTS_Product_Transition_Cleaning_Methods 
			SET		End_time = @TransTime
			WHERE	CPTCM_id = @ParentCPTCMId
			
			INSERT INTO @output
			(
				OutputStatus,
				OutputMessage
			)
			VALUES
			(
				1,
				'Rule added and overriden active one with same parameters'
			)
			GOTO THEEND
		END
		INSERT INTO @output
		(
			OutputStatus,
			OutputMessage
		)
		VALUES
		(
			1,
			'Rule added'
		)			

	END
		

	----IF @Transaction_type = 'Update'
	----BEGIN
	----	IF @Rule_id IS NULL OR @From_product_id IS NULL OR @To_product_id IS NULL OR @Cleaning_type_id IS NULL
	----	BEGIN
	----		INSERT INTO @output
	----		(
	----			OutputStatus,
	----			OutputMessage
	----		)
	----		VALUES
	----		(
	----			0,
	----			'Fields received are or incomplete or incorrect '
	----		)
	----		GOTO THEEND

	----	END
	----	INSERT INTO dbo.Local_CTS_Product_Transition_Cleaning_Methods
	----	(	From_Product_id,
	----		To_Product_id,
	----		Location_id,
	----		CCM_id,
	----		Start_Time,
	----		Parent_CPTCM_id
	----	)
	----	VALUES
	----	(
	----		@From_Product_id,
	----		@To_Product_id,
	----		@Location_id,
	----		@Cleaning_type_id,
	----		@TransTime,
	----		@Rule_id
	----	)


	----	-- UPDATE LAST STATE
	----	IF @CPTCMId IS NOT NULL
	----	BEGIN
	----		UPDATE	Local_CTS_Product_Transition_Cleaning_Methods 
	----		SET		End_time = @TransTime
	----		WHERE	CPTCM_id = @Rule_id
	----	END

	----			INSERT INTO @output
	----	(
	----		OutputStatus,
	----		OutputMessage
	----	)
	----	VALUES
	----	(
	----		1,
	----		'Rule updated, history retained'
	----	)
	----		GOTO THEEND
	----END

	IF @Transaction_type = 'Delete'
	BEGIN
		IF @Rule_id IS NULL 
		BEGIN
			INSERT INTO @output
			(
				OutputStatus,
				OutputMessage
			)
			VALUES
			(
				0,
				'Fields received are or incomplete or incorrect '
			)
			GOTO THEEND
		END

		UPDATE	Local_CTS_Product_Transition_Cleaning_Methods 
		SET		End_time = @TransTime
		WHERE	CPTCM_id = @Rule_id

		INSERT INTO @output
		(
			OutputStatus,
			OutputMessage
		)
		VALUES
		(
			1,
			'Rule deleted '
		)
			GOTO THEEND
	END

	THEEND:
		SELECT	OutPutStatus,
				OutPutMessage
		FROM	@output

	SET NOCOUNT OFF;
END
