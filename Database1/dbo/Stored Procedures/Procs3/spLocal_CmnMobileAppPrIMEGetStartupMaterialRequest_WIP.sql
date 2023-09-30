--------------------------------------------------------------------------------------------------
-- Stored Procedure: spLocal_CmnMobileAppPrIMEGetStartupMaterialRequest
--------------------------------------------------------------------------------------------------
-- Author				: Ugo Lapierre, Symasol
-- Date created			: 22-Aug-2018	
-- Version 				: Version <1.0>
-- SP Type				: MobileApp
-- Caller				: Called by PE MobileAPp
-- Description			: This make the list of all Prime material needed for the PO, including the actual open request
-- Editor tab spacing	: 4
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ========		====	  		====					=====
-- 1.0			22-Aug-2018		U.Lapierre				Original
-- 1.1			23-Aug-2018		Julien B. Ethier		Added QuantityUOM field (from SOA property)
-- 1.2			24-Aug-2018		Julien B. Ethier		Fixed issue regarding wrong open request count
-- 1.3			28-Aug-2018		Linda Hudon				remove user id input parametes
-- 1.4			29-Aug-2018		Julien B. Ethier		Call function instead of SP 
-- 1.5			10-Sep-2018		Julien B. Ethier		Fixed @OpenRequest table fields datatype
-- 1.6			20-Sep-2018		U.Lapierre				Adapt [fnLocal_CmnPrIMEGetOpenRequests] due to new parameter
-- 1.7			2018-09-20		Linda Hudon				change location to varchar(50)
-- 1.8			2018-09-21		Linda Hudon				remove lineID
-- 1.9			2018-10-12		U.Lapierre				PCM (FO-03511)
-- 1.10			2018-11-12		Linda Hudon				add invenotory availability
-- 1.11			2018-12-12		U.Lapierre				for PCM set Threshold in UOM as sum of Threshold of UOM for each position.  (used for yellow background in MA)
-- 1.12			2018-12-14		U.Lapierre				Fix issue with suggested quantity when ordering material
-- 1.13			2019-02-20		U.Lapierre				FO-03557.  Prevent showing C/O material   if it is the alternate material of Active order
-- 1.14			2019-03-27		U.Lapierre				Fix issue with suggested quantity when ordering material	
-- 1.15			2019-09-19		Sasha Metlitski			FO-04067 Implement Pre-Staged Material Request Functionality

/*---------------------------------------------------------------------------------------------
Testing Code


exec dbo.spLocal_CmnMobileAppPrIMEGetStartupMaterialRequest_WIP 57, 1, 1
select * from local_prime_openrequests
select * from prdExec_paths
-----------------------------------------------------------------------------------------------*/


--------------------------------------------------------------------------------
CREATE PROCEDURE				[dbo].[spLocal_CmnMobileAppPrIMEGetStartupMaterialRequest_WIP]
@PathId							int,					
@DebugFlagOnLine				int,
@DebugFlagManual				int

--WITH ENCRYPTION
AS
SET NOCOUNT ON

DECLARE	
@SPName							varchar(50),
@CurrentTime					datetime,

--Production Plan
@pathCode						varchar(30),
@StatusStrActive				varchar(25),
@StatusStrComplete				varchar(25),
@StatusStrNext					varchar(25),
@StatusStrReady					varchar(25),
@PPSchedulePUId					int,
@ProdLineId						int,
@ProdLineDesc					varchar(50),
@ActPPId						int,
@ActPPProcessOrder				varchar(12),
@ActPPProdId					int,
@ActPPProdCode					varchar(8),
@ActBOMFormId					int,
@ActiveOrderExists				bit,
@NxtPPId						int,
@NxtPPStatusId					int,
@NxtPPStatusStr					varchar(50),
@NxtPPPlannedQty				float,				-- verify if used
@NxtPPProcessOrder				varchar(12),
@NxtPPProdId					int,				
@NxtPPProdCode					varchar(8),			
@NxtBOMFormId					int,
@NxtFPStandardQty				float,

--SOA properties
@pnOriginGroupCapacity			varchar(50),
@ProductGroupCapacity			int,
@pnOriginGroupThreshold			varchar(50),
@ProductGroupThreshold			float,
@pnUOMPerPallet					varchar(30),
@UOMPerPallet					int,
@pnOriginGroup					varchar(30),
@pnUOM							varchar(50),
@UOM							varchar(25),
@cnOrderMaterials				varchar(50),
@pnPrIMELocation				varchar(50),


--Path UDPs
@TableIdPath					int,
@TableIdRMI						int,
@tfPEWMSSystemId				int,
@tfIsOrderingId					int,
@tfUseRMScrapFactorId			int,
@tfRMScrapFactorId				int,
@tfOGId							int,
@udpUseScrapFactorId			int,
@UsePathScrapFactor				bit,
@IsSCOLineId					int,
@IsSCOLine						bit,

--Subscription UDPs
@UsePrIME						bit,
@WMSSubscriptionID				int,

--PCM
@tfParallelConsumptionId		int,
@tfParallelItemCountId			int,
@PEIID							int,
@CountPosition					int,
@RequiredQtyPos					float,
@LoadedQtyPos					float,
@LoadedCountPos					int,
@NeededQtyPos					float,
@NeededCountPos					int,
@TotalLoadedQty					float,
@TotalLoadedCount				float,
@TotalNeededQty					float,
@TotalNeededCount				float,
@CountPositionFilled			int,
@FinalNeededQtyPos				float,
@FinalNeededCountPos			int,
@TotalFinalNeededQty			float,
@TotalFinalNeededCount			int,
@TotalNotLoadedCount			int,
@TotalNotLoadedQty				float,
@NxtRequiredBOMRMUOMQtyPos		float,


--Events and event properties
@toBeReturnedId					int,

--Calculate material Actuals
@LoopIndex					int,
@BOMRMOG					varchar(10),
@BOMRMStoragePUDesc			varchar(50),
@BOMRMProdId				int,
@BOMRMSubProdId				int,
@BOMRMTNLOCATN				varchar(50),
@BOMRMProdCode				varchar(8),
@BOMRMSubProdCode			varchar(100),
@ActualPalletCntTot			int,	
@ActualPalletCntStaging		int,
@ActualPalletCntOpenRequest int,
@FlgNewToInitiateOrder		bit,
@UseRMScrapFactor			bit,
@RMScrapFactor				float,
@BOMRMScrapFactor			float,


--Final calc
@ActualUOMQtyStaging			float,
@ActualUOMQtyStagingSub			float,
@ActualUOMQtyPreStaging			float,
@ActualUOMQtyOpenRequest		float,
@ActualUOMQtyOpenRequestSub		float,
@ActualUOMQtyTot				float,
@ActualPalletCntStagingSub		int,
@LoopIndexRM					int,
@LoopcountRM					int,
@BOMRMQty						float,
@BOMRMQtyOR						float,
@BOMRMEngUnitDesc				varchar(25),
@BOMRMSubEngUnitDesc			varchar(25),
@ProductUOMPerPallet			float,
@ActRequiredBOMRMUOMQty			float,
@NxtRequiredBOMRMUOMQty			float,
@NeededUOMQty					float,
@FinalNeededUOMQty				float,
@ActFinalNeededUOMQty			float,
@NxtFinalNeededUOMQty			float,
@NeededPalletCnt				int,
@FinalNeededPalletCnt			int,
@ActFinalNeededPalletCnt		int,
@NxtFinalNeededPalletCnt		int,
@BOMRMSubConversionFactor		float,
@BOMRMProdDesc					varchar(100),
@ThresholdInUOM					int,
@OrderedQtyUOM					int,
@ActualOldestORTime				datetime,
@ActualOrderSinceMinute			int,
@OpenRequestPalletCnt			int,
@LastRequestStatus				varchar(50)

--FO-04067 Change-over Materials Change Request
--1.15			2019-09-19		Sasha Metlitski			Implement Pre-Staged Material Request Functionality
DECLARE @FlgPreStagedMaterialRequest		int,
		@UDPPreStagedMaterialRequest		varchar(255),
		@StatusPreStaged					varchar(255)

DECLARE @tblBOMRMListComplete TABLE
(	BOMRMId						int IDENTITY,
	PPId						int,
	ProcessOrder				varchar(50),
	PPStatusStr					varchar(25),
	BOMRMProdId					int,
	BOMRMProdCode				varchar(25),
	BOMRMQty					float,
	BOMRMEngUnitId				int,
	BOMRMEngUnitDesc			varchar(25),
	BOMRMScrapFactor			float,
	BOMRMFormItemId				int,
	BOMRMOG						varchar(25),
	ProductGroupCapacity		int,
	ProductGroupThreshold		float,
	ProductUOMPerPallet			float,
	FlgNewToInitiateOrder		bit,
	BOMRMStoragePUId			int,
	BOMRMStoragePUDesc			varchar(50),
	--BOMRMTNLOCATN				varchar(50),
	PrIMELocation				varchar(50),
	BOMRMSubProdId				int,
	BOMRMSubProdCode			varchar(25),
	BOMRMSubEngUnitId			int,
	BOMRMSubEngUnitDesc			varchar(25),
	BOMRMSubConversionFactor	float,
	BOMErrMsg					varchar(1000)
)


DECLARE	@tblDuplicateProducts TABLE
(	Id				int	IDENTITY,
	BOMRMProdId		int,
	BOMRMProdCode	varchar(25)
)


DECLARE @PRDExecInputs TABLE 
(
	PUID						int,
	PEIID						int,
	OG							varchar(50),
	PEWMSSystem					varchar(50),
	IsOrdering					bit,
	UseRMScrapFactor			bit,
	RMScrapFactor				float,
	ParallelConsumption			bit,
	ParallelItemCount			int
					)



DECLARE @tblRMInventoryStaging TABLE
(
	RMInventoryId			int Identity, 
	RMEventId				int, 
	RMEventNum				varchar(50),
	RMPUId					int,
	RMPUDesc				varchar(50),
	RMInitDimX				float, 
	RMFinalDimX				float,
	RMProdId				int,
	RMProdCode				varchar(25),
	RMProdStatusId			int,
	RMProdStatusStr			varchar(50),
	RMPPId					int,
	RMProcessOrder			varchar(50),
	BOMRMOG					varchar(25)
)


DECLARE @Openrequest TABLE 
(
	OpenTableId			int,
	RequestId			varchar(50),
	PrimeReturnCode		int,
	RequestTime			datetime,
	LocationId			varchar(50),
	CurrentLocation		varchar(50),
	ULID				varchar(50),
	Batch				varchar(10),
	ProcessOrder		varchar(50),
	PrimaryGCAS			varchar(50),
	AlternateGCAS		varchar(50),
	GCAS				varchar(50),
	QuantityValue		float,
	QuantityUOM			varchar(50),
	Status				varchar(50),
	EstimatedDelivery	datetime,
	lastUpdatedTime		datetime,
	userId				int,
	eventId				int
)

DECLARE @tblRMInventoryGroupActual TABLE
(
	RMInventoryGrpId			int IDENTITY, 
	BOMRMOG						varchar(25),
	BOMRMStoragePUDesc			varchar(50),
	BOMRMPreStagingLocation		varchar(50),
	BOMRMScrapFactor			float,  
	BOMRMTNLOCATN				varchar(50),
	BOMRMProdId					int,
	BOMRMSubProdId				int,
	BOMRMProdCode				varchar(50),
	BOMRMSubProdCode			varchar(50),	
	ProductGroupCapacity		int,
	ProductGroupThreshold		float,
	ActualPalletCntStaging		int,
	ActualPalletCntOpenRequest	int,
	ActualPalletCntTot			int,
	FlgThresholdGTActual		int,
	FlgNewToInitiateOrder		bit,
	FlgNeededForActiveEq0		int,
	FlgOrderForActive			int,
	FlgOrderForNext				int,
	LastRequestStatus			varchar(50)
	)


