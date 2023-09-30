 
 
 
 
CREATE    PROCEDURE [dbo].[spLocal_MPWS_DISP_GetDispenseStationInfo_test]
	@ErrorCode				INT				OUTPUT	,
	@ErrorMessage			VARCHAR(500)	OUTPUT	,
	@DispenseStationId		INT						,   -- PU_Id of dispense station
	@POLineItemId			INT						,	-- BOM formulation item Id
	@GetNextLineItem		INT = 0						-- 0 = Get @POLineItemId, 1 = Get next line item after @POLineItemId wrapping from highest ranked back to 1.
														-- used for iFix Dispense screen "Next Instance" button
 
AS	
 
 
--declare
--	@ErrorCode				INT					,
--	@ErrorMessage			VARCHAR(500)		,
--	@DispenseStationId		INT		= 5631				,   -- PU_Id of dispense station
--	@POLineItemId			INT			=1931			,	-- BOM formulation item Id
--	@GetNextLineItem		INT = 1	 
/*
-------------------------------------------------------------------------------
	Return BOM formulation item information at the dispense station
 
	Date			Version Build	Author  
	06-Oct-2015		001     001		Susan Lee		Initial development
	06-Jun-2016		002		001		Jim Cameron		Rewrite to get all bomfi's and rank them within the group, then return only the requested one.
	10-Jun-2016		002		002		Jim Cameron		Added optional param @GetNextLineItem which gets the next line item after the one passed in for iFix "Next Instance" button.
	19-Oct-2016		002		003		Jim Cameron		Added Clean Before/After Dispensing to result
	22-Dec-2016		002		004		Jim Cameron (GE Digital)	Updated for OverrideQuantity
	10-May-2017		002		005		Susan Lee (GE Digital)		Updated property name for destination folder
	15-Aug-2017		002		006		Jim Cameron		Added check for line item status = dispensed and returning -3 to ifix instead of the -2 at end which could also be invalid line item
	21-Sep-2017     002     007     Susan Lee		Do not error if status=dispensed if GetNextLineItem flag is 1
													Only exclude POs that are Complete so it will get all assigned BOM items.
	10-Oct-2017		002		008		Jim Cameron		Changed 'returning -3' to look at all rows instead of just the @POLineItemId row for status = 'dispensed'. only returns -3 if all rows are dispensed.
													Moved the Clean Before/After UPDATE to after DELETE'ing rows so fewer rows are updated and query runs faster.

select pu_id,pu_desc from prod_units where pu_desc like 'PW01DS%'
	
declare @ErrorCode INT, @ErrorMessage VARCHAR(500)
exec spLocal_MPWS_DISP_GetDispenseStationInfo_test @ErrorCode OUTPUT, @ErrorMessage OUTPUT, 4321, 6719,1
select @ErrorCode, @ErrorMessage
exec spLocal_MPWS_DISP_GetDispenseStationInfo @ErrorCode, @ErrorMessage, 3375, 5488252, 1
 
select @ErrorCode, @ErrorMessage
 
 
 
*/
 
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
DECLARE 
	@LineItemStatus VARCHAR(50),
	@SelectedRowNo	INT,
	@NextHigherRow	INT;
 
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
	CleanAfterDispensing	INT
);

DECLARE @Results TABLE
(
	CurrentDispenseCount	INT,
	TotDispenseCount		INT,
	ProcessOrder			VARCHAR(50),
	POLineItemId			INT,
	Material				VARCHAR(50),
	TargetWgt				FLOAT,
	WgtRemainingLower		FLOAT,
	WgtRemainingUpper		FLOAT,
	DispensedWgt			FLOAT,
	UOM						VARCHAR(20),
	POBatchNum				VARCHAR(50),
	ResourceCode			VARCHAR(50),
	MaterialId				INT,
	LabelFileLocation		VARCHAR(255),
	CleanBeforeDispensing	VARCHAR(255),
	CleanAfterDispensing	VARCHAR(255),

	PPId					INT,
	POLineItemStatus		VARCHAR(50),
	CurrentOrNextRow		INT	DEFAULT (0)			-- used to return the current or next row if POLineItemId row is 'dispensed' - i.e. skip returning any dispensed rows
);

DECLARE
	@LabelFileLocation VARCHAR(255) =
			(SELECT distinct
				SUBSTRING(CAST(peec.Value AS VARCHAR(7000)), 1, 255) Value
			FROM dbo.EquipmentClass_EquipmentObject eeo
				JOIN dbo.Property_Equipment_EquipmentClass peec ON eeo.EquipmentId = peec.EquipmentId
				JOIN dbo.PAEquipment_Aspect_SOAEquipment pas ON peec.EquipmentId = pas.Origin1EquipmentId
				JOIN dbo.Prod_Units_Base pu ON pas.PU_Id = pu.PU_Id
			WHERE eeo.EquipmentClassName = 'Pre-Weigh - Dispense'
				AND peec.Name = 'Dispense Label.DestinationFolder'
				AND pas.PU_Id = @DispenseStationId);
 
