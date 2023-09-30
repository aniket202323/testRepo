 
 
CREATE   PROCEDURE [dbo].[spLocal_MPWS_DASH_MaterialsBeingDispensed]
	@ErrorCode		INT				OUTPUT,
	@ErrorMessage	VARCHAR(500)	OUTPUT,
	@ExecutionPath	INT
--WITH ENCRYPTION 
AS
 
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
 
BEGIN TRY
 

	SELECT
		p.Prod_Code MaterialDescription,
		COUNT(*) ItemCount,
		CAST(SUM(1.0 * COALESCE(oq.Value, bomfi.Quantity)) AS DECIMAL(10, 3)) [Weight],
		pu.PU_Desc DispenseStation,									-- DispenseStation to eventually be removed.
		eu.Eng_Unit_Code UOM
	FROM dbo.Production_Plan pp
		JOIN dbo.Bill_Of_Material_Formulation_Item bomfi ON pp.BOM_Formulation_Id = bomfi.BOM_Formulation_Id
		JOIN dbo.Production_Plan_Statuses pps ON pp.PP_Status_Id = pps.PP_Status_Id
		JOIN dbo.Products_Base p ON bomfi.Prod_Id = p.Prod_Id
		JOIN dbo.Engineering_Unit eu ON bomfi.Eng_Unit_Id = eu.Eng_Unit_Id
		JOIN dbo.Prod_units_Base bompu ON bompu.PU_Id = bomfi.PU_Id
		JOIN dbo.Prdexec_Paths pep ON pep.PL_Id = bompu.PL_Id AND pep.Path_Id = @ExecutionPath
		OUTER APPLY dbo.fnLocal_MPWS_GetUDP(bomfi.BOM_Formulation_Item_Id, 'DispenseStationId', 'Bill_Of_Material_Formulation_Item') ds
		LEFT JOIN dbo.Prod_Units_Base pu ON pu.PU_Id = ds.Value
		OUTER APPLY dbo.fnLocal_MPWS_GetUDP(bomfi.BOM_Formulation_Item_Id, 'OverrideQuantity',  'Bill_Of_Material_Formulation_Item') oq
	WHERE pp.Path_Id = @ExecutionPath
		AND pps.PP_Status_Desc IN ('Released', 'Dispensing')
	GROUP BY p.Prod_Code, pu.PU_Desc, eu.Eng_Unit_Code, ds.Value
 
	SET @ErrorCode = 1;
	SET @ErrorMessage = 'Success';
 
END TRY
BEGIN CATCH
 
	SET @ErrorCode = ERROR_NUMBER()
	SET @ErrorMessage = ERROR_MESSAGE()
	
END CATCH;
 
 
 
