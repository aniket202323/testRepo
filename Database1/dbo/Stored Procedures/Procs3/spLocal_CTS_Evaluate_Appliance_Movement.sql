
--------------------------------------------------------------------------------------------------
-- Table function: fnLocal_CTS_Evaluate_Appliance_Movement
--------------------------------------------------------------------------------------------------
-- Author				: Francois Bergeron, Symasol
-- Date created			: 2021-10-05
-- Version 				: Version 1.0
-- SP Type				: Proficy Plant Applications
-- Caller				: SQL
-- Description			: Evaluation appliance movement to location
--						  This procedure evaluates container movement to a location
--						  Against RMI (Location and Status), PO,
--						  Location and appliance cleaning state compatibility and
--						  Reservations
-- Editor tab spacing	: 4
-------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ===========================================================================================
-- 1.0		2022-06-27		F. Bergeron				Initial Release 
-- 1.1		2022-09-13		F. Bergeron				FIx cleaning matrix
-- 1.2		2022-09-14		U.Lapierre				Fix cleaning matrix
-- 1.3		2022-12-12		K. Michel				Update return message
-- 1.4		2023-03-16		U. Lapierre				refuse movement for destination under maintenance

--================================================================================================
--
--------------------------------------------------------------------------------------------------
-- TEST CODE:
--------------------------------------------------------------------------------------------------
/*

EXEC spLocal_CTS_Evaluate_Appliance_Movement
1339351,
10416,
NULL,
1596

*/


CREATE   PROCEDURE [dbo].[spLocal_CTS_Evaluate_Appliance_Movement]
@ApplianceId			INTEGER,
@DestlocationId			INTEGER,
@DestProcessOrderId		INTEGER = NULL,
@UserId					INTEGER