-------------------------------------------------------------------------------
--  Initialize output values
-------------------------------------------------------------------------------
SELECT	@ErrorCode		=	0,
		@ErrorMessage	=	'Initialized'
		
-------------------------------------------------------------------------------
-- Validate Dispense Station
-------------------------------------------------------------------------------
IF NOT EXISTS 
	( 
	SELECT 1 FROM Prod_Units_Base WHERE PU_Id = @DispenseStationId
	
	)
	BEGIN
		SELECT	@ErrorCode	=	-1	,
				@ErrorMessage = 'Invalid dispense station'
		RETURN
	END	
 
SELECT 
	@LineItemStatus = pps.PP_Status_Desc
FROM dbo.fnLocal_MPWS_GetUDP(@POLineItemId, 'BOMItemStatus', 'Bill_Of_Material_Formulation_Item') s
	JOIN dbo.Production_Plan_Statuses pps ON pps.PP_Status_Id = s.Value
 
--IF @LineItemStatus = 'Dispensed' AND @GetNextLineItem=0
--BEGIN
 
--	SELECT	
--		@ErrorCode	=	-3,
--		@ErrorMessage = 'Dispensed'
		
--	RETURN
 
--END;
 
-------------------------------------------------------------------------------
-- Validate BOM formulation Id is for PO that runs on this line
-------------------------------------------------------------------------------
 
INSERT @items (PPId, PO, BOMFIId, Quantity, ProdId, EngUnitId)
	SELECT
		pp.PP_Id,
		pp.Process_Order,
		bomfi.BOM_Formulation_Item_Id,
		COALESCE(oq.Value, bomfi.Quantity) Quantity,
		bomfi.Prod_Id,
		bomfi.Eng_Unit_Id
	FROM dbo.Bill_Of_Material_Formulation_Item bomfi
		JOIN dbo.Production_Plan pp ON bomfi.BOM_Formulation_Id = pp.BOM_Formulation_Id
		JOIN dbo.Production_Plan_Statuses pps ON pps.PP_Status_Id = pp.PP_Status_Id
		JOIN dbo.Prdexec_Paths pep ON pep.Path_Id = pp.Path_Id
		JOIN dbo.Prod_Lines_Base pl ON pep.PL_Id = pl.PL_Id
		JOIN dbo.Departments_Base d ON pl.Dept_Id = d.Dept_Id
		OUTER APPLY dbo.fnLocal_MPWS_GetUDP(bomfi.BOM_Formulation_Item_Id, 'OverrideQuantity',  'Bill_Of_Material_Formulation_Item') oq
	WHERE d.Dept_Desc = 'Pre-Weigh'
		AND pps.PP_Status_Desc NOT IN ('Complete');
 

UPDATE i
	SET DispPUId = ds.Value
	FROM @items i
		OUTER APPLY dbo.fnLocal_MPWS_GetUDP(i.BOMFIId, 'DispenseStationId', 'Bill_Of_Material_Formulation_Item') ds
  
DELETE @items
	WHERE (DispPUId <> @DispenseStationId OR DispPUId IS NULL);

UPDATE @items
	SET CleanBeforeDispensing = CONVERT(INT, CONVERT(VARCHAR(255), Prop_MaterialDef.Value))
	FROM dbo.Products_Aspect_MaterialDefinition Prod_MaterialDef
		JOIN [dbo].[Property_MaterialDefinition_MaterialClass] Prop_MaterialDef ON Prop_MaterialDef.MaterialDefinitionId = Prod_MaterialDef.Origin1MaterialDefinitionId
	WHERE Prod_MaterialDef.Prod_Id = Prod_Id
		AND Prop_MaterialDef.Class = 'Pre-Weigh'
		AND Prop_MaterialDef.Name	=  'CleanBeforeDispensing'
		AND Prop_MaterialDef.MaterialDefinitionId = Prod_MaterialDef.Origin1MaterialDefinitionId
 
UPDATE @items
	SET CleanAfterDispensing = CONVERT(INT, CONVERT(VARCHAR(255), Prop_MaterialDef.Value))
	FROM dbo.Products_Aspect_MaterialDefinition Prod_MaterialDef
		JOIN [dbo].[Property_MaterialDefinition_MaterialClass] Prop_MaterialDef ON Prop_MaterialDef.MaterialDefinitionId = Prod_MaterialDef.Origin1MaterialDefinitionId
	WHERE Prod_MaterialDef.Prod_Id = Prod_Id
		AND Prop_MaterialDef.Class = 'Pre-Weigh'
		AND Prop_MaterialDef.Name	=  'CleanAfterDispensing'
		AND Prop_MaterialDef.MaterialDefinitionId = Prod_MaterialDef.Origin1MaterialDefinitionId
 

