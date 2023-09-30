 
 
/*	-------------------------------------------------------------------------------
	dbo.spLocal_MPWS_DISP_GetIncompletePOs
	
	Sproc to get list of POs that are not all dispensed 
	(has at least one PO line items in "RELEASED" or "DISPENSING" status.
 
	Date			Version		Build	Author  
	08-Jun-2016		001			001		Jim Cameron (GEIP)		Initial development	
 
test
 
DECLARE @ErrorCode INT, @ErrorMessage VARCHAR(500)
EXEC dbo.spLocal_MPWS_DISP_GetIncompletePOs @ErrorCode OUTPUT, @ErrorMessage OUTPUT, 29
 
SELECT @ErrorCode, @ErrorMessage
 
*/	-------------------------------------------------------------------------------
 
CREATE  PROCEDURE [dbo].[spLocal_MPWS_DISP_GetIncompletePOs]
	@ErrorCode		INT				OUTPUT,
	@ErrorMessage	VARCHAR(500)	OUTPUT,
	@PathId			INT
 
AS
 
SET NOCOUNT ON;
 
BEGIN TRY
 
	SELECT DISTINCT
		pp.Process_Order ProcessOrder,
		ps.Pattern_Code BatchNo,
		p.Prod_Code Material,
		pp.Forecast_Quantity [BatchSize],
		eu.Eng_Unit_Code UOM
	FROM dbo.Production_Plan pp
		JOIN dbo.Bill_Of_Material_Formulation_Item bomfi ON pp.BOM_Formulation_Id = bomfi.BOM_Formulation_Id
		JOIN dbo.Production_Setup ps ON pp.PP_Id = ps.PP_Id
		JOIN dbo.Products_Base p ON pp.Prod_Id = p.Prod_Id
		JOIN dbo.Bill_Of_Material_Formulation bomf ON pp.BOM_Formulation_Id = bomf.BOM_Formulation_Id
		JOIN dbo.Engineering_Unit eu ON bomf.Eng_Unit_Id = eu.Eng_Unit_Id
		OUTER APPLY dbo.fnLocal_MPWS_GetUDP(bomfi.BOM_Formulation_Item_Id, 'BOMItemStatus', 'Bill_Of_Material_Formulation_Item') s
		JOIN dbo.Production_Plan_Statuses pps ON pps.PP_Status_Id = s.Value
	WHERE pp.Path_Id = @PathId
		AND pps.PP_Status_Desc IN ('Released', 'Dispensing');
 
	SET @ErrorCode = 1;
	SET @ErrorMessage = 'Success';
 
END TRY
BEGIN CATCH
 
	SET @ErrorCode = ERROR_NUMBER();
	SET @ErrorMessage = ERROR_MESSAGE();
	
END CATCH;
 
 
