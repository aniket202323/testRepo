

/*=====================================================================================================================
Local Function: fnLocal_CTS_Location_Status
=====================================================================================================================

 Author				:	Francois Bergeron (AutomaTech Canada)
 Date created			:	2021-08-12
 Version 				:	1.1
 Description			:	The purpose of this function is to determine the location cleaning state
							- In Use
							- Dirty
							- Clean (cleaning type)
							IF the location is virgin, then it is considered major clean
 Editor tab spacing	: 4 


 ==================================================================================================
 EDIT HISTORY:

 ========		====	  		====					=====
1.0			2021-08-12		F.Bergeron				Initial Release 
1.1			2021-11-23		F.Bergeron				Add threshold evaluation
1.2			2021-01-21		F.Bergeron				Timer validation corrections
1.3			2022-01-24		U.Lapierre				Rename cleaning statuses
1.4			2022-01-26		F.Bergeron				Incluse logic around cancelled or rejected cleaning
1.5			2022-02-07		F.Bergeron				Add time parameter to enable status evaluation at anytime
1.6			2022-02-08		F.Bergeron				Evaluate order status from Production plants starts
1.7			2022-02-11		F.Bergeron				Add cleaning status for SSE purposes
2.0			2023-03-15		U.Lapierre				Add maintenance event
2.1			2023-06-27		U. Lapierre				Adapt for Code review

Testing Code

 SELECT * FROM fnLocal_CTS_Location_Status(10425,NULL)
==================================================================================================*/


CREATE   FUNCTION [dbo].[fnLocal_CTS_Location_Status] 
(
	@LocationId 		INTEGER,
	@evaluationTime		DATETIME = NULL

)
RETURNS @Output TABLE 
(
	Location_status					VARCHAR(25),
	Cleaning_status					VARCHAR(25),
	Cleaning_type					VARCHAR(25),
	Last_product_id					INTEGER,
	Last_Process_order_Id			INTEGER,
	Last_Process_order_status_Id	INTEGER,
	Maintenance_Status				varchar(50),
	Cleaned_timer_hour				FLOAT,
	Cleaned_limit_hour				FLOAT,
	Used_timer_hour					FLOAT,
	Used_limit_hour					FLOAT,
	Timer_Exception					VARCHAR(25) /* None, Cleaning, Usage */
)
					