DECLARE @tblRMInventoryQtyCalc TABLE		
(	
	RMInventoryId				int IDENTITY,
	PPId						int,
	ProcessOrder				varchar(50),
	PPStatusStr					varchar(25),
	BOMRMProdId					int,
	BOMRMProdCode				varchar(25),
	BOMRMQty					float,
	BOMRMEngUnitDesc			varchar(25),
	BOMRMOG						varchar(25),
	BOMRMStoragePUDesc			varchar(50),
	BOMRMScrapFactor			float,
	BOMRMTNLOCATN				varchar(25),
	ProductGroupCapacity		int,
	ProductUOMPerPallet			float,
	BOMRMSubProdId				int,
	BOMRMSubProdCode			varchar(25),
	BOMRMSubEngUnitId			int,
	BOMRMSubEngUnitDesc			varchar(25),
	BOMRMSubConversionFactor	float,
	RemainingProdCnt			int,
	FPStandardQty				int,
	RequiredBOMRMUOMQty			float,
	ActualUOMQtyStaging			float,
	ActualPalletCntStaging		int,			
	ActualUOMQtyPreStaging		float,
	ActualUOMQtyOpenRequest		float,
	ActualPalletCntOpenRequest	int,			
	CalcErrMsg					varchar(1000)
)


DECLARE @tblWFRequestMaterial TABLE
		(	Id							int IDENTITY,
			PPStatusStr					varchar(50),
			RMOG						varchar(25),
			BOMRMStoragePUDesc			varchar(50),
			RMProdCode					varchar(25),
			RMProdDesc					varchar(50),
			RMSubProdCode				varchar(25),
			RMPlannedQty				float,
			RMPlannedQTYOR				float,
			RMOpenRequestUOMQty			float,
			RMOpenRequestPalletCnt		int,			
			RMStagingUOMQty				float,
			RMStagingPalletCnt			int,
			RMStagingUOMQtySub			float,
			RMStagingPalletCntSub		int,			
			RMStagingCapacityPallet		int,
			RMUOMQTYTotal				float,
			RMPalletCntTotal			int,
			RMThresholdCapacity			float,		
			RMNeededUOMQty				float,
			RMNeededPalletCnt			int,
			RMRequestUOMQty				int,
			RMRequestPalletCnt			int,
			RMUOMPerPallet				int,
			RMEngUnitDesc				varchar(25),
			FlgNewToInitiateOrder		bit,
			PrimeLocation				varchar(50),
			ActualOrderSinceMinute		int,
			ThresholdInUOM				int,
			RMSubEngUnitDesc			varchar(25),
			LastRequestStatus			varchar(50),
			Inventoryavailibilty		varchar(10)
		)

-------------------------------------------------------------------------------
-- Initialize variables.
-------------------------------------------------------------------------------
SELECT	@SPName	= 'spLocal_CmnMobileAppPrIMEGetStartupMaterialRequest'

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

SELECT @CurrentTime = GETDATE()			
		
SELECT	@pnUOMPerPallet					= 'UOM Per Pallet',
		@pnOriginGroup					= 'Origin Group',
		@pnUOM							= 'UOM',
		@pnOriginGroupCapacity			= 'Origin Group Capacity',
		@pnOriginGroupThreshold			= 'Origin Group Threshold',
		@cnOrderMaterials				= 'PE:PrIME_WMS',
		@pnPrIMELocation				= 'LocationId',
		@UDPPreStagedMaterialRequest	= 'PE_PrIME_PreStagedMaterialRequest',
		@StatusPreStaged				= 'Pre-Staged'



--pp_status string
SELECT	@StatusStrActive				= 'Active',
		@StatusStrComplete				= 'Closing',
		@StatusStrNext					= 'Initiate',
		@StatusStrReady					= 'Ready'	


--prodcution_status
SET  @tobereturnedId = (SELECT prodStatus_id FROM dbo.production_status WITH(NOLOCK) WHERE prodStatus_desc = 'To be Returned')



SELECT 	@FlgPreStagedMaterialRequest = Null
SELECT 	@FlgPreStagedMaterialRequest = IsNull(tfv.Value,0)
FROM	dbo.TABLE_FIELDS_VALUES tfv
join	dbo.TABLE_FIELDS tf on tfv.TABLE_FIELD_ID = tf.TABLE_FIELD_ID
join	dbo.TABLES t on tf.TABLEID = t.TABLEID
WHERE	t.TABLENAME = 'PrdExec_Paths'
and		tf.TABLE_FIELD_DESC = @UDPPreStagedMaterialRequest
and		tfv.KeyId = @PathId


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

	IF @DebugFlagManual = '1'
	BEGIN
		SELECT 'Not a PrIME server'
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
SET @IsSCOLineId			= ( SELECT Table_Field_id	FROM dbo.Table_Fields			WITH(NOLOCK)	WHERE Table_Field_Desc  = 'PE_General_IsSCOLine'	AND TableID = @TableIdPath)
SET @IsSCOLine				= ( SELECT value			FROM dbo.Table_Fields_values	WITH(NOLOCK)	WHERE table_Field_ID = @IsSCOLineId AND KEYID  = @PathId) 
IF @IsSCOLine IS NULL
	SET @IsSCOLine = 0

SET @TableIdRMI	= (SELECT TableID FROM dbo.Tables Where tableName = 'PRDExec_inputs')
SET @tfPEWMSSystemId		= (	SELECT Table_Field_Id 	FROM dbo.Table_Fields 			WITH(NOLOCK)	WHERE Table_Field_Desc = 'PE_WMS_System'		AND tableid = @TableIdRMI)
SET @tfIsOrderingId			= (	SELECT Table_Field_Id 	FROM dbo.Table_Fields 			WITH(NOLOCK)	WHERE Table_Field_Desc = 'PE_WMS_IsOrdering'	AND tableid = @TableIdRMI)
SET @tfUseRMScrapFactorId	= (	SELECT Table_Field_Id 	FROM dbo.Table_Fields 			WITH(NOLOCK)	WHERE Table_Field_Desc = 'UseRMScrapFactor'		AND tableid = @TableIdRMI)
SET @tfRMScrapFactorId		= (	SELECT Table_Field_Id 	FROM dbo.Table_Fields 			WITH(NOLOCK)	WHERE Table_Field_Desc = 'RMScrapFactor'		AND tableid = @TableIdRMI)
SET @tfOGId					= (	SELECT Table_Field_Id 	FROM dbo.Table_Fields 			WITH(NOLOCK)	WHERE Table_Field_Desc = 'Origin Group'			AND tableid = @TableIdRMI)
SET @tfParallelConsumptionId= (	SELECT Table_Field_Id 	FROM dbo.Table_Fields 			WITH(NOLOCK)	WHERE Table_Field_Desc = 'ParallelConsumption'	AND tableid = @TableIdRMI)
SET @tfParallelItemCountId	= (	SELECT Table_Field_Id 	FROM dbo.Table_Fields 			WITH(NOLOCK)	WHERE Table_Field_Desc = 'ParallelItemCount'	AND tableid = @TableIdRMI)


--1.15
SELECT 	@FlgPreStagedMaterialRequest = Null
SELECT 	@FlgPreStagedMaterialRequest = IsNull(tfv.Value,0)
FROM	dbo.TABLE_FIELDS_VALUES tfv
join	dbo.TABLE_FIELDS tf on tfv.TABLE_FIELD_ID = tf.TABLE_FIELD_ID
join	dbo.TABLES t on tf.TABLEID = t.TABLEID
WHERE	t.TABLENAME = 'PrdExec_Paths'
and		tf.TABLE_FIELD_DESC = @UDPPreStagedMaterialRequest
and		tfv.KeyId = @PathId

IF @DebugFlagOnLine = 1  
BEGIN
	INSERT INTO dbo.Local_Debug([Timestamp], CallingSP, [Message], msg) 
			VALUES(	
			getdate(), 
			@SPName,
			'0001' +
			' TimeStamp=' + convert(varchar(25), getdate(), 120) + 
			' @FlgPreStagedMaterialRequest=' + convert(varchar(255), IsNull(@FlgPreStagedMaterialRequest,0)),
			@pathid
			)
END



-------------------------------------------------------------------------------
-- Task 1
-- 1. Locate Active Process Order 
--		- Get the Planned Production Qty
--		- Retrieve the Remaining Qty of the Production count
--		- Retrieve the BOM Table of the Active Process Order
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Retrieve basic path info
-------------------------------------------------------------------------------
SET @PPSchedulePUId = NULL

--get path Code
SET @pathCode = (SELECT path_code FROM dbo.prdExec_Paths WITH(NOLOCK) WHERE path_id = @pathId)

										
SELECT	@PPSchedulePUId = ppu.PU_Id						
FROM	dbo.PrdExec_Path_Units ppu		WITH(NOLOCK)
JOIN	dbo.Prod_Units_base pu			WITH(NOLOCK) ON (pu.PU_Id = ppu.PU_Id)
WHERE ppu.Path_Id = @PathId									
		AND Is_Schedule_Point = 1

																							
SELECT  @ProdLineId = pu.PL_Id,														
		@ProdLineDesc = pl.PL_Desc
FROM dbo.Prod_Units_base pu		WITH(NOLOCK)
JOIN dbo.Prod_Lines_base pl		WITH(NOLOCK) ON (pl.PL_Id = pu.PL_Id)
WHERE pu.PU_Id = @PPSchedulePUId

IF @ProdLineId IS NULL
BEGIN
	IF @DebugFlagOnLine = 1
	BEGIN 
	INSERT into Local_Debug([Timestamp], CallingSP, [Message],msg) 
		VALUES(	getdate(), 
				@SpName,
				'0100' +
				' TimeStamp=' + convert(varchar(25), getdate(), 120) +
				' Invalid Path',
				@pathId)
	END

	IF @DebugFlagManual = '1'
	BEGIN
		SELECT 'Invalid Path'
	END

	GOTO ErrCode
END


-------------------------------------------------------------------------------
-- Retrieve the Active Process Order Info
-------------------------------------------------------------------------------
																							
SELECT	@ActPPId = NULL
SET		@ActiveOrderExists = 0			
SELECT	TOP 1
		@ActPPId				= pp.PP_Id,
		@ActPPProcessOrder		= pp.Process_Order,
		@ActPPProdId			= pp.Prod_Id,
		@ActPPProdCode			= p.Prod_Code,
		@ActBOMFormId			= pp.BOM_Formulation_Id
FROM dbo.Production_Plan pp					WITH(NOLOCK)
JOIN dbo.Products_base p					WITH(NOLOCK) ON (pp.Prod_Id = p.Prod_Id)
JOIN dbo.Production_Plan_Statuses pps		WITH(NOLOCK) ON (pps.PP_Status_Id = pp.PP_Status_Id)
WHERE pps.PP_Status_Desc = @StatusStrActive
	AND Path_Id = @PathId
ORDER BY pp.Actual_start_time DESC

IF @ActPPId IS NOT NULL
BEGIN
	SET		@ActiveOrderExists = 1
END

IF	@ActPPId IS NULL
BEGIN
	IF @DebugFlagOnLine = 1
	BEGIN
		INSERT intO Local_Debug([Timestamp], CallingSP, [Message], msg) 
			VALUES(	getdate(), 
					@SpName,
					'0110' +
					' TimeStamp=' + convert(varchar(25), getdate(), 120) +
					' No Active Order',
					@pathId)
	END
	GOTO	CheckNxtOrder	
END

IF @DebugFlagManual = 1
BEGIN
	SELECT
		@ActPPId				AS PPId,
		@ActPPProcessOrder		AS Process_Order,
		@ActPPProdId			AS Prod_Id,
		@ActPPProdCode			AS Prod_Code
END

