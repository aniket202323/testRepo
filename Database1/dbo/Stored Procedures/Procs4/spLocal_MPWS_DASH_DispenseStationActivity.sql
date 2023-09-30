 
 
 
/*	-------------------------------------------------------------------------------
	dbo.spLocal_MPWS_DASH_DispenseStationActivity
	
	This dashboard item shows which dispense stations have logged in users and what 
	materials are being dispensed at each one. 	
	
	Date			Version		Build	Author  
	27-May-2016		001			001		Jim Cameron (GE Digital)	Initial development	
	27-June-2016	002			002		Chris Donnelly (GE Digital) - Added PO NUM and Dispense Method
										-Not implemented - remmed out - due to grouping issues changing dataset behavior
	28-Jun-2016		002			003		Jim Cameron (GE Digital)	Added Operator, DispenseMethod and ProcessOrder.
	22-Dec-2016		002			004		Jim Cameron (GE Digital)	Updated for CanOverrideQty and OverrideQuantity
	
test
 
DECLARE @ErrorCode INT, @ErrorMessage VARCHAR(500)
EXEC dbo.spLocal_MPWS_DASH_DispenseStationActivity @ErrorCode OUTPUT, @ErrorMessage OUTPUT, '83'
EXEC dbo.spLocal_MPWS_DASH_DispenseStationActivity @ErrorCode OUTPUT, @ErrorMessage OUTPUT, '30'
EXEC dbo.spLocal_MPWS_DASH_DispenseStationActivity @ErrorCode OUTPUT, @ErrorMessage OUTPUT, '29,30'
SELECT @ErrorCode, @ErrorMessage
 
 
*/	-------------------------------------------------------------------------------
 
CREATE   PROCEDURE [dbo].[spLocal_MPWS_DASH_DispenseStationActivity]
	@ErrorCode			INT				OUTPUT,
	@ErrorMessage		VARCHAR(500)	OUTPUT,
	@ExecutionPathMask	VARCHAR(255)
 
AS
 
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
 
