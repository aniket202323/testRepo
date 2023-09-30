 
 
 
/*	-------------------------------------------------------------------------------
	dbo.spLocal_MPWS_DISP_GetDispenseContainer
	
	Get Dispense Container info for reassigning. 
	
	Date			Version		Build	Author  
	22-Jun-2016		001			001		Jim Cameron (GEIP)		Initial development	
	14-Sept-2017	001			002		Susan Lee (GE Digital)	made PO optional (left join) for misc dispenses without POs 
test
 
DECLARE @ErrorCode INT, @ErrorMessage VARCHAR(500)
EXEC dbo.spLocal_MPWS_DISP_GetDispenseContainer @ErrorCode OUTPUT, @ErrorMessage OUTPUT, 'DI20170912-10000001-001'
 
SELECT @ErrorCode, @ErrorMessage
 
 
*/	-------------------------------------------------------------------------------
 
CREATE   PROCEDURE [dbo].[spLocal_MPWS_DISP_GetDispenseContainer]
	@ErrorCode			INT				OUTPUT,
	@ErrorMessage		VARCHAR(500)	OUTPUT,
	@DispenseEventNum	VARCHAR(50)
 
AS
 
SET NOCOUNT ON;
	
BEGIN TRY
 
	SELECT
		DispenseId,
		MPWS_DISP_BOMFIId POLineItemId,
		PONum,
		Material,
		MaterialDesc,
		[Status],
		QtyDispensed,
		MPWS_DISP_DISPENSE_UOM UOM
	FROM (
			SELECT
				e.Event_Id DispenseId,
				ISNULL(pp.Process_Order,'') PONum,
				p.Prod_Code Material,
				p.Prod_Desc MaterialDesc,
				ps.ProdStatus_Desc [Status],
				ed.Final_Dimension_X QtyDispensed,
				v.Test_Name,
				t.Result
			FROM dbo.Event_Details ed
				JOIN dbo.Events e ON ed.Event_Id = e.Event_Id
				JOIN dbo.Variables_Base v ON v.PU_Id = e.PU_Id
				LEFT JOIN dbo.Tests t ON t.Result_On = e.[Timestamp]
					AND t.Var_Id = v.Var_Id
				JOIN dbo.Production_Status ps ON e.Event_Status = ps.ProdStatus_Id
				JOIN dbo.Products_Base p ON p.Prod_Id = e.Applied_Product
				LEFT JOIN dbo.Production_Plan pp ON ed.PP_Id = pp.PP_Id
			WHERE v.Test_Name IN ('MPWS_DISP_DISPENSE_UOM', 'MPWS_DISP_BOMFIId')
				AND e.Event_Num = @DispenseEventNum
		) a
	PIVOT (MAX(Result) FOR Test_Name IN ([MPWS_DISP_DISPENSE_UOM], [MPWS_DISP_BOMFIId])) pvt
	
	IF @@ROWCOUNT > 0
	BEGIN
		SET @ErrorCode = 1;
		SET @ErrorMessage = 'Success';
	END
	ELSE
	BEGIN
		SET @ErrorCode = -1;
		SET @ErrorMessage = 'Container not found';
	END
	
END TRY
BEGIN CATCH
 
	SET @ErrorCode = ERROR_NUMBER()
	SET @ErrorMessage = ERROR_MESSAGE()
	
END CATCH;
 
 
 
