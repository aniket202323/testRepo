--------------------------------------------------------------------------------------------------
-- Stored Procedure: spLocal_CmnPEKanbanOrdering
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

/*---------------------------------------------------------------------------------------------
Testing Code

-----------------------------------------------------------------------------------------------*/
--EXEC spLocal_CmnPEKanbanOrdering 150,'B160','Syatem.PE',1

--------------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[spLocal_CmnPEKanbanOrdering]
@PathId							int,
@OG								varchar(4),
@DefaultUserName				varchar(100),
@DebugflagOnLine				bit

--WITH ENCRYPTION
AS
SET NOCOUNT ON


DECLARE	
@DefaultUserId					int,
@SPName							varchar(50),


----Subscription UDPs
@UsePrIME						bit,
@WMSSubscriptionID				int,


--ProcessOrder
@ActPPId						int,
@ActPPProcessOrder				varchar(12),
@ActBOMFormId					int,
@ActPPLineCounterQty			float,
@ActPPPlannedStartTime			datetime,
@ActPPPlannedEndTime			datetime,	
@StatusStrActive				varchar(30),
@NxtPPId						int,
@NxtPPProcessOrder				varchar(12),
@NxtBOMFormId					int,
@NxtPPLineCounterQty			float,
@NxtPPPlannedStartTime			datetime,
@NxtPPPlannedEndTime			datetime,	
@StatusStrInitiate				varchar(30),
@StatusStrReady					varchar(30),

--SOA properties
@pnUOMPerPallet					varchar(30),
@pnOriginGroup					varchar(30),
@pnUOM							varchar(50),
@pnOriginGroupCapacity			varchar(50),

--BOM variables
@BOMRMFormItemId				int,
@TPQ							float,
@TCQ							float,
@BOMRMScrapFactor				float,


----UDPs
@TableIdPath					int,
@TableIdRMI						int,
@tfPEWMSSystemId				int,
@tfSafetyStockId				int,
@tfAutoOrderProdMaterialByOGId	int,
@tfIsOrderingId					int,
@tfUseRMScrapFactorId			int,
@tfRMScrapFactorId				int,
@tfOGId							int,
@udpUseScrapFactorId			int,
@UsePathScrapFactor				bit,
@IsSCOLineId					int,
@IsSCOLine						bit,
@tfKanbanTypeId					int,
@AutoOrderByOg					bit,
@UseRMScrapFactor				bit,
@RMScrapFactor					float,
@IsOrdering						bit,
@SafetyStock					bit,
@KanbanType						int,
@PEWMSSystem					varchar(30)

DECLARE @PRDExecInputs TABLE 
(
	PUID						int,
	PEIID						int,
	OG							varchar(50),
	PEWMSSystem					varchar(50),
	IsOrdering					bit,
	IsSafetyStock				bit DEFAULT 0,
	AutoorderingByOG			bit DEFAULT 0,
	UseRMScrapFactor			bit DEFAULT 0,
	RMScrapFactor				float DEFAULT 0,
	KanbanType					int DEFAULT 0
			)


DECLARE @tblBOMRMListNext TABLE
(	BOMRMId						int IDENTITY,
	PPId						int,
	ProcessOrder				varchar(50),
	PPStatusStr					varchar(25),
	BOMRMProdId					int,
	BOMRMProdCode				varchar(25),
	BOMRMQty					float,
	BOMRMEngUnitDesc			varchar(25),
	BOMRMScrapFactor			float,
	BOMRMFormItemId				int,
	BOMRMOG						varchar(25),
	ProductGroupCapacity		int,
	ProductUOMPerPallet			float,
	FlgUniqueToActiveOrder		bit,
	BOMRMStoragePUId			int,
	BOMRMStoragePUDesc			varchar(50),
	BOMRMProdIdSub				int,
	BOMRMProdCodeSub			varchar(25)
)

