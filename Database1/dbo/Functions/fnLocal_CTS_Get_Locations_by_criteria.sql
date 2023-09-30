

/*=====================================================================================================================
Local Function: fnLocal_CTS_Get_Locations_by_criteria
=====================================================================================================================
 Author				: Ugo Lapierre (AutomaTech Canada)
 Date created			: 2021-10-05
 Version 				: 1.8
 Description			: Get location
 Editor tab spacing	: 4 
 
 =====================================================================================================================
 EDIT HISTORY:

 ========		====	  		====					=====
 1.0			2021-10-05		U.Lapierre				Initial Release 
 1.1			2022-01-10		Francois Bergeron		Add require PO selection field to output (Requires_PO_selection)
 1.2			2022-01-10		Francois Bergeron		Add is making field to output
 1.3			2022-01-18		Francois Bergeron		Include default movement location in output (UDP)
 1.4			2022-01-25		Francois Bergeron		Add cleanable field in teh output to determine if the location can be cleaned or not
 1.5			2022-01-31		Francois Bergeron		Add cleanable field in teh output to determine if the applaince can be cleaned or not
 1.6			2022-02-03		Francois Bergeron		Add count of appliances in location
 1.7			2022-02-04		Francois Bergeron		Add timers
 1.8			2022-02-07		Francois Bergeron		Add parameter to fnLocal_CTS_Location_Status
 1.9			2022-02-11		Francois Bergeron		Add clean status output for SSE
 2.0			2022-04-06		Francois Bergeron		Status update staging
 2.1			2023-02-21		U.Lapierre				FIx issue to have Minor clean PrO visible
 2.2			2023-06-26		U. Lapierre				Adapt for Code review


 =====================================================================================================================
Testing Code
-
SELECT * FROM fnLocal_CTS_Get_Locations_by_criteria (NULL,NULL, NULL, NULL, NULL, NULL)




==================================================================================================*/

CREATE   FUNCTION [dbo].[fnLocal_CTS_Get_Locations_by_criteria]
(
	@Serial								VARCHAR(25),
	@F_Product							VARCHAR(255),
	@F_Location_Type					VARCHAR(255),
	@F_Location_Status					VARCHAR(255),	
	@F_Order_Range_hours				INT,
	@C_User								VARCHAR(100)
)
RETURNS 
@Output	TABLE (
Serial									VARCHAR(50),
Location_id								INT,
Location_desc							VARCHAR(50),
Location_type							VARCHAR(50), 
Location_status							VARCHAR(50), 
Cleaning_status							VARCHAR(50),
Cleaning_type							VARCHAR(25),
Compatible_process_order_count			INT DEFAULT 0,
Active_or_inprep_process_order_Id		INT,  
Active_or_inprep_process_order_desc		VARCHAR(50),  
Active_or_inprep_process_order_product	VARCHAR(50),  
Active_or_inprep_process_order_status	VARCHAR(50), 
Number_of_soft_reservations				INT DEFAULT 0, 
Number_of_hard_reservations				INT DEFAULT 0, 
Access									VARCHAR(25),
Requires_PO_selection					INT DEFAULT 0,
Default_destination_location_id			INT,
Default_destination_location_desc		VARCHAR(50),
Location_Cleanable						INT,
Appliance_Cleanable						INT,
Number_of_appliances					INT,
Pending_Appliance_Count					INT,
Cleaned_timer_hour						FLOAT,
Cleaned_limit_hour						FLOAT,
Used_timer_hour							FLOAT,
Used_limit_hour							FLOAT,
Appliance_cleaning_active				BIT,
Timer_Exception							VARCHAR(25) /* None, Cleaning, Usage */
)
AS
BEGIN

	DECLARE @TableIdProdUnit				INT,
			@tfIdLocationSerial				INT,
			@tfIdLocationType				INT,
			@tfIdDefDestinationLocationId	INT,
			@TransactionTime				DATETIME = GETDATE(),
			@Puid							INT,
			@PathId							INT,
			@PrId							INT,
			@PrO							VARCHAR(100),
			@GCAS							VARCHAR(100),
			@ProductDesc					VARCHAR(100),
			@locationCleaningType			VARCHAR(25),
			@PPStatusDesc					VARCHAR(100),
			@CompatiblePrO					INT,
			@MaxDate						DATETIME,
			@ESReservation					INT,
			@varIdType						INT,
			@CountSoft						INT,
			@CountHard						INT,
			@LocationStatus					VARCHAR(100)

	DECLARE @LocationTypeStr TABLE
	(
	LocationType VARCHAR(50)
	);

	DECLARE @Processorders		TABLE	(
	PPId							INT,
	ProcessOrder					VARCHAR(50),
	PPStatusDesc					VARCHAR(50),
	ProdCode						VARCHAR(50),
	ProdDesc						VARCHAR(50),
	ForecastStartDate				DATETIME,
	BOMFId							INT,
	ForecastEndDate					datetime
	);

	DECLARE @ProductsFilter		TABLE	(
	ProdId							INT,
	ProdDesc						VARCHAR(100)
	);

	DECLARE @Location_Status TABLE
	(
	Location_status					VARCHAR(25),
	Cleaning_status					VARCHAR(25),
	Cleaning_type					VARCHAR(25),
	Last_product_id					INTEGER,
	Last_Process_order_Id			INTEGER,
	Last_Process_order_status_Id	INTEGER,
	Cleaned_timer_hour				FLOAT,
	Cleaned_limit_hour				FLOAT,
	Used_timer_hour					FLOAT,
	Used_limit_hour					FLOAT,
	Timer_Exception					VARCHAR(25)
	);

	DECLARE @Reservations	TABLE	(
	UDEId							INT,
	Timestamp						DATETIME,
	Type							VARCHAR(100)
	);

	DECLARE @LocationCleanStr	TABLE	(
	CleanStatus						VARCHAR(50)
	);

	DECLARE @Location_Appliance_Cleaning_Active TABLE
	(
	Location_Pu_id					INTEGER,
	Apppliance_cleaning_active		BIT
	);

	DECLARE @AppliancesInLocation TABLE(
	Appliance_id					INTEGER,
	Transition_PU_Id				INTEGER,
	Transition_event_id				INTEGER,
	Transition_timestamp			DATETIME,
	Transition_extended_info		VARCHAR(500),
	Rownum							INTEGER
	);

