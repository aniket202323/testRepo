CREATE PROCEDURE [dbo].[spLocal_CmnMobileAppSIStartupMaterialOverview]
@pathId							int,		--Destination Location
@DebugFlag						int			--When debug flag = 1, many record set are presented to user

AS
SET NOCOUNT ON

DECLARE 
@SPNAME							varchar(255),
@ThisTime						datetime,
--PO
@NextPPID						int,
@NextProcessOrder				varchar(50),
@BOMFormId						int,
@ActivePPID						int,
@ActiveBOMFormId				int,
@PODuration						float,
@ThresholdInMinute				float,
@ThresholdInUOM					float,
@BomQty							float,
--RMIs
@tableId						int,
@tfIdOG							int,
@tfidWMSSystem					int,
@tfidConsumptionType			int,
@tfidIsRMIScrapfactor			int,
@tfidIsAutoOrdering				int,
@tfidSafetyStock				int,
@tfidRMIScrapfactor				int,
@tfIdMaterialOriginGroup		int,
--LOOP variables
@ProdId							int,
@RequestId						varchar(50),
@Location						varchar(30),
@QuantityInventory				float,
@MinuteSinceLastOrder			int,
@CountOpenrequest				int,
@OG								varchar(12),
@SourcePuid						int,
@SourcePuDesc					varchar(50),
@ProdDesc						varchar(50),
@ProdCode						varchar(25),
@ProdDescSub					varchar(50),
@ProdCodeSub					varchar(50),
@UOM							varchar(30),		--V1.2
@tfidIsWMSOrdering				varchar(50),
@varIdLineProdRate				int,
@LineProdRate					float



DECLARE @PathUnit TABLE(
PUID	int)

DECLARE @ProdUnits	TABLE (
puid					int--,
---ActivePPID				int
)



--Raw material input UDP table
DECLARE @RMI	TABLE (
peiid					int,
puid					int,
OG						varchar(30),
WMSSystem				varchar(50),
IsRMIScrapfactor		bit,
RMIScrapfactor			float,
SafetyStock				bit,
IsWMSOrdering			bit
)


DECLARE @tblBOMNext TABLE 		(	
BOMRMId						int IDENTITY,
PPId						int,
BOMRMProdId					int,
BOMRMProdCode				varchar(25),
BOMRMQty					float,
BOMUOM						varchar(30),
BOMScrapFactor				float,
BOMRMFormItemId				int,
BOMOG						varchar(25),
OGRunningThreshold			float,
BOMRMStoragePUId			int,
BOMRMProdIdSub				int,
BOMRMProdCodeSub			varchar(25)
)


DECLARE @tblBOMActive TABLE (	
BOMRMId						int IDENTITY,
PPId						int,
BOMRMProdId					int,
BOMRMProdCode				varchar(25),
BOMRMQty					float,
BOMUOM						varchar(30),
BOMScrapFactor				float,
BOMRMFormItemId				int,
BOMOG						varchar(25),
OGRunningThreshold			float,
BOMRMStoragePUId			int,
BOMRMProdIdSub				int,
BOMRMProdCodeSub			varchar(25)
)

DECLARE @OpenRequest	TABLE (
RequestId					varchar(50),
RequestTime					datetime,
LineId						varchar(50),
ULID						varchar(50),
ProcessOrder				varchar(50),
VendorLot					varchar(50),
GCAS						varchar(25),
PrimaryGCAS					varchar(25),
AlternateGCAS				varchar(25),
Status						varchar(50),
Location					varchar(50),
Quantity					float,
UOM							varchar(50)
)


DECLARE @Inventory TABLE (
StorageUnit					varchar(50),
ULID						varchar(50),
DeliveryTime				datetime,
Material					varchar(50),
Batch						varchar(50),
OG							varchar(30),
Status						varchar(30),
DeliveredQty				float,
RemainingQty				float,
UOM							varchar(30),
ProcessOrder				varchar(30),
POStatus					varchar(30),
EventId						int,
VendorLot					varchar(30),
IsManualReturn				int, 
IsInventoryAdjust			int
)

