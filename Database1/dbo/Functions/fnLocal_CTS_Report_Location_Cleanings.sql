

--------------------------------------------------------------------------------------------------
-- Table function: fnLocal_CTS_Report_Location_Cleanings
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

SELECT * FROM [fnLocal_CTS_Report_Location_Cleanings](8451, '20-feb-2022', '23-feb-2022') order by Entity_Activity_Timestamp asc

*/


CREATE FUNCTION [dbo].[fnLocal_CTS_Report_Location_Cleanings]
(
@LocationId											INTEGER,
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
	Entity_Activity_comment_Id					INTEGER
)

AS
BEGIN
DECLARE
@LocationCleaningUDESubTypeId					VARCHAR(50),
@locationCleaningTypeVarId						INTEGER,
@TableIdProdUnit								INTEGER,
@tfIdApplianceType								INTEGER,
@tfIdLocationSerial								INTEGER,
@tfIdLocationType								INTEGER


SET @TableIdProdUnit = (SELECT tableId FROM dbo.Tables WITH(NOLOCK) WHERE TableName = 'Prod_Units'	)
SET @tfIdApplianceType = (	SELECT table_field_id FROM dbo.Table_Fields WITH(NOLOCK) WHERE TableId = @TableIdProdUnit AND Table_Field_Desc = 'CTS Appliance type')
SET @tfIdLocationSerial = (	SELECT table_field_id FROM dbo.Table_Fields WITH(NOLOCK) WHERE TableId = @TableIdProdUnit AND Table_Field_Desc = 'CTS Location serial number')	
SET @tfIdLocationType = (	SELECT table_field_id FROM dbo.Table_Fields WITH(NOLOCK) WHERE TableId = @TableIdProdUnit AND Table_Field_Desc = 'CTS location Type')	

SET @LocationCleaningUDESubTypeId = 
(
	SELECT	EST.event_Subtype_Id
	FROM	dbo.event_subtypes EST WITH(NOLOCK)
	WHERE	EST.event_Subtype_Desc = 'CTS Location Cleaning'
)


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



	RETURN	
END
