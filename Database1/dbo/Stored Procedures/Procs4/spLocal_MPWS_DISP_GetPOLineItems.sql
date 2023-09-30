 
 
 
 
CREATE   	PROCEDURE [dbo].[spLocal_MPWS_DISP_GetPOLineItems]
		@ErrorCode				INT				OUTPUT	,
		@ErrorMessage			VARCHAR(500)	OUTPUT	,
		@ProcessOrder			VARCHAR(255)			, 
		@MaterialId				INT						,
		@Statuses				VARCHAR(255)			,
		@DispenseStationId		INT						,
		@AllowedMaterialsOnly	BIT = 0,
		@PathId					INT				-- =	29		
 
AS	
 
SET NOCOUNT ON
 
 
-------------------------------------------------------------------------------
-- Return list of PO Line items by Process Order OR Material 
 
/*
 --select prod_id,prod_code from products where prod_code='10045960'
declare @ErrorCode INT, @ErrorMessage VARCHAR(500)
exec spLocal_MPWS_DISP_GetPOLineItems @ErrorCode OUTPUT, @ErrorMessage OUTPUT, NULL, 10530,'Released,Dispensing', 5631, 0, 107
select @ErrorCode, @ErrorMessage
*/
 
-- Date         Version Build Author  
-- 19-Nov-2015  001     001    Susan Lee (GEIP)				Initial development	
-- 20-May-2016	001		001	  Gopinath K (GE)				'DispenseStationId' UDP excluded,
--															BOMFI.PU_Id used instead.
-- 02-Jun-2016	001		002		Jim Cameron (GE Digital)	added @AllowedMaterialsOnly filter
--															added back in DispenseStationId UDP
-- 15-Jun-2016	001		003		Jim Cameron (GE Digital)	Changed getting dispense event bomfi id's from a UDP to a variable
-- 22-Dec-2016	001		004		Jim Cameron (GE Digital)	Updated for CanOverrideQty and OverrideQuantity
-- 02-Jun-2017  001     005     Susan Lee (GE Digital)		Added filter for PO status of passed in statuses in addition to BOM statuses
--															Updated material BOM list to order by PO priority and BOMFI to mimic spLocal_MPWS_DISP_GetDispenseStationInfo
 
-------------------------------------------------------------------------------
-- Declare Variables
-------------------------------------------------------------------------------
 
 
DECLARE		@tPOItemList			TABLE
(	
	Id					INT					IDENTITY(1,1)	NOT NULL,
	PPId				INT				,
	ProcessOrder		VARCHAR(255)	,
	ProdId				INT				,
	ProdCode			VARCHAR(50)		,	-- check char
	ProdDesc			VARCHAR(50)		,		-- check char
	TargetQty			FLOAT			,
	DispensedQty		FLOAT			,
	RemainingQty		FLOAT			,
	UOM					VARCHAR(50)		,	--check char
	OKToDispense		INT				,
	ItemStatus			VARCHAR(50)		,		-- check char
	DispenseStation		VARCHAR(50)		,
	BOMfiId				INT
)
 
DECLARE		@tDispenseList			TABLE
(
	BOMfi				INT				,
	EventId				INT				,
	EventNum			VARCHAR(50)		,
	Qty					FLOAT			
)	
 
DECLARE		@tDispenseSumList			TABLE
(
	BOMfi				INT				,
	SumQty					FLOAT			
)	
DECLARE		@tStatus				TABLE
(
Id		INT	IDENTITY(1,1)	NOT NULL	,
Status	VARCHAR(255)		NULL
)
-------------------------------------------------------------------------------
--  Initialize values
-------------------------------------------------------------------------------
 
SELECT	@ErrorCode		=	0,
		@ErrorMessage	=	'Initialized'
		
-------------------------------------------------------------------------------
-- Validate Parameters
-------------------------------------------------------------------------------
 
-- todo: validate material and PO, only one should be passed in
 