AS
BEGIN
	DECLARE @Output TABLE 
	(
	O_Status	INTEGER, -- -1 (REJECTED), 0(ACTION REQUIRED), 1 (ACCEPTED)
	O_Message	VARCHAR(500)
)
	DECLARE
	@NextCleaning					VARCHAR(50),	
	@InUseStatusId					INTEGER,
	@DirtyStatusId					INTEGER,
	@CleanStatusId					INTEGER,
	@USerIsSuper					BIT,
	@Runtime						DATETIME,
	@Runtimeplus24					DATETIME,
	@ApplianceProductDesc			VARCHAR(50),
	@NextDestinationProductDesc		VARCHAR(50) /*REV 1.1*/



	-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- GET LOCATION PO
	-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- GET NEXT 24 hours PO -  OLD PENDING ONES ARE BROUGHT 
	--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	DECLARE @Location_POs TABLE
	(
	Product_Id						INTEGER,
	Product_code					VARCHAR(50),
	Product_desc					VARCHAR(50),	
	Process_order_Id				INTEGER,
	Process_order_desc				VARCHAR(50),
	Process_order_status_id			VARCHAR(50),
	Process_order_status_desc		VARCHAR(50),
	Planned_Start_time				DATETIME,
	Planned_End_time				DATETIME,
	Actual_Start_time				DATETIME,
	Actual_End_time					DATETIME,
	Location_id						INTEGER,
	Location_desc					VARCHAR(50),
	AllowToSelectInCurrentLocation	BIT
	)	

	--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- GET NEXT 24 hours PO -  OLD PENDING ONES ARE BROUGHT 
	--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	INSERT INTO @Location_POs(
	Product_Id,
	Product_code,
	Product_desc,	
	Process_order_Id,
	Process_order_desc,
	Process_order_status_id,
	Process_order_status_desc,
	Planned_Start_time,
	Planned_End_time,
	Actual_Start_time,
	Actual_End_time,
	Location_id,
	Location_desc,
	AllowToSelectInCurrentLocation)

	SELECT
	Product_Id,
	Product_code,
	Product_desc,	
	Process_order_Id,
	Process_order_desc,
	Process_order_status_id,
	Process_order_status_desc,
	Planned_Start_time,
	Planned_End_time,
	Actual_Start_time,
	Actual_End_time,
	Location_id,
	Location_desc,
	AllowToSelectInCurrentLocation
	FROM 
	[fnLocal_CTS_Get_Process_Orders_by_criteria]
	(	
			@DestlocationId,
			NULL,
			@Runtime,
			@Runtimeplus24,
			NULL,
			NULL,
			NULL,
			0)

	--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- GET APPLIANCE TYPES - PROD_UNITS
	--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	DECLARE 
	@FAppliance_types TABLE
	(
		PU_Id						INTEGER,
		PU_Desc						VARCHAR(50),
		Type						VARCHAR(50)
	)
	INSERT INTO  @FAppliance_types (PU_Id,Type) 
		SELECT	TFV.KeyId, TFV.Value			
		FROM	dbo.Table_Fields_Values TFV
				JOIN dbo.table_fields TF ON TF.Table_Field_Id = TFV.Table_Field_Id
                JOIN dbo.Tables T ON t.tableid = TF.tableId
					AND T.tableName = 'Prod_Units'
		WHERE   Table_Field_Desc = 'CTS Appliance type'
	

	--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- GET APPLIANCE STATUSES AT DESTINATION LOCATION
	--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	DECLARE @ApplianceStatuses TABLE
	(
	Status_Id							INTEGER,
	Status_Desc							VARCHAR(50)
	)

	INSERT INTO @ApplianceStatuses 
	(
				Status_Id,
				Status_Desc
	)
	SELECT		PS.ProdStatus_Id, 
				PS.ProdStatus_Desc 
	FROM		dbo.PrdExec_Status PES WITH(NOLOCK) 
				JOIN dbo.Production_Status PS WITH(NOLOCK)
					ON PS.ProdStatus_Id = PES.Valid_Status 
	WHERE		pu_id = @DestlocationId


	--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- GET APPLIANCE CURRENT STATUSE
	--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	DECLARE @ApplianceStatus TABLE
	(
		Clean_status		VARCHAR(25),
		Clean_type			VARCHAR(25),
		Hardware_Status		VARCHAR(50),
		Last_product_id		INTEGER,
		Last_Product_Desc	VARCHAR(50)
	)

	INSERT INTO	 @ApplianceStatus
	(
				Clean_status,
				Clean_type,
				Last_product_id,
				Last_product_desc
	)
	SELECT		Clean_status,
				Clean_type,
				Last_product_id,
				PB.prod_desc
	FROM		fnLocal_CTS_Appliance_Status(@ApplianceId,NULL)
				LEFT JOIN dbo.products_base PB WITH(NOLOCK)
					ON PB.prod_id = Last_product_id

	UPDATE	@ApplianceStatus SET Hardware_Status = PS.prodstatus_desc
	FROM	dbo.production_status PS WITH(NOLOCK)
	JOIN	dbo.events E WITH(NOLOCK)
				ON E.event_status = PS.prodStatus_Id 
	WHERE	E.event_id = @ApplianceId
	

	/*------------------------------------------
	Refuse if destination is in maintenance
	-------------------------------------------*/
	IF (SELECT Maintenance_status FROM fnLocal_CTS_Location_Status(@DestlocationId,NULL)) = 'CST_Maintenance_Started'
	BEGIN
		INSERT INTO @Output 
		(
			O_Status,
			O_Message
		)
		SELECT -1, 
		'Destination is under maintenance'
		GOTO The_End		

	END





	--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- GET APPLIANCE LAST TRANSITIONS FROM LOCATION TO TO LOCATION 
	--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	DECLARE @App_Transitions TABLE
	(
		Location_id					INTEGER,
		Location_desc				VARCHAR(50),
		Product_Id					INTEGER,
		Product_code				VARCHAR(50),
		Product_desc				VARCHAR(50),
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
		User_AD						VARCHAR(100)
	)
	
	
	INSERT INTO	@App_Transitions
	(			Location_id,
				Location_desc,
				Product_Id,
				Product_code,
				Product_desc,
				Process_order_Id,
				Process_order_desc,
				Process_order_Status_Id,
				Process_order_Status_desc,
				Process_order_Start_time,
				Process_order_End_time,
				Start_time,
				End_time,
				User_Id,
				Username,
				User_AD
	)
	
	SELECT TOP 1  
			PUB.PU_id,
			PUB.PU_desc,
			PB.prod_id,
			PB.prod_code,
			PB.Prod_desc,
			PP.PP_id,
			PP.process_order,
			PP.pp_status_id,
			pps.pp_status_desc,
			PPST.start_time,
			PPST.end_time,
			E.start_time,
			NULL,
			UB.user_id,
			UB.username,
			UB.windowsUserInfo

	FROM	dbo.event_components EC WITH(NOLOCK)
			JOIN dbo.events E WITH(NOLOCK)
				ON E.event_id = EC.Event_Id
			LEFT JOIN dbo.event_details ED WITH(NOLOCK)
				ON ED.event_id = EC.event_Id
			LEFT JOIN dbo.production_plan PP WITH(NOLOCK)
				ON PP.pp_id = ED.PP_id
			LEFT JOIN dbo.production_plan_starts PPST 
				ON PPST.pp_id = PP.pp_id
			LEFT JOIN dbo.Production_Plan_Statuses PPS WITH(NOLOCK) 
				ON PP.pp_status_id = PPS.pp_status_id
			LEFT JOIN dbo.Prod_Units_Base PUB
				ON PUB.pu_id = E.PU_Id
			--LEFT JOIN dbo.Production_Status PS
			--	ON PS.ProdStatus_Id = E.Event_Status
			LEFT JOIN dbo.products_base PB 
				ON PB.prod_id = E.Applied_Product
			JOIN dbo.users_base UB 
				ON UB.user_id = E.user_id
			/*OUTER APPLY (SELECT TOP 1 timestamp FROM dbo.event_components WHERE source_event_id = @ApplianceId AND timestamp > E.timestamp ORDER BY timestamp ASC) Q1*/
			WHERE EC.source_event_id = @ApplianceId
			ORDER By EC.timestamp DESC


	--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- GET APPLIANCE TRANSITION LOCATIONS
	--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		DECLARE 
		@FAppliance_locations TABLE
		(
			PU_Id						INTEGER,
			PU_Desc						VARCHAR(50),
			LType						VARCHAR(25)
		)

		INSERT INTO @FAppliance_locations 
		(
					PU_ID, 
					PU_Desc,
					LType
		)
		SELECT		PUB.PU_ID, 
					PUB.PU_Desc,
					(CASE COALESCE(PPU.pu_id,-1) 
					WHEN -1 THEN 'Non making'
					ELSE 'Making' 
					END)
		FROM		dbo.Prod_Units_Base PUB WITH(NOLOCK) 
					LEFT JOIN dbo.prdexec_Path_Units PPU WITH(NOLOCK) 
						ON PPU.pu_id = PUB.pu_id
		WHERE		PUB.Equipment_Type = 'CTS location'



	--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- GET STATUSES AT DESTINATION LOCATION
	--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	DECLARE @DestinationStatus TABLE
	(
		Location_status					VARCHAR(25),
		Cleaning_type					VARCHAR(25),
		Last_product_id					INTEGER,
		Last_Process_order_id			INTEGER,
		Last_Process_order_status_Id	INTEGER
	)

	INSERT INTO	 @DestinationStatus
	(
				Location_status,
				Cleaning_type,
				Last_product_id,
				Last_Process_order_id,
				Last_Process_order_status_Id
	)
	SELECT		Location_status,
				Cleaning_type,
				Last_product_id,
				Last_Process_order_Id,
				Last_Process_order_status_Id
	FROM		fnLocal_CTS_Location_Status(@DestlocationId, NULL)


	--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- GET APPLIANCE UNITS (WHERE THEY ARE CONFIGURED AS PROD_EVENTS)
	--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	DECLARE @Appliance_Units TABLE
	(
		PU_Id			INTEGER,
		Appliance_Type	VARCHAR(50)
	)
	INSERT INTO @Appliance_Units
	(
		PU_Id,
		Appliance_Type
	)
	SELECT	PUB.PU_Id,TFV.Value FROM dbo.Prod_units_base PUB
			JOIN dbo.Table_Fields_Values TFV WITH(NOLOCK)
				ON  TFV.KeyId = PUB.PU_Id
			JOIN dbo.Table_Fields TF WITH(NOLOCK) 
				ON TF.Table_Field_Id = TFV.Table_Field_Id
				AND TF.Table_Field_Desc = 'CTS Appliance type'
				AND TF.TableId =	(
									SELECT	TableId 
									FROM	dbo.Tables WITH(NOLOCK) 
									WHERE	TableName = 'Prod_units'
									)
		

	--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- GET APPLIANCE RESERVATION
	--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	DECLARE @Appliance_Reservations TABLE 
	(
	Appliance_Event_id							INTEGER,
	Appliance_Serial							VARCHAR(25),
	Appliance_Type								VARCHAR(50),
	Reservation_Status							VARCHAR(25),
	Reservation_type							VARCHAR(25),	
	Reservation_PU_Id							INTEGER,
	Reservation_PU_Desc							VARCHAR(50),
	Reservation_PP_Id							INTEGER,
	Reservation_Process_Order					VARCHAR(50),
	Reservation_Product_Id						INTEGER,
	Reservation_Product_Code					VARCHAR(50),
	Reservation_creation_User_Id				INTEGER,
	Reservation_creation_User_Desc				VARCHAR(50)
	)
	INSERT INTO @Appliance_Reservations
	(
		Appliance_event_Id,	
		Appliance_Serial,
		Appliance_Type,
		Reservation_Status,
		Reservation_type,
		Reservation_PU_Id,
		Reservation_PU_Desc,
		Reservation_PP_Id,
		Reservation_Process_Order,
		Reservation_Product_Id,
		Reservation_Product_Code,
		Reservation_creation_User_Id,
		Reservation_creation_User_Desc
	)
	SELECT	Appliance_event_Id,	
			Appliance_Serial,
			Appliance_Type,
			Reservation_Status,
			Reservation_type,
			Reservation_PU_Id,
			Reservation_PU_Desc,
			Reservation_PP_Id,
			Reservation_Process_Order,
			Reservation_Product_Id,
			Reservation_Product_Code,
			Reservation_creation_User_Id,
			Reservation_creation_User_Desc
	FROM	fnLocal_CTS_Appliance_Reservations(@ApplianceId,NULL,NULL)


	---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- SECURITY
	---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

	--Check if user is super user
	SET @USerIsSuper =
	CASE (
		SELECT	urs.USER_Role_Security_ID	
				FROM dbo.User_Role_Security urs
				JOIN dbo.users_base u1	WITH(NOLOCK)	
					ON  urs.Role_User_Id = u1.User_Id 
					AND u1.Username IN( 'Plant Apps Admin','Operator','Manufacturing Leader','Super User', 'MDATA')
				JOIN dbo.Users_Base u2	WITH(NOLOCK)	
					ON  urs.User_Id = u2.User_Id	
					AND u2.User_Id = @UserId
		)
		WHEN NULL THEN 0
		ELSE 1
	END
	------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- EVALUATE IF CONTAINER IS RESERVED 
	------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- HARD RESRVATION AND USER IS OWNER OF RESERVATION OR SUPER USER
	------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	IF  (SELECT Reservation_PU_Id FROM @Appliance_Reservations) = @DestlocationId 
	BEGIN
		 GOTO EVALUATE_TRANSITION
	END


	IF (SELECT COUNT(1) FROM @Appliance_Reservations) > 0 
	BEGIN
		IF (SELECT LType FROM @FAppliance_locations WHERE Pu_id = @DestlocationId) = 'Making'
		BEGIN
			IF  (SELECT Reservation_PU_Id FROM @Appliance_Reservations) <> @DestlocationId 
				AND (SELECT Reservation_type FROM @Appliance_Reservations) = 'Hard' 
				AND (@userId = (SELECT Reservation_creation_User_Id FROM @Appliance_Reservations) OR @USerIsSuper = 1)
			BEGIN
				INSERT INTO @Output 
				(
					O_Status,
					O_Message
				)
				SELECT 0, 
				'Hard reservation location '+ (SELECT Reservation_PU_desc FROM @Appliance_Reservations) + ' Different than destination'
			END
			ELSE
			BEGIN
					INSERT INTO @Output 
				(
					O_Status,
					O_Message
				)
				SELECT -1, 
				'Hard reservation location '+ (SELECT Reservation_PU_desc FROM @Appliance_Reservations) + ' Different than destination'
				GOTO The_End
			END
		END

		IF (SELECT Reservation_PU_Id FROM @Appliance_Reservations) <> @DestlocationId AND (SELECT Reservation_type FROM @Appliance_Reservations) = 'Soft'
		BEGIN
			INSERT INTO @Output 
			(
				O_Status,
				O_Message
			)
			SELECT 0, 
			'Soft reservation location '+ (SELECT Reservation_PU_desc FROM @Appliance_Reservations) + ' Different than destination'
		END

	END


	------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- EVALUATE IF CONTAINER IS VIRGIN
	------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	IF  (SELECT COUNT(1) Location_id FROM @App_Transitions) = 0 AND @DestlocationId IN (SELECT pu_Id FROM @FAppliance_locations)
	BEGIN

		INSERT INTO @Output 
		(
		O_Status,
		O_Message
		)
		SELECT  1,  
				NULL
		GOTO THE_END

	END
	------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- EVALUATE IF LOCATION TRANSITION IS ALLOWED
	------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	EVALUATE_TRANSITION:

	IF NOT EXISTS	(SELECT 1 
					FROM	dbo.prdExec_inputs PEI	WITH(NOLOCK)
							JOIN dbo.PrdExec_Input_Sources peis	WITH(NOLOCK)
								ON pei.pei_id = peis.pei_id 
								AND peis.PU_Id = (SELECT Location_id FROM @App_Transitions)
							JOIN dbo.PrdExec_Status PES WITH(NOLOCK) 
								ON PES.PU_Id = PEI.PU_Id
					WHERE	pei.pu_id = @DestlocationId
							AND PEI.Input_Name = 'CTS Location Transition'

					)
	BEGIN
		INSERT INTO @Output 
		(
			O_Status,
			O_Message
		)
			SELECT -1, 
			'Destination location ' + (SELECT pu_desc FROM dbo.prod_units_base WITh(NOLOCK) WHERE PU_Id = @DestlocationId) 
			+ ' is not configured as an allowed movement from ' 
			+ (SELECT PUB.PU_Desc FROM @App_Transitions AT 
			JOIN dbo.prod_units_base PUB WITH(NOLOCK) 
				ON PUB.PU_id = AT.Location_id)
		GOTO The_End
	END
	ELSE
	------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- TRANSITION IS ALLOWED, EVALUATE IF STATUS IS ALLOWED
	------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	BEGIN 
		IF (SELECT Clean_status FROM @ApplianceStatus) NOT IN (
															SELECT	PS.ProdStatus_Desc
															FROM	dbo.prdExec_inputs PEI	WITH(NOLOCK)
																	JOIN dbo.PrdExec_Input_Sources peis	WITH(NOLOCK)
																		ON pei.pei_id = peis.pei_id
																	JOIN dbo.PrdExec_Input_Source_Data PEISD
																		ON PEISD.PEIS_Id = PEIS.PEIS_Id
																	JOIN dbo.production_status PS
																		ON PS.ProdStatus_Id = PEISD.Valid_Status
															WHERE	pei.pu_id = @DestlocationId
																AND peis.PU_Id = (SELECT Location_id FROM @App_Transitions)
														)
		BEGIN	
			INSERT INTO @Output 
			(
				O_Status,
				O_Message
			)
			SELECT -1, 'Destination location ' + (SELECT pu_desc FROM dbo.prod_units_base WITh(NOLOCK) WHERE PU_Id = @DestlocationId) 
			+ ' is not configured to receive appliances with '
			--+ (SELECT Clean_status FROM @ApplianceStatus) 
			+ ' current status'
			GOTO The_End
		END



	---------------------------------------------------------------------------------------------------------------		
	-- EXCLUDE PPW LOCATION WHEN APPLIANCE CLEAN TYPE DIFFERENT THAN MAJOR
	---------------------------------------------------------------------------------------------------------------		
	IF	(SELECT Clean_type FROM fnLocal_CTS_Appliance_Status(@ApplianceId,NULL)) !=  'Major'
		AND 
		(SELECT TFV.value 
		FROM	dbo.Table_Fields_Values TFV WITH(NOLOCK)
				JOIN dbo.Table_Fields TF WITH(NOLOCK) 
					ON TF.Table_Field_Id = TFV.Table_Field_Id
					AND TF.Table_Field_Desc = 'CTS Location type'
					AND TF.TableId =	(
										SELECT	TableId 
										FROM	dbo.Tables WITH(NOLOCK) 
										WHERE	TableName = 'Prod_units'
										) WHERE TFV.keyId = @DestlocationId
		) = 'PPW'
		BEGIN	
			INSERT INTO @Output 
			(
				O_Status,
				O_Message
			)
			SELECT -1, 'Destination location ' + (SELECT pu_desc FROM dbo.prod_units_base WITh(NOLOCK) WHERE PU_Id = @DestlocationId) 
			+ ' Can only receive Major clean appliances '
			GOTO The_End
		END
					


	END
	------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- EVALUATE IF APPLIANCE TYPE CAN BE MOVED TO THIS LOCATION
	------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

	EVALUATE_APPLIANCE_TYPE:
	IF NOT EXISTS (	
					SELECT	1 
					FROM	dbo.prdExec_inputs PEI	WITH(NOLOCK)
							JOIN dbo.PrdExec_Input_Sources peis	WITH(NOLOCK)
								ON pei.pei_id = peis.pei_id
					WHERE	pei.pu_id = @DestlocationId
								AND peis.PU_Id = (SELECT pu_id FROM dbo.events WITH(NOLOCK) WHERE event_id = @ApplianceId)	
								AND PEI.Input_Name = 'CTS Appliance'
					)
	BEGIN
		--THIS IS NOT A VALID LOCATION FOR THIS APPLIANCE
		INSERT INTO @Output 
		(
		O_Status,
		O_Message
		)
		SELECT 
		-1,
		'Appliance type ' 
		+ (	SELECT	Appliance_Type 
			FROM	@Appliance_Units AU 
					JOIN dbo.events E WITH(NOLOCK)
						ON E.pu_id = Au.pu_id 
			WHERE	E.event_id = @ApplianceId) 
		+ ' cannot be moved to this location'
		GOTO The_End
	END
	------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- TYPE IS ALLOWED, EVALUATE IF STATUS IS ALLOWED
	------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	ELSE
	BEGIN 
		IF (SELECT Hardware_status FROM @ApplianceStatus) NOT IN (
															SELECT	PS.ProdStatus_Desc
															FROM	dbo.prdExec_inputs PEI	WITH(NOLOCK)
																	JOIN dbo.PrdExec_Input_Sources peis	WITH(NOLOCK)
																		ON pei.pei_id = peis.pei_id
																	JOIN dbo.PrdExec_Input_Source_Data PEISD
																		ON PEISD.PEIS_Id = PEIS.PEIS_Id
																	JOIN dbo.production_status PS
																		ON PS.ProdStatus_Id = PEISD.Valid_Status
															WHERE	pei.pu_id = @DestlocationId
																AND peis.PU_Id IN (SELECT pu_Id FROM @Appliance_Units)
														)
		BEGIN	


		
			INSERT INTO @Output 
			(
				O_Status,
				O_Message
			)
			SELECT -1, 'Destination location ' + (SELECT pu_desc FROM dbo.prod_units_base WITh(NOLOCK) WHERE PU_Id = @DestlocationId) 
			+ ' is not configured to receive appliances with '
			+ (SELECT hardware_status FROM @ApplianceStatus) 
			+ ' Status'
			GOTO The_End





		END
	END
	------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- EVALUATE IF PROCESS ORDER EXISTS OR IF THE UNIT IS A PRODUCTION ONE
	------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- DETERMINE IF UNIT IS IN A PATH
	IF NOT EXISTS	(
					SELECT	path_id
					FROM	dbo.prdExec_path_units WITH(NOLOCK)
					WHERE	PU_id = @destLocationId
					)
	BEGIN	
		-- IF NOT A MAKING LOCATION THEN MOVE
		INSERT INTO @Output 
			(
				O_Status,
				O_Message
			)
			SELECT 1, 
			''
		GOTO The_End
	END

	ELSE IF @DestProcessOrderId IS NULL
	BEGIN
			INSERT INTO @Output 
		(
			O_Status,
			O_Message
		)
			SELECT -1, 
			'Process order id is not found'
		
		GOTO The_End
	END

	CLEANING_STATUSES_EVALUATION:
	------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- EVALUATE IF LOCATION TRANSITION IS ALLOWED
	------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

	-- CASES 
	-- A) L = Dirty, A = Dirty; No move
	-- B) L = Dirty A = In use; No move, minimal cleaning required
	-- C) L = In Use, A = Dirty; No move, minimal cleaning required
	-- D) L = In Use, A = In use; Validation - Matrix
	-- E) L = Clean, A = Dirty
	-- F) L = Dirty, A = Clean
	-- G) L = Clean, A = Clean
	-- H) L = In use, A = Clean
	-- I) L = Clean, A = In Use
	------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- A) L = DIRTY, A = DIRTY; NO MOVE
	------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