/*===============================================================
Get table field_id
===============================================================*/
	SET @TableIdProdUnit				=	(	SELECT tableId			FROM dbo.Tables			WITH(NOLOCK) WHERE TableName = 'Prod_Units'	);
	SET @tfIdLocationSerial				=	(	SELECT table_field_id	FROM dbo.Table_Fields	WITH(NOLOCK) WHERE TableId = @TableIdProdUnit AND Table_Field_Desc = 'CTS Location serial number');
	SET @tfIdLocationType				=	(	SELECT table_field_id	FROM dbo.Table_Fields	WITH(NOLOCK) WHERE TableId = @TableIdProdUnit AND Table_Field_Desc = 'CTS location Type');
	SET @tfIdDefDestinationLocationId	=	(	SELECT table_field_id	FROM dbo.Table_Fields	WITH(NOLOCK) WHERE TableId = @TableIdProdUnit AND Table_Field_Desc = 'CTS Default movement destination');


	INSERT INTO @Location_Appliance_Cleaning_Active(Location_Pu_id,Apppliance_cleaning_active)
	SELECT PUB.pu_id, 1
	FROM	dbo.user_defined_events UDE WITH(NOLOCK)
	JOIN dbo.prod_units_base PUB		WITH(NOLOCK)	ON PUB.pu_id = UDE.pu_id
	JOIN dbo.event_subtypes EST			WITH(NOLOCK)	ON EST.event_subtype_id = UDE.event_subtype_id
	JOIN dbo.production_status PS		WITH(NOLOCK)	ON PS.prodStatus_id = UDE.event_status
	WHERE	PS.ProdStatus_Desc IN('CTS_Cleaning_Started', 'CTS_Cleaning_completed')
			AND PUB.Equipment_Type = 'CTS Location'
			AND EST.event_subtype_desc = 'CTS Appliance Cleaning';

	/*Get reservation event_subtype*/
	SET @ESReservation = (	SELECT event_subtype_id FROM dbo.Event_Subtypes WITH(NOLOCK) WHERE Event_Subtype_Desc = 'CTS Reservation')

	/*Set Maxdate to query production_plan*/
	If @F_Order_Range_hours IS NULL
		SET @F_Order_Range_hours = 24;

	SELECT @MaxDate = DATEADD(HH,@F_Order_Range_hours,GETDATE());