-------------------------------------------------------------------------------
-- Parse status
-------------------------------------------------------------------------------
 
INSERT @tStatus (Status)
SELECT *
FROM dbo.fnLocal_CmnParseListLong(@Statuses,',')
 
-------------------------------------------------------------------------------
-- GET PO line item list
-------------------------------------------------------------------------------
 
INSERT INTO @tPOItemList
	
	(PPID,ProcessOrder, ProdId,ProdCode,ProdDesc,TargetQty,UOM,OKToDispense,DispensedQty,BOMfiId )
SELECT	pp.PP_Id		,
		pp.Process_Order,
		BOMfi.Prod_Id	,
		p.Prod_Code		,
		p.Prod_Desc		,
		COALESCE(oq.Value, bomfi.Quantity),
		eu.Eng_Unit_Code,
		0				,		--default OKToDispense to false
		0				,		--default DispensedQty to 0
		BOMfi.BOM_Formulation_Item_Id
FROM	dbo.Production_Plan						pp		WITH (NOLOCK)
JOIN	dbo.Production_Plan_statuses			PPS		WITH (NOLOCK)
	ON  PP.PP_Status_Id = PPS.PP_Status_Id
JOIN	@tStatus								ppstatus
	ON	PPS.PP_Status_Desc = ppstatus.Status
JOIN	dbo.Bill_Of_Material_Formulation_Item	BOMfi	WITH (NOLOCK)
	ON	BOMfi.BOM_Formulation_Id	=	pp.BOM_Formulation_Id
JOIN	dbo.Products_Base							p		WITH (NOLOCK)
	ON	p.Prod_Id					=	BOMfi.Prod_Id
JOIN	dbo.Engineering_Unit					eu		WITH (NOLOCK)
	ON	eu.Eng_Unit_Id				=	BOMfi.Eng_Unit_Id
OUTER APPLY dbo.fnLocal_MPWS_GetUDP(bomfi.BOM_Formulation_Item_Id, 'OverrideQuantity',  'Bill_Of_Material_Formulation_Item') oq
WHERE	( @ProcessOrder = ''	OR @ProcessOrder	IS NULL		OR pp.Process_Order = @ProcessOrder )
AND		( @MaterialId	= 0		OR @MaterialId		IS NULL		OR BOMfi.Prod_Id	= @MaterialId )
AND		pp.Path_Id					=	@PathId
 
-------------------------------------------------------------------------------
-- Update Dispensed Qty and RemainingQty
-------------------------------------------------------------------------------
 
--
 
--INSERT INTO @tDispenseList
--	( BOMfi, EventId, EventNum, Qty )
--SELECT	tOutput.BOMFiId		,
--		e.event_id			,
--		e.event_num			,
--		ed.Final_Dimension_X
--FROM	@tPOItemList						tOutput
--JOIN	dbo.Table_Fields_Values				tfv		WITH (NOLOCK)	
--	ON tfv.Value			=	tOutput.BOMfiId
--JOIN	dbo.[Events]						e		WITH (NOLOCK)
--		ON	tfv.KeyId			=	e.Event_Id
--JOIN	dbo.Event_Details					ed		WITH (NOLOCK)
--	ON	ed.Event_Id			=	e.Event_Id
 
--JOIN	dbo.Table_Fields					tf		WITH (NOLOCK) 
--	ON	tf.Table_Field_Id	=	tfv.Table_Field_Id
--JOIN	dbo.[Tables]						t		WITH (NOLOCK)
--	ON	t.TableId			=	tf.TableId 
--	AND t.TableId			=	tfv.TableId
--WHERE	tf.Table_Field_Desc	=	'BOMFormulationItemID'
--	AND	t.TableName			=	'Event_Details'
 