DECLARE @Output TABLE (
ProcessOrder				varchar(12),
OriginGroup					varchar(4),
MaterialCode				varchar(25),
MaterialDesc				varchar(50),
NbrOpenRequest				int,
OrderedSince				int,
SuggestedOrder				varchar(50),	--Useless field, maybe future usage. (always "--')
Inventory					float,
Available					varchar(2),		--Useless field, maybe future usage. (always "--')
SAPlocation					varchar(30),
UnitDesc					varchar(50), 
MaterialSubCode				varchar(50),  --1.4
MaterialDescSub				varchar(50),  --1.4
SIManaged					bit,
ThresholdInUOM				float,
UOM							varchar(30)		--V1.2
)

-----------------------------------------------------------------------
--Beginning of code
-----------------------------------------------------------------------
SET @SPNAME = 'spLocal_CmnMobileAppSIStartupMaterialOverview'

INSERT local_debug (CallingSP,timestamp, message, msg)
VALUES (	@SPNAME,
			GETDATE(),
			'0000 - SP started',
			convert(varchar(50),@pathId)
		)


SELECT @ThisTime = GETDATE()







-----------------------------------------------------------------------
--Get All production units in the paths
-----------------------------------------------------------------------
INSERT @ProdUnits (puid)
SELECT pu_id
FROM dbo.prdExec_path_units WITH(NOLOCK)
WHERE path_id = @pathid

IF @DebugFlag  =1
	SELECT 'Production prod_units', * FROM @ProdUnits




INSERT INTO @PathUnit(PUID)
SELECT PU_ID
FROM dbo.PrdExec_Path_Units WITH(NOLOCK)
WHERE Path_Id = @pathid
SET @varIdLineProdRate  = (	SELECT var_id FROM dbo.variables_base WITH(NOLOCK) WHERE pu_id in (SELECT PUID FROM @PathUnit) AND extended_info = 'PE:LineProductionRate' )

IF @varIdLineProdRate  IS NULL
BEGIN
INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
			GETDATE(),
			'0370 - ' +
			'Error:variable  Line Production Rate is missing',
			convert(varchar(50),@pathId)
		)
	RETURN
END

SET @LineProdRate = (SELECT TOP 1 Result FROM dbo.TEsts WTIH(NOLOCK) WHERE Var_ID =@varIdLineProdRate ORDER BY result_ON DESC )

IF @LineProdRate IS NULL OR @LineProdRate =0 
BEGIN
	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
			GETDATE(),
			'0380 - ' +
			'Error:  Line Production Rate is empty',
			convert(varchar(50),@pathId)
		)
	--RETURN
END



-----------------------------------------------------------------------
--Get active and Next Order
-----------------------------------------------------------------------
--Get the next order (ready or Initiate).  If it doesn't exist, exit the Stored proc
SET @NextPPID = (	SELECT pp.pp_id 
					FROM dbo.production_plan pp 			WITH(NOLOCK) 
					JOIN dbo.production_plan_statuses pps	WITH(NOLOCK)	ON pp.pp_status_id = pps.pp_status_id
					WHERE pps.pp_status_desc IN ('Initiate','Ready')
						AND pp.path_id = @pathid
					)

SELECT	@NextProcessOrder	= process_order, 
		@poDuration			= DATEDIFF(mi, forecast_start_date, forecast_End_date)
		FROM dbo.production_plan WITH(NOLOCK) 
		WHERE pp_id = @NextPPID



IF @DebugFlag  =1
	SELECT @NextPPID 'Next PPID', @NextProcessOrder 'Next PO'


IF @NextPPID IS NULL
BEGIN
	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
			GETDATE(),
			'0109 - Initiate or ready order not found',
			convert(varchar(50),@pathId)
		)
	GOTO Fin
END
ELSE
BEGIN
	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
			GETDATE(),
			'0110 - ' + 
			' Next PPID = ' + CONVERT(varchar(10),@nextPPID) + 
			' Next ProcessOrder = ' + @NextProcessOrder,
			convert(varchar(50),@pathId)
		)

END



----Get the Active order for each unit of the path
--UPDATE pu
--SET Activeppid = pps.pp_id
--FROM @ProdUnits pu
--JOIN dbo.production_plan_starts pps		WITH(NOLOCK)	ON pps.pu_id = pu.puid
--															AND pps.STart_time< @thistime
--															AND pps.end_time IS NULL

SET @ActivePPID = (	SELECT TOP 1 pp_id 
					FROM dbo.Production_Plan 		WITH(NOLOCK) 
					WHERE Path_Id = @pathid
						AND PP_Status_Id = 3
					ORDER BY Actual_Start_Time DESC)