AS
BEGIN
	DECLARE
	@LocationCleaningUDESubTypeDesc			VARCHAR(50),
	@LocationCleaningUDESubTypeId			VARCHAR(50),
	@LocationCleaningTypeVarId				INTEGER,
	@CleanedTimerLimit						FLOAT,
	@CleanedTimer							FLOAT,
	@UsedTimerLimit							FLOAT,
	@UsedTimer								FLOAT,
	@CleanedTimerSecond						INTEGER,
	@UsedTimerSecond						INTEGER;

	DECLARE @loc_cleaning TABLE
	(
	Status						VARCHAR(25),
	type						VARCHAR(25),
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
	UDE_Id						INTEGER,
	Err_Warn					VARCHAR(500)
	);


	DECLARE @Loc_Products TABLE
	(
	Product_Id					INTEGER,
	Product_code				VARCHAR(50),
	Process_order_Id			INTEGER,
	Process_order_desc			VARCHAR(50),
	Process_order_status_id		VARCHAR(50),
	Process_order_status_desc	VARCHAR(50),
	Location_id					INTEGER,
	Location_desc				VARCHAR(50),
	Start_time					DATETIME,
	End_time					DATETIME
	);

	DECLARE @Loc_Maintenance TABLE (
	Status					varchar(50),
	StartTime				datetime,
	EndTime					datetime
	);

	IF @evaluationTime IS NULL
		SET @evaluationTime = GETDATE();
	
	SELECT	@CleanedTimerLimit = TFV.Value 
	FROM dbo.Prod_units_base PUB		WITH(NOLOCK)
	JOIN dbo.Table_Fields_Values TFV	WITH(NOLOCK)	ON  TFV.KeyId = PUB.PU_Id
	JOIN dbo.Table_Fields TF			WITH(NOLOCK) 	ON TF.Table_Field_Id = TFV.Table_Field_Id
														AND TF.Table_Field_Desc = 'CTS time since last cleaned threshold (hours)'
														AND TF.TableId =	(
																			SELECT	TableId 
																			FROM	dbo.Tables WITH(NOLOCK) 
																			WHERE	TableName = 'Prod_units'
																			)
	WHERE	PUB.PU_ID = @LocationId;


	SELECT	@UsedTimerLimit = TFV.Value 
	FROM dbo.Prod_units_base PUB		WITH(NOLOCK)
	JOIN dbo.Table_Fields_Values TFV	WITH(NOLOCK)	ON  TFV.KeyId = PUB.PU_Id
	JOIN dbo.Table_Fields TF			WITH(NOLOCK) 	ON TF.Table_Field_Id = TFV.Table_Field_Id
														AND TF.Table_Field_Desc = 'CTS time since last used threshold (hours)'
														AND TF.TableId =	(
																			SELECT	TableId 
																			FROM	dbo.Tables WITH(NOLOCK) 
																			WHERE	TableName = 'Prod_units'
																			)
 	WHERE	PUB.PU_ID = @LocationId;

	/* Get location celaning, with type and status */
	INSERT INTO		@loc_cleaning
	(
	Status,
	type,
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
	UDE_Id,
	Err_Warn
	)
	SELECT 	Status,
			type,
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
			UDE_Id,
			Err_Warn
	FROM	[dbo].[fnLocal_CTS_Location_Cleanings](@LocationId, NULL, @EvaluationTime);


	
	SET @CleanedTimerSecond = DATEDIFF(Second,(SELECT End_time FROM @loc_cleaning),GETDATE());
	SET @CleanedTimer = DATEDIFF(hour,(SELECT End_time FROM @loc_cleaning),GETDATE());


	INSERT INTO	@Loc_Products
	(
			Product_Id,
			Product_code,
			Process_order_Id,
			Process_order_desc,
			Process_order_status_id,
			Process_order_status_desc,
			Location_id,
			Location_desc,
			Start_time,
			End_time
	)
	SELECT 	Product_Id,
			Product_code,
			Process_order_Id,
			Process_order_desc,
			Process_order_status_id,
			Process_order_status_desc,
			Location_id,
			Location_desc,
			Start_time,
			end_time
	FROM	[dbo].[fnLocal_CTS_Location_Products](@LocationId, NULL, @EvaluationTime);

	
	SET @UsedTimerSecond = DATEDIFF(Second,(SELECT Start_time FROM @Loc_Products),GETDATE());
	SET @UsedTimer = DATEDIFF(hour,(SELECT Start_time FROM @Loc_Products),GETDATE());

	INSERT @Loc_Maintenance (Status, StartTime, EndTime)
	SELECT TOP 1 p.prodStatus_Desc, ude.Start_Time, UDE.end_Time
	FROM dbo.user_defined_events ude	WITH(NOLOCK)
	JOIN dbo.event_Subtypes est			WITH(NOLOCK)	ON est.event_SubType_Id = ude.event_subtype_id
	JOIN dbo.production_status p		WITH(NOLOCK)	ON ude.event_status = p.prodStatus_Id
	WHERE ude.pu_id = @LocationId 
		AND est.event_subtype_desc = 'CST Maintenance';

	/* Evaluate status from @Loc_Products and @Loc_cleaning */
	/*========================================================
	CLEANING IN PROGRESS
	==========================================================*/

	IF (SELECT Status FROM @loc_cleaning) IN ('Cleaning started', 'Cleaning completed', 'CTS_Cleaning_Started', 'CTS_Cleaning_Completed')
	BEGIN
		INSERT INTO @Output 
		(
			Location_status,
			Cleaning_status,
			Cleaning_type,
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
			(SELECT Status FROM @loc_cleaning),
			(SELECT Type FROM @loc_cleaning),
			(SELECT product_id FROM @Loc_Products),
			(SELECT Process_order_id FROM @Loc_Products),
			(SELECT Process_order_status_id FROM @Loc_Products),
				@CleanedTimerLimit,
				@UsedTimerLimit,
				@CleanedTimer,
				@UsedTimer
		) ;
			
		GOTO The_End;


	END

	/*========================================================
	Maintenance IN PROGRESS
	==========================================================*/
	IF (SELECT Status FROM @loc_Maintenance) IN ('CST_Maintenance_Started')
	BEGIN
		INSERT INTO @Output 
		(
			Location_status,
			Cleaning_status,
			Cleaning_type,
			Maintenance_Status,
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
			NULL,
			(SELECT status FROM @Loc_Maintenance) ,
			NULL,
			NULL,
			NULL,
			@CleanedTimerLimit,
			@UsedTimerLimit,
			@CleanedTimer,
			@UsedTimer
		) ;
			
		GOTO The_End;
	END

	/*========================================================
	If last action was a maintenance that is finished| 
	==========================================================*/
	ELSE IF COALESCE((SELECT Start_time FROM @loc_cleaning),'1-Jan-1970 00:01') < COALESCE((SELECT starttime FROM @Loc_Maintenance), '1-Jan-1970 00:00')
			AND COALESCE((SELECT Start_time FROM @loc_Products),'1-Jan-1970 00:01') < COALESCE((SELECT starttime FROM @Loc_Maintenance), '1-Jan-1970 00:00')
	BEGIN
		/*it finishes a maintenance.  Needs to be cleaned */
		INSERT INTO @Output 
		(
			Location_status,
			Cleaning_status,
			Cleaning_type,
			Maintenance_Status,
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
			NULL,--(SELECT Status FROM @loc_cleaning),
			NULL,--(SELECT Type FROM @loc_cleaning),
			(SELECT status FROM @Loc_Maintenance) ,
			NULL,--(SELECT product_id FROM @Loc_Products),
			NULL,--(SELECT Process_order_id FROM @Loc_Products),
			NULL,--(SELECT Process_order_status_id FROM @Loc_Products),
			@CleanedTimerLimit,
			@UsedTimerLimit,
			@CleanedTimer,
			@UsedTimer
		) ;
			
		GOTO The_End;
	END


	/*========================================================
	 CLEANING IS BEFORE ORDER STARTED
	 IN USE IF ORDER IS ACTIVE
	 DIRTY IF ORDER IS COMPLETED|  
	==========================================================*/

	ELSE IF (SELECT Start_time FROM @loc_cleaning) < (SELECT start_time FROM @Loc_Products)
	BEGIN
		IF @evaluationTime >= (SELECT Start_time FROM @Loc_Products) AND  (@evaluationTime < (SELECT End_time FROM @Loc_Products) OR (SELECT End_time FROM @Loc_Products) IS NULL)
		BEGIN
		INSERT INTO @Output 
		(
			Location_status,
			Cleaning_status,
			Cleaning_type,
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
				NULL,
				(SELECT product_id FROM @Loc_Products),
				(SELECT Process_order_id FROM @Loc_Products),
				(SELECT Process_order_status_id FROM @Loc_Products),
				@CleanedTimerLimit,
				@UsedTimerLimit,
				@CleanedTimer,
				@UsedTimer
			) 
			GOTO The_End;
		END
		ELSE IF @evaluationTime >= (SELECT End_time FROM @Loc_Products)
		BEGIN
		INSERT INTO @Output 
		(
			Location_status,
			Cleaning_status,
			Cleaning_type,
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
				(SELECT product_id FROM @Loc_Products),
				(SELECT Process_order_id FROM @Loc_Products),
				(SELECT Process_order_status_id FROM @Loc_Products),
				@CleanedTimerLimit,
				@UsedTimerLimit,
				@CleanedTimer,
				@UsedTimer
			) 
			GOTO The_End;
		END
	END

	/*========================================================
	 CLEANING IS AFTER ORDER STARTED OR ORDER NEVER STARTED
	 WHEN LOCATION CLEANING TYPE IS MAJOR DO NOT GET PRODUCT DETAILS 
	==========================================================*/
	ELSE IF (SELECT Start_time FROM @loc_cleaning) >= COALESCE((SELECT start_time FROM @Loc_Products),'01-01-1970')  AND (SELECT Status FROM @loc_cleaning) IN ('Cleaning approved', 'CTS_Cleaning_Approved')
	BEGIN

		IF (SELECT Type FROM @loc_cleaning) = 'Major'
		BEGIN 
			INSERT INTO @Output 
			(
				Location_status,
				Cleaning_status,
				Cleaning_type,
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
					NULL,
					(SELECT Type FROM @loc_cleaning),
					NULL,
					NULL,
					NULL,
					@CleanedTimerLimit,
					@UsedTimerLimit,
					@CleanedTimer,
					@UsedTimer
				) ;
		END
		ELSE IF (SELECT Type FROM @loc_cleaning) = 'Minor'
		BEGIN 
			INSERT INTO @Output 
			(
				Location_status,
				Cleaning_status,
				Cleaning_type,
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
					NULL,
					(SELECT Type FROM @loc_cleaning),
					(SELECT product_id FROM @Loc_Products),
					(SELECT Process_order_id FROM @Loc_Products),
					(SELECT Process_order_status_id FROM @Loc_Products),
					@CleanedTimerLimit,
					@UsedTimerLimit,
					@CleanedTimer,
					@UsedTimer
				) ;
			END
			GOTO The_End;
	END

	/*========================================================
	VIRGIN LOCATION
	Major clean
	==========================================================*/
	ELSE IF (SELECT COUNT(1) FROM @loc_cleaning) = 0 AND (SELECT COUNT(1) FROM @Loc_Products) = 0
	BEGIN
		INSERT INTO @Output 
		(
			Location_status,
			Cleaning_status,
			Cleaning_type,
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
			NULL,
			(SELECT Type FROM @loc_cleaning),
			NULL,
			NULL,
			NULL,
			@CleanedTimerLimit,
			@UsedTimerLimit,
			@CleanedTimer,
			@UsedTimer
		) ;
		GOTO The_End;
	END

	/*========================================================
	CLEANING NEVER DONE
	BUT ORDER ONCE EXECUTED
	IF ORDER IS COMPLETE THEN DIRTY ELSE IN USE
	==========================================================*/
	ELSE IF (SELECT COUNT(1) FROM @loc_cleaning) = 0 AND (SELECT COUNT(1) FROM @Loc_Products) = 1 AND (SELECT Process_order_status_desc FROM @Loc_Products) !='Complete'
	BEGIN
		INSERT INTO @Output 
		(
			Location_status,
			Cleaning_status,
			Cleaning_type,
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
			'In use',
			NULL,
			NULL,
			(SELECT product_id FROM @Loc_Products),
			(SELECT Process_order_id FROM @Loc_Products),
			(SELECT Process_order_status_id FROM @Loc_Products),
			@CleanedTimerLimit,
			@UsedTimerLimit,
			@CleanedTimer,
			@UsedTimer
		) ;
		GOTO The_End;
	END

	ELSE IF (SELECT COUNT(1) FROM @loc_cleaning) = 0 AND (SELECT COUNT(1) FROM @Loc_Products) = 1 AND (SELECT Process_order_status_desc FROM @Loc_Products) ='Complete'
	BEGIN
		INSERT INTO @Output 
		(
			Location_status,
			Cleaning_status,
			Cleaning_type,
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
			(SELECT Status FROM @loc_cleaning),
			(SELECT Type FROM @loc_cleaning),
			(SELECT product_id FROM @Loc_Products),
			(SELECT Process_order_id FROM @Loc_Products),
			(SELECT Process_order_status_id FROM @Loc_Products),
				@CleanedTimerLimit,
				@UsedTimerLimit,
				@CleanedTimer,
				@UsedTimer
		) ;
		GOTO The_End;
	END
	ELSE IF (SELECT Start_time FROM @loc_cleaning) >= COALESCE((SELECT start_time FROM @Loc_Products),'01-01-1970')  AND (SELECT Status FROM @loc_cleaning) IN ('CTS_Cleaning_Cancelled','CTS_Cleaning_Rejected')
	BEGIN
		INSERT INTO @Output 
		(
			Location_status,
			Cleaning_status,
			Cleaning_type,
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
				(SELECT Status FROM @loc_cleaning),
				NULL,
				(SELECT product_id FROM @Loc_Products),
				(SELECT Process_order_id FROM @Loc_Products),
				(SELECT Process_order_status_id FROM @Loc_Products),
					@CleanedTimerLimit,
					@UsedTimerLimit,
					@CleanedTimer,
					@UsedTimer
			) ;
			GOTO The_End;
	END
	IF(SELECT Location_status FROM @Output) = 'In use'
	BEGIN
		IF	@UsedTimerSecond >= @UsedTimerLimit*3600
		BEGIN
			DELETE @Output 
			INSERT INTO @Output 
			(
				Location_status,
				Cleaning_status,
				Cleaning_type,
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
					NULL,
					@CleanedTimerLimit,
					@UsedTimerLimit,
					@CleanedTimer,
					@UsedTimer,
					'Usage'
				) ;
		END 
	END

	IF(SELECT location_status FROM @Output) = 'Clean'
	BEGIN
		IF	@CleanedTimerSecond >= @CleanedTimerLimit *3600
		BEGIN
			DELETE @Output 
			INSERT INTO @Output 
			(
				Location_status,
				Cleaning_status,
				Cleaning_type,
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
					NULL,
					@CleanedTimerLimit,
					@UsedTimerLimit,
					@CleanedTimer,
					@UsedTimer,
					'Cleaning'
				) ;
		END 
	END

  The_End:
RETURN
END