DECLARE @tblBOMRMListActive TABLE
(	BOMRMId						int IDENTITY,
	PPId						int,
	ProcessOrder				varchar(50),
	PPStatusStr					varchar(25),
	BOMRMProdId					int,
	BOMRMProdCode				varchar(25),
	BOMRMQty					float,
	BOMRMEngUnitDesc			varchar(25),
	BOMRMScrapFactor			float,
	BOMRMFormItemId				int,
	BOMRMOG						varchar(25),
	ProductGroupCapacity		int,
	ProductUOMPerPallet			float,
	FlgUniqueToActiveOrder		bit,
	BOMRMStoragePUId			int,
	BOMRMStoragePUDesc			varchar(50),
	BOMRMProdIdSub				int,
	BOMRMProdCodeSub			varchar(25)
)







-------------------------------------------------------------------------------
-- starts
-------------------------------------------------------------------------------
SELECT	@SPName	= 'spLocal_CmnPEKanbanOrdering'

IF @DebugflagOnLine = 1 
BEGIN
	INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
	VALUES(	getdate(), 
			@SPName,
			'0001' +
			' TimeStamp=' + convert(varchar(25), getdate(), 120) +
			' Stored proc started',
			@pathid
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
				@pathid
				)
	END

	GOTO	ErrCode
END
-------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------
--Verify if this server uses PrIME
-------------------------------------------------------------------------------------
SET @WMSSubscriptionID	= (SELECT Subscription_Id
							FROM dbo.Subscription
							WHERE Subscription_Desc = 'WMS')						
						
SET @UsePrIME			= (SELECT tfv.Value
								FROM dbo.Table_Fields_Values tfv	WITH(NOLOCK)
								JOIN dbo.Table_Fields tf			WITH(NOLOCK)	ON tf.Table_Field_Id = tfv.Table_Field_Id
								JOIN dbo.Tables t					WITH(NOLOCK)	ON t.TableId = tf.TableId
								WHERE t.TableName = 'Subscription'
									AND tf.Table_Field_Desc = 'Use_PrIME'
									AND tfv.KeyId = @WMSSubscriptionID				
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
				@pathid
				)
	END

	GOTO	ErrCode
END
-------------------------------------------------------------------------------------


-------------------------------------------------------------------------------
-- Initialize variables.
-------------------------------------------------------------------------------
--pp_status string
SELECT	@StatusStrActive				= 'Active',
		@StatusStrInitiate				= 'Initiate',
		@StatusStrReady					= 'Ready'


SELECT	@pnUOMPerPallet					= 'UOM Per Pallet',
		@pnOriginGroup					= 'Origin Group',
		@pnUOM							= 'UOM',
		@pnOriginGroupCapacity			= 'Origin Group Capacity'



-------------------------------------------------------------------------------------
--Read required path UDPs
-------------------------------------------------------------------------------------

SET @TableIdPath	= (SELECT TableID FROM dbo.Tables Where tableName = 'PRDExec_Paths')


SET @udpUseScrapFactorId	= (	SELECT Table_Field_Id 	FROM dbo.Table_Fields 			WITH(NOLOCK)	WHERE Table_Field_Desc = 'PE_PPA_UseBOMScrapfactor'	AND tableid = @TableIdPath)
SET @UsePathScrapFactor		= ( SELECT value			FROM dbo.Table_Fields_Values	WITH(NOLOCK)	WHERE Table_Field_Id = @udpUseScrapFactorId 		AND keyid = @pathId		AND tableid = @TableIdPath	 )	
SET @IsSCOLineId			= ( SELECT Table_Field_id	FROM dbo.Table_Fields			WITH(NOLOCK)	WHERE Table_Field_Desc  = 'PE_General_IsSCOLine'	AND TableID = @TableIdPath)
SET @IsSCOLine				= ( SELECT value			FROM dbo.Table_Fields_values	WITH(NOLOCK)	WHERE table_Field_ID = @IsSCOLineId AND KEYID  = @PathId) 
IF @IsSCOLine IS NULL
	SET @IsSCOLine = 0