IF @DebugFlagOnLine = 1
BEGIN
	INSERT INTO Local_Debug([Timestamp], CallingSP, [Message], msg) 
		VALUES(	getdate(), 
				@SpName,
				'0120' +
				' PathId=' + convert(varchar(5), @PathId) + 
				' TimeStamp=' + convert(varchar(25), getdate(), 120) +
				' ActPPId=' + coalesce(convert(varchar(10), @ActPPId), 'NoPPId') + 
				' ActPO=' + coalesce(@ActPPProcessOrder, 'NOPO') + 
				' ActProduct=' + coalesce(@ActPPProdCode, 'NOProduct'), 
				@pathId
				)
END


-------------------------------------------------------------------------------
-- Retrieve the BOM for the Active Order
-------------------------------------------------------------------------------
INSERT INTO @tblBOMRMListComplete (
			PPId,
			ProcessOrder,
			PPStatusStr,
			BOMRMProdId,
			BOMRMProdCode,
			BOMRMQty,
			BOMRMEngUnitId,
			BOMRMEngUnitDesc,
			BOMRMScrapFactor,
			BOMRMFormItemId,
			BOMRMOG,
			FlgNewToInitiateOrder,
			BOMRMStoragePUId,
			BOMRMStoragePUDesc,
			BOMRMSubProdId,
			BOMRMSubProdCode,
			BOMRMSubEngUnitId,
			BOMRMSubEngUnitDesc,
			BOMRMSubConversionFactor	)
	SELECT	@ActPPId,
			@ActPPProcessOrder,
			@StatusStrActive,
			bomfi.Prod_Id, 
			p.Prod_Code, 
			bomfi.Quantity,
			bomfi.Eng_Unit_Id,
			eu.Eng_Unit_Desc,						
			bomfi.Scrap_Factor,
			bomfi.BOM_Formulation_Item_Id,
			NULL, 			
			'False',
			pu.PU_Id,
			pu.PU_Desc,
			bomfs.Prod_Id,
			p_sub.Prod_Code,
			bomfs.Eng_Unit_Id,
			eu_sub.Eng_Unit_Desc,
			bomfs.Conversion_Factor
	FROM	dbo.Bill_Of_Material_Formulation_Item bomfi		WITH(NOLOCK)
	JOIN dbo.Bill_Of_Material_Formulation bomf				WITH(NOLOCK) ON (bomf.BOM_Formulation_Id = bomfi.BOM_Formulation_Id)
	JOIN dbo.Products_base p								WITH(NOLOCK) ON (p.Prod_Id = bomfi.Prod_Id) 
	JOIN dbo.Engineering_Unit eu							WITH(NOLOCK) ON (eu.Eng_Unit_Id = bomfi.Eng_Unit_Id)
	LEFT JOIN dbo.Bill_Of_Material_Substitution bomfs		WITH(NOLOCK) ON (bomfs.BOM_Formulation_Item_Id = bomfi.BOM_Formulation_Item_Id)
	LEFT JOIN dbo.Products_base p_sub						WITH(NOLOCK) ON (p_sub.Prod_Id = bomfs.Prod_Id) 
	LEFT JOIN dbo.Engineering_Unit eu_sub					WITH(NOLOCK) ON (eu_sub.Eng_Unit_Id = bomfs.Eng_Unit_Id)
	LEFT JOIN dbo.Prod_Units_base pu						WITH(NOLOCK) ON (bomfi.PU_Id = pu.PU_Id)
	WHERE	bomf.BOM_Formulation_Id = @ActBOMFormId



IF @DebugFlagOnLine = 1
BEGIN
	INSERT INTO Local_Debug([Timestamp], CallingSP, [Message], msg) 
		VALUES(	getdate(), 
				@SPName,
				'0130' +
				' TimeStamp=' + convert(varchar(25), getdate(), 120) +
				' ActPPId=' + coalesce(convert(varchar(10), @ActPPId), 'NoPPId') + 
				' ActPO=' + coalesce(@ActPPProcessOrder, 'NOPO') + 
				' ActProduct=' + coalesce(@ActPPProdCode, 'NOProduct') +
				' Finish to get the Active BOM',
				@pathid
				)
END








-------------------------------------------------------------------------------
-- Task 2
-- 2. Locate Next Process Order and its Planned Qty
--    Retrieve the BOM Table of the Next Process Order (Initiate)
-------------------------------------------------------------------------------
CheckNxtOrder:

-------------------------------------------------------------------------------
-- Retrieve the Next Process Order Info
-------------------------------------------------------------------------------
SET @NxtPPId = NULL

SELECT	
	@NxtPPId				= pp.PP_Id,
	@NxtPPStatusId			= pp.PP_Status_Id,
	@NxtPPStatusStr			= pps.PP_Status_Desc,
	@NxtPPPlannedQty		= pp.Forecast_Quantity,
	@NxtPPProcessOrder		= pp.Process_Order,
	@NxtPPProdId			= pp.Prod_Id,
	@NxtPPProdCode			= p.Prod_Code,
	@NxtBOMFormId			= pp.BOM_Formulation_Id
FROM dbo.Production_Plan pp				WITH(NOLOCK)
JOIN dbo.Products_base p				WITH(NOLOCK) ON (pp.Prod_Id = p.Prod_Id)
JOIN dbo.Production_Plan_Statuses pps	WITH(NOLOCK) ON (pps.PP_Status_Id = pp.PP_Status_Id)
WHERE pps.PP_Status_Desc = @StatusStrNext
	AND Path_Id = @PathId


IF @NxtPPId IS NULL
BEGIN
	SELECT	
		@NxtPPId				= pp.PP_Id,
		@NxtPPStatusId			= pp.PP_Status_Id,
		@NxtPPStatusStr			= pps.PP_Status_Desc,
		@NxtPPPlannedQty		= pp.Forecast_Quantity,
		@NxtPPProcessOrder		= pp.Process_Order,
		@NxtPPProdId			= pp.Prod_Id,
		@NxtPPProdCode			= p.Prod_Code,
		@NxtBOMFormId			= pp.BOM_Formulation_Id
	FROM dbo.Production_Plan pp				WITH(NOLOCK)
	JOIN dbo.Products_base p				WITH(NOLOCK) ON (pp.Prod_Id = p.Prod_Id)
	JOIN dbo.Production_Plan_Statuses pps	WITH(NOLOCK) ON (pps.PP_Status_Id = pp.PP_Status_Id)
	WHERE pps.PP_Status_Desc = @StatusStrReady  	
		AND Path_Id = @PathId
END



IF	@NxtPPId IS NULL
BEGIN
	IF @DebugFlagOnLine = 1 
	BEGIN
		INSERT into Local_Debug(Timestamp, CallingSP, Message, msg) 
			VALUES(	getdate(), 
					@spname,
					'0210' +
					' TimeStamp=' + convert(varchar(25), getdate(), 120) +
					' No Next Order',
					@pathId)
	END

	IF @DebugFlagManual = '1'
	BEGIN
		SELECT 'No next order'
	END
	GOTO ErrCode
END

IF @DebugFlagManual = 1
BEGIN
	SELECT
		@NxtPPId				AS PPId,
		@NxtPPStatusId			AS PP_Status_Id,
		@NxtPPStatusStr			AS PP_Status_Str,
		@NxtPPPlannedQty		AS Forecast_Quantity,
		@NxtPPProcessOrder		AS Process_Order,
		@NxtPPProdId			AS Prod_Id,
		@NxtPPProdCode			AS Prod_Code
END

IF @DebugFlagOnLine = 1  
BEGIN
	INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
		VALUES(	getdate(), 
				@spname,
				'0220' +
				' TimeStamp=' + convert(varchar(25), getdate(), 120) +
				' NxtPPId=' + coalesce(convert(varchar(10), @NxtPPId), 'NoPPId') + 
				' NxtPO=' + coalesce(@NxtPPProcessOrder, 'NOPO') + 
				' NxtProduct=' + coalesce(@NxtPPProdCode, 'NOProduct'),
				@pathId)
END


SET @NxtFPStandardQty = @NxtPPPlannedQty



INSERT INTO @tblBOMRMListComplete (
			PPId,
			ProcessOrder,
			PPStatusStr,
			BOMRMProdId,
			BOMRMProdCode,
			BOMRMQty,
			BOMRMEngUnitId,
			BOMRMEngUnitDesc,
			BOMRMScrapFactor,
			BOMRMFormItemId,
			BOMRMOG,
			FlgNewToInitiateOrder,
			BOMRMStoragePUId,
			BOMRMStoragePUDesc,
			BOMRMSubProdId,
			BOMRMSubProdCode,
			BOMRMSubEngUnitId,
			BOMRMSubEngUnitDesc,
			BOMRMSubConversionFactor	)
SELECT	@NxtPPId,
		@NxtPPProcessOrder,
		@NxtPPStatusStr,
		bomfi.Prod_Id, 
		p.Prod_Code, 
		bomfi.Quantity,
		bomfi.Eng_Unit_Id,
		eu.Eng_Unit_Desc,
		bomfi.Scrap_Factor,
		bomfi.BOM_Formulation_Item_Id,
		NULL, 
		'False',
		pu.PU_Id,
		pu.PU_Desc,
		bomfs.Prod_Id,
		p_sub.Prod_Code,
		bomfs.Eng_Unit_Id,
		eu_sub.Eng_Unit_Desc,
		bomfs.Conversion_Factor
FROM dbo.Bill_Of_Material_Formulation_Item bomfi		WITH(NOLOCK)
JOIN dbo.Bill_Of_Material_Formulation bomf				WITH(NOLOCK) ON (bomf.BOM_Formulation_Id = bomfi.BOM_Formulation_Id)
JOIN dbo.Products_base p								WITH(NOLOCK) ON (p.Prod_Id = bomfi.Prod_Id) 
JOIN dbo.Engineering_Unit eu							WITH(NOLOCK) ON (eu.Eng_Unit_Id = bomfi.Eng_Unit_Id)
LEFT JOIN dbo.Bill_Of_Material_Substitution bomfs		WITH(NOLOCK) ON (bomfs.BOM_Formulation_Item_Id = bomfi.BOM_Formulation_Item_Id)
LEFT JOIN dbo.Products_base p_sub						WITH(NOLOCK) ON (p_sub.Prod_Id = bomfs.Prod_Id) 
LEFT JOIN dbo.Engineering_Unit eu_sub					WITH(NOLOCK) ON (eu_sub.Eng_Unit_Id = bomfs.Eng_Unit_Id)
LEFT JOIN dbo.Prod_Units_base pu						WITH(NOLOCK) ON (bomfi.PU_Id = pu.PU_Id)
WHERE bomf.BOM_Formulation_Id = @NxtBOMFormId

IF @DebugFlagOnLine = 1  
BEGIN
	INSERT INTO Local_Debug([Timestamp], CallingSP, [Message], msg) 
		VALUES(	getdate(), 
				@SPName,
				'0230' +
				' TimeStamp=' + convert(varchar(25), getdate(), 120) +
				' NxtPPId=' + coalesce(convert(varchar(10), @NxtPPId), 'NoPPId') + 
				' NxtPO=' + coalesce(@NxtPPProcessOrder, 'NOPO') + 
				' NxtProduct=' + coalesce(@NxtPPProdCode, 'NOProduct') +
				' Finish to get the Next BOM',
				@pathid
				)
END



--  GET OG for all BOM items
UPDATE b
SET BOMRMOG = CONVERT(varchar(50),pmdmc2.value),
	BOMRMSubEngUnitDesc = CONVERT(varchar(50),pmdmc.value),
	productUOMperPallet = CONVERT(varchar(50),pmdmc3.value)
FROM @tblBOMRMListComplete b
JOIN	dbo.Products_Aspect_MaterialDefinition a				WITH(NOLOCK)	ON b.BOMRMProdId = a.prod_id
JOIN	dbo.Property_MaterialDefinition_MaterialClass pmdmc		WITH(NOLOCK)	ON pmdmc.MaterialDefinitionId = a.Origin1MaterialDefinitionId
																					AND pmdmc.Name = @pnUOM
