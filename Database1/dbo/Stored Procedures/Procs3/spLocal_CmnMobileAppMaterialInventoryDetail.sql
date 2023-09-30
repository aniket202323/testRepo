CREATE PROCEDURE [dbo].[spLocal_CmnMobileAppMaterialInventoryDetail]
@pathCode		varchar(25),
@ProdCode		varchar(25),
@ProcessOrder	varchar(50)

AS
SET NOCOUNT ON


DECLARE  
@TableIdPrdExecInput		int,
@TFIDOG						int,
@StatusInitiateID			int,
@StatusReadyID				int,
@StatusActiveID				int,
@StatusClosingID			int,
@DebugFlagOnLine			int,
@PATHID						int,
@ProdID						int,
@SPNAME						varchar(50),
@ErrMsg						varchar(50),
@ActBOMFormId				int,
@SubProdID					int


DECLARE @Inventory			TABLE (
		S95Id						varchar(50),
		EventId						int,
		ULID						varchar(50),
		DeliveryTime				datetime,
		ProdId						int,
		ProdCode					varchar(25),
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
		VendorLot					varchar(25))

DECLARE @ProdUnits TABLE(
PUID		int, 
PUDesc		varchar(50))		

DECLARE @RMIs				TABLE(
		PeiId						int,
		InputOG						varchar(30)
		)

DECLARE @tProdUnits			TABLE (
		EquipmentId					varchar(50),
		puid						int,
		S95Id						varchar(50)
		)	

-----------------------------------------------------------------------
--Beginning of code
-----------------------------------------------------------------------
SET @SPNAME = 'spLocal_CmnMobileAppMaterialInventoryDetail'

INSERT local_debug (CallingSP,timestamp, message, msg)
VALUES (	@SPNAME,
			GETDATE(),
			'0000 - SP started',
			@pathId
		)

SET @StatusActiveID = (SELECT PP_Status_ID FROM dbo.Production_Plan_Statuses PPS WITH(NOLOCK) WHERE PP_Status_Desc = 'Active')
SET @StatusInitiateID = (SELECT PP_Status_ID FROM dbo.Production_Plan_Statuses PPS WITH(NOLOCK) WHERE PP_Status_Desc = 'Initiate')
SET @StatusReadyID = (SELECT PP_Status_ID FROM dbo.Production_Plan_Statuses PPS WITH(NOLOCK) WHERE PP_Status_Desc = 'Ready')
SET @StatusClosingID = (SELECT PP_Status_ID FROM dbo.Production_Plan_Statuses PPS WITH(NOLOCK) WHERE PP_Status_Desc = 'Closing')
SET @PATHID = (SELECT  Path_ID FROM dbo.Prdexec_Paths WITH(NOLOCK) WHERE PAth_Code  = @pathCode)
SET @ProdID = (SELECT Prod_ID  FROM dbo.Products_Base WITH(NOLOCK) WHERE Prod_Code =  @ProdCode)


SELECT  @ActBOMFormId = BOM_Formulation_Id
FROM  dbo.production_plan  pp WITH(NOLOCK)
WHERE process_order = @ProcessOrder

