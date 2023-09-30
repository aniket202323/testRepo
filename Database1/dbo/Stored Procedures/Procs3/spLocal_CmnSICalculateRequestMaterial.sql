CREATE PROCEDURE [dbo].[spLocal_CmnSICalculateRequestMaterial]
@LocationId					varchar(50),		--Destination Location
@DebugFlag						int				--When debug flag = 1, no request are sent to WAMAS, data apears on screen


AS
SET NOCOUNT ON

DECLARE 
	@SPNAME							varchar(255),

	--Storage Production Units
	@puid							int,
	@plid							int,
	@varIdRunOut					int,
	@varIdLineProdRate				int,
	@LineProdRate					float,
	@TimestampRunOut				datetime,
	@RunOutValue					varchar(25),
	@ActiveStatus					int,
	@InitiateStatus					int,
	@ReadyStatus					int,
	--Consuming production unit
	@ProdPuId						int,
	@tableId						int,
	@tfIdOG							int,
	@tfidWMSSystem					int,
	@tfidConsumptionType			int,
	@tfidIsSAPSrapFactor			int,
	@tfidIsRMIScrapfactor			int,
	@tfidIsAutoOrdering				int,
	@tfidSafetyStock				int,
	@tfidRMIScrapfactor				int,
	@tfIdMaterialOriginGroup		int,

	--Process orders
	@pathid							int,
	@pathAutoOrdering				bit,
	@MainUseSAPSF					bit,
	@ActivePPID						int,
	@ActiveProcessorder				varchar(12),
	@ActiveForecastQty				float,
	@ActiveActualQty				float,
	@ProcessOrder					varchar(12),
	@ppid							int,
	@BOMFormId						int,
	@PlannedDuration				float,

	--Loop thru BOM
	@BomId							int,
	@BomQty							float,
	@BOMOG							varchar(30),
	@BOMSF							float,
	@RMIIsSF						bit,
	@RMISF							float,
	@ConsumptionRate				float,
	@BOMProdCode					varchar(50),
	@BOMRMProdCodeSub				varchar(50),
	@BOMProdId						int,
	@BOMProdIdSub					int,
	@BomQtySF						float,
	@ThresholdInMinutes				int,
	@ThresholdInUOM					float,
	@Capacity						int,
	
	--Staging material
	@QtyMaterial					float,
	@QtyMaterialSub					float,
	@QuantityToOrderUOM				float,
	@QuantityToOrderStack			int,
	@UOMPerStack					float,
	@OrderNumber					int,
	@QuantityOpenRequestUOM			float,
	@QuantityOpenRequestStack		int	,
	@StackCount						int,
	@StillNeededqty					float,
	@RunninSgtackCount				int,			--v.19
	
	--request Material 
	@p_RequestTimestamp				datetime,
	@UOM							varchar(30)	,
	@UserName						varchar(50),
	@CurrentStatus					int,
	@tfidIsWMSOrdering				varchar(50),
	@UseBOMScrapFactorId			int,
	@AutoOrderProductionMaterialId	int


DECLARE @OUTPOUT TABLE(
outputMessage		varchar(50),
ErrorCode			int)

--Raw material input UDP table
DECLARE @RMI	TABLE (
peiid					int,
OG						varchar(30),
WMSSystem				varchar(50),
ConsumptionType			int,
IsRMIScrapfactor		bit,
RMIScrapfactor			float,
IsAutoOrdering			bit,
SafetyStock				bit,
IsWMSOrdering			bit
)



DECLARE @tblBOM TABLE
		(	BOMRMId						int IDENTITY,
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



--V1.1
DECLARE @OpenRequest	TABLE (
OpenTableId					int,
RequestTime					datetime,
LineId						varchar(50),
ULID						varchar(50),
ProcessOrder				varchar(50),
VendorLot					varchar(50),
GCAS						varchar(50),
PrimaryGCAS					varchar(50),
AlternateGCAS				varchar(50),
Status						varchar(50),
Location					varchar(10),
Quantity					int,
UOM							varchar(50)
)

--V1.5
DECLARE @StillNeeded TABLE (
StillNeededNext							float,
StillNeededActive						float,
StillNeeded								float,
StillNeededInventoryIncluded			float,
QtyInventory							float,
StackCount								int
)

DECLARE @PathUnit TABLE(
PUID	int)

SET @SPNAME = 'spLocal_CmnSICalculateRequestMaterial'

INSERT local_debug (CallingSP,timestamp, message, msg)
VALUES (	@SPNAME,
			GETDATE(),
			'0000 - SP started',
			@LocationId
		)


SET @ActiveStatus = (SELECT pp_STATUS_ID FROM dbo.Production_Plan_Statuses pp WITH(NOLOCK) WHERE PP_Status_Desc = 'Active')
SET @InitiateStatus = (SELECT pp_STATUS_ID FROM dbo.Production_Plan_Statuses pp WITH(NOLOCK) WHERE PP_Status_Desc = 'Initiate')
SET @ReadyStatus = (SELECT pp_STATUS_ID FROM dbo.Production_Plan_Statuses pp WITH(NOLOCK) WHERE PP_Status_Desc = 'Ready')

-------------------------------------------------------------------------------
--Identify the production unit representing the LineId (destination location)
-------------------------------------------------------------------------------

SET @puid = (	SELECT a.pu_id
				FROM dbo.Property_Equipment_EquipmentClass peec	WITH(NOLOCK)
				JOIN dbo.PAEquipment_Aspect_SOAEquipment a		WITH(NOLOCK)	ON peec.equipmentid = a.Origin1EquipmentId
				WHERE	peec.class = 'PE:SI_WMS'
					AND peec.name = 'Destination Location'
					AND peec.value = @LocationId
				)


SET @plid = (SELECT pl_id FROM dbo.prod_units_base WITH(NOLOCK) WHERE pu_id = @puid )

INSERT local_debug (CallingSP,timestamp, message, msg)
VALUES (	@SPNAME,
			GETDATE(),
			'0100 - ' +
			' /pu_id = ' + CONVERT(varchar(30),COALESCE(@puid,0)),
			@LocationId
		)


IF @puid IS NULL
BEGIN
	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
			GETDATE(),
			'0109 - ' +
			'Error: pu_id not found.  Verify the Class PE:SI_WMS on the conveyor',
			@LocationId
		)
		RETURN
