 
 
 
/*	-------------------------------------------------------------------------------
	dbo.spLocal_MPWS_GENL_CalculatePOandBOMStatus
	
	Calculates and updates statuses for all Preweigh components of a PO.
	
	First gets rows for x. Because a Kit can span PO's, then get any rows for y only if they are in KITxy 
	
	POx		--		BOMFIx		--		DISPx		--		CARSECx		--	CARx
											\
											KITxy
											/
	POy		--		BOMFIy		--		DISPy		--		CARSECy		--	CARy
	
	Date			Version		Build	Author  
	17-Jun-2016		001			001		Jim Cameron (GEIP)		Initial development	
 
test
 
DECLARE @ReturnStatus	INT, @ReturnMessage	VARCHAR(255)
EXEC dbo.spLocal_MPWS_GENL_SetStatuses @ReturnStatus OUTPUT, @ReturnMessage OUTPUT
, @DispEventId=5740905
 
DECLARE @ReturnStatus	INT, @ReturnMessage	VARCHAR(255)
EXEC dbo.spLocal_MPWS_GENL_SetStatuses @ReturnStatus OUTPUT, @ReturnMessage OUTPUT
, @KitEventId=5740909
 
DECLARE @ReturnStatus	INT, @ReturnMessage	VARCHAR(255)
EXEC dbo.spLocal_MPWS_GENL_SetStatuses @ReturnStatus OUTPUT, @ReturnMessage OUTPUT
, @CarEventId=5740759
 
DECLARE @ReturnStatus	INT, @ReturnMessage	VARCHAR(255)
EXEC dbo.spLocal_MPWS_GENL_SetStatuses @ReturnStatus OUTPUT, @ReturnMessage OUTPUT
, @ProcessOrder='905046847-3'
 
SELECT @ReturnStatus, @ReturnMessage
 
 
*/	-------------------------------------------------------------------------------
CREATE   PROCEDURE [dbo].[spLocal_MPWS_GENL_SetStatuses]
	@ErrorCode		INT				OUTPUT,		-- Flag to indicate Success or Failure (1-Success,0-Failure)s
	@ErrorMessage	VARCHAR(255)	OUTPUT,
	@PPId			INT				= NULL,
	@ProcessOrder	VARCHAR(50)		= NULL,
	@CarEventId		INT				= NULL,
	@CarEventNum	VARCHAR(50)		= NULL,
	@KitEventId		INT				= NULL,
	@KitEventNum	VARCHAR(50)		= NULL,
	@DispEventId	INT				= NULL,
	@DispEventNum	VARCHAR(50)		= NULL
 
AS
 
SET NOCOUNT ON;
 
BEGIN	-- BEGINNING OF BLOCK
 
DECLARE 
	@EventId	INT,
	@BomfiId	INT,
	@PPlanId	INT,
	@StatusId	INT,
	@ReturnCode	INT,
	@Timestamp	DATETIME = GETDATE();
		
DECLARE @Ids TABLE
(
	Selected				BIT DEFAULT (0),
	PONum					VARCHAR(50),
	PPId					INT,
	PathId					INT,
	POStatus				VARCHAR(50),
	NewPOStatus				VARCHAR(50),
	POStatusOrder			INT,
	CarId					INT,
	CarNum					VARCHAR(50),
	CarPUId					INT,
	CarStatus				VARCHAR(50),
	NewCarStatus			VARCHAR(50),
	CarStatusOrder			INT,
	CarLocationCode			VARCHAR(50),
	CarLocationDesc			VARCHAR(50),
	CSecId					INT,
	CSecNum					VARCHAR(50),
	CSecPUId				INT,
	CSecStatus				VARCHAR(50),
	NewCSecStatus			VARCHAR(50),
	CSecStatusOrder			INT,
	CSecLocationCode		VARCHAR(50),
	CSecLocationDesc		VARCHAR(50),
	KitId					INT,
	KitNum					VARCHAR(50),
	KitPUId					INT,
	KitStatus				VARCHAR(50),
	NewKitStatus			VARCHAR(50),
	KitStatusOrder			INT,
	KitLocationCode			VARCHAR(50),
	KitLocationDesc			VARCHAR(50),
	DispId					INT,
	DispNum					VARCHAR(50),
	DispPUId				INT,
	DispStatus				VARCHAR(50),
	NewDispStatus			VARCHAR(50),
	DispStatusOrder			INT,
	DispBomfiId				INT,
	DispQuantity			FLOAT,
	DispLocationCode		VARCHAR(50),
	DispLocationDesc		VARCHAR(50),
	BomfiId					INT,
	BomfiProdId				INT,
	BomfiProdCode			VARCHAR(50),
	BomfiProdDesc			VARCHAR(50),
	BomfiQuantity			FLOAT,
	BomfiStatus				VARCHAR(50),
	NewBomfiStatus			VARCHAR(50),
	BomfiStatusOrder		INT,
	RMCId					INT,
	RMCNum					VARCHAR(50),
	RMCPUId					INT,
	RMCStatus				VARCHAR(50)
);
 
