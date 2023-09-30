


--------------------------------------------------------------------------------------------------
-- Local Function: fnLocal_CTS_Location_Products
--------------------------------------------------------------------------------------------------
-- Author				:	Francois Bergeron (AutomaTech Canada)
-- Date created			:	2021-10-05
-- Version 				:	1.0
-- Description			:	Get location products
--							The purpose of this function is to retreive the product assigned to a location
--							Product assignment is done using a production event on the location, the production event is 
--							assocated to the appliance event using an event_components record
-- Editor tab spacing	: 4 
--------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ========		====	  		====					=====
-- 1.0			2021-10-05		F.Bergeron				Initial Release 
-- 1.1			2022-02-07		F.Bergeron				Add possibility to fetch last product from any point in time
-- 1.2			2022-02-16		F.Bergeron				Evaluation of process order end_time changed
-- 1.3			2022-02-24		F.Bergeron				Add product desc and Process_order_formulation_id to output
--------------------------------------------------------------------------------------------------
--Testing Code
--------------------------------------------------------------------------------------------------
/*
SELECT * FROM fnLocal_CTS_Location_Products(8464,NULL,NULL)
SElect *  FROM production_plan_starts PPS JOIN production_plan PP ON pp.pp_id = PPS.PP_ID
WHERE PP.path_id = 212
*/
--------------------------------------------------------------------------------------------------
CREATE FUNCTION [dbo].[fnLocal_CTS_Location_Products] 
(
	@PU_Id 				INTEGER,
	@Start_time			DATETIME = NULL,
	@End_time			DATETIME = NULL
)
RETURNS @Output TABLE 
(
	Id								INTEGER IDENTITY(1,1),	
	Product_Id						INTEGER,
	Product_code					VARCHAR(50),
	Product_desc					VARCHAR(50),
	Process_order_Id				INTEGER,
	Process_order_desc				VARCHAR(50),
	Process_order_status_id			VARCHAR(50),
	Process_order_status_desc		VARCHAR(50),
	Process_order_formulation_id	INTEGER,
	Location_id						INTEGER,
	Location_desc					VARCHAR(50),
	Start_time						DATETIME,
	End_time						DATETIME
)
					