SELECT   @SubProdID = bomfs.Prod_ID
FROM	dbo.Bill_Of_Material_Formulation_Item bomfi	WITH(NOLOCK)
JOIN		dbo.Bill_Of_Material_Formulation bomf		WITH(NOLOCK) ON (bomf.BOM_Formulation_Id = bomfi.BOM_Formulation_Id)
JOIN		dbo.Products_Base p							WITH(NOLOCK) ON (p.Prod_Id = bomfi.Prod_Id) 
JOIN		dbo.Engineering_Unit eu					WITH(NOLOCK) ON (eu.Eng_Unit_Id = bomfi.Eng_Unit_Id)
LEFT JOIN	dbo.Bill_Of_Material_Substitution bomfs	WITH(NOLOCK) ON (bomfs.BOM_Formulation_Item_Id = bomfi.BOM_Formulation_Item_Id)
LEFT JOIN	dbo.Products_Base p_sub						WITH(NOLOCK) ON (p_sub.Prod_Id = bomfs.Prod_Id) 
LEFT JOIN	dbo.Engineering_Unit eu_sub				WITH(NOLOCK) ON (eu_sub.Eng_Unit_Id = bomfs.Eng_Unit_Id)
LEFT JOIN	dbo.Prod_Units_Base pu							WITH(NOLOCK) ON (bomfi.PU_Id = pu.PU_Id)
WHERE	bomf.BOM_Formulation_Id = @ActBOMFormId
AND		bomfi.Prod_ID = @ProdID


	INSERT INTO @ProdUnits (PUID, PUDEsc)
	SELECT pu.Pu_ID, Pu_Desc 
	FROM [dbo].[PrdExec_Path_Units] ppu				WITH(NOLOCK)
	JOIN dbo.Prod_Units_Base pu						WITH(NOLOCK)	ON ppu.pu_id = pu.pu_id															
	WHERE Path_id =@PathID


	
	--Get tableID for prdexec_inputs
	SET @TableIdPrdExecInput = (SELECT tableid FROM dbo.tables  WITH(NOLOCK)WHERE tablename = 'PrdExec_Inputs')

	--Get TablefieldID for 'Origin Group'
	SET @TFIDOG = (SELECT table_field_ID FROM dbo.table_fields  WITH(NOLOCK) WHERE tableid = @TableIdPrdExecInput 
																		AND table_field_desc = 'Origin Group')

																		
	INSERT @RMIs (peiid, InputOG)
	SELECT	pei.pei_id, 		tfv.value
	FROM prdExec_inputs pei				WITH(NOLOCK)
	JOIN dbo.table_fields_values tfv			WITH(NOLOCK)	ON	tfv.keyid = pei.pei_id
																	AND tfv.table_field_id = @tfidog

	WHERE PU_ID IN(SELECT PUID FROM @ProdUnits)


	INSERT @tProdUnits (EquipmentId,puid,S95Id)
			SELECT  DISTINCT  eu.equipmentId, a.pu_id,eu.S95Id
			FROM	dbo.Equipment eu							WITH(NOLOCK)	
			JOIN	dbo.PAEquipment_Aspect_SOAEquipment a		WITH(NOLOCK)	ON eu.EquipmentId = a.Origin1EquipmentId
			JOIN	dbo.prdexec_input_sources peis			WITH(NOLOCK)	ON peis.PU_Id = a.Pu_id 
			JOIN @RMIs r ON r.peiid = peis.pei_id


--Get OUT if there is no line
IF NOT(EXISTS(SELECT * FROM @tProdUnits))
BEGIN
		SET @ErrMsg =		'0110' +
							' There is storage unit under the selected Path'
							
		INSERT INTO dbo.Local_Debug([Timestamp], CallingSP, [Message]) 
		VALUES(	getdate(), 
				@SPNAME,
				@ErrMsg			
				)
				
		RETURN
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
		VendorLot)
SELECT	pu.S95Id,
		e.event_id,
		CASE CHARINDEX('_',e.event_num)
			WHEN 0 THEN SUBSTRING(e.event_num,0,24)
			ELSE SUBSTRING(e.event_num,0,CHARINDEX('_',e.event_num))
		END	,
		e.applied_product,
		p.prod_code,
		m.S95ID,
		--Add case there is no "_" in the batch event_num  v1.1
		CASE CHARINDEX('_',e2.event_num)
			WHEN 0 THEN SUBSTRING(e2.event_num,1,10) -- 1.4
			ELSE SUBSTRING(e2.event_num,0,CHARINDEX('_',e2.event_num))
		END	,
		e.event_status,
		ps.prodStatus_Desc,
		ed.initial_dimension_X,
		COALESCE(ed.Final_dimension_X,0),
		CONVERT(varchar(25),pmdmc.value),
		CONVERT(varchar(25),pmdmc2.value),
		ed.pp_id,
		PP.Process_Order,
		PPs.PP_Status_Desc,
		ed.Alternate_Event_Num
