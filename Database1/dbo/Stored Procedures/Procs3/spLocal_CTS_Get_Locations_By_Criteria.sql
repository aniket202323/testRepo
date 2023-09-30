

--------------------------------------------------------------------------------------------------
-- Stored Procedure: spLocal_CTS_Get_Locations_by_criteria
--------------------------------------------------------------------------------------------------
-- Author				: Ugo Lapierre, Symasol
-- Date created			: 2021-10-05
-- Version 				: Version <1.1>
-- SP Type				: Web
-- Caller				: Called by CTS mobile application
-- Description			: Get locations is used by the CTS search dialog and scan dialog
-- Editor tab spacing	: 4
-------------------------------------------------------------------------------
--



--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ===========================================================================================
-- 1.0		2021-10-05		U.Lapierre						Initial Release 
-- 1.1		2022-01-10		Francois Bergeron				Add is making field to output
-- 1.2		2022-01-18		Francois Bergeron				Include default movement location in output (UDP)
-- 1.3		2022-01-25		Francois Bergeron				Add cleanable field in the output to determine if the location can be cleaned or not
-- 1.4		2022-01-31		Francois Bergeron				Add cleanable field in the output to determine if the appliance can be cleaned or not
-- 1.5		2022-02-03		Francois Bergeron				Add count of appliances in location
-- 1.6		2022-02-04		Francois Bergeron				Add timers
-- 1.7		2022-02-11		Francois Bergeron				Add rename fields in fnLocal_CTS_Get_Locations_by_criteria called function
-- 1.8		2022-04-06		Francois Bergeron				Status update staging
-- 1.9		2022-08-31		U. Lapierre						Improve performance for Appliance count section
-- 1.10		2022-11-17		U.Lapierre						Try to improve performance
-- 1.11		2023-02-21		U.Lapierre						Get the PrO info for Minor Clean location
-- 1.12		2023-03-15		U.Lapierre						Add maintenance to output possibility
-- 1.13		2023-03-27		U.Lapierre						Add output to indicate if Maintanance Button should be visible or not
--================================================================================================
--


--------------------------------------------------------------------------------------------------
-- TEST CODE:
--------------------------------------------------------------------------------------------------
/*
exec [dbo].[spLocal_CTS_Get_Locations_by_criteria] NULL,NULL,NULL, NULL, NULL, NULL
*/

-------------------------------------------------------------------------------
CREATE   PROCEDURE [dbo].[spLocal_CTS_Get_Locations_By_Criteria]
@Serial								varchar(25),
@F_Product							varchar(255),
@F_Location_Type					varchar(255),
@F_Location_Status					varchar(255),	
@F_Order_Range_hours				int,
@C_User								varchar(100)
		
--WITH ENCRYPTION	
AS
SET NOCOUNT ON

DECLARE
@SPName							varchar(100),
@GUID							uniqueidentifier


SET @GUID = ( SELECT newid())
SET @SPName = 'spLocal_CTS_Get_Locations_by_criteria'

--INSERT [dbo].[Local_CTS_Debug_Log] (timestamp,CallingSP, [LogNumber],[Message],[GroupingId])
--VALUES (GETDATE(), @SPName, 0, 'start',@GUID )

