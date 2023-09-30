--------------------------------------------------------------------------------------------------
-- Local Function: fnLocal_CTS_Location_Process_Orders
--------------------------------------------------------------------------------------------------
-- Author				:	Francois Bergeron (AutomaTech Canada)
-- Date created			:	2021-10-15
-- Version 				:	1.0
-- Description			:	Get location POs
--							The purpose of this function is to retreive the process orders assigned to a location
-- Editor tab spacing	: 4 
--------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ========		====	  		====					=====
-- 1.0			2021-10-15		F.Bergeron				Initial Release 
-- 1.1			2021-11-18		F.Bergeron				Add product filter
-- 1.2			2022-02-07		F.Bergeron				Add possibility to select a specific PP_Id
-- 1.3			2022-02-08		F.Bergeron				Retreive all Incomplete process orders and add product desc
-- 1.4			2022-03-01		F.Bergeron				Bit to return all POs

--------------------------------------------------------------------------------------------------
--Testing Code

--8451	CTS NUMC General	123456789_001
--8454	CTS NUMC Staging	123456789_104
--8459	CTS Clean Bin Storage	123456789_125
--8460	CTS Dirty Bin Storage	123456789_126
--8461	CTS Cleaning Station 1	123456789_127
--8463	CTS NUMD General	123456789_105
--8464	CTS NUMG General	123456789_109
--8465	CTS NUMJ General	123456789_113
--8466	CTS NUMK General	123456789_117
--8467	CTS NUMM General	123456789_121
--8471	CTS NUMD Staging	123456789_108
--8475	CTS NUMK Staging	123456789_120
--8478	CTS NUMM Staging	123456789_124
--8481	CTS NUMJ Staging	123456789_116
--8493	CTS PPW 1	123456789_999
--------------------------------------------------------------------------------------------------
-- SELECT * FROM fnLocal_CTS_Location_Process_Orders('8551,8454,8459',NULL,'02-mar-2022', '03-mar-2022', NULL, NULL,NULL, 0)
--------------------------------------------------------------------------------------------------
CREATE FUNCTION [dbo].[fnLocal_CTS_Location_Process_Orders] 
(
	@Location_Ids 		VARCHAR(500) = NULL,
	@ProcessOrderId		INTEGER = NULL,
	@StartTime			DATETIME = NULL, 
	@EndTime			DATETIME = NULL,
	@FProductId			VARCHAR(3000) = NULL,
	@ByCount			INTEGER = NULL,
	@Direction			VARCHAR(25) = 'FORWARD',
	@IncludeCompleted	BIT = 1
	--@Status				VARCHAR(25)

)
RETURNS @Output TABLE 
(
	Id							INTEGER IDENTITY(1,1),	
	Product_Id					INTEGER,
	Product_code				VARCHAR(50),
	Product_Desc				VARCHAR(50),
	Process_order_Id			INTEGER,
	Process_order_desc			VARCHAR(50),
	Process_order_status_id		VARCHAR(50),
	Process_order_status_desc	VARCHAR(50),
	Planned_Start_time			DATETIME,
	Planned_End_time			DATETIME,
	Actual_Start_time			DATETIME,
	Actual_End_time				DATETIME,
	Location_id					INTEGER,
	Location_desc				VARCHAR(50)
)
					