INSERT local_debug (CallingSP,timestamp, message, msg)
VALUES (	@SPNAME,
		GETDATE(),
		'0120 - ' + 
		' Active PPID = ' + CONVERT(varchar(10),COALESCE(@ActivePPID,-999)) ,
		convert(varchar(50),@pathId)
	)


IF @DebugFlag  =1
	SELECT @ActivePPID as ' Active PO'




-----------------------------------------------------------------------
--Get required RMI UDPs
-----------------------------------------------------------------------
--Get table fields ids
SET @TableID	= (	SELECT TableID 	FROM dbo.Tables WITH(NOLOCK) WHERE tableName = 'PRDExec_Inputs'	)


SET @tfIdOG					= (SELECT Table_Field_id FROM dbo.Table_Fields WITH(NOLOCK) WHERE Table_Field_Desc = 'Origin Group'			AND TableID = @TableID	)
SET @tfidWMSSystem			= (SELECT Table_Field_id FROM dbo.Table_Fields WITH(NOLOCK) WHERE Table_Field_Desc = 'PE_WMS_System'		AND TableID = @TableID	)
SET @tfidIsRMIScrapfactor	= (SELECT Table_Field_id FROM dbo.Table_Fields WITH(NOLOCK) WHERE Table_Field_Desc = 'UseRMScrapFactor'		AND TableID = @TableID	)
SET @tfidRMIScrapfactor		= (SELECT Table_Field_id FROM dbo.Table_Fields WITH(NOLOCK) WHERE Table_Field_Desc = 'RMScrapFactor'		AND TableID = @TableID	)
SET @tfidSafetyStock		= (SELECT Table_Field_id FROM dbo.Table_Fields WITH(NOLOCK) WHERE Table_Field_Desc = 'SafetyStock'			AND TableID = @TableID	)
SET @tfidIsWMSOrdering		= (SELECT Table_Field_id FROM dbo.Table_Fields WITH(NOLOCK) WHERE Table_Field_Desc = 'PE_WMS_IsOrdering'		AND TableID = @TableID	)


INSERT local_debug (CallingSP,timestamp, message, msg)
VALUES (	@SPNAME,
			GETDATE(),
			'0220 - ' +
			' /@tfIdOG = ' + CONVERT(varchar(30),COALESCE(@tfIdOG,0)) +
			' /@tfidWMSSystem = ' + CONVERT(varchar(30),COALESCE(@tfidWMSSystem,0)) +
			' /@tfidIsRMIScrapfactor = ' + CONVERT(varchar(30),COALESCE(@tfidIsRMIScrapfactor,0)) +
			' /@tfidRMIScrapfactor = ' + CONVERT(varchar(30),COALESCE(@tfidRMIScrapfactor,0)) +
			' /@@tfidIsWMSOrdering = ' + CONVERT(varchar(30),COALESCE(@tfidIsWMSOrdering,0)) +
			' /@tfidSafetyStock = ' + CONVERT(varchar(30),COALESCE(@tfidSafetyStock,0)) ,
			convert(varchar(50),@pathId)
		)

--retrieve and store all OG on the consumption unit
INSERT @RMI (
				peiid					,
				puid					,
				OG						,
				WMSSystem				,
				IsRMIScrapfactor		,
				RMIScrapfactor			,
				SafetyStock			,
				IsWMSOrdering	
						)
SELECT	pei.PEI_Id, 
		pei.PU_Id ,
		tfv.Value,						--OG
		tfv2.value,						--SImanaged
		CONVERT(bit,tfv5.value),		--IsRMIScrapfactor
		CONVERT(float,tfv6.value),		--RMIScrapfactor
		CONVERT(bit,tfv8.value),			--SafetyStock
		CONVERT(bit,tfv9.value)			--PE_WMS_Isoredering
FROM dbo.PrdExec_Inputs pei			WITH(NOLOCK)	
JOIN @ProdUnits	pu									ON pei.pu_id	= pu.puid
JOIN dbo.Table_Fields_Values tfv	WITH(NOLOCK)	ON tfv.KeyId	= pei.PEI_Id
JOIN dbo.Table_Fields_Values tfv2	WITH(NOLOCK)	ON tfv2.KeyId	= pei.PEI_Id
JOIN dbo.Table_Fields_Values tfv5	WITH(NOLOCK)	ON tfv5.KeyId	= pei.PEI_Id
JOIN dbo.Table_Fields_Values tfv6	WITH(NOLOCK)	ON tfv6.KeyId	= pei.PEI_Id
JOIN dbo.Table_Fields_Values tfv8	WITH(NOLOCK)	ON tfv8.KeyId	= pei.PEI_Id
JOIN dbo.Table_Fields_Values tfv9	WITH(NOLOCK)	ON tfv9.KeyId	= pei.PEI_Id
WHERE tfv.table_field_id	= @tfIdOG
	AND tfv2.table_field_id	= @tfidWMSSystem
	AND tfv5.table_field_id	= @tfidIsRMIScrapfactor
	AND tfv6.table_field_id	= @tfidRMIScrapfactor
	AND tfv8.table_field_id	= @tfidSafetyStock
	AND tfv9.table_field_id	= @tfidIsWMSOrdering