-- production_status (events) and production_plan_statuses (pplan/bomfi) should have the same pw descriptions
DECLARE @StatusOrder TABLE
(
	StatusDesc	VARCHAR(50),
	StatusOrder	INT
);
 
DECLARE @POItems TABLE
(
	PathId			INT,
	PPId			INT,
	PONum			VARCHAR(50),
	POStatus		VARCHAR(50),
	POStatusOrder	INT,
	BomfiId			INT,
	KitEventId		INT
);
 
----SELECT 
----	@ErrorCode = 0,
----	@ErrorMessage = 'Initializing';
 
----IF COALESCE(@PPId, @ProcessOrder, @CarEventId, @CarEventNum, @CSecEventId, @CSecEventNum, @KitEventId, @KitEventNum, @DispEventId, @DispEventNum) IS NULL
----BEGIN
 
----	SELECT 
----		@ErrorCode = -1,
----		@ErrorMessage = 'At least 1 parameter has to be non-null.';
 
----	--RETURN;
	
----END;
 
INSERT @StatusOrder
	VALUES ('Created', 0);
	
INSERT @StatusOrder
	SELECT
		pps.PP_Status_Desc,
		stat.Value PPOrder
	FROM dbo.Production_Plan_Statuses pps
		CROSS APPLY dbo.fnLocal_MPWS_GetUDP(pps.PP_Status_Id, 'PreWeigh Order', 'Production_Plan_Statuses') stat
	WHERE stat.Value IS NOT NULL;
 
IF @PPId IS NOT NULL OR @ProcessOrder IS NOT NULL
	OR COALESCE(@PPId, @ProcessOrder, @CarEventId, @CarEventNum, @KitEventId, @KitEventNum, @DispEventId, @DispEventNum) IS NULL
BEGIN
 
	INSERT @POItems (PathId, PPId, PONum, POStatus, POStatusOrder, BomfiId, KitEventId)
		SELECT DISTINCT
			vPO.PreweighPathId,
			vPO.PreweighPPId,
			vPO.PreweighPO,
			vPO.PreweighPOStatus,
			soPO.StatusOrder,
			bomfi.BOM_Formulation_Item_Id,
			kit2disp.KitEventId
		FROM dbo.vMPWS_ProcessOrder vPO
			LEFT JOIN @StatusOrder soPO ON soPO.StatusDesc = vPO.PreweighPOStatus
			JOIN dbo.vMPWS_BomItems bomfi ON bomfi.BOM_Formulation_Id = vPO.PreweighBOMF_Id
			LEFT JOIN dbo.vMPWS_Dispense vDisp ON vDisp.DispBomfiId = bomfi.BOM_Formulation_Item_Id
			LEFT JOIN dbo.vMPWS_KitToDispense kit2disp ON kit2disp.DispEventId = vDisp.DispEventId
		WHERE (vPO.PreweighPPId = @PPId OR @PPId IS NULL)
			AND (vPO.PreweighPO = @ProcessOrder OR @ProcessOrder IS NULL)
			
END
ELSE IF @CarEventId IS NOT NULL OR @CarEventNum IS NOT NULL
BEGIN
 
	INSERT @POItems (PathId, PPId, PONum, POStatus, POStatusOrder, BomfiId, KitEventId)
		SELECT DISTINCT
			vPO.PreweighPathId,
			vPO.PreweighPPId,
			vPO.PreweighPO,
			vPO.PreweighPOStatus,
			soPO.StatusOrder,
			bomfi2.BOM_Formulation_Item_Id,
			kit2disp.KitEventId
		FROM dbo.vMPWS_ProcessOrder vPO
			LEFT JOIN @StatusOrder soPO ON soPO.StatusDesc = vPO.PreweighPOStatus
			JOIN dbo.vMPWS_BomItems bomfi2 ON bomfi2.BOM_Formulation_Id = vPO.PreweighBOMF_Id
			JOIN dbo.vMPWS_BomItems bomfi ON bomfi.BOM_Formulation_Id = vPO.PreweighBOMF_Id
			JOIN dbo.vMPWS_Dispense vDisp ON vDisp.DispBomfiId = bomfi.BOM_Formulation_Item_Id
			JOIN dbo.vMPWS_CarrierSectionToDispense csec2disp ON csec2disp.DispEventId = vDisp.DispEventId
			JOIN dbo.vMPWS_CarrierSectionToCarrier csec2car ON csec2car.CSecEventId = csec2disp.CSecEventId
			JOIN dbo.vMPWS_Carrier vCar ON vCar.CarEventId = csec2car.CarEventId
			LEFT JOIN dbo.vMPWS_KitToDispense kit2disp ON kit2disp.DispEventId = vDisp.DispEventId
		WHERE (vCar.CarEventId = @CarEventId OR @CarEventId IS NULL)
			AND (vCar.CarEventNum = @CarEventNum OR @CarEventNum IS NULL)
 
