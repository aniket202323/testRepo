--------------------------------------------------------------------------------------------------
-- Stored Procedure: spLocal_CmnMobileAppGetPalletInventory_FO02809
--------------------------------------------------------------------------------------------------
-- Author				: Linda Hudon, Symasol
-- Date created			: 2015-02-10
-- Version 				: Version <1.0>
-- SP Type				: Mobile Apps
-- Caller				: Mobile App
-- Description			: Get the inventory of pallets based on an Path id provided by Mobile Apps
-- Editor tab spacing	: 4
-------------------------------------------------------------------------------
--
-- Basic Logic in Task #
--
/*-------------------------------------------------------------------------------
--The stored proc <spLocal_CmnMobileAppGetPalletInventory_FO02809> will
--1.	Using the Path ID, identify what are the units.
		Store the path in a temp table
	
		
--2.	Get inventory of pallets information

--*/
--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ===========================================================================================
-- 1.0		2015-02-10		L.Hudon				Initial Release
-- 1.1		2015-02-11		L.Hudon				ad PEWebservice User
-- 1.2		2015-02-11		L.Hudon				change varchar for int @pathid
-- 1.3		2015-06-05		l.hudon				add process Order outpu
-- 1.4		2015-07-23		l.hudon				get the pallet regardless the PPID
-- 1.5		2015-07-29		l.hudon				get the pallet regardless the Batch
-- 1.6		2015-10-09		l.hudon				convert decimal(20,3)
-- 1.7		2016-02-28		l.hudon				remove reference to GBDB and Appversion
-- 1.8		2016-05-06		l.hudon				add PO status
-- 1.9		2016-05-26		l.hudon				add closing, active, initiate, ready overconsuemd pallet
-- 2.0		2016-06-13		Julien B. Ethier	Added pallet event id field to record set
-- 2.1		2016-10-18		U.Lapierre			Allow RMI on several units
-- 2.2		2017-04-10		Julien B. Ethier	Don't return bulk material checked-in on another line
-- 2.3		2017-05-31		Julien B. Ethier	Don't return bulk material not tied to the current line
-- 2.4		2017-06-06		Julien B. Ethier	Added "convert" statement where source data is not the
--												same data type or length then destination (table variable)
-- 2.5		2017-06-07		Julien B. Ethier	Set batch number for bulk material
--================================================================================================
--


--------------------------------------------------------------------------------------------------
-- TEST CODE:
--------------------------------------------------------------------------------------------------
/*
exec [dbo].[spLocal_CmnMobileAppGetPalletInventory_FO02809]
		62,
		1,
		1

-- SELEcT * FROM prdExec_paths 
*/

-------------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[spLocal_CmnMobileAppGetPalletInventory_FO02809]
		@PathID						int,
		@DebugFlagOnLine			int,
		@DebugFlagManual			int
		
--WITH ENCRYPTION	
AS
SET NOCOUNT ON

DECLARE
		@ErrMsg						varchar(500),
		@CallingSP					varchar(50),
		@TableId					int,
		@TableFieldId				int,
		@ErrorYes					int
		
DECLARE	@StatusInitiateID			int,
		@StatusReadyID				int,
		@StatusActiveID				int,
		@StatusClosingID			int

DECLARE @ProdUnits TABLE(
PUID		int, 
PUDesc		varchar(50))		


DECLARE @tProdUnits			TABLE (
		EquipmentId					varchar(50),
		puid						int,
		S95Id						varchar(50),
		IsBulkMaterial				bit
		)		
		
DECLARE @RMIs				TABLE(
		PeiId						int,
		InputOG						varchar(30),
		IsBulkMaterial				bit
		)

DECLARE @Inventory			TABLE (
		S95Id						varchar(50),
		EventId						int,
		ULID						varchar(25),
		DeliveryTime				datetime,
		ProdId						int,
		ProdCode					varchar(8),
		ProdDesc					varchar(50),
		Batch						varchar(25),
		StatusId					int,
		StatusDesc					varchar(50),
		DeliveredQty				float,
		RemainingQty				float,
		UOM							varchar(20),
		OG							varchar(10),
		ppid						int,					--260814				
		ProcessOrder				varchar(50),
		POStatus					varchar(50),
		IsBulkMaterial				bit)

