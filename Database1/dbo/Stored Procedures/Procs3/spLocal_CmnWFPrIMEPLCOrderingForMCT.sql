--------------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[spLocal_CmnWFPrIMEPLCOrderingForMCT]
@pathId							int,
@puid							int,					
@DefaultUserName				varchar(50),
@ULID							varchar(30),
@ProcessOrder					varchar(30),
@Product						varchar(30),
@DebugFlagOnLine				int,
@DebugFlagManual				int


--WITH ENCRYPTION
AS
SET NOCOUNT ON

DECLARE	
@DefaultUserId					int,
@SPName							varchar(50),
@ThisTime						datetime,

--Production Plan
@pathCode						varchar(50),
@ppid							int,
@formulationId					int,
@ppStatusId						int,
@BOMProdId						int,
@BOMPlannedQty					float,
@POPlannedQty					float,
@POActQty						float,
@BOMRMScrapFactor				float,
@BOMRMProdIdSub					int,


--Order information
@ProdId							int,
@prodCode						varchar(25),
@UOM							varchar(50),
@UOMperPallet					float,
@NbrPallet						int,
@StillNeededQty					float,
@StillNeededQtyOr				float,
@StillNeededPallet				int,
@InventoryPallet				int,
@InventoryQty					float,
@OpenRequestPallet				int,
@OpenRequestQty					float,
@PrimeLocation					varchar(30),
@Capacity						int,

----SOA properties
@pnOriginGroupCapacity			varchar(50),
@pnUOMPerPallet					varchar(30),
@pnOriginGroup					varchar(30),
@pnUOM							varchar(50),
@cnOrderMaterials				varchar(50),
@pnPrIMELocation				varchar(50),
@i								int,

----UDPs
@TableIdPath					int,
@TableIdRMI						int,
@tfPEWMSSystemId				int,
@tfAutoOrderProdMaterialByOG	varchar(50),
@tfAutoOrderProdMaterialByOGId	int,
@tfIsOrderingId					int,
@tfUseRMScrapFactorId			int,
@tfRMScrapFactorId				int,
@tfOGId							int,
@udpUseScrapFactorId			int,
@UsePathScrapFactor				bit,
@PLCOrderingForMCTId			int,
@PLCOrderingForMCTTypeId		int,
@PLCOrderingForMCTUsecapacityId	int,
@PE_PPA_UseBOMScrapFactor		int,

--RMIs values
@PEIID							int,
@puidProd						int,
@UseRMScrapFactor				bit,
@RMScrapFactor					float,
@IsOrdering						bit,
@OG								varchar(4),
@orderByOG						bit,
@WMS							varchar(30),
@PLCOrderingForMCT				bit,
@PLCOrderingForMCTType			varchar(30),
@PLCOrderingForMCTUsecapacity	bit,


----Subscription UDPs
@UsePrIME						bit,
@WMSSubscriptionID				int,

------Events and event properties
@toBeReturnedId					int,
@StatusStrRunning				Varchar(30),
@StatusStrActive				varchar(25),
@StatusStrComplete				varchar(25),
@StatusStrNext					varchar(25),
@StatusStrReady					varchar(25),
@IdStatusStrActive				int,
@IDdtatusStrComplete			int,
@IdStatusStrNext				int,
@IdStatusStrReady				int,

-- 1.1
@TableId						int,
@TableFieldId					int


DECLARE @Openrequest TABLE 
(
	OpenTableId			int,
	RequestId			varchar(30),
	PriMeReturnCode				int,
	RequestTime			datetime,
	LocationId			varchar(50),
	CurrentLocation		varchar(50),
	ULID				varchar(50),
	Batch				varchar(50),
	ProcessOrder		varchar(50),
	PrimaryGCAS			varchar(25),
	AlternateGCAS		varchar(25),
	GCAS				varchar(25),
	QuantityValue		float,
	QuantityUOM			varchar(50),
	Status				varchar(50),
	EstimatedDelivery	datetime,
	lastUpdatedTime		datetime,
	userId				int,
	eventId				int
)


-------------------------------------------------------------------------------
-- starts
-------------------------------------------------------------------------------
SELECT	@SPName	= 'spLocal_CmnWFPrIMEPLCOrderingForMCT'


IF @DebugflagOnLine = 1 
BEGIN
	INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
	VALUES(	getdate(), 
			@SPName,
			'0001' +
			' TimeStamp=' + convert(varchar(25), getdate(), 120) +
			' Stored proc started',
			@puid
			)
END	

IF @DebugflagOnLine = 1 
BEGIN
	INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
	VALUES(	getdate(), 
			@SPName,
			'0002' +
			' ProcessOrder=' + COALESCE(@ProcessOrder,'-') +
			' Path id=' + CONVERT(varchar(30),COALESCE(@pathId,0)),
			@puid
			)
END					
		
	

-------------------------------------------------------------------------------------------
--Get User
-------------------------------------------------------------------------------------------
SET @DefaultUserId = NULL
SET @DefaultUserId = (	SELECT	TOP 1 [User_Id]
						FROM	dbo.Users WITH(NOLOCK)
						WHERE	UserName = @DefaultUserName)
