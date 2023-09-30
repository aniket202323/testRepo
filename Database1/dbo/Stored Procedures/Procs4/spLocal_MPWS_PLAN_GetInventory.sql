 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_PLAN_GetInventory]
		@ErrorCode			INT				OUTPUT,
		@ErrorMessage		VARCHAR(255)	OUTPUT,
		@PathId				INT,
		@InventoryToView	VARCHAR(50)				-- 'To Be Ordered', 'All Released', 'All Preweigh Materials'
		
AS

--declare
--		@ErrorCode			INT				,
--		@ErrorMessage		VARCHAR(255)	,
--		@PathId				INT = 107,
--		@InventoryToView	VARCHAR(50)	='All Released'			-- 'To Be Ordered', 'All Released', 'All Preweigh Materials'

/* -------------------------------------------------------------------------------
	Get Inventory information for released and dispensing POs for the passed in path
 
	Date			Version Build	Author  
	24-Sep-2015		001		001		Alex Judkowicz (GEIP)		Initial development
	01-Aug-2016		002		001		Jim Cameron (GE Digital)	Rewrite and added RMC/Dispense quantities. 
																Converted non-KG quantities to KG. 
																Added @InventoryToView parameter.
	21-Aug-2017		002		002		Susan Lee (GE Digital)		Changed RMC "Inventory" status to "Checked In"
	29-Sep-2017		002		003     Susan Lee (GE Digital)		Added Dispense Qty to output and renamed some columns.
 
tests
 
declare @ErrorCode INT, @ErrorMessage VARCHAR(500)
--EXEC spLocal_MPWS_PLAN_GetInventory @ErrorCode OUTPUT, @ErrorMessage OUTPUT, 29, ''
--EXEC spLocal_MPWS_PLAN_GetInventory @ErrorCode OUTPUT, @ErrorMessage OUTPUT, 29, 'To Be Ordered'
--EXEC spLocal_MPWS_PLAN_GetInventory @ErrorCode OUTPUT, @ErrorMessage OUTPUT, 107, 'All Released'
EXEC spLocal_MPWS_PLAN_GetInventory @ErrorCode OUTPUT, @ErrorMessage OUTPUT, 107, 'All Preweigh Materials'
 
 
 
------------------------------------------------------------------------------- */
 
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
 
DECLARE	@tOutput TABLE
(
	HasPPId					INT,			-- zero/non-zero flag to indicate if a prod_id is part of a PO.
	ProdId					INT,
	ProdCode				VARCHAR(255),
	ProdDesc				VARCHAR(255),
	OrderQty				FLOAT,
	DispensedQty			FLOAT,
	InventoryQty			FLOAT,
	QuantityDifference		FLOAT,
	DifferencePercent		FLOAT,
	EngUnitId				INT,
	EngUnitDesc				VARCHAR(255)
);
 
INSERT	@tOutput (HasPPId, ProdId, ProdCode, ProdDesc, OrderQty, EngUnitId, EngUnitDesc)
	SELECT
		AVG(pp.PP_Id),	-- if a prod_id has at least one PO, this field will be > 0, else 0 or null. AVG used to prevent an overflow if there's a lot of PO's.
		p.Prod_Id,
		p.Prod_Code,
		p.Prod_Desc,
		SUM(CASE eu.Eng_Unit_Desc WHEN 'G' THEN bomfi.Quantity / 1000.0 ELSE bomfi.Quantity END),
		CASE MIN(eu.Eng_Unit_Desc) WHEN 'G' THEN MIN(euKG.Eng_Unit_Id) ELSE MIN(eu.Eng_Unit_Id) END,		-- MIN() so we don't need it in the GROUP BY and there's only 1 SUM per prod_id
		CASE MIN(eu.Eng_Unit_Desc) WHEN 'G' THEN MIN(euKG.Eng_Unit_Desc) ELSE MIN(eu.Eng_Unit_Desc) END
	FROM dbo.Products_Aspect_MaterialDefinition  prodDef
		JOIN dbo.Property_MaterialDefinition_MaterialClass propDef ON propDef.MaterialDefinitionId = prodDef.Origin1MaterialDefinitionId
		JOIN dbo.Products_Base p ON p.Prod_Id = prodDef.Prod_Id
		LEFT JOIN dbo.Bill_Of_Material_Formulation_Item BOMFI ON bomfi.Prod_Id = p.Prod_Id
		LEFT JOIN dbo.Production_Plan pp ON pp.BOM_Formulation_Id = bomfi.BOM_Formulation_Id
		LEFT JOIN dbo.Production_Plan_Statuses pps ON pps.PP_Status_Id = pp.PP_Status_Id
		LEFT JOIN dbo.Engineering_Unit eu ON eu.Eng_Unit_Id = bomfi.Eng_Unit_Id
		CROSS APPLY dbo.Engineering_Unit euKG 
	WHERE propDef.Class LIKE 'Pre-Weigh'
		AND propDef.Name = 'MaterialClass'
		AND pp.Path_Id = @PathId
		AND euKG.Eng_Unit_Desc = 'KG'
		AND pps.PP_Status_Desc IN ('Released', 'Dispensing')
	GROUP BY p.Prod_Id, p.Prod_Code, p.Prod_Desc;


 
