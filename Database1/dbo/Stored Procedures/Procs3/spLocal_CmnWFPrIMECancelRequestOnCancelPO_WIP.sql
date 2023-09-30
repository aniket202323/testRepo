--------------------------------------------------------------------------------------------------
-- Stored Procedure: spLocal_CmnWFPrIMECancelRequestOnCancelPO_WIP
--------------------------------------------------------------------------------------------------
-- Author				: Linda Hudon, Symasol
-- Date created			: 04-Sep-2018	
-- Version 				: Version <1.0>
-- SP Type				: Workflow
-- Caller				: Called by PE:Cancel Workflow
-- Description			: This make the list of all Prime material needed for to be cancel by the initiate PO
-- Editor tab spacing	: 4
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ========		====	  		====					=====
-- 1.0			04-Sep-2018		L.Hudon				Original
-- 1.1			10-Sep-2018		L.Hudon				fix issue on cancel order
-- 1.2			20-Sep-2018		U. Lapierre			adapt to new field in Local_PrIME_Openrequests
-- 1.3			16-Nov-2018		U.Lapierre			remove LineID from the expected return of the function '[fnLocal_CmnPrIMEGetOpenRequests]' has been changed
-- 1.4			19-Dec-2018		U. Lapierre			Deal with Ready PO as well as initiate
-- 1.5			2019-05-17		L.hudon				fix issue related to cancel too much request from active order
-- 1.6			2019-09-13		A.Metlitski			Mark Unprocessed records in the [dbo.][Local_PrIME_PreStaged_Material_Request] table with Status 'CANCELED'
/*---------------------------------------------------------------------------------------------
Testing Code
exec dbo.spLocal_CmnWFPrIMECancelRequestOnCancelPO_WIP 12008,1,0
SELECT @ReturnCode
select* from local_Prime_openREquests
-----------------------------------------------------------------------------------------------*/


--------------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[spLocal_CmnWFPrIMECancelRequestOnCancelPO_WIP]
@PPId							int,					
@DebugFlagOnline				int,
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
@ActPPId						int,
@ActPPProcessOrder				varchar(12),
@ActBOMFormId					int,
@NxtPPId						int,
@NxtPPStatusStr					varchar(50),
@NxtPPProcessOrder				varchar(12),
@NxtBOMFormId					int,
@PathID							int,
--SOA properties

@cnWMSClass						varchar(50),
@pnPrIMELocation				varchar(50),
@pnOriginGroup					varchar(30),

--Path UDPs
@TableIdRMI						int,
@tfPEWMSSystemId				int,

@tfOGId							int,

--Subscription UDPs
@UsePrIME						bit,
@WMSSubscriptionID				int,
@Location						varchar(50),
@PrGCAS							varchar(8),
@ALtGCAS						varchar(8),
@ErrorCode						int,
@Username						varchar(50),
--Events and event properties
@toBeReturnedId					int,

--Calculate material Actuals
@LoopIndex						int,
--Canceled Status for the Pre-Staged Material Requests
@StatusStrCanceled				varchar(50)

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
	PEWMSSystem					varchar(50)
					)