IF @DefaultUserId IS NULL
BEGIN
	IF CHARINDEX('\',@DefaultUserName)> 0
	BEGIN
	SET @DefaultUserName  = substring(@DefaultUserName , charindex('\',@DefaultUserName)+1, len( @DefaultUserName ) - charindex('\',@DefaultUserName))
	END 
END

SET @DefaultUserId = (	SELECT	TOP 1 [User_Id]
						FROM	dbo.Users WITH(NOLOCK)
						WHERE	UserName = @DefaultUserName)

IF @DefaultUserId IS NULL
BEGIN
	IF @DebugflagOnLine = 1 
	BEGIN
		INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
		VALUES(	getdate(), 
				@SPName,
				'0007' +
				' TimeStamp=' + convert(varchar(25), getdate(), 120) +
				' Invalid User' + @DefaultUserName,
				@puid
				)
	END

	IF @DebugFlagManual = '1'
	BEGIN
		SELECT 'Invalid User'
	END

	GOTO	ErrCode
END
-------------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Initialize variables.
-------------------------------------------------------------------------------



SELECT	@pnUOMPerPallet					= 'UOM Per Pallet',
		@pnOriginGroup					= 'Origin Group',
		@pnUOM							= 'UOM',
		@pnOriginGroupCapacity			= 'Origin Group Capacity',
		@cnOrderMaterials				= 'PE:PrIME_WMS',
		@pnPrIMELocation				= 'LocationId',
		@tfAutoOrderProdMaterialByOG	= 'AutoOrderProductionMaterialByOG'

--pp_status string
SELECT	@StatusStrActive				= 'Active',
		@StatusStrComplete				= 'Closing',
		@StatusStrNext					= 'Initiate',
		@StatusStrReady					= 'Ready',
--pallet status			
		@StatusStrRunning				= 'Running'
SET		@tobereturnedId					= (SELECT prodStatus_id FROM dbo.production_status WITH(NOLOCK) WHERE prodStatus_desc = 'To be Returned')

--get status IDs
SET @IdStatusStrActive				= (SELECT pp_status_Id FROM dbo.production_plan_statuses WITH(NOLOCK) WHERE pp_status_Desc = @StatusStrActive)
SET @IDdtatusStrComplete			= (SELECT pp_status_Id FROM dbo.production_plan_statuses WITH(NOLOCK) WHERE pp_status_Desc = @StatusStrComplete)
SET @IdStatusStrNext				= (SELECT pp_status_Id FROM dbo.production_plan_statuses WITH(NOLOCK) WHERE pp_status_Desc = @StatusStrNext)
SET @IdStatusStrReady				= (SELECT pp_status_Id FROM dbo.production_plan_statuses WITH(NOLOCK) WHERE pp_status_Desc = @StatusStrReady)

-------------------------------------------------------------------------------------
--Verify if this server uses PrIME
-------------------------------------------------------------------------------------
SET @WMSSubscriptionID	= (SELECT Subscription_Id
							FROM dbo.Subscription
							WHERE Subscription_Desc = 'WMS')						
-- 1.1
SET @TableId		= (		SELECT	t.TableID			FROM dbo.Tables t			WITH (NOLOCK) WHERE upper(t.TableName)			= 'SUBSCRIPTION')
SET @TableFieldId	= (		SELECT	tf.Table_Field_ID	FROM dbo.Table_Fields tf	WITH (NOLOCK) WHERE upper(tf.Table_Field_Desc)	= 'USE_PRIME' and tf.TableId = @TableId)

SET @UsePrIME		= (		SELECT	tfv.Value
							FROM	dbo.Table_Fields_Values tfv	WITH(NOLOCK)
							WHERE	tfv.KeyId				=	@WMSSubscriptionID	
							and		tfv.Table_Field_Id		= 	@TableFieldId
							and		tfv.TableId				=	@TableId		
						)						

IF @UsePrIME != 1
BEGIN
	IF @DebugflagOnLine = 1 
	BEGIN
		INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
		VALUES(	getdate(), 
				@SPName,
				'0011' +
				' TimeStamp=' + convert(varchar(25), getdate(), 120) +
				' Not a PrIME server',
				@puid
				)
	END

	IF @DebugFlagManual = '1'
	BEGIN
		SELECT 'Not a PrIME server'
	END

	GOTO	ErrCode
END


--Get the path code
SET @pathCode = (SELECT path_code FROM dbo.prdExec_paths WITH(NOLOCK) WHERE path_id = @pathId)

SET @PrIMELocation = (	SELECT CONVERT(varchar(50), pee.Value)
						FROM  dbo.PAEquipment_Aspect_SOAEquipment a		
						JOIN dbo.property_equipment_equipmentclass pee	WITH(NOLOCK) ON a.Origin1EquipmentId = pee.EquipmentId
						WHERE pee.Class = @cnOrderMaterials
							AND pee.Name = @pnPrIMELocation 
							AND a.pu_id = @puid )

IF @PrIMELocation IS NULL
BEGIN
	IF @DebugflagOnLine = 1 
	BEGIN
		INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
		VALUES(	getdate(), 
				@SPName,
				'0017 Cannot define PrimeLocation' ,				
				@puid
				)
	END

	IF @DebugFlagManual = '1'
	BEGIN
		SELECT 'Cannot define PrimeLocation'
	END

	GOTO	ErrCode
END


-------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------
--Read required path UDPs
-------------------------------------------------------------------------------------

SET @TableIdPath	= (SELECT TableID FROM dbo.Tables Where tableName = 'PRDExec_Paths')
SET @udpUseScrapFactorId	= (	SELECT Table_Field_Id 	FROM dbo.Table_Fields 			WITH(NOLOCK)	WHERE Table_Field_Desc = 'PE_PPA_UseBOMScrapfactor'	AND tableid = @TableIdPath)
SET @UsePathScrapFactor		= ( SELECT value			FROM dbo.Table_Fields_Values	WITH(NOLOCK)	WHERE Table_Field_Id = @udpUseScrapFactorId 		AND keyid = @pathId		AND tableid = @TableIdPath	 )	

SET @TableIdRMI						= (SELECT TableID FROM dbo.Tables Where tableName = 'PRDExec_inputs')
SET @tfPEWMSSystemId				= (	SELECT Table_Field_Id 	FROM dbo.Table_Fields 			WITH(NOLOCK)	WHERE Table_Field_Desc = 'PE_WMS_System'				AND tableid = @TableIdRMI)
SET @tfIsOrderingId					= (	SELECT Table_Field_Id 	FROM dbo.Table_Fields 			WITH(NOLOCK)	WHERE Table_Field_Desc = 'PE_WMS_IsOrdering'			AND tableid = @TableIdRMI)
SET @tfUseRMScrapFactorId			= (	SELECT Table_Field_Id 	FROM dbo.Table_Fields 			WITH(NOLOCK)	WHERE Table_Field_Desc = 'UseRMScrapFactor'				AND tableid = @TableIdRMI)
SET @tfRMScrapFactorId				= (	SELECT Table_Field_Id 	FROM dbo.Table_Fields 			WITH(NOLOCK)	WHERE Table_Field_Desc = 'RMScrapFactor'				AND tableid = @TableIdRMI)
SET @tfOGId							= (	SELECT Table_Field_Id 	FROM dbo.Table_Fields 			WITH(NOLOCK)	WHERE Table_Field_Desc = 'Origin Group'					AND tableid = @TableIdRMI)
SET @tfAutoOrderProdMaterialByOGId	= (	SELECT Table_Field_Id 	FROM dbo.Table_Fields 			WITH(NOLOCK)	WHERE Table_Field_Desc = @tfAutoOrderProdMaterialByOG	AND tableid = @TableIdRMI)
SET @PLCOrderingForMCTId			= (	SELECT Table_Field_Id 	FROM dbo.Table_Fields 			WITH(NOLOCK)	WHERE Table_Field_Desc = 'PE_PLCOrderingForMCT'			AND tableid = @TableIdRMI)
SET @PLCOrderingForMCTTypeId		= (	SELECT Table_Field_Id 	FROM dbo.Table_Fields 			WITH(NOLOCK)	WHERE Table_Field_Desc = 'PE_PLCOrderingForMCTType'		AND tableid = @TableIdRMI)
SET @PLCOrderingForMCTUsecapacityId	= (	SELECT Table_Field_Id 	FROM dbo.Table_Fields 			WITH(NOLOCK)	WHERE Table_Field_Desc = 'PE_PLCOrderingForMCTUsecapacity'	AND tableid = @TableIdRMI)


------------------------------------------------------------------------------------
--Using the puid, find the right prdExec_inputs
--Then found they RMI udps for thatinput
------------------------------------------------------------------------------------
--Get pei_id
SELECT	TOP 1	@peiid		= pei.pei_id,
				@PuidProd	= pei.pu_id
FROM dbo.prdEXEC_inputs pei			WITH(NOLOCK)
JOIN dbo.prdExec_Input_sources peis	WITH(NOLOCK)	ON pei.pei_id = peis.pei_id
WHERE peis.pu_id = @puid



SET @OG							= (SELECT Value FROM dbo.Table_Fields_Values	WITH(NOLOCK)	WHERE KeyId = @peiid AND Table_Field_Id  = @tfOGId			AND Tableid = @TableIdRMI)
SET @WMS						= (SELECT Value FROM dbo.Table_Fields_Values	WITH(NOLOCK)	WHERE KeyId = @peiid AND Table_Field_Id  = @tfPEWMSSystemId	AND Tableid = @TableIdRMI)
SET @IsOrdering					= (SELECT COALESCE(CONVERT(bit,value),0) FROM dbo.Table_Fields_Values	WITH(NOLOCK)	WHERE KeyId = @peiid AND Table_Field_Id  = @tfIsOrderingId	AND Tableid = @TableIdRMI)
SET @orderByOG					= (SELECT COALESCE(CONVERT(bit,value),0) FROM dbo.Table_Fields_Values	WITH(NOLOCK)	WHERE KeyId = @peiid AND Table_Field_Id  = @tfAutoOrderProdMaterialByOGId	AND Tableid = @TableIdRMI)
SET @UseRMScrapFactor			= (SELECT COALESCE(CONVERT(bit,value),0) FROM dbo.Table_Fields_Values	WITH(NOLOCK)	WHERE KeyId = @peiid AND Table_Field_Id  = @tfUseRMScrapFactorId	AND Tableid = @TableIdRMI)
SET @RMScrapFactor				= (SELECT COALESCE(CONVERT(float,value),0) FROM dbo.Table_Fields_Values	WITH(NOLOCK)	WHERE KeyId = @peiid AND Table_Field_Id  = @tfRMScrapFactorId		AND Tableid = @TableIdRMI)
SET @PLCOrderingForMCT			= (SELECT COALESCE(CONVERT(bit,value),0) FROM dbo.Table_Fields_Values	WITH(NOLOCK)	WHERE KeyId = @peiid AND Table_Field_Id  = @PLCOrderingForMCTId		AND Tableid = @TableIdRMI)
SET @PLCOrderingForMCTType		= (SELECT value FROM dbo.Table_Fields_Values	WITH(NOLOCK)	WHERE KeyId = @peiid AND Table_Field_Id  = @PLCOrderingForMCTTypeId		AND Tableid = @TableIdRMI)
SET @PLCOrderingForMCTUsecapacity	= (SELECT COALESCE(CONVERT(bit,value),0) FROM dbo.Table_Fields_Values	WITH(NOLOCK)	WHERE KeyId = @peiid AND Table_Field_Id  = @PLCOrderingForMCTUsecapacityId		AND Tableid = @TableIdRMI)




IF @DebugflagOnLine = 1 
BEGIN
	INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
	VALUES(	getdate(), 
			@SPName,
			'0100' +
			' Pei_id =' + convert(varchar(25), @peiid) +
			' pu_id production =' + convert(varchar(25), @PuidProd) +
			' OG =' + @OG +
			' IsOrdering =' + convert(varchar(25), @IsOrdering) +
			' orderByOG =' + convert(varchar(25), @orderByOG) +
			' UseRMScrapFactor =' + convert(varchar(25), @UseRMScrapFactor) +
			' RMScrapFactor =' + convert(varchar(25), @RMScrapFactor)+
			' PLCOrderingForMCT =' + convert(varchar(25), @PLCOrderingForMCT)+
			' PLCOrderingForMCTType =' + @PLCOrderingForMCTType+
			' PLCOrderingForMCTUsecapacity =' + convert(varchar(25), @PLCOrderingForMCTUsecapacity)
			, 
			@puid
			)
END		



--------------------------------------------------------------
--Verify that it is PLC ordering for MCT
--If not get out
-------------------------------------------------------------
IF @PLCOrderingForMCT IS NULL
	SET @PLCOrderingForMCT = 0
IF @PLCOrderingForMCT = 0
BEGIN
	INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
	VALUES(	getdate(), 
			@SPName,
			'0125' +
			' Pei_id =' + convert(varchar(25), @peiid) +
			' pu_id production =' + convert(varchar(25), @PuidProd) +
			' OG =' + @OG +
			' This is not MCT for ordering - END'	, 
			@puid
			)

	GOTO	ErrCode
END


--------------------------------------------------------------
--Verify that it is PLC ordering for MCT
--If not get out
-------------------------------------------------------------
IF @orderByOG IS NULL
	SET @orderByOG = 0
IF @orderByOG = 0
BEGIN
	INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
	VALUES(	getdate(), 
			@SPName,
			'0115' +
			' Pei_id =' + convert(varchar(25), @peiid) +
			' pu_id production =' + convert(varchar(25), @PuidProd) +
			' OG =' + @OG +
			' This is not Ordering for that OG - END'	, 
			@puid
			)

	GOTO	ErrCode
END







---------------------------------------------------------------------------------
-- Determine the Case and order based on this case
-- 1 ProcessOrder
-- 2 Product
-- 3 Planned Quantity 
---------------------------------------------------------------------------------


---------------------------------------------------------------------------------
-- Order by Process Order
-- Retrieve the material from the BOM of the process order based on the OG
---------------------------------------------------------------------------------
IF @PLCOrderingForMCTType = 'Process order'
BEGIN
	-------------------------------------------------------------
	--Validate the process order read
	-------------------------------------------------------------
	SET  @ppid = NULL

	--Get PP_ID
	SELECT	@ppid = pp_id,
			@formulationId = bom_formulation_id,
			@ppStatusId = pp_status_id
	FROM dbo.production_plan WITH(NOLOCK)
	WHERE process_order = @ProcessOrder
		AND path_id = @pathId

	IF @DebugflagOnLine = 1 
	BEGIN
		INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
		VALUES(	getdate(), 
				@SPName,
				'0200' +
				'PP_ID: ' + CONVERT(varchar(30),COALESCE(@ppid, -1)) ,
				@puid
				)
	END
	



	--Exit if no PPID
	IF @ppid IS NULL
	BEGIN
		IF @DebugflagOnLine = 1 
		BEGIN
			INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
			VALUES(	getdate(), 
					@SPName,
					'0205' +
					'Invalid Process Order',
					@puid
					)
		END

		IF @DebugFlagManual = '1'
		BEGIN
			SELECT 'Invalid Process Order'
		END

		GOTO	ErrCode
	END


	--Exit if sttaus is Closing or complete
	IF EXISTS(SELECT 1 FROM dbo.production_plan_statuses WITH(NOLOCK) WHERE   pp_status_id = @ppStatusId AND pp_Status_DESC IN ('Complete', 'Closing'))
	BEGIN
		IF @DebugflagOnLine = 1 
		BEGIN
			INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
			VALUES(	getdate(), 
					@SPName,
					'0215' +
					'PO ' + @ProcessOrder +' is already closed',
					@puid
					)
		END

		IF @DebugFlagManual = '1'
		BEGIN
			SELECT 'PO ' + @ProcessOrder +' is already closed'
		END

		GOTO	ErrCode
	END

	
	--Get the product to order from the BOM
	SELECT	@prodId = bom.prod_id,
			@BOMRMProdIdSub = COALESCE(bomfs.prod_Id,0),
			@UOMperPallet = CONVERT(float,pmdmc2.value),
			@prodCode = p.prod_code,
			@UOM = CONVERT(varchar(50),pmdmc3.value)
	FROM	dbo.Bill_Of_Material_Formulation_Item bom				WITH(NOLOCK)
	LEFT JOIN dbo.Bill_Of_Material_Substitution bomfs				WITH(NOLOCK)	ON (bomfs.BOM_Formulation_Item_Id = bom.BOM_Formulation_Item_Id)
	JOIN	dbo.Products_Aspect_MaterialDefinition a				WITH(NOLOCK)	ON bom.prod_id = a.prod_id
	JOIN	dbo.Property_MaterialDefinition_MaterialClass pmdmc		WITH(NOLOCK)	ON pmdmc.MaterialDefinitionId = a.Origin1MaterialDefinitionId
																					AND pmdmc.Name = @pnOriginGroup
	JOIN	dbo.Property_MaterialDefinition_MaterialClass pmdmc2	WITH(NOLOCK)	ON pmdmc2.MaterialDefinitionId = a.Origin1MaterialDefinitionId
																					AND pmdmc2.Name = @pnUOMPerPallet
	JOIN	dbo.Property_MaterialDefinition_MaterialClass pmdmc3	WITH(NOLOCK)	ON pmdmc3.MaterialDefinitionId = a.Origin1MaterialDefinitionId
																					AND CONVERT(varchar(50),pmdmc3.Name) = @pnUOM
	JOIN	dbo.products_base p										WITH(NOLOCK)	ON p.prod_id = bom.prod_id
	WHERE CONVERT(varchar(4),pmdmc.value) = @OG
		AND bom.bom_formulation_id = @formulationId

	SET @NbrPallet = 1

	IF @DebugflagOnLine = 1 
	BEGIN
		INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
		VALUES(	getdate(), 
				@SPName,
				'0230' +
				'ProdCode: ' + @prodCode +
				'UOMperPallet: ' + CONVERT(varchar(30),COALESCE(@UOMperPallet,0)) + ' ' + COALESCE(@UOM, ''),
				@puid
				)
	END

END



---------------------------------------------------------------------------------
-- Order by Product
-- PLC indicates the material to order
---------------------------------------------------------------------------------
IF @PLCOrderingForMCTType = 'Product'
BEGIN
	-------------------------------------------------------------
	--Validate the process order read
	-------------------------------------------------------------
	SET  @prodId = NULL

	--Get prod_id
	SET @prodId = (SELECT prod_id FROM dbo.products_base WITH(NOLOCK) WHERE prod_code = @product)

	IF @DebugflagOnLine = 1 
	BEGIN
		INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
		VALUES(	getdate(), 
				@SPName,
				'0300' +
				'ProdId: ' + CONVERT(varchar(30),@prodId) ,
				@puid
				)
	END
	
	--Exit if no @prodId
	IF @prodId IS NULL
	BEGIN
		IF @DebugflagOnLine = 1 
		BEGIN
			INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
			VALUES(	getdate(), 
					@SPName,
					'0305' +
					'Invalid product passed by PLC',
					@puid
					)
		END

		IF @DebugFlagManual = '1'
		BEGIN
			SELECT 'Invalid product passed by PLC'
		END

		GOTO	ErrCode
	END



	--INSURE the product we need to order is part of the BOM of an active or next order
	IF NOT EXISTS(	SELECT bom.prod_id
					FROM dbo.production_plan pp						WITH(NOLOCK)
					JOIN dbo.bill_of_material_formulation_item bom	WITH(NOLOCK)	ON pp.bom_formulation_id = bom.bom_formulation_id
					WHERE pp.path_id = @pathId
						AND pp.pp_status_id IN (@IdStatusStrActive,@IdStatusStrNext,@IdStatusStrReady)
					)
	BEGIN
		IF @DebugflagOnLine = 1 
		BEGIN
			INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
			VALUES(	getdate(), 
					@SPName,
					'0315' +
					'No PO at least initiated',
					@puid
					)
		END

		IF @DebugFlagManual = '1'
		BEGIN
			SELECT 'No PO at least initiated'
		END

		GOTO	ErrCode
	END


	
	--Get the product to order from the BOM
	SELECT	@UOMperPallet = CONVERT(float,pmdmc2.value),
			@prodCode = p.prod_code,
			@UOM = CONVERT(varchar(50),pmdmc3.value)
	FROM	dbo.Products_Aspect_MaterialDefinition a				
	JOIN	dbo.Property_MaterialDefinition_MaterialClass pmdmc2	WITH(NOLOCK)	ON pmdmc2.MaterialDefinitionId = a.Origin1MaterialDefinitionId
																					AND pmdmc2.Name = @pnUOMPerPallet
	JOIN	dbo.Property_MaterialDefinition_MaterialClass pmdmc3	WITH(NOLOCK)	ON pmdmc3.MaterialDefinitionId = a.Origin1MaterialDefinitionId
																					AND CONVERT(varchar(50),pmdmc3.Name) = @pnUOM
	JOIN	dbo.products p											WITH(NOLOCK)	ON p.prod_id = a.prod_id
	WHERE a.prod_id = @prodid

	SET @NbrPallet = 1

	IF @DebugflagOnLine = 1 
	BEGIN
		INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
		VALUES(	getdate(), 
				@SPName,
				'0330' +
				'ProdCode: ' + @prodCode +
				'UOMperPallet: ' + CONVERT(varchar(30),COALESCE(@UOMperPallet,0)) + ' ' + COALESCE(@UOM, ''),
				@puid
				)
	END

END



---------------------------------------------------------------------------------
-- Order by planned Qty
-- Ordering will be made if still needed is greater than 0
---------------------------------------------------------------------------------
IF @PLCOrderingForMCTType = 'Planned Qty'
BEGIN
--Get the active Order

	SET  @ppid = NULL

	--Get PP_ID
	SELECT	@ppid = pp_id,
			@formulationId = bom_formulation_id,
			@ppStatusId = pp_status_id,
			@POPlannedQty = pp.forecast_quantity,
			@POActQty = pp.actual_good_quantity,
			@ProcessOrder = pp.process_order
	FROM dbo.production_plan pp WITH(NOLOCK)
	WHERE pp_status_id = @IdStatusStrActive
		AND path_id = @pathId


	IF @POPlannedQty IS NULL
		SET @POPlannedQty = 0
	IF @POActQty IS NULL
		SET @POActQty = 0
	
	IF @DebugflagOnLine = 1 
	BEGIN
		INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
		VALUES(	getdate(), 
				@SPName,
				'0400' +
				'PP_ID: ' + CONVERT(varchar(30),COALESCE(@ppid,0)) + 
				'ppStatusId: ' + CONVERT(varchar(30),COALESCE(@ppStatusId,0)) +
				'PO Planned Qty: ' + CONVERT(varchar(30),COALESCE(@POPlannedQty,0)) +
				'PO Act Qty: ' + CONVERT(varchar(30),COALESCE(@POActQty,0)) ,
				@puid
				)
	END

	--if the active PO doesn't is null or overproduced, check for the Next PO
	IF (@ppid IS NULL) OR (@POActQty > @POPlannedQty)
	BEGIN
		SELECT	@ppid = pp_id,
		@formulationId = bom_formulation_id,
		@ppStatusId = pp_status_id,
		@POPlannedQty = pp.forecast_quantity,
		@POActQty = pp.actual_good_quantity
		FROM dbo.production_plan pp WITH(NOLOCK)
		WHERE pp_status_id IN (@IdStatusStrNEXT, @IdStatusStrReady)
			AND path_id = @pathId

		IF @POPlannedQty IS NULL
			SET @POPlannedQty = 0
		IF @POActQty IS NULL
			SET @POActQty = 0

		IF @DebugflagOnLine = 1 
		BEGIN
			INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
			VALUES(	getdate(), 
					@SPName,
					'0420' +
					'PP_ID: ' + CONVERT(varchar(30),COALESCE(@ppid,0)) + 
					'ppStatusId: ' + CONVERT(varchar(30),COALESCE(@ppStatusId,0)) +
					'PO Planned Qty: ' + CONVERT(varchar(30),COALESCE(@POPlannedQty,0)) +
					'PO Act Qty: ' + CONVERT(varchar(30),COALESCE(@POActQty,0)) ,
					@puid
					)
		END
	END

	--Exit if no PPID
	IF @ppid IS NULL
	BEGIN
		IF @DebugflagOnLine = 1 
		BEGIN
			INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
			VALUES(	getdate(), 
					@SPName,
					'0425' +
					'Invalid Process Order',
					@puid
					)
		END

		IF @DebugFlagManual = '1'
		BEGIN
			SELECT 'Invalid Process Order'
		END

		GOTO	ErrCode
	END


	SET @processOrder = (SELECT process_order FROM dbo.production_Plan WITH(NOLOCK) WHERE pp_id = @ppid)

	--Get the product to order from the BOM
	SELECT	@prodId = bom.prod_id,
			@BOMRMProdIdSub = COALESCE(bomfs.prod_Id,0),
			@BomPlannedQty = bom.quantity,
			@BOMRMScrapFactor	= COALESCE(bom.scrap_factor,0),
			@UOMperPallet = CONVERT(float,pmdmc2.value),
			@prodCode = p.prod_code,
			@UOM = CONVERT(varchar(50),pmdmc3.value)
	FROM	dbo.Bill_Of_Material_Formulation_Item bom				WITH(NOLOCK)
	LEFT JOIN dbo.Bill_Of_Material_Substitution bomfs				WITH(NOLOCK) ON (bomfs.BOM_Formulation_Item_Id = bom.BOM_Formulation_Item_Id)
	JOIN	dbo.Products_Aspect_MaterialDefinition a				WITH(NOLOCK)	ON bom.prod_id = a.prod_id
	JOIN	dbo.Property_MaterialDefinition_MaterialClass pmdmc		WITH(NOLOCK)	ON pmdmc.MaterialDefinitionId = a.Origin1MaterialDefinitionId
																					AND pmdmc.Name = @pnOriginGroup
	JOIN	dbo.Property_MaterialDefinition_MaterialClass pmdmc2	WITH(NOLOCK)	ON pmdmc2.MaterialDefinitionId = a.Origin1MaterialDefinitionId
																					AND pmdmc2.Name = @pnUOMPerPallet
	JOIN	dbo.Property_MaterialDefinition_MaterialClass pmdmc3	WITH(NOLOCK)	ON pmdmc3.MaterialDefinitionId = a.Origin1MaterialDefinitionId
																					AND CONVERT(varchar(50),pmdmc3.Name) = @pnUOM
	JOIN	dbo.products_base p										WITH(NOLOCK)	ON p.prod_id = bom.prod_id
	WHERE CONVERT(varchar(4),pmdmc.value) = @OG
		AND bom.bom_formulation_id = @formulationId


	--Exit if no prod_id
	IF @prodId IS NULL
	BEGIN
		IF @DebugflagOnLine = 1 
		BEGIN
			INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
			VALUES(	getdate(), 
					@SPName,
					'0425' +
					'Invalid product',
					@puid
					)
		END

		IF @DebugFlagManual = '1'
		BEGIN
			SELECT 'Invalid Product'
		END

		GOTO	ErrCode
	END

	IF @DebugflagOnLine = 1 
	BEGIN
		INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
		VALUES(	getdate(), 
				@SPName,
				'0450' +
				'PP_ID: ' + CONVERT(varchar(30),COALESCE(@ppid,0)) + 
				'prod Id: ' + CONVERT(varchar(30),COALESCE(@prodId,0)) +
				'Alternate prod id: ' + CONVERT(varchar(30),COALESCE(@BOMRMProdIdSub,-1)) +
				'BOM ScrapFactor: ' + CONVERT(varchar(30),COALESCE(@BOMRMScrapFactor,0)) +
				'POActQty: ' + CONVERT(varchar(30),COALESCE(@POActQty,0)) ,
				@puid
				)
	END

	--Calculate STill needed based on theoretical consumption
	SET @StillNeededQty = (@BomPlannedQty-(@POActQty/@POPlannedQty*@BomPlannedQty))
	SET @StillNeededQtyOr = @StillNeededQty


	--Update BOMQTY based on scrap factor
	IF @UsePathScrapFactor = 1 AND @BOMRMScrapFactor != 0 AND @BOMRMScrapFactor IS NOT NULL
	BEGIN
			SELECT	@StillNeededQty = @StillNeededQtyOr * (1+@BOMRMScrapFactor/100)
	END
		
	IF @UseRMScrapFactor = 1 AND @RMScrapFactor != 0 AND @RMScrapFactor IS NOT NULL
	BEGIN
			SELECT	@StillNeededQty = @StillNeededQty + (@StillNeededQtyOr  * (@RMScrapFactor/100)) 
					
	END


	--Exclude the inventory and the openrequest from the still needed.


	--Get the inventory
	SELECT	@InventoryPallet	= COUNT(e.event_id),
			@InventoryQty		= SUM(ed.final_dimension_x)
	FROM dbo.events e				WITH(NOLOCK)
	JOIN dbo.event_details ed		WITH(NOLOCK) ON e.event_id = ed.event_id
	JOIN dbo.production_status ps	WITH(NOLOCK) ON e.event_status = ps.prodStatus_id
	WHERE e.applied_product IN (@prodId,@BOMRMProdIdSub )
		AND e.pu_id = @puid
		AND (((ps.count_For_Production = 1 AND ps.count_For_Inventory = 1)	OR (ps.count_For_Production = 0 AND ps.count_For_Inventory = 0)))

	IF @InventoryPallet IS NULL
		SET @InventoryPallet = 0

	IF @InventoryQty IS NULL
		SET @InventoryQty = 0


	--Get Open requests
	INSERT @Openrequest (OpenTableId,RequestId,PrimeReturnCode,RequestTime,LocationId,CurrentLocation,ULID,Batch,ProcessOrder,PrimaryGCAS,AlternateGCAS,GCAS,QuantityValue,QuantityUOM,Status,EstimatedDelivery,
	lastUpdatedTime	,userId, eventid	)
	EXEC dbo.spLocal_CmnPrIMEGetOpenRequests @pathCode,NULL,NULL

	--set quantityValue where the value is empty
	UPDATE @Openrequest 
	SET QuantityValue = @UOMperPallet
	WHERE (QuantityValue IS NULL OR QuantityValue = 1) 
		AND PrimaryGCAS = @prodCode


	SELECT	@OpenRequestPallet	= COUNT(RequestId),
			@OpenRequestQty		= SUM(QuantityValue)
	FROM @Openrequest
	WHERE PrimaryGCAS = @prodCode

	IF @OpenRequestPallet IS NULL
		SET @OpenRequestPallet = 0

	IF @OpenRequestQty IS NULL
		SET @OpenRequestQty = 0

	SET @StillNeededQty = @StillNeededQty - @OpenRequestQty - @InventoryQty
	SET @StillNeededPallet = (SELECT CEILING((@StillNeededQty/@UOMperPallet)))
	--Set the number of required pallet based on UOM per pallet
	SET @NbrPallet = (SELECT CEILING((@StillNeededQty/@UOMperPallet)))

	IF @DebugflagOnLine = 1 
	BEGIN
		INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
		VALUES(	getdate(), 
				@SPName,
				'0470' +
				'PP_ID: ' + CONVERT(varchar(30),COALESCE(@ppid,0)) + 
				'prod Id: ' + CONVERT(varchar(30),COALESCE(@prodId,0)) +
				'NbrPallet: ' + CONVERT(varchar(30),COALESCE(@NbrPallet,-1)) +
				'prodCode: ' + COALESCE(@prodCode,'0') +
				'UOM per Pallet: ' + CONVERT(varchar(30),COALESCE(@UOMperPallet,0)) ,
				@puid
				)
	END

END




---------------------------------------------------------------------------------
-- Check if we need to use capacity
-- this is set on the path UDP
-- If capacity is needed, it will have to be read on the sotgare loc
---------------------------------------------------------------------------------

IF @PLCOrderingForMCTUsecapacity = 1
BEGIN
	IF @DebugflagOnLine = 1 
	BEGIN
		INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
		VALUES(	getdate(), 
				@SPName,
				'0500 use capacity' ,
				@puid
				)
	END


	SELECT  @Capacity = CONVERT(int, pee.Value)
	FROM dbo.PAEquipment_Aspect_SOAEquipment a		WITH(NOLOCK) 
	JOIN dbo.property_equipment_equipmentclass pee	WITH(NOLOCK) ON a.Origin1EquipmentId = pee.EquipmentId
																	AND pee.Name LIKE '%'+  @OG + '.' + @pnOriginGroupCapacity
	WHERE a.pu_id = @puid

	IF @DebugflagOnLine = 1 
	BEGIN
		INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
		VALUES(	getdate(), 
				@SPName,
				'0530' +
				'PP_ID: ' + CONVERT(varchar(30),COALESCE(@ppid,0)) + 
				'prod Id: ' + CONVERT(varchar(30),COALESCE(@prodId,0)) +
				'Capacity: ' + CONVERT(varchar(30),COALESCE(@Capacity,-1)) ,
				@puid
				)
	END



	IF @PLCOrderingForMCTType = 'Product' OR @PLCOrderingForMCTType = 'Process Order'
	BEGIN
		--Get inventory (we already have it for Planned Qty)

		--Get the inventory
		SELECT	@InventoryPallet	= COUNT(e.event_id),
				@InventoryQty		= SUM(ed.final_dimension_x)
		FROM dbo.events e				WITH(NOLOCK)
		JOIN dbo.event_details ed		WITH(NOLOCK) ON e.event_id = ed.event_id
		JOIN dbo.production_status ps	WITH(NOLOCK) ON e.event_status = ps.prodStatus_id
		WHERE e.applied_product IN (@prodId,@BOMRMProdIdSub )
			AND e.pu_id = @puid
			AND (((ps.count_For_Production = 1 AND ps.count_For_Inventory = 1)	OR (ps.count_For_Production = 0 AND ps.count_For_Inventory = 0)))

		IF @InventoryPallet IS NULL
			SET @InventoryPallet = 0

		IF @InventoryQty IS NULL
			SET @InventoryQty = 0


		--Get Open requests
		INSERT @Openrequest (OpenTableId,RequestId,PrimeReturnCode,RequestTime,LocationId,CurrentLocation,ULID,Batch,ProcessOrder,PrimaryGCAS,AlternateGCAS,GCAS,QuantityValue,QuantityUOM,Status,EstimatedDelivery,
		lastUpdatedTime	,userId, eventid	)
		EXEC dbo.spLocal_CmnPrIMEGetOpenRequests @pathCode,NULL,NULL

		--set quantityValue where the value is empty
		UPDATE @Openrequest 
		SET QuantityValue = @UOMperPallet
		WHERE (QuantityValue IS NULL OR QuantityValue = 1) 
			AND PrimaryGCAS = @prodCode


		SELECT	@OpenRequestPallet	= COUNT(RequestId),
				@OpenRequestQty		= SUM(QuantityValue)
		FROM @Openrequest
		WHERE PrimaryGCAS = @prodCode

		IF @OpenRequestPallet IS NULL
			SET @OpenRequestPallet = 0

		IF @OpenRequestQty IS NULL
			SET @OpenRequestQty = 0

		IF @DebugflagOnLine = 1 
		BEGIN
			INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
			VALUES(	getdate(), 
					@SPName,
					'0560' +
					'PP_ID: ' + CONVERT(varchar(30),COALESCE(@ppid,0)) + 
					'@InventoryPallet: ' + CONVERT(varchar(30),COALESCE(@InventoryPallet,0)) +
					'@OpenRequestPallet: ' + CONVERT(varchar(30),COALESCE(@OpenRequestPallet,-1)) ,
					@puid
					)
		END
	END

		IF @Capacity <= (@OpenRequestPallet + @InventoryPallet)
		BEGIN
			SET @NbrPallet = 0
		END
		ELSE
		BEGIN
			SET @NbrPallet = @Capacity - (@OpenRequestPallet + @InventoryPallet)


			--Special case for Planned Qty.  When the still needed is smaller than the capacity, use still needed pallet.
			IF @StillNeededPallet IS NOT NULL
			BEGIN
				IF @StillNeededPallet < @NbrPallet
					SET @NbrPallet = 0
			END
		END
END
ELSE
BEGIN
	IF @DebugflagOnLine = 1 
	BEGIN
		INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
		VALUES(	getdate(), 
				@SPName,
				'0600 do not use capacity' ,
				@puid
				)
	END

	--Order only one pallets
	SET @NbrPallet = 1



END



---------------------------------------------------------------------------------
-- Order material
---------------------------------------------------------------------------------

SET @i = 0
WHILE @i<@NbrPallet
BEGIN

		
	EXEC dbo.spLocal_CmnPrIMECreateOpenRequest	@PrimeLocation,@ProcessOrder,@ProdCode,NULL,1,NULL,@defaultUserName

	IF @DebugflagOnLine = 1 
	BEGIN
	INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
	VALUES(	getdate(), 
			@SPName,
			'700' +
			'@PrimeLocation: ' + COALESCE(@PrimeLocation,'-') + 
			'@ProcessOrder: ' + COALESCE(@ProcessOrder,'-') +
			'@ProdCode: ' + COALESCE(@ProdCode,'-') ,
			@puid
			)
	END

	/*  --replacxed by real SP
	--Create a request ID
	SELECT @requestId = CONVERT(varchar(30),datediff(s,'1-Aug-2018',Getdate())+@i+@LOOPIndex)

	--Temp

	INSERT local_PrIME_OpenRequests (RequestId, PickId,RequestTime, LocationId, ULID, Batch, ProcessOrder, PrimaryGCAS, AlternateGCAS, GCAS, QuantityValue, QuantityUOM, Status, UserId,eventid,lastUpdatedTime)
	VALUES (@requestId,NULL,GETDATE(),@BOMRMTNLOCATN,NULL,NULL,@NxtPPProcessOrder,@BOMRMProdCode,@BOMRMSubProdCode,NULL,1,'EA','RequestMaterial',383,NULL, getdate())
	*/
	SELECT @ThisTime = Getdate()
	EXEC dbo.spLocal_InsertTblMaterialRequest	'Request', @ProcessOrder, @ProdCode,	@PrimeLocation,  @ThisTime,	1,@DefaultUserId,'PRODUCTION', 'Auto','Success',''

	SELECT @i = @i+1
END




ErrCode:

IF @DebugFlagOnLine = 1  
BEGIN
	INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
		VALUES(	getdate(), 
				@SPName,
				'9999' +

				' Finished',
				@PathId
				)
END


SET NOcount OFF

RETURN