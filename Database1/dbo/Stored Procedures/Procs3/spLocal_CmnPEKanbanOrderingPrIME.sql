

--------------------------------------------------------------------------------------------------
-- Stored Procedure: spLocal_CmnPEKanbanOrderingPrIME
--------------------------------------------------------------------------------------------------
-- Author				: Ugo Lapierre, Symasol
-- Date created			: 13-Aug-2019	
-- Version 				: Version <1.0>
-- SP Type				: Generic SP
-- Caller				: Other SP or Mobile App
-- Description			:	FO-03832
--							It order material for kanban type 2 material (order to plan quantity)
--							This SP order Material for a specific OG provided to the SP
--							It orders material for Active order first.  Then for Next order if there is still capacity.
-- Editor tab spacing	: 4
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ========		====	  		====					=====
-- 1.0			13-Aug-2019		U.Lapierre				Original
-- 1.1			2019-08-28		U.Lapierre				FO-03832.  Replace UDP KanbanOrderingType by OrderingType
-- 1.2			2019-09-23		U.Lapierre				remove on route from Stillneeded
-- 1.3			2019-11-19		A. Metlitski			Fix Table_Fields JOIN
-- 1.4			2019-11-29		U. Lapierre				Catch output of the open request Stored proc
-- 1.5			2019			U.Lapierre				Fix Issue getting the open request for the next Order while there is still an active order
-- 1.6			2020-06-08		U.Lapierre				BAT Shiga Issue.  remove on route from Stillneeded or chnageover material (same as 1.2)
-- 1.7			2022-01-31		U.Lapierre				Replace the VARCHAR(8)
-- 1.8			2023-07-25		L. Hudon				fix issue slowness with pedexecinput UDP, add identity on  @PRDExecInputs AND split RMI  UDP called 
/*---------------------------------------------------------------------------------------------
Testing Code

-----------------------------------------------------------------------------------------------*/
--EXEC spLocal_CmnPEKanbanOrderingPrIME 150,'B160','System.PE',1

--------------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[spLocal_CmnPEKanbanOrderingPrIME]
@PathId							INT,
@OG								VARCHAR(4),
@DefaultUserName				VARCHAR(100),
@DebugflagOnLine				BIT

--WITH ENCRYPTION
AS
SET NOCOUNT ON;


DECLARE	
@DefaultUserId					INT,
@SPName							VARCHAR(50),
@TableId						INT,
@TableFieldId					INT,


----Subscription UDPs
@UsePrIME						BIT,
@WMSSubscriptionID				INT,


--ProcessOrder
@ActPPId						INT,
@ActPPIDNext					INT,
@ActPPProcessOrder				VARCHAR(12),
@ActBOMFormId					INT,
@ActPPLineCounterQty			FLOAT,
@ActPPPlannedStartTime			DATETIME,
@ActPPPlannedEndTime			DATETIME,	
@StatusStrActive				VARCHAR(30),
@NxtPPId						INT,
@NxtPPProcessOrder				VARCHAR(12),
@NxtBOMFormId					INT,
@NxtPPLineCounterQty			FLOAT,
@NxtPPPlannedStartTime			DATETIME,
@NxtPPPlannedEndTime			DATETIME,	
@StatusStrInitiate				VARCHAR(30),
@StatusStrReady					VARCHAR(30),
@ProductionPuID					INT,
@PPStartTime					DATETIME,

--SOA properties
@pnUOMPerPallet					VARCHAR(30),
@pnOriginGroup					VARCHAR(30),
@pnUOM							VARCHAR(50),
@pnOriginGroupCapacity			VARCHAR(50),

--BOM variables
@BOMRMFormItemId				INT,
@BOMRMScrapFactor				FLOAT,
@BomQty							FLOAT,
@SourcePuID						INT,
@ProdId							INT,
@ProdIdSub						INT,
@ProdCode						VARCHAR(25),
@ProdCodeSub					VARCHAR(25),
@ProdCodeActive					VARCHAR(25),


--Calculation variables
@TPQ							FLOAT,
@TCQ							FLOAT,
@StillNeededQty					FLOAT,
@StillNeededCnt					INT,
@DeliveredCnt					INT,
@RequestCnt						FLOAT,
@OnRouteQty						FLOAT,
@OnRouteCnt						INT,
@ToOrderCnt						INT,
@Capacity						INT,
@UOMperPallet					FLOAT,		
@capacityMovedToNext			BIT,
@Row							INT,
@capacityNext					INT,

--Ordering
@PrIMELocation					VARCHAR(50),
@cnOrderMaterials				VARCHAR(50),
@pnPrIMELocation				VARCHAR(50),
@ThisTime						DATETIME,
@pathCode						VARCHAR(20),

----UDPs
@TableIdPath					INT,
@TableIdRMI						INT,
@tfPEWMSSystemId				INT,
@tfSafetyStockId				INT,
@tfAutoOrderProdMaterialByOGId	INT,
@tfIsOrderingId					INT,
@tfUseRMScrapFactorId			INT,
@tfRMScrapFactorId				INT,
@tfOGId							INT,
@udpUseScrapFactorId			INT,
@UsePathScrapFactor				BIT,
@IsSCOLineId					INT,
@IsSCOLine						BIT,
@tfKanbanTypeId					INT,
@AutoOrderByOg					BIT,
@UseRMScrapFactor				BIT,
@RMScrapFactor					FLOAT,
@IsOrdering						BIT,
@SafetyStock					BIT,
@KanbanType						INT,
@PEWMSSystem					VARCHAR(30),

--Productiuon status
@ConsumedStatusId				INT,
@OverconsumedStatusId			INT,
@RunningStatusId				INT,
@CheckedInStatusId				INT,
@DeliveredStatusId				INT;

DECLARE @PRDExecInputs TABLE 
(
	Id							 INT	IDENTITY,--v1.8
	PUID						INT,
	PEIID						INT,
	OG							VARCHAR(50),
	PEWMSSystem					VARCHAR(50),
	IsOrdering					BIT,
	IsSafetyStock				BIT DEFAULT 0,
	AutoorderingByOG			BIT DEFAULT 0,
	UseRMScrapFactor			BIT DEFAULT 0,
	RMScrapFactor				FLOAT DEFAULT 0,
	KanbanType					INT DEFAULT 0
			);


DECLARE @tblBOMRMListNext TABLE
(	BOMRMId						INT IDENTITY,
	PPId						INT,
	ProcessOrder				VARCHAR(50),
	PPStatusStr					VARCHAR(25),
	BOMRMProdId					INT,
	BOMRMProdCode				VARCHAR(25),
	BOMRMQty					FLOAT,
	BOMRMEngUnitDesc			VARCHAR(25),
	BOMRMScrapFactor			FLOAT,
	BOMRMFormItemId				INT,
	BOMRMOG						VARCHAR(25),
	ProductGroupCapacity		INT,
	ProductUOMPerPallet			FLOAT,
	FlgUniqueToActiveOrder		BIT,
	BOMRMStoragePUId			INT,
	BOMRMStoragePUDesc			VARCHAR(50),
	BOMRMProdIdSub				INT,
	BOMRMProdCodeSub			VARCHAR(25)
);