AS
BEGIN
	DECLARE
	@LocationCleaningUDESubTypeId			VARCHAR(50),
	@LocationCleaningTypeVarId				INTEGER

	IF @End_time IS NULL 
		SET @End_time = GETDATE()
	

	SET @LocationCleaningUDESubTypeId = 
	(
		SELECT	EST.Event_Subtype_Id
		FROM	dbo.event_subtypes EST WITH(NOLOCK)
		WHERE	EST.Event_Subtype_Desc = 'CTS Location Cleaning'
	)
	
	SET @LocationCleaningTypeVarId = 

	(
		SELECT	V.var_id 
		FROM	dbo.variables_base V WITH(NOLOCK)	
		WHERE	V.PU_Id = @PU_id
					AND V.Event_Subtype_Id = @LocationCleaningUDESubTypeId
					AND V.Test_Name = 'Type'
	)

	-- GET LOCATION ASSIGNED PRODUCTS
	-- TWO CASES
	-- 1- @Start_time and @end_time are NULL only get the latest
	-- 2- @Start_time and @end_time are NOT NULL get all for interval

	IF @Start_time IS NULL
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
			Process_order_formulation_id,
			Location_id,
			Location_desc,
			Start_time,
			end_time
		)
		SELECT TOP 1 
					PB.prod_id 'Product_Id',
					PB.Prod_Code 'Product_code',
					PB.prod_desc 'Product_desc',
					PP.PP_Id 'Process_order_Id',
					PP.Process_Order 'Process_order_desc',
					PP.PP_Status_Id 'Process_order_status_id',
					PPSt.PP_Status_Desc 'Process_order_status_desc',
					PP.BOM_Formulation_id 'Process_order_formulation_id',
					PUB.PU_Id 'Location_id',
					PUB.PU_Desc 'Location_desc',
					PPS.Start_time 'Start_time',
					PPS.End_time 'End_time'
		FROM		dbo.prod_units_Base PUB
					JOIN dbo.production_plan_starts PPS WITH(NOLOCK) 
						ON PPS.PU_Id = PUB.PU_Id
					JOIN dbo.Production_plan PP WITH(NOLOCK)
						ON PP.PP_Id = PPS.PP_Id
						AND PP.Path_Id IS NOT NULL
					JOIN dbo.Production_Plan_Statuses PPSt WITH(NOLOCK)
						ON PPSt.PP_Status_Id = PP.PP_Status_Id
					JOIN dbo.PrdExec_Path_Units PPU WITH(NOLOCK)
						ON PPU.Path_Id = PP.Path_Id
					OUTER APPLY (
									SELECT TOP 1	*
									FROM			dbo.User_Defined_Events UDEc WITH(NOLOCK)
									WHERE			UDEc.pu_id = PPU.PU_Id 
														AND UDEc.Event_Subtype_Id = @LocationCleaningUDESubTypeId 
														AND UDEc.End_time > PPS.Start_Time
									ORDER BY		UDEc.end_time ASC
								) UDE
					-- TYPE
					LEFT JOIN dbo.tests T WITH(NOLOCK)
						ON UDE.End_Time = T.Result_On 
						AND T.var_id = @LocationCleaningTypeVarId	
					JOIN dbo.products_base PB WITH(NOLOCK)
						ON PB.prod_id = PP.prod_Id
		WHERE		PUB.PU_Id = @PU_Id
					AND PPS.start_time < @end_time
		ORDER BY	PPS.Start_Time DESC
	END
	ELSE
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
			Process_order_formulation_id,
			Location_id,
			Location_desc,
			Start_time,
			end_time
		)
		SELECT 
					PB.prod_id 'Product_Id',
					PB.Prod_Code 'Product_code',
					PB.prod_desc 'Product_desc',
					PP.PP_Id 'Process_order_Id',
					PP.Process_Order 'Process_order_desc',
					PP.PP_Status_Id 'Process_order_status_id',
					PPSt.PP_Status_Desc 'Process_order_status_desc',
					PP.BOM_Formulation_id 'Process_order_formulation_id',
					PUB.PU_Id 'Location_id',
					PUB.PU_Desc 'Location_desc',
					PPS.Start_time 'Start_time',
					--(CASE 
					--WHEN UDE.End_Time > PPS.Start_Time 
					--	THEN UDE.End_Time 
					--ELSE NULL
					--END)'End_time'
					PPS.End_time 'End_time'
		FROM		dbo.prod_units_Base PUB
					JOIN dbo.production_plan_starts PPS WITH(NOLOCK) 
						ON PPS.PU_Id = PUB.PU_Id
					JOIN dbo.Production_plan PP WITH(NOLOCK)
						ON PP.PP_Id = PPS.PP_Id
						AND PP.Path_Id IS NOT NULL
					JOIN dbo.Production_Plan_Statuses PPSt WITH(NOLOCK)
						ON PPSt.PP_Status_Id = PP.PP_Status_Id
					JOIN dbo.PrdExec_Path_Units PPU WITH(NOLOCK)
						ON PPU.Path_Id = PP.Path_Id
					OUTER APPLY (
									SELECT TOP 1	*
									FROM			dbo.User_Defined_Events UDEc WITH(NOLOCK)
									WHERE			UDEc.pu_id = PPU.PU_Id 
														AND UDEc.Event_Subtype_Id = @LocationCleaningUDESubTypeId 
														AND UDEc.End_time > PPS.Start_Time
									ORDER BY		UDEc.end_time ASC
								) UDE
					-- TYPE
					LEFT JOIN dbo.tests T WITH(NOLOCK)
						ON UDE.End_Time = T.Result_On 
						AND T.var_id = @LocationCleaningTypeVarId	
					JOIN dbo.products_base PB WITH(NOLOCK)
						ON PB.prod_id = PP.prod_Id		WHERE		PUB.PU_Id = @PU_Id
						AND PPS.start_time BETWEEN @Start_time AND @End_time 
		ORDER BY	PPS.Start_Time DESC
	END
						
	

RETURN
END
