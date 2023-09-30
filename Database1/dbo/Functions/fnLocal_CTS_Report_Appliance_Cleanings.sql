

--------------------------------------------------------------------------------------------------
-- Table function: fnLocal_CTS_Report_Appliance_Cleanings
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

SELECT * FROM [fnLocal_CTS_Report_Appliance_Cleanings](1031429, '1-jan-2022', '23-feb-2022') order by Entity_Activity_Timestamp asc

*/


CREATE FUNCTION [dbo].[fnLocal_CTS_Report_Appliance_Cleanings]
(
@ApplianceId										INTEGER,
@StartTime											DATETIME = NULL,
@EndTime											DATETIME = NULL
)

RETURNS @Output TABLE 
(
	Entity_type									VARCHAR(25),
	Entity_sub_type								VARCHAR(25),	
	Entity_status								VARCHAR(50),
	Entity_id									INTEGER,
	Entity_desc									VARCHAR(50),
	Entity_serial								VARCHAR(50),
	Entity_product_id							INTEGER,
	Entity_product_code							VARCHAR(100),
	Entity_product_desc							VARCHAR(100),
	Entity_Process_order_Id						INTEGER,
	Entity_Process_order_desc					VARCHAR(50),
	Entity_process_order_Form_Id				INTEGER,
	Entity_Activity_id							INTEGER,
	Entity_Activity_desc						VARCHAR(100),
	Entity_Subactivity_desc						VARCHAR(100),
	Entity_Activity_Timestamp					DATETIME,
	Entity_Activity_User_Id						INTEGER,
	Entity_Activity_Username					VARCHAR(100),
	Entity_Activity_location_id					INTEGER,
	Entity_Activity_Location_desc				VARCHAR(50),
	Entity_Activity_Comment_Id					INTEGER
)

AS
BEGIN
DECLARE
@ApplianceCleaningUDESubTypeId					VARCHAR(50),
@ApplianceCleaningTypeVarId						INTEGER,
@TableIdProdUnit								INTEGER,
@tfIdApplianceType								INTEGER,
@tfIdLocationSerial								INTEGER,
@tfIdLocationType								INTEGER


SET @TableIdProdUnit = (SELECT tableId FROM dbo.Tables WITH(NOLOCK) WHERE TableName = 'Prod_Units'	)
SET @tfIdApplianceType = (	SELECT table_field_id FROM dbo.Table_Fields WITH(NOLOCK) WHERE TableId = @TableIdProdUnit AND Table_Field_Desc = 'CTS Appliance type')
SET @tfIdLocationSerial = (	SELECT table_field_id FROM dbo.Table_Fields WITH(NOLOCK) WHERE TableId = @TableIdProdUnit AND Table_Field_Desc = 'CTS Location serial number')	
SET @tfIdLocationType = (	SELECT table_field_id FROM dbo.Table_Fields WITH(NOLOCK) WHERE TableId = @TableIdProdUnit AND Table_Field_Desc = 'CTS location Type')	

SET @ApplianceCleaningUDESubTypeId = 
(
	SELECT	EST.event_Subtype_Id
	FROM	dbo.event_subtypes EST WITH(NOLOCK)
	WHERE	EST.event_Subtype_Desc = 'CTS Appliance Cleaning'
)