DECLARE @tblBOMRMListActive TABLE
(	BOMRMId						INT IDENTITY,
	PPId						INT,
	ProcessOrder				VARCHAR(50),
	PPStatusStr					VARCHAR(25),
	BOMRMProdId					INT,
	BOMRMProdCode				VARCHAR(25),
	BOMRMQty					FLOAT,
	BOMRMEngUnitDesc			VARCHAR(25),
	BOMRMScrapFactor			FLOAT,
	BOMRMFormItemId				INT,
	BOMRMOG						VARCHAR(25),
	ProductGroupCapacity		INT,
	ProductUOMPerPallet			FLOAT,
	FlgUniqueToActiveOrder		BIT,
	BOMRMStoragePUId			INT,
	BOMRMStoragePUDesc			VARCHAR(50),
	BOMRMProdIdSub				INT,
	BOMRMProdCodeSub			VARCHAR(25)
);

DECLARE @ParentEvents	TABLE(
SourceEventId						INT,
RMEventId							INT,
RMEventStatus						INT,
Qty									FLOAT
);


DECLARE @Openrequest TABLE 
(
	OpenTableId			INT,
	RequestId			VARCHAR(30),
	PrimeReturnCode		INT,
	RequestTime			DATETIME,
	LocationId			VARCHAR(50),
	CurrentLocation		VARCHAR(50),
	ULID				VARCHAR(50),
	Batch				VARCHAR(50),
	ProcessOrder		VARCHAR(50),
	PrimaryGCAS			VARCHAR(25),
	AlternateGCAS		VARCHAR(25),
	GCAS				VARCHAR(25),
	QuantityValue		FLOAT,
	QuantityUOM			VARCHAR(50),
	Status				VARCHAR(50),
	EstimatedDelivery	DATETIME,
	lastUpdatedTime		DATETIME,
	userId				INT,
	eventId				INT
);


DECLARE @CatchGarbage TABLE (
garbage				VARCHAR(300)
);


-------------------------------------------------------------------------------
-- starts
-------------------------------------------------------------------------------
SELECT	@SPName	= 'spLocal_CmnPEKanbanOrderingPrIME';

IF @DebugflagOnLine = 1 
BEGIN
	INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
	VALUES(	GETDATE(), 
			@SPName,
			'0001' +
			' OG=' + @OG +
			' Stored proc started',
			@pathid
			);
END	;
-------------------------------------------------------------------------------------------
--Get User
-------------------------------------------------------------------------------------------
SET @DefaultUserId = NULL;
SET @DefaultUserId = (	SELECT	TOP 1 [User_Id]
						FROM	dbo.Users WITH(NOLOCK)
						WHERE	UserName = @DefaultUserName);