DECLARE @Openrequest TABLE 
(
	OpenTableId			int,
	RequestId			varchar(30),
	RequestTime			datetime,
	LocationId			varchar(50),
	LineId				int,
	CurrentLocation		varchar(30),
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



-------------------------------------------------------------------------------
-- Initialize variables.
-------------------------------------------------------------------------------
SELECT	@SPName	= 'spLocal_CmnWFPrIMECancelRequestOnCancelPO_WIP'

IF @DebugflagOnLine = 1 
BEGIN
	INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
	VALUES(	getdate(), 
			@SPName,
			'0001' +
			' TimeStamp=' + convert(varchar(25), getdate(), 120) +
			' PPID=' + convert(varchar(25), @PPID) +
			' Stored proc started',
			@pathid
			)
END		

SELECT @CurrentTime = GETDATE()			
		
SELECT	@cnWMSClass						= 'PE:PrIME_WMS',
		@pnOriginGroup					= 'Origin Group',
		@pnPrIMELocation				= 'LocationId'



--pp_status string
SELECT	@StatusStrActive				= 'Active',
		@StatusStrComplete				= 'Closing',
		@StatusStrNext					= 'Initiate',
		@StatusStrReady					= 'Ready',
		@StatusStrCanceled				= 'CANCELED'

--prodcution_status
SET  @tobereturnedId = (SELECT prodStatus_id FROM dbo.production_status WITH(NOLOCK) WHERE prodStatus_desc = 'To be Returned')

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
		INSERT INTO Local_Debug([Timestamp], CallingSP, [Message]) 
		VALUES(	getdate(), 
				@SPName,
				'0010' +
				' TimeStamp=' + convert(varchar(25), getdate(), 120) +
				' Not a PrIME server'		)
	END

	
	RETURN
END



-------------------------------------------------------------------------------------
--Read required path UDPs
-------------------------------------------------------------------------------------
SET @TableIdRMI	= (SELECT TableID FROM dbo.Tables Where tableName = 'PRDExec_inputs')
SET @tfPEWMSSystemId		= (	SELECT Table_Field_Id 	FROM dbo.Table_Fields 			WITH(NOLOCK)	WHERE Table_Field_Desc = 'PE_WMS_System'		AND tableid = @TableIdRMI)
SET @tfOGId					= (	SELECT Table_Field_Id 	FROM dbo.Table_Fields 			WITH(NOLOCK)	WHERE Table_Field_Desc = 'Origin Group'			AND tableid = @TableIdRMI)

-------------------------------------------------------------------------------
-- Retrieve the Next Process Order Info
-------------------------------------------------------------------------------
SET @NxtPPId = NULL

SELECT	
	@NxtPPId				= pp.PP_Id,
	@NxtPPProcessOrder		= pp.Process_Order,
	@NxtBOMFormId			= pp.BOM_Formulation_Id,
	@PathId					= pp.Path_ID
FROM dbo.Production_Plan pp				WITH(NOLOCK)
JOIN dbo.Products_base p				WITH(NOLOCK) ON (pp.Prod_Id = p.Prod_Id)
JOIN dbo.Production_Plan_Statuses pps	WITH(NOLOCK) ON (pps.PP_Status_Id = pp.PP_Status_Id)
WHERE pps.PP_Status_Desc IN ( @StatusStrNext, @StatusStrReady)
	AND PP_ID =@PPId 


IF	@NxtPPId IS NULL
BEGIN
	IF @DebugFlagOnLine = 1 
	BEGIN
		INSERT into Local_Debug(Timestamp, CallingSP, Message, msg) 
			VALUES(	getdate(), 
					@spname,
					'0020' +
					' TimeStamp=' + convert(varchar(25), getdate(), 120) +
					' No Next Order',
					@pathId)
	END
	
	RETURN
END

SET @PathCode = (SELECT Path_Code FROM dbo.PrdEXEC_Paths p WITH(NOLOCK)  WHERE Path_ID = @PathId)

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
		@StatusStrNext,
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
				'0030' +
				' TimeStamp=' + convert(varchar(25), getdate(), 120) +
				' NxtPPId=' + coalesce(convert(varchar(10), @NxtPPId), 'NoPPId') + 
				' NxtPO=' + coalesce(@NxtPPProcessOrder, 'NOPO') + 
				' Finish to get the Next BOM',
				@pathid
				)
END

IF @DebugFlagManual = 1 
BEGIN
	 SELECT 'InitiateOrder', * FROM @tblBOMRMListComplete
END 
-------------------------------------------------------------------------------
-- Retrieve the Active Process Order Info
-------------------------------------------------------------------------------
																							
SELECT	@ActPPId = NULL

SELECT	TOP 1
		@ActPPId				= pp.PP_Id,
		@ActPPProcessOrder		= pp.Process_Order,
		@ActBOMFormId			= pp.BOM_Formulation_Id
FROM dbo.Production_Plan pp					WITH(NOLOCK)
JOIN dbo.Products_base p					WITH(NOLOCK) ON (pp.Prod_Id = p.Prod_Id)
JOIN dbo.Production_Plan_Statuses pps		WITH(NOLOCK) ON (pps.PP_Status_Id = pp.PP_Status_Id)
WHERE pps.PP_Status_Desc = @StatusStrActive
	AND Path_Id = @PathId
ORDER BY pp.Actual_start_time DESC

IF @DebugFlagOnLine = 1
BEGIN
	INSERT INTO Local_Debug([Timestamp], CallingSP, [Message], msg) 
		VALUES(	getdate(), 
				@SpName,
				'0040' +
				' PathId=' + convert(varchar(5), @PathId) + 
				' TimeStamp=' + convert(varchar(25), getdate(), 120) +
				' ActPPId=' + coalesce(convert(varchar(10), @ActPPId), 'NoPPId') + 
				' ActPO=' + coalesce(@ActPPProcessOrder, 'NOPO') ,
				@pathId
				)
END