--Output table
DECLARE @Output	TABLE (
Serial									varchar(50),
Location_id								int,
Location_desc							varchar(50),
Location_type							varchar(50), 
Location_status							varchar(50), 
Cleaning_status							varchar(50),
Cleaning_type							varchar(50),
Compatible_process_order_count			int, 
Active_or_inprep_process_order_Id		Int,  
Active_or_inprep_process_order_desc		varchar(50),  
Active_or_inprep_process_order_product	varchar(50),  
Active_or_inprep_process_order_status	varchar(50), 
Number_of_soft_reservations				int, 
Number_of_hard_reservations				int, 
Access									varchar(25),
Requires_PO_selection					int DEFAULT 0,
Default_destination_location_id			int,
Default_destination_location_desc		varchar(50),
Location_Cleanable						int,
Maintenance_Visible						INT DEFAULT 1,
Maintenance_Possible					int DEFAULT 1,
Appliance_Cleanable						int,
Number_of_appliances					int,
Pending_Appliance_Count					int,
Cleaned_timer_hour						FLOAT,
Cleaned_limit_hour						FLOAT,
Used_timer_hour							FLOAT,
Used_limit_hour							FLOAT,
Appliance_cleaning_active				BIT,
Timer_Exception							VARCHAR(25) -- None, Cleaning, Usage
)


	--Table_fields
	DECLARE @TableIdProdUnit				int,
			@tfIdLocationSerial				int,
			@tfIdLocationType				int,
			@tfIdDefDestinationLocationId	int
			--,
			--@tfIdLocationCleanVarId			int,
			--@tfIdLocationPrOVarId			int,
			--@tfIdLocationPrOStatusVarId		int

	--***********************************************
	--Filters
	--***********************************************
	DECLARE @LocationTypeStr TABLE
	(
	LocationType varchar(50)
	)

	DECLARE @TransactionTime	DATETIME

	SET @TransactionTime = GETDATE()
	--***********************************************
	--Process Order
	--***********************************************
	DECLARE @Puid							int,
			@PathId							int,
			@PrId							Int,
			@PrO							varchar(100),
			@GCAS							varchar(100),
			@ProductDesc					varchar(100),
			@PPStatusDesc					varchar(100),
			@locationCleaningType			varchar(25),
			@CompatiblePrO					int,
			@MaxDate						datetime

	DECLARE @Processorders		TABLE	(
	PPId									int,
	ProcessOrder							varchar(50),
	PPStatusDesc							varchar(50),
	ProdCode								varchar(50),
	ProdDesc								varchar(50),
	ForecastStartDate						datetime,
	BOMFId									int,
	ForecastEndDate							datetime
										)

	DECLARE @ProductsFilter		TABLE	(
	ProdId									int,
	ProdDesc								varchar(100)
										)

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
	)
	--***********************************************
	--Reservation
	--***********************************************
	DECLARE	@ESReservation					int,
			@varIdType						int,
			@CountSoft						int,
			@CountHard						int

	DECLARE @Reservations	TABLE	(
	UDEId									int,
	Timestamp								datetime,
	Type									varchar(100)
		)


	--***********************************************
	--Cleaning
	--***********************************************
	DECLARE	@LocationStatus					varchar(100)

	DECLARE @LocationCleanStr	TABLE	(
	CleanStatus							varchar(50)
		)

	------------------------------------
	--Get table field_id
	------------------------------------
	SET @TableIdProdUnit				=	(	SELECT tableId FROM dbo.Tables WITH(NOLOCK) WHERE TableName = 'Prod_Units'	)
	SET @tfIdLocationSerial				=	(	SELECT table_field_id FROM dbo.Table_Fields WITH(NOLOCK) WHERE TableId = @TableIdProdUnit AND Table_Field_Desc = 'CTS Location serial number')
	SET @tfIdLocationType				=	(	SELECT table_field_id FROM dbo.Table_Fields WITH(NOLOCK) WHERE TableId = @TableIdProdUnit AND Table_Field_Desc = 'CTS location Type')
	SET @tfIdDefDestinationLocationId	=	(	SELECT table_field_id FROM dbo.Table_Fields WITH(NOLOCK) WHERE TableId = @TableIdProdUnit AND Table_Field_Desc = 'CTS Default movement destination')


	
	DECLARE @Location_Appliance_Cleaning_Active TABLE
	(
	Location_Pu_id INTEGER,
	Apppliance_cleaning_active BIT
	)

	INSERT INTO @Location_Appliance_Cleaning_Active(Location_Pu_id,Apppliance_cleaning_active)
	SELECT PUB.pu_id, 1
	FROM	dbo.user_defined_events UDE WITH(NOLOCK)
			JOIN dbo.prod_units_base PUB WITH(NOLOCK)
				ON PUB.pu_id = UDE.pu_id
			JOIN dbo.event_subtypes EST WITh(NOLOCK)
				ON EST.event_subtype_id = UDE.event_subtype_id
			JOIN dbo.production_status PS
				ON PS.prodStatus_id = UDE.event_status
	WHERE	PS.ProdStatus_Desc IN('CTS_Cleaning_Started', 'CTS_Cleaning_completed')
			AND PUB.Equipment_Type = 'CTS Location'
			AND EST.event_subtype_desc = 'CTS Appliance Cleaning'


