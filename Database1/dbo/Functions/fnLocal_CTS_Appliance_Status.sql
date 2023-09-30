

/*=====================================================================================================================
Local Function: fnLocal_CTS_Appliance_Status
=====================================================================================================================
 Author				:	Francois Bergeron (AutomaTech Canada)
 Date created			:	2021-08-12
 Version 				:	1.0
 Description			:	The purpose of this function is to determine the appliance cleaning state
							- In Use
							- Dirty
							- Clean (cleaning type)
 Editor tab spacing	: 4 



EDIT HISTORY:

========		====	  		====					=====
1.0			2021-08-12		F.Bergeron				Initial Release 
1.1			2021-11-23		F.Bergeron				Add threshold evaluation
1.2			2022-01-31		F.Bergeron				Code multiple cleaning phases
1.3			2022-02-07		F.Bergeron				Add time parameter to enable status evaluation at anytime
1.4			2023-06-26		U. Lapierre				Adapt for Code review


Testing Code

 SELECT * FROM fnLocal_CTS_Appliance_Status(1268670,NULL)
====================================================================================================================== */


CREATE   FUNCTION [dbo].[fnLocal_CTS_Appliance_Status] 
(
	@ApplianceId 		INTEGER,
	@evaluationTime		DATETIME = NULL
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
	Timer_Exception					VARCHAR(50) -- None, Cleaning, Usage
)
					