END

IF EXISTS(SELECT 1 FROM dbo.Users_Base WITH(NOLOCK) WHERE Username = 'System.PE')
BEGIN
	SET @UserName = 'System.PE'
END

-------------------------------------------------------------------------------
--Get the Run out tag value
--We read it from a PPA variable on the conveyor unit
--If the run otu is 0, exit
-------------------------------------------------------------------------------
SET @varIdRunOut = (	SELECT var_id FROM dbo.variables_base WITH(NOLOCK) WHERE pu_id = @puid AND extended_info = 'PE:RunOutTag' )



IF @varIdRunOut IS NULL
BEGIN
	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
			GETDATE(),
			'0209 - ' +
			'Error: Run out variable not configured',
			@LocationId
		)
		RETURN
END

--Get the RUN out value
SET @TimestampRunOut =	(SELECT TOP 1 result_on FROM dbo.tests WITH(NOLOCK) WHERE var_id = @varIdRunOut ORDER BY result_on DESC )
SET @RunOutValue =		(SELECT result			FROM dbo.tests WITH(NOLOCK) WHERE var_id = @varIdRunOut AND result_on = @TimestampRunOut) 

INSERT local_debug (CallingSP,timestamp, message, msg)
VALUES (	@SPNAME,
			GETDATE(),
			'0220 - ' +
			' /varIdRunOut = ' + CONVERT(varchar(30),COALESCE(@varIdRunOut,0)) + 
			' /TimestampRunOut = ' + CONVERT(varchar(30),COALESCE(@TimestampRunOut,'1-Jan-2000'),20) + 
			' /RunOutValue = ' + CONVERT(varchar(30),COALESCE(@RunOutValue,'0')),
			@LocationId
		)

IF @RunOutValue IS NULL
BEGIN
	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
			GETDATE(),
			'0229 - ' +
			'Error: Run out variable not configured',
			@LocationId
		)
		RETURN
END

IF @RunOutValue = '0'
BEGIN
	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
			GETDATE(),
			'0240 - ' +
			'RunOut tag = 0.   Exit, nothing to order',
			@LocationId
		)
	RETURN
END

SET @CurrentStatus  = COALESCE((SELECT pp_Status_Id FROM dbo.Production_Plan p WITH(NOLOCK) WHERE process_ORDEr = @RunOutValue),0)

--- check if runout if initaite ready, active
IF ( @CurrentStatus != @ActiveStatus AND @CurrentStatus != @InitiateStatus AND @CurrentStatus !=  @ReadyStatus)
BEGIN 
INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
			GETDATE(),
			'0245 - ' +
			'RunOut tag PO is not initiate, ready or active PO',
			@LocationId
		)
	RETURN
END 
-------------------------------------------------------------------------------
--Retrieve the production unit (Consuming)
--Get all the OG related to SI
--Verify the Safety stock option
-------------------------------------------------------------------------------
SET @ProdPuId 	=	(SELECT TOP 1 pei.pu_id
					FROM dbo.prdExec_input_sources peis WITH(NOLOCK) 
					JOIN dbo.prdExec_inputs pei	WITH(NOLOCK) ON pei.pei_id = peis.pei_id
					WHERE peis.pu_id = @puid)


INSERT local_debug (CallingSP,timestamp, message, msg)
VALUES (	@SPNAME,
			GETDATE(),
			'0300 - ' +
			' /ProdPuId = ' + CONVERT(varchar(30),COALESCE(@ProdPuId,0)) ,
			@LocationId
		)



--Get table fields ids
SET @TableID	= (	SELECT TableID 	FROM dbo.Tables WITH(NOLOCK) WHERE tableName = 'PRDExec_Inputs'	)