AS
BEGIN
	DECLARE
	@LocationCleaningUDESubTypeId			VARCHAR(50),
	@LocationCleaningTypeVarId				INTEGER,
	@UTCStartTime							DATETIME,
	@UTCEndTime								DATETIME,
	@vchTimeZone							VARCHAR(50),
	@NullStartTime							DATETIME,
	@NullEndTime							DATETIME
	DECLARE 
	@FProducts TABLE
	(
		Product_Id						INTEGER,
		Product_desc					INTEGER
	)

	DECLARE 
	@FLocations TABLE
	(
		Location_Id						INTEGER,
		Location_desc					VARCHAR(50)
	)

	DECLARE 
	@OrderStatus TABLE
	(
		SchStatusId						INTEGER,
		SchStatusDesc					VARCHAR(50)
	)

	IF @IncludeCompleted = 0
	BEGIN
		INSERT INTO @OrderStatus
		(
		SchStatusId,
		SchStatusDesc
		)
		SELECt	PP_Status_Id, 
				PP_Status_Desc 
		FROM	dbo.Production_Plan_Statuses WITH(NOLOCK)
		WHERE	PP_Status_Desc IN('Active','Pending')
	END
	ELSE
	BEGIN
		INSERT INTO @OrderStatus
		(
		SchStatusId,
		SchStatusDesc
		)
		SELECt	PP_Status_Id, 
				PP_Status_Desc 
		FROM	dbo.Production_Plan_Statuses WITH(NOLOCK)
		WHERE	PP_Status_Desc IN('Active','Pending','Complete')
	END

	IF @Location_Ids IS NULL
	BEGIN
	INSERT INTO @FLocations
	(
	Location_Id,
	Location_desc
	)
	SELECT	PUB.pu_id, 
			PUB.pu_desc 
	FROM	dbo.prod_units_base PUB WITH(NOLOCK) 
			JOIN dbo.prdexec_path_units PEPU 
			ON PEPU.pu_id = PUB.pu_id 
	WHERE	PUB.equipment_type = 'CTS Location'

	END
	ELSE
	BEGIN
		INSERT INTO @FLocations(Location_Id)
		SELECT value FROM STRING_SPLIT(@Location_Ids, ',');

	END
	
	INSERT INTO @FProducts(Product_id)
	SELECT CAST(value AS INTEGER) FROM STRING_SPLIT(@FProductId,',')

	IF (SELECT COUNT(1) FROM @FProducts) = 0
			INSERT INTO @Fproducts (Product_Id)
			SELECT		prod_id 
			FROM		dbo.Products_Base