AS
BEGIN
DECLARE
	@ApplianceleaningUDESubTypeDesc			VARCHAR(50),
	@ApplianceCleaningUDESubTypeId			VARCHAR(50),
	@ApplianceCleaningTypeVarId				INTEGER,
	@CurrentTransitionEventId				INTEGER,	
	@CurrentTransitionStatusId				INTEGER,
	@CurrentTransitionStatusDesc			VARCHAR(25),
	@CurrentTransitionEDPPID				INTEGER,
	@CurrentTransitionEDPPIDProdId			INTEGER,
	@CurrentTransitionEDPPIDStatusId		INTEGER,
	@CurrentTransitionEDAppliedProductId	INTEGER,
	@CleanedTimerLimit						FLOAT,
	@CleanedTimer							FLOAT,
	@UsedTimerLimit							FLOAT,
	@UsedTimer								FLOAT,
	@ApplianceTimestamp						DATETIME,
	@CurrentTransitionStatusTimestamp		DATETIME,
	@CleanedTimerSeconds					INTEGER,
	@ApplianceLastUsed						DATETIME,
	@UsedTimerSeconds						INTEGER;

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
	);


	DECLARE @App_Transitions TABLE
	(
		Location_id					INTEGER,
		Location_desc				VARCHAR(50),
		Product_Id					INTEGER,
		Product_code				VARCHAR(25),
		Process_order_Id			INTEGER,
		Process_order_desc			VARCHAR(50),
		Process_order_status_Id		INTEGER,
		Process_order_Status_desc	VARCHAR(50),
		Process_Order_start_time	DATETIME,
		Process_Order_End_time		DATETIME,
		Start_time					DATETIME,
		End_time					DATETIME,
		User_Id						INTEGER,
		Username					VARCHAR(100),
		User_AD						VARCHAR(100),
		Err_Warn					VARCHAR(500)
	);

	IF @evaluationTime IS NULL
		SET @evaluationTime = GETDATE();

	/* Get appliance cleaning, with type and status*/
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
	FROM	[dbo].[fnLocal_CTS_Appliance_Cleanings](@ApplianceId, NULL, @EvaluationTime);

	
	SET @CleanedTimer = DATEDIFF(hour,COALESCE((SELECT End_time FROM @App_cleaning),(SELECT Timestamp FROM dbo.events WITH(NOLOCK) WHERE Event_id = @ApplianceId)),GETDATE());
	
	SET @CleanedTimerSeconds = DATEDIFF(Second,COALESCE((SELECT End_time FROM @App_cleaning),(SELECT Timestamp FROM dbo.events WITH(NOLOCK) WHERE Event_id = @ApplianceId)),GETDATE());


	SELECT	@CleanedTimerLimit = TFV.Value FROM dbo.Prod_units_base PUB
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
	WHERE	PUB.PU_ID = (SELECT PU_ID FROM dbo.events WITH(NOLOCK) WHERE event_id = @ApplianceId)	;						

	SELECT  @ApplianceLastUsed = MAX(Q.start_time)
	FROM	event_components EC  
			OUTER APPLY(
			SELECT TOP 1	EST.Start_time,PS.prodStatus_desc 
			FROM			dbo.Event_Status_Transitions EST WITH(NOLOCK) 
							JOIN dbo.Production_Status PS
								ON PS.ProdStatus_Id = EST.Event_Status 
			WHERE			EST.event_id = EC.event_id 
							AND PS.prodStatus_desc = 'In Use' 
			ORDER BY		EST.Start_time DESC)Q
			GROUP BY		EC.source_event_id ;




	SELECT	@UsedTimerLimit = TFV.Value FROM dbo.Prod_units_base PUB
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
	WHERE	PUB.PU_ID = (SELECT PU_ID FROM dbo.events WITH(NOLOCK) WHERE event_id = @ApplianceId);	
	

	SELECT TOP 1	@CurrentTransitionStatusTimestamp = EST.start_time,
					@CurrentTransitionStatusId = E.Event_Status,
					@CurrentTransitionEventId = E.event_id,
					@CurrentTransitionEDPPID = ED.PP_ID, 
					@CurrentTransitionStatusDesc = PS.ProdStatus_desc, 
					@CurrentTransitionEDAppliedProductId = E.applied_product
	FROM			dbo.event_components EC WITH(NOLOCK) 
					JOIN dbo.events E WITH(NOLOCK) 
						ON E.event_id = EC.event_id 
					LEFT JOIN dbo.event_details ED WITH(NOLOCK)
						ON ED.event_id = E.event_id
					JOIN dbo.Event_Status_Transitions EST  WITH(NOLOCK) 
						ON EST.Event_Id = E.Event_Id
					JOIN dbo.Production_status PS WITH(NOLOCK) 
						ON PS.ProdStatus_Id = E.event_status
	WHERE			EC.Source_event_id = @ApplianceId 
					AND EST.start_time <= @evaluationTime
	ORDER BY		EST.Start_Time DESC;
												

	SET @ApplianceTimestamp = (SELECT Timestamp FROM dbo.events E WITH(NOLOCK) WHERE E.event_id = @ApplianceId)	;										
	SET @UsedTimerSeconds = COALESCE(DATEDIFF(Second,@ApplianceLastUsed,GETDATE()), DATEDIFF(Second,@ApplianceTimestamp,GETDATE()));
	SET @UsedTimer = COALESCE(DATEDIFF(Hour,@ApplianceLastUsed,GETDATE()), DATEDIFF(hour,@ApplianceTimestamp,GETDATE()))	;			
	
	

	SELECT	@CurrentTransitionEDPPIDProdId = Prod_Id,
			@CurrentTransitionEDPPIDStatusId = PP_status_id 
	FROM	dbo.production_Plan WITH(NOLOCK) 
	WHERE	PP_ID = @CurrentTransitionEDPPID;

	
	
	/* Evaluate status from @Loc_Products and @Loc_cleaning */
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
			COALESCE(@CurrentTransitionEDPPIDProdId,@CurrentTransitionEDAppliedProductId),
			@CurrentTransitionEDPPID,
			@CurrentTransitionStatusId,
			@CleanedTimerLimit,
			@UsedTimerLimit,
			@CleanedTimer,
			@UsedTimer
		) ;
	END

	ELSE IF  (SELECT Status FROM @app_cleaning) IN ('CTS_Cleaning_Cancelled','CTS_Cleaning_Rejected')
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
				'',
				COALESCE(@CurrentTransitionEDPPIDProdId,@CurrentTransitionEDAppliedProductId),
				@CurrentTransitionEDPPID,
				@CurrentTransitionStatusId,
				@CleanedTimerLimit,
				@UsedTimerLimit,
				NULL,
				NULL
			) ;
	END

	/*	CLEANING IS AFTER LAST PRODUCT ASSIGNATION 
		CLEAN MAJOR		*/
	ELSE IF @CurrentTransitionStatusDesc = 'Clean' AND COALESCE((SELECT Type FROM @App_cleaning),'Major') = 'Major'
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
		);
	END

	/*	CLEAN MINOR	*/
	ELSE IF @CurrentTransitionStatusDesc = 'Clean' AND COALESCE((SELECT Type FROM @App_cleaning),'Major') = 'Minor'
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
			'Minor',
			COALESCE(@CurrentTransitionEDPPIDProdId,@CurrentTransitionEDAppliedProductId),
			@CurrentTransitionEDPPID,
			@CurrentTransitionStatusId,
			@CleanedTimerLimit,
			@UsedTimerLimit,
			@CleanedTimer,
			@UsedTimer
		);
	END

	ELSE IF @CurrentTransitionStatusDesc = 'In use' 
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
			COALESCE(@CurrentTransitionEDPPIDProdId,@CurrentTransitionEDAppliedProductId),
			@CurrentTransitionEDPPID,
			@CurrentTransitionStatusId,
			@CleanedTimerLimit,
			@UsedTimerLimit,
			@CleanedTimer,
			@UsedTimer
		);
	END

	ELSE IF @CurrentTransitionStatusDesc = 'Dirty' 
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
			COALESCE(@CurrentTransitionEDPPIDProdId,@CurrentTransitionEDAppliedProductId),
			@CurrentTransitionEDPPID,
			@CurrentTransitionStatusId,
			@CleanedTimerLimit,
			@UsedTimerLimit,
			@CleanedTimer,
			@UsedTimer
		);
	END

