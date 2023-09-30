
--------------------------------------------------------------------------------------------------
-- Author				: Ugo Lapierre
-- Date created			: 15-Sep-2017
-- Version 				: 1.2
-- SP Type				: Call by several stored procedures
-- Caller				: Call by several stored procedures
-- Description			: Based on a product id, it calculates the still needed quantity to complete the Active+Next PO
--						: Only for SCO type of line
-- Editor tab spacing	: 4
--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
--================================================================================================
-- 1.0		15-Sep-2017		Ugo Lapierre		Initial Release
-- 1.1		20-Sep-2017		U. Lapierre			fix issue when prodID is only in the NEXT BOM.  The @puidInv, was not found.
-- 1.2		11-Nov-2017		Julien B. Ethier	Fix field name
-- 1.3		30-Jan-2018		U.Lapierre			Still needed returns 0 if the quantity is negative
-- 1.4		21-Mar-2018		U.Lapierre			Include the Open request in the still needed

/*
Declare	@OutputValue	nvarchar(25)
Exec spLocal_CmnCalculateStillNeeded_t 79,7462,1

*/


CREATE PROCEDURE [dbo].[spLocal_CmnCalculateStillNeeded_t]
@pathId							int,
@prodId							int,			--
@DebugFlag						int				--When debug flag = 1, no request are sent to WAMAS, data apears on screen


AS
SET NOCOUNT ON

DECLARE 
	@SPNAME							varchar(255),

	--PO
	@NextPPid						int,
	@ActivePPid						int,
	
	--BOM
	@NextBOMFormId					int,
	@ActiveBOMFormId				int,
	@NextOG							varchar(4),
	@ActiveOG						varchar(4),
	@BomQtyNext						Float,
	@BOMQtyActive					float,
	@BOMScrapFactorActive			float,
	@BOMScrapFactorNext				float,

	--UDPs
	@TableID						int,		
	@tfIdOG							int,
	@tfidSIManaged					int,
	@tfidConsumptionType			int,
	@tfidIsSAPSrapFactor			int,
	@tfidIsRMIScrapfactor			int,
	@tfidIsAutoOrdering				int,
	@tfidIsOGCounter				int,
	@tfidRMIScrapfactor				int,
	@IsRMISF						bit,
	@RMISF							float,

	--Production
	@ProductionCountNet				int,
	@ProductionCount				int,
	@ProductionWaste				int,
	@ProductionPuid					int,
	@StillNeededActive				int,
	@StillNeededNext				int,
	@StillNeeded					int, 

	--Inventory						
	@puidInv						int,
	@ProdIdInv						int,
	@SubProdIdInv					int,
	@StackCount						int,
	@StackQty						float,
	@StackCountR					int,
	@StackQtyR						float,

	--WAMAS
	@Location						varchar(50),
	@ProdCode						varchar(50),
	@UOMperPallet					float,
	@OpenRequestQty					float

DECLARE @ProdUnits	TABLE (
puid					int--,
---ActivePPID				int
)



--Raw material input UDP table
DECLARE @RMI	TABLE (
peiid					int,
puid					int,
OG						varchar(30),
SImanaged				bit,
IsSAPSrapFactor			bit,
IsRMIScrapfactor		bit,
RMIScrapfactor			float,
IsOGCounter				bit
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
OpenTableId					int,
RequestTime					datetime,
LineId						varchar(50),
ULID						varchar(50),
ProcessOrder				varchar(50),
VendorLot					varchar(50),
GCAS						varchar(8),
PrimaryGCAS					varchar(8),
AlternateGCAS				varchar(8),
Status						varchar(50),
Location					varchar(50),
Quantity					float,
UOM							varchar(50)
)

INSERT local_debug (CallingSP,timestamp, message, msg)
VALUES (	@SPNAME,
			GETDATE(),
			'0001 -Start of SP  ' ,
			CONVERT(varchar(30),@prodId)+'/'+CONVERT(varchar(30),@pathid)
		)



	

-----------------------------------------------------------------------
--Get active  Order
-----------------------------------------------------------------------
--Get the next order (ready or Initiate).  If it doesn't exist, exit the Stored proc
SET @ActivePPid = (	SELECT TOP 1 pp.pp_id 
					FROM dbo.production_plan pp 			WITH(NOLOCK) 
					JOIN dbo.production_plan_statuses pps	WITH(NOLOCK)	ON pp.pp_status_id = pps.pp_status_id
					WHERE pps.pp_status_desc IN ('Active')
						AND pp.path_id = @pathid
					ORDER BY actual_start_time DESC
					)


