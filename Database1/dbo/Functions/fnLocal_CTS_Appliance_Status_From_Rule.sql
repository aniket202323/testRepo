
--------------------------------------------------------------------------------------------------
-- Local Function: fnLocal_CTS_Appliance_Status_From_Rule
--------------------------------------------------------------------------------------------------
-- Author				:	Francois Bergeron (AutomaTech Canada)
-- Date created			:	2021-08-12
-- Version 				:	1.0
-- Description			:	The purpose of this function is to determine the appliance cleaning state
--							- In Use
--							- Dirty
--							- Clean (cleaning type)
-- Editor tab spacing	: 4 
--------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ========		====	  		====					=====
-- 1.0			2021-08-12		F.Bergeron				Initial Release 



--------------------------------------------------------------------------------------------------
--Testing Code
--------------------------------------------------------------------------------------------------
-- SELECT * FROM fnLocal_CTS_Appliance_Status(1018702,NULL) SELECT * FROM fnLocal_CTS_Appliance_Status_From_Rule(1018702,NULL)


--------------------------------------------------------------------------------------------------


CREATE FUNCTION [dbo].[fnLocal_CTS_Appliance_Status_From_Rule] 
(
	@ApplianceId 		INTEGER,
	@EvaluationTime		DATETIME
)
RETURNS @Output TABLE 
(
	Clean_status					VARCHAR(25),
	Clean_type						VARCHAR(25),
	Last_product_id					INTEGER,
	Last_Process_order_Id			INTEGER,
	Last_Process_order_status_Id	INTEGER,
	Cleaned_timer_hour				FLOAT,
	Cleaned_limit_hour				FLOAT,
	Used_timer_hour					FLOAT,
	Used_limit_hour					FLOAT,
	Timer_Exception					VARCHAR(25) -- None, Cleaning, Usage
)
					