SET @TableIdRMI						= (SELECT TableID FROM dbo.Tables Where tableName = 'PRDExec_inputs')
SET @tfPEWMSSystemId				= (	SELECT Table_Field_Id 	FROM dbo.Table_Fields 			WITH(NOLOCK)	WHERE Table_Field_Desc = 'PE_WMS_System'					AND tableid = @TableIdRMI)
SET @tfIsOrderingId					= (	SELECT Table_Field_Id 	FROM dbo.Table_Fields 			WITH(NOLOCK)	WHERE Table_Field_Desc = 'PE_WMS_IsOrdering'				AND tableid = @TableIdRMI)
SET @tfUseRMScrapFactorId			= (	SELECT Table_Field_Id 	FROM dbo.Table_Fields 			WITH(NOLOCK)	WHERE Table_Field_Desc = 'UseRMScrapFactor'					AND tableid = @TableIdRMI)
SET @tfRMScrapFactorId				= (	SELECT Table_Field_Id 	FROM dbo.Table_Fields 			WITH(NOLOCK)	WHERE Table_Field_Desc = 'RMScrapFactor'					AND tableid = @TableIdRMI)
SET @tfOGId							= (	SELECT Table_Field_Id 	FROM dbo.Table_Fields 			WITH(NOLOCK)	WHERE Table_Field_Desc = 'Origin Group'						AND tableid = @TableIdRMI)
SET @tfSafetyStockId				= (	SELECT Table_Field_Id 	FROM dbo.Table_Fields 			WITH(NOLOCK)	WHERE Table_Field_Desc = 'SafetyStock'						AND tableid = @TableIdRMI)
SET @tfAutoOrderProdMaterialByOGId	= (	SELECT Table_Field_Id 	FROM dbo.Table_Fields 			WITH(NOLOCK)	WHERE Table_Field_Desc = 'AutoOrderProductionMaterialByOG'	AND tableid = @TableIdRMI)
SET @tfKanbanTypeId					= (	SELECT Table_Field_Id 	FROM dbo.Table_Fields 			WITH(NOLOCK)	WHERE Table_Field_Desc = 'KanbanOrderingType'				AND tableid = @TableIdRMI)



--Get All RMIs
INSERT @PRDExecInputs (
						PUID,
						PEIID,
						OG,
						PEWMSSystem,
						IsOrdering,
						IsSafetyStock,
						AutoorderingByOG,
						UseRMScrapFactor,
						RMScrapFactor,
						KanbanType
						)
SELECT	pepu.PU_Id, 
		pei.PEI_Id, 
		tfv.Value,									--OG
		tfv2.value,									--PEWMSSystem
		CONVERT(bit,tfv3.value),					--IsOrdering		
		COALESCE(CONVERT(bit,tfv4.value),0),		--IsSafetyStock
		COALESCE(CONVERT(bit,tfv5.value),0),		--AutoorderingByOG
		COALESCE(CONVERT(float,tfv7.value),0),		--UseRMScrapFactor
		COALESCE(CONVERT(float,tfv8.value),0),		--RMScrapFactor
		COALESCE(CONVERT(int,tfv12.value),0)
FROM dbo.PrdExec_Path_Units pepu		WITH(NOLOCK)
JOIN dbo.PrdExec_Inputs pei				WITH(NOLOCK)	ON pei.PU_Id = pepu.PU_Id
JOIN dbo.Table_Fields_Values tfv		WITH(NOLOCK)	ON tfv.KeyId = pei.PEI_Id AND tfv.Table_Field_Id  = @tfOGId
JOIN dbo.Table_Fields_Values tfv2		WITH(NOLOCK)	ON tfv2.KeyId= pei.PEI_Id AND tfv2.Table_Field_Id = @tfPEWMSSystemId
LEFT JOIN dbo.Table_Fields_Values tfv3	WITH(NOLOCK)	ON tfv3.KeyId= pei.PEI_Id AND tfv3.Table_Field_Id = @tfIsOrderingId
LEFT JOIN dbo.Table_Fields_Values tfv4	WITH(NOLOCK)	ON tfv4.KeyId= pei.PEI_Id AND tfv4.Table_Field_Id = @tfSafetyStockId
LEFT JOIN dbo.Table_Fields_Values tfv5	WITH(NOLOCK)	ON tfv5.KeyId= pei.PEI_Id AND tfv5.Table_Field_Id = @tfAutoOrderProdMaterialByOGId
LEFT JOIN dbo.Table_Fields_Values tfv7	WITH(NOLOCK)	ON tfv7.KeyId= pei.PEI_Id AND tfv7.Table_Field_Id = @tfUseRMScrapFactorId
LEFT JOIN dbo.Table_Fields_Values tfv8	WITH(NOLOCK)	ON tfv8.KeyId= pei.PEI_Id AND tfv8.Table_Field_Id = @tfRMScrapFactorId
LEFT JOIN dbo.Table_Fields_Values tfv12	WITH(NOLOCK)	ON tfv12.KeyId= pei.PEI_Id AND tfv12.Table_Field_Id = @tfKanbanTypeId
WHERE pepu.Path_Id = @PathId 



