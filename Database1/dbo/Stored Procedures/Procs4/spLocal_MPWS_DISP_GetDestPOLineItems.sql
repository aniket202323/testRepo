 
 
/*	-------------------------------------------------------------------------------
	dbo.spLocal_MPWS_DISP_GetDestPOLineItems
	
	Date			Version		Build	Author  
	14-Jun-2016		001			001		Jim Cameron (GEIP)		Initial development	
 
test
 
DECLARE @ErrorCode INT, @ErrorMessage VARCHAR(500)
EXEC dbo.spLocal_MPWS_DISP_GetDestPOLineItems @ErrorCode OUTPUT, @ErrorMessage OUTPUT, 5738916
 
SELECT @ErrorCode, @ErrorMessage
 
select 
	ed.event_id,
	pp.process_order
from dbo.event_details ed
join dbo.production_plan pp on ed.pp_id = pp.pp_id and pp.path_id in (29, 39)
 
*/	-------------------------------------------------------------------------------
 
CREATE  PROCEDURE [dbo].[spLocal_MPWS_DISP_GetDestPOLineItems]
	@ErrorCode		INT				OUTPUT,
	@ErrorMessage	VARCHAR(500)	OUTPUT,
	@DispenseId		INT
 
AS
 
SET NOCOUNT ON;
 
BEGIN TRY
 
	SELECT
		pp.Process_Order ProcessOrder,
		p.Prod_Id MaterialId,
		p.Prod_Code Material,
		pps.PP_Status_Desc [Status],
		eu.Eng_Unit_Code UOM
	FROM dbo.Event_Details ed
		JOIN dbo.Events e ON ed.Event_Id = e.Event_Id
		JOIN dbo.Production_Plan pp ON ed.PP_Id = pp.PP_Id
		JOIN dbo.Tests t ON e.[Timestamp] = t.Result_On
		JOIN dbo.Variables_Base v ON t.Var_Id = v.Var_Id
			AND v.PU_Id = e.PU_Id
		JOIN dbo.Bill_Of_Material_Formulation_Item bomfi ON CAST(t.Result AS INT) = bomfi.BOM_Formulation_Item_Id
		JOIN dbo.Products_Base p ON bomfi.Prod_Id = p.Prod_Id
		JOIN dbo.Engineering_Unit eu ON bomfi.Eng_Unit_Id = eu.Eng_Unit_Id
		CROSS APPLY dbo.fnLocal_MPWS_GetUDP(bomfi.BOM_Formulation_Item_Id, 'BOMItemStatus', 'Bill_Of_Material_Formulation_Item') s
		JOIN dbo.Production_Plan_Statuses pps ON s.Value = pps.PP_Status_Id
	WHERE ed.Event_Id = @DispenseId
		AND v.Test_Name = 'MPWS_DISP_BOMFIId'
 
	
	SET @ErrorCode = 1;
	SET @ErrorMessage = 'Success';
 
END TRY
BEGIN CATCH
 
	SET @ErrorCode = ERROR_NUMBER();
	SET @ErrorMessage = ERROR_MESSAGE();
	
END CATCH;
 
 
