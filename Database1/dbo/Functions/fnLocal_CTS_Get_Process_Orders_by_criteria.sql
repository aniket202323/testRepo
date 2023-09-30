

/*=====================================================================================================================
Local Function: fnLocal_CTS_Get_Process_Orders_by_criteria
=====================================================================================================================
 Author				:	Francois Bergeron (AutomaTech Canada)
 Date created			:	2021-10-15
 Version 				:	1.0
 Description			:	Get location POs
							The purpose of this function is to retrieve the process orders assigned to a location
 Editor tab spacing	: 4 


==================================================================================================
 EDIT HISTORY:

 ========		====	  		====					=====
 1.0			2021-10-15		F.Bergeron				Initial Release 
 1.1			2021-11-18		F.Bergeron				Add product filter
 1.2			2022-02-07		F.Bergeron				Add possibility to select a specific PP_Id
 1.3			2022-02-08		F.Bergeron				Retreive all Incomplete process orders and add product desc
 1.4			2022-03-01		F.Bergeron				Bit to return all POs
 1.5			2022-04-20		F.Bergeron				Bit to filter out POs that are not compatible with appliance in location
 1.6			2023-06-26		U. Lapierre				Adapt for Code review
==================================================================================================
Testing Code


 SELECT * FROM fnLocal_CTS_Get_Process_Orders_by_criteria('10415',NULL,NULL, NULL, NULL, NULL,NULL, 0)
==================================================================================================*/
CREATE   FUNCTION [dbo].[fnLocal_CTS_Get_Process_Orders_by_criteria] 
(
	@Location_Ids 					VARCHAR(500)	= NULL,
	@ProcessOrderId					INTEGER			= NULL,
	@StartTime						DATETIME		= NULL, 
	@EndTime						DATETIME		= NULL,
	@FProductId						VARCHAR(3000)	= NULL,
	@ByCount						INTEGER			= NULL,
	@Direction						VARCHAR(25)		= 'FORWARD',
	@IncludeCompleted				BIT				= 1
)
RETURNS @Output TABLE 
(
	Id								INTEGER IDENTITY(1,1),	
	Product_Id						INTEGER,
	Product_code					VARCHAR(50),
	Product_Desc					VARCHAR(50),
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
					
AS
BEGIN
	DECLARE
	@Location_Serial						VARCHAR(4000) = NULL,
	@LocationCleaningUDESubTypeId			VARCHAR(50),
	@LocationCleaningTypeVarId				INTEGER,
	@UTCStartTime							DATETIME,
	@UTCEndTime								DATETIME,
	@vchTimeZone							VARCHAR(50),
	@NullStartTime							DATETIME,
	@NullEndTime							DATETIME;
	
	DECLARE 
	@FProducts TABLE
	(
	Product_Id										INTEGER,
	Product_desc									INTEGER
	);

	DECLARE 
	@OrderStatus TABLE
	(
	SchStatusId										INTEGER,
	SchStatusDesc									VARCHAR(50)
	);


	DECLARE @ApplianceProductInLocation TABLE(
	Prod_id											INTEGER
	);
	
	DECLARE @AppliancesInLocation TABLE(	
	Serial											VARCHAR(25),
	Appliance_Id									INTEGER,
	Appliance_desc									VARCHAR(50),
	Appliance_Type									VARCHAR(50),
	Appliance_location_Id							INTEGER,
	Appliance_location_Desc							VARCHAR(50),
	Appliance_location_Type							VARCHAR(50),
	Appliance_status_Id								INTEGER,
	Appliance_status_desc							VARCHAR(25), /* Clean, In Use, Dirty */
	Appliance_status_type							VARCHAR(25), /* Major or Minor when clean */
	Appliance_Product_Id							INTEGER,
	Appliance_Product_desc							VARCHAR(50),
	Appliance_transition_event_id					INTEGER,
	Appliance_hardware_status_id					INTEGER,
	Appliance_hardware_status_desc					VARCHAR(50),
	Appliance_hardware_pu_id						INTEGER,
	Cleaning_status									VARCHAR(25), /* CTS Cleaning Started, CTS Ckeaning Completed, CTS Cleaning Rejected */
	Cleaning_Type									VARCHAR(25),
	Cleaning_PU_Id									INTEGER,
	Cleaning_PU_Desc								VARCHAR(50),	
	Appliance_PP_Id									INTEGER,
	Appliance_process_order							VARCHAR(100),
	Appliance_process_order_product_Id				INTEGER,
	Appliance_process_order_product_code			VARCHAR(50),
	Appliance_process_order_status_Id				INTEGER,
	Appliance_process_order_status_Desc				VARCHAR(50),
	Reservation_type								VARCHAR(25),
	Reservation_PU_Id								INTEGER,
	Reservation_PU_Desc								VARCHAR(50),
	Reservation_PP_Id								INTEGER,
	Reservation_Process_Order						VARCHAR(50),
	Reservation_Product_Id							INTEGER,
	Reservation_Product_Code						VARCHAR(50),
	Action_Reservation_Is_Active					BIT,
	Action_Cleaning_Is_Active						BIT,
	Action_Movement_Is_Active						BIT,
	Cleaning_level_allowed							VARCHAR(25),
	Allow_Cleaning_In_Place							BIT,
	Allow_Hardware_Status_Update					BIT,
	PPW_Movable										BIT,
	In_PPW											BIT,
	PPW_Requires_PO									INTEGER, /*0 = greyed out, 1 = mandatory, 2 = optional*/
	PPW_Requires_Product							INTEGER, /*0 = greyed out, 1 = mandatory, 2 = optional*/
	PPW_Match										BIT,
	Extended_Info									VARCHAR(500),				
	Status_Pending_Id								INTEGER,
	Status_Pending_Desc								VARCHAR(50),
	Cleaned_timer_hour								FLOAT,
	Cleaned_limit_hour								FLOAT,
	Used_timer_hour									FLOAT,
	Used_limit_hour									FLOAT,
	Used_timer_Second								FLOAT,
	Cleaned_timer_Second							FLOAT,
	Usage_Display_Message							VARCHAR(1000),
	Hardware_Display_Message						VARCHAR(1000)
	);

	DECLARE 
	@FAppliance_locations TABLE(
	Location_Id										INTEGER,
	Location_Desc									VARCHAR(50),
	Serial											VARCHAR(50)
	);

	INSERT INTO @FAppliance_locations(Serial)
	SELECT value 
	FROM STRING_SPLIT(@Location_Serial, ',');

	UPDATE	@FAppliance_locations
	SET		Location_id = PUB.PU_Id,
			Location_desc = PUB.PU_desc 
	FROM	dbo.Prod_units_base PUB
	JOIN dbo.Table_Fields_Values TFV WITH(NOLOCK)	ON  TFV.KeyId = PUB.PU_Id
	JOIN dbo.Table_Fields TF WITH(NOLOCK) 			ON TF.Table_Field_Id = TFV.Table_Field_Id
														AND TF.Table_Field_Desc = 'CTS Location serial number'
														AND TF.TableId =	(	SELECT	TableId 
																				FROM	dbo.Tables WITH(NOLOCK) 
																				WHERE	TableName = 'Prod_units'
																			)			
	JOIN @FAppliance_locations FAL					ON FAL.serial= CAST(TFV.Value AS VARCHAR(25));

	IF (SELECT COUNT(1) FROM @FAppliance_locations)=0
		INSERT INTO @FAppliance_locations (Location_Id, Location_Desc)
		SELECT		PU_ID, PU_Desc
		FROM		dbo.Prod_Units_Base PUB WITH(NOLOCK) 
		WHERE		PUB.Equipment_Type = 'CTS location';


	SET @Location_Ids = (SELECT STUFF((SELECT ',' + CAST(Location_id AS VARCHAR(25))FROM @FAppliance_locations FOR XML PATH('')),1,1,'') AS Result);

	IF @IncludeCompleted = 0
	BEGIN
		INSERT INTO @OrderStatus
		(
		SchStatusId,
		SchStatusDesc
		)
		SELECt	PP_Status_Id, 
				PP_Status_Desc 
		FROM	dbo.Production_Plan_Statuses WITH(NOLOCK)
		WHERE	PP_Status_Desc IN('Active','Pending');
	END
	ELSE
	BEGIN
		INSERT INTO @OrderStatus
		(
		SchStatusId,
		SchStatusDesc
		)
		SELECt	PP_Status_Id, 
				PP_Status_Desc 
		FROM	dbo.Production_Plan_Statuses WITH(NOLOCK)
		WHERE	PP_Status_Desc IN('Active','Pending','Complete');
	END

	INSERT INTO @FProducts(Product_id)
	SELECT CAST(value AS INTEGER) FROM STRING_SPLIT(@FProductId,',');

	IF (SELECT COUNT(1) FROM @FProducts) = 0
			INSERT INTO @Fproducts (Product_Id)
			SELECT		prod_id 
			FROM		dbo.Products_Base;


	IF @ByCount IS NOT NULL
	BEGIN
		IF @EndTime IS NULL
		BEGIN
			SET @EndTime = GETDATE();
		END

		IF @Direction = 'BACKWARD'
		BEGIN
			INSERT INTO	@Output
			(
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
				Location_desc

			)
			SELECT	
			DISTINCT
			TOP (@ByCount)	PP.Prod_Id 'Product_Id',
							P.Prod_code,
							P.Prod_Desc,
							PP.PP_Id,
							PP.Process_Order,
							PP.PP_Status_Id,
							PPSt.PP_Status_Desc,
							PP.Forecast_Start_Date,
							PP.Forecast_End_Date,
							PPS.Start_Time,
							PPS.End_time,
							PUB.PU_Id,
							PUB.pu_desc
			FROM		dbo.prod_units_Base PUB
			JOIN dbo.PrdExec_Path_Units PPU				WITH(NOLOCK)	ON PPU.PU_Id = PUB.PU_Id
			JOIN dbo.Production_plan PP					WITH(NOLOCK)	ON PP.Path_Id = PPU.Path_Id
																		AND PP.Path_Id IS NOT NULL 
			JOIN dbo.Production_Plan_Statuses PPSt		WITH(NOLOCK)	ON PPSt.PP_Status_Id = PP.PP_Status_Id
			JOIN dbo.products P							WITH(NOLOCK)	ON P.Prod_Id = PP.Prod_Id
			LEFT JOIN dbo.production_plan_starts PPS	WITH(NOLOCK) 	ON PPS.PP_Id = PP.PP_Id
																		AND PPS.PU_Id IN (	SELECT Location_Id 
																							FROM @FAppliance_locations
																						)
			JOIN dbo.Bill_Of_Material_Formulation_Item bomfi WITH(NOLOCK)	ON pp.BOM_Formulation_Id = bomfi.BOM_Formulation_Id
			LEFT JOIN dbo.Bill_Of_Material_Substitution boms WITH(NOLOCK)	ON bomfi.BOM_Formulation_Item_Id = boms.BOM_Formulation_Item_Id
			WHERE	PUB.PU_Id IN (	SELECT Location_Id 
									FROM @FAppliance_locations)
					AND PP.Forecast_Start_Date <= @EndTime
					AND PPSt.PP_Status_Id IN (	SELECT SchStatusId 
												FROM @OrderStatus
												)
			ORDER BY	PPS.start_time DESC;

			GOTO AFTER_INPUT_VAL;
		END
		IF @Direction = 'FORWARD'
		BEGIN
			INSERT INTO	@Output
			(
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
				Location_desc
			)
			SELECT	
			DISTINCT
			TOP (@ByCount)	PP.Prod_Id 'Product_Id',
							P.Prod_code,
							P.Prod_Desc,
							PP.PP_Id,
							PP.Process_Order,
							PP.PP_Status_Id,
							PPSt.PP_Status_Desc,
							PP.Forecast_Start_Date,
							PP.Forecast_End_Date,
							PPS.Start_Time,
							PPS.End_time,
							PUB.PU_Id,
							PUB.pu_desc
			FROM		dbo.prod_units_Base PUB
			JOIN dbo.PrdExec_Path_Units PPU						WITH(NOLOCK)	ON PPU.PU_Id = PUB.PU_Id
			JOIN dbo.Production_plan PP							WITH(NOLOCK)	ON PP.Path_Id = PPU.Path_Id
																				AND PP.Path_Id IS NOT NULL 
			JOIN dbo.Production_Plan_Statuses PPSt				WITH(NOLOCK)	ON PPSt.PP_Status_Id = PP.PP_Status_Id
			JOIN dbo.products_Base P							WITH(NOLOCK)	ON P.Prod_Id = PP.Prod_Id
			LEFT JOIN dbo.production_plan_starts PPS			WITH(NOLOCK) 	ON PPS.PP_Id = PP.PP_Id
																				AND PPS.PU_Id IN (	SELECT Location_Id 
																									FROM @FAppliance_locations
																									)
			JOIN dbo.Bill_Of_Material_Formulation_Item bomfi	WITH(NOLOCK)	ON pp.BOM_Formulation_Id = bomfi.BOM_Formulation_Id
			LEFT JOIN dbo.Bill_Of_Material_Substitution boms	WITH(NOLOCK)	ON bomfi.BOM_Formulation_Item_Id = boms.BOM_Formulation_Item_Id
			WHERE	PUB.PU_Id IN (	SELECT Location_Id 
									FROM @FAppliance_locations
									)
					AND PP.Forecast_Start_Date > @EndTime
					AND PPSt.PP_Status_Id IN (SELECT SchStatusId FROM @OrderStatus)
			ORDER BY	PP.Forecast_Start_Date ASC;

			GOTO AFTER_INPUT_VAL;
		END
	END


	IF EXISTS(SELECT 1 FROM dbo.production_plan WITH(NOLOCK) WHERE PP_id = @ProcessOrderId)
	BEGIN
		INSERT INTO	@Output
		(
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
			Location_desc

		)
		SELECT	DISTINCT 
				PP.Prod_Id 'Product_Id',
				P.Prod_code,
				P.Prod_Desc,
				PP.PP_Id,
				PP.Process_Order,
				PP.PP_Status_Id,
				PPSt.PP_Status_Desc,
				PP.Forecast_Start_Date,
				PP.Forecast_End_Date,
				PPS.Start_Time,
				PPS.End_time,
				PUB.PU_Id,
				PUB.pu_desc
		FROM	dbo.prod_units_Base PUB
		JOIN dbo.PrdExec_Path_Units PPU						WITH(NOLOCK)	ON PPU.PU_Id = PUB.PU_Id
		JOIN dbo.Production_plan PP							WITH(NOLOCK)	ON PP.Path_Id = PPU.Path_Id
																			AND PP.Path_Id IS NOT NULL 
		JOIN dbo.Production_Plan_Statuses PPSt				WITH(NOLOCK)	ON PPSt.PP_Status_Id = PP.PP_Status_Id
		JOIN dbo.products P									WITH(NOLOCK)	ON P.Prod_Id = PP.Prod_Id
		LEFT JOIN dbo.production_plan_starts PPS			WITH(NOLOCK) 	ON PPS.PP_Id = PP.PP_Id
		JOIN dbo.Bill_Of_Material_Formulation_Item bomfi	WITH(NOLOCK)	ON pp.BOM_Formulation_Id = bomfi.BOM_Formulation_Id
		LEFT JOIN dbo.Bill_Of_Material_Substitution boms	WITH(NOLOCK)	ON bomfi.BOM_Formulation_Item_Id = boms.BOM_Formulation_Item_Id
		WHERE	PP.PP_Id = @ProcessOrderId;

		GOTO AFTER_INPUT_VAL;
	END

	IF @StartTime IS NOT NULL and @Endtime > @StartTime
	BEGIN
		/* GET LOCATION ASSIGNED PROCESS ORDERS. NO PRODUCT*/
		INSERT INTO	@Output
		(
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
			Location_desc

		)
		SELECT	DISTINCT
				PP.Prod_Id 'Product_Id',
				P.Prod_code,
				P.prod_desc,
				PP.PP_Id,
				PP.Process_Order,
				PP.PP_Status_Id,
				PPSt.PP_Status_Desc,
				PP.Forecast_Start_Date,
				PP.Forecast_End_Date,
				PPS.Start_Time,
				PPS.End_time,
				PUB.PU_Id,
				PUB.pu_desc

		FROM	dbo.prod_units_Base PUB
		JOIN dbo.PrdExec_Path_Units PPU						WITH(NOLOCK)	ON PPU.PU_Id = PUB.PU_Id
		JOIN dbo.Production_plan PP							WITH(NOLOCK)	ON PP.Path_Id = PPU.Path_Id
																			AND PP.Path_Id IS NOT NULL 
		JOIN dbo.Production_Plan_Statuses PPSt				WITH(NOLOCK)	ON PPSt.PP_Status_Id = PP.PP_Status_Id
		JOIN dbo.products_base P							WITH(NOLOCK)	ON P.Prod_Id = PP.Prod_Id
		LEFT JOIN dbo.production_plan_starts PPS			WITH(NOLOCK) 	ON PPS.PP_Id = PP.PP_Id
																			AND PPS.PU_Id IN (	SELECT Location_Id 
																								FROM @FAppliance_locations)
		JOIN dbo.Bill_Of_Material_Formulation_Item bomfi	WITH(NOLOCK)	ON pp.BOM_Formulation_Id = bomfi.BOM_Formulation_Id
		LEFT JOIN dbo.Bill_Of_Material_Substitution boms	WITH(NOLOCK)	ON bomfi.BOM_Formulation_Item_Id = boms.BOM_Formulation_Item_Id
		WHERE	PUB.PU_Id IN (	SELECT Location_Id 
								FROM @FAppliance_locations)
				AND COALESCE(PPS.start_time, PP.Forecast_Start_Date) <= @EndTime 
				AND COALESCE(PPS.start_time, PP.Forecast_Start_Date) > @StartTime 
				AND PPSt.PP_Status_Id IN (	SELECT SchStatusId 
											FROM @OrderStatus
										)
		ORDER BY	PP.Forecast_Start_Date;
		GOTO AFTER_INPUT_VAL;
	END

	IF @StartTime IS NULL and @Endtime IS NULL
	BEGIN
		SET @EndTime = DATEADD(Day,1,GETDATE())
		/* GET LOCATION ASSIGNED PROCESS ORDERS. NO PRODUCT*/
		INSERT INTO	@Output
		(
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
			Location_desc

		)
		SELECT	DISTINCT
				PP.Prod_Id 'Product_Id',
				P.Prod_code,
				P.prod_desc,
				PP.PP_Id,
				PP.Process_Order,
				PP.PP_Status_Id,
				PPSt.PP_Status_Desc,
				PP.Forecast_Start_Date,
				PP.Forecast_End_Date,
				PPS.Start_Time,
				PPS.End_time,
				PUB.PU_Id,
				PUB.pu_desc
		FROM	dbo.prod_units_Base PUB
		JOIN dbo.PrdExec_Path_Units PPU						WITH(NOLOCK)	ON PPU.PU_Id = PUB.PU_Id
		JOIN dbo.Production_plan PP							WITH(NOLOCK)	ON PP.Path_Id = PPU.Path_Id
																			AND PP.Path_Id IS NOT NULL 
		JOIN dbo.Production_Plan_Statuses PPSt				WITH(NOLOCK)	ON PPSt.PP_Status_Id = PP.PP_Status_Id
		JOIN dbo.products_base P							WITH(NOLOCK)	ON P.Prod_Id = PP.Prod_Id
		LEFT JOIN dbo.production_plan_starts PPS			WITH(NOLOCK) 	ON PPS.PP_Id = PP.PP_Id
																			AND PPS.PU_Id IN (	SELECT Location_Id 
																								FROM @FAppliance_locations)
		JOIN dbo.Bill_Of_Material_Formulation_Item bomfi	WITH(NOLOCK)	ON pp.BOM_Formulation_Id = bomfi.BOM_Formulation_Id
		LEFT JOIN dbo.Bill_Of_Material_Substitution boms	WITH(NOLOCK)	ON bomfi.BOM_Formulation_Item_Id = boms.BOM_Formulation_Item_Id
		WHERE	PUB.PU_Id IN (	SELECT Location_Id 
								FROM @FAppliance_locations)
				AND COALESCE(PPS.start_time, PP.Forecast_Start_Date) <= @EndTime
				AND PPSt.PP_Status_Id IN (	SELECT SchStatusId 
											FROM @OrderStatus)
		ORDER BY	PP.Forecast_Start_Date;


		/* GET OLD PENDING ORDERS */
		INSERT INTO	@Output
		(
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
			Location_desc

		)
		SELECT	DISTINCT
				PP.Prod_Id 'Product_Id',
				P.Prod_code,
				P.prod_desc,
				PP.PP_Id,
				PP.Process_Order,
				PP.PP_Status_Id,
				PPSt.PP_Status_Desc,
				PP.Forecast_Start_Date,
				PP.Forecast_End_Date,
				PPS.Start_Time,
				PPS.End_time,
				PUB.PU_Id,
				PUB.pu_desc
		FROM	dbo.prod_units_Base PUB
		LEFT JOIN dbo.PrdExec_Path_Units PPU				WITH(NOLOCK)	ON PPU.PU_Id = PUB.PU_Id
		LEFT JOIN dbo.Production_plan PP					WITH(NOLOCK)	ON PP.Path_Id = PPU.Path_Id
																			AND PP.Path_Id IS NOT NULL 
		JOIN dbo.Production_Plan_Statuses PPSt				WITH(NOLOCK)	ON PPSt.PP_Status_Id = PP.PP_Status_Id
		JOIN dbo.products_Base P							WITH(NOLOCK)	ON P.Prod_Id = PP.Prod_Id
		LEFT JOIN dbo.production_plan_starts PPS			WITH(NOLOCK) 	ON PPS.PP_Id = PP.PP_Id
																			AND PPS.PU_Id IN (	SELECT Location_Id 
																								FROM @FAppliance_locations)
		JOIN dbo.Bill_Of_Material_Formulation_Item bomfi	WITH(NOLOCK)	ON pp.BOM_Formulation_Id = bomfi.BOM_Formulation_Id
		LEFT JOIN dbo.Bill_Of_Material_Substitution boms	WITH(NOLOCK)	ON bomfi.BOM_Formulation_Item_Id = boms.BOM_Formulation_Item_Id
		WHERE	PUB.PU_Id IN (	SELECT Location_Id 
								FROM @FAppliance_locations)
				AND COALESCE(PPS.start_time, PP.Forecast_Start_Date) <= @EndTime 
				AND COALESCE(PPS.start_time, PP.Forecast_Start_Date) > @StartTime 
				AND PPSt.PP_Status_Id IN (	SELECT SchStatusId 
											FROM @OrderStatus)
		ORDER BY	PP.Forecast_Start_Date;
		GOTO AFTER_INPUT_VAL;
	END

	AFTER_INPUT_VAL:
	IF @FProductId IS NOT NULL
	BEGIN
		DELETE  @Output
		FROM	dbo.production_plan PP						WITH(NOLOCK)	
		JOIN @output O														ON O.Process_order_Id = PP.PP_id
		JOIN dbo.Bill_Of_Material_Formulation_Item bomfi	WITH(NOLOCK)	ON PP.BOM_Formulation_Id = bomfi.BOM_Formulation_Id
		LEFT JOIN dbo.Bill_Of_Material_Substitution boms	WITH(NOLOCK)	ON bomfi.BOM_Formulation_Item_Id = boms.BOM_Formulation_Item_Id
		WHERE	(COALESCE(BOMS.prod_id,bomfi.Prod_Id) NOT IN (	SELECT Product_Id 
																FROM  @FProducts) 
				AND
				PP.prod_id NOT IN (	SELECT Product_Id 
									FROM  @FProducts)
				) ;
	END	

	IF @Location_Ids IS NOT NULL
	BEGIN
		INSERT INTO @AppliancesInLocation(
		Serial,
		Appliance_Id,
		Appliance_desc,
		Appliance_Type,
		Appliance_location_Id,
		Appliance_location_Desc,
		Appliance_location_Type,
		Appliance_Status_Id,
		Appliance_Status_Desc,
		Appliance_Status_Type,
		Appliance_product_Id,
		Appliance_product_Desc,
		Cleaning_status,
		Cleaning_Type,
		Cleaning_PU_Id,
		Cleaning_PU_Desc,	
		Appliance_PP_Id,
		Appliance_process_order,
		Appliance_process_order_product_Id,
		Appliance_process_order_product_code,
		Appliance_process_order_status_Id,
		Appliance_process_order_status_Desc,
		Appliance_hardware_status_id,
		Appliance_hardware_status_desc,
		Reservation_type,
		Reservation_PU_Id,
		Reservation_PU_Desc,
		Reservation_PP_Id,
		Reservation_Process_Order,
		Reservation_Product_Id,
		Reservation_Product_Code,
		Action_Reservation_Is_Active,
		Action_Cleaning_Is_Active,
		Action_Movement_Is_Active,
		Cleaning_level_allowed,
		Allow_Cleaning_In_Place,
		Allow_Hardware_Status_Update,
		PPW_movable,
		In_PPW,
		PPW_Requires_PO,
		PPW_Requires_Product,
		PPW_Match,
		Status_Pending_Id,
		Status_Pending_Desc,
		Cleaned_limit_hour,
		Used_limit_hour,
		Cleaned_timer_hour,
		Used_timer_hour,
		Usage_Display_Message,
		Hardware_Display_Message)
		SELECT 
		Serial,
		Appliance_Id,
		Appliance_desc,
		Appliance_Type,
		Appliance_location_Id,
		Appliance_location_Desc,
		Appliance_location_Type,
		Appliance_Status_Id,
		Appliance_Status_Desc,
		Appliance_Status_Type,
		Appliance_product_Id,
		Appliance_product_Desc,
		Cleaning_status,
		Cleaning_Type,
		Cleaning_PU_Id,
		Cleaning_PU_Desc,	
		Appliance_PP_Id,
		Appliance_process_order,
		Appliance_process_order_product_Id,
		Appliance_process_order_product_code,
		Appliance_process_order_status_Id,
		Appliance_process_order_status_Desc,
		Appliance_hardware_status_id,
		Appliance_hardware_status_desc,
		Reservation_type,
		Reservation_PU_Id,
		Reservation_PU_Desc,
		Reservation_PP_Id,
		Reservation_Process_Order,
		Reservation_Product_Id,
		Reservation_Product_Code,
		Action_Reservation_Is_Active,
		Action_Cleaning_Is_Active,
		Action_Movement_Is_Active,
		Cleaning_level_allowed,
		Allow_Cleaning_In_Place,
		Allow_Hardware_Status_Update,
		PPW_movable,
		In_PPW,
		PPW_Requires_PO,
		PPW_Requires_Product,
		PPW_Match,
		Status_Pending_Id,
		Status_Pending_Desc,
		Cleaned_limit_hour,
		Used_limit_hour,
		Cleaned_timer_hour,
		Used_timer_hour,
		Usage_Display_Message,
		Hardware_Display_Message
		FROM dbo.fnLocal_CTS_Get_Appliances_by_Criteria (NULL,NULL,NULL, @Location_Ids,NULL,NULL,'CTS.System');

		INSERT INTO @ApplianceProductInLocation(Prod_id)
		SELECT 
		DISTINCT	Appliance_Product_Id
		FROM		@AppliancesInLocation
		WHERE		Appliance_Status_Desc IN('Clean', 'In use');
	
		UPDATE	@Output
		SET		AllowToSelectInCurrentLocation = 1
		IF (SELECT COUNT(1) FROM @ApplianceProductInLocation) > 0 
		BEGIN
			UPDATE  @Output
			SET		AllowToSelectInCurrentLocation = 0
			FROM	dbo.production_plan PP WITH(NOLOCK)
					JOIN @output O
						ON O.Process_order_Id = PP.PP_id
					JOIN dbo.Bill_Of_Material_Formulation_Item bomfi WITH(NOLOCK)
						ON PP.BOM_Formulation_Id = bomfi.BOM_Formulation_Id
					LEFT JOIN dbo.Bill_Of_Material_Substitution boms WITH(NOLOCK)	
						ON bomfi.BOM_Formulation_Item_Id = boms.BOM_Formulation_Item_Id
			WHERE	(COALESCE(BOMS.prod_id,bomfi.Prod_Id) NOT IN (SELECT prod_id FROM @ApplianceProductInLocation)
					AND
					PP.prod_id NOT IN (SELECT prod_id FROM @ApplianceProductInLocation));

		END
	END
	GOTO LAFIN
	LaFin:
	RETURN

END