JOIN	dbo.Property_MaterialDefinition_MaterialClass pmdmc2	WITH(NOLOCK)	ON pmdmc2.MaterialDefinitionId = a.Origin1MaterialDefinitionId
																					AND pmdmc2.Name = @pnOriginGroup
JOIN	dbo.Property_MaterialDefinition_MaterialClass pmdmc3	WITH(NOLOCK)	ON pmdmc3.MaterialDefinitionId = a.Origin1MaterialDefinitionId
																					AND pmdmc3.Name = @pnUOMPerPallet


--Get PrIME Location from the SOA equipement class
UPDATE b
SET PrIMELocation = CONVERT(varchar(50), pee.Value)
FROM @tblBOMRMListComplete b
JOIN dbo.PAEquipment_Aspect_SOAEquipment a		WITH(NOLOCK) ON b.BOMRMStoragePUId = a.pu_id
JOIN dbo.property_equipment_equipmentclass pee	WITH(NOLOCK) ON a.Origin1EquipmentId = pee.EquipmentId
WHERE pee.Class = @cnOrderMaterials
AND pee.Name = @pnPrIMELocation 

--This is used to remove all BOM material where we do not have a PrIME location
DELETE @tblBOMRMListComplete
WHERE PrIMELocation IS NULL  OR PrIMELocation = ''


IF @DebugFlagOnLine = 1  
BEGIN
	INSERT INTO Local_Debug([Timestamp], CallingSP, [Message], msg) 
		VALUES(	getdate(), 
				@SPName,
				'0250' +
				' TimeStamp=' + convert(varchar(25), getdate(), 120) +
				' ActPPId=' + coalesce(convert(varchar(10), @ActPPId), 'NoPPId') + 
				' ActPO=' + coalesce(@ActPPProcessOrder, 'NOPO') + 
				' ActProduct=' + coalesce(@ActPPProdCode, 'NOProduct') +
				' NxtPPId=' + coalesce(convert(varchar(10), @NxtPPId), 'NoPPId') + 
				' NxtPO=' + coalesce(@NxtPPProcessOrder, 'NOPO') + 
				' NxtProduct=' + coalesce(@NxtPPProdCode, 'NOProduct') +
				' Finish-Update the Orgin Grp',
				@pathID
				)
END


IF @DebugFlagManual = 1
BEGIN
	SELECT	'@tblBOMRMList-Next', * 
	FROM	@tblBOMRMListComplete
END


-------------------------------------------------------------------------------
-- Delete all the BOMs of the Active Order
-- Delete all the ProdCodes which are used at the Active Order
-------------------------------------------------------------------------------
INSERT INTO @tblDuplicateProducts (BOMRMProdId, BOMRMProdCode)	
	SELECT	t1.BOMRMProdId, t1.BOMRMProdCode
	FROM	@tblBOMRMListComplete t1 
		JOIN @tblBOMRMListComplete t2 ON (t1.BOMRMProdId = t2.BOMRMProdId)
	WHERE	(t1.PPStatusStr = @StatusStrActive OR t1.PPStatusStr = @StatusStrComplete)
		AND (t2.PPStatusStr = @StatusStrNext OR t2.PPStatusStr = @StatusStrReady) 



--V1.13 FO-03557-------------------------
INSERT INTO @tblDuplicateProducts (BOMRMProdId, BOMRMProdCode)	
SELECT	t1.BOMRMSubProdId, t1.BOMRMSubProdCode
FROM	@tblBOMRMListComplete t1 
	JOIN @tblBOMRMListComplete t2 ON (t1.BOMRMSubProdId = t2.BOMRMProdId)
WHERE	(t1.PPStatusStr = @StatusStrActive OR t1.PPStatusStr = @StatusStrComplete)
	AND (t2.PPStatusStr = @StatusStrNext OR t2.PPStatusStr = @StatusStrReady)



DELETE FROM @tblBOMRMListComplete
WHERE PPStatusStr = @StatusStrActive
	OR PPStatusStr = @StatusStrComplete



UPDATE @tblBOMRMListComplete
SET FlgNewToInitiateOrder = 'True'
FROM @tblBOMRMListComplete  blc
WHERE BOMRMProdId NOT IN (SELECT BOMRMProdId FROM @tblDuplicateProducts)


-----------------------------------------



DELETE FROM t1
FROM @tblBOMRMListComplete t1
JOIN @tblDuplicateProducts t2 ON (t1.BOMRMProdId = t2.BOMRMProdId)


DELETE FROM @tblBOMRMListComplete
WHERE PPStatusStr = @StatusStrActive
	OR PPStatusStr = @StatusStrComplete



IF @DebugFlagOnLine = 1  
BEGIN
	INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
		VALUES(	getdate(), 
				@SPName,
				'0260' +
				' TimeStamp=' + convert(varchar(25), getdate(), 120) +
				' ActPPId=' + coalesce(convert(varchar(10), @ActPPId), 'NoPPId') + 
				' ActPO=' + coalesce(@ActPPProcessOrder, 'NOPO') + 
				' ActProduct=' + coalesce(@ActPPProdCode, 'NOProduct') +
				' NxtPPId=' + coalesce(convert(varchar(10), @NxtPPId), 'NoPPId') + 
				' NxtPO=' + coalesce(@NxtPPProcessOrder, 'NOPO') + 
				' NxtProduct=' + coalesce(@NxtPPProdCode, 'NOProduct') +
				' Clean up the BOM List',
				@pathId
				)
END

IF @DebugFlagManual = 1
BEGIN
	SELECT	'@tblBOMRMList-Clean', *
	FROM	@tblBOMRMListComplete
END



-------------------------------------------------------------------------------
--get capacity and trhreshold
-------------------------------------------------------------------------------

UPDATE b
SET ProductGroupCapacity = CONVERT(int, pee.Value),
	ProductGroupThreshold = CONVERT(float, pee2.Value)
FROM @tblBOMRMListComplete b
JOIN dbo.PAEquipment_Aspect_SOAEquipment a		WITH(NOLOCK) ON b.BOMRMStoragePUId = a.pu_id
JOIN dbo.property_equipment_equipmentclass pee	WITH(NOLOCK) ON a.Origin1EquipmentId = pee.EquipmentId
																AND pee.Name LIKE '%'+  b.BOMRMOG + '.' + @pnOriginGroupCapacity
JOIN dbo.property_equipment_equipmentclass pee2	WITH(NOLOCK) ON a.Origin1EquipmentId = pee2.EquipmentId
																AND pee2.Name LIKE '%'+  b.BOMRMOG + '.' + @pnOriginGroupThreshold

 IF @DebugFlagOnLine = 1  
	BEGIN
		INSERT INTO Local_Debug([Timestamp], CallingSP, [Message], msg) 
			VALUES(	getdate(), 
					@SPName,
					'0310' +
					' TimeStamp=' + convert(varchar(25), getdate(), 120) +
					' ActPPId=' + coalesce(convert(varchar(10), @ActPPId), 'NoPPId') + 
					' ActPO=' + coalesce(@ActPPProcessOrder, 'NOPO') + 
					' ActProduct=' + coalesce(@ActPPProdCode, 'NOProduct') +
					' NxtPPId=' + coalesce(convert(varchar(10), @NxtPPId), 'NoPPId') + 
					' NxtPO=' + coalesce(@NxtPPProcessOrder, 'NOPO') + 
					' NxtProduct=' + coalesce(@NxtPPProdCode, 'NOProduct') +
					' Finish populating the Capacity',
					@pathId
					)
	END

IF @DebugFlagManual = 1
BEGIN
	SELECT	'@tblBOMRMList-Capacity', * 
	FROM	@tblBOMRMListComplete
END



-------------------------------------------------------------------------------
-- Task 3
-- Remove all BOM item which are not PrIME material that needs to be ordered
-- PE_WMS_System = PrIME
-- PE_WMS_IsOrdering = 1
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
--Get prdExecInpus UDP
-------------------------------------------------------------------------------------------------

INSERT @PRDExecInputs (
						PUID,
						PEIID,
						OG,
						PEWMSSystem,
						IsOrdering,
						UseRMScrapFactor,
						RMScrapFactor,
						ParallelConsumption,
						ParallelItemCount
						)
SELECT	pepu.PU_Id, 
		pei.PEI_Id, 
		tfv.Value, 
		tfv2.value,
		CONVERT(bit,tfv3.value),
		CONVERT(bit,tfv4.value),
		CONVERT(float,tfv5.value),
		CONVERT(bit,tfv6.value),
		CONVERT(int,tfv7.value)
FROM dbo.PrdExec_Path_Units pepu		WITH(NOLOCK)
JOIN dbo.PrdExec_Inputs pei				WITH(NOLOCK)	ON pei.PU_Id = pepu.PU_Id
JOIN dbo.Table_Fields_Values tfv		WITH(NOLOCK)	ON tfv.KeyId = pei.PEI_Id AND tfv.Table_Field_Id  = @tfOGId					AND tfv.tableid = @TableIdRMI
LEFT JOIN dbo.Table_Fields_Values tfv2	WITH(NOLOCK)	ON tfv2.KeyId= pei.PEI_Id AND tfv2.Table_Field_Id = @tfPEWMSSystemId		AND tfv2.tableid = @TableIdRMI
LEFT JOIN dbo.Table_Fields_Values tfv3	WITH(NOLOCK)	ON tfv3.KeyId= pei.PEI_Id AND tfv3.Table_Field_Id = @tfIsOrderingId			AND tfv3.tableid = @TableIdRMI
LEFT JOIN dbo.Table_Fields_Values tfv4	WITH(NOLOCK)	ON tfv4.KeyId= pei.PEI_Id AND tfv4.Table_Field_Id = @tfUseRMScrapFactorId	AND tfv4.tableid = @TableIdRMI
LEFT JOIN dbo.Table_Fields_Values tfv5	WITH(NOLOCK)	ON tfv5.KeyId= pei.PEI_Id AND tfv5.Table_Field_Id = @tfRMScrapFactorId		AND tfv5.tableid = @TableIdRMI
LEFT JOIN dbo.Table_Fields_Values tfv6	WITH(NOLOCK)	ON tfv6.KeyId= pei.PEI_Id AND tfv6.Table_Field_Id = @tfParallelConsumptionId AND tfv6.tableid = @TableIdRMI
LEFT JOIN dbo.Table_Fields_Values tfv7	WITH(NOLOCK)	ON tfv7.KeyId= pei.PEI_Id AND tfv7.Table_Field_Id = @tfParallelItemCountId	AND tfv7.tableid = @TableIdRMI
WHERE pepu.Path_Id = @PathId 



IF @DebugFlagManual = 1
BEGIN
	SELECT	'@PRDExecInputs', * 
	FROM	@PRDExecInputs
END

--Clean BOM
DELETE @PRDExecInputs WHERE  PEWMSSystem <> 'PrIME' OR IsOrdering != 1 OR IsOrdering IS NULL
DELETE @tblBOMRMListComplete WHERE BOMRMOG NOT IN (SELECT OG FROM @PRDExecInputs)



IF @DebugFlagManual = 1
BEGIN
	SELECT	'@tblBOMRMListComplete PrIME Only', * 
	FROM	@tblBOMRMListComplete
END





-------------------------------------------------------------------------------
--	Task 4. 
--	Retrieve all Raw Materials at the Staging Location at this Line
-------------------------------------------------------------------------------

INSERT INTO @tblRMInventoryStaging(
			RMEventId, 
			RMEventNum, 
			RMPUId, 
			RMPUDesc, 
			RMInitDimX, 
			RMFinalDimX, 
			RMProdId, 
			RMProdCode,
			RMProdStatusId,
			RMProdStatusStr,
			BOMRMOG,
			RMPPId
			)		
