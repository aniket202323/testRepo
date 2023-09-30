
--------------------------------------------------------------------------------------------------
-- Stored Procedure: spLocal_CmnWFPrIMEStartupMaterialRequest_WIP
--------------------------------------------------------------------------------------------------
-- Author				: Ugo Lapierre, Symasol
-- Date created			: 17-Aug-2018	
-- Version 				: Version <1.0>
-- SP Type				: Workflow
-- Caller				: Called by PE:OrderChnageOver workflow
-- Description			: This Stored Procedure is to request the PrIME Material during Startup
-- Editor tab spacing	: 4
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ========		====	  		====					=====
-- 1.0			17-Aug-2018		U.Lapierre				Original
-- 1.1			7-Sep-2018		U. Lapierre				Insert into local_tblMaterialrequests table
-- 1.2			14-Sep-2018		Julien B. Ethier		Removed ActualUOMQtyPreStaging field
-- 1.3			10-10-2018		U.Lapierre				PCM (FO-03511)
-- 1.4			2018-11-08		L.hudon					add primereturn code from openrequest 
-- 1.5			2019-02-20		U.Lapierre				FO-03557.  Prevent request for C/O material  primary material if it is the alternate material of Active order	
-- 1.6			2019-08-20		U.Lapierre				FO-03832.  Order kanban type 2 material when PO is initiated. Exclude Kanban Type 2 fro standard ordering. 
-- 1.7			2019-08-28		U.Lapierre				FO-03832.  Replace UDP KanbanOrderingType by OrderingType
-- 1.8			2019-09-23		Sasha Metlitski			FO-04067. Introduce Pre-Staged Material Request for PrIME Sites
/*---------------------------------------------------------------------------------------------
Testing Code

exec dbo.spLocal_CmnWFPrIMEStartupMaterialRequest_WIP 150, 'System.PE', 1, 0

select * from prdexec_paths
-----------------------------------------------------------------------------------------------*/


--------------------------------------------------------------------------------
CREATE PROCEDURE				[dbo].[spLocal_CmnWFPrIMEStartupMaterialRequest_WIP]
@PathId							int,					
@DefaultUserName				varchar(50),
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
@tfKanbanTypeId					int,		--1.6

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

--Subscription UDPs
@UsePrIME						bit,
@WMSSubscriptionID				int,

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
@ActualUOMQtyOpenRequest		float,
@ActualUOMQtyOpenRequestSub		float,
@ActualUOMQtyTot				float,
@ActualPalletCntStagingSub		int,
@LoopIndexRM					int,
@LoopcountRM					int,
@BOMRMQty						float,
@BOMRMQtyOR						float,
@BOMRMEngUnitDesc				varchar(25),
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

--Final request
@requestId						varchar(30),
@i								int

--FO-04067 Change-over Materials Change Request
DECLARE @FlgPreStagedMaterialRequest		int,
		@UDPPreStagedMaterialRequest		varchar(255),
		@SLAInterval						int, -- SLA Interval (Min) defined on the Path level (UDP) in minutes					
		@UDPSLAInterval						varchar(255),
		@MaxRequestWindow					int, -- From the time the PrO is initiated this is the MAX time for C/O request to be sent to WMS
		@UDPMaxRequestWindow				varchar(255),
		@ForecastStartTime					datetime,
		@SOAEventName						varchar(255),
		@MaxRequestWindowBasedTime			datetime,
		@ProjectedEndTime					datetime, -- projected end time for the current active order
		@ChangeOverTime						datetime,
		@LatestRequestTime					datetime,
		@StopOrderingTime					datetime,
		@SOAEventInterval					int,		-- time interval of the SOA Event that is scanning the Local Table and submitting the Request in minutes
		@FirstRequestTime					datetime,	-- First Timestamp that to schedule request to be picked-up by the SOA Event
		@LastRequestTime					datetime,	-- Last Timestamp to schedule request to be picked-up by the SOA Event
		@TotalRequestedPalletCnt			int,		-- total Number of Pallets to be requested from the PrIME
		@SOAEventTimeSlot					datetime,-- suggested timestamp for the SOA Event
		@PalletRequestInterval				int,-- Interval between Material Request Records in seconds,
		@StatusPreStaged					varchar(255)

--FO-04067 Change-over Materials Change Request
DECLARE	@PreStagedBOMRMProdCode			nvarchar(255),
		@PreStagedBOMRMSubProdCode		nvarchar(255),
		@PreStagedBOMRMTNLOCATN			nvarchar(255),
		@PreStagedQty					int,
		@PreStagedDefaultUserName		nvarchar(255),
		@PreStagedSOAEventTimeSlot		datetime,
		@PreStagedPPProcessOrder		nvarchar(255)

DECLARE	@tblWFRequestMaterialPreStaged TABLE(
		Id							int IDENTITY (1,1),
		BOMRMPRODCODE				nvarchar(255),
		BOMRMSubProdCode			nvarchar(255),
		BOMRMTNLOCATN				nvarchar(255),
		NXTPPPROCESSORDER			nvarchar(255),		
		QUANTITY					int,
		DEFAULTUSERNAME				nvarchar(255),
		SOAEventTimeSlot			datetime)