/*	-- SET DEFAULT INTERVAL IF NOT SET
	IF @ByCount IS NULL
	BEGIN
		IF 	@StartTime IS NULL
			SET @NULLStartTime = GETDATE()
		IF 	@EndTime IS NULL
			SET @NULLEndTime = DATEADD(HOUR,24,@StartTime)
	END
*/
/*	SET @vchTimeZone =	(
						SELECT DB.Time_Zone	FROM dbo.Departments_Base DB WITH(NOLOCK) 
								JOIN dbo.Prod_Lines_Base PLB WITH(NOLOCK)
									ON PLB.Dept_Id = DB.Dept_Id
								JOIN Prod_Units_Base PUB 
									ON PUB.PL_Id = PLB.PL_Id
						WHERE		PUB.PU_Id = @Location_Id
						)



	SET @UTCStartTime =	(
						SELECT CAST(@StartTime AS DATETIME) AT TIME ZONE @vchTimeZone AT TIME ZONE 'UTC'
						)

	SET @UTCEndTime =	(
						SELECT CAST(@EndTime AS DATETIME) AT TIME ZONE @vchTimeZone AT TIME ZONE 'UTC'
						)
*/
	IF @ByCount IS NOT NULL
	BEGIN
		IF @EndTime IS NULL
		BEGIN
			SET @EndTime = GETDATE()
		END

		IF @Direction = 'BACKWARD'
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
				Planned_Start_time,
				Planned_End_time,
				Actual_Start_time,
				Actual_End_time,
				Location_id,
				Location_desc

			)
			SELECT	
			DISTINCT
			TOP (@ByCount)	PP.Prod_Id 'Product_Id',
							P.Prod_code,
							P.Prod_Desc,
							PP.PP_Id,
							PP.Process_Order,
							PP.PP_Status_Id,
							PPSt.PP_Status_Desc,
							PP.Forecast_Start_Date,
							PP.Forecast_End_Date,
							PPS.Start_Time,
							PPS.End_time,
							PUB.PU_Id,
							PUB.pu_desc
			FROM		dbo.prod_units_Base PUB
						JOIN dbo.PrdExec_Path_Units PPU WITH(NOLOCK)
							ON PPU.PU_Id = PUB.PU_Id
						JOIN dbo.Production_plan PP WITH(NOLOCK)
							ON PP.Path_Id = PPU.Path_Id
							AND PP.Path_Id IS NOT NULL 
						JOIN dbo.Production_Plan_Statuses PPSt WITH(NOLOCK)
							ON PPSt.PP_Status_Id = PP.PP_Status_Id
						JOIN dbo.products P WITH(NOLOCK)
							ON P.Prod_Id = PP.Prod_Id
						LEFT JOIN dbo.production_plan_starts PPS WITH(NOLOCK) 
							ON PPS.PP_Id = PP.PP_Id
								AND PPS.PU_Id IN (SELECT Location_Id FROM @FLocations)
						JOIN dbo.Bill_Of_Material_Formulation_Item bomfi WITH(NOLOCK)	
							ON pp.BOM_Formulation_Id = bomfi.BOM_Formulation_Id
						LEFT JOIN dbo.Bill_Of_Material_Substitution boms WITH(NOLOCK)	
							ON bomfi.BOM_Formulation_Item_Id = boms.BOM_Formulation_Item_Id
			WHERE		PUB.PU_Id IN (SELECT Location_Id FROM @FLocations)
						AND PP.Forecast_Start_Date <= @EndTime
						AND PPSt.PP_Status_Id IN (SELECT SchStatusId FROM @OrderStatus)
							--AND (bomfi.Prod_Id IN (SELECT Product_Id FROM  @FProducts) OR PP.prod_id = (SELECT Product_Id FROM  @FProducts))
			ORDER BY	PPS.start_time DESC

			RETURN
		END
		ELSE IF @Direction = 'FORWARD'
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
				Planned_Start_time,
				Planned_End_time,
				Actual_Start_time,
				Actual_End_time,
				Location_id,
				Location_desc

			)
			SELECT	
			DISTINCT
			TOP (@ByCount)	PP.Prod_Id 'Product_Id',
							P.Prod_code,
							P.Prod_Desc,
							PP.PP_Id,
							PP.Process_Order,
							PP.PP_Status_Id,
							PPSt.PP_Status_Desc,
							PP.Forecast_Start_Date,
							PP.Forecast_End_Date,
							PPS.Start_Time,
							PPS.End_time,
							PUB.PU_Id,
							PUB.pu_desc
			FROM		dbo.prod_units_Base PUB
						JOIN dbo.PrdExec_Path_Units PPU WITH(NOLOCK)
							ON PPU.PU_Id = PUB.PU_Id
						JOIN dbo.Production_plan PP WITH(NOLOCK)
							ON PP.Path_Id = PPU.Path_Id
							AND PP.Path_Id IS NOT NULL 
						JOIN dbo.Production_Plan_Statuses PPSt WITH(NOLOCK)
							ON PPSt.PP_Status_Id = PP.PP_Status_Id
						JOIN dbo.products P WITH(NOLOCK)
							ON P.Prod_Id = PP.Prod_Id
						LEFT JOIN dbo.production_plan_starts PPS WITH(NOLOCK) 
							ON PPS.PP_Id = PP.PP_Id
								AND PPS.PU_Id IN (SELECT Location_Id FROM @FLocations)
						JOIN dbo.Bill_Of_Material_Formulation_Item bomfi WITH(NOLOCK)	
							ON pp.BOM_Formulation_Id = bomfi.BOM_Formulation_Id
						LEFT JOIN dbo.Bill_Of_Material_Substitution boms WITH(NOLOCK)	
							ON bomfi.BOM_Formulation_Item_Id = boms.BOM_Formulation_Item_Id
			WHERE		PUB.PU_Id IN (SELECT Location_Id FROM @FLocations)
							AND PP.Forecast_Start_Date > @EndTime
							AND PPSt.PP_Status_Id IN (SELECT SchStatusId FROM @OrderStatus)
							--AND (bomfi.Prod_Id IN (SELECT Product_Id FROM  @FProducts) OR PP.prod_id = (SELECT Product_Id FROM  @FProducts))
			ORDER BY	PP.Forecast_Start_Date ASC

			RETURN
		END
	END

	--IF (SELECT COUNT(1) FROM @FProducts) > 0
	IF EXISTS(SELECT 1 FROM dbo.production_plan WITH(NOLOCK) WHERE PP_id = @ProcessOrderId)
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
			Planned_Start_time,
			Planned_End_time,
			Actual_Start_time,
			Actual_End_time,
			Location_id,
			Location_desc

		)
		SELECT	DISTINCT 
				PP.Prod_Id 'Product_Id',
				P.Prod_code,
				P.Prod_Desc,
				PP.PP_Id,
				PP.Process_Order,
				PP.PP_Status_Id,
				PPSt.PP_Status_Desc,
				PP.Forecast_Start_Date,
				PP.Forecast_End_Date,
				PPS.Start_Time,
				PPS.End_time,
				PUB.PU_Id,
				PUB.pu_desc

		FROM		dbo.prod_units_Base PUB
					JOIN dbo.PrdExec_Path_Units PPU WITH(NOLOCK)
						ON PPU.PU_Id = PUB.PU_Id
					JOIN dbo.Production_plan PP WITH(NOLOCK)
						ON PP.Path_Id = PPU.Path_Id
						AND PP.Path_Id IS NOT NULL 
					JOIN dbo.Production_Plan_Statuses PPSt WITH(NOLOCK)
						ON PPSt.PP_Status_Id = PP.PP_Status_Id
					JOIN dbo.products P WITH(NOLOCK)
						ON P.Prod_Id = PP.Prod_Id
					LEFT JOIN dbo.production_plan_starts PPS WITH(NOLOCK) 
						ON PPS.PP_Id = PP.PP_Id
							--AND PPS.PU_Id = @Location_Id
					JOIN dbo.Bill_Of_Material_Formulation_Item bomfi WITH(NOLOCK)	
						ON pp.BOM_Formulation_Id = bomfi.BOM_Formulation_Id
					LEFT JOIN dbo.Bill_Of_Material_Substitution boms WITH(NOLOCK)	
						ON bomfi.BOM_Formulation_Item_Id = boms.BOM_Formulation_Item_Id
		WHERE		PP.PP_Id = @ProcessOrderId

		RETURN
	END

	ELSE IF @StartTime IS NOT NULL and @Endtime > @StartTime
	BEGIN
		-- GET LOCATION ASSIGNED PROCESS ORDERS. NO PRODUCT
		INSERT INTO	@Output
		(
			Product_Id,
			Product_code,
			Product_desc,
			Process_order_Id,
			Process_order_desc,
			Process_order_status_id,
			Process_order_status_desc,
			Planned_Start_time,
			Planned_End_time,
			Actual_Start_time,
			Actual_End_time,
			Location_id,
			Location_desc

		)
		SELECT	DISTINCT
				PP.Prod_Id 'Product_Id',
				P.Prod_code,
				P.prod_desc,
				PP.PP_Id,
				PP.Process_Order,
				PP.PP_Status_Id,
				PPSt.PP_Status_Desc,
				PP.Forecast_Start_Date,
				PP.Forecast_End_Date,
				PPS.Start_Time,
				PPS.End_time,
				PUB.PU_Id,
				PUB.pu_desc

		FROM		dbo.prod_units_Base PUB
					JOIN dbo.PrdExec_Path_Units PPU WITH(NOLOCK)
						ON PPU.PU_Id = PUB.PU_Id
					JOIN dbo.Production_plan PP WITH(NOLOCK)
						ON PP.Path_Id = PPU.Path_Id
						AND PP.Path_Id IS NOT NULL 
					JOIN dbo.Production_Plan_Statuses PPSt WITH(NOLOCK)
						ON PPSt.PP_Status_Id = PP.PP_Status_Id
					JOIN dbo.products P WITH(NOLOCK)
						ON P.Prod_Id = PP.Prod_Id
					LEFT JOIN dbo.production_plan_starts PPS WITH(NOLOCK) 
						ON PPS.PP_Id = PP.PP_Id
							AND PPS.PU_Id IN (SELECT Location_Id FROM @FLocations)
					JOIN dbo.Bill_Of_Material_Formulation_Item bomfi WITH(NOLOCK)	
						ON pp.BOM_Formulation_Id = bomfi.BOM_Formulation_Id
					LEFT JOIN dbo.Bill_Of_Material_Substitution boms WITH(NOLOCK)	
						ON bomfi.BOM_Formulation_Item_Id = boms.BOM_Formulation_Item_Id
		WHERE		PUB.PU_Id IN (SELECT Location_Id FROM @FLocations)
					AND COALESCE(PPS.start_time, PP.Forecast_Start_Date) <= @EndTime AND COALESCE(PPS.start_time, PP.Forecast_Start_Date) > @StartTime 
					AND PPSt.PP_Status_Id IN (SELECT SchStatusId FROM @OrderStatus)
		ORDER BY	PP.Forecast_Start_Date

