

--------------------------------------------------------------------------------------------------
-- Table function: fnLocal_CTS_Report_Appliance_Transitions
--------------------------------------------------------------------------------------------------
-- Author				: Francois Bergeron, Symasol
-- Date created			: 2022-02-23
-- Version 				: Version 1.0
-- SP Type				: Proficy Plant Applications
-- Caller				: SQL
-- Description			: This function retrieves the location and status transition of an appliance
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

SELECT * FROM [fnLocal_CTS_Report_Appliance_Transitions](1038293, NULL, NULL)
ORDER BY Entity_Activity_Timestamp 
*/


CREATE FUNCTION [dbo].[fnLocal_CTS_Report_Appliance_Transitions]
(
@ApplianceID										INTEGER,
@StartTime											DATETIME = NULL,
@EndTime											DATETIME = NULL
)

RETURNS @Output TABLE 
(
	Entity_type										VARCHAR(25),
	Entity_sub_type									VARCHAR(25),	
	Entity_status									VARCHAR(50),
	Entity_Id										INTEGER,
	Entity_Desc										VARCHAR(50),
	Entity_Serial									VARCHAR(50),
	Entity_Product_Id								INTEGER,
	Entity_Product_code								VARCHAR(100),
	Entity_Product_desc								VARCHAR(100),
	Entity_Process_order_Id							INTEGER,
	Entity_Process_order_desc						VARCHAR(50),
	Entity_process_order_Form_Id					INTEGER,
	Entity_Activity									VARCHAR(100),
	Entity_Subactivity								VARCHAR(100),
	Entity_Activity_Location_id						INTEGER,
	Entity_Activity_Location_desc					VARCHAR(50),
	Entity_Activity_Location_status					VARCHAR(50),
	Entity_Activity_Location_Process_Id				VARCHAR(50),	
	Entity_Activity_Location_Process_order			VARCHAR(50),	
	Entity_Activity_Location_Product_id				VARCHAR(50),	
	Entity_Activity_Location_Product_code			VARCHAR(50),
	Entity_Activity_Location_Product_desc			VARCHAR(50),	
	Entity_Activity_id								INTEGER,
	Entity_Activity_Timestamp						DATETIME,
	Entity_Activity_User_Id							INTEGER,
	Entity_Activity_Username						VARCHAR(100)
)