--INSERT [dbo].[Local_CTS_Debug_Log] (timestamp,CallingSP, [LogNumber],[Message],[GroupingId])
--VALUES (GETDATE(), @SPName, 1, 'after get location',@GUID )

	--Get reservation event_subtype
	SET @ESReservation = (	SELECT event_subtype_id FROM dbo.Event_Subtypes WITH(NOLOCK) WHERE Event_Subtype_Desc = 'CTS Reservation')

	--Set Maxdate to query production_plan
	If @F_Order_Range_hours IS NULL
		SET @F_Order_Range_hours = 24

	SELECT @MaxDate = DATEADD(HH,@F_Order_Range_hours,GETDATE())


	--------------------------------------------
	--Get all location matching the parameters
	--------------------------------------------
	IF @Serial IS NULL
			SET @Serial = ''

	IF @Serial <> ''
	BEGIN  --The serial is provided, so get specific location
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

		FROM	dbo.Prod_Units_Base pu WITH(NOLOCK)
				LEFT JOIN @Location_Appliance_Cleaning_Active LACA
					ON LACA.Location_Pu_id = pu.pu_id
				JOIN dbo.Table_Fields_Values tfv WITH(NOLOCK)	
					ON pu.PU_Id = tfv.KeyId AND tfv.Table_Field_Id = @tfIdLocationSerial
				JOIN dbo.prdExec_inputs PEI	WITH(NOLOCK)
					ON PU.pu_id = PEI.pu_id
				JOIN dbo.PrdExec_Input_Sources PEIS	WITH(NOLOCK)
					ON PEI.pei_id = PEIS.pei_id 
				LEFT JOIN dbo.prdexec_path_units PEPU 
					ON PEPU.pu_id = PEI.pu_id
				LEFT JOIN dbo.production_plan_starts PPS WITH(NOLOCK)
					ON PPS.pu_id = PU.PU_id AND @TransactionTime >= PPS.start_time AND (@TransactionTime<PPS.End_Time OR PPS.end_time IS NULL)
				OUTER APPLY	(SELECT EC.Event_subType_id FROM dbo.event_configuration EC WITH(NOLOCK)	
									JOIN dbo.event_subtypes EST WITh(NOLOCK)
										ON EST.event_SubType_Id = EC.Event_Subtype_Id
							WHERE	EC.pu_id = PU.PU_id 
									AND EC.ET_ID = 14
									AND EST.event_subtype_desc = 'CTS Location Cleaning') LCL
				OUTER APPLY	(SELECT EC.Event_subType_id FROM dbo.event_configuration EC WITH(NOLOCK)	
									JOIN dbo.event_subtypes EST WITh(NOLOCK)
										ON EST.event_SubType_Id = EC.Event_Subtype_Id
							WHERE	EC.pu_id = PU.PU_id 
									AND EC.ET_ID = 14
									AND EST.event_subtype_desc = 'CTS Appliance Cleaning') ACL
		WHERE	pu.Equipment_Type = 'CTS Location'
				AND PEI.input_name = 'CTS Location Transition'
				AND tfv.Value = @Serial
	
		--INSERT [dbo].[Local_CTS_Debug_Log] (timestamp,CallingSP, [LogNumber],[Message],[GroupingId])
		--VALUES (GETDATE(), @SPName, 2, 'after get specific location',@GUID )

		IF NOT EXISTS (SELECT 1 FROM @Output)
			GOTO LaFin
	END
	ELSE
	BEGIN  --filters have to be used, get all matching location
		------------------------------------
		--Get all CTS Locations using equipment type
		------------------------------------
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
		FROM	dbo.Prod_Units_Base pu WITH(NOLOCK)
				LEFT JOIN @Location_Appliance_Cleaning_Active LACA
					ON LACA.Location_Pu_id = pu.pu_id
				JOIN dbo.Table_Fields_Values tfv WITH(NOLOCK)	
					ON pu.PU_Id = tfv.KeyId AND tfv.Table_Field_Id = @tfIdLocationSerial
				JOIN dbo.prdExec_inputs PEI	WITH(NOLOCK)
					ON PU.pu_id = PEI.pu_id
				JOIN dbo.PrdExec_Input_Sources PEIS	WITH(NOLOCK)
					ON PEI.pei_id = PEIS.pei_id 
				LEFT JOIN dbo.prdexec_path_units PEPU 
					ON PEPU.pu_id = PEI.pu_id
				LEFT JOIN dbo.production_plan_starts PPS WITH(NOLOCK)
					ON PPS.pu_id = PU.PU_id AND @TransactionTime >= PPS.start_time AND (@TransactionTime<PPS.End_Time OR PPS.end_time IS NULL)
				OUTER APPLY	(SELECT EC.Event_subType_id FROM dbo.event_configuration EC WITH(NOLOCK)	
										JOIN dbo.event_subtypes EST WITh(NOLOCK)
											ON EST.event_SubType_Id = EC.Event_Subtype_Id
								WHERE	EC.pu_id = PU.PU_id 
										AND EC.ET_ID = 14
										AND EST.event_subtype_desc = 'CTS Location Cleaning') LCL
				OUTER APPLY	(SELECT EC.Event_subType_id FROM dbo.event_configuration EC WITH(NOLOCK)	
									JOIN dbo.event_subtypes EST WITh(NOLOCK)
										ON EST.event_SubType_Id = EC.Event_Subtype_Id
							WHERE	EC.pu_id = PU.PU_id 
									AND EC.ET_ID = 14
									AND EST.event_subtype_desc = 'CTS Appliance Cleaning') ACL
				
		WHERE	pu.Equipment_Type = 'CTS Location'
				AND PEI.input_name = 'CTS Location Transition'

		--INSERT [dbo].[Local_CTS_Debug_Log] (timestamp,CallingSP, [LogNumber],[Message],[GroupingId])
		--VALUES (GETDATE(), @SPName, 2, 'after get all location',@GUID )
	END  


	--Get All UDPs
	UPDATE o
	SET		Serial = tfv1.value, 
			Location_Type = tfv2.value,
			Default_destination_location_id = tfv3.value,
			Default_destination_location_desc = PUB.pu_desc
	FROM @Output o
	JOIN dbo.Table_Fields_Values tfv1	WITH(NOLOCK)	ON tfv1.KeyId = o.Location_id	AND	tfv1.Table_Field_Id = @tfIdLocationSerial
	LEFT JOIN dbo.Table_Fields_Values tfv2	WITH(NOLOCK)	ON tfv2.KeyId = o.Location_id	AND	tfv2.Table_Field_Id = @tfIdLocationType
	LEFT JOIN dbo.Table_Fields_Values tfv3	WITH(NOLOCK)	ON tfv3.KeyId = o.Location_id	AND	tfv3.Table_Field_Id = @tfIdDefDestinationLocationId
	LEFT JOIN dbo.prod_units_base PUB ON CAST(PUB.PU_ID AS VARCHAR(25)) = CAST(tfv3.value AS VARCHAR(25))
	