IF @DefaultUserId IS NULL
BEGIN
	IF CHARINDEX('\',@DefaultUserName)> 0
	BEGIN
	SET @DefaultUserName  = SUBSTRING(@DefaultUserName , CHARINDEX('\',@DefaultUserName)+1, len( @DefaultUserName ) - CHARINDEX('\',@DefaultUserName));
	END ;
END;

SET @DefaultUserId = (	SELECT	TOP 1 [User_Id]
						FROM	dbo.Users WITH(NOLOCK)
						WHERE	UserName = @DefaultUserName);

IF @DefaultUserId IS NULL
BEGIN
	IF @DebugflagOnLine = 1 
	BEGIN
		INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
		VALUES(	GETDATE(), 
				@SPName,
				'0007' +
				' TimeStamp=' + convert(VARCHAR(25), GETDATE(), 120) +
				' Invalid User' + @DefaultUserName,
				@pathid
				);
	END;

	GOTO	ErrCode;
END;
-------------------------------------------------------------------------------------
--Verify if this server uses PrIME
-------------------------------------------------------------------------------------
SET @WMSSubscriptionID	= (SELECT Subscription_Id
							FROM dbo.Subscription
							WHERE Subscription_Desc = 'WMS');						



SET @TableId		= (SELECT	t.TableID			FROM dbo.Tables t			WITH (NOLOCK) WHERE UPPER(t.TableName)			= 'SUBSCRIPTION');
SET @TableFieldId	= (SELECT	tf.Table_Field_ID	FROM dbo.Table_Fields tf	WITH (NOLOCK) WHERE UPPER(tf.Table_Field_Desc)	= 'USE_PRIME' AND tf.TableId = @TableId);

SET @UsePrIME			= (	SELECT	tfv.Value
							FROM	dbo.Table_Fields_Values tfv	WITH(NOLOCK)
							WHERE	tfv.KeyId 			= @WMSSubscriptionID
							AND		tfv.Table_Field_Id	= @TableFieldId
							AND		tfv.TableId			= @TableId				
						);


		
IF @UsePrIME != 1
BEGIN
	IF @DebugflagOnLine = 1 
	BEGIN
		INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
		VALUES(	GETDATE(), 
				@SPName,
				'0011' +
				' TimeStamp=' + convert(VARCHAR(25), GETDATE(), 120) +
				' Not a PrIME server',
				@pathid
				);
	END;

	GOTO	ErrCode;
END;
-------------------------------------------------------------------------------------


-------------------------------------------------------------------------------
-- Initialize variables.
-------------------------------------------------------------------------------
--pp_status string
SELECT	@StatusStrActive				= 'Active',
		@StatusStrInitiate				= 'Initiate',
		@StatusStrReady					= 'Ready';


SELECT	@pnUOMPerPallet					= 'UOM Per Pallet',
		@pnOriginGroup					= 'Origin Group',
		@pnUOM							= 'UOM',
		@pnOriginGroupCapacity			= 'Origin Group Capacity';

SET @capacityMovedToNext = 0;

--For material ordering
SELECT	@pnPrIMELocation				= 'LocationId',
		@cnOrderMaterials				= 'PE:PrIME_WMS';

SET @ConsumedStatusId		= (SELECT prodStatus_id FROM dbo.production_status WITH(NOLOCK) WHERE prodStatus_Desc = 'Consumed');
SET @OverconsumedStatusId	= (SELECT prodStatus_id FROM dbo.production_status WITH(NOLOCK) WHERE prodStatus_Desc = 'Overconsumed');
SET @RunningStatusId		= (SELECT prodStatus_id FROM dbo.production_status WITH(NOLOCK) WHERE prodStatus_Desc = 'Running');
SET @CheckedInStatusId		= (SELECT prodStatus_id FROM dbo.production_status WITH(NOLOCK) WHERE prodStatus_Desc = 'Checked in');
SET @DeliveredStatusId		= (SELECT prodStatus_id FROM dbo.production_status WITH(NOLOCK) WHERE prodStatus_Desc = 'Delivered');

SET @pathCode = (SELECT path_code FROM dbo.prdExec_Paths WITH(NOLOCK) WHERE path_id = @pathId)
;
SET @ProdCodeActive = ' ';		--V1.6
-------------------------------------------------------------------------------------
--Read required path UDPs
-------------------------------------------------------------------------------------

SET @TableIdPath	= (SELECT TableID FROM dbo.Tables Where tableName = 'PRDExec_Paths');


SET @udpUseScrapFactorId	= (	SELECT Table_Field_Id 	FROM dbo.Table_Fields 			WITH(NOLOCK)	WHERE Table_Field_Desc = 'PE_PPA_UseBOMScrapfactor'	AND tableid = @TableIdPath);
SET @UsePathScrapFactor		= ( SELECT value			FROM dbo.Table_Fields_Values	WITH(NOLOCK)	WHERE Table_Field_Id = @udpUseScrapFactorId 		AND keyid = @pathId		AND tableid = @TableIdPath	 )	;
SET @IsSCOLineId			= ( SELECT Table_Field_id	FROM dbo.Table_Fields			WITH(NOLOCK)	WHERE Table_Field_Desc  = 'PE_General_IsSCOLine'	AND TableID = @TableIdPath);
SET @IsSCOLine				= ( SELECT value			FROM dbo.Table_Fields_values	WITH(NOLOCK)	WHERE table_Field_ID = @IsSCOLineId AND KEYID  = @PathId) ;
IF @IsSCOLine IS NULL
	SET @IsSCOLine = 0;

SET @TableIdRMI						= (SELECT TableID FROM dbo.Tables Where tableName = 'PRDExec_inputs');
SET @tfPEWMSSystemId				= (	SELECT Table_Field_Id 	FROM dbo.Table_Fields 			WITH(NOLOCK)	WHERE Table_Field_Desc = 'PE_WMS_System'					AND tableid = @TableIdRMI);
SET @tfIsOrderingId					= (	SELECT Table_Field_Id 	FROM dbo.Table_Fields 			WITH(NOLOCK)	WHERE Table_Field_Desc = 'PE_WMS_IsOrdering'				AND tableid = @TableIdRMI);
SET @tfUseRMScrapFactorId			= (	SELECT Table_Field_Id 	FROM dbo.Table_Fields 			WITH(NOLOCK)	WHERE Table_Field_Desc = 'UseRMScrapFactor'					AND tableid = @TableIdRMI);
SET @tfRMScrapFactorId				= (	SELECT Table_Field_Id 	FROM dbo.Table_Fields 			WITH(NOLOCK)	WHERE Table_Field_Desc = 'RMScrapFactor'					AND tableid = @TableIdRMI);
SET @tfOGId							= (	SELECT Table_Field_Id 	FROM dbo.Table_Fields 			WITH(NOLOCK)	WHERE Table_Field_Desc = 'Origin Group'						AND tableid = @TableIdRMI);
SET @tfSafetyStockId				= (	SELECT Table_Field_Id 	FROM dbo.Table_Fields 			WITH(NOLOCK)	WHERE Table_Field_Desc = 'SafetyStock'						AND tableid = @TableIdRMI);
SET @tfAutoOrderProdMaterialByOGId	= (	SELECT Table_Field_Id 	FROM dbo.Table_Fields 			WITH(NOLOCK)	WHERE Table_Field_Desc = 'AutoOrderProductionMaterialByOG'	AND tableid = @TableIdRMI);
SET @tfKanbanTypeId					= (	SELECT Table_Field_Id 	FROM dbo.Table_Fields 			WITH(NOLOCK)	WHERE Table_Field_Desc = 'OrderingType'						AND tableid = @TableIdRMI);



--Get All RMIs
INSERT @PRDExecInputs (
						PUID,
						PEIID,
						OG,
						PEWMSSystem,
						IsOrdering,
						IsSafetyStock,
						AutoorderingByOG,
						UseRMScrapFactor
						--RMScrapFactor,
						--KanbanType
						)
SELECT	pepu.PU_Id, 
		pei.PEI_Id, 
		tfv.Value,									--OG
		tfv2.value,									--PEWMSSystem
		CONVERT(BIT,tfv3.value),					--IsOrdering		
		COALESCE(CONVERT(BIT,tfv4.value),0),		--IsSafetyStock
		COALESCE(CONVERT(BIT,tfv5.value),0),		--AutoorderingByOG
		COALESCE(CONVERT(FLOAT,tfv7.value),0)		--UseRMScrapFactor
		--COALESCE(CONVERT(FLOAT,tfv8.value),0),		--RMScrapFactor
		--COALESCE(CONVERT(INT,tfv12.value),0)
FROM dbo.PrdExec_Path_Units pepu		WITH(NOLOCK)
JOIN dbo.PrdExec_Inputs pei				WITH(NOLOCK)	ON pei.PU_Id = pepu.PU_Id
JOIN dbo.Table_Fields_Values tfv		WITH(NOLOCK)	ON tfv.KeyId = pei.PEI_Id AND tfv.Table_Field_Id  = @tfOGId
JOIN dbo.Table_Fields_Values tfv2		WITH(NOLOCK)	ON tfv2.KeyId= pei.PEI_Id AND tfv2.Table_Field_Id = @tfPEWMSSystemId
LEFT JOIN dbo.Table_Fields_Values tfv3	WITH(NOLOCK)	ON tfv3.KeyId= pei.PEI_Id AND tfv3.Table_Field_Id = @tfIsOrderingId
LEFT JOIN dbo.Table_Fields_Values tfv4	WITH(NOLOCK)	ON tfv4.KeyId= pei.PEI_Id AND tfv4.Table_Field_Id = @tfSafetyStockId
LEFT JOIN dbo.Table_Fields_Values tfv5	WITH(NOLOCK)	ON tfv5.KeyId= pei.PEI_Id AND tfv5.Table_Field_Id = @tfAutoOrderProdMaterialByOGId
LEFT JOIN dbo.Table_Fields_Values tfv7	WITH(NOLOCK)	ON tfv7.KeyId= pei.PEI_Id AND tfv7.Table_Field_Id = @tfUseRMScrapFactorId
--LEFT JOIN dbo.Table_Fields_Values tfv8	WITH(NOLOCK)	ON tfv8.KeyId= pei.PEI_Id AND tfv8.Table_Field_Id = @tfRMScrapFactorId
--LEFT JOIN dbo.Table_Fields_Values tfv12	WITH(NOLOCK)	ON tfv12.KeyId= pei.PEI_Id AND tfv12.Table_Field_Id = @tfKanbanTypeId
WHERE pepu.Path_Id = @PathId ;


UPDATE t
SET RMScrapFactor =  COALESCE(CONVERT(FLOAT,tfv.value),0)		--RMScrapFactor
FROM @PRDExecInputs t 
JOIN dbo.PrdExec_Inputs pei				WITH(NOLOCK)	ON pei.PU_Id = t.PEIID
LEFT JOIN dbo.Table_Fields_Values tfv	WITH(NOLOCK)	ON tfv.KeyId= pei.PEI_Id AND tfv.Table_Field_Id = @tfRMScrapFactorId  	AND tfv.tableid = @TableIdRMI ; --V1.8


UPDATE t
SET KanbanType =  COALESCE(CONVERT(INT,tfv.value),0)		--KanbanType
FROM @PRDExecInputs t 
JOIN dbo.PrdExec_Inputs pei				WITH(NOLOCK)	ON pei.PU_Id = t.PEIID
LEFT JOIN dbo.Table_Fields_Values tfv	WITH(NOLOCK)	ON tfv.KeyId= pei.PEI_Id AND tfv.Table_Field_Id = @tfKanbanTypeId  	AND tfv.tableid = @TableIdRMI ; --V1.8


--Remove Any RMI for an OG that is not in the BOM
DELETE @PRDExecInputs 
WHERE OG <> @OG;

SELECT	@AutoOrderByOg		= COALESCE(AutoorderingByOG,0),
		@UseRMScrapFactor	= COALESCE(UseRMScrapFactor,0),
		@RMScrapFactor		= COALESCE(RMScrapFactor,0),
		@IsOrdering			= COALESCE(IsOrdering,0),
		@SafetyStock		= COALESCE(IsSafetyStock,0),
		@KanbanType			= COALESCE(KanbanType,1),
		@PEWMSSystem		= COALESCE(PEWMSSystem, ''),
		@ProductionPuID		= PUID
FROM @PRDExecInputs
WHERE OG = @OG;


IF @AutoOrderByOg = 0 or @IsOrdering = 0
BEGIN
	IF @DebugflagOnLine = 1 
	BEGIN
		INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
		VALUES(	GETDATE(), 
				@SPName,
				'0025' +
				' TimeStamp=' + convert(VARCHAR(25), GETDATE(), 120) +
				' Ordering or AutoOrdering is OFF for this OG',
				@pathid
				)
	END;

	GOTO	ErrCode;
END;


IF UPPER(@PEWMSSystem) <> 'PRIME'
BEGIN
	IF @DebugflagOnLine = 1 
	BEGIN
		INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
		VALUES(	GETDATE(), 
				@SPName,
				'0035' +
				' TimeStamp=' + convert(VARCHAR(25), GETDATE(), 120) +
				' This OG is not configured as Prime: ' + @og,
				@pathid
				);
	END;

	GOTO	ErrCode;
END;
-------------------------------------------------------------------------------
-- Retrieve the Active Process Order Info
-------------------------------------------------------------------------------

SET		@ActPPId = NULL;
SET		@PPStartTime = NULL;
																							
SELECT	@ActPPId =  pp_id,
		@PPStartTime = start_time
FROM dbo.production_plan_starts 
WHERE pu_id = @ProductionPuID 
	AND end_time IS NULL;

SELECT	@ActPPProcessOrder		= pp.Process_Order,
		@ActBOMFormId			= pp.BOM_Formulation_Id,
		@ActPPLineCounterQty	= COALESCE(pp.Actual_Good_Quantity,0),
		@ActPPPlannedStartTime	= pp.actual_start_time	
FROM dbo.Production_Plan pp					WITH(NOLOCK)
JOIN dbo.Products_base p					WITH(NOLOCK) ON (pp.Prod_Id = p.Prod_Id)
JOIN dbo.Production_Plan_Statuses pps		WITH(NOLOCK) ON (pps.PP_Status_Id = pp.PP_Status_Id)
WHERE pp_id = @ActPPId;



IF @DebugflagOnLine = 1 
BEGIN
	INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
	VALUES(	GETDATE(), 
			@SPName,
			'0100' +
			' ActPPProcessOrder =' + COALESCE(@ActPPProcessOrder, '') +
			' @ActPPId =' + CONVERT(VARCHAR(25), COALESCE(@actPPID,0)),
			@pathid
			);
END;


--If there is an active order, get the BOM of this Active PO
IF @ActPPId IS NOT NULL
BEGIN


	INSERT INTO @tblBOMRMListActive (
				PPId,
				ProcessOrder,
				PPStatusStr,
				BOMRMProdId,
				BOMRMProdCode,
				BOMRMQty,
				BOMRMScrapFactor,
				BOMRMFormItemId,
				BOMRMOG,
				BOMRMStoragePUId,
				BOMRMStoragePUDesc,
				BOMRMProdIdSub,
				BOMRMProdCodeSub	)
	SELECT	@ActPPId,
			@ActPPProcessOrder,
			@StatusStrActive,
			bomfi.Prod_Id, 
			p.Prod_Code, 
			bomfi.Quantity,
			bomfi.Scrap_Factor,
			bomfi.BOM_Formulation_Item_Id,
			NULL, 			
			pu.PU_Id,
			pu.PU_Desc,
			bomfs.Prod_Id,
			p_sub.Prod_Code
	FROM	dbo.Bill_Of_Material_Formulation_Item bomfi		WITH(NOLOCK)
	JOIN dbo.Bill_Of_Material_Formulation bomf				WITH(NOLOCK) ON (bomf.BOM_Formulation_Id = bomfi.BOM_Formulation_Id)
	JOIN dbo.Products_base p								WITH(NOLOCK) ON (p.Prod_Id = bomfi.Prod_Id) 
	LEFT JOIN dbo.Bill_Of_Material_Substitution bomfs		WITH(NOLOCK) ON (bomfs.BOM_Formulation_Item_Id = bomfi.BOM_Formulation_Item_Id)
	LEFT JOIN dbo.Products_base p_sub						WITH(NOLOCK) ON (p_sub.Prod_Id = bomfs.Prod_Id) 
	LEFT JOIN dbo.Prod_Units_base pu						WITH(NOLOCK) ON (bomfi.PU_Id = pu.PU_Id)
	WHERE	bomf.BOM_Formulation_Id = @ActBOMFormId;



	------------------------------------------------------------------------------
	--  GET OG, UOM, UOM per pallet for all BOM items
	------------------------------------------------------------------------------
	UPDATE b
	SET BOMRMOG = CONVERT(VARCHAR(50),pmdmc2.value),
		BOMRMEngUnitDesc = CONVERT(VARCHAR(50),pmdmc.value),
		productUOMperPallet = CONVERT(VARCHAR(50),pmdmc3.value)
	FROM @tblBOMRMListActive b
	JOIN	dbo.Products_Aspect_MaterialDefinition a				WITH(NOLOCK)	ON b.BOMRMProdId = a.prod_id
	JOIN	dbo.Property_MaterialDefinition_MaterialClass pmdmc		WITH(NOLOCK)	ON pmdmc.MaterialDefinitionId = a.Origin1MaterialDefinitionId
																						AND pmdmc.Name = @pnUOM
	JOIN	dbo.Property_MaterialDefinition_MaterialClass pmdmc2	WITH(NOLOCK)	ON pmdmc2.MaterialDefinitionId = a.Origin1MaterialDefinitionId
																						AND pmdmc2.Name = @pnOriginGroup
	JOIN	dbo.Property_MaterialDefinition_MaterialClass pmdmc3	WITH(NOLOCK)	ON pmdmc3.MaterialDefinitionId = a.Origin1MaterialDefinitionId
	
																						AND pmdmc3.Name = @pnUOMPerPallet
	DELETE @tblBOMRMListActive WHERE BOMRMOG <> @OG;


	UPDATE b
	SET ProductGroupCapacity = CONVERT(INT, pee.Value)
	FROM @tblBOMRMListActive b
	JOIN dbo.PAEquipment_Aspect_SOAEquipment a		WITH(NOLOCK) ON b.BOMRMStoragePUId = a.pu_id
	JOIN dbo.property_equipment_equipmentclass pee	WITH(NOLOCK) ON a.Origin1EquipmentId = pee.EquipmentId
																	AND pee.Name LIKE '%'+  b.BOMRMOG + '.' + @pnOriginGroupCapacity;
	

	--LOOP INTo all matching items.  Probably only one
	SET @BOMRMFormItemId = (SELECT MIN(BOMRMFormItemId) FROM @tblBOMRMListActive);
	WHILE @BOMRMFormItemId IS NOT NULL
	BEGIN
		/*
		Still needed = TPQ - TC​Q
			TPQ = Total Planned Quantity = Process order planned quantity (component) + SAP AND / or Proficy scrap factor​
			TCQ = Total Consumed Quantity (UL’s with status “Checked in”, “running”, “consumed”, ‘overconsumed”)​
		IF “Still needed” > 1 THAN​
		Order quantity (Cases) = Capacity – On Route​
			On Route = Inventory (UL’s with status “Delivered”) + Open requests ​
		Order quantity (cases) =< Still needed​
		IF “Still needed” = 0 THAN look at Initiate order​
		*/

		-------------------------------------
		--Set the total planned Qty (TPQ)
		-------------------------------------
		SELECT	@TPQ				= NULL,
				@BomQty				= NULL,
				@TCQ				= NULL,
				@BOMRMScrapFactor	= NULL,
				@ProdIdSub			= NULL,
				@Capacity			= NULL,
				@UOMperPallet		= NULL,
				@ProdCode			= NULL,
				@ProdCodeSub		= NULL;

		SELECT	@TPQ				= BOMRMQty,
				@BomQty				= BOMRMQty,
				@BOMRMScrapFactor	= BOMRMScrapFactor,
				@SourcePuID			= BOMRMStoragePUId,
				@ProdId				= BOMRMProdId,
				@ProdIdSub			= BOMRMProdIdSub,
				@Capacity			= ProductGroupCapacity,
				@UOMperPallet		= productUOMperPallet,
				@ProdCode			= BOMRMProdCode,
				@ProdCodeSub		= BOMRMProdCodeSub
		FROM @tblBOMRMListActive
		WHERE BOMRMFormItemId = @BOMRMFormItemId;

		--V1.6---
		SET @ProdCodeActive = @ProdCode;
		-------


		IF @DebugflagOnLine = 1 
		BEGIN
			INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
			VALUES(	GETDATE(), 
					@SPName,
					'0150' +
					' @ProdCode =' + COALESCE(@ProdCode, '') +
					' @BomQty =' + CONVERT(VARCHAR(25), COALESCE(@BomQty,0)) +
					' @SourcePuID =' + CONVERT(VARCHAR(25), COALESCE(@SourcePuID,0)) +
					' @Capacity =' + CONVERT(VARCHAR(25), COALESCE(@Capacity,0)) +
					' @TPQ =' + CONVERT(VARCHAR(25), COALESCE(@TPQ,0)),
					@pathid
					);
		END;


		IF @UsePathScrapFactor = 1 AND @BOMRMScrapFactor != 0 AND @BOMRMScrapFactor IS NOT NULL
		BEGIN
			SELECT	@TPQ = @BomQty * (1+@BOMRMScrapFactor/100);
		END;

		IF @UseRMScrapFactor = 1 AND @RMScrapFactor != 0 AND @RMScrapFactor IS NOT NULL
		BEGIN
				SELECT	@TPQ = @TPQ + (@BomQty * (@RMScrapFactor/100));
		END;

		

		--------------------------------
		--Find the TCQ
		--------------------------------
		--Count the Consumed AND Overconsumed based on the genealogy (to cover the case where carried over split a pallets INTo 2 PO)
		INSERT @ParentEvents (
			SourceEventId	,
			RMEventId		,
			RMEventStatus	,
			Qty		)
		SELECT ep.event_id, es.event_id, es.event_status, ec.Dimension_x
		FROM dbo.events ep				WITH(NOLOCK)
		JOIN dbo.event_details ed		WITH(NOLOCK)	ON ep.event_id = ed.event_id
		JOIN dbo.event_components ec	WITH(NOLOCK)	ON ep.event_id = ec.event_id
		JOIN dbo.events es				WITH(NOLOCK)	ON ec.source_event_id = es.event_id
		WHERE ed.pp_id = @actPPID
			AND ep.pu_id = @ProductionPuID
			AND es.applied_product IN (@ProdId,@ProdIdSub);

		SET @TCQ = (SELECT SUM(Qty) FROM @ParentEvents WHERE RMEventStatus IN (@consumedStatusId,@OverconsumedStatusId));
		IF @TCQ IS NULL
			SET @TCQ = 0;



		--Count the running AND checked In based on the pp_id attached on the pallet
		SET @TCQ = @TCQ + (	SELECT COALESCE(SUM(ed.initial_dimension_x),0) 
							FROM dbo.events e			WITH(NOLOCK)
							JOIN dbo.event_details ed	WITH(NOLOCK) ON e.event_id = ed.event_id
							WHERE e.pu_id = @SourcePuID
								AND ed.pp_id = @actPPID
								AND e.event_status IN (@RunningStatusId, @CheckedInStatusId)
								AND e.applied_product IN (@ProdId,@ProdIdSub)
							);


		--------------------------------
		--Find the Still needed
		--------------------------------
		SET @StillNeededQty = @TPQ - @TCQ;
		IF @StillNeededQty IS NULL OR @StillNeededQty < 0 
			SET @StillNeededQty = 0;

		SET @StillNeededCnt = (SELECT CEILING(@StillNeededQty/@UOMperPallet));



		IF @DebugflagOnLine = 1 
		BEGIN
			INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
			VALUES(	GETDATE(), 
					@SPName,
					'0160' +
					' @TPQ =' + CONVERT(VARCHAR(25), COALESCE(@TPQ,-1)) +
					' @TCQ =' + CONVERT(VARCHAR(25), COALESCE(@TCQ,-1)) +
					' @StillNeededCnt =' + CONVERT(VARCHAR(25), COALESCE(@StillNeededCnt,-1)) ,
					@pathid
					);
		END;

		--------------------------------
		--Find the OnRoute
		--------------------------------
		SET @DeliveredCnt = (	SELECT COUNT(e.event_id) 
					FROM dbo.events e			WITH(NOLOCK)
					JOIN dbo.event_Details ed	WITH(NOLOCK) ON e.event_id = ed.event_id
					WHERE e.pu_id = @SourcePuID
						AND ed.pp_id = @actPPID
						AND e.event_status IN (@DeliveredStatusId)
						AND e.applied_product IN (@ProdId,@ProdIdSub)
					);

		INSERT @Openrequest (OpenTableId,RequestId,PrimeReturnCode,RequestTime,LocationId,CurrentLocation,ULID,Batch,ProcessOrder,PrimaryGCAS,AlternateGCAS,GCAS,QuantityValue,QuantityUOM,Status,EstimatedDelivery,
							lastUpdatedTime	,userId, eventid	)
		EXEC dbo.spLocal_CmnPrIMEGetOpenRequests @pathCode,NULL,NULL;

		SET @Requestcnt = (SELECT COUNT(RequestId) FROM @Openrequest WHERE PrimaryGCAS = @ProdCode)
		SET @OnRouteCnt = @DeliveredCnt + @Requestcnt;



		IF @DebugflagOnLine = 1 
		BEGIN
			INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
			VALUES(	GETDATE(), 
					@SPName,
					'0180' +
					' @DeliveredCnt =' + CONVERT(VARCHAR(25), COALESCE(@DeliveredCnt,-1)) +
					' @Requestcnt =' + CONVERT(VARCHAR(25), COALESCE(@Requestcnt,-1)) +
					' @OnRouteCnt =' + CONVERT(VARCHAR(25), COALESCE(@OnRouteCnt,-1)) ,
					@pathid
					);
		END;
		--------------------------------
		--Calculate to order qty
		--------------------------------
		SET @ToOrderCnt = 0;

		SET @StillNeededCnt = @StillNeededCnt - @OnRouteCnt ; --v1.2

		IF @StillNeededCnt > 0 
		BEGIN
			SET @ToOrderCnt = @capacity - @OnRouteCnt;
			IF @ToOrderCnt < 0 
				SET @ToOrderCnt = 0;

			IF @ToOrderCnt > @StillNeededCnt
				SET @ToOrderCnt = @StillNeededCnt;
		END;


		--If this is the end of the PO, all material is there on on route, the remaining capacity can be moved to the next order
		IF @capacity - (@OnRouteCnt + @ToOrderCnt) > 0 AND (@OnRouteCnt + @ToOrderCnt) >= @StillNeededCnt
		BEGIN
			SET @capacityMovedToNext = 1;
			SET @capacityNext = @capacity - (@OnRouteCnt + @ToOrderCnt);
		END
		

		IF @DebugflagOnLine = 1 
		BEGIN
			INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
			VALUES(	GETDATE(), 
					@SPName,
					'0190' +
					' @ToOrderCnt =' + CONVERT(VARCHAR(25), COALESCE(@ToOrderCnt,-1)) +
					' @capacityMovedToNext =' + CONVERT(VARCHAR(25), COALESCE(@capacityMovedToNext,-1)) +
					' @capacityNext =' + CONVERT(VARCHAR(25), COALESCE(@capacityNext,-1)) ,
					@pathid
					);
		END;


		--------------------------------
		--Order Material
		--------------------------------
		IF @ToOrderCnt>0
		BEGIN

			SELECT @PrIMELocation = CONVERT(VARCHAR(50), pee.Value)
			FROM dbo.PAEquipment_Aspect_SOAEquipment a		
			JOIN dbo.property_equipment_equipmentclass pee	WITH(NOLOCK) ON a.Origin1EquipmentId = pee.EquipmentId
			WHERE a.pu_id = @SourcePuid	
				AND pee.Class = @cnOrderMaterials
				AND pee.Name = @pnPrIMELocation ;

			SET @Row = 0;
			WHILE @Row < @ToOrderCnt
			BEGIN
				INSERT INTO @CatchGarbage (garbage)
				EXEC spLocal_CmnPrIMECreateOpenRequest	@PrimeLocation,@ActPPProcessOrder,@ProdCode,@ProdCodeSub,1,NULL,@defaultUserName;

				SELECT @ThisTime = GETDATE();
				INSERT INTO @CatchGarbage (garbage)
				EXEC spLocal_InsertTblMaterialRequest	'Request', @ActPPProcessOrder, @ProdCode,	@PrimeLocation,  @ThisTime,	1,@DefaultUserId,'PRODUCTION', 'Auto','Success','';

				SET @Row = @Row + 1;
			END;
		END;
	

		SET @BOMRMFormItemId = (SELECT MIN(BOMRMFormItemId) FROM @tblBOMRMListActive WHERE BOMRMFormItemId > @BOMRMFormItemId);
	END;
END;


IF @ActPPID IS NULL OR @capacityMovedToNext = 1
BEGIN
	--  Verify if we need to order for the NEXT order
	--1) Check for an active order not started yet on this path
	IF @ActPPID IS NULL
		SET @ActPPID = 0;
	SET @ActPPIDNext = (SELECT pp_id FROM dbo.production_plan WITH(NOLOCK) WHERE path_id = @pathId AND pp_status_id = 3 AND pp_id <> @ActPPID);
	IF @ActPPIDNext IS NOT NULL
	BEGIN
		--Insure it has never been run on the current unit
		IF NOT EXISTS(	SELECT pp_id 
						FROM dbo.production_plan_starts WITH(NOLOCK) 
						WHERE pu_id =  @ProductionPuID 
							AND pp_id = @ActPPIDNext)
		BEGIN
			--There is an active PO that is coming to the productrion unit soon
			SET @NxtPPID = @ActPPIDNext;

			IF @DebugflagOnLine = 1 
			BEGIN
				INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
				VALUES(	GETDATE(), 
						@SPName,
						'0210' +
						' SCO Line.  NEXT PPID come from an active order: ' + CONVERT(VARCHAR(25), COALESCE(@NxtPPID,-1)) ,
						@pathid
						);
			END;
		END;
	END;

	--2) Look at the ready PO
	IF @NxtPPID IS NULL
	BEGIN
		SET @NxtPPID = (SELECT pp_id 
						FROM dbo.production_plan pp				WITH(NOLOCK) 
						JOIN dbo.production_plan_statuses pps	WITH(NOLOCK) ON pp.pp_status_id = pps.pp_status_id
						WHERE pp.path_id = @pathId AND pps.pp_status_Desc = @StatusStrReady);

		IF @DebugflagOnLine = 1 
		BEGIN
			INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
			VALUES(	GETDATE(), 
					@SPName,
					'0220' +
					' NEXT PPID come from a Ready order: ' + CONVERT(VARCHAR(25), COALESCE(@NxtPPID,-1)) ,
					@pathid
					);
		END;

	END;

	--3) Look at the initiate PO
	IF @NxtPPID IS NULL
	BEGIN
		SET @NxtPPID = (SELECT pp_id 
						FROM dbo.production_plan pp				WITH(NOLOCK) 
						JOIN dbo.production_plan_statuses pps	WITH(NOLOCK) ON pp.pp_status_id = pps.pp_status_id
						WHERE pp.path_id = @pathId AND pps.pp_status_Desc = @StatusStrInitiate);

		IF @DebugflagOnLine = 1 
		BEGIN
			INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
			VALUES(	GETDATE(), 
					@SPName,
					'0230' +
					' NEXT PPID come from an Initiate order: ' + CONVERT(VARCHAR(25), COALESCE(@NxtPPID,-1)) ,
					@pathid
					);
		END;
	END;


	IF @NxtPPID IS NOT NULL
	BEGIN
		SELECT	@NxtPPProcessOrder		= pp.Process_Order,
				@NxtBOMFormId			= pp.BOM_Formulation_Id
		FROM dbo.Production_Plan pp					WITH(NOLOCK)
		WHERE pp_id = @NxtPPId;

		IF @DebugflagOnLine = 1 
		BEGIN
			INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
			VALUES(	GETDATE(), 
					@SPName,
					'0240' +
					' nxtPPProcessOrder =' + COALESCE(@NxtPPProcessOrder, '') +
					' NxtPPID =' + CONVERT(VARCHAR(25), COALESCE(@NxtPPID,0)),
					@pathid
					);
		END;

		--Get the Next BOM
		INSERT INTO @tblBOMRMListNext (
					PPId,
					ProcessOrder,
					PPStatusStr,
					BOMRMProdId,
					BOMRMProdCode,
					BOMRMQty,
					BOMRMScrapFactor,
					BOMRMFormItemId,
					BOMRMOG,
					BOMRMStoragePUId,
					BOMRMStoragePUDesc,
					BOMRMProdIdSub,
					BOMRMProdCodeSub	)
		SELECT	@NxtPPId,
				@NxtPPProcessOrder,
				NULL,
				bomfi.Prod_Id, 
				p.Prod_Code, 
				bomfi.Quantity,
				bomfi.Scrap_Factor,
				bomfi.BOM_Formulation_Item_Id,
				NULL, 			
				pu.PU_Id,
				pu.PU_Desc,
				bomfs.Prod_Id,
				p_sub.Prod_Code
		FROM	dbo.Bill_Of_Material_Formulation_Item bomfi		WITH(NOLOCK)
		JOIN dbo.Bill_Of_Material_Formulation bomf				WITH(NOLOCK) ON (bomf.BOM_Formulation_Id = bomfi.BOM_Formulation_Id)
		JOIN dbo.Products_base p								WITH(NOLOCK) ON (p.Prod_Id = bomfi.Prod_Id) 
		LEFT JOIN dbo.Bill_Of_Material_Substitution bomfs		WITH(NOLOCK) ON (bomfs.BOM_Formulation_Item_Id = bomfi.BOM_Formulation_Item_Id)
		LEFT JOIN dbo.Products_base p_sub						WITH(NOLOCK) ON (p_sub.Prod_Id = bomfs.Prod_Id) 
		LEFT JOIN dbo.Prod_Units_base pu						WITH(NOLOCK) ON (bomfi.PU_Id = pu.PU_Id)
		WHERE	bomf.BOM_Formulation_Id = @NxtBOMFormId;



		------------------------------------------------------------------------------
		--  GET OG, UOM, UOM per pallet for all BOM items
		------------------------------------------------------------------------------
		UPDATE b
		SET BOMRMOG = CONVERT(VARCHAR(50),pmdmc2.value),
			BOMRMEngUnitDesc = CONVERT(VARCHAR(50),pmdmc.value),
			productUOMperPallet = CONVERT(VARCHAR(50),pmdmc3.value)
		FROM @tblBOMRMListNext b
		JOIN	dbo.Products_Aspect_MaterialDefinition a				WITH(NOLOCK)	ON b.BOMRMProdId = a.prod_id
		JOIN	dbo.Property_MaterialDefinition_MaterialClass pmdmc		WITH(NOLOCK)	ON pmdmc.MaterialDefinitionId = a.Origin1MaterialDefinitionId
																							AND pmdmc.Name = @pnUOM
		JOIN	dbo.Property_MaterialDefinition_MaterialClass pmdmc2	WITH(NOLOCK)	ON pmdmc2.MaterialDefinitionId = a.Origin1MaterialDefinitionId
																							AND pmdmc2.Name = @pnOriginGroup
		JOIN	dbo.Property_MaterialDefinition_MaterialClass pmdmc3	WITH(NOLOCK)	ON pmdmc3.MaterialDefinitionId = a.Origin1MaterialDefinitionId
	
																							AND pmdmc3.Name = @pnUOMPerPallet;
		DELETE @tblBOMRMListNext WHERE BOMRMOG <> @OG;


		UPDATE b
		SET ProductGroupCapacity = CONVERT(INT, pee.Value)
		FROM @tblBOMRMListNext b
		JOIN dbo.PAEquipment_Aspect_SOAEquipment a		WITH(NOLOCK) ON b.BOMRMStoragePUId = a.pu_id
		JOIN dbo.property_equipment_equipmentclass pee	WITH(NOLOCK) ON a.Origin1EquipmentId = pee.EquipmentId
																		AND pee.Name LIKE '%'+  b.BOMRMOG + '.' + @pnOriginGroupCapacity;
		
		IF @capacityMovedToNext = 1
		BEGIN
			--Set capacity to the remaining qty...
			UPDATE @tblBOMRMListNext 
			SET ProductGroupCapacity = @capacityNext;
		END;

		
		--LOOP INTo all matching items.  Probably only one
		SET @BOMRMFormItemId = (SELECT MIN(BOMRMFormItemId) FROM @tblBOMRMListNext);
		WHILE @BOMRMFormItemId IS NOT NULL
		BEGIN
			/*
			Still needed = TPQ - TC​
				TPQ = Total Planned Quantity = Process order planned quantity (component) + SAP AND / or Proficy scrap factor​
				TCQ = Total Consumed Quantity (UL’s with status “Checked in”, “running”, “consumed”, ‘overconsumed”)​
			IF “Still needed” > 1 THAN​
			Order quantity (Cases) = Capacity – On Route​
				On Route = Inventory (UL’s with status “Delivered”) + Open requests ​
			Order quantity (cases) =< Still needed​
			IF “Still needed” = 0 THAN look at Initiate order​
			*/

			-------------------------------------
			--Set the total planned Qty (TPQ)
			-------------------------------------
			SELECT	@TPQ				= NULL,
					@BomQty				= NULL,
					@TCQ				= NULL,
					@BOMRMScrapFactor	= NULL,
					@ProdIdSub			= NULL,
					@Capacity			= NULL,
					@UOMperPallet		= NULL,
					@ProdCode			= NULL,
					@ProdCodeSub		= NULL;

			SELECT	@TPQ				= BOMRMQty,
					@BomQty				= BOMRMQty,
					@BOMRMScrapFactor	= BOMRMScrapFactor,
					@SourcePuID			= BOMRMStoragePUId,
					@ProdId				= BOMRMProdId,
					@ProdIdSub			= BOMRMProdIdSub,
					@Capacity			= ProductGroupCapacity,
					@UOMperPallet		= productUOMperPallet,
					@ProdCode			= BOMRMProdCode,
					@ProdCodeSub		= BOMRMProdCodeSub
			FROM @tblBOMRMListNext
			WHERE BOMRMFormItemId = @BOMRMFormItemId;

			IF @DebugflagOnLine = 1 
			BEGIN
				INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
				VALUES(	GETDATE(), 
						@SPName,
						'0250' +
						' @ProdCode =' + COALESCE(@ProdCode, '') +
						' @BomQty =' + CONVERT(VARCHAR(25), COALESCE(@BomQty,0)) +
						' @SourcePuID =' + CONVERT(VARCHAR(25), COALESCE(@SourcePuID,0)) +
						' @Capacity =' + CONVERT(VARCHAR(25), COALESCE(@Capacity,0)) +
						' @TPQ =' + CONVERT(VARCHAR(25), COALESCE(@TPQ,0)),
						@pathid
						);
			END;

			IF @UsePathScrapFactor = 1 AND @BOMRMScrapFactor != 0 AND @BOMRMScrapFactor IS NOT NULL
			BEGIN
				SELECT	@TPQ = @BomQty * (1+@BOMRMScrapFactor/100);
			END;

			IF @UseRMScrapFactor = 1 AND @RMScrapFactor != 0 AND @RMScrapFactor IS NOT NULL
			BEGIN
					SELECT	@TPQ = @TPQ + (@BomQty * (@RMScrapFactor/100));
			END;


			--------------------------------
			--Find the TCQ
			--------------------------------
			

			--Count the running AND checked In based on the pp_id attached on the pallet
			SET @TCQ = (	SELECT COALESCE(SUM(ed.initial_dimension_x),0) 
							FROM dbo.events e			WITH(NOLOCK)
							JOIN dbo.event_details ed	WITH(NOLOCK) ON e.event_id = ed.event_id
							WHERE e.pu_id = @SourcePuID
								AND ed.pp_id = @nxtPPID
								AND e.event_status IN (@RunningStatusId, @CheckedInStatusId)
								AND e.applied_product IN (@ProdId,@ProdIdSub)
								);


			--------------------------------
			--Find the Still needed
			--------------------------------
			SET @StillNeededQty = @TPQ - @TCQ;
			IF @StillNeededQty IS NULL OR @StillNeededQty < 0 
				SET @StillNeededQty = 0;

			SET @StillNeededCnt = (SELECT CEILING(@StillNeededQty/@UOMperPallet));


			IF @DebugflagOnLine = 1 
			BEGIN
				INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
				VALUES(	GETDATE(), 
						@SPName,
						'0270' +
						' @TPQ =' + CONVERT(VARCHAR(25), COALESCE(@TPQ,-1)) +
						' @TCQ =' + CONVERT(VARCHAR(25), COALESCE(@TCQ,-1)) +
						' @StillNeededCnt =' + CONVERT(VARCHAR(25), COALESCE(@StillNeededCnt,-1)) ,
						@pathid
						);
			END;


			--------------------------------
			--Find the OnRoute
			--------------------------------
			SET @DeliveredCnt = (	SELECT COUNT(e.event_id) 
						FROM dbo.events e			WITH(NOLOCK)
						JOIN dbo.event_Details ed	WITH(NOLOCK) ON e.event_id = ed.event_id
						WHERE e.pu_id = @SourcePuID
							AND ed.pp_id = @nxtPPID
							AND e.event_status IN (@DeliveredStatusId)
							AND e.applied_product IN (@ProdId,@ProdIdSub)
						);
			

			DELETE @Openrequest;  --1.5
			INSERT @Openrequest (OpenTableId,RequestId,PrimeReturnCode,RequestTime,LocationId,CurrentLocation,ULID,Batch,ProcessOrder,PrimaryGCAS,AlternateGCAS,GCAS,QuantityValue,QuantityUOM,Status,EstimatedDelivery,
								lastUpdatedTime	,userId, eventid	)
			EXEC dbo.spLocal_CmnPrIMEGetOpenRequests @pathCode,NULL,NULL;

			SET @Requestcnt = (SELECT COUNT(RequestId) FROM @Openrequest WHERE PrimaryGCAS = @ProdCode  /* v1.6 */ AND PrimaryGCAS <> @ProdCodeActive);
			SET @OnRouteCnt = @DeliveredCnt + @Requestcnt;

			IF @DebugflagOnLine = 1 
			BEGIN
				INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
				VALUES(	GETDATE(), 
						@SPName,
						'0280' +
						' @DeliveredCnt =' + CONVERT(VARCHAR(25), COALESCE(@DeliveredCnt,-1)) +
						' @Requestcnt =' + CONVERT(VARCHAR(25), COALESCE(@Requestcnt,-1)) +
						' @OnRouteCnt =' + CONVERT(VARCHAR(25), COALESCE(@OnRouteCnt,-1)) ,
						@pathid
						);
			END;

			--------------------------------
			--Calculate to order qty
			--------------------------------
			SET @ToOrderCnt = 0;

			SET @StillNeededCnt = @StillNeededCnt - @OnRouteCnt ; --v1.6

			IF @StillNeededCnt > 0 
			BEGIN
				SET @ToOrderCnt = @capacity - @OnRouteCnt;
				IF @ToOrderCnt < 0 
					SET @ToOrderCnt = 0;

				IF @ToOrderCnt > @StillNeededCnt
					SET @ToOrderCnt = @StillNeededCnt;
			END;

			IF @DebugflagOnLine = 1 
			BEGIN
				INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
				VALUES(	GETDATE(), 
						@SPName,
						'0290' +
						' @ToOrderCnt =' + CONVERT(VARCHAR(25), COALESCE(@ToOrderCnt,-1))  ,
						@pathid
						);
			END		;


			--------------------------------
			--Order Material
			--------------------------------
			IF @ToOrderCnt>0
			BEGIN

				SELECT @PrIMELocation = CONVERT(VARCHAR(50), pee.Value)
				FROM dbo.PAEquipment_Aspect_SOAEquipment a		
				JOIN dbo.property_equipment_equipmentclass pee	WITH(NOLOCK) ON a.Origin1EquipmentId = pee.EquipmentId
				WHERE a.pu_id = @SourcePuid	
					AND pee.Class = @cnOrderMaterials
					AND pee.Name = @pnPrIMELocation ;

				IF @DebugflagOnLine = 1 
				BEGIN
					INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
					VALUES(	GETDATE(), 
							@SPName,
							'0300' +
							' @PrIMELocation =' + COALESCE(@PrIMELocation,'WHERE'),
							@pathid
							);
				END		;

				SET @Row = 0;
				WHILE @Row < @ToOrderCnt
				BEGIN

					INSERT INTO @CatchGarbage (garbage)
					EXEC spLocal_CmnPrIMECreateOpenRequest	@PrimeLocation,@NxtPPProcessOrder,@ProdCode,@ProdCodeSub,1,NULL,@defaultUserName;



					SELECT @ThisTime = GETDATE();

					INSERT INTO @CatchGarbage (garbage)
					EXEC spLocal_InsertTblMaterialRequest	'Request', @NxtPPProcessOrder, @ProdCode,	@PrimeLocation,  @ThisTime,	1,@DefaultUserId,'Initiate', 'Auto','Success','';

					SET @Row = @Row + 1;
				END;
			END;

			--Loop next
			SET @BOMRMFormItemId = (SELECT MIN(BOMRMFormItemId) FROM @tblBOMRMListNext WHERE BOMRMFormItemId > @BOMRMFormItemId);
		END;
	END;
END;



ErrCode:

IF @DebugflagOnLine = 1  
BEGIN
	INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
		VALUES(	GETDATE(), 
				@SPName,
				'9999' +

				' Finished',
				@pathid
				);
END;


SET NOcount OFF;

RETURN
