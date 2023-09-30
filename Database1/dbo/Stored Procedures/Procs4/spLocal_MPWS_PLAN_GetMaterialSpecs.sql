 
/*	-------------------------------------------------------------------------------
	dbo.spLocal_MPWS_PLAN_GetWorkOrder
		
	This sp returns header info for spLocal_MPWS_PLAN_GetMaterialSpecs
	
	Date			Version		Build	Author  
	03-2-18		001			001		Don Reinert (GrayMatter)		Initial development	
	03-8-18		001			002		Andrew Drake (GrayMatter)		Changed Decimal output to 3 spots
  
*/	-------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[spLocal_MPWS_PLAN_GetMaterialSpecs]
	@Message VARCHAR(50) OUTPUT,
	@MaterialName VARCHAR(50) OUTPUT,
	@LowerLimit FLOAT OUTPUT,
	@UpperLimit FLOAT OUTPUT,
	@UseByDate INT OUTPUT,
	@GCASNumber VARCHAR(25),
	@TargetWeight FLOAT

AS

DECLARE @items TABLE
(
	PPId		INT,
	PO			VARCHAR(50),
	BOMFIId		INT,
	DispPUId	INT,
	Quantity	FLOAT,
	ProdId		INT,
	EngUnitId	INT,
	CleanBeforeDispensing	INT,
	CleanAfterDispensing	INT,
	MandatoryTare			INT
);

DECLARE
	@Prod_Id INT,
	@Spec_Id INT,
	@TableID INT,
	@Value FLOAT,
	@IsKanban INT,
	@RecordCount INT,
	@Event_Id INT,
	@Timestamp DATETIME,
	@Var_Id INT,
	@LineItemStatus		VARCHAR(50),
	@SelectedRowNo		INT,
	@NextHigherRow		INT,
	@CurrentMaterial	INT
 

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
SET NOCOUNT ON;

SELECT @Spec_Id = Spec_Id
	FROM Specifications
	WHERE Spec_Desc = 'TargetWeight'

SELECT @MaterialName = Prod_Desc, @Prod_Id = Prod_Id
	FROM Products_Base
	WHERE Prod_Code = @GCASNumber

--INSERT @items (BOMFIId, Quantity,  EngUnitId)
--	SELECT
--		bomfi.BOM_Formulation_Item_Id,
--		COALESCE(oq.Value, bomfi.Quantity) Quantity,
--		bomfi.Eng_Unit_Id
--	FROM dbo.Bill_Of_Material_Formulation_Item bomfi
--		JOIN dbo.Production_Plan pp ON bomfi.BOM_Formulation_Id = pp.BOM_Formulation_Id
--		JOIN dbo.Production_Plan_Statuses pps ON pps.PP_Status_Id = pp.PP_Status_Id
--		JOIN dbo.Prdexec_Paths pep ON pep.Path_Id = pp.Path_Id
--		JOIN dbo.Prod_Lines_Base pl ON pep.PL_Id = pl.PL_Id
--		JOIN dbo.Departments_Base d ON pl.Dept_Id = d.Dept_Id
--		OUTER APPLY dbo.fnLocal_MPWS_GetUDP(bomfi.BOM_Formulation_Item_Id, 'OverrideQuantity',  'Bill_Of_Material_Formulation_Item') oq
--	WHERE d.Dept_Desc = 'Pre-Weigh'
--		AND pps.PP_Status_Desc NOT IN ('Complete')
--		and bomfi.Prod_Id = @Prod_Id

--UPDATE i
--	SET DispPUId = ds.Value
--	FROM @items i
--		OUTER APPLY dbo.fnLocal_MPWS_GetUDP(i.BOMFIId, 'DispenseStationId', 'Bill_Of_Material_Formulation_Item') ds