SET @tfIdOG					= (SELECT Table_Field_id FROM dbo.Table_Fields WITH(NOLOCK) WHERE Table_Field_Desc = 'Origin Group'			AND TableID = @TableID	)
SET @tfidWMSSystem			= (SELECT Table_Field_id FROM dbo.Table_Fields WITH(NOLOCK) WHERE Table_Field_Desc = 'PE_WMS_System'		AND TableID = @TableID	)
SET @tfidConsumptionType	= (SELECT Table_Field_id FROM dbo.Table_Fields WITH(NOLOCK) WHERE Table_Field_Desc = 'ConsumptionType'		AND TableID = @TableID	)

SET @tfidIsRMIScrapfactor	= (SELECT Table_Field_id FROM dbo.Table_Fields WITH(NOLOCK) WHERE Table_Field_Desc = 'UseRMScrapFactor'		AND TableID = @TableID	)
SET @tfidRMIScrapfactor		= (SELECT Table_Field_id FROM dbo.Table_Fields WITH(NOLOCK) WHERE Table_Field_Desc = 'RMScrapFactor'		AND TableID = @TableID	)
SET @tfidIsAutoOrdering		= (SELECT Table_Field_id FROM dbo.Table_Fields WITH(NOLOCK) WHERE Table_Field_Desc = 'AutoOrderProductionMaterialByOG'		AND TableID = @TableID	)
SET @tfidIsWMSOrdering		= (SELECT Table_Field_id FROM dbo.Table_Fields WITH(NOLOCK) WHERE Table_Field_Desc = 'PE_WMS_IsOrdering'		AND TableID = @TableID	)
SET @tfidSafetyStock		= (SELECT Table_Field_id FROM dbo.Table_Fields WITH(NOLOCK) WHERE Table_Field_Desc = 'SafetyStock'			AND TableID = @TableID	)


INSERT local_debug (CallingSP,timestamp, message, msg)
VALUES (	@SPNAME,
			GETDATE(),
			'0310 - ' +
			' /@tfIdOG = ' + CONVERT(varchar(30),COALESCE(@tfIdOG,0)) +
			' /@tfidWMSSystem = ' + CONVERT(varchar(30),COALESCE(@tfidWMSSystem,0)) +
			' /@tfidConsumptionType = ' + CONVERT(varchar(30),COALESCE(@tfidConsumptionType,0)) +
			' /@tfidIsRMIScrapfactor = ' + CONVERT(varchar(30),COALESCE(@tfidIsRMIScrapfactor,0)) +
			' /@tfidRMIScrapfactor = ' + CONVERT(varchar(30),COALESCE(@tfidRMIScrapfactor,0)) +
			' /@tfidIsAutoOrdering = ' + CONVERT(varchar(30),COALESCE(@tfidIsAutoOrdering,0)) +
			' /@@tfidIsWMSOrdering = ' + CONVERT(varchar(30),COALESCE(@tfidIsWMSOrdering,0)) +
			' /@tfidSafetyStock = ' + CONVERT(varchar(30),COALESCE(@tfidSafetyStock,0)) ,
			@LocationId
		)


--retrieve and store all OG on the consumption unit
INSERT @RMI (
				peiid					,
				OG						,
				WMSSystem				,
				ConsumptionType			,
				IsRMIScrapfactor		
						)
SELECT	pei.PEI_Id, 
		tfv.Value,						--OG
		tfv2.value,						--WMSSystem
		CONVERT(int,tfv3.value),		--ConsumptionType
		CONVERT(bit,tfv5.value)

FROM dbo.PrdExec_Inputs pei			WITH(NOLOCK)	
JOIN dbo.Table_Fields_Values tfv	WITH(NOLOCK)	ON tfv.KeyId	= pei.PEI_Id	AND tfv.table_field_id	= @tfIdOG
JOIN dbo.Table_Fields_Values tfv2	WITH(NOLOCK)	ON tfv2.KeyId	= pei.PEI_Id	AND tfv2.table_field_id	= @tfidWMSSystem
JOIN dbo.Table_Fields_Values tfv3	WITH(NOLOCK)	ON tfv3.KeyId	= pei.PEI_Id	AND tfv3.table_field_id	= @tfidConsumptionType
JOIN dbo.Table_Fields_Values tfv5	WITH(NOLOCK)	ON tfv5.KeyId	= pei.PEI_Id	AND tfv5.table_field_id	= @tfidIsRMIScrapfactor

WHERE pei.pu_id = @prodPuid 


UPDATE pei
SET		RMIScrapfactor			= CONVERT(float,tfv6.value),
		IsAutoOrdering			= COALESCE(CONVERT(bit,tfv7.value),1),
		SafetyStock				= CONVERT(bit,tfv8.value)	,
		IsWMSOrdering			= CONVERT(bit,tfv9.value)	
FROM @RMI pei
JOIN dbo.Table_Fields_Values tfv6	WITH(NOLOCK)	ON tfv6.KeyId	= pei.PEIId AND tfv6.table_field_id	= @tfidRMIScrapfactor
JOIN dbo.Table_Fields_Values tfv7	WITH(NOLOCK)	ON tfv7.KeyId	= pei.PEIId AND tfv7.table_field_id	= @tfidIsAutoOrdering
JOIN dbo.Table_Fields_Values tfv8	WITH(NOLOCK)	ON tfv8.KeyId	= pei.PEIId AND tfv8.table_field_id	= @tfidSafetyStock
JOIN dbo.Table_Fields_Values tfv9	WITH(NOLOCK)	ON tfv9.KeyId	= pei.PEIId AND tfv9.table_field_id	= @tfidIsWMSOrdering


