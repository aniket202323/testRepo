 
 
 
/*	-------------------------------------------------------------------------------
	dbo.spLocal_MPWS_DASH_WorkInProgressSummary
	
	This dashboard item provides an overview of dispensing backlog in terms of number 
	of line items, number of different materials released, and total weight of items 
	remaining to be released.
	
	Date			Version		Build	Author  
	25-May-2016		001			001		Jim Cameron (GE Digital)	Initial development	
	22-Dec-2016		001			002		Jim Cameron (GE Digital)	Updated for OverrideQuantity
 
test
 
DECLARE @ErrorCode INT, @ErrorMessage VARCHAR(500)
EXEC dbo.spLocal_MPWS_DASH_WorkInProgressSummary @ErrorCode OUTPUT, @ErrorMessage OUTPUT, 83
SELECT @ErrorCode, @ErrorMessage
 
*/	-------------------------------------------------------------------------------
 
CREATE   PROCEDURE [dbo].[spLocal_MPWS_DASH_WorkInProgressSummary]
	@ErrorCode		INT				OUTPUT,
	@ErrorMessage	VARCHAR(500)	OUTPUT,
	@ExecutionPath	INT
 
AS
 
SET NOCOUNT ON;
 
BEGIN TRY
 
	SELECT
		COUNT(*) NumOfItems,
		COUNT(DISTINCT bomfi.Prod_Id) NumOfMaterials,
		SUM(COALESCE(oq.Value, bomfi.Quantity)) WgtOfItemsKG,
		eu.Eng_Unit_Code UOM
	FROM dbo.Production_Plan pp
		JOIN dbo.Bill_Of_Material_Formulation_Item bomfi ON pp.BOM_Formulation_Id = bomfi.BOM_Formulation_Id
		JOIN dbo.Production_Plan_Statuses pps ON pp.PP_Status_Id = pps.PP_Status_Id
		JOIN dbo.Engineering_Unit eu ON bomfi.Eng_Unit_Id = eu.Eng_Unit_Id
		CROSS APPLY dbo.fnLocal_MPWS_GetUDP(bomfi.BOM_Formulation_Item_Id, 'BOMItemStatus', 'Bill_Of_Material_Formulation_Item') ds	-- used to only get PW bomfi's, the udp must exist
		OUTER APPLY dbo.fnLocal_MPWS_GetUDP(bomfi.BOM_Formulation_Item_Id, 'OverrideQuantity',  'Bill_Of_Material_Formulation_Item') oq
	WHERE pp.Path_Id = @ExecutionPath
		AND pps.PP_Status_Desc IN ('Released', 'Dispensing')
		AND ds.Value IS NOT NULL
	GROUP BY eu.Eng_Unit_Code
 
	SET @ErrorCode = 1;
	SET @ErrorMessage = 'Success';
 
END TRY
BEGIN CATCH
 
	SET @ErrorCode = ERROR_NUMBER()
	SET @ErrorMessage = ERROR_MESSAGE()
	
END CATCH;
 
 
 