--Remove Any RMI for an OG that is not in the BOM
DELETE @PRDExecInputs 
WHERE OG <> @OG


SELECT	@AutoOrderByOg		= COALESCE(AutoorderingByOG,0),
		@UseRMScrapFactor	= COALESCE(UseRMScrapFactor,0),
		@RMScrapFactor		= COALESCE(RMScrapFactor,0),
		@IsOrdering			= COALESCE(IsOrdering,0),
		@SafetyStock		= COALESCE(IsSafetyStock,0),
		@KanbanType			= COALESCE(KanbanType,1),
		@PEWMSSystem		= COALESCE(PEWMSSystem, '')
FROM @PRDExecInputs
WHERE OG = @OG


IF @AutoOrderByOg = 0 or @IsOrdering = 0
BEGIN
	IF @DebugflagOnLine = 1 
	BEGIN
		INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
		VALUES(	getdate(), 
				@SPName,
				'0025' +
				' TimeStamp=' + convert(varchar(25), getdate(), 120) +
				' Ordering or AutoOrdering is OFF for this OG',
				@pathid
				)
	END

	GOTO	ErrCode
END


--Delete all OG which are not autoOrderproductionbyOG = false 
--DELETE @tblBOMRMListComplete WHERE BOMRMOG IN (SELECT OG FROM @PRDExecInputs WHERE AutoorderingByOG =0)

----Delete all OG which WMS is not PrIME
--DELETE @tblBOMRMListComplete WHERE BOMRMOG NOT IN (SELECT OG FROM @PRDExecInputs WHERE PEWMSSystem = 'PrIME')

----Delete all OG which are notis_ordering= false 
--DELETE @tblBOMRMListComplete WHERE BOMRMOG IN (SELECT OG FROM @PRDExecInputs WHERE IsOrdering =0)

----Delete all OG where MCT for PLC ordering is true
--DELETE @tblBOMRMListComplete WHERE BOMRMOG IN (SELECT OG FROM @PRDExecInputs WHERE MCTforPLCOrdering =1)



-------------------------------------------------------------------------------
-- Retrieve the Active Process Order Info
-------------------------------------------------------------------------------
																							
SET		@ActPPId = NULL
SELECT	TOP 1
		@ActPPId				= pp.PP_Id,
		@ActPPProcessOrder		= pp.Process_Order,
		@ActBOMFormId			= pp.BOM_Formulation_Id,
		@ActPPLineCounterQty	= COALESCE(pp.Actual_Good_Quantity,0),
		@ActPPPlannedStartTime	= pp.forecast_start_date,
		@ActPPPlannedEndTime	= pp.forecast_end_date	
FROM dbo.Production_Plan pp					WITH(NOLOCK)
JOIN dbo.Products_base p					WITH(NOLOCK) ON (pp.Prod_Id = p.Prod_Id)
JOIN dbo.Production_Plan_Statuses pps		WITH(NOLOCK) ON (pps.PP_Status_Id = pp.PP_Status_Id)
WHERE pps.PP_Status_Desc = @StatusStrActive
	AND Path_Id = @PathId
