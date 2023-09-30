

--------------------------------------------------------------------------------------------------
-- Stored Procedure: spLocal_CTS_Get_Allowed_Destination_Locations
--------------------------------------------------------------------------------------------------
-- Author				: Francois Bergeron, Symasol
-- Date created			: 2021-11-12
-- Version 				: Version 1.0
-- SP Type				: WEB
-- Caller				: WEB SERVICE
-- Description			: The purpose of this store procedure is to list the locations where a selected appliance can be moved
-- Editor tab spacing	: 4
-------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ===========================================================================================
-- 1.0		2021-11-12		F. Bergeron				Initial Release 
-- 1.1		2022-02-07		F. Bergeron				Add parameter to fnLocal_CTS_Location_Status
-- 1.2		2022-06-01		F. Bergeron				Set dirty lcoations to disallowed
-- 1.3		2022-08-25		U.Lapierre				Reset active PrO variable within the loop to avoid keeping prev unit value
-- 1.4		2022-09-14		U.Lapierre				fix issue for clean matrix case Location in use, appliance clean
-- 1.5		2023-03-16		U.Lapierre				Refuse movement to location under maintenance
--================================================================================================
--
--------------------------------------------------------------------------------------------------
-- TEST CODE:
--------------------------------------------------------------------------------------------------
/*
EXECUTE [spLocal_CTS_Get_Allowed_Destination_Locations] '10062022005',1596
https://brtc-mslab080.na.pg.com:4801/api/Location/Move/AllowedMove/10062022005/1596
*/

CREATE   PROCEDURE [dbo].[spLocal_CTS_Get_Allowed_Destination_Locations]
	@Serial 		VARCHAR(25),
	@UserId			INTEGER