--;WITH bomfid AS
--(
--	SELECT
--		ROW_NUMBER() OVER (ORDER BY pr.Value, i.BOMFIId) CurrentDispenseCount,
--		COUNT(i.BOMFIId) OVER () TotDispenseCount,
--		i.PO ProcessOrder,
--		ROUND(CAST(pr.Value AS FLOAT), 0) POPriority,
--		info.ProdLineBatchNum POBatchNum,
--		i.BOMFIId BOMFI_Id,
--		i.DispPUId DispenseStation,
--		i.ProdId,
--		p.Prod_Code Material,
--		i.Quantity TargetWgt,
--		eu.Eng_Unit_Code UOM,
--		info.ProdLineDesc ResourceCode,
--		i.CleanBeforeDispensing,
--		i.CleanAfterDispensing,
--		i.MandatoryTare,
--		i.PPId
--	FROM @items i
--		JOIN dbo.Products_Base p ON i.ProdId = p.Prod_Id
--		JOIN dbo.Engineering_Unit eu ON i.EngUnitId = eu.Eng_Unit_Id
--		CROSS APPLY dbo.fnLocal_MPWS_GetProductionLineInfoByPwPPId(i.PPId) info
--		OUTER APPLY dbo.fnLocal_MPWS_GetUDP(i.BOMFIId, 'DispenseStationId', 'Bill_Of_Material_Formulation_Item') ds
--		OUTER APPLY dbo.fnLocal_MPWS_GetUDP(i.PPId, 'PreWeighProcessOrderPriority', 'Production_Plan') pr
--)

SELECT @Value = MAX(CONVERT(FLOAT, propDef.Value)) 
	FROM dbo.Products_Aspect_MaterialDefinition prodDef
	JOIN dbo.Property_MaterialDefinition_MaterialClass propDef ON propDef.MaterialDefinitionId = prodDef.Origin1MaterialDefinitionId
	--JOIN bomfid ON prodDef.Prod_Id = bomfid.ProdId
	WHERE propDef.Class = 'Pre-Weigh'
	  AND propDef.Name = 'MPWSToleranceLower'
	  AND Prod_Id = @Prod_Id

SET	@LowerLimit = FORMAT(@TargetWeight - (@TargetWeight * (@Value / 100.0)),'N3')--LIMITS SHOULD ALL BE 3 DECIMALS

SELECT @Value = MAX(CONVERT(FLOAT, propDef.Value)) 
	FROM dbo.Products_Aspect_MaterialDefinition prodDef
	JOIN dbo.Property_MaterialDefinition_MaterialClass propDef ON propDef.MaterialDefinitionId = prodDef.Origin1MaterialDefinitionId
	--JOIN bomfid ON prodDef.Prod_Id = bomfid.ProdId
	WHERE propDef.Class = 'Pre-Weigh'
	  AND propDef.Name = 'MPWSToleranceUpper'
	  AND Prod_Id = @Prod_Id

SET	@UpperLimit = FORMAT(@TargetWeight + (@TargetWeight * (@Value / 100.0)),'N3')--LIMITS SHOULD ALL BE 3 DECIMALS

SELECT @Value = MAX(CONVERT(INT, propDef.Value)) 
	FROM dbo.Products_Aspect_MaterialDefinition prodDef
	JOIN dbo.Property_MaterialDefinition_MaterialClass propDef ON propDef.MaterialDefinitionId = prodDef.Origin1MaterialDefinitionId
	--JOIN bomfid ON prodDef.Prod_Id = bomfid.ProdId
	WHERE propDef.Class = 'Pre-Weigh'
	  AND propDef.Name = 'UseByDate'
	  AND Prod_Id = @Prod_Id

SET @UseByDate = @Value

IF (@Prod_Id IS NULL)
	SET	@Message = 'Invalid Material'
IF (@LowerLimit IS NULL OR @UpperLimit IS NULL)
	SET	@Message = 'Limits for Material not Set'
ELSE IF (@UseByDate IS NULL)
	SET	@Message = 'UseByDate for Material not Set'
ELSE
	SET	@Message = 'OK'

	Select @Message AS Message,
	@MaterialName AS MaterialName,
	@LowerLimit AS LowerLimit,
	@UpperLimit AS UpperLimit,
	@UseByDate AS UseByDate

END