DECLARE	@tActiveOrder TABLE(	
		Id								INT	IDENTITY (1,1)	NOT NULL,
		PathCode						VARCHAR(255)	NULL,
		ProcessOrder					VARCHAR(255)	NULL,
		ProdCode						VARCHAR(255)	NULL,
		ProdDesc						VARCHAR(255)	NULL,
		ForecastQuantity				FLOAT			NULL,
		ActualGoodItems					INT				NULL,
		Comment							NVARCHAR(4000)	NULL,
		PPStatusID						INT				NULL,
		PPStatusDesc					VARCHAR(255)	NULL,
		ForecastStartDate				DATETIME		NULL,
		ForecastEndDate					DATETIME		NULL,
		PredictedRemainingDuration		FLOAT			NULL,
		ActualGoodQuantity				FLOAT			NULL,
		AdjustedQuantity				FLOAT			NULL,
		UOM								VARCHAR(255)	NULL,
		UserGeneral2					VARCHAR(255)	NULL,
		UserGeneral1					VARCHAR(255)	NULL,	
		ExpectedQualityStatus			VARCHAR(255)	NULL,
		StartTime						DATETIME		NULL,
		EndTime							DATETIME		NULL,
		ProductionVersion				VARCHAR(255)	NULL,
		ProductionLine					VARCHAR(255)	NULL,
		ProductionPlanPPId				INT				NULL,
		BOMFormulationId				INT				NULL,
		ProdId							INT				NULL,
		CommentId						INT				NULL,
		PLId							INT				NULL,
		RemainingQuantity				FLOAT			NULL,
		ProjectedEnd					DATETIME		NULL,
		ChangeOverHour					INT				NULL,
		ChangeOverMin					INT				NULL,
		ChangeOverSec					INT				NULL,
		TargetQuantity					FLOAT			NULL,
		WasteQuantity					FLOAT			NULL,
		MaxQuantity						FLOAT			NULL,
		SortOrder						INT				NULL)		




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
	ParallelItemCount			int,
	KanbanType					int				--1.6
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
	RequestId			varchar(30),
	PriMeReturnCode				int,
	RequestTime			datetime,
	LocationId			varchar(50),
	CurrentLocation		varchar(50),
	ULID				varchar(50),
	Batch				varchar(50),
	ProcessOrder		varchar(50),
	PrimaryGCAS			varchar(8),
	AlternateGCAS		varchar(8),
	GCAS				varchar(8),
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
	FlgOrderForNext				int
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
			PrimeLocation				varchar(50) 
		)

-------------------------------------------------------------------------------
-- Initialize variables.
-------------------------------------------------------------------------------
SELECT	@SPName	= 'spLocal_CmnWFPrIMEStartupMaterialRequest_WIP'

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
		
SELECT	@pnUOMPerPallet					= 'UOM Per Pallet',
		@pnOriginGroup					= 'Origin Group',
		@pnUOM							= 'UOM',
		@pnOriginGroupCapacity			= 'Origin Group Capacity',
		@pnOriginGroupThreshold			= 'Origin Group Threshold',
		@cnOrderMaterials				= 'PE:PrIME_WMS',
		@pnPrIMELocation				= 'LocationId'



--pp_status string
SELECT	@StatusStrActive				= 'Active',
		@StatusStrComplete				= 'Closing',
		@StatusStrNext					= 'Initiate',
		@StatusStrReady					= 'Ready'	


--prodcution_status
SET  @tobereturnedId = (SELECT prodStatus_id FROM dbo.production_status WITH(NOLOCK) WHERE prodStatus_desc = 'To be Returned')


SELECT	@UDPPreStagedMaterialRequest	= 'PE_PrIME_PreStagedMaterialRequest'
SELECT	@UDPSLAInterval					= 'PE_PrIME_SLAInterval'
SELECT	@UDPMaxRequestWindow			= 'PE_PrIME_MaxRequestWindow'		
SELECT	@SOAEventName					= 'PE: PreStaged Material Request'		
SELECT	@StatusPreStaged				= 'Pre-Staged'
						
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

	IF @DebugFlagManual = '1'
	BEGIN
		SELECT 'Invalid User'
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
SET @tfKanbanTypeId			= (	SELECT Table_Field_Id 	FROM dbo.Table_Fields 			WITH(NOLOCK)	WHERE Table_Field_Desc = 'OrderingType'			AND tableid = @TableIdRMI)







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





--V1.5 FO-03557-------------------------
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
						ParallelItemCount,
						kanbanType
						)
SELECT	pepu.PU_Id, 
		pei.PEI_Id, 
		tfv.Value, 
		tfv2.value,
		CONVERT(bit,tfv3.value),
		CONVERT(bit,tfv4.value),
		CONVERT(float,tfv5.value),
		CONVERT(bit,tfv6.value),
		CONVERT(int,tfv7.value),
		CONVERT(int,tfv8.value)
