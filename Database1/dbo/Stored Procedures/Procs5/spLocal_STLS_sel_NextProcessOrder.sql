/*
--------------------------------------------------------------------------------------------------------------------------------------
Name:		spLocal_STLS_sel_NextProcessOrder
Purpose:	Returns the process order that follows the one passed as an input
Date:		2019/05/13
--------------------------------------------------------------------------------------------------------------------------------------
*/
CREATE PROCEDURE [dbo].[spLocal_STLS_sel_NextProcessOrder]
	@ProductionPlanId	INT
AS
--------------------------------------------------------------------------------------------------------------------------------------
-- Declare variables
--------------------------------------------------------------------------------------------------------------------------------------
DECLARE
@PoEndTime	DATETIME
--------------------------------------------------------------------------------------------------------------------------------------
-- Get end time for the PO
--------------------------------------------------------------------------------------------------------------------------------------
SET @PoEndTime =	(
						SELECT	COALESCE(pps.End_Time, pp.Forecast_End_Date)
						FROM	dbo.Production_Plan			pp
						LEFT
						JOIN	dbo.Production_Plan_Starts	pps	ON	pp.PP_Id	= pps.PP_Id
						WHERE	pp.PP_Id = @ProductionPlanId
					)
--------------------------------------------------------------------------------------------------------------------------------------
-- Return next PO
--------------------------------------------------------------------------------------------------------------------------------------
SELECT	TOP	1
		pp.PP_Id				[ProductionPlanId],
		pp.Process_Order		[ProcessOrder],
		pp.Forecast_Start_Date	[ForecastStartTime],
		pps.Start_Time			[StartTime],
		pp.Forecast_End_Date	[ForecastEndTime],
		pps.End_Time			[EndTime]
FROM	dbo.Production_Plan	pp
LEFT
JOIN	dbo.Production_Plan_Starts	pps	ON	pp.PP_Id = pps.PP_Id
WHERE	COALESCE(pps.Start_Time, pp.Forecast_Start_Date) >= @PoEndTime
AND		pp.PP_Id != @ProductionPlanId
ORDER
BY		COALESCE(pps.Start_Time, pp.Forecast_Start_Date) ASC
--------------------------------------------------------------------------------------------------------------------------------------
--	Footer
--------------------------------------------------------------------------------------------------------------------------------------