-----------------------------------------------------------------------
--Get  Next Order
-----------------------------------------------------------------------
--Get the next order (ready or Initiate).  If it doesn't exist, exit the Stored proc
SET @NextPPID = (	SELECT TOP 1 pp.pp_id 
					FROM dbo.production_plan pp 			WITH(NOLOCK) 
					JOIN dbo.production_plan_statuses pps	WITH(NOLOCK)	ON pp.pp_status_id = pps.pp_status_id
					WHERE pps.pp_status_desc IN ('Initiate','Ready')
						AND pp.path_id = @pathid
					)


IF @DebugFlag  =1
	SELECT @NextPPID 'Next PPID', @ActivePPid 'Active PPid'


INSERT local_debug (CallingSP,timestamp, message, msg)
VALUES (	@SPNAME,
		GETDATE(),
		'0100 - ' + 
		' Next PPID = ' + CONVERT(varchar(10),COALESCE(@nextPPID,-1)) + 
		' Active PPID = ' + CONVERT(varchar(10),COALESCE(@ActivePPid,-1)),
		CONVERT(varchar(30),@prodId)+'/'+CONVERT(varchar(30),@pathid)
	)






-----------------------------------------------------------------------
--Get BOM for the active and Next order
-----------------------------------------------------------------------


SET @TableID	= (	SELECT TableID 	FROM dbo.Tables WITH(NOLOCK) WHERE tableName = 'Bill_of_Material_Formulation_Item'	)

IF @NextPPID IS NOT NULL
BEGIN
	--Get the full BOM for the next order
	SET @NextBOMFormId = (SELECT BOM_Formulation_Id FROM dbo.production_plan WITH(NOLOCK) WHERE PP_Id = @nextPPID)

	INSERT @tblBOMNEXT 		(	
				PPId						,
				BOMRMProdId					,
				BOMRMQty					,
				BOMScrapFactor				,
				BOMRMFormItemId				,
				BOMRMStoragePUId			,
				BOMRMProdIdSub				
			)
	SELECT		@NextPPID,
				bomfi.Prod_Id, 
				bomfi.Quantity,
				bomfi.Scrap_Factor,
				bomfi.BOM_Formulation_Item_Id,
				bomfi.PU_Id,
				bomfs.Prod_Id
		FROM	dbo.Bill_Of_Material_Formulation_Item bomfi	WITH(NOLOCK)
		JOIN		dbo.Bill_Of_Material_Formulation bomf	WITH(NOLOCK) ON (bomf.BOM_Formulation_Id = bomfi.BOM_Formulation_Id)
		LEFT JOIN	dbo.Bill_Of_Material_Substitution bomfs	WITH(NOLOCK) ON (bomfs.BOM_Formulation_Item_Id = bomfi.BOM_Formulation_Item_Id)
		WHERE	bomf.BOM_Formulation_Id = @NextBOMFormId
			AND (bomfi.Prod_Id = @prodId OR bomfs.Prod_Id = @prodid)


	UPDATE bom
	SET BOMOG = tfv.value
	FROM @tblBOMNEXT bom
	JOIN dbo.Table_Fields_Values tfv	WITH(NOLOCK)	ON tfv.KeyId	= bom.BOMRMFormItemId
	JOIN  dbo.Table_Fields tf			WITH(NOLOCK)	ON tfv.table_field_id = tf.table_field_id AND tf.tableid = @TableID
	WHERE tf.table_field_desc = 'MaterialOriginGroup'

	SET @NextOG = (SELECT TOP 1 BOMOG FROM @tblBOMNEXT /*WHERE (BOMRMProdId = @prodId OR BOMRMProdIdSub = @prodid)*/)

	IF @DebugFlag  =1
	SELECT 'Next BOM ', * FROM @tblBOMNEXT

END


