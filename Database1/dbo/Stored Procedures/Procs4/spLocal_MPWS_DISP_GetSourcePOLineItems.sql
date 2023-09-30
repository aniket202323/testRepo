 
 
 
/*	-------------------------------------------------------------------------------
	dbo.spLocal_MPWS_DISP_GetSourcePOLineItems
	
	Get list of PO line items that has not been fully dispensed for the PO 
	(in "RELEASED" or "DISPENSING" status).
 
	Date			Version		Build	Author  
	14-Jun-2016		001			001		Jim Cameron (GE Digital)	Initial development	
	22-Dec-2016		001			002		Jim Cameron (GE Digital)	Updated for OverrideQuantity
 
test
 
DECLARE @ErrorCode INT, @ErrorMessage VARCHAR(500)
EXEC dbo.spLocal_MPWS_DISP_GetSourcePOLineItems @ErrorCode OUTPUT, @ErrorMessage OUTPUT, 390777
 
SELECT @ErrorCode, @ErrorMessage
 
ProcessOrder	PP_Id
20151112083038	390775
20151113141739	390776
20151120105844	390777
20151120105909	390778
20151120110130	390779
20151123145047	390781
20151123145424	390782
20160527082028	390785
20160527123151	390788
 
*/	-------------------------------------------------------------------------------
 
CREATE   PROCEDURE [dbo].[spLocal_MPWS_DISP_GetSourcePOLineItems]
	@ErrorCode		INT				OUTPUT,
	@ErrorMessage	VARCHAR(500)	OUTPUT,
	@PPId			INT
 
AS
 
SET NOCOUNT ON;
 
DECLARE @paths TABLE
(
	Path_Id	INT
);
 
BEGIN TRY
 
	INSERT @paths
		SELECT DISTINCT
			pep.Path_Id
		FROM dbo.Prdexec_Paths pep
			JOIN dbo.Prod_Lines_Base pl ON pep.PL_Id = pl.PL_Id
			JOIN dbo.Departments_Base d ON pl.Dept_Id = d.Dept_Id
		WHERE d.Dept_Desc = 'Pre-Weigh';
 
	SELECT
		p.Prod_Id MaterialId,
		p.Prod_Code Material,
		p.Prod_Desc MaterialDesc,
		COUNT(bomfi.BOM_Formulation_Item_Id) DispensesRemaining,
		CAST(SUM(COALESCE(oq.Value, bomfi.Quantity)) - SUM(ISNULL(ed.Final_Dimension_X, 0.0)) AS DECIMAL(10, 3)) RemainingQty,
		eu.Eng_Unit_Code UOM
	FROM dbo.Production_Plan pp
		JOIN dbo.Bill_Of_Material_Formulation_Item bomfi ON pp.BOM_Formulation_Id = bomfi.BOM_Formulation_Id
		JOIN dbo.Products_Base p ON bomfi.Prod_Id = p.Prod_Id
		JOIN dbo.Engineering_Unit eu ON bomfi.Eng_Unit_Id = eu.Eng_Unit_Id
		CROSS APPLY dbo.fnLocal_MPWS_GetUDP(bomfi.BOM_Formulation_Item_Id, 'BOMItemStatus', 'Bill_Of_Material_Formulation_Item') s
		LEFT JOIN dbo.Production_Plan_Statuses pps ON pps.PP_Status_Id = s.Value
		LEFT JOIN dbo.Event_Details ed ON ed.PP_Id = pp.PP_Id
		LEFT JOIN dbo.Events e ON e.Event_Id = ed.Event_Id
		LEFT JOIN dbo.Tests t ON e.[Timestamp] = t.Result_On
			AND CAST(t.Result AS INT) = bomfi.BOM_Formulation_Item_Id
		LEFT JOIN dbo.Variables_Base v ON t.Var_Id = v.Var_Id
			AND v.PU_Id = e.PU_Id
		OUTER APPLY dbo.fnLocal_MPWS_GetUDP(bomfi.BOM_Formulation_Item_Id, 'OverrideQuantity',  'Bill_Of_Material_Formulation_Item') oq
	WHERE (pp.PP_Id = @PPId) -- OR @PPId IS NULL)
		AND pps.PP_Status_Desc IN ('Released', 'Dispensing')
		AND v.Test_Name = 'MPWS_DISP_BOMFIId'
		AND pp.Path_Id IN (SELECT Path_Id FROM @paths)
	GROUP BY p.Prod_Id, p.Prod_Code, p.Prod_Desc, eu.Eng_Unit_Code
	ORDER BY MaterialId
	
	SET @ErrorCode = 1;
	SET @ErrorMessage = 'Success';
 
END TRY
BEGIN CATCH
 
	SET @ErrorCode = ERROR_NUMBER();
	SET @ErrorMessage = ERROR_MESSAGE();
	
END CATCH;
 
 
 