IF @ActPPId IS NOT NULL
BEGIN
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


	IF @DebugFlagManual = 1 
	BEGIN
		 SELECT 'ACtiveeOrder', * FROM @tblBOMRMListComplete
	END
	IF @DebugFlagOnLine = 1
	BEGIN
		INSERT INTO Local_Debug([Timestamp], CallingSP, [Message], msg) 
			VALUES(	getdate(), 
					@SPName,
					'0050' +
					' TimeStamp=' + convert(varchar(25), getdate(), 120) +
					' ActPPId=' + coalesce(convert(varchar(10), @ActPPId), 'NoPPId') + 
					' ActPO=' + coalesce(@ActPPProcessOrder, 'NOPO') + 
			
					' Finish to get the Active BOM',
					@pathid
					)
	END

END



--  GET OG for all BOM items
UPDATE b
SET BOMRMOG = CONVERT(varchar(50),pmdmc2.value)
FROM @tblBOMRMListComplete b
JOIN	dbo.Products_Aspect_MaterialDefinition a				WITH(NOLOCK)	ON b.BOMRMProdId = a.prod_id

JOIN	dbo.Property_MaterialDefinition_MaterialClass pmdmc2	WITH(NOLOCK)	ON pmdmc2.MaterialDefinitionId = a.Origin1MaterialDefinitionId
																					AND pmdmc2.Name = @pnOriginGroup

--Get PrIME Location from the SOA equipement class
UPDATE b
SET PrIMELocation = CONVERT(varchar(50), pee.Value)
FROM @tblBOMRMListComplete b
JOIN dbo.PAEquipment_Aspect_SOAEquipment a		WITH(NOLOCK) ON b.BOMRMStoragePUId = a.pu_id
JOIN dbo.property_equipment_equipmentclass pee	WITH(NOLOCK) ON a.Origin1EquipmentId = pee.EquipmentId
WHERE pee.Class = @cnWMSClass
AND pee.Name = @pnPrIMELocation 

--This is used to remove all BOM material where we do not have a PrIME location
DELETE @tblBOMRMListComplete
WHERE PrIMELocation IS NULL  OR PrIMELocation = ''

IF @DebugFlagManual = 1 
	BEGIN
		 SELECT 'Location', * FROM @tblBOMRMListComplete
	END

IF @DebugFlagOnLine = 1  
BEGIN
	INSERT INTO Local_Debug([Timestamp], CallingSP, [Message], msg) 
		VALUES(	getdate(), 
				@SPName,
				'0060' +
				' TimeStamp=' + convert(varchar(25), getdate(), 120) +
				' ActPPId=' + coalesce(convert(varchar(10), @ActPPId), 'NoPPId') + 
				' ActPO=' + coalesce(@ActPPProcessOrder, 'NOPO') + 
				' NxtPPId=' + coalesce(convert(varchar(10), @NxtPPId), 'NoPPId') + 
				' NxtPO=' + coalesce(@NxtPPProcessOrder, 'NOPO') + 
				' Finish-Update the Orgin Grp',
				@pathID
				)
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
		AND (t2.PPStatusStr = @StatusStrNext ) 


DELETE FROM t1
FROM @tblBOMRMListComplete t1
JOIN @tblDuplicateProducts t2 ON (t1.BOMRMProdId = t2.BOMRMProdId)


IF @DebugFlagOnLine = 1  
BEGIN
	INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
		VALUES(	getdate(), 
				@SPName,
				'0070' +
				' TimeStamp=' + convert(varchar(25), getdate(), 120) +
				' ActPPId=' + coalesce(convert(varchar(10), @ActPPId), 'NoPPId') + 
				' ActPO=' + coalesce(@ActPPProcessOrder, 'NOPO') + 
				' NxtPPId=' + coalesce(convert(varchar(10), @NxtPPId), 'NoPPId') + 
				' NxtPO=' + coalesce(@NxtPPProcessOrder, 'NOPO') + 
				' Clean up the BOM List',
				@pathId
				)
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
						PEWMSSystem
						)
SELECT	pepu.PU_Id, 
		pei.PEI_Id, 
		tfv.Value, 
		tfv2.value
FROM dbo.PrdExec_Path_Units pepu		WITH(NOLOCK)
JOIN dbo.PrdExec_Inputs pei				WITH(NOLOCK)	ON pei.PU_Id = pepu.PU_Id
JOIN dbo.Table_Fields_Values tfv		WITH(NOLOCK)	ON tfv.KeyId = pei.PEI_Id AND tfv.Table_Field_Id  = @tfOGId
LEFT JOIN dbo.Table_Fields_Values tfv2		WITH(NOLOCK)	ON tfv2.KeyId= pei.PEI_Id AND tfv2.Table_Field_Id = @tfPEWMSSystemId
WHERE pepu.Path_Id = @PathId 