END
ELSE IF @KitEventId IS NOT NULL OR @KitEventNum IS NOT NULL
BEGIN
 
	INSERT @POItems (PathId, PPId, PONum, POStatus, POStatusOrder, BomfiId, KitEventId)
		SELECT DISTINCT
			vPO.PreweighPathId,
			vPO.PreweighPPId,
			vPO.PreweighPO,
			vPO.PreweighPOStatus,
			soPO.StatusOrder,
			bomfi2.BOM_Formulation_Item_Id,
			kit2disp.KitEventId
		FROM dbo.vMPWS_ProcessOrder vPO
			LEFT JOIN @StatusOrder soPO ON soPO.StatusDesc = vPO.PreweighPOStatus
			JOIN dbo.vMPWS_BomItems bomfi2 ON bomfi2.BOM_Formulation_Id = vPO.PreweighBOMF_Id
			JOIN dbo.vMPWS_BomItems bomfi ON bomfi.BOM_Formulation_Id = vPO.PreweighBOMF_Id
			JOIN dbo.vMPWS_Dispense vDisp ON vDisp.DispBomfiId = bomfi.BOM_Formulation_Item_Id
			JOIN dbo.vMPWS_KitToDispense kit2disp ON kit2disp.DispEventId = vDisp.DispEventId
			JOIN dbo.vMPWS_Kit vKit ON vKit.KitEventId = kit2disp.KitEventId
		WHERE (vKit.KitEventId = @KitEventId OR @KitEventId IS NULL)
			AND (vKit.KitEventNum = @KitEventNum OR @KitEventNum IS NULL)
 
END
ELSE IF @DispEventId IS NOT NULL OR @DispEventNum IS NOT NULL
BEGIN
 
	INSERT @POItems (PathId, PPId, PONum, POStatus, POStatusOrder, BomfiId, KitEventId)
		SELECT DISTINCT
			vPO.PreweighPathId,
			vPO.PreweighPPId,
			vPO.PreweighPO,
			vPO.PreweighPOStatus,
			soPO.StatusOrder,
			bomfi2.BOM_Formulation_Item_Id,
			kit2disp.KitEventId
		FROM dbo.vMPWS_ProcessOrder vPO
			LEFT JOIN @StatusOrder soPO ON soPO.StatusDesc = vPO.PreweighPOStatus
			JOIN dbo.vMPWS_BomItems bomfi2 ON bomfi2.BOM_Formulation_Id = vPO.PreweighBOMF_Id
			JOIN dbo.vMPWS_BomItems bomfi ON bomfi.BOM_Formulation_Id = vPO.PreweighBOMF_Id
			JOIN dbo.vMPWS_Dispense vDisp ON vDisp.DispBomfiId = bomfi.BOM_Formulation_Item_Id
			LEFT JOIN dbo.vMPWS_KitToDispense kit2disp ON kit2disp.DispEventId = vDisp.DispEventId
		WHERE (vDisp.DispEventId = @DispEventId OR @DispEventId IS NULL)
			AND (vDisp.DispEventNum = @DispEventNum OR @DispEventNum IS NULL)
 
END;
 
-- because a Kit can belong to multiple PO's, look for additional
INSERT @POItems (PathId, PPId, PONum, POStatus, POStatusOrder, BomfiId)
	SELECT DISTINCT
		vPO.PreweighPathId,
		vPO.PreweighPPId,
		vPO.PreweighPO,
		vPO.PreweighPOStatus,
		soPO.StatusOrder,
		bomfi2.BOM_Formulation_Item_Id
	FROM dbo.vMPWS_ProcessOrder vPO
		JOIN @StatusOrder soPO ON soPO.StatusDesc = vPO.PreweighPOStatus
		JOIN dbo.vMPWS_BomItems bomfi2 ON bomfi2.BOM_Formulation_Id = vPO.PreweighBOMF_Id
		JOIN dbo.vMPWS_BomItems bomfi ON bomfi.BOM_Formulation_Id = vPO.PreweighBOMF_Id
		JOIN dbo.vMPWS_Dispense vDisp ON vDisp.DispBomfiId = bomfi.BOM_Formulation_Item_Id
		JOIN dbo.vMPWS_KitToDispense kit2disp ON kit2disp.DispEventId = vDisp.DispEventId
		JOIN dbo.vMPWS_Kit vKit ON vKit.KitEventId = kit2disp.KitEventId
		JOIN @POItems po ON po.KitEventId = vKit.KitEventId
	WHERE vPO.PreweighPPId NOT IN (SELECT DISTINCT PPId FROM @POItems)
 
