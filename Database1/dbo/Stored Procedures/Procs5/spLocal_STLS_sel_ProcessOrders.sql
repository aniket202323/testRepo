/*
--------------------------------------------------------------------------------------------------------------------------------------
Name:		spLocal_STLS_sel_ProcessOrders
Purpose:	Returns the list of possible Process Orders for the user to select when creating/updating line statuses
Date:		2019/05/13
--------------------------------------------------------------------------------------------------------------------------------------
*/
CREATE PROCEDURE [dbo].[spLocal_STLS_sel_ProcessOrders]
	@ProductionUnitDescription	VARCHAR(100),
	@StartTime					DATETIME,
	@EndTime					DATETIME
AS
--------------------------------------------------------------------------------------------------------------------------------------
-- Declarations
--------------------------------------------------------------------------------------------------------------------------------------
DECLARE @Results TABLE
(
	ProductionPlanId	INT,
	ProcessOrder		NVARCHAR(MAX),
	ForecastStartTime	DATETIME,
	ActualStartTime		DATETIME,
	ForecastEndTime		DATETIME,
	ActualEndTime		DATETIME,
	Product				NVARCHAR(MAX)
)

DECLARE
@PuId	INT
--------------------------------------------------------------------------------------------------------------------------------------
-- Get unit ID
--------------------------------------------------------------------------------------------------------------------------------------
SET @PuId =	(
				SELECT	pu.PU_Id
				FROM	dbo.Prod_Units_Base	pu	WITH(NOLOCK)
				WHERE	pu.PU_Desc = @ProductionUnitDescription
			)
--------------------------------------------------------------------------------------------------------------------------------------
-- Get the process orders that were started
--------------------------------------------------------------------------------------------------------------------------------------
INSERT INTO @Results
(
	ProductionPlanId,
	ProcessOrder,
	ForecastStartTime,
	ActualStartTime,
	ForecastEndTime,
	ActualEndTime,
	Product
)
SELECT	DISTINCT
		pp.PP_Id,
		pp.Process_Order,
		pp.Forecast_Start_Date,
		pps.Start_Time,
		pp.Forecast_End_Date,
		pps.End_Time,
		p.Prod_Code
FROM	dbo.Production_Plan			pp	WITH(NOLOCK)
JOIN	dbo.Production_Plan_Starts	pps	WITH(NOLOCK)	ON pp.PP_Id		= pps.PP_Id
LEFT
JOIN	dbo.Products_Base			p	WITH(NOLOCK)	ON pp.Prod_Id	= p.Prod_Id
WHERE	pps.PU_Id		= @PuId
AND		pps.Start_Time	< @EndTime
AND		(
			pps.End_Time	>	@StartTime
		OR	pps.End_Time	IS	NULL
		)
--------------------------------------------------------------------------------------------------------------------------------------
-- Get the process orders that weren't started
--------------------------------------------------------------------------------------------------------------------------------------
INSERT INTO @Results
(
	ProductionPlanId,
	ProcessOrder,
	ForecastStartTime,
	ActualStartTime,
	ForecastEndTime,
	ActualEndTime,
	Product
)
SELECT	DISTINCT
		pp.PP_Id,
		pp.Process_Order,
		pp.Forecast_Start_Date,
		NULL,
		pp.Forecast_End_Date,
		NULL,
		p.Prod_Code
FROM	dbo.Production_Plan		pp	WITH(NOLOCK)
LEFT
JOIN	dbo.Products_Base		p	WITH(NOLOCK)	ON pp.Prod_Id = p.Prod_Id
WHERE	pp.Forecast_Start_Date	< @EndTime
AND		pp.Forecast_End_Date	> @StartTime
AND		pp.Path_Id				IN	(
										SELECT	pepu.Path_Id
										FROM	dbo.PrdExec_Path_Units	pepu	WITH(NOLOCK)
										WHERE	pepu.PU_Id = @PuId
									)
AND		NOT EXISTS	(
						SELECT	1
						FROM	Production_Plan_Starts	pps	WITH(NOLOCK)
						WHERE	pps.PP_Id = pp.PP_ID
					)
--------------------------------------------------------------------------------------------------------------------------------------
-- Return the results
--------------------------------------------------------------------------------------------------------------------------------------
SELECT	ProductionPlanId,
		ProcessOrder,
		ForecastStartTime,
		ActualStartTime,
		ForecastEndTime,
		ActualEndTime,
		CASE
			WHEN	ForecastStartTime	<	ActualStartTime
			OR		ActualStartTime		IS	NULL
				THEN ForecastStartTime
			ELSE
				ActualStartTime
		END														[ProcessedStartTime],
		COALESCE(ActualEndTime, ForecastEndTime)				[ProcessedEndTime],
		Product
FROM	@Results
ORDER
BY		COALESCE(ActualStartTime, ForecastStartTime) ASC
--------------------------------------------------------------------------------------------------------------------------------------
--	Footer
--------------------------------------------------------------------------------------------------------------------------------------