--Delete all OG which are not SI_managed and Consumtpion Type  = 4
DELETE @RMI WHERE UPPER(WMSSystem) <> 'WAMAS'
DELETE @RMI WHERE IsWMSOrdering = 0




--Delete all OG which are not autoOrderproductionbyOG = false 
DELETE @RMI WHERE (IsAutoOrdering = 0 OR IsAutoOrdering IS NULL) 

INSERT local_debug (CallingSP,timestamp, message, msg)
SELECT 	@SPNAME,
			GETDATE(),
			'0320 - ' +
			' /OG = ' + OG +
			' /WMSSystem = ' + WMSSystem +
			' /ConsumptionType = ' + CONVERT(varchar(30),COALESCE(ConsumptionType,0)) +
			' /IsRMIScrapfactor = ' + CONVERT(varchar(30),COALESCE(IsRMIScrapfactor,0)) +
			' /RMIScrapfactor = ' + CONVERT(varchar(30),COALESCE(RMIScrapfactor,0)) +
			' /IsAutoOrdering = ' + CONVERT(varchar(30),COALESCE(IsAutoOrdering,0)) +
			' /SafetyStock = ' + CONVERT(varchar(30),COALESCE(SafetyStock,0)) ,
			@LocationId
FROM @RMI




IF NOT EXISTS(SELECT OG FROM @RMI)
BEGIN
	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
			GETDATE(),
			'0340 - ' +
			'Not configured for SI ordering.   Exit, nothing to order',
			@LocationId
		)
	RETURN
END




-------------------------------------------------------------------------------
--Get Process order information
--If the run out is the active order, check if actual good quantity> forecast qty.
--In that case , do ordering only if safeety stock is true, otherwise, exit.
-------------------------------------------------------------------------------


SET @ProcessOrder = @RunOutValue
SET @pathid = (SELECT path_id FROM dbo.production_plan WITH(NOLOCK) WHERE process_order = @ProcessOrder)  -- In PG, process order unique per site...


IF @pathid IS  NULL
BEGIN
	--invalid order

	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
			GETDATE(),
			'0360 - ' +
			'Error: Invalid process order in the run out tag',
			@LocationId
		)
	RETURN
END

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
			@LocationId
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
			@LocationId
		)
	RETURN
END

INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
			GETDATE(),
			'0385 - ' +
			'Line Production Rate' + convert(varchar(50),@LineProdRate),
			@LocationId
		)

SET @TableID	= (	SELECT TableID 	FROM dbo.Tables WITH(NOLOCK) WHERE tableName = 'prdExec_paths'	)


SET @AutoOrderProductionMaterialid = (SELECT table_field_id FROM dbo.table_fields WITH(NOLOCK) WHERE tableid = @TableID AND table_field_desc = 'PE_SI_AutoOrderProductionMaterial')

--Check if Auto ordering is ON, if not exit
SET @pathAutoOrdering = (SELECT CONVERT(bit,tfv.value)
						FROM dbo.Table_Fields_Values tfv	WITH(NOLOCK)
						WHERE table_field_id = 	@AutoOrderProductionMaterialid
						--JOIN  dbo.Table_Fields tf			WITH(NOLOCK)	ON tfv.table_field_id = tf.table_field_id AND tf.tableid = @TableID
						--WHERE tf.table_field_desc = 'PE_SI_AutoOrderProductionMaterial'		
							AND tfv.keyid = @pathid)


IF @pathAutoOrdering IS NULL
	SET @pathAutoOrdering = 0

IF @pathAutoOrdering = 0
BEGIN
	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
			GETDATE(),
			'0390 - ' +
			'PE_SI_AutoOrderProductionMaterial is false (or missing).   Exit, nothing to order',
			@LocationId
		)
	RETURN
END


SET @UseBOMScrapFactorid = (SELECT table_field_id FROM dbo.table_fields WITH(NOLOCK) WHERE tableid = @TableID AND table_field_desc = 'PE_PPA_UseBOMScrapFactor')

--Check SAP ScrapFactor (at path level)
SET @MainUseSAPSF = (	SELECT CONVERT(bit,tfv.value)
						FROM dbo.Table_Fields_Values tfv	WITH(NOLOCK)
						WHERE table_field_id = 	@UseBOMScrapFactorid
						--JOIN  dbo.Table_Fields tf			WITH(NOLOCK)	ON tfv.table_field_id = tf.table_field_id AND tf.tableid = @TableID
						--WHERE tf.table_field_desc = 'PE_PPA_UseBOMScrapFactor'
							AND tfv.keyid = @pathid)

IF @MainUseSAPSF IS NULL
	SET @MainUseSAPSF = 0