FROM dbo.PrdExec_Path_Units pepu		WITH(NOLOCK)
JOIN dbo.PrdExec_Inputs pei				WITH(NOLOCK)	ON pei.PU_Id = pepu.PU_Id
JOIN dbo.Table_Fields_Values tfv		WITH(NOLOCK)	ON tfv.KeyId = pei.PEI_Id AND tfv.Table_Field_Id  = @tfOGId						AND tfv.tableid = @TableIdRMI
LEFT JOIN dbo.Table_Fields_Values tfv2	WITH(NOLOCK)	ON tfv2.KeyId= pei.PEI_Id AND tfv2.Table_Field_Id = @tfPEWMSSystemId			AND tfv2.tableid = @TableIdRMI
LEFT JOIN dbo.Table_Fields_Values tfv3	WITH(NOLOCK)	ON tfv3.KeyId= pei.PEI_Id AND tfv3.Table_Field_Id = @tfIsOrderingId				AND tfv3.tableid = @TableIdRMI
LEFT JOIN dbo.Table_Fields_Values tfv4	WITH(NOLOCK)	ON tfv4.KeyId= pei.PEI_Id AND tfv4.Table_Field_Id = @tfUseRMScrapFactorId		AND tfv4.tableid = @TableIdRMI
LEFT JOIN dbo.Table_Fields_Values tfv5	WITH(NOLOCK)	ON tfv5.KeyId= pei.PEI_Id AND tfv5.Table_Field_Id = @tfRMScrapFactorId			AND tfv5.tableid = @TableIdRMI
LEFT JOIN dbo.Table_Fields_Values tfv6	WITH(NOLOCK)	ON tfv6.KeyId= pei.PEI_Id AND tfv6.Table_Field_Id = @tfParallelConsumptionId	AND tfv6.tableid = @TableIdRMI
LEFT JOIN dbo.Table_Fields_Values tfv7	WITH(NOLOCK)	ON tfv7.KeyId= pei.PEI_Id AND tfv7.Table_Field_Id = @tfParallelItemCountId		AND tfv7.tableid = @TableIdRMI
LEFT JOIN dbo.Table_Fields_Values tfv8	WITH(NOLOCK)	ON tfv8.KeyId= pei.PEI_Id AND tfv8.Table_Field_Id = @tfKanbanTypeId				AND tfv8.tableid = @TableIdRMI
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
INSERT @Openrequest (OpenTableId,RequestId,PriMeReturnCode,RequestTime,LocationId,CurrentLocation, ULID,Batch,ProcessOrder,PrimaryGCAS,AlternateGCAS,GCAS,QuantityValue,QuantityUOM,Status,EstimatedDelivery,
lastUpdatedTime	,userId, eventid	)
EXEC dbo.spLocal_CmnPrIMEGetOpenRequests @pathCode,NULL,NULL




--set quantityValue where the value is empty
UPDATE @Openrequest 
SET QuantityValue = b.ProductUOMPerPallet
FROM  @Openrequest Op
JOIN @tblBOMRMListComplete b	ON b.BOMRMProdCode = Op.PrimaryGCAS
WHERE QuantityValue IS NULL OR QuantityValue = 1