IF @ActivePPid IS NOT NULL
BEGIN
	--Get the full BOM for the next order
	SET @ActiveBOMFormId = (SELECT BOM_Formulation_Id FROM dbo.production_plan WITH(NOLOCK) WHERE PP_Id = @ActivePPid)

	INSERT @tblBOMActive		(	
				PPId						,
				BOMRMProdId					,
				BOMRMQty					,
				BOMScrapFactor				,
				BOMRMFormItemId				,
				BOMRMStoragePUId			,
				BOMRMProdIdSub				
			)
	SELECT		@ActivePPid,
				bomfi.Prod_Id, 
				bomfi.Quantity,
				bomfi.Scrap_Factor,
				bomfi.BOM_Formulation_Item_Id,
				bomfi.PU_Id,
				bomfs.Prod_Id
		FROM	dbo.Bill_Of_Material_Formulation_Item bomfi	WITH(NOLOCK)
		JOIN		dbo.Bill_Of_Material_Formulation bomf	WITH(NOLOCK) ON (bomf.BOM_Formulation_Id = bomfi.BOM_Formulation_Id)
		LEFT JOIN	dbo.Bill_Of_Material_Substitution bomfs	WITH(NOLOCK) ON (bomfs.BOM_Formulation_Item_Id = bomfi.BOM_Formulation_Item_Id)
		WHERE	bomf.BOM_Formulation_Id = @ActiveBOMFormId
			AND (bomfi.Prod_Id = @prodId OR bomfs.Prod_Id = @prodid)


	UPDATE bom
	SET BOMOG = tfv.value
	FROM @tblBOMActive bom
	JOIN dbo.Table_Fields_Values tfv	WITH(NOLOCK)	ON tfv.KeyId	= bom.BOMRMFormItemId
	JOIN  dbo.Table_Fields tf			WITH(NOLOCK)	ON tfv.table_field_id = tf.table_field_id AND tf.tableid = @TableID
	WHERE tf.table_field_desc = 'MaterialOriginGroup'

	SET @ActiveOG = (SELECT TOP 1 BOMOG FROM @tblBOMActive /*WHERE (BOMRMProdId = @prodId OR BOMRMProdIdSub = @prodid)*/)
		

	IF @DebugFlag  =1
	SELECT 'Active BOM ', * FROM @tblBOMActive

END



-----------------------------------------------------------------------
--Get required RMI UDPs
-----------------------------------------------------------------------
IF @ActiveOG IS NULL
	SET @ActiveOG = ''

IF @NextOG IS NULL
	SET @NextOG = ''



--Get table fields ids
SET @TableID	= (	SELECT TableID 	FROM dbo.Tables WITH(NOLOCK) WHERE tableName = 'PRDExec_Inputs'	)


SET @tfIdOG					= (SELECT Table_Field_id FROM dbo.Table_Fields WITH(NOLOCK) WHERE Table_Field_Desc = 'Origin Group'						AND TableID = @TableID	)
SET @tfidSIManaged			= (SELECT Table_Field_id FROM dbo.Table_Fields WITH(NOLOCK) WHERE Table_Field_Desc = 'SI_Managed'						AND TableID = @TableID	)
SET @tfidIsSAPSrapFactor	= (SELECT Table_Field_id FROM dbo.Table_Fields WITH(NOLOCK) WHERE Table_Field_Desc = 'UseSAPScrapFactor'				AND TableID = @TableID	)
SET @tfidIsRMIScrapfactor	= (SELECT Table_Field_id FROM dbo.Table_Fields WITH(NOLOCK) WHERE Table_Field_Desc = 'UseRMScrapFactor'					AND TableID = @TableID	)
SET @tfidRMIScrapfactor		= (SELECT Table_Field_id FROM dbo.Table_Fields WITH(NOLOCK) WHERE Table_Field_Desc = 'RMScrapFactor'					AND TableID = @TableID	)
SET @tfidIsOGCounter		= (SELECT Table_Field_id FROM dbo.Table_Fields WITH(NOLOCK) WHERE Table_Field_Desc = 'IsProductionCounterOG'			AND TableID = @TableID	)