--Get PO info
SELECT	@ActivePpid = pp_id,
		@ActiveProcessOrder = process_order,
		@ActiveForecastQty	= Forecast_quantity,
		@ActiveActualQty	= Actual_good_quantity
FROM dbo.production_plan 			WITH(NOLOCK) 
WHERE	path_id = @pathid
	AND pp_status_id = 3
ORDER BY actual_start_time


INSERT local_debug (CallingSP,timestamp, message, msg)
VALUES (	@SPNAME,
			GETDATE(),
			'0430 - ' +
			' /@ProcessOrder = ' + @ProcessOrder +
			' /@ActivePpid = ' + CONVERT(varchar(30),COALESCE(@ActivePpid,0)) +
			' /@ActiveProcessOrder = ' + COALESCE(@ActiveProcessOrder, 'NONE') +
			' /@ActiveForecastQty = ' + CONVERT(varchar(30),COALESCE(@ActiveForecastQty,-1)) +
			' /@ActiveActualQty = ' + CONVERT(varchar(30),COALESCE(@ActiveActualQty,-1))+
			' /@MainUseSAPSF = ' + CONVERT(varchar(30),COALESCE(@MainUseSAPSF,-1)) ,
			@LocationId
		)


--Check for over produce
IF @ProcessOrder = @ActiveProcessOrder
BEGIN
	IF @ActiveActualQty > @ActiveForecastQty
	BEGIN
		--We need to keep only safety stock = TRUE
		--When Safety stock is true, it must continue to order material even if the planned quantity is reached.
		DELETE @RMI WHERE SafetyStock = 0 OR SafetyStock IS NULL
	END
END


IF NOT EXISTS(SELECT OG FROM @RMI)
BEGIN
	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
			GETDATE(),
			'0440 - ' +
			'Overproduce and safety stock false.   Exit, nothing to order',
			@LocationId
		)
	RETURN
END



-------------------------------------------------------------------------------
--Get BOM information
--remove what is related to OG in the RMI table
-------------------------------------------------------------------------------
--Get PO information
SELECT	@ppid = pp_id,
		@BOMFormId = BOM_Formulation_Id,
		@PlannedDuration = DATEDIFF(mi,forecast_Start_date, forecast_end_date)
		FROM dbo.production_plan WITH(NOLOCK) 
WHERE process_order = @ProcessOrder



INSERT local_debug (CallingSP,timestamp, message, msg)
VALUES (	@SPNAME,
			GETDATE(),
			'0500 - ' +
			' /@ProcessOrder = ' + @ProcessOrder +
			' /@ppid = ' + CONVERT(varchar(30),COALESCE(@ppid,0)) +
			' /@BOMFormId =  ' + CONVERT(varchar(30),COALESCE(@BOMFormId,0)) +
			' /@PlannedDuration (in minutes) =  ' + CONVERT(varchar(30),COALESCE(@PlannedDuration,0))  ,
			@LocationId
		)



