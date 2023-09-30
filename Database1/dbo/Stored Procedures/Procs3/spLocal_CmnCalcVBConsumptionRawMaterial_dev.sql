

--------------------------------------------------------------------------------------------------
-- Stored Procedure: spLocal_CmnCalcVBConsumptionRawMaterial_dev
--------------------------------------------------------------------------------------------------
-- Author				:	Ugo Lapierre
-- Date created			:	27-Mar-2013
-- Version 				:	Version <1.0>
-- SP Type				:	PA Calculation
-- Caller				:	Called by a change of the Production Count Change
-- Description			:	This Stored Procedure is based on SP spLocal_CmnCalcVBConsumptionTheo
--							created by Simon Poon.  The new SP managed like the previous one the 
--							theoritical consumption, but it also manage the real consumption.
--							It links the produced event with its raw materials
-- Editor tab spacing	:	4
-------------------------------------------------------------------------------
-- Task Logic :
-- This SP is used by the Calculation Engine to update the Theretical Consumption
-- of the Raw Materials
--
-- 1. Identify the Event
-- 2. Identify the Final Product
-- 3. Identify the BOM and and associate the BOM with the Equipment Properties
--    Update the BOMRMProdGroupDesc based on the Material Class
-- 4. Based on the Raw Material Input of this Unit,
--    Identify the Raw Material Parent PUs 
--    populate a list of the BOM we should consumed at this unit
--    Populate the BOM with PEIId so that we can verify the FlgReportAsConsumption
--    Later
-- 5. Loop through the List of the Raw Material at the BOM which 
--    requires the Theoretical Consumption
-- 5a. Calculate the consumption of the raw material according to the UDP ConsumptionType
--		•	0 = no consumption tracked
--		•	1 = Theoretical consumption
--		•	2 = actual based on counter
--		•	3 = actual based on event (FUTURE)
-- 5b. Retrieve the qty of the existing consumption (All the extsing event components)
-- 5c. calculation the Consumed Qty of the Active Pallet
-- 5d. Verify there is an active pallet
--     If there is an active Pallet, then verify there is a genealogy link
--	if there is no genealogy link, create one with the dimension_x = @RMTotConsumedQtyActiveShouldBe
--		update the pallet with the status <Running>
--	if there is a genealogy link, update the dimension_x = @RMTotConsumedQtyActiveShouldBe
--	If there is no active pallet, then over-consume the last Inactive pallet
--			dimension_x = @RMTotConsumedQtyInactiveLast + @RMTotConsumedQtyActiveShouldBe
--			Do not change the status to <Consumed> or <OverConsumed>
--			Let the CalcEBUpdateFinalDim to do it
-- 6. Output the resultsets
--
-- TRIGGERING
-- This SP is called from the calculation. It is triggered by the changed of the Production Count
--
-- INPUTS Parameters
		--@PUId						- PUId
		--@TimeStamp				- Event TimeStamp
		--@DefaultUserName			- Default User Name
		--@ProdCount				- Production Count
		--@StatusStrToFire			- only execute when the event status match this string
		--@RMRunningStatusStr		- Raw Material Running status (It is started to be consumed)
		--@RMOverConsumedStatusStr	- The pallet is consumed more than its qty
		--@0LevelDebug				
		--@1LevelDebug				
		--@2LevelDebug					
		--@3LevelDebug					
		--@4Leveldebug					
--
-- 
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ============	===============	=======================	==========================================
-- Version		Date			Modified By				Description
-- ============	===============	=======================	==========================================
-- 1.0			2013-03-27		Ugo Lapierre			Initial release
-- 1.1			2013-07-25		Ugo Lapierre			Change some varchar(10) by varchar(30) in the insert local_debug table.
-- 1.2			2014-07-10		linda hudon				on inactive pallet , retrieve overconsummed 
--														and consummed pallet to update dimension x
-- 1.3			2014-07-28		linda hudon				overconsummed has been changed in configuration so modify the query to retrive it in the @RMTotConsumedQtyInactive
-- 1.4			2014-09-15		U.lapierre				Make SP works well With ScannerCheckIn UDP
-- 1.5			2014-11-06		l.hudon					use SPServer instead of result set
-- 1.6			2014-11-06		l.hudon					change final dimension on overconsumed pallet
-- 1.7			2015-01-19		U.Lapierre				Have the SP check for non-scanned, non-RTCIS managed pallets to give them the active PP_id
-- 1.8			2015-03-19		U.Lapierre				Fix issue where "To be Returned get ignored from actual consumed qty (causing over consumption)
-- 1.9			2015-05-11		U.Lapierre				Add scrap factor to the material consumption
-- 1.10			2015-05-12		l.hudon					convert decimal to avoid issue with too much decimal
-- 1.11			2015-05-11		U.Lapierre				Fix divsion by 0 with scrap factor to the material consumption
-- 1.12			2015-05-14		U.Lapierre				TEST: Chenage PP_ID of All pallet fiiting the BOM on the Right ULIN
-- 1.13			2015-05-19		l.hudon					Fix issue PO has been closing and production is added, get pallet by event status instead of pp_id = ACtivePPID
-- 1.15			2015-05-12		l.hudon					change GBDB for GBDB
-- 1.16			2015-05-22		U.Lapierre				Remove bug introduced in the TEST version (1.12)
-- 1.17			2015-06-10		l.hudon					add new consumption with scrap factor
-- 1.18			2015-07-14		l.hudon					issue converting varchar and use the appropriate scrap factor when the Scrap on Path is activated
-- 1.19			2015-07-27		l.hudon					issue when add the SAP scrap factor  to the RM scap factor
-- 1.20			2015-08-05		U.Lapierre				Assign PP_ID to all Non Scann pallet of the BOM in the used ULIN
-- 1.21			2015-08-10		U.Lapierre				Calc can take control of pallets (assign a PO) only if the PO is still active
-- 1.22			2015-09-01		U.Lapierre				Make SP verify if the pallet used is really in status Active (PE 3.1)
--														Fix issue when there is 2 or more active pallet partially consumed (Checked in or running) (PE 3.1)
-- 1.23			2015-10-01		U.Lapierre				Change float and Decimal(18,3) for Decimal(18,6)
-- 1.24			2015-01-29		U.Lapierre				Make SP always round at 3
-- 1.25			2016-05-02		L.Hudon					change consumption from valid status
-- 1.26			2016-05-07		L.Hudon					consumption on overconsumed pallet witout genealogy when this pallet come from a carryover
-- 1.27			2016-06-27		U.Lapierre				insure getting inventory use PP_ID for alternate product
-- 1.28			2016-06-28		U.lapierre				Replace UseBOMScrapFactor by PE_PPA_UseBOMScrapFactor
-- 2.0			2016-11-10		Julien B. Ethier		New version for SCO project
--================================================================================================
--
/*

declare @OutputValue varchar(50)
Exec dbo.spLocal_CmnCalcVBConsumptionRawMaterial_dev
		@OutputValue		OUTPUT,
		@PUId				= 231,				
		@TimeStamp			= '2015-06-16 09:15:00',
		@DefaultUserName	= 'System.PE',		
		@ProdCount			= 30,
		@StatusStrToFire	= 'In Progress~Complete',
		@RMRunningStatusStr = 'Running',
		@RMOverConsumedStatusStr = 'OverConsumed',
		@0LevelDebug		= 0,
		@1LevelDebug		= 0,
		@2LevelDebug		= 0,
		@3LevelDebug		= 1,
		@4Leveldebug		= 0

SELECT @OutputValue as OutputValue

*/

-------------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[spLocal_CmnCalcVBConsumptionRawMaterial_dev]
		@OutputValue				varchar(25) OUTPUT,
		@PUId						int,		-- This Variable / Master PUId / False
		@TimeStamp					datetime,
		@DefaultUserName			varchar(50),
		@ProdCount					float,
		@StatusStrToFire			varchar(100),
		@RMRunningStatusStr			varchar(50),
		@RMOverConsumedStatusStr	varchar(50),
		@0LevelDebug				int,	-- not used in Calculation Manager	
		@1LevelDebug				int,	
		@2LevelDebug				int,	
		@3LevelDebug				int,	
		@4Leveldebug				int		

 
AS
SET NOCOUNT ON
DECLARE	
		@ObjectName					varchar(255),
		@DebugOff					varchar(255),
		@DebugCalcLog				varchar(255),
		@DebugFlagOnLine			varchar(255),
		@DebugFlagManual			varchar(255),
--		@DefaultUserName			varchar(255),
		@spName						varchar(100),

		@DefaultUserId 				int,
		@ErrMsg						varchar(50),			--> to variable
		@CalcErrMsg					varchar(2000),			--> to Local_DebugCalcLog
		@CurrentTime				datetime,

		@EventId					int,
		@EventNum					varchar(50),
		@EventStatusId				int,
		@EventStatusStr				varchar(25),
		@ConsumedStatusId			int,
		@PPId						int,
		@PUDesc						varchar(50)

DECLARE	@ActPPId					int,
		@ActPPStatusId				int,
		@ActPPStatusStr				varchar(25),
		@ActPPPlannedQty			int,
		@ActPPProcessOrder			varchar(25),
		@ActPPProdId				int,
		@ActPPProdCode				varchar(25),
		@ActFPStandardQty			DECIMAL(18,6),
		@ActBOMFormId				int,
		@ActEngUnitDesc				varchar(25),
		@pathId						int

DECLARE	@ProdId						int,
		@ProdCode					varchar(25),
		
		@LoopCount					int,
		@LoopIndex					int,

		@BOMRMId					int,
		@BOMRMProdId				int,
		@BOMRMProdCode				varchar(25),
		@BOMRMStoragePUId			int,
		@BOMRMStoragePUDesc			varchar(50),		
		@BOMRMQty					DECIMAL(18,6),
		@OrBOMRMQTY					DECIMAL(18,6),
		@BOMRMEngUnitId				int,
		@BOMRMEngUnitDesc			varchar(25),
		@BOMRMScrapFactor			DECIMAL(18,6),
		@BOMRMSubProdId				int,
		@BOMRMSubProdCode			varchar(25),
		@BOMRMSubEngUnitId			int,
		@BOMRMSubEngUnitDesc		varchar(25),
		@BOMRMSubConversionFactor	DECIMAL(18,6),
		@RMSubConversionFactor		DECIMAL(18,6),
		@FlgSubstitute				int,
		@ComponentId				int,
		@AdjustedProdCount			FLOAT

DECLARE @RMEventId					int,
		@RMEventNum					varchar(50),
		@RMPUId						int,
		@RMPUDesc					varchar(50),
		@RMInitDimX					DECIMAL(18,6),
		@RMProdId					int,
		@RMProdCode					varchar(25),		
		@RMLoopIndex				int,
		@RMLoopCount				int
DECLARE	@BOMRMFormItemId			int,
		@BOMRMProdGroupDesc			varchar(50)
DECLARE	@pnMaterialOriginGroup		varchar(50),
		@pnProficyManaged			varchar(50),
		@FlgProficyManaged			bit,
		@cnOrderMaterials			varchar(50),
		@pnPreStagingLocation		varchar(50),
		@pnSAPResource				varchar(50),
		@udpUseScrapFactorId		int,
		@UsePathScrapFactor				bit,
		@TableIdPath				int

DECLARE	@BOMRMPreStagingLocation	varchar(50),
		@BOMRMStorageSOAEquipDesc	varchar(50)
-- Task 4
DECLARE	@PEIId						int,
		@PEIInputName				varchar(50),
		@UDPOriginGroup				varchar(50),
		@UDPConsumptionType			varchar(50),
		@UDPConsumptionVariable		varchar(50),
		@UDPReportAsConsumption		varchar(50),
		@UDPUseRMScapFactor			varchar(50),
		@UDPRMScrapFactor			varchar(50),
		@UDPIsProductionCounter		varchar(50),
		@RTCISManagedFlag			int,			--1.7
		@FlgReportAsConsumption		int, 
		@FlgConsumptionType			int,
		@ConsumptionVarId			int,
		@ScannerCheckedInFlag		int,
		@useRMScrapFactor			bit,
		@RMScrapFactor				DECIMAL(18,6),
		@IsProductionCounter		bit

-- Task 5
DECLARE	@RMTotConsumedQty				DECIMAL(18,6),
		@RMTotConsumedQtyInactive		DECIMAL(18,6),
		@RMTotConsumedQtyActiveExisted	DECIMAL(18,6),
		@RMTotConsumedQtyActiveShouldBe	DECIMAL(18,6),
		@OtherActivePalletQty			DECIMAL(18,6),   --1.22
		@ThisPalletQty					DECIMAL(18,6),   --1.22
		@RMOverConsumedQtyExisted		DECIMAL(18,6),
		@RMTagOverConsumed				varchar(50),
		@FlgNoAction					int,
		@FlgActivePalletExisted			int,
		@FlgConsumedPalletExisted		int,
		@FlgActivePalletLinkExisted		int,
		@RMProdStatusStr				varchar(50),
		@RMRunningStatusId				int,
		@RMOverConsumedStatusId			int,
		@IsProdCounterPOBOMQty			DECIMAL(18,6)
DECLARE
	@ParmEventId				int,
	@ParmComponentId			int,
	@ParmSourceEventId			int,
	@ParmDimensionX				DECIMAL(18,6),
	@ParmDimensionY				float,
	@ParmDimensionZ				float,
	@ParmDimensionA				float,
	@ParmChildUnitId			int,
	@ParmStartCoordinateX		float,
	@ParmStartCoordinateY		float,
	@ParmStartCoordinateZ		float,
	@ParmStartCoordinateA		float,
	@ParmStartTime				datetime,
	@ParmTimeStamp				datetime,
	@ParmParentComponentId		int,
	@ParmEntryOn				datetime,
	@ParmExtendedInfo			varchar(255),
	@ParmPEIId					int,
	@ParmReportAsConsumption	int,
	@ParmSignatureId			int			

DECLARE @EnableConsumptionUDP		varchar(50),
		@EnableConsumptionUDPID		int,
		@POStartTime				datetime,
		@EventStartTime				datetime,
		@PathCode					varchar(25),
		@LogID						int

-------------------------------------------------------------------------------
-- declare the variable tables
-------------------------------------------------------------------------------
-- Task 3
DECLARE @tblBOMRMListComplete TABLE
		(	BOMRMId						int IDENTITY,
			PPId						int,
			ProcessOrder				varchar(50),
			PPStatusStr					varchar(25),
			BOMRMProdId					int,
			BOMRMProdCode				varchar(25),
			OrBOMRMQTY					DECIMAL(18,6),
			BOMRMQty					DECIMAL(18,6),
			BOMRMEngUnitId				int,
			BOMRMEngUnitDesc			varchar(25),
			BOMRMScrapFactor			DECIMAL(18,6),
			BOMRMFormItemId				int,
			BOMRMProdGroupId			int,
			BOMRMProdGroupDesc			varchar(25),
			ProductGroupCapacity		int,
			ProductGroupThreshold		float,
			ProductUOMPerPallet			float,
			FlgNewToInitiateOrder		bit,
			FlgProficyManaged			bit,
			FlgInputToThisUnit			int,
			BOMRMStoragePUId			int,
			BOMRMStoragePUDesc			varchar(50),
			BOMRMPreStagingLocation		varchar(50),
			BOMRMSubProdId				int,
			BOMRMSubProdCode			varchar(25),
			BOMRMSubEngUnitId			int,
			BOMRMSubEngUnitDesc			varchar(50),
			BOMRMSubConversionFactor	DECIMAL(18,6),
			PEIId						int,
			PEIInputName				varchar(50),
			FlgReportAsConsumption		int,
			FlgTheoConsumed				int,
			FlgConsumptionType			int,
			ConsumptionVarId			int,
			RTCISManaged				bit,						--1.7
			ScannerCheckedInFlag		bit,						--1.7
			UseRMScrapFactor			bit,						-- 1.17
			RMScrapFactor				DECIMAL(18,6),						-- 1.17
			BOMErrMsg					varchar(1000),
			IsProductionCounter			bit
		)