INSERT local_debug (CallingSP,timestamp, message, msg)
VALUES (	@SPNAME,
			GETDATE(),
			'0200 - ' +
			' /@tfIdOG = ' + CONVERT(varchar(30),COALESCE(@tfIdOG,0)) +
			' /@tfidSIManaged = ' + CONVERT(varchar(30),COALESCE(@tfidSIManaged,0)) +
			' /@tfidIsSAPSrapFactor = ' + CONVERT(varchar(30),COALESCE(@tfidIsSAPSrapFactor,0)) +
			' /@tfidIsRMIScrapfactor = ' + CONVERT(varchar(30),COALESCE(@tfidIsRMIScrapfactor,0)) +
			' /@tfidRMIScrapfactor = ' + CONVERT(varchar(30),COALESCE(@tfidRMIScrapfactor,0)) +
			' /@tfidIsOGCounter = ' + CONVERT(varchar(30),COALESCE(@tfidIsOGCounter,0)) ,
			CONVERT(varchar(30),@prodId)+'/'+CONVERT(varchar(30),@pathid)
		)



-----------------------------------------------------------------------
--Get All production units in the paths
-----------------------------------------------------------------------
INSERT @ProdUnits (puid)
SELECT pu_id
FROM dbo.prdExec_path_units WITH(NOLOCK)
WHERE path_id = @pathid

IF @DebugFlag  =1
	SELECT 'Production prod_units', * FROM @ProdUnits



--retrieve and store all OG on the consumption unit
INSERT @RMI (
				peiid					,
				puid					,
				OG						,
				SImanaged				,
				IsSAPSrapFactor			,
				IsRMIScrapfactor		,
				RMIScrapfactor			,
				IsOGCounter				
						)
SELECT	pei.PEI_Id, 
		pei.PU_Id ,
		tfv.Value,									--OG
		CONVERT(bit,tfv2.value),					--SImanaged
		CONVERT(bit,tfv4.value),					--IsSAPSrapFactor
		CONVERT(bit,tfv5.value),					--IsRMIScrapfactor
		CONVERT(float,tfv6.value),					--RMIScrapfactor
		COALESCE(CONVERT(bit,tfv8.value),0)			--IsOGCounter
FROM dbo.PrdExec_Inputs pei			WITH(NOLOCK)	
JOIN @ProdUnits	pu									ON pei.pu_id	= pu.puid
JOIN dbo.Table_Fields_Values tfv	WITH(NOLOCK)	ON tfv.KeyId	= pei.PEI_Id
JOIN dbo.Table_Fields_Values tfv2	WITH(NOLOCK)	ON tfv2.KeyId	= pei.PEI_Id
JOIN dbo.Table_Fields_Values tfv4	WITH(NOLOCK)	ON tfv4.KeyId	= pei.PEI_Id
JOIN dbo.Table_Fields_Values tfv5	WITH(NOLOCK)	ON tfv5.KeyId	= pei.PEI_Id
JOIN dbo.Table_Fields_Values tfv6	WITH(NOLOCK)	ON tfv6.KeyId	= pei.PEI_Id
LEFT JOIN dbo.Table_Fields_Values tfv8	WITH(NOLOCK)	ON tfv8.KeyId	= pei.PEI_Id
WHERE tfv.table_field_id	= @tfIdOG
	AND tfv2.table_field_id	= @tfidSIManaged
	AND tfv4.table_field_id	= @tfidIsSAPSrapFactor
	AND tfv5.table_field_id	= @tfidIsRMIScrapfactor
	AND tfv6.table_field_id	= @tfidRMIScrapfactor
	AND tfv8.table_field_id	= @tfidIsOGCounter
	AND (tfv.Value = @NextOG OR tfv.Value = @ActiveOG)


IF @DebugFlag  =1
	SELECT 'RMI All', * FROM @RMI


INSERT local_debug (CallingSP,timestamp, message, msg)
VALUES (	@SPNAME,
			GETDATE(),
			'0220 - SI RMI identified' ,
			CONVERT(varchar(30),@prodId)+'/'+CONVERT(varchar(30),@pathid)
		)


--Clean prod_unit table to have only prod_unit involved in SI material
DELETE @ProdUnits WHERE puid NOT IN (SELECT DISTINCT puid FROM @RMI )

IF @DebugFlag  =1
	SELECT 'ProdUnits ', * FROM @ProdUnits







--------------------------------------------------------------
--Get still needed
--------------------------------------------------------------
SET @StillNeeded = 0
SET @StillNeededActive = 0
SET @StillNeededNext = 0

