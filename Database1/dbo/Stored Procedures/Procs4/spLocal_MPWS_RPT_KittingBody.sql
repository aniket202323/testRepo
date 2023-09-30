 
 
/*	-------------------------------------------------------------------------------
	dbo.spLocal_MPWS_RPT_KittingBody
	
	This report is used to determine if a PO has been fully preweighed. 
	When the PO is fully dispensed this report provides a record of the dispenses 
	that must be kittted to deliver the complete PO to production.
	
	This sp returns body info for spLocal_MPWS_RPT_KittingHeader
	
	Date			Version		Build	Author  
	17-Jun-2016		001			001		Jim Cameron (GEIP)		Initial development	
	11-Aug-2016		001			002		Susan Lee (GEIP)		return 2 tables
	19-Aug-2016		001			003		Jim Cameron				Split into 3, original sp to get data, _Grouping to get distinct groups and _Details to get the details for the groups
 
test
 
DECLARE @ErrorCode INT, @ErrorMessage VARCHAR(500)
EXEC dbo.spLocal_MPWS_RPT_KittingBody @ErrorCode OUTPUT, @ErrorMessage OUTPUT, null 
 
DECLARE @ErrorCode INT, @ErrorMessage VARCHAR(500)
EXEC dbo.spLocal_MPWS_RPT_KittingBody @ErrorCode OUTPUT, @ErrorMessage OUTPUT, '20151120105909'
 
DECLARE @ErrorCode INT, @ErrorMessage VARCHAR(500)
EXEC dbo.spLocal_MPWS_RPT_KittingBody @ErrorCode OUTPUT, @ErrorMessage OUTPUT, 'PO19'
 
SELECT @ErrorCode, @ErrorMessage
 
*/	-------------------------------------------------------------------------------
 
CREATE  PROCEDURE [dbo].[spLocal_MPWS_RPT_KittingBody]
	@ErrorCode		INT				OUTPUT,
	@ErrorMessage	VARCHAR(500)	OUTPUT,
	@ProcessOrder	VARCHAR(50)
--WITH ENCRYPTION 
AS
 
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
 