/*	 TIMER EXCEPTION
	 CLEAN AND USAGE TIMERS CASES (CLEAN TIMER < USAGE TIMER THEN USAGE TIMER BECOMES CLEAN TIMER
	 CLEAN TIMER < USAGE TIMER BOTH ARE EVALUATED, THE SMALLEST DIFF OWNS THE REASON
*/

	IF @CleanedTimerSeconds > @CleanedTimerLimit*3600 
	BEGIN
		DELETE @Output
		INSERT INTO @Output (
		Clean_status, 
					Clean_type,
					Last_product_id, 
					Last_Process_order_Id, 
					Last_Process_order_status_Id,
					Cleaned_limit_hour,
					Used_limit_hour,
					Cleaned_timer_hour,
					Used_timer_hour,
					Timer_Exception /* None, Cleaning, Usage */
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
					'Clean timer limit exceeded'
					);
		RETURN
	END
	IF 	@CleanedTimerSeconds <= @CleanedTimerLimit*3600  
		AND @CleanedTimerSeconds <= @UsedTimerSeconds
		AND @CleanedTimerSeconds > @UsedTimerLimit*3600
	BEGIN
		DELETE @Output
		INSERT INTO @Output (
		Clean_status, 
					Clean_type,
					Last_product_id, 
					Last_Process_order_Id, 
					Last_Process_order_status_Id,
					Cleaned_limit_hour,
					Used_limit_hour,
					Cleaned_timer_hour,
					Used_timer_hour,
					Timer_Exception /* None, Cleaning, Usage */
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
					'Use timer limit exceeded'
					);
		RETURN
	END
	IF 	@CleanedTimerSeconds <= @CleanedTimerLimit*3600  
		AND @CleanedTimerSeconds > @UsedTimerSeconds
		AND @UsedTimerSeconds > @UsedTimerLimit*3600
	BEGIN
		DELETE @Output
		INSERT INTO @Output (
		Clean_status, 
					Clean_type,
					Last_product_id, 
					Last_Process_order_Id, 
					Last_Process_order_status_Id,
					Cleaned_limit_hour,
					Used_limit_hour,
					Cleaned_timer_hour,
					Used_timer_hour,
					Timer_Exception /* None, Cleaning, Usage */
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
					'Use timer limit exceeded'
					);
		RETURN
	END
												

RETURN
END