--Get the full BOM
INSERT @tblBOM 		(	
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
SELECT		@ppid,
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
	JOIN		dbo.Products_Base p							WITH(NOLOCK) ON (p.Prod_Id = bomfi.Prod_Id) 
	LEFT JOIN	dbo.Bill_Of_Material_Substitution bomfs	WITH(NOLOCK) ON (bomfs.BOM_Formulation_Item_Id = bomfi.BOM_Formulation_Item_Id)
	LEFT JOIN	dbo.Products_Base p_sub						WITH(NOLOCK) ON (p_sub.Prod_Id = bomfs.Prod_Id)
	WHERE	bomf.BOM_Formulation_Id = @BOMFormId


SET @TableID	= (	SELECT TableID 	FROM dbo.Tables WITH(NOLOCK) WHERE tableName = 'Bill_of_Material_Formulation_Item'	)
SET @tfIdMaterialOriginGroup = (SELECT Table_Field_Id FROM dbo.Table_Fields WITH(NOLOCK) WHERE Table_Field_Desc = 'MaterialOriginGroup' AND TableId = @TableId);

UPDATE bom
SET BOMOG = tfv.value
FROM @tblBOM bom
JOIN dbo.Table_Fields_Values tfv	WITH(NOLOCK)	ON tfv.KeyId	= bom.BOMRMFormItemId
WHERE tfv.Table_Field_Id = @tfIdMaterialOriginGroup



--Remove all BOM items not relevant														
DELETE @tblBOM WHERE BOMOG NOT IN (SELECT OG FROM @RMI)


INSERT local_debug (CallingSP,timestamp, message, msg)
SELECT 	@SPNAME,
			GETDATE(),
			'0520 - ' +
			' /BOMOG = ' + BOMOG +
			' /BOMRMProdId = ' + CONVERT(varchar(30),COALESCE(BOMRMProdId,0)) +
			' /BOMRMProdCode = ' + BOMRMProdCode +
			' /BOMRMQty = ' + CONVERT(varchar(30),COALESCE(BOMRMQty,0)) +
			' /BOMScrapFactor = ' + CONVERT(varchar(30),COALESCE(BOMScrapFactor,0)) +
			' /BOMRMFormItemId = ' + CONVERT(varchar(30),COALESCE(BOMRMFormItemId,0)) +
			' /BOMRMStoragePUId = ' + CONVERT(varchar(30),COALESCE(BOMRMStoragePUId,0)) +
			' /BOMRMProdIdSub = ' + CONVERT(varchar(30),COALESCE(BOMRMProdIdSub,0)) +
			' /BOMRMProdCodeSub = ' + CONVERT(varchar(30),COALESCE(BOMRMProdCodeSub,0)) ,
			@LocationId
FROM @tblBOM




--------------------------------------------------------------------------------------
--Loop thru all BOM items that matches the requirement (SIManaged = TRUE)
--Usually only one BOM item...  However, I loop for future possible use.
--------------------------------------------------------------------------------------
SET @bomID = (	SELECT MIN(BOMRMId) FROM @tblBOM	)
WHILE @bomID IS NOT NULL
BEGIN
	--Re-Initialize variables	
	SET @BomQty = NULL
	SET @BOMProdCode = NULL
	SET @BOMOG = NULL
	SET @BOMSF = 0
	SET @RMIIsSF = 0
	SET @RMISF = 0
	SET @ConsumptionRate = NULL
	SET @BOMProdId		= NULL
	SET @BOMProdIdSub	= NULL
	SET @BOMRMProdCodeSub = NULL


	--Get all value for the calculations
	SELECT	@BomQty			=	b.BOMRMQty,
			@BOMProdCode	=	b.BOMRMProdCode,
			@BOMOG			=	b.BomOg,
			@BOMSF			=	b.BOMScrapFactor,
			@RMIIsSF		=	rmi.IsRMIScrapfactor,
			@RMISF			=	rmi.RMIScrapfactor,
			@BOMProdId		=	b.bomrmprodid,
			@BOMProdIdSub	=	b.bomrmprodidSub,
			@BOMRMProdCodeSub = BOMRMProdCodeSub
	FROM @tblBOM b
	JOIN @RMI rmi	ON b.bomog = rmi.og
	WHERE b.BOMRMId = @bomID


	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
			GETDATE(),
			'0600 - Loop BOM  ' +
			' /@bomID = ' + CONVERT(varchar(30),COALESCE(@bomID,0)) +
			' /@BOMProdCode = ' + @BOMProdCode +
			' /@BOMOG = ' + @BOMOG +
			' /@BomQty = ' + CONVERT(varchar(30),COALESCE(@BomQty,0)) +
			' /@BOMSF = ' + CONVERT(varchar(30),COALESCE(@BOMSF,0)) +
			' /@RMIIsSF = ' + CONVERT(varchar(30),COALESCE(@RMIIsSF,-1)) +
			' /@RMISF = ' + CONVERT(varchar(30),COALESCE(@RMISF,0))  ,
			@LocationId
		)



	--Calculate consumption rate-------------------------------------------
	SET @BomQtySF =  @BomQty

	-- Add BOM Scrap factor if the OG BOM RMI UDP is true and the Path UDP is TRUE
	--  IF @BOMIsSF_RMI = 1 AND @MainUseSAPSF = 1  1.7
	IF @MainUseSAPSF = 1 
	BEGIN
		SET @BomQtySF = @BomQtySF + (@BomQty*@BOMSF/100)
	END

	--Add RMI scrap factor, if the RMI UDP is TRUE
	IF @RMIIsSF = 1 
	BEGIN
		SET @BomQtySF = @BomQtySF + (@BomQty*@RMISF/100)
	END

	--Calculate UOM per minutes
	SET @ConsumptionRate = @LineProdRate --@BomQtySF/@PlannedDuration

	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
			GETDATE(),
			'0610 - Loop BOM  ' +
			' /@ConsumptionRate = ' + CONVERT(varchar(30),COALESCE(@ConsumptionRate,0)) ,
			@LocationId
		)

	-------------------------------------------------------------------------


	--Calculate Threshold in UOM (based on threshold in minutes in the SOA model.
	--Get threshold in Minutes for SOA property
	SET @ThresholdInMinutes = (		SELECT convert(int, pee.Value)		--20140710																			
									FROM dbo.property_equipment_equipmentclass pee	
									JOIN dbo.PAEquipment_Aspect_SOAEquipment a		WITH(NOLOCK)ON pee.equipmentid = a.Origin1EquipmentId
									WHERE a.pu_id = @puid
										AND pee.Name LIKE '%' +  @BOMOG + '.' +'Origin Group Running Threshold')

	
	SET @ThresholdInUOM = @ThresholdInMinutes * @ConsumptionRate

	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
			GETDATE(),
			'0620 - Loop BOM  ' +
			' /@ThresholdInMinutes = ' + CONVERT(varchar(30),COALESCE(@ThresholdInMinutes,0)) +
			' /@ThresholdInUOM = ' + CONVERT(varchar(30),COALESCE(@ThresholdInUOM,0)) ,
			@LocationId
		)




-----------------------------------------------------------------------------
	--get the actual inventory for the OG
	--get staging qty (created in PPA)