DECLARE @TableIdPrdExecInput int ,
@TFIDOG int,
@peiid	int,
@inputOG varchar(50)

SET @CallingSP = 'spLocal_CmnMobileAppGetPalletInventory_FO02809'

SET @StatusActiveID = (SELECT PP_Status_ID FROM dbo.Production_Plan_Statuses PPS WITH(NOLOCK) WHERE PP_Status_Desc = 'Active')
SET @StatusInitiateID = (SELECT PP_Status_ID FROM dbo.Production_Plan_Statuses PPS WITH(NOLOCK) WHERE PP_Status_Desc = 'Initiate')
SET @StatusReadyID = (SELECT PP_Status_ID FROM dbo.Production_Plan_Statuses PPS WITH(NOLOCK) WHERE PP_Status_Desc = 'Ready')
SET @StatusClosingID = (SELECT PP_Status_ID FROM dbo.Production_Plan_Statuses PPS WITH(NOLOCK) WHERE PP_Status_Desc = 'Closing')

IF @DebugFlagOnLine = 1  	
BEGIN	
	SET @ErrMsg =	'0001' +
					' SP STarted'

	INSERT INTO dbo.Local_Debug([Timestamp], CallingSP, [Message]) 
	VALUES(	getdate(), 
			@CallingSP,
			@ErrMsg			
			)
END


/*-----------------------------------------------------------------------------------------
1) Get the production units involded
-------------------------------------------------------------------------------------------*/
BEGIN

	INSERT INTO @ProdUnits (PUID, PUDEsc)
	SELECT pu.Pu_ID, Pu_Desc 
	FROM [dbo].[PrdExec_Path_Units] ppu
	JOIN dbo.prod_Units pu						WITH(NOLOCK)	ON ppu.pu_id = pu.pu_id															
	WHERE Path_id =@PathID



	--Get tableID for prdexec_inputs
	SET @TableIdPrdExecInput = (SELECT tableid FROM dbo.tables WHERE tablename = 'PrdExec_Inputs')

	--Get TablefieldID for 'Origin Group'
	SET @TFIDOG = (SELECT table_field_ID FROM dbo.table_fields WHERE tableid = @TableIdPrdExecInput 
																		AND table_field_desc = 'Origin Group')
	INSERT @RMIs (peiid, InputOG, IsBulkMaterial)
	SELECT 	pei.pei_id			AS PEIId,
			CONVERT(varchar(30), tfv.value),
			CASE es.Event_Subtype_Desc
				WHEN 'Bulk_Unit' THEN 1
				ELSE 0
			END
		FROM dbo.PrdExec_Inputs pei WITH(NOLOCK)
			JOIN dbo.table_fields_values tfv	WITH(NOLOCK) ON tfv.keyid = pei.pei_id AND tfv.table_field_id = @tfidog
			JOIN dbo.PrdExec_Input_Sources peis WITH(NOLOCK) ON (peis.pei_id = pei.pei_id)
			JOIN dbo.Prod_Units pu				WITH(NOLOCK) ON (pu.PU_Id = peis.PU_Id)
			JOIN dbo.Event_SubTypes es			WITH(NOLOCK) ON (es.Event_Subtype_Id = pei.Event_Subtype_Id)
		WHERE pei.PU_Id IN(SELECT PUID FROM @ProdUnits)


	INSERT @tProdUnits (EquipmentId,puid,S95Id,IsBulkMaterial)
			SELECT DISTINCT CONVERT(varchar(50), eu.equipmentId),
							a.pu_id,
							CONVERT(varchar(50), eu.S95Id),
							r.IsBulkMaterial
			FROM	dbo.Equipment eu							WITH(NOLOCK)	
			JOIN	dbo.PAEquipment_Aspect_SOAEquipment a		WITH(NOLOCK)	ON eu.EquipmentId = a.Origin1EquipmentId
			JOIN	dbo.prdexec_input_sources peis			WITH(NOLOCK)	ON peis.PU_Id = a.Pu_id
			JOIN @RMIs r ON r.peiid = peis.pei_id
			--WHERE peis.pei_id = @peiid
	