-- now that we have all the bom items in @POItems, get everything associated with them
INSERT @Ids (	PONum, POStatus, POStatusOrder, PPId, PathId,
				CarId, CarNum, CarStatus, CarStatusOrder, CarLocationCode, CarLocationDesc,
				CSecId, CSecNum, CSecStatus, CSecStatusOrder,
				KitId, KitNum, KitStatus, KitStatusOrder, KitLocationCode, KitLocationDesc,
				DispId, DispNum, DispPUId, DispStatus, DispStatusOrder, DispBomfiId, DispQuantity, DispLocationCode, DispLocationDesc,
				BomfiId, BomfiProdId, BomfiProdCode, BomfiProdDesc, BomfiQuantity, BomfiStatus, BomfiStatusOrder, 
				RMCId, RMCNum, RMCPUId, RMCStatus
			)
	SELECT DISTINCT
		po.PONum, po.POStatus, po.POStatusOrder, po.PPId, po.PathId, 
		vCar.CarEventId, vCar.CarEventNum, vCar.CarStatus, soCar.StatusOrder, vCar.CarLocationCode, vCar.CarLocationDesc,
		vCSec.CSecEventId, vCSec.CSecEventNum, vCSec.CSecStatus, soCSec.StatusOrder,
		vKit.KitEventId, vKit.KitEventNum, vKit.KitStatus, soKit.StatusOrder, vKit.KitLocationCode, vKit.KitLocationDesc,
		vDisp.DispEventId, vDisp.DispEventNum, vDisp.DispPUId, vDisp.DispStatus, soDisp.StatusOrder, vDisp.DispBomfiId, vDisp.DispQuantity, vDisp.DispLocationCode, vDisp.DispLocationDesc,
		bomfi.BOM_Formulation_Item_Id, bomfi.BomfiProdId, bomfi.BomfiProdCode, bomfi.BomfiProdDesc, bomfi.BomfiQuantity, bomfi.BOMItemStatusDesc, soBomfi.StatusOrder,
		vRmc.RmcEventId, vRmc.RmcEventNum, vRmc.RmcPUId, vRmc.RmcStatus
	FROM @POItems po
		JOIN dbo.vMPWS_Dispense vDisp ON vDisp.DispBomfiId = po.BomfiId
		JOIN @StatusOrder soDisp ON soDisp.StatusDesc = vDisp.DispStatus
		
		LEFT JOIN dbo.vMPWS_KitToDispense kit2disp ON kit2disp.DispEventId = vDisp.DispEventId
		LEFT JOIN dbo.vMPWS_Kit vKit ON vKit.KitEventId = kit2disp.KitEventId
		LEFT JOIN @StatusOrder soKit ON soKit.StatusDesc = vKit.KitStatus
				
		JOIN dbo.vMPWS_BomItems bomfi ON bomfi.BOM_Formulation_Item_Id = vDisp.DispBomfiId
		JOIN @StatusOrder soBomfi ON soBomfi.StatusDesc = bomfi.BOMItemStatusDesc
		
		JOIN dbo.vMPWS_RmcToDispense disp2rmc ON disp2rmc.DispEventId = vDisp.DispEventId
		JOIN dbo.vMPWS_Rmc vRmc ON vRmc.RmcEventId = disp2rmc.RMCEventId
		
		LEFT JOIN dbo.vMPWS_CarrierSectionToKit kit2csec ON kit2csec.KitEventId = vKit.KitEventId
		LEFT JOIN dbo.vMPWS_CarrierSection vCSec ON vCSec.CSecEventId = kit2csec.CSecEventId
		LEFT JOIN @StatusOrder soCSec ON soCSec.StatusDesc = vCSec.CSecStatus
 
		LEFT JOIN dbo.vMPWS_CarrierSectionToCarrier cs2c ON cs2c.CSecEventId = vCSec.CSecEventId
		LEFT JOIN dbo.vMPWS_Carrier vCar ON vCar.CarEventId = cs2c.CarEventId
		LEFT JOIN @StatusOrder soCar ON soCar.StatusDesc = vCar.CarStatus
 
 
END; -- END OF BLOCK
 
 
 
IF EXISTS (SELECT CarId FROM @Ids WHERE CarLocationDesc IN ('Ready For Production', 'Staged'))
BEGIN
 
