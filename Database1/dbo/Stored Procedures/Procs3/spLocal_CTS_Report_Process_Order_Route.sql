

--------------------------------------------------------------------------------------------------
-- Table function: spLocal_CTS_Report_Process_Order_Route
--------------------------------------------------------------------------------------------------
-- Author				: Francois Bergeron, Symasol
-- Date created			: 2022-02-23
-- Version 				: Version 1.0
-- SP Type				: Proficy Plant Applications
-- Caller				: SQL
-- Description			: This function retrieves the process order route from a starting process order
-- Editor tab spacing	: 4
-------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ===========================================================================================
-- 1.0		2022-02-23		F. Bergeron				Initial Release 
-- 1.1		2023-01-11		U.Lapierre				Avoid Clean value in empty row
-- 1.2		2023-01-31		U.Lapierre				Add batch with process order
-- 2.0		2023-03-08		U.Lapierre				Allow to type Batch or PrO
-- 2.1		2023-05-30		U.Lapierre				Standardize + create to Alter
--================================================================================================
--
--------------------------------------------------------------------------------------------------
-- TEST CODE:
--------------------------------------------------------------------------------------------------
/*

EXECUTE spLocal_CTS_Report_Process_Order_Route NULL,'G202302204' ,NULL

EXECUTE spLocal_CTS_Report_Process_Order_Route NULL, NULL,'C220908002'

EXECUTE spLocal_CTS_Report_Process_Order_Route 16044, NULL,NULL


*/


