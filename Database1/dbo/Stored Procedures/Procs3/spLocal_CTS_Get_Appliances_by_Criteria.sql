
/*===========================================================================================
Stored Procedure: spLocal_CTS_Get_Appliances_by_Criteria
===========================================================================================
Author				: Francois Bergeron, Symasol
Date created			: 2021-08-12
Version 				: Version 1.0
SP Type				: WEB
Caller				: WEB SERVICE
Description			: The purpose of this query is to get the appliances by different criteria
Editor tab spacing	: 4
===========================================================================================
===========================================================================================
EDIT HISTORY:
===========================================================================================
===========================================================================================
1.0			2021-08-12		F. Bergeron				Initial Release 
1.1			2022-01-13		F. Bergeron				Modification of the process order query
1.2			2022-01-14		F. Bergeron				Add appliance status type when the appliance is clean
1.3			2022-01-27		F. Bergeron				Only major celan can be moved to PPW location and appliance cleaning type can be determined by a UDP 
1.4			2022-02-07		F. Bergeron				Add parameter to fnLocal_CTS_Location_Status
1.5			2022-02-09		F. Bergeron				Missing the timer limits
1.6			2022-02-09		F. Bergeron				PPW Located flag 
1.7			2022-02-22		F. Bergeron				Add Cleaning_level_allowed to prevent seleting the cleaning function when an appliance cleaning is ongoin at location
1.8			2022-04-25		F. Bergeron				Improve performance - restrictopmn for appliances statuses
1.9			2022-09-14		U.Lapierre.u			Apply matrix rule
1.10		2022-09-16		U.Lapierre.u			FIx issue with material not in BOM
1.11		2023-03-02		U.Lapierre				Allow multiple simultaneous cleanings in a location
1.12		2023-04-05		U. Lapierre				Fix issue when filtering products
1.13		2023-04-21		U. Lapierre				Set limit to the max number of appliance to be cleanned simultaneously
================================================================================================

===========================================================================================
TEST CODE:
===========================================================================================

EXECUTE [spLocal_CTS_Get_Appliances_by_Criteria] '1357908642',NULL,NULL,NULL, NULL,NULL,NULL,'Bergeron.fe'
EXECUTE [spLocal_CTS_Get_Appliances_by_Criteria] NULL, NULL,NULL, '10432', NULL,NULL,0,'Bergeron.fe'
SELECT * FROM event_details WHERE event_id = 997982

===========================================================================================*/



CREATE   PROCEDURE [dbo].[spLocal_CTS_Get_Appliances_by_Criteria]
	@Serial						VARCHAR(25)		= NULL,
	@F_Product					VARCHAR(4000)	= NULL,
	@F_Appliance_status			VARCHAR(25)		= NULL,
	@F_Appliance_location		VARCHAR(255)	= NULL,
	@F_Appliance_type			VARCHAR(255)	= NULL,
	@Destination_location		INTEGER			= NULL,
	@ShowDecommissioned			BIT				= 0,
	@C_User						VARCHAR(100)


AS
BEGIN
	SET NOCOUNT ON;
	-- SP Variables
	DECLARE 
	@F_Appliance_Id					INTEGER,
	@C_User_Id						INTEGER,
	@TableId						INTEGER,
	@ApplianceTypeTFiD				INTEGER,
	@ApplianceTypeHMTFiD			INTEGER,
	@LocationTypeTFiD				INTEGER,
	@CleanedTimerLimitTFid			INTEGER,	
	@UsedTimerLimitTFid				INTEGER,
	@DestinationLocationType		VARCHAR(50),
	@NewLineChar					VARCHAR(2) = CHAR(13) + CHAR(10),
	@MaxSimulAppCleaningTFiD		INTEGER
	
	DECLARE @ApplianceCleanMethod	TABLE(
	TF_Id				INTEGER,
	TD_Desc				VARCHAR(50)
	)

	DECLARE
	@Output TABLE
	(	Id												INTEGER IDENTITY(1,1),
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
							
	)

	DECLARE
	@EventSubtypeId INTEGER
	SET @EventSubtypeId = (SELECT	Event_Subtype_Id 
							FROM	dbo.event_subtypes  WITH(NOLOCK)
							WHERE	ET_ID = 14 AND event_subtype_desc = 'CTS Appliance Cleaning')

	SET @TableId = (SELECt tableId from dbo.tables WITH(NOLOCK) WHERE tableName = 'prod_units')

	/*  UDP */
	SET @ApplianceTypeTFiD =		(SELECT	table_field_id  
									FROM	dbo.table_fields 
									WHERE   Table_Field_Desc = 'CTS Appliance type' 
											AND TableId = @tableId)
	SET @ApplianceTypeHMTFiD =		(SELECT	table_field_id  
									FROM	dbo.table_fields 
									WHERE   Table_Field_Desc = 'CTS Appliance holds material' 
											AND TableId = @tableId)
	SET @LocationTypeTFiD =			(SELECT	table_field_id  
									FROM	dbo.table_fields 
									WHERE   Table_Field_Desc = 'CTS Location type' 
											AND TableId = @tableId)
	SET @CleanedTimerLimitTFid =	(SELECT	table_field_id  
									FROM	dbo.table_fields 
									WHERE   Table_Field_Desc = 'CTS time since last cleaned threshold (hours)' 
											AND TableId = @tableId)
	SET @UsedTimerLimitTFid =		(SELECT	table_field_id  
									FROM	dbo.table_fields 
									WHERE   Table_Field_Desc = 'CTS time since last used threshold (hours)' 
												AND TableId = @tableId)
	SET @MaxSimulAppCleaningTFiD =	(SELECT	table_field_id  
									FROM	dbo.table_fields 
									WHERE   Table_Field_Desc = 'CST Max Simultaneous Appliance Cleaning'
												AND TableId = @tableId)

	DECLARE @now DATETIME
	SET @now = GETDATE()
	DECLARE @RMI TABLE(
	RMId				INTEGER,
	Type				VARCHAR(25),
	Source_Pu_id		INTEGER,
	Valid_Status_id		INTEGER)

	DECLARE @Destination_status TABLE(
	status_desc	VARCHAR(50),
	prod_id INTEGER)
	
	IF @Destination_location IS NOT NULL
	BEGIN
		INSERT INTO @RMI(RMId,Type,Source_Pu_id,Valid_Status_id) 
		SELECT		PEI.PEI_Id, 
					PEI.Input_Name, 
					PEIS.PU_Id,
					PEISD.Valid_Status
		FROM		dbo.PrdExec_Inputs PEI WITH(NOLOCK) 
					JOIN dbo.PrdExec_Input_Sources PEIS WITH(NOLOCK) 
						ON PEI.PEI_Id = PEIS.PEI_Id
					JOIN dbo.PrdExec_Input_Source_Data PEISD WITH(NOLOCK) 
						ON PEISD.PEIS_Id = PEIS.PEIS_Id
		WHERE		PEI.PU_Id = @Destination_location

		DELETE @RMI WHERE Valid_Status_id IS NULL

		INSERT INTO @Destination_status 
					(status_desc,
					prod_id)
		SELECT		Location_status,Last_product_id 
		FROM		fnLocal_CTS_Location_Status(@Destination_location,NULL)
	END
	

	/*=====================================================================================================================
	FILTER LOCATIONS
	=====================================================================================================================*/
	DECLARE 
	@FAppliance_locations TABLE
	(
		PU_Id						INTEGER,
		PU_Desc						VARCHAR(50),
		Type						VARCHAR(50),
		MaxSimulApp					INT DEFAULT 5,
		CntActiveAppCleaning		INT DEFAULT 0
	)

	INSERT INTO @FAppliance_locations(PU_Id)
	SELECT		value 
	FROM		STRING_SPLIT(@F_Appliance_location, ',');

	UPDATE	@FAppliance_locations
	SET		PU_Desc = PUB.PU_Desc,
			Type = TFV.value
	FROM	@FAppliance_locations FAL
			JOIN dbo.prod_units_base PUB
				ON FAL.pu_id = PUB.PU_id 
			JOIN Table_Fields_Values TFV
				ON TFV.keyId = FAL.PU_Id
				AND TFV.TableId = @TableId
				AND TFV.Table_Field_Id = @LocationTypeTFiD

	DELETE @FAppliance_locations WHERE PU_ID IS NULL
	

	IF (SELECT COUNT(1) FROM @FAppliance_locations)=0
	BEGIN
		INSERT INTO @FAppliance_locations (PU_ID, PU_Desc,Type)
		SELECT	PU_ID, PU_Desc,TFV.Value
		FROM	dbo.Prod_Units_Base PUB WITH(NOLOCK) 
				JOIN Table_Fields_Values TFV
						ON TFV.keyId = PUB.PU_Id
						AND TFV.Table_Field_Id = @LocationTypeTFiD
						AND TFV.TableId = @TableId
		WHERE	PUB.Equipment_Type = 'CTS location'
	END

	/* Get max cleaning simultaneaous */
	UPDATE al
	SET MaxSimulApp = CONVERT(INTEGER,TFV.value)
	FROM @FAppliance_locations al
	JOIN dbo.prod_units_base PUB		WITH(NOLOCK)	ON al.pu_id = PUB.PU_id 
	JOIN Table_Fields_Values TFV		WITH(NOLOCK)	ON TFV.keyId = al.PU_Id
				AND TFV.TableId = @TableId
				AND TFV.Table_Field_Id = @MaxSimulAppCleaningTFiD


	 
	/*=====================================================================================================================
	FILTER Products
	=====================================================================================================================*/
	DECLARE 
	@F_Products TABLE
	(
		Product_Id					INTEGER,
		Product_desc				INTEGER
	)

	INSERT INTO @F_Products(Product_id)
	SELECT		CAST(value AS INTEGER) 
	FROM		STRING_SPLIT(@F_Product, ',');