/*REV 1.1 BEGIN */
DECLARE @FinalProdId		int,
		@DestProdId			int

IF @DestProcessOrderId IS NULL
BEGIN
	 SET @DestProdId = (SELECT Last_product_id FROM @DestinationStatus)
END
ELSE
BEGIN
	 SET @DestProdId = (SELECT prod_id FROM dbo.production_plan WITH(NOLOCK) WHERE pp_id = @DestProcessOrderId)
END

	SET @NextCleaning = 
	(
	SELECT	CCM.Code
	FROM	dbo.Local_CTS_Product_Transition_Cleaning_Methods CPTCM WITH(NOLOCK)
			JOIN dbo.Local_CTS_Cleaning_Methods CCM 
				ON CCM.CCM_id = CPTCM.CCM_id
	WHERE	From_Product_id =	(
								SELECT Last_product_id 
								FROM @ApplianceStatus
								)
				AND To_product_id =		@DestProdId
				AND (CPTCM.Location_id IS NULL OR CPTCM.Location_id =@DestlocationId	)
			AND CPTCM.End_Time IS NULL
	)

	SET @NextDestinationProductDesc =	(SELECT	Last_product_id 
										FROM	@DestinationStatus D
												JOIN dbo.products_base PB WITH(NOLOCK)
												ON PB.prod_id = D.Last_product_id
										)