SELECT 	e.Event_Id,
		e.Event_Num,
		e.PU_Id,
		pu.PU_Desc,
		ed.Initial_Dimension_X,
		ed.Final_Dimension_X,
		e.Applied_Product,
		p.Prod_Code,
		ps.ProdStatus_Id,
		ps.ProdStatus_Desc,
		NULL,
		ed.PP_Id
FROM dbo.Events e						WITH(NOLOCK)
LEFT JOIN dbo.Event_Details ed			WITH(NOLOCK) ON (e.Event_Id = ed.Event_Id)
JOIN dbo.Production_Status ps			WITH(NOLOCK) ON (ps.ProdStatus_Id = e.Event_Status)
JOIN dbo.Products_base p				WITH(NOLOCK) ON (p.Prod_Id = e.Applied_Product)
JOIN dbo.Prod_Units_base pu				WITH(NOLOCK) ON (pu.PU_Id = e.PU_Id)
WHERE e.PU_Id IN (SELECT BOMRMStoragePUId FROM @tblBOMRMListComplete)
	AND (e.applied_product IN (SELECT BOMRMProdId FROM @tblBOMRMListComplete UNION SELECT BOMRMSubProdId FROM @tblBOMRMListComplete)) 
	AND (ed.pp_id = @NxtPPId AND (ps.count_For_Production = 1 AND ps.count_For_Inventory = 1)	
		OR
		(ps.count_For_Production = 0 AND ps.count_For_Inventory = 0) 	)
ORDER BY e.TimeStamp

-- In case of SCO, need to remove "To be returned" Pallet with a PP_ID
IF @IsSCOLine = 1
BEGIN
	DELETE @tblRMInventoryStaging WHERE RMEventId IN (		SELECT RMEventId 
															FROM @tblRMInventoryStaging a
															JOIN dbo.events e WITH(NOLOCK) ON e.event_id = a.RMEventId
															WHERE e.event_status = @tobereturnedId
																AND RMPPId IS NOT NULL
												)

END


--Get OG
UPDATE rms
SET BOMRMOG = brl.BOMRMOG
FROM @tblRMInventoryStaging rms
	JOIN @tblBOMRMListComplete brl ON ((brl.BOMRMProdCode = rms.RMProdCode) OR (brl.BOMRMSubProdCode = rms.RMProdCode))


IF @DebugFlagOnLine = 1  
BEGIN
	INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
		VALUES(	getdate(), 
				@SPName,
				'0410' +
				' TimeStamp=' + convert(varchar(25), getdate(), 120) +
				' ActPPId=' + coalesce(convert(varchar(10), @ActPPId), 'NoPPId') + 
				' ActPO=' + coalesce(@ActPPProcessOrder, 'NOPO') + 
				' ActProduct=' + coalesce(@ActPPProdCode, 'NOProduct') +
				' NxtPPId=' + coalesce(convert(varchar(10), @NxtPPId), 'NoPPId') + 
				' NxtPO=' + coalesce(@NxtPPProcessOrder, 'NOPO') + 
				' NxtProduct=' + coalesce(@NxtPPProdCode, 'NOProduct') +
				' Finish populating the Staging',
				@pathId
				)
END


IF @DebugFlagManual = 1
BEGIN
	SELECT	'@tblRMInventoryStaging', * 
	FROM	@tblRMInventoryStaging 
END





-------------------------------------------------------------------------------
	-- 5.	Get the open request 
	--		Update Quantityvalue where it is not defined by PrIME yet
-------------------------------------------------------------------------------
INSERT @Openrequest (OpenTableId,RequestId,RequestTime,LocationId, CurrentLocation,ULID,Batch,ProcessOrder,PrimaryGCAS,AlternateGCAS,GCAS,QuantityValue,QuantityUOM,Status,EstimatedDelivery,
lastUpdatedTime	,userId, eventid	)
-- 1.4
--EXEC dbo.spLocal_CmnPrIMEGetOpenRequests @pathCode,NULL,NULL
SELECT * FROM [dbo].[fnLocal_CmnPrIMEGetOpenRequests](@pathCode)

IF @DebugFlagManual = 1
BEGIN
	SELECT	'@Openrequest Original', * 
	FROM	@Openrequest 
END


--1.15 FO-04067
IF isNull(@FlgPreStagedMaterialRequest,0) >0
--Pre-staged request Implemented on the current Path. Retrieve Un-processed Records from the Table Local_PrIME_PreStaged_Material_Request for the Initiated Process Ordewr

/*
	Mapping between @Openrequest and dbo.Local_PrIME_PreStaged_Material_Request Fields


	OpenTableId			int,			COUNT	(*)
	RequestId			varchar(50),	Not Relevant
	PrimeReturnCode		int,			Not Relevant
	RequestTime			datetime,		SOAEVENTTIMESLOT ???
	LocationId			varchar(50),	BOMRMTNLOCATN
	CurrentLocation		varchar(50),	Not Relevant
	ULID				varchar(50),	Not Relevant
	Batch				varchar(10),	Not Relevant
	ProcessOrder		varchar(50),	PROCESSORDER
	PrimaryGCAS			varchar(50),	BOMRMPRODCODE
	AlternateGCAS		varchar(50),	BOMRMSUBPRODCODE
	GCAS				varchar(50),	BOMRMPRODCODE
	QuantityValue		float,			derived from the @tblBOMRMListComplete.ProductUOMPerPallet
	QuantityUOM			varchar(50),	Irrelevant
	Status				varchar(50),	Shuld be hardcoded i.e. 'RequestMaterial'
	EstimatedDelivery	datetime,		Not Relevant
	lastUpdatedTime		datetime,		Not Relevant  - may use inserted time
	userId				int,			DEFAULTUSERNAME		
	eventId				int				Not Relevant




*/



BEGIN
	
	INSERT	@Openrequest (
			OpenTableId,
			RequestId,
			RequestTime,
			LocationId, 
			CurrentLocation,
			ULID,
			Batch,
			ProcessOrder,
			PrimaryGCAS,
			AlternateGCAS,
			GCAS,
			QuantityValue,
			QuantityUOM,
			Status,
			EstimatedDelivery,
			lastUpdatedTime	,
			userId, 
			eventid	)
	SELECT	1,							-- OpenTableId		(Irrelevant)
			1,							-- RequestId		(Irrelevant)
			lpmr.SOAEVENTTIMESLOT,		-- RequestTime		(Irrelevant)
			lpmr.BOMRMTNLOCATN,			-- LocationId
			lpmr.BOMRMTNLOCATN,			-- CurrentLocation	(irrelevant)
			Null,						-- ULID (irrelevant)
			Null,						-- Batch (irrelevant)
			lpmr.PROCESSORDER,			-- ProcessOrder
			lpmr.BOMRMPRODCODE,			-- PrimaryGCAS
			lpmr.BOMRMSUBPRODCODE,		-- AlternateGCAS
			lpmr.BOMRMPRODCODE,			-- GCAS
			Null,						-- QuantityValue
			Null,						-- QuantityUOM
			'RequestMaterial',			-- Status !!!! ?????? what status should we use
			Null,						-- EstimatedDelivery (Irrelevant)
			lpmr.INSERTEDTIME,			-- lastUpdatedTime
			u.User_Id,					-- userId
			Null						-- eventid (Irrelevant)
	FROM	dbo.Local_PrIME_PreStaged_Material_Request lpmr with (nolock)
	join    dbo.users u on lpmr.DEFAULTUSERNAME = u.Username
	WHERE	lpmr.PROCESSORDER = @NxtPPProcessOrder
	and		lpmr.PROCESSEDTIME Is Null
	and		upper(IsNull(lpmr.STATUS,'')) = upper(@StatusPreStaged)
END 


--set quantityValue where the value is empty
UPDATE @Openrequest 
SET QuantityValue = b.ProductUOMPerPallet
FROM  @Openrequest Op
JOIN @tblBOMRMListComplete b	ON b.BOMRMProdCode = Op.PrimaryGCAS
WHERE QuantityValue IS NULL OR QuantityValue = 1



IF @DebugFlagManual = 1
BEGIN
	SELECT	'@Openrequest With Pre-Staged', * 
	FROM	@Openrequest 
END

-------------------------------------------------------------------------------
--	TASK 6. 
--	6a. Execute the Realtime inventory calculation for each Raw Material
-------------------------------------------------------------------------------


INSERT INTO @tblRMInventoryGroupActual (
		BOMRMOG,
		BOMRMStoragePUDesc,
		BOMRMTNLOCATN,
		BOMRMProdId,
		BOMRMSubProdId,
		BOMRMProdCode,
		BOMRMSubProdCode, 
		ProductGroupCapacity,
		ProductGroupThreshold,
		FlgNewToInitiateOrder,
		BOMRMScrapFactor	)	
SELECT 
		BOMRMOG,
		BOMRMStoragePUDesc,
		PrIMELocation,
		BOMRMProdId,
		BOMRMSubProdId,
		BOMRMProdCode,
		BOMRMSubProdCode, 
		ProductGroupCapacity,
		ProductGroupThreshold,
		FlgNewToInitiateOrder,
		BOMRMScrapFactor	
FROM	@tblBOMRMListComplete
				
If @DebugFlagManual = 1
BEGIN
	SELECT 	'@tblRMInventoryGroupActual', * 
	FROM	@tblRMInventoryGroupActual
END



-------------------------------------------------------------------------------
--	6b.	Update the table for ActualPalletCntTot for each Product Group (material)
--		Actual Pallet = Pallets at Staging + Open Request Pallets
-------------------------------------------------------------------------------
SET @LoopIndex = (SELECT MIN(RMInventoryGrpId) FROM @tblRMInventoryGroupActual)
WHILE @LoopIndex IS NOT NULL
BEGIN
	SELECT  @BOMRMOG			=	NULL,
			@BOMRMStoragePUDesc	=	NULL,
			@BOMRMProdId		=	NULL,
			@BOMRMSubProdId		=	NULL,
			@BOMRMTNLOCATN		=	NULL,
			@BOMRMProdCode		=	NULL,
			@BOMRMSubProdCode	=	NULL

	SELECT	@ActualPalletCntTot			= NULL,	
			@ActualPalletCntStaging		= NULL,
			@ActualPalletCntOpenRequest = NULL,
			@LastRequestStatus			= NULL

	SELECT	@BOMRMOG					=  BOMRMOG,
			@BOMRMStoragePUDesc			=  BOMRMStoragePUDesc,
			@BOMRMTNLOCATN				=  BOMRMTNLOCATN,
			@ProductGroupThreshold		=  ProductGroupThreshold,
			@BOMRMProdId				=  BOMRMProdId,		
			@BOMRMSubProdId				=  BOMRMSubProdId,	
			@BOMRMProdCode				=  BOMRMProdCode,	
			@BOMRMSubProdCode			=  BOMRMSubProdCode
	FROM	@tblRMInventoryGroupActual
	WHERE	RMInventoryGrpId = @LoopIndex

	-- Retrieve all the pallet counts
	SET @ActualPalletCntStaging = (	SELECT	COUNT(*) 
									FROM	@tblRMInventoryStaging
									WHERE	BOMRMOG = @BOMRMOG
											AND	RMPUDesc = @BOMRMStoragePUDesc 
											AND (RMProdId = @BOMRMProdId OR RMProdId = @BOMRMSubProdId ))  

												
												

	SET @ActualPalletCntOpenRequest = ( SELECT	COUNT(OpenTableId) 
										FROM	@Openrequest
										WHERE	LocationId = @BOMRMTNLOCATN 
												AND primaryGCAS = @BOMRMProdCode )
	
	SET @LastRequestStatus = (SELECT TOP 1 Status
								FROM @Openrequest
								WHERE	LocationId = @BOMRMTNLOCATN 
										AND primaryGCAS = @BOMRMProdCode 
								ORDER BY RequestTime DESC);

	IF exists (SELECT Status FROM @Openrequest
		WHERE	LocationId = @BOMRMTNLOCATN 
		AND primaryGCAS = @BOMRMProdCode  AND status ='Short') 
	BEGIN
		SET  @LastRequestStatus =  'Short'
	END

	SET @ActualPalletCntTot =	coalesce(@ActualPalletCntStaging,0) + 
								coalesce(@ActualPalletCntOpenRequest,0)

	UPDATE @tblRMInventoryGroupActual
	SET ActualPalletCntStaging	= coalesce(@ActualPalletCntStaging,0),
		ActualPalletCntOpenRequest= coalesce(@ActualPalletCntOpenRequest,0),
		ActualPalletCntTot =  @ActualPalletCntTot,
		FlgThresholdGTActual = CASE 
									WHEN @ProductGroupThreshold >= @ActualPalletCntTot THEN 1
									ELSE 0
								END,
		LastRequestStatus = @LastRequestStatus
	WHERE RMInventoryGrpId = @LoopIndex


	SET @LoopIndex = (SELECT MIN(RMInventoryGrpId) FROM @tblRMInventoryGroupActual WHERE RMInventoryGrpId > @LoopIndex)