IF @DebugFlagManual = 1
BEGIN
	SELECT	'@Openrequest', * 
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
			@ActualPalletCntOpenRequest = NULL

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

	SET @ActualPalletCntTot =	coalesce(@ActualPalletCntStaging,0) + 
								coalesce(@ActualPalletCntOpenRequest,0)

	UPDATE @tblRMInventoryGroupActual
	SET ActualPalletCntStaging	= coalesce(@ActualPalletCntStaging,0),
		ActualPalletCntOpenRequest= coalesce(@ActualPalletCntOpenRequest,0),
		ActualPalletCntTot =  @ActualPalletCntTot,
		FlgThresholdGTActual = CASE 
									WHEN @ProductGroupThreshold >= @ActualPalletCntTot THEN 1
									ELSE 0
								END
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
			@BOMRMScrapFactor			=   NULL  
			
	SELECT	@BOMRMOG					=  BOMRMOG,
			@BOMRMStoragePUDesc			=  BOMRMStoragePUDesc,
			@BOMRMTNLOCATN				=  BOMRMTNLOCATN,
			@ProductGroupCapacity		=  ProductGroupCapacity,
			@ProductGroupThreshold		=  ProductGroupThreshold,
			@ActualPalletCntTot			=  ActualPalletCntTot,
			@FlgNewToInitiateOrder		=  FlgNewToInitiateOrder,
			@BOMRMProdId				=  BOMRMProdId,	
			@BOMRMSubProdId				=  BOMRMSubProdId,	
			@BOMRMScrapFactor			=  BOMRMScrapFactor 
	FROM	@tblRMInventoryGroupActual
	WHERE	RMInventoryGrpId = @LoopIndex



	IF (SELECT TOP 1 kanbantype FROM @PRDExecInputs WHERE OG = @BOMRMOG) = 2
	BEGIN

		IF @DebugFlagOnLine = 1  
		BEGIN
			INSERT INTO Local_Debug([Timestamp], CallingSP, [Message], Msg)
						VALUES(	getdate(), 
						@SPNAME,
						'0615' +
						' OG for Ordering type 2, call the SP',
						@pathid
						)
		END

		IF @DebugFlagManual = 1
		BEGIN
			SELECT 'OrderingType 2 for OG: ' + @BOMRMOG
		END
		ELSE
		BEGIN
		--Verify the need for ordering OrderingType 2
			EXEC spLocal_CmnPEKanbanOrderingPrIME @pathid,@BOMRMOG,@DefaultUserName,1  --1.6
			--IF @DebugFlagOnLine = 1  
			--BEGIN
			--	INSERT INTO Local_Debug([Timestamp], CallingSP, [Message], Msg)
			--				VALUES(	getdate(), 
			--				@SPNAME,
			--				'0616' +
			--				' OG for Kanban type 2, test',
			--				@pathid
			--				)
			--END
		END


	END
	ELSE
	BEGIN
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
				@BOMRMScrapFactor			= BOMRMScrapFactor
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
			

		SELECT	@ActualPalletCntOpenRequest = coalesce(COUNT(coalesce(QuantityValue,0)),0),
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
				JOIN dbo.prdExec_input_event ie	WITH(NOLOCK) on i.RMeventid = ie.event_id
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


				--Increment the position filled counter
				IF @LoadedCountPos > 0
					SET @CountPositionFilled = @CountPositionFilled +1
			

				SET @NeededQtyPos = @NxtRequiredBOMRMUOMQtyPos - @LoadedQtyPos
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
								' @ThresholdInUOM= ' + CONVERT(varchar(30),@ThresholdInUOM)  ,
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


				SET @NeededCountPos = CEILING(@NeededQtyPos/@ProductUOMPerPallet)	


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
								'0635' +
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
		
			--SELECT	@NeededUOMQty			= @TotalNeededQty,
			--		@NeededPalletCnt		= @TotalNeededCount	,
			--		@FinalNeededUOMQty		= @TotalFinalNeededCount * @ProductUOMPerPallet,
			--		@FinalNeededPalletCnt	= @TotalFinalNeededCount
			
			----Count existing pallet not loaded 
			--SET @TotalNotLoadedCount = @ActualPalletCntStaging+ @ActualPalletCntOpenRequest+@ActualPalletCntStagingSub - @TotalLoadedCount


			--Count existing pallet not loaded 
			SET @TotalNotLoadedCount = coalesce(@ActualPalletCntStaging,0)  + coalesce(@ActualPalletCntOpenRequest,0)  +coalesce(@ActualPalletCntStagingSub,0)  - coalesce(@TotalLoadedCount,0) 

			--Count existing qty not loaded 
			SET @TotalNotLoadedQty = coalesce(@ActualUOMQtyStaging,0)  + coalesce(@ActualUOMQtyOpenRequest,0)+coalesce(@ActualUOMQtyStagingSub,0)	 -  coalesce(@TotalLoadedQty,0)

			
			SELECT	@NeededUOMQty			= @TotalNeededQty - @TotalNotLoadedQty,
					@NeededPalletCnt		= @TotalNeededCount	- @TotalNotLoadedCount,
					@FinalNeededUOMQty		= (@TotalFinalNeededCount- @TotalNotLoadedCount) * @ProductUOMPerPallet,
					@FinalNeededPalletCnt	= @TotalFinalNeededCount-@TotalNotLoadedCount
			
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

			----------------------------------------------------------------
			--end of PCM Section
			----------------------------------------------------------------
		END
		ELSE
		BEGIN
			----------------------------------------------------------------
			--Standard Section
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
					@FlgNewToInitiateOrder			AS FlgNewTointiateOrder
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
				PrimeLocation)
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
				@BOMRMTNLOCATN)


		--reset table
		DELETE FROM @tblRMInventoryQtyCalc
	END  --1.6
	SET @LoopIndex = (SELECT MIN(RMInventoryGrpId) FROM @tblRMInventoryGroupActual WHERE RMInventoryGrpId > @LoopIndex)
END



IF @DebugFlagOnLine = 1  
BEGIN
	INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
		VALUES(	getdate(), 
				@spnAME,
				'705' +
				' Finish populating the @tblWFRequestMaterial ',
				@pathid
				)
END

IF @DebugFlagManual = 1
BEGIN
	SELECT	'tblWFCRequestMaterial ', * 
	FROM	@tblWFRequestMaterial 
END

-------------------------------------------------------------------------------
-- Task 6-A
-- If Path Is Configured for the Pre-Staged Material Request
-- Populate Table Local_PrIME_PreStaged_Material_Request with pre-Staged Request
-- Distributed over Time Interval
-------------------------------------------------------------------------------

	/*
	PrO # 2 is initiated
	Calculate ProjectedEndTime  for the active order (PrO #1) based on Planned rate, cases produced and planned quantity (already displayed today on schedule screen)
	Calculate ChangeOverTime = MAX of ProjectedEndTime PrO #1 AND  Planned Start Time PrO #2 (= Forecast_start_date from production_plan) 
	Calculate LatestRequestTime = ChangeOverTime – SLA
	Calculate StopOrdering = MIN LatestRequestTime AND (CurrentTime + MaxRequestWindow)
	Distribute Material Requests Between CurrentTime and StopOrdering
	*/

