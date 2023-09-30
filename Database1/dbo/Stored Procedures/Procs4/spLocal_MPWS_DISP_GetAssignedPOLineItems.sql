 
 
 
 
CREATE  	PROCEDURE [dbo].[spLocal_MPWS_DISP_GetAssignedPOLineItems]
		@ErrorCode				INT				OUTPUT,
		@ErrorMessage			VARCHAR(500)	OUTPUT,
		@DispenseStationId		INT		-- pu_id of dispense station unit
AS	
-------------------------------------------------------------------------------
-- This stored procedures will return a list of PO line items that have been
-- assigned to the dispense station.
/*
 
declare @ErrorCode INT, @ErrorMessage VARCHAR(500)
exec spLocal_MPWS_DISP_GetAssignedPOLineItems @ErrorCode OUTPUT, @ErrorMessage OUTPUT, 4317
 
select @ErrorCode, @ErrorMessage
 
*/
-- Date         Version Build	Author  
-- 06-Oct-2015  001     001		Satya (GEIP)		Initial development	
-- 16-May-2016	001		002		Gopinath K			Exclude 'DispenseStationId' UDP ,
--													Query Performance improvement,
--													Messages
-- 03-Jun-2016	001		003		Jim Cameron (GED)	Added in DispenseStation description for iFix display
-- 17-Aug-2016	001		004		Jim Cameron (GED)	Broke out looking up dispense station from initial query because it was forcing a table scan on bomfi
--													because it had to look up the UDP on every bomfi to see if it was assigned
-- 22-Dec-2016	001		005		Jim Cameron (GE Digital)	Updated for OverrideQuantity
-- 19-May-2017  001		006		Susan Lee (GE Digital)		Changed Cross Apply to Outer Apply for dispense station UDP
--															
-------------------------------------------------------------------------------
-- Declare Variables
-------------------------------------------------------------------------------
SET NOCOUNT ON;
 
DECLARE	@AssignedPOLineItems	TABLE
(
	Id						INT				IDENTITY(1,1),
	BOMFormulationItemId	INT				NULL,
	ProcessOrder			VARCHAR(50)		NULL,
	ProdId					INT				NULL,
	ProdCode				VARCHAR(50)		NULL,	
	ProdDesc				VARCHAR(50)		NULL,	
	TargetQty				FLOAT			NULL,	-- BOM formulation item target
	RemainingQty			FLOAT			NULL,	-- subtract sum of all dispensed qty against this PO line item from the BOM formulation item target qty, event detail has UDP that holds the BOM formulation item id
	UOM						VARCHAR(50)		NULL,	-- BOM formulation item UOM -- check num of char
	PPStatus				VARCHAR(50)		NULL,
	BOMStatus				VARCHAR(50)		NULL,
	DispenseStation			VARCHAR(50)
)
 
DECLARE		@tDispenseList			TABLE
(
	BOMfi					INT				,
	EventId					INT				,
	EventNum				VARCHAR(50)		,
	Qty						FLOAT			
)	
 
DECLARE		@tDispenseSumList		TABLE
(
	BOMfi					INT				,
	SumQty					FLOAT			
)
 
DECLARE	
	@DispensedQuantity	FLOAT,
	@PUDesc				NVARCHAR(500),
	@PathId				INT;
 
-------------------------------------------------------------------------------
--  Initialize output values
-------------------------------------------------------------------------------
SELECT	@ErrorCode		=	0,						-- 1
		@ErrorMessage	=	'Initialized'				-- 'Success'
 
-------------------------------------------------------------------------------
-- Validate Parameters
-------------------------------------------------------------------------------
-- 2015-10-16
-- Preweigh Dispensing Station(s) are designated PWnnDSxx.
-- Validate PU_Id parameter.
 
SELECT @PUDesc = PU_Desc FROM dbo.Prod_Units_Base WITH (NOLOCK) WHERE PU_Id = @DispenseStationId
 
IF @PUDesc NOT LIKE 'PW%DS%'
	BEGIN
		SELECT 
			@ErrorCode		= -1,
			@ErrorMessage	= 'Invalid Dispense Station Id'
			GOTO ENDOFSP
	END
 