END



IF @DebugFlagOnLine = 1  
	BEGIN
		INSERT INTO Local_Debug([Timestamp], CallingSP, [Message], Msg)
					VALUES(	getdate(), 
					@SPNAME,
					'0610' +
					' Finish Updating the Actual Pallet Cnt',
					@pathid
					)
	END

IF @DebugFlagManual = 1
BEGIN
	SELECT	'@tblRMInventoryGroupActual', * 
	FROM	@tblRMInventoryGroupActual
END



-------------------------------------------------------------------------------
-- 6c. Loop through the Product Group which has FlgThresholdGTActual = 1
-------------------------------------------------------------------------------
SET @LoopIndex  =(SELECT MIN(RMInventoryGrpId) FROM @tblRMInventoryGroupActual)

WHILE @LoopIndex IS NOT NULL
BEGIN
	--reset variables
	SELECT	@BOMRMOG					=	NULL,
			@BOMRMStoragePUDesc			=	NULL,
			@BOMRMProdId				=	NULL,
			@BOMRMSubProdId				=	NULL,
			@BOMRMTNLOCATN				=	NULL,
			@BOMRMProdCode				=	NULL,
			@BOMRMSubProdCode			=	NULL,
			@ProductGroupCapacity		=   NULL,
			@ProductGroupThreshold		=   NULL,
			@ActualPalletCntTot			=   NULL,
			@FlgNewToInitiateOrder		=   NULL,
			@UseRMScrapFactor			=   NULL,
			@RMScrapFactor				=   NULL,
			@BOMRMScrapFactor			=   NULL,
			@OpenRequestPalletCnt		=	NULL,
			@LastRequestStatus			=	NULL
			
	SELECT	@BOMRMOG					=  BOMRMOG,
			@BOMRMStoragePUDesc			=  BOMRMStoragePUDesc,
			@BOMRMTNLOCATN				=  BOMRMTNLOCATN,
			@ProductGroupCapacity		=  ProductGroupCapacity,
			@ProductGroupThreshold		=  ProductGroupThreshold,
			@ActualPalletCntTot			=  ActualPalletCntTot,
			@FlgNewToInitiateOrder		=  FlgNewToInitiateOrder,
			@BOMRMProdId				=  BOMRMProdId,	
			@BOMRMSubProdId				=  BOMRMSubProdId,	
			@BOMRMScrapFactor			=  BOMRMScrapFactor,
			@OpenRequestPalletCnt		=  ActualPalletCntOpenRequest,
			@LastRequestStatus			=  LastRequestStatus
	FROM	@tblRMInventoryGroupActual
	WHERE	RMInventoryGrpId = @LoopIndex

	INSERT INTO @tblRMInventoryQtyCalc (
				PPId,
				ProcessOrder,
				PPStatusStr,
				BOMRMProdId,
				BOMRMProdCode,
				BOMRMQty,
				BOMRMEngUnitDesc,
				BOMRMOG,
				BOMRMStoragePUDesc,		
				BOMRMTNLOCATN,
				ProductGroupCapacity,
				ProductUOMPerPallet,
				BOMRMSubProdId,
				BOMRMSubProdCode,
				BOMRMSubEngUnitId,
				BOMRMSubEngUnitDesc,
				BOMRMSubConversionFactor,
				BOMRMScrapFactor )
	SELECT	PPId,
			ProcessOrder,
			PPStatusStr,
			BOMRMProdId,
			BOMRMProdCode,
			BOMRMQty,
			BOMRMEngUnitDesc,
			BOMRMOG,
			BOMRMStoragePUDesc,		
			PrIMELocation,
			ProductGroupCapacity,
			ProductUOMPerPallet,
			BOMRMSubProdId,
			BOMRMSubProdCode,
			BOMRMSubEngUnitId,
			BOMRMSubEngUnitDesc,
			BOMRMSubConversionFactor,
			BOMRMScrapFactor
	FROM	@tblBOMRMListComplete
	WHERE	BOMRMOG = @BOMRMOG
			AND BOMRMStoragePUDesc = @BOMRMStoragePUDesc
			AND BOMRMProdId = @BOMRMProdId


	--Reset variables
	SELECT	@ActRequiredBOMRMUOMQty			= NULL,
			@NxtRequiredBOMRMUOMQty			= NULL,	
			@ActualPalletCntStaging			= NULL,
			@ActualUOMQtyStaging			= NULL,
			@ActualPalletCntOpenRequest		= NULL,
			@ActualUOMQtyOpenRequest		= NULL,
			@ActualPalletCntStagingSub		= NULL,
			@ActualUOMQtyStagingSub			= NULL,
			@ActualUOMQtyTot				= NULL,	
			@NeededUOMQty					= NULL,	
			@NeededPalletCnt				= NULL,	
			@FinalNeededPalletCnt			= NULL,	
			@ActFinalNeededPalletCnt		= NULL		



	SELECT	@UseRMScrapFactor	=  UseRMScrapFactor,
			@RMScrapFactor		=  RMScrapFactor
	FROM	@PRDExecInputs
	WHERE	OG = @BOMRMOG

	SELECT	@BOMRMQty					= BomRMQTY,
			@BOMRMQtyOR					= BomRMQTY,
			@BOMRMProdId				= BOMRMProdId,
			@BOMRMProdCode				= BOMRMProdCode,
			@BOMRMEngUnitDesc			= BOMRMEngUnitDesc,
			@ProductUOMPerPallet		= ProductUOMPerPallet,
			@ProductGroupCapacity		= ProductGroupCapacity,
			@BOMRMStoragePUDesc			= BOMRMStoragePUDesc,		
			@BOMRMTNLOCATN				= BOMRMTNLOCATN,
			@BOMRMSubProdId				= BOMRMSubProdId,
			@BOMRMSubProdCode			= BOMRMSubProdCode,
			@BOMRMSubConversionFactor	= BOMRMSubConversionFactor,
			@BOMRMScrapFactor			= BOMRMScrapFactor,
			@BOMRMSubEngUnitDesc		= BOMRMSubEngUnitDesc
	FROM	@tblRMInventoryQtyCalc
	WHERE	PPStatusStr IN( @StatusStrNext,@StatusStrReady) 


	--Add BOM scrap factor
	IF @UsePathScrapFactor = 1 AND @BOMRMScrapFactor != 0 AND @BOMRMScrapFactor IS NOT NULL
	BEGIN
			SELECT	@BOMRMQty = BomRMQTY * (1+@BOMRMScrapFactor/100)
			FROM	@tblRMInventoryQtyCalc
			WHERE	PPStatusStr IN( @StatusStrNext,@StatusStrReady)   
	END
		
	--add RMI scrap factor
	SELECT	@BOMRMQty		=
			CASE @UseRMScrapFactor
			WHEN 0 THEN @BOMRMQty
			WHEN 1 THEN  @BOMRMQty + (@BOMRMQtyOR  * (@RMScrapFactor/100))       
			ELSE @BOMRMQty 
		END
	FROM	@tblRMInventoryQtyCalc
	WHERE	PPStatusStr IN( @StatusStrNext,@StatusStrReady)		

	--get prod_desc
	SET @BOMRMProdDesc = (	SELECT	Prod_Desc
					FROM	dbo.Products_base  WITH(NOLOCK)
					WHERE	Prod_Id = @BOMRMProdId)

	-- count requ qty
	UPDATE @tblRMInventoryQtyCalc
	SET RemainingProdCnt = Coalesce(@NxtPPPlannedQty,0),
		FPStandardQty	= Coalesce(@NxtFPStandardQty,0),
		RequiredBOMRMUOMQty = @NxtPPPlannedQty * @BOMRMQty /  @NxtFPStandardQty
	WHERE PPStatusStr IN( @StatusStrNext,@StatusStrReady) 
		AND BOMRMProdId = @BOMRMProdId	


	SET @NxtRequiredBOMRMUOMQty = @NxtPPPlannedQty * @BOMRMQty /  @NxtFPStandardQty

	IF @DebugFlagManual = 1
	BEGIN
		SELECT	@LoopIndex			As LoopIndex,
				@BomRMOG			AS OG,
				@NxtPPPlannedQty	AS NxtPPPlannedQty,
				@NxtFPStandardQty	AS NxtFPStandardQty,
				@BOMRMQty			AS BOMRMQty,
				@StatusStrNext		AS StatusStrNext,
				@NxtRequiredBOMRMUOMQty As NxtRequiredBOMRMUOMQty
	END



-------------------------------------------------------------------------------			
	-- Available Pallets and UOM Qty for Primary Materials
-------------------------------------------------------------------------------
	SELECT	@ActualPalletCntStaging	= count(*),
			@ActualUOMQtyStaging = coalesce(SUM(coalesce(RMFinalDimX,0)) ,0)
	FROM	@tblRMInventoryStaging
	WHERE	RMProdId = @BOMRMProdId
			AND	RMPUDesc = @BOMRMStoragePUDesc				
			
			
	SELECT	@ActualPalletCntOpenRequest = count(*), -- 1.2
			@ActualUOMQtyOpenRequest = coalesce(SUM(coalesce(QuantityValue,0)),0)
	FROM	@openRequest
	WHERE	PrimaryGCAS = @BOMRMProdCode
			AND	LocationId = @BOMRMTNLOCATN 

-------------------------------------------------------------------------------			
	-- Available Pallets and UOM Qty for Alternate Materials
-------------------------------------------------------------------------------
	IF @BOMRMSubProdCode IS NOT NULL
	BEGIN
		SELECT	@ActualPalletCntStagingSub = count(*),
				@ActualUOMQtyStagingSub = coalesce(sum(coalesce(RMFinalDimX,0)),0)* @BOMRMSubCOnversionFactor 
		FROM	@tblRMInventoryStaging
		WHERE	RMProdId = @BOMRMSubProdId
				AND	RMPUDesc = @BOMRMStoragePUDesc	
	END

-------------------------------------------------------------------------------	
	--Official inventroy Counts