/*
		-- GET OLD PENDING ORDERS
		INSERT INTO	@Output
		(
			Product_Id,
			Product_code,
			Product_desc,
			Process_order_Id,
			Process_order_desc,
			Process_order_status_id,
			Process_order_status_desc,
			Planned_Start_time,
			Planned_End_time,
			Actual_Start_time,
			Actual_End_time,
			Location_id,
			Location_desc

		)
		SELECT	DISTINCT
				PP.Prod_Id 'Product_Id',
				P.Prod_code,
				P.prod_desc,
				PP.PP_Id,
				PP.Process_Order,
				PP.PP_Status_Id,
				PPSt.PP_Status_Desc,
				PP.Forecast_Start_Date,
				PP.Forecast_End_Date,
				PPS.Start_Time,
				PPS.End_time,
				PUB.PU_Id,
				PUB.pu_desc

		FROM		dbo.prod_units_Base PUB
					JOIN dbo.PrdExec_Path_Units PPU WITH(NOLOCK)
						ON PPU.PU_Id = PUB.PU_Id
					JOIN dbo.Production_plan PP WITH(NOLOCK)
						ON PP.Path_Id = PPU.Path_Id
						AND PP.Path_Id IS NOT NULL 
					JOIN dbo.Production_Plan_Statuses PPSt WITH(NOLOCK)
						ON PPSt.PP_Status_Id = PP.PP_Status_Id
					JOIN dbo.products P WITH(NOLOCK)
						ON P.Prod_Id = PP.Prod_Id
					LEFT JOIN dbo.production_plan_starts PPS WITH(NOLOCK) 
						ON PPS.PP_Id = PP.PP_Id
							AND PPS.PU_Id IN (SELECT Location_Id FROM @FLocations)
					JOIN dbo.Bill_Of_Material_Formulation_Item bomfi WITH(NOLOCK)	
						ON pp.BOM_Formulation_Id = bomfi.BOM_Formulation_Id
					LEFT JOIN dbo.Bill_Of_Material_Substitution boms WITH(NOLOCK)	
						ON bomfi.BOM_Formulation_Item_Id = boms.BOM_Formulation_Item_Id
		WHERE		PUB.PU_Id IN (SELECT Location_Id FROM @FLocations)
					AND COALESCE(PPS.start_time, PP.Forecast_Start_Date) <= @EndTime AND COALESCE(PPS.start_time, PP.Forecast_Start_Date) > @StartTime 
					AND PPSt.PP_Status_Id IN (SELECT SchStatusId FROM @OrderStatus)
		ORDER BY	PP.Forecast_Start_Date
*/
	END

	ELSE IF @StartTime IS NULL and @Endtime IS NULL
	BEGIN
		SET @EndTime = DATEADD(Day,1,GETDATE())
		-- GET LOCATION ASSIGNED PROCESS ORDERS. NO PRODUCT
		INSERT INTO	@Output
		(
			Product_Id,
			Product_code,
			Product_desc,
			Process_order_Id,
			Process_order_desc,
			Process_order_status_id,
			Process_order_status_desc,
			Planned_Start_time,
			Planned_End_time,
			Actual_Start_time,
			Actual_End_time,
			Location_id,
			Location_desc

		)
		SELECT	DISTINCT
				PP.Prod_Id 'Product_Id',
				P.Prod_code,
				P.prod_desc,
				PP.PP_Id,
				PP.Process_Order,
				PP.PP_Status_Id,
				PPSt.PP_Status_Desc,
				PP.Forecast_Start_Date,
				PP.Forecast_End_Date,
				PPS.Start_Time,
				PPS.End_time,
				PUB.PU_Id,
				PUB.pu_desc

		FROM		dbo.prod_units_Base PUB
					JOIN dbo.PrdExec_Path_Units PPU WITH(NOLOCK)
						ON PPU.PU_Id = PUB.PU_Id
					JOIN dbo.Production_plan PP WITH(NOLOCK)
						ON PP.Path_Id = PPU.Path_Id
						AND PP.Path_Id IS NOT NULL 
					JOIN dbo.Production_Plan_Statuses PPSt WITH(NOLOCK)
						ON PPSt.PP_Status_Id = PP.PP_Status_Id
					JOIN dbo.products P WITH(NOLOCK)
						ON P.Prod_Id = PP.Prod_Id
					LEFT JOIN dbo.production_plan_starts PPS WITH(NOLOCK) 
						ON PPS.PP_Id = PP.PP_Id
							AND PPS.PU_Id IN (SELECT Location_Id FROM @FLocations)
					JOIN dbo.Bill_Of_Material_Formulation_Item bomfi WITH(NOLOCK)	
						ON pp.BOM_Formulation_Id = bomfi.BOM_Formulation_Id
					LEFT JOIN dbo.Bill_Of_Material_Substitution boms WITH(NOLOCK)	
						ON bomfi.BOM_Formulation_Item_Id = boms.BOM_Formulation_Item_Id
		WHERE		PUB.PU_Id IN (SELECT Location_Id FROM @FLocations)
					AND COALESCE(PPS.start_time, PP.Forecast_Start_Date) <= @EndTime
					AND PPSt.PP_Status_Id IN (SELECT SchStatusId FROM @OrderStatus)
						--AND (bomfi.Prod_Id IN (SELECT Product_Id FROM  @FProducts) OR PP.prod_id = (SELECT Product_Id FROM  @FProducts))
		ORDER BY	PP.Forecast_Start_Date


		-- GET OLD PENDING ORDERS
		INSERT INTO	@Output
		(
			Product_Id,
			Product_code,
			Product_desc,
			Process_order_Id,
			Process_order_desc,
			Process_order_status_id,
			Process_order_status_desc,
			Planned_Start_time,
			Planned_End_time,
			Actual_Start_time,
			Actual_End_time,
			Location_id,
			Location_desc

		)
		SELECT	DISTINCT
				PP.Prod_Id 'Product_Id',
				P.Prod_code,
				P.prod_desc,
				PP.PP_Id,
				PP.Process_Order,
				PP.PP_Status_Id,
				PPSt.PP_Status_Desc,
				PP.Forecast_Start_Date,
				PP.Forecast_End_Date,
				PPS.Start_Time,
				PPS.End_time,
				PUB.PU_Id,
				PUB.pu_desc

		FROM		dbo.prod_units_Base PUB
					LEFT JOIN dbo.PrdExec_Path_Units PPU WITH(NOLOCK)
						ON PPU.PU_Id = PUB.PU_Id
					LEFT JOIN dbo.Production_plan PP WITH(NOLOCK)
						ON PP.Path_Id = PPU.Path_Id
						AND PP.Path_Id IS NOT NULL 
					JOIN dbo.Production_Plan_Statuses PPSt WITH(NOLOCK)
						ON PPSt.PP_Status_Id = PP.PP_Status_Id
					JOIN dbo.products P WITH(NOLOCK)
						ON P.Prod_Id = PP.Prod_Id
					LEFT JOIN dbo.production_plan_starts PPS WITH(NOLOCK) 
						ON PPS.PP_Id = PP.PP_Id
							AND PPS.PU_Id IN (SELECT Location_Id FROM @FLocations)
					JOIN dbo.Bill_Of_Material_Formulation_Item bomfi WITH(NOLOCK)	
						ON pp.BOM_Formulation_Id = bomfi.BOM_Formulation_Id
					LEFT JOIN dbo.Bill_Of_Material_Substitution boms WITH(NOLOCK)	
						ON bomfi.BOM_Formulation_Item_Id = boms.BOM_Formulation_Item_Id
		WHERE		PUB.PU_Id IN (SELECT Location_Id FROM @FLocations)
					AND COALESCE(PPS.start_time, PP.Forecast_Start_Date) <= @EndTime AND COALESCE(PPS.start_time, PP.Forecast_Start_Date) > @StartTime 
					AND PPSt.PP_Status_Id IN (SELECT SchStatusId FROM @OrderStatus)
		ORDER BY	PP.Forecast_Start_Date
	END
	IF EXISTS(SELECT COUNT(1) FROM @FProducts)
	BEGIN
		DELETE  @Output
		FROM	dbo.production_plan PP WITH(NOLOCK)
				JOIN @output O
					ON O.Process_order_Id = PP.PP_id
				LEFT JOIN dbo.Bill_Of_Material_Formulation_Item bomfi WITH(NOLOCK)
					ON PP.BOM_Formulation_Id = bomfi.BOM_Formulation_Id
				LEFT JOIN dbo.Bill_Of_Material_Substitution boms WITH(NOLOCK)	
					ON bomfi.BOM_Formulation_Item_Id = boms.BOM_Formulation_Item_Id
		WHERE	COALESCE(BOMS.prod_id,bomfi.Prod_Id) NOT IN (SELECT Product_Id FROM  @FProducts) OR PP.prod_id NOT IN (SELECT Product_Id FROM  @FProducts)

	END
						


	RETURN
END


--GRANT EXECUTE ON [dbo].[fnLocal_CTS_Location_Process_Orders] TO ctsWebService
--GRANT EXECUTE ON [dbo].[fnLocal_CTS_Location_Process_Orders] TO comxclient