IF @ActiveOG <> ''
	SELECT	@IsRMISF	=	IsRMIScrapfactor,
			@RMISF		=	RMIScrapfactor
	FROM @RMI
	WHERE OG = @ActiveOG
ELSE
	SELECT	@IsRMISF	=	IsRMIScrapfactor,
			@RMISF		=	RMIScrapfactor
	FROM @RMI
	WHERE OG = @NextOG	

-------------------------------------------------
--Calculate the Still Needed for the active order
-------------------------------------------------
IF @ActivePPID IS NOT NULL
BEGIN
	--Get the actual production
	--Get production unit pu_id
	SET @ProductionPuid = (SELECT puid FROM @rmi WHERE OG = @ActiveOG)
		
	----Sum of all production events for this PP_ID
	SET @ProductionCount = (	SELECT SUM(initial_dimension_x) 
								FROM dbo.event_details WITH(NOLOCK)
								WHERE pu_id = @ProductionPuid
									AND pp_id = @Activeppid
							)

	--Sum of all waste for this PP_ID
	SET @ProductionWaste = (	SELECT SUM(amount) 
								FROM dbo.waste_event_details WITH(NOLOCK) 
								WHERE pu_id = @ProductionPuid
									AND event_id IN (	SELECT event_id
														FROM dbo.event_details WITH(NOLOCK)
														WHERE pu_id = @ProductionPuid
															AND pp_id = @Activeppid)
								)
	
	
	IF @ProductionCount IS NULL
		 SET @ProductionCount = 0

	IF @ProductionWaste IS NULL
		SET @ProductionWaste = 0

	--Get net production		
	SET @ProductionCountNet = @ProductionCount - @ProductionWaste



	IF @DebugFlag  =1
		SELECT @ProductionPuid as '@ProductionPuid', @ProductionCount as '@ProductionCount', @ProductionWaste as '@ProductionWaste', @ProductionCountNet as '@ProductionCountNet'

	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
			GETDATE(),
			'0300 - ' +
			' /@ProductionPuid = ' + CONVERT(varchar(30),COALESCE(@ProductionPuid,0)) +
			' /@ProductionCount = ' + CONVERT(varchar(30),COALESCE(@ProductionCount,0)) +
			' /@ProductionWaste = ' + CONVERT(varchar(30),COALESCE(@ProductionWaste,0)) +
			' /@ProductionCountNet = ' + CONVERT(varchar(30),COALESCE(@ProductionCountNet,0)) ,
			CONVERT(varchar(30),@prodId)+'/'+CONVERT(varchar(30),@pathid)
		)
	

	SELECT	@BomQtyActive			=  BOMRMQty,
			@BOMScrapFactorActive	=  COALESCE(BOMScrapFactor,0)
	FROM @tblBOMActive
	WHERE BOMOG = @ActiveOG

	IF @BomQtyActive IS NULL
		SET @BomQtyActive= 0

	IF @BOMScrapFactorActive IS NULL
		SET @BOMScrapFactorActive= 0


	SET @StillNeededActive = @BomQtyActive - @ProductionCountNet
	--V1.3
	IF @StillNeededActive < 0
		SET @StillNeededActive = 0


	--Add SAP (BOM) scrap factor
	IF (SELECT IsSAPSrapFactor FROM @RMI WHERE OG = @ActiveOG) = 1
		SET @StillNeededActive = @StillNeededActive + @StillNeededActive*@BOMScrapFactorActive/100

	--Add RMI Scrap factor
	IF @IsRMISF = 1
		SET @StillNeededActive = @StillNeededActive + @StillNeededActive*@RMISF/100


	IF @DebugFlag  =1
		SELECT @BomQtyActive as '@BomQtyActive', @BOMScrapFactorActive as '@BOMScrapFactorActive', @IsRMISF as '@IsRMISF', @RMISF as '@RMISF', @StillNeededActive as '@StillNeededActive'

	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
			GETDATE(),
			'0320 - ' +
			' /@BomQtyActive = ' + CONVERT(varchar(30),COALESCE(@BomQtyActive,0)) +
			' /@BOMScrapFactorActive = ' + CONVERT(varchar(30),COALESCE(@BOMScrapFactorActive,0)) +
			' /@IsRMISF = ' + CONVERT(varchar(30),COALESCE(@IsRMISF,0)) +
			' /@RMISF = ' + CONVERT(varchar(30),COALESCE(@RMISF,0)) +
			' /@StillNeededActive = ' + CONVERT(varchar(30),COALESCE(@StillNeededActive,0)),
			CONVERT(varchar(30),@prodId)+'/'+CONVERT(varchar(30),@pathid)
		)