BEGIN -- GET APPLIANCE CLEANINGS START

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
	Entity_Activity_Desc,
	Entity_Subactivity_desc,
	Entity_Activity_Location_Id,
	Entity_Activity_Location_Desc,
	Entity_Activity_id,
	Entity_Activity_Timestamp,
	Entity_Activity_User_Id,
	Entity_Activity_Username,
	Entity_Activity_Comment_Id
	)

	SELECT		
	'Appliance',							--'Entity_type',
	TFV.value,								--'Entity_sub_type',	
	PS.prodstatus_desc,						--'Entity_status',
	EA.event_id,							--'Entity_Id',
	EA.event_num,							--'Entity_Desc',
	EDA.alternate_event_num,					--'Entity_Serial',
	PB.prod_id,								--'Entity_Product_Id',
	PB.prod_Code,							--'Entity_Product_code',
	PB.prod_desc,							--'Entity_Product_desc',
	PP.PP_id,								--'Entity_Process_order_Id',
	PP.Process_order,						--'Entity_Process_order_desc',
	PP.BOM_Formulation_id,					--'Entity_process_order_Form_Id',
	'Appliance Cleaning',					--'Entity_Activity',
	'Cleaning started - ' + T.Result,		--'Entity_SUBctivity',
	PUB1.pu_id,								--'Entity_Activity_Location_Id',
	PUB1.pu_Desc,							--'Entity_Activity_Location_Desc',
	UDE.UDE_ID,								--'Entity_Activity_id',
	UDE.start_time,							--'Entity_Activity_Timestamp',
	UB.user_id,								--'Entity_Activity_User_Id',
	UB.username,							--'Entity_Activity_Username'
	UDE.Comment_id							--'Entity_Activity_Comment_Id'
	
	FROM	dbo.events EA WITH(NOLOCK)
			JOIN dbo.user_defined_events UDE WITH(NOLOCK)
				ON EA.event_Id = UDE.event_Id
			JOIN dbo.event_details EDA WITH(NOLOCK)
				ON EA.event_id = EDA.event_id
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
			CROSS APPLY(SELECT 
						TOP 1	ECn.event_id,ED.PP_ID,E.applied_product 
						FROM	dbo.event_components ECn WITH(NOLOCK) 
								JOIN dbo.event_details ED WITH(NOLOCK) 
									ON ED.event_id = ECn.event_id
								JOIN dbo.events E WITH(NOLOCK) 
									ON E.event_id = ECn.event_id
						WHERE	ECn.source_event_id = EA.event_id 
								AND ECn.timestamp < UDE.start_time 
						ORDER 
						BY		ECn.timestamp DESC) Q1 
			LEFT JOIN dbo.production_plan PP WITH(NOLOCK)
				ON PP.PP_Id = Q1.PP_ID
			LEFT JOIN dbo.products_base PB WITH(NOLOCK)
				ON PB.prod_id = COALESCE(PP.prod_id,Q1.applied_product)
			CROSS APPLY(SELECT *,ROW_NUMBER() OVER(PARTITION BY ETRANSST.event_id ORDER BY ETRANSST.Start_time ASC)  'Rownum'  
						FROM dbo.event_status_transitions ETRANSST WITH(NOLOCK)
						WHERE ETRANSST.event_id = Q1.event_id
						AND ETRANSST.start_time<= UDE.start_time)Q2
			JOIN dbo.production_status PS WITH(NOLOCK)
				ON PS.prodStatus_id = Q2.event_status
	WHERE	UDE.event_Subtype_Id = 	@ApplianceCleaningUDESubTypeId
			AND UDE.start_time >= @StartTime AND UDE.End_Time < @EndTime
			AND EA.event_id = @ApplianceId
			AND VB.Test_Name = 'Type'
			AND Q2.Rownum = 1
	ORDER 
	BY		UDE.Modified_on DESC--UDE.Modified_on DESC
END;