AS
BEGIN
DECLARE
	@ApplianceleaningUDESubTypeDesc			VARCHAR(50),
	@ApplianceCleaningUDESubTypeId			VARCHAR(50),
	@ApplianceCleaningTypeVarId				INTEGER,
	@CleanedTimerLimit						FLOAT,
	@CleanedTimer							FLOAT,
	@UsedTimerLimit							FLOAT,
	@UsedTimer								FLOAT,
	@CurrentTransitionStatusTimestamp		DATETIME


	DECLARE @App_cleaning TABLE
	(
	Status						VARCHAR(25),
	type						VARCHAR(25),
	Location_id					INTEGER,
	Location_desc				VARCHAR(50),
	Start_time					DATETIME,
	End_time					DATETIME,
	Start_User_Id				INTEGER,
	Start_Username				VARCHAR(100),
	Start_User_AD				VARCHAR(100),
	Completion_ES_User_Id		INTEGER,
	Completion_ES_Username		VARCHAR(100),
	Completion_ES_User_AD		VARCHAR(100),
	Approver_ES_User_Id			INTEGER,
	Approver_ES_Username		VARCHAR(100),
	Approver_ES_User_AD			VARCHAR(100),
	Err_Warn					VARCHAR(500),
	UDE_Id						INTEGER
	)


	DECLARE @App_Transitions TABLE
	(
	Location_id										INTEGER,
	Location_desc									VARCHAR(50),
	Location_Product_Id								INTEGER,
	Location_Product_code							VARCHAR(25),
	Location_Process_order_Id						INTEGER,
	Location_Process_order_desc						VARCHAR(50),
	Location_process_order_Form_Id					INTEGER,
	Location_Process_order_status_Id				INTEGER,
	Location_Process_order_Status_desc				VARCHAR(50),
	Location_Process_Order_start_time				DATETIME,
	Location_Process_Order_End_time					DATETIME,
	Enter_time										DATETIME,
	Exit_time										DATETIME,
	Appliance_Product_Id							INTEGER,
	Appliance_Product_code							VARCHAR(25),
	Appliance_Process_order_Id						INTEGER,
	Appliance_Process_order_desc					VARCHAR(50),
	Appliance_process_order_Form_Id					INTEGER,
	Appliance_Process_order_status_Id				INTEGER,
	Appliance_Process_order_Status_desc				VARCHAR(50),
	Appliance_Process_order_started					DATETIME,
	Mover_User_Id									INTEGER,
	Mover_Username									VARCHAR(100),
	Mover_User_AD									VARCHAR(100),
	Err_Warn										VARCHAR(500)
	)

	DECLARE @App_Transitions_making TABLE
	(
	Location_id										INTEGER,
	Location_desc									VARCHAR(50),
	Location_Product_Id								INTEGER,
	Location_Product_code							VARCHAR(25),
	Location_Process_order_Id						INTEGER,
	Location_Process_order_desc						VARCHAR(50),
	Location_process_order_Form_Id					INTEGER,
	Location_Process_order_status_Id				INTEGER,
	Location_Process_order_Status_desc				VARCHAR(50),
	Location_Process_Order_start_time				DATETIME,
	Location_Process_Order_End_time					DATETIME,
	Enter_time										DATETIME,
	Exit_time										DATETIME,
	Appliance_Product_Id							INTEGER,
	Appliance_Product_code							VARCHAR(25),
	Appliance_Process_order_Id						INTEGER,
	Appliance_Process_order_desc					VARCHAR(50),
	Appliance_process_order_Form_Id					INTEGER,
	Appliance_Process_order_status_Id				INTEGER,
	Appliance_Process_order_Status_desc				VARCHAR(50),
	Appliance_Process_order_started					DATETIME,
	Mover_User_Id									INTEGER,
	Mover_Username									VARCHAR(100),
	Mover_User_AD									VARCHAR(100),
	Err_Warn										VARCHAR(500)
	)

	IF @EvaluationTime IS NULL
		SET @EvaluationTime = GETDATE()
	-- Get appliance celaning, with type and status
	INSERT INTO	@App_cleaning
	(
			Status,
			type,
			Location_id,
			Location_desc,
			Start_time,
			End_time,
			Start_User_Id,
			Start_Username,
			Start_User_AD,
			Completion_ES_User_Id,
			Completion_ES_Username,
			Completion_ES_User_AD,
			Approver_ES_User_Id,
			Approver_ES_Username,
			Approver_ES_User_AD,
			Err_Warn,
			UDE_Id
	)
	SELECT 	Status,
			type,
			Location_id,
			Location_desc,
			Start_time,
			End_time,
			Start_User_Id,
			Start_Username,
			Start_User_AD,
			Completion_ES_User_Id,
			Completion_ES_Username,
			Completion_ES_User_AD,
			Approver_ES_User_Id,
			Approver_ES_Username,
			Approver_ES_User_AD,
			Err_Warn,
			UDE_Id
	FROM	[dbo].[fnLocal_CTS_Appliance_Cleanings](@ApplianceId, NULL, @EvaluationTime)

	SET @CleanedTimer = DATEDIFF(hour,(SELECT End_time FROM @App_cleaning),GETDATE())



	SELECT	@CleanedTimerLimit = TFV.Value 
	FROM	dbo.Prod_units_base PUB
			JOIN dbo.Table_Fields_Values TFV WITH(NOLOCK)
				ON  TFV.KeyId = PUB.PU_Id
			JOIN dbo.Table_Fields TF WITH(NOLOCK) 
				ON TF.Table_Field_Id = TFV.Table_Field_Id
				AND TF.Table_Field_Desc = 'CTS time since last cleaned threshold (hours)'
				AND TF.TableId =	(
									SELECT	TableId 
									FROM	dbo.Tables WITH(NOLOCK) 
									WHERE	TableName = 'Prod_units'
									)
	WHERE	PUB.PU_ID = (SELECT PU_ID FROM dbo.events WITH(NOLOCK) WHERE event_id = @ApplianceId)							



	SELECT	@UsedTimerLimit = TFV.Value 
	FROM	dbo.Prod_units_base PUB
			JOIN dbo.Table_Fields_Values TFV WITH(NOLOCK)
				ON  TFV.KeyId = PUB.PU_Id
			JOIN dbo.Table_Fields TF WITH(NOLOCK) 
				ON TF.Table_Field_Id = TFV.Table_Field_Id
				AND TF.Table_Field_Desc = 'CTS time since last used threshold (hours)'
				AND TF.TableId =	(
									SELECT	TableId 
									FROM	dbo.Tables WITH(NOLOCK) 
									WHERE	TableName = 'Prod_units'
									)
	WHERE	PUB.PU_ID = (SELECT PU_ID FROM dbo.events WITH(NOLOCK) WHERE event_id = @ApplianceId)							


	INSERT INTO	@App_Transitions
	(
		Location_id,
			Location_desc,
			Location_Product_Id,
			Location_Product_code,
			Location_Process_order_Id,
			Location_Process_order_desc,
			Location_Process_order_Form_Id,
			Location_Process_order_status_Id,
			Location_Process_order_Status_desc,
			Location_Process_Order_start_time,
			Location_Process_Order_End_time,
			Enter_time,
			Exit_time,
			Appliance_Product_Id,
			Appliance_Product_code,
			Appliance_Process_order_Id,
			Appliance_Process_order_desc,
			Appliance_Process_order_Form_Id,
			Appliance_Process_order_status_Id,
			Appliance_Process_order_Status_desc,
			Mover_User_Id,
			Mover_Username,
			Mover_User_AD,
			Err_Warn
	)
	SELECT	Location_id,
			Location_desc,
			Location_Product_Id,
			Location_Product_code,
			Location_Process_order_Id,
			Location_Process_order_desc,
			Location_Process_order_Form_Id,
			Location_Process_order_status_Id,
			Location_Process_order_Status_desc,
			Location_Process_Order_start_time,
			Location_Process_Order_End_time,
			Enter_time,
			Exit_time,
			Appliance_Product_Id,
			Appliance_Product_code,
			Appliance_Process_order_Id,
			Appliance_Process_order_desc,
			Appliance_Process_order_Form_Id,
			Appliance_Process_order_status_Id,
			Appliance_Process_order_Status_desc,
			Mover_User_Id,
			Mover_Username,
			Mover_User_AD,
			Err_Warn
	FROM	[dbo].[fnLocal_CTS_Appliance_Transitions_Dev](@ApplianceId, 0, NULL, @EvaluationTime,'BACKWARD')

	INSERT INTO	@App_Transitions_making
	(
		Location_id,
			Location_desc,
			Location_Product_Id,
			Location_Product_code,
			Location_Process_order_Id,
			Location_Process_order_desc,
			Location_Process_order_Form_Id,
			Location_Process_order_status_Id,
			Location_Process_order_Status_desc,
			Location_Process_Order_start_time,
			Location_Process_Order_End_time,
			Enter_time,
			Exit_time,
			Appliance_Product_Id,
			Appliance_Product_code,
			Appliance_Process_order_Id,
			Appliance_Process_order_desc,
			Appliance_Process_order_Form_Id,
			Appliance_Process_order_status_Id,
			Appliance_Process_order_Status_desc,
			Mover_User_Id,
			Mover_Username,
			Mover_User_AD,
			Err_Warn
	)
	SELECT	Location_id,
			Location_desc,
			Location_Product_Id,
			Location_Product_code,
			Location_Process_order_Id,
			Location_Process_order_desc,
			Location_Process_order_Form_Id,
			Location_Process_order_status_Id,
			Location_Process_order_Status_desc,
			Location_Process_Order_start_time,
			Location_Process_Order_End_time,
			Enter_time,
			Exit_time,
			Appliance_Product_Id,
			Appliance_Product_code,
			Appliance_Process_order_Id,
			Appliance_Process_order_desc,
			Appliance_Process_order_Form_Id,
			Appliance_Process_order_status_Id,
			Appliance_Process_order_Status_desc,
			Mover_User_Id,
			Mover_Username,
			Mover_User_AD,
			Err_Warn
	FROM	[dbo].[fnLocal_CTS_Appliance_Transitions_Dev](@ApplianceId, 1, NULL, @EvaluationTime,'BACKWARD')
	


	SET @CurrentTransitionStatusTimestamp = (SELECT CASE 
			WHEN (SELECT Enter_time FROM @App_Transitions_making) >= (SELECT Location_process_order_start_time FROM @App_Transitions_making) 
			THEN (SELECT Enter_time FROM @App_Transitions_making)
			ELSE (SELECT Location_process_order_start_time FROM @App_Transitions_making)
			END)

		SET @UsedTimer = DATEDIFF(hour,@CurrentTransitionStatusTimestamp,GETDATE())
		------------------------------------------------------------------------------------------------------------------------------------
	-- VIRGIN APPLIANCE
	------------------------------------------------------------------------------------------------------------------------------------	
	IF (SELECT COUNT(1) FROM  @App_Transitions_making) = 0
	BEGIN
		INSERT INTO @Output 
			(
				Clean_status, 
				Clean_type,
				Last_product_id,
				Last_Process_order_Id, 
				Last_Process_order_status_Id,
				Cleaned_limit_hour,
				Used_limit_hour,
				Cleaned_timer_hour,
				Used_timer_hour
			)
			VALUES
			(
				'Clean',
				(SELECT Type FROM @App_cleaning),
				NULL,
				NULL,
				NULL,
				@CleanedTimerLimit,
				@UsedTimerLimit,
				@CleanedTimer,
				@UsedTimer
			)
			GOTO LAFIN
	END

	IF (SELECT COUNT(1) FROM  @App_cleaning) = 0 AND @EvaluationTime <= @CurrentTransitionStatusTimestamp
	BEGIN
		INSERT INTO @Output 
			(
				Clean_status, 
				Clean_type,
				Last_product_id,
				Last_Process_order_Id, 
				Last_Process_order_status_Id,
				Cleaned_limit_hour,
				Used_limit_hour,
				Cleaned_timer_hour,
				Used_timer_hour
			)
			VALUES
			(
				'Clean',
				'Major',
				NULL,
				NULL,
				NULL,
				@CleanedTimerLimit,
				@UsedTimerLimit,
				@CleanedTimer,
				@UsedTimer
			)
			GOTO LAFIN
	
	END
	------------------------------------------------------------------------------------------------------------------------------------
	-- IF CLEANING IS ACTIVE THEN DIRTY
	------------------------------------------------------------------------------------------------------------------------------------
	IF (SELECT Status FROM @App_cleaning) IN ('Cleaning started', 'Cleaning completed', 'CTS_Cleaning_Started', 'CTS_Cleaning_Completed')
	BEGIN
		INSERT INTO @Output 
		(
			Clean_status, 
			Clean_type,
			Last_product_id,
			Last_Process_order_Id, 
			Last_Process_order_status_Id,
			Cleaned_limit_hour,
			Used_limit_hour,
			Cleaned_timer_hour,
			Used_timer_hour
		)
		VALUES
		(
			'Dirty',
			(SELECT Type FROM @App_cleaning),
			(SELECT Appliance_Product_Id FROM @App_Transitions),
			(SELECT Appliance_Process_order_Id FROM @App_Transitions),
			(SELECT Appliance_Process_order_status_Id FROM @App_Transitions),
			@CleanedTimerLimit,
			@UsedTimerLimit,
			@CleanedTimer,
			@UsedTimer
		) 
	END
	------------------------------------------------------------------------------------------------------------------------------------
	-- IF CLEANING IS UNFINISHED THEN DIRTY
	------------------------------------------------------------------------------------------------------------------------------------
	ELSE IF (SELECT Status FROM @app_cleaning) IN ('CTS_Cleaning_Cancelled','CTS_Cleaning_Rejected')
	BEGIN
		INSERT INTO @Output 
		(
			Clean_status, 
			Clean_type,
			Last_product_id, 
			Last_Process_order_Id, 
			Last_Process_order_status_Id,
			Cleaned_limit_hour,
			Used_limit_hour,
			Cleaned_timer_hour,
			Used_timer_hour
		)
			VALUES
			(
				'Dirty',
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				NULL
			) 
	END
	------------------------------------------------------------------------------------------------------------------------------------
	--	CLEANING IS AFTER LAST PRODUCT ASSIGNATION 
	--	CLEAN MAJOR OR MINOR
	------------------------------------------------------------------------------------------------------------------------------------

	IF (SELECT CASE 
			WHEN (SELECT Enter_time FROM @App_Transitions_making) >= (SELECT Location_process_order_start_time FROM @App_Transitions_making) 
			THEN (SELECT Enter_time FROM @App_Transitions_making)
			ELSE (SELECT Location_process_order_start_time FROM @App_Transitions_making)
			END) <= (SELECT COALESCE((SELECT End_time FROM @App_cleaning),'01-01-1970'))
	BEGIN
		IF (SELECT Type FROM @App_cleaning) = 'Major'
		BEGIN
			INSERT INTO @Output 
			(
				Clean_status, 
				Clean_type,
				Last_product_id,
				Last_Process_order_Id, 
				Last_Process_order_status_Id,
				Cleaned_limit_hour,
				Used_limit_hour,
				Cleaned_timer_hour,
				Used_timer_hour
			)
			VALUES
			(
				'Clean',
				(SELECT Type FROM @App_cleaning),
				NULL,
				NULL,
				NULL,
				@CleanedTimerLimit,
				@UsedTimerLimit,
				@CleanedTimer,
				@UsedTimer
			)
		END
		ELSE IF (SELECT Type FROM @App_cleaning) = 'Minor'
		BEGIN
			INSERT INTO @Output 
			(
				Clean_status, 
				Clean_type,
				Last_product_id,
				Last_Process_order_Id, 
				Last_Process_order_status_Id,
				Cleaned_limit_hour,
				Used_limit_hour,
				Cleaned_timer_hour,
				Used_timer_hour
			)
			VALUES
			(
				'Clean',
				(SELECT Type FROM @App_cleaning),
				(SELECT Appliance_Product_Id FROM @App_Transitions),
				(SELECT Appliance_Process_order_Id FROM @App_Transitions),
				(SELECT Appliance_Process_order_status_Id FROM @App_Transitions),
				@CleanedTimerLimit,
				@UsedTimerLimit,
				@CleanedTimer,
				@UsedTimer
			)
		END
	END

	------------------------------------------------------------------------------------------------------------------------------------
	--	CLEANING IS BEFORE LAST PRODUCT ASSIGNATION 
	--	IN USE OR DIRTY
	------------------------------------------------------------------------------------------------------------------------------------

	ELSE IF (SELECT CASE 
			WHEN (SELECT Enter_time FROM @App_Transitions_making) >= (SELECT Location_process_order_start_time FROM @App_Transitions_making) 
			THEN (SELECT Enter_time FROM @App_Transitions_making)
			ELSE (SELECT Location_process_order_start_time FROM @App_Transitions_making)
			END) > (SELECT COALESCE((SELECT End_time FROM @App_cleaning),'01-01-1970'))
	BEGIN
		IF (SELECT Location_Process_order_Id FROM @App_Transitions) IS NOT NULL
		BEGIN
			------------------------------------------------------------------------------------------------------------------------------------
			-- APPLIANCE PP NOT NULL; UTILIZED
			-- LOCATION PP NOT NULL;  CAN BE ACTIVE OR COMPLETED
			-- APP <> LPP
			-- LOCATION PP END TIME IS NOT NULL; IS COMPLETED
			-- A UTILIZED CONTAINER IN A LOCATION WITH A PROCESS ORDER COMPLETED
			-- THEN DIRTY
			------------------------------------------------------------------------------------------------------------------------------------
			IF  (SELECT Appliance_Process_order_Id FROM @App_Transitions) IS NOT NULL
				AND (SELECT Appliance_Process_order_Id FROM @App_Transitions) != (SELECT Location_Process_order_Id FROM @App_Transitions)
				AND @EvaluationTime >= (SELECT Location_Process_Order_End_time FROM @App_Transitions) 
				
			BEGIN
				INSERT INTO @Output 
				(
					Clean_status, 
					Clean_type,
					Last_product_id,
					Last_Process_order_Id, 
					Last_Process_order_status_Id,
					Cleaned_limit_hour,
					Used_limit_hour,
					Cleaned_timer_hour,
					Used_timer_hour
				)
				VALUES
				(
					'Dirty',
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL
				)
			END
			------------------------------------------------------------------------------------------------------------------------------------
			-- APPLIANCE PP NOT NULL; UTILIZED
			-- LOCATION PP NOT NULL;  CAN BE ACTIVE OR COMPLETED
			-- APP <> LPP
			-- LOCATION PP END TIME IS NOT NULL; IS ACTIVE
			-- A UTILIZED CONTAINER IN A LOCATION WITH A PROCESS ORDER COMPLETED
			-- THEN IN USE
			------------------------------------------------------------------------------------------------------------------------------------
			ELSE IF  (SELECT Appliance_Process_order_Id FROM @App_Transitions) IS NOT NULL
				AND (SELECT Appliance_Process_order_Id FROM @App_Transitions) != (SELECT Location_Process_order_Id FROM @App_Transitions)
				AND @EvaluationTime >= (SELECT Location_Process_Order_Start_time FROM @App_Transitions) 
				AND (@EvaluationTime < (SELECT Location_Process_Order_End_time FROM @App_Transitions) OR (SELECT Location_Process_Order_End_time FROM @App_Transitions) IS NULL)


			BEGIN
				INSERT INTO @Output 
				(
					Clean_status, 
					Clean_type,
					Last_product_id,
					Last_Process_order_Id, 
					Last_Process_order_status_Id,
					Cleaned_limit_hour,
					Used_limit_hour,
					Cleaned_timer_hour,
					Used_timer_hour
				)
				VALUES
				(
					'In Use',
					NULL,
					(SELECT Appliance_Product_Id FROM @App_Transitions),
					(SELECT Appliance_Process_order_Id FROM @App_Transitions),
					(SELECT Appliance_Process_order_status_Id FROM @App_Transitions),
					@CleanedTimerLimit,
					@UsedTimerLimit,
					@CleanedTimer,
					@UsedTimer
				)
			END
			------------------------------------------------------------------------------------------------------------------------------------
			-- APPLIANCE PP NOT NULL; UTILIZED
			-- LOCATION PP NOT NULL;  CAN BE ACTIVE OR COMPLETED
			-- APP = LPP
			-- LOCATION PP END TIME HAS NO IMPORTANCE HERE
			-- A UTILIZED CONTAINER IN A LOCATION WITH A PROCESS ORDER COMPLETED
			-- THEN IN USE
			------------------------------------------------------------------------------------------------------------------------------------
			ELSE IF (SELECT Appliance_Process_order_Id FROM @App_Transitions) IS NOT NULL
					AND (SELECT Appliance_Process_order_Id FROM @App_Transitions) = (SELECT Location_Process_order_Id FROM @App_Transitions)
					AND (SELECT Location_process_order_status_desc FROM @App_Transitions) = 'Complete'

			BEGIN
				INSERT INTO @Output 
				(
					Clean_status, 
					Clean_type,
					Last_product_id,
					Last_Process_order_Id, 
					Last_Process_order_status_Id,
					Cleaned_limit_hour,
					Used_limit_hour,
					Cleaned_timer_hour,
					Used_timer_hour
				)
				VALUES
				(
					'In Use',
					NULL,
					(SELECT Appliance_Product_Id FROM @App_Transitions),
					(SELECT Appliance_Process_order_Id FROM @App_Transitions),
					(SELECT Appliance_Process_order_status_Id FROM @App_Transitions),
					@CleanedTimerLimit,
					@UsedTimerLimit,
					@CleanedTimer,
					@UsedTimer
				)
			END
						ELSE IF (SELECT Appliance_Process_order_Id FROM @App_Transitions) IS NOT NULL
					AND (SELECT Appliance_Process_order_Id FROM @App_Transitions) = (SELECT Location_Process_order_Id FROM @App_Transitions)
					AND (SELECT Location_process_order_status_desc FROM @App_Transitions) = 'Active'

			BEGIN
				INSERT INTO @Output 
				(
					Clean_status, 
					Clean_type,
					Last_product_id,
					Last_Process_order_Id, 
					Last_Process_order_status_Id,
					Cleaned_limit_hour,
					Used_limit_hour,
					Cleaned_timer_hour,
					Used_timer_hour
				)
				VALUES
				(
					'Clean',
					(SELECT Type FROM @App_cleaning),
					(SELECT CASE
					WHEN (SELECT Type FROM @App_cleaning) = 'Major'
					THEN NULL
					ELSE (SELECT Appliance_Product_Id FROM @App_Transitions)
					END),
					(SELECT CASE
					WHEN (SELECT Type FROM @App_cleaning) = 'Major'
					THEN NULL
					ELSE (SELECT Appliance_Process_order_Id FROM @App_Transitions)
					END),
					(SELECT CASE
					WHEN (SELECT Type FROM @App_cleaning) = 'Major'
					THEN NULL
					ELSE (SELECT Appliance_Process_order_status_Id FROM @App_Transitions)
					END),
					@CleanedTimerLimit,
					@UsedTimerLimit,
					@CleanedTimer,
					@UsedTimer
				)
			END

			ELSE IF (SELECT Appliance_Process_order_Id FROM @App_Transitions) IS NULL
					AND @EvaluationTime >= (SELECT Location_Process_Order_Start_time FROM @App_Transitions) 
					AND (@EvaluationTime < (SELECT Location_Process_Order_End_time FROM @App_Transitions) OR (SELECT Location_Process_Order_End_time FROM @App_Transitions) IS NULL)


			BEGIN
				INSERT INTO @Output 
				(
					Clean_status, 
					Clean_type,
					Last_product_id,
					Last_Process_order_Id, 
					Last_Process_order_status_Id,
					Cleaned_limit_hour,
					Used_limit_hour,
					Cleaned_timer_hour,
					Used_timer_hour
				)
				VALUES
				(
					'Clean',
					(SELECT Type FROM @App_cleaning),
					(SELECT CASE
					WHEN (SELECT Type FROM @App_cleaning) = 'Major'
					THEN NULL
					ELSE (SELECT Appliance_Product_Id FROM @App_Transitions)
					END),
					(SELECT CASE
					WHEN (SELECT Type FROM @App_cleaning) = 'Major'
					THEN NULL
					ELSE (SELECT Appliance_Process_order_Id FROM @App_Transitions)
					END),
					(SELECT CASE
					WHEN (SELECT Type FROM @App_cleaning) = 'Major'
					THEN NULL
					ELSE (SELECT Appliance_Process_order_status_Id FROM @App_Transitions)
					END),
					@CleanedTimerLimit,
					@UsedTimerLimit,
					@CleanedTimer,
					@UsedTimer
				)
			END
		END
		ELSE
		BEGIN
			------------------------------------------------------------------------------------------------------------------------------------
			-- APPLIANCE PP NOT NULL; UTILIZED
			-- LOCATION PP IS NULL;  IN A NON MAKING UNIT
			-------------------------------------------------------------------------------------------------------------------------------------
			IF (SELECT Location_Process_order_Id FROM @App_Transitions_making)<>(SELECT Appliance_Process_order_Id FROM @App_Transitions)
			BEGIN
				INSERT INTO @Output 
				(
					Clean_status, 
					Clean_type,
					Last_product_id,
					Last_Process_order_Id, 
					Last_Process_order_status_Id,
					Cleaned_limit_hour,
					Used_limit_hour,
					Cleaned_timer_hour,
					Used_timer_hour
				)
				VALUES
				(
					'Dirty',
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL
				)
			END
			ELSE 
			BEGIN
				INSERT INTO @Output 
				(
					Clean_status, 
					Clean_type,
					Last_product_id,
					Last_Process_order_Id, 
					Last_Process_order_status_Id,
					Cleaned_limit_hour,
					Used_limit_hour,
					Cleaned_timer_hour,
					Used_timer_hour
				)
				VALUES
				(
					'In Use',
					NULL,
					(SELECT Appliance_Product_Id FROM @App_Transitions),
					(SELECT Appliance_Process_order_Id FROM @App_Transitions),
					(SELECT Appliance_Process_order_status_Id FROM @App_Transitions),
					@CleanedTimerLimit,
					@UsedTimerLimit,
					@CleanedTimer,
					@UsedTimer
				)
			END
		END



	END


	
	IF	@UsedTimer >= @UsedTimerLimit 
	BEGIN
		DELETE @Output 
		INSERT INTO @Output 
		(
			Clean_status, 
			Clean_type,
			Last_product_id, 
			Last_Process_order_Id, 
			Last_Process_order_status_Id,
			Cleaned_limit_hour,
			Used_limit_hour,
			Cleaned_timer_hour,
			Used_timer_hour,
			Timer_Exception -- None, Cleaning, Usage
		)
			VALUES
			(
				'Dirty',
				NULL,
				NULL,
				NULL,
				NULL,
				@CleanedTimerLimit,
				@UsedTimerLimit,
				@CleanedTimer,
				@UsedTimer,
				'Usage'
			) 
	END 
	IF	@CleanedTimer >= @CleanedTimerLimit 
	BEGIN
		DELETE @Output 
		INSERT INTO @Output 
		(
			Clean_status, 
			Clean_type,
			Last_product_id, 
			Last_Process_order_Id, 
			Last_Process_order_status_Id,
			Cleaned_limit_hour,
			Used_limit_hour,
			Cleaned_timer_hour,
			Used_timer_hour,
			Timer_Exception -- None, Cleaning, Usage
		)
			VALUES
			(
				'Dirty',
				NULL,
				NULL,
				NULL,
				NULL,
				@CleanedTimerLimit,
				@UsedTimerLimit,
				@CleanedTimer,
				@UsedTimer,
				'Cleaning'
			) 
	END 
LAFIN:
RETURN
END