BEGIN TRY
 
	;WITH areas AS
	(
		SELECT
			pep.Path_Id ExecutionPath,
			pl.PL_Id,
			SUBSTRING(CAST(peec.Value AS VARCHAR), 1, 100) PreweighAreaName
		FROM dbo.Property_Equipment_EquipmentClass peec
			JOIN dbo.EquipmentClass_EquipmentObject eeo ON eeo.EquipmentId = peec.EquipmentId
			LEFT JOIN dbo.PAEquipment_Aspect_SOAEquipment pas ON peec.EquipmentId = pas.Origin1EquipmentId
			LEFT JOIN dbo.Prod_Lines_Base pl ON pas.PL_Id = pl.PL_Id
			LEFT JOIN dbo.Prdexec_Paths pep ON pep.PL_Id = pl.PL_Id
		WHERE peec.Name	= 'Security Group'
			AND eeo.EquipmentClassName =  'Pre-Weigh - Area'
	)
	, dStation AS
	(
		SELECT
			PL_Id,
			PU_Id,
			Station,
			DispenseOperator Operator,
			DispenseType DispenseMethod
		FROM (
				SELECT
					pu.PL_Id,
					pu.PU_Id,
					peec.Name,
					SUBSTRING(CAST(peec.Value AS VARCHAR), 1, 100) Value,
					pu.PU_Desc Station
				FROM dbo.EquipmentClass_EquipmentObject eeo
					JOIN dbo.Property_Equipment_EquipmentClass peec ON eeo.EquipmentId = peec.EquipmentId
					JOIN dbo.PAEquipment_Aspect_SOAEquipment pas ON peec.EquipmentId = pas.Origin1EquipmentId
					JOIN dbo.Prod_Units_Base pu ON pas.PU_Id = pu.PU_Id
				WHERE eeo.EquipmentClassName = 'Pre-Weigh - Dispense'
					AND peec.Name IN ('DispenseOperator', 'DispenseType') ) a
				PIVOT (MAX(Value) FOR Name IN ([DispenseOperator], [DispenseType])) pvt
	)
	, bomfis AS
	(
		-- we need to look up DispenseStationId by BOM_Formulation_Item_Id 
		-- so reduce resultset we need to search by only getting released/dispensing
		SELECT
			pp.PP_Id,
			pp.Path_Id,
			bomfi.BOM_Formulation_Item_Id,
			ds.Value DispenseStationId,
			bs.Value BOMItemStatus,
			CASE WHEN dstat.DispenseMethod LIKE '%Material%' THEN p.Prod_Desc ELSE '' END Prod_Desc,
			CASE WHEN dstat.DispenseMethod LIKE '%Material%' THEN p.Prod_Code ELSE '' END Prod_Code,
			COALESCE(oq.Value, bomfi.Quantity) Quantity,
			eu.Eng_Unit_Code UOM,
			CASE WHEN dstat.DispenseMethod LIKE '%PO%' THEN pp.Process_Order ELSE '' END ProcessOrder,
			ISNULL(CAST(propDef.Value AS INT), 0) CanOverrideQty
		FROM areas
			JOIN dbo.Production_Plan pp ON pp.Path_Id = areas.ExecutionPath
			JOIN dbo.Bill_Of_Material_Formulation_Item bomfi ON pp.BOM_Formulation_Id = bomfi.BOM_Formulation_Id
			JOIN dbo.Production_Plan_Statuses pps ON pp.PP_Status_Id = pps.PP_Status_Id
			JOIN dbo.Engineering_Unit eu ON bomfi.Eng_Unit_Id = eu.Eng_Unit_Id
			JOIN dbo.Products_Base p ON p.Prod_Id = bomfi.Prod_Id
			CROSS APPLY dbo.fnLocal_MPWS_GetUDP(bomfi.BOM_Formulation_Item_Id, 'BOMItemStatus',     'Bill_Of_Material_Formulation_Item') bs
			CROSS APPLY dbo.fnLocal_MPWS_GetUDP(bomfi.BOM_Formulation_Item_Id, 'DispenseStationId', 'Bill_Of_Material_Formulation_Item') ds
			JOIN dStation dstat ON dstat.PL_Id = areas.PL_Id
				AND dstat.PU_Id = ds.Value
			OUTER APPLY dbo.fnLocal_MPWS_GetUDP(bomfi.BOM_Formulation_Item_Id, 'OverrideQuantity',  'Bill_Of_Material_Formulation_Item') oq
			LEFT JOIN dbo.Products_Aspect_MaterialDefinition prodDef ON prodDef.Prod_Id = bomfi.Prod_Id
			LEFT JOIN dbo.Property_MaterialDefinition_MaterialClass propDef ON propDef.MaterialDefinitionId = prodDef.Origin1MaterialDefinitionId
				AND propDef.Class = 'Pre-Weigh'
				AND propDef.Name = 'CanOverrideQty'
		WHERE pps.PP_Status_Desc IN ('Released', 'Dispensing')
	)
	SELECT
		CAST(areas.PreweighAreaName AS VARCHAR(100)) PreweighAreaName,
		d.Station,
		CAST(d.Operator AS VARCHAR(100)) Operator,
		CAST(d.DispenseMethod AS VARCHAR(100)) DispenseMethod,
		bomfis.ProcessOrder,
		bomfis.Prod_Code GCAS,
		bomfis.Prod_Desc [Description],
		SUM(bomfis.Quantity) [Weight],
		bomfis.UOM,
		ISNULL(bomfis.CanOverrideQty, 0) CanOverrideQty
	FROM dStation d
		JOIN areas ON d.PL_Id = areas.PL_Id
		LEFT JOIN bomfis ON d.PU_Id = bomfis.DispenseStationId
	WHERE areas.ExecutionPath IN (	SELECT
										x.y.value('.', 'int') PathId
									FROM (SELECT CAST('<p>' + REPLACE(@ExecutionPathMask, ',', '</p><p>') + '</p>' AS XML) q) p
										CROSS APPLY q.nodes('/p/text()') x(y)
								)
	GROUP BY areas.PreweighAreaName, d.Station, d.Operator, d.DispenseMethod, bomfis.ProcessOrder, bomfis.Prod_Code, bomfis.Prod_Desc, bomfis.UOM, bomfis.CanOverrideQty
	ORDER BY d.Station
	
	SET @ErrorCode = 1;
	SET @ErrorMessage = 'Success';
 
END TRY
BEGIN CATCH
 
	SET @ErrorCode = ERROR_NUMBER()
	SET @ErrorMessage = ERROR_MESSAGE()
	
END CATCH;
 
 
 