/*
 
If carrier location description = "Ready for Production"
1.	carrier status = "Ready for Production"
2.	Dispense status = "Ready for Production"
3.	Calculate Kit status (least status of all carriers to which the kit is assigned)
4.	Calculate BOM Item status (are all dispense containers in "Ready for Production", if yes, update status to "Ready for Production")
5.	Calculate PO status (are all BOM Items in "Ready for Production", if yes, update status to "Ready for Production")
 
*/
 
	UPDATE i
		SET NewCarStatus = CarLocationDesc,
			NewDispStatus = CarLocationDesc
		FROM @Ids i
		WHERE i.CarLocationDesc IN ('Ready For Production', 'Staged')
	
	-- kit can span multiple carriers
	;WITH CarStat AS
	(
		SELECT
			i.KitId,
			MIN(soCar.StatusOrder) MinCarStatusOrder
		FROM @Ids i
			JOIN dbo.Event_Components KitToCSec ON KitToCSec.Event_Id = i.KitId
			JOIN dbo.Events eCSec ON eCSec.Event_Id = KitToCSec.Source_Event_Id
			JOIN dbo.Prod_Units_Base puCSec ON puCSec.PU_Id = eCSec.PU_Id
				AND puCSec.Equipment_Type = 'Carrier Section'
			JOIN dbo.Event_Components CSecToCar ON CSecToCar.Event_Id = eCSec.Event_Id
			JOIN dbo.Events eCar ON eCar.Event_Id = CSecToCar.Source_Event_Id
			JOIN dbo.Prod_Units_Base puCar ON puCar.PU_Id = eCar.PU_Id
				AND puCar.Equipment_Type = 'Carrier'
			JOIN dbo.Production_Status psCar ON psCar.ProdStatus_Id = eCar.Event_Status
			JOIN @StatusOrder soCar ON soCar.StatusDesc = psCar.ProdStatus_Desc
		GROUP BY i.KitId
	)
	UPDATE i
		SET NewKitStatus = soNew.StatusDesc
		FROM @Ids i
			JOIN CarStat ON CarStat.KitId = i.KitId
			JOIN @StatusOrder soNew ON soNew.StatusOrder = CarStat.MinCarStatusOrder
			
	;WITH DispStat AS
	(
		SELECT
			i.BomfiId,
			MIN(i.DispStatusOrder) MinDispStatusOrder
		FROM @Ids i
		GROUP BY i.BomfiId
	)
	UPDATE i
		SET NewBomfiStatus = soNew.StatusDesc
		FROM @Ids i
			JOIN DispStat ON DispStat.BomfiId = i.BomfiId
			JOIN @StatusOrder soNew ON soNew.StatusOrder = DispStat.MinDispStatusOrder
		WHERE soNew.StatusDesc IN ('Ready For Production', 'Staged')
		
END;
 
 
-- update kit status based on bomfi quantity vs dispensed quantity and status
WITH kitboms AS
(
	-- kit can have multiple rows for same bomfi quantity, get distinct
	SELECT DISTINCT
		i.KitId,
		i.BomfiId,
		i.BomfiProdId,
		i.BomfiQuantity
	FROM @Ids i
	WHERE i.KitId IS NOT NULL
)
, tols AS
(
	SELECT
		BomfiProdId,
		(100.0 - MPWSToleranceLower) / 100.0 MPWSToleranceLower,
		(100.0 + MPWSToleranceUpper) / 100.0 MPWSToleranceUpper
	FROM (
			SELECT DISTINCT
			--prodDef.Prod_Id ,
				kitboms.BomfiProdId,
				propDef.Name,
				CAST(propDef.Value AS FLOAT) Value
			FROM dbo.Products_Aspect_MaterialDefinition prodDef
				JOIN dbo.Property_MaterialDefinition_MaterialClass propDef ON propDef.MaterialDefinitionId = prodDef.Origin1MaterialDefinitionId
				JOIN kitboms ON prodDef.Prod_Id = kitboms.BomfiProdId
			WHERE propDef.Class = 'Pre-Weigh'
				AND propDef.Name IN ('MPWSToleranceLower', 'MPWSToleranceUpper')
		) a
		PIVOT (MAX(Value) FOR Name IN ([MPWSToleranceLower], [MPWSToleranceUpper])) pvt
)
, kitdisp AS
(
	SELECT
		i.KitId,
		i.BomfiId,
		i.BomfiProdId,
		kitboms.BomfiQuantity * MPWSToleranceLower LowerQuantityLimit,
		kitboms.BomfiQuantity * MPWSToleranceUpper UpperQuantityLimit,
		kitboms.BomfiQuantity KitBomfiQty,
		SUM(i.DispQuantity) KitDispQty,
		MIN(i.DispStatusOrder) MinKitDispStatusOrder
	FROM @Ids i
		JOIN kitboms ON kitboms.KitId = i.KitId
			AND kitboms.BomfiId = i.BomfiId
		JOIN tols ON tols.BomfiProdId = i.BomfiProdId
	WHERE i.KitId IS NOT NULL
	GROUP BY i.KitId, i.BomfiId, i.BomfiProdId, MPWSToleranceLower, MPWSToleranceUpper, kitboms.BomfiQuantity
)
UPDATE i
	SET NewKitStatus = 'Kitted'
	FROM @Ids i
		JOIN kitdisp ON kitdisp.KitId = i.KitId
			AND kitdisp.BomfiId = i.BomfiId
		JOIN @StatusOrder soDisp ON soDisp.StatusOrder = MinKitDispStatusOrder
	WHERE kitdisp.KitDispQty BETWEEN kitdisp.LowerQuantityLimit AND kitdisp.UpperQuantityLimit 	-- if total bom item quanity for the kit = total dispensed quantity for the kit
		AND soDisp.StatusDesc = 'Kitted'			-- and all dispenses are in kitted
		