-----------------------------------------------------------------------------
	--SET @QtyMaterial	= 0
	--SET @StackCount		= 0
	--SELECT  @QtyMaterial = SUM(ed.final_dimension_x),
	--		@StackCount = COUNT(e.event_id)
	--FROM dbo.events e				WITH(NOLOCK)
	--JOIN dbo.production_status ps	WITH(NOLOCK)	ON e.event_status = ps.prodStatus_id
	--JOIN dbo.event_details ed		WITH(NOLOCK)	ON e.event_id = ed.event_id
	--WHERE e.pu_id = @puid
	--	AND (e.Applied_Product = @BOMProdId OR e.applied_product = @BOMProdIdSub)
	--	AND ((ps.count_For_Production = 1 AND ps.count_For_Inventory = 1)	OR (ps.count_For_Production = 0 AND ps.count_For_Inventory = 0))
	DELETE @StillNeeded

	INSERT @StillNeeded (StillNeededNext, StillNeededActive, StillNeeded, StillNeededInventoryIncluded, QtyInventory,StackCount)
	EXEC spLocal_CmnCalculateStillNeeded @pathid, @BOMProdId, 0

	SELECT	@QtyMaterial	 = QtyInventory,
			@StackCount		= StackCount,
			@StillNeededqty	= StillNeededInventoryIncluded
	FROM @StillNeeded

	----V1.9
	----Remove Running Stack from stack count
	--SET @RunninSgtackCount = (	SELECT COUNT(event_id) 
	--							FROM dbo.events e					WITH(NOLOCK) 
	--							JOIN dbo.production_status ps		WITH(NOLOCK)  ON e.event_status = ps.prodStatus_id
	--							WHERE e.pu_id = @puid AND ps.prodStatus_desc = 'Running')

	--INSERT local_debug (CallingSP,timestamp, message, msg)
	--VALUES (	@SPNAME,
	--		GETDATE(),
	--		'0638 - Loop BOM  ' +
	--		' /@RunninSgtackCount = ' + CONVERT(varchar(30),COALESCE(@RunninSgtackCount,0)),
	--		@LocationId
	--	)

	--SET @StackCount = @StackCount - @RunninSgtackCount  --V1.9







	IF @QtyMaterial IS NULL
		SET  @QtyMaterial	= 0
	IF @StackCount IS NULL
		SET  @StackCount	= 0

	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
			GETDATE(),
			'0640 - Loop BOM  ' +
			' /@QtyMaterial = ' + CONVERT(varchar(30),COALESCE(@QtyMaterial,0))+ 
			' /@StackCount = ' + CONVERT(varchar(30),COALESCE(@StackCount,0)),
			@LocationId
		)




-------------------------------------------------------------------------------
	--Get the open request quantity
	--Look at the local table
-------------------------------------------------------------------------------
	--Clear @Openrequest
	DELETE @Openrequest
	
	INSERT @Openrequest (OpenTableId, RequestTime, Location,LineId,  ProcessOrder, PrimaryGCAS, AlternateGCAS, GCAS, Quantity,UOM, Status, ULID,VendorLot) -- 1.2 add process order
	EXEC [dbo].[spLocal_CmnSIGetOpenRequest] @LocationId, NULL,@BOMProdCode, NULL -- 1.2 add process order





	--Get UOM per stack
	SET @UOMPerStack = (		SELECT convert(integer, pmm.Value)
								FROM dbo.Property_MaterialDefinition_MaterialClass pmm	WITH(NOLOCK)
								JOIN dbo.Products_Aspect_MaterialDefinition a			WITH(NOLOCK) ON a.Origin1MaterialDefinitionId = pmm.MaterialDefinitionId
								WHERE a.Prod_id = @BOMProdId
									AND pmm.Name = 'UOM Per Pallet')	

	--Get the default value if it has bot been set by SI
	UPDATE @Openrequest 
	SET Quantity = @UOMPerStack
	WHERE Quantity IS NULL
		OR Quantity  =1			--V1.4
		OR Quantity = 0			--V1.4

	SET @QuantityOpenRequestUOM = (SELECT SUM(Quantity) FROM @Openrequest)

	IF @QuantityOpenRequestUOM IS NULL
		SET @QuantityOpenRequestUOM = 0


	SET @QtyMaterial = @QtyMaterial + @QuantityOpenRequestUOM

	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
			GETDATE(),
			'0770 - Loop BOM  ' +
			' /@QtyMaterial 2 = ' + CONVERT(varchar(30),COALESCE(@QtyMaterial,-1)) +
			' /@QuantityOpenRequestUOM = ' + CONVERT(varchar(30),COALESCE(@QuantityOpenRequestUOM,-1)),
			@LocationId
		)




-----------------------------------------------------------------------------------
	--Verify needs to order Material
