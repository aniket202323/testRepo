 
 
 
/*	-------------------------------------------------------------------------------
	dbo.spLocal_MPWS_RPT_ShortOrderBody
	
	Return all materials that need to be ordered from RTCIS to satisfy released POs.
	
	
	Date			Version		Build	Author  
	20-Jun-2016		001			001		Jim Cameron (GEIP)		Initial development	
	01-Jun-2017		001			002		Susan Lee (GE Digital)	Changed RM container status check from "Inventory" to "Checked In"
	02-Jun-2017     001         003		Susan Lee (GE Digital)	Exclude materials where inventory is sufficent
	18-Sep-2017     001			004		Susan Lee (GE Digital)	Added PO status of Dispensing to the PO list and updated one of the joins to the inventory query to a where. 
 
test
 
DECLARE @ErrorCode INT, @ErrorMessage VARCHAR(500)
EXEC dbo.spLocal_MPWS_RPT_ShortOrderBody @ErrorCode OUTPUT, @ErrorMessage OUTPUT
 
SELECT @ErrorCode, @ErrorMessage
 
 
 
*/	-------------------------------------------------------------------------------
 
CREATE   PROCEDURE [dbo].[spLocal_MPWS_RPT_ShortOrderBody]
	@ErrorCode		INT				OUTPUT,
	@ErrorMessage	VARCHAR(500)	OUTPUT
 
AS
 
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	
BEGIN TRY
 
	;WITH paths AS
	(
		SELECT
			pep.Path_Id
		FROM dbo.Prdexec_Paths pep
			JOIN dbo.Prod_Lines_Base pl ON pep.PL_Id = pl.PL_Id
			JOIN dbo.Departments_Base d ON pl.Dept_Id = d.Dept_Id
		WHERE d.Dept_Desc = 'Pre-Weigh'
	)
	, items AS
	(
		SELECT
			bomfi.Prod_Id,
			eu.Eng_Unit_Code UOM,
			SUM(bomfi.Quantity) ReleasedOrderQty
		FROM dbo.Production_Plan pp
			JOIN dbo.Production_Plan_Statuses pps ON pp.PP_Status_Id = pps.PP_Status_Id
			JOIN paths ON pp.Path_Id = paths.Path_Id
			JOIN dbo.Bill_Of_Material_Formulation_Item bomfi ON pp.BOM_Formulation_Id = bomfi.BOM_Formulation_Id
			JOIN dbo.Engineering_Unit eu ON eu.Eng_Unit_Id = bomfi.Eng_Unit_Id
		WHERE pps.PP_Status_Desc IN  ('Released','Dispensing')
		GROUP BY bomfi.Prod_Id, eu.Eng_Unit_Code
	)
	, inv AS
	(
		SELECT
			e.Applied_Product Prod_Id,
			SUM(ed.Final_Dimension_X) InventoryQty
		FROM dbo.Events e
			JOIN dbo.Event_Details ed ON e.Event_Id = ed.Event_Id
			JOIN dbo.Prod_Units_Base pu ON e.PU_Id = pu.PU_Id
			JOIN dbo.Production_Status ps ON e.Event_Status = ps.ProdStatus_Id
		WHERE pu.PU_Desc LIKE '%Receiving%'
			AND ProdStatus_Desc IN ('Checked In','Weighing')
		GROUP BY e.Applied_Product
	)
	SELECT
		p.Prod_Code Material,
		p.Prod_Desc MaterialDesc,
		CAST(items.ReleasedOrderQty AS DECIMAL(10, 3)) ReleasedOrderQty,
		UPPER(items.UOM) UOM,
		CAST(ISNULL(inv.InventoryQty, 0.0) AS DECIMAL(10, 3)) InventoryQty,
		CAST((items.ReleasedOrderQty - ISNULL(inv.InventoryQty, 0.0)) AS DECIMAL(10, 3)) ToBeOrderedQty
	FROM items
		JOIN dbo.Products_Base p ON p.Prod_Id = items.Prod_Id
		LEFT JOIN inv ON inv.Prod_Id = items.Prod_Id
	WHERE inv.InventoryQty <  items.ReleasedOrderQty
	ORDER BY Material
		
	IF @@ROWCOUNT > 0
	BEGIN
		SET @ErrorCode = 1;
		SET @ErrorMessage = 'Success';
	END
	ELSE
	BEGIN
		SET @ErrorCode = -1;
		SET @ErrorMessage = 'No BOM Items found';
	END
	
END TRY
BEGIN CATCH
 
	SET @ErrorCode = ERROR_NUMBER()
	SET @ErrorMessage = ERROR_MESSAGE()
	
END CATCH;
 
 
 