CREATE PROCEDURE [dbo].[spLocal_CTS_Report_Process_Order_Route]
(
@ProcessOrderId			INTEGER,
@Batch					varchar(50) = NULL,
@ProcessOrder			varchar(50) = NULL

)
AS
BEGIN

	DECLARE @ValidPaths TABLE (
	pathId			int
	)

	DECLARE @Output TABLE 
	(
	Level									INTEGER,
	Group_id								INTEGER,
	Line_id									INTEGER IDENTITY(1,1),
	Type									VARCHAR(100),
	BackgroundColor							VARCHAR(25),
	TextColor								VARCHAR(25),
	Field1									VARCHAR(50),
	Field2									VARCHAR(50),
	Field3									VARCHAR(50),
	Field4									VARCHAR(50),	
	Field5									VARCHAR(50),	
	Field6									VARCHAR(50),	
	Field7									VARCHAR(50),
	Field8									VARCHAR(50),
	Field9									VARCHAR(50),
	Field10									VARCHAR(50),
	Field11									VARCHAR(50),
	Field12									VARCHAR(50),
	Field13									VARCHAR(50),
	Field14									VARCHAR(50),
	Field15									VARCHAR(50),
	BigField1								NVARCHAR(500),
	BigField2								NVARCHAR(500)
	)


	DECLARE 
	@OK										INTEGER,
	@loopPUid								INTEGER,
	@loopStartTime							DATETIME,
	@loopEndTime							DATETIME,
	@LoopProcessOrderId						INTEGER,
	@LoopLocationCleaningUDEId				INTEGER,
	@loopCount								INTEGER,
	@SecondLoopCount						INTEGER,
	@SecondLoopApplianceId					INTEGER,
	@SecondLoopApplianceCleaningUDEId		INTEGER,
	@GroupId								INTEGER,
	@TableIdProdUnit						INTEGER,
	@tfIdApplianceType						INTEGER,
	@tfIdLocationType						INTEGER,
	@tfIdLocationSerial						INTEGER,
	@LocationCleaningUDESubTypeId			INTEGER,
	@ApplianceCleaningUDESubTypeId			INTEGER,
	@locationCleaningTypeVarId				INTEGER,
	@varIdCleaningProcedure					INTEGER,				
	@VarIdSanitizer_serial					INTEGER,			
	@VarIdSanitizer_Conc					INTEGER,				
	@VarIdDetergent_serial					INTEGER,				
	@VarIdDetergent_Conc					INTEGER,
	@ApplianceCleaningPuId					INTEGER

	DECLARE @Appliance_Transitions			TABLE(
	T_Id									INTEGER IDENTITY(1,1),
	Appliance_PE_Id							INTEGER,
	Appliance_Serial						VARCHAR(25),
	Appliance_Type							VARCHAR(50),
	Transition_PE_Id						INTEGER,
	Transition_PE_Time						DATETIME,
	Transition_PE_PU_Id						INTEGER,
	Transition_PE_PU_Desc					VARCHAR(50),
	Transition_PE_PP_Id						INTEGER,
	Transition_PE_PP_Id_ON_Entry			INTEGER,
	Transition_PE_PP_Desc					VARCHAR(50),
	Transition_PE_PP_Product_Id				INTEGER,
	Transition_PE_PP_Product_Code			VARCHAR(50),
	Transition_PE_PP_Product_Desc			VARCHAR(50),
	Transition_PE_PP_Applied_Product_Id		INTEGER,
	Transition_PE_PP_Applied_Product_Code	VARCHAR(50),
	Transition_PE_PP_Applied_Product_Desc	VARCHAR(50),
	Status_Id								INTEGER,
	Status_Desc								VARCHAR(50)
	)

	DECLARE 
	@LoopInUseApplianceEventId				INTEGER,
	@LoopInUselastTimestamp					DATETIME,
	@LoopLastPPWTimestamp					DATETIME,
	@LoopLastPPWTransitionEventId			INTEGER,
	@LoopLastPPWTransitionProdCode			VARCHAR(50),
	@LoopLastPPWTransitionProdDesc			VARCHAR(50),
	@LoopLastPPWTransitionProdId			INTEGER,
	@LoopLastPPWPUDesc						VARCHAR(50),
	@LoopLastPPWPUId						INTEGER,
	@LoopLastPUSerial						VARCHAR(50),
	@LoopLastPPWApplianceSerial				VARCHAR(50),
	@LoopLastPPWApplianceType				VARCHAR(50),
	@LoopLastPPWApplianceFilledOn			DATETIME



	/* V2.0 Exit if all inputs are NULL */

	IF @ProcessOrderId IS NULL  /* new case by Batch or ProcessOrder */
	BEGIN
		INSERT @ValidPaths (pathId)
		SELECT path_id
		FROM dbo.prdExec_Paths WITH(NOLOCK)
		WHERE path_code LIKE 'CTS_%'
			OR path_code LIKE 'CST_%'


		IF @ProcessOrder IS NOT NULL
		BEGIN
			IF ( SELECT CHARINDEX('-CTS',@ProcessOrder,0) +  CHARINDEX('-CST',@ProcessOrder,0)) > 1
			BEGIN
				SET @ProcessOrderId = (	SELECT TOP 1 pp.pp_id 
										FROM dbo.production_plan pp		WITH(NOLOCK) 
										JOIN @ValidPaths vp								ON pp.path_id = vp.pathid
										WHERE pp.process_order = @ProcessOrder
										)
			END
			ELSE
			BEGIN
				SET @ProcessOrder = @ProcessOrder + '-CTS'
				SET @ProcessOrderId = (	SELECT TOP 1 pp.pp_id 
										FROM dbo.production_plan pp		WITH(NOLOCK) 
										JOIN @ValidPaths vp								ON pp.path_id = vp.pathid
										WHERE pp.process_order = @ProcessOrder
										)
				IF @ProcessOrderId IS NULL
				BEGIN
					SET @ProcessOrder = @ProcessOrder + '-CST'
					SET @ProcessOrderId = (	SELECT TOP 1 pp.pp_id 
											FROM dbo.production_plan pp		WITH(NOLOCK) 
											JOIN @ValidPaths vp								ON pp.path_id = vp.pathid
											WHERE pp.process_order = @ProcessOrder
											)

				END
			END
		END
		IF @Batch IS NOT NULL AND @ProcessOrderId IS NULL
		BEGIN
			SET @ProcessOrderId = (	SELECT TOP 1 pp.pp_id 
									FROM dbo.production_plan pp		WITH(NOLOCK) 
									JOIN @ValidPaths vp								ON pp.path_id = vp.pathid
									WHERE pp.User_General_1 = @Batch
									)
		END

	END



	SET @groupId = 1
	SET @TableIdProdUnit = (SELECT tableId FROM dbo.Tables WITH(NOLOCK) WHERE TableName = 'Prod_Units'	)
	SET @tfIdLocationSerial = (	SELECT table_field_id FROM dbo.Table_Fields WITH(NOLOCK) WHERE TableId = @TableIdProdUnit AND Table_Field_Desc = 'CTS Location serial number')
	SET @tfIdApplianceType = (	SELECT table_field_id FROM dbo.Table_Fields WITH(NOLOCK) WHERE TableId = @TableIdProdUnit AND Table_Field_Desc = 'CTS Appliance type')
	SET @tfIdLocationType = (	SELECT table_field_id FROM dbo.Table_Fields WITH(NOLOCK) WHERE TableId = @TableIdProdUnit AND Table_Field_Desc = 'CTS location type')

	SET @SecondLoopCount = 1
	
	SET @LocationCleaningUDESubTypeId = 
	(
		SELECT	EST.event_Subtype_Id
		FROM	dbo.event_subtypes EST WITH(NOLOCK)
		WHERE	EST.event_Subtype_Desc = 'CTS Location Cleaning'
	)

	SET @ApplianceCleaningUDESubTypeId = 
	(
		SELECT	EST.Event_Subtype_Id
		FROM	dbo.event_subtypes EST WITH(NOLOCK)
		WHERE	EST.Event_Subtype_Desc = 'CTS Appliance Cleaning'
	)

	SET @loopCount = 0
	SET @LoopProcessOrderId = @ProcessOrderId
	SET @OK = 0

	
	-- INSERT THE FIRST LINES IN THE REPORT
	INSERT INTO @Output
	(
	Level,
	Group_id,
	Type,
	BackgroundColor,
	TextColor,
	Field1,
	Field2,
	Field3, 
	Field4
	)
	VALUES	(0,@groupId,'Title bar','#000080','#FFFFFF','Process order',NULL,NULL, NULL),
			(0,@groupId,'Data type',NULL,NULL,'string','string','string','string'),
			(0,@groupId,'Header',NULL,NULL,'Process order','Product desc','Product code', 'Batch')


	INSERT INTO @Output
	(
	Level,
	Group_id,
	Type,
	BackgroundColor,
	TextColor,
	Field1,
	Field2,
	Field3,
	Field4
	)
	SELECT 0, @groupId,'Data', NULL, NULL, PP.process_order, PB.prod_desc, PB.prod_code ,PP.user_general_1
				FROM dbo.production_plan PP WITH(NOLOCK) 
				JOIN dbo.products_base PB WITH(NOLOCK) 
				ON PB.prod_id = PP.prod_id WHERE PP.PP_ID = @ProcessOrderId



	/*Start by the PO selected and loop Backward*/
	WHILE (@OK = 0)
	BEGIN
		SET @GroupId =  @groupId + 1
		SELECT	@loopPUid = pu_id, 
				@loopStartTime = Start_time, 
				@loopEndTime = End_time 
		FROM	dbo.production_plan_starts 
		WHERE	PP_ID = @LoopProcessOrderId



		INSERT INTO @Output
		(
		Level,
		Group_id,
		Type,
		BackgroundColor,
		TextColor,
		Field1,
		Field2,
		Field3,
		Field4,	
		Field5,	
		Field6,	
		Field7,
		Field8,
		Field9,
		Field10
		)
		VALUES	(1,@groupId,'Title bar','#000080','#FFFFFF','Location activity',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
				(1,@groupId,'Data type',NULL,NULL,'string','string','string','string','string','string','datetime','datetime','datetime','datetime'),
				(1,@groupId,'Header',NULL,NULL,'Location','Serial', 'Location status prior PO start','Process order','Product_desc', 'Product code', 'Planned start', 'Actual start', 'Planned end', 'Actual end')


		/* GET PROCESS ORDER STATE AT LOCATION LEVEL 1	*/
		INSERT 
		INTO	@Output(
				Level,
				Group_id,
				Type,
				BackgroundColor,
				TextColor,
				Field1,
				Field2,
				Field3,
				Field4,	
				Field5,	
				Field6,	
				Field7,
				Field8,
				Field9,
				Field10
		)

		SELECT	
				1,
				@groupId,
				'Data',
				NULL,
				NULL,
				PUB.pu_desc,
				TFV.Value,
				(SELECT location_status 
				FROM dbo.fnlocal_CTS_Location_status(PPS.PU_ID, @loopStartTime)),
				PP.process_order,
				PBPP.prod_desc,
				PBPP.prod_code,
				PP.Forecast_Start_Date,
				@loopStartTime,
				PP.forecast_end_date,
				@loopEndTime
		FROM	dbo.production_plan_starts PPS	
				JOIN dbo.production_plan PP WITH(NOLOCK)
					ON PP.PP_Id = PPS.PP_Id
				JOIN dbo.products_base PBPP WITH(NOLOCK)
					ON PBPP.prod_id = PP.Prod_id
				JOIN dbo.PrdExec_Path_Units PPU WITH(NOLOCK) 
					ON PPU.PU_Id= PPS.pu_id
				JOIN dbo.prod_units_base PUB WITH(NOLOCK)
					ON PUB.PU_id = PPS.pu_id
				JOIN dbo.Table_Fields_Values TFV WITH(NOLOCK)
					ON PUB.PU_id = TFV.KeyId
					AND TFV.Table_Field_Id = @tfIdLocationSerial
		WHERE	PPS.PP_id = @LoopProcessOrderId


		SET @GroupId =  @groupId + 1
		/* GET LOCATION CLEANING Level = 2	*/
		INSERT INTO @Output
		(
		Level,
		Group_id,
		Type,
		BackgroundColor,
		TextColor,
		Field1,
		Field2,
		Field3,
		Field4,	
		Field5,	
		BigField1
		)
		VALUES	(2,@groupId,'Title bar','#000080','#FFFFFF','Location cleaning',NULL,NULL,NULL,NULL,NULL),
				(2,@groupId,'Data type',NULL,NULL,'string','datetime','datetime','string','string','string'),
				(2,@groupId,'Header',NULL,NULL,'Type', 'Start','End','User', 'Approver', 'Comments')


		INSERT INTO @Output
		(
		Level,
		Group_id,
		Type,
		BackgroundColor,
		TextColor,
		Field1,
		Field2,
		Field3,
		Field4,	
		Field5--,
		--BigField1
		)
		SELECT
		TOP 1
		2,
		@groupId,
		'Data',
		NULL,
		NULL,
		Type,
		Start_time,
		End_time,
		Completion_ES_Username,
		Approver_ES_Username
		FROM fnLocal_CTS_Location_Cleanings(@loopPUid, NULL, @loopStartTime)

		SET @LoopLocationCleaningUDEId =
		(SELECT UDE_Id FROM fnLocal_CTS_Location_Cleanings(@loopPUid, NULL, @loopStartTime))
	
/*
		SELECT	
		TOP 1
		2,
		@groupId,
		'Data',
		NULL,
		NULL,
		T.result,
		UDE.start_time,
		UDE.End_Time,
		UB.username,
		VU.username--,					-
		--C.comment
		FROM	dbo.user_defined_events UDE WITH(NOLOCK)
				JOIN  dbo.production_status PS WITH(NOLOCK) 
					ON PS.prodStatus_id = UDE.event_Status
				JOIN dbo.Users_Base UB WITH(NOLOCK)
					ON UB.User_Id = UDE.User_Id
				JOIN dbo.prod_units_base PUB WITH(NOLOCK)
					ON PUB.PU_ID = UDE.PU_ID
				JOIN dbo.esignature ES WITH(NOLOCK)
					ON ES.signature_id = UDE.signature_id
				JOIN dbo.users VU
					ON VU.user_id = ES.verify_user_id
				-- TYPE
				JOIN dbo.variables_Base VB WITH(NOLOCK) 
					ON VB.pu_id = PUB.pu_id
					AND VB.Test_Name = 'Type'
				JOIN dbo.tests T WITH(NOLOCK)
					ON T.var_id = VB.var_id
						AND t.result_on = UDE.end_time
				LEFT JOIN dbo.comments C  WITH(NOLOCK)
					ON C.comment_id = UDE.comment_id
		WHERE	UDE.event_Subtype_Id = 	@LocationCleaningUDESubTypeId
				AND VB.Test_Name = 'Type'
				AND UDE.pu_id = @loopPUid
				AND UDE.end_time <=@loopStartTime
		ORDER 
		BY		UDE.start_time
*/

		SET @GroupId =  @groupId + 1
		/* GET LOCATION CLEANING DETAIL Level = 3	*/

		INSERT INTO @Output
		(
		Level,
		Group_id,
		Type,
		BackgroundColor,
		TextColor,
		Field1,
		Field2,
		Field3,
		Field4,	
		Field5
		)
		VALUES	(3,@groupId,'Title bar','#000080','#FFFFFF','Location cleaning details',NULL,NULL,NULL,NULL),
				(3,@groupId,'Data type',NULL,NULL,'string','string','float','string','Float'),
				(3,@groupId,'Header',NULL,NULL,'Procedure', 'Detergent batch','Detergent concentration','Sanitizer batch', 'Sanitizer concentration')

		
		--Get var_id
		SET @VarIdDetergent_serial			=	(	SELECT var_id	FROM dbo.variables_base WITH(NOLOCK) WHERE pu_id = @loopPUid AND event_subtype_id = @LocationCleaningUDESubTypeId AND Test_Name = 'Detergent batch:serial')	
		SET @VarIdDetergent_Conc			=	(	SELECT var_id	FROM dbo.variables_base WITH(NOLOCK) WHERE pu_id = @loopPUid AND event_subtype_id = @LocationCleaningUDESubTypeId AND Test_Name = 'Detergent batch:concentration')	
		SET @VarIdSanitizer_serial			=	(	SELECT var_id 	FROM dbo.variables_base WITH(NOLOCK) WHERE pu_id = @loopPUid AND event_subtype_id = @LocationCleaningUDESubTypeId AND Test_Name = 'Sanitizer batch:serial')	
		SET @VarIdSanitizer_Conc			=	(	SELECT var_id	FROM dbo.variables_base WITH(NOLOCK) WHERE pu_id = @loopPUid AND event_subtype_id = @LocationCleaningUDESubTypeId AND Test_Name = 'Sanitizer batch:concentration')	
		SET @varIdCleaningProcedure			=	(	SELECT var_id	FROM dbo.variables_base WITH(NOLOCK) WHERE pu_id = @loopPUid AND event_subtype_id = @LocationCleaningUDESubTypeId AND Test_Name = 'Cleaning:procedure')

		INSERT INTO @Output
		(
		Level,
		Group_id,
		Type,
		BackgroundColor,
		TextColor,
		Field1,
		Field2,
		Field3,
		Field4,	
		Field5
		)
		SELECT
		3,
		@groupId,
		'Data',
		NULL,
		NULL,
		T1.result,
		T2.result,
		T3.result,
		T4.result,
		T5.result
		FROM	dbo.user_defined_events UDE WITH(NOLOCK)
				LEFT JOIN dbo.tests t1			WITH(NOLOCK)	ON t1.Result_On = UDE.end_time AND t1.var_id = @varIdCleaningProcedure AND T1.Event_Id = UDE.UDE_Id
				LEFT JOIN dbo.tests t2			WITH(NOLOCK)	ON t2.Result_On = UDE.end_time AND t2.var_id = @VarIdDetergent_serial AND T2.Event_Id = UDE.UDE_Id
				LEFT JOIN dbo.tests t3			WITH(NOLOCK)	ON t3.Result_On = UDE.end_time AND t3.var_id = @VarIdDetergent_Conc AND T3.Event_Id = UDE.UDE_Id
				LEFT JOIN dbo.tests t4			WITH(NOLOCK)	ON t4.Result_On = UDE.end_time AND t4.var_id = @VarIdSanitizer_serial AND T4.Event_Id = UDE.UDE_Id
				LEFT JOIN dbo.tests t5			WITH(NOLOCK)	ON t5.Result_On = UDE.end_time AND t5.var_id = @VarIdSanitizer_Conc AND T5.Event_Id = UDE.UDE_Id
		WHERE	UDE.ude_id = @LoopLocationCleaningUDEId

		/* GET ALL APPLIANCE IN WHILE PO ACTIVE AT LOCATION	*/
		INSERT INTO @Appliance_transitions(
		Appliance_PE_Id,
		Appliance_Serial,
		Appliance_Type,
		Transition_PE_Id,
		Transition_PE_Time,
		Transition_PE_PU_Id,
		Transition_PE_PU_Desc,
		Transition_PE_PP_Id, 
		Transition_PE_PP_Id_ON_Entry,/*WHEN ENTERING THE LOCATION*/
		Transition_PE_PP_Desc,
		Transition_PE_PP_Product_Id,
		Transition_PE_PP_Product_Code,
		Transition_PE_PP_Product_Desc,
		Transition_PE_PP_Applied_Product_Id,
		Transition_PE_PP_Applied_Product_Code,
		Transition_PE_PP_Applied_Product_Desc,
		Status_Id,
		Status_Desc)

		SELECT 
		EDAPP.Event_Id, 
		EDAPP.Alternate_Event_Num, 
		TFV.value,
		EDTRANS.Event_Id, 
		ETRANS.Start_Time,
		ETRANS.PU_Id,
		PUB.PU_desc,
		EDTRANS.PP_Id, 
		NULL,
		PP.process_order,
		PBPP.prod_id,
		PBPP.prod_code,
		PBPP.prod_desc,
		PBAP.prod_id,
		PBAP.prod_code,
		PBAP.prod_desc,
		PS.ProdStatus_Id, 
		PS.ProdStatus_Desc
		FROM	dbo.events ETRANS WITH(NOLOCK) 
				JOIN dbo.event_components EC WITH(NOLOCK)
					ON EC.event_id = ETRANS.event_id
				JOIN dbo.events EAPP WITH(NOLOCK)
					ON EAPP.event_id = EC.Source_Event_Id
				JOIN dbo.event_details EDTRANS WITH(NOLOCK) 
					ON EDTRANS.event_id = ETRANS.Event_Id
				JOIN dbo.event_details EDAPP 
					ON EDAPP.Event_Id = EAPP.Event_Id
				CROSS APPLY(SELECT *,ROW_NUMBER() OVER(PARTITION BY ETRANSST.event_id ORDER BY ETRANSST.Start_time ASC)  'Rownum'  
							FROM dbo.event_status_transitions ETRANSST WITH(NOLOCK)
							WHERE ETRANSST.event_id = ETRANS.event_id)Q1
				JOIN dbo.Production_Status PS WITH(NOLOCK) 
					ON PS.ProdStatus_Id = Q1.Event_Status
				JOIN dbo.production_plan PP WITH(NOLOCK)
					ON PP.PP_Id = EDTRANS.PP_Id
				JOIN dbo.products_base PBPP WITH(NOLOCK)
					ON PBPP.prod_id = PP.Prod_id
				LEFT JOIN dbo.products_base PBAP WITH(NOLOCK)
					ON PBAP.prod_id = ETRANS.Applied_product
				JOIN dbo.PrdExec_Path_Units PPU WITH(NOLOCK) 
					ON PPU.PU_Id= ETRANS.pu_id
				JOIN dbo.prod_units_base PUB WITH(NOLOCK)
					ON PUB.PU_id = ETRANS.PU_Id
				LEFT JOIN dbo.table_fields_Values TFV WITH(NOLOCK)
					ON TFV.keyid = EAPP.pu_id
						AND TFV.table_field_Id = @tfIdApplianceType
		WHERE	ETRANS.PU_Id = @loopPUid 
				AND ETRANS.Start_time >= @loopStartTime 
				AND (ETRANS.Start_time < @loopEndTime OR @loopEndTime IS NULL)
				AND Q1.rownum = 1

		UPDATE	@Appliance_transitions SET Transition_PE_PP_Id_ON_Entry = ED.PP_ID
		FROM	@Appliance_transitions AT
		CROSS Apply (SELECT TOP 1 * FROM dbo.event_components WITH(NOLOCK) WHERE source_event_id = Appliance_PE_Id AND event_id != Transition_PE_Id AND Timestamp < Transition_PE_Time  ORDER by timestamp DESC) Q
		JOIN dbo.event_details ED WITH(NOLOCK) ON ED.event_id = Q.event_id
		WHERE Status_desc = 'In use'



		
/*		UPDATE	@Appliance_transitions SET Transition_PE_PP_Id_ON_Entry = -999
		FROM	@Appliance_transitions AT
		CROSS Apply (SELECT TOP 1 EC.event_id FROM dbo.event_components EC WITH(NOLOCK) JOIN dbo.events E WITH(NOLOCK) ON E.event_id = EC.event_id JOIN dbo.prod_units_base PUB WITH(NOLOCK)
		ON PUB.pu_id = E.pu_id 
		
		WHERE EC.source_event_id = Appliance_PE_Id AND E.event_id != Transition_PE_Id AND EC.Timestamp < Transition_PE_Time  AND PUB.Equipment_Type ='PPW' ORDER by EC.timestamp DESC
		) Q
		JOIN dbo.event_details ED WITH(NOLOCK) ON ED.event_id = Q.event_id
		WHERE Status_desc = 'In use'
*/

		
		/*GET ALL APPLIANCES THAT GOT IN THE LOCATION FOR THIS PO*/
		WHILE (SELECT COUNT(1) FROM @Appliance_transitions WHERE T_Id = @SecondLoopCount) > 0
		BEGIN
			SET @GroupId =  @groupId + 1

			SET @SecondLoopApplianceId = (SELECT Appliance_PE_Id FROM @Appliance_transitions 
			WHERE	T_Id = @secondLoopCount) 

			INSERT INTO @Output
			(
			Level,
			Group_id,
			Type,
			BackgroundColor,
			TextColor,
			Field1,
			Field2,
			Field3,
			Field4,	
			Field5,
			Field6
			)
			VALUES	(2,@groupId,'Title bar','#000080','#FFFFFF','Appliances',NULL,NULL,NULL,NULL,NULL),
					(2,@groupId,'Data type',NULL,NULL,'string','string','string','string','string','string'),
					(2,@groupId,'Header',NULL,NULL,'Appliance type', 'Serial number','Process order','Product desc','Product code','Status')

			INSERT INTO @Output
			(
			Level,
			Group_id,
			Type,
			BackgroundColor,
			TextColor,
			Field1,
			Field2,
			Field3,
			Field4,	
			Field5,
			Field6
			)
			SELECT 
			2,
			@groupId,
			'Data',
			NULL,
			NULL,
			Appliance_type,
			Appliance_Serial,
			Transition_PE_PP_Desc,
			COALESCE(Transition_PE_PP_Product_Desc,Transition_PE_PP_Applied_Product_Desc),
			COALESCE(Transition_PE_PP_Product_Code,Transition_PE_PP_Applied_Product_Code),
			Status_Desc
			FROM	@Appliance_transitions 
			WHERE	T_Id = @secondLoopCount 
			
			
		


			IF (SELECT Status_Desc FROM	@Appliance_transitions  WHERE T_Id = @secondLoopCount) in ('Clean')
			BEGIN
				IF EXISTS(SELECT 1 FROM fnLocal_CTS_Appliance_Cleanings(@SecondLoopApplianceId, NULL, @loopStartTime))
				BEGIN
					SET @GroupId =  @groupId + 1
					/* GET CLEANING	*/
					INSERT INTO @Output
					(
					Level,
					Group_id,
					Type,
					BackgroundColor,
					TextColor,
					Field1,
					Field2,
					Field3,
					Field4,	
					Field5,	
					Field6,
					BigField1
					)
					VALUES	(3,@groupId,'Title bar','#000080','#FFFFFF','Appliance cleaning',NULL,NULL,NULL,NULL,NULL,NULL),
							(3,@groupId,'Data type',NULL,NULL,'String','string','datetime','datetime','string','string','string'),
							(3,@groupId,'Header',NULL,NULL,'Location','Type', 'Start','End','User', 'Approver', 'Comments')


					INSERT INTO @Output
					(
					Level,
					Group_id,
					Type,
					BackgroundColor,
					TextColor,
					Field1,
					Field2,
					Field3,
					Field4,	
					Field5,
					Field6
					)
					SELECT
					TOP 1
					3,
					@groupId,
					'Data',
					NULL,
					NULL,
					Location_desc,
					Type,
					Start_time,
					End_time,
					Completion_ES_Username,
					Approver_ES_Username
					FROM fnLocal_CTS_Appliance_Cleanings(@SecondLoopApplianceId, NULL, @loopStartTime)



					SET @SecondLoopApplianceCleaningUDEId =
					(SELECT UDE_Id FROM fnLocal_CTS_Appliance_Cleanings(@SecondLoopApplianceId, NULL, @loopStartTime))
	
					SET @ApplianceCleaningPuId = (SELECT pu_id FROM dbo.User_Defined_Events WHERE ude_id = @SecondLoopApplianceCleaningUDEId)

					SET @GroupId =  @groupId + 1
					/* GET CLEANING DETAILS */
					INSERT INTO @Output
					(
					Level,
					Group_id,
					Type,
					BackgroundColor,
					TextColor,
					Field1,
					Field2,
					Field3,
					Field4,	
					Field5
					)
					VALUES	(4,@groupId,'Title bar','#000080','#FFFFFF','Appliance cleaning details',NULL,NULL,NULL,NULL),
							(4,@groupId,'Data type',NULL,NULL,'string','string','float','string','Float'),
							(4,@groupId,'Header',NULL,NULL,'Procedure', 'Detergent batch','Detergent concentration','Sanitizer batch', 'Sanitizer concentration')


					/* Get var_id */
				
					SET @VarIdDetergent_serial			=	(	SELECT var_id	FROM dbo.variables_base WITH(NOLOCK) WHERE pu_id = @ApplianceCleaningPuId AND event_subtype_id = @ApplianceCleaningUDESubTypeId AND Test_Name = 'Detergent batch:serial')	
					SET @VarIdDetergent_Conc			=	(	SELECT var_id	FROM dbo.variables_base WITH(NOLOCK) WHERE pu_id = @ApplianceCleaningPuId AND event_subtype_id = @ApplianceCleaningUDESubTypeId AND Test_Name = 'Detergent batch:concentration')	
					SET @VarIdSanitizer_serial			=	(	SELECT var_id 	FROM dbo.variables_base WITH(NOLOCK) WHERE pu_id = @ApplianceCleaningPuId AND event_subtype_id = @ApplianceCleaningUDESubTypeId AND Test_Name = 'Sanitizer batch:serial')	
					SET @VarIdSanitizer_Conc			=	(	SELECT var_id	FROM dbo.variables_base WITH(NOLOCK) WHERE pu_id = @ApplianceCleaningPuId AND event_subtype_id = @ApplianceCleaningUDESubTypeId AND Test_Name = 'Sanitizer batch:concentration')	
					SET @varIdCleaningProcedure			=	(	SELECT var_id	FROM dbo.variables_base WITH(NOLOCK) WHERE pu_id = @ApplianceCleaningPuId AND event_subtype_id = @ApplianceCleaningUDESubTypeId AND Test_Name = 'Cleaning:procedure')

					INSERT INTO @Output
					(
					Level,
					Group_id,
					Type,
					BackgroundColor,
					TextColor,
					Field1,
					Field2,
					Field3,
					Field4,	
					Field5
					)
					SELECT
					4,
					@groupId,
					'Data',
					NULL,
					NULL,
					T1.result,
					T2.result,
					T3.result,
					T4.result,
					T5.result
					FROM	dbo.user_defined_events UDE WITH(NOLOCK)
							LEFT JOIN dbo.tests t1			WITH(NOLOCK)	ON t1.Result_On = UDE.end_time AND t1.var_id = @varIdCleaningProcedure AND T1.Event_Id = UDE.UDE_Id
							LEFT JOIN dbo.tests t2			WITH(NOLOCK)	ON t2.Result_On = UDE.end_time AND t2.var_id = @VarIdDetergent_serial AND T2.Event_Id = UDE.UDE_Id
							LEFT JOIN dbo.tests t3			WITH(NOLOCK)	ON t3.Result_On = UDE.end_time AND t3.var_id = @VarIdDetergent_Conc AND T3.Event_Id = UDE.UDE_Id
							LEFT JOIN dbo.tests t4			WITH(NOLOCK)	ON t4.Result_On = UDE.end_time AND t4.var_id = @VarIdSanitizer_serial AND T4.Event_Id = UDE.UDE_Id
							LEFT JOIN dbo.tests t5			WITH(NOLOCK)	ON t5.Result_On = UDE.end_time AND t5.var_id = @VarIdSanitizer_Conc AND T5.Event_Id = UDE.UDE_Id
					WHERE	UDE.ude_id = @SecondLoopApplianceCleaningUDEId
				END
			
			END --IF
		
			SET @Secondloopcount = @secondLoopCount + 1
			
		END 
		/*GET THE PREVIOUS PROCESS ORDER*/
		/*TO GET THE PREVIOUS PROCESS ORDER */
		IF EXISTS(SELECT TOP 1 Transition_PE_PP_Id_ON_Entry FROM @Appliance_transitions WHERE Transition_PE_PP_Id_ON_Entry IS NOT NULL)
		BEGIN

			SET @OK=0
			SET @LoopProcessOrderId = (SELECT TOP 1 Transition_PE_PP_Id_ON_Entry FROM @Appliance_transitions WHERE Transition_PE_PP_Id_ON_Entry IS NOT NULL)
		
		END
		ELSE
		BEGIN
			 


			SELECT	@LoopInUseApplianceEventId = Appliance_PE_Id,
					@LoopInUselastTimestamp	= Transition_PE_Time
			FROM	@Appliance_transitions AT WHERE Status_desc = 'In use'

			SELECT	TOP 1	@LoopLastPPWTimestamp = EC.timestamp,
							@LoopLastPPWTransitionEventId = EC.event_id,
							@LoopLastPPWTransitionProdCode = PB.Prod_Code,
							@LoopLastPPWTransitionProdDesc  = PB.Prod_Desc,
							@LoopLastPPWTransitionProdId  = PB.Prod_Id,
							@LoopLastPPWPUDesc = PUB.PU_Desc,
							@LoopLastPUSerial = TFV.value,
							@LoopLastPPWApplianceSerial = ED1.alternate_event_num,
							@LoopLastPPWApplianceType =  TFV1.value,
							@LoopLastPPWApplianceFilledOn =  Q1.Start_time
						
			FROM	dbo.event_components EC 
					JOIN dbo.events E WITH(NOLOCK) 
						ON E.event_id = EC.event_id 
					JOIN dbo.events E1 WITH(NOLOCK) 
						ON E1.event_id = EC.Source_event_id 
					JOIN dbo.prod_units_base PUB WITH(NOLOCK)
						ON PUB.pu_id = E.pu_id 
					JOIN dbo.prod_units_base PUB1 WITH(NOLOCK)
						ON PUB1.pu_id = E1.pu_id
					LEFT JOIN dbo.event_details ED WITH(NOLOCK) 
						ON ED.event_id = EC.event_id
					JOIN dbo.event_details ED1 WITH(NOLOCK) 
						ON ED1.event_id = EC.Source_event_id
					JOIN dbo.products_base PB WITH(NOLOCK) 
						ON PB.prod_id = E.Applied_Product
					JOIN dbo.Table_Fields_Values TFV WITH(NOLOCK)
						ON PUB.PU_id = TFV.KeyId
						AND TFV.Table_Field_Id = @tfIdLocationSerial
					JOIN dbo.Table_Fields_Values TFV1 WITH(NOLOCK)
						ON PUB1.PU_id = TFV1.KeyId
						AND TFV1.Table_Field_Id = @tfIdApplianceType
					JOIN dbo.Table_Fields_Values TFV2 WITH(NOLOCK)
						ON PUB.PU_id = TFV2.KeyId
						AND TFV2.Table_Field_Id = @tfIdLocationType
					CROSS APPLY(SELECT *,ROW_NUMBER() OVER(PARTITION BY ETRANSST.event_id ORDER BY ETRANSST.Start_time DESC)  'Rownum'  
								FROM dbo.event_status_transitions ETRANSST WITH(NOLOCK)
								WHERE ETRANSST.event_id = E.event_id)Q1
					JOIN dbo.Production_Status PS WITH(NOLOCK) 
						ON PS.ProdStatus_Id = Q1.Event_Status

			WHERE	EC.source_event_id = @LoopInUseApplianceEventId AND EC.Timestamp < @LoopInUselastTimestamp  AND TFV2.value ='PPW' AND Q1.rownum = 1
			ORDER by EC.timestamp DESC

			/*SELECT @LoopLastPPWTimestamp,
							@LoopLastPPWTransitionEventId,
							@LoopLastPPWTransitionProdCode,
							@LoopLastPPWTransitionProdDesc,
							@LoopLastPPWTransitionProdId,
							@LoopLastPPWPUDesc,
							@LoopLastPUSerial,
							@LoopLastPPWApplianceSerial,
							@LoopLastPPWApplianceType
			*/
			/* Look if the appliance was cleaned between @LoopInUselastTimestamp and @LoopLastPPWTimestamp	*/
			IF (SELECT Count(1) FROM fnLocal_CTS_Appliance_Cleanings(@SecondLoopApplianceId, @LoopLastPPWTimestamp, @LoopInUselastTimestamp)) = 0
			BEGIN

				/* INSERT LOCATION INFO */
				INSERT INTO @Output
				(
				Level,
				Group_id,
				Type,
				BackgroundColor,
				TextColor,
				Field1,
				Field2,
				Field3,
				Field4,	
				Field5,
				Field6
				)
				VALUES	(1,@groupId,'Title bar','#000080','#FFFFFF','Location activity',NULL,NULL,NULL,NULL,NULL),
						(1,@groupId,'Data type'	,NULL	,NULL	,'Datetime'				,'string'	,'string'	,'string'			,'string'			,'string'),
						(1,@groupId,'Header'	,NULL	,NULL	,'Appliance filled on'	,'Location'	,'Serial'	, 'Location status'	,'Product_desc'		,'Product code')

				IF @LoopLastPUSerial IS NOT NULL
				BEGIN
					INSERT INTO @Output
					(
					Level,
					Group_id,
					Type,
					BackgroundColor,
					TextColor,
					Field1,
					Field2,
					Field3,
					Field4,	
					Field5,
					Field6
					)
					VALUES(
					1,
					@groupId,
					'Data',
					NULL,
					NULL,
					@LoopLastPPWApplianceFilledOn,
					@LoopLastPPWPUDesc,
					@LoopLastPUSerial,
					'Clean',
					@LoopLastPPWTransitionProdDesc,
					@LoopLastPPWTransitionProdCode)
				END
				ELSE
				BEGIN
				BEGIN
					INSERT INTO @Output
					(
					Level,
					Group_id,
					Type,
					BackgroundColor,
					TextColor,
					Field1,
					Field2,
					Field3,
					Field4,	
					Field5,
					Field6
					)
					VALUES(
					1,
					@groupId,
					'Data',
					NULL,
					NULL,
					@LoopLastPPWApplianceFilledOn,
					@LoopLastPPWPUDesc,
					@LoopLastPUSerial,
					NULL,
					@LoopLastPPWTransitionProdDesc,
					@LoopLastPPWTransitionProdCode)
				END
				END
				SET @GroupId =  @groupId + 1
				

				/* SET APPLIANCE INFOR */
				INSERT INTO @Output
				(
				Level,
				Group_id,
				Type,
				BackgroundColor,
				TextColor,
				Field1,
				Field2,
				Field3,
				Field4,	
				Field5
				)
				VALUES	(2,@groupId,'Title bar','#000080','#FFFFFF','Appliances',NULL,NULL,NULL,NULL),
						(2,@groupId,'Data type',NULL,NULL,'string','string','string','string','string'),
						(2,@groupId,'Header',NULL,NULL,'Appliance type','Serial number','Product desc','Product code','Status')
				IF @LoopLastPPWApplianceSerial IS NOT NULL
				BEGIN
					INSERT INTO @Output
					(
					Level,
					Group_id,
					Type,
					BackgroundColor,
					TextColor,
					Field1,
					Field2,
					Field3,
					Field4,	
					Field5
					)
					SELECT 
					2,
					@groupId,
					'Data',
					NULL,
					NULL,
					@LoopLastPPWApplianceType,
					@LoopLastPPWApplianceSerial,
					@LoopLastPPWTransitionProdDesc,
					@LoopLastPPWTransitionProdCode,
					'Clean'
				END
				ELSE
				BEGIN
					INSERT INTO @Output
					(
					Level,
					Group_id,
					Type,
					BackgroundColor,
					TextColor,
					Field1,
					Field2,
					Field3,
					Field4,	
					Field5
					)
					SELECT 
					2,
					@groupId,
					'Data',
					NULL,
					NULL,
					@LoopLastPPWApplianceType,
					@LoopLastPPWApplianceSerial,
					@LoopLastPPWTransitionProdDesc,
					@LoopLastPPWTransitionProdCode,
					NULL
				END
					
				/* CLEANING	*/
				SET @GroupId =  @groupId + 1
				/* GET CLEANING	*/
				INSERT INTO @Output
				(
				Level,
				Group_id,
				Type,
				BackgroundColor,
				TextColor,
				Field1,
				Field2,
				Field3,
				Field4,	
				Field5,	
				Field6,
				BigField1
				)
				VALUES	(3,@groupId,'Title bar','#000080','#FFFFFF','Appliance cleaning',NULL,NULL,NULL,NULL,NULL,NULL),
						(3,@groupId,'Data type',NULL,NULL,'String','string','datetime','datetime','string','string','string'),
						(3,@groupId,'Header',NULL,NULL,'Location','Type', 'Start','End','User', 'Approver', 'Comments')


				INSERT INTO @Output
				(
				Level,
				Group_id,
				Type,
				BackgroundColor,
				TextColor,
				Field1,
				Field2,
				Field3,
				Field4,	
				Field5,
				Field6
				)
				SELECT
				TOP 1
				3,
				@groupId,
				'Data',
				NULL,
				NULL,
				Location_desc,
				Type,
				Start_time,
				End_time,
				Completion_ES_Username,
				Approver_ES_Username
				FROM fnLocal_CTS_Appliance_Cleanings(@LoopInUseApplianceEventId, NULL, @LoopLastPPWTimestamp)



				SET @SecondLoopApplianceCleaningUDEId =
				(SELECT UDE_Id FROM fnLocal_CTS_Appliance_Cleanings(@LoopInUseApplianceEventId, NULL, @loopStartTime))
	
				SET @ApplianceCleaningPuId = (SELECT pu_id FROM dbo.User_Defined_Events WHERE ude_id = @SecondLoopApplianceCleaningUDEId)

				SET @GroupId =  @groupId + 1
				/*GET CLEANING DETAILS*/
				INSERT INTO @Output
				(
				Level,
				Group_id,
				Type,
				BackgroundColor,
				TextColor,
				Field1,
				Field2,
				Field3,
				Field4,	
				Field5
				)
				VALUES	(4,@groupId,'Title bar','#000080','#FFFFFF','Appliance cleaning details',NULL,NULL,NULL,NULL),
						(4,@groupId,'Data type',NULL,NULL,'string','string','float','string','Float'),
						(4,@groupId,'Header',NULL,NULL,'Procedure', 'Detergent batch','Detergent concentration','Sanitizer batch', 'Sanitizer concentration')


				/*Get var_id*/
				
				SET @VarIdDetergent_serial			=	(	SELECT var_id	FROM dbo.variables_base WITH(NOLOCK) WHERE pu_id = @ApplianceCleaningPuId AND event_subtype_id = @ApplianceCleaningUDESubTypeId AND Test_Name = 'Detergent batch:serial')	
				SET @VarIdDetergent_Conc			=	(	SELECT var_id	FROM dbo.variables_base WITH(NOLOCK) WHERE pu_id = @ApplianceCleaningPuId AND event_subtype_id = @ApplianceCleaningUDESubTypeId AND Test_Name = 'Detergent batch:concentration')	
				SET @VarIdSanitizer_serial			=	(	SELECT var_id 	FROM dbo.variables_base WITH(NOLOCK) WHERE pu_id = @ApplianceCleaningPuId AND event_subtype_id = @ApplianceCleaningUDESubTypeId AND Test_Name = 'Sanitizer batch:serial')	
				SET @VarIdSanitizer_Conc			=	(	SELECT var_id	FROM dbo.variables_base WITH(NOLOCK) WHERE pu_id = @ApplianceCleaningPuId AND event_subtype_id = @ApplianceCleaningUDESubTypeId AND Test_Name = 'Sanitizer batch:concentration')	
				SET @varIdCleaningProcedure			=	(	SELECT var_id	FROM dbo.variables_base WITH(NOLOCK) WHERE pu_id = @ApplianceCleaningPuId AND event_subtype_id = @ApplianceCleaningUDESubTypeId AND Test_Name = 'Cleaning:procedure')

				INSERT INTO @Output
				(
				Level,
				Group_id,
				Type,
				BackgroundColor,
				TextColor,
				Field1,
				Field2,
				Field3,
				Field4,	
				Field5
				)
				SELECT
				4,
				@groupId,
				'Data',
				NULL,
				NULL,
				T1.result,
				T2.result,
				T3.result,
				T4.result,
				T5.result
				FROM	dbo.user_defined_events UDE WITH(NOLOCK)
						LEFT JOIN dbo.tests t1			WITH(NOLOCK)	ON t1.Result_On = UDE.end_time AND t1.var_id = @varIdCleaningProcedure AND T1.Event_Id = UDE.UDE_Id
						LEFT JOIN dbo.tests t2			WITH(NOLOCK)	ON t2.Result_On = UDE.end_time AND t2.var_id = @VarIdDetergent_serial AND T2.Event_Id = UDE.UDE_Id
						LEFT JOIN dbo.tests t3			WITH(NOLOCK)	ON t3.Result_On = UDE.end_time AND t3.var_id = @VarIdDetergent_Conc AND T3.Event_Id = UDE.UDE_Id
						LEFT JOIN dbo.tests t4			WITH(NOLOCK)	ON t4.Result_On = UDE.end_time AND t4.var_id = @VarIdSanitizer_serial AND T4.Event_Id = UDE.UDE_Id
						LEFT JOIN dbo.tests t5			WITH(NOLOCK)	ON t5.Result_On = UDE.end_time AND t5.var_id = @VarIdSanitizer_Conc AND T5.Event_Id = UDE.UDE_Id
				WHERE	UDE.ude_id = @SecondLoopApplianceCleaningUDEId


			END


			
			SET @OK=1
		END

		DELETE @Appliance_transitions

		SET @loopCount = @loopCount-1


	END

	DELETE @Output WHERE group_Id NOT IN(SELECT Group_id FROM @Output WHERE Type = 'Data')


	SELECT	Level,
			Group_id,
			Type,
			BackgroundColor,
			TextColor,
			Field1,
			Field2,
			Field3,
			Field4,	
			Field5,	
			Field6,	
			Field7,
			Field8,
			Field9,
			Field10,
			Field11,
			Field12,
			Field13,
			Field14,
			Field15,
			BigField1,
			BigField2
	FROM	@Output /*order by Process_level*/



END
