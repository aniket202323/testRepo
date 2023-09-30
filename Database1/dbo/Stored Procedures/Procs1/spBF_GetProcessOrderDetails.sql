CREATE PROCEDURE [dbo].[spBF_GetProcessOrderDetails] 
 	 @line_id 	  	  	  	 int = NULL,
 	 @processOrder_name 	  	 nvarchar(50) = NULL
AS 
IF EXISTS (
SELECT path.PL_Id
FROM [dbo].[Prdexec_Paths] path WITH(NOLOCK)
WHERE path.PL_Id = @line_id)
BEGIN
 	 
  DECLARE @DbTZ nVarChar(200)
  SELECT @DbTZ = value from site_parameters where parm_id=192
  SELECT   path.PL_Id as LineId,
           po.PP_Id as ProcessOrderId,
           po.Process_Order as ProcessOrderName,
           product.Prod_Id as ProductId,
           product.Prod_Desc as ProductName,
           po.Forecast_Quantity as ProductQuantity,
           statusValues.PP_Status_Desc as StatusText,
           dbo.fnServer_CmnConvertTime(po.Actual_Start_Time, @DbTZ,'UTC') as StartTime,
           pathUnits.PU_Id as ProductionPointUnitId,
           dbo.fnServer_CmnConvertTime(po.Forecast_Start_Date, @DbTZ,'UTC') as PlannedStartDate,
           dbo.fnServer_CmnConvertTime(po.Forecast_End_Date, @DbTZ,'UTC') as PlannedEndDate
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
  WHERE path.PL_Id = @line_id  AND po.Process_Order LIKE CASE WHEN @processOrder_name = '*' THEN '%' ELSE  '%' + @processOrder_name + '%' END
  ORDER BY LineId
END
ELSE
BEGIN
 	 -- Returning -999 when the entered Input ID is not present in DB
SELECT -999
END 