END


-------------------------------------------------
--Calculate the Still Needed for the next order
-------------------------------------------------
IF @NextPPID IS NOT NULL
BEGIN
	SELECT	@BomQtyNext			=  COALESCE(BOMRMQty,0),
			@BOMScrapFactorNext	=  COALESCE(BOMScrapFactor,0)
	FROM @tblBOMNext
	WHERE BOMOG = @NextOG

	IF @BomQtyNext IS NULL
		SET @BomQtyNext= 0

	IF @BOMScrapFactorNext IS NULL
		SET @BOMScrapFactorNext= 0

	SET @StillNeededNext = @BomQtyNext 


	--Add SAP (BOM) scrap factor
	IF (SELECT IsSAPSrapFactor FROM @RMI WHERE OG = @NextOG) = 1
		SET @StillNeededNext = @StillNeededNext + @StillNeededNext*@BOMScrapFactorNext/100

	--Add RMI Scrap factor
	IF @IsRMISF = 1
		SET @StillNeededNext = @StillNeededNext + @StillNeededNext*@RMISF/100


	IF @DebugFlag  =1
		SELECT @BomQtyNext as '@BomQtyNEXT', @BOMScrapFactorNEXT as '@BOMScrapFactorNEXT', @IsRMISF as '@IsRMISF', @RMISF as '@RMISF', @StillNeededNEXT as '@StillNeededNEXT'

	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
			GETDATE(),
			'0340 - ' +
			' /@BomQtyNEXT = ' + CONVERT(varchar(30),COALESCE(@BomQtyNEXT,0)) +
			' /@BOMScrapFactorNEXT = ' + CONVERT(varchar(30),COALESCE(@BOMScrapFactorNEXT,0)) +
			' /@IsRMISF = ' + CONVERT(varchar(30),COALESCE(@IsRMISF,0)) +
			' /@RMISF = ' + CONVERT(varchar(30),COALESCE(@RMISF,0)) +
			' /@StillNeededNEXT = ' + CONVERT(varchar(30),COALESCE(@StillNeededNEXT,0)),
			CONVERT(varchar(30),@prodId)+'/'+CONVERT(varchar(30),@pathid)
		)

END

SET @StillNeeded = @StillNeededNEXT + @StillNeededActive




--Get the Inventory
-- If there is an active order, we get the prodId and the sub prod id of the active order.  Otherwise, use the next
IF EXISTS(SELECT BOMRMProdId FROM @tblBOMActive WHERE BOMRMProdId = @prodId)  --V1.1
BEGIN
	SELECT  @puidInv		=	BOMRMStoragePUId	,
			@ProdIdInv		=	BOMRMProdId			,
			@SubProdIdInv	=	BOMRMProdIdSub
	FROM @tblBOMActive 
	WHERE BOMRMProdId = @prodId
END
ELSE
BEGIN
	SELECT  @puidInv		=	BOMRMStoragePUId	,
			@ProdIdInv		=	BOMRMProdId			,
			@SubProdIdInv	=	BOMRMProdIdSub
	FROM @tblBOMNext 
	WHERE BOMRMProdId = @prodId
END



IF @DebugFlag  =1
	SELECT @puidInv as '@puidInv', @ProdIdInv as '@ProdIdInv', @SubProdIdInv as '@SubProdIdInv'


-------------------------------------------------------------
--V1.4
--Get open request
--------------------------------------------------------------
--get prod_code
SET @ProdCode = (SELECT prod_code FROM dbo.products WHERE prod_id = @prodId)

--Get Location
SET @Location = (SELECT CONVERT(varchar(50),peec.value)
				FROM dbo.Property_Equipment_EquipmentClass peec	WITH(NOLOCK)
				JOIN dbo.PAEquipment_Aspect_SOAEquipment a		WITH(NOLOCK)	ON peec.equipmentid = a.Origin1EquipmentId
				WHERE	peec.class = 'PE:SI_WMS'
					AND peec.name = 'Destination Location'
					AND a.pu_id = @puidInv
					)