INSERT @tDispenseList (BOMfi, EventId, EventNum, Qty)
	SELECT
		t.Result BOMfi,
		e.Event_Id,
		e.Event_Num,
		ed.Final_Dimension_X
	FROM dbo.Events e
		JOIN dbo.Event_Details ed ON e.Event_Id = ed.Event_Id
		LEFT JOIN dbo.Tests t ON e.[Timestamp] = t.Result_On
		LEFT JOIN dbo.Variables_Base v ON t.Var_Id = v.Var_Id
	WHERE v.PU_Id = @DispenseStationId
		AND v.Test_Name = 'MPWS_DISP_BOMFIId'
		AND t.Result IN (SELECT DISTINCT BOMfiId FROM @tPOItemList)
		
--select * from @tDispenseList  --debug
 
INSERT INTO @tDispenseSumList
	( SumQty, BOMfi )
SELECT	DispensedQty	= ISNULL(SUM(tDispense.Qty), 0.0),
		BOMfiId			= tDispense.BOMfi
FROM	@tPOItemList						tOutput
JOIN	@tDispenseList						tDispense
	ON	tOutput.BOMfiId		=	tDispense.BOMfi
GROUP BY tDispense.BOMfi
 
UPDATE	@tPOItemList
SET		DispensedQty	=	ISNULL(tSum.SumQty, 0.0)					,
		RemainingQty	=	tOutput.TargetQty - ISNULL(tSum.SumQty, 0.0)
FROM    @tPOItemList						tOutput
JOIN	@tDispenseSumList					tSum
	ON	tOutput.BOMfiId		=	tSum.BOMfi
 
-------------------------------------------------------------------------------
-- Update OKToDispense by checking materials
-------------------------------------------------------------------------------
 
UPDATE	@tPOItemList
SET		OKToDispense	=	1
FROM	@tPOItemList						tOutput
JOIN	dbo.PU_Products						pup
	ON	tOutput.ProdId		=	pup.Prod_Id
	AND	pup.PU_Id			=	@DispenseStationId
	
-------------------------------------------------------------------------------
-- Update ItemStatus  
-------------------------------------------------------------------------------
 
UPDATE	tOutput
SET		ItemStatus	=	pps.PP_Status_Desc
FROM	@tPOItemList						tOutput
JOIN	dbo.Table_Fields_Values				tfv		WITH (NOLOCK)	
	ON tfv.KeyId			=	tOutput.BOMfiId
JOIN	dbo.Table_Fields					tf		WITH (NOLOCK) 
	ON	tf.Table_Field_Id	=	tfv.Table_Field_Id
JOIN	dbo.[Tables]						t		WITH (NOLOCK)
	ON	t.TableId			=	tf.TableId 
	AND t.TableId			=	tfv.TableId
JOIN	dbo.Production_Plan_Statuses		pps		WITH (NOLOCK)
	ON	tfv.Value = convert(varchar(25),pps.PP_Status_Id)
WHERE	tf.Table_Field_Desc	=	'BOMItemStatus'
	AND	t.TableName			=	'Bill_Of_Material_Formulation_Item'
 
 
-------------------------------------------------------------------------------
-- Update DispenseStation  -todo: needs to be tested
-------------------------------------------------------------------------------
--2016-05-20: START
--UPDATE	tOutput
--SET		DispenseStation	=	tfv.Value
--FROM	@tPOItemList						tOutput
--JOIN	dbo.Table_Fields_Values				tfv		WITH (NOLOCK)	
--	ON tfv.KeyId			=	tOutput.BOMfiId
--JOIN	dbo.Table_Fields					tf		WITH (NOLOCK) 
--	ON	tf.Table_Field_Id	=	tfv.Table_Field_Id
--JOIN	dbo.[Tables]						t		WITH (NOLOCK)
--	ON	t.TableId			=	tf.TableId 
--	AND t.TableId			=	tfv.TableId
--WHERE	tf.Table_Field_Desc	=	'DispenseStationId'
--	AND	t.TableName			=	'Bill_Of_Material_Formulation_Item'
--2016-05-20: END
 