------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------
 
/*
	update events event_status where NewXxxStatus <> XxxStatus and NewXxxStatus is not null
	if no rows match any cursor where clause, no updates are performed. i.e. no IF condition needed.
*/
 
DECLARE Car_Cursor CURSOR FOR
	SELECT DISTINCT
		i.CarId,
		ps.ProdStatus_Id
	FROM @Ids i
		JOIN dbo.Production_Status ps ON ps.ProdStatus_Desc = i.NewCarStatus
	WHERE i.NewCarStatus <> i.CarStatus
		AND NewCarStatus IS NOT NULL;
 
OPEN Car_Cursor;
FETCH NEXT FROM Car_Cursor INTO @EventId, @StatusId;
 
WHILE @@FETCH_STATUS = 0
BEGIN
 
	--EXEC @ReturnCode = dbo.spServer_DBMgrUpdEvent
	SELECT 'Update Car',
		@EventId	OUTPUT,           
		NULL,
		NULL,
		@Timestamp,	-- TimeStamp
		NULL,		-- Applied Product
		NULL,		-- SourceEvent
		@StatusId,	-- Event Status
		2,			-- TransType
		0,			-- TransNum
		NULL,		-- User
		NULL,		-- CommentId,
		NULL,		-- @EventSubtypeId 	  	  	 
		NULL,		-- @TestingStatus 	  	  	 
		NULL,		-- @StartTime
		NULL,		-- @EntryOn
		NULL,		-- @ReturnResultSet
		NULL,		-- @Conformance
		NULL,		-- @TestPctComplete
		NULL,		-- @SecondUserId
		NULL,		-- @ApproverUserId
		NULL,		-- @ApproverReasonId
		NULL,		-- @UserReasonId
		NULL,		-- @UserSignoffId
		NULL,		-- @Extended_Info
		0,			-- @SendEventPost
		NULL		-- @SignatureId
 
	IF @ReturnCode < 0
	BEGIN
		SELECT	
			@ErrorCode		= @ReturnCode,
			@ErrorMessage	= 'Error updating status for production event';
			
		--RETURN		
	END
 
	------------------------------------------------------------------------------
	--  Request real-time message publishing
	------------------------------------------------------------------------------
	--INSERT dbo.Local_MPWS_GENL_RealTimeMessages (EventId, ResultsetId, TransactionType, TransNum, InsertedDate, ErrorCode)
	--	VALUES (@EventId, 1, 2, 0, @Timestamp, 0);
		
	FETCH NEXT FROM Car_Cursor INTO @EventId, @StatusId;
	
END;
 
CLOSE Car_Cursor;
DEALLOCATE Car_Cursor;
 
DECLARE Kit_Cursor CURSOR FOR
	SELECT DISTINCT
		i.KitId,
		ps.ProdStatus_Id
	FROM @Ids i
		JOIN dbo.Production_Status ps ON ps.ProdStatus_Desc = i.NewKitStatus
	WHERE i.NewKitStatus <> i.KitStatus
		AND i.NewKitStatus IS NOT NULL;
 
OPEN Kit_Cursor;
FETCH NEXT FROM Kit_Cursor INTO @EventId, @StatusId;
 