AS
BEGIN
	DECLARE
	@ApplianceEventId				INTEGER,
	@ApplianceProdId				INTEGER,
	@AppliancePUId					INTEGER,
	@ApplianceType					VARCHAR(25),
	@ApplianceLocationEventId		INTEGER,
	@ApplianceLocationPUId			INTEGER,
	@ApplianceCleaningStatus		VARCHAR(25),
	@ApplianceCleaningType			VARCHAR(25),
	@ApplianceTransitionLocationId	INTEGER,
	@ApplianceTypeTFID				INTEGER,
	@TableId						INTEGER

	DECLARE @MatrixCleaning			varchar(30)

	SET NOCOUNT ON;
	DECLARE @Output TABLE 
	(
	Serial									VARCHAR(50),
	Location_id								INTEGER,
	Location_desc							VARCHAR(50),
	Location_type							VARCHAR(50), 
	Cleaning_status							VARCHAR(50), 
	Cleaning_type							VARCHAR(50),
	Active_Product							VARCHAR(50),
	RequiresPOSelection						BIT,
	Compatible_process_order_count			INTEGER DEFAULT 0, 
	Active_or_inprep_process_order_Id	    INTEGER,
	Active_or_inprep_process_order_desc		VARCHAR(50),  
	Active_or_inprep_process_order_product	VARCHAR(50),  
	Active_or_inprep_process_order_status	VARCHAR(50), 
	Number_of_soft_reservations				INTEGER DEFAULT 0, 
	Number_of_hard_reservations				INTEGER DEFAULT 0, 
	Access									VARCHAR(25),
	AllowedToMove							BIT,
	OMessage								VARCHAR(5000)
)


	---------------------------------------------------------------------------------------------------------------
	-- GET THE EVENT_ID ASSOCIATED TO THE SERIAL
	---------------------------------------------------------------------------------------------------------------	
	SELECT	@ApplianceEventId = event_id,
			@AppliancePUId	=	Pu_id
	FROM	dbo.event_details WITH(NOLOCK)
	WHERE	Alternate_event_num = @Serial
	
	SET @TableId = (SELECT	TableId 
					FROM	dbo.Tables WITH(NOLOCK) 
					WHERE	TableName = 'Prod_units'
					)
	SET @ApplianceTypeTFID =	(SELECT table_field_id 
								FROM	dbo.Table_Fields TF WITH(NOLOCK) 
								WHERE	Table_Field_Desc = 'CTS Appliance type'
										AND TableId = @TableId
								)

	SELECT  @ApplianceCleaningStatus = Clean_status, 
			@ApplianceCleaningType = Clean_type,
			@ApplianceProdId = Last_product_id
	FROM	fnLocal_CTS_Appliance_Status(@ApplianceEventId,NULL)
									


	
	SET @ApplianceType =	(
							SELECT	TFV.Value 
							FROM	dbo.Prod_units_base PUB
									JOIN dbo.Table_Fields_Values TFV WITH(NOLOCK)
										ON  TFV.KeyId = PUB.PU_Id							
							WHERE	TFV.table_field_id = @ApplianceType 
									AND TFV.keyid = @AppliancePUId
							)

	 SET @ApplianceTransitionLocationId =  (SELECT Location_id FROM	fnLocal_CTS_Appliance_Transitions (@ApplianceEventId, 0, NULL,NULL,'BACKWARD'))

	--Table_fields
	DECLARE 
	@TableIdProdUnit				INTEGER,
	@tfIdLocationSerial				INTEGER,
	@tfIdLocationType				INTEGER
	------------------------------------
	--Get table field_id
	------------------------------------
	SET @TableIdProdUnit			=	(	SELECT tableId FROM dbo.Tables WITH(NOLOCK) WHERE TableName = 'Prod_Units'	)
	SET @tfIdLocationSerial			=	(	SELECT table_field_id FROM dbo.Table_Fields WITH(NOLOCK) WHERE TableId = @TableIdProdUnit AND Table_Field_Desc = 'CTS Location serial number')
	SET @tfIdLocationType			=	(	SELECT table_field_id FROM dbo.Table_Fields WITH(NOLOCK) WHERE TableId = @TableIdProdUnit AND Table_Field_Desc = 'CTS location Type')


	---------------------------------------------------------------------------------------------------------------	
	-- GET ALL LOCATIONS WHERE IT CAN BE MOVED ACCORDING TO CTS LOCATION TRANSITION RMI
	---------------------------------------------------------------------------------------------------------------	
	INSERT INTO @Output
	(
		Location_id, 
		Location_desc, 
		AllowedToMove,
		RequiresPOSelection
	)
	
		SELECT DISTINCT
		PEI.pu_id,
		PUB.PU_desc,
		1,
		(CASE ISNULL(pepu.pu_id,0)
		WHEN 0 THEN 0
		ELSE 1
		END)
		FROM	dbo.prdExec_inputs PEI	WITH(NOLOCK)
				JOIN dbo.PrdExec_Input_Sources PEIS	WITH(NOLOCK)
					ON PEI.pei_id = PEIS.pei_id 
				JOIN dbo.prod_units_Base PUB
					ON PUB.pu_id = PEI.pu_id
				LEFT JOIN dbo.prdexec_path_units PEPU 
					ON PEPU.pu_id = PEI.pu_id
		WHERE	PEI.input_name = 'CTS Location Transition'
				AND PEIS.pu_id = @ApplianceTransitionLocationId

	---------------------------------------------------------------------------------------------------------------	
	-- UPDATE IF THE APPLIANCE STATUS IS NOT ALLOWED ACCORDING TO 'CTS Location transition' RMI
	---------------------------------------------------------------------------------------------------------------	
	UPDATE	@Output 
	SET		allowedtomove = 0 
	WHERE	(	
			SELECT	Clean_status 
			FROM	fnLocal_CTS_Appliance_Status(@ApplianceEventId,NULL)
			) 
			NOT IN
			(
			SELECT	PS.ProdStatus_desc
			FROM	dbo.prdExec_inputs PEI	WITH(NOLOCK)
					JOIN dbo.PrdExec_Input_Sources peis	WITH(NOLOCK)
						ON pei.pei_id = peis.pei_id
					JOIN dbo.PrdExec_Input_Source_Data PEISD
						ON PEISD.PEIS_Id = PEIS.PEIS_Id
					JOIN dbo.Production_Status PS WITH(NOLOCK)
						ON PS.prodStatus_Id = PEISD.Valid_Status
			WHERE	PEI.input_name = 'CTS Location Transition'
					AND PEI.PU_Id = Location_Id
			)


	---------------------------------------------------------------------------------------------------------------	
	-- UPDATE IF THE APPLIANCE TYPE IS NOT ALLOWED ACCORDING TO 'CTS Appliance' RMI
	---------------------------------------------------------------------------------------------------------------
	UPDATE	@Output 
	SET		allowedtomove = 0 
	WHERE	Location_Id 
			NOT IN	
			(
			SELECT	PEI.pu_id			
			FROM	dbo.prdExec_inputs PEI	WITH(NOLOCK)
					JOIN dbo.PrdExec_Input_Sources PEIS	WITH(NOLOCK)
						ON PEI.pei_id = PEIS.pei_id 
			WHERE	PEI.input_name = 'CTS Appliance'
					AND PEIS.pu_id = @AppliancePUId	
			)

	---------------------------------------------------------------------------------------------------------------	
	-- UPDATE IF THE APPLIANCE STATUS IS NOT ALLOWED ACCORDING TO 'CTS Appliance
	---------------------------------------------------------------------------------------------------------------		
	UPDATE	@Output 
	SET		allowedtomove = 0 
	WHERE	(	
			SELECT	event_status 
			FROM	dbo.events WITH(NOLOCK) WHERE event_id = @ApplianceEventId
			) 
			NOT IN
			(
			SELECT	PS.ProdStatus_id
			FROM	dbo.prdExec_inputs PEI	WITH(NOLOCK)
					JOIN dbo.PrdExec_Input_Sources peis	WITH(NOLOCK)
						ON pei.pei_id = peis.pei_id
					JOIN dbo.PrdExec_Input_Source_Data PEISD
						ON PEISD.PEIS_Id = PEIS.PEIS_Id
					JOIN dbo.Production_Status PS WITH(NOLOCK)
						ON PS.prodStatus_Id = PEISD.Valid_Status
			WHERE	PEI.input_name = 'CTS Appliance'
					AND PEI.PU_Id = Location_Id
			)

	---------------------------------------------------------------------------------------------------------------		
	-- EXCLUDE PPW LOCATION WHEN APPLIANCE CLEAN TYPE DIFFERENT THAN MAJOR
	---------------------------------------------------------------------------------------------------------------		
	UPDATE	@Output 
	SET		allowedtomove = 0 
	FROM	@Output O 
			LEFT JOIN	(SELECT PEI.pu_id, PS.ProdStatus_desc
						FROM	dbo.prdExec_inputs PEI	WITH(NOLOCK)
								JOIN dbo.PrdExec_Input_Sources peis	WITH(NOLOCK)
									ON pei.pei_id = peis.pei_id
								JOIN dbo.PrdExec_Input_Source_Data PEISD
									ON PEISD.PEIS_Id = PEIS.PEIS_Id
								JOIN dbo.Production_Status PS WITH(NOLOCK)
									ON PS.prodStatus_Id = PEISD.Valid_Status
						WHERE	PEI.input_name = 'CTS Location Transition'
								AND PS.ProdStatus_desc = @ApplianceCleaningStatus	
														--(
													--	SELECT	Clean_status 
													--	FROM	fnLocal_CTS_Appliance_Status(@ApplianceEventId,NULL)
													--	)
						) AST
							ON AST.pu_id = O.location_ID
						JOIN dbo.Table_Fields_Values TFV WITH(NOLOCK)
							ON  TFV.KeyId = O.Location_id
							AND TFV.Table_Field_Id = @tfIdLocationType
						--JOIN dbo.Table_Fields TF WITH(NOLOCK) 
						--	ON TF.Table_Field_Id = TFV.Table_Field_Id
						--	AND TF.Table_Field_Desc = 'CTS Location type'
						--	AND TF.TableId =	(
						--						SELECT	TableId 
						--						FROM	dbo.Tables WITH(NOLOCK) 
						--						WHERE	TableName = 'Prod_units'
						--						)
				WHERE	Location_id = AST.PU_Id
						AND TFV.value = 'PPW'
						AND (
							SELECT	Clean_type
							FROM	fnLocal_CTS_Appliance_Status(@ApplianceEventId,NULL)
							) != 'Major'

	UPDATE o
	SET		Serial = tfv1.value, 
			Location_Type = tfv2.value
	FROM @Output o
	JOIN dbo.Table_Fields_Values tfv1	WITH(NOLOCK)	ON tfv1.KeyId = o.Location_id	AND	tfv1.Table_Field_Id = @tfIdLocationSerial
	LEFT JOIN dbo.Table_Fields_Values tfv2	WITH(NOLOCK)	ON tfv2.KeyId = o.Location_id	AND	tfv2.Table_Field_Id = @tfIdLocationType
	
	UPDATE @output
	SET		Cleaning_status =	(SELECT Location_status FROM dbo.fnLocal_CTS_Location_Status(location_id, NULL))
	UPDATE @output
	SET		Cleaning_Type =	(SELECT Cleaning_type FROM dbo.fnLocal_CTS_Location_Status(location_id, NULL))

	UPDATE @output 
	SET allowedtomove = 0  WHERE Cleaning_status = 'Dirty'

	UPDATE @output
	SET		Active_Product = 
	(SELECT Prod_Desc FROM dbo.products_base PB WITH(NOLOCK) WHERE Prod_Id = (SELECT Last_product_id FROM dbo.fnLocal_CTS_Location_Status(location_id, NULL)))
	
		 
	
	---------------------------------------------------------------------
	--Loop across remaining Location to get other information
	---------------------------------------------------------------------
	DECLARE 
	@Puid							INTEGER,
	@PathId							INTEGER,
	@PrO							VARCHAR(100),
	@PrId							INTEGER,
	@GCAS							VARCHAR(100),
	@PPStatusDesc					VARCHAR(100),
	@CompatiblePrO					INTEGER,
	@MaxDate						DATETIME

	DECLARE @Processorders TABLE
	(
	PPId									INTEGER,
	ProcessOrder							VARCHAR(50),
	PPStatusDesc							VARCHAR(50),
	ProdCode								VARCHAR(50),
	ForecastStartDate						DATETIME,
	BOMFId									INTEGER,
	ForecastEndDate							DATETIME
	)

	DECLARE @ProductsFilter	TABLE	
	(
	ProdId									INTEGER,
	ProdCode								VARCHAR(100)
	)


	--***********************************************
	--Reservation
	--***********************************************
	DECLARE	
	@ESReservation					INTEGER,
	@varIdType						INTEGER,
	@CountSoft						INTEGER,
	@CountHard						INTEGER

	DECLARE @Reservations TABLE	
	(
	UDEId							INTEGER,
	Timestamp						DATETIME,
	Type							VARCHAR(100)
	)
	SET @Puid = (SELECT MIN(location_id) FROM @Output)

	SET @ESReservation = (	SELECT event_subtype_id
							FROM dbo.event_subtypes WITH(NOLOCK) 
							WHERE event_subtype_desc = 'CTS Reservation')

	SET @MaxDate = GETDATE()
	SET @MaxDate = DATEADD(Day,1, @MaxDate)
	----------------------------------------------
	-- WHILE START
	----------------------------------------------	
	WHILE @Puid IS NOT NULL
	BEGIN
		----------------------------------------------
		--PrO management
		----------------------------------------------
		SELECT	@PrO = NULL,
				@GCAS = NULL,
				@PPStatusDesc = NULL
		
		DELETE @ProcessOrders

		SET @PathId = (SELECT TOP 1 path_id FROM dbo.PrdExec_Path_Units WHERE PU_Id = @Puid)
		IF @PathId IS NOT NULL
		BEGIN

			INSERT @Processorders (PPId ,ProcessOrder ,ProdCode , PPStatusDesc , BOMFId, ForecastStartDate)
			SELECT pp.PP_Id, pp.Process_Order, p.Prod_Code, ps.PP_Status_Desc, pp.BOM_Formulation_Id, Forecast_Start_Date
			FROM dbo.Production_Plan pp				WITH(NOLOCK)
			JOIN dbo.Products_Base p				WITH(NOLOCK)	ON pp.Prod_Id = p.Prod_Id
			JOIN dbo.Production_Plan_Statuses ps	WITH(NOLOCK)	ON pp.PP_Status_Id = ps.PP_Status_Id
			WHERE pp.Path_Id = @PathId AND ps.PP_Status_Id IN (1,3)

			--Get active info
			SELECT  @PrO = NULL,
					@GCAS = NULL,
					@PPStatusDesc = NULL, 
					@PrId = NULL

			SELECT	@PrO = processorder,
					@GCAS = prodcode,
					@PPStatusDesc = ppstatusdesc,
					@PrId = PPId
			FROM @Processorders
			WHERE PPStatusDesc = 'Active'

			--Get count for valid order
			IF @ApplianceProdId IS NOT NULL
			BEGIN
				--Get the filtering product list and their prod id
				INSERT @ProductsFilter	(ProdId)
				VALUES(@ApplianceProdId)

				UPDATE pf
				SET prodcode = p.prod_code
				FROM @ProductsFilter pf
				JOIN Products_Base p		WITH(NOLOCK)	ON pf.ProdId = p.Prod_Id

				DELETE @ProductsFilter WHERE ProdId IS NULL

				SET @CompatiblePrO = (	SELECT COUNT(1)
										FROM @Processorders pp
										JOIN dbo.Bill_Of_Material_Formulation_Item bomfi WITH(NOLOCK)	ON pp.BOMFId = bomfi.BOM_Formulation_Id
										JOIN @ProductsFilter	 pf										ON bomfi.prod_id = pf.ProdId
										--WHERE pp.ForecastEndDate < @MaxDate 
										)

										

				SET @CompatiblePrO = @CompatiblePrO + (	SELECT COUNT(1)
														FROM @Processorders pp
														JOIN dbo.Bill_Of_Material_Formulation_Item bomfi WITH(NOLOCK)	ON pp.BOMFId = bomfi.BOM_Formulation_Id
														JOIN dbo.Bill_Of_Material_Substitution boms		WITH(NOLOCK)	ON bomfi.BOM_Formulation_Item_Id = boms.BOM_Formulation_Item_Id
														JOIN @ProductsFilter	 pf										ON boms.Prod_Id = pf.ProdId
														--WHERE pp.ForecastEndDate < @MaxDate 
														)




			END
			ELSE
			BEGIN
				-- No product filters
				SET @CompatiblePrO = (SELECT COUNT(1) FROM @Processorders)
			END

			--Update pro info
			UPDATE @Output
			SET Compatible_process_order_count			= @CompatiblePrO, 
				Active_or_inprep_process_order_desc		= @PrO,  
				Active_or_inprep_process_order_product	= @GCAS,
				Active_or_inprep_process_order_status	= @PPStatusDesc,
				Active_or_inprep_process_order_id =	@PrId
			WHERE Location_id = @puid

		END  --end of PrO management


		--------------------------------------------------------
		--Reservation management
		--------------------------------------------------------
		DELETE @Reservations

		SET @varIdType = NULL
		SET @varIdType = (SELECT var_id FROM dbo.variables_base WHERE pu_id = @Puid AND Test_Name = 'Type' AND Event_Subtype_Id = @ESReservation )

		IF @varIdType IS NULL
		BEGIN
			SET @CountSoft=0
			SET @CountHard=0
		END
		ELSE
		BEGIN
			INSERT @Reservations(	UDEId, Timestamp)
			SELECT ude_id, End_Time
			FROM dbo.User_Defined_Events WITH(NOLOCK)
			WHERE PU_Id = @Puid	
				AND Event_Subtype_Id = @ESReservation
				AND UDE_Desc = 'Reserved'

			UPDATE r
			SET type= t.result
			FROM @Reservations r
			JOIN dbo.Tests t		WITH(NOLOCK)	ON r.Timestamp = t.Result_On AND t.Var_Id = @varIdType

			SET @CountSoft = (SELECT COUNT(1) FROM @Reservations WHERE Type = 'Soft')
			SET @CountHard = (SELECT COUNT(1) FROM @Reservations WHERE Type = 'Hard')

		END

		UPDATE	@Output
		SET		Number_of_soft_reservations = @CountSoft,
				Number_of_hard_reservations = @CountHard
		WHERE	Location_id = @puid




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


		IF (SELECT location_type FROM @output WHERE location_id = @Puid)= 'Making'
		BEGIN


	
			------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			-- A) L = DIRTY, A = DIRTY; NO MOVE
			------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			IF (SELECT Cleaning_status FROM @output WHERE location_id = @puId)  = 'Dirty' AND @ApplianceCleaningStatus = 'Dirty' 
			BEGIN
				UPDATE	@Output
						SET  allowedtomove = 0 
						WHERE  Location_id = @Puid
				GOTO The_End
			END

			------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			-- B) L = DIRTY A = IN USE; NO MOVE - NO SUGGESTION
			------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			IF (SELECT Cleaning_status FROM @output WHERE location_id = @puId)  = 'Dirty' AND @ApplianceCleaningStatus = 'In Use' 
			BEGIN
		
		
				----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
				-- IF APPLIANCE PRODUCT ID IN NEXT PO BOM THEN MINOR ELSE MAJOR
				----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
				UPDATE	@Output
						SET  allowedtomove = 0 
						WHERE  Location_id = @Puid
				GOTO The_End
			END
	
			------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			-- C) L = IN USE, A = DIRTY; NO MOVE, EVALUATE MINIMAL CLEANING
			------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			IF (SELECT Cleaning_status FROM @output WHERE location_id = @puId)  = 'In use' AND @ApplianceCleaningStatus = 'Dirty' 
			BEGIN
				UPDATE	@Output
						SET  allowedtomove = 0 
						WHERE  Location_id = @Puid
				GOTO The_End
			END
			
			------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			-- D) L = IN USE, A = IN USE; EVALUATE BOM COMPONENTS.  IF NO FIT REFUSE MOVEMENT
			------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			IF (SELECT Cleaning_status FROM @output WHERE location_id = @puId)  = 'In use' AND @ApplianceCleaningStatus = 'In Use' 
			BEGIN
				--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
				-- EVALUATE IF APPLIANCE PRODUCT IS IN LOCATION BOM
				--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
				IF
					@ApplianceProdId
					NOT IN
					(
					SELECT		BOMFI.Prod_Id 
					FROM		dbo.Bill_Of_Material_Formulation BOMF WITH(NOLOCK)
								JOIN dbo.Production_plan PP WITH(NOLOCK)
									ON PP.BOM_Formulation_Id = BOMF.BOM_Formulation_Id 
								JOIN dbo.Bill_Of_Material_Formulation_Item BOMFI  WITH(NOLOCK) 
									ON BOMFI.BOM_Formulation_Id = BOMF.BOM_Formulation_Id
					WHERE		PP.PP_Id = @PrId
					)
				BEGIN
		
				--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
				-- REFUSE MOVEMENT
				--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
					UPDATE	@Output
							SET  allowedtomove = 0 
							WHERE  Location_id = @Puid
					GOTO The_End
				END
			END
				
			------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			-- E) L = CLEAN, A = DIRTY. ONLY EVALUATE MINiMAL CLEANING REQUIRED
			------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			IF (SELECT Cleaning_status FROM @output WHERE location_id = @puId)  = 'Clean' AND @ApplianceCleaningStatus = 'Dirty' 
			------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			-- EVALUATE MINIMAL CLEANING.  NEED LAST APPLIANCE PRODUCT AND LAST PRODUCT AT LOCATION
			------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			BEGIN
		
				UPDATE	@Output
						SET  allowedtomove = 0 
						WHERE  Location_id = @Puid
				GOTO The_End
			END
			------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			-- F) L = DIRTY, A = CLEAN.  NO EVALUATION --EVALUATE NEXT LOCATION CLEANING ACCORDING TO NEXT PO 
			------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			IF (SELECT Cleaning_status FROM @output WHERE location_id = @puId)  = 'Dirty' AND @ApplianceCleaningStatus = 'Clean' 
			BEGIN
		
				UPDATE	@Output
						SET  allowedtomove = 0 
						WHERE  Location_id = @Puid
				GOTO The_End

			
			END
			-----------------------------------------------------------------------------------------------------------------------------
			-- G) L = CLEAN, A = CLEAN
			-----------------------------------------------------------------------------------------------------------------------------
			IF (SELECT Cleaning_status FROM @output WHERE location_id = @puId)  = 'Clean' AND @ApplianceCleaningStatus = 'Clean' 
			BEGIN
				IF @ApplianceCleaningType = 'Minor'
				-------------------------------------------------------------------------------------------------------------------------
				-- IF BOTH LOCATION AND APPLIANCE STATUS ARE CLEAN AND APPLIANCE STATUS IS MINOR CLEANED, PRIOR PRODUCT MUST BE EVALUATED
				-------------------------------------------------------------------------------------------------------------------------
				BEGIN
					IF @ApplianceProdId
							NOT IN
							(
							SELECT		BOMFI.Prod_Id 
							FROM		dbo.Bill_Of_Material_Formulation BOMF 
										JOIN dbo.production_plan PP WITH(NOLOCK)
											ON PP.BOM_Formulation_Id = BOMF.BOM_Formulation_Id 
										JOIN dbo.Bill_Of_Material_Formulation_Item BOMFI  WITH(NOLOCK) 
											ON BOMFI.BOM_Formulation_Id = BOMF.BOM_Formulation_Id
							WHERE		PP.PP_Id = @PrId
							
							)
							AND
							(
								@ApplianceProdId
								!=
								(
								SELECT	prod_id 
								FROM	dbo.production_plan WITH(NOLOCK)
								WHERE PP_ID = @PrId
								) 
							)
						BEGIN
			
						---------------------------------------------------------------------------------------------------------------------
						-- NO COMPATIBLE PRODUCT IN BOM
						---------------------------------------------------------------------------------------------------------------------
							UPDATE	@Output
									SET  allowedtomove = 0 
									WHERE  Location_id = @Puid
							GOTO The_End
						END
					END
				END

			-----------------------------------------------------------------------------------------------------------------------------
			-- H) L = IN USE, A = CLEAN
			-----------------------------------------------------------------------------------------------------------------------------
			IF (SELECT Cleaning_status FROM @output WHERE location_id = @puId)  = 'In use' AND @ApplianceCleaningStatus = 'Clean' 
			BEGIN


				--Check Matrix cleaning
				SET @MatrixCleaning = (	SELECT CASE 
											WHEN CCM_Id = 1 THEN 'Major'
											WHEN CCM_Id = 2 THEN 'Minor'
											ELSE 'None'
										END
										FROM [dbo].[Local_CTS_Product_Transition_Cleaning_Methods] a
										WHERE From_Product_id = @ApplianceProdId
											AND To_Product_Id = (	SELECT	prod_id 
																	FROM	dbo.production_plan WITH(NOLOCK)
																	WHERE PP_ID = @PrId
																	) 
											AND (Location_id = @Puid OR Location_id IS NULL)
											AND END_TIME IS NULL 
										)

				IF @MatrixCleaning IS NULL
					SET @MatrixCleaning = 'None'


				--Matrix says major required
				IF @MatrixCleaning = 'Major' AND  @ApplianceCleaningType = 'Minor'
				BEGIN
					UPDATE	@Output
					SET  allowedtomove = 0 
					WHERE  Location_id = @Puid
					GOTO The_End
				END


				IF @ApplianceCleaningType = 'Minor' AND @MatrixCleaning = 'None'
				BEGIN		

					IF @ApplianceProdId IS NOT NULL
					BEGIN
						IF		@ApplianceProdId
								NOT IN
								(
								SELECT		BOMFI.Prod_Id 
								FROM		dbo.Bill_Of_Material_Formulation BOMF 
											JOIN dbo.production_plan PP WITH(NOLOCK)
												ON PP.BOM_Formulation_Id = BOMF.BOM_Formulation_Id 
											JOIN dbo.Bill_Of_Material_Formulation_Item BOMFI  WITH(NOLOCK) 
												ON BOMFI.BOM_Formulation_Id = BOMF.BOM_Formulation_Id
								WHERE		PP.PP_Id = @PrId
								
								)
								AND
								(
									@ApplianceProdId
									!=
									(
									SELECT	prod_id 
									FROM	dbo.production_plan WITH(NOLOCK)
									WHERE PP_ID = @PrId
									) 
								)
						BEGIN			
							---------------------------------------------------------------------------------------------------------------------
							-- NO COMPATIBLE PRODUCT IN BOM
							---------------------------------------------------------------------------------------------------------------------
							UPDATE	@Output
									SET  allowedtomove = 0 
									WHERE  Location_id = @Puid
							GOTO The_End
						END
					END		
				END
			END

			-----------------------------------------------------------------------------------------------------------------------------
			-- I) L = CLEAN, A = IN USE
			-----------------------------------------------------------------------------------------------------------------------------
			IF (SELECT Cleaning_status FROM @output WHERE location_id = @puId)  = 'Clean' AND @ApplianceCleaningStatus = 'In use' 
			BEGIN
				IF (SELECT Cleaning_type FROM @output WHERE location_id = @puId)  = 'Minor'
				BEGIN
					IF		@ApplianceProdId
							NOT IN
							(
							SELECT		BOMFI.Prod_Id 
							FROM		dbo.Bill_Of_Material_Formulation BOMF 
										JOIN dbo.production_plan PP WITH(NOLOCK)
											ON PP.BOM_Formulation_Id = BOMF.BOM_Formulation_Id 
										JOIN dbo.Bill_Of_Material_Formulation_Item BOMFI  WITH(NOLOCK) 
											ON BOMFI.BOM_Formulation_Id = BOMF.BOM_Formulation_Id
							WHERE		PP.PP_Id = @PrId

																				
							)
							OR
							(
							@ApplianceProdId
								!=
								(
								SELECT	prod_id 
								FROM	dbo.production_plan WITH(NOLOCK)
								WHERE PP_ID = @PrId
								) 
							)
					BEGIN
	
					---------------------------------------------------------------------------------------------------------------------
					-- NO COMPATIBLE PRODUCT IN BOM
					---------------------------------------------------------------------------------------------------------------------
						UPDATE	@Output
								SET  allowedtomove = 0 
								WHERE  Location_id = @Puid
						GOTO The_End
					END
				END
			END

		END
			


	/*---------------------------------------------
	refuse movement to all location under maintenance
	-----------------------------------------------*/
	UPDATE o
	SET AllowedToMove = 0
	FROM @Output o
	CROSS APPLY fnLocal_CTS_Location_Status(o.location_id,NULL) f
	WHERE f.Maintenance_Status = 'CST_Maintenance_Started'






	/*		IF (SELECt location_type FROM @output WHERE location_id = @Puid)= 'Making'
			BEGIN
				IF @ApplianceCleaningStatus = 'Clean' AND @ApplianceCleaningType = 'Minor' 
					--(SELECT	Clean_status 
					--FROM	fnLocal_CTS_Appliance_Status(@ApplianceEventId,NULL)
					--) = 'Clean'
					--AND
					--(
					--SELECT	Clean_type
					--FROM	fnLocal_CTS_Appliance_Status(@ApplianceEventId,NULL)
					--) = 'Minor'
				BEGIN
					UPDATE	@Output
					SET		allowedtomove = 0 
					WHERE	(SELECT prod_code FROM dbo.products_base WHERE prod_Id = @ApplianceProdId)
							!=
							Active_or_inprep_process_order_product
							AND location_id = @Puid					
				END		


				IF @ApplianceCleaningStatus = 'In use'
				BEGIN
					IF @PrId IS NOT NULL
					BEGIN
						IF @ApplianceProdId 
						NOT IN
						(
						SELECT	COALESCE(boms.Prod_Id, BOMFI.Prod_Id) 
						FROM	dbo.production_plan PP WITH(NOLOCK)
								JOIN dbo.production_plan_starts PPS WITH(NOLOCK)
									ON PPS.PP_id = PP.pp_id
									AND PPS.end_time IS NULL
									AND PPS.pu_id = @Puid
								JOIN dbo.Bill_Of_Material_Formulation_Item bomfi WITH(NOLOCK)	
									ON pp.BOM_Formulation_Id = bomfi.BOM_Formulation_Id
								LEFT JOIN dbo.Bill_Of_Material_Substitution boms	WITH(NOLOCK)	
									ON bomfi.BOM_Formulation_Item_Id = boms.BOM_Formulation_Item_Id
						) 
						BEGIN
							UPDATE	@Output
							SET  allowedtomove = 0 
							WHERE  Location_id = @Puid
						END
					END

				END

			END
	*/

		THE_END:

		SET @Puid = (SELECT MIN(location_id) FROM @Output WHERE location_id > @Puid)
	END  --End of Loop






	SELECT 	Serial,
			Location_id,
			Location_desc,
			Location_type,
			Cleaning_status,
			Active_Product,
			RequiresPOSelection,
			Compatible_process_order_count,
			Active_or_inprep_process_order_Id, 
			Active_or_inprep_process_order_desc, 
			Active_or_inprep_process_order_product,
			Active_or_inprep_process_order_status,
			Number_of_soft_reservations,
			Number_of_hard_reservations,
			Access,
			AllowedToMove,
			OMessage
	FROM @Output

	SET NOCOUNT OFF;
END