-- get raw material container available quantities in inventory on same path
;WITH rmc AS
(
	SELECT	
		e.Applied_Product Prod_Id,
		SUM(CASE eu.Eng_Unit_Desc WHEN 'G' THEN ed.Final_Dimension_X / 1000.0 ELSE ed.Final_Dimension_X END) AvailableQty,
		CASE MIN(eu.Eng_Unit_Desc) WHEN 'G' THEN MIN(euKG.Eng_Unit_Id) ELSE MIN(eu.Eng_Unit_Id) END EngUnitId		-- MIN() so we don't need it in the GROUP BY and there's only 1 SUM per prod_id
	FROM dbo.Events e
		JOIN dbo.Event_Details ed ON e.Event_Id = ed.Event_Id
		JOIN dbo.Prod_Units_Base pu ON e.PU_Id = pu.PU_Id
		JOIN dbo.Prdexec_Paths pep ON pep.PL_Id = pu.PL_Id
		JOIN dbo.Variables_Base v ON v.PU_Id = e.PU_Id
		LEFT JOIN dbo.Tests t ON t.Result_On = e.[Timestamp]
			AND t.Var_Id = v.Var_Id
		JOIN dbo.Production_Status ps ON ps.ProdStatus_Id = e.Event_Status
		JOIN dbo.Engineering_Unit eu ON eu.Eng_Unit_Desc = t.Result
		CROSS APPLY dbo.Engineering_Unit euKG	
	WHERE pep.Path_Id = @PathId
		AND ps.ProdStatus_Desc = 'Checked In'
		AND euKG.Eng_Unit_Desc = 'KG'
		AND v.Test_Name = 'MPWS_INVN_RMC_UOM'
	GROUP BY e.Applied_Product
)
UPDATE t
	SET InventoryQty = ISNULL(AvailableQty, 0.0)
	FROM @tOutput t
		LEFT JOIN rmc ON rmc.Prod_Id = t.ProdId
			AND rmc.EngUnitId = t.EngUnitId;

-- get any dispense containers 
;WITH disp AS
(
	SELECT
		p.Prod_Id,
		SUM(CASE eu.Eng_Unit_Desc WHEN 'G' THEN ed.Final_Dimension_X / 1000.0 ELSE ed.Final_Dimension_X END) DispensedQty,
		CASE MIN(eu.Eng_Unit_Desc) WHEN 'G' THEN MIN(euKG.Eng_Unit_Id) ELSE MIN(eu.Eng_Unit_Id) END EngUnitId		-- MIN() so we don't need it in the GROUP BY and there's only 1 SUM per prod_id
	FROM dbo.Event_Details ed
		JOIN dbo.Events e ON ed.Event_Id = e.Event_Id
		JOIN dbo.Prod_Units_Base pu ON e.PU_Id = pu.PU_Id
		JOIN dbo.Prdexec_Paths pep ON pep.PL_Id = pu.PL_Id
		JOIN dbo.Variables_Base v ON v.PU_Id = e.PU_Id
		LEFT JOIN dbo.Tests t ON t.Result_On = e.[Timestamp]
			AND t.Var_Id = v.Var_Id
		JOIN dbo.Products_Base p ON p.Prod_Id = e.Applied_Product
		JOIN dbo.Production_Plan pp ON ed.PP_Id = pp.PP_Id
		JOIN dbo.Production_Plan_Statuses pps ON pps.PP_Status_Id = pp.PP_Status_Id
		JOIN dbo.Engineering_Unit eu ON eu.Eng_Unit_Desc = t.Result
		CROSS APPLY dbo.Engineering_Unit euKG	
	WHERE v.Test_Name = 'MPWS_DISP_DISPENSE_UOM'
		AND pep.Path_Id = @PathId
		AND euKG.Eng_Unit_Desc = 'KG'
		AND pps.PP_Status_Desc IN ('Released', 'Dispensing')
	GROUP BY p.Prod_Id
)
UPDATE t
	SET DispensedQty = disp.DispensedQty	
	FROM @tOutput t
		JOIN disp ON disp.Prod_Id = t.ProdId
			AND disp.EngUnitId = t.EngUnitId;
 
UPDATE	@tOutput	
		SET QuantityDifference = COALESCE(OrderQty, 0) - COALESCE(InventoryQty, 0) - COALESCE(DispensedQty, 0);
								 
UPDATE	@tOutput
		SET	DifferencePercent = 100.0 * QuantityDifference / OrderQty
		WHERE	OrderQty > 0;
								 
SELECT	
	@ErrorCode = 1,
	@ErrorMessage = 'Success';
					
SELECT
	ROW_NUMBER() OVER (ORDER BY ProdId) Id,
	ProdId,
	ProdCode,
	ProdDesc,
	CAST(OrderQty     AS DECIMAL(10, 3)) OrderQty,
	CAST(InventoryQty  AS DECIMAL(10, 3)) InventoryQty,
	CAST(DispensedQty  AS DECIMAL(10, 3)) DispensedQty,
	CAST(QuantityDifference AS DECIMAL(10, 3)) QuantityDifference,
	CAST(DifferencePercent  AS DECIMAL(10, 3)) DifferencePercent,
	EngUnitId,
	EngUnitDesc
FROM @tOutput
WHERE 
	(@InventoryToView = 'To Be Ordered' AND ISNULL(HasPPId, 0) > 0 AND QuantityDifference > 0)	-- prod_id's in a PO and need to order
	OR
	(@InventoryToView = 'All Released' AND ISNULL(HasPPId, 0) > 0)								-- prod_id's in a PO regardless of inventory
	OR
	(@InventoryToView = 'All Preweigh Materials')												-- all PW prod_id's regardless of PO or inventory
ORDER BY Id;
 
 
 
 
 
 
 
 