IF @DebugFlag  =1
	SELECT 'RMI All', * FROM @RMI

--Only keep SI
DELETE @RMI WHERE UPPER(WMSSystem) <> 'WAMAS'

DELETE @RMI WHERE IsWMSOrdering = 0

IF @DebugFlag  =1
	SELECT 'RMI Clean', * FROM @RMI


INSERT local_debug (CallingSP,timestamp, message, msg)
VALUES (	@SPNAME,
			GETDATE(),
			'0240 - SI RMI identified' ,
			convert(varchar(50),@pathId)
		)


--Clean prod_unit table to have only prod_unit involved in SI material
DELETE @ProdUnits WHERE puid NOT IN (SELECT DISTINCT puid FROM @RMI )

IF @DebugFlag  =1
	SELECT 'ProdUnits for SI', * FROM @ProdUnits








-----------------------------------------------------------------------
--Get BOM for SI material
-----------------------------------------------------------------------

--Get the full BOM for the next order
SET @BOMFormId = (SELECT BOM_Formulation_Id FROM dbo.production_plan WITH(NOLOCK) WHERE PP_Id = @nextPPID)

INSERT @tblBOMNEXT 		(	
			PPId						,
			BOMRMProdId					,
			BOMRMProdCode				,
			BOMRMQty					,
			BOMScrapFactor				,
			BOMRMFormItemId				,
			BOMRMStoragePUId			,
			BOMRMProdIdSub				,
			BOMRMProdCodeSub			
		)
SELECT		@NextPPID,
			bomfi.Prod_Id, 
			p.Prod_Code, 
			bomfi.Quantity,
			bomfi.Scrap_Factor,
			bomfi.BOM_Formulation_Item_Id,
			bomfi.PU_Id,
			bomfs.Prod_Id,
			p_sub.Prod_Code
	FROM	dbo.Bill_Of_Material_Formulation_Item bomfi	WITH(NOLOCK)
	JOIN		dbo.Bill_Of_Material_Formulation bomf	WITH(NOLOCK) ON (bomf.BOM_Formulation_Id = bomfi.BOM_Formulation_Id)
	JOIN		dbo.Products_Base p						WITH(NOLOCK) ON (p.Prod_Id = bomfi.Prod_Id) 
	LEFT JOIN	dbo.Bill_Of_Material_Substitution bomfs	WITH(NOLOCK) ON (bomfs.BOM_Formulation_Item_Id = bomfi.BOM_Formulation_Item_Id)
	LEFT JOIN	dbo.Products_Base p_sub						WITH(NOLOCK) ON (p_sub.Prod_Id = bomfs.Prod_Id)
	WHERE	bomf.BOM_Formulation_Id = @BOMFormId


SET @TableID	= (	SELECT TableID 	FROM dbo.Tables WITH(NOLOCK) WHERE tableName = 'Bill_of_Material_Formulation_Item'	)
SET @tfIdMaterialOriginGroup = (SELECT Table_Field_Id FROM dbo.Table_Fields WITH(NOLOCK) WHERE Table_Field_Desc = 'MaterialOriginGroup' AND TableId = @TableId);

UPDATE bom
SET BOMOG = tfv.value
FROM @tblBOMNEXT bom
JOIN dbo.Table_Fields_Values tfv	WITH(NOLOCK)	ON tfv.KeyId	= bom.BOMRMFormItemId
WHERE tfv.table_field_id = @tfIdMaterialOriginGroup


--Remove all BOM items not relevant														
DELETE @tblBOMNEXT WHERE BOMOG NOT IN (SELECT OG FROM @RMI)

IF @DebugFlag  =1
	SELECT 'Next BOM Clean', * FROM @tblBOMNEXT