UPDATE t
	SET DispenseStation = (SELECT PU_Desc FROM dbo.Prod_Units_Base WHERE Equipment_Type = 'Dispense Station' AND PU_Id = dbo.fnLocal_GetUDP(BOMfiId, 'DispenseStationId', 'Bill_Of_Material_Formulation_Item'))
	FROM @tPOItemList t
 
-------------------------------------------------------------------------------
-- Return Data Table
-------------------------------------------------------------------------------
 
SELECT	@ErrorMessage	=	'SUCCESS'
 
---- TODO: REMOVE THIS CHUNK. IT IS USED TO SIMULATE DIFFERENT PRIORITIES FOR iFIX TESTING
--;with a as
--(
--	select
--		*,
--		ROW_NUMBER() OVER(ORDER BY ProdId) rowno
--	from @tPOItemList
--)
--update a
--	set OkToDispense = OkToDispense & rowno
 
IF @ProcessOrder IS NOT NULL
-- BY PO
BEGIN
	
	SELECT		
		--tp.ProcessOrder		AS	ProcessOrder,
		--ProdId				AS	MaterialId,
		ProdCode			AS	Material,
		ProdDesc			AS	Description,		
		CAST(TargetQty AS DECIMAL(10, 3))		AS	TargetQty,
		CAST(DispensedQty AS DECIMAL(10, 3))	AS	DispQty,
		--CAST(ISNULL(RemainingQty, 0.0) AS DECIMAL(10, 3))	AS	RemainQty,
		CAST(TargetQty - DispensedQty AS DECIMAL(10, 3)) AS RemainQty,
		UOM					AS	UOM,
		CASE	WHEN [OkToDispense]=1 THEN 'Y'
				WHEN [OkToDispense]=0 THEN 'N'
		END					AS	DispOK,
		ItemStatus			AS	Status,		
		DispenseStation		AS	DispStation,
		BOMfiId				AS	BOMfiId
	FROM	@tPOItemList tp
		JOIN @tStatus ts ON ts.[Status] = tp.ItemStatus
	WHERE OkToDispense >= @AllowedMaterialsOnly	-- allowed = 0 gets Ok = 0 & 1 (Y&N), allowed = 1 gets only Ok = 1 (Y)
	ORDER BY ProdCode --, tp.ProcessOrder
			
END
ELSE
-- BY Material
BEGIN
 
	SELECT		
		tp.ProcessOrder		AS	ProcessOrder,
		--ProdId				AS	MaterialId,
		--ProdCode			AS	Material,
		--ProdDesc			AS	Description,		
		CAST(TargetQty AS DECIMAL(10, 3))		AS	TargetQty,
		CAST(DispensedQty AS DECIMAL(10, 3))	AS	DispQty,
		--CAST(ISNULL(RemainingQty, 0.0) AS DECIMAL(10, 3))	AS	RemainQty,
		CAST(TargetQty - DispensedQty AS DECIMAL(10, 3)) AS RemainQty,
		UOM					AS	UOM,
		CASE	WHEN [OkToDispense]=1 THEN 'Y'
				WHEN [OkToDispense]=0 THEN 'N'
		END					AS	DispOK,
		ItemStatus			AS	Status,		
		DispenseStation		AS	DispStation,
		BOMfiId				AS	BOMfiId
	FROM	@tPOItemList tp
		JOIN @tStatus ts ON ts.[Status] = tp.ItemStatus
		OUTER APPLY dbo.fnLocal_MPWS_GetUDP(tp.PPId, 'PreWeighProcessOrderPriority', 'Production_Plan') pr
	WHERE OkToDispense >= @AllowedMaterialsOnly	-- allowed = 0 gets Ok = 0 & 1 (Y&N), allowed = 1 gets only Ok = 1 (Y)
	ORDER BY pr.Value,BOMfiId
 
END
 
 
 
--GRANT EXECUTE ON [dbo].[spLocal_MPWS_DISP_GetPOLineItems] TO [public]
 
 
 
 
 
 
 