--INSERT [dbo].[Local_CTS_Debug_Log] (timestamp,CallingSP, [LogNumber],[Message],[GroupingId])
--VALUES (GETDATE(), @SPName, 3, 'update location',@GUID )

	-------------------------------------------------------
	--Filter list of location based on Location Type
	-------------------------------------------------------
	IF @F_Location_Type IS NOT NULL
	BEGIN
		INSERT @LocationTypeStr (LocationType)
		SELECT * FROM dbo.fnLocal_CmnParseList(@F_Location_Type,',')

		DELETE @Output 
			WHERE Location_type NOT IN (SELECT LocationType
										FROM @LocationTypeStr)
	END


	-------------------------------------------------------
	--Filter list of location based on Location status
	-------------------------------------------------------
	IF @F_Location_Status IS NOT NULL
	BEGIN
		INSERT @LocationCleanStr (CleanStatus)
		SELECT * FROM dbo.fnLocal_CmnParseList(@F_Location_Status,',')
	END

	--------------------------------------------
	--Filter list of location based on product filter
	--------------------------------------------
	INSERT @ProductsFilter	(ProdId)
	SELECT CAST(value AS INTEGER) FROM dbo.fnLocal_CmnParseList(@F_Product,',')

	UPDATE pf
	SET proddesc = p.prod_desc
	FROM @ProductsFilter pf
	JOIN Products_Base p WITH(NOLOCK) ON pf.Prodid = p.Prod_Id

	DELETE @ProductsFilter WHERE Proddesc IS NULL