INSERT @Openrequest (OpenTableId, RequestTime, Location,LineId,  ProcessOrder, PrimaryGCAS, AlternateGCAS, GCAS, Quantity,UOM, Status, ULID,VendorLot) -- 1.2 add process order
EXEC [dbo].[spLocal_CmnSIGetOpenRequest] @Location, NULL,@ProdCode, NULL 

--Get UOM per pallet
SET @UOMperPallet = (	SELECT CONVERT(varchar(30), pmm.Value)
						FROM dbo.Property_MaterialDefinition_MaterialClass pmm	WITH(NOLOCK)
						JOIN [dbo].[Products_Aspect_MaterialDefinition] a		WITH(NOLOCK) ON a.[Origin1MaterialDefinitionId] = pmm.MaterialDefinitionId
						WHERE a.prod_id = @prodId
						AND pmm.Name = 'UOM Per Pallet')	

SET @OpenRequestQty = (	SELECT COALESCE(SUM(Quantity),0) FROM @Openrequest WHERE ULID IS NOT NULL )						--Get OR when SI give amount
SET @OpenRequestQty = @OpenRequestQty + (	SELECT COALESCE(SUM(@UOMperPallet),0) FROM @Openrequest WHERE ULID IS NULL )	--Get OR when SI has not provided the amount yet

IF @DebugFlag  =1
	SELECT @OpenRequestQty as '@OpenRequestQty'

SET @StillNeeded = @StillNeeded - @OpenRequestQty


--End of V1.4




--Get the count and qty of inventory
SELECT	@StackCount = COUNT(e.event_id),
		@StackQty	= COALESCE(SUM(ed.final_dimension_x),0)
FROM dbo.events e				WITH(NOLOCK)
JOIN dbo.event_details	ed		WITH(NOLOCK)	ON e.event_id = ed.event_id
JOIN dbo.production_Status ps	WITH(NOLOCK)	ON e.event_status = ps.prodStatus_id
WHERE e.pu_id = @puidInv
	AND ps.prodStatus_Desc IN ('Delivered','Running','To Be Returned')
	AND e.applied_product IN (@ProdIdInv,@SubProdIdInv)


--Should we remove the 'To be returned' that are waiting for the wait ?
SET @Location = (SELECT CONVERT(varchar(50),peec.value)
				FROM dbo.Property_Equipment_EquipmentClass peec	WITH(NOLOCK)
				JOIN dbo.PAEquipment_Aspect_SOAEquipment a		WITH(NOLOCK)	ON peec.equipmentid = a.Origin1EquipmentId
				WHERE	peec.class = 'PE:SI_WMS'
					AND peec.name = 'Destination Location'
					AND a.pu_id = @puidInv
					)

SELECT	@StackCountR = COUNT(OpenTableID),
		@StackQtyR	= COALESCE(SUM([QuantityValue]),0)
FROM [dbo].[Local_WAMAS_OPENREQUESTS] w			WITH(NOLOCK)
JOIN dbo.products p								WITH(NOLOCK) ON W.GCAS = p.prod_code
WHERE (p.prod_id = @ProdIdInv OR p.prod_id = @SubProdIdInv)
	AND w.[Status] = 'ToBeReturned'

IF @DebugFlag  =1
	SELECT @StackCount as '@StackCount', @StackQty as '@StackQty', @StackCountR as '@StackCountR', @StackQtyR as '@StackQtyR'
---------------------------------------------------------------------



--Final still needed nned to have inventory deduced
--SET @StillNeeded = @StillNeeded - @StackQty



--Final Output

SELECT	@StillNeededNext					as 'StillNeededNext',
		@StillNeededActive					as 'StillNeededActive',
		@StillNeeded						as 'StillNeeded',
		CASE   --V1.3
			WHEN @StillNeeded-@StackQty <= 0 THEN 0   
			WHEN @StillNeeded-@StackQty > 0 THEN @StillNeeded-@StackQty  
		END 		as 'StillNeededInventoryIncluded',
		@StackQty - @StackQtyR				as 'QtyInventory',
		@StackCount	- @StackCountR			as 'StackCount'











INSERT local_debug (CallingSP,timestamp, message, msg)
VALUES (	@SPNAME,
			GETDATE(),
			'0999 -End of SP  ' ,
			@prodId
		)