END
--Get OUT if there is no line
IF NOT(EXISTS(SELECT * FROM @tProdUnits))
BEGIN
		SET @ErrMsg =		'0110' +
							' There is storage unit under the selected Path'
							
		INSERT INTO dbo.Local_Debug([Timestamp], CallingSP, [Message]) 
		VALUES(	getdate(), 
				@CallingSP,
				@ErrMsg			
				)
				
		GOTO Sortie
END

/*-----------------------------------------------------------------------------------------
2) Get Inventory
-------------------------------------------------------------------------------------------*/
IF @DebugFlagOnLine = 1  	
BEGIN	
	SET @ErrMsg =	'Before INSERT INTO @Inventory'

	INSERT INTO dbo.Local_Debug([Timestamp], CallingSP, [Message]) 
	VALUES(	getdate(), 
			@CallingSP,
			@ErrMsg			
			)
END

INSERT @Inventory (
		S95Id,
		EventId,
		ULID,
		ProdId,
		ProdCode,
		ProdDesc,
		Batch,
		StatusId,
		StatusDesc,
		DeliveredQty,
		RemainingQty,
		UOM,
		OG,
		ppid,
		ProcessOrder,
		POStatus,
		IsBulkMaterial)
SELECT	pu.S95Id,
		e.event_id,
		CASE CHARINDEX('_',e.event_num)
			WHEN 0 THEN SUBSTRING(e.event_num,0,24)
			ELSE SUBSTRING(e.event_num,0,CHARINDEX('_',e.event_num))
		END	,
		e.applied_product,
		CONVERT(varchar(8), p.prod_code),
		CONVERT(varchar(50), m.S95ID),
		SUBSTRING(e2.event_num,0,CHARINDEX('_',e2.event_num)),
		e.event_status,
		ps.prodStatus_Desc,
		ed.initial_dimension_X,
		COALESCE(ed.Final_dimension_X,0),
		CONVERT(varchar(20),pmdmc.value),
		CONVERT(varchar(10),pmdmc2.value),
		ed.pp_id,
		PP.Process_Order,
		PPs.PP_Status_Desc,
		pu.IsBulkMaterial
FROM	@tProdUnits	pu
JOIN	dbo.events e											WITH(NOLOCK)	ON e.pu_id = pu.puid
JOIN	dbo.production_Status	ps								WITH(NOLOCK)	ON e.event_status = ps.prodStatus_Id
																					AND (ps.LifecycleStage = 1 OR ps.LifecycleStage = 2)
JOIN	dbo.event_details ed									WITH(NOLOCK)	ON e.event_id = ed.event_id
																					AND ed.final_dimension_x != 0
JOIN	dbo.products p										WITH(NOLOCK)	ON e.applied_product = p.prod_id
JOIN	dbo.Products_Aspect_MaterialDefinition a				WITH(NOLOCK)	ON a.prod_id = p.prod_id
JOIN	dbo.materialDefinition m										WITH(NOLOCK)	ON a.Origin1MaterialDefinitionId = m.materialDefinitionId
JOIN	dbo.Property_MaterialDefinition_MaterialClass pmdmc	WITH(NOLOCK)	ON pmdmc.MaterialDefinitionId = m.MaterialDefinitionid
																					AND pmdmc.Name = 'UOM'
JOIN	dbo.Property_MaterialDefinition_MaterialClass pmdmc2	WITH(NOLOCK)	ON pmdmc2.MaterialDefinitionId = m.MaterialDefinitionid
																					AND pmdmc2.Name = 'Origin Group'
LEFT JOIN	dbo.event_components ec								WITH(NOLOCK)	ON ec.event_id = e.event_id
LEFT JOIN	dbo.events e2											WITH(NOLOCK)	ON ec.source_event_id = e2.event_id
LEFT JOIN	dbo.prod_units pu2									WITH(NOLOCK)	ON e2.pu_id = pu2.pu_id		AND		pu2.equipment_type = 'LotStorage'
LEFT JOIN	dbo.Production_Plan	pp								WITH(NOLOCK)	ON ed.PP_ID = PP.PP_ID
LEFT JOIN	dbo.Production_Plan_Statuses	pps								WITH(NOLOCK)	ON pps.PP_Status_ID = PP.PP_Status_ID

IF @DebugFlagOnLine = 1  	
BEGIN	
	SET @ErrMsg =	'After INSERT INTO @Inventory'

	INSERT INTO dbo.Local_Debug([Timestamp], CallingSP, [Message]) 
	VALUES(	getdate(), 
			@CallingSP,
			@ErrMsg			
			)