-- FO-04067
SELECT 	@FlgPreStagedMaterialRequest = Null
SELECT 	@FlgPreStagedMaterialRequest = IsNull(tfv.Value,0)
FROM	dbo.TABLE_FIELDS_VALUES tfv
join	dbo.TABLE_FIELDS tf on tfv.TABLE_FIELD_ID = tf.TABLE_FIELD_ID
join	dbo.TABLES t on tf.TABLEID = t.TABLEID
WHERE	t.TABLENAME = 'PrdExec_Paths'
and		tf.TABLE_FIELD_DESC = @UDPPreStagedMaterialRequest
and		tfv.KeyId = @PathId


SELECT 	@SLAInterval = Null
SELECT 	@SLAInterval = IsNull(tfv.Value,240)
FROM	dbo.TABLE_FIELDS_VALUES tfv
join	dbo.TABLE_FIELDS tf on tfv.TABLE_FIELD_ID = tf.TABLE_FIELD_ID
join	dbo.TABLES t on tf.TABLEID = t.TABLEID
WHERE	t.TABLENAME = 'PrdExec_Paths'
and		tf.TABLE_FIELD_DESC = @UDPSLAInterval
and		tfv.KeyId = @PathId


SELECT 	@MaxRequestWindow = Null
SELECT 	@MaxRequestWindow = IsNull(tfv.Value,180)
FROM	dbo.TABLE_FIELDS_VALUES tfv
join	dbo.TABLE_FIELDS tf on tfv.TABLE_FIELD_ID = tf.TABLE_FIELD_ID
join	dbo.TABLES t on tf.TABLEID = t.TABLEID
WHERE	t.TABLENAME = 'PrdExec_Paths'
and		tf.TABLE_FIELD_DESC = @UDPMaxRequestWindow
and		tfv.KeyId = @PathId

----------------------------------------------------------------------


IF @DebugFlagOnLine = 1  
BEGIN
	INSERT INTO dbo.Local_Debug([Timestamp], CallingSP, [Message],msg) 
				VALUES(	
				getdate(), 
				@spnAME,
				'0610' +
				' @FlgPreStagedMaterialRequest ' + convert(varchar(255), IsNull(@FlgPreStagedMaterialRequest,-911)) +
				' @SLAInterval ' + convert(varchar(255), IsNull(@SLAInterval,-911)) +
				' @MaxRequestWindow ' + convert(varchar(255), IsNull(@MaxRequestWindow,-911)),
				@pathid
				)
END