/*
	IF (SELECT COUNT (1) FROM @F_Products) = 0 
	BEGIN
		INSERT INTO @F_Products (Product_id)
		SELECT	prod_id
		FROM	dbo.products_base WITH(NOLOCK)
	END
*/

	/*=====================================================================================================================
	FILTER Statuses
	=====================================================================================================================*/
	DECLARE 
	@FAppliance_statuses TABLE
	(
		Status_id					INTEGER,
		Status_Desc					VARCHAR(50)
	)	
	INSERT INTO	@FAppliance_statuses (Status_Id)
	SELECT		VALUE 
	FROM		STRING_SPLIT(@F_Appliance_Status, ',');

	/*=====================================================================================================================
	FILTER Appliance types
	=====================================================================================================================*/
	DECLARE 
	@FAppliance_types TABLE
	(
		PU_Id						INTEGER,
		Type						VARCHAR(50)
	)
	INSERT INTO @FAppliance_types (Type)
	SELECT		VALUE 
	FROM		STRING_SPLIT(@F_Appliance_type, ',');

	IF (SELECT COUNT(1) FROM @FAppliance_types) > 0
	BEGIN
		UPDATE	@FAppliance_types 
		SET		PU_Id = KeyId 					
		FROM	dbo.Table_Fields_Values TFV with(nolock)
				JOIN dbo.prod_units_base PUBA with(nolock)
					ON PUBA.pu_id = TFV.keyid
		WHERE	Table_Field_id = @ApplianceTypeTFID
				AND tableid = @tableid
				AND puba.Equipment_Type = 'CTS Appliance'
				AND TFV.value = Type
	END
	ELSE
	BEGIN
		INSERT INTO @FAppliance_types (PU_Id,Type) 
		SELECT		KeyId, 
					Value		
		FROM		dbo.Table_Fields_Values TFV with(nolock)
					JOIN dbo.prod_units_base PUBA with(nolock)
						ON PUBA.pu_id = TFV.keyid
		WHERE		Table_Field_id = @ApplianceTypeTFID
					AND tableid = @tableid
					AND puba.Equipment_Type = 'CTS Appliance'
	END

	/*=====================================================================================================================
	BUILD INTERMEDIATE DATASETS
	GET ALL APPLIANCES
	=====================================================================================================================*/
	DECLARE @Appliances TABLE(
	Appliance_event_id	INTEGER,
	Appliance_type		VARCHAR(50),
	Appliance_serial	VARCHAR(25),
	Appliance_event_num	VARCHAR(50),
	Appliance_status_id	INTEGER,
	Appliance_status_desc VARCHAR(50),
	Appliance_pu_id		INTEGER,
	Appliance_clean_timer_limit INTEGER,
	Appliance_usage_timer_limit INTEGER,
	Appliance_holds_material	BIT,
	Timestamp DATETIME
	)

	INSERT INTO @Appliances (
				Appliance_event_id,
				appliance_type,
				Appliance_serial, 
				Appliance_event_num, 
				Appliance_status_id, 
				Appliance_status_desc,
				Appliance_pu_id,
				Appliance_clean_timer_limit,
				Appliance_usage_timer_limit,
				Appliance_holds_material,
				Timestamp
				)
	SELECT		E.event_id, 
				TFV1.Value, 
				ED.alternate_event_num,
				E.event_num, 
				PS.ProdStatus_Id, 
				PS.ProdStatus_Desc,
				E.PU_Id,
				TFV2.Value,
				TFV3.Value,
				TFV4.Value,
				E.timestamp
	FROM		dbo.events E WITH(NOLOCK)
				JOIN dbo.event_details ED
					ON ED.event_id = E.event_id
				JOIN dbo.Prod_Units_Base PUB WITH(NOLOCK) 
					ON PUB.PU_id = E.pu_id
				JOIN dbo.table_fields_values TFV1
					ON TFV1.keyId = PUB.pu_id 
					AND TFV1.table_field_id = @ApplianceTypeTFiD
				JOIN dbo.Production_Status PS
					ON PS.ProdStatus_Id = E.Event_Status
				JOIN dbo.Table_Fields_Values TFV2 WITH(NOLOCK)
					ON TFV2.keyId = E.pu_id 
					AND TFV2.TableId = @TableId
					AND TFV2.Table_Field_Id = @CleanedTimerLimitTFid 
				JOIN dbo.Table_Fields_Values TFV3 WITH(NOLOCK)
					ON TFV3.keyId = E.pu_id 
					AND TFV3.TableId = @TableId
					AND TFV3.Table_Field_Id = @UsedTimerLimitTFid 
				JOIN dbo.Table_Fields_Values TFV4 WITH(NOLOCK)
					ON TFV4.keyId = E.pu_id 
					AND TFV4.TableId = @TableId
					AND TFV4.Table_Field_Id = @ApplianceTypeHMTFiD 
	WHERE		PUB.Equipment_Type = 'CTS Appliance'	


	/*=====================================================================================================================
	GET CURRENT POSITION
	=====================================================================================================================*/
	DECLARE @Appliance_current_status TABLE(
	Appliance_event_id	INTEGER,
	Location_event_id	INTEGER,
	Location_pu_id		INTEGER,
	Location_pu_desc	VARCHAR(50),
	Location_event_status_id	INTEGER,
	Location_event_status_desc	VARCHAR(50),
	Location_event_applied_product	INTEGER,
	Location_event_applied_product_desc VARCHAR(50),
	Start_time DATETIME,
	timestamp DATETIME
	)
	INSERT INTO @Appliance_current_status(
			Appliance_event_id,
			Location_event_id,
			Location_pu_id,
			Location_pu_desc,
			Location_event_status_id,
			Location_event_status_desc,
			Location_event_applied_product,
			Location_event_applied_product_desc,
			E.start_time,
			E.timestamp)
	SELECT  EC.Source_Event_Id,
			EC.Event_Id,
			E.pu_id,
			PUB.PU_Desc,
			E.Event_Status,
			PS.ProdStatus_Desc,
			E.Applied_Product,
			PB.Prod_Desc,
			E.start_time,
			E.timestamp
	FROM	dbo.event_components EC WITH(NOLOCK)
			JOIN (SELECT	EC.source_event_id 'Source_event_id', 
							MAX(EC.timestamp) 'timestamp'
					FROM		dbo.event_components EC	WITH(NOLOCK)
							JOIN @Appliances A 
								ON A.Appliance_event_id = EC.Source_event_id 
				GROUP BY	EC.source_event_id
			) Q1
				ON EC.Source_Event_Id = Q1.Source_event_id
				AND Q1.timestamp = EC.timestamp
			JOIN dbo.events E WITH(NOLOCK)
				ON E.event_id = EC.Event_Id
			JOIN dbo.Prod_Units_Base PUB
				ON PUB.pu_id = E.PU_Id
			JOIN dbo.Production_Status PS
				ON PS.ProdStatus_Id = E.Event_Status
			LEFT JOIN dbo.products_base PB 
				ON PB.prod_id = E.Applied_Product



	DECLARE @Appliance_Last_Use TABLE(
	ApplianceId			INTEGER,
	Last_use			DATETIME
	)


	INSERT INTO @Appliance_Last_Use(	
	ApplianceId,
	Last_use)

	SELECT  MAX(A.Appliance_event_id),
			MAX(Q.start_time)

	FROM	@Appliances A
			JOIN event_components EC  
				ON EC.source_event_id = A.Appliance_event_id
			OUTER APPLY(
			SELECT TOP 1	EST.Start_time,PS.prodStatus_desc 
			FROM			dbo.Event_Status_Transitions EST WITH(NOLOCK) 
							JOIN dbo.Production_Status PS WITH(NOLOCK) 
								ON PS.prodStatus_id = EST.Event_Status 
							JOIN dbo.event_details ED WITH(NOLOCK)
								ON ED.event_id = EST.event_id
							JOIN @FAppliance_locations FAL 
								ON FAL.pu_id = EST.pu_id
			WHERE			EST.event_id = EC.event_id 
							AND PS.prodStatus_desc = 'In Use' 
							AND ED.PP_ID IS NOT NULL
							AND FAL.type = 'Making'
			ORDER BY		EST.Start_time DESC)Q
			GROUP BY		EC.source_event_id 


	/*=====================================================================================================================
	GET Appliance production
	=====================================================================================================================*/
	DECLARE @Appliance_Production TABLE(
	Appliance_event_id			INTEGER,
	Location_event_id			INTEGER,
	PP_ID						INTEGER,
	Prod_id						INTEGER,
	Prod_desc					VARCHAR(50),
	Prod_code					VARCHAR(50),
	Process_order				VARCHAR(50),
	Process_order_status_id		INTEGER,
	Process_order_status_desc	VARCHAR(50)
	)


	INSERT INTO @Appliance_Production	(
										Appliance_event_id,
										Location_event_id, 
										PP_ID, 
										Prod_id, 
										Prod_desc, 
										Prod_code, 
										Process_order,
										Process_order_status_id,
										Process_order_status_desc
										)
	SELECT	ACS.Appliance_event_id,
			ED.event_id, 
			ED.PP_Id,
			PUB.Prod_Id, 
			PUB.prod_desc,
			PUB.prod_code, 
			PP.Process_Order,
			PPSt.PP_Status_Id, 
			PPSt.PP_Status_Desc
	FROM	event_details ED 
			JOIN @Appliance_current_status ACS
				ON ACS.Location_event_id = ED.Event_Id
			JOIN dbo.production_plan PP WITH(NOLOCK) 
				ON PP.pp_id = ED.pp_id
			JOIN dbo.Production_Plan_Statuses PPSt WITH(NOLOCK)
					ON PPSt.PP_Status_Id = PP.PP_Status_Id
			JOIN dbo.products_base PUB
				ON PUB.Prod_Id = PP.Prod_Id

	/*=====================================================================================================================
	GET All cleanings
	=====================================================================================================================*/
	DECLARE @Appliance_last_cleaning TABLE(
	Appliance_event_id	INTEGER,
	Location_pu_id		INTEGER,
	Location_pu_desc	VARCHAR(50),
	Start_time			DATETIME,
	End_time			DATETIME,
	Cleaning_status		VARCHAR(50),
	Type				VARCHAR(25)
	)
	
	
	INSERT INTO	@Appliance_last_cleaning(
				Appliance_event_id,
				Location_pu_id,
				Location_pu_desc,
				Start_time,
				End_time,
				Cleaning_status,
				Type
				)
	SELECT		A.Appliance_event_id,
				Q1.Location_id,
				Q1.location_desc,
				Q1.Start_time,
				Q1.End_time,
				Q1.Status,
				Q1.Type				
	FROM		@Appliances	A 
				CROSS APPLY (SELECT 
									Status,
									type,
									Location_id,
									Location_desc,
									Start_time,
									End_time
		
							FROM	[dbo].[fnLocal_CTS_Appliance_Cleanings](A.Appliance_event_id , NULL, NULL)
							) Q1

	/*=====================================================================================================================
	GET ALL LAST COMPLETED CLEANINGS
	=====================================================================================================================*/
	DECLARE @Appliance_last_completed_cleaning TABLE(
	Appliance_event_id	INTEGER,
	Location_pu_id		INTEGER,
	Location_pu_desc	VARCHAR(50),
	Start_time			DATETIME,
	End_time			DATETIME,
	Cleaning_status		VARCHAR(50),
	Type				VARCHAR(25)
	)
	
	
	INSERT INTO	@Appliance_last_completed_cleaning(
				Appliance_event_id,
				Location_pu_id,
				Location_pu_desc,
				Start_time,
				End_time,
				Cleaning_status,
				Type
				)
	SELECT		A.Appliance_event_id,
				Q.pu_id,
				Q.pu_id,
				Q.Start_time,
				Q.End_time,
				(CASE Q.prodstatus_desc
				WHEN 'CTS_Cleaning_Started' THEN 'Cleaning started'
				WHEN 'CTS_Cleaning_Completed' THEN 'Cleaning completed'
				WHEN 'CTS_Cleaning_Approved' THEN 'Clean'
				WHEN 'CTS_Cleaning_Cancelled' THEN 'Cleaning cancelled'
				WHEN 'CTS_Cleaning_Rejected' THEN 'Cleaning  rejected'
				ELSE 'Cleaning status not found'
				END)							'Cleaning_Status',
				Q.result				
	FROM		@Appliances	A 
				CROSS APPLY 
				(SELECT top 1 PUB.pu_id, PUB.pu_desc, UDE.UDE_id, UDE.event_id, UDE.start_time, UDE.end_time, PS.prodStatus_desc, T.result 
				FROM dbo.user_defined_events UDE WITH(NOLOCK)
				JOIN dbo.production_status PS WITH(NOLOCK) 
					ON PS.prodStatus_id = UDE.Event_Status
				JOIN dbo.prod_units_base PUB 
					ON PUB.pu_id = UDE.pu_id
				JOIN dbo.variables_Base VB WITH(NOLOCK) 
					ON VB.pu_id = UDE.pu_id
					AND VB.Test_Name = 'Type'
				LEFT JOIN dbo.tests T WITH(NOLOCK)
					ON T.var_id = VB.var_id
						AND T.result_on = UDE.end_time
				WHERE PS.prodstatus_desc = 'CTS_Cleaning_Approved'
				AND UDE.event_id = A.Appliance_event_id
				ORDER BY UDE.end_time desc) Q
				 
			


	DECLARE @location_transition_cleaning_level_UDP TABLE(
	Table_Field_Id	INTEGER,
	Table_Field_desc VARCHAR(50)
	)

	INSERT INTO @location_transition_cleaning_level_UDP (Table_field_id, Table_field_desc)						
	SELECT	table_field_id, Table_field_desc
	FROM	dbo.Table_Fields WITH(NOLOCK)
	WHERE	TableId = @tableId
			AND Table_Field_desc LIKE 'CTS cleaning type - %'




	DECLARE @location_transition_cleaning_level TABLE(
	Location_event_id	INTEGER,
	Value	VARCHAR(50)
	)


	INSERT INTO @location_transition_cleaning_level (Location_event_id,Value)
	SELECT	ACS.location_event_id, 
			TFV.value 
	FROM	dbo.Table_Fields_Values TFV WITH(NOLOCK)
			JOIN @Appliance_current_status ACS 
				ON ACS.Location_pu_id = TFV.keyId
				AND TFV.tableId = @tableId
			JOIN @Appliances A 
				ON A.appliance_event_id = ACS.appliance_event_id
			JOIN @location_transition_cleaning_level_UDP TF
				ON TF.table_field_id = TFV.table_field_id
				AND RIGHT(TF.Table_Field_desc,LEN(A.Appliance_type)) = A.Appliance_type


	DECLARE @SerialEventId INTEGER

	IF @Serial IS NOT NULL 
	BEGIN
		SET @SerialEventId = (SELECT event_id FROM dbo.event_details WITH(NOLOCK) WHERE alternate_event_num = @Serial)
		IF @SerialEventId IS NULL
		BEGIN
			GOTO TheEnd
		END

	END  
	/*=====================================================================================================================
	GET Specific Appliances
	=====================================================================================================================*/
	IF @SerialEventId IS NOT NULL
	BEGIN
		INSERT INTO @Output
		(
		Serial,
		Appliance_Id,
		Appliance_desc,
		Appliance_Type,
		Appliance_location_Id,
		Appliance_location_Desc,
		Appliance_location_Type,
		Appliance_status_Id,
		Appliance_status_Desc,
		Appliance_status_type,
		Appliance_Product_Id,
		Appliance_Product_Desc,
		Appliance_transition_event_id,
		Appliance_hardware_status_id,
		Appliance_hardware_status_desc,
		Appliance_hardware_pu_id,
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
		Action_Cleaning_Is_Active,
		Action_Movement_Is_Active,
		Cleaning_level_allowed,
		PPW_movable,
		In_PPW,
		PPW_Requires_PO,
		PPW_Requires_Product,
		PPW_Match,
		Extended_Info,
		Status_Pending_Id,
		Status_Pending_Desc,
		Cleaned_limit_hour,
		Used_limit_hour,
		Cleaned_timer_hour,
		Used_timer_hour,
		Cleaned_timer_second,
		Used_timer_second
		)
		SELECT	A.Appliance_serial 'Serial',
				A.Appliance_event_id 'Appliance_Id',
				A.Appliance_event_num 'Appliance_desc',
				A.Appliance_type 'Appliance_type',
				ACS.Location_pu_id 'Appliance_location_Id',
				ACS.location_pu_desc 'Appliance_location_Desc',
				FAL.Type 'Appliance_location_Type',
				ACS.Location_event_status_id 'Appliance_status_Id',
				ACS.Location_event_status_desc 'Appliance_status_desc', 	
				(CASE
					WHEN ACS.Location_event_status_desc = 'Clean' AND  A.Appliance_status_desc= 'Active'  
						THEN COALESCE(ALC.Type, 'Major')
					ELSE 
						''
				END
				) 'Appliance_status_type',
				COALESCE(ACS.Location_event_applied_product,AP.Prod_Id) 'Appliance_Product_Id',
				COALESCE(ACS.Location_event_applied_product_desc,AP.Prod_desc) 'Appliance_Product_Desc',
				ACS.Location_event_id 'Appliance_transition_event_id',
				A.Appliance_status_id 'Appliance_hardware_status_id',
				A.Appliance_status_desc 'Appliance_hardware_status_desc',
				A.Appliance_pu_id 'Appliance_hardware_pu_id',
				(CASE ALC.Cleaning_status
				WHEN 'Clean' THEN '' 
				WHEN 'Dirty' THEN '' 
				ELSE ALC.Cleaning_status
				END) 'Cleaning_status',
				(CASE ALC.Cleaning_status
				WHEN 'Clean' THEN '' 
				WHEN 'Dirty' THEN '' 
				ELSE ALC.type
				END) 'Cleaning_Type',
				(CASE ALC.Cleaning_status
				WHEN 'Clean' THEN ALC.Location_pu_id
				WHEN 'Dirty' THEN '' 
				ELSE ALC.Location_pu_id
				END) 'Cleaning_PU_Id',
				(CASE ALC.Cleaning_status
				WHEN 'Clean' THEN ALC.Location_pu_desc
				WHEN 'Dirty' THEN '' 
				ELSE ALC.Location_pu_desc
				END) 'Cleaning_PU_Desc',
				AP.PP_ID 'Appliance_PP_Id',
				AP.Process_order 'Appliance_process_order',
				AP.Prod_id 'Appliance_process_order_product_Id',
				AP.Prod_code 'Appliance_process_order_product_code',
				AP.Process_order_status_id 'Appliance_process_order_status_Id',
				AP.Process_order_status_desc 'Appliance_process_order_status_desc',
				1 'Action_Cleaning_Is_Active',
				(CASE 
					WHEN ALC.Cleaning_status IN('CTS_Cleaning_Started','Cleaning started','CTS_Cleaning_Completed','Cleaning Completed') 
					THEN 0 
					ELSE 1 END) 'Action_Movement_Is_Active',
				(CASE 
				WHEN 	CL.value IS NULL
						AND EC.event_subtype_id IS NOT NULL
				THEN	'Major'
				WHEN 	CL.value IS NOT NULL
						AND EC.event_subtype_id IS NOT NULL
				THEN	CL.value
				ELSE	'None'
				END
				)	'Cleaning_level_allowed',
				(CASE
				WHEN	ALC.type = 'Major'
				THEN	1
				ELSE	0
				END
				) 'PPW_movable',
				(CASE WHEN FAL.Type = 'PPW' THEN 1
				ELSE 0
				END) 'In_PPW',
				(CASE	WHEN A.Appliance_holds_material = 0 THEN 0
						ELSE 2
				END) 'PPW_Requires_PO',
				1 'PPW_Requires_Product',
				(CASE WHEN ACS.Location_event_applied_product IS NOT NULL AND FAL.type = 'PPW' THEN 1 
				ELSE 0
				END ) 'PPW_Match',
				NULL 'Extended_Info',
				NULL 'Status_Pending_Id',
				NULL 'Status_Pending_Desc',
				A.Appliance_clean_timer_limit 'Cleaned_limit_hour',
				A.Appliance_usage_timer_limit 'Used_limit_hour',
				DATEDIFF(hour,COALESCE(ALCC.End_time,A.timestamp),@now) 'Cleaned_timer_hour',
				COALESCE(DATEDIFF(hour,ALU.Last_use,@now),DATEDIFF(hour,A.Timestamp,@now)) 'Used_timer_hour',
				DATEDIFF(second,COALESCE(ALCC.End_time,A.timestamp),@now) 'Cleaned_timer_hour',
				COALESCE(DATEDIFF(second,ALU.Last_use,@now),DATEDIFF(second,A.Timestamp,@now)) 'Used_timer_hour'
		FROM	@Appliances A
				JOIN @Appliance_current_status ACS
					ON ACS.Appliance_event_id = A.Appliance_event_id
				JOIN @Appliance_Last_Use ALU
					ON ALU.ApplianceId = A.Appliance_event_id
				JOIN @FAppliance_locations FAL
					ON FAL.pu_id = ACS.Location_pu_id
				LEFT JOIN @Appliance_last_cleaning ALC
					ON ALC.Appliance_event_id = A.Appliance_event_id
				LEFT JOIN @Appliance_last_completed_cleaning ALCC
					ON ALCC.Appliance_event_id = A.Appliance_event_id
				LEFT JOIN @Appliance_Production AP
					ON AP.Appliance_event_id = A.Appliance_event_id
				LEFT JOIN dbo.products P
					ON P.prod_id = ACS.Location_event_applied_product
				LEFT JOIN @location_transition_cleaning_level CL
					ON CL.location_event_id = ACS.location_event_id
				LEFT JOIN dbo.event_configuration EC WITH(NOLOCK)
					ON EC.pu_id = ACS.location_pu_id 
					AND EC.et_id = 14 AND EC.event_SubType_Id = (
																SELECT	Event_Subtype_Id 
																FROM	dbo.event_subtypes  WITH(NOLOCK)
																WHERE	event_SubType_Id = EC.Event_Subtype_Id
																		AND event_subtype_desc = 'CTS Appliance Cleaning'
																) 
		WHERE	A.Appliance_serial = @Serial
		
		

	
	END
	ELSE
	/*=====================================================================================================================
	GET ALL APPLIANCES
	=====================================================================================================================*/
	BEGIN
		INSERT INTO @Output
		(
		Serial,
		Appliance_Id,
		Appliance_desc,
		Appliance_Type,
		Appliance_location_Id,
		Appliance_location_Desc,
		Appliance_location_Type,
		Appliance_status_Id,
		Appliance_status_Desc,
		Appliance_status_type,
		Appliance_Product_Id,
		Appliance_Product_Desc,
		Appliance_transition_event_id,
		Appliance_hardware_status_id,
		Appliance_hardware_status_desc,
		Appliance_hardware_pu_id,
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
		Action_Cleaning_Is_Active,
		Action_Movement_Is_Active,
		Cleaning_level_allowed,
		PPW_movable,
		In_PPW,
		PPW_Requires_PO,
		PPW_Requires_Product,
		PPW_Match,
		Extended_Info,
		Status_Pending_Id,
		Status_Pending_Desc,
		Cleaned_limit_hour,
		Used_limit_hour,
		Cleaned_timer_hour,
		Used_timer_hour,
		Cleaned_timer_second,
		Used_timer_second
		)
		SELECT	A.Appliance_serial 'Serial',
				A.Appliance_event_id 'Appliance_Id',
				A.Appliance_event_num 'Appliance_desc',
				A.Appliance_type 'Appliance_type',
				ACS.Location_pu_id 'Appliance_location_Id',
				ACS.location_pu_desc 'Appliance_location_Desc',
				FAL.Type 'Appliance_location_Type',
				ACS.Location_event_status_id 'Appliance_status_Id',
				ACS.Location_event_status_desc 'Appliance_status_desc', 	
				(CASE
					WHEN ACS.Location_event_status_desc = 'Clean' AND  A.Appliance_status_desc= 'Active'  
						THEN COALESCE(ALC.Type, 'Major')
					ELSE 
						''
				END
				) 'Appliance_status_type',
				COALESCE(ACS.Location_event_applied_product,AP.Prod_Id) 'Appliance_Product_Id',
				COALESCE(ACS.Location_event_applied_product_desc,AP.Prod_desc) 'Appliance_Product_Desc',
				ACS.Location_event_id 'Appliance_transition_event_id',
				A.Appliance_status_id 'Appliance_hardware_status_id',
				A.Appliance_status_desc 'Appliance_hardware_status_desc',
				A.Appliance_pu_id 'Appliance_hardware_pu_id',
				(CASE ALC.Cleaning_status
				WHEN 'Clean' THEN '' 
				WHEN 'Dirty' THEN '' 
				ELSE ALC.Cleaning_status
				END) 'Cleaning_status',
				(CASE ALC.Cleaning_status
				WHEN 'Clean' THEN '' 
				WHEN 'Dirty' THEN '' 
				ELSE ALC.type
				END) 'Cleaning_Type',
				(CASE ALC.Cleaning_status
				WHEN 'Clean' THEN ALC.Location_pu_id
				WHEN 'Dirty' THEN '' 
				ELSE ALC.Location_pu_id
				END) 'Cleaning_PU_Id',
				(CASE ALC.Cleaning_status
				WHEN 'Clean' THEN ALC.Location_pu_desc
				WHEN 'Dirty' THEN '' 
				ELSE ALC.Location_pu_desc
				END) 'Cleaning_PU_Desc',
				AP.PP_ID 'Appliance_PP_Id',
				AP.Process_order 'Appliance_process_order',
				AP.Prod_id 'Appliance_process_order_product_Id',
				AP.Prod_code 'Appliance_process_order_product_code',
				AP.Process_order_status_id 'Appliance_process_order_status_Id',
				AP.Process_order_status_desc 'Appliance_process_order_status_desc',
				1 'Action_Cleaning_Is_Active',
				(CASE 
					WHEN ALC.Cleaning_status IN('CTS_Cleaning_Started','Cleaning started','CTS_Cleaning_Completed','Cleaning Completed') 
					THEN 0 
					ELSE 1 END) 'Action_Movement_Is_Active',
				(CASE 
				WHEN 	CL.value IS NULL
						AND EC.event_subtype_id IS NOT NULL
				THEN	'Major'
				WHEN 	CL.value IS NOT NULL
						AND EC.event_subtype_id IS NOT NULL
				THEN	CL.value
				ELSE	'None'
				END
				)	'Cleaning_level_allowed',
				(CASE
				WHEN	ALC.type = 'Major'
				THEN	1
				ELSE	0
				END
				) 'PPW_movable',
				(CASE WHEN FAL.Type = 'PPW' THEN 1
				ELSE 0
				END) 'In_PPW',
				(CASE	WHEN A.Appliance_holds_material = 0 THEN 0
						ELSE 2
				END) 'PPW_Requires_PO',
				1 'PPW_Requires_Product',
				(CASE WHEN ACS.Location_event_applied_product IS NOT NULL AND FAL.type = 'PPW' THEN 1 
				ELSE 0
				END ) 'PPW_Match',
				NULL 'Extended_Info',
				NULL 'Status_Pending_Id',
				NULL 'Status_Pending_Desc',
				A.Appliance_clean_timer_limit 'Cleaned_limit_hour',
				A.Appliance_usage_timer_limit 'Used_limit_hour',
				DATEDIFF(hour,COALESCE(ALCC.End_time,A.timestamp),@now) 'Cleaned_timer_hour',
				COALESCE(DATEDIFF(hour,ALU.Last_use,@now),DATEDIFF(hour,A.Timestamp,@now)) 'Used_timer_hour',
				DATEDIFF(second,COALESCE(ALCC.End_time,A.timestamp),@now) 'Cleaned_timer_hour',
				COALESCE(DATEDIFF(second,ALU.Last_use,@now),DATEDIFF(second,A.Timestamp,@now)) 'Used_timer_hour'
		FROM	@Appliances A
				JOIN @Appliance_current_status ACS
					ON ACS.Appliance_event_id = A.Appliance_event_id
				JOIN @Appliance_Last_Use ALU
					ON ALU.ApplianceId = A.Appliance_event_id
				JOIN @FAppliance_locations FAL
					ON FAL.pu_id = ACS.Location_pu_id
				LEFT JOIN @Appliance_last_cleaning ALC
					ON ALC.Appliance_event_id = A.Appliance_event_id
				LEFT JOIN @Appliance_last_completed_cleaning ALCC
					ON ALCC.Appliance_event_id = A.Appliance_event_id
				LEFT JOIN @Appliance_Production AP
					ON AP.Appliance_event_id = A.Appliance_event_id
				LEFT JOIN dbo.products P
					ON P.prod_id = ACS.Location_event_applied_product
				LEFT JOIN @location_transition_cleaning_level CL
					ON CL.location_event_id = ACS.location_event_id
				LEFT JOIN dbo.event_configuration EC WITH(NOLOCK)
					ON EC.pu_id = ACS.location_pu_id 
					AND EC.et_id = 14 AND EC.event_SubType_Id = (
																SELECT	Event_Subtype_Id 
																FROM	dbo.event_subtypes  WITH(NOLOCK)
																WHERE	event_SubType_Id = EC.Event_Subtype_Id
																		AND event_subtype_desc = 'CTS Appliance Cleaning'
																) 

	END




	/* V1.9 Check for cleaning matrix here Matrix here */
	DECLARE @DestinationProdId			int
	DECLARE @MatrixProducts		TABLE( 
	FromProdId			int,
	ToProdId			int,
	CleaningType		varchar(50)	)


	IF @Destination_location IS NOT NULL
	BEGIN
		SET @DestinationProdId = (	SELECT pp.prod_id 
									FROM dbo.production_plan_starts pps WITH(NOLOCK)
									JOIN dbo.production_plan pp			WITH(NOLOCK)	ON pps.pp_id = pp.pp_id
									WHERE pps.pu_id = @Destination_location 
										AND end_time IS NULL)
		/* Get prod id from PrO that is not started yet */
		IF @DestinationProdId IS NULL
		BEGIN
			SET @DestinationProdId = (	SELECT TOP 1 Product_id
										FROM @F_Products p
										JOIN dbo.production_plan pp			WITH(NOLOCK)	ON p.Product_id = pp.prod_id
										JOIN dbo.prdExec_paths pep			WITH(NOLOCK)	ON pp.path_id = pep.path_id
										JOIN dbo.prdExec_path_units pepu	WITH(NOLOCK)	ON pep.path_id = pepu.path_id AND pepu.pu_id = @Destination_location
										WHERE pp.pp_status_id IN (1,2,3)
										)

		END

		IF @DestinationProdId IS NOT NULL
		BEGIN
			INSERT @MatrixProducts (FromProdId, ToProdId, CleaningType)
			SELECT	From_Product_Id, 
					To_Product_Id,
					CASE 
						WHEN CCM_Id = 1 Then 'Major'
						WHEN CCM_Id = 2 Then 'Minor'
						ELSE 'None'
					END
			FROM dbo.Local_CTS_Product_Transition_Cleaning_Methods
			WHERE To_Product_Id = @DestinationProdId
				AND end_time IS NULL
				AND (location_id = @Destination_location OR location_id IS NULL)
		END

	--V1.10
	IF (SELECT COUNT(1) FROM @F_Products) > 0 
		DELETE @Output 
		WHERE  COALESCE(Appliance_product_Id,0) NOT IN(SELECT Product_id FROM @F_Products)  
			AND Appliance_Status_Desc = 'In use'

	IF (SELECT COUNT(1) FROM @F_Products) > 0 
		DELETE @Output 
		WHERE  COALESCE(Appliance_product_Id,0) NOT IN(SELECT Product_id FROM @F_Products)  
			/* V1.9 do not remove the accepted minor cleaning n the Matrix */
			AND (Appliance_Status_Desc = 'Clean' AND Appliance_Status_Type = 'Minor' AND  Appliance_product_Id NOT IN (SELECT FromProdId FROM @MatrixProducts WHERE CleaningType = 'Minor')   )  

	/* V1.9  remove where matrix requires Major cleaning */
	IF (SELECT COUNT(1) FROM @F_Products) > 0 
		DELETE @Output 
		WHERE Appliance_Status_Desc = 'Clean' AND Appliance_Status_Type = 'Minor' AND  Appliance_product_Id IN (SELECT FromProdId FROM @MatrixProducts WHERE CleaningType = 'Major')

	END
	ELSE
	BEGIN
		IF (SELECT COUNT(1) FROM @F_Products) > 0 
		DELETE @Output 
		WHERE  COALESCE(Appliance_product_Id,0) NOT IN(SELECT Product_id FROM @F_Products) 
	END