ORDER BY pp.Actual_start_time DESC





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
		WHERE	bomf.BOM_Formulation_Id = @ActBOMFormId



	------------------------------------------------------------------------------
	--  GET OG, UOM, UOM per pallet for all BOM items
	------------------------------------------------------------------------------
	UPDATE b
	SET BOMRMOG = CONVERT(varchar(50),pmdmc2.value),
		BOMRMEngUnitDesc = CONVERT(varchar(50),pmdmc.value),
		productUOMperPallet = CONVERT(varchar(50),pmdmc3.value)
	FROM @tblBOMRMListActive b
	JOIN	dbo.Products_Aspect_MaterialDefinition a				WITH(NOLOCK)	ON b.BOMRMProdId = a.prod_id
	JOIN	dbo.Property_MaterialDefinition_MaterialClass pmdmc		WITH(NOLOCK)	ON pmdmc.MaterialDefinitionId = a.Origin1MaterialDefinitionId
																						AND pmdmc.Name = @pnUOM
	JOIN	dbo.Property_MaterialDefinition_MaterialClass pmdmc2	WITH(NOLOCK)	ON pmdmc2.MaterialDefinitionId = a.Origin1MaterialDefinitionId
																						AND pmdmc2.Name = @pnOriginGroup
	JOIN	dbo.Property_MaterialDefinition_MaterialClass pmdmc3	WITH(NOLOCK)	ON pmdmc3.MaterialDefinitionId = a.Origin1MaterialDefinitionId
	
																						AND pmdmc3.Name = @pnUOMPerPallet
	DELETE @tblBOMRMListActive WHERE BOMRMOG <> @OG


	UPDATE b
	SET ProductGroupCapacity = CONVERT(int, pee.Value)
	FROM @tblBOMRMListActive b
	JOIN dbo.PAEquipment_Aspect_SOAEquipment a		WITH(NOLOCK) ON b.BOMRMStoragePUId = a.pu_id
	JOIN dbo.property_equipment_equipmentclass pee	WITH(NOLOCK) ON a.Origin1EquipmentId = pee.EquipmentId
																	AND pee.Name LIKE '%'+  b.BOMRMOG + '.' + @pnOriginGroupCapacity
	

	--LOOP into all matching items.  Probably only one
	SET @BOMRMFormItemId = (SELECT MIN(BOMRMFormItemId) FROM @tblBOMRMListActive)
	WHILE @BOMRMFormItemId IS NOT NULL
	BEGIN
		/*
		Still needed = TPQ - TC​
			TPQ = Total Planned Quantity = Process order planned quantity (component) + SAP and / or Proficy scrap factor​
			TCQ = Total Consumed Quantity (UL’s with status “Checked in”, “running”, “consumed”, ‘overconsumed”)​
		IF “Still needed” > 1 THAN​
		Order quantity (Cases) = Capacity – On Route​
			On Route = Inventory (UL’s with status “Delivered”) + Open requests ​
		Order quantity (cases) =< Still needed​
		IF “Still needed” = 0 THAN look at Initiate order​
		*/
		--Set the total planned Qty
		SELECT	@TPQ				= NULL,
				@TCQ				= NULL,
				@BOMRMScrapFactor	= NULL

		SELECT	@TPQ				= BOMRMQty,
				@BOMRMScrapFactor	= BOMRMScrapFactor
		FROM @tblBOMRMListActive
		WHERE BOMRMFormItemId = @BOMRMFormItemId



		
		SET @BOMRMFormItemId = (SELECT MIN(BOMRMFormItemId) FROM @tblBOMRMListActive WHERE BOMRMFormItemId > @BOMRMFormItemId)
	END

	

	--Get the capacity for each BOM entry remaining






--ul
select * from @tblBOMRMListActive




END




ErrCode:

IF @DebugflagOnLine = 1  
BEGIN
	INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
		VALUES(	getdate(), 
				@SPName,
				'9999' +

				' Finished',
				@pathid
				)
END


SET NOcount OFF

RETURN