-------------------------------------------------------------------------------
	SELECT @ActualUOMQtyTot =	coalesce(@ActualUOMQtyStaging,0) + 
								coalesce(@ActualUOMQtyOpenRequest,0) +
								coalesce(@ActualUOMQtyStagingSub,0)
			
	UPDATE @tblRMInventoryQtyCalc
	SET		ActualPalletCntStaging = Coalesce(@ActualPalletCntStaging,0) + Coalesce(@ActualPalletCntStagingSub,0),
			ActualUOMQtyStaging = Coalesce(@ActualUOMQtyStaging,0) + Coalesce(@ActualUOMQtyStagingSub,0),
			ActualPalletCntOpenRequest = Coalesce(@ActualPalletCntOpenRequest,0),
			ActualUOMQtyOpenRequest =Coalesce( @ActualUOMQtyOpenRequest,0)				
	WHERE	PPStatusStr IN( @StatusStrNext,@StatusStrReady)  	
			AND BOMRMProdId = @BOMRMProdId		


	SET @ActualOldestORTime			= ( SELECT MIN(RequestTime)
										FROM	@Openrequest
										WHERE	LocationId = @BOMRMTNLOCATN 		
											AND PrimaryGCAS = @BOMRMProdCode )


	IF @ActualOldestORTime IS NOT NULL
		SET @ActualOrderSinceMinute = (SELECT DATEDIFF(mi, @ActualOldestORTime, @CurrentTime))
	ELSE
		SET @ActualOrderSinceMinute = 0





	------------------------------------------------------------------------
	--Check what type of material (PCM or Standatrd)
	-----------------------------------------------------------------------
	IF (SELECT TOP 1 COALESCE(parallelConsumption,0) FROM @PRDExecInputs WHERE OG = @BOMRMOG ) =1
	BEGIN

		IF @DebugFlagOnLine = 1  
		BEGIN
			INSERT INTO Local_Debug([Timestamp], CallingSP, [Message], Msg)
						VALUES(	getdate(), 
						@SPNAME,
						'0620' +
						' PCM',
						@pathid
						)
		END



		----------------------------------------------------------------
		--PCM Section
		----------------------------------------------------------------
		--Reset variables
		SELECT	@LoadedQtyPos				= NULL,
				@LoadedCountPos				= NULL,
				@NeededQtyPos				= NULL,
				@NeededCountPos				= NULL,
				@TotalLoadedQty				= 0,
				@TotalLoadedCount			= 0,
				@TotalNeededQty				= 0,
				@TotalNeededCount			= 0,
				@CountPositionFilled		= 0,
				@FinalNeededQtyPos			= NULL,
				@FinalNeededCountPos		= NULL,
				@TotalFinalNeededQty		= 0,
				@TotalFinalNeededCount		= 0



		SET @CountPosition = (SELECT TOP 1 parallelItemCount FROM @PRDExecInputs WHERE OG = @BOMRMOG)

		--Qty required per position
		SET @NxtRequiredBOMRMUOMQtyPos = @NxtRequiredBOMRMUOMQty / @CountPosition  --required per position

		
		--we need to check based on the actualUOM quantity
		SET @ThresholdInUOM = 0
		SET @ThresholdInUOM = @ProductUOMPerPallet*@ProductGroupThreshold

		IF @DebugFlagOnLine = 1  
		BEGIN
			INSERT INTO Local_Debug([Timestamp], CallingSP, [Message], Msg)
						VALUES(	getdate(), 
						@SPNAME,
						'0630' +
						' Count Pos = ' + CONVERT(varchar(30),@CountPosition) +
						' NxtRequiredBOMRMUOMQty = ' + CONVERT(varchar(30),@NxtRequiredBOMRMUOMQtyPos)  ,
						@pathid
						)
		END

		


		--Loop thru all PCM position
		SET	@peiid = (SELECT MIN(peiid) FROM @PRDExecInputs WHERE OG = @BOMRMOG)
		WHILE @peiid IS NOT NULL
		BEGIN
			IF @DebugFlagOnLine = 1  
			BEGIN
				INSERT INTO Local_Debug([Timestamp], CallingSP, [Message], Msg)
							VALUES(	getdate(), 
							@SPNAME,
							'0631' +
							' pei_id = ' + CONVERT(varchar(30),@peiid) ,
							@pathid
							)
			END

			SELECT	@LoadedCountPos = COALESCE(COUNT(ie.event_id),0),
					@LoadedQtyPos = COALESCE(SUM(i.RMFinalDimX),0)
			FROM @tblRMInventoryStaging i
			JOIN dbo.prdExec_input_event ie	WITH(NOLOCK) on i.RMEventId = ie.event_id
			WHERE ie.pei_id = @peiid

			IF @DebugFlagOnLine = 1  
			BEGIN
				INSERT INTO Local_Debug([Timestamp], CallingSP, [Message], Msg)
							VALUES(	getdate(), 
							@SPNAME,
							'0632' +
							' @LoadedCountPos = ' + CONVERT(varchar(30),@LoadedCountPos) +
							' @LoadedQtyPos= ' + CONVERT(varchar(30),@LoadedQtyPos)  ,
							@pathid
							)
			END


			IF @LoadedCountPos IS NULL 
				SET @LoadedCountPos = 0

			IF @LoadedQtyPos IS NULL	
				SET @LoadedQtyPos = 0

			--Increment the position filled counter
			IF @LoadedCountPos > 0
				SET @CountPositionFilled = @CountPositionFilled +1
			

			SET @NeededQtyPos = COALESCE(@NxtRequiredBOMRMUOMQtyPos,0) - COALESCE(@LoadedQtyPos,0)
			IF @NeededQtyPos < 0
			BEGIN
				SET	@NeededQtyPos = 0	
			END

			SET @FinalNeededQtyPos = @NeededQtyPos
			SET @FinalNeededCountPos = CEILING (@FinalNeededQtyPos/@ProductUOMPerPallet)	

			IF @DebugFlagOnLine = 1  
			BEGIN
				INSERT INTO Local_Debug([Timestamp], CallingSP, [Message], Msg)
							VALUES(	getdate(), 
							@SPNAME,
							'0633' +
							' @FinalNeededQtyPos = ' + CONVERT(varchar(30),@FinalNeededQtyPos) +
							' @ThresholdInUOM= ' + CONVERT(varchar(30),@ThresholdInUOM) +
							' @NeededQtyPos = ' + CONVERT(varchar(30),@NeededQtyPos),
							@pathid
							)
			END


			IF @LoadedQtyPos < @ThresholdInUOM
			BEGIN
				SET @FinalNeededQtyPos = COALESCE(@ThresholdInUOM,0) - COALESCE(@LoadedQtyPos,0)
				IF @FinalNeededQtyPos > @NeededQtyPos
					SET @FinalNeededQtyPos = @NeededQtyPos
				IF @FinalNeededQtyPos < 0
					SET @FinalNeededQtyPos = 0

				SET @FinalNeededCountPos = ceiling(@FinalNeededQtyPos/@ProductUOMPerPallet)	

			END
			



			IF @DebugFlagOnLine = 1  
			BEGIN
				INSERT INTO Local_Debug([Timestamp], CallingSP, [Message], Msg)
							VALUES(	getdate(), 
							@SPNAME,
							'0634' +
							' @FinalNeededCountPos= ' + CONVERT(varchar(30),@FinalNeededCountPos)  ,
							@pathid
							)
			END


			IF @NeededQtyPos < 0 OR @NeededQtyPos IS NULL
				SET @NeededQtyPos = 0

			IF @NeededCountPos < 0 OR @NeededCountPos IS NULL
				SET @NeededCountPos = 0

			SET @NeededCountPos = CEILING(@NeededQtyPos/@ProductUOMPerPallet)	

		IF @DebugFlagOnLine = 1  
			BEGIN
				INSERT INTO Local_Debug([Timestamp], CallingSP, [Message], Msg)
							VALUES(	getdate(), 
							@SPNAME,
							'0634.5' +
							' @NeededCountPos= ' + CONVERT(varchar(30),@NeededCountPos)  ,
							@pathid
							)
			END


			SELECT 	@TotalLoadedQty				= COALESCE(@TotalLoadedQty,0)	+ COALESCE(@LoadedQtyPos,0),
					@TotalLoadedCount			= COALESCE(@TotalLoadedCount,0) + COALESCE(@LoadedCountPos,0),
					@TotalNeededQty				= COALESCE(@TotalNeededQty,0)	+ COALESCE(@NeededQtyPos,0),
					@TotalNeededCount			= COALESCE(@TotalNeededCount,0) + COALESCE(@NeededCountPos,0),
					@TotalFinalNeededCount		= COALESCE(@TotalFinalNeededCount,0) + COALESCE(@FinalNeededCountPos,0) 

			IF @DebugFlagOnLine = 1  
			BEGIN
				INSERT INTO Local_Debug([Timestamp], CallingSP, [Message], Msg)
							VALUES(	getdate(), 
							@SPNAME,
							'0635' +
							' @TotalLoadedQty= ' + CONVERT(varchar(30),@TotalLoadedQty)  + 
							' @TotalLoadedCount= ' + CONVERT(varchar(30),@TotalLoadedCount)  + 
							' @TotalNeededQty= ' + CONVERT(varchar(30),@TotalNeededQty)  + 
							' @TotalNeededCount= ' + CONVERT(varchar(30),@TotalNeededCount)  + 
							' @TotalFinalNeededCount= ' + CONVERT(varchar(30),@TotalFinalNeededCount) ,
							@pathid
							)
			END

			SET	@peiid = (SELECT MIN(peiid) FROM @PRDExecInputs WHERE OG = @BOMRMOG AND peiid > @peiid)
		END
		
		
		--check if we need to order
		IF @TotalFinalNeededCount > 0
		BEGIN
			IF @DebugFlagOnLine = 1  
			BEGIN
				INSERT INTO Local_Debug([Timestamp], CallingSP, [Message], Msg)
							VALUES(	getdate(), 
							@SPNAME,
							'0636' +
							' @ProductGroupCapacity= ' + CONVERT(varchar(30),@ProductGroupCapacity)  + 
							' @ActualPalletCntStaging= ' + CONVERT(varchar(30),COALESCE(@ActualPalletCntStaging,-9999))  + 
							' @ActualPalletCntOpenRequest= ' + CONVERT(varchar(30),COALESCE(@ActualPalletCntOpenRequest,-9999))  + 
							' @ActualPalletCntStagingSub= ' + CONVERT(varchar(30),COALESCE(@ActualPalletCntStagingSub,-9999))  ,
							@pathid
							)
			END
			
			
			--Can we order to capacity
			IF @TotalNeededCount > @ProductGroupCapacity
			BEGIN
				--fill all places possible
				SET @TotalFinalNeededCount = @ProductGroupCapacity - COALESCE(@ActualPalletCntStaging,0) - COALESCE(@ActualPalletCntOpenRequest,0)- COALESCE(@ActualPalletCntStagingSub,0)
			END
			ELSE
			BEGIN
				SET @TotalFinalNeededCount = @TotalNeededCount
			END
		END

		IF @DebugFlagOnLine = 1  
		BEGIN
			INSERT INTO Local_Debug([Timestamp], CallingSP, [Message], Msg)
						VALUES(	getdate(), 
						@SPNAME,
						'0650' +
						' @TotalFinalNeededCount= ' + CONVERT(varchar(30),@TotalFinalNeededCount)  + 
						' @ProductGroupCapacity= ' + CONVERT(varchar(30),@ProductGroupCapacity)   ,
						@pathid
						)
		END	
		
			
		--Count existing pallet not loaded 
		SET @TotalNotLoadedCount = coalesce(@ActualPalletCntStaging,0)  + coalesce(@ActualPalletCntOpenRequest,0)  +coalesce(@ActualPalletCntStagingSub,0)  - coalesce(@TotalLoadedCount,0) 

		--Count existing qty not loaded 
		SET @TotalNotLoadedQty = coalesce(@ActualUOMQtyStaging,0)  + coalesce(@ActualUOMQtyOpenRequest,0)+coalesce(@ActualUOMQtyStagingSub,0)	 -  coalesce(@TotalLoadedQty,0)


		IF @DebugFlagOnLine = 1  
		BEGIN
			INSERT INTO Local_Debug([Timestamp], CallingSP, [Message], Msg)
						VALUES(	getdate(), 
						@SPNAME,
						'0655' +
						' @TotalNeededQty= ' + CONVERT(varchar(30),@TotalNeededQty)  + 
						' @TotalNotLoadedQty= ' + CONVERT(varchar(30),@TotalNotLoadedQty) +
						' @TotalNeededCount= ' + CONVERT(varchar(30),@TotalNeededCount)  + 
						' @TotalNotLoadedCount= ' + CONVERT(varchar(30),@TotalNotLoadedCount)   ,
						@pathid
						)
		END	






			
		SELECT	@NeededUOMQty			= @TotalNeededQty - @TotalNotLoadedQty,
				@NeededPalletCnt		= @TotalNeededCount	- @TotalNotLoadedCount,
				@FinalNeededUOMQty		= (@TotalFinalNeededCount- @TotalNotLoadedCount) * @ProductUOMPerPallet,
				@FinalNeededPalletCnt	= @TotalFinalNeededCount-@TotalNotLoadedCount  --1.14
			
				IF @NeededUOMQty < 0
					SET @NeededUOMQty = 0

				IF @NeededPalletCnt < 0
					SET @NeededPalletCnt = 0

				IF @FinalNeededUOMQty < 0
					SET @FinalNeededUOMQty = 0

				IF @FinalNeededPalletCnt < 0
					SET @FinalNeededPalletCnt = 0



		IF @DebugFlagOnLine = 1  
		BEGIN
			INSERT INTO Local_Debug([Timestamp], CallingSP, [Message], Msg)
						VALUES(	getdate(), 
						@SPNAME,
						'0660' +
						' @NeededUOMQty= ' + CONVERT(varchar(30),@NeededUOMQty)  + 
						' @NeededPalletCnt= ' + CONVERT(varchar(30),@NeededPalletCnt) +
						' @FinalNeededUOMQty= ' + CONVERT(varchar(30),@FinalNeededUOMQty)  + 
						' @FinalNeededPalletCnt= ' + CONVERT(varchar(30),@FinalNeededPalletCnt)   ,
						@pathid
						)
		END		

		
		--Establish threshold in UOM based on allposition together
		SET @ThresholdInUOM = @ThresholdInUOM*@countPosition

		----------------------------------------------------------------
		--end of PCM Section
		----------------------------------------------------------------
	END
	ELSE
	BEGIN

		----------------------------------------------------------------
		--Start of Standard Section
		----------------------------------------------------------------

		-------------------------------------------------------------------------------			
		-- Calculated the NeededUOMQty and NeededPalletCnt
		-------------------------------------------------------------------------------

		SET @NeededUOMQty = coalesce(@ActRequiredBOMRMUOMQty,0) + coalesce(@NxtRequiredBOMRMUOMQty,0) - @ActualUOMQtyTot
				
		IF @NeededUOMQty < 0
		BEGIN
			SELECT @FinalNeededUOMQty = 0
			SET		@NeededUOMQty = 0	
		END
		ELSE
		BEGIN
			SELECT @FinalNeededUOMQty = @NeededUOMQty
		END

		--we need to check based on the actualUOM quantity
		SET @ThresholdInUOM = 0
		SET @ThresholdInUOM = @ProductUOMPerPallet*@ProductGroupThreshold

		SET @NeededPalletCnt = ceiling(@NeededUOMQty/@ProductUOMPerPallet)	


		IF @ActualUOMQtyTot < @ThresholdInUOM
		BEGIN
			SET @FinalNeededUOMQty = @ThresholdInUOM - @ActualUOMQtyTot
			IF @FinalNeededUOMQty > @NeededUOMQty
				SET @FinalNeededUOMQty = @NeededUOMQty

			IF @FinalNeededUOMQty < 0
				SET @FinalNeededUOMQty = 0

			SET @FinalNeededPalletCnt = @ProductGroupCapacity - (@ActualPalletCntTot)

			SET @OrderedQtyUOM = @FinalNeededPalletCnt * @ProductUOMPerPallet
			SET @FinalNeededUOMQty = @OrderedQtyUOM

			--Verify if the requested pallet will be sufficient
			IF @ThresholdInUOM IS NOT NULL AND @ActualUOMQtyTot IS NOT NULL AND  @OrderedQtyUOM IS NOT NULL  --Insure not an endless loop
			BEGIN
				WHILE @ThresholdInUOM > @ActualUOMQtyTot + @OrderedQtyUOM
				BEGIN
					SET @FinalNeededPalletCnt = @FinalNeededPalletCnt + 1
					SET @OrderedQtyUOM = @FinalNeededPalletCnt * @ProductUOMPerPallet
				END
			END


			IF @FinalNeededPalletCnt > @NeededPalletCnt
			BEGIN
				SET @FinalNeededPalletCnt = @NeededPalletCnt
			END

		END
		ELSE
		BEGIN
			SELECT	@FinalNeededPalletCnt	= 0,
					@FinalNeededUOMQty		= 0
 		END


			
		SET @FinalNeededUOMQty = @FinalNeededPalletCnt * @ProductUOMPerPallet 

		----------------------------------------------------------------
		--End of Standard Section
		----------------------------------------------------------------
	END





	-------------------------------------------------------------------------------
	-- Debugging display					
	-------------------------------------------------------------------------------
	IF @DebugFlagManual = 1
	BEGIN
		SELECT	@BOMRMOG						AS BOMRMOG,
				@BOMRMStoragePUDesc				AS BOMRMStoragePUDesc,
				@BOMRMProdCode					AS BOMRMProdCode,
				@BOMRMProdDesc					AS BOMRMProdDesc,
				@BOMRMSubProdCode				AS BOMRMSubProdCode,
				@ActRequiredBOMRMUOMQty			AS ActBOMRMPlannedQty,
				@NxtRequiredBOMRMUOMQty			AS NxtBOMRMPlannedQty,
				@ActualUOMQtyOpenRequest		AS ActualUOMQtyOpenRequest,
				@ActualPalletCntOpenRequest		AS ActualPalletCntOpenRequest,
				@ActualUOMQtyStaging			AS ActualUOMQtyStaging,
				@ActualPalletCntStaging			AS ActualPalletCntStaging,
				@ActualUOMQtyStagingSub			AS ActualUOMQtyStagingSub,
				@ActualPalletCntStagingSub		AS ActualPalletCntStagingSub,							
				@ActualUOMQtyTot				AS ActualUOMQtyTot,
				@ActualPalletCntTot				AS ActualPalletCntTot,
				@ProductGroupCapacity			AS ProductGroupCapacity, 
				@ProductGroupThreshold			AS ProductGroupThreshold,
				@NeededUOMQty					AS NeededUOMQty,
				@NeededPalletCnt				AS NeededPalletCnt,
				@FinalNeededUOMQty				AS FinalNeededUOMQty,
				@FinalNeededPalletCnt			AS FinalNeededPalletCnt,
				@ProductUOMPerPallet			AS ProductUOMPerPallet,
				@FlgNewToInitiateOrder			AS FlgNewTointiateOrder,
				@LastRequestStatus				AS LastRequestStatus
	END

	INSERT INTO @tblWFRequestMaterial 
		(	RMOG,
			BOMRMStoragePUDesc,
			RMProdCode,
			RMProdDesc,	
			RMSubProdCode,	
			RMPlannedQty,
			RMOpenRequestUOMQty,	
			RMOpenRequestPalletCnt,	
			RMStagingUOMQty,	
			RMStagingPalletCnt,	
			RMStagingUOMQtySub,	
			RMStagingPalletCntSub,						
			RMUOMQtyTotal,	
			RMPalletCntTotal,	
			RMStagingCapacityPallet,
			RMThresholdCapacity,	
			RMNeededUOMQty,	
			RMNeededPalletCnt,	
			RMRequestUOMQTY,	
			RMRequestPalletCnt,									
			RMUOMPerPallet,	
			FlgNewToInitiateOrder,
			PrimeLocation,
			ThresholdInUOM,
			ActualOrderSinceMinute,
			RMSubEngUnitDesc,
			LastRequestStatus
			)
	VALUES(
			@BOMRMOG,
			@BOMRMStoragePUDesc,
			@BOMRMProdCode,
			@BOMRMProdDesc,
			@BOMRMSubProdCode,
			@NxtRequiredBOMRMUOMQty,	
			@ActualUOMQtyOpenRequest,
			@ActualPalletCntOpenRequest,
			@ActualUOMQtyStaging,	
			@ActualPalletCntStaging,
			@ActualUOMQtyStagingSub,	
			@ActualPalletCntStagingSub,
			@ActualUOMQtyTot,	
			@ActualPalletCntTot,
			@ProductGroupCapacity,	
			@ProductGroupThreshold,	
			@NeededUOMQty,	
			@NeededPalletCnt,	
			@FinalNeededUOMQty,
			@FinalNeededPalletCnt,
			@ProductUOMPerPallet,	
			@FlgNewToInitiateOrder,
			@BOMRMTNLOCATN,
			@ThresholdInUOM,
			@ActualOrderSinceMinute,
			@BOMRMSubEngUnitDesc,
			@LastRequestStatus)


	--reset table
	DELETE FROM @tblRMInventoryQtyCalc

	SET @LoopIndex = (SELECT MIN(RMInventoryGrpId) FROM @tblRMInventoryGroupActual WHERE RMInventoryGrpId > @LoopIndex)
