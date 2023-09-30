


--------------------------------------------------------------------------------------------------
-- Local Function: fnLocal_CTS_Appliance_Transitions_New
--------------------------------------------------------------------------------------------------
-- Author				:	Francois Bergeron (AutomaTech Canada)
-- Date created			:	2021-11-05
-- Version 				:	1.0
-- Description			:	Get appliance location
--							The purpose of this function is to retreive the current or past locations of an appliance.
--							
-- Editor tab spacing	: 4 
--------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ========		====	  		====					=====
-- 1.0			2021-10-05		F.Bergeron				Initial Release 



--------------------------------------------------------------------------------------------------
--Testing Code
--------------------------------------------------------------------------------------------------
-- SELECT * FROM fnLocal_CTS_Appliance_Transitions_New(993916, 0, NULL,NULL)
--------------------------------------------------------------------------------------------------
CREATE FUNCTION [dbo].[fnLocal_CTS_Appliance_Transitions_New] 
(
	@Event_Id 				INTEGER,
	@ProductTransitionOnly	BIT = 0,
	@Start_time				DATETIME = NULL,
	@End_time				DATETIME = NULL
)
RETURNS @Output TABLE 
(
	Id									INTEGER IDENTITY(1,1),	
	Location_id							INTEGER,
	Location_desc						VARCHAR(50),
	Location_Product_Id					INTEGER,
	Location_Product_code				VARCHAR(25),
	Location_Process_order_Id			INTEGER,
	Location_Process_order_desc			VARCHAR(50),
	Location_Process_order_status_Id	INTEGER,
	Location_Process_order_Status_desc	VARCHAR(50),
	Location_Process_Order_start_time	DATETIME,
	Location_Process_Order_End_time		DATETIME,
	Enter_time							DATETIME,
	Exit_time							DATETIME,
	Appliance_Product_Id				INTEGER,
	Appliance_Product_code				VARCHAR(25),
	Appliance_Process_order_Id			INTEGER,
	Appliance_Process_order_desc		VARCHAR(50),
	Mover_User_Id						INTEGER,
	Mover_Username						VARCHAR(100),
	Mover_User_AD						VARCHAR(100),
	Err_Warn							VARCHAR(500)
)
					