INSERT local_debug (CallingSP,timestamp, message, msg)
VALUES (	@SPNAME,
			GETDATE(),
			'0310 - Next BOM read' ,
			convert(varchar(50),@pathId)
		)


IF @ActivePPID IS NOT NULL
BEGIN
	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
			GETDATE(),
			'0320 - There is an active order.  Get the BOM' ,
			convert(varchar(50),@pathId)
		)

	--get the Active order BOM
	SET @ActiveBOMFormId = (SELECT BOM_Formulation_Id FROM dbo.production_plan WITH(NOLOCK) WHERE PP_Id = @ActivePPID)

	INSERT @tblBOMActive		(	
				PPId						,
				BOMRMProdId					,
				BOMRMProdCode				,
				BOMRMQty					,
				BOMScrapFactor				,
				BOMRMFormItemId				,
				BOMRMStoragePUId			,
				BOMRMProdIdSub				,
				BOMRMProdCodeSub			
			)
	SELECT		@ActivePPID,
				bomfi.Prod_Id, 
				p.Prod_Code, 
				bomfi.Quantity,
				bomfi.Scrap_Factor,
				bomfi.BOM_Formulation_Item_Id,
				bomfi.PU_Id,
				bomfs.Prod_Id,
				p_sub.Prod_Code
		FROM	dbo.Bill_Of_Material_Formulation_Item bomfi	WITH(NOLOCK)
		JOIN		dbo.Bill_Of_Material_Formulation bomf	WITH(NOLOCK) ON (bomf.BOM_Formulation_Id = bomfi.BOM_Formulation_Id)
		JOIN		dbo.Products_Base p						WITH(NOLOCK) ON (p.Prod_Id = bomfi.Prod_Id) 
		LEFT JOIN	dbo.Bill_Of_Material_Substitution bomfs	WITH(NOLOCK) ON (bomfs.BOM_Formulation_Item_Id = bomfi.BOM_Formulation_Item_Id)
		LEFT JOIN	dbo.Products_Base p_sub					WITH(NOLOCK) ON (p_sub.Prod_Id = bomfs.Prod_Id)
		WHERE	bomf.BOM_Formulation_Id = @ActiveBOMFormId

		UPDATE bom
		SET BOMOG = tfv.value
		FROM @tblBOMActive bom
		JOIN dbo.Table_Fields_Values tfv	WITH(NOLOCK)	ON tfv.KeyId	= bom.BOMRMFormItemId
		WHERE tfv.table_field_id = @tfIdMaterialOriginGroup

		--Remove all BOM items not relevant														
		DELETE @tblBOMActive WHERE BOMOG NOT IN (SELECT OG FROM @RMI)  --V1.2

		IF @DebugFlag  =1
			SELECT 'Active BOM Clean', * FROM @tblBOMActive


END



--remove from next bom all common materials with the active bom
DELETE @tblBOMNEXT WHERE BOMRMProdId IN (SELECT BOMRMProdId FROM @tblBOMActive)

IF @DebugFlag  =1
	SELECT 'Final Next BOM', * FROM @tblBOMNEXT


INSERT local_debug (CallingSP,timestamp, message, msg)
VALUES (	@SPNAME,
		GETDATE(),
		'0360 - Required BOM finalized' ,
		convert(varchar(50),@pathId)
	)



------------------------------------------------------------------------
--GET SI Inventory
------------------------------------------------------------------------
INSERT @Inventory  (
StorageUnit					,
ULID						,
DeliveryTime				,
Material					,
Batch						,
OG							,
Status						,
DeliveredQty				,
RemainingQty				,
UOM							,
ProcessOrder				,
POStatus					,
EventId						,
VendorLot					,
IsInventoryAdjust			,
IsManualReturn				)
EXEC spLocal_CmnMobileAppGetSIInventory @pathid			

IF @DebugFlag  =1
	SELECT 'Inventory', * FROM @Inventory


-------------------------------------------------------------------------
--Loop BOM items
--a) get open request
--b) get inventory
--c) get since how long last order was made
-------------------------------------------------------------------------