/* end of 1.9 modification*/


	IF (SELECT COUNT(1) FROM @FAppliance_locations) > 0 
		DELETE @Output WHERE  Appliance_location_Id NOT IN(SELECT pu_id FROM @FAppliance_locations) 
	IF (SELECT COUNT(1) FROM @FAppliance_types) > 0 
		DELETE @Output WHERE  Appliance_type NOT IN(SELECT Type FROM @FAppliance_types) 

	/* Check if it is allowed to clean the appliance in current location */
	UPDATE	@Output SET Allow_Cleaning_In_Place =
	CASE WHEN TFV2.value != 'None'
	THEN 1
	ELSE 0
	END,
	Usage_Display_Message = 
	CASE WHEN TFV2.value != 'None'
	THEN ''
	ELSE 
	'UDP configuration does not allow Appliance type ' + O.Appliance_Type + ' to be cleaned at location ' + O.Appliance_location_Desc + @NewLineChar
	END
	FROM	@output O
			JOIN dbo.events EAPP WITH(NOLOCK)
				ON EAPP.Event_Id = O.Appliance_Id
			JOIN dbo.Table_Fields_Values TFV2 WITH(NOLOCK)
				ON TFV2.KeyId = O.Appliance_location_Id
				AND TFV2.TableId = @tableId
			JOIN dbo.Table_Fields TF2 WITH(NOLOCK)
				ON TF2.Table_Field_Id = TFV2.Table_Field_Id
				AND TF2.Table_Field_Desc = 'CTS cleaning type - ' + O.Appliance_Type