END																			

--Get delivery time
UPDATE i
SET deliveryTime = est.start_time
FROM @Inventory i
JOIN dbo.Event_Status_Transitions est							WITH(NOLOCK)	ON i.eventid = est.event_id
JOIN dbo.production_Status	ps								WITH(NOLOCK)	ON est.event_status = ps.prodStatus_id
WHERE ps.prodStatus_Desc = 'Delivered'


--convert to have only 3 digits after comma when the number has decimal
UPDATE i
SET RemainingQty = convert(varchar(50),RemainingQty,2),
 DeliveredQty = convert(varchar(50),DeliveredQty,2)
FROM @Inventory i

UPDATE i
SET RemainingQty = convert(decimal(20,3),RemainingQty)
FROM @Inventory i
WHERE charindex(',',RemainingQty) <> 0 OR charindex('.',RemainingQty) <>0

UPDATE i
SET DeliveredQty = convert(decimal(20,3),DeliveredQty)
FROM @Inventory i
WHERE charindex(',',DeliveredQty) <> 0 OR charindex('.',DeliveredQty) <>0


--Remove Overconsumed that are not for a running PO
--260814
DELETE i
FROM @Inventory i
LEFT JOIN dbo.production_plan pp		WITH(NOLOCK)	ON i.ppid = pp.pp_id
JOIN dbo.production_Status ps		WITH(NOLOCK)	ON i.StatusId = ps.prodStatus_Id
															and ps.LifecycleStage = 2
WHERE i.RemainingQty <=0
	AND (pp.pp_status_id not in (@StatusActiveID,@StatusReadyID,@StatusInitiateID,@StatusClosingID) OR  pp.pp_status_id IS  NULL)


-- Remove bulk material event not checked-in on the current path
DELETE FROM I
FROM @Inventory I
INNER JOIN dbo.Production_Plan pp ON pp.PP_Id = I.ppid
WHERE	IsBulkMaterial = 1 
		AND pp.Path_Id <> @PathID

DELETE FROM @Inventory
WHERE	IsBulkMaterial = 1 
		AND ppid IS NULL

-- Set batch field for bulk material
UPDATE i
SET Batch = ULID
FROM @Inventory i
WHERE IsBulkMaterial = 1

/*-----------------------------------------------------------------------------------------
3) Generate Output
-------------------------------------------------------------------------------------------*/
IF EXISTS(SELECT S95Id FROM @Inventory)
BEGIN
	SELECT	S95Id			AS	'Storage Unit',
			ULID			AS  'ULID',
			deliveryTime	AS	'Delivery Time',
			ProdDesc		AS	'Material',
			Batch			AS  'Batch',
			OG				AS	'Group',
			statusDesc		AS	'Status',
			DeliveredQty	AS	'Delivered Qty',
			RemainingQty	AS	'Remaining Qty',
			UOM				AS	'UOM',
			ProcessOrder	AS	'Process Order',
			PoStatus		AS	'PoStatus',
			EventId			AS	'EventId',
			ppid
	FROM @Inventory
END
ELSE
BEGIN
	SELECT	'No Inventory'	AS	'Storage Unit',
			''			AS  'ULID',
			convert(varchar(25),GETDATE(),120)			AS	'Delivery Time',
			''			AS	'Material',
			''			AS  'Batch',
			''			AS	'Group',
			''			AS	'Status',
			''			AS	'Delivered Qty',
			''			AS	'Remaining Qty',
			''			AS	'UOM',
			''			AS 	'Process Order',
			''			AS	'PoStatus',
			''			AS	'EventId'
	FROM @Inventory
END
SET NOCOUNT OFF
RETURN

sortie:
	SELECT	'Line not configured for PE'	AS	'Storage Unit',
			''							AS  'ULID',
			convert(varchar(25),GETDATE(),120)							AS	'Delivery Time',
			''							AS	'Material',
			''							AS  'Batch',
			''							AS	'Group',
			''							AS	'Status',
			''							AS	'Delivered Qty',
			''							AS	'Remaining Qty',
			''							AS	'UOM',
			''							AS	'Process Order',
			''							AS	'PoStatus',
			''							AS	'EventId'

SET NOCOUNT OFF
RETURN