WHILE @@FETCH_STATUS = 0
BEGIN
 
	--EXEC @ReturnCode = dbo.spServer_DBMgrUpdEvent
	SELECT 'Update Kit',
		@EventId	OUTPUT,           
		NULL,
		NULL,
		@Timestamp,	-- TimeStamp
		NULL,		-- Applied Product
		NULL,		-- SourceEvent
		@StatusId,	-- Event Status
		2,			-- TransType
		0,			-- TransNum
		NULL,		-- User
		NULL,		-- CommentId,
		NULL,		-- @EventSubtypeId 	  	  	 
		NULL,		-- @TestingStatus 	  	  	 
		NULL,		-- @StartTime
		NULL,		-- @EntryOn
		NULL,		-- @ReturnResultSet
		NULL,		-- @Conformance
		NULL,		-- @TestPctComplete
		NULL,		-- @SecondUserId
		NULL,		-- @ApproverUserId
		NULL,		-- @ApproverReasonId
		NULL,		-- @UserReasonId
		NULL,		-- @UserSignoffId
		NULL,		-- @Extended_Info
		0,			-- @SendEventPost
		NULL		-- @SignatureId
 
	IF @ReturnCode < 0
	BEGIN
		SELECT	
			@ErrorCode		= @ReturnCode,
			@ErrorMessage	= 'Error updating status for production event';
			
		--RETURN		
	END
 
	------------------------------------------------------------------------------
	--  Request real-time message publishing
	------------------------------------------------------------------------------
	--INSERT dbo.Local_MPWS_GENL_RealTimeMessages (EventId, ResultsetId, TransactionType, TransNum, InsertedDate, ErrorCode)
	--	VALUES (@EventId, 1, 2, 0, @Timestamp, 0);
		
	FETCH NEXT FROM Kit_Cursor INTO @EventId, @StatusId;
	
END;
 
CLOSE Kit_Cursor;
DEALLOCATE Kit_Cursor;
 
DECLARE Disp_Cursor CURSOR FOR
	SELECT DISTINCT
		i.DispId,
		ps.ProdStatus_Id
	FROM @Ids i
		JOIN dbo.Production_Status ps ON ps.ProdStatus_Desc = i.NewDispStatus
	WHERE i.NewDispStatus <> i.DispStatus
		AND NewDispStatus IS NOT NULL;
 
OPEN Disp_Cursor;
FETCH NEXT FROM Disp_Cursor INTO @EventId, @StatusId;
 
WHILE @@FETCH_STATUS = 0
BEGIN
 
	--EXEC @ReturnCode = dbo.spServer_DBMgrUpdEvent
	SELECT 'Update Disp',
		@EventId	OUTPUT,           
		NULL,
		NULL,
		@Timestamp,	-- TimeStamp
		NULL,		-- Applied Product
		NULL,		-- SourceEvent
		@StatusId,	-- Event Status
		2,			-- TransType
		0,			-- TransNum
		NULL,		-- User
		NULL,		-- CommentId,
		NULL,		-- @EventSubtypeId 	  	  	 
		NULL,		-- @TestingStatus 	  	  	 
		NULL,		-- @StartTime
		NULL,		-- @EntryOn
		NULL,		-- @ReturnResultSet
		NULL,		-- @Conformance
		NULL,		-- @TestPctComplete
		NULL,		-- @SecondUserId
		NULL,		-- @ApproverUserId
		NULL,		-- @ApproverReasonId
		NULL,		-- @UserReasonId
		NULL,		-- @UserSignoffId
		NULL,		-- @Extended_Info
		0,			-- @SendEventPost
		NULL		-- @SignatureId
 
	IF @ReturnCode < 0
	BEGIN
		SELECT	
			@ErrorCode		= @ReturnCode,
			@ErrorMessage	= 'Error updating status for production event';
			
		--RETURN		
	END
 
	------------------------------------------------------------------------------
	--  Request real-time message publishing
	------------------------------------------------------------------------------
	--INSERT dbo.Local_MPWS_GENL_RealTimeMessages (EventId, ResultsetId, TransactionType, TransNum, InsertedDate, ErrorCode)
	--	VALUES (@EventId, 1, 2, 0, @Timestamp, 0);
		
	FETCH NEXT FROM Disp_Cursor INTO @EventId, @StatusId;
	
END;
 
CLOSE Disp_Cursor;
DEALLOCATE Disp_Cursor;
 
DECLARE 
	@ECode INT, @EMessage VARCHAR(500)
 
DECLARE Bomfi_Cursor CURSOR FOR
	SELECT DISTINCT
		i.BomfiId,
		ps.ProdStatus_Id
	FROM @Ids i
		JOIN dbo.Production_Status ps ON ps.ProdStatus_Desc = i.NewBomfiStatus
	WHERE i.NewBomfiStatus <> i.BomfiStatus
		AND NewBomfiStatus IS NOT NULL;
 