/*	IF (SELECT COUNT(1) FROM @ProductsFilter) = 0
	BEGIN
		INSERT @ProductsFilter (ProdId,ProdDesc)
		SELECT	DISTINCT
		p.prod_id	as 'Prod_Id',
		p.prod_Desc as 'Prod_Desc'
		FROM dbo.pu_products pup			WITH(NOLOCK)
		JOIN dbo.products_base p			WITH(NOLOCK)	ON pup.prod_id = p.prod_id
		JOIN @output O										ON O.Location_id = pup.pu_id
	END
	*/   
		--INSERT [dbo].[Local_CTS_Debug_Log] (timestamp,CallingSP, [LogNumber],[Message],[GroupingId])
		--VALUES (GETDATE(), @SPName, 4, 'Before loop',@GUID )
	---------------------------------------------------------------------
	--Loop across remaining Location to get other information
	---------------------------------------------------------------------
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
		FROM	dbo.fnLocal_CTS_Location_Status(@Puid, NULL)


		----------------------------------------------
		--PrO management
		----------------------------------------------
		SELECT	@Prid = NULL,
				@PrO = NULL,
				@GCAS = NULL,
				@PPStatusDesc = NULL,
				@ProductDesc	= NULL,
				@locationCleaningType = NULL,
				@LocationStatus = NULL
		
	

		SET @PathId = (SELECT TOP 1 path_id FROM dbo.PrdExec_Path_Units WHERE PU_Id = @Puid)
		IF @PathId IS NOT NULL
		BEGIN
			/*
			INSERT @Processorders (PPId ,ProcessOrder ,ProdCode , ProdDesc , PPStatusDesc , BOMFId, ForecastStartDate )
			SELECT pp.PP_Id, pp.Process_Order, p.Prod_Code, p.prod_desc, ps.PP_Status_Desc, pp.BOM_Formulation_Id, Forecast_Start_Date
			FROM dbo.Production_Plan pp				WITH(NOLOCK)
			JOIN dbo.Products_Base p				WITH(NOLOCK)	ON pp.Prod_Id = p.Prod_Id
			JOIN dbo.Production_Plan_Statuses ps	WITH(NOLOCK)	ON pp.PP_Status_Id = ps.PP_Status_Id
			WHERE pp.Path_Id = @PathId AND ps.PP_Status_Id IN (1,3)

			--Get active info
			SELECT	@Prid = PPId,
					@PrO = processorder,
					@GCAS = prodcode,
					@PPStatusDesc = ppstatusdesc,
					@ProductDesc = ProdDesc
			FROM @Processorders
			WHERE PPStatusDesc = 'Active'

			*/


			--Get active info
			SELECT	@Prid = PP.pp_id,
					@PrO = PP.process_order,
					@GCAS = P.prod_code,
					@PPStatusDesc = PS.PP_Status_Desc,
					@ProductDesc = p.prod_desc,
					@locationCleaningType = LS.Cleaning_type,
					@LocationStatus	= LS.Location_status
			FROM	@Location_Status LS
					JOIN  dbo.Production_Plan pp WITH(NOLOCK)
						ON PP.pp_id = LS.Last_Process_order_Id
					JOIN dbo.Products_Base p WITH(NOLOCK)	
						ON pp.Prod_Id = p.Prod_Id
					JOIN dbo.Production_Plan_Statuses ps WITH(NOLOCK)	
						ON pp.PP_Status_Id = ps.PP_Status_Id
			WHERE	pp.Path_Id = @PathId


	/*		
			IF @LocationStatus != 'Clean' AND COALESCE(@locationCleaningType,'') !='Major' 
				UPDATE @Output
				SET		Active_or_inprep_process_order_Id		= @PrId, 
						Active_or_inprep_process_order_desc		= @PrO,  
						Active_or_inprep_process_order_product	= @ProductDesc,
						Active_or_inprep_process_order_status	= @PPStatusDesc
						WHERE location_id = @Puid

	*/	

						--Update pro info
			IF @LocationStatus = 'Clean' AND COALESCE(@locationCleaningType,'') !='Major' 
				UPDATE @Output
				SET		Active_or_inprep_process_order_Id		= @PrId, 
						Active_or_inprep_process_order_desc		= @PrO,  
						Active_or_inprep_process_order_product	= @ProductDesc,
						Active_or_inprep_process_order_status	= @PPStatusDesc
						WHERE location_id = @Puid


			IF @LocationStatus != 'Clean' --AND COALESCE(@locationCleaningType,'') !='Major' 
				UPDATE @Output
				SET		Active_or_inprep_process_order_Id		= @PrId, 
						Active_or_inprep_process_order_desc		= @PrO,  
						Active_or_inprep_process_order_product	= @ProductDesc,
						Active_or_inprep_process_order_status	= @PPStatusDesc
						WHERE location_id = @Puid




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



		-------------------------------------------------------
		--Cleaning status management
		-------------------------------------------------------
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
		WHERE	Location_id = @puid
		
		
		SET @LocationStatus = (SELECT Location_status FROM @Location_status)
		
		DELETE @Processorders
		DELETE @Location_status
		SET @Puid = (SELECT MIN(location_id) FROM @Output WHERE location_id > @Puid)
	END  --End of Loop


		--INSERT [dbo].[Local_CTS_Debug_Log] (timestamp,CallingSP, [LogNumber],[Message],[GroupingId])
		--VALUES (GETDATE(), @SPName, 5, 'after loop',@GUID )
	-------------------------------------------
	--Filter cleaning status
	-------------------------------------------
	IF @F_Location_Status IS NOT NULL
	BEGIN
		DELETE @Output WHERE Location_status IS NULL
		DELETE @Output WHERE Location_status NOT IN (SELECT CleanStatus FROM @LocationCleanStr)
	END
	
	-------------------------------------------
	--determine the number of appliances in the location(s)
	-------------------------------------------
	-------------------------------------------
	--determine the number of appliances in the location(s)
	-------------------------------------------
	DECLARE @ApplianceEvents TABLE (
	EventId				int,
	Puid				int	)

	INSERT @ApplianceEvents (EventId, Puid)
	SELECT e.event_id, pu.pu_id
	FROM dbo.events e WITH(NOLOCK)
	JOIN dbo.prod_units_base pu WITH(NOLOCK) ON e.pu_id = pu.pu_id
	WHERE pu.equipment_type = 'CTS Appliance'


	DECLARE @AppliancesInLocation TABLE(
	Appliance_id				INTEGER,
	Transition_PU_Id			INTEGER,
	Transition_event_id			INTEGER,
	Transition_timestamp		DATETIME,
	Transition_extended_info	VARCHAR(500),
	Rownum						INTEGER
	)
	INSERT INTO @AppliancesInLocation(
	Appliance_id,
	Transition_PU_Id,
	Transition_event_id,
	Transition_timestamp,
	Transition_extended_info)
	SELECT	sub.SEID,
			ET.pu_id, 
			ET.event_id,
			ET.timestamp,
			ET.extended_info
	FROM dbo.event_components EC	WITH(NOLOCK) 
	JOIN  (	SELECT  EC.Source_Event_id AS SEID, MAX(ec.component_id) AS ECID
			FROM	dbo.event_components EC WITH(NOLOCK) 
			JOIN @ApplianceEvents ea 	ON EC.source_event_id = EA.eventid
			GROUP BY EC.Source_Event_id		) sub	ON ec.component_id = sub.ECID
	JOIN dbo.events ET				WITH(NOLOCK)	ON EC.event_id = ET.event_id

					
	UPDATE @Output 
	SET Number_of_appliances = 
	A.CNT FROM @output O
	CROSS APPLY (SELECT COUNT(Appliance_id) CNT FROM @AppliancesInLocation WHERE /*rownum = 1 AND */  Transition_PU_Id = O.Location_id) A
	

	UPDATE @Output 
	SET Pending_Appliance_Count = 
	A.CNT FROM @output O
	CROSS APPLY (SELECT COUNT(1) CNT FROM @AppliancesInLocation WHERE Transition_PU_Id = O.Location_id /*AND rownum = 1*/ AND Transition_extended_info IS NOT NULL) A
	
	IF (SELECT COUNT(1) FROM @ProductsFilter) > 0
		DELETE @output WHERE COALESCE(Active_or_inprep_process_order_product,'') NOT IN(SELECT proddesc FROM @ProductsFilter)

		--INSERT [dbo].[Local_CTS_Debug_Log] (timestamp,CallingSP, [LogNumber],[Message],[GroupingId])
		--VALUES (GETDATE(), @SPName, 7, 'After cross apply',@GUID )

	-------------------------------------------
	--define access
	-------------------------------------------
	UPDATE @Output
	SET Access = 'Read\Write'


	-------------------------------------------
	--Check For maintenance
	-------------------------------------------
	UPDATE o
	SET Cleaning_status = f.Maintenance_Status,
		Location_status = f.Location_status
	FROM @Output o
	CROSS APPLY fnLocal_CTS_Location_Status(o.location_id,NULL) f
	WHERE f.Maintenance_Status IS NOT NULL

	UPDATE @Output
	SET maintenance_possible = 0,
		maintenance_Visible = 0
	WHERE Location_Type <> 'Making'

	UPDATE @Output
	SET maintenance_possible = 0
	WHERE Active_or_inprep_process_order_status = 'Active'

	UPDATE @Output
	SET maintenance_possible = 0
	WHERE Cleaning_Status IN ('CTS_Cleaning_Completed','CTS_Cleaning_Started')

	UPDATE @Output
	SET Location_Cleanable = 0
	WHERE Cleaning_Status IN ('CST_Maintenance_Started')


	LaFin:

	SELECt Serial,
	Location_id,
	Location_desc,
	Location_type, 
	Location_status, 
	Cleaning_status,
	Cleaning_type,
	Compatible_process_order_count, 
	Active_or_inprep_process_order_Id,  
	Active_or_inprep_process_order_desc,  
	Active_or_inprep_process_order_product,  
	Active_or_inprep_process_order_status, 
	Number_of_soft_reservations, 
	Number_of_hard_reservations, 
	Access,
	Requires_PO_selection,
	Default_destination_location_id,
	Default_destination_location_desc,
	Location_Cleanable,
	Maintenance_Visible,
	Maintenance_Possible,
	Appliance_Cleanable,
	Number_of_appliances,
	Pending_Appliance_Count,
	Cleaned_timer_hour,
	Cleaned_limit_hour,
	Used_timer_hour,
	Used_limit_hour,
	Appliance_cleaning_active,
	Timer_Exception
	FROM @output

SET NOCOUNT OFF

RETURN