-----------------------------------------------------------------------------------
	IF @ThresholdInUOM > @QtyMaterial
	BEGIN
			INSERT local_debug (CallingSP,timestamp, message, msg)
			VALUES (	@SPNAME,
			GETDATE(),
			'0800 - Loop BOM  ' +
			' Material ' + @BOMProdCode +' needs to be ordered  ' ,
			@LocationId
		)

		--Get threshold in Minutes for SOA property
		SET @Capacity = (		SELECT convert(int, pee.Value)		--20140710																			
										FROM dbo.property_equipment_equipmentclass pee	
										JOIN dbo.PAEquipment_Aspect_SOAEquipment a		WITH(NOLOCK)ON pee.equipmentid = a.Origin1EquipmentId
										WHERE a.pu_id = @puid
											AND pee.Name LIKE '%' +  @BOMOG + '.' +'Origin Group Capacity')
		


		



		--Material need to be ordered
		SET @QuantityToOrderUOM	= @ThresholdInUOM - @QtyMaterial



		IF @UOMPerStack IS NULL
		BEGIN
			INSERT local_debug (CallingSP,timestamp, message, msg)
				VALUES (	@SPNAME,
				GETDATE(),
				'0659 - Loop BOM  ' +
				' Material ' + @BOMProdCode + ': UOM per pallet not found  ' ,
				@LocationId
						)
		END
		ELSE
		BEGIN

			--v1.5  --1.9
			--IF @StillNeededqty > @QuantityToOrderUOM
			--	SET @QuantityToOrderStack = @Capacity - @StackCount 
			--ELSE
				SET @QuantityToOrderStack = CEILING(@QuantityToOrderUOM/@UOMPerStack)


			INSERT local_debug (CallingSP,timestamp, message, msg)
			VALUES (	@SPNAME,
						GETDATE(),
						'0820 - Loop BOM  ' +
						' /@QuantityToOrderUOM = ' + CONVERT(varchar(30),COALESCE(@QuantityToOrderUOM,0)) +
						' /@StillNeededqty = ' + CONVERT(varchar(30),COALESCE(@StillNeededqty,0)) +
						' /@UOMPerStack = ' + CONVERT(varchar(30),COALESCE(@UOMPerStack,0)) +
						' /@QuantityToOrderStack = ' + CONVERT(varchar(30),COALESCE(@QuantityToOrderStack,0)),
						@LocationId
					)

			--sent individual order
			SET @OrderNumber = 0
			WHILE @OrderNumber < @QuantityToOrderStack
			BEGIN
				------------------------------------------------------------------------
				--order material
				------------------------------------------------------------------------
				--To be verified.
				--Documentation is not clear,should this SP make the Open request???


				--get the open requets time
				SELECT @p_RequestTimestamp = GETDATE()


				--get the UOM of the material requested
				SET @UOM = (SELECT  CONVERT(varchar(30),pmm.Value)
							FROM dbo.Property_MaterialDefinition_MaterialClass pmm	WITH(NOLOCK)
							JOIN dbo.Products_Aspect_MaterialDefinition a			WITH(NOLOCK) ON a.Origin1MaterialDefinitionId = pmm.MaterialDefinitionId
							WHERE a.Prod_id = @BOMProdId
								AND pmm.Name = 'UOM')	

					


				IF @debugFlag = 1
				BEGIN
					SELECT						@p_RequestTimestamp,
												@LocationId,
												@plid,
												@BOMProdCode,			--@p_PrimaryGcas
												@BOMRMProdCodeSub,		--@p_AlternateGcas
												1,						--@p_Quantity
												@UOM

					--INSERT dbo.Local_WAMAS_OPENREQUESTS ([RequestTime],[LocationID],[LineID],[PrimaryGCAS],[Status],[LastUpdatedTime])
					--VALUES (@p_RequestTimestamp,@LocationId,NULL,@BOMProdCode,'RequestMaterial', @p_RequestTimestamp)
				END
				ELSE
				BEGIN
					INSERT INTO @OUTPOUT (outputMessage,ErrorCode)
					EXEC [dbo].[spLocal_CmnSICreateOpenRequest]	@LocationId,
																@RunOutValue,			--Processorder		--V1.3 added
																@BOMProdCode,			--@p_PrimaryGcas
																@BOMRMProdCodeSub,		--@p_AlternateGcas
																1,						--@p_Quantity
																@UOM,
																@UserName
				END


				INSERT local_debug (CallingSP,timestamp, message, msg)
				VALUES (	@SPNAME,
							GETDATE(),
							'0850 - Order sent  ' +
							' /@p_RequestTimestamp = ' + CONVERT(varchar(30),@p_RequestTimestamp,20) +
							' /@LocationId = ' + COALESCE(@LocationId,'XXX') +
							' /@plid = ' + CONVERT(varchar(30),@plid) +
							' /@BOMProdCode = ' + @BOMProdCode +
							' /@BOMProdCodeSub = ' + COALESCE(@BOMRMProdCodeSub,'XXX')+
							' /@UOM = ' + COALESCE(@UOM,'XXX')	 ,
							@LocationId
						)


				SET @OrderNumber = @OrderNumber +1
			END


		END
	END



	SET @bomID = (SELECT MIN(BOMRMId) FROM @tblBOM WHERE BOMRMId > @bomID	)
END




INSERT local_debug (CallingSP,timestamp, message, msg)
VALUES (	@SPNAME,
			GETDATE(),
			'0999 -End of SP  ' ,
			@LocationId
		)