OPEN Bomfi_Cursor;
FETCH NEXT FROM Bomfi_Cursor INTO @BomfiId, @StatusId;
 
WHILE @@FETCH_STATUS = 0
BEGIN
 
	--EXEC dbo.spLocal_MPWS_GENL_CreateUpdateUDP @ECode OUTPUT, @EMessage OUTPUT, @BomfiId, 'BOMItemStatus', 'Bill_Of_Material_Formulation_Item', @StatusId
	SELECT 'Update Bomfi', @BomfiId, @StatusId
	
	FETCH NEXT FROM Bomfi_Cursor INTO @BomfiId, @StatusId;
	
END;
 
CLOSE Bomfi_Cursor;
DEALLOCATE Bomfi_Cursor;
 
DECLARE PO_Cursor CURSOR FOR
	SELECT DISTINCT
		i.PPId,
		pps.PP_Status_Id
	FROM @Ids i
		JOIN dbo.Production_Plan_Statuses pps ON pps.PP_Status_Desc = i.NewPOStatus
	WHERE i.NewPOStatus <> i.POStatus
		AND NewPOStatus IS NOT NULL;
 
OPEN PO_Cursor;
FETCH NEXT FROM PO_Cursor INTO @PPlanId, @StatusId;
 
WHILE @@FETCH_STATUS = 0
BEGIN
 
	--EXEC @ReturnCode = dbo.spServer_DBMgrUpdProdPlan
	SELECT 'Update PO',
		@PPlanId	OUTPUT, --PPId
		2,			--TransType
		0,			--TransNum
		NULL,		--PathId
		NULL,		--CommentId
		NULL,		--ProdId
		NULL,		--ImpliedSequence
		@StatusId,	--PPStatusId
		NULL,		--PPTypeId
		NULL,		--SourcePPId
		1,			--UserId
		NULL,		--ParentPPId
		NULL,		--ControlType
		NULL,		--ForecastStartTime
		NULL,		--ForecastEndTime
		NULL,		--EntryOn
		NULL,		--ForecastQuantity
		NULL,		--ProductionRate
		NULL,		--AdjustedQuantity
		NULL,		--BlockNumber
		NULL,		--ProcessOrder
		@Timestamp,	--TransactionTime
		NULL,		--Misc1
		NULL,		--Misc2
		NULL,		--Misc3
		NULL,		--Misc4
		NULL,		--BOMFormulationId
		NULL,		--UserGeneral1
		NULL,		--UserGeneral2
		NULL,		--UserGeneral3
		NULL		--ExtendedInfo
 
	IF @ReturnCode < 0
	BEGIN
		SELECT	
			@ErrorCode		= @ReturnCode,
			@ErrorMessage	= 'Error updating status for production plan';
			
		--RETURN		
	END
 
	------------------------------------------------------------------------------
	--  Request real-time message publishing
	------------------------------------------------------------------------------
	--INSERT dbo.Local_MPWS_GENL_RealTimeMessages (EventId, ResultsetId, TransactionType, TransNum, InsertedDate, ErrorCode)
	--	VALUES (@PPlanId, 15, 2, 0, @Timestamp, 0);
 
	FETCH NEXT FROM PO_Cursor INTO @PPlanId, @StatusId;
	
END;
 
CLOSE PO_Cursor;
DEALLOCATE PO_Cursor;
 
------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------
 
IF @PPId IS NOT NULL OR @ProcessOrder IS NOT NULL
BEGIN
 
	UPDATE @Ids
		SET Selected = 1
	WHERE (PONum = @ProcessOrder OR @ProcessOrder IS NOT NULL)
	
END
ELSE IF @CarEventId IS NOT NULL OR @CarEventNum IS NOT NULL
BEGIN
 
	UPDATE @Ids
		SET Selected = 1
	WHERE (CarId = @CarEventId OR CarNum = @CarEventNum)
	
END
ELSE IF @KitEventId IS NOT NULL OR @KitEventNum IS NOT NULL
BEGIN
 
	UPDATE @Ids
		SET Selected = 1
	WHERE (KitId = @KitEventId OR KitNum = @KitEventNum)
	
END
ELSE IF @DispEventId IS NOT NULL OR @DispEventNum IS NOT NULL
BEGIN
 
	-- select dispense row
	UPDATE @Ids
		SET Selected = 1
	WHERE (DispId = @DispEventId OR DispNum = @DispEventNum)
	
	-- select kit that selected dispense belongs to, if any
	UPDATE @Ids
		SET Selected = 1
	WHERE KitId IN (SELECT KitId FROM @Ids WHERE Selected = 1);
	
END
		
SELECT * FROM @Ids
ORDER BY PONum, DispNum, KitNum, CSecNum, CarNum
 
return
 
 
 
 
 