--SELECT @NextCleaning,@DestlocationId
/* REV 1.1 END */

	IF (SELECT Location_status FROM @DestinationStatus)  = 'Dirty' AND (SELECT Clean_status FROM @ApplianceStatus) = 'Dirty' 
	BEGIN
		INSERT INTO @Output 
		(
		O_Status,
		O_Message
		)
		SELECT  -1, 'Location and Appliance are Dirty, movement is refused'
		GOTO The_End
	END

	------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- B) L = DIRTY A = IN USE; NO MOVE - NO SUGGESTION
	------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	IF (SELECT Location_status FROM @DestinationStatus)  = 'Dirty' AND (SELECT Clean_status FROM @ApplianceStatus) = 'In Use' 
	BEGIN
		
		--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- DEFINE NEXT CLEANING
		-- FIRST, LOOK IN EXCEPTION MATRIX TABLE
		--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	
		SET @NextCleaning = 
		(
		SELECT	CCM.Code
		FROM	dbo.Local_CTS_Product_Transition_Cleaning_Methods CPTCM WITH(NOLOCK)
				JOIN dbo.Local_CTS_Cleaning_Methods CCM 
					ON CCM.CCM_id = CPTCM.CCM_id
		WHERE	From_Product_id =	(
									SELECT Last_product_id 
									FROM @ApplianceStatus
									)
				AND To_product_id =	(
									SELECT TOP 1	Product_Id 
									FROM			@Location_POs
									WHERE			Planned_Start_time >	(
																			SELECT	Forecast_Start_Date 
																			FROM	dbo.production_plan PP WITH(NOLOCK) 
																			WHERE	PP_id =	(
																							SELECT	Last_Process_order_id 
																							FROM	@DestinationStatus
																							)
																			)
									)
		)
		--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- DEFINE NEXT CLEANING
		-- SECOND, LOOK AT BOM
		--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		IF @NextCleaning IS NULL
		BEGIN
			----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			-- IF APPLIANCE PRODUCT ID IN NEXT PO BOM THEN MINOR ELSE MAJOR
			----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

			INSERT INTO @Output 
			(
			O_Status,
			O_Message
			)
			SELECT  -1,  
			'Location is Dirty, movement is refused'

			GOTO The_End
		END
				
	END
	------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- C) L = IN USE, A = DIRTY; NO MOVE, EVALUATE MINIMAL CLEANING
	------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	IF (SELECT Location_status FROM @DestinationStatus)  = 'In use' AND (SELECT Clean_status FROM @ApplianceStatus) = 'Dirty' 
	BEGIN
		--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- EVALUATE CLEANING REQUIREMENT FROM LAST PRODUCT ON THE DIRTY APPLIANCE
		-- FROM MATRIX -  LOOK AT LAST PRODUCT ON APPLIANCE AND CURRENT PRODUCT ON LOCATION
		--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		SET @NextCleaning = 
		(
		SELECT	CCM.Code
		FROM	dbo.Local_CTS_Product_Transition_Cleaning_Methods CPTCM WITH(NOLOCK)
				JOIN dbo.Local_CTS_Cleaning_Methods CCM 
					ON CCM.CCM_id = CPTCM.CCM_id
		WHERE	From_Product_id =	(
									SELECT Last_product_id 
									FROM @ApplianceStatus
									)
					AND To_product_id =		(
												SELECT Last_product_id 
												FROM @DestinationStatus
												)
		)
		--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- EVALUATE CLEANING REQUIREMENT FROM LAST PRODUCT ON THE DIRTY APPLIANCE
		-- IF NOTHING FOUND ON MATRIX - USE BOM
		-- LAST PRODUCT ON APPLIANCE COMPARED TO PO BOM COMPONENTS AND PRODUCTS.  IF IN ONE OF BOTH THAN MINIMAL IS MINOR OTHERWISE MAJOR
		--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		IF @NextCleaning IS NULL
		BEGIN
			IF
				(
				SELECT	Last_product_id 
				FROM	@ApplianceStatus
				) 
				IN
				(
				SELECT		BOMFI.Prod_Id 
				FROM		dbo.Bill_Of_Material_Formulation BOMF 
							JOIN dbo.Production_plan PP WITH(NOLOCK)
								ON PP.BOM_Formulation_Id = BOMF.BOM_Formulation_Id 
							JOIN dbo.Bill_Of_Material_Formulation_Item BOMFI  WITH(NOLOCK) 
								ON BOMFI.BOM_Formulation_Id = BOMF.BOM_Formulation_Id
				WHERE		PP.PP_Id = @DestProcessOrderId

				)
				OR
				(
					(
					SELECT	Last_product_id 
					FROM	@ApplianceStatus
					) 
					=
					(
						(
						SELECT	Last_product_id 
						FROM	@DestinationStatus	
						)
					)
				)
			BEGIN
				SET @NextCleaning = 'Minor'
			
			END
			ELSE
			BEGIN
				SET @NextCleaning = 'Major'
			END
		END

		INSERT INTO @Output 
		(
		O_Status,
		O_Message
		)
		SELECT  -1,  
				'Appliance is Dirty, movement is refused.  Minimum appliance cleaning is ' 
				+ @NextCleaning
		GOTO The_End
	END

	------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- D) L = IN USE, A = IN USE; EVALUATE BOM COMPONENTS.  IF NO FIT REFUSE MOVEMENT
	------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

	IF (SELECT Location_status FROM @DestinationStatus)  = 'In use' AND (SELECT Clean_status FROM @ApplianceStatus) = 'In Use' 
	BEGIN
		--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- EVALUATE IF APPLIANCE PRODUCT IS IN LOCATION BOM
		--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

		IF
			(
			SELECT	Last_product_id 
			FROM	@ApplianceStatus
			) 
			IN
			(
			SELECT		BOMFI.Prod_Id 
			FROM		dbo.Bill_Of_Material_Formulation BOMF WITH(NOLOCK)
						JOIN dbo.Production_plan PP WITH(NOLOCK)
							ON PP.BOM_Formulation_Id = BOMF.BOM_Formulation_Id 
						JOIN dbo.Bill_Of_Material_Formulation_Item BOMFI  WITH(NOLOCK) 
							ON BOMFI.BOM_Formulation_Id = BOMF.BOM_Formulation_Id
			WHERE		PP.PP_Id = @DestProcessOrderId
			)
		BEGIN
			INSERT INTO @Output 
			(
			O_Status,
			O_Message
			)
			SELECT  1,  
					''
			GOTO The_End
		END
		ELSE
		BEGIN
		--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- REFUSE MOVEMENT
		--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			INSERT INTO @Output 
			(
			O_Status,
			O_Message
			)
			SELECT  0,  
					'In use Appliance product, not compatible with In use location product ' 
			GOTO The_End
		END
	END
	------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- E) L = CLEAN, A = DIRTY. ONLY EVALUATE MINiMAL CLEANING REQUIRED
	------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	IF (SELECT Location_status FROM @DestinationStatus)  = 'Clean' AND (SELECT Clean_status FROM @ApplianceStatus) = 'Dirty' 
	------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- EVALUATE MINIMAL CLEANING.  NEED LAST APPLIANCE PRODUCT AND LAST PRODUCT AT LOCATION
	------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	BEGIN
		-- LOOK IN MATRIX
		SET @NextCleaning = 
		(
		SELECT	CCM.Code
		FROM	dbo.Local_CTS_Product_Transition_Cleaning_Methods CPTCM WITH(NOLOCK)
				JOIN dbo.Local_CTS_Cleaning_Methods CCM 
					ON CCM.CCM_id = CPTCM.CCM_id
		WHERE	From_Product_id =	(
									SELECT Last_product_id 
									FROM @ApplianceStatus
									)
					AND To_product_id =		(
												SELECT Last_product_id 
												FROM @DestinationStatus
												)
		)
		-- LOOK IN BOM
		IF @NextCleaning IS NULL
		BEGIN
			IF
				(
				SELECT	Last_product_id 
				FROM	@ApplianceStatus
				) 
				IN
				(
				SELECT		BOMFI.Prod_Id 
				FROM		dbo.Bill_Of_Material_Formulation BOMF 
							JOIN dbo.Production_plan PP WITH(NOLOCK)
								ON PP.BOM_Formulation_Id = BOMF.BOM_Formulation_Id 
							JOIN dbo.Bill_Of_Material_Formulation_Item BOMFI  WITH(NOLOCK) 
								ON BOMFI.BOM_Formulation_Id = BOMF.BOM_Formulation_Id
				WHERE		PP.PP_Id = @DestProcessOrderId

				)
				OR
				(
					(
					SELECT	Last_product_id 
					FROM	@ApplianceStatus
					) 
					=
					(
						(
						SELECT	Last_product_id 
						FROM	@DestinationStatus
						
					)
				)
			)
			BEGIN
				SET @NextCleaning = 'Minor'
			
			END
			ELSE
			BEGIN
				SET @NextCleaning = 'Major'
			END
		END
		
		INSERT INTO @Output 
		(
		O_Status,
		O_Message
		)
		SELECT  -1,  
				'Appliance is Dirty, movement is refused.  Minimum appliance cleaning is ' + @NextCleaning
		GOTO The_End
	END
	------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- F) L = DIRTY, A = CLEAN.  NO EVALUATION --EVALUATE NEXT LOCATION CLEANING ACCORDING TO NEXT PO 
	------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	IF (SELECT Location_status FROM @DestinationStatus)  = 'Dirty' AND (SELECT Clean_status FROM @ApplianceStatus) = 'Clean' 
	BEGIN
	
		INSERT INTO @Output 
		(
		O_Status,
		O_Message
		)
		/*SELECT  -1,  
				 'Location is Dirty, movement is refused and must minimally be ' 
				 + @NextCleaning + ' Clean in order to start next PO ' 
				 +	(SELECT TOP 1	Process_order_desc 
					FROM			@Location_POs
					WHERE			Planned_Start_time >	(
															SELECT	Forecast_Start_Date 
															FROM	dbo.production_plan PP WITH(NOLOCK) 
															WHERE PP_id =	(
																			SELECT	Last_Process_order_id 
																			FROM	@DestinationStatus
																			)
															)
					)*/

		SELECT  -1,  
		'Location is Dirty, movement is refused.' --  Minimum appliance cleaning is ' + @NextCleaning
		GOTO The_End

			
	END
	-----------------------------------------------------------------------------------------------------------------------------
	-- G) L = CLEAN, A = CLEAN
	-----------------------------------------------------------------------------------------------------------------------------
	IF (SELECT Location_status FROM @DestinationStatus)  = 'Clean' AND (SELECT Clean_status FROM @ApplianceStatus) = 'Clean' 
	BEGIN
		IF @DestProcessOrderId IS NULL
			SET @DestProcessOrderId = 0
		IF (SELECT COALESCE(Clean_type,'Major') FROM @ApplianceStatus) = 'Minor' AND @DestProcessOrderId != 0
		-------------------------------------------------------------------------------------------------------------------------
		-- IF BOTH LOCATION AND APPLIANCE STATUS ARE CLEAN AND APPLIANCE STATUS IS MINOR CLEANED, PRIOR PRODUCT MUST BE EVALUATED
		-------------------------------------------------------------------------------------------------------------------------
		BEGIN
		
			IF (SELECT Last_product_id FROM @ApplianceStatus) IS NOT NULL
			BEGIN

				IF @NextCleaning IS NULL /* REV 1.1 */
				BEGIN /* NOTHING IN MATRIX, LOOK AT BOM */
					IF	(
						SELECT	Last_product_id 
						FROM	@ApplianceStatus
						) 
						IN
						(
						SELECT		BOMFI.Prod_Id 
						FROM		dbo.Bill_Of_Material_Formulation BOMF 
									JOIN dbo.production_plan PP WITH(NOLOCK)
										ON PP.BOM_Formulation_Id = BOMF.BOM_Formulation_Id 
									JOIN dbo.Bill_Of_Material_Formulation_Item BOMFI  WITH(NOLOCK) 
										ON BOMFI.BOM_Formulation_Id = BOMF.BOM_Formulation_Id
						WHERE		PP.PP_Id = @DestProcessOrderId
								
						)
						OR
						(
							(
							SELECT	Last_product_id 
							FROM	@ApplianceStatus
							) 
							=
							(
							SELECT	prod_id 
							FROM	dbo.production_plan WITH(NOLOCK)
							WHERE PP_ID = @DestProcessOrderId
							) 
						)
					BEGIN
						---------------------------------------------------------------------------------------------------------------------
						-- COMPATIBLE PRODUCT IN BOM
						---------------------------------------------------------------------------------------------------------------------
						INSERT INTO @Output 
						(
						O_Status,
						O_Message
						)
						SELECT  1,  
									''
						GOTO The_End
					END
					ELSE
					BEGIN
						---------------------------------------------------------------------------------------------------------------------
						-- NO COMPATIBLE PRODUCT IN BOM
						---------------------------------------------------------------------------------------------------------------------
						INSERT INTO @Output 
						(
						O_Status,
						O_Message
						)
						SELECT  -1,  
									'Process order ' + (SELECT process_order FROM dbo.production_plan WITH(NOLOCK) WHERE PP_ID = @DestProcessOrderId) +
									' Is not compatible with the appliance product ' + (SELECT	Last_product_desc FROM	@ApplianceStatus)

						GOTO The_End
					END
				END
		
				/* REV 1.1 BEGIN */
				ELSE IF @NextCleaning = 'Major' /* ENTRY IN MATRIX */
				BEGIN
					INSERT INTO @Output 
						(
						O_Status,
						O_Message
						)
						SELECT  -1,  
								'Matrix entry requires major clean when product ' + (SELECT	Last_product_desc FROM	@ApplianceStatus) +
								'Moved to product ' + @NextDestinationProductDesc

					GOTO The_End
				END
				ELSE
				BEGIN
					---------------------------------------------------------------------------------------------------------------------
					-- COMPATIBLE PRODUCT IN BOM
					---------------------------------------------------------------------------------------------------------------------
					INSERT INTO @Output 
					(
					O_Status,
					O_Message
					)
					SELECT  1,  
								''
					GOTO The_End
				END
			END
			/* REV 1.1 END */
			-------------------------------------------------------------------------------------------------------------------------
			-- APPLIANCE STATUS IS MINOR CLEAN BUT WAS NEVER USED
			-------------------------------------------------------------------------------------------------------------------------
			BEGIN
				INSERT INTO @Output 
				(
				O_Status,
				O_Message
				)
				SELECT  1,  
							''
				GOTO The_End
			END
		END
		INSERT INTO @Output 
		(
		O_Status,
		O_Message
		)
		SELECT  1,  
					''
		GOTO The_End			

	
	END
	-----------------------------------------------------------------------------------------------------------------------------
	-- H) L = IN USE, A = CLEAN
	-----------------------------------------------------------------------------------------------------------------------------
	IF (SELECT Location_status FROM @DestinationStatus)  = 'In use' AND (SELECT Clean_status FROM @ApplianceStatus) = 'Clean' 
	BEGIN
	
		IF (SELECT COALESCE(Clean_type,'Major') FROM @ApplianceStatus) = 'Minor'
		BEGIN
		
			IF (SELECT Last_product_id FROM @ApplianceStatus) IS NOT NULL
			BEGIN

				IF @NextCleaning IS NULL /* REV 1.1 */
				BEGIN /* NOTHING IN MATRIX, LOOK AT BOM */
					IF	(
						SELECT	Last_product_id 
						FROM	@ApplianceStatus
						) 
						IN
						(
						SELECT		BOMFI.Prod_Id 
						FROM		dbo.Bill_Of_Material_Formulation BOMF 
									JOIN dbo.production_plan PP WITH(NOLOCK)
										ON PP.BOM_Formulation_Id = BOMF.BOM_Formulation_Id 
									JOIN dbo.Bill_Of_Material_Formulation_Item BOMFI  WITH(NOLOCK) 
										ON BOMFI.BOM_Formulation_Id = BOMF.BOM_Formulation_Id
						WHERE		PP.PP_Id = @DestProcessOrderId
								
						)
						OR
						(
							(
							SELECT	Last_product_id 
							FROM	@ApplianceStatus
							) 
							=
							(
							SELECT	prod_id 
							FROM	dbo.production_plan WITH(NOLOCK)
							WHERE PP_ID = @DestProcessOrderId
							) 
						)
					BEGIN
						---------------------------------------------------------------------------------------------------------------------
						-- COMPATIBLE PRODUCT IN BOM
						---------------------------------------------------------------------------------------------------------------------
						INSERT INTO @Output 
						(
						O_Status,
						O_Message
						)
						SELECT  1,  
									''
						GOTO The_End
					END
					ELSE
					BEGIN
						---------------------------------------------------------------------------------------------------------------------
						-- NO COMPATIBLE PRODUCT IN BOM
						---------------------------------------------------------------------------------------------------------------------
						INSERT INTO @Output 
						(
						O_Status,
						O_Message
						)
						SELECT  -1,  
									'Process order ' + (SELECT process_order FROM dbo.production_plan WITH(NOLOCK) WHERE PP_ID = @DestProcessOrderId) +
									' Is not compatible with the appliance product ' + (SELECT	Last_product_desc FROM	@ApplianceStatus)

						GOTO The_End
					END
				END
		
				/* REV 1.1 BEGIN */
				ELSE IF @NextCleaning = 'Major' /* ENTRY IN MATRIX */
				BEGIN
					INSERT INTO @Output 
						(
						O_Status,
						O_Message
						)
						SELECT  -1,  
								'Matrix entry requires major clean when product ' + (SELECT	Last_product_desc FROM	@ApplianceStatus) +
								'Moved to product ' + @NextDestinationProductDesc

					GOTO The_End
				END
				ELSE
				BEGIN
					---------------------------------------------------------------------------------------------------------------------
					-- COMPATIBLE PRODUCT IN BOM
					---------------------------------------------------------------------------------------------------------------------
					INSERT INTO @Output 
					(
					O_Status,
					O_Message
					)
					SELECT  1,  
								''
					GOTO The_End
				END
			END
			/* REV 1.1 END */
			-------------------------------------------------------------------------------------------------------------------------
			-- APPLIANCE STATUS IS MINOR CLEAN BUT WAS NEVER USED
			-------------------------------------------------------------------------------------------------------------------------
			BEGIN
				INSERT INTO @Output 
				(
				O_Status,
				O_Message
				)
				SELECT  1,  
							''
				GOTO The_End
			END
		END
		INSERT INTO @Output 
		(
		O_Status,
		O_Message
		)
		SELECT  1,  
					''
		GOTO The_End
	END