return

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
	Entity_Activity_Desc,
	Entity_Subactivity_desc,
	Entity_Activity_Location_Id,
	Entity_Activity_Location_Desc,
	Entity_Activity_id,
	Entity_Activity_Timestamp,
	Entity_Activity_User_Id,
	Entity_Activity_Username,
	Entity_Activity_Comment_Id
	)

	SELECT	DISTINCT	
	'Appliance',							--'Entity_type',
	TFV.value,								--'Entity_sub_type',	
	NULL,									--'Entity_status',
	EA.event_id,							--'Entity_Id',
	EA.event_num,							--'Entity_Desc',
	ED.alternate_event_num,					--'Entity_Serial',
	PB.prod_id,								--'Entity_Product_Id',
	PB.prod_Code,							--'Entity_Product_code',
	PB.prod_desc,							--'Entity_Product_desc',
	PP.PP_id,								--'Entity_Process_order_Id',
	PP.Process_order,						--'Entity_Process_order_desc',
	PP.BOM_Formulation_id,					--'Entity_process_order_Form_Id',
	'Appliance cleaning',					--'Entity_Activity',
	(CASE	PS.prodStatus_Desc
	WHEN	'CTS_Cleaning_Cancelled' 
	THEN	'Cleaning cancelled'
	ELSE	'Cleaning completed'
	END),									--'Entity_Subactivity',
	PUB1.pu_id,								--'Entity_Activity_Location_Id',
	PUB1.pu_Desc,							--'Entity_Activity_Location_Desc',
	UDE.UDE_ID,								--'Entity_Activity_id',
	UDE.End_time,							--'Entity_Activity_Timestamp',
	UB.user_id,								--'Entity_Activity_User_Id',
	UB.username,							--'Entity_Activity_Username'
	UDE.Comment_id							--'Entity_Activity_Comment_Id'
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
			CROSS APPLY(SELECT 
						TOP 1	ECn.event_id,ED.PP_ID,E.applied_product 
						FROM	dbo.event_components ECn WITH(NOLOCK) 
								JOIN dbo.event_details ED WITH(NOLOCK) 
									ON ED.event_id = ECn.event_id
								JOIN dbo.events E WITH(NOLOCK) 
									ON E.event_id = ECn.event_id
						WHERE	ECn.source_event_id = EA.event_id 
								AND ECn.timestamp < UDE.End_time 
						ORDER 
						BY		ECn.timestamp DESC) Q1 
			LEFT JOIN dbo.production_plan PP WITH(NOLOCK)
				ON PP.PP_Id = Q1.PP_ID
			LEFT JOIN dbo.products_base PB WITH(NOLOCK)
				ON PB.prod_id = COALESCE(PP.prod_id,Q1.applied_product)
					AND t.result_on = ude.end_time
	WHERE	UDE.event_Subtype_Id = 	@ApplianceCleaningUDESubTypeId
				AND UDE.start_time >= @StartTime AND UDE.End_Time < @EndTime
			AND EA.event_id = @ApplianceId
			AND VB.Test_Name = 'Type'


END;