IF (ISNULL(@FlgPreStagedMaterialRequest,0) = 1)
BEGIN
	IF @DebugFlagOnLine = 1  
	BEGIN
		INSERT INTO dbo.Local_Debug([Timestamp], CallingSP, [Message],msg) 
				VALUES(	
				getdate(), 
				@spnAME,
				'0620' +
				' Pre-Staged Raw Material Request Logic',
				@pathid
				)
	END

	SELECT	@ThisTime = Getdate()
	
	--Find Forecast Start Time for the Initiated Order
	SELECT	@ForecastStartTime = pp.FORECAST_START_DATE
	FROM	dbo.PRODUCTION_PLAN	pp WITH (NOLOCK)
	WHERE	pp.pp_id = @NxtPPId

	--If the Active Order Exisis Find the Projected End Time
	IF IsNull(@ActiveOrderExists,0) =1
	BEGIN
		INSERT	@tActiveOrder (	
				PathCode,
				ProcessOrder,
				ProdCode,
				ProdDesc,
				ForecastQuantity,
				ActualGoodItems,
				Comment,
				PPStatusDesc,
				ForecastStartDate,
				ForecastEndDate,
				PredictedRemainingDuration,
				ActualGoodQuantity,
				AdjustedQuantity,
				UOM,
				UserGeneral2,
				UserGeneral1,
				ExpectedQualityStatus,
				StartTime,
				EndTime,
				ProductionVersion,
				ProductionLine,
				ProductionPlanPPId,
				RemainingQuantity,
				PPStatusID,
				ProjectedEnd,
				ChangeOverHour,
				ChangeOverMin,
				ChangeOverSec,
				TargetQuantity,
				WasteQuantity,
				MaxQuantity)
				
		EXECUTE	[dbo].[spLocal_CmnMobileAppGetProductionPlans]
				@PathCode,
				Null,--@StartTime
				Null,--@EndTime					
				@StatusStrActive,
				@ActPPProcessOrder,
				0,
				0
		
		SELECT	@ProjectedEndTime = IsNUll(tao.ProjectedEnd, @ForecastStartTime)
		FROM	@tActiveOrder tao
		WHERE	tao.id = (select min(id) from @tActiveOrder)
	END
	ELSE
	BEGIN
		-- Active Order Not Found
 		SELECT @ProjectedEndTime = @ForecastStartTime
	END	

	--Calculate ChangeOverTime = MAX of ProjectedEndTime PrO #1 AND  Planned Start Time PrO #2 (= Forecast_start_date from production_plan) 
	IF DATEDIFF(MINUTE, @ProjectedEndTime, @ForecastStartTime) >= 0
	BEGIN
		SELECT @ChangeOverTime = @ForecastStartTime
	END
	ELSE
	BEGIN
		SELECT @ChangeOverTime = @ProjectedEndTime
	END

	---Calculate LatestRequestTime = ChangeOverTime – SLA
	SELECT @LatestRequestTime = DATEADD(MINUTE, -@SLAInterval, @ChangeOverTime)
	select @LatestRequestTime = '2019-10-29 13:00:00.000'

	-- calculate Latest Request Time = This Time + Max Request Window
	SELECT @MaxRequestWindowBasedTime  = DATEADD(MINUTE, @MaxRequestWindow, @ThisTime)

	--Calculate StopOrdering = MIN LatestRequestTime AND (CurrentTime + MaxRequestWindow)
	IF DATEDIFF(MINUTE, @LatestRequestTime, @MaxRequestWindowBasedTime) >= 0 -- @MaxRequestWindowBasedTime >= @LatestRequestTime
	BEGIN
		SELECT @StopOrderingTime = @LatestRequestTime
	END
	ELSE
	BEGIN --@MaxRequestWindowBasedTime < @LatestRequestTime
		SELECT @StopOrderingTime = @MaxRequestWindowBasedTime
	END

	IF @DebugFlagOnLine = 1  
	BEGIN
		INSERT	INTO dbo.Local_Debug([Timestamp], CallingSP, [Message],msg) 
				VALUES(	
				getdate(), 
				@spnAME,
				'0630' +
				' @ForecastStartTime: '					+ convert(varchar(255), IsNull(@ForecastStartTime, '1999-01-01 00:00:00'),121) + 
				' @ProjectedEndTime: '					+ convert(varchar(255), IsNull(@ProjectedEndTime,'1999-01-01 00:00:00'),121) +
				' @ChangeOverTime: '					+ convert(varchar(255), IsNull(@ChangeOverTime,'1999-01-01 00:00:00'),121) +
				' @LatestRequestTime: '					+ convert(varchar(255), IsNull(@LatestRequestTime,'1999-01-01 00:00:00'),121) +
				' @MaxRequestWindowBasedTime: '			+ convert(varchar(255), IsNull(@MaxRequestWindowBasedTime,'1999-01-01 00:00:00'),121) +
				' @StopOrderingTime: '					+ convert(varchar(255), IsNull(@StopOrderingTime, '1999-01-01 00:00:00'),121),
				@pathid
				)
	END

	IF @DebugFlagManual = 1
	BEGIN
		SELECT @ProjectedEndTime as ProjectedEndTime, @ForecastStartTime as ForecastStartTime, @ChangeOverTime as ChangeOverTime, @LatestRequestTime as LatestRequestTime, @MaxRequestWindowBasedTime as MaxRequestWindowBasedTime, @StopOrderingTime as StopOrderingTime
	END

	
	--Find whether we are within the interval where we can pre-stage the request the request
	IF DATEDIFF(MINUTE, @ThisTime, @LatestRequestTime)  <= 0  -- @ThisTime > @LatestRequestTim. We are already beyond the Latest Request Time. Too Late to pre-stage requests Requests. Skip to the Reguar Logic
	BEGIN
		IF @DebugFlagOnLine = 1  
		BEGIN
			INSERT	INTO dbo.Local_Debug([Timestamp], CallingSP, [Message],msg) 
					VALUES(	
					getdate(), 
					@spnAME,
					'0640	' +
					'Too Late to pre-stage requests Requests. Skip to the Reguar Logic',
					@pathid)
		END
		GOTO SENDREQUESTTOPRIME
	END	
	
	--Interval of the SOA Event
	SELECT	@SOAEventInterval = round((IsNull(te.timespaninterval,0)/600000000),0)
	FROM	dbo.TimeEvent te
	WHERE	te.NAME = @SOAEventName

	-- Find Number of SOA Events avilable to execute the request
	-- First Available Time to guarantee that record will be picked up by the SOA Event
	SELECT @FirstRequestTime = @ThisTime
	-- need to round to the minute	

	-- Last Available Time to guarantee that record will be picked up by the SOA Event	
	SELECT @LastRequestTime = DATEADD(MINUTE, -(@SOAEventInterval +1), @StopOrderingTime)

	IF @DebugFlagOnLine = 1  
	BEGIN
		INSERT	INTO dbo.Local_Debug([Timestamp], CallingSP, [Message],msg) 
				VALUES(	
				getdate(), 
				@spnAME,
				'0650' +
				' Implement Pre-Staged Logic ' +
				' @FirstRequestTime: '	+ convert(varchar(255), IsNull(@FirstRequestTime, '1999-01-01 00:00:00'),121) + 
				' @LastRequestTime: '	+ convert(varchar(255), IsNull(@LastRequestTime, '1999-01-01 00:00:00'),121),
				@pathid
				)
	END
	
	-- Now Reproduce the original Request Code but wite to the Local Table Instead of sending the Actual Request	
	SET		@LOOPIndex = (SELECT MIN(Id) FROM @tblWFRequestMaterial)
	WHILE	@LOOPIndex IS NOT NULL
	BEGIN
		SELECT	@BOMRMProdCode = RMProdCode,
				@BOMRMSubProdCode = RMSubProdCode,
				@BOMRMTNLOCATN = PrimeLocation,
				@FinalNeededPalletCnt = COALESCE(RMRequestPalletCnt,0)--Number of Pallets for this Material. May be More than 1
		FROM	@tblWFRequestMaterial 
		WHERE	ID = @LOOPIndex

		SET		@i = 0
		WHILE	@i<@FinalNeededPalletCnt
		BEGIN			
			--select @LOOPIndex as LOOPIndex, @i as i
			INSERT	@tblWFRequestMaterialPreStaged (
					BOMRMPRODCODE,
					BOMRMSubProdCode,
					BOMRMTNLOCATN,
					NXTPPPROCESSORDER,
					QUANTITY,
					DEFAULTUSERNAME)					
			SELECT	@BOMRMProdCode,
					@BOMRMSubProdCode,
					@BOMRMTNLOCATN,
					@NxtPPProcessOrder,
					1,--we always request a single Pallet
					@DefaultUserName
					
			SELECT @i = @i+1
		END
		SELECT @LOOPIndex = (SELECT MIN(Id) FROM @tblWFRequestMaterial WHERE Id > @LOOPIndex)
	END	

	--total Number of records to be inserted into the Local Table
	SELECT	@TotalRequestedPalletCnt = count(id)
	FROM	@tblWFRequestMaterialPreStaged 

	--Find Interval between Requests based on interval between @FirstRequestTime and @LastRequestTime and Number of Pallets to be requested
	SELECT	@PalletRequestInterval = FLOOR((DATEDIFF(SECOND, @FirstRequestTime,@LastRequestTime)/@TotalRequestedPalletCnt)) --interval between request records in seconds

	IF @DebugFlagOnLine = 1  
	BEGIN
		INSERT	INTO dbo.Local_Debug([Timestamp], CallingSP, [Message],msg) 
				VALUES(	
				getdate(), 
				@spnAME,
				'0660' +
				' @TotalRequestedPalletCnt: '	+ convert(varchar(255), IsNull(@TotalRequestedPalletCnt, -911)) + 
				' @PalletRequestInterval  : '	+ convert(varchar(255), IsNull(@PalletRequestInterval, -911)), 
				@pathid
				)
	END

	
	--2nd loop through all inserted records	and update the Time Slot
	SELECT	@LoopIndex = Null
	SELECT	@LoopIndex = (SELECT MIN(Id) FROM @tblWFRequestMaterialPreStaged)
	WHILE	@LOOPIndex IS NOT NULL
	BEGIN
		SELECT	@SOAEventTimeSlot = Null
		SELECT	@SOAEventTimeSlot = DATEADD(SECOND, (@LOOPIndex-1)* @PalletRequestInterval, @FirstRequestTime)

		UPDATE	t
		SET		t.SOAEventTimeSlot = @SOAEventTimeSlot
		FROM	@tblWFRequestMaterialPreStaged t
		WHERE	t.id = @LoopIndex
		SELECT	@LOOPIndex = (SELECT MIN(Id) FROM @tblWFRequestMaterialPreStaged WHERE Id > @LOOPIndex)
	END	


	IF @DebugFlagManual = 1
	BEGIN
		SELECT		'@tblWFRequestMaterialPreStaged Populated', 
					tps.* 
		FROM		@tblWFRequestMaterialPreStaged tps
		ORDER BY	tps.Id
	END
	
	-- 3rd Loop through to insert records into the Local Table
	SELECT	@LoopIndex = Null
	SELECT	@LoopIndex = (SELECT MIN(Id) FROM @tblWFRequestMaterialPreStaged)
	WHILE	@LOOPIndex IS NOT NULL
	BEGIN
		SELECT	@PreStagedBOMRMProdCode		= Null,
				@PreStagedBOMRMSubProdCode	= Null,
				@PreStagedBOMRMTNLOCATN		= Null,
				@PreStagedPPProcessOrder	= Null,
				@PreStagedQty				= Null,
				@PreStagedDefaultUserName	= Null,
				@PreStagedSOAEventTimeSlot  = Null		
		
		
		SELECT	@PreStagedBOMRMProdCode		= tps.BOMRMPRODCODE,
				@PreStagedBOMRMSubProdCode	= tps.BOMRMSubProdCode,
				@PreStagedBOMRMTNLOCATN		= tps.BOMRMTNLOCATN,
				@PreStagedPPProcessOrder	= tps.NXTPPPROCESSORDER,
				@PreStagedQty				= tps.QUANTITY,
				@PreStagedDefaultUserName	= tps.DEFAULTUSERNAME,
				@PreStagedSOAEventTimeSlot  = tps.SOAEventTimeSlot
		FROM	@tblWFRequestMaterialPreStaged tps
		WHERE	tps.Id = @LoopIndex	
		
		IF @DebugFlagOnLine = 1  
		BEGIN
		INSERT	INTO dbo.Local_Debug([Timestamp], CallingSP, [Message],msg) 
				VALUES(	
				getdate(), 
				@spnAME,
				'0670' +
				' Inserting Pre-Staged Request Record'	+ 
				' @PreStagedBOMRMProdCode: '			+ convert(varchar(255), IsNull(@PreStagedBOMRMProdCode, 'Null')) + 
				' @PreStagedBOMRMSubProdCode  : '		+ convert(varchar(255), IsNull(@PreStagedBOMRMSubProdCode, 'Null')) + 
				' @PreStagedBOMRMTNLOCATN  : '			+ convert(varchar(255), IsNull(@PreStagedBOMRMTNLOCATN, 'Null')) +
				' @PreStagedPPProcessOrder  : '			+ convert(varchar(255), IsNull(@PreStagedPPProcessOrder, 'Null')) +
				' @PreStagedQty  : '					+ convert(varchar(255), IsNull(@PreStagedQty, -911)) +
				' @PreStagedDefaultUserName  : '		+ convert(varchar(255), IsNull(@PreStagedDefaultUserName, 'Null')) +
				' @PreStagedSOAEventTimeSlot  : '		+ convert(varchar(255), IsNull(@PreStagedSOAEventTimeSlot, '1999-01-01 00:00:00'),121) +
				' @Inserted Time  : '					+ convert(varchar(255), IsNull(@ThisTime, '1999-01-01 00:00:00'),121) +
				' @StatusPreStaged  : '					+ convert(varchar(255), IsNull(@StatusPreStaged, 'Null')),
				@pathid
				)
		END		
		
		INSERT	[dbo].[Local_PrIME_PreStaged_Material_Request] (	
				[BOMRMPRODCODE],
				[BOMRMSUBPRODCODE],
				[BOMRMTNLOCATN],
				[PROCESSORDER],
				[QUANTITY],
				[DEFAULTUSERNAME],
				[SOAEventTimeSlot],
				[InsertedTime],
				[STATUS])	
		SELECT	@PreStagedBOMRMProdCode,
				@PreStagedBOMRMSubProdCode,
				@PreStagedBOMRMTNLOCATN,
				@PreStagedPPProcessOrder,
				@PreStagedQty,
				@PreStagedDefaultUserName,
				@PreStagedSOAEventTimeSlot,
				@ThisTime,
				@StatusPreStaged
					
		SELECT	@LOOPIndex = (SELECT MIN(Id) FROM @tblWFRequestMaterialPreStaged WHERE Id > @LOOPIndex)
	END

	IF @DebugFlagManual = 1
	BEGIN
		SELECT		'Local_PrIME_PreStaged_Material_Request Popuated', 
					lps.* 
		FROM		dbo.Local_PrIME_PreStaged_Material_Request lps
		where		lps.ProcessOrder = @NxtPPProcessOrder
		ORDER BY	lps.Id
	END
	
	GOTO ErrCode