END



IF @DebugFlagOnLine = 1  
BEGIN
	INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
		VALUES(	getdate(), 
				@spnAME,
				'0800' +
				' Finish populating the @tblWFRequestMaterial ',
				@pathid
				)
END


IF @DebugFlagManual = 1
BEGIN
	SELECT	'tblWFCRequestMaterial ', * 
	FROM	@tblWFRequestMaterial 
END


--- update inventory availibity
UPDATE @tblWFRequestMaterial
SET Inventoryavailibilty = 'N'																					   
WHERE  UPPER(LastRequestStatus) = 'SHORT' OR  UPPER(LastRequestStatus) = 'FAILED'  OR  UPPER(LastRequestStatus) = 'REQUESTMATERIALPENDING' 


UPDATE @tblWFRequestMaterial
SET Inventoryavailibilty = 'Y'
WHERE  UPPER(LastRequestStatus) <> 'SHORT' AND  UPPER(LastRequestStatus) <> 'FAILED'  AND UPPER(LastRequestStatus) <> 'REQUESTMATERIALPENDING' 
--Final output
SELECT	
	PrimeLocation				AS Location,				
	RMOG						AS OriginGroup,
	RMProdCode					AS Material,
	RMProdDesc					AS MaterialDesc,
	RMSubProdCode				AS AltMaterial,
	RMRequestUOMQTY				AS OrderUOMQty,
	RMRequestPalletCnt			AS SuggestedQty,
	ActualOrderSinceMinute		AS OrderedSince,
	RMStagingCapacityPallet		AS StagingCapacityPallet,
	RMNeededPalletCnt			AS StillNeededPallet,
	RMThresholdCapacity			AS ThresholdPallet,
	ThresholdInUOM				AS ThresholdInUOM,
	RMPlannedQty				AS PlannedQty,
	RMOpenRequestUOMQty			AS OpenRequestUOMQty,
	RMOpenRequestPalletCnt		AS OpenRequestPalletCnt,
	Inventoryavailibilty		AS RTCISInventory,
	coalesce(RMStagingUOMQty,0)+coalesce(RMStagingUOMQtySub,0)						AS StagingUOMQty,
	coalesce(RMStagingPalletCnt,0)+coalesce(RMStagingPalletCntSub,0)				AS StagingPalletCnt,
	RMSubEngUnitDesc			AS QuantityUoM,
	LastRequestStatus		AS LastRequestStatus
	FROM @tblWFRequestMaterial


ErrCode:

IF @DebugFlagOnLine = 1  
BEGIN
	INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
		VALUES(	getdate(), 
				@SPName,
				'0999' +

				' Finished',
				@PathId
				)
END




SET NOcount OFF

RETURN