FROM	@tProdUnits	pu
JOIN	dbo.events e											WITH(NOLOCK)	ON e.pu_id = pu.puid
JOIN	dbo.production_Status	ps								WITH(NOLOCK)	ON e.event_status = ps.prodStatus_Id
																					AND (ps.LifecycleStage = 1 OR ps.LifecycleStage = 2)
JOIN	dbo.event_details ed									WITH(NOLOCK)	ON e.event_id = ed.event_id
																					AND ed.final_dimension_x != 0  -- 1.1
JOIN	dbo.Products_Base p										WITH(NOLOCK)	ON e.applied_product = p.prod_id
JOIN	dbo.Products_Aspect_MaterialDefinition a				WITH(NOLOCK)	ON a.prod_id = p.prod_id
JOIN	dbo.materialDefinition m										WITH(NOLOCK)	ON a.Origin1MaterialDefinitionId = m.materialDefinitionId
JOIN	dbo.Property_MaterialDefinition_MaterialClass pmdmc	WITH(NOLOCK)	ON pmdmc.MaterialDefinitionId = m.MaterialDefinitionid
																					AND pmdmc.Name = 'UOM'
JOIN	dbo.Property_MaterialDefinition_MaterialClass pmdmc2	WITH(NOLOCK)	ON pmdmc2.MaterialDefinitionId = m.MaterialDefinitionid
																					AND pmdmc2.Name = 'Origin Group'
LEFT JOIN	dbo.event_components ec								WITH(NOLOCK)	ON ec.event_id = e.event_id
LEFT JOIN	dbo.events e2											WITH(NOLOCK)	ON ec.source_event_id = e2.event_id
LEFT JOIN	dbo.Prod_Units_Base pu2									WITH(NOLOCK)	ON e2.pu_id = pu2.pu_id		AND		(pu2.equipment_type = 'StackStorage'  )--Updated in V1.1
LEFT JOIN	dbo.Production_Plan	pp								WITH(NOLOCK)	ON ed.PP_ID = PP.PP_ID
LEFT JOIN	dbo.Production_Plan_Statuses	pps								WITH(NOLOCK)	ON pps.PP_Status_ID = PP.PP_Status_ID
																		


--Remove Overconsumed that are not for a running PO
--260814
DELETE i
FROM @Inventory i
LEFT JOIN dbo.production_plan pp		WITH(NOLOCK)	ON i.ppid = pp.pp_id
JOIN dbo.production_Status ps		WITH(NOLOCK)	ON i.StatusId = ps.prodStatus_Id
															and ps.LifecycleStage = 2
WHERE i.RemainingQty <=0
	AND (pp.pp_status_id not in (@StatusActiveID,@StatusReadyID,@StatusInitiateID,@StatusClosingID) OR  pp.pp_status_id IS  NULL)


-- keep only materail for the input parameter prodid
DELETE i
FROM @Inventory i WHERE ProdID NOT IN( @ProdID,coalesce(@SubProdID,0))

	SELECT	S95Id			AS	'Storage Unit',
			EventId			AS	'EventId',
			ULID			AS  'ULID',
			deliveryTime	AS	'Delivery Time',
			ProdId			AS	'MaterialID',
			ProdDesc		AS	'Material',
			Batch			AS  'Batch',
			OG				AS	'Group',
			statusDesc		AS	'Status',
			DeliveredQty	AS	'Delivered Qty',
			RemainingQty	AS	'Remaining Qty',
			UOM				AS	'UOM',
			ProcessOrder	AS	'Process Order',
			ppid			AS	'PPID',
			PoStatus		AS	'PoStatus',			
			VendorLot		AS	'VendorLot'
	FROM @Inventory




INSERT local_debug (CallingSP,timestamp, message, msg)
VALUES (	@SPNAME,
			GETDATE(),
			'0999 -End of SP  ' ,
			@pathId
		)