--Clean BOM
DELETE @PRDExecInputs WHERE  PEWMSSystem <> 'PrIME' OR PEWMSSystem IS NULL


IF @DebugFlagManual = 1 
	BEGIN
		 SELECT 'PRIMEPRD INPUTs', * FROM @PRDExecInputs
	END

DELETE @tblBOMRMListComplete WHERE BOMRMOG NOT IN (SELECT OG FROM @PRDExecInputs)



IF @DebugFlagManual = 1 
	BEGIN
		 SELECT 'clean BOM', * FROM @tblBOMRMListComplete
	END

-------------------------------------------------------------------------------
	-- 5.	Get the open request 
	--		Update Quantityvalue where it is not defined by PrIME yet
-------------------------------------------------------------------------------
INSERT @Openrequest (OpenTableId,RequestId,RequestTime,LocationId,	CurrentLocation,ULID,Batch,ProcessOrder,PrimaryGCAS,AlternateGCAS,GCAS,QuantityValue,QuantityUOM,Status,EstimatedDelivery,
lastUpdatedTime	,userId, eventid	)
SELECT * FROM [dbo].[fnLocal_CmnPrIMEGetOpenRequests](@pathCode)

IF @DebugFlagManual = 1 
	BEGIN
		 SELECT 'OpenRequest', * FROM @Openrequest
	END


-------------------------------------------------------------------------------
--	6b.	Update the table for ActualPalletCntTot for each Product Group (material)
--		Actual Pallet = Pallets at Staging + Open Request Pallets
-------------------------------------------------------------------------------
SET @LoopIndex = (SELECT MIN(OpenTableId) FROM @Openrequest)
WHILE @LoopIndex IS NOT NULL
BEGIN
	SELECT  @Location		=	NULL,
			@PrGCAS			=	NULL,
			@ALtGCAS			=	NULL

	SELECT	@Location			=  LocationId,
			@PrGCAS				=  PrimaryGCAS,
			@ALtGCAS				=  AlternateGCAS
	FROM	@Openrequest
	WHERE	OpenTableId = @LoopIndex

	
	IF EXISTS(SELECT 1 FROM @tblBOMRMListComplete WHERE @location = PrIMELocation AND (BOMRMProdCode IN (@PrGCAS,@ALtGCAS) OR BOMRMSubProdCode IN (@PrGCAS,@ALtGCAS)))
	BEGIN
		IF @DebugFlagManual = 0
		BEGIN
			EXEC DBO.spLocal_CmnPrIMECancelOpenRequest  @LoopIndex, @Username,'Auto', @ErrorCode OUTPUT
	

			IF @ErrorCode <0
			BEGIN
				IF @DebugFlagOnLine = 1  
				BEGIN
					INSERT INTO Local_Debug([Timestamp], CallingSP, [Message], Msg)
								VALUES(	getdate(),  
								@SPNAME,
								'0070' +
								' Unable to cancel' + convert(varchar(50),@LoopIndex),
								@pathid
								)
				END
			END
			ELSE
			BEGIN

	
				IF @DebugFlagOnLine = 1  
				BEGIN
					INSERT INTO Local_Debug([Timestamp], CallingSP, [Message], Msg)
								VALUES(	getdate(), 
								@SPNAME,
								'0080' +
								' able to cancel' + convert(varchar(50),@LoopIndex),
								@pathid
								)
				END
			END
		END
		ELSE
		BEGIN
			SELECT @LoopIndex, @Username
		END
	END
	SET @LoopIndex = (SELECT MIN(OpenTableId) FROM @Openrequest WHERE OpenTableId > @LoopIndex)
END

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--	6c.	Update the Local_PrIME_PreStaged_Material_Request Table set Status = CANCELED for all unprocessed records for this canceled PO
--	1.6	2019-09-13		A.Metlitski			Mark Unprocessed records in the [dbo.][Local_PrIME_PreStaged_Material_Request] table with Status 'CANCELED'
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
UPDATE	lmr
SET		lmr.STATUS = @StatusStrCanceled,
		lmr.PROCESSEDTIME = getdate()
FROM	[dbo].[Local_PrIME_PreStaged_Material_Request] lmr
join	[dbo].[Production_Plan] pp on lmr.PROCESSORDER = pp.Process_Order 
and		pp.PP_Id = @PPId
WHERE	lmr.PROCESSEDTIME is Null



IF @DebugFlagOnLine = 1  
	BEGIN
		INSERT INTO Local_Debug([Timestamp], CallingSP, [Message], Msg)
					VALUES(	getdate(), 
					@SPNAME,
					'0999' +
					' FInished',
					@pathid
					)
	END


SET NOcount OFF

RETURN