/* V1.11 allow multiple simultaneous cleaning for appliance in a location*/

		UPDATE	o 
		SET		Allow_Cleaning_In_Place = sub.nbr,
				Usage_Display_Message = Usage_Display_Message + 'Appliance cleaning not allowed at location' + @NewLineChar
		FROM @Output o
		JOIN (	SELECT COUNT(ec.ec_id) as nbr, op.Appliance_Id
				FROM @Output op
				JOIN dbo.event_configuration ec		WITH(NOLOCK) 	ON ec.pu_id = op.Appliance_location_Id
				JOIN dbo.event_subtypes EST			WITH(NOLOCK) 	ON EST.event_subtype_id = ec.event_subtype_id
																		AND EST.event_subtype_desc = 'CTS Appliance cleaning'
				GROUP  BY op.appliance_Id) sub ON o.appliance_id = sub.appliance_Id

				/*
				SELECT COUNT(ec.ec_id) as nbr, op.Appliance_Id--, op.Appliance_location_Id
				FROM @Output op
				JOIN dbo.event_configuration ec		WITH(NOLOCK) 	ON ec.pu_id = op.Appliance_location_Id
				JOIN dbo.event_subtypes EST			WITH(NOLOCK) 	ON EST.event_subtype_id = ec.event_subtype_id
																			AND EST.event_subtype_desc = 'CTS Appliance cleaning'
				GROUP  BY op.appliance_Id

				select Appliance_location_Id from @Output
				*/