SELECT @PathId = (	SELECT DISTINCT
						pep.Path_Id
					FROM dbo.Prdexec_Paths pep
						JOIN dbo.Prod_Lines_Base pl ON pep.PL_Id = pl.PL_Id
						JOIN dbo.Departments_Base d ON pl.Dept_Id = d.Dept_Id
						JOIN dbo.Prod_Units_Base pu ON pl.PL_Id = pu.PL_Id
					WHERE d.Dept_Desc = 'Pre-Weigh'
						AND pu.PU_Id = @DispenseStationId);
 
-------------------------------------------------------------------------------
-- Insert/update into @AssignedPOLineItems
-------------------------------------------------------------------------------
 
;WITH a AS
(
	SELECT	
		BOMFI.BOM_Formulation_Item_Id, 
		PP.Process_Order, 
		bomfi.Prod_Id, 
		null Prod_Code, 
		null Prod_Desc, 
		isnull(COALESCE(oq.Value, bomfi.Quantity),0.0) TargQty,
		isnull(COALESCE(oq.Value, bomfi.Quantity),0.0) RemQty,		-- default remaining quantity to target quantity
		eu.Eng_Unit_Code,
		pps.PP_Status_Desc
	FROM dbo.Production_Plan pp
		JOIN dbo.Production_Plan_Statuses pps ON pps.PP_Status_Id = pp.PP_Status_Id
		JOIN dbo.Bill_Of_Material_Formulation_Item BOMfi ON BOMfi.BOM_Formulation_Id = pp.BOM_Formulation_Id
		LEFT JOIN dbo.Engineering_Unit eu ON eu.Eng_Unit_Id = BOMFI.Eng_Unit_Id
		OUTER APPLY dbo.fnLocal_MPWS_GetUDP(bomfi.BOM_Formulation_Item_Id, 'OverrideQuantity',  'Bill_Of_Material_Formulation_Item') oq
	WHERE pp.Path_Id = @PathId
		AND pps.PP_Status_Desc IN ('Released', 'Dispensing')
)
INSERT	@AssignedPOLineItems (BOMFormulationItemId, ProcessOrder, ProdId, ProdCode, ProdDesc, TargetQty, RemainingQty, UOM, PPStatus, DispenseStation)
	SELECT BOM_Formulation_Item_Id, Process_Order, Prod_Id, Prod_Code, Prod_Desc, TargQty, RemQty, Eng_Unit_Code, PP_Status_Desc, null --pu.PU_Desc
	FROM a
 
-- this cte is to avoid apparently random 'cannot convert value to int' errors when joining to prod_units
;WITH ds AS
(
	SELECT
		A.BOMFormulationItemId,
		FLOOR(d.Value) Value
	FROM @AssignedPOLineItems a
		OUTER APPLY dbo.fnLocal_MPWS_GetUDP(BOMFormulationItemId, 'DispenseStationId', 'Bill_Of_Material_Formulation_Item') d
	WHERE FLOOR(d.Value) = @DispenseStationId
)
UPDATE a
	SET DispenseStation = pu.PU_Desc
	FROM @AssignedPOLineItems a
		JOIN ds ON ds.BOMFormulationItemId = a.BOMFormulationItemId
		JOIN dbo.Prod_Units_Base pu ON pu.PU_Id = ds.Value
 
;WITH bomstatus AS
(
	SELECT
		A.BOMFormulationItemId,
		FLOOR(d.Value) Value
	FROM @AssignedPOLineItems a
		OUTER APPLY dbo.fnLocal_MPWS_GetUDP(BOMFormulationItemId, 'BOMItemStatus', 'Bill_Of_Material_Formulation_Item') d
 
)
UPDATE a
	SET BOMStatus = pps.PP_Status_Desc
	FROM @AssignedPOLineItems a
		JOIN bomstatus ON bomstatus.BOMFormulationItemId = a.BOMFormulationItemId
		JOIN dbo.Production_Plan_Statuses pps ON pps.PP_Status_Id = bomstatus.Value
 
DELETE @AssignedPOLineItems
	WHERE DispenseStation IS NULL;
 
UPDATE a
	SET ProdCode = p.Prod_Code,
		ProdDesc = p.Prod_Desc
	FROM @AssignedPOLineItems a
		JOIN dbo.Products_Base p ON a.ProdId = p.Prod_Id
		
IF @@ROWCOUNT = 0 
	BEGIN
		SELECT 
			@ErrorCode		= -2,
			@ErrorMessage	= 'Process Order Line Items not found for Dispense Station Id'
			GOTO ENDOFSP
	END	
