

CREATE PROCEDURE dbo.spMES_GetProcessOrderDetails
	@ProcessOrderId	INT,	-- Id for a specific process order.
	@LineId			INT,	-- Line to return PO details for.
	@StatusSet	NVARCHAR(30)-- Set of status ID as a string
AS

/* Temp table to hold the StatusSet values after parsing */
DECLARE @StatusValues Table (
	StatusValue Int)

/* Parse the status set by into a temp table for later selection */
IF @StatusSet IS NOT NULL
BEGIN
	INSERT INTO @StatusValues(StatusValue)
	SELECT Id
	FROM dbo.fnCMN_IdListToTable('Production_Plan_Statuses ',@StatusSet,',')
END

SELECT path.PL_Id as LineId,
  po.PP_Id as ProcessOrderId,
  po.Process_Order as ProcessOrderName,
  product.Prod_Id as ProductId,
  product.Prod_Desc as ProductName,
  po.Forecast_Quantity as ProductQuantity,
  statusValues.PP_Status_Desc as StatusText,
  dbo.fnServer_CmnConvertFromDBTime(po.Actual_Start_Time,'UTC') as StartTime,
  pathUnits.PU_Id as ProductionPointUnitId,
  dbo.fnServer_CmnConvertFromDBTime(po.Forecast_Start_Date,'UTC') as PlannedStartDate,
  dbo.fnServer_CmnConvertFromDBTime(po.Forecast_End_Date,'UTC') as PlannedEndDate
FROM [dbo].[Prdexec_Paths] path
JOIN [dbo].Production_Plan po
ON po.Path_Id = path.Path_Id
JOIN [dbo].Production_Plan_Statuses statusValues
ON statusValues.PP_Status_Id = po.PP_Status_Id
JOIN [dbo].Products_Base product
ON product.Prod_Id = po.Prod_Id
JOIN [dbo].PrdExec_Path_Units pathUnits
ON pathUnits.Path_Id = path.Path_Id
	AND pathUnits.Is_Production_Point = 1
WHERE (@ProcessOrderId is null OR @ProcessOrderId = po.PP_Id) 
	AND (@LineId is null or @LineId = path.PL_Id)
	AND (@StatusSet is null or po.PP_Status_Id in 
		(SELECT StatusValue FROM @StatusValues))
ORDER BY LineId
