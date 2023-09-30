 
 
/*	-------------------------------------------------------------------------------
	dbo.spLocal_MPWS_RPT_KittingBody
	
	This report is used to determine if a PO has been fully preweighed. 
	When the PO is fully dispensed this report provides a record of the dispenses 
	that must be kittted to deliver the complete PO to production.
	
	This sp returns body info for spLocal_MPWS_RPT_KittingHeader
	
	Date			Version		Build	Author  
	17-Jun-2016		001			001		Jim Cameron (GEIP)		Initial development	
 
test
 
DECLARE @ErrorCode INT, @ErrorMessage VARCHAR(500)
EXEC dbo.spLocal_MPWS_RPT_KittingBody @ErrorCode OUTPUT, @ErrorMessage OUTPUT, null 
 
DECLARE @ErrorCode INT, @ErrorMessage VARCHAR(500)
EXEC dbo.spLocal_MPWS_RPT_KittingBody @ErrorCode OUTPUT, @ErrorMessage OUTPUT, '20151120105909'
 
DECLARE @ErrorCode INT, @ErrorMessage VARCHAR(500)
EXEC dbo.spLocal_MPWS_RPT_KittingBody @ErrorCode OUTPUT, @ErrorMessage OUTPUT, 'PO01'
 
SELECT @ErrorCode, @ErrorMessage
 
*/	-------------------------------------------------------------------------------
 
CREATE  PROCEDURE [dbo].[spLocal_MPWS__DBUG_PO_Disp_Kit_CSec_Car]
	@ErrorCode		INT				OUTPUT,
	@ErrorMessage	VARCHAR(500)	OUTPUT,
	@ProcessOrder	VARCHAR(50)
 
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
			PP_Id,
			DispEventId,
			DispNum,
			DispQty,
			DispPUDesc,
			MPWS_DISP_BOMFIId BOMFIId,
			MPWS_DISP_TARE_QUANTITY TareQty,
			MPWS_DISP_DISPENSE_UOM UOM,
			MPWS_DISP_SCALE DispenseScale
		FROM (
				SELECT DISTINCT
					po.PP_Id,
					ed.Event_Id AS DispEventId,
					e.Event_Num AS DispNum,
					ed.Final_Dimension_X DispQty,
					pu.PU_Desc DispPUDesc,
					v.Test_Name,
					t.Result
				FROM dbo.Event_Details ed
					JOIN dbo.Events e ON e.Event_Id = ed.Event_Id
					JOIN dbo.Prod_Units_Base pu ON pu.PU_Id = e.PU_Id
					JOIN po ON po.PP_Id = ed.PP_Id
					JOIN dbo.Variables_Base v ON v.PU_Id = e.PU_Id 
					LEFT JOIN dbo.Tests t ON t.Var_Id = v.Var_Id 
						AND t.Result_On = e.[Timestamp]
				WHERE v.Test_Name IN ('MPWS_DISP_BOMFIId', 'MPWS_DISP_TARE_QUANTITY', 'MPWS_DISP_DISPENSE_UOM', 'MPWS_DISP_SCALE')
			) a
			PIVOT (MAX(Result) FOR Test_Name IN ([MPWS_DISP_BOMFIId], [MPWS_DISP_TARE_QUANTITY], [MPWS_DISP_DISPENSE_UOM], [MPWS_DISP_SCALE])) pvt
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
	)
	, csec AS
	(
		SELECT DISTINCT
			kit.KitEventId,
			e.Event_Id CSecEventId,
			e.Event_Num CSecNum,
			pu.PU_Desc CSecPUDesc
		FROM kit
			JOIN dbo.Event_Components ec ON ec.Source_Event_Id = kit.KitEventId
			JOIN dbo.Events e ON e.Event_Id = ec.Event_Id
			JOIN dbo.Prod_Units_Base pu ON pu.PU_Id = e.PU_Id
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
			) a
			PIVOT (MAX(Result) FOR Var_Desc IN ([CarrierType], [CarrierSection])) pvt
 
	)
	SELECT 
		po.PP_Id, po.Process_Order, 
		disp.DispEventId, disp.DispNum, disp.DispQty, disp.DispPUDesc, 
		kit.KitEventId, kit.KitNum, kit.KitPUDesc, 
		csec.CSecEventId, csec.CSecNum, csec.CSecPUDesc, 
		car.CarEventId, car.CarNum, car.CarPUDesc, car.CarrierType, car.CarrierSections
	FROM po
		left JOIN disp ON disp.pp_id = po.pp_id
		left join kit on kit.dispeventid = disp.dispeventid
		left join csec on csec.kiteventid = kit.kiteventid
		left join car on car.cseceventid = csec.cseceventid
	
	--SELECT
	--	NULL Kit,				-- Kit Event_Num
	--	NULL Carrier,			-- Carrier Event_Num
	--	NULL CarrierSection,	-- 
	--	NULL Material,			-- BOMFI GCAS - Prod_Code
	--	NULL MaterialDesc,		-- BOMFI Prod_Desc
	--	NULL TargetWgt,			-- BOMFI Quantity
	--	NULL DispensedWgt,		-- SUM(Dispense Events)
	--	NULL ContainerId,		-- Container Event_Num
	--	NULL ContainerWgt,		-- Container Final_Dimension_X
	--	NULL PGLotId			-- TBD
		
	
	SET @ErrorCode = 1;
	SET @ErrorMessage = 'Success';
	
END TRY
BEGIN CATCH
 
	SET @ErrorCode = ERROR_NUMBER()
	SET @ErrorMessage = ERROR_MESSAGE()
	
END CATCH;
 
--select e.event_id, e.event_num from event_components ec join dbo.events e on e.event_id = ec.event_id where source_event_id = 5740155