/*
@ProdId							
@RequestId					
@Location					
@QuantityInventory			
@MinuteSinceLastOrder		
@CountOpenrequest			
@OG								varchar(12),
@SourcePuid						int,
@SourcePuDesc					varchar(50),
@ProdDesc						varchar(50),
@ProdCode						varchar(25)
*/
SET @ProdId = (SELECT MIN(BOMRMProdId) FROM @tblBOMNEXT)
WHILE @ProdId IS NOT NULL
BEGIN
	--reset Variable
	SELECT	@RequestId				= NULL,
			@Location				= NULL,
			@QuantityInventory		= NULL,
			@MinuteSinceLastOrder	= NULL,
			@CountOpenrequest		= NULL,
			@OG						= NULL,
			@SourcePuid				= NULL,
			@SourcePuDesc			= NULL,
			@ProdDesc				= NULL,
			@ProdCode				= NULL,
			@ProdDescSub			= NULL,
			@ProdCodeSub			= NULL,
			@BomQty					= NULL


	--Clear temp table
	DELETE @OpenRequest

	--Get OG
	SELECT	@OG				= BOMOG,
			@SourcePuid		= BOMRMStoragePUId,
			@SourcePuDesc	= PU.pu_desc,
			@ProdCode		= p.prod_code,
			@ProdDesc		= p.prod_Desc,
			@ProdDescSub	= p2.prod_desc,
			@ProdCodeSub	= p2.Prod_Code,
			@BomQty			= b.bomRMQty
	FROM @tblBOMNEXT b
	JOIN dbo.Prod_Units_Base pu		WITH(NOLOCK)	ON b.BOMRMStoragePUId = pu.pu_id
	JOIN dbo.Products_Base p		WITH(NOLOCK)	ON b.BOMRMProdId = p.prod_id
	LEFT JOIN dbo.Products_Base p2	WITH(NOLOCK)	ON b.BOMRMProdIdSub = p2.prod_id
	WHERE b.BOMRMProdId = @ProdId

	
	IF @DebugFlag  =1
		SELECT	@OG				as 'OG',
				@SourcePuid		as 'puid',
				@SourcePuDesc	as 'pu_desc',
				@ProdCode		as 'prod_code',
				@ProdDesc		as 'prod_Desc'


	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
				GETDATE(),
				'0410 - ' +
				' /@OG = ' + COALESCE(@OG,'NULL') +
				' /@SourcePuid = ' + CONVERT(varchar(30),COALESCE(@SourcePuid,0)) +
				' /@SourcePuDesc = ' + COALESCE(@SourcePuDesc,'NULL') +
				' /@ProdCode = ' + COALESCE(@ProdCode,'NULL')  +
				' /@ProdDescc = ' + COALESCE(@ProdDesc,'NULL') ,
				convert(varchar(50),@pathId)
			)


	--Get the open requests
	SET @Location = (SELECT CONVERT(varchar(50),peec.value)
					FROM dbo.Property_Equipment_EquipmentClass peec	WITH(NOLOCK)
					JOIN dbo.PAEquipment_Aspect_SOAEquipment a		WITH(NOLOCK)	ON peec.equipmentid = a.Origin1EquipmentId
					WHERE	peec.class = 'PE:SI_WMS'
						AND peec.name = 'Destination Location'
						AND a.pu_id = @SourcePuid
						)


	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
				GETDATE(),
				'0430 - ' +
				' /@Location = ' + COALESCE(@Location,'NULL')  ,
				convert(varchar(50),@pathId)
			)


	INSERT @Openrequest (RequestId, RequestTime, Location,LineId,  ProcessOrder, PrimaryGCAS, AlternateGCAS, GCAS, Quantity,UOM, Status, ULID,VendorLot) -- 1.2 add process order
	EXEC [dbo].[spLocal_CmnSIGetOpenRequest] @Location, NULL,@ProdCode, NULL 

	IF @DebugFlag  =1
		SELECT 'Open request', * FROM @Openrequest

	--count open request
	SET @CountOpenrequest = (SELECT COUNT(requestID) FROM @Openrequest)

	--get number of minute since last request
	IF @CountOpenrequest > 0
	BEGIN
		SET @MinuteSinceLastOrder = (SELECT TOP 1 COALESCE(DATEDIFF(mi,RequestTime, @thistime),0) FROM @Openrequest ORDER BY RequestTime ASC)  --V1.3 ASC instead of DESC
	END
	ELSE
	BEGIN
		SET @MinuteSinceLastOrder = 0
	END

	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
				GETDATE(),
				'0450 - ' +
				' /@CountOpenrequest = ' + CONVERT(varchar(30),COALESCE(@CountOpenrequest,-999)) +
				' /@MinuteSinceLastOrder = ' + CONVERT(varchar(30),COALESCE(@MinuteSinceLastOrder,-999)) ,
				convert(varchar(50),@pathId)
			)


	IF @DebugFlag  =1
		SELECT @CountOpenrequest as '@CountOpenrequest', @MinuteSinceLastOrder as '@MinuteSinceLastOrder'


	--Get the inventory
	SET @QuantityInventory = (	SELECT SUM(remainingQty )
								FROM @inventory		
								WHERE storageUnit = @SourcePuDesc
									AND (Material = @ProdDesc OR Material = @ProdDescSub)
									AND status IN ('Delivered','Running')
									)
	IF @QuantityInventory IS NULL
		SET @QuantityInventory = 0


	SET @ThresholdInMinute = (	(	SELECT convert(int, pee.Value)																				
									FROM dbo.property_equipment_equipmentclass pee	
									JOIN dbo.PAEquipment_Aspect_SOAEquipment a		WITH(NOLOCK)ON pee.equipmentid = a.Origin1EquipmentId
									WHERE a.pu_id = @SourcePuid
										AND pee.Name LIKE '%' +  @OG + '.' +'Origin Group Running Threshold')
	
								)

	SET @ThresholdInUOM = @ThresholdInMinute * @LineProdRate


	IF @DebugFlag  =1
		SELECT @ThresholdInMinute as '@ThresholdInMinute', @BomQty as '@BomQty', @POduration as 'PODuration', @ThresholdInUOM AS '@ThresholdInUOM'

	
	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
				GETDATE(),
				'0470 - ' +
				' /@ThresholdInMinute = ' + CONVERT(varchar(30),COALESCE(@ThresholdInMinute,-999)) +
				' /@POduration = ' + CONVERT(varchar(30),COALESCE(@POduration,-999)) +
				' /@BomQty = ' + CONVERT(varchar(30),COALESCE(@BomQty,-999)) +
				' /@ThresholdInUOM = ' + CONVERT(varchar(30),COALESCE(@ThresholdInUOM,-999)) ,
				convert(varchar(50),@pathId)
			)

	--V1.2
	SET @UOM = (		SELECT CONVERT(varchar(30), pmm.Value)
						FROM dbo.Property_MaterialDefinition_MaterialClass pmm	WITH(NOLOCK)
						JOIN [dbo].[Products_Aspect_MaterialDefinition] a		WITH(NOLOCK) ON a.[Origin1MaterialDefinitionId] = pmm.MaterialDefinitionId
						WHERE a.prod_id = @prodId
							AND pmm.Name = 'UOM')	


	--end of loop, fill the output table
	INSERT @Output  (
	ProcessOrder	,
	OriginGroup		,
	MaterialCode	,
	MaterialDesc	,
	NbrOpenRequest	,
	OrderedSince	,
	SuggestedOrder	,	
	Inventory		,
	Available		,		
	SAPlocation		,
	UnitDesc		, 
	MaterialSubCode	,  --v1.4
	MaterialDescSub,
	SIManaged		,
	ThresholdInUOM	,
	UOM							--V1.2
	)
	VALUES (
	@NextProcessOrder,
	@OG,
	@ProdCode,
	@ProdDesc,
	@CountOpenrequest,
	@MinuteSinceLastOrder,
	'--',
	@QuantityInventory,
	'--',
	@Location,
	@SourcePuDesc,
	@ProdCodeSub,
	@ProdDescSub,    --v1.4
	1,
	@ThresholdInUOM,
	@UOM						--V1.2
	)
	
	SET @ProdId = (SELECT MIN(BOMRMProdId) FROM @tblBOMNEXT WHERE BOMRMProdId > @ProdId)
END

Fin:

--Return the final output
SELECT	ProcessOrder,
		OriginGroup, 
		MaterialCode, 
		CASE 
		WHEN MaterialDescSub IS NOT NULL THEN '* ' + MaterialDesc
			ELSE MaterialDesc
		END AS 'MaterialDesc',
		NbrOpenRequest,
		OrderedSince, 
		SuggestedOrder,
		Inventory, 
		Available,
		SAPLocation,
		UnitDesc,
		MaterialSubCode,
		MaterialDescSub,
		SIManaged,
		ThresholdInUOM,
		UOM
	FROM @Output



INSERT local_debug (CallingSP,timestamp, message, msg)
VALUES (	@SPNAME,
			GETDATE(),
			'0999 -End of SP  ' ,
			convert(varchar(50),@pathId)
		)