DECLARE @tblBOMRMList TABLE
		(	BOMRMId						int IDENTITY,
			PPId						int,
			ProcessOrder				varchar(50),
			PPStatusStr					varchar(25),
			BOMRMProdId					int,
			BOMRMProdCode				varchar(25),
			ORBOMRMQty					DECIMAL(18,6),
			BOMRMQty					DECIMAL(18,6),
			BOMRMEngUnitId				int,
			BOMRMEngUnitDesc			varchar(25),
			BOMRMScrapFactor			DECIMAL(18,6),
			BOMRMFormItemId				int,
			BOMRMProdGroupId			int,
			BOMRMProdGroupDesc			varchar(25),
			ProductGroupCapacity		int,
			ProductGroupThreshold		float,
			ProductUOMPerPallet			float,
			FlgNewToInitiateOrder		bit,
			FlgProficyManaged			bit,
			FlgInputToThisUnit			int,
			BOMRMStoragePUId			int,
			BOMRMStoragePUDesc			varchar(50),
			BOMRMPreStagingLocation		varchar(50),
			BOMRMSubProdId				int,
			BOMRMSubProdCode			varchar(25),
			BOMRMSubEngUnitId			int,
			BOMRMSubEngUnitDesc			varchar(25),
			BOMRMSubConversionFactor	DECIMAL(18,6),
			PEIId						int,
			PEIInputName				varchar(50),
			FlgReportAsConsumption		int,
			FlgTheoConsumed				int,
			FlgConsumptionType			int,
			ConsumptionVarId			int,
			RTCISManaged				bit,						--1.7
			ScannerCheckedInFlag		bit,						--1.7
			BOMErrMsg					varchar(1000),
			UseRMScrapFactor			bit,						-- 1.17
			RMScrapFactor				DECIMAL(18,6),						-- 1.17
			RmScrapvalue				DECIMAL(18,6),
			IsProductionCounter			bit
		)
DECLARE	@tblRMParentInfo TABLE (
			ParentId				int		IDENTITY,
			PEIId					int,
			InputName				varchar(50),
			ParentPUId				int,
			ParentPUDesc			varchar(50),
			BOMRMProdGroupDesc		varchar(50),
			FlgTheoConsumed			int,
			FlgReportAsConsumption	int,
			FlgConsumptionType		int,
			ConsumptionVarId		int,
			ScannerCheckedInFlag	bit,
			RTCISManaged			bit	,					--1.7
			UseRMScrapFactor		bit,					-- 1.17
			RMScrapFactor			DECIMAL(18,6),					-- 1.17
			IsProductionCounter		bit
			)
DECLARE	@tblInputValidStatus	TABLE (
			Id						int		Identity,
			PEIId					int,
			PEIInputName			varchar(50),
			ValidInputStatusId		int,
			ValidInputStatusStr		varchar(50)
			)
DECLARE @tblRMInventorytmp TABLE(
			RMInventoryId			int Identity, 
			RMPPId					int,
			RMProcessOrder			varchar(50),
			RMEventId				int, 
			RMEventNum				varchar(50),
			RMEventTimeStamp		datetime,
			RMPUId					int,
			RMPUDesc				varchar(50),
			RMInitDimX				DECIMAL(18,6), 
			RMFinalDimX				DECIMAL(18,6),
			RMProdId				int,
			RMProdCode				varchar(25),
			RMProdStatusId			int,
			RMProdStatusStr			varchar(25),
			CountForProduction		int,
			CountForInventory		int,
			RMSubConversionFactor	DECIMAL(18,6),
			BOMRMScrapFactor		DECIMAL(18,6), --v.18
			FlgSubstitute			int,
			FlgReportAsConsumption	int,
			PEIId					int
		)
DECLARE @tblRMInventory TABLE(
			RMInventoryId			int Identity, 
			RMPPId					int,
			RMProcessOrder			varchar(50),
			RMEventId				int, 
			RMEventNum				varchar(50),
			RMEventTimeStamp		datetime,
			RMPUId					int,
			RMPUDesc				varchar(50),
			RMInitDimX				DECIMAL(18,6), 
			RMFinalDimX				DECIMAL(18,6),
			RMProdId				int,
			RMProdCode				varchar(25),
			RMProdStatusId			int,
			RMProdStatusStr			varchar(25),
			BOMRMScrapFactor		DECIMAL(18,6), -- v1.18
			CountForProduction		int,
			CountForInventory		int,
			RMSubConversionFactor	DECIMAL(18,6),
			FlgSubstitute			int,
			FlgReportAsConsumption	int,
			PEIId					int
		)
DECLARE @tblEventComponentUpds TABLE (	-- ResultSetType = 11
			Pre					int NULL,
			UserId				int NULL,
			TransactionType		int NULL,
			TransactionNumber	int NULL,
			ComponentId			int NULL,
			EventId				int NULL,
			SrcEventId			int NULL,
			DimX				DECIMAL(18,6) NULL,
			DimY				float NULL,
			DimZ				float NULL,
			DimA				float NULL,
			StartCoordinateX	float NULL, 
			StartCoordinateY	float NULL, 
			StartCoordinateZ	float NULL, 
			StartCoordinateA	float NULL,
			StartTime			datetime NULL, 
			TimeStamp			datetime NULL, 
			PPComponentId		int NULL, 
			EntryOn				datetime NULL, 
			ExtendedInfo		varchar(255) NULL,
			PEIId				int,
			ReportAsConsumption	int,
			ChildunitId			int,
			ESignatureId		int
)

DECLARE @tblEventUpds TABLE(		-- ResultSetType = 1
			Id					int Primary Key Identity,
			TransactionType		int NULL,
			EventId				int NULL,
			EventNum			varchar(50) NULL,
			PUId				int NULL,
			TimeStamp			datetime NULL,
 			AppliedProduct		int NULL,
			SourceEvent			int NULL,
			EventStatus			int NULL,
			Confirmed			int NULL,
			UserId				int NULL,
			PostUpdate			int NULL,
			Conformance			int NULL,
			TestPctComplete		int NULL,
			StartTime			datetime NULL,
			TransNum			int NULL,
			TestingStatus		int NULL,
			CommentId			int NULL,
			EventSubTypeId		int NULL,
			EntryOn				datetime NULL,
			ApprovedUserId		int,
			SecondUserId		int,
			ApprovedReasonId	int,
			UserReasonId			int,
			UserSignOffId		int,
			ExtendedInfo		varchar(255)
)

	DECLARE @LOG TABLE
	(LOGID INT)
-------------------------------------------------------------------------------
-- Initialize variables.
-------------------------------------------------------------------------------
SET		@ObjectName = object_name(@@PROCID)
SELECT	@OutputValue = 'DONOTHING',
		@CurrentTime = getdate(),
		@ConsumedStatusId = 8,
		@CalcErrMsg = 'PUId:' + convert(varchar(8), @PUId) + 
						';Time:' + convert(varchar(25), @TimeStamp, 120) + 
						';PCnt:' + convert(varchar(50), @ProdCount)
		SET @spName = 'spLocal_CmnCalcVBConsumptionRawMaterial_dev'
-------------------------------------------------------------------------------
-- Debug Setting
--		@DebugOff = '1' --> no debug will be sent to anywhere
--		@DebugToCalcLog = '1' --> debug to the Local_DebugCalcLog
--		@DebugFlagOnLine = '1' --> debug to dbo.Local_Debug
--		@DebugFlagManual = '1' --> debug to SELECT statement when running the SQL Analyser
-------------------------------------------------------------------------------
SELECT	@DebugFlagOnLine		= @1LevelDebug,
		@DebugCalcLog			= @2LevelDebug,
		@DebugFlagManual		= @3LevelDebug,
		@DebugOff				= @4LevelDebug
			
SELECT	@pnMaterialOriginGroup			= 'MaterialOriginGroup',
		@pnProficyManaged				= 'Proficy Managed',
		@cnOrderMaterials				= 'Order Materials',
		@pnPrestagingLocation			= 'Pre-staging Location',
		@pnSAPResource					= 'SAP resource'

SELECT 	@UDPOriginGroup					='Origin Group',
		--@UDPTheoConsumed				='Theoretical Consumption',
		@UDPReportAsConsumption			='ReportAsConsumption',
		@RMTagOverConsumed				= 'Tag:OverConsumed',
		@UDPConsumptionType				= 'ConsumptionType',
		@UDPConsumptionVariable			= 'RealConsumptionVariable',
		@UDPUseRMScapFactor				= 'UseRMScrapFactor',
		@UDPRMScrapFactor				= 'RMScrapFactor',
		@UDPIsProductionCounter			= 'IsProductionCounterOG'
		

SET @RMRunningStatusId = NULL
SET	@RMRunningStatusId	= (SELECT ProdStatus_Id
							FROM dbo.Production_Status WITH(NOLOCK)
							WHERE ProdStatus_Desc = @RMRunningStatusStr)
IF	@RMRunningStatusId IS NULL
	BEGIN
	
		SELECT	@CalcErrMsg = @CalcErrMsg + '; No Running StatusId',
				@ErrMsg = 'No Running StatusId'

		IF @DebugflagOnLine = 1
			BEGIN
				INSERT INTO dbo.Local_Debug(
					[TimeStamp], 
					CallingSP, 
					[Message])
				VALUES (
					getdate(),
					@spName,
					'0010' +
					' PUId=' + convert(varchar(8), @PUId) +
					' TimeStamp=' + convert(varchar(25), @TimeStamp, 120) +
					' No Running StatusId')
			END
		
		IF @DebugFlagManual = 1
			SELECT 'No Running StatusId'
		
		GOTO	ErrCode
	END

IF @DebugFlagOnLine = 1
BEGIN
		INSERT intO Local_Debug(Timestamp, CallingSP, Message) 	VALUES(	getdate(), @spName,'Sp Started, puid = ' +  CONVERT(Varchar(50),@PUId))
END	


SET	@RMOverConsumedStatusId = NULL		
SET	@RMOverConsumedStatusId	=(SELECT ProdStatus_Id
							FROM dbo.Production_Status WITH(NOLOCK)
							WHERE ProdStatus_Desc = @RMOverConsumedStatusStr)
IF	@RMOverConsumedStatusId IS NULL
	BEGIN
	
		SELECT	@CalcErrMsg = @CalcErrMsg + '; No OverConsumed StatusId',
				@ErrMsg = 'No OC StatusId'

		IF @DebugflagOnLine = 1
			BEGIN
				INSERT INTO dbo.Local_Debug(
					[TimeStamp], 
					CallingSP, 
					[Message])
				VALUES (
					getdate(),
					@spName,
					'0020' +
					' PUId=' + convert(varchar(8), @PUId) +
					' TimeStamp=' + convert(varchar(25), @TimeStamp, 120) +
					' No OverConsumed StatusId')
			END
		
		IF @DebugFlagManual = 1
			SELECT 'No OverConsumed StatusId'
		
		GOTO	ErrCode
	END

IF @DebugFlagOnLine = 1 
	BEGIN 
		INSERT intO Local_Debug(Timestamp, CallingSP, Message) 
			VALUES(	getdate(), 
					@spName,
					'0030' +
					' PUId=' + convert(varchar(5), @PUId) + 
					' TimeStamp=' + convert(varchar(25), @TimeStamp, 120) + 
					' ProdCount=' + convert(varchar(30), @ProdCount) 
					)
	END

-------------------------------------------------------------------------------
-- Validate the User
-------------------------------------------------------------------------------
SET @DefaultUserId = NULL
SELECT @DefaultUserId = User_Id
FROM dbo.Users WITH(NOLOCK)
WHERE Username = @DefaultUserName
IF @DefaultUserId IS NULL
BEGIN
	SELECT	@CalcErrMsg = @CalcErrMsg + '; Invalid User',
			@ErrMsg = 'Invalid User'

	IF @DebugflagOnLine = 1 
		BEGIN
			INSERT intO Local_Debug(TimeStamp, CallingSP, Message)
			VALUES (getdate(),
				@spName,
				'0040' +
				' PUId=' + convert(varchar(8), @PUId) +
				' TimeStamp=' + convert(varchar(25), @TimeStamp, 120) +
				' Invalid User')
		END

	IF @DebugFlagManual = '1'
		BEGIN
			SELECT 'Invalid User'
		END

	GOTO	ErrCode
END

-------------------------------------------------------------------------------
-- 1. Identify the Event
-------------------------------------------------------------------------------
SET		@EventId		= NULL
SELECT	@EventId		= e.Event_Id,
		@EventNum		= e.Event_Num,
		@EventStatusId	= e.Event_Status,
		@EventStatusStr = ps.ProdStatus_Desc,
		@PPId			= ed.PP_Id,
		@PUDesc			= pu.PU_Desc,
		@EventStartTime = e.Start_Time
		FROM	dbo.Events e WITH(NOLOCK)
		JOIN	dbo.Event_Details ed WITH(NOLOCK) ON (e.Event_Id = ed.Event_Id)
		JOIN	dbo.Production_Status ps WITH(NOLOCK) ON (ps.ProdStatus_Id = e.Event_Status)
		JOIN	dbo.Prod_Units pu			WITH(NOLOCK) ON (pu.PU_Id = e.PU_Id)
		WHERE	e.PU_Id = @PUID
		AND	e.TimeStamp = @TimeStamp

SET @CalcErrMsg = 'PU:' + @PUDesc + ';' + @CalcErrMsg
IF	@EventId IS NULL
	BEGIN
	
		SELECT	@CalcErrMsg = @CalcErrMsg + '; Invalid EventId',
				@ErrMsg = 'Invalid EventId'

		IF @DebugflagOnLine = 1
			BEGIN
				INSERT INTO dbo.Local_Debug(
					[TimeStamp], 
					CallingSP, 
					[Message])
				VALUES (
					getdate(),
					@spName,
					'0110' +
					' PUId=' + convert(varchar(8), @PUId) +
					' TimeStamp=' + convert(varchar(25), @TimeStamp, 120) +
					' Invalid EventId')
			END
		
		IF @DebugFlagManual = 1
			BEGIN
				SELECT 'Invalid EventId'
			END	
		GOTO	ErrCode
	END

-------------------------------------------------------------------------------
-- Check whether the SP should be fired
------------------------------------------------------------------------------- 
IF charindex('~' + @EventStatusStr + '~', '~' + @StatusStrToFire + '~') = 0
	BEGIN
		SELECT	@CalcErrMsg = @CalcErrMsg + '; Invalid Status',
				@ErrMsg = 'Invalid Status'	
		
		IF @DebugflagOnLine = 1
		BEGIN
			INSERT INTO dbo.Local_Debug(
				[TimeStamp], 
				CallingSP, 
				[Message])
			VALUES (
				getdate(),
				@spName,
				'0120' +
				' PUId=' + convert(varchar(8), @PUId) +
				' TimeStamp=' + convert(varchar(25), @TimeStamp, 120) +
				' Invalid Status')
		END

		IF @DebugFlagManual = 1
			BEGIN
				SELECT 'Invalid Status'
			END
		GOTO ErrCode
	END

-------------------------------------------------------------------------------
-- 2. Identify the Final Product
-------------------------------------------------------------------------------
IF @PPId IS NULL
	BEGIN
		SELECT	@CalcErrMsg = @CalcErrMsg + '; PPId is null',
				@ErrMsg = 'PPId is null'	

		IF @DebugFlagOnLine = 1  
			INSERT intO Local_Debug(Timestamp, CallingSP, Message) 
				VALUES(	getdate(), 
						@spName,
						'0210' +
						' PUId=' + convert(varchar(5), @PUId) + 
						' TimeStamp=' + convert(varchar(25), @TimeStamp, 120) + 
						' ProdCount=' + coalesce(convert(varchar(30), @ProdCount), 'NoProdCount') + 
						' EventId='  + coalesce(convert(varchar(10), @EventId), 'NoEventId') + 
						' EventNum=' + coalesce(@EventNum, 'NoEventNum') + 
						' ProdCode=' + coalesce(@ProdCode, 'NoProdCode') + 
						' PPId is NULL'
					)

		IF @DebugFlagManual = 1
			BEGIN
				SELECT 'PPId is null'
			END
		GOTO ErrCode
	END