IF NOT EXISTS 
	(
		SELECT
			i.BOMFIId
		FROM @items i
			CROSS APPLY dbo.fnLocal_MPWS_GetUDP(i.BOMFIId, 'BOMItemStatus', 'Bill_Of_Material_Formulation_Item') s
			JOIN dbo.Production_Plan_Statuses pps ON pps.PP_Status_Id = s.Value
		WHERE pps.PP_Status_Desc IN ('Dispensing', 'Released')
	)
BEGIN
 
	SELECT	
		@ErrorCode	=	-3,
		@ErrorMessage = 'Dispensed'
		
	RETURN
 
END;

;WITH bomfid AS
(
	SELECT
		ROW_NUMBER() OVER (ORDER BY pr.Value, i.BOMFIId) CurrentDispenseCount,
		COUNT(i.BOMFIId) OVER () TotDispenseCount,
		i.PO ProcessOrder,
		ROUND(CAST(pr.Value AS FLOAT), 0) POPriority,
		info.ProdLineBatchNum POBatchNum,
		i.BOMFIId BOMFI_Id,
		i.DispPUId DispenseStation,
		i.ProdId,
		p.Prod_Code Material,
		i.Quantity TargetWgt,
		eu.Eng_Unit_Code UOM,
		info.ProdLineDesc ResourceCode,
		i.CleanBeforeDispensing,
		i.CleanAfterDispensing,
		i.PPId
	FROM @items i
		JOIN dbo.Products_Base p ON i.ProdId = p.Prod_Id
		JOIN dbo.Engineering_Unit eu ON i.EngUnitId = eu.Eng_Unit_Id
		CROSS APPLY dbo.fnLocal_MPWS_GetProductionLineInfoByPwPPId(i.PPId) info
		OUTER APPLY dbo.fnLocal_MPWS_GetUDP(i.BOMFIId, 'DispenseStationId', 'Bill_Of_Material_Formulation_Item') ds
		OUTER APPLY dbo.fnLocal_MPWS_GetUDP(i.PPId, 'PreWeighProcessOrderPriority', 'Production_Plan') pr
)
--, selItem AS
--(
--	-- if @GetNextLineItem = 0 then return the row for @POLineItemId
--	-- if @GetNextLineItem = 1 then return the row following @POLineItemId wrapping from the max CurrentDispenseCount back to 1
--	SELECT
--		CASE WHEN @GetNextLineItem = 0
--			THEN CurrentDispenseCount
--			ELSE CurrentDispenseCount % TotDispenseCount + 1
--		END SelectedLineItem
--	FROM bomfid 
--	WHERE BOMFI_Id = @POLineItemId
--)
, tols AS
(
	SELECT
		Prod_Id,
		(100.0 - MPWSToleranceLower) / 100.0 MPWSToleranceLower,
		(100.0 + MPWSToleranceUpper) / 100.0 MPWSToleranceUpper
	FROM (
			SELECT
				prodDef.Prod_Id,
				propDef.Name,
				CAST(propDef.Value AS FLOAT) Value
			FROM dbo.Products_Aspect_MaterialDefinition prodDef
				JOIN dbo.Property_MaterialDefinition_MaterialClass propDef ON propDef.MaterialDefinitionId = prodDef.Origin1MaterialDefinitionId
				JOIN bomfid ON prodDef.Prod_Id = bomfid.ProdId
			WHERE propDef.Class = 'Pre-Weigh'
				AND propDef.Name IN ('MPWSToleranceLower', 'MPWSToleranceUpper')
		) a
		PIVOT (MAX(Value) FOR Name IN ([MPWSToleranceLower], [MPWSToleranceUpper])) pvt
)
, disp AS
(
	SELECT
		t.Result BOMFormulationItemID,
		SUM(ed.Final_Dimension_X) DispensedWgt
	FROM dbo.Events e
		JOIN dbo.Event_Details ed ON e.Event_Id = ed.Event_Id
		JOIN dbo.Tests t ON e.[Timestamp] = t.Result_On
		JOIN dbo.Variables_Base v ON t.Var_Id = v.Var_Id
		JOIN bomfid ON bomfid.BOMFI_Id = CAST(t.Result AS INT)
	WHERE v.PU_Id = @DispenseStationId
		AND v.Test_Name = 'MPWS_DISP_BOMFIId'
	GROUP BY t.Result
)
INSERT @Results (CurrentDispenseCount, TotDispenseCount, ProcessOrder, POLineItemId, Material, TargetWgt, WgtRemainingLower, WgtRemainingUpper, DispensedWgt, UOM, POBatchNum, ResourceCode, MaterialId, LabelFileLocation, CleanBeforeDispensing, CleanAfterDispensing, PPId, POLineItemStatus)
	SELECT
		CurrentDispenseCount,
		TotDispenseCount,
 
		ProcessOrder,
		bomfid.BOMFI_Id POLineItemId,
		Material,
		TargetWgt,
		TargetWgt * MPWSToleranceLower - ISNULL(DispensedWgt, 0.0) WgtRemainingLower,
		TargetWgt * MPWSToleranceUpper - ISNULL(DispensedWgt, 0.0) WgtRemainingUpper,
		ISNULL(DispensedWgt, 0.0) DispensedWgt,
		UOM,
		POBatchNum,
		ResourceCode,
		bomfid.ProdId MaterialId,
		@LabelFileLocation LabelFileLocation,
		CleanBeforeDispensing,
		CleanAfterDispensing,
		bomfid.PPId,
		pps.PP_Status_Desc
	FROM bomfid
		CROSS APPLY dbo.fnLocal_MPWS_GetUDP(bomfid.BOMFI_Id, 'BOMItemStatus', 'Bill_Of_Material_Formulation_Item') s
		JOIN dbo.Production_Plan_Statuses pps ON pps.PP_Status_Id = s.Value
		LEFT JOIN tols ON bomfid.ProdId = tols.Prod_Id
		LEFT JOIN disp ON disp.BOMFormulationItemID = bomfid.BOMFI_Id
	--WHERE CurrentDispenseCount = (SELECT SelectedLineItem FROM selItem)