AS
BEGIN
	-- GET all units that are CTS locations
	DECLARE @Location_Units TABLE
	(
		PU_Id			INTEGER,
		Location_Type	VARCHAR(50)
	)
	INSERT INTO @Location_Units
	(
		PU_Id,
		Location_Type
	)
	SELECT	PUB.PU_Id,TFV.Value FROM dbo.Prod_units_base PUB
			JOIN dbo.Table_Fields_Values TFV WITH(NOLOCK)
				ON  TFV.KeyId = PUB.PU_Id
			JOIN dbo.Table_Fields TF WITH(NOLOCK) 
				ON TF.Table_Field_Id = TFV.Table_Field_Id
				AND TF.Table_Field_Desc = 'CTS Location type'
				AND TF.TableId =	(
									SELECT	TableId 
									FROM	dbo.Tables WITH(NOLOCK) 
									WHERE	TableName = 'Prod_units'
									)

	DECLARE @App_cleaning TABLE
	(
		Status						VARCHAR(25),
		type						VARCHAR(25),
		Location_id					INTEGER,
		Location_desc				VARCHAR(50),
		Start_time					DATETIME,
		End_time					DATETIME,
		Start_User_Id				INTEGER,
		Start_Username				VARCHAR(100),
		Start_User_AD				VARCHAR(100),
		Completion_ES_User_Id		INTEGER,
		Completion_ES_Username		VARCHAR(100),
		Completion_ES_User_AD		VARCHAR(100),
		Approver_ES_User_Id			INTEGER,
		Approver_ES_Username		VARCHAR(100),
		Approver_ES_User_AD			VARCHAR(100),
		Err_Warn					VARCHAR(500),
		UDE_Id						INTEGER
	)

	-- GET APPLIANCE ASSIGNED PRODUCTS
	-- TWO CASES
	-- 1- @Start_time and @end_time are NULL only get the latest
	-- 2- @Start_time and @end_time are NOT NULL get all for interval
	-- GET LAST TIME IT WAS CLEANED
		INSERT INTO	@App_cleaning
	(
			Status,
			type,
			Location_id,
			Location_desc,
			Start_time,
			End_time,
			Start_User_Id,
			Start_Username,
			Start_User_AD,
			Completion_ES_User_Id,
			Completion_ES_Username,
			Completion_ES_User_AD,
			Approver_ES_User_Id,
			Approver_ES_Username,
			Approver_ES_User_AD,
			Err_Warn,
			UDE_Id
	)
	SELECT 	Status,
			type,
			Location_id,
			Location_desc,
			Start_time,
			End_time,
			Start_User_Id,
			Start_Username,
			Start_User_AD,
			Completion_ES_User_Id,
			Completion_ES_Username,
			Completion_ES_User_AD,
			Approver_ES_User_Id,
			Approver_ES_Username,
			Approver_ES_User_AD,
			Err_Warn,
			UDE_Id
	FROM	[dbo].[fnLocal_CTS_Appliance_Cleanings](@Event_Id, NULL, NULL)

	IF @ProductTransitionOnly = 0
	BEGIN
		IF @Start_time IS NULL OR @End_time IS NULL
		BEGIN


			INSERT INTO	@Output
			(
			Location_id,
			Location_desc,
			Location_Product_Id,
			Location_Product_code,
			Location_Process_order_Id,
			Location_Process_order_desc,
			Location_Process_order_status_Id,
			Location_Process_order_Status_desc,
			Location_Process_Order_start_time,
			Location_Process_Order_End_time,
			Enter_time,
			Exit_time,
			Appliance_Product_Id,
			Appliance_Product_code,
			Appliance_Process_order_Id,
			Appliance_Process_order_desc,
			Mover_User_Id,
			Mover_Username,
			Mover_User_AD,
			Err_Warn
			)
			SELECT TOP 1 
						PUB.PU_Id 'Location_id',
						PUB.PU_Desc 'Location_desc',
						PB.prod_id 'Location_Product_Id',
						PB.Prod_Code 'Location_Product_code',
						PP.PP_Id	'Location_Process_Order_Id',
						PP.Process_Order 'Location_Process_Order_Desc',	
						PP.PP_Status_Id 'Location_Process_order_Status_Id',
						PPSt.PP_Status_Desc 'Process_order_Status_Desc',
						PPS.Start_Time 'Location_Process_Order_start_time',
						PPS.End_Time 'Location_Process_Order_End_time',
						E1.Start_Time 'Enter_time',
						E1.Timestamp 'Exit_time',
						E1.Applied_Product 'Appliance_Product_Id',
						PB1.prod_code 'Appliance_Product_code',
						ED.PP_id 'Appliance_Process_order_Id',
						PP1.Process_Order'Appliance_Process_order_desc',
						E1.User_Id 'Mover_User_Id',
						U.Username 'Mover_Username',
						U.WindowsUserInfo 'Mover_User_AD',
						(CASE
						WHEN PPU.PU_Id IS NOT NULL AND PPS.PP_Id IS NULL
							THEN 'Illegal movement, PO should be set at this location'
						ELSE
							''
						END) 'Err_Warn'
			FROM		dbo.events E WITH(NOLOCK)
						JOIN dbo.event_components EC WITH(NOLOCK) 
							ON EC.Source_event_Id = E.event_id
						JOIN dbo.events E1 WITH(NOLOCK) 
							ON E1.event_Id = EC.event_id
						JOIN dbo.users U WITH(NOLOCK)
							ON U.user_id = E1.User_Id
						-- Location event
						LEFT JOIN dbo.event_details ED WITH(NOLOCK)
							ON ED.event_id = E1.event_id
						LEFT JOIN dbo.PrdExec_Path_Units PPU WITH(NOLOCK)
							ON PPU.pu_id = E1.pu_id
						LEFT JOIN dbo.production_plan_starts PPS WITH(NOLOCK) 
							ON E1.TimeStamp >= PPS.Start_Time 
							AND (E1.timestamp < PPS.end_time OR PPS.end_time IS NULL)
							AND PPS.PU_Id = E1.pu_id
						LEFT JOIN dbo.Production_plan PP WITH(NOLOCK)
							ON PP.PP_Id = PPS.PP_Id
							AND PP.Path_Id IS NOT NULL
						LEFT JOIN dbo.Production_Plan_Statuses PPSt WITH(NOLOCK)
							ON PPSt.PP_Status_Id = PP.PP_Status_Id
						LEFT JOIN dbo.products_base PB WITH(NOLOCK)
							ON PB.prod_id = PP.prod_Id
						JOIN dbo.prod_units_base PUB WITH(NOLOCK) 
							ON PUB.PU_Id = E1.pu_id
						JOIN @Location_Units LU
							ON LU.PU_Id = PUB.PU_Id
						LEFT JOIN dbo.products_base PB1 WITH(NOLOCK)
							ON PB1.prod_id = E1.Applied_Product
						LEFT JOIN dbo.Production_Plan PP1 WITH(NOLOCK)
							ON PP1.PP_id  = ED.PP_ID
			WHERE		E.Event_Id = @Event_Id
						--AND e.timestamp > (SELECT COALESCE(End_time,(SELECT timestamp FROM dbo.events WITH(NOLOCK) WHERE event_id = @Event_Id))  FROM @App_cleaning)
			ORDER BY	EC.Timestamp DESC
		END
		ELSE
		BEGIN
			INSERT INTO	@Output
			(
			Location_id,
			Location_desc,
			Location_Product_Id,
			Location_Product_code,
			Location_Process_order_Id,
			Location_Process_order_desc,
			Location_Process_order_status_Id,
			Location_Process_order_Status_desc,
			Location_Process_Order_start_time,
			Location_Process_Order_End_time,
			Enter_time,
			Exit_time,
			Appliance_Product_Id,
			Appliance_Product_code,
			Appliance_Process_order_Id,
			Appliance_Process_order_desc,
			Mover_User_Id,
			Mover_Username,
			Mover_User_AD,
			Err_Warn
			)
			SELECT TOP 1 
						PUB.PU_Id 'Location_id',
						PUB.PU_Desc 'Location_desc',
						PB.prod_id 'Location_Product_Id',
						PB.Prod_Code 'Location_Product_code',
						PP.PP_Id	'Location_Process_Order_Id',
						PP.Process_Order 'Location_Process_Order_Desc',	
						PP.PP_Status_Id 'Location_Process_order_Status_Id',
						PPSt.PP_Status_Desc 'Process_order_Status_Desc',
						PPS.Start_Time 'Location_Process_Order_start_time',
						PPS.End_Time 'Location_Process_Order_End_time',
						E1.Start_Time 'Enter_time',
						E1.Timestamp 'Exit_time',
						E1.Applied_Product 'Appliance_Product_Id',
						PB1.prod_code 'Appliance_Product_code',
						ED.PP_id 'Appliance_Process_order_Id',
						PP1.Process_Order'Appliance_Process_order_desc',
						E1.User_Id 'Mover_User_Id',
						U.Username 'Mover_Username',
						U.WindowsUserInfo 'Mover_User_AD',
						(CASE
						WHEN PPU.PU_Id IS NOT NULL AND PPS.PP_Id IS NULL
							THEN 'Illegal movement, PO should be set at this location'
						ELSE
							''
						END) 'Err_Warn'
			FROM		dbo.events E WITH(NOLOCK)
						JOIN dbo.event_components EC WITH(NOLOCK) 
							ON EC.Source_event_Id = E.event_id
						JOIN dbo.events E1 WITH(NOLOCK) 
							ON E1.event_Id = EC.event_id
						JOIN dbo.users U WITH(NOLOCK)
							ON U.user_id = E1.User_Id
						-- Location event
						LEFT JOIN dbo.event_details ED WITH(NOLOCK)
							ON ED.event_id = E1.event_id
						LEFT JOIN dbo.PrdExec_Path_Units PPU WITH(NOLOCK)
							ON PPU.pu_id = E1.pu_id
						LEFT JOIN dbo.production_plan_starts PPS WITH(NOLOCK) 
							ON E1.TimeStamp >= PPS.Start_Time 
							AND (E1.timestamp < PPS.end_time OR PPS.end_time IS NULL)
							AND PPS.PU_Id = E1.pu_id
						LEFT JOIN dbo.Production_plan PP WITH(NOLOCK)
							ON PP.PP_Id = PPS.PP_Id
							AND PP.Path_Id IS NOT NULL
						LEFT JOIN dbo.Production_Plan_Statuses PPSt WITH(NOLOCK)
							ON PPSt.PP_Status_Id = PP.PP_Status_Id
						LEFT JOIN dbo.products_base PB WITH(NOLOCK)
							ON PB.prod_id = PP.prod_Id
						JOIN dbo.prod_units_base PUB WITH(NOLOCK) 
							ON PUB.PU_Id = E1.pu_id
						JOIN @Location_Units LU
							ON LU.PU_Id = PUB.PU_Id
						LEFT JOIN dbo.products_base PB1 WITH(NOLOCK)
							ON PB1.prod_id = E1.Applied_Product
						LEFT JOIN dbo.Production_Plan PP1 WITH(NOLOCK)
							ON PP1.PP_id  = ED.PP_ID
			WHERE		E.Event_Id = @Event_Id
							AND E1.TimeStamp Between @Start_time and @End_time
			ORDER BY	EC.Timestamp DESC
					
		END
	END
	ELSE
	BEGIN
		IF @Start_time IS NULL OR @End_time IS NULL
		BEGIN
			INSERT INTO	@Output
			(
			Location_id,
			Location_desc,
			Location_Product_Id,
			Location_Product_code,
			Location_Process_order_Id,
			Location_Process_order_desc,
			Location_Process_order_status_Id,
			Location_Process_order_Status_desc,
			Location_Process_Order_start_time,
			Location_Process_Order_End_time,
			Enter_time,
			Exit_time,
			Appliance_Product_Id,
			Appliance_Product_code,
			Appliance_Process_order_Id,
			Appliance_Process_order_desc,
			Mover_User_Id,
			Mover_Username,
			Mover_User_AD,
			Err_Warn
			)
			SELECT TOP 1 
						PUB.PU_Id 'Location_id',
						PUB.PU_Desc 'Location_desc',
						PB.prod_id 'Location_Product_Id',
						PB.Prod_Code 'Location_Product_code',
						PP.PP_Id	'Location_Process_Order_Id',
						PP.Process_Order 'Location_Process_Order_Desc',	
						PP.PP_Status_Id 'Location_Process_order_Status_Id',
						PPSt.PP_Status_Desc 'Process_order_Status_Desc',
						PPS.Start_Time 'Location_Process_Order_start_time',
						PPS.End_Time 'Location_Process_Order_End_time',
						E1.Start_Time 'Enter_time',
						E1.Timestamp 'Exit_time',
						E1.Applied_Product 'Appliance_Product_Id',
						PB1.prod_code 'Appliance_Product_code',
						ED.PP_id 'Appliance_Process_order_Id',
						PP1.Process_Order'Appliance_Process_order_desc',
						E1.User_Id 'Mover_User_Id',
						U.Username 'Mover_Username',
						U.WindowsUserInfo 'Mover_User_AD',
						(CASE
						WHEN PPU.PU_Id IS NOT NULL AND PPS.PP_Id IS NULL
							THEN 'Illegal movement, PO should be set at this location'
						ELSE
							''
						END) 'Err_Warn'
			FROM		dbo.events E WITH(NOLOCK)
						JOIN dbo.event_components EC WITH(NOLOCK) 
							ON EC.Source_event_Id = E.event_id
						JOIN dbo.events E1 WITH(NOLOCK) 
							ON E1.event_Id = EC.event_id
						JOIN dbo.users U WITH(NOLOCK)
							ON U.user_id = E1.User_Id
						-- Location event
						LEFT JOIN dbo.event_details ED WITH(NOLOCK)
							ON ED.event_id = E1.event_id
						LEFT JOIN dbo.PrdExec_Path_Units PPU WITH(NOLOCK)
							ON PPU.pu_id = E1.pu_id
						LEFT JOIN dbo.production_plan_starts PPS WITH(NOLOCK) 
							ON E1.TimeStamp >= PPS.Start_Time 
							AND (E1.timestamp < PPS.end_time OR PPS.end_time IS NULL)
							AND PPS.PU_Id = E1.pu_id
						LEFT JOIN dbo.Production_plan PP WITH(NOLOCK)
							ON PP.PP_Id = PPS.PP_Id
							AND PP.Path_Id IS NOT NULL
						LEFT JOIN dbo.Production_Plan_Statuses PPSt WITH(NOLOCK)
							ON PPSt.PP_Status_Id = PP.PP_Status_Id
						LEFT JOIN dbo.products_base PB WITH(NOLOCK)
							ON PB.prod_id = PP.prod_Id
						JOIN dbo.prod_units_base PUB WITH(NOLOCK) 
							ON PUB.PU_Id = E1.pu_id
						JOIN @Location_Units LU
							ON LU.PU_Id = PUB.PU_Id
						LEFT JOIN dbo.products_base PB1 WITH(NOLOCK)
							ON PB1.prod_id = E1.Applied_Product
						LEFT JOIN dbo.Production_Plan PP1 WITH(NOLOCK)
							ON PP1.PP_id  = ED.PP_ID
			WHERE		E.Event_Id = @Event_Id
							AND PP.PP_Id IS NOT NULL
			ORDER BY	EC.Timestamp DESC
		END
		ELSE
		BEGIN
			INSERT INTO	@Output
			(
			Location_id,
			Location_desc,
			Location_Product_Id,
			Location_Product_code,
			Location_Process_order_Id,
			Location_Process_order_desc,
			Location_Process_order_status_Id,
			Location_Process_order_Status_desc,
			Location_Process_Order_start_time,
			Location_Process_Order_End_time,
			Enter_time,
			Exit_time,
			Appliance_Product_Id,
			Appliance_Product_code,
			Appliance_Process_order_Id,
			Appliance_Process_order_desc,
			Mover_User_Id,
			Mover_Username,
			Mover_User_AD,
			Err_Warn
			)
			SELECT TOP 1 
						PUB.PU_Id 'Location_id',
						PUB.PU_Desc 'Location_desc',
						PB.prod_id 'Location_Product_Id',
						PB.Prod_Code 'Location_Product_code',
						PP.PP_Id	'Location_Process_Order_Id',
						PP.Process_Order 'Location_Process_Order_Desc',	
						PP.PP_Status_Id 'Location_Process_order_Status_Id',
						PPSt.PP_Status_Desc 'Process_order_Status_Desc',
						PPS.Start_Time 'Location_Process_Order_start_time',
						PPS.End_Time 'Location_Process_Order_End_time',
						E1.Start_Time 'Enter_time',
						E1.Timestamp 'Exit_time',
						E1.Applied_Product 'Appliance_Product_Id',
						PB1.prod_code 'Appliance_Product_code',
						ED.PP_id 'Appliance_Process_order_Id',
						PP1.Process_Order'Appliance_Process_order_desc',
						E1.User_Id 'Mover_User_Id',
						U.Username 'Mover_Username',
						U.WindowsUserInfo 'Mover_User_AD',
						(CASE
						WHEN PPU.PU_Id IS NOT NULL AND PPS.PP_Id IS NULL
							THEN 'Illegal movement, PO should be set at this location'
						ELSE
							''
						END) 'Err_Warn'
			FROM		dbo.events E WITH(NOLOCK)
						JOIN dbo.event_components EC WITH(NOLOCK) 
							ON EC.Source_event_Id = E.event_id
						JOIN dbo.events E1 WITH(NOLOCK) 
							ON E1.event_Id = EC.event_id
						JOIN dbo.users U WITH(NOLOCK)
							ON U.user_id = E1.User_Id
						-- Location event
						LEFT JOIN dbo.event_details ED WITH(NOLOCK)
							ON ED.event_id = E1.event_id
						LEFT JOIN dbo.PrdExec_Path_Units PPU WITH(NOLOCK)
							ON PPU.pu_id = E1.pu_id
						LEFT JOIN dbo.production_plan_starts PPS WITH(NOLOCK) 
							ON E1.TimeStamp >= PPS.Start_Time 
							AND (E1.timestamp < PPS.end_time OR PPS.end_time IS NULL)
							AND PPS.PU_Id = E1.pu_id
						LEFT JOIN dbo.Production_plan PP WITH(NOLOCK)
							ON PP.PP_Id = PPS.PP_Id
							AND PP.Path_Id IS NOT NULL
						LEFT JOIN dbo.Production_Plan_Statuses PPSt WITH(NOLOCK)
							ON PPSt.PP_Status_Id = PP.PP_Status_Id
						LEFT JOIN dbo.products_base PB WITH(NOLOCK)
							ON PB.prod_id = PP.prod_Id
						JOIN dbo.prod_units_base PUB WITH(NOLOCK) 
							ON PUB.PU_Id = E1.pu_id
						JOIN @Location_Units LU
							ON LU.PU_Id = PUB.PU_Id
						LEFT JOIN dbo.products_base PB1 WITH(NOLOCK)
							ON PB1.prod_id = E1.Applied_Product
						LEFT JOIN dbo.Production_Plan PP1 WITH(NOLOCK)
							ON PP1.PP_id  = ED.PP_ID
			WHERE		E.Event_Id = @Event_Id
							AND E1.TimeStamp Between @Start_time and @End_time
							AND PP.PP_Id IS NOT NULL
			ORDER BY	EC.Timestamp DESC
					
		END
	END

	RETURN
END