--V1.9
--Get the path and path UDP for scrap factor
SELECT 	@pathId = pp.Path_ID, 
		@PathCode = prd.Path_Code
FROM dbo.production_plan pp WITH(NOLOCK)
JOIN [dbo].[Prdexec_Paths] prd WITH(NOLOCK) ON pp.Path_ID = prd.Path_ID 
WHERE pp_id = @ppid

SET @TableIdPath = (SELECT tableid FROM dbo.tables WHERE tableName = 'PrdExec_Paths')


SET @udpUseScrapFactorId= (	SELECT Table_Field_Id 
							FROM dbo.Table_Fields 
							WHERE Table_Field_Desc = 'PE_PPA_UseBOMScrapFactor'
								AND tableid = @TableIdPath)

SET @UsePathScrapFactor	=  (	SELECT value
							FROM dbo.Table_Fields_Values
							WHERE Table_Field_Id = @udpUseScrapFactorId
								AND keyid = @pathId
								AND tableid = @TableIdPath
								 )	

------------------------------------------------------------------------------------------------------
--verify if the path UDP PE Enable material is set to false
------------------------------------------------------------------------------------------------------
SET @EnableConsumptionUDPID= (	SELECT Table_Field_Id 
							FROM dbo.Table_Fields 
							WHERE Table_Field_Desc = 'PE_PPA_EnableMaterialConsumption'
								AND tableid = @TableIdPath)

SET @EnableConsumptionUDP =	(	SELECT value
								FROM dbo.Table_Fields_Values
								WHERE Table_Field_Id = @EnableConsumptionUDPID
								AND keyid = @pathId
								AND tableid = @TableIdPath 
								 )		

IF @EnableConsumptionUDP = 0
BEGIN

		SELECT	@CalcErrMsg = @CalcErrMsg + '; UDP Consumption Disable',
				@ErrMsg ='UDP Consumption Disable'		
	
		IF @DebugFlagOnLine = 1  
			INSERT intO Local_Debug(Timestamp, CallingSP, Message) 
				VALUES(	getdate(), 
						@spName,
						'0218' +
						' PUId=' + convert(varchar(5), @PUId) + 
						' TimeStamp=' + convert(varchar(25), @TimeStamp, 120) + 
						' ProdCount=' + coalesce(convert(varchar(30), @ProdCount), 'NoProdCount') + 
						' EventId='  + coalesce(convert(varchar(10), @EventId), 'NoEventId') + 
						' EventNum=' + coalesce(@EventNum, 'NoEventNum') + 
						' ProdCode=' + coalesce(@ProdCode, 'NoProdCode') + 
						' UDP Path Material Consumption is disable'
					)

		IF @DebugFlagManual = 1
			BEGIN
				SELECT 'UDP Path Material Consumption is disable'
			END
		GOTO ErrCode
	END

------------------------------------------------------------------------------------------------------
--verify  the production event start time is equal to the PO start time
-- if not we stop consumption
------------------------------------------------------------------------------------------------------


SET		@ProdCode = NULL
SELECT	@ProdId = pp.Prod_Id,
		@ProdCode = p.Prod_Code
		FROM dbo.Production_Plan pp WITH(NOLOCK)
		JOIN dbo.Products p WITH(NOLOCK) ON (pp.Prod_Id = p.Prod_Id)
		WHERE pp.PP_Id = @PPId

IF @ProdId IS NULL
	BEGIN
	
		SELECT	@CalcErrMsg = @CalcErrMsg + '; No Prod',
				@ErrMsg = 'No Prod'		
	
		IF @DebugFlagOnLine = 1  
			INSERT intO Local_Debug(Timestamp, CallingSP, Message) 
				VALUES(	getdate(), 
						@spName,
						'0220' +
						' PUId=' + convert(varchar(5), @PUId) + 
						' TimeStamp=' + convert(varchar(25), @TimeStamp, 120) + 
						' ProdCount=' + coalesce(convert(varchar(30), @ProdCount), 'NoProdCount') + 
						' EventId='  + coalesce(convert(varchar(10), @EventId), 'NoEventId') + 
						' EventNum=' + coalesce(@EventNum, 'NoEventNum') + 
						' ProdCode=' + coalesce(@ProdCode, 'NoProdCode') + 
						' ProdId is NULL'
					)

		IF @DebugFlagManual = 1
			BEGIN
				SELECT 'No Prod'
			END
		GOTO ErrCode
	END

SET	@CalcErrMsg = @CalcErrMsg + 
					';EvtId:' + convert(varchar(25), @EventId) + 
					';EvtNum:' + @EventNum +
					';PCode:' + @ProdCode

IF @DebugFlagOnLine = 1  
	BEGIN
		INSERT intO Local_Debug(Timestamp, CallingSP, Message) 
			VALUES(	getdate(), 
					@spName,
					'0230' +
					' PUId=' + convert(varchar(5), @PUId) + 
					' TimeStamp=' + convert(varchar(25), @TimeStamp, 120) + 
					' ProdCount=' + coalesce(convert(varchar(30), @ProdCount), 'NoProdCount') + 
					' EventId='  + coalesce(convert(varchar(10), @EventId), 'NoEventId') + 
					' EventNum=' + coalesce(@EventNum, 'NoEventNum') + 
					' ProdCode=' + coalesce(@ProdCode, 'NoProdCode')
					)
	END
IF @DebugFlagManual = 1
	BEGIN
		SELECT	@EventId as EventId, 
				@EventNum AS EventNum, 
				@ProdCode as ProdCode
	END
-------------------------------------------------------------------------------
-- 3. Identify the BOM and and associate the BOM with the Equipment Properties
-------------------------------------------------------------------------------
SET @ActPPId = NULL
SELECT	
		@ActPPId				= pp.PP_Id,
		@ActPPStatusId			= pp.PP_Status_Id,
		@ActPPStatusStr			= pps.PP_Status_DesC,
		@ActPPPlannedQty		= pp.Forecast_Quantity,
		@ActPPProcessOrder		= pp.Process_Order,
		@ActPPProdId			= pp.Prod_Id,
		@ActPPProdCode			= p.Prod_Code,
		@ActBOMFormId			= pp.BOM_Formulation_Id,
		@ActEngUnitDesc			= eu.Eng_Unit_Desc
FROM dbo.Production_Plan pp						WITH(NOLOCK)
	JOIN dbo.Products p							WITH(NOLOCK) ON (pp.Prod_Id = p.Prod_Id)
	JOIN dbo.Production_Plan_Statuses pps		WITH(NOLOCK) ON (pps.PP_Status_Id = pp.PP_Status_Id)
	JOIN dbo.Bill_Of_Material_Formulation bomf WITH(NOLOCK) ON (bomf.BOM_Formulation_Id = pp.BOM_Formulation_Id)
	LEFT JOIN dbo.Engineering_Unit eu			WITH(NOLOCK) ON (eu.Eng_Unit_Id = bomf.Eng_Unit_Id)
WHERE PP_Id = @PPId
IF @DebugFlagOnLine = 1 
	BEGIN
		INSERT intO Local_Debug(Timestamp, CallingSP, Message) 
			VALUES(	getdate(), 
					@spName,
					'0310' +
					' PUId=' + convert(varchar(5), @PUId) + 
					' TimeStamp=' + convert(varchar(25), @TimeStamp, 120) + 
					' ActPPPlannedQty=' + coalesce(convert(varchar(30), @ActPPPlannedQty), 'No Planned Qty')
					)
	END
IF @DebugFlagManual = 1
	BEGIN
		SELECT @ActPPPlannedQty AS ActPPPlannedQty, @ActEngUnitDesc AS ActEngUnitDesc
	END


SET @POStartTime = ( SELECT TOP 1 Start_Time FROM [dbo].[production_plan_starts] pps WHERE PP_ID  = @ppid AND PU_Id = @PUId ORDER BY Start_Time DESC)


IF (@EventStartTime <> @POStartTime)
BEGIN

		-------------------------------
		-- ADD NOTIFICATION
		-------------------------------
		INSERT INTO @LOG (LOGID)
		EXEC [dbo].[spLocal_PE_AddLog] 	'Plant Apps', @PathCode, @DefaultUserName, 	'Production Event doesnt match '

		SET @LOGID = (SELECT LOGID FROM @LOG)

		EXEC [dbo].[spLocal_PE_AddLogDetail] @LOGID ,'Process Order',@ActPPProcessOrder
		EXEC [dbo].[spLocal_PE_AddLogDetail] @LOGID ,'@EventStartTime', @EventStartTime
		EXEC [dbo].[spLocal_PE_AddLogDetail] @LOGID ,'@POStartTime',@POStartTime

		SELECT	@CalcErrMsg = @CalcErrMsg + '; Event not Match',
				@ErrMsg = ' Event not Match'		
	
		IF @DebugFlagOnLine = 1  
			INSERT intO Local_Debug(Timestamp, CallingSP, Message) 
				VALUES(	getdate(), 
						@spName,
						'0315' +
						' PUId=' + convert(varchar(5), @PUId) + 
						' TimeStamp=' + convert(varchar(25), @TimeStamp, 120) + 
						' ProdCount=' + coalesce(convert(varchar(30), @ProdCount), 'NoProdCount') + 
						' EventId='  + coalesce(convert(varchar(10), @EventId), 'NoEventId') + 
						' EventNum=' + coalesce(@EventNum, 'NoEventNum') + 
						' ProdCode=' + coalesce(@ProdCode, 'NoProdCode') + 
						'  Production Event not match with PO start time'
					)

		IF @DebugFlagManual = 1
			BEGIN
				SELECT 'Production Event not match with PO start time'
			END
		GOTO ErrCode
END


