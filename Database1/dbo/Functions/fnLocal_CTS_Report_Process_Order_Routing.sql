

--------------------------------------------------------------------------------------------------
-- Table function: fnLocal_CTS_Report_Process_Order_Route
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


--================================================================================================
--
--------------------------------------------------------------------------------------------------
-- TEST CODE:
--------------------------------------------------------------------------------------------------
/*

SELECT * FROM [fnLocal_CTS_Report_Process_Order_Routing](15072) 
*/

--CREATE FUNCTION [dbo].[fnLocal_CTS_Report_Appliance_History]
CREATE FUNCTION [dbo].[fnLocal_CTS_Report_Process_Order_Routing]
(
@ProcessOrderId			INTEGER
)

RETURNS @Output TABLE 
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

AS
BEGIN
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
	@tfIdLocationSerial						INTEGER,
	@LocationCleaningUDESubTypeId			INTEGER,
	@ApplianceCleaningUDESubTypeId			INTEGER,
	@locationCleaningTypeVarId				INTEGER,
	@varIdCleaningProcedure					INTEGER,				
	@VarIdSanitizer_serial					INTEGER,			
	@VarIdSanitizer_Conc					INTEGER,				
	@VarIdDetergent_serial					INTEGER,				
	@VarIdDetergent_Conc					INTEGER	

	DECLARE @Appliance_Transitions			TABLE(
	T_Id									INTEGER IDENTITY(1,1),
	Appliance_PE_Id							INTEGER,
	Appliance_Serial						VARCHAR(25),
	Appliance_Type							VARCHAR(25),
	Transition_PE_Id						INTEGER,
	Transition_PE_Time						DATETIME,
	Transition_PE_PU_Id						INTEGER,
	Transition_PE_PU_Desc					VARCHAR(50),
	Transition_PE_PP_Id						INTEGER,
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

	SET @groupId = 1
	SET @TableIdProdUnit = (SELECT tableId FROM dbo.Tables WITH(NOLOCK) WHERE TableName = 'Prod_Units'	)
	SET @tfIdLocationSerial = (	SELECT table_field_id FROM dbo.Table_Fields WITH(NOLOCK) WHERE TableId = @TableIdProdUnit AND Table_Field_Desc = 'CTS Location serial number')
	SET @tfIdApplianceType = (	SELECT table_field_id FROM dbo.Table_Fields WITH(NOLOCK) WHERE TableId = @TableIdProdUnit AND Table_Field_Desc = 'CTS Appliance type')
	
	
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
	Field3
	)
	VALUES	(0,@groupId,'Title bar','#000080','#FFFFFF','Process order',NULL,NULL),
			(0,@groupId,'Data type',NULL,NULL,'string','string','string'),
			(0,@groupId,'Header',NULL,NULL,'Selected process order','Product code','Product_desc')


	INSERT INTO @Output
	(
	Level,
	Group_id,
	Type,
	BackgroundColor,
	TextColor,
	Field1,
	Field2,
	Field3
	)
	SELECT 0, @groupId,'Data', NULL, NULL, PP.process_order, PB.prod_desc, PB.prod_code 
				FROM dbo.production_plan PP WITH(NOLOCK) 
				JOIN dbo.products_base PB WITH(NOLOCK) 
				ON PB.prod_id = PP.prod_id WHERE PP.PP_ID = @ProcessOrderId


	--LOOP BACKWARD
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
		VALUES	(1,@groupId,'Title bar','#000080','#FFFFFF','Process order activity at location',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
				(1,@groupId,'Data type',NULL,NULL,'string','string','string','string','string','string','datetime','datetime','datetime','datetime'),
				(1,@groupId,'Header',NULL,NULL,'Location','Serial', 'Status','Process order','Product_desc', 'Product code', 'Planned start', 'Actual start', 'Planned end', 'Actual end')

		-- GET PROCESS ORDER STATE AT LOCATION LEVEL 1
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

		-- GET LOCATION CELANING Level = 2
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
		3,
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


		-- GET LOCATION CLEANING DETAIL Level = 3

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
		SET @VarIdDetergent_serial			=	(	SELECT var_id	FROM dbo.variables_base WITH(NOLOCK) WHERE pu_id = @loopPuId AND event_subtype_id = @LocationCleaningUDESubTypeId AND Test_Name = 'Detergent batch:serial')	
		SET @VarIdDetergent_Conc			=	(	SELECT var_id	FROM dbo.variables_base WITH(NOLOCK) WHERE pu_id = @loopPuId AND event_subtype_id = @LocationCleaningUDESubTypeId AND Test_Name = 'Detergent batch:concentration')	
		SET @VarIdSanitizer_serial			=	(	SELECT var_id 	FROM dbo.variables_base WITH(NOLOCK) WHERE pu_id = @loopPuId AND event_subtype_id = @LocationCleaningUDESubTypeId AND Test_Name = 'Sanitizer batch:serial')	
		SET @VarIdSanitizer_Conc			=	(	SELECT var_id	FROM dbo.variables_base WITH(NOLOCK) WHERE pu_id = @loopPuId AND event_subtype_id = @LocationCleaningUDESubTypeId AND Test_Name = 'Sanitizer batch:concentration')	
		SET @varIdCleaningProcedure			=	(	SELECT var_id	FROM dbo.variables_base WITH(NOLOCK) WHERE pu_id = @loopPuId AND event_subtype_id = @LocationCleaningUDESubTypeId AND Test_Name = 'Cleaning:procedure')


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

		--GET ALL APPLIANCE IN WHILE PO ACTIVE AT LOCATION
		INSERT INTO @Appliance_transitions(
		Appliance_PE_Id,
		Appliance_Serial,
		Appliance_Type,
		Transition_PE_Id,
		Transition_PE_Time,
		Transition_PE_PU_Id,
		Transition_PE_PU_Desc,
		Transition_PE_PP_Id,
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
		WHERE	ETRANS.PU_Id = @loopPUid AND ETRANS.Start_time >= @loopStartTime 
				AND (ETRANS.Start_time < @loopEndTime OR @loopEndTime IS NULL)
				AND Q1.rownum = 1
		


		SET @SecondLoopCount = 1


		WHILE (SELECT COUNT(1) FROM @Appliance_transitions WHERE T_Id = @SecondLoopCount)>0
		BEGIN


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
			VALUES	(2,@groupId,'Title bar','#000080','#FFFFFF','Appliances utilized',NULL,NULL,NULL,NULL,NULL),
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



			IF (SELECT Status_Desc FROM	@Appliance_transitions  WHERE T_Id = @secondLoopCount) = 'Clean'
			BEGIN
				
				-- GET CLEANING
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
				VALUES	(2,@groupId,'Title bar','#000080','#FFFFFF','Appliance cleaning',NULL,NULL,NULL,NULL,NULL),
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
				3,
				@groupId,
				'Data',
				NULL,
				NULL,
				Type,
				Start_time,
				End_time,
				Completion_ES_Username,
				Approver_ES_Username
				FROM fnLocal_CTS_Appliance_Cleanings(@SecondLoopApplianceId, NULL, @loopStartTime)

				SET @SecondLoopApplianceCleaningUDEId =
				(SELECT UDE_Id FROM fnLocal_CTS_Location_Cleanings(@SecondLoopApplianceId, NULL, @loopStartTime))


				--GET CLEANING DETAILS
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
				VALUES	(3,@groupId,'Title bar','#000080','#FFFFFF','Appliance cleaning details',NULL,NULL,NULL,NULL),
						(3,@groupId,'Data type',NULL,NULL,'string','string','float','string','Float'),
						(3,@groupId,'Header',NULL,NULL,'Procedure', 'Detergent batch','Detergent concentration','Sanitizer batch', 'Sanitizer concentration')


				--Get var_id
				SET @VarIdDetergent_serial			=	(	SELECT var_id	FROM dbo.variables_base WITH(NOLOCK) WHERE pu_id = @loopPuId AND event_subtype_id = @ApplianceCleaningUDESubTypeId AND Test_Name = 'Detergent batch:serial')	
				SET @VarIdDetergent_Conc			=	(	SELECT var_id	FROM dbo.variables_base WITH(NOLOCK) WHERE pu_id = @loopPuId AND event_subtype_id = @ApplianceCleaningUDESubTypeId AND Test_Name = 'Detergent batch:concentration')	
				SET @VarIdSanitizer_serial			=	(	SELECT var_id 	FROM dbo.variables_base WITH(NOLOCK) WHERE pu_id = @loopPuId AND event_subtype_id = @ApplianceCleaningUDESubTypeId AND Test_Name = 'Sanitizer batch:serial')	
				SET @VarIdSanitizer_Conc			=	(	SELECT var_id	FROM dbo.variables_base WITH(NOLOCK) WHERE pu_id = @loopPuId AND event_subtype_id = @ApplianceCleaningUDESubTypeId AND Test_Name = 'Sanitizer batch:concentration')	
				SET @varIdCleaningProcedure			=	(	SELECT var_id	FROM dbo.variables_base WITH(NOLOCK) WHERE pu_id = @loopPuId AND event_subtype_id = @ApplianceCleaningUDESubTypeId AND Test_Name = 'Cleaning:procedure')


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
				WHERE	UDE.ude_id = @SecondLoopApplianceCleaningUDEId

				
			END --IF
		
			SET @Secondloopcount = @secondLoopCount + 1

		END -- SEC Loop

		
		IF (SELECT TOP 1 Transition_PE_PP_Id FROM @Appliance_transitions WHERE Status_Desc = 'In Use' ORDER by Transition_PE_Time ASC) != @LoopProcessOrderId
		BEGIN
			SET @OK=0
			SET @LoopProcessOrderId = (SELECT TOP 1 Transition_PE_PP_Id FROM @Appliance_transitions WHERE Status_Desc = 'In Use' ORDER by Transition_PE_Time ASC)
		END
		ELSE
			SET @OK=1



		SET @loopCount = @loopCount + 1

	END

	Return

End