AS
BEGIN
	DECLARE
	@TableIdProdUnit INTEGER,
	@tfIdApplianceType INTEGER,
	@tfIdLocationSerial INTEGER,
	@tfIdLocationType	INTEGER

	SET @TableIdProdUnit = (SELECT tableId FROM dbo.Tables WITH(NOLOCK) WHERE TableName = 'Prod_Units'	)
	SET @tfIdApplianceType = (	SELECT table_field_id FROM dbo.Table_Fields WITH(NOLOCK) WHERE TableId = @TableIdProdUnit AND Table_Field_Desc = 'CTS Appliance type')
	SET @tfIdLocationSerial = (	SELECT table_field_id FROM dbo.Table_Fields WITH(NOLOCK) WHERE TableId = @TableIdProdUnit AND Table_Field_Desc = 'CTS Location serial number')	
	SET @tfIdLocationType = (	SELECT table_field_id FROM dbo.Table_Fields WITH(NOLOCK) WHERE TableId = @TableIdProdUnit AND Table_Field_Desc = 'CTS location Type')	

	IF @StartTime IS NULL
		SET @StartTime = '01-01-1970'
	IF @EndTime IS NULL
		SET @EndTime = GETDATE()
	INSERT INTO	@output
	(
	Entity_type,
	Entity_sub_type,	
	Entity_status,
	Entity_Id,
	Entity_Desc,
	Entity_Serial,
	Entity_Product_Id,
	Entity_Product_code,
	Entity_Product_desc,
	Entity_Process_order_Id,
	Entity_Process_order_desc,
	Entity_process_order_Form_Id,
	Entity_Activity,
	Entity_Subactivity,
	Entity_Activity_Location_Id,
	Entity_Activity_Location_Desc,
	Entity_Activity_Location_status,
	Entity_Activity_Location_Process_Id,	
	Entity_Activity_Location_Process_order,
	Entity_Activity_Location_Product_id,
	Entity_Activity_Location_Product_code,
	Entity_Activity_Location_Product_desc,
	Entity_Activity_id,
	Entity_Activity_Timestamp,
	Entity_Activity_User_Id,
	Entity_Activity_Username
	)

	SELECT		
	'Appliance'								'Entity_type',
	TFV.value								'Entity_sub_type',	
	PS.ProdStatus_Desc						'Entity_status',
	EA.event_id								'Entity_Id',
	EA.event_num							'Entity_Desc',
	EDA.alternate_event_num					'Entity_Serial',
	COALESCE(ET.Applied_product,ED.PP_ID)	'Entity_Product_Id',
	COALESCE(PBT.prod_code,PB.prod_code)	'Entity_Product_code',
	COALESCE(PBT.prod_Desc,PB.prod_Desc)	'Entity_Product_desc',
	ED.PP_ID								'Entity_Process_order_Id',
	PP.process_order						'Entity_Process_order_desc',
	PP.BOM_Formulation_Id					'Entity_process_order_Form_Id',
	'Location transition'					'Entity_Activity',
	NULL									'Entity_Subactivity',
	PUBT.pu_id								'Entity_Activity_Location_Id',
	PUBT.pu_Desc							'Entity_Activity_Location_Desc',
	(SELECT Location_status FROM fnLocal_CTS_Location_Status(PUBT.pu_id,dateadd(second,-1,ET.start_time))) 'Entity_Activity_Location_status',
	(SELECT Process_order_Id FROM fnLocal_CTS_Location_Products(PUBT.pu_id, NULL,Q1.start_time)) 'Entity_Activity_Location_Process_order_id',
	(SELECT Process_order_desc FROM fnLocal_CTS_Location_Products(PUBT.pu_id,NULL,Q1.start_time)) 'Entity_Activity_Location_Process_order',
	(SELECT Product_Id FROM fnLocal_CTS_Location_Products(PUBT.pu_id,NULL,ET.start_time)) 'Entity_Activity_Location_product_id',
	(SELECT Product_code FROM fnLocal_CTS_Location_Products(PUBT.pu_id, NULL,ET.start_time)) 'Entity_Activity_Location_product_code',
	NULL,--(SELECT Location_Product_desc FROM fnLocal_CTS_Location_Products(PUBT.pu_id, NULL,ET.start_time)) 'Entity_Activity_Location_product_desc',
	ET.event_id								'Entity_Activity_id',
	ET.start_time							'Entity_Activity_Timestamp',
	ET.user_id								'Entity_Activity_User_Id',
	UB.username								'Entity_Activity_Username'
	FROM	dbo.event_components EC WITH(NOLOCK) 
			JOIN dbo.events ET WITH(NOLOCK) 
				ON ET.event_id = EC.event_id
			LEFT JOIN dbo.products_base PBT 
				ON PBT.prod_id = ET.applied_product
			JOIN dbo.users_base UB WITH(NOLOCK) 
				ON UB.user_id = EC.user_id
			JOIN dbo.events EA WITH(NOLOCK) 
				ON EA.event_id = EC.Source_event_id
			JOIN dbo.event_details EDA WITH(NOLOCK)
				ON EA.event_id = EDA.event_id
			JOIN dbo.event_details ED WITH(NOLOCK)
				ON ET.event_id = ED.event_id
			CROSS APPLY(SELECT *,ROW_NUMBER() OVER(PARTITION BY ETRANSST.event_id ORDER BY ETRANSST.Start_time ASC)  'Rownum'  
						FROM dbo.event_status_transitions ETRANSST WITH(NOLOCK)
						WHERE ETRANSST.event_id = ET.event_id)Q1
			JOIN dbo.production_status PS WITH(NOLOCK)
				ON PS.prodStatus_id = Q1.event_status
			JOIN dbo.prod_units_Base PUBA WITH(NOLOCK)
				ON PUBA.pu_id = EA.pu_id 
			JOIN dbo.prod_units_Base PUBT WITH(NOLOCK)
				ON PUBT.pu_id = ET.pu_id  
			LEFT JOIN dbo.production_plan PP WITH(NOLOCK)
				ON PP.PP_ID = ED.PP_ID
			LEFT JOIN dbo.products_base PB 
				ON PB.prod_id = PP.prod_id
			JOIN dbo.Table_Fields_Values TFV WITH(NOLOCK)
				ON PUBA.PU_id = TFV.KeyId
				AND TFV.Table_Field_Id = @tfIdApplianceType
	WHERE		ET.Start_Time >= @StartTime AND ET.timestamp < @EndTime			
				AND EC.source_event_id = @ApplianceId
				AND Q1.Rownum = 1
				ORDER BY EC.timestamp


	INSERT INTO	@Output
	(
	Entity_type,
	Entity_sub_type,	
	Entity_status,
	Entity_Id,
	Entity_Desc,
	Entity_Serial,
	Entity_Product_Id,
	Entity_Product_code,
	Entity_Product_desc,
	Entity_Process_order_Id,
	Entity_Process_order_desc,
	Entity_process_order_Form_Id,
	Entity_Activity,
	Entity_Subactivity,
	Entity_Activity_Location_Id,
	Entity_Activity_Location_Desc,
	Entity_Activity_Location_status,
	Entity_Activity_Location_Process_Id,	
	Entity_Activity_Location_Process_order,
	Entity_Activity_Location_Product_id,
	Entity_Activity_Location_Product_code,
	Entity_Activity_Location_Product_desc,
	Entity_Activity_id,
	Entity_Activity_Timestamp,
	Entity_Activity_User_Id,
	Entity_Activity_Username
	)

	SELECT		
	'Appliance'								'Entity_type',
	TFV.value								'Entity_sub_type',	
	PS.ProdStatus_Desc						'Entity_status',
	EA.event_id								'Entity_Id',
	EA.event_num							'Entity_Desc',
	EDA.alternate_event_num					'Entity_Serial',
	COALESCE(ET.Applied_product,ED.PP_ID)	'Entity_Product_Id',
	COALESCE(PBT.prod_code,PB.prod_code)	'Entity_Product_code',
	COALESCE(PBT.prod_Desc,PB.prod_Desc)	'Entity_Product_desc',
	ED.PP_ID								'Entity_Process_order_Id',
	PP.process_order						'Entity_Process_order_desc',
	PP.BOM_Formulation_Id					'Entity_process_order_Form_Id',
	'Status transition'						'Entity_Activity',
	NULL									'Entity_Subactivity',
	PUBT.pu_id								'Entity_Activity_Location_Id',
	PUBT.pu_Desc							'Entity_Activity_Location_Desc',
	(SELECT Location_status FROM fnLocal_CTS_Location_Status(PUBT.pu_id,dateadd(second,-1,ET.start_time))) 'Entity_Activity_Location_status',
	(SELECT Process_order_Id FROM fnLocal_CTS_Location_Products(PUBT.pu_id, NULL,Q1.start_time)) 'Entity_Activity_Location_Process_order_id',
	(SELECT Process_order_desc FROM fnLocal_CTS_Location_Products(PUBT.pu_id,NULL,Q1.start_time)) 'Entity_Activity_Location_Process_order',
	(SELECT Product_Id FROM fnLocal_CTS_Location_Products(PUBT.pu_id,NULL,ET.start_time)) 'Entity_Activity_Location_product_id',
	(SELECT Product_code FROM fnLocal_CTS_Location_Products(PUBT.pu_id, NULL,ET.start_time)) 'Entity_Activity_Location_product_code',
	NULL,--(SELECT Location_Product_desc FROM fnLocal_CTS_Location_Products(PUBT.pu_id, NULL,ET.start_time)) 'Entity_Activity_Location_product_desc',
	ET.event_id								'Entity_Activity_id',
	Q1.start_time							'Entity_Activity_Timestamp',
	ET.user_id								'Entity_Activity_User_Id',
	NULL									'Entity_Activity_Username'
	FROM	dbo.event_components EC WITH(NOLOCK) 
			JOIN dbo.events ET WITH(NOLOCK) 
				ON ET.event_id = EC.event_id
			JOIN dbo.products_base PBT 
				ON PBT.prod_id = ET.applied_product
			JOIN dbo.events EA WITH(NOLOCK) 
				ON EA.event_id = EC.Source_event_id
			JOIN dbo.event_details EDA WITH(NOLOCK)
				ON EA.event_id = EDA.event_id
			JOIN dbo.event_details ED WITH(NOLOCK)
				ON ET.event_id = ED.event_id
				CROSS APPLY(SELECT *,ROW_NUMBER() OVER(PARTITION BY ETRANSST.event_id ORDER BY ETRANSST.Start_time ASC)  'Rownum'  
							FROM dbo.event_status_transitions ETRANSST WITH(NOLOCK)
							WHERE ETRANSST.event_id = ET.event_id)Q1
			JOIN dbo.production_status PS WITH(NOLOCK)
				ON PS.prodStatus_id = Q1.event_status
			JOIN dbo.prod_units_Base PUBA WITH(NOLOCK)
				ON PUBA.pu_id = EA.pu_id 
			JOIN dbo.prod_units_Base PUBT WITH(NOLOCK)
				ON PUBT.pu_id = ET.pu_id  
			LEFT JOIN dbo.production_plan PP WITH(NOLOCK)
				ON PP.PP_ID = ED.PP_ID
			LEFT JOIN dbo.products_base PB 
				ON PB.prod_id = PP.prod_id
			JOIN dbo.Table_Fields_Values TFV WITH(NOLOCK)
				ON PUBA.PU_id = TFV.KeyId
				AND TFV.Table_Field_Id = @tfIdApplianceType

	WHERE	Q1.Start_Time >= @StartTime AND (Q1.end_time < @EndTime OR Q1.End_Time IS NULL)
			AND EC.source_event_id = @ApplianceId
			And Q1.Rownum > 1
	ORDER BY Q1.end_time desc


	/*
	DECLARE
	@ApplianceCleaningUDESubTypeId			VARCHAR(50),
	@ApplianceCleaningTypeVarId				INTEGER


	SET @ApplianceCleaningUDESubTypeId = 
	(
		SELECT	EST.event_Subtype_Id
		FROM	dbo.event_subtypes EST WITH(NOLOCK)
		WHERE	EST.event_Subtype_Desc = 'CTS Appliance Cleaning'
	)

	BEGIN
	INSERT INTO	@Output
	(
	Entity_type,
	Entity_sub_type,	
	Entity_status,
	Entity_Id,
	Entity_Desc,
	Entity_Serial,
	Entity_Product_Id,
	Entity_Product_code,
	Entity_Product_desc,
	Entity_Process_order_Id,
	Entity_Process_order_desc,
	Entity_process_order_Form_Id,
	Entity_Activity,
	Entity_Subactivity,
	Entity_Activity_Location_Id,
	Entity_Activity_Location_Desc,
	Entity_Activity_id,
	Entity_Activity_Timestamp,
	Entity_Activity_User_Id,
	Entity_Activity_Username
	)

	SELECT		
	'Appliance'								'Entity_type',
	TFV.value								'Entity_sub_type',	
	NULL									'Entity_status',
	EA.event_id								'Entity_Id',
	EA.event_num							'Entity_Desc',
	ED.alternate_event_num					'Entity_Serial',
	NULL									'Entity_Product_Id',
	NULL									'Entity_Product_code',
	NULL									'Entity_Product_desc',
	NULL									'Entity_Process_order_Id',
	NULL									'Entity_Process_order_desc',
	NULL									'Entity_process_order_Form_Id',
	'Appliance Cleaning'					'Entity_Activity',
	'Cleaning started - ' + T.Result		'Entity_SUBctivity',
	PUB1.pu_id								'Entity_Activity_Location_Id',
	PUB1.pu_Desc							'Entity_Activity_Location_Desc',
	UDE.UDE_ID								'Entity_Activity_id',
	UDE.start_time							'Entity_Activity_Timestamp',
	UB.user_id								'Entity_Activity_User_Id',
	UB.username								'Entity_Activity_Username'
	
	FROM	dbo.events EA WITH(NOLOCK)
			JOIN dbo.user_defined_events UDE WITH(NOLOCK)
				ON EA.event_Id = UDE.event_Id
			JOIN dbo.event_details ED WITH(NOLOCK)
				ON EA.event_id = ED.event_id
			JOIN dbo.Users_Base UB WITH(NOLOCK)
				ON UB.User_Id = UDE.User_Id
			LEFT JOIN dbo.ESignature ESIG WITH(NOLOCK)
				ON ESIG.Signature_Id = UDE.Signature_Id
			LEFT JOIN dbo.users_base UBPERF 
				ON UBPERF.user_id = ESIG.Perform_User_Id
			LEFT JOIN dbo.users_base UBVER 
				ON UBVER.user_id = ESIG.Verify_User_Id
			-- APPLIANCE TYPE UNIT
			JOIN dbo.prod_units_base PUB WITH(NOLOCK)
				ON PUB.pu_id = EA.pu_id
			JOIN dbo.Table_Fields_Values TFV WITH(NOLOCK)
				ON PUB.PU_id = TFV.KeyId
				AND TFV.Table_Field_Id = @tfIdApplianceType
			-- CLEANING LOCATION UNIT
			JOIN dbo.prod_units_base PUB1 ON PUB1.pu_id = UDE.PU_Id
			-- TYPE
			JOIN dbo.variables_Base VB WITH(NOLOCK) 
				ON VB.pu_id = PUB1.pu_id
				AND VB.Test_Name = 'Type'
			JOIN dbo.tests T WITH(NOLOCK)
				ON T.var_id = VB.var_id
					AND t.result_on = ude.end_time
	WHERE	UDE.event_Subtype_Id = 	@ApplianceCleaningUDESubTypeId
			AND UDE.start_time >= @StartTime AND UDE.End_Time < @EndTime
			AND EA.event_id = @ApplianceId
			AND VB.Test_Name = 'Type'
	ORDER 
	BY		UDE.Modified_on DESC--UDE.Modified_on DESC
END;


BEGIN --GET APPLIANCE CLEANINGS COMPLETE OR CANCELLED
	INSERT INTO	@Output
	(
	Entity_type,
	Entity_sub_type,	
	Entity_status,
	Entity_Id,
	Entity_Desc,
	Entity_Serial,
	Entity_Product_Id,
	Entity_Product_code,
	Entity_Product_desc,
	Entity_Process_order_Id,
	Entity_Process_order_desc,
	Entity_process_order_Form_Id,
	Entity_Activity,
	Entity_Subactivity,
	Entity_Activity_Location_Id,
	Entity_Activity_Location_Desc,
	Entity_Activity_id,
	Entity_Activity_Timestamp,
	Entity_Activity_User_Id,
	Entity_Activity_Username
	)
	SELECT		
	'Appliance'								'Entity_type',
	TFV.value								'Entity_sub_type',	
	NULL									'Entity_status',
	EA.event_id								'Entity_Id',
	EA.event_num							'Entity_Desc',
	ED.alternate_event_num					'Entity_Serial',
	NULL									'Entity_Product_Id',
	NULL									'Entity_Product_code',
	NULL									'Entity_Product_desc',
	NULL									'Entity_Process_order_Id',
	NULL									'Entity_Process_order_desc',
	NULL									'Entity_process_order_Form_Id',
	'Appliance cleaning'					'Entity_Activity',
	(CASE	PS.prodStatus_Desc
	WHEN	'CTS_Cleaning_Cancelled' 
	THEN	'Cleaning cancelled'
	ELSE	'Cleaning completed'
	END)									'Entity_Subactivity',
	PUB1.pu_id								'Entity_Activity_Location_Id',
	PUB1.pu_Desc							'Entity_Activity_Location_Desc',
	UDE.UDE_ID								'Entity_Activity_id',
	UDE.start_time							'Entity_Activity_Timestamp',
	UB.user_id								'Entity_Activity_User_Id',
	UB.username								'Entity_Activity_Username'
	FROM	dbo.events EA WITH(NOLOCK)
			JOIN dbo.user_defined_events UDE WITH(NOLOCK)
				ON EA.event_Id = UDE.event_Id
			JOIN  dbo.production_status PS WITH(NOLOCK) 
				ON PS.prodStatus_id = UDE.event_Status
			JOIN dbo.event_details ED WITH(NOLOCK)
				ON EA.event_id = ED.event_id
			JOIN dbo.Users_Base UB WITH(NOLOCK)
				ON UB.User_Id = UDE.User_Id
			LEFT JOIN dbo.ESignature ESIG WITH(NOLOCK)
				ON ESIG.Signature_Id = UDE.Signature_Id
			LEFT JOIN dbo.users_base UBPERF 
				ON UBPERF.user_id = ESIG.Perform_User_Id
			LEFT JOIN dbo.users_base UBVER 
				ON UBVER.user_id = ESIG.Verify_User_Id
			-- APPLIANCE TYPE UNIT
			JOIN dbo.prod_units_base PUB WITH(NOLOCK)
				ON PUB.pu_id = EA.pu_id
			JOIN dbo.Table_Fields_Values TFV WITH(NOLOCK)
				ON PUB.PU_id = TFV.KeyId
				AND TFV.Table_Field_Id = @tfIdApplianceType
			-- CLEANING LOCATION UNIT
			JOIN dbo.prod_units_base PUB1 ON PUB1.pu_id = UDE.PU_Id
			-- TYPE
			JOIN dbo.variables_Base VB WITH(NOLOCK) 
				ON VB.pu_id = PUB1.pu_id
				AND VB.Test_Name = 'Type'
			JOIN dbo.tests T WITH(NOLOCK)
				ON T.var_id = VB.var_id
					AND t.result_on = ude.end_time
	WHERE	UDE.event_Subtype_Id = 	@ApplianceCleaningUDESubTypeId
				AND UDE.start_time >= @StartTime AND UDE.End_Time < @EndTime
			AND EA.event_id = @ApplianceId
			AND VB.Test_Name = 'Type'
	ORDER 
	BY		UDE.Modified_on DESC--UDE.Modified_on DESC
END;


BEGIN	--GET APPLIANCE CLEANINGS COMPLETE CANCEL SIGNATURE
	INSERT INTO	@Output
	(
	Entity_type,
	Entity_sub_type,	
	Entity_status,
	Entity_Id,
	Entity_Desc,
	Entity_Serial,
	Entity_Product_Id,
	Entity_Product_code,
	Entity_Product_desc,
	Entity_Process_order_Id,
	Entity_Process_order_desc,
	Entity_process_order_Form_Id,
	Entity_Activity,
	Entity_Subactivity,
	Entity_Activity_Location_Id,
	Entity_Activity_Location_Desc,
	Entity_Activity_id,
	Entity_Activity_Timestamp,
	Entity_Activity_User_Id,
	Entity_Activity_Username
	)

	SELECT		
	'Appliance'								'Entity_type',
	TFV.value								'Entity_sub_type',	
	NULL									'Entity_status',
	EA.event_id								'Entity_Id',
	EA.event_num							'Entity_Desc',
	ED.alternate_event_num					'Entity_Serial',
	NULL									'Entity_Product_Id',
	NULL									'Entity_Product_code',
	NULL									'Entity_Product_desc',
	NULL									'Entity_Process_order_Id',
	NULL									'Entity_Process_order_desc',
	NULL									'Entity_process_order_Form_Id',
	'Appliance cleaning'					'Entity_Activity',
	(CASE	PS.prodStatus_Desc
	WHEN	'CTS_Cleaning_Cancelled' 
	THEN	'Cleaning cancelled signature'
	ELSE	'Cleaning completed signature'
	END)									'Entity_Subactivity',
	PUB1.pu_id								'Entity_Activity_Location_Id',
	PUB1.pu_Desc							'Entity_Activity_Location_Desc',
	UDE.UDE_ID								'Entity_Activity_id',
	UDE.start_time							'Entity_Activity_Timestamp',
	UB.user_id								'Entity_Activity_User_Id',
	UB.username								'Entity_Activity_Username'
	
	FROM	dbo.events EA WITH(NOLOCK)
			JOIN dbo.user_defined_events UDE WITH(NOLOCK)
				ON EA.event_Id = UDE.event_Id
			JOIN  dbo.production_status PS WITH(NOLOCK) 
				ON PS.prodStatus_id = UDE.event_Status
			JOIN dbo.event_details ED WITH(NOLOCK)
				ON EA.event_id = ED.event_id
			JOIN dbo.Users_Base UB WITH(NOLOCK)
				ON UB.User_Id = UDE.User_Id
			JOIN dbo.ESignature ESIG WITH(NOLOCK)
				ON ESIG.Signature_Id = UDE.Signature_Id
			JOIN dbo.users_base UBPERF 
				ON UBPERF.user_id = ESIG.Perform_User_Id
			JOIN dbo.users_base UBVER 
				ON UBVER.user_id = ESIG.Verify_User_Id
			-- APPLIANCE TYPE UNIT
			JOIN dbo.prod_units_base PUB WITH(NOLOCK)
				ON PUB.pu_id = EA.pu_id
			JOIN dbo.Table_Fields_Values TFV WITH(NOLOCK)
				ON PUB.PU_id = TFV.KeyId
				AND TFV.Table_Field_Id = @tfIdApplianceType
			-- CLEANING LOCATION UNIT
			JOIN dbo.prod_units_base PUB1 ON PUB1.pu_id = UDE.PU_Id
			-- CLEANING LOCATION PO
			LEFT JOIN dbo.production_plan_starts PPS WITH(NOLOCK) 
				ON PPS.pu_id = PUB1.pu_id 
				AND UDE.End_time >= PPS.Start_time  AND (UDE.Start_time < PPS.end_time OR PPS.end_time  IS NULL)
			LEFT JOIN dbo.production_plan PP WITH(NOLOCK)
				ON PP.PP_ID = PPS.PP_ID
			LEFT JOIN dbo.products_base PB 
				ON PB.prod_id = PP.prod_id
			-- TYPE
			JOIN dbo.variables_Base VB WITH(NOLOCK) 
				ON VB.pu_id = PUB1.pu_id
				AND VB.Test_Name = 'Type'
			JOIN dbo.tests T WITH(NOLOCK)
				ON T.var_id = VB.var_id
					AND t.result_on = ude.end_time
	WHERE	UDE.event_Subtype_Id = 	@ApplianceCleaningUDESubTypeId
				AND UDE.start_time >= @StartTime AND UDE.End_Time < @EndTime
			AND EA.event_id = @ApplianceId
			AND VB.Test_Name = 'Type'

	ORDER 
	BY		UDE.Modified_on DESC--UDE.Modified_on DESC
END;


BEGIN	-- GET APPPLIANCE CLEANING REJECT APPROVE SIGNATURE

	INSERT INTO	@Output
	(
	Entity_type,
	Entity_sub_type,	
	Entity_status,
	Entity_Id,
	Entity_Desc,
	Entity_Serial,
	Entity_Product_Id,
	Entity_Product_code,
	Entity_Product_desc,
	Entity_Process_order_Id,
	Entity_Process_order_desc,
	Entity_process_order_Form_Id,
	Entity_Activity,
	Entity_Subactivity,
	Entity_Activity_Location_Id,
	Entity_Activity_Location_Desc,
	Entity_Activity_id,
	Entity_Activity_Timestamp,
	Entity_Activity_User_Id,
	Entity_Activity_Username
	)

	SELECT		
	'Appliance'								'Entity_type',
	TFV.value								'Entity_sub_type',	
	NULL									'Entity_status',
	EA.event_id								'Entity_Id',
	EA.event_num							'Entity_Desc',
	ED.alternate_event_num					'Entity_Serial',
	NULL									'Entity_Product_Id',
	NULL									'Entity_Product_code',
	NULL									'Entity_Product_desc',
	NULL									'Entity_Process_order_Id',
	NULL									'Entity_Process_order_desc',
	NULL									'Entity_process_order_Form_Id',
	'Appliance cleaning'					'Entity_Activity',
	(CASE	PS.prodStatus_Desc			
	WHEN	'CTS_Cleaning_Rejected' 
	THEN	'Cleaning rejected signature'
	ELSE	'Cleaning approved signature'
	END)									'Entity_Subactivity',
	PUB1.pu_id								'Entity_Activity_Location_Id',
	PUB1.pu_Desc							'Entity_Activity_Location_Desc',
	UDE.UDE_ID								'Entity_Activity_id',
	UDE.start_time							'Entity_Activity_Timestamp',
	UB.user_id								'Entity_Activity_User_Id',
	UB.username								'Entity_Activity_Username'

	
	FROM	dbo.events EA WITH(NOLOCK)
			JOIN dbo.user_defined_events UDE WITH(NOLOCK)
				ON EA.event_Id = UDE.event_Id
			JOIN  dbo.production_status PS WITH(NOLOCK) 
				ON PS.prodStatus_id = UDE.event_Status
			JOIN dbo.event_details ED WITH(NOLOCK)
				ON EA.event_id = ED.event_id
			JOIN dbo.Users_Base UB WITH(NOLOCK)
				ON UB.User_Id = UDE.User_Id
			JOIN dbo.ESignature ESIG WITH(NOLOCK)
				ON ESIG.Signature_Id = UDE.Signature_Id
			JOIN dbo.users_base UBPERF 
				ON UBPERF.user_id = ESIG.Perform_User_Id
			JOIN dbo.users_base UBVER 
				ON UBVER.user_id = ESIG.Verify_User_Id
			-- APPLIANCE TYPE UNIT
			JOIN dbo.prod_units_base PUB WITH(NOLOCK)
				ON PUB.pu_id = EA.pu_id
			JOIN dbo.Table_Fields_Values TFV WITH(NOLOCK)
				ON PUB.PU_id = TFV.KeyId
				AND TFV.Table_Field_Id = @tfIdApplianceType
			-- CLEANING LOCATION UNIT
			JOIN dbo.prod_units_base PUB1 ON PUB1.pu_id = UDE.PU_Id
			-- CLEANING LOCATION PO
			LEFT JOIN dbo.production_plan_starts PPS WITH(NOLOCK) 
				ON PPS.pu_id = PUB1.pu_id 
				AND UDE.End_time >= PPS.Start_time  AND (UDE.Start_time < PPS.end_time OR PPS.end_time  IS NULL)
			LEFT JOIN dbo.production_plan PP WITH(NOLOCK)
				ON PP.PP_ID = PPS.PP_ID
			LEFT JOIN dbo.products_base PB 
				ON PB.prod_id = PP.prod_id
			-- TYPE
			JOIN dbo.variables_Base VB WITH(NOLOCK) 
				ON VB.pu_id = PUB1.pu_id
				AND VB.Test_Name = 'Type'
			JOIN dbo.tests T WITH(NOLOCK)
				ON T.var_id = VB.var_id
					AND t.result_on = ude.end_time
	WHERE	UDE.event_Subtype_Id = 	@ApplianceCleaningUDESubTypeId
					AND UDE.start_time >= @StartTime AND UDE.End_Time < @EndTime
			AND EA.event_id = @ApplianceId
			AND VB.Test_Name = 'Type'

	ORDER 
	BY		UDE.Modified_on DESC--UDE.Modified_on DESC

END;
*/
	RETURN	
END