-------------------------------------------------------------------------------
-- Calculate remaining quantity
------------------------------------------------------------------------------				
-- For each selected BOMFI above, obtain the Final Dimension X from the Event
-- record. Use the 'BOMFormulationItemID' UDP  defined on the Event Details 
-- Table that contains the  BOM Formulation Item ID to obtain the Event Id 
-- and the corresponding 
-- Event Dimension information. 
------------------------------------------------------------------------------
 
-------------------------------------------------------------------------------
-- Update Dispensed Qty and RemainingQty
-------------------------------------------------------------------------------
---- 2016-05-16
--INSERT INTO @tDispenseList
--	( BOMfi, EventId, EventNum, Qty )
--SELECT	tOutput.BOMFormulationItemId		,
--		e.event_id			,
--		e.event_num			,
--		isnull(ed.Final_Dimension_X,0.0)
--FROM		dbo.[Events]						e		WITH (NOLOCK)
--	JOIN	dbo.Event_Details					ed		WITH (NOLOCK)
--		ON	ed.Event_Id			=	e.Event_Id
--	JOIN	dbo.Table_Fields_Values				tfv		WITH (NOLOCK)
--		ON	tfv.KeyId			=	e.Event_Id 
--		AND tfv.TableId			> 0 
--	JOIN	dbo.Table_Fields					tf		WITH (NOLOCK)
--		ON	tf.Table_Field_Id	=	tfv.Table_Field_Id
--	JOIN	dbo.Tables							t		WITH (NOLOCK)
--		ON	t.TableId			=	tfv.TableId
--		AND t.TableId			=	tf.TableId
--	JOIN	@AssignedPOLineItems						tOutput
--		ON	tfv.Value			=   convert(varchar(25),tOutput.BOMFormulationItemId)
--WHERE	tf.Table_Field_Desc	=	'BOMFormulationItemID'
--	AND	 t.TableName		=	'Event_Details'
 
-- 2016-06-15
INSERT @tDispenseList (BOMfi, EventId, EventNum, Qty)
	SELECT
		t.Result BOMfi,
		e.Event_Id,
		e.Event_Num,
		ISNULL(ed.Final_Dimension_X, 0.0)
	FROM dbo.Events e
		JOIN dbo.Event_Details ed ON e.Event_Id = ed.Event_Id
		LEFT JOIN dbo.Tests t ON e.[Timestamp] = t.Result_On
		LEFT JOIN dbo.Variables_Base v ON t.Var_Id = v.Var_Id
	WHERE v.PU_Id = @DispenseStationId
		AND v.Test_Name = 'MPWS_DISP_BOMFIId'
		AND t.Result IN (SELECT DISTINCT BOMFormulationItemId FROM @AssignedPOLineItems)
 
 
INSERT INTO @tDispenseSumList
	( SumQty, BOMfi )
SELECT	DispensedQty	= SUM(tDispense.Qty),
		BOMfiId			= tDispense.BOMfi
FROM	@AssignedPOLineItems				tOutput
JOIN	@tDispenseList						tDispense
	ON	tOutput.BOMFormulationItemId		=	tDispense.BOMfi
GROUP BY tDispense.BOMfi
 
UPDATE	@AssignedPOLineItems
SET		RemainingQty	=	tOutput.TargetQty - tSum.SumQty
FROM    @AssignedPOLineItems				tOutput
JOIN	@tDispenseSumList					tSum
	ON	tOutput.BOMFormulationItemId		=	tSum.BOMfi
 
SELECT 
	@ErrorCode	  = 1,
	@ErrorMessage = 'Success'
 
ENDOFSP:
-------------------------------------------------------------------------------
-- Return Data Table
-------------------------------------------------------------------------------
SELECT	BOMFormulationItemId	POLineItemId,
		ProcessOrder			PO			,
		ProdId					ProdId		,
		ProdCode				Material	,  
		ProdDesc				MaterialDesc, 
		CAST(TargetQty AS DECIMAL(10, 3))		TargetQty	,
		CAST(RemainingQty AS DECIMAL(10, 3))	RemainingQty,
		UOM						UOM,
		BOMStatus				BOMStatus,
		DispenseStation
FROM	@AssignedPOLineItems
ORDER BY Id
 
--GRANT EXECUTE ON [dbo].[spLocal_MPWS_DISP_GetAssignedPOLineItems] TO [public]
 
 
 