/*===============================================================
Get all location matching the parameters
===============================================================*/
	IF @Serial IS NULL
			SET @Serial = '';

	IF @Serial <> ''
	BEGIN  /*The serial is provided, so get specific location*/
		INSERT	@Output (Location_id, Location_desc, Requires_PO_selection,Location_Cleanable,Appliance_Cleanable,Appliance_cleaning_active)
		SELECT	DISTINCT 
				pu.pu_id, 
				pu.pu_desc,
				(CASE ISNULL(pepu.pu_id,0)
				WHEN 0 THEN 0
				ELSE 1
				END),
				(CASE 
				WHEN ISNULL(LCL.event_SubType_Id,0) = 0 
					THEN 0
				WHEN ISNULL(PPS.PP_Id,0) != 0 
					THEN 0
				ELSE 1
				END
				),
				(CASE ISNULL(ACL.event_SubType_Id,0)
				WHEN 0 THEN 0
				ELSE 1
				END
				),
				LACA.Apppliance_cleaning_active
		FROM	dbo.Prod_Units_Base pu						WITH(NOLOCK)
		LEFT JOIN @Location_Appliance_Cleaning_Active LACA					ON LACA.Location_Pu_id = pu.pu_id
		JOIN dbo.Table_Fields_Values tfv					WITH(NOLOCK)	ON pu.PU_Id = tfv.KeyId AND tfv.Table_Field_Id = @tfIdLocationSerial
		JOIN dbo.prdExec_inputs PEI							WITH(NOLOCK)	ON PU.pu_id = PEI.pu_id
		JOIN dbo.PrdExec_Input_Sources PEIS					WITH(NOLOCK)	ON PEI.pei_id = PEIS.pei_id 
		LEFT JOIN dbo.prdexec_path_units PEPU				WITH(NOLOCK)	ON PEPU.pu_id = PEI.pu_id
		LEFT JOIN dbo.production_plan_starts PPS			WITH(NOLOCK)	ON PPS.pu_id = PU.PU_id 
																			AND @TransactionTime >= PPS.start_time 
																			AND (@TransactionTime<PPS.End_Time OR PPS.end_time IS NULL)
		OUTER APPLY	(	SELECT EC.Event_subType_id 
						FROM dbo.event_configuration EC WITH(NOLOCK)	
						JOIN dbo.event_subtypes EST		WITh(NOLOCK)	ON EST.event_SubType_Id = EC.Event_Subtype_Id
						WHERE	EC.pu_id = PU.PU_id 
							AND EC.ET_ID = 14
							AND EST.event_subtype_desc = 'CTS Location Cleaning'
					) LCL
				OUTER APPLY	(	SELECT EC.Event_subType_id 
								FROM dbo.event_configuration EC WITH(NOLOCK)	
								JOIN dbo.event_subtypes EST		WITh(NOLOCK)	ON EST.event_SubType_Id = EC.Event_Subtype_Id
								WHERE	EC.pu_id = PU.PU_id 
									AND EC.ET_ID = 14
									AND EST.event_subtype_desc = 'CTS Appliance Cleaning'
							) ACL
		WHERE	pu.Equipment_Type = 'CTS Location'
			AND PEI.input_name = 'CTS Location Transition'
			AND tfv.Value = @Serial;

		IF NOT EXISTS (SELECT 1 FROM @Output)
			GOTO LaFin;
	END;
	ELSE
	BEGIN  /*filters have to be used, get all matching location*/
		/*Get all CTS Locations using equipment type*/
		INSERT	@Output (Location_id, Location_desc,Requires_PO_selection,Location_Cleanable,Appliance_Cleanable,Appliance_cleaning_active)
		SELECT	DISTINCT	
				pu.pu_id, 
				pu.pu_desc,
				(CASE ISNULL(pepu.pu_id,0)
				WHEN 0 THEN 0
				ELSE 1
				END),
				(CASE 
				WHEN ISNULL(LCL.event_SubType_Id,0) = 0 
					THEN 0
				WHEN ISNULL(PPS.PP_Id,0) != 0 
					THEN 0
				ELSE 1
				END
				),
				(CASE ISNULL(ACL.event_SubType_Id,0)
				WHEN 0 THEN 0
				ELSE 1
				END
				),
				LACA.Apppliance_cleaning_active
		FROM	dbo.Prod_Units_Base pu						WITH(NOLOCK)
		LEFT JOIN @Location_Appliance_Cleaning_Active LACA					ON LACA.Location_Pu_id = pu.pu_id
		JOIN dbo.Table_Fields_Values tfv					WITH(NOLOCK)	ON pu.PU_Id = tfv.KeyId AND tfv.Table_Field_Id = @tfIdLocationSerial
		JOIN dbo.prdExec_inputs PEI							WITH(NOLOCK)	ON PU.pu_id = PEI.pu_id
		JOIN dbo.PrdExec_Input_Sources PEIS					WITH(NOLOCK)	ON PEI.pei_id = PEIS.pei_id 
		LEFT JOIN dbo.prdexec_path_units PEPU				WITH(NOLOCK)	ON PEPU.pu_id = PEI.pu_id
		LEFT JOIN dbo.production_plan_starts PPS			WITH(NOLOCK)	ON PPS.pu_id = PU.PU_id 
																			AND @TransactionTime >= PPS.start_time 
																			AND (@TransactionTime<PPS.End_Time OR PPS.end_time IS NULL)
		OUTER APPLY	(	SELECT EC.Event_subType_id 
						FROM dbo.event_configuration EC WITH(NOLOCK)	
						JOIN dbo.event_subtypes EST		WITh(NOLOCK)	ON EST.event_SubType_Id = EC.Event_Subtype_Id
						WHERE	EC.pu_id = PU.PU_id 
							AND EC.ET_ID = 14
							AND EST.event_subtype_desc = 'CTS Location Cleaning'
					) LCL
				OUTER APPLY	(	SELECT EC.Event_subType_id 
								FROM dbo.event_configuration EC WITH(NOLOCK)	
								JOIN dbo.event_subtypes EST		WITh(NOLOCK)	ON EST.event_SubType_Id = EC.Event_Subtype_Id
								WHERE	EC.pu_id = PU.PU_id 
									AND EC.ET_ID = 14
									AND EST.event_subtype_desc = 'CTS Appliance Cleaning'
							) ACL
		WHERE	pu.Equipment_Type = 'CTS Location'
				AND PEI.input_name = 'CTS Location Transition';
	END  ;
	/*Get All UDPs*/
	UPDATE o
	SET		Serial = tfv1.value, 
			Location_Type = tfv2.value,
			Default_destination_location_id = tfv3.value,
			Default_destination_location_desc = PUB.pu_desc
	FROM @Output o
	JOIN dbo.Table_Fields_Values tfv1		WITH(NOLOCK)	ON tfv1.KeyId = o.Location_id	AND	tfv1.Table_Field_Id = @tfIdLocationSerial
	LEFT JOIN dbo.Table_Fields_Values tfv2	WITH(NOLOCK)	ON tfv2.KeyId = o.Location_id	AND	tfv2.Table_Field_Id = @tfIdLocationType
	LEFT JOIN dbo.Table_Fields_Values tfv3	WITH(NOLOCK)	ON tfv3.KeyId = o.Location_id	AND	tfv3.Table_Field_Id = @tfIdDefDestinationLocationId
	LEFT JOIN dbo.prod_units_base PUB		WITH(NOLOCK)	ON CAST(PUB.PU_ID AS VARCHAR(25)) = CAST(tfv3.value AS VARCHAR(25));
	
	/*Filter list of location based on Location Type*/
	IF @F_Location_Type IS NOT NULL
	BEGIN
		INSERT @LocationTypeStr (LocationType)
		SELECT * FROM dbo.fnLocal_CmnParseList(@F_Location_Type,',');

		DELETE @Output 
		WHERE Location_type NOT IN (SELECT LocationType
									FROM @LocationTypeStr);
	END;


	/*Filter list of location based on Location status*/
	IF @F_Location_Status IS NOT NULL
	BEGIN
		INSERT @LocationCleanStr (CleanStatus)
		SELECT * FROM dbo.fnLocal_CmnParseList(@F_Location_Status,',');
	END;

	/*Filter list of location based on product filter*/
	INSERT @ProductsFilter	(ProdId)
	SELECT CAST(value AS INTEGER) FROM dbo.fnLocal_CmnParseList(@F_Product,',');

	UPDATE pf
	SET proddesc = p.prod_desc
	FROM @ProductsFilter pf
	JOIN Products_Base p WITH(NOLOCK) ON pf.Prodid = p.Prod_Id;

	DELETE @ProductsFilter WHERE Proddesc IS NULL;
	
	/*Loop across remaining Location to get other information*/
	SET @Puid = (SELECT MIN(location_id) FROM @Output)
	WHILE @Puid IS NOT NULL
	BEGIN
		INSERT INTO @Location_Status 
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
				Timer_Exception
				)
		SELECT 	Location_status, 
				Cleaning_status,
				Cleaning_type,
				Last_product_id, 
				Last_Process_order_Id, 
				Last_Process_order_status_Id,
				Cleaned_limit_hour,
				Used_limit_hour,
				Cleaned_timer_hour,
				Used_timer_hour,
				Timer_Exception 
		FROM	dbo.fnLocal_CTS_Location_Status(@Puid, NULL);

		/*PrO management */
		SELECT	@Prid			= NULL,
				@PrO			= NULL,
				@GCAS			= NULL,
				@PPStatusDesc	= NULL,
				@ProductDesc	= NULL;
		
		SET @PathId = (SELECT TOP 1 path_id FROM dbo.PrdExec_Path_Units WITH(NOLOCK) WHERE PU_Id = @Puid);

		IF @PathId IS NOT NULL
		BEGIN
		/* Get active info	*/
		SELECT	@Prid = PP.pp_id,
				@PrO = PP.process_order,
				@GCAS = P.prod_code,
				@PPStatusDesc = PS.PP_Status_Desc,
				@ProductDesc = p.prod_desc,
				@locationCleaningType = LS.Cleaning_type,
				@LocationStatus	= LS.Location_status
		FROM	@Location_Status LS
		JOIN  dbo.Production_Plan pp			WITH(NOLOCK)	ON PP.pp_id = LS.Last_Process_order_Id
		JOIN dbo.Products_Base p				WITH(NOLOCK)	ON pp.Prod_Id = p.Prod_Id
		JOIN dbo.Production_Plan_Statuses ps	WITH(NOLOCK)	ON pp.PP_Status_Id = ps.PP_Status_Id
		WHERE	pp.Path_Id = @PathId;

		/* Update pro info */
		IF @LocationStatus = 'Clean' AND COALESCE(@locationCleaningType,'') !='Major' 
			UPDATE @Output
			SET		Active_or_inprep_process_order_Id		= @PrId, 
					Active_or_inprep_process_order_desc		= @PrO,  
					Active_or_inprep_process_order_product	= @ProductDesc,
					Active_or_inprep_process_order_status	= @PPStatusDesc
					WHERE location_id = @Puid;


			IF @LocationStatus != 'Clean'  
				UPDATE @Output
				SET		Active_or_inprep_process_order_Id		= @PrId, 
						Active_or_inprep_process_order_desc		= @PrO,  
						Active_or_inprep_process_order_product	= @ProductDesc,
						Active_or_inprep_process_order_status	= @PPStatusDesc
						WHERE location_id = @Puid;

		END;  /*End of PrO management*/

		/*Reservation management*/
		DELETE @Reservations;
		SET @varIdType = NULL;
		SET @varIdType = (	SELECT var_id 
							FROM dbo.variables_base 
							WHERE pu_id = @Puid AND Test_Name = 'Type' 
								AND Event_Subtype_Id = @ESReservation );

		IF @varIdType IS NULL
		BEGIN
			SET @CountSoft=0;
			SET @CountHard=0;
		END;
		ELSE
		BEGIN
			INSERT @Reservations(	UDEId, Timestamp)
			SELECT ude_id, End_Time
			FROM dbo.User_Defined_Events WITH(NOLOCK)
			WHERE PU_Id = @Puid	
				AND Event_Subtype_Id = @ESReservation
				AND UDE_Desc = 'Reserved';

			UPDATE r
			SET type= t.result
			FROM @Reservations r
			JOIN dbo.Tests t		WITH(NOLOCK)	ON r.Timestamp = t.Result_On AND t.Var_Id = @varIdType;

			SET @CountSoft = (SELECT COUNT(1) FROM @Reservations WHERE Type = 'Soft');
			SET @CountHard = (SELECT COUNT(1) FROM @Reservations WHERE Type = 'Hard');
		END;

		UPDATE @Output
		SET Number_of_soft_reservations = @CountSoft,
			Number_of_hard_reservations = @CountHard
		WHERE  Location_id = @puid;

		/*Cleaning status management*/
		UPDATE	@Output 
		SET		Location_status = LS.Location_status,
				Cleaning_status = LS.Cleaning_status,
				Cleaning_type = LS.Cleaning_type,
				Cleaned_limit_hour = LS.Cleaned_limit_hour,
				Used_limit_hour = LS.Used_limit_hour,
				Cleaned_timer_hour = LS.Cleaned_timer_hour,
				Used_timer_hour = LS.Used_timer_hour,
				Timer_Exception = LS.Timer_Exception
		FROM	@Location_status LS
		WHERE	Location_id = @puid;
		
		
		SET @LocationStatus = (SELECT Location_status FROM @Location_status);
		
		DELETE @Processorders;
		DELETE @Location_status;
		SET @Puid = (SELECT MIN(location_id) FROM @Output WHERE location_id > @Puid);
	END;  /*End of Loop*/

	/*Filter cleaning status*/
	IF @F_Location_Status IS NOT NULL
	BEGIN
		DELETE @Output WHERE Location_status IS NULL;
		DELETE @Output WHERE Location_status NOT IN (SELECT CleanStatus FROM @LocationCleanStr);
	END
	
	/*determine the number of appliances in the location(s)*/
	INSERT INTO @AppliancesInLocation(
	Appliance_id,
	Transition_PU_Id,
	Transition_event_id,
	Transition_timestamp,
	Transition_extended_info,
	Rownum)
	SELECT	
			EA.event_id,
			ET.pu_id, 
			ET.event_id,
			ET.timestamp,
			ET.extended_info,
			ROW_NUMBER() OVER(PARTITION BY EC.Source_Event_id ORDER BY EC.timestamp DESC)
	FROM	dbo.event_components EC WITH(NOLOCK) 
	JOIN dbo.events EA				WITH(NOLOCK)	ON EC.source_event_id = EA.event_id
	JOIN dbo.events ET				WITH(NOLOCK)	ON EC.event_id = ET.event_id
	JOIN dbo.prod_units_base PUBA	WITH(NOLOCK)	ON PUBA.pu_id = EA.pu_id
	WHERE	PUBA.Equipment_Type = 'CTS Appliance';		
					
	UPDATE @Output 
	SET Number_of_appliances = 
	A.CNT FROM @output O
	CROSS APPLY (	SELECT COUNT(rownum) CNT 
					FROM @AppliancesInLocation 
					WHERE rownum = 1 
						AND Transition_PU_Id = O.Location_id
				) A;
	
	UPDATE @Output 
	SET Pending_Appliance_Count = 
	A.CNT FROM @output O
	CROSS APPLY (	SELECT COUNT(1) CNT 
					FROM @AppliancesInLocation 
					WHERE Transition_PU_Id = O.Location_id 
						AND rownum = 1 
						AND Transition_extended_info IS NOT NULL
				) A;
	
	IF (SELECT COUNT(1) FROM @ProductsFilter) > 0
		DELETE @output 
		WHERE COALESCE(Active_or_inprep_process_order_product,'') NOT IN(	SELECT proddesc 
																			FROM @ProductsFilter);
	/*define access*/
	UPDATE @Output
	SET Access = 'Read\Write';


	LaFin:
	RETURN 
END