/*
BEGIN --GET APPLIANCE CLEANINGS COMPLETE OR CANCELLED
	INSERT INTO	@Entity_transactions_app
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
			AND EA.event_id = @Appliance_Id
			AND VB.Test_Name = 'Type'
	ORDER 
	BY		UDE.Modified_on DESC--UDE.Modified_on DESC
END;


BEGIN	--GET APPLIANCE CLEANINGS COMPLETE CANCEL SIGNATURE
	INSERT INTO	@Entity_transactions_app
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
			AND EA.event_id = @Appliance_Id
			AND VB.Test_Name = 'Type'

	ORDER 
	BY		UDE.Modified_on DESC--UDE.Modified_on DESC
END;


BEGIN	-- GET APPPLIANCE CLEANING REJECT APPROVE SIGNATURE

	INSERT INTO	@Entity_transactions_app
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
			AND EA.event_id = @Appliance_Id
			AND VB.Test_Name = 'Type'

	ORDER 
	BY		UDE.Modified_on DESC--UDE.Modified_on DESC

END;



























BEGIN -- GET LOCATION Cleaning start time
	INSERT INTO	@output
	(
	Entity_type,
	Entity_sub_type,	
	Entity_status,
	Entity_id,
	Entity_desc,
	Entity_serial,
	Entity_product_id,
	Entity_product_code,
	Entity_product_desc,
	Entity_Process_order_Id,
	Entity_Process_order_desc,
	Entity_process_order_Form_Id,
	Entity_Activity_id,
	Entity_Activity_desc,
	Entity_Subactivity_desc,
	Entity_Activity_Timestamp,
	Entity_Activity_User_Id,
	Entity_Activity_Username,
	Entity_Activity_comment_Id
	)

	SELECT		
	'Location',								--Entity_type
	TFV1.value,								--Entity_sub_type'
	(SELECT location_status 
	FROM dbo.fnlocal_CTS_Location_status(UDE.PU_id, UDE.start_time)),	--Entity_status
	PUB.pu_id,								--Entity_id
	PUB.pu_desc,							--Entity_desc
	TFV.value,								--Entity_serial
	(SELECT Product_Id 
	FROM dbo.fnlocal_CTS_Location_products(UDE.PU_id, NULL, UDE.start_time)), --Entity_product_is
	(SELECT product_code
	FROM dbo.fnlocal_CTS_Location_products(UDE.PU_id, NULL, UDE.start_time)), --Entity_product_code
	(SELECT product_desc
	FROM dbo.fnlocal_CTS_Location_products(UDE.PU_id, NULL, UDE.start_time)), --Entity_product_desc
	(SELECT Process_order_Id
	FROM dbo.fnlocal_CTS_Location_products(UDE.PU_id, NULL, UDE.start_time)), --Entity_Process_order_Id
	(SELECT Process_order_desc 
	FROM dbo.fnlocal_CTS_Location_products(UDE.PU_id, NULL, UDE.start_time)), --Entity_Process_order_desc
	(SELECT Process_order_formulation_id 
	FROM dbo.fnlocal_CTS_Location_products(UDE.PU_id, NULL, UDE.start_time)), --Entity_process_order_Form_Id
	UDE.UDE_ID,								--Entity_Activity_id
	'Location cleaning',					--Entity_Activity
	'Cleaning started - ' + T.Result,		--Entity_Subactivity
	UDE.start_time,							--Entity_Activity_Timestamp
	UB.user_id,								--Entity_Activity_User_Id
	UB.username,							--Entity_Activity_Username
	UDE.comment_id							--Entity_Activity_Comment_id

	
	FROM	dbo.user_defined_events UDE WITH(NOLOCK)
			JOIN  dbo.production_status PS WITH(NOLOCK) 
				ON PS.prodStatus_id = UDE.event_Status
			JOIN dbo.Users_Base UB WITH(NOLOCK)
				ON UB.User_Id = UDE.User_Id
			JOIN dbo.prod_units_base PUB WITH(NOLOCK)
				ON PUB.PU_ID = UDE.PU_ID
			JOIN dbo.Table_Fields_Values TFV WITH(NOLOCK)
				ON PUB.PU_id = TFV.KeyId
				AND TFV.Table_Field_Id = @tfIdLocationSerial
			JOIN dbo.Table_Fields_Values TFV1 WITH(NOLOCK)
				ON PUB.PU_id = TFV1.KeyId
				AND TFV1.Table_Field_Id = @tfIdLocationType	
			-- TYPE
			JOIN dbo.variables_Base VB WITH(NOLOCK) 
				ON VB.pu_id = PUB.pu_id
				AND VB.Test_Name = 'Type'
			JOIN dbo.tests T WITH(NOLOCK)
				ON T.var_id = VB.var_id
					AND t.result_on = UDE.end_time
	WHERE	UDE.event_Subtype_Id = 	@LocationCleaningUDESubTypeId
			AND VB.Test_Name = 'Type'
			AND UDE.pu_id = @locationid
	ORDER 
	BY		UDE.pu_id, UDE.start_time

END;
	



BEGIN	--GET COMPLETE OR CANCELLED
	INSERT INTO	@output
	(
	Entity_type,
	Entity_sub_type,	
	Entity_status,
	Entity_id,
	Entity_desc,
	Entity_serial,
	Entity_product_id,
	Entity_product_code,
	Entity_product_desc,
	Entity_Process_order_Id,
	Entity_Process_order_desc,
	Entity_process_order_Form_Id,
	Entity_Activity_id,
	Entity_Activity_desc,
	Entity_Subactivity_desc,
	Entity_Activity_Timestamp,
	Entity_Activity_User_Id,
	Entity_Activity_Username,
	Entity_Activity_comment_Id
	)

	SELECT		
	'Location',								--Entity_type
	TFV1.value,								--Entity_sub_type'
	(SELECT location_status 
	FROM dbo.fnlocal_CTS_Location_status(UDE.PU_id, UDE.start_time)),	--Entity_status
	PUB.pu_id,								--Entity_id
	PUB.pu_desc,							--Entity_desc
	TFV.value,								--Entity_serial
	(SELECT Product_Id 
	FROM dbo.fnlocal_CTS_Location_products(UDE.PU_id, NULL, UDE.start_time)), --Entity_product_is
	(SELECT product_code
	FROM dbo.fnlocal_CTS_Location_products(UDE.PU_id, NULL, UDE.start_time)), --Entity_product_code
	(SELECT product_desc
	FROM dbo.fnlocal_CTS_Location_products(UDE.PU_id, NULL, UDE.start_time)), --Entity_product_desc
	(SELECT Process_order_Id
	FROM dbo.fnlocal_CTS_Location_products(UDE.PU_id, NULL, UDE.start_time)), --Entity_Process_order_Id
	(SELECT Process_order_desc 
	FROM dbo.fnlocal_CTS_Location_products(UDE.PU_id, NULL, UDE.start_time)), --Entity_Process_order_desc
	(SELECT Process_order_formulation_id 
	FROM dbo.fnlocal_CTS_Location_products(UDE.PU_id, NULL, UDE.start_time)), --Entity_process_order_Form_Id
	UDE.UDE_ID,								--Entity_Activity_id
	'Location cleaning',					--Entity_Activity
	(CASE	PS.prodStatus_Desc
	WHEN	'CTS_Cleaning_Cancelled' 
	THEN	'Cleaning cancelled'
	ELSE	'Cleaning completed'
	END),									--Entity_Subactivity
	UDE.start_time,							--Entity_Activity_Timestamp
	UB.user_id,								--Entity_Activity_User_Id
	UB.username,							--Entity_Activity_Username
	UDE.comment_id							--Entity_Activity_Comment_id
	
	FROM	dbo.user_defined_events UDE WITH(NOLOCK)
			JOIN  dbo.production_status PS WITH(NOLOCK) 
				ON PS.prodStatus_id = UDE.event_Status
			JOIN dbo.Users_Base UB WITH(NOLOCK)
				ON UB.User_Id = UDE.User_Id
			JOIN dbo.prod_units_base PUB WITH(NOLOCK)
				ON PUB.PU_ID = UDE.PU_ID
			JOIN dbo.Table_Fields_Values TFV WITH(NOLOCK)
				ON PUB.PU_id = TFV.KeyId
				AND TFV.Table_Field_Id = @tfIdLocationSerial
			JOIN dbo.Table_Fields_Values TFV1 WITH(NOLOCK)
				ON PUB.PU_id = TFV1.KeyId
				AND TFV1.Table_Field_Id = @tfIdLocationType	
			-- TYPE
			JOIN dbo.variables_Base VB WITH(NOLOCK) 
				ON VB.pu_id = PUB.pu_id
				AND VB.Test_Name = 'Type'
			JOIN dbo.tests T WITH(NOLOCK)
				ON T.var_id = VB.var_id
					AND t.result_on = UDE.end_time
	WHERE	UDE.event_Subtype_Id = 	@LocationCleaningUDESubTypeId
			AND VB.Test_Name = 'Type'
			AND UDE.pu_id = @locationid
				AND UDE.start_time >= @StartTime AND UDE.End_Time < @EndTime
	ORDER 
	BY		UDE.pu_id, UDE.start_time
END;

BEGIN		--GET COMPLETE CANCEL SIGNATURE
	INSERT INTO	@output
	(
Entity_type,
	Entity_sub_type,	
	Entity_status,
	Entity_id,
	Entity_desc,
	Entity_serial,
	Entity_product_id,
	Entity_product_code,
	Entity_product_desc,
	Entity_Process_order_Id,
	Entity_Process_order_desc,
	Entity_process_order_Form_Id,
	Entity_Activity_id,
	Entity_Activity_desc,
	Entity_Subactivity_desc,
	Entity_Activity_Timestamp,
	Entity_Activity_User_Id,
	Entity_Activity_Username,
	Entity_Activity_comment_Id
	)

	SELECT		
	'Location',								--Entity_type
	TFV1.value,								--Entity_sub_type'
	(SELECT location_status 
	FROM dbo.fnlocal_CTS_Location_status(UDE.PU_id, UDE.start_time)),	--Entity_status
	PUB.pu_id,								--Entity_id
	PUB.pu_desc,							--Entity_desc
	TFV.value,								--Entity_serial
	(SELECT Product_Id 
	FROM dbo.fnlocal_CTS_Location_products(UDE.PU_id, NULL, UDE.start_time)), --Entity_product_is
	(SELECT product_code
	FROM dbo.fnlocal_CTS_Location_products(UDE.PU_id, NULL, UDE.start_time)), --Entity_product_code
	(SELECT product_desc
	FROM dbo.fnlocal_CTS_Location_products(UDE.PU_id, NULL, UDE.start_time)), --Entity_product_desc
	(SELECT Process_order_Id
	FROM dbo.fnlocal_CTS_Location_products(UDE.PU_id, NULL, UDE.start_time)), --Entity_Process_order_Id
	(SELECT Process_order_desc 
	FROM dbo.fnlocal_CTS_Location_products(UDE.PU_id, NULL, UDE.start_time)), --Entity_Process_order_desc
	(SELECT Process_order_formulation_id 
	FROM dbo.fnlocal_CTS_Location_products(UDE.PU_id, NULL, UDE.start_time)), --Entity_process_order_Form_Id
	UDE.UDE_ID,								--Entity_Activity_id
	'Location cleaning',					--Entity_Activity
	(CASE	PS.prodStatus_Desc
	WHEN	'CTS_Cleaning_Cancelled' 
	THEN	'Cleaning cancelled signature'
	ELSE	'Cleaning completed signature'
	END),									--Entity_Subactivity
	UDE.start_time,							--Entity_Activity_Timestamp
	UB.user_id,								--Entity_Activity_User_Id
	UB.username,							--Entity_Activity_Username
	UDE.comment_id							--Entity_Activity_Comment_id
	
	FROM	dbo.user_defined_events UDE WITH(NOLOCK)
			JOIN  dbo.production_status PS WITH(NOLOCK) 
				ON PS.prodStatus_id = UDE.event_Status
			JOIN dbo.Users_Base UB WITH(NOLOCK)
				ON UB.User_Id = UDE.User_Id
			JOIN dbo.prod_units_base PUB WITH(NOLOCK)
				ON PUB.PU_ID = UDE.PU_ID
			JOIN dbo.Table_Fields_Values TFV WITH(NOLOCK)
				ON PUB.PU_id = TFV.KeyId
				AND TFV.Table_Field_Id = @tfIdLocationSerial
			JOIN dbo.Table_Fields_Values TFV1 WITH(NOLOCK)
				ON PUB.PU_id = TFV1.KeyId
				AND TFV1.Table_Field_Id = @tfIdLocationType	
			-- TYPE
			JOIN dbo.variables_Base VB WITH(NOLOCK) 
				ON VB.pu_id = PUB.pu_id
				AND VB.Test_Name = 'Type'
			JOIN dbo.tests T WITH(NOLOCK)
				ON T.var_id = VB.var_id
					AND t.result_on = UDE.end_time
	WHERE	UDE.event_Subtype_Id = 	@LocationCleaningUDESubTypeId
			AND VB.Test_Name = 'Type'
			AND UDE.pu_id = @locationid
				AND UDE.start_time >= @StartTime AND UDE.End_Time < @EndTime
	ORDER 
	BY		UDE.pu_id, UDE.start_time
END;

BEGIN	--GET REJECT APPROVE SIGNATURE
	INSERT INTO	@output
	(
	Entity_type,
	Entity_sub_type,	
	Entity_status,
	Entity_id,
	Entity_desc,
	Entity_serial,
	Entity_product_id,
	Entity_product_code,
	Entity_product_desc,
	Entity_Process_order_Id,
	Entity_Process_order_desc,
	Entity_process_order_Form_Id,
	Entity_Activity_id,
	Entity_Activity_desc,
	Entity_Subactivity_desc,
	Entity_Activity_Timestamp,
	Entity_Activity_User_Id,
	Entity_Activity_Username,
	Entity_Activity_comment_Id
	)

	SELECT		
	'Location',								--Entity_type
	TFV1.value,								--Entity_sub_type'
	(SELECT location_status 
	FROM dbo.fnlocal_CTS_Location_status(UDE.PU_id, UDE.start_time)),	--Entity_status
	PUB.pu_id,								--Entity_id
	PUB.pu_desc,							--Entity_desc
	TFV.value,								--Entity_serial
	(SELECT Product_Id 
	FROM dbo.fnlocal_CTS_Location_products(UDE.PU_id, NULL, UDE.start_time)), --Entity_product_is
	(SELECT product_code
	FROM dbo.fnlocal_CTS_Location_products(UDE.PU_id, NULL, UDE.start_time)), --Entity_product_code
	(SELECT product_desc
	FROM dbo.fnlocal_CTS_Location_products(UDE.PU_id, NULL, UDE.start_time)), --Entity_product_desc
	(SELECT Process_order_Id
	FROM dbo.fnlocal_CTS_Location_products(UDE.PU_id, NULL, UDE.start_time)), --Entity_Process_order_Id
	(SELECT Process_order_desc 
	FROM dbo.fnlocal_CTS_Location_products(UDE.PU_id, NULL, UDE.start_time)), --Entity_Process_order_desc
	(SELECT Process_order_formulation_id 
	FROM dbo.fnlocal_CTS_Location_products(UDE.PU_id, NULL, UDE.start_time)), --Entity_process_order_Form_Id
	UDE.UDE_ID,								--Entity_Activity_id
	'Location cleaning',						--Entity_Activity
	(CASE	PS.prodStatus_Desc
	WHEN	'CTS_Cleaning_Rejected' 
	THEN	'Cleaning rejected signature'
	ELSE	'Cleaning approved signature'
	END),									--Entity_Subactivity,
	UDE.start_time,							--Entity_Activity_Timestamp
	UB.user_id,								--Entity_Activity_User_Id
	UB.username,							--Entity_Activity_Username
	UDE.comment_id							--Entity_Activity_Comment_id
	
	FROM	dbo.user_defined_events UDE WITH(NOLOCK)
			JOIN  dbo.production_status PS WITH(NOLOCK) 
				ON PS.prodStatus_id = UDE.event_Status
			JOIN dbo.Users_Base UB WITH(NOLOCK)
				ON UB.User_Id = UDE.User_Id
			JOIN dbo.prod_units_base PUB WITH(NOLOCK)
				ON PUB.PU_ID = UDE.PU_ID
			JOIN dbo.Table_Fields_Values TFV WITH(NOLOCK)
				ON PUB.PU_id = TFV.KeyId
				AND TFV.Table_Field_Id = @tfIdLocationSerial
			JOIN dbo.Table_Fields_Values TFV1 WITH(NOLOCK)
				ON PUB.PU_id = TFV1.KeyId
				AND TFV1.Table_Field_Id = @tfIdLocationType	
			-- TYPE
			JOIN dbo.variables_Base VB WITH(NOLOCK) 
				ON VB.pu_id = PUB.pu_id
				AND VB.Test_Name = 'Type'
			JOIN dbo.tests T WITH(NOLOCK)
				ON T.var_id = VB.var_id
					AND t.result_on = UDE.end_time
	WHERE	UDE.event_Subtype_Id = 	@LocationCleaningUDESubTypeId
			AND VB.Test_Name = 'Type'
			AND UDE.pu_id = @locationid
				AND UDE.start_time >= @StartTime AND UDE.End_Time < @EndTime
	ORDER 
	BY		UDE.pu_id, UDE.start_time
END;

*/

	RETURN	
END