---------------------------------------------------------------------------------------------
--  Declare variables
---------------------------------------------------------------------------------------------
DECLARE @tOutput TABLE
(
		Kit					varchar(50),				
		Carrier				varchar(50),			
		CarrierSection		varchar(50), 
		Material			varchar(50),			
		MaterialDesc		varchar(50),		
		TargetWgt			float,			
		DispensedWgt		float,		
		ContainerId			varchar(50),		
		ContainerWgt		float,		
		PGLotId				varchar(50)		
)
---------------------------------------------------------------------------------------------
--  Get data
---------------------------------------------------------------------------------------------
	
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
	, po AS
	(
		SELECT DISTINCT
			pp.PP_Id,
			pp.Process_Order,
			pp.BOM_Formulation_Id
		FROM dbo.Production_Plan pp
			JOIN paths ON pp.Path_Id = paths.Path_Id
		WHERE pp.Process_Order = @ProcessOrder OR @ProcessOrder IS NULL
	)
	, bom AS
	(
		SELECT
			bomf.BOM_Formulation_Id
		FROM dbo.Bill_Of_Material_Formulation bomf
			JOIN po ON po.BOM_Formulation_Id = bomf.BOM_Formulation_Id
		WHERE bomf.BOM_Formulation_Id = po.BOM_Formulation_Id
	)
	, bitems AS
	(
		SELECT
			bomfi.BOM_Formulation_Item_Id,
			p.Prod_Id,
			p.Prod_Code,
			p.Prod_Desc,
			bomfi.Quantity TargetQuantity,
			stat.Value BOMItemStatus,
			dstation.Value DispenseStationId
		FROM dbo.Bill_Of_Material_Formulation_Item bomfi
			JOIN bom ON bom.BOM_Formulation_Id = bomfi.BOM_Formulation_Id
			JOIN dbo.Products_Base p ON bomfi.Prod_Id = p.Prod_Id
			OUTER APPLY dbo.fnLocal_MPWS_GetUDP(bomfi.BOM_Formulation_Item_Id, 'BOMItemStatus',     'Bill_Of_Material_Formulation_Item') stat
			OUTER APPLY dbo.fnLocal_MPWS_GetUDP(bomfi.BOM_Formulation_Item_Id, 'DispenseStationId', 'Bill_Of_Material_Formulation_Item') dstation
	)
	, disp AS
	(
		SELECT DISTINCT
			pvt.PP_Id,
			pvt.DispEventId,
			pvt.DispNum,
			pvt.SAPBatchNum,
			bitems.Prod_Code,
			bitems.Prod_Desc,
			bitems.TargetQuantity,
			pvt.DispQty,
			pvt.DispPUDesc,
			pvt.MPWS_DISP_BOMFIId BOMFIId,
			pvt.MPWS_DISP_TARE_QUANTITY TareQty,
			pvt.MPWS_DISP_DISPENSE_UOM UOM,
			pvt.MPWS_DISP_SCALE DispenseScale
		FROM (
				SELECT DISTINCT
					po.PP_Id,
					ed.Event_Id AS DispEventId,
					e.Event_Num AS DispNum,
					ed.Final_Dimension_X DispQty,
					pu.PU_Desc DispPUDesc,
					rmct.Result SAPBatchNum,
					v.Test_Name,
					t.Result
				FROM dbo.Event_Details ed
					JOIN dbo.Events e ON e.Event_Id = ed.Event_Id
					JOIN dbo.Prod_Units_Base pu ON pu.PU_Id = e.PU_Id
					JOIN po ON po.PP_Id = ed.PP_Id
					JOIN dbo.Event_Components  rmc_d ON rmc_d.Event_Id = e.Event_Id
					JOIN dbo.Events rmc ON rmc.event_id = rmc_d.Source_Event_Id
					JOIN dbo.Prod_Units rmcpu ON rmcpu.PU_Id = rmc.PU_Id AND rmcpu.Equipment_Type = 'Receiving Station'
					JOIN dbo.Variables rmcv ON rmcv.PU_Id = rmc.PU_Id AND rmcv.Test_Name = 'MPWS_INVN_SAP_LOT'
					LEFT JOIN dbo.Tests rmct ON rmct.Var_Id = rmcv.Var_Id AND rmct.Result_On = rmc.[TimeStamp]
					JOIN dbo.Variables_Base v ON v.PU_Id = e.PU_Id 
					LEFT JOIN dbo.Tests t ON t.Var_Id = v.Var_Id 
						AND t.Result_On = e.[Timestamp]
				WHERE v.Test_Name IN ('MPWS_DISP_BOMFIId', 'MPWS_DISP_TARE_QUANTITY', 'MPWS_DISP_DISPENSE_UOM', 'MPWS_DISP_SCALE')
					AND pu.Equipment_Type = 'Dispense Station'
			) a
			PIVOT (MAX(Result) FOR Test_Name IN ([MPWS_DISP_BOMFIId], [MPWS_DISP_TARE_QUANTITY], [MPWS_DISP_DISPENSE_UOM], [MPWS_DISP_SCALE])) pvt
			JOIN bitems ON bitems.BOM_Formulation_Item_Id = pvt.MPWS_DISP_BOMFIId
	)
	, kit AS
	(
		SELECT DISTINCT
			disp.DispEventId,
			e.Event_Id KitEventId,
			e.Event_Num KitNum,
			pu.PU_Desc KitPUDesc
		FROM disp
			JOIN dbo.Event_Components ec ON ec.Source_Event_Id = disp.DispEventId
			JOIN dbo.Events e ON e.Event_Id = ec.Event_Id
			JOIN dbo.Prod_Units_Base pu ON pu.PU_Id = e.PU_Id
		WHERE pu.Equipment_Type = 'Kitting Station'
	)
	, csec AS
	(
		SELECT
			CSecToDisp.Event_Id AS CSecEventId, 
			CSecToDisp.Source_Event_Id AS DispEventId,
			eCSec.Event_Num CSecNum
		FROM dbo.Event_Components AS CSecToDisp
			JOIN dbo.Events AS eCSec ON eCSec.Event_Id = CSecToDisp.Event_Id
			JOIN dbo.Prod_Units_Base AS puCSec ON puCSec.PU_Id = eCSec.PU_Id 
				AND puCSec.Equipment_Type = 'Carrier Section'
			JOIN dbo.Events AS eDisp ON eDisp.Event_Id = CSecToDisp.Source_Event_Id
			JOIN dbo.Prod_Units_Base AS puDisp ON puDisp.PU_Id = eDisp.PU_Id
				AND puDisp.Equipment_Type = 'Dispense Station'
	)
	, car AS
	(
		SELECT DISTINCT
			CSecEventId,
			CarEventId,
			CarNum,
			CarPUDesc,
			ISNULL(CarrierType,'Cart') CarrierType, 
			ISNULL(CarrierSection, '2x2x2') CarrierSections
		FROM (
				SELECT DISTINCT
					csec.CSecEventId,
					e.Event_Id CarEventId,
					e.Event_Num CarNum,
					pu.PU_Desc CarPUDesc,
					v.Var_Desc, 
					t.Result
				FROM csec
					JOIN dbo.Event_Components ec ON ec.Event_Id = csec.CSecEventId
					JOIN dbo.Events e ON e.Event_Id = ec.Source_Event_Id
					JOIN dbo.Prod_Units_Base pu ON pu.PU_Id = e.PU_Id
					JOIN dbo.Variables_Base v ON v.PU_Id = e.PU_Id 
					LEFT JOIN dbo.Tests t ON t.Var_Id = v.Var_Id 
						AND t.Result_On = e.[Timestamp]
				WHERE v.Var_Desc IN ('CarrierType', 'CarrierSection')
					AND pu.Equipment_Type = 'Carrier'
			) a
			PIVOT (MAX(Result) FOR Var_Desc IN ([CarrierType], [CarrierSection])) pvt
 
	)
	SELECT
		--@ProcessOrder		ProcessOrder,
		kit.KitNum			Kit,				-- Kit Event_Num
		car.CarNum			Carrier,			-- Carrier Event_Num
		csec.CSecNum		CarrierSection,	-- 
		disp.Prod_Code		Material,			-- BOMFI GCAS - Prod_Code
		disp.Prod_Desc		MaterialDesc,		-- BOMFI Prod_Desc
		disp.TargetQuantity	TargetWgt,			-- BOMFI Quantity
		CAST(SUM(disp.DispQty) OVER (PARTITION BY disp.BOMFIId) AS DECIMAL(10, 3))	TotDispensedWgt,		-- SUM(Dispense Events)
		disp.DispNum		ContainerId,		-- Container Event_Num
		CAST(disp.DispQty AS DECIMAL(10, 3)) ContainerWgt,		-- Container Final_Dimension_X
		SAPBatchNum			SAPBatchNum			-- RMC SAP batch num
	FROM po
		LEFT JOIN disp ON disp.pp_id = po.pp_id
		LEFT JOIN kit on kit.dispeventid = disp.dispeventid
		LEFT JOIN csec on csec.DispEventId = disp.dispeventid
		LEFT JOIN car on car.cseceventid = csec.cseceventid
	WHERE kit.KitNum IS NOT NULL;
	
	SET @ErrorCode = 1;
	SET @ErrorMessage = 'Success';
	
END TRY
BEGIN CATCH
 
	SET @ErrorCode = ERROR_NUMBER()
	SET @ErrorMessage = ERROR_MESSAGE()
	
END CATCH;
 
 