SELECT 
	@SelectedRowNo = CurrentDispenseCount
FROM @Results r
WHERE r.POLineItemId = @POLineItemId;

DELETE @Results
WHERE POLineItemStatus = 'Dispensed';

IF (SELECT MAX(CurrentDispenseCount) FROM @Results) < @SelectedRowNo + @GetNextLineItem
BEGIN

	-- wrap around to row 1
	SELECT TOP 1
		ROW_NUMBER() OVER (ORDER BY pr.Value, POLineItemId) CurrDispenseCount,
		COUNT(POLineItemId) OVER () TotDispenseCount,
		ProcessOrder,
		POLineItemId,
		Material,
		TargetWgt,
		WgtRemainingLower,
		WgtRemainingUpper,
		DispensedWgt,
		UOM,
		POBatchNum,
		ResourceCode,
		MaterialId,
		LabelFileLocation,
		CleanBeforeDispensing,
		CleanAfterDispensing
	FROM @Results r
		OUTER APPLY dbo.fnLocal_MPWS_GetUDP(r.PPId, 'PreWeighProcessOrderPriority', 'Production_Plan') pr
	ORDER BY CurrDispenseCount;

END
ELSE
BEGIN

	SELECT TOP 1
		@NextHigherRow = CurrentDispenseCount
	FROM @Results
	WHERE CurrentDispenseCount >= @SelectedRowNo + @GetNextLineItem
	ORDER BY CurrentDispenseCount;

	UPDATE @Results
		SET CurrentOrNextRow = 1
		WHERE CurrentDispenseCount = @NextHigherRow;

	-- renumber
	;WITH a AS
	(
		SELECT
			*,
			ROW_NUMBER() OVER (ORDER BY pr.Value, POLineItemId) curr,
			COUNT(POLineItemId) OVER () tot
		FROM @Results r
			OUTER APPLY dbo.fnLocal_MPWS_GetUDP(r.PPId, 'PreWeighProcessOrderPriority', 'Production_Plan') pr
	)
	UPDATE a
		SET CurrentDispenseCount = curr,
			TotDispenseCount = tot;

	SELECT
		CurrentDispenseCount CurrDispenseCount,
		TotDispenseCount,
		ProcessOrder,
		POLineItemId,
		Material,
		TargetWgt,
		WgtRemainingLower,
		WgtRemainingUpper,
		DispensedWgt,
		UOM,
		POBatchNum,
		ResourceCode,
		MaterialId,
		LabelFileLocation,
		CleanBeforeDispensing,
		CleanAfterDispensing
	FROM @Results r
	WHERE CurrentOrNextRow = 1

END;

IF @@ROWCOUNT > 0
BEGIN
 
	SELECT
		@ErrorCode		=	1,
		@ErrorMessage	=	'Success'
 
END
ELSE
BEGIN
 
	SELECT
		@ErrorCode		=	-2,
		@ErrorMessage	=	'No Data Found'
 
END
 
 