END
-------------------------------------------------------------------------------
-- Task 7
-- Process Material Request to PrIME 
-------------------------------------------------------------------------------
SENDREQUESTTOPRIME:
IF @DebugFlagManual = 0
BEGIN

	SET @LOOPIndex = (SELECT MIN(Id) FROM @tblWFRequestMaterial)
	WHILE @LOOPIndex IS NOT NULL
	BEGIN
		SELECT	@BOMRMProdCode = RMProdCode,
				@BOMRMSubProdCode = RMSubProdCode,
				@BOMRMTNLOCATN = PrimeLocation,
				@FinalNeededPalletCnt = COALESCE(RMRequestPalletCnt,0)
		FROM @tblWFRequestMaterial 
		WHERE ID = @LOOPIndex

		SET @i = 0
		WHILE @i<@FinalNeededPalletCnt
		BEGIN

			EXEC dbo.spLocal_CmnPrIMECreateOpenRequest	@BOMRMTNLOCATN,@NxtPPProcessOrder,@BOMRMProdCode,@BOMRMSubProdCode,1,NULL,@DefaultUserName

			/*  --replacxed by real SP
			--Create a request ID
			SELECT @requestId = CONVERT(varchar(30),datediff(s,'1-Aug-2018',Getdate())+@i+@LOOPIndex)

			--Temp

			INSERT local_PrIME_OpenRequests (RequestId, PickId,RequestTime, LocationId, ULID, Batch, ProcessOrder, PrimaryGCAS, AlternateGCAS, GCAS, QuantityValue, QuantityUOM, Status, UserId,eventid,lastUpdatedTime)
			VALUES (@requestId,NULL,GETDATE(),@BOMRMTNLOCATN,NULL,NULL,@NxtPPProcessOrder,@BOMRMProdCode,@BOMRMSubProdCode,NULL,1,'EA','RequestMaterial',383,NULL, getdate())
			*/
			SELECT @ThisTime = Getdate()
			EXEC dbo.spLocal_InsertTblMaterialRequest	'Request', @NxtPPProcessOrder, @BOMRMProdCode,	@BOMRMTNLOCATN,  @ThisTime,	1,@DefaultUserId,'INITIATE', 'Auto','Success',''
											

			SELECT @i = @i+1
		END


		SET @LOOPIndex = (SELECT MIN(Id) FROM @tblWFRequestMaterial WHERE Id > @LOOPIndex)
	END

	IF @DebugFlagOnLine = 1  
	BEGIN
		INSERT INTO Local_Debug([Timestamp], CallingSP, [Message], msg) 
			VALUES(	getdate(), 
					@SPName,
					'0710' +
					' material request made', 
					@pathid
					)
	END
ENd




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