/*
	UPDATE	@Output SET	Allow_Cleaning_In_Place = 0,
						Usage_Display_Message = Usage_Display_Message + 'Appliance cleaning not allowed at location, appliance ' + ED.alternate_event_num + ' is currently being cleaned' + @NewLineChar
	FROM	dbo.user_defined_events UDE WITH(NOLOCK)
			JOIN dbo.events E WITH(NOLOCK)
				ON E.event_id = UDE.event_id
			JOIN dbo.event_Details ED WITH(NOLOCK)
				ON ED.event_id = E.event_id
			JOIN dbo.production_status PS  WITH(NOLOCK)
				ON PS.prodstatus_id = UDE.event_status
			JOIN dbo.event_subtypes EST WITH(NOLOCK)
				ON EST.event_subtype_id = UDE.event_subtype_id
				AND EST.event_subtype_desc = 'CTS Appliance cleaning'
	WHERE	PS.prodStatus_desc IN ('CTS_Cleaning_Started','CTS_Cleaning_Completed')
			AND 
			UDE.pu_id = Appliance_location_Id	
			AND UDE.event_id != Appliance_Id

*/


	UPDATE	O SET Allow_Cleaning_In_Place = 0
	FROM	@Output O
			JOIN dbo.prdExec_path_units PPU
				ON PPU.pu_id = O.Appliance_location_id
			JOIN dbo.production_plan PP WITH(NOLOCK)
				ON PP.path_id = PPU.Path_Id
	WHERE	PP.PP_Status_Id = (SELECT PP_Status_Id FROM dbo.Production_Plan_Statuses PPSt WITH(NOLOCK) WHERE PP_Status_Desc = 'Active')
	
	
	UPDATE	O SET	Allow_Cleaning_In_Place = 0,
					Usage_Display_Message = Usage_Display_Message +  'Cleaning not allowed for ' + Appliance_hardware_status_desc + ' appliance' + @NewLineChar
	FROM	@Output O
	WHERE	Appliance_hardware_status_desc NOT IN('Active','QC Hold')

	UPDATE	@Output SET	Allow_Hardware_Status_Update = 1
	
	UPDATE	O SET	Allow_Hardware_Status_Update = 0,
					Hardware_Display_Message = 'Hardware status update not allowed when apliance is in making location' + @NewLineChar
	FROM	@Output O
	WHERE	Appliance_hardware_status_desc = 'Active' 
			AND Appliance_location_type = 'Making'


	UPDATE @Output SET Allow_Cleaning_In_Place = 1 WHERE Allow_Cleaning_In_Place IS NULL

	UPDATE @Output SET Status_Pending_Desc = prodStatus_desc FROM dbo.production_status WITH(NOLOCK) WHERE prodStatus_id = Status_Pending_Id
	DECLARE @loopcount INTEGER
	DECLARE @ApplianceTransitionExtendedInfo VARCHAR(500)
	
	DECLARE @SplitExtendedInfo TABLE(
	DaString VARCHAR(25),
	DaValue VARCHAR(25))
	

	SET @loopcount = (SELECT MIN(Id) FROM @Output)
	WHILE EXISTS(SELECT Id FROM @Output WHERE Id = @loopcount)
	BEGIN
	
		SET @ApplianceTransitionExtendedInfo = 
		(SELECT Extended_info FROM dbo.events WHERE event_id = (SELECT Appliance_transition_event_id FROM @output WHERE id = @loopcount))
		
		INSERT INTO @SplitExtendedInfo (DaString)
		SELECT value FROM STRING_SPLIT(@ApplianceTransitionExtendedInfo,',')
 
		UPDATE @SplitExtendedInfo SET DaValue = SUBSTRING(DaString,CHARINDEX('=',DaString,0)+1,Len(DaString)-CHARINDEX('=',DaString,0)+1)

		UPDATE @Output SET Status_Pending_Id = (SELECT CAST(DaValue AS INTEGER) FROM @SplitExtendedInfo WHERE DaString LIKE '%SID=%')
		WHERE ID = @loopcount


		SET @loopcount = (SELECT COALESCE(MIN(Id),0) FROM @Output Where Id > @loopcount)


		DELETE @SplitExtendedInfo
	END


	UPDATE @Output SET Status_Pending_desc = (SELECT prodStatus_desc FROM Production_Status WHERE ProdStatus_Id = Status_Pending_Id)

	IF @Destination_location IS NOT NULL
	BEGIN
		/* DELETE appliance for which statuses are not matching */
		DELETE @Output WHERE Appliance_status_Id NOT IN (SELECT Valid_Status_id FROM @RMI WHERE Appliance_location_Id = Source_Pu_id )
		DELETE @Output WHERE Appliance_hardware_status_id NOT IN (SELECT Valid_Status_id FROM @RMI WHERE Appliance_hardware_pu_id = Source_Pu_id )

	
		
	END


	UPDATE @Output SET	Appliance_Status_Desc =		(CASE 
													WHEN	Cleaned_timer_second > Cleaned_limit_hour*3600 
													THEN	'Dirty'

													WHEN	Cleaned_timer_second <= Cleaned_limit_hour*3600 
															AND Cleaned_timer_second <= Used_timer_second
															AND Cleaned_timer_second > Used_limit_hour*3600
													THEN	'Dirty'

													WHEN	Cleaned_timer_second <= Cleaned_limit_hour*3600 
															AND Cleaned_timer_second > Used_timer_second
															AND used_timer_second > Used_limit_hour*3600
													THEN	'Dirty'

													ELSE	Appliance_Status_Desc

													END),
						Appliance_Status_Id =		(CASE 
													WHEN	Cleaned_timer_second > Cleaned_limit_hour*3600 
													THEN	(SELECT prodStatus_id FROM dbo.Production_Status WHERE prodStatus_desc = 'Dirty')
					
													WHEN	Cleaned_timer_second <= Cleaned_limit_hour*3600 
															AND Cleaned_timer_second <= Used_timer_second
															AND Cleaned_timer_second > Used_limit_hour*3600
													THEN	(SELECT prodStatus_id FROM dbo.Production_Status WHERE prodStatus_desc = 'Dirty')
													
													WHEN	Cleaned_timer_second <= Cleaned_limit_hour*3600 
															AND Cleaned_timer_second > Used_timer_second
															AND used_timer_second > Used_limit_hour*3600
													THEN	(SELECT prodStatus_id FROM dbo.Production_Status WHERE prodStatus_desc = 'Dirty')

													ELSE	Appliance_Status_Id

													END),
						Appliance_Status_Type =		(CASE 
													WHEN	Cleaned_timer_second > Cleaned_limit_hour*3600 
													THEN	NULL
					
													WHEN	Cleaned_timer_second <= Cleaned_limit_hour*3600 
															AND Cleaned_timer_second <= Used_timer_second
															AND Cleaned_timer_second > Used_limit_hour*3600
													THEN	NULL

													WHEN	Cleaned_timer_second <= Cleaned_limit_hour*3600 
															AND Cleaned_timer_second > Used_timer_second
															AND used_timer_second > Used_limit_hour*3600
													THEN	NULL

													ELSE	Appliance_Status_type

													END),
						Usage_Display_Message =		(CASE 
													WHEN	Cleaned_timer_second > Cleaned_limit_hour*3600 
													THEN	COALESCE(Usage_Display_Message,'') + 'Appliance is dirty, cleaning timer limit exceeded' + @NewLineChar
					
													WHEN	Cleaned_timer_second <= Cleaned_limit_hour*3600 
															AND Cleaned_timer_second <= Used_timer_second
															AND Cleaned_timer_second > Used_limit_hour*3600
													THEN	COALESCE(Usage_Display_Message,'') + 'Appliance is dirty, Usage timer limit exceeded' + @NewLineChar
													
													WHEN	Cleaned_timer_second <= Cleaned_limit_hour*3600 
															AND Cleaned_timer_second > Used_timer_second
															AND used_timer_second > Used_limit_hour*3600
													THEN	COALESCE(Usage_Display_Message,'') + 'Appliance is dirty, Usage timer limit exceeded' + @NewLineChar
													ELSE	NULL
													END)


	/*=====================================================================================================================
	Apply filter on appliance statuses
	=====================================================================================================================*/
		IF (SELECT COUNT(1) FROM @FAppliance_statuses) > 0 
			DELETE @Output WHERE  Appliance_Status_Id NOT IN(SELECT status_id FROM @FAppliance_statuses) 


	
	IF @Destination_location IS NOT NULL
	BEGIN
		DELETE @output
		WHERE Appliance_status_Id NOT IN (SELECT Valid_Status_id FROM @RMI WHERE Source_Pu_id = Appliance_location_Id) 

		DELETE	@output 
		WHERE	Appliance_status_desc = 'In use'  AND Appliance_Product_Id = (SELECT prod_id FROM @Destination_status)
	END
	TheEnd:


	/*=====================================================================================================================
	Check for Multiple cleanings on a location
	=====================================================================================================================*/
	UPDATE al
	SET CntActiveAppCleaning = SUB.CNT
	FROM @FAppliance_locations al
	JOIN (	SELECT COUNT(1) as CNT,Appliance_location_Id as PUID
			FROM @Output 
			WHERE Cleaning_status IN ('Cleaning started','Cleaning complete')
			GROUP BY Appliance_location_Id) SUB ON al.PU_ID = SUB.PUID 

	UPDATE o
	SET Allow_Cleaning_In_Place = 0
	FROM @output o
	JOIN @FAppliance_locations al ON o.Appliance_location_Id = al.PU_Id
	WHERE o.Cleaning_status NOT IN ('Cleaning started','Cleaning complete')
		 AND al.CntActiveAppCleaning >= MaxSimulApp





	
		IF COALESCE(@ShowDecommissioned,0) = 0
		BEGIN
			DELETE @output WHERE Appliance_hardware_status_desc = 'Decommissioned'
		END
		SELECT  /* Appliance_hardware_status_desc,*/
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
		FROM	@Output
	

END