-- I) L = CLEAN, A = IN USE
	-----------------------------------------------------------------------------------------------------------------------------
	IF (SELECT Location_status FROM @DestinationStatus)  = 'Clean' AND (SELECT Clean_status FROM @ApplianceStatus) = 'In use' 
	BEGIN
		IF (SELECT COALESCE(Cleaning_type,'Major') FROM @DestinationStatus) = 'Minor'
		BEGIN
			IF 	(
				SELECT	Last_product_id 
				FROM	@ApplianceStatus
				) 
				IN
				(
				SELECT		BOMFI.Prod_Id 
				FROM		dbo.Bill_Of_Material_Formulation BOMF 
							JOIN dbo.production_plan PP WITH(NOLOCK)
								ON PP.BOM_Formulation_Id = BOMF.BOM_Formulation_Id 
							JOIN dbo.Bill_Of_Material_Formulation_Item BOMFI  WITH(NOLOCK) 
								ON BOMFI.BOM_Formulation_Id = BOMF.BOM_Formulation_Id
				WHERE		PP.PP_Id = @DestProcessOrderId

																				
				)
				OR
				(
					(
					SELECT	Last_product_id 
					FROM	@ApplianceStatus
					) 
					=
					(
					SELECT	prod_id 
					FROM	dbo.production_plan WITH(NOLOCK)
					WHERE PP_ID = @DestProcessOrderId
					) 
				)
			BEGIN
				---------------------------------------------------------------------------------------------------------------------
				-- COMPATIBLE PRODUCT IN BOM
				---------------------------------------------------------------------------------------------------------------------
				INSERT INTO @Output 
				(
				O_Status,
				O_Message
				)
				SELECT  1,  
							''
				GOTO The_End
				END
				ELSE
				BEGIN
					---------------------------------------------------------------------------------------------------------------------
					-- NO COMPATIBLE PRODUCT IN BOM
					---------------------------------------------------------------------------------------------------------------------
					INSERT INTO @Output 
					(
					O_Status,
					O_Message
					)
					SELECT  -1,  
							 'No compatible product in BOM'
					GOTO The_End
				END

			END
			ELSE
			-------------------------------------------------------------------------------------------------------------------------
			-- APPLIANCE STATUS IS MAJOR CLEAN
			-------------------------------------------------------------------------------------------------------------------------
			BEGIN
				INSERT INTO @Output 
				(
				O_Status,
				O_Message
				)
				SELECT  1,  
						 ''
				GOTO The_End
			END


	END



	The_End:


	SELECT 	O_Status,
			O_Message 
	FROM	@Output
	RETURN
 END