INSERT intO @tblBOMRMListComplete (
			PPId,
			ProcessOrder,
			PPStatusStr,
			BOMRMProdId,
			BOMRMProdCode,
			ORBOMRMQty,
			BOMRMQty,
			BOMRMEngUnitId,
			BOMRMEngUnitDesc,
			BOMRMScrapFactor,
			BOMRMFormItemId,
			BOMRMProdGroupId,
			BOMRMProdGroupDesc,
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
			@ActPPStatusStr,
			bomfi.Prod_Id, 
			p.Prod_Code, 
			bomfi.Quantity,
			bomfi.Quantity,
			bomfi.Eng_Unit_Id,
			eu.Eng_Unit_Desc,						
			COALESCE(bomfi.Scrap_Factor,0), --1.9
			bomfi.BOM_Formulation_Item_Id,
			NULL, 
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
		JOIN dbo.Bill_Of_Material_Formulation bomf			WITH(NOLOCK) ON (bomf.BOM_Formulation_Id = bomfi.BOM_Formulation_Id)
		JOIN dbo.Products p									WITH(NOLOCK) ON (p.Prod_Id = bomfi.Prod_Id) 
		JOIN dbo.Engineering_Unit eu						WITH(NOLOCK) ON (eu.Eng_Unit_Id = bomfi.Eng_Unit_Id)
		LEFT JOIN dbo.Bill_Of_Material_Substitution bomfs	WITH(NOLOCK) ON (bomfs.BOM_Formulation_Item_Id = bomfi.BOM_Formulation_Item_Id)
		LEFT JOIN dbo.Products p_sub						WITH(NOLOCK) ON (p_sub.Prod_Id = bomfs.Prod_Id) 
		LEFT JOIN dbo.Engineering_Unit eu_sub				WITH(NOLOCK) ON (eu_sub.Eng_Unit_Id = bomfs.Eng_Unit_Id)
		LEFT JOIN dbo.Prod_Units pu							WITH(NOLOCK) ON (bomfi.PU_Id = pu.PU_Id)
	WHERE	bomf.BOM_Formulation_Id = @ActBOMFormId
SET	@CalcErrMsg = @CalcErrMsg + ';BOM CList'
IF @DebugFlagOnLine = 1 
	BEGIN
		INSERT intO Local_Debug(Timestamp, CallingSP, Message) 
			VALUES(	getdate(), 
					@spName,
					'0320' +
					' PUId=' + convert(varchar(5), @PUId) + 
					' TimeStamp=' + convert(varchar(25), @TimeStamp, 120) + 
					' Finish populate the BOM Complete List')
	END
IF @DebugFlagManual = 1
	BEGIN
		SELECT '@tblRMListComplete', * FROM @tblBOMRMListComplete
	END
				
-------------------------------------------------------------------------------
--	Update the BOMRMProdGroupDesc based on the Material Class
-------------------------------------------------------------------------------
SELECT @Loopcount = max(BOMRMId) FROM @tblBOMRMListComplete
SELECT @LoopIndex = min(BOMRMId) FROM @tblBOMRMListComplete

WHILE @LoopIndex <= @Loopcount
	BEGIN
		SELECT	@BOMRMId = NULL,
				@BOMRMFormItemId = NULL,
				@BOMRMProdGroupDesc = NULL,
				@BOMRMStoragePUDesc = NULL,
				@BOMRMPreStagingLocation = NULL,
				@FlgProficyManaged = NULL
		SELECT	@BOMRMId = BOMRMId,
				@BOMRMFormItemId = BOMRMFormItemId,
				@BOMRMStoragePUDesc = BOMRMStoragePUDesc
		FROM	@tblBOMRMListComplete 
		WHERE	BOMRMId = @LoopIndex
			
		SELECT @BOMRMProdGroupDesc = tfv.Value
		FROM dbo.Table_Fields_Values tfv WITH(NOLOCK)
			JOIN dbo.Table_Fields tf WITH(NOLOCK) ON (tf.Table_Field_Id = tfv.Table_Field_Id)
			JOIN dbo.Tables t  WITH(NOLOCK) ON (t.TableId = tf.TableId)
		WHERE t.TableName = 'Bill_of_Material_Formulation_Item'
			AND tf.Table_Field_Desc = @pnMaterialOriginGroup
			AND tfv.KeyId = @BOMRMFormItemId

		SET @FlgProficyManaged = (	SELECT convert(integer, pee.Value)																					
									FROM dbo.Equipment e								WITH(NOLOCK)
										JOIN dbo.property_equipment_equipmentclass pee	WITH(NOLOCK) ON (e.EquipmentId = pee.EquipmentId)
									WHERE e.S95Id = @BOMRMStoragePUDesc 
										AND pee.Name = @pnProficyManaged)
		SET @BOMRMStorageSOAEquipDesc = ( SELECT e.S95Id
											FROM dbo.Equipment e WITH(NOLOCK)
												JOIN dbo.property_equipment_equipmentclass pee WITH(NOLOCK)ON (e.EquipmentId = pee.EquipmentId)
											WHERE pee.Class = @cnOrderMaterials
												AND pee.Name = @pnSAPResource
												AND pee.Value = @BOMRMStoragePUDesc )
		SET @BOMRMPreStagingLocation = (SELECT  convert(varchar(50), pee.Value)
										FROM dbo.Equipment e WITH(NOLOCK)
											JOIN dbo.property_equipment_equipmentclass pee WITH(NOLOCK)ON (e.EquipmentId = pee.EquipmentId)
										WHERE e.S95Id = @BOMRMStorageSOAEquipDesc
											AND pee.Class = @cnOrderMaterials
											AND pee.Name = @pnPreStagingLocation )
		UPDATE @tblBOMRMListComplete
		SET BOMRMProdGroupDesc = @BOMRMProdGroupDesc,
			BOMRMPrestagingLocation = @BOMRMPrestagingLocation,
			FlgProficyManaged = @FlgProficyManaged
		WHERE BOMRMId = @LoopIndex

		SELECT @LoopIndex = @LoopIndex + 1
	END

SET	@CalcErrMsg = @CalcErrMsg + ';BOM SOAProp'
IF @DebugFlagOnLine = 1 
	BEGIN
		INSERT intO Local_Debug(Timestamp, CallingSP, Message) 
			VALUES(	getdate(), 
					@spName,
					'0330' +
					' PUId=' + convert(varchar(5), @PUId) + 
					' TimeStamp=' + convert(varchar(25), @TimeStamp, 120) + 
					' Update BOMRMProdGroupDesc from Material Class')
	END
IF @DebugFlagManual = 1
	BEGIN
		SELECT	'@tblBOMRMList-SOAProp', * 
		FROM	@tblBOMRMListComplete
	END

-------------------------------------------------------------------------------
-- 4. Based on the Raw Material Input of this Unit,
--    Identify the Raw Material Parent PUs 
------------------------------------------------------------------------------- 
INSERT intO @tblRMParentInfo(
		PEIId					,
		InputName				,	
		ParentPUId				,
		ParentPUDesc			)
SELECT 	pei.pei_id			AS PEIId,
		pei.Input_Name		AS InputName,
		peis.PU_Id			AS ParentPUId,
		pu.PU_Desc 			AS ParentPUDesc
FROM dbo.PrdExec_Inputs pei WITH(NOLOCK)
	JOIN dbo.PrdExec_Input_Sources peis WITH(NOLOCK) ON (peis.pei_id = pei.pei_id)
	JOIN dbo.Prod_Units pu WITH(NOLOCK) ON (pu.PU_Id = peis.PU_Id)
WHERE pei.PU_Id = @PUId

			
SELECT @LoopCount = max(ParentId) FROM 	@tblRMParentInfo
SELECT @LoopIndex = min(ParentId) FROM 	@tblRMParentInfo

	
WHILE @LoopIndex <= @LoopCount
	BEGIN
		SELECT @BOMRMProdGroupDesc		= NULL,
				--@FlgTheoConsumed		= NULL,
				@FlgReportAsConsumption	= NULL,
				@FlgConsumptionType		= NULL,
				@ConsumptionVarId		= NULL,
				@useRMScrapFactor		= NULL,
				@RMScrapFactor			= NULL,
				@IsProductionCounter	= NULL
		
		SELECT	@PEIId				= PEIId,
				@BOMRMStoragePUDesc	= ParentPUDesc
		FROM @tblRMParentInfo
		WHERE ParentId = @LoopIndex

	


		SELECT @BOMRMProdGroupDesc = tfv.Value
		FROM dbo.Table_Fields_Values tfv WITH(NOLOCK)
			JOIN dbo.Table_Fields tf WITH(NOLOCK) ON (tfv.Table_Field_id = tf.Table_Field_Id)
			JOIN dbo.Tables t WITH(NOLOCK) ON (t.TableId = tf.TableId)
		WHERE t.TableName = 'PrdExec_Inputs'
			AND tf.Table_Field_Desc = @UDPOriginGroup
			AND tfv.KeyId = @PEIId
/*
		SELECT @FlgTheoConsumed = convert(int,coalesce(tfv.Value,0))
		FROM dbo.Table_Fields_Values tfv WITH(NOLOCK)
			JOIN dbo.Table_Fields tf WITH(NOLOCK) ON (tfv.Table_Field_id = tf.Table_Field_Id)
			JOIN dbo.Tables t WITH(NOLOCK) ON (t.TableId = tf.TableId)
		WHERE t.TableName = 'PrdExec_Inputs'
			AND tf.Table_Field_Desc = @UDPTheoConsumed
			AND tfv.KeyId = @PEIId
*/
		SELECT @FlgReportAsConsumption = convert(int,coalesce(tfv.Value,0))
		FROM dbo.Table_Fields_Values tfv
			JOIN dbo.Table_Fields tf WITH(NOLOCK) ON (tfv.Table_Field_id = tf.Table_Field_Id)
			JOIN dbo.Tables t WITH(NOLOCK) ON (t.TableId = tf.TableId)
		WHERE t.TableName = 'PrdExec_Inputs'
			AND tf.Table_Field_Desc = @UDPReportAsConsumption
			AND tfv.KeyId = @PEIId
			
		--1.4  UL 15-Sep-2014	
		SELECT @ScannerCheckedInFlag = convert(int,coalesce(tfv.Value,0))
		FROM dbo.Table_Fields_Values tfv
			JOIN dbo.Table_Fields tf WITH(NOLOCK) ON (tfv.Table_Field_id = tf.Table_Field_Id)
			JOIN dbo.Tables t WITH(NOLOCK) ON (t.TableId = tf.TableId)
		WHERE t.TableName = 'PrdExec_Inputs'
			AND tf.Table_Field_Desc = 'ScannerCheckIn'
			AND tfv.KeyId = @PEIId

		--1.7  UL 19-Jan-2015	
		SELECT @RTCISManagedFlag = convert(int,coalesce(tfv.Value,0))
		FROM dbo.Table_Fields_Values tfv
			JOIN dbo.Table_Fields tf WITH(NOLOCK) ON (tfv.Table_Field_id = tf.Table_Field_Id)
			JOIN dbo.Tables t WITH(NOLOCK) ON (t.TableId = tf.TableId)
		WHERE t.TableName = 'PrdExec_Inputs'
			AND tf.Table_Field_Desc = 'RTCIS_Managed'
			AND tfv.KeyId = @PEIId

/*New UDPs*/
		--Get the flag indicating the type of consumption to use for that material
		SELECT @FlgConsumptionType = convert(int,coalesce(tfv.Value,0))
		FROM dbo.Table_Fields_Values tfv WITH(NOLOCK)
			JOIN dbo.Table_Fields tf WITH(NOLOCK) ON (tfv.Table_Field_id = tf.Table_Field_Id)
			JOIN dbo.Tables t WITH(NOLOCK) ON (t.TableId = tf.TableId)
		WHERE t.TableName = 'PrdExec_Inputs'
			AND tf.Table_Field_Desc = @UDPConsumptionType 
			AND tfv.KeyId = @PEIId			
		
		--If material is managed by real consumption (type = 2), get the var_id fo the variable indicatiing the consumption
		SELECT @ConsumptionVarId = convert(int,coalesce(tfv.Value,0))
		FROM dbo.Table_Fields_Values tfv WITH(NOLOCK)
			JOIN dbo.Table_Fields tf WITH(NOLOCK) ON (tfv.Table_Field_id = tf.Table_Field_Id)
			JOIN dbo.Tables t WITH(NOLOCK) ON (t.TableId = tf.TableId)
		WHERE t.TableName = 'PrdExec_Inputs'
			AND tf.Table_Field_Desc = @UDPConsumptionVariable 
			AND tfv.KeyId = @PEIId	
					
		/*New UDPs  2015-06-15*/	
		-- get flag indicating id we use the RM scrap factor					
		SELECT @useRMScrapFactor = convert(bit,coalesce(tfv.Value,0))
		FROM dbo.Table_Fields_Values tfv WITH(NOLOCK)
			JOIN dbo.Table_Fields tf WITH(NOLOCK) ON (tfv.Table_Field_id = tf.Table_Field_Id)
			JOIN dbo.Tables t WITH(NOLOCK) ON (t.TableId = tf.TableId)
		WHERE t.TableName = 'PrdExec_Inputs'
			AND tf.Table_Field_Desc = @UDPUseRMScapFactor
			AND tfv.KeyId = @PEIId

		IF @useRMScrapFactor = 1
		BEGIN
			-- get  RM scrap factor	value		
			SELECT @RMScrapFactor = coalesce(cast(tfv.value as float),0)
			FROM dbo.Table_Fields_Values tfv WITH(NOLOCK)
				JOIN dbo.Table_Fields tf WITH(NOLOCK) ON (tfv.Table_Field_id = tf.Table_Field_Id)
				JOIN dbo.Tables t WITH(NOLOCK) ON (t.TableId = tf.TableId)
			WHERE t.TableName = 'PrdExec_Inputs'
				AND tf.Table_Field_Desc = @UDPRMScrapFactor
				AND tfv.KeyId = @PEIId
					
		END

		SELECT @IsProductionCounter = convert(int,coalesce(tfv.Value,0))
		FROM dbo.Table_Fields_Values tfv WITH(NOLOCK)
			JOIN dbo.Table_Fields tf WITH(NOLOCK) ON (tfv.Table_Field_id = tf.Table_Field_Id)
			JOIN dbo.Tables t WITH(NOLOCK) ON (t.TableId = tf.TableId)
		WHERE t.TableName = 'PrdExec_Inputs'
			AND tf.Table_Field_Desc = @UDPIsProductionCounter
			AND tfv.KeyId = @PEIId

		
		--here
		UPDATE @tblRMParentInfo
		SET BOMRMProdGroupDesc		= @BOMRMProdGroupDesc,
			FlgReportAsConsumption	= @FlgReportAsConsumption,
			FlgCOnsumptionType		= @FlgConsumptionType,
			ConsumptionVarId		= @ConsumptionVarId,
			ScannerCheckedInFlag    = @ScannerCheckedInFlag,
			RTCISManaged			= @RTCISManagedFlag	,			--1.7
			UseRMScrapFactor		= @useRMScrapFactor,
			RMScrapFactor			= @RMScrapFactor,
			IsProductionCounter		= @IsProductionCounter
		FROM @tblRMParentInfo
		WHERE ParentId = @LoopIndex


		
		UPDATE @tblBOMRMListComplete
		SET	FlgInputToThisUnit = 1
		FROM @tblBOMRMListComplete
		WHERE BOMRMProdGroupDesc = @BOMRMProdGroupDesc
			AND BOMRMStoragePUDesc = @BOMRMStoragePUDesc
			
		INSERT INTO @tblInputValidStatus
		(		PEIId			,
				PEIInputName	,
				ValidInputStatusId,
				ValidInputStatusStr
				)
		SELECT	pei.pei_Id,
				pei.Input_Name,
				peisd.Valid_Status,
				ps.ProdStatus_Desc
		FROM dbo.PrdExec_Inputs pei
			JOIN dbo.PrdExec_Input_Sources peis WITH(NOLOCK) ON (peis.pei_id = pei.pei_id)
			JOIN dbo.PrdExec_Input_Source_Data peisd WITH(NOLOCK) ON (peisd.peis_id = peis.peis_id) 
			JOIN dbo.Production_Status ps WITH(NOLOCK) ON (ps.ProdStatus_Id = peisd.Valid_Status)
		WHERE pei.pei_id = 	@PEIId

		--If Scanner CheckInFlag is TRUE, we need to keep only Checked In and Running Status
		If @ScannerCheckedInFlag = 1
		BEGIN
			DELETE @tblInputValidStatus
			WHERE PEIId = @PEIId AND ValidInputStatusId NOT IN (SELECT prodStatus_Id 
																FROM dbo.production_Status
																WHERE Count_for_Inventory = 1 AND Count_For_Production = 1 )
		END
		
		SELECT @LoopIndex = @LoopIndex + 1
	END

SET	@CalcErrMsg = @CalcErrMsg + ';ParentInfo'
IF @DebugFlagOnLine = 1 
	BEGIN
		INSERT intO Local_Debug(Timestamp, CallingSP, Message) 
			VALUES(	getdate(), 
					@spName,
					'0340' +
					' PUId=' + convert(varchar(5), @PUId) + 
					' TimeStamp=' + convert(varchar(25), @TimeStamp, 120) + 
					' Create Parent Info')
	END
IF @DebugFlagManual = 1
	BEGIN
		SELECT '@tblRMParentInfo', * FROM @tblRMParentInfo
		SELECT '@tblInputValidStatus', * FROM @tblInputValidStatus
	END
------------------------------------------------------------------------------- 
-- Populate the BOM with PEIId so that we can verify the FlgReportAsConsumption
-- Later
------------------------------------------------------------------------------- 
UPDATE @tblBOMRMListComplete
SET		PEIId					= rmpi.PEIId,
		PEIInputName			= rmpi.InputName,
		FlgReportAsConsumption	= rmpi.FlgReportAsConsumption,
		FlgConsumptionType		= rmpi.FlgConsumptionType	,
		ConsumptionVarId		= rmpi.ConsumptionVarId, 
		RTCISManaged			= rmpi.RTCISManaged,						--1.7
		ScannerCheckedInFlag	= rmpi.ScannerCheckedInFlag	,				--1.7
		UseRMScrapFactor		= rmpi.UseRMScrapFactor,					--1.17
		RMScrapFactor			= rmpi.RMScrapFactor,						--1.17
		IsProductionCounter		= rmpi.IsProductionCounter
FROM @tblBOMRMListComplete	brmc
JOIN @tblRMParentInfo		rmpi ON ((brmc.BOMRMStoragePUId = rmpi.ParentPUId) 
									AND (brmc.BOMRMProdGroupDesc = rmpi.BOMRMProdGroupDesc))

 INSERT INTO @tblBOMRMList (
			PPId,
			ProcessOrder,
			PPStatusStr,
			BOMRMProdId,
			BOMRMProdCode,
			OrBOMRMQTY,
			BOMRMQty,
			BOMRMEngUnitId,
			BOMRMEngUnitDesc,
			BOMRMScrapFactor,
			BOMRMFormItemId,
			BOMRMProdGroupId,
			BOMRMProdGroupDesc,
			FlgNewToInitiateOrder,
			FlgProficyManaged,
			FlgInputToThisUnit,
			BOMRMStoragePUId,
			BOMRMStoragePUDesc,
			BOMRMPreStagingLocation,
			BOMRMSubProdId,
			BOMRMSubProdCode,
			BOMRMSubEngUnitId,
			BOMRMSubEngUnitDesc,
			BOMRMSubConversionFactor,
			PEIId,
			PEIInputName,
			FlgReportAsConsumption,
			--FlgTheoConsumed,
			FlgConsumptionType, 
			RTCISManaged,								--1.7
			ScannerCheckedInFlag,						--1.7
			UseRMScrapFactor,							--1.17
			RMScrapFactor,								--1.17
			ConsumptionVarId,
			IsProductionCounter )
	SELECT 		
			PPId,
			ProcessOrder,
			PPStatusStr,
			BOMRMProdId,
			BOMRMProdCode,
			BOMRMQty,
			BOMRMQty,
			BOMRMEngUnitId,
			BOMRMEngUnitDesc,
			BOMRMScrapFactor,
			BOMRMFormItemId,
			BOMRMProdGroupId,
			BOMRMProdGroupDesc,
			FlgNewToInitiateOrder,
			FlgProficyManaged,
			FlgInputToThisUnit,
			BOMRMStoragePUId,
			BOMRMStoragePUDesc,
			BOMRMPreStagingLocation,
			BOMRMSubProdId,
			BOMRMSubProdCode,
			BOMRMSubEngUnitId,
			BOMRMSubEngUnitDesc,
			BOMRMSubConversionFactor,
			PEIId,
			PEIInputName,
			FlgReportAsConsumption,
			FlgConsumptionType,
			RTCISManaged,								--1.7
			ScannerCheckedInFlag,						--1.7
			UseRMScrapFactor,							--1.17
			RMScrapFactor,								--1.17
			ConsumptionVarId,
			IsProductionCounter
	FROM	@tblBOMRMListComplete
	WHERE	FlgProficyManaged = 1
			AND FlgInputToThisUnit = 1
			AND FlgConsumptionType > 0

	-- update BOMQTY with 
	UPDATE @tblBOMRMList
	SET OrBOMRMQTY = BomRMQTY,
	BOMRMQty = BomRMQTY + coalesce((BOMRMQty  * (RMScrapFactor/100))	,0)
	WHERE UseRMScrapFactor =1

IF @DebugFlagManual = 1
	BEGIN
		SELECT '@tblBOMRMList', BomRMQty,RmScrapvalue, * FROM @tblBOMRMList
	END

/* --------------------------------------------
--New in Version 1.7
We need to update all inventory pallet to the active PP_ID if they meet the following conditions
-Part of BOM (primary or Alternate)
-Not RTCIS Managed, Not ScannedCheckin, Report as consumption
-In a valid ULIN

Will do a direct UPDATE to PP_ID, will be faster than a while with SP server
---------------------------------------------------*/

IF EXISTS(SELECT pp_id FROM dbo.production_plan WHERE pp_id = @PPId AND pp_status_id = 3)  --New  1.21  --get possession of pallet only if your PO staill active
BEGIN
	UPDATE ed
	SET pp_ID = @PPId
	FROM dbo.event_details ed
	JOIN dbo.events e				ON ed.event_id = e.event_id
	JOIN @tblBOMRMList	b				ON e.pu_id = b.BOMRMStoragePUId
										AND (e.applied_product = b.BOMRMProdId
											OR e.applied_product = b.BOMRMSubProdId	)
	JOIN dbo.Production_Status ps		ON (ps.ProdStatus_Id = e.Event_Status)
	WHERE	(	(ps.Count_For_Production = 0 	AND ps.Count_For_Inventory = 0)
				OR	 (ps.Count_For_Production = 1 	AND ps.Count_For_Inventory = 1 AND ed.final_dimension_X > 0)
			)
	AND		b.FlgReportAsConsumption = 1
	AND     b.ScannerCheckedInFlag = 0
	--AND		b.RTCISManaged = 0
	AND		(ed.pp_ID != @PPId OR ed.pp_ID IS NULL)
END						
					

SET	@CalcErrMsg = @CalcErrMsg + ';BOM-ClnList'
IF @DebugFlagOnLine = 1 
	BEGIN 
		INSERT intO Local_Debug(Timestamp, CallingSP, Message) 
			VALUES(	getdate(), 
					@spName,
					'0410' +
					' PUId=' + convert(varchar(5), @PUId) + 
					' TimeStamp=' + convert(varchar(25), @TimeStamp, 120) + 
					' Finish ParentInfo')
	END

IF @DebugFlagManual = 1
	BEGIN
		SELECT	'@tblBOMRMList-Clean', * FROM	@tblBOMRMList
	END


-- There cannot be more than one OG with IsProductionCounter set to 1
IF (SELECT COUNT(*) FROM @tblBOMRMList WHERE IsProductionCounter = 1) > 1
BEGIN

	-------------------------------
	-- ADD NOTIFICATION
	-------------------------------
	INSERT INTO @LOG (LOGID)
	EXEC [dbo].[spLocal_PE_AddLog] 	'Plant Apps', @PathCode, @DefaultUserName, 	'More than one OG have IsProductionCounter set to 1 '

	SET @LOGID = (SELECT LOGID FROM @LOG)

	EXEC [dbo].[spLocal_PE_AddLogDetail] @LOGID ,'Process Order',@ActPPProcessOrder	

	SELECT	@CalcErrMsg = @CalcErrMsg + '; IsProductionCounter wrongly set',
			@ErrMsg = ' IsProductionCounter wrongly se'		
	
	IF @DebugFlagOnLine = 1  
		INSERT intO Local_Debug(Timestamp, CallingSP, Message) 
			VALUES(	getdate(), 
					@spName,
					'0315' +
					' PUId=' + convert(varchar(5), @PUId) + 
					' TimeStamp=' + convert(varchar(25), @TimeStamp, 120) + 
					' ProdCount=' + coalesce(convert(varchar(30), @ProdCount), 'NoProdCount') + 
					' EventId='  + coalesce(convert(varchar(10), @EventId), 'NoEventId') + 
					' EventNum=' + coalesce(@EventNum, 'NoEventNum') + 
					' ProdCode=' + coalesce(@ProdCode, 'NoProdCode') + 
					'  More than one OG have IsProductionCounter set to 1'
				)

	IF @DebugFlagManual = 1
		BEGIN
			SELECT 'More than one OG have IsProductionCounter set to 1'
		END
	GOTO ErrCode

END
ELSE
BEGIN
	
	-- Retrieve PO BOM Qty of OG with IsProductionCounter UDP set to True
	SET @IsProdCounterPOBOMQty = NULL;
	
	SELECT @IsProdCounterPOBOMQty = BOMRMQty
		FROM @tblBOMRMList
		WHERE IsProductionCounter = 1;

END


------------------------------------------------------------------------------- 
-- 5. Loop through the List of the Raw Material at the BOM which 
--    requires the Theoretical Consumption
-- 5a. Based on the Production Count of this Event, calculation the Total Consumed of each material
-- 5b. Retrieve the qty of the existing consumption (All the existing event components)
-- 5c. calculation the Consumed Qty of the Active Pallet
-- 5d. Verify there is an active pallet
--     If there is an active Pallet, then verify there is a genealogy link
--	if there is no genealogy link, create one with the dimension_x = @RMTotConsumedQtyActiveShouldBe
--	if there is a genealogy link, update the dimension_x = @RMTotConsumedQtyActiveShouldBe
--	If there is no active pallet, then over-consume the last Inactive pallet
--			dimension_x = @RMTotConsumedQtyInactiveLast + @RMTotConsumedQtyActiveShouldBe
------------------------------------------------------------------------------- 
SELECT @LoopCount = max(BOMRMId) FROM @tblBOMRMList
SELECT @LoopIndex = min(BOMRMId) FROM @tblBOMRMList


WHILE @LoopIndex <= @LoopCount
BEGIN
	SELECT	@ComponentId						= NULL,
			@RMEventId							= NULL,
			@RMEventNum							= NULL
	
	SELECT	@RMTotConsumedQty					= NULL,
			@RMTotConsumedQtyInactive			= NULL,
			@RMTotConsumedQtyActiveExisted		= NULL,
			@RMTotConsumedQtyActiveShouldBe		= NULL,
			@FlgConsumptionType					= NULL
		
	SELECT	@BOMRMQty					= NULL,
			@OrBOMRMQTY					= NULL,
			@BOMRMProdId				= NULL,
			@BOMRMProdCode				= NULL,	
			@BOMRMStoragePUId			= NULL,
			@BOMRMStoragePUDesc			= NULL,				
			@BOMRMEngUnitDesc			= NULL,
			@BOMRMEngUnitId				= NULL,
			@BOMRMEngUnitDesc			= NULL,
			@BOMRMScrapFactor			= NULL,
			@BOMRMSubProdId				= NULL,
			@BOMRMSubProdCode			= NULL,
			@BOMRMSubEngUnitId			= NULL,
			@BOMRMSubEngUnitDesc		= NULL,
			@BOMRMSubConversionFactor	= NULL,
			@PEIId						= NULL,
			@PEIInputName				= NULL,
			@FlgReportAsConsumption		= NULL,
			@IsProductionCounter		= NULL

	SELECT	@BOMRMQty					= BOMRMQty,
			@ORBOMRMQty					= ORBOMRMQty,
			@BOMRMId					= BOMRMId,
			@BOMRMProdId				= BOMRMProdId,
			@BOMRMProdCode				= BOMRMProdCode,
			@BOMRMStoragePUId			= BOMRMStoragePUId,
			@BOMRMStoragePUDesc			= BOMRMStoragePUDesc,	
			@BOMRMEngUnitId				= BOMRMEngUnitId,
			@BOMRMEngUnitDesc			= BOMRMEngUnitDesc,
			@BOMRMScrapFactor			= BOMRMScrapFactor,
			@BOMRMSubProdId				= BOMRMSubProdId,
			@BOMRMSubProdCode			= BOMRMSubProdCode,
			@BOMRMSubEngUnitId			= BOMRMSubEngUnitId,
			@BOMRMSubEngUnitDesc		= BOMRMSubEngUnitDesc,
			@BOMRMSubConversionFactor	= BOMRMSubConversionFactor,
			@PEIId						= PEIId,
			@PEIInputName				= PEIInputName,
			@FlgReportAsConsumption		= FlgReportAsConsumption,
			@FlgConsumptionType			= FlgConsumptionType,
			@ConsumptionVarId			= ConsumptionVarId,
			@IsProductionCounter		= IsProductionCounter,
			@BOMRMProdGroupDesc			= BOMRMProdGroupDesc
	FROM @tblBOMRMList
	WHERE BOMRMId = @LoopIndex


	IF @DebugFlagOnLine = 1
	BEGIN
			INSERT intO Local_Debug(Timestamp, CallingSP, Message) 	VALUES(	getdate(), @spName,'Begin with @BOMRMProdCode = ' +  CONVERT(Varchar(50),@BOMRMProdCode))

	END	
				
	-------------------------------------------------------------------------------
	-- Establish a table with all the Events 'Inventory' for this Raw Material
	-- @tblRMInventorytmp only has 1 record because a strategy has been changed
	-- Instead of retrieving all the parent inventory, we just take the oldest one
	-- and then let the PlugFlow Calculation at the parent to do the FIFO link adjustment.
	------------------------------------------------------------------------------- 
	DELETE FROM @tblRMInventorytmp
	DELETE FROM @tblRMInventory

	INSERT intO @tblRMInventorytmp(
			RMPPId,
			RMProcessOrder,
			RMEventId, 
			RMEventNum, 
			RMEventTimeStamp, 
			RMPUId, 
			RMPUDesc, 
			RMInitDimX, 
			RMFinalDimX, 
			RMProdId, 
			RMProdCode,
			RMProdStatusId,
			RMProdStatusStr,
			CountForProduction,
			CountForInventory,
			RMSubConversionFactor,
			FlgSubstitute )		
	SELECT 	ed.PP_Id,
			pp.Process_Order,
			e.Event_Id,
			e.Event_Num,
			e.TimeStamp,
			e.PU_Id,
			pu.PU_Desc,
			ed.Initial_Dimension_X,
			ed.Final_Dimension_X,
			e.Applied_Product,
			p.Prod_Code,
			e.Event_Status,
			ps.ProdStatus_Desc,
			ps.Count_For_Production,
			ps.Count_For_Inventory,
			1.0,
			0
	FROM dbo.Events e WITH(NOLOCK)
		JOIN dbo.Event_Details ed WITH(NOLOCK) ON (e.Event_Id = ed.Event_Id)
		JOIN dbo.Production_Status ps WITH(NOLOCK) ON (ps.ProdStatus_Id = e.Event_Status)
		JOIN dbo.Products p WITH(NOLOCK) ON (p.Prod_Id = e.Applied_Product)
		JOIN dbo.Prod_Units pu WITH(NOLOCK) ON (pu.PU_Id = e.PU_Id)
		LEFT JOIN dbo.Production_Plan pp WITH(NOLOCK) ON (ed.PP_Id = pp.PP_Id)
	WHERE e.PU_Id IN (SELECT ParentPUId FROM @tblRMParentInfo )
		AND e.PU_Id = @BOMRMStoragePUId
		AND e.Applied_Product = @BOMRMProdId
		AND e.event_status IN (SELECT ValidInputStatusId FROM @tblInputValidStatus WHERE PEIId = @PEIId)  --added 16-March 2015
		AND ed.pp_Id = @ActPPId
			/*remove 16-March 2015
		--AND ps.Count_For_Production = 1
		--AND ps.Count_For_Inventory = 1
		*/
	ORDER BY e.TimeStamp
		
	IF @BOMRMSubProdId IS NOT NULL
		INSERT intO @tblRMInventorytmp(	
				RMPPId,
				RMProcessOrder,
				RMEventId, 
				RMEventNum, 
				RMEventTimeStamp, 
				RMPUId, 
				RMPUDesc, 
				RMInitDimX, 
				RMFinalDimX, 
				RMProdId, 
				RMProdCode,
				RMProdStatusId,
				RMProdStatusStr,
				CountForProduction,
				CountForInventory,
				RMSubConversionFactor,
				FlgSubstitute )	
	SELECT 		ed.PP_Id,
				pp.Process_Order,	
				e.Event_Id,
				e.Event_Num,
				e.TimeStamp,
				e.PU_Id,
				pu.PU_Desc,
				ed.Initial_Dimension_X,
				ed.Final_Dimension_X,
				e.Applied_Product,
				p.Prod_Code,
				e.Event_Status,
				ps.ProdStatus_Desc,
				ps.Count_For_Production,
				ps.Count_For_Inventory,
				@BOMRMSubConversionFactor,
				1
	FROM dbo.Events e
			JOIN dbo.Event_Details ed WITH(NOLOCK) ON (e.Event_Id = ed.Event_Id)
			JOIN dbo.Production_Status ps WITH(NOLOCK) ON (ps.ProdStatus_Id = e.Event_Status)
			JOIN dbo.Products p WITH(NOLOCK) ON (p.Prod_Id = e.Applied_Product)
			JOIN dbo.Prod_Units pu WITH(NOLOCK) ON (pu.PU_Id = e.PU_Id)
			LEFT JOIN dbo.Production_Plan pp WITH(NOLOCK) ON (ed.PP_Id = pp.PP_Id)
	WHERE e.PU_Id IN (SELECT ParentPUId FROM @tblRMParentInfo )
			AND e.PU_Id = @BOMRMStoragePUId
			AND e.Applied_Product = @BOMRMSubProdId
			AND e.event_status IN (SELECT ValidInputStatusId FROM @tblInputValidStatus WHERE PEIId = @PEIId)  --added 19-May 2015
			AND ed.pp_Id = @ActPPId  -- 1.27  It was commented.  I remove the comment to insure we get pallet only for the right PP_ID  
		/*remove 19-May 2015
		--AND ps.Count_For_Production = 1
		--AND ps.Count_For_Inventory = 1
		*/
	ORDER BY e.TimeStamp

	INSERT intO @tblRMInventory(
				RMPPId,
				RMProcessOrder,
				RMEventId, 
				RMEventNum, 
				RMEventTimeStamp, 
				RMPUId, 
				RMPUDesc, 
				RMInitDimX, 
				RMFinalDimX, 
				RMProdId, 
				RMProdCode,
				RMProdStatusId,
				RMProdStatusStr,
				CountForProduction,
				CountForInventory,
				RMSubConversionFactor,
				FlgSubstitute )	
		SELECT	RMPPId,
				RMProcessOrder,
				RMEventId, 
				RMEventNum, 
				RMEventTimeStamp,
				RMPUId, 
				RMPUDesc, 
				RMInitDimX, 
				RMFinalDimX, 
				RMProdId, 
				RMProdCode,
				RMProdStatusId,
				RMProdStatusStr,
				CountForProduction,
				CountForInventory,
				RMSubConversionFactor,
				FlgSubstitute
		FROM @tblRMInventorytmp
		ORDER BY RMEventTimeStamp

	IF @DebugFlagManual = 1
	BEGIN
		SELECT	'@FlgConsumptionType', @FlgConsumptionType, @BOMRMScrapFactor
	END

	--5a
	--Get the actual consumption according to the consumption type	

	--CASE THERORITICAL Consumption (Consumption Type = 1)
	IF @FlgConsumptionType = 1
	BEGIN

		--V1.9  Add usage of scrap factor
		IF @UsePathScrapFactor = 1 AND @BOMRMScrapFactor != 0 AND @BOMRMScrapFactor IS NOT NULL
		BEGIN
			SET @BOMRMQty = @BOMRMQty + (@ORBOMRMQty*(@BOMRMScrapFactor/100))  			
		END
		
		SET @RMTotConsumedQty =  CONVERT(DECIMAL(18,6), @BOMRMQty / @ActPPPlannedQty * @ProdCount)
		
	END
		
	
		
	--CASE REAL Consumption (Consumption Type = 2)
	IF @FlgConsumptionType = 2
	BEGIN
		--read the value of the consumption variable for this raw material input
		SET @RMTotConsumedQty =  (	SELECT COALESCE(CONVERT(float,Result),0) 
									FROM dbo.Tests
									WHERE Var_Id = @ConsumptionVarId
										AND Result_On = @TimeStamp)
											
		IF @RMTotConsumedQty IS NULL
			SET @RMTotConsumedQty = 0 
	END



	--CASE "Production counter matches one of the BOM elements" (Consumption Type = 3)
	IF @FlgConsumptionType = 3
	BEGIN
		
		IF @DebugFlagManual = 1
		BEGIN
			SELECT '@BOMRMProdGroupDesc', @BOMRMProdGroupDesc, '@UsePathScrapFactor', @UsePathScrapFactor, '@BOMRMScrapFactor', @BOMRMScrapFactor, '@BOMRMQty', @BOMRMQty, '@ORBOMRMQty', @ORBOMRMQty
		END
			
		SET @AdjustedProdCount = @ProdCount;

		--V1.9  Add usage of scrap factor
		IF @UsePathScrapFactor = 1 AND @BOMRMScrapFactor != 0 AND @BOMRMScrapFactor IS NOT NULL
		BEGIN
			IF @IsProductionCounter = 1
			BEGIN
				SET @AdjustedProdCount = @ProdCount + (@ProdCount*(@BOMRMScrapFactor/100))
			END
			ELSE
			BEGIN
				SET @BOMRMQty = @BOMRMQty + (@ORBOMRMQty*(@BOMRMScrapFactor/100))
			END
		END

		IF @IsProductionCounter = 1
		BEGIN		
			IF @DebugFlagManual = 1
			BEGIN
				SELECT	'@IsProductionCounter', @IsProductionCounter, '@BOMRMQty', @BOMRMQty, '@ActPPPlannedQty', @ActPPPlannedQty, '@ProdCount', @ProdCount
			END

			SET @RMTotConsumedQty =  CONVERT(DECIMAL(18,6), @AdjustedProdCount)			
		END
		ELSE
		BEGIN			
			IF @DebugFlagManual = 1
			BEGIN
				SELECT	'@IsProductionCounter', @IsProductionCounter, '@BOMRMQty', @BOMRMQty, '@IsProdCounterPOBOMQty', @IsProdCounterPOBOMQty, '@ProdCount', @ProdCount
			END

			SET @RMTotConsumedQty =  CONVERT(DECIMAL(18,6), @ProdCount / @IsProdCounterPOBOMQty * @BOMRMQty)
		END

	END

	
		
	IF @DebugFlagManual = 1
	BEGIN
		SELECT	'@RMTotConsumedQty', @RMTotConsumedQty
	END
			

	-------------------------------------------------------------------------------
	-- 5b. Retrieve the qty of the existing consumption (All the extsing event components)
	-------------------------------------------------------------------------------
	--Removed in V1.8  Replaced by query below
	--SET @RMTotConsumedQtyInactive = (SELECT coalesce(sum(coalesce(Dimension_X,0)),0)
	--								FROM dbo.Event_Components ec WITH(NOLOCK)
	--									JOIN @tblRMInventory rmi ON (rmi.RMEventId = ec.Source_Event_Id)
	--								WHERE	(rmi.CountForProduction = 1
	--										AND rmi.CountForInventory = 0)
	--										OR RMProdStatusStr  = @RMOverConsumedStatusStr  --Need to add "To be returned"
	--										AND ec.Event_Id = @EventId )


	--V 1.8  Get all pallet with a status not part of the valid status  
	SET @RMTotConsumedQtyInactive = (SELECT coalesce(sum(coalesce(Dimension_X,0)),0)
										FROM dbo.Event_Components ec WITH(NOLOCK)
										JOIN dbo.events rmi ON (rmi.Event_Id = ec.Source_Event_Id)
										WHERE rmi.event_status NOT IN (SELECT ValidInputStatusId FROM @tblInputValidStatus
																		WHERE PEIId = @PEIId)
											AND ec.Event_Id = @EventId
											AND rmi.applied_product IN (@BOMRMProdId,@BOMRMSubProdId)
											)




	-- Use the Valid Status
	SET @RMTotConsumedQtyActiveExisted = (SELECT coalesce(sum(coalesce(Dimension_X,0)),0)
										FROM dbo.Event_Components ec WITH(NOLOCK)
										JOIN dbo.events rmi ON (rmi.Event_Id = ec.Source_Event_Id)
										WHERE rmi.event_status in (SELECT ValidInputStatusId FROM @tblInputValidStatus
																		WHERE PEIId = @PEIId)
											AND ec.Event_Id = @EventId
											AND rmi.applied_product IN (@BOMRMProdId,@BOMRMSubProdId)
											)

IF @DebugFlagOnLine = 1
BEGIN
		INSERT intO Local_Debug(Timestamp, CallingSP, Message) 	VALUES(	getdate(), @spName,'@RMTotConsumedQtyInactive = ' +  CONVERT(Varchar(50),@RMTotConsumedQtyInactive))
		INSERT intO Local_Debug(Timestamp, CallingSP, Message) 	VALUES(	getdate(), @spName,'@RMTotConsumedQtyActiveExisted = ' +  CONVERT(Varchar(50),@RMTotConsumedQtyActiveExisted))
END											
	
	IF @DebugFlagManual = 1
	BEGIN
		Select	 @RMTotConsumedQtyInactive as '@RMTotConsumedQtyInactive', 
				@RMTotConsumedQtyActiveExisted as '@RMTotConsumedQtyActiveExisted'
	END
	
																																				
	SET @FlgNoAction = 0
	IF @RMTotConsumedQtyInactive + @RMTotConsumedQtyActiveExisted >= @RMTotConsumedQty	
	BEGIN
		SET @FlgNoAction = 1
				
		IF @DebugFlagOnLine = 1
			BEGIN
				INSERT intO Local_Debug(Timestamp, CallingSP, Message) 
					VALUES(	getdate(), 
							@spName,
							'0510' +
							' PUId=' + convert(varchar(5), @PUId) + 
							' TimeStamp=' + convert(varchar(25), @TimeStamp, 120) + 
										' PCount=' + coalesce(convert(varchar(30), @ProdCount), 'NoPCount') + 
											' EvtId='  + coalesce(convert(varchar(10), @EventId), 'NoEvtId') + 
											' EvtNum=' + coalesce(@EventNum, 'NoEvtNum') + 
											' PCode=' + coalesce(@ProdCode, 'NoPCode') + 
											' BOMPCode=' + coalesce(@BOMRMProdCode, 'NoBOMProdCode') + 						
											' BOMPU=' + coalesce(@BOMRMStoragePUDesc, 'NoBOMPU') + 						
											' RMTCQty=' + coalesce(convert(varchar(30), @RMTotConsumedQty), 'NoRMCQty') + 	
											' RMCQtyInAct=' + coalesce(convert(varchar(30), @RMTotConsumedQtyInactive), 'RMCInAct') + 	
											' RMCQtyActExisted=' + coalesce(convert(varchar(30), @RMTotConsumedQtyActiveExisted), 'NoRMCQtyActExisted') + 
											' No Action'
							)
			END
				
		GOTo SkipLinkUpdate
	END
			
	-------------------------------------------------------------------------------
	-- 5c. calculation the Consumed Qty of the Active Pallet
	-------------------------------------------------------------------------------											
	SET @RMTotConsumedQtyActiveShouldBe = convert(decimal(18,6),(@RMTotConsumedQty -  @RMTotConsumedQtyInactive))

	IF @DebugFlagOnLine = 1
	BEGIN
		INSERT intO Local_Debug(Timestamp, CallingSP, Message) 
		VALUES(	getdate(), 
				@spName,
				'0515' +
				' PUId=' + convert(varchar(5), @PUId) + 
				' TimeStamp=' + convert(varchar(25), @TimeStamp, 120) + 
							' PCount=' + coalesce(convert(varchar(30), @ProdCount), 'NoPCount') + 
								' EvtId='  + coalesce(convert(varchar(10), @EventId), 'NoEvtId') + 
								' EvtNum=' + coalesce(@EventNum, 'NoEvtNum') + 
								' PCode=' + coalesce(@ProdCode, 'NoPCode') + 
								' BOMPCode=' + coalesce(@BOMRMProdCode, 'NoBOMProdCode') + 						
								' BOMPU=' + coalesce(@BOMRMStoragePUDesc, 'NoBOMPU') + 						
								' RMTCQty=' + coalesce(convert(varchar(30), @RMTotConsumedQty), 'NoRMCQty') + 	
								' RMCQtyInAct=' + coalesce(convert(varchar(30), @RMTotConsumedQtyInactive), 'RMCInAct') + 	
								' RMCQtyActExisted=' + coalesce(convert(varchar(30), @RMTotConsumedQtyActiveExisted), 'NoRMCQtyActExisted') + 
								' RMCQtyActShouldBe=' + coalesce(convert(varchar(30), @RMTotConsumedQtyActiveShouldBe), 'NoRMCQtyActShouldBe')
				)
	END

	-------------------------------------------------------------------------------											
	-- 5d. Verify there is an active pallet
	--     If there is an active Pallet, then verify there is a genealogy link
	--		if there is no genealogy link, create one with the dimension_x = @RMTotConsumedQtyActiveShouldBe
	--		if there is a genealogy link, update the dimension_x = @RMTotConsumedQtyActiveShouldBe
	--	   If there is no active pallet, then over-consume the last Inactive pallet
	--			dimension_x = @RMTotConsumedQtyInactiveLast + @RMTotConsumedQtyActiveShouldBe
	-------------------------------------------------------------------------------		
				
	SET @FlgActivePalletExisted = 0
	SET @FlgConsumedPalletExisted = 0
	-------------------------------------------------------------------------------				
		-- search the Inactive Pallet (these are the pallet
		-- have already been consumed, overconsumed, or returned 
		-- before to check the active pallet to consumed the oversconsumed if it's the case
		-------------------------------------------------------------------------------		

	IF EXISTS(	SELECT RMEventId
	FROM @tblRMInventory rmi
		JOIN @tblInputValidStatus ivs ON (rmi.RMProdStatusId = ValidInputStatusId)
	WHERE ivs.PEIId = @PEIId)
	-------------------------------------------------------------------------------				
	-- Active Pallet Existed
	-------------------------------------------------------------------------------				
	BEGIN
		SET @FlgActivePalletExisted = 1


		IF @DebugFlagOnLine = 1
		BEGIN
				INSERT intO Local_Debug(Timestamp, CallingSP, Message) 	VALUES(	getdate(), @spName,'@FlgActivePalletExisted = ' +  CONVERT(Varchar(50),@FlgActivePalletExisted))
		END	
				
		SELECT Top 1 @RMEventId = RMEventId
		FROM @tblRMInventory rmi
			JOIN @tblInputValidStatus ivs ON (rmi.RMProdStatusId = ValidInputStatusId)
		WHERE ivs.PEIId = @PEIId
		ORDER BY RMEventTimeStamp
					
		SELECT	@RMEventNum = RMEventNum,
				@RMProdStatusStr = RMProdStatusStr
		FROM @tblRMInventory
		WHERE RMEventId = @RMEventId

		IF @DebugFlagOnLine = 1
		BEGIN
				INSERT intO Local_Debug(Timestamp, CallingSP, Message, msg) 	VALUES(	getdate(), @spName,'@RMEventId = ' +  CONVERT(Varchar(50),@RMEventId), convert(Varchar(30),@BOMRMProdId))
		END	


		-------------------------------------------------
		--1.22
		--Trap case where there is more than on Pallet Active partially consumed
		--We need to exclude the quantity already consumed by the other pallets
		-------------------------------------------------
		SET @OtherActivePalletQty = 0

		SET @ThisPalletQty = 0
		SELECT @ThisPalletQty = dimension_x 
		FROM dbo.Event_Components WITH(NOLOCK) 
		WHERE Source_Event_Id = @RMEventId
				AND Event_Id = @EventId

		--Active quantity from other pallet (it means those are partillay consumed pallet)
		SELECT @OtherActivePalletQty = @RMTotConsumedQtyActiveExisted-@ThisPalletQty

		--Quantity of material that need to be consumed on the real active pallet (running pallet)
		SELECT @RMTotConsumedQtyActiveShouldBe = @RMTotConsumedQtyActiveShouldBe - @OtherActivePalletQty
		--END OF 1.22 ADDED CODE


		SELECT @RMTotConsumedQtyActiveShouldBe = ROUND(@RMTotConsumedQtyActiveShouldBe,3)  --1.24
		------------------------------------------------------------------

		IF @DebugFlagOnLine = 1
		BEGIN
				INSERT intO Local_Debug(Timestamp, CallingSP, Message,msg) 	VALUES(	getdate(), @spName,
				'@OtherActivePalletQty = ' +  CONVERT(Varchar(50),@OtherActivePalletQty) + 
				' @RMTotConsumedQtyActiveExisted = ' +  CONVERT(Varchar(50),@RMTotConsumedQtyActiveExisted) + 
				' @ThisPalletQty = ' +  CONVERT(Varchar(50),@ThisPalletQty)+
				' @RMTotConsumedQtyActiveShouldBe = ' +  CONVERT(Varchar(50),@RMTotConsumedQtyActiveShouldBe) ,
				CONVERT(Varchar(30),@BOMRMProdId)
				)
		END	

				
			

		IF EXISTS(	SELECT Component_Id
					FROM dbo.Event_Components WITH(NOLOCK)
					WHERE Source_Event_Id = @RMEventId
						AND Event_Id = @EventId)
		BEGIN
			-------------------------------------------------------------------------------				
			-- Active Pallet Genealogy Link Existed
			-- Update the link
			-------------------------------------------------------------------------------	
			SELECT	@ComponentId = Component_Id
					FROM dbo.Event_Components WITH(NOLOCK)
					WHERE Source_Event_Id = @RMEventId
						AND Event_Id = @EventId

			SELECT	@ParmComponentId		= Component_Id,
					@ParmEventId			= Event_Id,
					@ParmSourceEventId		= Source_Event_Id,
					@ParmDimensionX			= Dimension_X,
					@ParmDimensionY			= Dimension_Y,
					@ParmDimensionZ			= @RMTotConsumedQtyActiveShouldBe,
					@ParmDimensionA			= Dimension_A,
					@ParmStartCoordinateX	= Start_Coordinate_X,
					@ParmStartCoordinateY	= Start_Coordinate_Y,
					@ParmStartCoordinateZ	= Start_Coordinate_Z,
					@ParmStartCoordinateA	= Start_Coordinate_A,
					@ParmStartTime			= Start_Time,
					@ParmTimeStamp			= [TimeStamp],
					@ParmParentComponentId  = Parent_Component_Id,
					@ParmExtendedInfo		= Extended_Info,
					@ParmPEIId				= PEI_Id,
					@ParmReportAsConsumption= Report_As_Consumption,
					@ParmSignatureId		= Signature_Id
			FROM dbo.Event_Components WITH(NOLOCK) 
			WHERE Component_Id = @ComponentId
						
					
						
			IF @DebugFlagManual = '0'
			BEGIN
				Exec spServer_DBMgrUpdEventComp
				@DefaultUserId			,
				@ParmEventId			, 
				@ParmComponentId		OUTPUT, 
				@ParmSourceEventId		, 
				@RMTotConsumedQtyActiveShouldBe		,
				@ParmDimensionY			,
				@ParmDimensionZ			,
				@ParmDimensionA			,
				0						,		-- TranNum
				2						,		-- TransType
				@ParmChildUnitId		OUTPUT,				
				@ParmStartCoordinateX	,
				@ParmStartCoordinateY	,
				@ParmStartCoordinateZ	,
				@ParmStartCoordinateA	,
				@ParmTimeStamp			,		-- StartTime
				@TimeStamp			,		-- TimeStamp
				@ParmParentComponentId	, 
				@ParmEntryOn			OUTPUT, 
				NULL				,		-- ExtendedInfo
				@ParmPEIId				OUTPUT,
				@ParmReportAsConsumption	


				INSERT	@tblEventComponentUpds (Pre, UserId, TransactionType,		
				TransactionNumber, ComponentId, EventId, SrcEventId, 
				DimX,DimY, DimZ, DimA, 
				StartCoordinateX, StartCoordinateY, StartCoordinateZ, StartCoordinateA,
				StartTime, TimeStamp, PPComponentId, EntryOn, ExtendedInfo,
				PEIId, ReportAsConsumption, ESignatureId )

				SELECT	0, @DefaultUserId, 2,
				0, Component_Id, Event_Id, Source_Event_Id, 
				@RMTotConsumedQtyActiveShouldBe,Dimension_Y, Dimension_Z, Dimension_A, 
				Start_Coordinate_X,Start_Coordinate_Y, Start_Coordinate_Z, Start_Coordinate_A, 
				Start_Time, @TimeStamp, Parent_Component_Id, Entry_On, Extended_Info,
				PEI_Id, Report_As_Consumption, Signature_Id 
				FROM	dbo.Event_Components WITH(NOLOCK)
				WHERE	Component_Id = @ComponentId				
			END		
	
	
			-------------------------------------------------------------------------------	
			--V1.22 2-Sep-2015
			-- Update the Pallet Event Status to 'Running' if it was not
			-------------------------------------------------------------------------------	
			IF 	@RMProdStatusStr <> @RMRunningStatusStr 
			BEGIN						
				INSERT	@tblEventUpds (TransactionType, EventId, EventNum, PUId, TimeStamp,       
					AppliedProduct, SourceEvent, EventStatus, Confirmed, UserId, PostUpdate,
					Conformance, TestPctComplete, StartTime, TransNum, TestingStatus, CommentId,
					EventSubTypeId, EntryOn,
					ApprovedUserId, SecondUserId, ApprovedReasonId, UserReasonId, UserSignOffId, ExtendedInfo)
					SELECT	2, Event_Id, Event_Num, PU_Id, TimeStamp,
							Applied_Product, Source_Event, @RMRunningStatusId, Confirmed, @DefaultUserId, 0,
							Conformance, Testing_Prct_Complete, Start_Time, 0, Testing_Status, 
							Comment_Id, Event_SubType_Id, Entry_On,
							Approver_User_Id, Second_User_Id, Approver_Reason_Id, User_Reason_Id, User_SignOff_Id, Extended_Info
					FROM	dbo.Events WITH(NOLOCK)
					WHERE	Event_Id = @RMEventId			
			END
	
	
	
																				
			-------------------------------------------------------------------------------									
			-- 	Send a Pending Task to the parent to execute the Event-Based
			--	Calculation - mainly to update the final dimensions	
			-------------------------------------------------------------------------------	
			INSERT	dbo.PendingTasks	(TimeStamp, PU_Id, ActualId, TaskId)
			SELECT	[Timestamp], PU_Id, Event_Id, 5
			FROM	dbo.Events WITH(NOLOCK)
			WHERE	Event_Id = @RMEventId
				-------------------------------------------------------------------------------													
			IF @DebugFlagOnLine = 1
			BEGIN
				INSERT intO Local_Debug(Timestamp, CallingSP, Message) 
				VALUES(	getdate(), 
						@spName,
						'0520' +
						' PUId=' + convert(varchar(5), @PUId) + 
						' TimeStamp=' + convert(varchar(25), @TimeStamp, 120) + 
						' PCount=' + coalesce(convert(varchar(10), @ProdCount), 'NoPCount') + 
						' EvtId='  + coalesce(convert(varchar(10), @EventId), 'NoEvtId') + 
						' EvtNum=' + coalesce(@EventNum, 'NoEvtNum') + 
						' PCode=' + coalesce(@ProdCode, 'NoPCode') + 
						' BOMPCode=' + coalesce(@BOMRMProdCode, 'NoBOMProdCode') + 						
						' BOMPU=' + coalesce(@BOMRMStoragePUDesc, 'NoBOMPU') + 						
						' RMTCQty=' + coalesce(convert(varchar(30), @RMTotConsumedQty), 'NoRMCQty') + 	
						' RMCQtyInAct=' + coalesce(convert(varchar(30), @RMTotConsumedQtyInactive), 'RMCInAct') + 	
						' RMCQtyActExist=' + coalesce(convert(varchar(30), @RMTotConsumedQtyActiveExisted), 'NoRMCQtyActExisted') + 
						' RMCQtyActShouldBe=' + coalesce(convert(varchar(30), @RMTotConsumedQtyActiveShouldBe), 'NoRMCQtyActShouldBe') +
						' RMEvtNum =' + coalesce(@RMEventNum, 'NoRMEventNum') + 
						' CompId='  + coalesce(convert(varchar(10), @ComponentId), 'NoCompId') + 
						' Update Active Link'
				)
			END
		END
		ELSE
		BEGIN
			-------------------------------------------------------------------------------				
			-- Active Pallet Genealogy Link Not Existed
			-- Create the link
			-------------------------------------------------------------------------------
			SELECT	@ParmComponentId		= NULL,
					@ParmEventId			= NULL,
					@ParmSourceEventId		= NULL,
					@ParmDimensionX			= NULL,
					@ParmDimensionY			= NULL,
					@ParmDimensionZ			= NULL,
					@ParmDimensionA			= NULL,
					@ParmStartCoordinateX	= NULL,
					@ParmStartCoordinateY	= NULL,
					@ParmStartCoordinateZ	= NULL,
					@ParmStartCoordinateA	= NULL,
					@ParmStartTime			= NULL,
					@ParmTimeStamp			= NULL,
					@ParmParentComponentId  = NULL,
					@ParmExtendedInfo		= NULL,
					@ParmPEIId				= NULL,
					@ParmReportAsConsumption= NULL,
					@ParmSignatureId		= NULL
							

					SET @ParmDimensionX =  @RMTotConsumedQtyActiveShouldBe
					SET @ParmTimeStamp = getdate()
					IF @DebugFlagManual = '0'
					BEGIN
						Exec spServer_DBMgrUpdEventComp
						@DefaultUserId			,
						@EventId			, 
						@ParmComponentId		OUTPUT, 
						@RMEventId		, 
						@RMTotConsumedQtyActiveShouldBe			,
						0			,
						0			,
						0			,
						0						,		-- TranNum
						1						,		-- TransType
						@ParmChildUnitId		OUTPUT,				
						NULL	,
						NULL	,
						NULL	,
						NULL	,
						@TimeStamp			,		-- StartTime
						@TimeStamp			,		-- TimeStamp
						NULL	, 
						@CurrentTime			OUTPUT, 
						NULL				,		-- ExtendedInfo
						@PEIId				OUTPUT,
						@FlgReportAsConsumption	

								
					INSERT	@tblEventComponentUpds (Pre, UserId, TransactionType,		
						TransactionNumber, ComponentId, EventId, SrcEventId, 
						DimX,DimY, DimZ, DimA, 
						StartCoordinateX, StartCoordinateY, StartCoordinateZ, StartCoordinateA,
						StartTime, TimeStamp, PPComponentId, EntryOn, ExtendedInfo,
						PEIId, ReportAsConsumption, ESignatureId )

						VALUES	(1, @DefaultUserId, 1,
						0, NULL, @EventId, @RMEventId,  @RMTotConsumedQtyActiveShouldBe,
						0, 0, 0, NULL, NULL, NULL, NULL,
						@TimeStamp, @TimeStamp, NULL, getdate(), NULL,
						@PEIId, @FlgReportAsConsumption, NULL)
					END
					ELSE
					BEGIN
						INSERT	@tblEventComponentUpds (Pre, UserId, TransactionType,		
						TransactionNumber, ComponentId, EventId, SrcEventId, 
						DimX,DimY, DimZ, DimA, 
						StartCoordinateX, StartCoordinateY, StartCoordinateZ, StartCoordinateA,
						StartTime, TimeStamp, PPComponentId, EntryOn, ExtendedInfo,
						PEIId, ReportAsConsumption, ESignatureId )

						VALUES	(1, @DefaultUserId, 1,
						0, NULL, @EventId, @RMEventId,  @RMTotConsumedQtyActiveShouldBe,
						0, 0, 0, NULL, NULL, NULL, NULL,
						@TimeStamp, @TimeStamp, NULL, getdate(), NULL,
							@PEIId, @FlgReportAsConsumption, NULL)
					END
					
			-------------------------------------------------------------------------------	
			-- Update the Pallet Event Status to 'Running'
			-------------------------------------------------------------------------------	
			IF 	@RMProdStatusStr <> @RMRunningStatusStr
			BEGIN						
				INSERT	@tblEventUpds (TransactionType, EventId, EventNum, PUId, TimeStamp,       
					AppliedProduct, SourceEvent, EventStatus, Confirmed, UserId, PostUpdate,
					Conformance, TestPctComplete, StartTime, TransNum, TestingStatus, CommentId,
					EventSubTypeId, EntryOn,
					ApprovedUserId, SecondUserId, ApprovedReasonId, UserReasonId, UserSignOffId, ExtendedInfo)
					SELECT	2, Event_Id, Event_Num, PU_Id, TimeStamp,
							Applied_Product, Source_Event, @RMRunningStatusId, Confirmed, @DefaultUserId, 0,
							Conformance, Testing_Prct_Complete, Start_Time, 0, Testing_Status, 
							Comment_Id, Event_SubType_Id, Entry_On,
							Approver_User_Id, Second_User_Id, Approver_Reason_Id, User_Reason_Id, User_SignOff_Id, Extended_Info
					FROM	dbo.Events WITH(NOLOCK)
					WHERE	Event_Id = @RMEventId			
			END

			-------------------------------------------------------------------------------									
			-- 	Send a Pending Task to the parent to execute the Event-Based
			--	Calculation - mainly to update the final dimensions	
			-------------------------------------------------------------------------------	
			INSERT	dbo.PendingTasks	(TimeStamp, PU_Id, ActualId, TaskId)
			SELECT	[Timestamp], PU_Id, Event_Id, 5
			FROM	dbo.Events WITH(NOLOCK)
			WHERE	Event_Id = @RMEventId
								
			IF @DebugFlagOnLine = 1
			BEGIN 
				INSERT intO Local_Debug(Timestamp, CallingSP, Message) 
					VALUES(	getdate(), 
							@spName,
							'0530' +
							' PUId=' + convert(varchar(5), @PUId) + 
							' TimeStamp=' + convert(varchar(25), @TimeStamp, 120) + 
							' PCount=' + coalesce(convert(varchar(30), @ProdCount), 'NoPCount') + 
							' EvtId='  + coalesce(convert(varchar(10), @EventId), 'NoEvtId') + 
							' EvtNum=' + coalesce(@EventNum, 'NoEvtNum') + 
							' PCode=' + coalesce(@ProdCode, 'NoPCode') + 
							' BOMPCode=' + coalesce(@BOMRMProdCode, 'NoBOMProdCode') + 						
							' BOMPU=' + coalesce(@BOMRMStoragePUDesc, 'NoBOMPU') + 						
							' RMTCQty=' + coalesce(convert(varchar(30), @RMTotConsumedQty), 'NoRMCQty') + 	
							' RMCQtyInAct=' + coalesce(convert(varchar(30), @RMTotConsumedQtyInactive), 'RMCInAct') + 	
							' RMCQtyActExist=' + coalesce(convert(varchar(30), @RMTotConsumedQtyActiveExisted), 'NoRMCQtyActExisted') + 
							' RMCQtyActShouldBe=' + coalesce(convert(varchar(30), @RMTotConsumedQtyActiveShouldBe), 'NoRMCQtyActShouldBe') +
							' RMEvtNum =' + coalesce(@RMEventNum, 'NoRMEvtNum') + 
							' Create Active Link'
							)
			END
		END
	END								


	IF 	@FlgActivePalletExisted = 0
	BEGIN
		SET @RMEventId = NULL

		--V1.8 removed
		--SELECT Top 1 @RMEventId = RMEventId
		--FROM @tblRMInventory
		--WHERE	CountForProduction	= 1
		--	AND CountForInventory	= 0
		--	OR  RMProdStatusStr  = @RMOverConsumedStatusStr 
		--ORDER BY RMEventTimeStamp DESC

		--V1.8 Added
		SELECT TOP 1 @RMEventId = ec.source_event_id
		FROM dbo.event_components ec	WITH(NOLOCK)
		JOIN dbo.events e				WITH(NOLOCK)	ON	ec.source_event_id = e.event_id
																AND	ec.event_id = @EventId
		WHERE (e.applied_product =@BOMRMProdId OR e.applied_product = @BOMRMSubProdId)
		--ORDER BY ec.ENTRY_ON DESC
		ORDER BY e.timestamp DESC

			
		IF 	@RMEventId IS NULL
		BEGIN
	
				SELECT TOP 1 @RMEventId = e.event_id
				FROM dbo.event_details ed	WITH(NOLOCK)
				JOIN dbo.events e				WITH(NOLOCK)	ON	ed.event_id = e.event_id
																		AND	ed.PP_id = @PPId
				WHERE (e.applied_product =@BOMRMProdId OR e.applied_product = @BOMRMSubProdId)
				AND	e.Event_Status = @RMOverConsumedStatusId
				AND ed.Final_dimension_X < 0.1   -- to avoid pallet with consumption issue
				ORDER BY e.timestamp DESC
		END

		IF @DebugFlagOnLine = 1
		BEGIN
				INSERT intO Local_Debug(Timestamp, CallingSP, Message) 	VALUES(	getdate(), @spName,'@FlgActivePalletExisted= ' +  CONVERT(Varchar(50),@FlgActivePalletExisted))
				INSERT intO Local_Debug(Timestamp, CallingSP, Message) 	VALUES(	getdate(), @spName,'@RMEventId= ' +  CONVERT(Varchar(50),@RMEventId))
		END	
				

		IF  @RMEventId IS NOT NULL
		BEGIN
			SET @FlgConsumedPalletExisted  =1
			SELECT	@RMEventNum = event_num,
					@RMProdStatusStr = ps.prodStatus_Desc
			FROM dbo.events e
			JOIN dbo.production_status ps ON e.event_status = ps.prodStatus_id
			WHERE e.event_id = @RMEventId

			IF EXISTS(	SELECT Component_Id
						FROM dbo.Event_Components WITH(NOLOCK)
						WHERE Source_Event_Id = @RMEventId
							AND Event_Id = @EventId)							
			BEGIN
				-------------------------------------------------------------------------------				
				-- InActive Pallet Genealogy Link Existed
				-- Update the link
				--			@RMOverConsumedQtyExisted		float,
				-------------------------------------------------------------------------------
							
				SELECT	@ComponentId		= Component_Id,
						@ParmEventId			= Event_Id,
						@ParmSourceEventId		= Source_Event_Id,
						@RMOverConsumedQtyExisted			=coalesce(Dimension_X,0),
						@ParmDimensionY			= Dimension_Y,
						@ParmDimensionZ			= Dimension_Z,
						@ParmDimensionA			= Dimension_A,
						@ParmStartCoordinateX	= Start_Coordinate_X,
						@ParmStartCoordinateY	= Start_Coordinate_Y,
						@ParmStartCoordinateZ	= Start_Coordinate_Z,
						@ParmStartCoordinateA	= Start_Coordinate_A,
						@ParmStartTime			= Start_Time,
						@ParmTimeStamp			= [TimeStamp],
						@ParmParentComponentId  = Parent_Component_Id,
						@ParmExtendedInfo		= Extended_Info,
						@ParmPEIId				= PEI_Id,
						@ParmReportAsConsumption= Report_As_Consumption,
						@ParmSignatureId		= Signature_Id
				FROM dbo.Event_Components WITH(NOLOCK) 
				WHERE Source_Event_Id = @RMEventId
						AND Event_Id = @EventId


				SET @ParmDimensionX = (@RMOverConsumedQtyExisted + @RMTotConsumedQtyActiveShouldBe)

				SELECT @ParmDimensionX = ROUND(@ParmDimensionX,3)  --1.24

				SET @ParmTimeStamp = getdate()
				IF @DebugFlagManual = '0'
				BEGIN
					Exec spServer_DBMgrUpdEventComp
					@DefaultUserId			,
					@ParmEventId			, 
					@ComponentId		OUTPUT, 
					@ParmSourceEventId		, 
					@ParmDimensionX			,
					@ParmDimensionY			,
					@ParmDimensionZ			,
					@ParmDimensionA			,
					0						,		-- TranNum
					2						,		-- TransType
					@ParmChildUnitId		OUTPUT,				
					@ParmStartCoordinateX	,
					@ParmStartCoordinateY	,
					@ParmStartCoordinateZ	,
					@ParmStartCoordinateA	,
					@ParmTimeStamp			,		-- StartTime
					@ParmTimeStamp			,		-- TimeStamp
					@ParmParentComponentId	, 
					@ParmEntryOn			OUTPUT, 
					NULL				,		-- ExtendedInfo
					@ParmPEIId				OUTPUT,
					@ParmReportAsConsumption	

								
					INSERT	@tblEventComponentUpds (Pre, UserId, TransactionType,		
						TransactionNumber, ComponentId, EventId, SrcEventId, 
						DimX,DimY, DimZ, DimA, 
						StartCoordinateX, StartCoordinateY, StartCoordinateZ, StartCoordinateA,
						StartTime, TimeStamp, PPComponentId, EntryOn, ExtendedInfo,
						PEIId, ReportAsConsumption, ESignatureId )

					SELECT	0, @DefaultUserId, 2,
						0, Component_Id, Event_Id, Source_Event_Id, 
						@ParmDimensionX,Dimension_Y, Dimension_Z, Dimension_A, 
						Start_Coordinate_X,Start_Coordinate_Y, Start_Coordinate_Z, Start_Coordinate_A, 
						Start_Time,@ParmTimeStamp, Parent_Component_Id, Entry_On, Extended_Info,
						PEI_Id, Report_As_Consumption, Signature_Id 
					FROM	dbo.Event_Components WITH(NOLOCK)
					WHERE	Component_Id = @ComponentId									
				END
				ELSE
				BEGIN
										
					INSERT	@tblEventComponentUpds (Pre, UserId, TransactionType,		
						TransactionNumber, ComponentId, EventId, SrcEventId, 
						DimX,DimY, DimZ, DimA, 
						StartCoordinateX, StartCoordinateY, StartCoordinateZ, StartCoordinateA,
						StartTime, TimeStamp, PPComponentId, EntryOn, ExtendedInfo,
						PEIId, ReportAsConsumption, ESignatureId )

					SELECT	0, @DefaultUserId, 2,
						0, Component_Id, Event_Id, Source_Event_Id, 
						@ParmDimensionX,Dimension_Y, Dimension_Z, Dimension_A, 
						Start_Coordinate_X,Start_Coordinate_Y, Start_Coordinate_Z, Start_Coordinate_A, 
						Start_Time,@ParmTimeStamp, Parent_Component_Id, Entry_On, Extended_Info,
						PEI_Id, Report_As_Consumption, Signature_Id 
					FROM	dbo.Event_Components WITH(NOLOCK)
					WHERE	Component_Id = @ComponentId			
				END
									
				-------------------------------------------------------------------------------									
				-- 	Send a Pending Task to the parent to execute the Event-Based
				--	Calculation - mainly to update the final dimensions	
				-------------------------------------------------------------------------------	
				INSERT	dbo.PendingTasks	(TimeStamp, PU_Id, ActualId, TaskId)
				SELECT	[Timestamp], PU_Id, Event_Id, 5
				FROM	dbo.Events WITH(NOLOCK)
				WHERE	Event_Id = @RMEventId
														
				IF @DebugFlagOnLine = 1 
				BEGIN 
					INSERT intO Local_Debug(Timestamp, CallingSP, Message) 
					VALUES(	getdate(), 
							@spName,
							'0540' +
							' PUId=' + convert(varchar(5), @PUId) + 
							' TimeStamp=' + convert(varchar(25), @TimeStamp, 120) + 
							' PCount=' + coalesce(convert(varchar(30), @ProdCount), 'NoPCount') + 
							' EvtId='  + coalesce(convert(varchar(10), @EventId), 'NoEvtId') + 
							' EvtNum=' + coalesce(@EventNum, 'NoEvtNum') + 
							' PCode=' + coalesce(@ProdCode, 'NoPCode') + 
							' BOMPCode=' + coalesce(@BOMRMProdCode, 'NoBOMProdCode') + 						
							' BOMPU=' + coalesce(@BOMRMStoragePUDesc, 'NoBOMPU') + 						
							' RMTCQty=' + coalesce(convert(varchar(30), @RMTotConsumedQty), 'NoRMCQty') + 	
							' RMCQtyInAct=' + coalesce(convert(varchar(30), @RMTotConsumedQtyInactive), 'RMCInAct') + 	
							' RMCQtyActExist=' + coalesce(convert(varchar(30), @RMTotConsumedQtyActiveExisted), 'NoRMCQtyActExisted') + 
							' RMOCQtyExist=' + coalesce(convert(varchar(30), @RMOverConsumedQtyExisted), 'NoRMOCExisted') + 
							' RMCQtyActShouldBe=' + coalesce(convert(varchar(30), @RMTotConsumedQtyActiveShouldBe), 'NoRMCQtyActShouldBe') +
							' RMEvtNum =' + coalesce(@RMEventNum, 'NoRMEvtNum') + 
							' CompId='  + coalesce(convert(varchar(10), @ComponentId), 'NoCompId') + 
							' Update InActive Link'
							)
				END
			END					
			ELSE
																																																																									BEGIN
					-------------------------------------------------------------------------------				
					-- InActive Pallet Genealogy Link Not Existed
					-- Create the link
					-- If there is no existing inactive genealogy link, log the error
					-------------------------------------------------------------------------------		

					
					INSERT	@tblEventComponentUpds (Pre, UserId, TransactionType,
							TransactionNumber, ComponentId, EventId, SrcEventId, DimX,
							DimY, DimZ, DimA, StartCoordinateX, StartCoordinateY, StartCoordinateZ, StartCoordinateA,
							StartTime, TimeStamp, PPComponentId, EntryOn, ExtendedInfo,
							PEIId, ReportAsConsumption, ESignatureId )
							VALUES	(1, @DefaultUserId, 1,
							0, NULL, @EventId, @RMEventId,  @RMTotConsumedQtyActiveShouldBe,
							0, 0, 0, NULL, NULL, NULL, NULL,
							getdate(), getdate(), NULL, getdate(), @RMTagOverConsumed,
							@PEIId, @FlgReportAsConsumption, NULL)

					-------------------------------------------------------------------------------	
					-- Update the Pallet Event Status to 'OverConsumed'
					-------------------------------------------------------------------------------	
					/*IF 	@RMProdStatusStr <> @RMOverConsumedStatusStr
					BEGIN						
						INSERT	@tblEventUpds (TransactionType, EventId, EventNum, PUId, TimeStamp,       
							AppliedProduct, SourceEvent, EventStatus, Confirmed, UserId, PostUpdate,
							Conformance, TestPctComplete, StartTime, TransNum, TestingStatus, CommentId,
							EventSubTypeId, EntryOn,
							ApprovedUserId, SecondUserId, ApprovedReasonId, UserReasonId, UserSignOffId, ExtendedInfo)
							SELECT	2, Event_Id, Event_Num, PU_Id, TimeStamp,
									Applied_Product, Source_Event, @RMOverConsumedStatusId, Confirmed, @DefaultUserId, 0,
									Conformance, Testing_Prct_Complete, Start_Time, 0, Testing_Status, 
									Comment_Id, Event_SubType_Id, Entry_On,
									Approver_User_Id, Second_User_Id, Approver_Reason_Id, User_Reason_Id, User_SignOff_Id, Extended_Info
									FROM	dbo.Events
									WHERE	Event_Id = @RMEventId			
					END*/
								
					-------------------------------------------------------------------------------									
					-- 	Send a Pending Task to the parent to execute the Event-Based
					--	Calculation - mainly to update the final dimensions	
					-------------------------------------------------------------------------------	
					INSERT	dbo.PendingTasks	(TimeStamp, PU_Id, ActualId, TaskId)
						SELECT	[Timestamp], PU_Id, Event_Id, 5
							FROM	dbo.Events WITH(NOLOCK)
							WHERE	Event_Id = @RMEventId
					
				IF @DebugFlagOnLine = 1  
					BEGIN
						INSERT intO Local_Debug(Timestamp, CallingSP, Message) 
							VALUES(	getdate(), 
									@spName,
									'0550' +
									' PUId=' + convert(varchar(5), @PUId) + 
									' TimeStamp=' + convert(varchar(25), @TimeStamp, 120) + 
									' PCount=' + coalesce(convert(varchar(10), @ProdCount), 'NoPCount') + 
									' EvtId='  + coalesce(convert(varchar(10), @EventId), 'NoEvtId') + 
									' EvtNum=' + coalesce(@EventNum, 'NoEvtNum') + 
									' PCode=' + coalesce(@ProdCode, 'NoPCode') + 
									' BOMPCode=' + coalesce(@BOMRMProdCode, 'NoBOMProdCode') + 						
									' BOMPU=' + coalesce(@BOMRMStoragePUDesc, 'NoBOMPU') + 						
									' RMTCQty=' + coalesce(convert(varchar(30), @RMTotConsumedQty), 'NoRMCQty') + 	
									' RMCQtyInAct=' + coalesce(convert(varchar(30), @RMTotConsumedQtyInactive), 'RMCInAct') + 	
									' RMCQtyActExist=' + coalesce(convert(varchar(30), @RMTotConsumedQtyActiveExisted), 'NoRMCQtyActExisted') + 
									' RMCQtyActShouldBe=' + coalesce(convert(varchar(30), @RMTotConsumedQtyActiveShouldBe), 'NoRMCQtyActShouldBe') +
									' RMEvtNum =' + coalesce(@RMEventNum, 'NoRMEvtNum') + 
									' No exisitng Inactive Link'
									)
					END
			END
		END
					
	END
		

	IF @DebugFlagOnLine = 1  
	BEGIN
		INSERT intO Local_Debug(Timestamp, CallingSP, Message) 
		VALUES(	getdate(), 
				@spName,
				'0560' +
				' PUId=' + convert(varchar(5), @PUId) + 
				' TimeStamp=' + convert(varchar(25), @TimeStamp, 120) + 
				' PCount=' + coalesce(convert(varchar(10), @ProdCount), 'NoProdCount') + 
				' EvtId='  + coalesce(convert(varchar(10), @EventId), 'NoEventId') + 
				' EvtNum=' + coalesce(@EventNum, 'NoEventNum') +
				' Finish Genealogy Link')
	END
			
	SkipLinkUpdate:				
	IF @DebugFlagManual = 1
	BEGIN
		SELECT '@tblRMInventory', * FROM @tblRMInventory
		SELECT	@PEIId							AS PEIId,
				@PEIInputName					AS PEIInputName,
				@BOMRMQty						AS BOMRMQty,
				@ActPPPlannedQty				AS ActPPPlannedQty,
				@ProdCount						AS ProdCount,
				@RMTotConsumedQty				AS RMTotConsumedQty,
				@RMTotConsumedQtyInactive		AS RMTotConsumedQtyInactive,
				@RMTotConsumedQtyActiveExisted	AS RMTotConsumedQtyActiveExisted,
				@RMTotConsumedQtyActiveShouldBe	AS RMTotConsumedQtyActiveShouldBe,
				@RMOverConsumedQtyExisted		AS RMOverConsumedQtyExisted,
				@FlgNoAction					AS FlgNoAction																				
	END							
	SELECT @LoopIndex = @LoopIndex + 1
END

SET @CalcErrMsg = @CalcErrMsg + ';Finish Genealogy Link'

-------------------------------------------------------------------------------
-- 6 - Termination Block
-- Output the Result Sets.
-------------------------------------------------------------------------------
SendResultSets:
-------------------------------------------------------------------------------
-- Return ResultSet.
-------------------------------------------------------------------------------
IF @DebugFlagOnLine = 1 
BEGIN
	INSERT intO Local_Debug(Timestamp, CallingSP, Message) 
				VALUES(	getdate(), 
						@spName,
						'0610' +
						' PUId=' + convert(varchar(5), @PUId) + 
						' TimeStamp=' + convert(varchar(25), @TimeStamp, 120) + 
						' PCount=' + coalesce(convert(varchar(10), @ProdCount), 'NoPCount') + 
						' EvtId='  + coalesce(convert(varchar(10), @EventId), 'NoEvtId') + 
						' EvtNum=' + coalesce(@EventNum, 'NoEvtNum') +
						' Send Result Sets'
						)
END

SELECT	1 ResultType, Id, TransactionType, EventId, EventNum, PUId,
		convert(varChar(25), TimeStamp, 120) TimeStamp, AppliedProduct,
		SourceEvent, EventStatus, Confirmed, UserId, PostUpdate, Conformance,
		TestPctComplete, StartTime, TransNum, TestingStatus, CommentId,
		EventSubTypeId, EntryOn,
		ApprovedUserId, SecondUserId, ApprovedReasonId, UserReasonId, UserSignOffId, ExtendedInfo
FROM	@tblEventUpds

SELECT	11 ResultType, Pre, UserId, TransactionType, TransactionNumber,
		ComponentId, EventId, SrcEventId, DimX, DimY, DimZ, DimA,
		StartCoordinateX, StartCoordinateY, StartCoordinateZ, StartCoordinateA,
		StartTime, TimeStamp, PPComponentId, EntryOn, ExtendedInfo,
		PEIId, ReportAsConsumption, ChildUnitId, ESignatureId 
FROM	@tblEventComponentUpds

SET @CalcErrMsg = @CalcErrMsg + ';Finish'

IF @DebugFlagOnLine = 1 
BEGIN
	INSERT intO Local_Debug(Timestamp, CallingSP, Message) 
				VALUES(	getdate(), 
						@spName,
						'0620' +
						' PUId=' + convert(varchar(5), @PUId) + 
						' TimeStamp=' + convert(varchar(25), @TimeStamp, 120) + 
						' PCount=' + coalesce(convert(varchar(10), @ProdCount), 'NoPCount') + 
						' EvtId='  + coalesce(convert(varchar(10), @EventId), 'NoEvtId') + 
						' EvtNum=' + coalesce(@EventNum, 'NoEvtNum') +
						' Finished'
						)
END
SELECT	@OutputValue = convert(varchar(25), getdate(), 120)
GOTO Finished

ErrCode:
	SELECT	@OutputValue = @ErrMsg

Finished:

-------------------------------------------------------------------------------
-- Process the Debug Message
-------------------------------------------------------------------------------
-- Suppress the @ErrMSg if the @DebugOff is Set
IF @DebugOff = '1'
BEGIN
	SELECT	@CalcErrMsg = '',
			@ErrMsg = ''
END

-- Send the @CalcErrMSg to the Local_DebugCalcLog if the @DebugCalcLog = 1	
IF @DebugCalcLog = '1'
BEGIN
	INSERT INTO dbo.Local_DebugCalcLog(
		PUId,
		PUDesc,
		ObjectName, 
		[TimeStamp], 
		Entry_On, 
		CalcErrMsg)
	VALUES (
		@PUId,
		@PUDesc,
		@ObjectName,
		@TimeStamp,
		getdate(),
		@CalcErrMsg)	
END


RETURN

SET NOCOUNT OFF
